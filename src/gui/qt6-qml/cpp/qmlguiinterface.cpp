/*****************************************************************************
 * PokerTH - The open source texas holdem engine                             *
 * Copyright (C) 2006-2025 Felix Hammer, Florian Thauer, Lothar May          *
 *****************************************************************************/

#include "qmlguiinterface.h"
#include "serverconnectionhandler.h"
#include "lobbyhandler.h"
#include "configfile.h"
#include <session.h>
#include <gamedata.h>
#include <QString>
#include <QMetaObject>

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
