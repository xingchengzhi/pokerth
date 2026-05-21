/*****************************************************************************
 * PokerTH - The open source texas holdem engine                             *
 * Copyright (C) 2006-2025 Felix Hammer, Florian Thauer, Lothar May          *
 *****************************************************************************/

#include "qmlguiinterface.h"
#include "serverconnectionhandler.h"
#include "lobbyhandler.h"
#include "gamehandler.h"
#include "configfile.h"
#include <session.h>
#include <game.h>
#include <gamedata.h>
#include <game_defs.h>
#include <QString>
#include <QMetaObject>
#include <QTimer>

QmlGuiInterface::QmlGuiInterface(ConfigFile *config, ServerConnectionHandler *handler, LobbyHandler *lobbyHandler)
    : m_config(config), m_session(), m_handler(handler), m_lobbyHandler(lobbyHandler)
{
}

QmlGuiInterface::~QmlGuiInterface()
{
}

void QmlGuiInterface::SignalNetClientConnect(int actionID)
{
    if (m_handler) {
        QMetaObject::invokeMethod(m_handler, [this, actionID]() {
            m_handler->onNetClientConnect(actionID);
        }, Qt::QueuedConnection);
    }

    if (m_lobbyHandler && m_session && actionID == 1) {
        QMetaObject::invokeMethod(m_lobbyHandler, [this]() {
            // New client initialization: force lobby model reset/sync.
            m_lobbyHandler->setSession(m_session);
        }, Qt::QueuedConnection);
    }
}

void QmlGuiInterface::SignalNetClientError(int errorID, int osErrorID)
{
    if (m_handler) {
        QMetaObject::invokeMethod(m_handler, [this, errorID, osErrorID]() {
            m_handler->onNetClientError(errorID, osErrorID);
        }, Qt::QueuedConnection);
    }
}

void QmlGuiInterface::SignalNetClientLoginShow()
{
    if (m_handler) {
        QMetaObject::invokeMethod(m_handler, [this]() {
            m_handler->onNetClientLoginShow();
        }, Qt::QueuedConnection);
    }
}

void QmlGuiInterface::SignalNetClientGameListNew(unsigned gameId)
{
    if (m_lobbyHandler && m_session) {
        GameInfo gameInfo = m_session->getClientGameInfo(gameId);
        QString gameName = QString::fromStdString(gameInfo.name);
        QMetaObject::invokeMethod(m_lobbyHandler, "onGameListNew", Qt::QueuedConnection,
                                  Q_ARG(unsigned, gameId), Q_ARG(QString, gameName));
    }
}

void QmlGuiInterface::SignalNetClientGameListRemove(unsigned gameId)
{
    if (m_lobbyHandler) {
        QMetaObject::invokeMethod(m_lobbyHandler, "onGameListRemove", Qt::QueuedConnection,
                                  Q_ARG(unsigned, gameId));
    }
}

void QmlGuiInterface::SignalNetClientGameListUpdateMode(unsigned gameId, GameMode mode)
{
    if (m_lobbyHandler) {
        QMetaObject::invokeMethod(m_lobbyHandler, "onGameListUpdateMode", Qt::QueuedConnection,
                                  Q_ARG(unsigned, gameId), Q_ARG(int, static_cast<int>(mode)));
    }
}

void QmlGuiInterface::SignalNetClientGameListUpdateAdmin(unsigned gameId, unsigned adminPlayerId)
{
    Q_UNUSED(adminPlayerId)
    if (m_lobbyHandler) {
        QMetaObject::invokeMethod(m_lobbyHandler, "onGameListChanged", Qt::QueuedConnection,
                                  Q_ARG(unsigned, gameId));
    }
}

void QmlGuiInterface::SignalNetClientGameListPlayerJoined(unsigned gameId, unsigned playerId)
{
    Q_UNUSED(playerId)
    if (m_lobbyHandler) {
        QMetaObject::invokeMethod(m_lobbyHandler, "onGameListChanged", Qt::QueuedConnection,
                                  Q_ARG(unsigned, gameId));
    }
}

void QmlGuiInterface::SignalNetClientGameListPlayerLeft(unsigned gameId, unsigned playerId)
{
    Q_UNUSED(playerId)
    if (m_lobbyHandler) {
        QMetaObject::invokeMethod(m_lobbyHandler, "onGameListChanged", Qt::QueuedConnection,
                                  Q_ARG(unsigned, gameId));
    }
}

void QmlGuiInterface::SignalNetClientGameListSpectatorJoined(unsigned gameId, unsigned playerId)
{
    Q_UNUSED(playerId)
    if (m_lobbyHandler) {
        QMetaObject::invokeMethod(m_lobbyHandler, "onGameListChanged", Qt::QueuedConnection,
                                  Q_ARG(unsigned, gameId));
    }
}

void QmlGuiInterface::SignalNetClientGameListSpectatorLeft(unsigned gameId, unsigned playerId)
{
    Q_UNUSED(playerId)
    if (m_lobbyHandler) {
        QMetaObject::invokeMethod(m_lobbyHandler, "onGameListChanged", Qt::QueuedConnection,
                                  Q_ARG(unsigned, gameId));
    }
}

void QmlGuiInterface::SignalNetClientLobbyChatMsg(const std::string &playerName, const std::string &msg)
{
    if (m_lobbyHandler) {
        const QString qPlayerName = QString::fromStdString(playerName);
        const QString qMsg = QString::fromStdString(msg);
        QMetaObject::invokeMethod(m_lobbyHandler, "onLobbyChatMessage", Qt::QueuedConnection,
                                  Q_ARG(QString, qPlayerName), Q_ARG(QString, qMsg));
    }
}

void QmlGuiInterface::SignalNetClientPrivateChatMsg(const std::string &playerName, const std::string &msg)
{
    if (m_lobbyHandler) {
        QMetaObject::invokeMethod(m_lobbyHandler, "onPrivateChatMessage", Qt::QueuedConnection,
                                  Q_ARG(QString, QString::fromStdString(playerName)),
                                  Q_ARG(QString, QString::fromStdString(msg)));
    }
}

void QmlGuiInterface::SignalLobbyPlayerJoined(unsigned playerId, const std::string &nickName)
{
    if (m_lobbyHandler) {
        const QString qNickName = QString::fromStdString(nickName);
        QMetaObject::invokeMethod(m_lobbyHandler, "onLobbyPlayerJoined", Qt::QueuedConnection,
                                  Q_ARG(unsigned, playerId), Q_ARG(QString, qNickName));
    }
}

void QmlGuiInterface::SignalLobbyPlayerLeft(unsigned playerId)
{
    if (m_lobbyHandler) {
        QMetaObject::invokeMethod(m_lobbyHandler, "onLobbyPlayerLeft", Qt::QueuedConnection,
                                  Q_ARG(unsigned, playerId));
    }
}

void QmlGuiInterface::SignalNetClientPlayerJoined(unsigned playerId, const std::string &playerName, bool isGameAdmin)
{
    if (m_lobbyHandler) {
        const QString qPlayerName = QString::fromStdString(playerName);
        QMetaObject::invokeMethod(m_lobbyHandler, "updatePlayerName", Qt::QueuedConnection,
                                  Q_ARG(unsigned, playerId), Q_ARG(QString, qPlayerName), Q_ARG(bool, isGameAdmin));
    }
}

void QmlGuiInterface::SignalNetClientPlayerChanged(unsigned playerId, const std::string &newPlayerName)
{
    if (m_lobbyHandler) {
        const QString qPlayerName = QString::fromStdString(newPlayerName);
        // Read isAdmin from session — same as Qt widgets GUI does on demand
        const bool isAdmin = m_session ? m_session->getClientPlayerInfo(playerId).isAdmin : false;
        QMetaObject::invokeMethod(m_lobbyHandler, "updatePlayerName", Qt::QueuedConnection,
                                  Q_ARG(unsigned, playerId), Q_ARG(QString, qPlayerName), Q_ARG(bool, isAdmin));
    }
}

void QmlGuiInterface::SignalNetClientSelfJoined(unsigned playerId, const std::string &playerName, bool isGameAdmin)
{
    Q_UNUSED(isGameAdmin)
    if (m_lobbyHandler) {
        const QString qPlayerName = QString::fromStdString(playerName);
        QMetaObject::invokeMethod(m_lobbyHandler, [this, playerId, qPlayerName]() {
            m_lobbyHandler->setMyPlayerInfo(playerId, qPlayerName);
            m_lobbyHandler->onSelfJoinedGame();
        }, Qt::QueuedConnection);
    }
}

void QmlGuiInterface::SignalNetClientRemovedFromGame(int notificationId)
{
    Q_UNUSED(notificationId)
    if (m_lobbyHandler) {
        QMetaObject::invokeMethod(m_lobbyHandler, [this]() {
            m_lobbyHandler->onRemovedFromGame();
        }, Qt::QueuedConnection);
    }
}

void QmlGuiInterface::SignalNetClientGameStart(boost::shared_ptr<Game> game)
{
    if (m_lobbyHandler) {
        QMetaObject::invokeMethod(m_lobbyHandler, [this]() {
            m_lobbyHandler->onGameStarted();
        }, Qt::QueuedConnection);
    }
    if (m_gameHandler && game) {
        QMetaObject::invokeMethod(m_gameHandler, [this, game]() {
            m_gameHandler->setGame(game);
        }, Qt::QueuedConnection);
    }
}

void QmlGuiInterface::refreshSet() const
{
    if (m_gameHandler) {
        QMetaObject::invokeMethod(m_gameHandler, "onRefreshSet", Qt::QueuedConnection);
    }
}

void QmlGuiInterface::refreshCash() const
{
    if (m_gameHandler) {
        QMetaObject::invokeMethod(m_gameHandler, "onRefreshCash", Qt::QueuedConnection);
    }
}

void QmlGuiInterface::refreshPlayerName() const
{
    if (m_gameHandler) {
        QMetaObject::invokeMethod(m_gameHandler, "onRefreshPlayerName", Qt::QueuedConnection);
    }
}

void QmlGuiInterface::refreshPot() const
{
    if (m_gameHandler) {
        QMetaObject::invokeMethod(m_gameHandler, "onRefreshPot", Qt::QueuedConnection);
    }
}

void QmlGuiInterface::refreshGameLabels(GameState state) const
{
    if (m_gameHandler) {
        int stateInt = static_cast<int>(state);
        QMetaObject::invokeMethod(m_gameHandler, "onRefreshGameLabels", Qt::QueuedConnection,
                                  Q_ARG(int, stateInt));
    }
}

void QmlGuiInterface::meInAction()
{
    if (m_gameHandler) {
        QMetaObject::invokeMethod(m_gameHandler, "onMeInAction", Qt::QueuedConnection);
    }
}

void QmlGuiInterface::disableMyButtons()
{
    if (m_gameHandler) {
        QMetaObject::invokeMethod(m_gameHandler, "onDisableMyButtons", Qt::QueuedConnection);
    }
}

void QmlGuiInterface::nextRoundCleanGui()
{
    if (m_gameHandler) {
        QMetaObject::invokeMethod(m_gameHandler, "onNextRoundCleanGui", Qt::QueuedConnection);
    }
}

void QmlGuiInterface::refreshAll() const
{
    if (m_gameHandler) {
        QMetaObject::invokeMethod(m_gameHandler, "onRefreshPlayerName", Qt::QueuedConnection);
        QMetaObject::invokeMethod(m_gameHandler, "onRefreshCash",       Qt::QueuedConnection);
        QMetaObject::invokeMethod(m_gameHandler, "onRefreshSet",        Qt::QueuedConnection);
        QMetaObject::invokeMethod(m_gameHandler, "onRefreshPot",        Qt::QueuedConnection);
    }
}

void QmlGuiInterface::dealFlopCards()
{
    if (m_gameHandler) QMetaObject::invokeMethod(m_gameHandler, "onDealFlopCards", Qt::QueuedConnection);
}

void QmlGuiInterface::dealTurnCard()
{
    if (m_gameHandler) QMetaObject::invokeMethod(m_gameHandler, "onDealTurnCard", Qt::QueuedConnection);
}

void QmlGuiInterface::dealRiverCard()
{
    if (m_gameHandler) QMetaObject::invokeMethod(m_gameHandler, "onDealRiverCard", Qt::QueuedConnection);
}

// ─── Local game-loop animation callbacks ─────────────────────────────────────
// These replicate the timer-driven animation chain in the Qt5 gametableimpl.
// Each "Animation1" starts a new betting round (calls BeRo::run()).
// "beRoAnimation2" advances to the next CPU player (calls BeRo::nextPlayer()).
// "nextPlayerAnimation" processes the end of an action (calls switchRounds()).
// "postRiverAnimation1" distributes the pot; "postRiverRunAnimation1" starts the next hand.

void QmlGuiInterface::nextPlayerAnimation()
{
    // After a player acts: trigger switchRounds() with a short delay
    if (!m_gameHandler) return;
    GameHandler *gh = m_gameHandler;
    QTimer::singleShot(300, gh, [gh]() {
        QMetaObject::invokeMethod(gh, "onSwitchRounds", Qt::DirectConnection);
    });
}

void QmlGuiInterface::beRoAnimation2(int /*myBeRoID*/)
{
    // CPU player's turn: advance to nextPlayer() with a short delay
    if (!m_gameHandler) return;
    GameHandler *gh = m_gameHandler;
    QTimer::singleShot(300, gh, [gh]() {
        QMetaObject::invokeMethod(gh, "onNextPlayerBeRo", Qt::DirectConnection);
    });
}

void QmlGuiInterface::preflopAnimation1()
{
    // Start of preflop betting: call BeRo::run()
    if (!m_gameHandler) return;
    GameHandler *gh = m_gameHandler;
    QTimer::singleShot(300, gh, [gh]() {
        QMetaObject::invokeMethod(gh, "onRunBeRo", Qt::DirectConnection);
    });
}

void QmlGuiInterface::flopAnimation1()
{
    if (!m_gameHandler) return;
    GameHandler *gh = m_gameHandler;
    QTimer::singleShot(300, gh, [gh]() {
        QMetaObject::invokeMethod(gh, "onRunBeRo", Qt::DirectConnection);
    });
}

void QmlGuiInterface::turnAnimation1()
{
    if (!m_gameHandler) return;
    GameHandler *gh = m_gameHandler;
    QTimer::singleShot(300, gh, [gh]() {
        QMetaObject::invokeMethod(gh, "onRunBeRo", Qt::DirectConnection);
    });
}

void QmlGuiInterface::riverAnimation1()
{
    if (!m_gameHandler) return;
    GameHandler *gh = m_gameHandler;
    QTimer::singleShot(300, gh, [gh]() {
        QMetaObject::invokeMethod(gh, "onRunBeRo", Qt::DirectConnection);
    });
}

void QmlGuiInterface::postRiverAnimation1()
{
    // Show-down: call BeRo::postRiverRun() which distributes the pot
    if (!m_gameHandler) return;
    GameHandler *gh = m_gameHandler;
    QTimer::singleShot(500, gh, [gh]() {
        QMetaObject::invokeMethod(gh, "onPostRiverRunBeRo", Qt::DirectConnection);
    });
}

void QmlGuiInterface::postRiverRunAnimation1()
{
    // Pot already distributed. Show showdown: reveal cards + mark winner.
    if (!m_gameHandler) return;
    GameHandler *gh = m_gameHandler;
    boost::shared_ptr<Session> session = m_session;

    QMetaObject::invokeMethod(gh, "onShowdown", Qt::QueuedConnection);

    // Start the next hand after a pause so the user can see the result
    QTimer::singleShot(3000, gh, [gh, session]() {
        QMetaObject::invokeMethod(gh, "onNextRoundCleanGui", Qt::DirectConnection);
        if (session) {
            auto game = session->getCurrentGame();
            if (game) {
                game->initHand();
                game->startHand();
            }
        }
    });
}

void QmlGuiInterface::dealBeRoCards(int beRoID)
{
    // Called by BeRo::run() on its first invocation to "show" dealing.
    // Reveal board cards for Flop/Turn/River, then trigger the second BeRo::run().
    if (!m_gameHandler) return;
    GameHandler *gh = m_gameHandler;

    // Reveal the appropriate board cards
    if (beRoID == GAME_STATE_FLOP) {
        QMetaObject::invokeMethod(gh, "onDealFlopCards", Qt::QueuedConnection);
    } else if (beRoID == GAME_STATE_TURN) {
        QMetaObject::invokeMethod(gh, "onDealTurnCard", Qt::QueuedConnection);
    } else if (beRoID == GAME_STATE_RIVER) {
        QMetaObject::invokeMethod(gh, "onDealRiverCard", Qt::QueuedConnection);
    }

    // Schedule the second BeRo::run() call after the card reveal
    QTimer::singleShot(300, gh, [gh]() {
        QMetaObject::invokeMethod(gh, "onRunBeRo", Qt::DirectConnection);
    });
}
