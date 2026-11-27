# PiliPlus HarmonyOS Custom Fork

[中文](README.md) | English

This repository is a personal fork based on the `ohos` branch of [dev4harmony/PiliPlus](https://github.com/dev4harmony/PiliPlus). Only the differences from the HarmonyOS upstream branch are listed below; for general features, build setup, and troubleshooting, please refer to the upstream repository.

## Demo

https://github.com/user-attachments/assets/cdfd8747-9656-4f87-a778-a6ffca8eb369

## Differences from Upstream

- **HarmonyOS Native Immersive Light Top & Bottom Bar Overhaul**
  - **Landscape Native Floating Bottom Bar & Smart Reachability**: Allows keeping the native HarmonyOS `HdsTabs` floating bottom navigation bar in landscape mode (toggled in **Appearance Settings**), and adds a **Smart Holding-Hand Bottom Bar** toggle under **HarmonyOS Features** so supported devices smoothly slide the bottom capsule to the left/right corner on one-handed hold and re-center on two-handed or flat placement
  - **Icon-Only Minimalism & Wide Single-Row Glass Top Bar**: Removes bottom bar text labels for a clean icon-only capsule; replaces home category tabs (Live / Recommended / Hot / Channels / Bangumi / Cinema) with adaptive-width HarmonyOS `SymbolGlyph` icon capsules centered in the header, merged into a single `56vp`-tall row alongside a compact search pill, notification, and avatar buttons on wide screens (retaining a two-row glass layout in portrait)
  - **Symmetric Progressive Blur & Mouse Hover Feedback**: Adds native ArkUI `linearGradientBlur` progressive blur and gradient scrims beneath both top and bottom bars to remove hard edges and boost legibility over colorful covers, with smooth hover highlight and scale feedback across all top/bottom bar controls
- **App-Wide Immersive Light UI & Frosted-Glass Menus**
  - **Frosted-Glass 3-Dot Popup Menu**: Replaces the stock `PopupMenuButton` on video cards with a root-`Overlay` `BackdropFilter` frosted-glass menu (removing the hover "Show menu" tooltip), featuring automatic viewport edge clamping/flipping, tap-anywhere dismissal without triggering underlying cards, and keeping the native HarmonyOS bottom bar and blur scrim intact while open
  - **Search & Full Search Result Tabs Overhaul**: Switches both the search page and search result page to a neutral tint-free surface with left-aligned adaptive luminous-glass capsules for the search bar, category tabs, and Video/User/Article filter bars, alongside rounded glass cards across all search tabs (All, Video, Bangumi/Cinema, Live, User, Article) and related creator cards with hover highlight/scale feedback
  - **Unified Home Tabs Styling**: Extends the lightweight luminous-glass aesthetic beyond the Recommended feed to Bangumi/Cinema (timeline, follow, and index grids), Live (follow strip, area/tag bars, and room cards), Hot (top shortcut pill and horizontal cards), and Channels/Rank (floating glass side rail)
- **Motion, Rendering Performance & Input Polish**
  - **Smooth Feed Motion & 120Hz Inertial Mouse-Wheel Scrolling**: Adds HarmonyOS-curved micro-spring card entrance, press bounce, and real-mouse-only (`PointerDeviceKind.mouse` `onHover`) hover lift to prevent ghost pop-outs in pure touch mode; eliminates brief cover blanking when returning from video pages, and implements 120Hz `Ticker`-driven exponential-damping smooth mouse-wheel scrolling across lists
  - **Lightweight Glass Rendering & Smooth Page Transitions**: Uses gradient luminous-glass surfaces with `RepaintBoundary` on solid-background capsules, filter bars, and list cards (reserving real-time `BackdropFilter` for floating overlays), and defers search input focus until after route push animations finish to eliminate transition frame drops
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
