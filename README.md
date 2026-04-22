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
    Width = 960,
    Height = 540,
    Resizable = true,
    SidebarWidth = 220,
    ShowSidebar = true,
    AutoShow = true,
})
```

Harness:
- `harness/init.client.lua` mounts the library in `PlayerGui`
- `harness/Harness.lua` exposes `mount`, `unmount`, `step`, and `snapshotState`
- future MCP-driven test passes can call the harness, wait `0.1`, and then take a Roblox window screenshot
