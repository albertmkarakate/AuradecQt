#pragma once
#include <QObject>
#include <QString>
#include <QStringList>
#include <QAtomicInt>

class TrackDatabase;

class TrackScanner : public QObject {
    Q_OBJECT
public:
    explicit TrackScanner(TrackDatabase *db, QObject *parent = nullptr);

    Q_INVOKABLE void pickAndScan();
    Q_INVOKABLE void rescanAll();
    Q_INVOKABLE QStringList scanFolders() const;
    Q_INVOKABLE void removeFolder(const QString &path);
    void scanDirectory(const QString &path);
    void cancel();

signals:
    void scanProgress(int done, int total);
    void scanComplete(int added);
    void foldersChanged();

private:
    static QStringList collectFiles(const QString &dir);
    static QStringList loadFolders();
    static void saveFolders(const QStringList &folders);
    TrackDatabase *m_db;
    QAtomicInt     m_cancel{0};
};
