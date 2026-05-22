/*****************************************************************************
 * PokerTH - The open source texas holdem engine                             *
 * Copyright (C) 2006-2025 Felix Hammer, Florian Thauer, Lothar May          *
 *****************************************************************************/

#include "networkgamehandler.h"

#include <session.h>
#include <configfile.h>
#include <gamedata.h>
#include <gui/generic/serverguiwrapper.h>

#include <list>

NetworkGameHandler::NetworkGameHandler(QObject *parent)
    : QObject(parent)
{
}

NetworkGameHandler::~NetworkGameHandler()
{
}

void NetworkGameHandler::shutdown()
{
    if (m_serverSession)
        m_serverSession->terminateNetworkServer();
    m_serverSession.reset();
    m_serverGui.reset();
    m_session.reset();
}

void NetworkGameHandler::createGame(int maxPlayers, int startCash, int firstSmallBlind,
                                    bool raiseByHands, int raiseEveryHands, int raiseEveryMinutes,
                                    bool doubleBlinds, int playerActionTimeout, int delayBetweenHands)
{
    if (!m_session || !m_config) {
        emit hostingFailed(tr("No session available."));
        return;
    }

    // Persist the chosen settings (the "saved" network game settings).
    m_config->writeConfigInt("NetNumberOfPlayers", maxPlayers);
    m_config->writeConfigInt("NetStartCash", startCash);
    m_config->writeConfigInt("NetFirstSmallBlind", firstSmallBlind);
    m_config->writeConfigInt("NetRaiseBlindsAtHands", raiseByHands ? 1 : 0);
    m_config->writeConfigInt("NetRaiseBlindsAtMinutes", raiseByHands ? 0 : 1);
    m_config->writeConfigInt("NetRaiseSmallBlindEveryHands", raiseEveryHands);
    m_config->writeConfigInt("NetRaiseSmallBlindEveryMinutes", raiseEveryMinutes);
    m_config->writeConfigInt("NetAlwaysDoubleBlinds", doubleBlinds ? 1 : 0);
    m_config->writeConfigInt("NetManualBlindsOrder", doubleBlinds ? 0 : 1);
    m_config->writeConfigInt("NetTimeOutPlayerAction", playerActionTimeout);
    m_config->writeConfigInt("NetDelayBetweenHands", delayBetweenHands);

    // Build the game data (mirrors startWindowImpl::callCreateNetworkGameDialog).
    GameData gameData;
    gameData.maxNumberOfPlayers = maxPlayers;
    gameData.startMoney = startCash;
    gameData.firstSmallBlind = firstSmallBlind;

    if (raiseByHands) {
        gameData.raiseIntervalMode = RAISE_ON_HANDNUMBER;
        gameData.raiseSmallBlindEveryHandsValue = raiseEveryHands;
    } else {
        gameData.raiseIntervalMode = RAISE_ON_MINUTES;
        gameData.raiseSmallBlindEveryMinutesValue = raiseEveryMinutes;
    }

    if (doubleBlinds) {
        gameData.raiseMode = DOUBLE_BLINDS;
    } else {
        // Manual blinds: use the saved blind list / after-mode (no inline editor).
        gameData.raiseMode = MANUAL_BLINDS_ORDER;
        gameData.manualBlindsList = m_config->readConfigIntList("NetManualBlindsList");
        if (m_config->readConfigInt("NetAfterMBAlwaysRaiseAbout")) {
            gameData.afterManualBlindsMode = AFTERMB_RAISE_ABOUT;
            gameData.afterMBAlwaysRaiseValue = m_config->readConfigInt("NetAfterMBAlwaysRaiseValue");
        } else if (m_config->readConfigInt("NetAfterMBStayAtLastBlind")) {
            gameData.afterManualBlindsMode = AFTERMB_STAY_AT_LAST_BLIND;
        } else {
            gameData.afterManualBlindsMode = AFTERMB_DOUBLE_BLINDS;
        }
    }

    gameData.guiSpeed = m_config->readConfigInt("GameSpeed");
    gameData.delayBetweenHandsSec = delayBetweenHands;
    gameData.playerActionTimeoutSec = playerActionTimeout;

    // Create the embedded server once (a pseudo GUI wrapper + its own Session),
    // re-used for subsequent hosted games.
    if (!m_serverGui) {
        m_serverGui.reset(new ServerGuiWrapper(m_config, m_session->getGui(), m_session->getGui()));
        boost::shared_ptr<Session> serverSession(new Session(m_serverGui.get(), m_config, 0));
        serverSession->init(m_session->getAvatarManager());
        m_serverGui->setSession(serverSession);
        m_serverSession = serverSession;
    }

    // Terminate any running client/server, then host and connect locally.
    m_session->terminateNetworkClient();
    m_serverSession->terminateNetworkServer();

    m_serverSession->startNetworkServer(false);
    m_session->startNetworkClientForLocalServer(gameData);

    emit hostingStarted();
}
