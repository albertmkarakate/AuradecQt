#include "ArtworkProvider.h"
#include <QMutexLocker>

ArtworkProvider::ArtworkProvider(TrackDatabase *db)
    : QQuickImageProvider(QQuickImageProvider::Image), m_db(db) {}

void ArtworkProvider::invalidate(int trackId) {
    QMutexLocker lock(&m_mutex);
    m_cache.remove(trackId);
}

QImage ArtworkProvider::requestImage(const QString &id, QSize *size, const QSize &requestedSize) {
    bool ok;
    int trackId = id.toInt(&ok);
    if (!ok || trackId < 0) return {};

    {
        QMutexLocker lock(&m_mutex);
        if (m_cache.contains(trackId)) {
            QImage full = m_cache.value(trackId);
            if (size) *size = full.size();
            if (requestedSize.isValid() && !requestedSize.isEmpty())
                return full.scaled(requestedSize, Qt::KeepAspectRatioByExpanding, Qt::SmoothTransformation);
            return full;
        }
    }

    // Load outside lock — DB read can take time
    QByteArray data = m_db->artworkBlob(trackId);
    if (data.isEmpty()) return {};
    QImage full;
    if (!full.loadFromData(data)) return {};

    {
        QMutexLocker lock(&m_mutex);
        if (m_cache.size() >= kMaxCache) {
            m_cache.erase(m_cache.begin());
        }
        m_cache.insert(trackId, full);
    }

    if (size) *size = full.size();
    if (requestedSize.isValid() && !requestedSize.isEmpty())
        return full.scaled(requestedSize, Qt::KeepAspectRatioByExpanding, Qt::SmoothTransformation);
    return full;
}
