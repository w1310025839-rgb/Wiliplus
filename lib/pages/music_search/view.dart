import 'package:PiliPlus/common/constants.dart';
import 'package:PiliPlus/common/skeleton/video_card_v.dart';
import 'package:PiliPlus/common/widgets/flutter/refresh_indicator.dart';
import 'package:PiliPlus/common/widgets/loading_widget/http_error.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/http/search.dart';
import 'package:PiliPlus/models/common/search/search_type.dart';
import 'package:PiliPlus/models/search/result.dart';
import 'package:PiliPlus/pages/music_player/controller.dart';
import 'package:PiliPlus/utils/grid.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

class MusicSearchPage extends StatefulWidget {
  const MusicSearchPage({super.key});

  @override
  State<MusicSearchPage> createState() => _MusicSearchPageState();
}

class _MusicSearchPageState extends State<MusicSearchPage> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final RxString _keyword = ''.obs;
  final Rx<LoadingState<SearchVideoData?>> _loadingState = Rx(
    LoadingState.loading(),
  );
  final RxList<SearchVideoItemModel> _results = <SearchVideoItemModel>[].obs;
  int _page = 1;
  bool _isEnd = false;
  String? _gaiaVtoken;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _onSearch() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _keyword.value = text;
    _focusNode.unfocus();
    _page = 1;
    _isEnd = false;
    _results.clear();
    _search();
  }

  void _onClear() {
    _textController.clear();
    _keyword.value = '';
    _results.clear();
    _loadingState.value = LoadingState.loading();
  }

  Future<void> _search() async {
    if (_keyword.value.isEmpty) return;

    _loadingState.value = LoadingState.loading();

    final res = await SearchHttp.searchByType<SearchVideoData>(
      searchType: SearchType.video,
      keyword: _keyword.value,
      page: _page,
      tids: 3, // 音乐分区
      gaiaVtoken: _gaiaVtoken,
      onSuccess: (String gaiaVtoken) {
        _gaiaVtoken = gaiaVtoken;
        _search();
      },
    );

    if (res.isSuccess) {
      final data = res.data;
      if (data.list != null) {
        if (_page == 1) {
          _results.value = data.list!;
        } else {
          _results.addAll(data.list!);
        }
        if (data.list!.isEmpty || _results.length >= (data.numResults ?? 0)) {
          _isEnd = true;
        }
      }
      _loadingState.value = Success(_results.isNotEmpty ? data : null);
    } else {
      final errMsg = res is Error ? res.errMsg : '搜索失败';
      _loadingState.value = Error(errMsg);
    }
  }

  Future<void> _loadMore() async {
    if (_isEnd || _keyword.value.isEmpty) return;
    _page++;
    await _search();
  }

  Future<void> _onRefresh() async {
    _page = 1;
    _isEnd = false;
    _results.clear();
    await _search();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = MediaQuery.viewPaddingOf(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _textController,
          focusNode: _focusNode,
          textInputAction: TextInputAction.search,
          keyboardType: TextInputType.text,
          autocorrect: false,
          enableSuggestions: true,
          decoration: const InputDecoration(
            hintText: '搜索音乐',
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 8),
          ),
          onSubmitted: (_) => _onSearch(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear, size: 22),
            onPressed: _onClear,
            tooltip: '清空',
          ),
          IconButton(
            icon: const Icon(Icons.search, size: 22),
            onPressed: _onSearch,
            tooltip: '搜索',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.only(left: padding.left, right: padding.right),
        child: Obx(() {
          if (_keyword.value.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search,
                    size: 64,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '输入关键词搜索音乐',
                    style: TextStyle(color: theme.colorScheme.outline),
                  ),
                ],
              ),
            );
          }
          return refreshIndicator(
            onRefresh: _onRefresh,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(StyleString.safeSpace),
                  sliver: _buildBody(_loadingState.value),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  late final gridDelegate = SliverGridDelegateWithExtentAndRatio(
    mainAxisSpacing: StyleString.cardSpace,
    crossAxisSpacing: StyleString.cardSpace,
    maxCrossAxisExtent: Pref.recommendCardWidth,
    childAspectRatio: StyleString.aspectRatio,
    mainAxisExtent: MediaQuery.textScalerOf(context).scale(90),
  );

  Widget _buildBody(LoadingState<SearchVideoData?> loadingState) {
    return switch (loadingState) {
      Loading() => _buildSkeleton,
      Success() =>
        _results.isNotEmpty
            ? SliverGrid.builder(
                gridDelegate: gridDelegate,
                itemBuilder: (context, index) {
                  final item = _results[index];
                  return RepaintBoundary(
                    child: GestureDetector(
                      onTap: () => _playVideo(item),
                      onLongPress: () => _onVideoLongPress(item, index),
                      child: _buildVideoCard(item),
                    ),
                  );
                },
                itemCount: _results.length,
              )
            : HttpError(
                errMsg: '未找到相关音乐',
                onReload: _onRefresh,
              ),
      Error(:final errMsg) => HttpError(
        errMsg: errMsg,
        onReload: _onRefresh,
      ),
    };
  }

  Widget _buildVideoCard(SearchVideoItemModel item) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  item.cover ?? '',
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => ColoredBox(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.music_note),
                  ),
                ),
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _formatDuration(item.duration),
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  Text(
                    item.owner.name ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final minutes = duration.inMinutes;
    final secs = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _playVideo(SearchVideoItemModel item) {
    // 点击直接跳转到视频播放器
    PageUtils.toVideoPage(
      bvid: item.bvid,
      aid: item.aid,
      cid: item.cid ?? 0,
      cover: item.cover,
      title: item.title,
    );
  }

  void _onVideoLongPress(SearchVideoItemModel item, int index) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add),
              title: const Text('添加到播放列表'),
              onTap: () {
                Navigator.pop(context);
                _addToPlaylist(item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.play_arrow),
              title: const Text('立即播放'),
              onTap: () {
                Navigator.pop(context);
                _playVideo(item);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _addToPlaylist(SearchVideoItemModel item) {
    try {
      MusicPlayerController musicController;
      try {
        musicController = Get.find<MusicPlayerController>();
      } catch (e) {
        musicController = Get.put(MusicPlayerController());
      }

      final musicItem = MusicItem(
        musicId: item.bvid ?? (item.aid?.toString() ?? ''),
        title: item.title,
        artist: item.owner.name ?? '未知作者',
        cover: item.cover ?? '',
        mvAid: item.aid,
        mvBvid: item.bvid,
        mvCid: item.cid,
      );
      musicController.addToPlaylist(musicItem);
      SmartDialog.showToast('已添加到播放列表');
    } catch (e) {
      SmartDialog.showToast('添加失败');
    }
  }

  Widget get _buildSkeleton => SliverGrid.builder(
    gridDelegate: gridDelegate,
    itemBuilder: (context, index) => const VideoCardVSkeleton(),
    itemCount: 10,
  );
}
