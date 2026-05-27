#pragma once
#include <QQuickImageProvider>
#include <QImage>
#include <QHash>
#include <QMutex>
#include "TrackDatabase.h"

class ArtworkProvider : public QQuickImageProvider {
public:
    explicit ArtworkProvider(TrackDatabase *db);
    QImage requestImage(const QString &id, QSize *size, const QSize &requestedSize) override;
    void invalidate(int trackId);
private:
    TrackDatabase     *m_db;
    QHash<int,QImage>  m_cache;
    mutable QMutex     m_mutex;
    static constexpr int kMaxCache = 200;
};
