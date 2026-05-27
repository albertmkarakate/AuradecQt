#pragma once
#include <QObject>
#include <QString>
#include <QVariantMap>
#include <QNetworkAccessManager>
#include <QNetworkReply>

class GeminiClient : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)

public:
    explicit GeminiClient(QObject *parent = nullptr);

    bool busy() const { return m_reply != nullptr; }

    Q_INVOKABLE void enrichTrack(const QString &title,
                                 const QString &artist,
                                 const QString &album,
                                 const QString &apiKey);
    Q_INVOKABLE void fetchLyrics(const QString &title,
                                 const QString &artist,
                                 const QString &apiKey);
    Q_INVOKABLE void cancel();

signals:
    void metadataReady(const QVariantMap &metadata);
    void lyricsReady(const QString &lyrics);
    void fetchError(const QString &message);
    void busyChanged();

private slots:
    void onReplyFinished();

private:
    enum Mode { MetadataMode, LyricsMode };
    QNetworkAccessManager *m_nam;
    QNetworkReply         *m_reply = nullptr;
    Mode                   m_mode  = MetadataMode;
};
