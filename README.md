# Workout Heatmap & Interactive Dropdown Prototype

Interactive workout heatmap prototype built in SwiftUI. Inspired by GitHub-style activity charts featuring interactive spring-based detail dropdowns, and an animated toast for rest days.

---

## Highlights

### 1. Heatmap Bars
* **Responsive Layout:** Distributes bars edge-to-edge using dynamic `Spacer()` alignment so the last bar aligns flush with top header badges.
* **Selecting Dynamics:** Tapping an active workout day expands its bar height (`32pt` → `48pt`) with a glowing pink shadow while dimming non-selected bars (`1.0` → `0.35` opacity).
* **Spring Animation:** Smooth selection changes powered by `.spring(response: 0.3, dampingFraction: 0.7)`.

---

### 2. Rest Day Toast & 'Shake' Micro-Animation
* **Haptic Feedback:** Triggers native system haptics (`.sensoryFeedback(.error)`) on rest day selection.
* **Horizontal Sine-Wave Shake:** Uses a custom `GeometryEffect` (`ShakeEffect`) driven by `animatableData` to perform a springy horizontal error shake.
* **Dismissal Timer:** Uses a unique `@State private var toastID` token to cleanly reset auto-dismiss timers when tapping rest bars repeatedly without interrupting the shake physics.

---

### 3. Interactive Detail Modal Card
* **Auto-Layout Structure:** Positioned cleanly with a flush top-right close icon (`xmark`) sharing the header row alignment without extra background card wrappers.
* **White Pill Badges:** Renders workout duration and location as clean white capsule badges with micro-drop shadows and native Apple emojis (`⏱️`, `🏠`, `🏋️‍♂️`).
* **High-Contrast Close Action:** Solid black `xmark` vector with a `.plain` button style for a sharp visual affordance against light grey containers.

---

### 4. Interactive Playlist Card & Spotify Integration
* **Asynchronous Thumbnail Fetching:** Uses a custom `SpotifyThumbnailView` component that falls back to remote Spotify oEmbed metadata (`https://open.spotify.com/oembed?url=...`) via `AsyncImage` if a local Asset image isn't available.
* **Hover & Press States:** Responds with scaling (`1.01` on hover, `0.98` on click) and subtle background shifts.
* **Cross-Platform URL Handlers:** Utilizes SwiftUI's `@Environment(\.openURL)` to trigger native deep-linking to Spotify playlists across iOS and macOS without relying on UIKit's `UIApplication`.

---

## Micro-Animation Reference

| Animation Element | Implementation Mechanism | Parameters / Curve |
| :--- | :--- | :--- |
| **Bar Selection** | `.animation()` on `height` & `opacity` | `.spring(response: 0.3, dampingFraction: 0.7)` |
| **Error Shake** | `GeometryEffect` with `CGAffineTransform` | `8 * sin(animatableData * .pi * 3)` |
| **Shake Trigger** | `.spring()` toggle on `shakeOffset` (`0` ↔ `1`) | `.spring(response: 0.18, dampingFraction: 0.2)` |
| **Toast Pop-Up** | `.transition(.asymmetric)` | Bottom edge move combined with fade |
| **Card Hover & Tap** | `.scaleEffect()` driven by hover/gesture state | `.easeOut(duration: 0.15)` |

---
