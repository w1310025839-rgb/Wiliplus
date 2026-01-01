import 'package:PiliPlus/common/widgets/flutter/refresh_indicator.dart';
import 'package:PiliPlus/common/widgets/loading_widget/http_error.dart';
import 'package:PiliPlus/http/dynamics.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models/common/dynamic/dynamics_type.dart';
import 'package:PiliPlus/models/dynamics/result.dart';
import 'package:PiliPlus/pages/dynamics/widgets/dynamic_panel.dart';
import 'package:PiliPlus/pages/friends/controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FriendDynamicsTab extends StatefulWidget {
  const FriendDynamicsTab({super.key});

  @override
  State<FriendDynamicsTab> createState() => _FriendDynamicsTabState();
}

class _FriendDynamicsTabState extends State<FriendDynamicsTab>
    with AutomaticKeepAliveClientMixin {
  final Rx<LoadingState<DynamicsDataModel?>> _loadingState = Rx(
    LoadingState.loading(),
  );
  final RxList<DynamicItemModel> _dynamicsList = <DynamicItemModel>[].obs;
  final ScrollController _scrollController = ScrollController();

  String? _offset;
  bool _isEnd = false;

  late final FriendsController _friendsController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _friendsController = Get.find<FriendsController>();
    _scrollController.addListener(_onScroll);
    _waitForFriendsAndLoad();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _waitForFriendsAndLoad() async {
    // 等待好友列表加载完成
    while (_friendsController.friendsState.value is Loading) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    _loadDynamics();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadDynamics() async {
    _loadingState.value = LoadingState.loading();
    _offset = null;
    _isEnd = false;
    _dynamicsList.clear();

    // 如果没有好友，直接显示空状态
    if (_friendsController.friendMids.isEmpty) {
      _loadingState.value = const Success(null);
      return;
    }

    final res = await DynamicsHttp.followDynamic(
      type: DynamicsTabType.all,
      offset: '',
    );

    if (res is Success<DynamicsDataModel>) {
      final data = res.response;
      final friendMids = _friendsController.friendMids;

      // 筛选好友的动态
      final filteredItems = (data.items ?? [])
          .where(
            (item) =>
                item.modules.moduleAuthor?.mid != null &&
                friendMids.contains(item.modules.moduleAuthor?.mid),
          )
          .toList();

      _dynamicsList.addAll(filteredItems);
      _offset = data.offset;
      _isEnd = data.hasMore != true;

      // 如果筛选后数量太少，继续加载
      if (_dynamicsList.length < 10 && !_isEnd) {
        await _loadMore();
      }

      _loadingState.value = const Success(null);
    } else if (res is Error) {
      _loadingState.value = Error(res.errMsg);
    }
  }

  Future<void> _loadMore() async {
    if (_isEnd || _offset == null) return;

    final res = await DynamicsHttp.followDynamic(
      type: DynamicsTabType.all,
      offset: _offset!,
    );

    if (res is Success<DynamicsDataModel>) {
      final data = res.response;
      final friendMids = _friendsController.friendMids;

      final filteredItems = (data.items ?? [])
          .where(
            (item) =>
                item.modules.moduleAuthor?.mid != null &&
                friendMids.contains(item.modules.moduleAuthor?.mid),
          )
          .toList();

      _dynamicsList.addAll(filteredItems);
      _offset = data.offset;
      _isEnd = data.hasMore != true;
      _loadingState.refresh();
    }
  }

  Future<void> _onRefresh() async {
    await _friendsController.onRefresh();
    await _loadDynamics();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    return Obx(() => _buildBody(_loadingState.value, theme));
  }

  Widget _buildBody(LoadingState<DynamicsDataModel?> state, ThemeData theme) {
    return switch (state) {
      Loading() => const Center(child: CircularProgressIndicator()),
      Success() =>
        _dynamicsList.isNotEmpty
            ? refreshIndicator(
                onRefresh: _onRefresh,
                child: ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: _dynamicsList.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = _dynamicsList[index];
                    return DynamicPanel(
                      item: item,
                      maxWidth: MediaQuery.sizeOf(context).width - 24,
                    );
                  },
                ),
              )
            : _buildEmptyState(theme),
      Error(:final errMsg) => HttpError(
        errMsg: errMsg,
        onReload: _loadDynamics,
      ),
    };
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.dynamic_feed_outlined,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            '好友暂无动态',
            style: TextStyle(color: theme.colorScheme.outline),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _onRefresh,
            child: const Text('刷新'),
          ),
        ],
      ),
    );
  }
}
