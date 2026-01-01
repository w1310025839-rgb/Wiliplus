<div align="center">
    <img width="200" height="200" src="assets/images/logo/logo.png">
</div>

<div align="center">
    <h1>Wiliplus</h1>
    <p>使用Flutter开发的BiliBili第三方客户端</p>
    <p>基于 PiliPlus 修改</p>
</div>

<br/>

## 适配平台

- [x] Android
- [x] iOS
- [x] Pad
- [x] Windows
- [x] Linux

## 主要功能

### 视频播放
- 双击快进/快退、播放/暂停
- 手势调节亮度/音量
- 全屏方向设置、倍速选择
- 画质/音质/解码格式选择
- 弹幕、字幕、记忆播放
- 弹幕设置面板（不透明度、显示区域、类型屏蔽等）

### 音乐播放器
- Spotify 风格界面
- 封面/MV 切换显示（左右滑动切换）
- MV 视频比例选择（16:9/2:3）
- 播放控制、随机/循环模式
- 播放列表管理
- 后台播放和通知栏控制
- 收藏夹浏览和导入
- 分P视频选择导入

### 用户功能
- 粉丝、关注、拉黑用户查看
- 离线缓存、稍后再看、观看记录
- 我的收藏、站内私信
- 动态查看和评论

### 其他功能
- DLNA 投屏
- 跳过番剧片头/片尾
- AI 原声翻译
- SuperChat
- 发布动态/评论（富文本/表情/@用户）
- WebDAV 备份/恢复
- 多账号支持
- 互动视频
- 高能进度条
- 主题色自定义

## 性能优化

### 滚动优化
- 主页视频列表使用优化的滚动物理引擎
- Tab 切换添加 RepaintBoundary 隔离重绘
- 搜索框键盘响应优化
- 动态页面滚动优化

### 刷新率同步
- 支持高刷新率显示 (60Hz/90Hz/120Hz/144Hz)
- 设置路径：设置 -> 外观 -> 屏幕帧率

## 构建

```bash
cd PiliPlus-main
flutter clean
flutter pub get
flutter build apk --release
```

## 版本信息

- 当前版本：v0.5.6.2
- 构建时间：01.01.2026
- 问题反馈：w1310025839@gmail.com

## 声明

此项目仅用于学习和测试。
所用API皆从官方网站收集，不提供任何破解内容。

致敬原作者：
- [guozhigq/pilipala](https://github.com/guozhigq/pilipala)
- [orz12/PiliPalaX](https://github.com/orz12/PiliPalaX)
- [bggRGjQaUbCoE/PiliPlus](https://github.com/bggRGjQaUbCoE/PiliPlus)

## 致谢

- [bilibili-API-collect](https://github.com/SocialSisterYi/bilibili-API-collect)
- [media-kit](https://github.com/media-kit/media-kit)
- [dio](https://pub.dev/packages/dio)
