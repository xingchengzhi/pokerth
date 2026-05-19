/*****************************************************************************
 * PokerTH - The open source texas holdem engine                             *
 * Copyright (C) 2006-2025 Felix Hammer, Florian Thauer, Lothar May          *
 *****************************************************************************/

#ifndef LOBBYHANDLER_H
#define LOBBYHANDLER_H

#include <QObject>
#include <QAbstractListModel>
#include <QAbstractItemModel>
#include <QSortFilterProxyModel>
#include <QString>
#include <QHash>
#include <QVariantMap>
#include <boost/shared_ptr.hpp>

class Session;
class ConfigFile;
struct GameInfo;

// Model for players in lobby
class PlayerListModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int count READ count NOTIFY countChanged)

public:
    enum PlayerRoles {
        PlayerIdRole = Qt::UserRole + 1,
        PlayerNameRole,
        IsAdminRole,
        CountryCodeRole,
        IsGuestRole
    };

    explicit PlayerListModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    int count() const { return m_players.count(); }

    void addPlayer(unsigned playerId, const QString &playerName, bool isAdmin = false, const QString &countryCode = QString(), bool isGuest = false);
    void removePlayer(unsigned playerId);
    void updatePlayer(unsigned playerId, const QString &newName);
    void updatePlayerInfo(unsigned playerId, const QString &playerName, bool isAdmin, const QString &countryCode = QString(), bool isGuest = false);
    void clear();

signals:
    void countChanged();

private:
    struct PlayerInfo {
        unsigned id;
        QString name;
        bool isAdmin;
        QString countryCode;
        bool isGuest;
    };
    
    QList<PlayerInfo> m_players;
    QHash<unsigned, int> m_playerIndexMap; // playerId -> index
};

// Model for games in lobby
class GameListModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int runningCount READ runningCount NOTIFY runningCountChanged)
    Q_PROPERTY(int openCount READ openCount NOTIFY openCountChanged)

public:
    enum GameRoles {
        GameIdRole = Qt::UserRole + 1,
        GameNameRole,
        PlayerCountRole,
        MaxPlayersRole,
        GameModeRole,
        IsPrivateRole,
        GameTypeRole,
        FirstSmallBlindRole,
        StartMoneyRole,
        RaiseIntervalModeRole,
        RaiseEveryHandsRole,
        RaiseEveryMinutesRole,
        RaiseModeRole,
        ManualBlindsTextRole,
        PlayerActionTimeoutRole,
        DelayBetweenHandsRole
    };

    explicit GameListModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    int runningCount() const { return m_runningCount; }
    int openCount() const { return m_openCount; }

    void addGame(unsigned gameId, const QString &gameName);
    void removeGame(unsigned gameId);
    void updateGameMode(unsigned gameId, int mode);
    void updateGameInfo(unsigned gameId, const ::GameInfo &info);
    void clear();

signals:
    void runningCountChanged();
    void openCountChanged();

private:
    struct GameEntry {
        unsigned id;
        QString name;
        int playerCount;
        int maxPlayers;
        int gameMode;
        bool isPrivate;
        int gameType;
        int firstSmallBlind;
        int startMoney;
        int raiseIntervalMode;
        int raiseEveryHands;
        int raiseEveryMinutes;
        int raiseMode;
        QString manualBlindsText;
        int playerActionTimeoutSec;
        int delayBetweenHandsSec;
    };
    
    void recomputeCounts();

    QList<GameEntry> m_games;
    QHash<unsigned, int> m_gameIndexMap; // gameId -> index
    int m_runningCount = 0;
    int m_openCount = 0;
};

// Main lobby handler
class LobbyHandler : public QObject
{
    Q_OBJECT
    Q_PROPERTY(PlayerListModel* playerListModel READ playerListModel CONSTANT)
    Q_PROPERTY(QAbstractItemModel* playerListProxyModel READ playerListProxyModel CONSTANT)
    Q_PROPERTY(GameListModel* gameListModel READ gameListModel CONSTANT)
    Q_PROPERTY(QAbstractItemModel* gameListProxyModel READ gameListProxyModel CONSTANT)
    Q_PROPERTY(QString myPlayerName READ myPlayerName NOTIFY myPlayerNameChanged)
    Q_PROPERTY(unsigned myPlayerId READ myPlayerId NOTIFY myPlayerIdChanged)
    Q_PROPERTY(bool isMyPlayerGuest READ isMyPlayerGuest NOTIFY gameContextChanged)
    Q_PROPERTY(bool isCurrentPlayerAdmin READ isCurrentPlayerAdmin NOTIFY isCurrentPlayerAdminChanged)
    Q_PROPERTY(bool canInviteFromCurrentGame READ canInviteFromCurrentGame NOTIFY gameContextChanged)
    Q_PROPERTY(int playerListFilterMode READ playerListFilterMode WRITE setPlayerListFilterMode NOTIFY playerListFilterModeChanged)
    Q_PROPERTY(int gameListFilterMode READ gameListFilterMode WRITE setGameListFilterMode NOTIFY gameListFilterModeChanged)
    Q_PROPERTY(int playerListRevision READ playerListRevision NOTIFY playerListRevisionChanged)
    Q_PROPERTY(int gameListRevision READ gameListRevision NOTIFY gameListRevisionChanged)
    Q_PROPERTY(int playerIgnoreListRevision READ playerIgnoreListRevision NOTIFY playerIgnoreListChanged)
    Q_PROPERTY(bool isInGame READ isInGame NOTIFY isInGameChanged)
    Q_PROPERTY(int currentGameId READ currentGameId NOTIFY currentGameIdChanged)

public:
    explicit LobbyHandler(QObject *parent = nullptr);
    virtual ~LobbyHandler();

    void setSession(boost::shared_ptr<Session> session);
    void setConfig(ConfigFile *config);

    PlayerListModel* playerListModel() { return &m_playerListModel; }
    QAbstractItemModel* playerListProxyModel() const { return m_playerListProxyModel; }
    GameListModel* gameListModel() { return &m_gameListModel; }
    QAbstractItemModel* gameListProxyModel() const { return m_gameListProxyModel; }
    
    QString myPlayerName() const { return m_myPlayerName; }
    unsigned myPlayerId() const { return m_myPlayerId; }
    bool isMyPlayerGuest() const;
    bool isCurrentPlayerAdmin() const { return m_isCurrentPlayerAdmin; }
    bool canInviteFromCurrentGame() const;
    bool isInGame() const { return m_isInGame; }
    int  currentGameId() const { return static_cast<int>(m_currentGameId); }
    Q_INVOKABLE QString currentGameName() const;
    int playerListFilterMode() const { return m_playerListFilterMode; }
    int gameListFilterMode() const { return m_gameListFilterMode; }
    int playerListRevision() const { return m_playerListRevision; }
    int gameListRevision() const { return m_gameListRevision; }
    int playerIgnoreListRevision() const { return m_playerIgnoreListRevision; }
    void setPlayerListFilterMode(int mode);
    void setGameListFilterMode(int mode);
    
    void setMyPlayerInfo(unsigned playerId, const QString &playerName);

public slots:
    // Player management
    void onLobbyPlayerJoined(unsigned playerId, const QString &playerName);
    void onLobbyPlayerLeft(unsigned playerId);
    void updatePlayerName(unsigned playerId, const QString &playerName, bool isAdmin);
    
    // Game management
    void onGameListNew(unsigned gameId, const QString &gameName);
    void onGameListRemove(unsigned gameId);
    void onGameListUpdateMode(unsigned gameId, int mode);
    void onGameListChanged(unsigned gameId);
    
    // Chat
    void sendChatMessage(const QString &message);
    void onLobbyChatMessage(const QString &playerName, const QString &message);
    void onPrivateChatMessage(const QString &playerName, const QString &message);
    
    // Actions from QML
    Q_INVOKABLE void joinGame(unsigned gameId, const QString &password);
    Q_INVOKABLE void leaveGame();
    void onSelfJoinedGame();
    void onGameStarted();
    void onRemovedFromGame();
    
    // Player actions (QML-invokable)
    Q_INVOKABLE void createGame(const QString &name, const QString &password,
                               int gameType, bool allowSpectators, int maxPlayers,
                               int startCash, int firstSmallBlind,
                               int raiseIntervalMode, int raiseEveryHands,
                               int raiseEveryMinutes, int raiseMode,
                               int playerActionTimeout, int delayBetweenHands);
    Q_INVOKABLE void kickPlayer(unsigned playerId);
    Q_INVOKABLE void invitePlayer(unsigned playerId);
    Q_INVOKABLE void adminBanPlayer(unsigned playerId);
    Q_INVOKABLE void sendPrivateMessage(unsigned targetPlayerId, const QString &message);
    Q_INVOKABLE QVariantMap playerListEntry(int row) const;
    Q_INVOKABLE QVariantList gamePlayersInGame(unsigned gameId) const;
    Q_INVOKABLE bool canJoinGame(unsigned gameId) const;
    Q_INVOKABLE bool openExternalUrl(const QString &url) const;
    Q_INVOKABLE bool isPlayerIgnored(unsigned playerId) const;
    Q_INVOKABLE void ignorePlayer(unsigned playerId);
    Q_INVOKABLE void unignorePlayer(unsigned playerId);
    Q_INVOKABLE void showPlayerStats(unsigned playerId);
    Q_INVOKABLE QString gameTypeText(int gameType) const;
    Q_INVOKABLE QString gameStatusText(int gameMode, int playerCount, int maxPlayers) const;
    Q_INVOKABLE void startGame(bool fillWithCpu = false);
    Q_INVOKABLE QVariantMap currentGameInfo() const;

signals:
    void chatLineReady(const QString &formattedLine);
    void lobbyChatMentionDetected();
    void gameCreated(unsigned gameId);
    void gameJoined(unsigned gameId);
    void selfJoinedGame();
    void gameStarted();
    void removedFromGame();
    void errorOccurred(const QString &errorMessage);
    void myPlayerNameChanged();
    void myPlayerIdChanged();
    void isCurrentPlayerAdminChanged();
    void gameContextChanged();
    void playerListFilterModeChanged();
    void gameListFilterModeChanged();
    void playerListRevisionChanged();
    void gameListRevisionChanged();
    void playerIgnoreListChanged();
    void isInGameChanged();
    void currentGameIdChanged();

private:
    boost::shared_ptr<Session> m_session;
    ConfigFile *m_config;
    
    PlayerListModel m_playerListModel;
    QSortFilterProxyModel *m_playerListProxyModel;
    GameListModel m_gameListModel;
    QSortFilterProxyModel *m_gameListProxyModel;
    
    QString m_myPlayerName;
    unsigned m_myPlayerId;
    bool m_isCurrentPlayerAdmin;
    bool m_isInGame = false;
    unsigned m_currentGameId = 0;
    int m_playerListFilterMode;
    int m_gameListFilterMode;
    int m_playerListRevision;
    int m_gameListRevision;
    int m_playerIgnoreListRevision;

    void refreshGameInfo(unsigned gameId);
    QString resolvedPlayerName(unsigned playerId) const;
    unsigned parsePrivateMessageTarget(QString &chatText) const;
};

#endif // LOBBYHANDLER_H
