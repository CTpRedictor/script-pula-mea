# BloxStrike Domination v4.0

Premium stealth script hub for BloxStrike with full anti-detection.

## Features

### Combat
- **Aimbot** - Smooth aim assist with human-like jitter (anti-detect)
- **Silent Aim** - Redirects shots server-side via namecall hook
- **Triggerbot** - Auto-fire with randomized delay (anti-detect)
- **No Recoil** - Camera stabilization during fire

### Visuals
- **Player ESP** - Boxes, names, health bars, distance, tracers (Drawing API only - invisible to anti-cheat)
- **Custom Crosshair** - Configurable size, gap, thickness, center dot
- **Fullbright** - See in dark areas
- **No Fog** - Remove fog effects

### Movement
- **Bunny Hop** - Auto jump when holding space
- **Speed Boost** - CFrame-based speed (no WalkSpeed modification = undetected)
- **Infinite Jump** - Jump in mid-air
- **Fly** - CFrame-based flight (no BodyVelocity = undetected)
- **Noclip** - Walk through walls

### Utility
- **Anti-AFK** - Prevents idle kick
- **Third Person Lock** - Lock camera distance
- **Auto-Updating Offsets** - Fetches latest Roblox offsets automatically

## Anti-Detection (v4.0)

| Detection Vector | Old Method (Detected) | v4.0 Method (Stealth) |
|---|---|---|
| GUI Names | `BloxStrikeDom`, `BSDom` | Random 16-char strings |
| GUI Parent | CoreGui (scanned by BAC) | `gethui()` (invisible to game) |
| Speed Hack | Direct `WalkSpeed` change | CFrame-based movement |
| Fly Hack | `BodyVelocity` + `BodyGyro` | CFrame teleportation |
| Chams | `Highlight` instances | Removed (Drawing ESP only) |
| Aimbot | Perfect tracking | Human-like jitter + random alpha |
| Triggerbot | Fixed delay | Randomized delay (+/- 20ms) |
| HTTP Fetch | Immediate on load | Delayed 2-4 seconds |
| Instance Names | Readable names | All randomized |

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

## Notes

- All features use `pcall` wrapping for crash protection
- ESP uses Drawing API (executor-side rendering, invisible to game)
- Speed/Fly use CFrame manipulation (no detectable body movers)
- GUI elements use randomized names on every execution
- Compatible with all major executors (Xeno, Fluxus, KRNL, Synapse, Wave, Delta)
