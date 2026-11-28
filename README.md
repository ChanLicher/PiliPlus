# PiliPlus 鸿蒙个人定制版

中文 | [English](README.en.md)

本仓库基于 [dev4harmony/PiliPlus](https://github.com/dev4harmony/PiliPlus)（`ohos` 分支）构建，仅记录相对鸿蒙上游分支的差异改动。基础功能、编译环境配置与常见问题请直接参考上游仓库说明。

## 效果演示

https://github.com/user-attachments/assets/cdfd8747-9656-4f87-a778-a6ffca8eb369

## 相对上游的差异改动

- **鸿蒙原生沉浸光感导航**
  - 平板等横屏场景支持保留原生悬浮底栏，支持单手「智感握姿」自动贴边与回中
  - 极简纯图标顶/底栏（图标视觉比例统一），宽屏合并为单行光感顶栏，顶底栏下方均带对称渐进模糊衬底
- **全站沉浸光感界面与浮层统一**
  - 首页全分类、搜索与结果页、视频详情与评论区、动态、“我的”页（含观看记录/收藏夹/稍后再看）及“关于”页全面适配无色偏中性底色与通透光感卡片
  - 播放器顶栏与悬浮底栏、右侧滑出设置/弹幕/提交片段菜单、居中悬浮弹幕与回复输入框，以及全局三点菜单、确认/单选/举报/更新弹窗均统一为毛玻璃光感样式
  - 播放器按钮随屏幕尺寸自适应，鼠标悬停顶/底栏时暂停自动隐藏，键鼠悬停反馈统一为圆角高亮且纯触屏零误触
- **苹果风格一镜到底转场与丝滑交互动效**
  - 全站视频卡片（首页、热门、排行、搜索及 UP 主卡片、视频相关推荐、观看记录、收藏夹、稍后再看、动态、“我的”页）全面支持苹果物理弹簧曲线的一镜到底放大/缩回转场，退出视频即刻可流畅滚轮滑动
  - 全站卡片统一柔和入场动画、按压回弹与仅鼠标触发的悬停微浮起，搭配高刷平滑惯性鼠标滚轮滚动
- **线程撕裂者（多线程多节点下载加速）**
  - 移植 [Bilibili-thread-ripper](https://github.com/MrTangLuyao/Bilibili-thread-ripper)（MIT 协议）实现多线程分片下载与多节点竞速，支持自动/手动并发与自定义节点，异常自动回退直连
- **仓库与更新检查适配**
  - 设置「关于」页源码链接与更新检查已切换至本仓库，保留上游仓库链接与版本号同步

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
