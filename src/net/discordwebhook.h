#ifndef _DISCORDWEBHOOK_H_
#define _DISCORDWEBHOOK_H_

#include <QNetworkAccessManager>
#include <string>

class DiscordWebhookSender : public QObject
{
	Q_OBJECT
public:
	explicit DiscordWebhookSender(const std::string &webhookUrl, QObject *parent = nullptr);

	void SendChatMessage(const std::string &playerName, const std::string &message);
	bool IsEnabled() const;

private:
	QNetworkAccessManager m_networkManager;
	std::string m_webhookUrl;
};

#endif
