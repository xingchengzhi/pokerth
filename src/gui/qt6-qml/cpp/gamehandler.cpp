/*****************************************************************************
 * PokerTH - The open source texas holdem engine                             *
 * Copyright (C) 2006-2025 Felix Hammer, Florian Thauer, Lothar May          *
 *****************************************************************************/

#include "gamehandler.h"
#include <session.h>
#include <game.h>
#include <handinterface.h>
#include <playerinterface.h>
#include <boardinterface.h>
#include <berointerface.h>
#include <game_defs.h>
#include <gamedata.h>
#include <configfile.h>
#include <QString>
#include <QTimer>
#include <QDebug>
#include <algorithm>
#include <list>

GameHandler::GameHandler(QObject *parent)
    : QObject(parent), m_phaseText("Preflop")
{
    // Initialize empty player list (10 seats)
    for (int i = 0; i < 10; ++i) {
        QVariantMap p;
        p["name"]    = QString("");
        p["stack"]   = 0;
        p["bet"]     = 0;
        p["active"]  = false;
        p["myTurn"]  = false;
        p["seatId"]  = i;
        p["button"]  = 0;
        p["card0"]   = -1;
        p["card1"]   = -1;
        m_players.append(p);
    }
    // Initialize empty board cards (5 slots, -1 = not dealt)
    for (int i = 0; i < 5; ++i)
        m_boardCards.append(-1);
}

void GameHandler::setSession(boost::shared_ptr<Session> session)
{
    m_session = session;
}

void GameHandler::setGame(boost::shared_ptr<Game> game)
{
    m_localGameExitRequested = false;
    m_game = game;
    // Reset state for new game
    m_pot = 0;
    m_phaseText = "Preflop";
    m_handNumber = 0;
    m_myTurn = false;
    m_callAmount = 0;
    m_minRaiseAmount = 0;
    m_maxRaiseAmount = 0;
    m_boardCardCount = 0;
    m_boardCards = QVariantList{-1, -1, -1, -1, -1};
    m_winnerSeatId = -1;

    // Re-build player list (seats may differ between games)
    refreshPlayerData();

    emit potChanged();
    emit phaseTextChanged();
    emit handNumberChanged();
    emit myTurnChanged();
    emit callAmountChanged();
    emit minRaiseAmountChanged();
    emit maxRaiseAmountChanged();
    emit boardCardCountChanged();
    emit boardCardsChanged();
}

// ─── private helpers ────────────────────────────────────────────────────────

bool GameHandler::localGameCallbacksBlocked() const
{
    if (!m_localGameExitRequested) return false;
    if (!m_session) return true;
    return !m_session->isNetworkClientRunning();
}

void GameHandler::refreshPlayerData()
{
    // Build a fresh 10-slot list
    QVariantList newPlayers;
    for (int i = 0; i < 10; ++i) {
        QVariantMap p;
        p["name"]   = QString("");
        p["stack"]  = 0;
        p["bet"]    = 0;
        p["active"] = false;
        p["myTurn"] = false;
        p["seatId"] = i;
        p["button"] = 0;
        p["card0"]  = -1;
        p["card1"]  = -1;
        newPlayers.append(p);
    }

    // Lazy-init m_game for local games: session creates the game internally
    if (!m_game && m_session && !m_localGameExitRequested) {
        auto g = m_session->getCurrentGame();
        if (g) m_game = g;
    }

    if (m_game) {
        PlayerList seats = m_game->getSeatsList();
        for (auto it = seats->begin(); it != seats->end(); ++it) {
            int id = (*it)->getMyID();
            if (id >= 0 && id < 10) {
                int cards[2] = {-1, -1};
                (*it)->getMyCards(cards);
                // Show face-up cards for: human player (id==0), explicitly flipped,
                // or required to show at showdown (winner / called player).
                bool faceUp = (id == 0) || (*it)->getMyCardsFlip() || (*it)->checkIfINeedToShowCards();
                QVariantMap p;
                p["name"]   = QString::fromStdString((*it)->getMyName());
                p["stack"]  = (*it)->getMyCash();
                p["bet"]    = (*it)->getMySet();
                p["active"] = (*it)->getMyActiveStatus();
                p["myTurn"] = (*it)->getMyTurn();
                p["seatId"] = id;
                p["button"] = (*it)->getMyButton();
                p["card0"]  = faceUp ? cards[0] : -1;
                p["card1"]  = faceUp ? cards[1] : -1;
                if (id == 0) {
                    // qDebug() << "[DBG] seat0 cards:" << cards[0] << cards[1]
                    //          << "faceUp:" << faceUp;
                }
                newPlayers[id] = p;
            }
        }
    }

    m_players = newPlayers;
    emit playersChanged();
}

void GameHandler::refreshPotData()
{
    if (!m_game) return;
    auto hand = m_game->getCurrentHand();
    if (!hand) return;
    auto board = hand->getBoard();
    if (!board) return;

    int newPot = board->getPot();
    if (newPot != m_pot) {
        m_pot = newPot;
        emit potChanged();
    }

    int newTotalPot = board->getPot() + board->getSets();
    if (newTotalPot != m_totalPot) {
        m_totalPot = newTotalPot;
        emit totalPotChanged();
    }
}

void GameHandler::computeCallAndRaiseAmounts()
{
    int newCallAmount = 0;
    int newMinRaise = 0;
    int newMaxRaise = 0;

    if (m_game) {
        auto hand = m_game->getCurrentHand();
        if (hand) {
            auto bero = hand->getCurrentBeRo();
            auto seats = hand->getSeatsList();
            if (bero && seats && !seats->empty()) {
                auto humanPlayer = seats->front();
                const int highestSet = bero->getHighestSet();
                const int humanSet = humanPlayer->getMySet();
                const int humanCash = humanPlayer->getMyCash();

                if (humanCash + humanSet <= highestSet) {
                    newCallAmount = humanCash;
                } else {
                    newCallAmount = highestSet - humanSet;
                }
                if (newCallAmount < 0) {
                    newCallAmount = 0;
                }

                const bool buttonsDisabled =
                    humanPlayer->getMyAction() == PLAYER_ACTION_ALLIN ||
                    humanPlayer->getMyAction() == PLAYER_ACTION_FOLD ||
                    humanCash == 0 ||
                    (humanSet == highestSet && humanPlayer->getMyAction() != PLAYER_ACTION_NONE) ||
                    !humanPlayer->isSessionActive();

                if (!buttonsDisabled && !bero->getFullBetRule()) {
                    int minimum = 0;
                    bool canBetRaise = false;

                    if (hand->getCurrentRound() == 0) {
                        if (humanCash + humanSet > highestSet) {
                            minimum = highestSet - humanSet + bero->getMinimumRaise();
                            canBetRaise = true;
                        }
                    } else {
                        if (highestSet == 0) {
                            minimum = hand->getSmallBlind() * 2;
                            canBetRaise = true;
                        } else if (highestSet > humanSet && humanCash + humanSet > highestSet) {
                            minimum = highestSet - humanSet + bero->getMinimumRaise();
                            canBetRaise = true;
                        }
                    }

                    if (canBetRaise) {
                        if (minimum < 0) {
                            minimum = 0;
                        }
                        newMaxRaise = humanCash;
                        newMinRaise = std::min(minimum, newMaxRaise);
                    }
                }
            }
        }
    }

    if (newCallAmount != m_callAmount) {
        m_callAmount = newCallAmount;
        emit callAmountChanged();
    }
    if (newMinRaise != m_minRaiseAmount) {
        m_minRaiseAmount = newMinRaise;
        emit minRaiseAmountChanged();
    }
    if (newMaxRaise != m_maxRaiseAmount) {
        m_maxRaiseAmount = newMaxRaise;
        emit maxRaiseAmountChanged();
    }
}

void GameHandler::doActionDone()
{
    if (!m_session) return;
    if (localGameCallbacksBlocked()) return;

    if (m_myTurn) {
        m_myTurn = false;
        emit myTurnChanged();
    }

    if (m_session->isNetworkClientRunning()) {
        // Network game: send action to server
        m_session->sendClientPlayerAction();
    } else {
        // Local game: advance game loop (equivalent to Qt5 nextPlayerAnimation -> switchRounds)
        boost::shared_ptr<Game> game = m_game;
        QTimer::singleShot(300, this, [game]() {
            if (game && game->getCurrentHand())
                game->getCurrentHand()->switchRounds();
        });
    }
}

// ─── slots called from QmlGuiInterface ──────────────────────────────────────

void GameHandler::onRefreshSet()
{
    if (localGameCallbacksBlocked()) return;
    refreshPlayerData();
    computeCallAndRaiseAmounts();
}

void GameHandler::onRefreshCash()
{
    if (localGameCallbacksBlocked()) return;
    refreshPlayerData();
    computeCallAndRaiseAmounts();
}

void GameHandler::onRefreshPlayerName()
{
    if (localGameCallbacksBlocked()) return;
    refreshPlayerData();
}

void GameHandler::onRefreshPot()
{
    if (localGameCallbacksBlocked()) return;
    refreshPotData();
    refreshPlayerData();
    computeCallAndRaiseAmounts();
}

void GameHandler::onRefreshGameLabels(int gameState)
{
    if (localGameCallbacksBlocked()) return;
    QString newPhase;
    switch (gameState) {
    case 0:  newPhase = "Preflop"; break;
    case 1:  newPhase = "Flop";    break;
    case 2:  newPhase = "Turn";    break;
    case 3:  newPhase = "River";   break;
    default: newPhase = "";        break;
    }

    if (newPhase != m_phaseText) {
        m_phaseText = newPhase;
        emit phaseTextChanged();
    }

    if (m_game) {
        auto hand = m_game->getCurrentHand();
        if (hand) {
            int newHandNum = hand->getMyID();
            if (newHandNum != m_handNumber) {
                m_handNumber = newHandNum;
                emit handNumberChanged();
            }
        }
    }

    computeCallAndRaiseAmounts();
}

void GameHandler::onMeInAction()
{
    if (localGameCallbacksBlocked()) return;
    refreshPlayerData();
    computeCallAndRaiseAmounts();
    if (!m_myTurn) {
        m_myTurn = true;
        emit myTurnChanged();
    }
}

void GameHandler::onDisableMyButtons()
{
    if (localGameCallbacksBlocked()) return;
    if (m_myTurn) {
        m_myTurn = false;
        emit myTurnChanged();
    }
}

void GameHandler::refreshBoardCards()
{
    if (!m_game) return;
    auto hand = m_game->getCurrentHand();
    if (!hand) return;
    auto board = hand->getBoard();
    if (!board) return;

    int raw[5] = {-1, -1, -1, -1, -1};
    board->getMyCards(raw);

    QVariantList newCards;
    for (int i = 0; i < 5; ++i)
        newCards.append(i < m_boardCardCount ? raw[i] : -1);

    if (newCards != m_boardCards) {
        m_boardCards = newCards;
        emit boardCardsChanged();
    }
}

void GameHandler::onNextRoundCleanGui()
{
    if (localGameCallbacksBlocked()) return;
    onDisableMyButtons();
    m_pot = 0;
    m_totalPot = 0;
    emit potChanged();
    emit totalPotChanged();
    m_minRaiseAmount = 0;
    m_maxRaiseAmount = 0;
    emit minRaiseAmountChanged();
    emit maxRaiseAmountChanged();
    m_boardCardCount = 0;
    m_boardCards = QVariantList{-1, -1, -1, -1, -1};
    emit boardCardCountChanged();
    emit boardCardsChanged();
    if (m_winnerSeatId != -1) {
        m_winnerSeatId = -1;
        emit winnerSeatIdChanged();
    }
    refreshPlayerData();
}

void GameHandler::onDealFlopCards()
{
    if (localGameCallbacksBlocked()) return;
    m_boardCardCount = 3;
    emit boardCardCountChanged();
    refreshBoardCards();
}

void GameHandler::onDealTurnCard()
{
    if (localGameCallbacksBlocked()) return;
    m_boardCardCount = 4;
    emit boardCardCountChanged();
    refreshBoardCards();
}

void GameHandler::onDealRiverCard()
{
    if (localGameCallbacksBlocked()) return;
    m_boardCardCount = 5;
    emit boardCardCountChanged();
    refreshBoardCards();
}

// ─── Q_INVOKABLE actions called from QML ────────────────────────────────────

void GameHandler::fold()
{
    if (!m_game || !m_session || !m_myTurn) return;

    auto hand = m_game->getCurrentHand();
    if (!hand) return;
    auto seats = hand->getSeatsList();
    if (!seats || seats->empty()) return;
    auto humanPlayer = seats->front();

    humanPlayer->setMyAction(PLAYER_ACTION_FOLD, true);
    humanPlayer->setMyTurn(false);
    hand->setPreviousPlayerID(0);

    doActionDone();
}

void GameHandler::call()
{
    if (!m_game || !m_session || !m_myTurn) return;

    auto hand = m_game->getCurrentHand();
    if (!hand) return;
    auto seats = hand->getSeatsList();
    if (!seats || seats->empty()) return;
    auto humanPlayer = seats->front();
    auto bero = hand->getCurrentBeRo();
    if (!bero) return;

    int highestSet = bero->getHighestSet();

    if (highestSet == 0) {
        // Check (no bet to call)
        humanPlayer->setMyAction(PLAYER_ACTION_CHECK, true);
    } else if (humanPlayer->getMyCash() + humanPlayer->getMySet() <= highestSet) {
        // All-in call
        humanPlayer->setMySet(humanPlayer->getMyCash());
        humanPlayer->setMyCash(0);
        humanPlayer->setMyAction(PLAYER_ACTION_ALLIN, true);
    } else {
        // Regular call
        humanPlayer->setMySet(highestSet - humanPlayer->getMySet());
        humanPlayer->setMyAction(PLAYER_ACTION_CALL, true);
    }

    humanPlayer->setMyTurn(false);
    hand->getBoard()->collectSets();
    hand->setPreviousPlayerID(0);

    doActionDone();
    onRefreshPot();
}

void GameHandler::raise(int amount)
{
    if (!m_game || !m_session || !m_myTurn) return;

    auto hand = m_game->getCurrentHand();
    if (!hand) return;
    auto seats = hand->getSeatsList();
    if (!seats || seats->empty()) return;
    auto humanPlayer = seats->front();
    auto bero = hand->getCurrentBeRo();
    if (!bero) return;

    // Default to minimum raise if no amount specified
    if (amount <= 0) {
        amount = m_minRaiseAmount;
    }
    if (amount <= 0) return; // nothing to raise

    int tempCash = humanPlayer->getMyCash();

    humanPlayer->setMySet(amount); // adds to set, deducts from cash

    if (amount >= tempCash) {
        // All-in
        humanPlayer->setMyCash(0);
        humanPlayer->setMyAction(PLAYER_ACTION_ALLIN, true);
        if (bero->getHighestSet() + bero->getMinimumRaise() > humanPlayer->getMySet()) {
            bero->setFullBetRule(true);
        }
        if (humanPlayer->getMySet() > bero->getHighestSet()) {
            bero->setMinimumRaise(humanPlayer->getMySet() - bero->getHighestSet());
            bero->setHighestSet(humanPlayer->getMySet());
            hand->setLastActionPlayerID(humanPlayer->getMyUniqueID());
        }
    } else {
        humanPlayer->setMyAction(PLAYER_ACTION_RAISE, true);
        bero->setMinimumRaise(humanPlayer->getMySet() - bero->getHighestSet());
        bero->setHighestSet(humanPlayer->getMySet());
        hand->setLastActionPlayerID(humanPlayer->getMyUniqueID());
    }

    humanPlayer->setMyTurn(false);
    hand->getBoard()->collectSets();
    hand->setPreviousPlayerID(0);

    doActionDone();
    onRefreshPot();
}

void GameHandler::allIn()
{
    if (!m_game || !m_session || !m_myTurn) return;

    auto hand = m_game->getCurrentHand();
    if (!hand) return;
    auto seats = hand->getSeatsList();
    if (!seats || seats->empty()) return;
    auto humanPlayer = seats->front();
    auto bero = hand->getCurrentBeRo();
    if (!bero) return;

    humanPlayer->setMySet(humanPlayer->getMyCash());
    humanPlayer->setMyCash(0);
    humanPlayer->setMyAction(PLAYER_ACTION_ALLIN, true);

    if (bero->getHighestSet() + bero->getMinimumRaise() > humanPlayer->getMySet()) {
        bero->setFullBetRule(true);
    }
    if (humanPlayer->getMySet() > bero->getHighestSet()) {
        bero->setMinimumRaise(humanPlayer->getMySet() - bero->getHighestSet());
        bero->setHighestSet(humanPlayer->getMySet());
        hand->setLastActionPlayerID(humanPlayer->getMyUniqueID());
    }

    humanPlayer->setMyTurn(false);
    hand->getBoard()->collectSets();
    hand->setPreviousPlayerID(0);

    doActionDone();
    onRefreshPot();
}

// ─── Local game startup ──────────────────────────────────────────────────────

void GameHandler::startLocalGame()
{
    if (!m_session) return;
    m_localGameExitRequested = false;

    GameData gameData;
    if (m_config) {
        gameData.maxNumberOfPlayers = m_config->readConfigInt("NumberOfPlayers");
        gameData.startMoney         = m_config->readConfigInt("StartCash");
        gameData.firstSmallBlind    = m_config->readConfigInt("FirstSmallBlind");
    }
    if (gameData.maxNumberOfPlayers < 2) gameData.maxNumberOfPlayers = 6;
    if (gameData.startMoney <= 0)        gameData.startMoney         = 1500;
    if (gameData.firstSmallBlind <= 0)   gameData.firstSmallBlind    = 10;

    // Defaults match Qt5 local game defaults
    gameData.raiseIntervalMode              = RAISE_ON_HANDNUMBER;
    gameData.raiseSmallBlindEveryHandsValue = 8;
    gameData.raiseMode                      = DOUBLE_BLINDS;
    gameData.guiSpeed                       = 4;
    gameData.delayBetweenHandsSec           = 7;
    gameData.playerActionTimeoutSec         = 20;

    StartData startData;
    startData.numberOfPlayers     = gameData.maxNumberOfPlayers;
    startData.startDealerPlayerId = 0;

    m_session->startLocalGame(gameData, startData);

    // Sync m_game so action methods and refreshes work immediately
    auto game = m_session->getCurrentGame();
    if (game) setGame(game);
}

void GameHandler::endLocalGame()
{
    if (!m_session) return;
    if (m_session->isNetworkClientRunning()) return;

    m_localGameExitRequested = true;
    m_game.reset();

    if (m_myTurn) {
        m_myTurn = false;
        emit myTurnChanged();
    }

    refreshPlayerData();
}

bool GameHandler::isLocalGameRunning() const
{
    if (m_localGameExitRequested) return false;
    if (!m_session) return false;
    if (m_session->isNetworkClientRunning()) return false;
    if (m_game) return true;
    return static_cast<bool>(m_session->getCurrentGame());
}

// ─── Game-loop advance slots (called via QMetaObject from QmlGuiInterface) ───

void GameHandler::onRunBeRo()
{
    if (localGameCallbacksBlocked()) return;
    if (!m_game) return;
    auto hand = m_game->getCurrentHand();
    if (hand && hand->getCurrentBeRo())
        hand->getCurrentBeRo()->run();
}

void GameHandler::onNextPlayerBeRo()
{
    if (localGameCallbacksBlocked()) return;
    if (!m_game) return;
    auto hand = m_game->getCurrentHand();
    if (hand && hand->getCurrentBeRo())
        hand->getCurrentBeRo()->nextPlayer();
}

// Called after the board cards of a street have been dealt. In an all-in
// condition there is no more betting (the running-player list is empty), so
// calling BeRo::run() would throw ERR_RUNNING_PLAYER_NOT_FOUND. Instead we
// advance straight to the next street/showdown via switchRounds(). In a normal
// (non-all-in) round we start the betting via BeRo::run().
void GameHandler::onAfterDealCards()
{
    if (localGameCallbacksBlocked()) return;
    if (!m_game) return;
    auto hand = m_game->getCurrentHand();
    if (!hand) return;

    if (hand->getAllInCondition()) {
        hand->switchRounds();
    } else if (hand->getCurrentBeRo()) {
        hand->getCurrentBeRo()->run();
    }
}

void GameHandler::onSwitchRounds()
{
    if (localGameCallbacksBlocked()) return;
    if (!m_game) return;
    auto hand = m_game->getCurrentHand();
    if (hand) hand->switchRounds();
}

void GameHandler::onPostRiverRunBeRo()
{
    if (localGameCallbacksBlocked()) return;
    if (!m_game) return;
    auto hand = m_game->getCurrentHand();
    if (hand && hand->getCurrentBeRo())
        hand->getCurrentBeRo()->postRiverRun();
}

void GameHandler::onShowdown()
{
    if (localGameCallbacksBlocked()) return;

    // Reveal showdown cards (getMyCardsFlip() is set after determinePlayerNeedToShowCards)
    refreshPlayerData();

    // Find the winner seat ID from the board (pot is already distributed)
    if (!m_game) return;
    auto hand = m_game->getCurrentHand();
    if (!hand) return;
    auto board = hand->getBoard();
    if (!board) return;

    std::list<unsigned> winners = board->getWinners();
    int newWinner = -1;

    auto seats = hand->getSeatsList();
    for (auto it = seats->begin(); it != seats->end(); ++it) {
        unsigned uid = (*it)->getMyUniqueID();
        bool isWinner = std::find(winners.begin(), winners.end(), uid) != winners.end();
        if (isWinner && (*it)->getLastMoneyWon() > 0) {
            newWinner = (*it)->getMyID();
            break;
        }
    }

    if (newWinner != m_winnerSeatId) {
        m_winnerSeatId = newWinner;
        emit winnerSeatIdChanged();
    }
}
