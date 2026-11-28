# PiliPlus HarmonyOS Custom Fork

[中文](README.md) | English

This repository is a personal fork based on the `ohos` branch of [dev4harmony/PiliPlus](https://github.com/dev4harmony/PiliPlus). Only the differences from the HarmonyOS upstream branch are listed below; for general features, build setup, and troubleshooting, please refer to the upstream repository.

## Demo

https://github.com/user-attachments/assets/cdfd8747-9656-4f87-a778-a6ffca8eb369

## Differences from Upstream

- **Native HarmonyOS Immersive Light Navigation**
  - Keeps the native floating bottom navigation bar in landscape mode on tablets, with smart one-handed holding-side reachability and automatic re-centering
  - Minimalist icon-only top and bottom bars with balanced visual sizing, merged into a single glass header row on wide screens with symmetric progressive blur underneath
- **App-Wide Immersive Light UI & Frosted-Glass Overlays**
  - Unified neutral tint-free surface and luminous glass cards across Home tabs, Search & Results, Video Detail & Comments, Dynamics, Mine (History / Favorites / Watch Later), and About pages
  - Consistent frosted-glass styling across the player top/bottom docks, right-sliding settings/danmaku/segment panels, centered floating danmaku & reply composers, 3-dot menus, and global confirm/select/report/update dialogs
  - Screen-adaptive player controls that pause auto-hiding while hovered, with rounded mouse hover highlights and zero accidental touch triggers
- **Apple-Style One-Shot Transitions & Fluid Motion**
  - Physics-based Apple spring zoom-in/zoom-out transitions across video cards app-wide (Home, Hot, Rank, Search & Creator cards, Related videos, History, Favorites, Watch Later, Dynamics, and Mine), with instant scroll-wheel responsiveness on exit
  - Unified gentle card entrance animations, press bounce, mouse-only hover lift, and smooth high-refresh inertial mouse-wheel scrolling
- **Thread Ripper (Multi-Threaded Multi-CDN Acceleration)**
  - Ports [Bilibili-thread-ripper](https://github.com/MrTangLuyao/Bilibili-thread-ripper) (MIT License) for multi-threaded chunked downloading and multi-CDN racing, with auto/manual concurrency, custom nodes, and automatic direct-playback fallback
- **Repository & Update Check Integration**
  - Switches About source links and GitHub Releases update checks to this repository while preserving upstream links and version sync

## Download

Download builds from [Releases](../../releases), or follow the build instructions in [dev4harmony/PiliPlus](https://github.com/dev4harmony/PiliPlus).

## Disclaimer

PiliPlus is intended only for personal learning and testing. Please delete it within 24 hours of downloading. All APIs used are collected from official websites; this project does not provide any cracked content.

- Original author: [guozhigq/pilipala](https://github.com/guozhigq/pilipala)
- Upstream author: [orz12/PiliPalaX](https://github.com/orz12/PiliPalaX)

## Credits & Acknowledgements

- [dev4harmony/PiliPlus](https://github.com/dev4harmony/PiliPlus) (HarmonyOS upstream) and members of [dev4harmony/flutter-dev](https://github.com/orgs/dev4harmony/teams/flutter-dev)
- [bggRGjQaUbCoE/PiliPlus](https://github.com/bggRGjQaUbCoE/PiliPlus) (PiliPlus main upstream)
- [lemonteaau/PiliPlus](https://github.com/lemonteaau/PiliPlus) (pure-Dart Thread Ripper proxy integration reference)
- [MrTangLuyao/Bilibili-thread-ripper](https://github.com/MrTangLuyao/Bilibili-thread-ripper) (original Thread Ripper project, MIT License)
- [ErBW_s](https://github.com/ErBWs) (`media_kit` HarmonyOS adaptation)
- [bilibili-API-collect](https://github.com/SocialSisterYi/bilibili-API-collect)
- [flutter_meedu_videoplayer](https://github.com/zezo357/flutter_meedu_videoplayer)
- [media-kit](https://github.com/media-kit/media-kit)
- [dio](https://pub.dev/packages/dio)
- All other developers and contributors
