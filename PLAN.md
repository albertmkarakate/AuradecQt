# Auradec Qt6 — Project Status

_Last updated: 2026-05-26 (session 3)_

---

## ✅ DONE

### Core Infrastructure
- CMakeLists.txt — Qt6 Quick/Multimedia/Sql/Svg/Concurrent/Network/Widgets linked
- TagLib metadata scanner (TrackScanner) — dir walk, tag read, DB upsert
- SQLite library DB (TrackDatabase) — tracks + artists + albums tables, migration-safe
- QMediaPlayer audio engine (AudioEngine) — play/pause/seek/volume, signals to QML
- ArtworkProvider — image:// provider serving BLOB artwork per track ID
- CurrentTrackInfo — QObject context property: id/title/artist/album/codec/bitrate/
  sampleRate/hasArtwork/year/genre/playCount/lyrics/syncedLyrics + setTrack/setLyrics/clearLyrics
- LibraryModel — QAbstractListModel, setFilter/setArtistFilter/setAlbumFilter/clearFilters/
  setSort/setFavoritesOnly/doReload/snapshot
- ArtistModel, AlbumModel — group-by models for Artists/Albums tabs

### Network Clients (C++)
- LyricsClient — fetches from lrclib.net (synced LRC + plain) → lyrics.ovh fallback →
  Spotify fallback (if configured). Signals: lyricsReady(plain, synced, source) / fetchError
- MusicBrainzClient — search releases by title/artist/album, fetch track metadata
- CoverArtClient — fetchByMbid / fetchByAlbum via Cover Art Archive
- All three registered as QML context properties: lyricsClient / musicBrainz / coverArtClient

### QML — Components
- SplashScreen — breathing rings Canvas + EQ bars + loading dots + auto-dismiss 1.8s
- Sidebar — 272px, logo + nav items + mini now-playing (EQ bars) + codec bar + legend
- PlayerBar — 112px, transport buttons + seek bar + volume slider + shuffle/repeat
- NavItem, SubNavItem — orange pill active state
- AuradecTheme — singleton design tokens (colors/fonts/radii/spacing)
- TrackCard — 200×240 grid card, hover overlay, context menu (5 items)
- TrackListItem — list row, codec badge, play count, duration, context menu (5 items)
- ArtistCard — artist grid card with drill-down
- AlbumCard — album grid card with artwork + drill-down
- LyricsPanel — plain lyrics (Flickable) + LRC synced (ListView, auto-scroll, highlight)
  + loading dots + empty placeholder
- TrackEditorModal — full metadata editor, MusicBrainz lookup, cover art fetch/import,
  Gemini AI (stub), star rating, saves to DB

### QML — Views
- LibraryView (499 lines) — Tracks/Artists/Albums tabs, grid/list toggle,
  search + clear, sort chips (artist/title/album/year/duration/plays),
  favorites toggle, drill-down breadcrumb, scan progress bar, toast notification
- NowPlayingView (475 lines) — hero artwork + glow, stat chips (plays/year/genre/format),
  sample rate detail, lyrics toggle button, right pane StackLayout (File Info + Up Next ↔ Lyrics)
  Up Next = full scrollable queue (all remaining tracks), scrolls on ♪ icon press
- SettingsView — library stats, DB path, rescan/import buttons, playback info, about

### QML — main.qml (324 lines)
- Window geometry + playback settings persistence (QtCore.Settings)
- Queue state: queue[], queueIndex, shuffleOn, repeatOn
- playTrack() — builds queue from library snapshot, sets currentTrack, plays
- playNext() / playPrev() — queue navigation with shuffle/repeat support
- addToQueue(path, id) — append to end of queue
- playNextInQueue(path, id) — insert after current position
- onTrackEnded — auto-advance or repeat current
- Keyboard shortcuts: Space/←/→/MediaNext/MediaPrev/MediaPlay/Ctrl+N/P/↑/↓
- TrackEditorModal instance — openTrack(id), reloads model+currentTrack on save

### Context Menu Actions (TrackCard + TrackListItem)
1. Play
2. Play Next (insert at queue[queueIndex+1])
3. Add to Queue (append)
4. Edit Track Info → TrackEditorModal
5. Toggle Favorite
6. Show in Files

---

## 🔴 BUGS TO FIX

1. **Context menu on Wayland** — right-click menu doesn't display on Wayland XDG surfaces.
   TrackCard + TrackListItem use `Controls.Overlay.overlay` + `mapToItem()` approach.
   Workaround: test on X11 or set `QT_QPA_PLATFORM=xcb`. Root cause: Wayland XDG popup
   positioning restrictions with Qt popups parented to overlay.

2. **LyricsPanel position unit mismatch** — LyricsPanel expects `position` in ms
   (parseLRC stores `mins*60000 + secs*1000`). NowPlayingView passes `audioEngine.position`
   which is Qt6 QMediaPlayer ms — correct. But verify AudioEngine.position property
   unit: QMediaPlayer::position() returns ms. Should be fine, but verify sync works.

3. **Sidebar codec legend `parent.parent.parent.parent`** — brittle ancestor traversal
   in the Repeater model binding to reach the Rectangle's `codecData` property.
   Fix: move `codecData` to a separate `property var` on the outer Column or use id.

4. **TrackEditorModal rating TextInput** — accepts any text, not validated as 0-5 int.
   Can save invalid rating to DB.

5. **playCount not refreshed in-place** — after playTrack(), the grid/list doesn't
   immediately show updated play count (incremented in DB) until next doReload().
   Small UX issue.

6. **Shuffle "Play Next"** — `playNextInQueue()` inserts at a fixed position, but if
   shuffle is on, that position is irrelevant since playNext() ignores queue order.
   Shuffle + Play Next is semantically ambiguous — currently Play Next is silently
   ignored when shuffle fires next track.

---

## 🟡 MISSING / INCOMPLETE

### Views
- **Radio tab** — sidebar item exists, clicks show generic placeholder text. No implementation.
- **Intelligence tab** — not in sidebar at all (was in original plan). Analytics stub only.
- **Playlist management** — no create/save/load named playlists. Queue is ephemeral only.
- **Album detail view** — drills to filtered tracks, but no album header (art + name + year).
  ArtistCard drill-down same issue — goes straight to track list with breadcrumb only.

### Features
- **Keyboard shortcut for Edit** — no shortcut to open track editor for current track.
- **Track deletion** — no "Remove from Library" in context menu.
  TrackDatabase.deleteTrack() exists but not wired to UI.
- **Re-scan on file change** — no inotify/FSWatcher; library only updates on manual rescan.
- **Mini player / compact mode** — full PlayerBar always visible; no collapse.
- **Equalizer / EQ** — PlayerBar has an EQ icon (stub). Not implemented.
- **Multiple library folders** — TrackScanner.rescanLast() only knows one folder.
  Can't have /Music/FLAC + /Music/MP3 both tracked.
- **Gapless playback** — QMediaPlayer doesn't do gapless natively. Needs QAudioSink + decode ahead.
- **ReplayGain / volume normalization** — not implemented.
- **macOS / Windows** — untested. Linux/X11 only validated.

### Lyrics
- **Spotify fallback** — requires Spotify Web Player cookies (not a public API).
  `spotifyConfigured` property in LyricsClient exists but no settings UI to configure it.
- **Manual lyric edit** — TrackEditorModal has lyrics TextArea field but no LRC editor.
- **Lyrics source indicator** — LyricsPanel shows no "Source: lrclib.net" attribution.

### TrackEditorModal
- **Gemini AI auto-fill** — stubbed (`visible: false`) at line 366. Needs Gemini API key setting.
- **Write tags back to file** — editor saves to SQLite only. Original file tags not updated.
  TagLib write path exists in C++ (TrackScanner has write capability) but not wired.
- **Artwork drag-and-drop** — FileDialog works but no drag target.

### Settings
- **Spotify credentials** — no input for Spotify cookies (needed for lyrics fallback).
- **Gemini API key** — no settings row.
- **Theme selector** — dark only; no accent color picker.
- **Crossfade duration** — no setting.
- **Multiple scan folders** — no UI to manage list of folders.

---

## 🧪 TESTS TO DO

### Unit Tests (C++ / Qt Test)
- `TrackDatabase` — upsertTrack, trackById, toggleFavorite, updateTrack(lyrics),
  codecStats, incrementPlayCount, deleteTrack
- `LibraryModel` — setFilter, setArtistFilter, setAlbumFilter, clearFilters, setSort,
  setFavoritesOnly, snapshot() correct order
- `TrackScanner` — scan directory → correct track count, duplicate prevention (upsert)
- `LyricsClient` — mock QNetworkAccessManager, verify lrclib parse, fallback chain,
  LRC timestamp parse edge cases (fractional seconds, metadata tags)
- `CurrentTrackInfo` — setTrack, setLyrics, clearLyrics, JSON lyrics cache round-trip
- `AudioEngine` — play/pause/seek/volume round-trip (mock QMediaPlayer or headless)

### QML Tests (Qt Quick Test / tst_)
- Splash screen: auto-dismiss after ~1800ms, fade animation completes
- LibraryView: search filters list, sort chips reorder, favorites toggle, drill-down + back
- PlayerBar: seek bar click → audioEngine.seek() called with correct ms value
- NowPlayingView: lyrics toggle shows LyricsPanel, Up Next shows remaining queue
- TrackEditorModal: save updates DB, model reload triggered, cancel makes no changes
- context menus: Play/PlayNext/AddToQueue/EditTrackInfo trigger correct signals

### Integration Tests
- Full scan → play → track ends → auto-advance to next
- Scan → add to queue → Play Next inserts at correct position
- Edit track → save → currentTrack reflects new title if it's the playing track
- Restart app → last track ID restored to PlayerBar, volume/shuffle/repeat persist
- Lyrics fetch → cache to DB → restart → loads from DB without network call

---

## 🔧 IMPROVEMENTS / POLISH

1. **Sidebar codec legend**: replace `parent.parent.parent.parent` ancestor chain with
   named `id` reference on the containing Rectangle.

2. **LyricsPanel sync accuracy**: add `position` property in ms, verify against
   LRC timestamps. Current: `audioEngine.position` (ms) passed directly — confirm
   edge case where track changes mid-lyric-fetch doesn't show stale lyrics.

3. **TrackCard/TrackListItem context menu**: extract shared `TrackContextMenu` component
   to eliminate ~40 lines of duplication between the two files.

4. **NowPlayingView line count**: at 475 lines, close to 500. If lyrics panel grows,
   extract `UpNextPanel` into `src/qml/components/UpNextPanel.qml`.

5. **Empty library state**: LibraryView shows empty grid with no guidance. Add a
   centered "Import your music" CTA that calls `trackScanner.pickAndScan()`.

6. **Error handling in TrackScanner**: if scan fails (permissions, bad path), no
   user-visible error. Should emit scanFailed(error) signal and show toast.

7. **Artwork loading performance**: ArtworkProvider loads full BLOB per request.
   Add size parameter to provider URL (`image://artwork/123?size=64`) and return
   scaled QImage to avoid loading full 1000px art for 32px thumbnails.

8. **Memory**: queue[] stores JS objects in QML — for very large libraries (10k+ tracks),
   playing a track rebuilds the entire queue array. Should be capped or lazily built.

9. **TrackEditorModal**: 720 lines — over limit. Should be split into:
   - `MetadataSection.qml` (title/artist/album/etc fields)
   - `ArtworkSection.qml` (art display + fetch + import)
   - `LyricsSection.qml` (lyrics textarea)

10. **PlayerBar seek thumb** — thumb only visible on hover/drag. Hard to see initial
    position. Consider always-visible small dot (4px) that grows on hover.

---

## 📁 KEY FILE MAP

```
src/
  backend/
    AudioEngine.h/.cpp          — QMediaPlayer wrapper, Q_PROPERTYs: position/duration/playing/volume
    TrackDatabase.h/.cpp        — SQLite CRUD, Q_INVOKABLEs: trackById/codecStats/updateTrack/etc
    TrackScanner.h/.cpp         — TagLib dir walker, emits scanProgress/scanComplete
    LibraryModel.h/.cpp         — QAbstractListModel, doReload(), setFilter/Sort/Favorites
    ArtistModel.h/.cpp          — Group-by-artist model
    AlbumModel.h/.cpp           — Group-by-album model
    ArtworkProvider.h/.cpp      — QQuickImageProvider, image://artwork/<id>
    CurrentTrackInfo.h/.cpp     — Current track QObject, setTrack/setLyrics/clearLyrics
    LyricsClient.h/.cpp         — lrclib.net + lyrics.ovh + Spotify fetch chain
    MusicBrainzClient.h/.cpp    — MusicBrainz release search
    CoverArtClient.h/.cpp       — Cover Art Archive fetch
  qml/
    main.qml (324)              — ApplicationWindow, queue logic, keyboard shortcuts
    SplashScreen.qml (142)      — Breathing rings + EQ + loading dots
    Sidebar.qml (258)           — Nav + mini now-playing + codec bar
    PlayerBar.qml (330)         — Transport + seek + volume
    components/
      AuradecTheme.qml (52)     — Singleton design tokens
      TrackCard.qml (193)       — Grid card + context menu
      TrackListItem.qml (222)   — List row + context menu
      LyricsPanel.qml (179)     — Lyrics display (plain + LRC synced)
      TrackEditorModal.qml (720)— Full metadata editor ⚠️ over 500 lines
      ArtistCard.qml (52)       — Artist grid card
      AlbumCard.qml (57)        — Album grid card
    views/
      LibraryView.qml (499)     — Tracks/Artists/Albums + search/sort/filter
      NowPlayingView.qml (475)  — Hero + stats + lyrics + queue
      SettingsView.qml (292)    — Settings rows

main.cpp                        — Registers all C++ types, context properties
CMakeLists.txt                  — Qt6 Quick/Multimedia/Sql/Network/Concurrent/Widgets
```

---

## ⚡ NEXT PRIORITIES (suggested order)

1. ~~Fix **sidebar codec legend** ancestor chain~~ ✅ done — `id: storageWidget`
2. ~~Add **"Remove from Library"** to context menus~~ ✅ done — `TrackContextMenu.qml` + `Q_INVOKABLE deleteTrack`
3. ~~Add **empty library CTA** in LibraryView~~ ✅ done
4. ~~Extract **TrackContextMenu** shared component (DRY)~~ ✅ done
5. ~~Split **TrackEditorModal** into sub-components~~ ✅ done — 720 → 323 lines + MetadataSection/LyricsSection/ArtworkSection
6. Fix **Wayland context menu** (low priority per user)
7. **Settings rows** for Spotify token, Gemini key
8. **Multiple scan folders** support
9. Start **C++ unit tests** (Qt Test framework, no deps beyond project)
10. Fix **playCount not refreshed in-place** after playTrack()
