# PiliPlus HarmonyOS Custom Fork

[中文](README.md) | English

This repository is a personal fork based on the `ohos` branch of [dev4harmony/PiliPlus](https://github.com/dev4harmony/PiliPlus). Only the differences from the HarmonyOS upstream branch are listed below; for general features, build setup, and troubleshooting, please refer to the upstream repository.

## Differences from Upstream

- **Native Floating Bottom Navigation Bar in Landscape**
  - Allows keeping the native HarmonyOS `HdsTabs` floating bottom navigation bar in landscape mode (such as on tablets) instead of forcing a side navigation rail
  - Adds a toggle in **Appearance Settings** to switch behavior as needed
- **Thread Ripper (Multi-threaded Multi-CDN Download Acceleration)**
  - Ports the download acceleration layer of [MrTangLuyao/Bilibili-thread-ripper](https://github.com/MrTangLuyao/Bilibili-thread-ripper) (MIT License) following the pure-Dart implementation in [lemonteaau/PiliPlus](https://github.com/lemonteaau/PiliPlus), running a local `127.0.0.1` HTTP Range proxy for multi-threaded chunk downloading and multi-CDN racing on top of the existing `media_kit` / `libmpv` playback pipeline
  - Adds **Thread Ripper** controls under **Video Settings** (master toggle, Bangumi/PGC toggle, overseas CDN toggle, manual concurrency, dynamic auto-concurrency, and custom CDN hosts), with automatic fallback to direct playback for unsupported streams, DRM/preview content, or proxy errors
  - Registers the `Bilibili-thread-ripper` MIT license (`docs/licenses/bilibili-thread-ripper.txt`) in the app's **About → Licenses** page

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
