/*****************************************************************************
 * PokerTH - The open source texas holdem engine                             *
 * Copyright (C) 2006-2025 Felix Hammer, Florian Thauer, Lothar May          *
 *****************************************************************************/

#ifndef GAMEHANDLER_H
#define GAMEHANDLER_H

#include <QObject>
#include <QVariantList>
#include <boost/shared_ptr.hpp>

class ConfigFile;
class Session;
class Game;

class GameHandler : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QVariantList players READ players NOTIFY playersChanged)
    Q_PROPERTY(int pot READ pot NOTIFY potChanged)
    Q_PROPERTY(QString phaseText READ phaseText NOTIFY phaseTextChanged)
    Q_PROPERTY(int handNumber READ handNumber NOTIFY handNumberChanged)
    Q_PROPERTY(bool myTurn READ myTurn NOTIFY myTurnChanged)
    Q_PROPERTY(int callAmount READ callAmount NOTIFY callAmountChanged)
    Q_PROPERTY(int minRaiseAmount READ minRaiseAmount NOTIFY minRaiseAmountChanged)
    Q_PROPERTY(int maxRaiseAmount READ maxRaiseAmount NOTIFY maxRaiseAmountChanged)
    Q_PROPERTY(int totalPot READ totalPot NOTIFY totalPotChanged)
    Q_PROPERTY(int boardCardCount READ boardCardCount NOTIFY boardCardCountChanged)
    Q_PROPERTY(QVariantList boardCards READ boardCards NOTIFY boardCardsChanged)
    Q_PROPERTY(int winnerSeatId READ winnerSeatId NOTIFY winnerSeatIdChanged)

public:
    explicit GameHandler(QObject *parent = nullptr);

    void setSession(boost::shared_ptr<Session> session);
    void setGame(boost::shared_ptr<Game> game);
    void setConfig(ConfigFile *config) { m_config = config; }

    // Called from QML to start a local game
    Q_INVOKABLE void startLocalGame();
    Q_INVOKABLE void endLocalGame();
    Q_INVOKABLE bool isLocalGameRunning() const;
    QVariantList players() const { return m_players; }
    int pot() const { return m_pot; }
    QString phaseText() const { return m_phaseText; }
    int handNumber() const { return m_handNumber; }
    bool myTurn() const { return m_myTurn; }
    int callAmount() const { return m_callAmount; }
    int minRaiseAmount() const { return m_minRaiseAmount; }
    int maxRaiseAmount() const { return m_maxRaiseAmount; }
    int totalPot() const { return m_totalPot; }

    int boardCardCount() const { return m_boardCardCount; }
    QVariantList boardCards() const { return m_boardCards; }
    int winnerSeatId() const { return m_winnerSeatId; }

    // Called from QmlGuiInterface callbacks (must be Q_INVOKABLE for invokeMethod)
    Q_INVOKABLE void onRefreshSet();
    Q_INVOKABLE void onRefreshCash();
    Q_INVOKABLE void onRefreshPlayerName();
    Q_INVOKABLE void onRefreshPot();
    Q_INVOKABLE void onRefreshGameLabels(int gameState);
    Q_INVOKABLE void onMeInAction();
    Q_INVOKABLE void onDisableMyButtons();
    Q_INVOKABLE void onNextRoundCleanGui();
    Q_INVOKABLE void onDealFlopCards();
    Q_INVOKABLE void onDealTurnCard();
    Q_INVOKABLE void onDealRiverCard();
    // Game-loop advance callbacks (called via QMetaObject from QmlGuiInterface)
    Q_INVOKABLE void onRunBeRo();
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
    void callAmountChanged();
    void minRaiseAmountChanged();
    void maxRaiseAmountChanged();
    void totalPotChanged();
    void boardCardCountChanged();
    void boardCardsChanged();
    void winnerSeatIdChanged();

private:
    bool localGameCallbacksBlocked() const;
    void refreshPlayerData();
    void refreshBoardCards();
    void refreshPotData();
    void computeCallAndRaiseAmounts();
    void doActionDone();

    boost::shared_ptr<Session> m_session;
    boost::shared_ptr<Game> m_game;
    ConfigFile *m_config = nullptr;

    QVariantList m_players;
    int m_pot = 0;
    QString m_phaseText;
    int m_handNumber = 0;
    bool m_myTurn = false;
    int m_callAmount = 0;
    int m_minRaiseAmount = 0;
    int m_maxRaiseAmount = 0;
    int m_totalPot = 0;
    int m_boardCardCount = 0;
    QVariantList m_boardCards;  // 5 slots: card index (0-51) or -1 if not dealt
    int m_winnerSeatId = -1;
    bool m_localGameExitRequested = false;
};

#endif // GAMEHANDLER_H
