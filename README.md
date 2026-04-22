# Slate-V2

UI library source lives in `src/`.

Loader:
```lua
local Slate = loadstring(game:HttpGet("https://cdn.jsdelivr.net/gh/j0z4fx/Slate-V2@main/loader.lua"))()
```

Current API:
```lua
local window = Slate:CreateWindow({
    Title = "Slate",
    Version = "1.0.0",
    Width = 960,
    Height = 540,
    Resizable = true,
    SidebarWidth = 55,
    ShowSidebar = true,
    AutoShow = true,
})

window.Title = "Example"
window.Version = "1.0.1"
window.Width = 900
window:Set({
    Height = 500,
    ShowSidebar = false,
})

local homeTab = window:AddTab({
    Title = "Home",
    Icon = "house",
    Active = true,
})

local profileTab = window:AddTab({
    Title = "Profile",
    Icon = "user-round",
})

profileTab.Icon = "settings"
homeTab.Active = true
```

Destroy:
```lua
window:Destroy()
Slate:Destroy()
```

Harness:
- `harness/init.client.lua` mounts the library in `PlayerGui`
- `harness/Harness.lua` exposes `mount`, `unmount`, `Destroy`, `step`, and `snapshotState`
- future MCP-driven test passes can call the harness, wait `0.1`, and then take a Roblox window screenshot
