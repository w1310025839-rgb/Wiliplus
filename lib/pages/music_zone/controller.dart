import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/http/video.dart';
import 'package:PiliPlus/pages/common/common_list_controller.dart';

class MusicZoneController extends CommonListController {
  // 音乐分区排行榜 rid = 1003
  static const int musicRid = 1003;

  @override
  void onInit() {
    super.onInit();
    queryData();
  }

  @override
  Future<LoadingState> customGetData() {
    // 使用排行榜API获取音乐分区视频 (与rank/zone/controller.dart相同)
    return VideoHttp.getRankVideoList(musicRid);
  }

  @override
  Future<void> onRefresh() {
    page = 1;
    isEnd = false;
    return queryData();
  }
}
