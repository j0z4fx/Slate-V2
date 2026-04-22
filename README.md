# Slate-V2

UI library source lives in `src/`.

Loader:
```lua
local Slate = loadstring(game:HttpGet("https://raw.githubusercontent.com/j0z4fx/Slate-V2/refs/heads/main/loader.lua"))()
```

Current API:
```lua
local window = Slate:CreateWindow({
    Height = 540,
    Width = 960,
    Title = "Slate",
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
