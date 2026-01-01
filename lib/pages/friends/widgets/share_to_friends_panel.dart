import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/grpc/bilibili/app/im/v1.pb.dart';
import 'package:PiliPlus/grpc/im.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models/common/image_type.dart';
import 'package:PiliPlus/utils/request_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LengthLimitingTextInputFormatter;
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

/// 好友信息（用于分享面板）
class _FriendItem {
  final int uid;
  final String name;
  final String face;

  _FriendItem({required this.uid, required this.name, required this.face});
}

class ShareToFriendsPanel extends StatefulWidget {
  const ShareToFriendsPanel({super.key, required this.content});

  final Map content;

  @override
  State<ShareToFriendsPanel> createState() => _ShareToFriendsPanelState();
}

class _ShareToFriendsPanelState extends State<ShareToFriendsPanel> {
  final RxList<_FriendItem> _friendsList = <_FriendItem>[].obs;
  final RxSet<int> _selectedUids = <int>{}.obs;
  final Rx<LoadingState> _loadingState = Rx(LoadingState.loading());
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// 从私信会话中加载好友
  Future<void> _loadFriends() async {
    _loadingState.value = LoadingState.loading();
    _friendsList.clear();

    try {
      final res = await ImGrpc.sessionMain();

      if (res is Success<SessionMainReply>) {
        final sessions = res.response.sessions;

        for (final session in sessions) {
          if (!session.id.privateId.hasTalkerUid()) continue;

          final uid = session.id.privateId.talkerUid.toInt();
          final sessionInfo = session.sessionInfo;

          // 获取头像
          final resource = sessionInfo.avatar.fallbackLayers.layers.isNotEmpty
              ? sessionInfo.avatar.fallbackLayers.layers.first.resource
              : null;
          String face = '';
          if (resource != null) {
            if (resource.hasResImage()) {
              face = resource.resImage.imageSrc.remote.url;
            } else if (resource.hasResAnimation()) {
              face = resource.resAnimation.webpSrc.remote.url;
            }
          }

          _friendsList.add(
            _FriendItem(
              uid: uid,
              name: sessionInfo.sessionName,
              face: face,
            ),
          );
        }

        _loadingState.value = const Success(null);
      } else if (res is Error) {
        _loadingState.value = Error(res.errMsg);
      }
    } catch (e) {
      _loadingState.value = Error(e.toString());
    }
  }

  void _toggleSelection(int uid) {
    if (_selectedUids.contains(uid)) {
      _selectedUids.remove(uid);
    } else {
      _selectedUids.add(uid);
    }
  }

  Future<void> _onSend() async {
    if (_selectedUids.isEmpty) {
      SmartDialog.showToast('请选择要分享的好友');
      return;
    }

    SmartDialog.showLoading(msg: '分享中...');

    final results = await Future.wait(
      _selectedUids.map(
        (uid) => RequestUtils.pmShare(
          receiverId: uid,
          content: widget.content,
          message: _messageController.text,
        ),
      ),
    );

    SmartDialog.dismiss();

    if (results.every((e) => e)) {
      Get.back();
      SmartDialog.showToast('分享成功');
    } else if (results.every((e) => !e)) {
      SmartDialog.showToast('分享失败');
    } else {
      SmartDialog.showToast('部分分享失败');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = MediaQuery.paddingOf(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.7,
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: padding.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '分享给好友',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: Get.back,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(child: Obx(() => _buildBody(theme))),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  focusNode: _focusNode,
                  maxLines: 1,
                  decoration: InputDecoration(
                    hintText: '说点什么...',
                    hintStyle: const TextStyle(fontSize: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    fillColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                  inputFormatters: [LengthLimitingTextInputFormatter(100)],
                ),
              ),
              const SizedBox(width: 12),
              Obx(
                () => FilledButton(
                  onPressed: _selectedUids.isEmpty ? null : _onSend,
                  child: Text('发送(${_selectedUids.length})'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    final state = _loadingState.value;
    return switch (state) {
      Loading() => const Center(child: CircularProgressIndicator()),
      Success() =>
        _friendsList.isNotEmpty
            ? GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.8,
                ),
                itemCount: _friendsList.length,
                itemBuilder: (context, index) {
                  final item = _friendsList[index];
                  return _buildFriendItem(item, theme);
                },
              )
            : _buildEmptyState(theme),
      Error(:final errMsg) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              errMsg ?? '加载失败',
              style: TextStyle(color: theme.colorScheme.error),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: _loadFriends, child: const Text('重试')),
          ],
        ),
      ),
    };
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 48,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 8),
          Text(
            '暂无好友',
            style: TextStyle(color: theme.colorScheme.outline),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendItem(_FriendItem item, ThemeData theme) {
    return Obx(() {
      final isSelected = _selectedUids.contains(item.uid);
      return InkWell(
        onTap: () => _toggleSelection(item.uid),
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              children: [
                NetworkImgLayer(
                  width: 50,
                  height: 50,
                  src: item.face,
                  type: ImageType.avatar,
                ),
                if (isSelected)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                        border: Border.all(
                          width: 2,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? theme.colorScheme.primary : null,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    });
  }
}
