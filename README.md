# LuminaKit

[English](README.md) | [简体中文](README.zh-CN.md)

Premium soft / translucent / light-forward SwiftUI components.

Minimal. High-key. Built for calm product UIs.

<video src="Docs/Assets/iridescent-blob.mp4" autoplay loop muted playsinline width="420"></video>

## Components

| Component | Description | Preview |
|---|---|---|
| **IridescentBlob** | Translucent pearl blob with liquid folds, thin-film iridescence, soft high-gloss lighting | [MP4](Docs/Assets/iridescent-blob.mp4) · [PNG](Preview/iridescent-blob.png) |

More components will land here as the library grows.

## Requirements

- iOS 17+ / macOS 14+ / tvOS 17+ / visionOS 1+
- Metal

## Installation

### Swift Package Manager

In Xcode: **File → Add Package Dependencies…**

```
https://github.com/chen123aaa/LuminaKit.git
```

Or in `Package.swift`:

```swift
.package(url: "https://github.com/chen123aaa/LuminaKit.git", from: "0.1.0")
```

## Usage

```swift
import LuminaKit

struct ContentView: View {
    var body: some View {
        IridescentBlobView()
            .ignoresSafeArea()
    }
}
```

### Parameters

| Parameter | Type | Default | Meaning |
|---|---|---|---|
| `morph` | `Float` | `1.0` | Fold intensity (`0.4…1.4`) |
| `speed` | `Float` | `1.0` | Playback rate (`0.4…1.8`) |

```swift
IridescentBlobView(morph: 1.2, speed: 0.8)
```

## Design notes

- Soft SDF blob + domain-warped ridged noise (liquid folds)
- Thin-film iridescence biased to silhouette edges and creases
- High-key milk-white base, no harsh shadows
- Light cool-gray field (`#F2F2F3`) to match a calm UI canvas

## Demo

`Demo/IridescentBlobDemo.swift` is a ready `@main` App for macOS / iOS.

## License

[MIT](LICENSE)
