# Platform Setup

`advanced_chat_kit` itself is pure Dart/Flutter and needs no native
setup. The three plugin dependencies it *does* pull in — `video_player`,
`just_audio`, and `url_launcher` — need the platform configuration below
before they'll work correctly. None of this is optional boilerplate the
package could do for you: it lives in *your app's* `AndroidManifest.xml`
and `Info.plist`, not inside the package.

## Android

**`android/app/src/main/AndroidManifest.xml`**

1. Internet access (needed for network images, video playback, voice
   playback, and link previews):

   ```xml
   <uses-permission android:name="android.permission.INTERNET" />
   ```

2. Android 11+ (`queries`) — required for `url_launcher` to detect
   whether a browser can handle `http`/`https` links (without this
   block, `launchSafeUrl` can silently fail on API 30+):

   ```xml
   <queries>
     <intent>
       <action android:name="android.intent.action.VIEW" />
       <category android:name="android.intent.category.BROWSABLE" />
       <data android:scheme="https" />
     </intent>
   </queries>
   ```

3. **`android/app/build.gradle`** — `minSdkVersion` must be **21** or
   higher (required by `video_player` and `just_audio`):

   ```gradle
   android {
     defaultConfig {
       minSdkVersion 21
     }
   }
   ```

You do **not** need `READ_EXTERNAL_STORAGE`/`READ_MEDIA_*` permissions
for anything in this package — it never picks files itself (see the
architecture doc: image/file picking is the host app's job, typically via
`image_picker`/`file_picker`, which manage their own permissions).

## iOS

**`ios/Runner/Info.plist`**

1. If any link preview, avatar, or media URL you render is plain `http`
   (not `https`), add an App Transport Security exception — otherwise
   iOS blocks the request outright:

   ```xml
   <key>NSAppTransportSecurity</key>
   <dict>
     <key>NSAllowsArbitraryLoads</key>
     <true/>
   </dict>
   ```

   Prefer fixing the URLs to `https` over disabling ATS wholesale if you
   can — this is a blunt escape hatch, not a recommendation.

2. Background audio (only if you want voice messages to keep playing
   while the app is backgrounded — most chat apps don't need this):

   ```xml
   <key>UIBackgroundModes</key>
   <array>
     <string>audio</string>
   </array>
   ```

`video_player` and `url_launcher` need no additional `Info.plist` entries
for the http/https-only usage this package makes of them.

## Web

`video_player` and `just_audio` both work on Flutter Web without extra
setup, subject to browser codec support (H.264/AAC are the safest bet for
cross-browser video/audio). `url_launcher` opens links in a new tab by
default — no configuration needed.

## Not required for this package

- Camera/microphone **permissions** (`Permission.camera`,
  `Permission.microphone` via `permission_handler` or similar) — the
  press-and-hold voice recording *gesture* in [ChatInputBar] is UI-only;
  actually capturing audio is left to the host app's own recorder
  implementation (see the architecture doc's "own it" list for voice
  recording).
- Any Google Maps / geocoding API key — [LocationPreviewCard] renders a
  static image you supply, or a lightweight decorative placeholder; the
  package never calls a maps SDK itself.
