# HY350MAX Smart Mic / Assistant Fix

A Magisk module for the **Magcubic HY350MAX** Bluetooth remote that fixes the conflict between Google Assistant and in-app voice search.

## What it fixes

On the tested HY350MAX, the Bluetooth remote's microphone button emits Linux `KEY_VOICECOMMAND` (`0x246` / Android `VOICE_ASSIST`). The stock key layout maps that button globally to Google Assistant. As a result, holding the microphone button while using voice search in apps such as SmartTube causes Assistant to take over the screen.

This module changes the behavior to:

- **The currently configured Android HOME launcher is foreground:** microphone button launches Google Assistant.
- **Any other app is foreground:** Assistant is not launched; the remote's push-to-talk microphone remains available to the app.

## Tested configuration

- Magcubic HY350MAX
- CleanRom rooted build / Magisk
- Bluetooth remote USB/HID identity: vendor `1d5a`, product `c081`
- Input device name: `Bluetooth remote Keyboard`
- Launcher: automatically detected from Android's current `HOME` activity (Projectivy was used during testing)
- Google Assistant provider: `com.google.android.katniss`

This is deliberately device-specific. Do not install it on a different remote/device unless its key layout and behavior match.

## How it works

Android loads `/system/usr/keylayout/Vendor_1d5a_Product_c081.kl` for this remote. The stock file contains:

```text
key 0xd9     VOICE_ASSIST
key 0x246    VOICE_ASSIST
```

The physical microphone button was verified with `getevent` to generate `KEY_VOICECOMMAND`, corresponding to `0x246`. The module systemlessly overlays the key-layout file with the `0x246` mapping removed.

A Magisk `service.sh` then finds the remote's current `/dev/input/eventX` dynamically and watches the raw `KEY_VOICECOMMAND` event. When the microphone button is pressed, the service resolves Android's currently configured `HOME` activity. If that launcher is the foreground activity, it invokes:

```text
android.intent.action.ASSIST
```

Otherwise the Android action is ignored. The Bluetooth push-to-talk audio behavior is independent of the removed Android key mapping on the tested remote, so in-app voice search continues to work.

## Installation

1. Root the HY350MAX with Magisk (the rooted CleanRom build was used during development).
2. Copy the release ZIP to the projector.
3. Open **Magisk → Modules → Install from storage**.
4. Select the ZIP.
5. Reboot.

Do **not** extract the ZIP before installing it in Magisk.

## Expected behavior

On the currently configured Android launcher/home screen, pressing the microphone button should open Google Assistant. Inside SmartTube or another application, selecting the application's voice-search control and holding the physical microphone button should provide microphone audio without Assistant appearing. Projectivy was used to validate this behavior, but it is not hardcoded.

## Logs

With ADB available:

```sh
adb shell logcat -d -s hy350max-mic-fix
```

Typical messages:

```text
Listening on /dev/input/event6
Mic pressed on HOME (com.spocky.projengmenu) - launching Assistant
Mic pressed outside HOME (com.spocky.projengmenu) - ignored
```

The event number may differ between boots; the module resolves it dynamically.

## Uninstall / recovery

Normal removal: **Magisk → Modules → HY350MAX Smart Mic / Assistant Fix → Remove**, then reboot.

If Android cannot boot normally, remove the module directory from a root-capable recovery/ADB environment:

```text
/data/adb/modules/hy350max-mic-fix
```

The module does not modify the physical `/system` partition; the key-layout change is a Magisk systemless overlay.

## Compatibility notes

This module contains the complete tested `Vendor_1d5a_Product_c081.kl`, so it should only be used with the same HY350MAX Bluetooth remote mapping. Firmware updates may change the stock key-layout file. Re-check compatibility after major ROM/firmware changes.

## License

MIT
