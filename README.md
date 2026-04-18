# BloxStrike Domination v5.0

Premium stealth script hub for BloxStrike with full anti-detection.

## Features

### Combat
- **Aimbot** - Smooth aim assist with human-like jitter and randomized interpolation
- **Silent Aim** - Server-side shot redirection via namecall hook (manual init only)
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
- **Preset: Legit** - Subtle settings (high smoothing aimbot, ESP, crosshair, anti-AFK)
- **Preset: Risk** - Aggressive settings (low smoothing, high FOV, all combat features, speed, bhop)

## Anti-Detection (v5.0)

| Detection Vector | Old Method (Detected) | v5.0 Method (Stealth) |
|---|---|---|
| GUI Cleanup Marker | `_bsdom` BoolValue child | `getgenv()` reference tracking |
| Startup Notifications | 3x GUI Frame popups on load | Drawing API text (zero GUI instances) |
| GUI Parent | CoreGui / PlayerGui | `gethui()` priority (invisible to game) |
| Silent Aim Init | Auto-hook on script load | Manual init only when user enables |
| Offset Fetch | Auto HTTP on load (2-4s delay) | Manual fetch only via button |
| Speed Hack | Direct WalkSpeed change | CFrame-based movement |
| Fly Hack | BodyVelocity + BodyGyro | CFrame teleportation |
| Aimbot | Perfect tracking | Human jitter + randomized alpha |
| Triggerbot | Fixed delay | Randomized delay +/- 20ms |
| Instance Names | Readable names | All randomized per execution |
| GUI DisplayOrder | Random 50-150 (suspicious) | Fixed at 1 (normal) |
| Re-execution | BoolValue scan + destroy | getgenv reference cleanup |

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

## Notes

- All features use pcall wrapping for crash protection
- ESP uses Drawing API (executor-side rendering, invisible to game)
- Speed/Fly use CFrame manipulation (no detectable body movers)
- GUI elements use randomized names on every execution
- Silent Aim only hooks metatables when manually enabled
- No HTTP requests made on startup
- Full unload with Lighting restoration and Drawing cleanup
- Compatible with all major executors (Xeno, Fluxus, KRNL, Synapse, Wave, Delta)
