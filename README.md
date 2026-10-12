# LuminaKit

[English](README.md) | [简体中文](README.zh-CN.md)

Premium soft / translucent / light-forward UI components.
Minimal, high-key, built for calm product interfaces.

SwiftUI for native, plain HTML/CSS/JS for the web. No web dependencies.

## Components

| Component | Platform | Description | Preview |
|---|---|---|---|
| **IridescentBlob** | SwiftUI | Translucent pearl blob with liquid folds, thin-film iridescence, soft high-gloss lighting | [GIF](Docs/Assets/iridescent-blob.gif) · [MP4](Docs/Assets/iridescent-blob.mp4) |
| **GlowButton** | Web | Button whose soft glow and rim highlight track the pointer | [GIF](Docs/Assets/glow-button.gif) |

---

## IridescentBlob — SwiftUI

https://github.com/user-attachments/assets/2d0a54fe-cfac-43f4-9cd3-441d9c33a029

**Requirements:** iOS 17+ / macOS 14+ / tvOS 17+ / visionOS 1+, Metal

**Install** — Xcode → *File → Add Package Dependencies…*

```
https://github.com/chen123aaa/LuminaKit.git
```

**Usage**

```swift
import LuminaKit

IridescentBlobView()                       // default
IridescentBlobView(morph: 1.2, speed: 0.8)
```

| Parameter | Type | Default | Meaning |
|---|---|---|---|
| `morph` | `Float` | `1.0` | Fold intensity (`0.4…1.4`) |
| `speed` | `Float` | `1.0` | Playback rate (`0.4…1.8`) |

---

## GlowButton — Web

![GlowButton](Docs/Assets/glow-button.gif)

A button whose glow follows the cursor, with a short trailing lag so the light
feels like it has weight. Soft radial glow, rim highlight and a specular dot all
track the pointer.

**Install** — copy the two files, or reference them directly:

```html
<link rel="stylesheet" href="web/glow-button/lumina-glow-button.css">
<script src="web/glow-button/lumina-glow-button.js"></script>

<button class="lg-btn">Continue</button>
```

The script auto-initialises every `.lg-btn` on the page.

**Tune it with CSS custom properties**

```css
.lg-btn {
  --lg-glow: 111 199 255;   /* glow color as "r g b" */
  --lg-glow-size: 160;      /* trailing glow radius, px */
  --lg-glow-alpha: 1;       /* 0–1 strength */
  --lg-radius: 14;          /* corner radius, px */
}
```

Add `.lg-btn--light` when the button sits on a light backdrop.

**Demo:** open [`web/index.html`](web/index.html).

---

## Design notes

- Soft SDF blob + domain-warped ridged noise (liquid folds)
- Thin-film iridescence biased to silhouette edges and creases
- High-key milk-white base, no harsh shadows
- Glow follows with a lerped pointer so the light trails instead of snapping

## License

[MIT](LICENSE)
