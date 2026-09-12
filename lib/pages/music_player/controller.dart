import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:PiliPlus/http/constants.dart';
import 'package:PiliPlus/http/fav.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/http/video.dart';
import 'package:PiliPlus/models/common/video/video_type.dart';
import 'package:PiliPlus/models/common/video/video_quality.dart';
import 'package:PiliPlus/models/common/video/audio_quality.dart';
import 'package:PiliPlus/services/download/download_service.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:PiliPlus/utils/extension/iterable_ext.dart';
import 'package:PiliPlus/models_new/fav/fav_detail/media.dart';
import 'package:PiliPlus/models_new/fav/fav_detail/data.dart';
import 'package:PiliPlus/models_new/fav/fav_folder/data.dart';
import 'package:PiliPlus/models_new/fav/fav_folder/list.dart';
import 'package:PiliPlus/models_new/video/video_detail/page.dart';
import 'package:PiliPlus/models_new/video/video_play_info/data.dart';
import 'package:PiliPlus/plugin/pl_player/models/play_status.dart';
import 'package:PiliPlus/services/service_locator.dart';
import 'package:PiliPlus/utils/accounts.dart';
import 'package:PiliPlus/utils/video_utils.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class MusicItem {
  final String musicId;
  final String title;
  final String artist;
  final String cover;
  final int? mvAid;
  final int? mvCid;
  final String? mvBvid;
  final bool isLocal;
  final String? localPath;

  MusicItem({
    required this.musicId,
    required this.title,
    required this.artist,
    required this.cover,
    this.mvAid,
    this.mvCid,
    this.mvBvid,
    this.isLocal = false,
    this.localPath,
  });

  Map<String, dynamic> toJson() => {
    'musicId': musicId,
    'title': title,
    'artist': artist,
    'cover': cover,
    'mvAid': mvAid,
    'mvCid': mvCid,
    'mvBvid': mvBvid,
    'isLocal': isLocal,
    'localPath': localPath,
  };

  factory MusicItem.fromJson(Map<String, dynamic> json) => MusicItem(
    musicId: json['musicId'] ?? '',
    title: json['title'] ?? '',
    artist: json['artist'] ?? '',
    cover: json['cover'] ?? '',
    mvAid: json['mvAid'],
    mvCid: json['mvCid'],
    mvBvid: json['mvBvid'],
    isLocal: json['isLocal'] ?? false,
    localPath: json['localPath'],
  );
}

// 歌词行数据模型
class LyricLine {
  final double startTime; // 开始时间（秒）
  final double endTime; // 结束时间（秒）
  final String content; // 歌词内容

  LyricLine({
    required this.startTime,
    required this.endTime,
    required this.content,
  });

  factory LyricLine.fromSubtitleBody(Map<String, dynamic> json) {
    return LyricLine(
      startTime: (json['from'] as num?)?.toDouble() ?? 0.0,
      endTime: (json['to'] as num?)?.toDouble() ?? 0.0,
      content: json['content'] ?? '',
    );
  }
}

class MusicPlayerController extends GetxController with WidgetsBindingObserver {
  final RxList<MusicItem> playlist = <MusicItem>[].obs;
  final Rx<MusicItem?> currentMusic = Rx<MusicItem?>(null);
  final RxInt currentIndex = 0.obs;
  final RxBool isPlaying = false.obs;
  final RxBool showMV = false.obs;
  final RxDouble progress = 0.0.obs;
  final RxDouble duration = 0.0.obs;
  final RxBool isShuffleMode = false.obs;
  final RxInt repeatMode = 0.obs;
  final RxBool isBuffering = false.obs;
  final RxBool isLoadingVideo = false.obs;

  final Rx<LoadingState<FavFolderData>> favFoldersState = Rx(
    LoadingState.loading(),
  );
  final RxList<FavFolderInfo> favFolders = <FavFolderInfo>[].obs;
  final RxBool isLoadingFolders = false.obs;
  final RxList<MusicItem> favFolderItems = <MusicItem>[].obs;
  final RxList<FavDetailItemModel> favFolderItemsRaw =
      <FavDetailItemModel>[].obs;
  final RxBool isLoadingFolderItems = false.obs;

  final RxList<Part> videoParts = <Part>[].obs;
  final RxList<int> selectedPartIndices = <int>[].obs;
  final RxBool isLoadingParts = false.obs;

  final Rx<VideoQuality> cacheQuality = Rx(
    VideoQuality.fromCode(Pref.defaultVideoQa),
  );
  final Rx<AudioQuality> cacheAudioQuality = Rx(
    AudioQuality.fromCode(Pref.defaultAudioQa),
  );
  final RxList<MusicItem> cachedItems = <MusicItem>[].obs;
  final RxBool isLoadingCache = false.obs;
  final RxBool isAlbumRatio = false.obs;
  final RxString cacheFolderPath = ''.obs;

  // 音效相关
  final RxInt audioEffectMode = 0.obs; // 0=关闭, 1=低音增强, 2=人声增强, 3=3D环绕, 4=清晰人声
  final RxDouble bassBoost = 0.0.obs; // -10 到 10
  final RxDouble trebleBoost = 0.0.obs; // -10 到 10

  // AI歌词相关
  final RxBool showLyrics = false.obs; // 是否显示歌词视图
  final RxBool isLoadingLyrics = false.obs; // 是否正在加载歌词
  final RxList<LyricLine> lyrics = <LyricLine>[].obs; // 歌词列表
  final RxInt currentLyricIndex = 0.obs; // 当前歌词索引

  // 播放列表记忆功能
  final RxBool playlistMemoryEnabled = true.obs;
  static const String _playlistStorageKey = 'music_player_playlist';
  static const String _playlistMemoryKey = 'music_player_memory_enabled';
  static const String _playlistStateStorageKey = 'music_player_state';

  Player? _player;
  VideoController? _videoController;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _playingSubscription;
  StreamSubscription? _bufferingSubscription;
  StreamSubscription? _completedSubscription;
  Timer? _memorySaveTimer;
  bool _isInBackground = false;
  bool _restoredPendingMedia = false;

  Player? get player => _player;
  VideoController? get videoController => _videoController;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _initPlayer();
    _loadPlaylistMemorySetting();
    _loadSavedPlaylist();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _clearMediaNotification();
    _savePlaylistIfEnabled();
    _disposePlayer();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      _isInBackground = true;
      _updateMediaNotification();
      _savePlaybackMemory();
    } else if (state == AppLifecycleState.resumed) {
      _isInBackground = false;
    }
  }

  void _initPlayer() {
    _player = Player(
      configuration: const PlayerConfiguration(bufferSize: 32 * 1024 * 1024),
    );
    _videoController = VideoController(_player!);
    _setupListeners();
    _setupAudioServiceCallbacks();
  }

  void _disposePlayer() {
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playingSubscription?.cancel();
    _bufferingSubscription?.cancel();
    _completedSubscription?.cancel();
    _memorySaveTimer?.cancel();
    _player?.dispose();
    _player = null;
    _videoController = null;
  }

  void _setupAudioServiceCallbacks() {
    final handler = videoPlayerServiceHandler;
    if (handler != null) {
      handler.onPlay = play;
      handler.onPause = pause;
      handler.onSeek = (position) {
        seekTo(position.inMilliseconds / 1000.0);
      };
      handler.onSkipToNext = playNext;
      handler.onSkipToPrevious = playPrevious;
    }
  }

  void clearAudioServiceCallbacks() {
    final handler = videoPlayerServiceHandler;
    if (handler != null) {
      handler.onPlay = null;
      handler.onPause = null;
      handler.onSeek = null;
      handler.onSkipToNext = null;
      handler.onSkipToPrevious = null;
    }
  }

  void _updateMediaNotification() {
    final handler = videoPlayerServiceHandler;
    final music = currentMusic.value;
    if (handler == null || music == null) return;
    handler.setMusicPlayerMediaItem(
      MediaItem(
        id: music.musicId,
        title: music.title,
        artist: music.artist,
        artUri: Uri.parse(music.cover),
        duration: Duration(seconds: duration.value.toInt()),
      ),
    );
    handler.setMusicPlaybackState(
      isPlaying.value ? PlayerStatus.playing : PlayerStatus.paused,
      isBuffering.value,
      playlist.length > 1,
    );
  }

  void _clearMediaNotification() {
    clearAudioServiceCallbacks();
    videoPlayerServiceHandler?.clearMusicPlayerState();
    videoPlayerServiceHandler?.clear();
  }

  void _setupListeners() {
    if (_player == null) return;
    _positionSubscription = _player!.stream.position.listen((pos) {
      progress.value = pos.inMilliseconds / 1000.0;
      _scheduleSavePlaybackMemory();
      // 更新歌词索引
      if (showLyrics.value && lyrics.isNotEmpty) {
        updateCurrentLyricIndex();
      }
      if (_isInBackground) {
        videoPlayerServiceHandler?.onPositionChange(pos);
      }
    });
    _durationSubscription = _player!.stream.duration.listen((dur) {
      duration.value = dur.inMilliseconds / 1000.0;
      _scheduleSavePlaybackMemory();
    });
    _playingSubscription = _player!.stream.playing.listen((playing) {
      isPlaying.value = playing;
      _updateMediaNotification();
    });
    _bufferingSubscription = _player!.stream.buffering.listen((buffering) {
      isBuffering.value = buffering;
    });
    _completedSubscription = _player!.stream.completed.listen((completed) {
      if (completed) _onPlaybackCompleted();
    });
  }

  void _onPlaybackCompleted() {
    switch (repeatMode.value) {
      case 1:
        seekTo(0);
        _player?.play();
        break;
      case 2:
        if (playlist.isNotEmpty) {
          playMusic(DateTime.now().millisecondsSinceEpoch % playlist.length);
        }
        break;
      default:
        playNext();
    }
  }

  void addToPlaylist(MusicItem music) {
    if (!playlist.any((m) => m.musicId == music.musicId)) {
      playlist.add(music);
      _savePlaybackMemory();
    }
  }

  void removeFromPlaylist(int index) {
    if (index >= 0 && index < playlist.length) {
      final wasPlaying = currentIndex.value == index;
      playlist.removeAt(index);
      if (currentIndex.value >= playlist.length) {
        currentIndex.value = playlist.isNotEmpty ? playlist.length - 1 : 0;
      } else if (currentIndex.value > index) {
        currentIndex.value--;
      }
      if (wasPlaying && playlist.isNotEmpty) {
        currentMusic.value = playlist[currentIndex.value];
      } else if (playlist.isEmpty) {
        currentMusic.value = null;
        _player?.pause();
      }
      _savePlaybackMemory();
    }
  }

  void clearPlaylist() {
    playlist.clear();
    currentMusic.value = null;
    currentIndex.value = 0;
    isPlaying.value = false;
    _player?.pause();
    _savePlaybackMemory();
  }

  Future<void> playMusic(int index) async {
    if (index >= 0 && index < playlist.length) {
      _restoredPendingMedia = false;
      currentIndex.value = index;
      currentMusic.value = playlist[index];
      progress.value = 0;
      duration.value = 0;
      _savePlaybackMemory();
      // 切换歌曲时重新加载歌词
      lyrics.clear();
      currentLyricIndex.value = 0;
      if (showLyrics.value) {
        loadLyrics();
      }
      await _loadAndPlayVideo(playlist[index]);
    }
  }

  Future<void> _loadAndPlayVideo(MusicItem music) async {
    if (music.mvBvid == null) {
      SmartDialog.showToast('无法获取视频信息');
      isPlaying.value = false;
      return;
    }
    isLoadingVideo.value = true;
    try {
      int? cid = music.mvCid;
      if (cid == null) {
        final infoResult = await VideoHttp.videoIntro(bvid: music.mvBvid!);
        if (infoResult is Success) {
          cid = infoResult.data.cid;
          final index = playlist.indexWhere((m) => m.musicId == music.musicId);
          if (index >= 0) {
            playlist[index] = MusicItem(
              musicId: music.musicId,
              title: music.title,
              artist: music.artist,
              cover: music.cover,
              mvAid: music.mvAid ?? infoResult.data.aid,
              mvBvid: music.mvBvid,
              mvCid: cid,
            );
            if (currentIndex.value == index) {
              currentMusic.value = playlist[index];
            }
          }
        }
      }
      if (cid == null) {
        SmartDialog.showToast('无法获取视频cid');
        isPlaying.value = false;
        isLoadingVideo.value = false;
        return;
      }
      final result = await VideoHttp.videoUrl(
        bvid: music.mvBvid,
        cid: cid,
        tryLook: !Accounts.main.isLogin,
        videoType: VideoType.ugc,
      );
      if (result is Success) {
        final data = result.data;
        String? videoUrl, audioUrl;
        if (data.dash != null) {
          if (data.dash!.video?.isNotEmpty == true) {
            videoUrl = VideoUtils.getCdnUrl(data.dash!.video!.first.playUrls);
          }
          if (data.dash!.audio?.isNotEmpty == true) {
            audioUrl = VideoUtils.getCdnUrl(
              data.dash!.audio!.first.playUrls,
              isAudio: true,
            );
          }
        } else if (data.durl?.isNotEmpty == true) {
          videoUrl = VideoUtils.getCdnUrl(data.durl!.first.playUrls);
        }
        if (_player != null) {
          if (showMV.value && videoUrl != null && audioUrl != null) {
            final pp = _player!.platform;
            if (pp != null) {
              final escapedAudioUrl = Platform.isWindows
                  ? audioUrl.replaceAll(';', r'\;')
                  : audioUrl.replaceAll(':', r'\:');
              await pp.setProperty('audio-files', escapedAudioUrl);
            }
            await _player!.setVideoTrack(VideoTrack.auto());
            await _player!.setAudioTrack(AudioTrack.auto());
            await _player!.open(
              Media(
                videoUrl,
                httpHeaders: {
                  'referer': HttpString.baseUrl,
                  'user-agent':
                      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
                },
              ),
            );
          } else {
            final playUrl = audioUrl ?? videoUrl;
            if (playUrl != null) {
              final pp = _player!.platform;
              if (pp != null) {
                await pp.setProperty('audio-files', '');
              }
              await _player!.setAudioTrack(AudioTrack.auto());
              await _player!.setVideoTrack(VideoTrack.no());
              await _player!.open(
                Media(
                  playUrl,
                  httpHeaders: {
                    'referer': HttpString.baseUrl,
                    'user-agent':
                        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
                  },
                ),
              );
            } else {
              SmartDialog.showToast('无法获取播放地址');
              isPlaying.value = false;
            }
          }
          isPlaying.value = true;
          // 确保音频服务回调已设置
          _setupAudioServiceCallbacks();
          _updateMediaNotification();
          _savePlaybackMemory();
        }
      } else {
        SmartDialog.showToast(
          result is Error ? (result.errMsg ?? '获取播放地址失败') : '获取播放地址失败',
        );
        isPlaying.value = false;
      }
    } catch (e) {
      SmartDialog.showToast('播放失败: $e');
      isPlaying.value = false;
    } finally {
      isLoadingVideo.value = false;
    }
  }

  void togglePlay() {
    if (_player == null) return;
    // 确保音频服务回调已设置
    _setupAudioServiceCallbacks();
    if (isPlaying.value) {
      _player!.pause();
    } else {
      if (_restoredPendingMedia && currentMusic.value != null) {
        unawaited(_playRestoredMusic());
      } else if (currentMusic.value != null) {
        _player!.play();
      } else if (playlist.isNotEmpty) {
        playMusic(0);
      }
    }
  }

  void playNext() {
    if (playlist.isEmpty) return;
    if (isShuffleMode.value) {
      playMusic(DateTime.now().millisecondsSinceEpoch % playlist.length);
    } else {
      playMusic((currentIndex.value + 1) % playlist.length);
    }
  }

  void playPrevious() {
    if (playlist.isEmpty) return;
    int prevIndex = currentIndex.value - 1;
    if (prevIndex < 0) prevIndex = playlist.length - 1;
    playMusic(prevIndex);
  }

  void toggleShuffle() {
    isShuffleMode.value = !isShuffleMode.value;
    _savePlaybackMemory();
  }

  void toggleRepeatMode() {
    repeatMode.value = (repeatMode.value + 1) % 3;
    _savePlaybackMemory();
  }

  void toggleVideoRatio() {
    isAlbumRatio.value = !isAlbumRatio.value;
  }

  void toggleMVDisplay() {
    showMV.value = !showMV.value;
    if (currentMusic.value != null) {
      final currentPos = progress.value;
      _loadAndPlayVideo(currentMusic.value!).then((_) {
        Future.delayed(
          const Duration(milliseconds: 500),
          () => seekTo(currentPos),
        );
      });
    }
  }

  void seekTo(double position) {
    final target = duration.value > 0
        ? position.clamp(0.0, duration.value)
        : position.clamp(0.0, double.infinity);
    _player?.seek(Duration(milliseconds: (target * 1000).toInt()));
    progress.value = target;
    _savePlaybackMemory();
  }

  void seekBy(double seconds) {
    seekTo(progress.value + seconds);
  }

  void pause() {
    _player?.pause();
    _savePlaybackMemory();
  }

  void play() {
    // 确保音频服务回调已设置
    _setupAudioServiceCallbacks();
    if (_restoredPendingMedia && currentMusic.value != null) {
      unawaited(_playRestoredMusic());
    } else {
      _player?.play();
    }
  }

  Future<void> _playRestoredMusic() async {
    final music = currentMusic.value;
    if (music == null) return;

    final restoredProgress = progress.value;
    _restoredPendingMedia = false;
    await _loadAndPlayVideo(music);
    if (restoredProgress > 0) {
      await Future.delayed(const Duration(milliseconds: 300));
      seekTo(restoredProgress);
    }
  }

  Future<void> loadFavFolders() async {
    if (!Accounts.main.isLogin) {
      SmartDialog.showToast('请先登录');
      favFolders.clear();
      favFoldersState.value = const Error('账号未登录');
      return;
    }
    isLoadingFolders.value = true;
    favFolders.clear();
    try {
      final res = await FavHttp.userfavFolder(
        pn: 1,
        ps: 50,
        mid: Accounts.main.mid,
      );
      if (res is Success<FavFolderData>) {
        final data = res.response;
        if (data.list != null && data.list!.isNotEmpty) {
          favFolders.value = data.list!;
        }
        favFoldersState.value = res;
      } else if (res is Error) {
        favFoldersState.value = Error(res.errMsg ?? '加载失败');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Load fav folders error: $e');
      favFoldersState.value = Error('加载失败: $e');
    } finally {
      isLoadingFolders.value = false;
    }
  }

  Future<bool> addToFavFolder(int folderId, {int? aid}) async {
    final targetAid = aid ?? currentMusic.value?.mvAid;
    if (targetAid == null) {
      SmartDialog.showToast('无法获取视频ID');
      return false;
    }
    if (!Accounts.main.isLogin) {
      SmartDialog.showToast('请先登录');
      return false;
    }
    try {
      final res = await FavHttp.favVideo(
        resources: '$targetAid:2',
        addIds: folderId.toString(),
      );
      return res.isSuccess;
    } catch (e) {
      return false;
    }
  }

  Future<bool> removeFromFavFolder(int folderId, {int? aid}) async {
    final targetAid = aid ?? currentMusic.value?.mvAid;
    if (targetAid == null || !Accounts.main.isLogin) return false;
    try {
      final res = await FavHttp.favVideo(
        resources: '$targetAid:2',
        delIds: folderId.toString(),
      );
      return res.isSuccess;
    } catch (e) {
      return false;
    }
  }

  Future<void> loadFavFolderItems(int mediaId) async {
    if (!Accounts.main.isLogin) {
      favFolderItems.clear();
      favFolderItemsRaw.clear();
      SmartDialog.showToast('请先登录');
      return;
    }
    isLoadingFolderItems.value = true;
    favFolderItems.clear();
    favFolderItemsRaw.clear();
    try {
      final res = await FavHttp.userFavFolderDetail(
        mediaId: mediaId,
        pn: 1,
        ps: 50,
      );
      if (res is Success<FavDetailData>) {
        final data = res.response;
        final medias = data.medias;
        if (kDebugMode) {
          debugPrint(
            'Loaded ${medias?.length ?? 0} items from folder $mediaId',
          );
        }
        if (medias != null && medias.isNotEmpty) {
          // 过滤掉失效的视频 (attr == 9 表示失效)
          final validMedias = medias
              .where(
                (m) => m.title != null && m.title!.isNotEmpty && m.attr != 9,
              )
              .toList();
          favFolderItemsRaw.value = validMedias;
          favFolderItems.value = validMedias.map(_mediaToMusicItem).toList();
        }
      } else if (res is Error) {
        if (kDebugMode) {
          debugPrint('Load fav folder items error: ${res.errMsg}');
        }
        SmartDialog.showToast(res.errMsg ?? '加载失败');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Load fav folder items exception: $e');
      SmartDialog.showToast('加载失败: $e');
    } finally {
      isLoadingFolderItems.value = false;
    }
  }

  void importFolderToPlaylist() {
    for (final item in favFolderItems) {
      addToPlaylist(item);
    }
  }

  FavDetailItemModel? getRawFavItem(int index) {
    if (index >= 0 && index < favFolderItemsRaw.length) {
      return favFolderItemsRaw[index];
    }
    return null;
  }

  bool hasMultipleParts(int index) {
    final rawItem = getRawFavItem(index);
    return rawItem != null && (rawItem.page ?? 1) > 1;
  }

  Future<List<Part>?> loadVideoParts(String bvid) async {
    isLoadingParts.value = true;
    videoParts.clear();
    selectedPartIndices.clear();
    try {
      final result = await VideoHttp.videoIntro(bvid: bvid);
      if (result is Success) {
        final pages = result.data.pages;
        if (pages != null && pages.length > 1) {
          videoParts.value = pages;
          return pages;
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Load video parts error: $e');
    } finally {
      isLoadingParts.value = false;
    }
    return null;
  }

  void togglePartSelection(int index) {
    if (selectedPartIndices.contains(index)) {
      selectedPartIndices.remove(index);
    } else {
      selectedPartIndices.add(index);
    }
  }

  void toggleSelectAllParts() {
    if (selectedPartIndices.length == videoParts.length) {
      selectedPartIndices.clear();
    } else {
      selectedPartIndices.value = List.generate(videoParts.length, (i) => i);
    }
  }

  void importSelectedParts(FavDetailItemModel item) {
    if (selectedPartIndices.isEmpty) {
      SmartDialog.showToast('请选择要导入的分P');
      return;
    }
    for (final index in selectedPartIndices) {
      if (index < videoParts.length) {
        final part = videoParts[index];
        addToPlaylist(
          MusicItem(
            musicId: '${item.bvid}_p${index + 1}',
            title: '${item.title} - P${index + 1} ${part.part ?? ""}',
            artist: item.upper?.name ?? '',
            cover: item.cover ?? '',
            mvAid: item.id,
            mvBvid: item.bvid,
            mvCid: part.cid,
          ),
        );
      }
    }
    SmartDialog.showToast('已导入${selectedPartIndices.length}个分P到播放列表');
    videoParts.clear();
    selectedPartIndices.clear();
  }

  void importSinglePart(FavDetailItemModel item, int partIndex, Part part) {
    addToPlaylist(
      MusicItem(
        musicId: '${item.bvid}_p${partIndex + 1}',
        title: '${item.title} - P${partIndex + 1} ${part.part ?? ""}',
        artist: item.upper?.name ?? '',
        cover: item.cover ?? '',
        mvAid: item.id,
        mvBvid: item.bvid,
        mvCid: part.cid,
      ),
    );
    SmartDialog.showToast('已添加到播放列表');
  }

  MusicItem _mediaToMusicItem(FavDetailItemModel item) {
    return MusicItem(
      musicId: item.bvid ?? item.id?.toString() ?? '',
      title: item.title ?? '',
      artist: item.upper?.name ?? '',
      cover: item.cover ?? '',
      mvAid: item.id,
      mvBvid: item.bvid,
      mvCid: item.ugc?.firstCid,
    );
  }

  void stopAndRelease() {
    _player?.pause();
    _player?.stop();
    isPlaying.value = false;
    _clearMediaNotification();
  }

  Future<void> loadCachedItems() async {
    isLoadingCache.value = true;
    cachedItems.clear();
    try {
      final downloadService = Get.find<DownloadService>();
      await downloadService.waitForInitialization;
      for (final entry in downloadService.downloadList) {
        cachedItems.add(
          MusicItem(
            musicId: 'cache_${entry.cid}',
            title: entry.showTitle,
            artist: entry.ownerName ?? '',
            cover: entry.cover,
            mvAid: entry.avid,
            mvBvid: entry.bvid,
            mvCid: entry.cid,
            isLocal: true,
            localPath: entry.entryDirPath,
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Load cached items error: $e');
    } finally {
      isLoadingCache.value = false;
    }
  }

  void setCacheQuality(VideoQuality quality) {
    cacheQuality.value = quality;
  }

  void setCacheAudioQuality(AudioQuality quality) {
    cacheAudioQuality.value = quality;
  }

  Future<void> cacheCurrentVideo() async {
    final music = currentMusic.value;
    if (music == null || music.mvBvid == null) {
      SmartDialog.showToast('无法获取视频信息');
      return;
    }
    try {
      final infoResult = await VideoHttp.videoIntro(bvid: music.mvBvid!);
      if (infoResult is! Success) {
        SmartDialog.showToast('获取视频信息失败');
        return;
      }
      final pages = infoResult.data.pages;
      if (pages == null || pages.isEmpty) {
        SmartDialog.showToast('无法获取视频分P信息');
        return;
      }
      Part? targetPage;
      if (music.mvCid != null) {
        targetPage = pages.firstWhereOrNull((p) => p.cid == music.mvCid);
      }
      targetPage ??= pages.first;
      Get.find<DownloadService>().downloadVideo(
        targetPage,
        infoResult.data,
        null,
        cacheQuality.value,
      );
      SmartDialog.showToast('已添加到缓存队列');
    } catch (e) {
      SmartDialog.showToast('缓存失败: $e');
    }
  }

  Future<void> deleteCachedItem(MusicItem item) async {
    if (!item.isLocal || item.localPath == null) return;
    try {
      final downloadService = Get.find<DownloadService>();
      final cid = item.mvCid;
      if (cid != null) {
        final entry = downloadService.downloadList.firstWhereOrNull(
          (e) => e.cid == cid,
        );
        if (entry != null) {
          await downloadService.deleteDownload(entry: entry, removeList: true);
          cachedItems.removeWhere((i) => i.musicId == item.musicId);
          SmartDialog.showToast('已删除缓存');
        }
      }
    } catch (e) {
      SmartDialog.showToast('删除失败: $e');
    }
  }

  Future<void> playLocalCache(MusicItem item) async {
    addToPlaylist(item);
    playMusic(playlist.length - 1);
  }

  // 音效控制方法
  Future<void> setAudioEffect(int mode) async {
    audioEffectMode.value = mode;
    await _applyAudioEffect();
  }

  Future<void> setBassBoost(double value) async {
    bassBoost.value = value;
    await _applyAudioEffect();
  }

  Future<void> setTrebleBoost(double value) async {
    trebleBoost.value = value;
    await _applyAudioEffect();
  }

  Future<void> _applyAudioEffect() async {
    final pp = _player?.platform;
    if (pp == null) return;

    String afFilter = 'scaletempo2=max-speed=8';

    switch (audioEffectMode.value) {
      case 1: // 低音增强
        afFilter =
            'scaletempo2=max-speed=8,equalizer=f=60:width_type=o:w=2:g=8,equalizer=f=120:width_type=o:w=2:g=5';
        break;
      case 2: // 人声增强
        afFilter =
            'scaletempo2=max-speed=8,equalizer=f=1000:width_type=o:w=2:g=5,equalizer=f=2000:width_type=o:w=2:g=4,equalizer=f=4000:width_type=o:w=2:g=3';
        break;
      case 3: // 3D环绕 (使用 haas 效果模拟)
        afFilter =
            'scaletempo2=max-speed=8,extrastereo=m=2.5,aecho=0.8:0.88:6:0.4';
        break;
      case 4: // 清晰人声 (降低背景音)
        afFilter =
            'scaletempo2=max-speed=8,highpass=f=200,lowpass=f=3000,equalizer=f=1000:width_type=o:w=1:g=3';
        break;
      case 5: // 自定义均衡器
        final bass = bassBoost.value;
        final treble = trebleBoost.value;
        if (bass != 0 || treble != 0) {
          afFilter = 'scaletempo2=max-speed=8';
          if (bass != 0) {
            afFilter +=
                ',equalizer=f=60:width_type=o:w=2:g=$bass,equalizer=f=120:width_type=o:w=2:g=${bass * 0.7}';
          }
          if (treble != 0) {
            afFilter +=
                ',equalizer=f=8000:width_type=o:w=2:g=$treble,equalizer=f=12000:width_type=o:w=2:g=${treble * 0.8}';
          }
        }
        break;
      default: // 关闭
        afFilter = 'scaletempo2=max-speed=8';
    }

    try {
      await pp.setProperty('af', afFilter);
    } catch (e) {
      if (kDebugMode) debugPrint('Apply audio effect error: $e');
    }
  }

  String getAudioEffectName(int mode) {
    switch (mode) {
      case 1:
        return '低音增强';
      case 2:
        return '人声增强';
      case 3:
        return '3D环绕';
      case 4:
        return '清晰人声';
      case 5:
        return '自定义';
      default:
        return '关闭';
    }
  }

  // 播放列表记忆功能
  void _loadPlaylistMemorySetting() {
    playlistMemoryEnabled.value =
        GStorage.setting.get(_playlistMemoryKey, defaultValue: true) ?? true;
  }

  void togglePlaylistMemory() {
    playlistMemoryEnabled.value = !playlistMemoryEnabled.value;
    GStorage.setting.put(_playlistMemoryKey, playlistMemoryEnabled.value);
    if (playlistMemoryEnabled.value) {
      _savePlaybackMemory();
      SmartDialog.showToast('已开启播放列表记忆');
    } else {
      _clearSavedPlaylist();
      SmartDialog.showToast('已关闭播放列表记忆');
    }
  }

  void _loadSavedPlaylist() {
    if (!playlistMemoryEnabled.value) return;
    try {
      final savedState = GStorage.setting.get(_playlistStateStorageKey);
      if (savedState is String && savedState.isNotEmpty) {
        final decoded = jsonDecode(savedState);
        if (decoded is Map) {
          _restorePlaybackState(Map<String, dynamic>.from(decoded));
          return;
        }
      }

      final savedPlaylist = GStorage.setting.get(_playlistStorageKey);
      if (savedPlaylist is String && savedPlaylist.isNotEmpty) {
        final decoded = jsonDecode(savedPlaylist);
        if (decoded is List) {
          _restorePlaylist(decoded);
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Load saved playlist error: $e');
    }
  }

  void _savePlaylistIfEnabled() {
    if (playlistMemoryEnabled.value) {
      _savePlaybackMemory();
    }
  }

  void _scheduleSavePlaybackMemory() {
    if (!playlistMemoryEnabled.value || playlist.isEmpty) return;
    _memorySaveTimer?.cancel();
    _memorySaveTimer = Timer(
      const Duration(seconds: 2),
      _savePlaybackMemory,
    );
  }

  void _savePlaybackMemory() {
    if (!playlistMemoryEnabled.value) return;
    try {
      final jsonList = playlist.map((e) => e.toJson()).toList();
      if (jsonList.isEmpty) {
        _clearSavedPlaylist();
        return;
      }
      GStorage.setting.put(_playlistStorageKey, jsonEncode(jsonList));
      GStorage.setting.put(
        _playlistStateStorageKey,
        jsonEncode({
          'playlist': jsonList,
          'currentIndex': currentIndex.value,
          'progress': progress.value,
          'duration': duration.value,
          'isShuffleMode': isShuffleMode.value,
          'repeatMode': repeatMode.value,
          'showMV': showMV.value,
        }),
      );
      if (kDebugMode) {
        debugPrint('Saved ${playlist.length} items to playlist');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Save playlist error: $e');
    }
  }

  void _restorePlaybackState(Map<String, dynamic> state) {
    _restorePlaylist(state['playlist'] as List<dynamic>?);
    if (playlist.isEmpty) return;

    currentIndex.value = (state['currentIndex'] as num? ?? 0)
        .toInt()
        .clamp(0, playlist.length - 1)
        .toInt();
    currentMusic.value = playlist[currentIndex.value];
    progress.value = (state['progress'] as num? ?? 0).toDouble();
    duration.value = (state['duration'] as num? ?? 0).toDouble();
    isShuffleMode.value = state['isShuffleMode'] == true;
    repeatMode.value = (state['repeatMode'] as num? ?? 0)
        .toInt()
        .clamp(0, 2)
        .toInt();
    showMV.value = state['showMV'] == true;
    _restoredPendingMedia = true;
    _updateMediaNotification();
  }

  void _restorePlaylist(List<dynamic>? jsonList) {
    if (jsonList == null) return;
    final items = jsonList
        .whereType<Map>()
        .map((e) => MusicItem.fromJson(Map<String, dynamic>.from(e)))
        .where((e) => e.musicId.isNotEmpty)
        .toList();
    if (items.isEmpty) return;

    playlist.value = items;
    if (kDebugMode) {
      debugPrint('Loaded ${items.length} items from saved playlist');
    }
  }

  void _clearSavedPlaylist() {
    GStorage.setting.delete(_playlistStorageKey);
    GStorage.setting.delete(_playlistStateStorageKey);
  }

  // AI歌词功能
  void toggleLyricsView() {
    showLyrics.value = !showLyrics.value;
    if (showLyrics.value && lyrics.isEmpty) {
      loadLyrics();
    }
  }

  Future<void> loadLyrics() async {
    final music = currentMusic.value;
    if (music == null || music.mvBvid == null) {
      lyrics.clear();
      return;
    }

    isLoadingLyrics.value = true;
    lyrics.clear();
    currentLyricIndex.value = 0;

    try {
      // 获取视频播放信息以获取字幕（使用playInfo API）
      final cid = music.mvCid;
      if (cid == null) {
        isLoadingLyrics.value = false;
        return;
      }

      final result = await VideoHttp.playInfo(
        bvid: music.mvBvid,
        cid: cid,
      );

      if (result is Success<PlayInfoData>) {
        final data = result.response;
        final subtitleInfo = data.subtitle;
        if (subtitleInfo?.subtitles?.isNotEmpty == true) {
          // 优先选择AI字幕或中文字幕
          final subtitles = subtitleInfo!.subtitles!;
          var selectedSubtitle = subtitles.firstWhereOrNull(
            (s) => s.lan.startsWith('ai-zh'),
          );
          selectedSubtitle ??= subtitles.firstWhereOrNull(
            (s) => s.lan.contains('zh'),
          );
          selectedSubtitle ??= subtitles.first;

          if (selectedSubtitle.subtitleUrl != null) {
            await _fetchSubtitleContent(selectedSubtitle.subtitleUrl!);
          }
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Load lyrics error: $e');
    } finally {
      isLoadingLyrics.value = false;
    }
  }

  Future<void> _fetchSubtitleContent(String subtitleUrl) async {
    try {
      final result = await VideoHttp.getSubtitleBody(subtitleUrl);
      if (result != null) {
        lyrics.value = result
            .map(
              (item) =>
                  LyricLine.fromSubtitleBody(item as Map<String, dynamic>),
            )
            .toList();
        if (kDebugMode) {
          debugPrint('Loaded ${lyrics.length} lyric lines');
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Fetch subtitle content error: $e');
    }
  }

  void updateCurrentLyricIndex() {
    if (lyrics.isEmpty) return;
    final currentTime = progress.value;

    // 找到当前时间对应的歌词
    for (int i = 0; i < lyrics.length; i++) {
      final lyric = lyrics[i];
      if (currentTime >= lyric.startTime && currentTime < lyric.endTime) {
        if (currentLyricIndex.value != i) {
          currentLyricIndex.value = i;
        }
        return;
      }
    }

    // 如果没找到精确匹配，找最近的
    for (int i = lyrics.length - 1; i >= 0; i--) {
      if (currentTime >= lyrics[i].startTime) {
        if (currentLyricIndex.value != i) {
          currentLyricIndex.value = i;
        }
        return;
      }
    }
  }

  // 点击歌词跳转到对应时间
  void seekToLyric(int index) {
    if (index >= 0 && index < lyrics.length) {
      seekTo(lyrics[index].startTime);
    }
  }
}
