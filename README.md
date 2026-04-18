# ⚡ BloxStrike Domination v2.0

> Premium PVP Script Hub for BloxStrike with Auto-Updating Offsets

![Lua](https://img.shields.io/badge/Lua-5.1-blue?logo=lua)
![Version](https://img.shields.io/badge/version-2.0-cyan)
![Status](https://img.shields.io/badge/status-undetected-green)

---

## 🎯 Features

### ⚔ Combat
| Feature | Description |
|---------|-------------|
| **Aimbot** | Smooth camera-based aim with FOV limit, wall check, team check, bone selection, and velocity prediction |
| **Silent Aim** | Redirects shots server-side via namecall hook with configurable hit chance |
| **Triggerbot** | Auto-fires when crosshair hovers over an enemy with adjustable delay |
| **No Recoil** | Stabilizes camera during firing to eliminate recoil |
| **Rapid Fire** | Increases weapon fire rate with speed multiplier |

### 👁 Visuals
| Feature | Description |
|---------|-------------|
| **ESP Boxes** | 2D bounding boxes around all enemies |
| **ESP Names** | Display player names above their character |
| **ESP Health** | Health bars with color gradient (green→red) |
| **ESP Distance** | Shows distance in meters below each player |
| **ESP Skeleton** | Full R15 skeleton wireframe overlay |
| **ESP Tracers** | Lines from screen edge to enemy position |
| **Chams** | Highlight-based wallhack (see through walls) |
| **Custom Crosshair** | Configurable crosshair with gap, size, thickness, and center dot |
| **FOV Circle** | Visual circle showing aimbot targeting range |
| **Fullbright** | Removes all darkness from the map |
| **No Fog** | Removes fog for maximum visibility |
| **Hit Markers** | Visual feedback (X marks) when hitting a player |

### 🏃 Movement
| Feature | Description |
|---------|-------------|
| **Bunny Hop** | Auto-jump when holding space for continuous hopping |
| **Speed Boost** | Adjustable walk speed (16-60, clamped for stealth) |
| **Infinite Jump** | Jump in mid-air without limits |
| **Fly** | Full 3D flight with WASD + Space/Ctrl controls |
| **Noclip** | Walk through walls and solid objects |

### ⚙ Misc
| Feature | Description |
|---------|-------------|
| **Anti-AFK** | Prevents idle disconnect |
| **Kill Sound** | Plays a sound effect when an enemy dies |
| **Third Person** | Locks camera to third-person at configurable distance |
| **Offset Refresh** | Force-refresh game offsets from remote server |
| **Unload** | Cleanly removes all script traces |

---

## 🔄 Auto-Updating Offsets

The script automatically fetches the latest Roblox offsets from:
```
https://offsets.ntgetwritewatch.workers.dev/offsets_structured.hpp
```

- Offsets are fetched on script load
- Auto-refreshes every 5 minutes while running
- Manual refresh button in the Misc tab
- Status displayed in the bottom bar of the UI

---

## 📦 Installation

### Quick Load (Paste in Executor)
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/bloxstrike_hub.lua"))()
```

### Manual
1. Download `bloxstrike_hub.lua`
2. Open your Roblox executor
3. Load and execute the script
4. Press **RightCtrl** to toggle the menu

---

## 🎮 Controls

| Key | Action |
|-----|--------|
| `RightCtrl` | Toggle menu visibility |
| `Right Mouse Button` | Hold to aim (Aimbot) |
| `WASD` | Fly movement directions |
| `Space` | Fly up / Bunny hop |
| `Left Ctrl` | Fly down |

---

## 🛡️ Anti-Detection Notes

- Pure Lua — no DLL injection, no memory writes
- Aimbot uses smooth camera interpolation, not instant snaps
- Speed values clamped to reasonable ranges
- All features wrapped in `pcall` for error safety
- Clean unload removes every trace of the script
- No suspicious remote event spamming

---

## 🏗️ File Structure

```
├── bloxstrike_hub.lua    # Main script (all features)
├── loader.lua            # One-line loader for executors
└── README.md             # This file
```

---

## ⚠️ Disclaimer

This script is provided for educational purposes. Use at your own risk.

---

<p align="center">
  <b>⚡ BloxStrike Domination v2.0 ⚡</b><br>
  <i>Built with precision. Designed to dominate.</i>
</p>
