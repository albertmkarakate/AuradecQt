#pragma once
#include <QAbstractListModel>
#include <QVariantList>
#include "TrackDatabase.h"

class AlbumModel : public QAbstractListModel {
    Q_OBJECT
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)
public:
    enum Roles { NameRole = Qt::UserRole + 1, ArtistRole, YearRole, CountRole, CoverIdRole };
    explicit AlbumModel(TrackDatabase *db, QObject *parent = nullptr);
    int rowCount(const QModelIndex & = {}) const override;
    QVariant data(const QModelIndex &idx, int role) const override;
    QHash<int,QByteArray> roleNames() const override;
public slots:
    void reload();
signals:
    void countChanged();
private:
    TrackDatabase *m_db;
    QVariantList   m_data;
};
