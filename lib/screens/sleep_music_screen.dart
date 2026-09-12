import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'package:ai_last_v/l10n/app_localizations.dart';
import '../models/local_playlist.dart';
import '../models/sound_asset.dart';
import '../services/sounds_service.dart';
import '../state/auth_store.dart';
import '../state/local_playlist_store.dart';
import '../theme/app_text_color.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_panel.dart';

/// Список звуков категории sleep_music (загружает админ, см.
/// admin_sounds_screen.dart) — тап проигрывает/ставит на паузу, играет
/// только один трек за раз, зациклен, чтобы не обрывался внезапно.
///
/// Плюс личный слой поверх каталога (LocalPlaylistStore) - свои
/// плейлисты, свои загруженные файлы (никогда не уходят на сервер,
/// см. local_playlist.dart), лайки, удаление трека из СВОЕГО плейлиста
/// без удаления самого звука/файла.
class SleepMusicScreen extends StatefulWidget {
  final AuthStore authStore;
  // false - когда экран используется внутри main_shell_screen.dart, см.
  // тот же комментарий в wellbeing_screen.dart
  final bool showOwnBackground;
  const SleepMusicScreen({
    super.key,
    required this.authStore,
    this.showOwnBackground = true,
  });

  @override
  State<SleepMusicScreen> createState() => _SleepMusicScreenState();
}

enum _Tab { catalog, playlists }

class _SleepMusicScreenState extends State<SleepMusicScreen> {
  final _service = SoundsService();
  final _player = AudioPlayer();
  final _localStore = LocalPlaylistStore.instance;
  List<SoundAsset> _sounds = [];
  // заменяет прежний int? _playingId - теперь играть может звук ИЗ
  // каталога ("sound:<id>") ИЛИ свой файл ("local:<uuid>"), единая ссылка
  // покрывает оба случая, не нужно два отдельных поля
  TrackRef? _playingRef;
  bool _isLoading = true;
  bool _isBuffering = false;
  String? _error;

  _Tab _tab = _Tab.catalog;
  // null - показываем список плейлистов, не null - открыт конкретный
  String? _openPlaylistId;
  // "Избранное" - виртуальный список из ВСЕХ лайкнутых треков (каталог +
  // свои файлы вместе), не настоящий плейлист - нет своего id в
  // LocalPlaylistStore, собирается на лету из likedRefs. Поэтому нельзя
  // "убрать из плейлиста" отсюда - можно только снять лайк (что и уберёт
  // трек из этого списка естественным образом).
  bool _showingLiked = false;

  // на вебе у file_picker путь к файлу всегда null (нет стабильного
  // доступа к выбранному файлу между перезагрузками страницы) - держим
  // байты уже добавленных в ЭТУ сессию своих треков в памяти отдельно,
  // чтобы их вообще можно было проиграть здесь и сейчас. После
  // перезагрузки страницы это пропадёт - см. sleepMusicOwnFileWebNotice
  final Map<String, Uint8List> _webSessionBytes = {};

  // Таймер сна - автостоп воспроизведения через заданное время, чтобы
  // музыка не играла всю ночь. null - таймер не установлен (обычный
  // режим, играет до ручной остановки). Отдельно от AudioPlayer -
  // сам плеер не умеет "стоп через N минут", это чисто наша логика
  // поверх него.
  Duration? _sleepTimerRemaining;
  Timer? _sleepTimerTicker;

  @override
  void initState() {
    super.initState();
    _player.setReleaseMode(ReleaseMode.loop);
    _localStore.addListener(_onLocalStoreChanged);
    _localStore.load();
    _load();
  }

  void _onLocalStoreChanged() => setState(() {});

  @override
  void dispose() {
    _service.dispose();
    _player.dispose();
    _sleepTimerTicker?.cancel();
    _localStore.removeListener(_onLocalStoreChanged);
    super.dispose();
  }

  Future<void> _load() async {
    final token = widget.authStore.token;
    if (token == null) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final sounds = await _service.list(
        baseUrl: widget.authStore.baseUrl,
        token: token,
        category: SoundCategory.sleepMusic,
      );
      if (mounted) setState(() => _sounds = sounds);
    } on SoundsException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _setSleepTimer(Duration duration) {
    _sleepTimerTicker?.cancel();
    setState(() => _sleepTimerRemaining = duration);
    _sleepTimerTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = _sleepTimerRemaining;
      if (remaining == null || remaining.inSeconds <= 1) {
        timer.cancel();
        _sleepTimerTicker = null;
        // истёк - останавливаем воспроизведение, как и просили ("чтобы
        // музыка не играла всю ночь"), не просто гасим таймер молча
        _player.stop();
        if (mounted) {
          setState(() {
            _playingRef = null;
            _sleepTimerRemaining = null;
          });
        }
        return;
      }
      if (mounted) {
        setState(
          () => _sleepTimerRemaining = remaining - const Duration(seconds: 1),
        );
      }
    });
  }

  void _cancelSleepTimer() {
    _sleepTimerTicker?.cancel();
    _sleepTimerTicker = null;
    setState(() => _sleepTimerRemaining = null);
  }

  String _formatTimerRemaining(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _showSleepTimerSheet() async {
    final l10n = AppLocalizations.of(context)!;
    final choice = await showModalBottomSheet<Duration?>(
      context: context,
      backgroundColor: const Color(0xFF1A2036),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_sleepTimerRemaining != null)
              ListTile(
                leading: const Icon(
                  Icons.timer_off_outlined,
                  color: Color(0xFFFF6B6B),
                ),
                title: Text(
                  l10n.sleepMusicTimerCancel,
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  _cancelSleepTimer();
                  Navigator.of(context).pop();
                },
              ),
            for (final minutes in [15, 30, 45, 60, 90])
              ListTile(
                leading: const Icon(
                  Icons.bedtime_outlined,
                  color: Colors.white70,
                ),
                title: Text(
                  l10n.sleepMusicTimerMinutes(minutes),
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () =>
                    Navigator.of(context).pop(Duration(minutes: minutes)),
              ),
          ],
        ),
      ),
    );
    if (choice != null) _setSleepTimer(choice);
  }

  /// Заголовок трека по ссылке - ищет либо в каталоге, либо в личной
  /// библиотеке, в зависимости от типа ссылки.
  String _titleForRef(TrackRef ref) {
    if (ref.isSound) {
      final sound = _sounds.where((s) => s.id == ref.soundId).firstOrNull;
      return sound?.title ?? '?';
    }
    final track = _localStore.trackById(ref.localId);
    return track?.title ?? '?';
  }

  Future<void> _playRef(TrackRef ref) async {
    if (_playingRef == ref) {
      await _player.stop();
      setState(() => _playingRef = null);
      return;
    }

    setState(() => _isBuffering = true);
    try {
      if (ref.isSound) {
        final token = widget.authStore.token;
        if (token == null) return;
        final bytes = await _service.fetchAudioBytes(
          baseUrl: widget.authStore.baseUrl,
          token: token,
          soundId: ref.soundId,
        );
        if (!mounted) return;
        await _player.play(BytesSource(bytes));
      } else {
        final track = _localStore.trackById(ref.localId);
        if (track == null) return;
        if (track.filePath != null) {
          await _player.play(DeviceFileSource(track.filePath!));
        } else {
          final bytes = _webSessionBytes[track.id];
          if (bytes == null) {
            return; // добавлен в другой сессии на вебе - байтов уже нет
          }
          await _player.play(BytesSource(bytes));
        }
      }
      if (!mounted) return;
      setState(() => _playingRef = ref);
    } on SoundsException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isBuffering = false);
    }
  }

  /// Список ссылок, по которому сейчас можно листать next/prev - каталог
  /// целиком во вкладке "Каталог", "Избранное" (все лайкнутые) или состав
  /// конкретного плейлиста внутри "Мои плейлисты".
  List<TrackRef> get _activeRefList {
    if (_tab == _Tab.catalog) {
      return _sounds.map((s) => TrackRef.sound(s.id)).toList();
    }
    if (_showingLiked) {
      return _localStore.likedRefs.map(TrackRef.parse).toList();
    }
    if (_openPlaylistId == null) return [];
    final playlist = _localStore.playlists
        .where((p) => p.id == _openPlaylistId)
        .firstOrNull;
    return playlist?.trackRefs ?? [];
  }

  Future<void> _playAdjacent(int delta) async {
    final refs = _activeRefList;
    if (refs.isEmpty) return;
    final currentIndex = _playingRef == null ? -1 : refs.indexOf(_playingRef!);
    final nextIndex = currentIndex == -1
        ? 0
        : (currentIndex + delta) % refs.length;
    await _playRef(refs[nextIndex]);
  }

  Future<void> _createPlaylist() async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A2036),
        title: Text(
          l10n.sleepMusicCreatePlaylist,
          style: const TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(hintText: l10n.sleepMusicNewPlaylistHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    final playlist = await _localStore.createPlaylist(name);
    if (mounted) setState(() => _openPlaylistId = playlist.id);
  }

  Future<void> _renamePlaylist(LocalPlaylist playlist) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: playlist.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A2036),
        title: Text(
          l10n.sleepMusicRenamePlaylist,
          style: const TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(hintText: l10n.sleepMusicNewPlaylistHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    await _localStore.renamePlaylist(playlist.id, name);
  }

  Future<void> _deletePlaylist(LocalPlaylist playlist) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A2036),
        title: Text(
          l10n.sleepMusicDeletePlaylist,
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          l10n.sleepMusicDeletePlaylistConfirm(playlist.name),
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              l10n.commonDelete,
              style: const TextStyle(color: Color(0xFFFF6B6B)),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _localStore.deletePlaylist(playlist.id);
    if (mounted) setState(() => _openPlaylistId = null);
  }

  Future<void> _addTrackToOpenPlaylist() async {
    final l10n = AppLocalizations.of(context)!;
    final playlistId = _openPlaylistId;
    if (playlistId == null) return;

    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF1A2036),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.library_music_outlined,
                color: Colors.white,
              ),
              title: Text(
                l10n.sleepMusicAddFromCatalog,
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () => Navigator.of(context).pop('catalog'),
            ),
            ListTile(
              leading: const Icon(
                Icons.upload_file_rounded,
                color: Colors.white,
              ),
              title: Text(
                l10n.sleepMusicUploadOwnFile,
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () => Navigator.of(context).pop('upload'),
            ),
          ],
        ),
      ),
    );

    if (choice == 'catalog') {
      await _pickFromCatalog(playlistId);
    } else if (choice == 'upload') {
      await _uploadOwnFile(playlistId);
    }
  }

  Future<void> _pickFromCatalog(String playlistId) async {
    final l10n = AppLocalizations.of(context)!;
    if (_sounds.isEmpty) {
      setState(() => _error = l10n.sleepMusicNoTracksInCatalogYet);
      return;
    }
    final picked = await showDialog<SoundAsset>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A2036),
        title: Text(
          l10n.sleepMusicAddFromCatalog,
          style: const TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: _sounds
                .map(
                  (s) => ListTile(
                    title: Text(
                      s.title,
                      style: const TextStyle(color: Colors.white),
                    ),
                    onTap: () => Navigator.of(context).pop(s),
                  ),
                )
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonCancel),
          ),
        ],
      ),
    );
    if (picked == null) return;
    await _localStore.addToPlaylist(playlistId, TrackRef.sound(picked.id));
  }

  Future<void> _uploadOwnFile(String playlistId) async {
    final l10n = AppLocalizations.of(context)!;
    // file_picker v12: FilePicker.pickFile() - один файл сразу,
    // PlatformFile? (не список с .single). path всегда null на вебе -
    // читаем байты явно через readAsBytes() вместо того, чтобы полагаться
    // на путь, который на некоторых платформах может отсутствовать
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'ogg', 'm4a'],
    );
    if (file == null) return;

    final title = file.name;
    final track = await _localStore.addLocalTrack(
      title: title,
      filePath: kIsWeb ? null : file.path,
    );

    if (kIsWeb) {
      try {
        _webSessionBytes[track.id] = await file.readAsBytes();
      } catch (_) {
        if (mounted) setState(() => _error = l10n.sleepMusicFileReadError);
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.sleepMusicOwnFileWebNotice)),
        );
      }
    }

    await _localStore.addToPlaylist(playlistId, TrackRef.local(track.id));
  }

  Future<void> _removeFromOpenPlaylist(TrackRef ref) async {
    final playlistId = _openPlaylistId;
    if (playlistId == null) return;
    if (_playingRef == ref) {
      await _player.stop();
      setState(() => _playingRef = null);
    }
    await _localStore.removeFromPlaylist(playlistId, ref);
  }

  Widget _buildTrackTile(TrackRef ref, {VoidCallback? onRemove}) {
    final isPlaying = _playingRef == ref;
    final isLiked = _localStore.isLiked(ref);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _isBuffering ? null : () => _playRef(ref),
          child: GlassPanel(
            opacity: 0.08,
            borderRadius: BorderRadius.circular(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  isPlaying
                      ? Icons.pause_circle_filled_rounded
                      : Icons.play_circle_outline_rounded,
                  color: isPlaying
                      ? const Color(0xFF00E6A0)
                      : context.onSurfaceFaded(0.6),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _titleForRef(ref),
                    style: TextStyle(color: context.onSurface, fontSize: 14.5),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isLiked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: isLiked
                        ? const Color(0xFFFF6B6B)
                        : context.onSurfaceFaded(0.4),
                    size: 20,
                  ),
                  onPressed: () => _localStore.toggleLike(ref),
                ),
                if (onRemove != null)
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: context.onSurfaceFaded(0.4),
                      size: 20,
                    ),
                    onPressed: onRemove,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCatalogTab(AppLocalizations l10n) {
    if (_sounds.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Center(
          child: Text(
            l10n.sleepMusicNoneUploaded,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.onSurfaceFaded(0.4)),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _sounds
          .map((s) => _buildTrackTile(TrackRef.sound(s.id)))
          .toList(),
    );
  }

  Widget _buildPlaylistsTab(AppLocalizations l10n) {
    if (_showingLiked) {
      final refs = _localStore.likedRefs.map(TrackRef.parse).toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: context.onSurface),
                onPressed: () => setState(() => _showingLiked = false),
              ),
              Expanded(
                child: Text(
                  l10n.sleepMusicLikedTitle,
                  style: TextStyle(
                    color: context.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (refs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  l10n.sleepMusicNoLikedYet,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.onSurfaceFaded(0.4)),
                ),
              ),
            )
          else
            ...refs.map((ref) => _buildTrackTile(ref)),
        ],
      );
    }

    if (_openPlaylistId != null) {
      final playlist = _localStore.playlists
          .where((p) => p.id == _openPlaylistId)
          .firstOrNull;
      if (playlist == null) {
        // удалён откуда-то ещё - откатываемся к списку, не показываем пустоту
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _openPlaylistId = null);
        });
        return const SizedBox.shrink();
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: context.onSurface),
                onPressed: () => setState(() => _openPlaylistId = null),
              ),
              Expanded(
                child: Text(
                  playlist.name,
                  style: TextStyle(
                    color: context.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.edit_outlined,
                  color: context.onSurfaceFaded(0.6),
                ),
                onPressed: () => _renamePlaylist(playlist),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFFF6B6B),
                ),
                onPressed: () => _deletePlaylist(playlist),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (playlist.trackRefs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  l10n.sleepMusicEmptyPlaylist,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.onSurfaceFaded(0.4)),
                ),
              ),
            )
          else
            ...playlist.trackRefs.map(
              (ref) => _buildTrackTile(
                ref,
                onRemove: () => _removeFromOpenPlaylist(ref),
              ),
            ),
          const SizedBox(height: 12),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6C5CE7),
            ),
            onPressed: _addTrackToOpenPlaylist,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(l10n.sleepMusicAddTrack),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => setState(() => _showingLiked = true),
              child: GlassPanel(
                opacity: 0.08,
                borderRadius: BorderRadius.circular(16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.favorite_rounded,
                      color: Color(0xFFFF6B6B),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.sleepMusicLikedTitle,
                        style: TextStyle(
                          color: context.onSurface,
                          fontSize: 14.5,
                        ),
                      ),
                    ),
                    Text(
                      '${_localStore.likedRefs.length}',
                      style: TextStyle(
                        color: context.onSurfaceFaded(0.4),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_localStore.playlists.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                l10n.sleepMusicNoPlaylists,
                textAlign: TextAlign.center,
                style: TextStyle(color: context.onSurfaceFaded(0.4)),
              ),
            ),
          )
        else
          ..._localStore.playlists.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => setState(() => _openPlaylistId = p.id),
                  child: GlassPanel(
                    opacity: 0.08,
                    borderRadius: BorderRadius.circular(16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.queue_music_rounded,
                          color: context.onSurfaceFaded(0.6),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            p.name,
                            style: TextStyle(
                              color: context.onSurface,
                              fontSize: 14.5,
                            ),
                          ),
                        ),
                        Text(
                          '${p.trackRefs.length}',
                          style: TextStyle(
                            color: context.onSurfaceFaded(0.4),
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 12),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF6C5CE7),
          ),
          onPressed: _createPlaylist,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: Text(l10n.sleepMusicCreatePlaylist),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    TrackRef? playingRef = _playingRef;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        enabled: widget.showOwnBackground,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    if (widget.showOwnBackground)
                      IconButton(
                        icon: Icon(
                          Icons.adaptive.arrow_back,
                          color: context.onSurface,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      )
                    else
                      const SizedBox(width: 8),
                    Text(
                      l10n.sleepMusicTitle,
                      style: TextStyle(
                        color: context.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SegmentedButton<_Tab>(
                  segments: [
                    ButtonSegment(
                      value: _Tab.catalog,
                      label: Text(l10n.sleepMusicTabCatalog),
                    ),
                    ButtonSegment(
                      value: _Tab.playlists,
                      label: Text(l10n.sleepMusicTabPlaylists),
                    ),
                  ],
                  selected: {_tab},
                  onSelectionChanged: (selection) =>
                      setState(() => _tab = selection.first),
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: const Color(0xFF6C5CE7),
                    selectedForegroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Center(
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          color: Color(0xFF6C5CE7),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 480),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (_error != null) ...[
                                  Text(
                                    _error!,
                                    style: const TextStyle(
                                      color: Color(0xFFFFB4B4),
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                if (_tab == _Tab.catalog)
                                  _buildCatalogTab(l10n)
                                else
                                  _buildPlaylistsTab(l10n),
                                // отступ снизу, чтобы последний трек списка не
                                // прятался под плеером с кнопками ниже
                                if (playingRef != null)
                                  const SizedBox(height: 76),
                              ],
                            ),
                          ),
                        ),
                ),
              ),
              if (playingRef != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: GlassPanel(
                    opacity: 0.14,
                    borderRadius: BorderRadius.circular(20),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _titleForRef(playingRef),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: context.onSurface,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: _showSleepTimerSheet,
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: _sleepTimerRemaining != null
                                  ? Text(
                                      _formatTimerRemaining(
                                        _sleepTimerRemaining!,
                                      ),
                                      style: const TextStyle(
                                        color: Color(0xFFFFD166),
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    )
                                  : Icon(
                                      Icons.bedtime_outlined,
                                      color: context.onSurfaceFaded(0.6),
                                      size: 20,
                                    ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.skip_previous_rounded,
                            color: context.onSurfaceFaded(0.8),
                          ),
                          onPressed: _isBuffering
                              ? null
                              : () => _playAdjacent(-1),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.pause_circle_filled_rounded,
                            color: Color(0xFF00E6A0),
                          ),
                          onPressed: _isBuffering
                              ? null
                              : () => _playRef(playingRef),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.skip_next_rounded,
                            color: context.onSurfaceFaded(0.8),
                          ),
                          onPressed: _isBuffering
                              ? null
                              : () => _playAdjacent(1),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
