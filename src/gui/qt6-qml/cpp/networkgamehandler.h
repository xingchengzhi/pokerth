/*****************************************************************************
 * PokerTH - The open source texas holdem engine                             *
 * Copyright (C) 2006-2025 Felix Hammer, Florian Thauer, Lothar May          *
 *****************************************************************************/

#ifndef NETWORKGAMEHANDLER_H
#define NETWORKGAMEHANDLER_H

#include <QObject>
#include <boost/shared_ptr.hpp>

class ConfigFile;
class Session;
class ServerGuiWrapper;

// Backs the QML "Netzwerkspiel erstellen" page (NetworkGameCreatePage.qml).
// Mirrors the Qt-Widgets "create network game" flow: it spins up an embedded
// (non-dedicated) network server in a second Session and connects the local
// client to it, which auto-hosts the configured game and drops the host into
// the existing lobby/wait flow (ServerConnection.showLobby → LobbyPage →
// GameWaitPage).
class NetworkGameHandler : public QObject
{
    Q_OBJECT

public:
    explicit NetworkGameHandler(QObject *parent = nullptr);
    ~NetworkGameHandler() override;

    void setSession(boost::shared_ptr<Session> session) { m_session = session; }
    void setConfig(ConfigFile *config) { m_config = config; }
    // Terminate the embedded server and release all session references. Must be
    // called during app shutdown before the client session/GUI are destroyed.
    void shutdown();

    // Start hosting a network game with the given rules. Persists the settings
    // (Net* config keys) and starts server + local-server client.
    Q_INVOKABLE void createGame(int maxPlayers, int startCash, int firstSmallBlind,
                                bool raiseByHands, int raiseEveryHands, int raiseEveryMinutes,
                                bool doubleBlinds, int playerActionTimeout, int delayBetweenHands);

signals:
    void hostingStarted();
    void hostingFailed(const QString &message);

private:
    boost::shared_ptr<Session> m_session;          // the client session
    boost::shared_ptr<ServerGuiWrapper> m_serverGui;
    boost::shared_ptr<Session> m_serverSession;     // the embedded server session
    ConfigFile *m_config = nullptr;
};

#endif // NETWORKGAMEHANDLER_H
