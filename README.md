# PiliPlus 鸿蒙个人定制版

中文 | [English](README.en.md)

本仓库基于 [dev4harmony/PiliPlus](https://github.com/dev4harmony/PiliPlus)（`ohos` 分支）构建，仅记录相对鸿蒙上游分支的差异改动。基础功能、编译环境配置与常见问题请直接参考上游仓库说明。

## 相对上游的差异改动

- **横屏保留原生悬浮底栏**
  - 在平板等横屏场景下支持保留鸿蒙原生 `HdsTabs` 悬浮底部导航栏，避免强制切换为侧边栏
  - 在「外观设置」中新增对应开关，可按需切换
- **线程撕裂者（多线程多节点下载加速）**
  - 参考 [lemonteaau/PiliPlus](https://github.com/lemonteaau/PiliPlus) 的纯 Dart 实现，移植 [MrTangLuyao/Bilibili-thread-ripper](https://github.com/MrTangLuyao/Bilibili-thread-ripper)（MIT 协议）下载加速层，通过本地 `127.0.0.1` HTTP Range 代理实现多线程分片下载与多 CDN 竞速，兼容现有 `media_kit` / `libmpv` 播放链路
  - 在「音视频设置」中新增「线程撕裂者」总开关、番剧/影视独立开关、海外节点、手动并发数、自动并发数与自定义节点配置；遇到不支持的流、DRM/试看或本地代理异常时自动回退直连
  - 已在应用「关于 → 开源许可」页面注册 `Bilibili-thread-ripper` 的 MIT 协议声明（`docs/licenses/bilibili-thread-ripper.txt`）

## 下载

可在右侧 [Releases](../../releases) 下载构建产物，或参考 [dev4harmony/PiliPlus](https://github.com/dev4harmony/PiliPlus) 自行编译。

## 声明

此项目（PiliPlus）仅用于个人学习与测试，请于下载后 24 小时内删除。所用 API 皆从官方网站收集，不提供任何破解内容。

- 原作者：[guozhigq/pilipala](https://github.com/guozhigq/pilipala)
- 上游作者：[orz12/PiliPalaX](https://github.com/orz12/PiliPalaX)

## 引用与致谢

- [dev4harmony/PiliPlus](https://github.com/dev4harmony/PiliPlus)（鸿蒙版上游仓库）及 [dev4harmony/flutter-dev](https://github.com/orgs/dev4harmony/teams/flutter-dev) 成员
- [bggRGjQaUbCoE/PiliPlus](https://github.com/bggRGjQaUbCoE/PiliPlus)（PiliPlus 主线上游）
- [lemonteaau/PiliPlus](https://github.com/lemonteaau/PiliPlus)（纯 Dart 线程撕裂者播放代理实现参考）
- [MrTangLuyao/Bilibili-thread-ripper](https://github.com/MrTangLuyao/Bilibili-thread-ripper)（线程撕裂者原项目，MIT License）
- [ErBW_s](https://github.com/ErBWs)（`media_kit` 鸿蒙适配者）
- [bilibili-API-collect](https://github.com/SocialSisterYi/bilibili-API-collect)
- [flutter_meedu_videoplayer](https://github.com/zezo357/flutter_meedu_videoplayer)
- [media-kit](https://github.com/media-kit/media-kit)
- [dio](https://pub.dev/packages/dio)
- 以及所有开发者和贡献者
