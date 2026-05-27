#include "AudioEngine.h"
#include <QUrl>

AudioEngine::AudioEngine(QObject *parent)
    : QObject(parent)
    , m_player(new QMediaPlayer(this))
    , m_audio(new QAudioOutput(this))
{
    m_player->setAudioOutput(m_audio);
    m_audio->setVolume(0.8f);

    connect(m_player, &QMediaPlayer::positionChanged, this, &AudioEngine::positionChanged);
    connect(m_player, &QMediaPlayer::durationChanged, this, &AudioEngine::durationChanged);

    connect(m_player, &QMediaPlayer::playbackStateChanged, this, [this](QMediaPlayer::PlaybackState) {
        emit playingChanged();
    });

    connect(m_player, &QMediaPlayer::mediaStatusChanged, this, [this](QMediaPlayer::MediaStatus status) {
        if (status == QMediaPlayer::EndOfMedia)
            emit trackEnded();
    });

    connect(m_player, &QMediaPlayer::errorOccurred, this, [this](QMediaPlayer::Error, const QString &msg) {
        emit errorOccurred(msg);
    });
}

qint64 AudioEngine::position() const { return m_player->position(); }
qint64 AudioEngine::duration() const { return m_player->duration(); }
bool   AudioEngine::playing()  const { return m_player->playbackState() == QMediaPlayer::PlayingState; }
float  AudioEngine::volume()   const { return m_audio->volume(); }
QString AudioEngine::currentPath() const { return m_currentPath; }

void AudioEngine::play(const QString &path) {
    m_currentPath = path;
    emit currentPathChanged();
    QUrl url = path.startsWith("/") ? QUrl::fromLocalFile(path) : QUrl(path);
    m_player->setSource(url);
    m_player->play();
    emit playingChanged();
}

void AudioEngine::resume() {
    m_player->play();
    emit playingChanged();
}

void AudioEngine::pause() {
    m_player->pause();
    emit playingChanged();
}

void AudioEngine::stop() {
    m_player->stop();
    emit playingChanged();
}

void AudioEngine::seek(qint64 ms) {
    m_player->setPosition(ms);
}

void AudioEngine::setVolume(float v) {
    m_audio->setVolume(qBound(0.0f, v, 1.0f));
    emit volumeChanged();
}
