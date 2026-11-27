# PiliPlus 鸿蒙个人定制版

中文 | [English](README.en.md)

本仓库基于 [dev4harmony/PiliPlus](https://github.com/dev4harmony/PiliPlus)（`ohos` 分支）构建，仅记录相对鸿蒙上游分支的差异改动。基础功能、编译环境配置与常见问题请直接参考上游仓库说明。

## 效果演示

https://github.com/user-attachments/assets/cdfd8747-9656-4f87-a778-a6ffca8eb369

## 相对上游的差异改动

- **鸿蒙原生沉浸光感顶底栏深度定制**
  - **横屏保留原生悬浮底栏与智感握姿**：平板等横屏场景支持保留鸿蒙原生 `HdsTabs` 悬浮底栏（可在「外观设置」开关）；在「鸿蒙特色功能」中新增「底栏跟随智感握姿」开关，受支持设备单手握持时底栏平滑移至左/右下角，双手或平放时自动回中
  - **极简纯图标与宽屏单行光感顶栏**：底栏去除文字标签仅保留图标；首页分类（直播/推荐/热门/分区/番剧/影视）改用鸿蒙原生 `SymbolGlyph` 图标胶囊并随按钮数量自适应居中，宽屏下与右侧缩短后的搜索栏、通知和头像合并为单行且统一为 `56vp` 视觉体量，竖屏保持两行并同步光感化
  - **顶底对称渐进模糊与键鼠悬停反馈**：在顶栏与底栏下方均叠加鸿蒙原生 `linearGradientBlur` 渐进模糊与渐变衬底，消除硬分界线并提升悬浮胶囊可见度；所有顶底栏按钮与搜索栏均支持鼠标悬停高亮及微放大反馈
- **全站沉浸光感界面与浮层菜单改造**
  - **三点毛玻璃浮层菜单**：将视频卡片右下角三点菜单重构为根 `Overlay` 实时 `BackdropFilter` 毛玻璃浮层，移除悬停“显示菜单”提示，支持边缘防裁切/上下自适应翻转与全屏点击取消（不误触底层卡片），且弹出时不隐藏鸿蒙原生底栏及模糊背景
  - **搜索页与搜索结果页全分类光感化**：统一无色偏中性浅/深底色，将搜索输入页（搜索栏、联想、热搜、发现、历史）与搜索结果页（顶部搜索栏、全部分类 Tab、视频/用户/专栏筛选条及全分类卡片与相关 UP 卡片）全部升级为靠左自适应高光玻璃胶囊与圆角光感卡片，补齐鼠标悬停高亮微缩放并清理多余 Tooltip
  - **首页全分类统一光感化**：除推荐流外，将首页番剧/影视（追番时间表、追番与推荐网格卡片）、直播（关注栏、分区栏、子标签栏与直播间卡片）、热门（顶部入口胶囊与横向视频卡）及分区（左侧悬浮玻璃导航栏）全部统一为一致的轻量光感风格
- **动效、流畅度与键鼠交互优化**
  - **瀑布流动效与无停顿平滑滚轮**：视频卡片支持鸿蒙重减速曲线微弹性入场、按压微缩回弹及真实鼠标悬停微浮起（限定 `PointerDeviceKind.mouse` 触发，避免纯触控误弹出）；修复返回首页时封面短暂闪灰问题，并基于 120Hz `Ticker` 指数阻尼覆写全应用鼠标滚轮平滑滚动
  - **低开销光感渲染与转场优化**：纯色底上的静态玻璃胶囊、筛选条与列表卡片采用渐变高光玻璃 + `RepaintBoundary` 替代高开销离屏 `BackdropFilter`，仅在透底浮层保留实时模糊；搜索页输入框改为转场动画完成后延迟聚焦，消除进出搜索页掉帧
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
