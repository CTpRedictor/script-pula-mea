# BloxStrike Domination v5.0

Premium stealth script hub for BloxStrike with full anti-detection.

## Features

### Combat
- **Aimbot** - Smooth aim assist with human-like jitter and randomized interpolation
- **Silent Aim** - Server-side shot redirection via namecall hook (always-on hook, feature toggle)
- **Triggerbot** - Auto-fire with randomized delay variance
- **No Recoil** - Camera stabilization during fire

### Visuals
- **Player ESP** - Boxes, names, health bars, distance, tracers (Drawing API only)
- **Custom Crosshair** - Configurable size, gap, thickness, color presets, center dot
- **Fullbright** - See in dark areas
- **No Fog** - Remove fog effects
- **Fog Color** - Custom fog color from 11 presets
- **Sky Override** - Atmosphere-based sky color override
- **Ambient Color** - Custom ambient lighting color
- **FOV Changer** - Camera field of view control (40-120)
- **Clock Time** - Set time of day (0-24)
- **Brightness** - Custom lighting brightness (0-5)
- **Bloom** - BloomEffect toggle
- **Blur** - BlurEffect with adjustable size (1-30)
- **Color Correction** - Brightness, contrast, saturation control (-100 to 100)
- **Sun Rays** - SunRaysEffect toggle

### Movement
- **Bunny Hop** - Auto jump when holding space
- **Speed Boost** - CFrame-based speed (no WalkSpeed modification)
- **Infinite Jump** - Jump in mid-air
- **Fly** - CFrame-based flight (no BodyVelocity)
- **Noclip** - Walk through walls

### Utility
- **Anti-AFK** - Prevents idle kick
- **Third Person Lock** - Lock camera distance
- **Auto-Updating Offsets** - Manual fetch of latest Roblox offsets

### Config System
- **Save/Load** - Save custom configs to executor filesystem (JSON)
- **Preset: Default** - Everything disabled
- **Preset: Legit** - Balanced features for subtle play
- **Preset: Risk** - Maximum feature activation

## Anti-Detection (v5.0)

### Layer 1: Remote Interception
The `__namecall` metamethod is hooked immediately on load (before GUI creation) to intercept ALL `FireServer`/`InvokeServer` calls. Any remote with anti-cheat keywords in its name (`ban`, `kick`, `detect`, `report`, `flag`, `security`, `cheat`, `exploit`, `hack`, `verify`, `check`, `scan`, `monitor`, `integrity`, `valid`, etc.) is silently blocked from reaching the server. This prevents the anti-cheat from reporting violations even if other detection vectors fire.

### Layer 2: GUI Enumeration Hiding
`GetChildren` and `GetDescendants` are hooked via `hookfunction` + `newcclosure` to filter our ScreenGui and all its descendants from the results when called on CoreGui, PlayerGui, or gethui(). The game's anti-cheat scripts literally cannot see our GUI exists.

### Layer 3: Anti-Cheat Script Neutralization
On load, all `LocalScript` instances in the game are scanned by name. Any script containing anti-cheat keywords (`anticheat`, `anti_cheat`, `ac_`, `detect`, `security`, `guard`, `shield`, `protect`, `cheatcheck`, `exploitcheck`, `integrity`) is disabled immediately.

### Layer 4: Connection Scanning
If `getconnections` is available, all connections on `RenderStepped`, `Heartbeat`, and `Stepped` are scanned. Any connection from a script with "anticheat" in its source path is disabled.

### Layer 5: Stealth Design
| Detection Vector | Method |
|---|---|
| GUI Parent | `gethui()` → `syn.protect_gui` → CoreGui → PlayerGui (priority cascade) |
| Instance Names | All randomized per execution (12-16 char random strings) |
| GUI DisplayOrder | Fixed at 1 (normal) |
| Speed Hack | CFrame-based movement (no WalkSpeed/BodyVelocity) |
| Fly Hack | CFrame teleportation (no BodyVelocity/BodyGyro) |
| Aimbot | Human jitter + randomized smoothing alpha |
| Triggerbot | Randomized delay +/- 20ms variance |
| Silent Aim | Integrated into anti-cheat hook (single hook, no double-hooking) |
| Re-execution | getgenv() reference cleanup |
| HTTP Requests | Manual only (zero requests on startup) |

## Usage

1. Open your executor (Xeno, Fluxus, KRNL, etc.)
2. Copy entire contents of `bloxstrike_hub.lua`
3. Paste into executor and execute
4. Press **RightCtrl** to toggle menu

## Controls

| Key | Action |
|---|---|
| RightCtrl | Toggle menu |
| Right Click (hold) | Activate aimbot |

## Config Files

Configs are saved as JSON to the executor's workspace directory:
- `bsd_custom.json` - User saved config

## Offset Fetching

The offset fetcher tries multiple HTTP methods in order:
1. `game:HttpGet()` (most compatible)
2. `request()` (generic)
3. `http_request()` (KRNL/Wave)
4. `syn.request()` (Synapse)

If the URL returns HTML (blocked by executor), it reports "URL blocked". If no HTTP method works, it reports "no HTTP access".

## Notes

- All features use pcall wrapping for crash protection
- ESP uses Drawing API (executor-side rendering, invisible to game)
- Speed/Fly use CFrame manipulation (no detectable body movers)
- GUI elements use randomized names on every execution
- __namecall hook is always active for anti-cheat blocking
- Silent aim piggybacks on the anti-cheat hook (no separate hook needed)
- No HTTP requests made on startup
- Full unload with Lighting restoration and Drawing cleanup
- Compatible with all major executors (Xeno, Fluxus, KRNL, Synapse, Wave, Delta)
