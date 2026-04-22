# Reference Detection Audit

Scope: `C:\Users\vvs\Documents\Slate-v2\Refrences`, excluding `infiniteyield`.

Reviewed targets:
- `Lucide.lua`
- `LinoriaLib`
- `Obsidian`
- `Rayfield`
- `Sirius`
- `WindUI`

Method:
- I searched for executor-aware and stealth-related primitives such as `gethui`, `syn.protect_gui`, `cloneref`, `hookmetamethod`, `getconnections`, `identifyexecutor`, executor HTTP shims, global environment writes, and GUI parenting to `CoreGui`.
- Where source and built output both existed, I preferred source files for the audit and only used generated output to confirm behavior.

## Executive Summary

| Library | Detection/Protection Rating | Bottom line |
| --- | --- | --- |
| `Lucide.lua` | None to Low | Asset/cache helper only. No active concealment or interference logic found. |
| `LinoriaLib` | Low | Minimal concealment. Uses `syn.protect_gui` and `CoreGui`, but no active anti-detection logic. |
| `Obsidian` | Low to Moderate | More concealment-aware than Linoria because it prefers `gethui`, but still mostly compatibility and cleanup. |
| `Rayfield` | Moderate | Hidden-parent support plus optional log suppression and built-in telemetry/fingerprinting. |
| `Sirius` | High | Active Protection/interference: anonymous text rewriting, anti-idle, anti-kick hooks, request interception, hidden loading. |
| `WindUI` | Low to Moderate | Hidden-parent support and executor abstractions, but no active anti-kick or anti-idle logic found in source. |

## Lucide.lua

Verdict: this is not an anti-detection component.

Evidence:
- `C:\Users\vvs\Documents\Slate-v2\Refrences\Lucide.lua:1-18` initializes a local icon cache, creates a `lucide-icons` folder, and writes a version file.
- `C:\Users\vvs\Documents\Slate-v2\Refrences\Lucide.lua:20-33` updates cached spritesheets and checks whether `getcustomasset` is working.
- `C:\Users\vvs\Documents\Slate-v2\Refrences\Lucide.lua:40-49` is static icon registry/index data.

Assessment:
- `Lucide.lua` uses executor filesystem APIs and `getcustomasset`, but only for icon storage and retrieval.
- I did not find hidden-parent GUI logic, executor fingerprinting, global API hooking, metamethod hooks, anti-idle behavior, or kick interception in this file.
- It is a dependency/support asset, not a self-protection layer.

## LinoriaLib

Verdict: this is the least stealthy library in the set.

Evidence:
- `C:\Users\vvs\Documents\Slate-v2\Refrences\LinoriaLib\Library.lua:12-18` resolves `protectgui` / `syn.protect_gui`, applies it to a `ScreenGui`, then parents the UI straight into `CoreGui`.
- `C:\Users\vvs\Documents\Slate-v2\Refrences\LinoriaLib\Library.lua:23-24` exports `Toggles` and `Options` into `getgenv()`, which increases global visibility rather than reducing it.
- `C:\Users\vvs\Documents\Slate-v2\Refrences\LinoriaLib\addons\SaveManager.lua:110-151` and `C:\Users\vvs\Documents\Slate-v2\Refrences\LinoriaLib\addons\ThemeManager.lua:53-75,208-221` use executor filesystem APIs for settings/themes, but that is persistence, not stealth.

Assessment:
- Concealment is limited to the classic Synapse-era `protect_gui` pattern.
- There is no `gethui` hidden parent fallback.
- I found no `hookmetamethod`, no anti-idle logic, no kick interception, no executor fingerprinting, and no request interception in the library itself.
- Operationally, this means LinoriaLib can hide a GUI from some executor-aware UI scanners, but it does not actively resist inspection or client enforcement.

## Obsidian

Verdict: Obsidian is stealth-aware, but mostly in the sense of "run safely across executors" rather than "evade detection aggressively."

Evidence:
- `C:\Users\vvs\Documents\Slate-v2\Refrences\Obsidian\Library.lua:1-20` wraps core services in `cloneref`, resolves `protectgui`, and defines `gethui`.
- `C:\Users\vvs\Documents\Slate-v2\Refrences\Obsidian\Library.lua:1157-1185` uses `SafeParentUI` to prefer `gethui`, fall back to `CoreGui`, and finally fall back to `PlayerGui` if hidden parenting fails.
- `C:\Users\vvs\Documents\Slate-v2\Refrences\Obsidian\addons\SaveManager.lua:1-35` clones and wraps `isfolder`, `isfile`, and `listfiles` so broken executor implementations do not throw unexpectedly.
- `C:\Users\vvs\Documents\Slate-v2\Refrences\Obsidian\addons\ThemeManager.lua:1-35` repeats the same defensive wrapper pattern for theme persistence.
- `C:\Users\vvs\Documents\Slate-v2\Refrences\Obsidian\Library.lua:2078-2082` destroys the active `ScreenGui` and clears `getgenv().Library` on teardown.
- `C:\Users\vvs\Documents\Slate-v2\Refrences\Obsidian\Library.lua:9366-9367` re-exports the active library into `getgenv()` at startup.

Assessment:
- The `gethui` + `protectgui` combo is a real concealment surface because it keeps the UI out of ordinary `PlayerGui` paths when the executor supports hidden UI.
- `cloneref` use reduces dependency on raw service objects and makes the library more resilient inside executor-patched environments.
- The filesystem wrappers are executor hardening, not anti-detection. They make the code survive bad exploit implementations; they do not hide the library from Roblox or anti-cheat code.
- Cleanup of `getgenv().Library` on destroy is a modest footprint-reduction step, but not a serious stealth system.
- I found no metamethod hooks, no idle suppression, no kick suppression, and no request/global API interception in the reviewed Obsidian files.

## Rayfield

Verdict: Rayfield is more operationally mature than Linoria/Obsidian, but its distinguishing behavior is telemetry and observability control.

Evidence:
- `C:\Users\vvs\Documents\Slate-v2\Refrences\Rayfield\source.lua:80-100` reads `DISABLE_RAYFIELD_REQUESTS`, `RAYFIELD_ASSET_ID`, and `RAYFIELD_SECURE` from `getgenv()`. If `RAYFIELD_SECURE` is set, it suppresses `warn` and `print`, and replaces `error`/`assert` messages with stripped-down behavior.
- `C:\Users\vvs\Documents\Slate-v2\Refrences\Rayfield\source.lua:131-152` exposes "Anonymised Analytics" and forces it off when requests are disabled.
- `C:\Users\vvs\Documents\Slate-v2\Refrences\Rayfield\source.lua:163-164` loads a remote prompt helper and resolves executor-specific request functions.
- `C:\Users\vvs\Documents\Slate-v2\Refrences\Rayfield\source.lua:272-280` downloads `reporter.lua` remotely and executes it unless requests have been disabled.
- `C:\Users\vvs\Documents\Slate-v2\Refrences\Rayfield\source.lua:732-740` and `1894-1902` parent both the main UI and the key UI into `gethui`, or `syn.protect_gui`, or `RobloxGui` / `CoreGui` as fallback.
- `C:\Users\vvs\Documents\Slate-v2\Refrences\Rayfield\source.lua:743-751` and `1905-1913` disable and rename older instances of the same GUI to avoid duplicate visible artifacts.
- `C:\Users\vvs\Documents\Slate-v2\Refrences\Rayfield\reporter.lua:198-225` fingerprints executor, version, platform, hashed user ID, and locale.
- `C:\Users\vvs\Documents\Slate-v2\Refrences\Rayfield\reporter.lua:233-247` discovers whichever HTTP primitive the current executor exposes.
- `C:\Users\vvs\Documents\Slate-v2\Refrences\Rayfield\reporter.lua:314-322` POSTs telemetry with a token header.
- `C:\Users\vvs\Documents\Slate-v2\Refrences\Rayfield\reporter.lua:393-400` polls `CoreGui.RobloxPromptGui.promptOverlay` for the kick/error overlay.
- `C:\Users\vvs\Documents\Slate-v2\Refrences\Rayfield\reporter.lua:466-475` explicitly records whether secure mode and custom asset mode are active.

Assessment:
- Hidden-parent support is standard executor concealment.
- The strongest self-protection behavior here is `RAYFIELD_SECURE`, because it reduces the amount of debugging output and message detail available to someone observing the script locally.
- The remote reporter is a privacy and operational telemetry surface, not direct anti-detection. It helps the maintainers understand environment and kick outcomes; it does not stop kicks.
- I found no `hookmetamethod` use, no anti-idle, and no direct interception of `LocalPlayer:Kick()` in Rayfield itself.

## Sirius

Verdict: Sirius is the only reference in scope that clearly implements active evasion/interference rather than just hidden GUI placement.

Evidence:
- `C:\Users\vvs\Documents\Slate-v2\Refrences\Sirius\source.lua:87-100` creates an ESP container in `gethui` or `CoreGui`.
- `C:\Users\vvs\Documents\Slate-v2\Refrences\Sirius\source.lua:750-758` parents the main UI into `gethui` or `CoreGui`.
- `C:\Users\vvs\Documents\Slate-v2\Refrences\Sirius\source.lua:395-400` defines an `Anonymous Client` setting whose purpose is explicitly to randomize the local username in `CoreGui`-parented interfaces.
- `C:\Users\vvs\Documents\Slate-v2\Refrences\Sirius\source.lua:4457-4469` implements that behavior by scanning cached text labels, storing originals, replacing occurrences of the local username/display name with a random alias, and restoring them later via `undoAnonymousChanges()`.
- `C:\Users\vvs\Documents\Slate-v2\Refrences\Sirius\source.lua:449-453` describes `Anti Idle` as removing callbacks/events linked to `LocalPlayer.Idled`.
- `C:\Users\vvs\Documents\Slate-v2\Refrences\Sirius\source.lua:4532-4534` executes that behavior by iterating `getconnections(localPlayer.Idled)` and disabling those connections when the setting is enabled.
- `C:\Users\vvs\Documents\Slate-v2\Refrences\Sirius\source.lua:456-461` describes a `Client-Based Anti Kick` feature.
- `C:\Users\vvs\Documents\Slate-v2\Refrences\Sirius\source.lua:3749-3769` implements anti-kick by using `hookmetamethod` on both `__index` and `__namecall`, intercepting `Kick` on `LocalPlayer`, and preventing the call from executing.
- `C:\Users\vvs\Documents\Slate-v2\Refrences\Sirius\source.lua:682-691` defines `Intelligent HTTP Interception` and `Intelligent Clipboard Interception`.
- `C:\Users\vvs\Documents\Slate-v2\Refrences\Sirius\source.lua:2799-2840` replaces the executor's global request and clipboard functions with wrappers that prompt before allowing outbound HTTP or clipboard writes.
- `C:\Users\vvs\Documents\Slate-v2\Refrences\Sirius\source.lua:2423-2441` caches enabled Core UI components and disables them through `StarterGui:SetCoreGuiEnabled`.
- `C:\Users\vvs\Documents\Slate-v2\Refrences\Sirius\source.lua:2538-2539` restores the cached Core UI later.
- `C:\Users\vvs\Documents\Slate-v2\Refrences\Sirius\source.lua:434-438` defines a `Load Hidden` option.
- `C:\Users\vvs\Documents\Slate-v2\Refrences\Sirius\source.lua:3804-3830` implements `Load Hidden` by closing the SmartBar on boot instead of opening it.

Assessment:
- `Sirius` goes beyond hidden-parent UI and into active behavior shaping.
- `Anonymous Client` is a real concealment feature aimed at obfuscating the local identity inside `CoreGui` interfaces.
- `Anti Idle` and `Client-Based Anti Kick` directly interfere with normal client behavior and the executor environment.
- The HTTP/clipboard interception is defensive from Sirius's point of view, but it also demonstrates that Sirius is willing to replace global executor APIs to control what other scripts can do.
- This is the strongest anti-detection / anti-interference reference in the folder by a wide margin.

## WindUI

Verdict: WindUI is executor-aware and hidden-parent capable, but I did not find active anti-kick or anti-idle behavior in the source tree.

Evidence:
- `C:\Users\vvs\Documents\Slate-v2\Refrences\WindUI\src\Init.lua:54-56` resolves `protectgui` and chooses `gethui` or `CoreGui` / `PlayerGui` as the GUI parent.
- `C:\Users\vvs\Documents\Slate-v2\Refrences\WindUI\src\Init.lua:64-110` creates multiple `ScreenGui` roots (`WindUI`, notifications, dropdowns, tooltips) under that parent and applies `ProtectGui` to each of them.
- `C:\Users\vvs\Documents\Slate-v2\Refrences\WindUI\src\modules\Creator.lua:1-21` wraps services with `cloneref` and remotely loads icon data outside Studio.
- `C:\Users\vvs\Documents\Slate-v2\Refrences\WindUI\src\modules\Creator.lua:41` abstracts HTTP through `http_request`, `syn.request`, or `request`.
- `C:\Users\vvs\Documents\Slate-v2\Refrences\WindUI\src\modules\Creator.lua:755-770` downloads remote image assets to disk and loads them as custom assets.
- `C:\Users\vvs\Documents\Slate-v2\Refrences\WindUI\src\modules\Creator.lua:789` calls `identifyexecutor()` only to produce an error/warning message.
- Repository-wide source review did not find `hookmetamethod`, `getconnections(localPlayer.Idled)`, `TeleportService` persistence hooks, or kick interception logic in `WindUI/src`.

Assessment:
- WindUI follows the same concealment template as Obsidian and Rayfield for UI placement: hide the UI when the executor offers `gethui`, and protect the ScreenGuis when possible.
- Its request abstraction is about compatibility and remote asset loading, not stealth.
- The absence of metamethod hooks and idle/kick manipulation matters here: WindUI hides its interface, but it does not appear to actively interfere with client enforcement behavior.

## Ranking By Stealth/Interference Depth

1. `Sirius`
2. `Rayfield`
3. `Obsidian`
4. `WindUI`
5. `LinoriaLib`
6. `Lucide.lua`
