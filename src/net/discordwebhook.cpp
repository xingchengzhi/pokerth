#include <net/discordwebhook.h>
#include <core/loghelper.h>

#include <QNetworkRequest>
#include <QNetworkReply>
#include <QJsonDocument>
#include <QJsonObject>
#include <QUrl>

DiscordWebhookSender::DiscordWebhookSender(const std::string &webhookUrl, QObject *parent)
	: QObject(parent), m_webhookUrl(webhookUrl)
{
}

bool
DiscordWebhookSender::IsEnabled() const
{
	return !m_webhookUrl.empty();
}

void
DiscordWebhookSender::SendChatMessage(const std::string &playerName, const std::string &message)
{
	if (!IsEnabled()) {
		return;
	}

	QJsonObject json;
	json["content"] = QString::fromStdString("**" + playerName + ":** " + message);

	QNetworkRequest request(QUrl(QString::fromStdString(m_webhookUrl)));
	request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");

	QNetworkReply *reply = m_networkManager.post(request, QJsonDocument(json).toJson(QJsonDocument::Compact));

	connect(reply, &QNetworkReply::finished, reply, [reply]() {
		if (reply->error() != QNetworkReply::NoError) {
			LOG_ERROR("Discord webhook failed: " << reply->errorString().toStdString());
		}
		reply->deleteLater();
	});
}
