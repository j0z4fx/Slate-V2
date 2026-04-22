# Slate-V2

Slate-V2 is a Roblox UI library with a remote loader, tab-based layouts, live-updating properties, and a small local harness for fast iteration.

## Quick Start

Load Slate:

```lua
local Slate = loadstring(game:HttpGet("https://cdn.jsdelivr.net/gh/j0z4fx/Slate-V2@main/loader.lua"))()
```

Create a window:

```lua
local Window = Slate:CreateWindow({
    Title = "Example",
    Version = "1.0.1",
    Width = 960,
    Height = 540,
})
```

Add tabs and content:

```lua
local Home = Window:AddTab({
    Title = "Home",
    Icon = "house",
    Active = true,
})

local Group = Home:AddGroupbox("leftColumn", {
    Title = "Example",
})

Group:AddLabel({
    Text = "Library v2.4.1",
    Subtext = "Loaded successfully",
})

Group:AddDivider()
Group:AddSeparator("Section")

local Toggle = Group:AddToggle({
    Text = "Example Toggle",
    Default = false,
})
```

## How It Works

- `Slate:CreateWindow(...)` creates one window instance.
- Every window automatically includes a `Settings` tab.
- Groupboxes belong to tabs, not to the whole window.
- Controls belong to groupboxes.
- Most objects support live updates through direct assignment or `:Set(...)`.

## Core API

### `Slate`

```lua
local Window = Slate:CreateWindow(config)
Slate:Destroy()
```

`Slate:Destroy()` destroys all mounted Slate windows for the current runtime and clears the owned root GUI.

### `Window`

Create with:

```lua
local Window = Slate:CreateWindow({
    Title = "Slate",        -- default: "Slate"
    Version = "1.0.0",      -- optional
    Width = 960,            -- default: 960
    Height = 540,           -- default: 540
    Resizable = true,       -- default: true
    SidebarWidth = 55,      -- default: 55
    ShowSidebar = true,     -- default: true
    AutoShow = true,        -- default: true
})
```

Window methods:

```lua
Window:AddTab(config)
Window:SelectTab(tab)
Window:Set(property, value)
Window:Update(properties)
Window:Show()
Window:Hide()
Window:Destroy()
```

Live window properties:

```lua
Window.Title = "New Title"
Window.Version = "1.0.2"
Window.Width = 900
Window.Height = 500
Window.ShowSidebar = false
Window.SidebarWidth = 64
Window.Visible = true
```

### `Tab`

Create with:

```lua
local Tab = Window:AddTab({
    Title = "Home",
    Icon = "house",
    Active = true,
    Visible = true,
    Order = 1,
})
```

Notes:

- `Settings` is always present automatically.
- The auto-created `Settings` tab uses a 2-column layout.
- Regular tabs currently default to 3 columns.

Tab methods:

```lua
Tab:AddGroupbox(column, config)
Tab:Select()
Tab:Show()
Tab:Hide()
Tab:Set(property, value)
Tab:Update(properties)
Tab:Destroy()
```

Tab columns:

```lua
Tab.leftColumn
Tab.middleColumn
Tab.rightColumn
```

You can pass either a column object or a column name:

```lua
Tab:AddGroupbox("leftColumn", { Title = "Example" })
Tab:AddGroupbox(Tab.middleColumn, { Title = "Other" })
```

### `Groupbox`

Create with:

```lua
local Groupbox = Tab:AddGroupbox("leftColumn", {
    Title = "Example",
})
```

Groupbox methods:

```lua
Groupbox:AddToggle(config)
Groupbox:AddLabel(config)
Groupbox:AddDivider()
Groupbox:AddSeparator(config)
```

### `Toggle`

Create with:

```lua
local Toggle = Groupbox:AddToggle({
    Text = "Example Toggle",
    Default = false,
    Disabled = false,
    Visible = true,
    Callback = function(value)
        print("Toggle changed:", value)
    end,
})
```

Toggle methods:

```lua
Toggle:SetValue(true)
Toggle:Toggle()
Toggle:OnChanged(function(value) end)
Toggle:Set(property, value)
Toggle:Update(properties)
Toggle:Destroy()
```

Live toggle properties:

```lua
Toggle.Value = true
Toggle.Text = "Renamed Toggle"
Toggle.Disabled = true
Toggle.Visible = false
```

### `Label`

Create with:

```lua
local Label = Groupbox:AddLabel({
    Text = "Library v2.4.1",
    Subtext = "Loaded successfully",
})
```

Label methods:

```lua
Label:Set(property, value)
Label:Update(properties)
Label:Destroy()
```

Live label properties:

```lua
Label.Text = "Main text"
Label.Subtext = "Secondary text"
Label.Visible = true
```

### `Divider`

Create with:

```lua
local Divider = Groupbox:AddDivider()
```

This is a plain horizontal line using Slate's divider color.

### `Separator`

Create with:

```lua
local Separator = Groupbox:AddSeparator({
    Text = "Section",
    Visible = true,
})
```

Or:

```lua
Groupbox:AddSeparator("Section")
```

Separator methods:

```lua
Separator:Set(property, value)
Separator:Update(properties)
Separator:Destroy()
```

## Harness

The harness lives in `harness/` and is useful for iterative Roblox-side checks.

- `harness/Harness.lua` exposes `mount`, `unmount`, `Destroy`, `step`, and `snapshotState`
- `harness/init.client.lua` mounts Slate into `PlayerGui`

The intended workflow is:

1. mount the library
2. make a UI change
3. wait a short amount of time
4. inspect state or take a screenshot
5. repeat

## Notes

- `Window:AddGroupbox(...)` is intentionally unsupported now. Use `Tab:AddGroupbox(...)`.
- The shipped single-file build lives in `dist/main.lua`.
- Source code lives in `src/`.
- More detailed API documentation lives in `docs.md`.
