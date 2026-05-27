#pragma once
#include <QObject>
#include <QMediaPlayer>
#include <QAudioOutput>
#include <QVariantMap>

class AudioEngine : public QObject {
    Q_OBJECT
    Q_PROPERTY(qint64  position READ position NOTIFY positionChanged)
    Q_PROPERTY(qint64  duration READ duration NOTIFY durationChanged)
    Q_PROPERTY(bool    playing  READ playing  NOTIFY playingChanged)
    Q_PROPERTY(float   volume   READ volume   WRITE setVolume NOTIFY volumeChanged)
    Q_PROPERTY(QString currentPath READ currentPath NOTIFY currentPathChanged)

public:
    explicit AudioEngine(QObject *parent = nullptr);

    qint64  position() const;
    qint64  duration() const;
    bool    playing()  const;
    float   volume()   const;
    QString currentPath() const;

public slots:
    void play(const QString &path);
    void resume();
    void pause();
    void stop();
    void seek(qint64 ms);
    void setVolume(float v);

signals:
    void positionChanged();
    void durationChanged();
    void playingChanged();
    void volumeChanged();
    void currentPathChanged();
    void trackEnded();
    void errorOccurred(const QString &msg);

private:
    QMediaPlayer  *m_player;
    QAudioOutput  *m_audio;
    QString        m_currentPath;
};
