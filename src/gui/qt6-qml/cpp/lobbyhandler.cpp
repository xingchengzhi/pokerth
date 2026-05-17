/*****************************************************************************
 * PokerTH - The open source texas holdem engine                             *
 * Copyright (C) 2006-2025 Felix Hammer, Florian Thauer, Lothar May          *
 *****************************************************************************/

#include "lobbyhandler.h"
#include "session.h"
#include "configfile.h"
#include "gamedata.h"
#include "core/appimage_utils.h"

#include <QRegularExpression>
#include <QProcess>
#include <QProcessEnvironment>
#include <QUrl>
#include <QStringList>

class PlayerNickListSortFilterProxyModel : public QSortFilterProxyModel
{
public:
    explicit PlayerNickListSortFilterProxyModel(QObject *parent = nullptr)
        : QSortFilterProxyModel(parent)
        , m_filterState(0)
        , m_lastFilterStateCountry(false)
        , m_lastFilterStateAlpha(true)
        , m_session(nullptr)
    {
    }

    void setSession(Session *session)
    {
        m_session = session;
        invalidateFilter();
    }

    void setFilterState(int state)
    {
        if (m_filterState == 0) {
            m_lastFilterStateCountry = false;
            m_lastFilterStateAlpha = true;
        } else if (m_filterState == 1) {
            m_lastFilterStateCountry = true;
            m_lastFilterStateAlpha = false;
        }

        m_filterState = state;
        invalidateFilter();
        sort(0, Qt::AscendingOrder);
    }

    void refresh()
    {
        invalidateFilter();
        sort(0, Qt::AscendingOrder);
    }

    QHash<int, QByteArray> roleNames() const override
    {
        return sourceModel() ? sourceModel()->roleNames() : QHash<int, QByteArray>();
    }

protected:
    bool filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const override
    {
        if (!QSortFilterProxyModel::filterAcceptsRow(sourceRow, sourceParent))
            return false;

        if (m_filterState == 2) {
            if (!m_session)
                return false;

            QModelIndex idx = sourceModel()->index(sourceRow, 0, sourceParent);
            unsigned playerId = sourceModel()->data(idx, PlayerListModel::PlayerIdRole).toUInt();
            return m_session->getGameIdOfPlayer(playerId) == 0;
        }

        return true;
    }

    bool lessThan(const QModelIndex &left, const QModelIndex &right) const override
    {
        QString leftName = sourceModel()->data(left, PlayerListModel::PlayerNameRole).toString().toLower();
        QString rightName = sourceModel()->data(right, PlayerListModel::PlayerNameRole).toString().toLower();

        if (m_filterState == 1) {
            QString leftCountry = sourceModel()->data(left, PlayerListModel::CountryCodeRole).toString().toUpper();
            QString rightCountry = sourceModel()->data(right, PlayerListModel::CountryCodeRole).toString().toUpper();
            return (leftCountry + leftName) < (rightCountry + rightName);
        }

        if (m_filterState == 2 && m_lastFilterStateCountry) {
            QString leftCountry = sourceModel()->data(left, PlayerListModel::CountryCodeRole).toString().toUpper();
            QString rightCountry = sourceModel()->data(right, PlayerListModel::CountryCodeRole).toString().toUpper();
            return (leftCountry + leftName) < (rightCountry + rightName);
        }

        return leftName < rightName;
    }

private:
    int m_filterState;
    bool m_lastFilterStateCountry;
    bool m_lastFilterStateAlpha;
    Session *m_session;
};

class GameListSortFilterProxyModel : public QSortFilterProxyModel
{
public:
    explicit GameListSortFilterProxyModel(QObject *parent = nullptr)
        : QSortFilterProxyModel(parent)
        , m_filterMode(0)
        , m_session(nullptr)
    {
    }

    void setSession(Session *session)
    {
        m_session = session;
        invalidateFilter();
    }

    void setFilterMode(int mode)
    {
        if (mode < 0 || mode > 5)
            mode = 0;

        if (m_filterMode == mode)
            return;

        m_filterMode = mode;
        invalidateFilter();
    }

    QHash<int, QByteArray> roleNames() const override
    {
        return sourceModel() ? sourceModel()->roleNames() : QHash<int, QByteArray>();
    }

protected:
    bool filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const override
    {
        if (!QSortFilterProxyModel::filterAcceptsRow(sourceRow, sourceParent))
            return false;

        QModelIndex idx = sourceModel()->index(sourceRow, 0, sourceParent);
        if (!idx.isValid())
            return false;

        const unsigned gameId = sourceModel()->data(idx, GameListModel::GameIdRole).toUInt();
        const int gameMode = sourceModel()->data(idx, GameListModel::GameModeRole).toInt();
        const int playerCount = sourceModel()->data(idx, GameListModel::PlayerCountRole).toInt();
        const int maxPlayers = sourceModel()->data(idx, GameListModel::MaxPlayersRole).toInt();
        const bool isPrivate = sourceModel()->data(idx, GameListModel::IsPrivateRole).toBool();
        const int gameType = sourceModel()->data(idx, GameListModel::GameTypeRole).toInt();

        if (m_session && gameId != 0 && m_session->getClientCurrentGameId() == gameId)
            return true;

        const bool isOpen = (gameMode == GAME_MODE_CREATED);
        const bool isNonFull = (playerCount < maxPlayers);
        const bool isRanking = (gameType == GAME_TYPE_RANKING);

        switch (m_filterMode) {
        case 0:
            return true;
        case 1:
            return isOpen;
        case 2:
            return isOpen && isNonFull;
        case 3:
            return isOpen && isNonFull && !isPrivate;
        case 4:
            return isOpen && isNonFull && isPrivate;
        case 5:
            return isOpen && isNonFull && isRanking;
        default:
            return true;
        }
    }

private:
    int m_filterMode;
    Session *m_session;
};

// PlayerListModel implementation
PlayerListModel::PlayerListModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int PlayerListModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return m_players.count();
}

QVariant PlayerListModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_players.count())
        return QVariant();

    const PlayerInfo &player = m_players.at(index.row());
    
    switch (role) {
    case PlayerIdRole:
        return player.id;
    case PlayerNameRole:
        return player.name;
    case IsAdminRole:
        return player.isAdmin;
    case CountryCodeRole:
        return player.countryCode;
    case IsGuestRole:
        return player.isGuest;
    default:
        return QVariant();
    }
}

QHash<int, QByteArray> PlayerListModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[PlayerIdRole] = "playerId";
    roles[PlayerNameRole] = "playerName";
    roles[IsAdminRole] = "isAdmin";
    roles[CountryCodeRole] = "countryCode";
    roles[IsGuestRole] = "isGuest";
    return roles;
}

void PlayerListModel::addPlayer(unsigned playerId, const QString &playerName, bool isAdmin, const QString &countryCode, bool isGuest)
{
    // Check if player already exists
    if (m_playerIndexMap.contains(playerId)) {
        qWarning() << "Player" << playerId << "already in list";
        return;
    }
    
    int newRow = m_players.count();
    beginInsertRows(QModelIndex(), newRow, newRow);
    
    PlayerInfo player;
    player.id = playerId;
    player.name = playerName;
    player.isAdmin = isAdmin;
    player.countryCode = countryCode;
    player.isGuest = isGuest;
    m_players.append(player);
    m_playerIndexMap[playerId] = newRow;
    
    endInsertRows();
    emit countChanged();
}

void PlayerListModel::removePlayer(unsigned playerId)
{
    if (!m_playerIndexMap.contains(playerId)) {
        qWarning() << "Player" << playerId << "not found";
        return;
    }
    
    int row = m_playerIndexMap[playerId];
    beginRemoveRows(QModelIndex(), row, row);
    
    m_players.removeAt(row);
    m_playerIndexMap.remove(playerId);
    
    // Update indices for remaining players
    for (int i = row; i < m_players.count(); ++i) {
        m_playerIndexMap[m_players[i].id] = i;
    }
    
    endRemoveRows();
    emit countChanged();
}

void PlayerListModel::updatePlayer(unsigned playerId, const QString &newName)
{
    if (!m_playerIndexMap.contains(playerId))
        return;
    
    int row = m_playerIndexMap[playerId];
    m_players[row].name = newName;
    
    QModelIndex idx = index(row);
    emit dataChanged(idx, idx, {PlayerNameRole});
}

void PlayerListModel::updatePlayerInfo(unsigned playerId, const QString &playerName, bool isAdmin, const QString &countryCode, bool isGuest)
{
    if (!m_playerIndexMap.contains(playerId))
        return;
    
    int row = m_playerIndexMap[playerId];
    m_players[row].name = playerName;
    m_players[row].isAdmin = isAdmin;
    if (!countryCode.isEmpty())
        m_players[row].countryCode = countryCode;
    m_players[row].isGuest = isGuest;
    
    QModelIndex idx = index(row);
    emit dataChanged(idx, idx);
}

void PlayerListModel::clear()
{
    beginResetModel();
    m_players.clear();
    m_playerIndexMap.clear();
    endResetModel();
    emit countChanged();
}

// GameListModel implementation
GameListModel::GameListModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int GameListModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return m_games.count();
}

QVariant GameListModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_games.count())
        return QVariant();

    const GameEntry &game = m_games.at(index.row());
    
    switch (role) {
    case GameIdRole:
        return game.id;
    case GameNameRole:
        return game.name;
    case PlayerCountRole:
        return game.playerCount;
    case MaxPlayersRole:
        return game.maxPlayers;
    case GameModeRole:
        return game.gameMode;
    case IsPrivateRole:
        return game.isPrivate;
    case GameTypeRole:
        return game.gameType;
    case FirstSmallBlindRole:
        return game.firstSmallBlind;
    case StartMoneyRole:
        return game.startMoney;
    case RaiseIntervalModeRole:
        return game.raiseIntervalMode;
    case RaiseEveryHandsRole:
        return game.raiseEveryHands;
    case RaiseEveryMinutesRole:
        return game.raiseEveryMinutes;
    case RaiseModeRole:
        return game.raiseMode;
    case ManualBlindsTextRole:
        return game.manualBlindsText;
    case PlayerActionTimeoutRole:
        return game.playerActionTimeoutSec;
    case DelayBetweenHandsRole:
        return game.delayBetweenHandsSec;
    default:
        return QVariant();
    }
}

QHash<int, QByteArray> GameListModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[GameIdRole] = "gameId";
    roles[GameNameRole] = "gameName";
    roles[PlayerCountRole] = "playerCount";
    roles[MaxPlayersRole] = "maxPlayers";
    roles[GameModeRole] = "gameMode";
    roles[IsPrivateRole] = "isPrivate";
    roles[GameTypeRole] = "gameType";
    roles[FirstSmallBlindRole] = "firstSmallBlind";
    roles[StartMoneyRole] = "startMoney";
    roles[RaiseIntervalModeRole] = "raiseIntervalMode";
    roles[RaiseEveryHandsRole] = "raiseEveryHands";
    roles[RaiseEveryMinutesRole] = "raiseEveryMinutes";
    roles[RaiseModeRole] = "raiseMode";
    roles[ManualBlindsTextRole] = "manualBlindsText";
    roles[PlayerActionTimeoutRole] = "playerActionTimeoutSec";
    roles[DelayBetweenHandsRole] = "delayBetweenHandsSec";
    return roles;
}

void GameListModel::addGame(unsigned gameId, const QString &gameName)
{
    if (m_gameIndexMap.contains(gameId)) {
        qWarning() << "Game" << gameId << "already in list";
        return;
    }
    
    int newRow = m_games.count();
    beginInsertRows(QModelIndex(), newRow, newRow);
    
    GameEntry game;
    game.id = gameId;
    game.name = gameName.isEmpty() ? QString("Game #%1").arg(gameId) : gameName;
    game.playerCount = 0;
    game.maxPlayers = 10;
    game.gameMode = GAME_MODE_CREATED;
    game.isPrivate = false;
    game.gameType = GAME_TYPE_NORMAL;
    game.firstSmallBlind = 10;
    game.startMoney = 1000;
    game.raiseIntervalMode = RAISE_ON_HANDNUMBER;
    game.raiseEveryHands = 8;
    game.raiseEveryMinutes = 1;
    game.raiseMode = DOUBLE_BLINDS;
    game.manualBlindsText.clear();
    game.playerActionTimeoutSec = 20;
    game.delayBetweenHandsSec = 6;
    m_games.append(game);
    m_gameIndexMap[gameId] = newRow;
    
    endInsertRows();
    recomputeCounts();
}

void GameListModel::removeGame(unsigned gameId)
{
    if (!m_gameIndexMap.contains(gameId)) {
        qWarning() << "Game" << gameId << "not found";
        return;
    }
    
    int row = m_gameIndexMap[gameId];
    beginRemoveRows(QModelIndex(), row, row);
    
    m_games.removeAt(row);
    m_gameIndexMap.remove(gameId);
    
    // Update indices
    for (int i = row; i < m_games.count(); ++i) {
        m_gameIndexMap[m_games[i].id] = i;
    }
    
    endRemoveRows();
    recomputeCounts();
}

void GameListModel::updateGameMode(unsigned gameId, int mode)
{
    if (!m_gameIndexMap.contains(gameId))
        return;
    
    int row = m_gameIndexMap[gameId];
    int oldMode = m_games[row].gameMode;
    m_games[row].gameMode = mode;
    
    QModelIndex idx = index(row);
    emit dataChanged(idx, idx, {GameModeRole});

    recomputeCounts();
}

void GameListModel::updateGameInfo(unsigned gameId, const ::GameInfo &info)
{
    if (!m_gameIndexMap.contains(gameId))
        return;

    const int row = m_gameIndexMap[gameId];
    GameEntry &entry = m_games[row];

    const QString nameFromSession = QString::fromStdString(info.name);
    if (!nameFromSession.isEmpty())
        entry.name = nameFromSession;

    entry.playerCount = static_cast<int>(info.players.size());
    entry.maxPlayers = info.data.maxNumberOfPlayers > 0 ? info.data.maxNumberOfPlayers : 10;
    entry.gameMode = static_cast<int>(info.mode);
    entry.isPrivate = info.isPasswordProtected;
    entry.gameType = static_cast<int>(info.data.gameType);
    entry.firstSmallBlind = info.data.firstSmallBlind > 0 ? info.data.firstSmallBlind : 10;
    entry.startMoney = info.data.startMoney > 0 ? info.data.startMoney : 1000;
    entry.raiseIntervalMode = static_cast<int>(info.data.raiseIntervalMode);
    entry.raiseEveryHands = info.data.raiseSmallBlindEveryHandsValue;
    entry.raiseEveryMinutes = info.data.raiseSmallBlindEveryMinutesValue;
    entry.raiseMode = static_cast<int>(info.data.raiseMode);
    entry.playerActionTimeoutSec = info.data.playerActionTimeoutSec;
    entry.delayBetweenHandsSec = info.data.delayBetweenHandsSec;

    QStringList manualBlinds;
    for (std::list<int>::const_iterator it = info.data.manualBlindsList.begin(); it != info.data.manualBlindsList.end(); ++it) {
        manualBlinds << QString::number(*it);
    }
    entry.manualBlindsText = manualBlinds.join(QStringLiteral(", "));

    QModelIndex idx = index(row);
    emit dataChanged(idx, idx);
    recomputeCounts();
}

void GameListModel::recomputeCounts()
{
    int newOpenCount = 0;
    int newRunningCount = 0;

    for (const GameEntry &entry : m_games) {
        if (entry.gameMode == GAME_MODE_CREATED) {
            ++newOpenCount;
        } else if (entry.gameMode == GAME_MODE_STARTED) {
            ++newRunningCount;
        }
    }

    if (m_openCount != newOpenCount) {
        m_openCount = newOpenCount;
        emit openCountChanged();
    }

    if (m_runningCount != newRunningCount) {
        m_runningCount = newRunningCount;
        emit runningCountChanged();
    }
}

void GameListModel::clear()
{
    beginResetModel();
    m_games.clear();
    m_gameIndexMap.clear();
    endResetModel();
    recomputeCounts();
}

// LobbyHandler implementation
LobbyHandler::LobbyHandler(QObject *parent)
    : QObject(parent)
    , m_session()
    , m_config(nullptr)
    , m_playerListModel(this)
    , m_playerListProxyModel(nullptr)
    , m_gameListModel(this)
    , m_gameListProxyModel(nullptr)
    , m_myPlayerId(0)
    , m_playerListFilterMode(0)
    , m_gameListFilterMode(0)
    , m_playerListRevision(0)
    , m_gameListRevision(0)
{
    auto *proxy = new PlayerNickListSortFilterProxyModel(this);
    proxy->setSourceModel(&m_playerListModel);
    proxy->setDynamicSortFilter(true);
    proxy->sort(0, Qt::AscendingOrder);
    m_playerListProxyModel = proxy;

    auto *gameProxy = new GameListSortFilterProxyModel(this);
    gameProxy->setSourceModel(&m_gameListModel);
    gameProxy->setDynamicSortFilter(true);
    m_gameListProxyModel = gameProxy;
}

LobbyHandler::~LobbyHandler()
{
}

void LobbyHandler::setSession(boost::shared_ptr<Session> session)
{
    m_session = session;

    // Always reset lobby models on session assignment to avoid stale rows
    // when reconnect/resubscribe happens without pointer change.
    m_gameListModel.clear();
    m_playerListModel.clear();

    static_cast<PlayerNickListSortFilterProxyModel *>(m_playerListProxyModel)->setSession(m_session.get());
    static_cast<PlayerNickListSortFilterProxyModel *>(m_playerListProxyModel)->refresh();
    static_cast<GameListSortFilterProxyModel *>(m_gameListProxyModel)->setSession(m_session.get());
    ++m_playerListRevision;
    emit playerListRevisionChanged();
    ++m_gameListRevision;
    emit gameListRevisionChanged();
}

void LobbyHandler::setConfig(ConfigFile *config)
{
    m_config = config;

    if (!m_config)
        return;

    int storedMode = m_config->readConfigInt("DlgGameLobbyNickListSortFilterIndex");
    if (storedMode < 0 || storedMode > 2)
        storedMode = 0;

    setPlayerListFilterMode(storedMode);

    int storedGameListMode = m_config->readConfigInt("DlgGameLobbyGameListFilterIndex");
    if (storedGameListMode < 0 || storedGameListMode > 5)
        storedGameListMode = 0;

    setGameListFilterMode(storedGameListMode);
}

void LobbyHandler::onLobbyPlayerJoined(unsigned playerId, const QString &playerName)
{
    QString countryCode;
    bool isGuest = false;
    if (m_session) {
        PlayerInfo info = m_session->getClientPlayerInfo(playerId);
        countryCode = QString::fromStdString(info.countryCode).toLower();
        isGuest = info.isGuest;
    }
    m_playerListModel.addPlayer(playerId, playerName, false, countryCode, isGuest);
    static_cast<PlayerNickListSortFilterProxyModel *>(m_playerListProxyModel)->refresh();
    ++m_playerListRevision;
    emit playerListRevisionChanged();
    ++m_gameListRevision;
    emit gameListRevisionChanged();
}

void LobbyHandler::onLobbyPlayerLeft(unsigned playerId)
{
    m_playerListModel.removePlayer(playerId);
    static_cast<PlayerNickListSortFilterProxyModel *>(m_playerListProxyModel)->refresh();
    ++m_playerListRevision;
    emit playerListRevisionChanged();
    ++m_gameListRevision;
    emit gameListRevisionChanged();
}

void LobbyHandler::updatePlayerName(unsigned playerId, const QString &playerName, bool isAdmin)
{
    // Fetch country code from session player info
    QString countryCode;
    bool isGuest = false;
    if (m_session) {
        PlayerInfo info = m_session->getClientPlayerInfo(playerId);
        countryCode = QString::fromStdString(info.countryCode).toLower();
        isGuest = info.isGuest;
    }
    // Update in player list model
    m_playerListModel.updatePlayerInfo(playerId, playerName, isAdmin, countryCode, isGuest);
    static_cast<PlayerNickListSortFilterProxyModel *>(m_playerListProxyModel)->refresh();
    ++m_playerListRevision;
    emit playerListRevisionChanged();
    ++m_gameListRevision;
    emit gameListRevisionChanged();
    
    // Check if this is our own player by comparing with session's unique player ID
    if (m_session) {
        unsigned myId = m_session->getClientUniquePlayerId();
        if (playerId == myId) {
            setMyPlayerInfo(playerId, playerName);
            // Update admin status
            if (m_isCurrentPlayerAdmin != isAdmin) {
                m_isCurrentPlayerAdmin = isAdmin;
                emit isCurrentPlayerAdminChanged();
            }
        }
    }
}

void LobbyHandler::onGameListNew(unsigned gameId, const QString &gameName)
{
    m_gameListModel.addGame(gameId, gameName.isEmpty() ? QString("Game #%1").arg(gameId) : gameName);
    refreshGameInfo(gameId);
    ++m_gameListRevision;
    emit gameListRevisionChanged();
    static_cast<PlayerNickListSortFilterProxyModel *>(m_playerListProxyModel)->refresh();
    emit gameContextChanged();
}

void LobbyHandler::onGameListRemove(unsigned gameId)
{
    m_gameListModel.removeGame(gameId);
    ++m_gameListRevision;
    emit gameListRevisionChanged();
    static_cast<PlayerNickListSortFilterProxyModel *>(m_playerListProxyModel)->refresh();
    emit gameContextChanged();
}

void LobbyHandler::onGameListUpdateMode(unsigned gameId, int mode)
{
    m_gameListModel.updateGameMode(gameId, mode);
    refreshGameInfo(gameId);
    ++m_gameListRevision;
    emit gameListRevisionChanged();
    static_cast<PlayerNickListSortFilterProxyModel *>(m_playerListProxyModel)->refresh();
    emit gameContextChanged();
}

void LobbyHandler::onGameListChanged(unsigned gameId)
{
    refreshGameInfo(gameId);
    ++m_gameListRevision;
    emit gameListRevisionChanged();
    emit gameContextChanged();
}

void LobbyHandler::setMyPlayerInfo(unsigned playerId, const QString &playerName)
{
    if (m_myPlayerId != playerId) {
        m_myPlayerId = playerId;
        emit myPlayerIdChanged();
    }
    
    if (m_myPlayerName != playerName) {
        m_myPlayerName = playerName;
        emit myPlayerNameChanged();
    }

    emit gameContextChanged();
}

bool LobbyHandler::canInviteFromCurrentGame() const
{
    if (!m_session)
        return false;

    const unsigned gameId = m_session->getClientCurrentGameId();
    if (!gameId)
        return false;

    const GameInfo currentGame = m_session->getClientGameInfo(gameId);
    return currentGame.data.gameType == GAME_TYPE_INVITE_ONLY;
}

void LobbyHandler::setPlayerListFilterMode(int mode)
{
    if (mode < 0 || mode > 2)
        mode = 0;

    if (m_playerListFilterMode == mode)
        return;

    m_playerListFilterMode = mode;
    static_cast<PlayerNickListSortFilterProxyModel *>(m_playerListProxyModel)->setFilterState(mode);
    ++m_playerListRevision;
    emit playerListRevisionChanged();

    if (m_config) {
        m_config->writeConfigInt("DlgGameLobbyNickListSortFilterIndex", mode);
        m_config->writeBuffer();
    }

    emit playerListFilterModeChanged();
}

void LobbyHandler::setGameListFilterMode(int mode)
{
    if (mode < 0 || mode > 5)
        mode = 0;

    if (m_gameListFilterMode == mode)
        return;

    m_gameListFilterMode = mode;
    static_cast<GameListSortFilterProxyModel *>(m_gameListProxyModel)->setFilterMode(mode);

    if (m_config) {
        m_config->writeConfigInt("DlgGameLobbyGameListFilterIndex", mode);
        m_config->writeBuffer();
    }

    emit gameListFilterModeChanged();
}

void LobbyHandler::refreshGameInfo(unsigned gameId)
{
    if (!m_session)
        return;

    const ::GameInfo info = m_session->getClientGameInfo(gameId);
    m_gameListModel.updateGameInfo(gameId, info);
}

QVariantMap LobbyHandler::playerListEntry(int row) const
{
    QVariantMap entry;

    if (!m_playerListProxyModel || row < 0)
        return entry;

    const QModelIndex index = m_playerListProxyModel->index(row, 0);
    if (!index.isValid())
        return entry;

    const unsigned playerId = m_playerListProxyModel->data(index, PlayerListModel::PlayerIdRole).toUInt();
    QString playerName = m_playerListProxyModel->data(index, PlayerListModel::PlayerNameRole).toString();
    const bool isAdmin = m_playerListProxyModel->data(index, PlayerListModel::IsAdminRole).toBool();
    QString countryCode = m_playerListProxyModel->data(index, PlayerListModel::CountryCodeRole).toString();
    const bool isGuest = m_playerListProxyModel->data(index, PlayerListModel::IsGuestRole).toBool();

    if (m_session && playerId != 0) {
        static const QRegularExpression numericPlaceholderPattern("^#?\\d+$");
        const bool nameIsPlaceholder = playerName.isEmpty() || numericPlaceholderPattern.match(playerName).hasMatch();

        if (nameIsPlaceholder || countryCode.isEmpty()) {
            const PlayerInfo info = m_session->getClientPlayerInfo(playerId);
            const QString sessionName = QString::fromStdString(info.playerName);
            const QString sessionCountryCode = QString::fromStdString(info.countryCode).toLower();

            if (nameIsPlaceholder && !sessionName.isEmpty()) {
                playerName = sessionName;
            }

            if (countryCode.isEmpty() && !sessionCountryCode.isEmpty()) {
                countryCode = sessionCountryCode;
            }
        }
    }

    entry.insert("playerId", playerId);
    entry.insert("playerName", playerName);
    entry.insert("isAdmin", isAdmin);
    entry.insert("countryCode", countryCode);
    entry.insert("isGuest", isGuest);
    return entry;
}

QVariantList LobbyHandler::gamePlayersInGame(unsigned gameId) const
{
    QVariantList players;

    if (!m_session || gameId == 0)
        return players;

    const ::GameInfo gameInfo = m_session->getClientGameInfo(gameId);
    for (PlayerIdList::const_iterator it = gameInfo.players.begin(); it != gameInfo.players.end(); ++it) {
        const unsigned playerId = *it;
        if (playerId == 0)
            continue;

        const PlayerInfo info = m_session->getClientPlayerInfo(playerId);

        QVariantMap entry;
        entry.insert("playerId", playerId);
        entry.insert("playerName", QString::fromStdString(info.playerName));
        entry.insert("countryCode", QString::fromStdString(info.countryCode).toLower());
        entry.insert("isAdmin", info.isAdmin);
        entry.insert("isGuest", info.isGuest);

        QString avatarUrl;
        if (info.hasAvatar) {
            std::string avatarFile;
            if (m_session->getAvatarFile(info.avatar, avatarFile) && !avatarFile.empty()) {
                avatarUrl = QUrl::fromLocalFile(QString::fromStdString(avatarFile)).toString();
            }
        }
        entry.insert("avatarUrl", avatarUrl);

        players.append(entry);
    }

    return players;
}

bool LobbyHandler::openExternalUrl(const QString &url) const
{
    if (url.trimmed().isEmpty())
        return false;

    const QUrl target = QUrl::fromUserInput(url.trimmed());
    if (!target.isValid())
        return false;

#ifdef Q_OS_LINUX
    const QString targetString = target.toString();

    // External host tools must not inherit bundled Qt libraries.
    auto startDetachedHostTool = [](const QString &program, const QStringList &args) {
        QProcessEnvironment env = QProcessEnvironment::systemEnvironment();

        const QString origLdLibraryPath = QString::fromLocal8Bit(qgetenv("POKERTH_ORIG_LD_LIBRARY_PATH"));
        if (origLdLibraryPath.isEmpty()) {
            env.remove(QStringLiteral("LD_LIBRARY_PATH"));
        } else {
            env.insert(QStringLiteral("LD_LIBRARY_PATH"), origLdLibraryPath);
        }
        env.remove(QStringLiteral("LD_PRELOAD"));

        QProcess process;
        process.setProcessEnvironment(env);
        process.setProgram(program);
        process.setArguments(args);
        return process.startDetached();
    };

    if (startDetachedHostTool(QStringLiteral("xdg-open"), {targetString}))
        return true;

    if (startDetachedHostTool(QStringLiteral("gio"), {QStringLiteral("open"), targetString}))
        return true;

    if (startDetachedHostTool(QStringLiteral("kde-open"), {targetString}))
        return true;
#endif

    if (AppImageUtils::openUrlSafe(target))
        return true;

    return false;
}

void LobbyHandler::sendChatMessage(const QString &message)
{
    if (!m_session || message.trimmed().isEmpty())
        return;
    
    try {
        m_session->sendLobbyChatMessage(message.toStdString());
    } catch (const std::exception &e) {
        qWarning() << "Failed to send chat message:" << e.what();
        emit errorOccurred(tr("Failed to send chat message"));
    }
}

void LobbyHandler::onLobbyChatMessage(const QString &playerName, const QString &message)
{
    emit chatMessageReceived(playerName, message);
}

void LobbyHandler::createGame()
{
    if (!m_session) {
        emit errorOccurred(tr("Not connected to server"));
        return;
    }
    
    // TODO: Implement game creation via session
}

void LobbyHandler::joinGame(unsigned gameId)
{
    if (!m_session) {
        emit errorOccurred(tr("Not connected to server"));
        return;
    }
    
    // TODO: Implement game join via session
    emit gameJoined(gameId);
}

void LobbyHandler::leaveGame()
{
    if (!m_session)
        return;
    
    // TODO: Implement game leave via session
}

void LobbyHandler::kickPlayer(unsigned playerId)
{
    if (!m_session) {
        emit errorOccurred(tr("Not connected to server"));
        return;
    }
    m_session->kickPlayer(playerId);
}

void LobbyHandler::invitePlayer(unsigned playerId)
{
    if (!m_session) {
        emit errorOccurred(tr("Not connected to server"));
        return;
    }
    m_session->invitePlayerToCurrentGame(playerId);
}

void LobbyHandler::adminBanPlayer(unsigned playerId)
{
    if (!m_session) {
        emit errorOccurred(tr("Not connected to server"));
        return;
    }
    m_session->adminActionBanPlayer(playerId);
}

void LobbyHandler::sendPrivateMessage(unsigned targetPlayerId, const QString &message)
{
    if (!m_session) {
        emit errorOccurred(tr("Not connected to server"));
        return;
    }
    m_session->sendPrivateChatMessage(targetPlayerId, message.toStdString());
}
