#pragma once
#include <QObject>
#include <QNetworkAccessManager>
#include <QTimer>
#include <QVariantList>

class MusicBrainzClient : public QObject {
    Q_OBJECT
public:
    explicit MusicBrainzClient(QObject *parent = nullptr);

    Q_INVOKABLE void search(const QString &title,
                            const QString &artist = {},
                            const QString &album  = {});

signals:
    void resultsReady(const QVariantList &results);
    void searchError(const QString &message);

private slots:
    void onSearchFinished();

private:
    QNetworkAccessManager *m_nam;
    QTimer                *m_rateLimit;
    QString                m_pendingTitle;
    QString                m_pendingArtist;
    QString                m_pendingAlbum;
    bool                   m_pending = false;

    void doSearch(const QString &title, const QString &artist, const QString &album);
};
