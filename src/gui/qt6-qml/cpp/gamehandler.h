/*****************************************************************************
 * PokerTH - The open source texas holdem engine                             *
 * Copyright (C) 2006-2025 Felix Hammer, Florian Thauer, Lothar May          *
 *****************************************************************************/

#ifndef GAMEHANDLER_H
#define GAMEHANDLER_H

#include <QObject>
#include <QVariantList>
#include <QStringList>
#include <boost/shared_ptr.hpp>

class ConfigFile;
class Session;
class Game;
class SoundEvents;
class QTimer;

class GameHandler : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QVariantList players READ players NOTIFY playersChanged)
    Q_PROPERTY(int pot READ pot NOTIFY potChanged)
    Q_PROPERTY(QString phaseText READ phaseText NOTIFY phaseTextChanged)
    Q_PROPERTY(int handNumber READ handNumber NOTIFY handNumberChanged)
    Q_PROPERTY(bool myTurn READ myTurn NOTIFY myTurnChanged)
    Q_PROPERTY(bool canAct READ canAct NOTIFY canActChanged)
    Q_PROPERTY(int callAmount READ callAmount NOTIFY callAmountChanged)
    Q_PROPERTY(int minRaiseAmount READ minRaiseAmount NOTIFY minRaiseAmountChanged)
    Q_PROPERTY(int maxRaiseAmount READ maxRaiseAmount NOTIFY maxRaiseAmountChanged)
    Q_PROPERTY(int totalPot READ totalPot NOTIFY totalPotChanged)
    Q_PROPERTY(int boardCardCount READ boardCardCount NOTIFY boardCardCountChanged)
    Q_PROPERTY(QVariantList boardCards READ boardCards NOTIFY boardCardsChanged)
    Q_PROPERTY(int winnerSeatId READ winnerSeatId NOTIFY winnerSeatIdChanged)
    Q_PROPERTY(QString winningHandText READ winningHandText NOTIFY winningHandTextChanged)
    Q_PROPERTY(QStringList gameLog READ gameLog NOTIFY gameLogChanged)
    Q_PROPERTY(QStringList chatLog READ chatLog NOTIFY chatLogChanged)
    // true, sobald außer mir noch (mind.) ein menschlicher Spieler im Spiel ist
    Q_PROPERTY(bool hasHumanOpponents READ hasHumanOpponents NOTIFY hasHumanOpponentsChanged)

public:
    explicit GameHandler(QObject *parent = nullptr);
    ~GameHandler() override;

    void setSession(boost::shared_ptr<Session> session);
    void setGame(boost::shared_ptr<Game> game);
    void setConfig(ConfigFile *config);

    // Called from QML to start a local game
    Q_INVOKABLE void startLocalGame();
    Q_INVOKABLE void endLocalGame();
    Q_INVOKABLE bool isLocalGameRunning() const;
    QVariantList players() const { return m_players; }
    int pot() const { return m_pot; }
    QString phaseText() const { return m_phaseText; }
    int handNumber() const { return m_handNumber; }
    bool myTurn() const { return m_myTurn; }
    bool canAct() const { return m_canAct; }
    int callAmount() const { return m_callAmount; }
    int minRaiseAmount() const { return m_minRaiseAmount; }
    int maxRaiseAmount() const { return m_maxRaiseAmount; }
    int totalPot() const { return m_totalPot; }

    int boardCardCount() const { return m_boardCardCount; }
    QVariantList boardCards() const { return m_boardCards; }
    int winnerSeatId() const { return m_winnerSeatId; }
    QString winningHandText() const { return m_winningHandText; }
    QStringList gameLog() const { return m_gameLog; }
    QStringList chatLog() const { return m_chatLog; }
    bool hasHumanOpponents() const { return m_hasHumanOpponents; }

    // Zeilentyp für die Einfärbung des Spielverlaufs – Farben/Stil 1:1 wie der
    // Qt-Widgets-Client (Default-Tischstil).
    enum LogLineType {
        LogNormal = 0,   // Aktionen, Blinds, aufgedeckte Karten (#F0F0F0)
        LogHeader,       // "## Game | Hand ##" (fett)
        LogWinnerMain,   // Gewinner Hauptpot (#FFFF00)
        LogWinnerSide,   // Gewinner Side-Pot (#FFFFCC)
        LogSitOut,       // "… sits out" (kursiv, #FF6633)
        LogBoard,        // "--- Flop/Turn/River ---" (#FF6633)
        LogGameWin       // "… wins game X!" (fett+kursiv)
    };
    Q_ENUM(LogLineType)

    // Append a line to the in-game action log (called from QmlGuiInterface).
    Q_INVOKABLE void appendGameLog(const QString &message, int type = LogNormal);
    // In-game chat: append a received message / send one to the table.
    Q_INVOKABLE void appendChat(const QString &playerName, const QString &message);
    Q_INVOKABLE void sendChat(const QString &message);

    // Called from QmlGuiInterface callbacks (must be Q_INVOKABLE for invokeMethod)
    Q_INVOKABLE void onRefreshSet();
    Q_INVOKABLE void onRefreshAction(int playerId, int playerAction);
    Q_INVOKABLE void onRefreshCash();
    Q_INVOKABLE void onRefreshPlayerName();
    Q_INVOKABLE void onRefreshPot();
    Q_INVOKABLE void onRefreshGameLabels(int gameState);
    Q_INVOKABLE void onMeInAction();
    Q_INVOKABLE void onDisableMyButtons();
    Q_INVOKABLE void onStartTimeoutAnimation(int playerNum, int timeoutSec);
    Q_INVOKABLE void onStopTimeoutAnimation(int playerNum);
    Q_INVOKABLE void onBlindsSet(int smallBlind);
    Q_INVOKABLE void onNextRoundCleanGui();
    Q_INVOKABLE void onDealFlopCards();
    Q_INVOKABLE void onDealTurnCard();
    Q_INVOKABLE void onDealRiverCard();
    // Game-loop advance callbacks (called via QMetaObject from QmlGuiInterface)
    Q_INVOKABLE void onRunBeRo();
    Q_INVOKABLE void onAfterDealCards();
    Q_INVOKABLE void onNextPlayerBeRo();
    Q_INVOKABLE void onSwitchRounds();
    Q_INVOKABLE void onPostRiverRunBeRo();
    Q_INVOKABLE void onShowdown();

    // Called from QML
    Q_INVOKABLE void fold();
    Q_INVOKABLE void call();
    Q_INVOKABLE void raise(int amount = 0);
    Q_INVOKABLE void allIn();

signals:
    void playersChanged();
    void potChanged();
    void phaseTextChanged();
    void handNumberChanged();
    void myTurnChanged();
    void canActChanged();
    void callAmountChanged();
    void minRaiseAmountChanged();
    void maxRaiseAmountChanged();
    void totalPotChanged();
    void boardCardCountChanged();
    void boardCardsChanged();
    void winnerSeatIdChanged();
    void winningHandTextChanged();
    void gameLogChanged();
    void chatLogChanged();
    void hasHumanOpponentsChanged();

private:
    bool localGameCallbacksBlocked() const;
    void ensureSoundEventHandler();
    void playYourTurnTimeoutSound();
    void refreshPlayerData();
    void refreshBoardCards();
    void refreshPotData();
    void computeCallAndRaiseAmounts();
    void doActionDone();

    boost::shared_ptr<Session> m_session;
    boost::shared_ptr<Game> m_game;
    ConfigFile *m_config = nullptr;
    SoundEvents *m_soundEventHandler = nullptr;
    QTimer *m_timeoutBeepTimer = nullptr;

    QVariantList m_players;
    int m_pot = 0;
    QString m_phaseText;
    int m_handNumber = 0;
    bool m_myTurn = false;
    bool m_canAct = false;
    int m_callAmount = 0;
    int m_minRaiseAmount = 0;
    int m_maxRaiseAmount = 0;
    int m_totalPot = 0;
    int m_boardCardCount = 0;
    QVariantList m_boardCards;  // 5 slots: card index (0-51) or -1 if not dealt
    int m_winnerSeatId = -1;
    QString m_winningHandText;  // Name der Gewinner-Hand (nur während des Showdowns)
    QStringList m_gameLog;      // Live-Aktions-Log (Spielverlauf) für das Overlay
    QStringList m_chatLog;      // In-Game-Chat-Verlauf
    bool m_hasHumanOpponents = false;
    // Showdown aktiv: erst dann dürfen Gegnerkarten aufgedeckt werden. Verhindert,
    // dass die (noch veraltete) playerNeedToShowCards-Liste während der River-
    // Setzrunde der nächsten Hand fälschlich Karten aufdeckt.
    bool m_showdownActive = false;
    // Aktions-Anzeige: pro Sitz die zuletzt gesehene Aktion + das Runden-Token,
    // in dem sie gesetzt wurde. So wird die Aktion nur in ihrer eigenen Runde
    // angezeigt und zu Rundenbeginn überall automatisch entfernt.
    int m_lastSeenAction[10] = {};
    // Zusätzlich zum Aktionstyp den Einsatz pro Sitz merken: ein erneutes Callen
    // nach einer Erhöhung bleibt Typ CALL, erhöht aber den Einsatz → gilt als
    // frische Aktion, damit das (zuvor geleerte) Badge wieder erscheint.
    int m_lastSeenSet[10] = {};
    int m_actionToken[10] = {-1, -1, -1, -1, -1, -1, -1, -1, -1, -1};
    // Setzt ein Spieler bet/raise, müssen die Aktions-Badges aller anderen (noch
    // nicht gefoldeten) Spieler verschwinden – sie sind wieder am Zug. Dazu bekommt
    // jede Aktion eine fortlaufende Sequenznummer; angezeigt wird sie nur, wenn sie
    // mindestens so neu ist wie die letzte Aggression (bet/raise) der Runde.
    int m_actionSeq[10] = {};
    int m_actionCounter = 0;
    int m_lastAggressorSeq = 0;
    int m_aggressorToken = -1;
    bool m_localGameExitRequested = false;
};

#endif // GAMEHANDLER_H
