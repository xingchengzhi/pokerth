/*****************************************************************************
 * PokerTH - The open source texas holdem engine                             *
 * Copyright (C) 2006-2025 Felix Hammer, Florian Thauer, Lothar May          *
 *****************************************************************************/

#include "lobbyhandler.h"
#include "session.h"
#include "configfile.h"
#include "gamedata.h"

#include <QRegularExpression>

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

    const GameInfo &game = m_games.at(index.row());
    
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
    
    GameInfo game;
    game.id = gameId;
    game.name = gameName.isEmpty() ? QString("Game #%1").arg(gameId) : gameName;
    game.playerCount = 0;
    game.maxPlayers = 10;
    game.gameMode = 1; // netGameCreated
    game.isPrivate = false;
    m_games.append(game);
    m_gameIndexMap[gameId] = newRow;
    
    endInsertRows();

    ++m_openCount;
    emit openCountChanged();
}

void GameListModel::removeGame(unsigned gameId)
{
    if (!m_gameIndexMap.contains(gameId)) {
        qWarning() << "Game" << gameId << "not found";
        return;
    }
    
    int row = m_gameIndexMap[gameId];
    int oldMode = m_games[row].gameMode;
    beginRemoveRows(QModelIndex(), row, row);
    
    m_games.removeAt(row);
    m_gameIndexMap.remove(gameId);
    
    // Update indices
    for (int i = row; i < m_games.count(); ++i) {
        m_gameIndexMap[m_games[i].id] = i;
    }
    
    endRemoveRows();

    if (oldMode == 1) { // netGameCreated
        if (m_openCount > 0) { --m_openCount; emit openCountChanged(); }
    } else if (oldMode == 2) { // netGameStarted
        if (m_runningCount > 0) { --m_runningCount; emit runningCountChanged(); }
    }
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

    // Update counters
    bool oldOpen    = (oldMode == 1);
    bool oldRunning = (oldMode == 2);
    bool newOpen    = (mode == 1);
    bool newRunning = (mode == 2);

    if (oldOpen != newOpen) {
        m_openCount += newOpen ? 1 : -1;
        emit openCountChanged();
    }
    if (oldRunning != newRunning) {
        m_runningCount += newRunning ? 1 : -1;
        emit runningCountChanged();
    }
}

void GameListModel::clear()
{
    beginResetModel();
    m_games.clear();
    m_gameIndexMap.clear();
    endResetModel();

    if (m_runningCount != 0) { m_runningCount = 0; emit runningCountChanged(); }
    if (m_openCount != 0) { m_openCount = 0; emit openCountChanged(); }
}

// LobbyHandler implementation
LobbyHandler::LobbyHandler(QObject *parent)
    : QObject(parent)
    , m_session()
    , m_config(nullptr)
    , m_playerListModel(this)
    , m_playerListProxyModel(nullptr)
    , m_gameListModel(this)
    , m_myPlayerId(0)
    , m_playerListFilterMode(0)
    , m_playerListRevision(0)
{
    auto *proxy = new PlayerNickListSortFilterProxyModel(this);
    proxy->setSourceModel(&m_playerListModel);
    proxy->setDynamicSortFilter(true);
    proxy->sort(0, Qt::AscendingOrder);
    m_playerListProxyModel = proxy;
}

LobbyHandler::~LobbyHandler()
{
}

void LobbyHandler::setSession(boost::shared_ptr<Session> session)
{
    m_session = session;
    static_cast<PlayerNickListSortFilterProxyModel *>(m_playerListProxyModel)->setSession(m_session.get());
    static_cast<PlayerNickListSortFilterProxyModel *>(m_playerListProxyModel)->refresh();
    ++m_playerListRevision;
    emit playerListRevisionChanged();
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
}

void LobbyHandler::onLobbyPlayerLeft(unsigned playerId)
{
    m_playerListModel.removePlayer(playerId);
    static_cast<PlayerNickListSortFilterProxyModel *>(m_playerListProxyModel)->refresh();
    ++m_playerListRevision;
    emit playerListRevisionChanged();
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
    static_cast<PlayerNickListSortFilterProxyModel *>(m_playerListProxyModel)->refresh();
    emit gameContextChanged();
}

void LobbyHandler::onGameListRemove(unsigned gameId)
{
    m_gameListModel.removeGame(gameId);
    static_cast<PlayerNickListSortFilterProxyModel *>(m_playerListProxyModel)->refresh();
    emit gameContextChanged();
}

void LobbyHandler::onGameListUpdateMode(unsigned gameId, int mode)
{
    m_gameListModel.updateGameMode(gameId, mode);
    static_cast<PlayerNickListSortFilterProxyModel *>(m_playerListProxyModel)->refresh();
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
