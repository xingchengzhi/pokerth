#include "qtaudioplayer.h"
#include "core/appimage_utils.h"
#include <QDebug>
#include <QFileInfo>
#include <QStandardPaths>

#ifdef Q_OS_WIN
#pragma comment(lib, "winmm.lib")
#endif

// All sound files to preload
static const char* SOUND_FILES[] = {
    "allin", "bet", "blinds_raises_level1", "blinds_raises_level2", 
    "blinds_raises_level3", "call", "check", "dealtwocards", "fold",
    "lobbychatnotify", "onlinegameready", "playerconnected", "raise", "yourturn"
};

// --- WavMixer implementation ---

WavMixer::WavMixer(QObject* parent)
    : QIODevice(parent), volume(1.0f)
{
    open(QIODevice::ReadOnly);
}

bool WavMixer::loadWav(const QString& key, const QString& filePath)
{
    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly))
        return false;

    QByteArray fileData = file.readAll();
    file.close();

    if (fileData.size() < 44)
        return false;
    if (fileData.mid(0, 4) != "RIFF" || fileData.mid(8, 4) != "WAVE")
        return false;

    // Parse chunks: validate fmt, extract data
    int pos = 12;
    bool fmtValid = false;

    while (pos + 8 <= fileData.size()) {
        QByteArray chunkId = fileData.mid(pos, 4);
        quint32 chunkSize = qFromLittleEndian<quint32>(
            reinterpret_cast<const uchar*>(fileData.constData() + pos + 4));

        if (chunkId == "fmt " && chunkSize >= 16) {
            const uchar* fmt = reinterpret_cast<const uchar*>(fileData.constData() + pos + 8);
            quint16 audioFormat = qFromLittleEndian<quint16>(fmt);
            quint16 channels    = qFromLittleEndian<quint16>(fmt + 2);
            quint32 sampleRate  = qFromLittleEndian<quint32>(fmt + 4);
            quint16 bitsPerSample = qFromLittleEndian<quint16>(fmt + 14);

            if (audioFormat == 1 && channels == 2 && sampleRate == 44100 && bitsPerSample == 16) {
                fmtValid = true;
            } else {
                qWarning() << "[Audio] Unsupported WAV format in" << key
                           << "- need PCM 16-bit stereo 44100Hz";
                return false;
            }
        }

        if (chunkId == "data" && fmtValid) {
            qint64 avail = fileData.size() - pos - 8;
            if (static_cast<qint64>(chunkSize) > avail)
                chunkSize = static_cast<quint32>(avail);

            WavSample sample;
            sample.pcmData = fileData.mid(pos + 8, chunkSize);
            samples.insert(key, sample);
            return true;
        }

        pos += 8 + chunkSize;
        if (chunkSize & 1) pos++; // Pad to even boundary
    }
    return false;
}

void WavMixer::play(const QString& key)
{
    QMutexLocker lock(&mutex);
    auto it = samples.constFind(key);
    if (it == samples.constEnd())
        return;

    ActiveVoice voice;
    voice.pcmData = &it->pcmData;
    voice.position = 0;
    voices.append(voice);
}

void WavMixer::setVolume(float vol)
{
    QMutexLocker lock(&mutex);
    volume = qBound(0.0f, vol, 1.0f);
}

void WavMixer::stopAll()
{
    QMutexLocker lock(&mutex);
    voices.clear();
}

bool WavMixer::hasActiveVoices()
{
    QMutexLocker lock(&mutex);
    return !voices.isEmpty();
}

qint64 WavMixer::readData(char* data, qint64 maxSize)
{
    QMutexLocker lock(&mutex);

    // Align to frame boundary (4 bytes = 2 channels x 16-bit)
    maxSize &= ~3LL;
    if (maxSize <= 0)
        return 0;

    memset(data, 0, static_cast<size_t>(maxSize));

    if (voices.isEmpty())
        return maxSize; // Output silence

    const qint64 numSamples = maxSize / 2; // 16-bit samples
    qint16* out = reinterpret_cast<qint16*>(data);

    for (int v = voices.size() - 1; v >= 0; --v) {
        ActiveVoice& voice = voices[v];
        const qint16* src = reinterpret_cast<const qint16*>(
            voice.pcmData->constData() + voice.position);
        qint64 remaining = (voice.pcmData->size() - voice.position) / 2;
        qint64 toMix = qMin(numSamples, remaining);

        for (qint64 i = 0; i < toMix; ++i) {
            qint32 mixed = static_cast<qint32>(out[i])
                         + static_cast<qint32>(src[i] * volume);
            out[i] = static_cast<qint16>(qBound(-32768, mixed, 32767));
        }

        voice.position += toMix * 2; // Back to bytes
        if (voice.position >= voice.pcmData->size()) {
            voices.removeAt(v);
        }
    }

    return maxSize;
}

qint64 WavMixer::writeData(const char*, qint64)
{
    return -1;
}

bool WavMixer::isSequential() const
{
    return true;
}

qint64 WavMixer::bytesAvailable() const
{
    // Infinite stream: always report data available so QAudioSink keeps pulling
    return 1024 * 1024;
}

// --- QtAudioPlayer ---

QtAudioPlayer::QtAudioPlayer(ConfigFile *config)
    : myConfig(config), audioEnabled(false), backend(AudioBackend::QSoundEffectBackend),
      mediaDevices(nullptr), deviceChangeDebounceTimer(nullptr),
      mixer(nullptr), mixerSink(nullptr)
{
    myAppDataPath = QString::fromUtf8(myConfig->readConfigString("AppDataDir").c_str());
    
    // Initialize device monitoring
    mediaDevices = new QMediaDevices(this);
    lastDefaultDevice = QMediaDevices::defaultAudioOutput();
    
    // Debounce timer for Bluetooth reconnects etc.
    deviceChangeDebounceTimer = new QTimer(this);
    deviceChangeDebounceTimer->setSingleShot(true);
    connect(deviceChangeDebounceTimer, &QTimer::timeout,
            this, &QtAudioPlayer::onDeviceChangeDebounceTimeout);
    
    // Connect device change signals
    connect(mediaDevices, &QMediaDevices::audioOutputsChanged,
            this, &QtAudioPlayer::onAudioOutputsChanged);
    
    initAudio();
}

QtAudioPlayer::~QtAudioPlayer()
{
    closeAudio();
}

void QtAudioPlayer::initAudio()
{
    if (audioEnabled)
        return;
        
    if (!myConfig->readConfigInt("PlaySoundEffects"))
        return;

    
    // Check for forced backend via environment variable
    QString forcedBackend = qEnvironmentVariable("POKERTH_AUDIO_BACKEND");
    if (!forcedBackend.isEmpty()) {
    }
    
    // === Audio subsystem diagnostics ===
    {
        auto outputs = QMediaDevices::audioOutputs();
        for (const auto& dev : outputs) {
        }
    }
    
    // Determine which backend to use
    if (forcedBackend.toLower() == "paplay") {
        backend = AudioBackend::PaPlayBackend;
    } else if (forcedBackend.toLower() == "qsoundeffect") {
        backend = AudioBackend::QSoundEffectBackend;
    } else if (forcedBackend.toLower() == "mixer") {
        backend = AudioBackend::SoftwareMixerBackend;
    } else if (forcedBackend.toLower() == "winmm") {
#ifdef Q_OS_WIN
        backend = AudioBackend::WinMMBackend;
#else
        qWarning() << "[Audio] WinMM backend only available on Windows, falling back";
#endif
    } else {
        // Auto-detect best backend
#ifdef Q_OS_LINUX
        // AppImage: QAudioSink may not work because the bundled glibc/libs
        // conflict with the host audio stack.  Use paplay via
        // startDetachedSafe() which restores the original LD_LIBRARY_PATH.
        if (AppImageUtils::isAppImage() && detectPaPlay()) {
            backend = AudioBackend::PaPlayBackend;
        } else {
            // Native builds: use the software mixer — a single persistent
            // QAudioSink stream that mixes all sounds in-process.  This
            // avoids spawning a new paplay/pw-play process per sound effect,
            // which floods PulseAudio/PipeWire with concurrent streams and
            // causes stuttering in other audio consumers (e.g. video players).
            backend = AudioBackend::SoftwareMixerBackend;
        }
#elif defined(Q_OS_WIN)
        // Windows: software mixer with auto-suspend — single WASAPI session
        // avoids BT distortion from per-sound waveOutOpen; idle auto-suspend
        // after 3s ensures zero CPU when no sounds are playing.
        backend = AudioBackend::SoftwareMixerBackend;
#else
        // macOS: software mixer for low-latency playback
        backend = AudioBackend::SoftwareMixerBackend;
#endif
    }
    
    // Initialize selected backend
    float vol = myConfig->readConfigInt("SoundVolume") / 10.0f;
    
    QAudioDevice deviceToUse = selectedDevice.isNull() 
        ? QMediaDevices::defaultAudioOutput() 
        : selectedDevice;
    
    if (backend == AudioBackend::SoftwareMixerBackend) {
        initSoftwareMixerBackend(deviceToUse, vol);
    } else if (backend == AudioBackend::PaPlayBackend) {
        if (detectPaPlay()) {
            initPaPlayBackend();
        } else {
            qWarning() << "[Audio] paplay not found - falling back to software mixer";
            backend = AudioBackend::SoftwareMixerBackend;
            initSoftwareMixerBackend(deviceToUse, vol);
        }
#ifdef Q_OS_WIN
    } else if (backend == AudioBackend::WinMMBackend) {
        initWinMMBackend(vol);
#endif
    } else {
        initQSoundEffectBackend(deviceToUse, vol);
    }
    
    audioEnabled = true;
}

void QtAudioPlayer::initQSoundEffectBackend(const QAudioDevice& device, float volume)
{
    
    for (const char* soundName : SOUND_FILES) {
        QString key = QString::fromLatin1(soundName);
        QString filePath = myAppDataPath + "sounds/default/" + key + ".wav";
        
        QFileInfo fileInfo(filePath);
        if (!fileInfo.exists()) {
            qWarning() << "[Audio] Sound file not found:" << filePath;
            continue;
        }
        
        auto effect = QSharedPointer<QSoundEffect>::create();
        // Only set audio device explicitly if user chose a non-default device.
        if (!selectedDevice.isNull() && !device.isNull()) {
            effect->setAudioDevice(device);
        }
        effect->setSource(QUrl::fromLocalFile(filePath));
        effect->setLoopCount(1);
        effect->setVolume(volume);
        
        connect(effect.data(), &QSoundEffect::statusChanged, this, [key, effect]() {
            if (effect->status() == QSoundEffect::Error) {
                qWarning() << "[Audio] Error loading sound:" << key;
            }
        });
        
        effects.insert(key, effect);
    }
}

void QtAudioPlayer::initPaPlayBackend()
{
    
    for (const char* soundName : SOUND_FILES) {
        QString key = QString::fromLatin1(soundName);
        QString filePath = myAppDataPath + "sounds/default/" + key + ".wav";
        
        QFileInfo fileInfo(filePath);
        if (!fileInfo.exists()) {
            qWarning() << "[Audio] Sound file not found:" << filePath;
            continue;
        }
        
        soundFilePaths.insert(key, fileInfo.absoluteFilePath());
    }
}

bool QtAudioPlayer::detectPaPlay()
{
    // Check for paplay (PulseAudio) or pw-play (PipeWire native)
    paplayBinary = QStandardPaths::findExecutable("paplay");
    if (!paplayBinary.isEmpty()) {
        return true;
    }
    
    paplayBinary = QStandardPaths::findExecutable("pw-play");
    if (!paplayBinary.isEmpty()) {
        return true;
    }
    
    qWarning() << "[Audio] Neither paplay nor pw-play found in PATH";
    return false;
}

void QtAudioPlayer::playSound(std::string audioName, int /*playerID*/)
{
    if (!audioEnabled || !myConfig->readConfigInt("PlaySoundEffects"))
        return;

    const QString key = QString::fromStdString(audioName);
    
    if (backend == AudioBackend::SoftwareMixerBackend) {
        playSoundSoftwareMixer(key);
    } else if (backend == AudioBackend::PaPlayBackend) {
        playSoundPaPlay(key);
#ifdef Q_OS_WIN
    } else if (backend == AudioBackend::WinMMBackend) {
        playSoundWinMM(key);
#endif
    } else {
        playSoundQSoundEffect(key);
    }
}

void QtAudioPlayer::playSoundQSoundEffect(const QString& key)
{
    if (!effects.contains(key)) {
        qWarning() << "[Audio] Unknown sound:" << key;
        return;
    }

    auto effect = effects.value(key);
    if (!effect) return;
    
    if (effect->status() == QSoundEffect::Error) {
        qWarning() << "[Audio] Cannot play (error state):" << key;
        return;
    }
    
    if (effect->isLoaded()) {
        if (effect->isPlaying()) {
            effect->stop();
        }
        effect->play();
    } else if (effect->status() == QSoundEffect::Loading) {
        QMetaObject::Connection* conn = new QMetaObject::Connection();
        *conn = connect(effect.data(), &QSoundEffect::loadedChanged, this, [this, effect, key, conn]() {
            if (effect->isLoaded()) {
                effect->play();
            }
            disconnect(*conn);
            delete conn;
        });
    }
}

void QtAudioPlayer::playSoundPaPlay(const QString& key)
{
    if (!soundFilePaths.contains(key)) {
        qWarning() << "[Audio] Unknown sound:" << key;
        return;
    }
    
    const QString& filePath = soundFilePaths.value(key);
    
    // Volume: paplay uses --volume with PA volume (0-65536), 100% = 65536
    float vol = myConfig->readConfigInt("SoundVolume") / 10.0f;
    QString volumeStr = QString::number(qRound(vol * 65536.0f));
    
    QStringList args;
    if (paplayBinary.endsWith("paplay")) {
        args << "--volume" << volumeStr << filePath;
    } else {
        // pw-play uses --volume as 0.0-1.0 float
        args << "--volume" << QString::number(vol, 'f', 2) << filePath;
    }

    
    bool ok = AppImageUtils::startDetachedSafe(paplayBinary, args);
    if (!ok) {
        qWarning() << "[Audio] *** Failed to start" << paplayBinary << args;
    }
}

void QtAudioPlayer::initSoftwareMixerBackend(const QAudioDevice& device, float vol)
{
    mixer = new WavMixer(this);
    mixer->setVolume(vol);

    for (const char* soundName : SOUND_FILES) {
        QString key = QString::fromLatin1(soundName);
        QString filePath = myAppDataPath + "sounds/default/" + key + ".wav";

        if (!QFileInfo::exists(filePath)) {
            qWarning() << "[Audio] Sound file not found:" << filePath;
            continue;
        }
        if (!mixer->loadWav(key, filePath)) {
            qWarning() << "[Audio] Failed to parse WAV:" << filePath;
        }
    }

    // Single persistent audio output - eliminates per-sound WASAPI session latency
    QAudioFormat format;
    format.setSampleRate(44100);
    format.setChannelCount(2);
    format.setSampleFormat(QAudioFormat::Int16);

    QAudioDevice sinkDevice = device.isNull() ? QMediaDevices::defaultAudioOutput() : device;
    mixerSink = new QAudioSink(sinkDevice, format, this);
    // WASAPI on Windows needs a larger buffer than PulseAudio/CoreAudio.
    // 100ms causes underruns that make WASAPI transition to IdleState,
    // cutting off sounds mid-playback (e.g. blinds_raises WAVs).
#ifdef Q_OS_WIN
    mixerSink->setBufferSize(44100 * 4 * 2 / 5); // ~400ms for WASAPI
#else
    mixerSink->setBufferSize(44100 * 4 / 5);      // ~200ms for PulseAudio/CoreAudio
#endif

    connectMixerSinkSignals();

    mixerSink->start(mixer);

    if (mixerSink->error() != QAudio::NoError) {
        qWarning() << "[Audio] Failed to start mixer sink:" << mixerSink->error();
        delete mixerSink;
        mixerSink = nullptr;
    }

    // Auto-suspend: stop QAudioSink after a few seconds of silence to
    // eliminate idle CPU usage (important for older Windows 10 machines).
    // playSoundSoftwareMixer() restarts the sink on demand.
    if (mixerSink) {
        mixerIdleTimer = new QTimer(this);
        mixerIdleTimer->setInterval(1000);
        connect(mixerIdleTimer, &QTimer::timeout, this, [this]() {
            if (!mixer || !mixerSink) return;
            if (mixerSink->state() != QAudio::ActiveState) return;
            if (!mixer->hasActiveVoices()) {
                if (++mixerIdleCount >= 3) {  // 3 seconds of silence
                    mixerIdleTimer->stop();
                    m_stoppingMixerIntentionally = true;
                    mixerSink->stop();
                    m_stoppingMixerIntentionally = false;
                }
            } else {
                mixerIdleCount = 0;
            }
        });
        mixerIdleTimer->start();
    }
}

void QtAudioPlayer::playSoundSoftwareMixer(const QString& key)
{
    if (!mixer) return;

    mixer->play(key);
    mixerIdleCount = 0;

    // Resume the QAudioSink if it was auto-suspended due to idle
    if (mixerSink && mixerSink->state() != QAudio::ActiveState) {
        mixerSink->start(mixer);
    }

    // Ensure idle timer is running
    if (mixerIdleTimer && !mixerIdleTimer->isActive()) {
        mixerIdleTimer->start();
    }
}

void QtAudioPlayer::connectMixerSinkSignals()
{
    if (!mixerSink)
        return;

    // CRITICAL (Windows & macOS/Linux): Handle QAudioSink state changes.
    //
    // IdleState  — buffer underrun; restart the stream so the next
    //              play() is immediately audible.  We set a guard flag
    //              before stop() so the StoppedState handler knows this
    //              is an intentional (internal) stop, not a device-lost
    //              event.
    //
    // StoppedState — if the error is NoError the stop was intentional
    //                (either our IdleState handler or closeAudio()).
    //                Only recreate the sink for real errors (FatalError,
    //                device lost after sleep/hibernate, etc.).
    //
    // SuspendedState — system suspended audio; try to resume.
    connect(mixerSink, &QAudioSink::stateChanged, this, [this](QAudio::State newState) {
        if (!mixerSink || !mixer)
            return;
        if (newState == QAudio::IdleState) {
            m_stoppingMixerIntentionally = true;
            mixerSink->stop();
            mixerSink->start(mixer);
            m_stoppingMixerIntentionally = false;
        } else if (newState == QAudio::StoppedState) {
            if (m_stoppingMixerIntentionally)
                return;   // Intentional stop (IdleState recovery / closeAudio)
            auto err = mixerSink->error();
            if (err == QAudio::NoError)
                return;   // Clean stop — nothing to recover from
            qWarning() << "[Audio] Mixer sink stopped (error:" << err
                       << ") — recreating sink";
            QMetaObject::invokeMethod(this, [this]() {
                if (!mixer) return;
                applyDeviceToEffects();   // recreates the sink
            }, Qt::QueuedConnection);
        } else if (newState == QAudio::SuspendedState) {
            qWarning() << "[Audio] Mixer sink suspended — attempting resume";
            mixerSink->resume();
        }
    });
}

// --- Win32 waveOut backend ---
// Uses the Windows Multimedia waveOut* API for concurrent WAV playback.
// Each sound plays in its own thread with its own waveOut handle.
// Volume is applied directly to PCM samples — no global device volume change.
// Zero CPU when no sounds are playing.

#ifdef Q_OS_WIN

#include <thread>

// Parse a WAV file and store format + PCM data
static bool parseWavFile(const QString& filePath, QtAudioPlayer::WinMMSound& out)
{
    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly))
        return false;

    QByteArray fileData = file.readAll();
    file.close();

    if (fileData.size() < 44)
        return false;
    if (fileData.mid(0, 4) != "RIFF" || fileData.mid(8, 4) != "WAVE")
        return false;

    int pos = 12;
    bool fmtFound = false;

    while (pos + 8 <= fileData.size()) {
        QByteArray chunkId = fileData.mid(pos, 4);
        quint32 chunkSize = qFromLittleEndian<quint32>(
            reinterpret_cast<const uchar*>(fileData.constData() + pos + 4));

        if (chunkId == "fmt " && chunkSize >= 16) {
            const uchar* fmt = reinterpret_cast<const uchar*>(fileData.constData() + pos + 8);
            quint16 audioFormat = qFromLittleEndian<quint16>(fmt);

            if (audioFormat != 1) {  // Must be PCM
                qWarning() << "[Audio] Not PCM format in:" << filePath;
                return false;
            }

            out.channels      = qFromLittleEndian<quint16>(fmt + 2);
            out.sampleRate    = qFromLittleEndian<quint32>(fmt + 4);
            out.bitsPerSample = qFromLittleEndian<quint16>(fmt + 14);
            fmtFound = true;
        }

        if (chunkId == "data" && fmtFound) {
            qint64 avail = fileData.size() - pos - 8;
            if (static_cast<qint64>(chunkSize) > avail)
                chunkSize = static_cast<quint32>(avail);

            out.pcmData = fileData.mid(pos + 8, chunkSize);
            return true;
        }

        pos += 8 + chunkSize;
        if (chunkSize & 1) pos++;
    }
    return false;
}

void QtAudioPlayer::initWinMMBackend(float vol)
{

    winmmVolume = qBound(0.0f, vol, 1.0f);
    winmmShuttingDown.store(false);

    int loaded = 0;
    for (const char* soundName : SOUND_FILES) {
        QString key  = QString::fromLatin1(soundName);
        QString path = myAppDataPath + "sounds/default/" + key + ".wav";

        if (!QFileInfo::exists(path)) {
            qWarning() << "[Audio] Sound file not found:" << path;
            continue;
        }

        WinMMSound snd;
        if (parseWavFile(path, snd)) {
            winmmSounds.insert(key, snd);
            loaded++;
        } else {
            qWarning() << "[Audio] Failed to parse WAV:" << path;
        }
    }

}

void QtAudioPlayer::playSoundWinMM(const QString& key)
{
    auto it = winmmSounds.constFind(key);
    if (it == winmmSounds.constEnd()) {
        qWarning() << "[Audio] Unknown sound:" << key;
        return;
    }

    // Re-read volume from config in case user changed it
    float vol = myConfig->readConfigInt("SoundVolume") / 10.0f;
    winmmVolume = qBound(0.0f, vol, 1.0f);

    // Copy PCM data and apply volume scaling
    QByteArray scaledData = it->pcmData;
    if (it->bitsPerSample == 16) {
        qint16* samples = reinterpret_cast<qint16*>(scaledData.data());
        int numSamples = scaledData.size() / 2;
        for (int i = 0; i < numSamples; i++) {
            samples[i] = static_cast<qint16>(qBound(-32768,
                static_cast<qint32>(samples[i] * winmmVolume), 32767));
        }
    } else if (it->bitsPerSample == 8) {
        // 8-bit WAV is unsigned, 128 = silence
        quint8* samples = reinterpret_cast<quint8*>(scaledData.data());
        int numSamples = scaledData.size();
        for (int i = 0; i < numSamples; i++) {
            int centered = static_cast<int>(samples[i]) - 128;
            centered = static_cast<int>(centered * winmmVolume);
            samples[i] = static_cast<quint8>(qBound(0, centered + 128, 255));
        }
    }

    // Build WAVEFORMATEX from stored format info
    quint16 channels      = it->channels;
    quint32 sampleRate    = it->sampleRate;
    quint16 bitsPerSample = it->bitsPerSample;

    // Pointers captured by the thread
    std::atomic<bool>* shuttingDown = &winmmShuttingDown;
    QMutex* mtx = &winmmMutex;
    QVector<HWAVEOUT>* handles = &winmmActiveHandles;

    // Launch playback in a detached thread
    std::thread([scaledData = std::move(scaledData),
                 channels, sampleRate, bitsPerSample,
                 shuttingDown, mtx, handles]() mutable
    {
        if (shuttingDown->load())
            return;

        WAVEFORMATEX wfx = {};
        wfx.wFormatTag      = WAVE_FORMAT_PCM;
        wfx.nChannels       = channels;
        wfx.nSamplesPerSec  = sampleRate;
        wfx.wBitsPerSample  = bitsPerSample;
        wfx.nBlockAlign     = channels * bitsPerSample / 8;
        wfx.nAvgBytesPerSec = sampleRate * wfx.nBlockAlign;
        wfx.cbSize           = 0;

        HWAVEOUT hwo = nullptr;
        MMRESULT res = waveOutOpen(&hwo, WAVE_MAPPER, &wfx, 0, 0, CALLBACK_NULL);
        if (res != MMSYSERR_NOERROR) {
            qWarning() << "[Audio] waveOutOpen failed:" << res;
            return;
        }

        // Register handle for cleanup
        {
            QMutexLocker lock(mtx);
            handles->append(hwo);
        }

        WAVEHDR hdr = {};
        hdr.lpData         = scaledData.data();
        hdr.dwBufferLength = static_cast<DWORD>(scaledData.size());

        waveOutPrepareHeader(hwo, &hdr, sizeof(hdr));
        waveOutWrite(hwo, &hdr, sizeof(hdr));

        // Wait for playback to complete (poll every 10ms)
        while (!(hdr.dwFlags & WHDR_DONE)) {
            if (shuttingDown->load()) {
                waveOutReset(hwo);  // Forces WHDR_DONE
                break;
            }
            Sleep(10);
        }

        waveOutUnprepareHeader(hwo, &hdr, sizeof(hdr));
        waveOutClose(hwo);

        // Unregister handle
        {
            QMutexLocker lock(mtx);
            handles->removeOne(hwo);
        }
    }).detach();
}

#endif // Q_OS_WIN

void QtAudioPlayer::closeAudio()
{
#ifdef Q_OS_WIN
    if (backend == AudioBackend::WinMMBackend) {
        // Signal all playback threads to stop
        winmmShuttingDown.store(true);

        // Force-stop all active waveOut handles
        {
            QMutexLocker lock(&winmmMutex);
            for (HWAVEOUT hwo : winmmActiveHandles) {
                waveOutReset(hwo);
            }
        }

        // Give threads a moment to clean up
        QThread::msleep(50);

        winmmSounds.clear();
        winmmActiveHandles.clear();
    }
#endif
    if (mixerIdleTimer) {
        mixerIdleTimer->stop();
        delete mixerIdleTimer;
        mixerIdleTimer = nullptr;
    }
    mixerIdleCount = 0;
    if (mixerSink) {
        // Disconnect stateChanged BEFORE stopping so the handler cannot
        // queue a spurious applyDeviceToEffects() call that would fire
        // after initAudio() has already created a fresh sink.
        mixerSink->disconnect(this);
        m_stoppingMixerIntentionally = true;
        mixerSink->stop();
        m_stoppingMixerIntentionally = false;
        delete mixerSink;
        mixerSink = nullptr;
    }
    if (mixer) {
        mixer->stopAll();
        mixer->close();
        delete mixer;
        mixer = nullptr;
    }
    for (auto& e : effects) {
        if (e) {
            e->stop();
            e->disconnect();
        }
    }
    effects.clear();
    soundFilePaths.clear();
    audioEnabled = false;
}

void QtAudioPlayer::reInit()
{
    // Fast-path: if only the volume changed we can update the existing
    // mixer/effects in-place instead of tearing down the whole audio
    // subsystem (which on some platforms causes audible glitches and,
    // before the fix, triggered an infinite sink-recreation loop).
    if (audioEnabled) {
        float vol = myConfig->readConfigInt("SoundVolume") / 10.0f;

        if (backend == AudioBackend::SoftwareMixerBackend && mixer) {
            mixer->setVolume(vol);
            return;
        }

        if (backend == AudioBackend::QSoundEffectBackend && !effects.isEmpty()) {
            for (auto& e : effects) {
                if (e) e->setVolume(vol);
            }
            return;
        }

#ifdef Q_OS_WIN
        if (backend == AudioBackend::WinMMBackend) {
            winmmVolume = qBound(0.0f, vol, 1.0f);
            return;
        }
#endif
        // PaPlayBackend reads volume from config at play-time — nothing to do.
        if (backend == AudioBackend::PaPlayBackend) {
            return;
        }
    }

    // Full reinit for backend changes or first-time init.
    closeAudio();
    initAudio();
}

// --- Audio Device Management ---

QList<QAudioDevice> QtAudioPlayer::availableDevices() const
{
    return QMediaDevices::audioOutputs();
}

QAudioDevice QtAudioPlayer::currentDevice() const
{
    if (!selectedDevice.isNull()) {
        return selectedDevice;
    }
    return QMediaDevices::defaultAudioOutput();
}

void QtAudioPlayer::setAudioDevice(const QAudioDevice& device)
{
    if (selectedDevice == device) {
        return;
    }
    
    
    selectedDevice = device;
    
    // Apply to all existing effects without full reinit
    applyDeviceToEffects();
}

void QtAudioPlayer::applyDeviceToEffects()
{
    if (!audioEnabled) {
        return;
    }
    
    QAudioDevice deviceToUse = selectedDevice.isNull() 
        ? QMediaDevices::defaultAudioOutput() 
        : selectedDevice;
    
    if (deviceToUse.isNull()) {
        qWarning() << "[Audio] No audio device available for apply!";
        return;
    }
    
    if (backend == AudioBackend::SoftwareMixerBackend) {
        // Recreate the audio sink with the new device
        if (mixerSink) {
            mixerSink->disconnect(this);
            m_stoppingMixerIntentionally = true;
            mixerSink->stop();
            m_stoppingMixerIntentionally = false;
            delete mixerSink;
        }
        QAudioFormat format;
        format.setSampleRate(44100);
        format.setChannelCount(2);
        format.setSampleFormat(QAudioFormat::Int16);
        mixerSink = new QAudioSink(deviceToUse, format, this);
#ifdef Q_OS_WIN
        mixerSink->setBufferSize(44100 * 4 * 2 / 5); // ~400ms for WASAPI
#else
        mixerSink->setBufferSize(44100 * 4 / 5);      // ~200ms
#endif
        connectMixerSinkSignals();
        if (mixer) {
            mixerSink->start(mixer);
        }
        // Reset idle timer after device change
        mixerIdleCount = 0;
        if (mixerIdleTimer && !mixerIdleTimer->isActive()) {
            mixerIdleTimer->start();
        }
        return;
    }
    
    for (auto& effect : effects) {
        if (effect) {
            effect->setAudioDevice(deviceToUse);
        }
    }
}

void QtAudioPlayer::onAudioOutputsChanged()
{
    
    // Restart debounce timer - this handles rapid connect/disconnect events
    // (e.g., Bluetooth momentarily losing connection)
    scheduleDeviceCheck();
}

void QtAudioPlayer::scheduleDeviceCheck()
{
    // Restart timer on each change event - only act after stable period
    deviceChangeDebounceTimer->start(DEVICE_CHANGE_DEBOUNCE_MS);
}

void QtAudioPlayer::onDeviceChangeDebounceTimeout()
{
    for (const auto& dev : QMediaDevices::audioOutputs()) {
        // qDebug() << "  -" << dev.description() << (dev.isDefault() ? "(default)" : "");
    }
    
    // Check if default device changed
    QAudioDevice newDefault = QMediaDevices::defaultAudioOutput();
    if (newDefault != lastDefaultDevice) {
        onDefaultOutputChanged();
        lastDefaultDevice = newDefault;
    }
    
    // If user selected a specific device that's no longer available, fall back to default
    if (!selectedDevice.isNull()) {
        bool deviceStillExists = false;
        for (const auto& dev : QMediaDevices::audioOutputs()) {
            if (dev == selectedDevice) {
                deviceStillExists = true;
                break;
            }
        }
        
        if (!deviceStillExists) {
            selectedDevice = QAudioDevice(); // Clear selection, use default
            applyDeviceToEffects();
        }
    }
}

void QtAudioPlayer::onDefaultOutputChanged()
{
    QAudioDevice newDefault = QMediaDevices::defaultAudioOutput();
    
    // Only auto-switch if user hasn't selected a specific device
    if (selectedDevice.isNull()) {
        applyDeviceToEffects();
    }
}

bool QtAudioPlayer::probeAudioOutput(const QAudioDevice& device)
{
    
    // Create a format matching our WAV files: 16-bit signed LE, stereo, 44100Hz
    QAudioFormat format;
    format.setSampleRate(44100);
    format.setChannelCount(2);
    format.setSampleFormat(QAudioFormat::Int16);
    
    if (!device.isFormatSupported(format)) {
        qWarning() << "[Audio] Probe: device does NOT support 44100/16bit/stereo!";
        // Try with the device's preferred format
        format = device.preferredFormat();
    } else {
    }
    
    // Try creating a QAudioSink
    QAudioSink sink(device, format);
    
    // Create a small buffer of silence (100ms)
    int bytesPerSample = format.bytesPerSample() * format.channelCount();
    int bufferSize = format.sampleRate() / 10 * bytesPerSample; // 100ms
    QByteArray silenceData(bufferSize, '\0');
    QBuffer buffer(&silenceData);
    buffer.open(QIODevice::ReadOnly);
    
    // Try to start the sink
    sink.start(&buffer);
    
    auto state = sink.state();
    auto error = sink.error();
    
    
    sink.stop();
    buffer.close();
    
    if (error != QAudio::NoError) {
        qWarning() << "[Audio] Probe: FAILED with error:" << error;
        return false;
    }
    
    if (state == QAudio::ActiveState || state == QAudio::IdleState) {
        return true;
    }
    
    qWarning() << "[Audio] Probe: unexpected state:" << state;
    return false;
}