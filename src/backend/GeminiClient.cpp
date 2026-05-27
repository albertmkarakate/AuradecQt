#include "GeminiClient.h"
#include <QNetworkRequest>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QUrl>
#include <QDebug>

static const char kEndpoint[] =
    "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent";

GeminiClient::GeminiClient(QObject *parent)
    : QObject(parent), m_nam(new QNetworkAccessManager(this)) {}

void GeminiClient::cancel() {
    if (!m_reply) return;
    auto *reply = m_reply;
    m_reply = nullptr;
    reply->abort();
    reply->deleteLater();
    emit busyChanged();
}

void GeminiClient::fetchLyrics(const QString &title,
                                const QString &artist,
                                const QString &apiKey)
{
    if (apiKey.trimmed().isEmpty()) {
        emit fetchError("No Gemini API key configured.");
        return;
    }
    cancel();
    m_mode = LyricsMode;

    QString prompt = QString(
        "Write the full lyrics for \"%1\" by %2. "
        "Return ONLY the lyrics as plain text — no explanation, no markdown, no attribution. "
        "If you do not know the lyrics, respond with exactly: UNKNOWN"
    ).arg(title, artist);

    QJsonObject part; part["text"] = prompt;
    QJsonObject content; content["parts"] = QJsonArray{ part };
    QJsonObject body; body["contents"] = QJsonArray{ content };

    QUrl url(QString("%1?key=%2").arg(kEndpoint, apiKey.trimmed()));
    QNetworkRequest req(url);
    req.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");

    m_reply = m_nam->post(req, QJsonDocument(body).toJson(QJsonDocument::Compact));
    connect(m_reply, &QNetworkReply::finished, this, &GeminiClient::onReplyFinished);
    emit busyChanged();
}

void GeminiClient::enrichTrack(const QString &title,
                                const QString &artist,
                                const QString &album,
                                const QString &apiKey)
{
    if (apiKey.trimmed().isEmpty()) {
        emit fetchError("No Gemini API key configured.");
        return;
    }
    cancel();
    m_mode = MetadataMode;

    QString prompt = QString(
        "You are a music metadata expert. Given the following track info, "
        "return ONLY a valid JSON object with these fields: "
        "title (string), artist (string), album (string), genre (string), year (integer, 4 digits). "
        "Correct any obvious errors. If a field is unknown, keep the original value. "
        "Do not include any explanation or markdown.\n\n"
        "Title: %1\nArtist: %2\nAlbum: %3"
    ).arg(title, artist, album);

    QJsonObject part; part["text"] = prompt;
    QJsonObject content; content["parts"] = QJsonArray{ part };
    QJsonObject body; body["contents"] = QJsonArray{ content };

    QUrl url(QString("%1?key=%2").arg(kEndpoint, apiKey.trimmed()));
    QNetworkRequest req(url);
    req.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");

    m_reply = m_nam->post(req, QJsonDocument(body).toJson(QJsonDocument::Compact));
    connect(m_reply, &QNetworkReply::finished, this, &GeminiClient::onReplyFinished);
    emit busyChanged();
}

void GeminiClient::onReplyFinished() {
    auto *reply = qobject_cast<QNetworkReply*>(sender());
    if (!reply) return;
    if (m_reply == reply) { m_reply = nullptr; emit busyChanged(); }
    reply->deleteLater();

    if (reply->error() != QNetworkReply::NoError) {
        emit fetchError(reply->errorString());
        return;
    }

    QByteArray raw = reply->readAll();
    QJsonDocument doc = QJsonDocument::fromJson(raw);
    if (doc.isNull()) {
        emit fetchError("Invalid JSON response from Gemini.");
        return;
    }

    // Extract text from candidates[0].content.parts[0].text
    QJsonArray candidates = doc.object()["candidates"].toArray();
    if (candidates.isEmpty()) {
        QJsonObject err = doc.object()["error"].toObject();
        QString msg = err.value("message").toString();
        emit fetchError(msg.isEmpty() ? "Gemini returned no candidates." : msg);
        return;
    }

    QString text = candidates[0].toObject()["content"]
                              .toObject()["parts"]
                              .toArray()[0]
                              .toObject()["text"]
                              .toString()
                              .trimmed();

    if (m_mode == LyricsMode) {
        if (text == "UNKNOWN" || text.isEmpty())
            emit fetchError("Gemini could not find lyrics for this track.");
        else
            emit lyricsReady(text);
        return;
    }

    // Strip markdown code fences if present
    if (text.startsWith("```")) {
        int start = text.indexOf('\n') + 1;
        int end = text.lastIndexOf("```");
        if (end > start) text = text.mid(start, end - start).trimmed();
    }

    QJsonDocument parsed = QJsonDocument::fromJson(text.toUtf8());
    if (parsed.isNull() || !parsed.isObject()) {
        emit fetchError("Gemini response was not valid JSON: " + text.left(200));
        return;
    }

    QVariantMap meta;
    QJsonObject obj = parsed.object();
    if (obj.contains("title"))  meta["title"]  = obj["title"].toString();
    if (obj.contains("artist")) meta["artist"] = obj["artist"].toString();
    if (obj.contains("album"))  meta["album"]  = obj["album"].toString();
    if (obj.contains("genre"))  meta["genre"]  = obj["genre"].toString();
    if (obj.contains("year"))   meta["year"]   = obj["year"].toInt();

    emit metadataReady(meta);
}
