# Slate-V2 Documentation

## Overview

Slate-V2 is a Roblox UI library built around four layers:

1. `Slate`
2. `Window`
3. `Tab`
4. `Groupbox`

Controls are attached to groupboxes. Groupboxes are attached to tabs. Tabs are attached to a window.

This matters because visible content is page-based. When a tab is selected, only that tab's page is shown.

## Installation

```lua
local Slate = loadstring(game:HttpGet("https://raw.githubusercontent.com/j0z4fx/Slate-V2/main/loader.lua"))()
```

If you want to pin a specific version, replace `@main` with a commit hash.

## Creating a Window

```lua
local Window = Slate:CreateWindow({
    Title = "Slate",
    Version = "1.0.0",
    Width = 960,
    Height = 540,
    Resizable = true,
    SidebarWidth = 55,
    ShowSidebar = true,
    AutoShow = true,
})
```

### Window Config

| Property | Type | Default | Notes |
| --- | --- | --- | --- |
| `Title` | `string` | `"Slate"` | Shown in the title bar |
| `Version` | `string?` | `nil` | Hidden when `nil` or empty |
| `Width` | `number` | `960` | Window width in pixels |
| `Height` | `number` | `540` | Window height in pixels |
| `Resizable` | `boolean` | `true` | Stored and exposed for future resize logic |
| `SidebarWidth` | `number` | `55` | Width of the tab rail |
| `ShowSidebar` | `boolean` | `true` | Hides or shows the sidebar |
| `AutoShow` | `boolean` | `true` | Initial visibility |

### Window Methods

```lua
Window:AddTab(config)
Window:SelectTab(tab)
Window:Set(property, value)
Window:Update(properties)
Window:Show()
Window:Hide()
Window:SetTitle(title)
Window:SetVersion(version)
Window:SetResizable(resizable)
Window:SetSidebarWidth(width)
Window:SetSidebarVisible(visible)
Window:SetSize(size)
Window:Destroy()
```

### Live Window Updates

```lua
Window.Title = "Example"
Window.Version = "1.0.1"
Window.Width = 900
Window.Height = 500
Window.ShowSidebar = false
Window.SidebarWidth = 64
Window.Visible = true
```

## Tabs

Tabs are page containers. Every tab gets its own content page and its own columns.

```lua
local Home = Window:AddTab({
    Title = "Home",
    Icon = "house",
    Active = true,
})
```

### Tab Config

| Property | Type | Default | Notes |
| --- | --- | --- | --- |
| `Title` | `string` | `"Tab"` | Sidebar title/identity |
| `Icon` | `string` | `"circle-question-mark"` | Uses lucide-roblox asset mapping |
| `Active` | `boolean` | `false` | If true, becomes the selected tab |
| `Visible` | `boolean` | `true` | Controls tab visibility |
| `Order` | `number` | auto | Sidebar order |
| `LayoutColumns` | `number` | `3` | Clamped between 1 and 3 |

### Settings Tab

Each window automatically creates a `Settings` tab:

- title: `Settings`
- icon: `settings`
- layout: 2 columns

You can access it through:

```lua
local Settings = Window.Tabs.Settings
```

### Tab Methods

```lua
Tab:AddGroupbox(column, config)
Tab:Select()
Tab:Show()
Tab:Hide()
Tab:Set(property, value)
Tab:Update(properties)
Tab:Destroy()
```

### Tab Columns

Each tab exposes:

```lua
Tab.leftColumn
Tab.middleColumn
Tab.rightColumn
```

For 2-column layouts like `Settings`, `rightColumn` is `nil`.

## Groupboxes

Groupboxes are the main control containers inside tab columns.

```lua
local Box = Home:AddGroupbox("leftColumn", {
    Title = "Example",
})
```

### Groupbox Config

| Property | Type | Default |
| --- | --- | --- |
| `Title` | `string` | `"Groupbox"` |
| `LayoutOrder` | `number` | auto |

### Groupbox Methods

```lua
Groupbox:AddToggle(config)
Groupbox:AddLabel(config)
Groupbox:AddDivider()
Groupbox:AddSeparator(config)
```

### Dragging

Groupboxes are draggable by their title bar. The library locks the lifted width while dragging so the groupbox does not expand across the whole page. A placeholder outline shows where the box will land.

## Toggle

Toggle behavior is state-driven and supports live mutation.

```lua
local Toggle = Box:AddToggle({
    Text = "Example Toggle",
    Default = false,
    Disabled = false,
    Visible = true,
    Callback = function(value)
        print(value)
    end,
})

local Picker = Toggle:AddColorPicker({
    Title = "Toggle Color",
    Default = Color3.fromRGB(255, 91, 155),
})

local Bind = Toggle:AddKeyPicker({
    Default = "RightShift",
    Mode = "Toggle",
})
```

### Toggle Config

| Property | Type | Default |
| --- | --- | --- |
| `Text` | `string` | `"Toggle"` |
| `Default` | `boolean` | `false` |
| `Disabled` | `boolean` | `false` |
| `Visible` | `boolean` | `true` |
| `Callback` | `function?` | `nil` |
| `Changed` | `function?` | `nil` |

### Toggle Methods

```lua
Toggle:Get(property)
Toggle:Set(property, value)
Toggle:Update(properties)
Toggle:SetValue(value)
Toggle:SetText(text)
Toggle:SetDisabled(disabled)
Toggle:SetVisible(visible)
Toggle:Toggle()
Toggle:OnChanged(callback)
Toggle:Destroy()
```

### Toggle Addons

```lua
Toggle:AddColorPicker(config)
Toggle:AddKeyPicker(config)
```

These mount inline to the right side of the toggle row.

## Color Picker

Color pickers are currently exposed as toggle addons.

```lua
local Picker = Toggle:AddColorPicker({
    Title = "Accent",
    Default = Color3.fromRGB(255, 91, 155),
    Callback = function(value)
        print(value)
    end,
})
```

### Color Picker Methods

```lua
Picker:SetValue(Color3.fromRGB(255, 0, 0))
Picker:OnChanged(function(value) end)
Picker:Open()
Picker:Close()
Picker:Destroy()
```

## Key Picker

Key pickers are currently exposed as toggle addons.

```lua
local Bind = Toggle:AddKeyPicker({
    Default = "RightShift",
    Mode = "Toggle",
    SyncToggleState = false,
})
```

### Key Picker Methods

```lua
Bind:SetValue("F")
Bind:SetMode("Hold")
Bind:GetState()
Bind:OnChanged(function(value) end)
Bind:OnClick(function(value) end)
Bind:Destroy()
```

Supported modes:

- `Toggle`
- `Hold`
- `Always`

### Toggle Style

Off state:

- body: `#20202E`
- stroke: `#2E2E44`
- dot: `#5E5E7E`

On state:

- body: accent color
- stroke: hidden
- dot: white

Animation:

- `TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)`

## Label

Labels can optionally show subtext.

```lua
local Label = Box:AddLabel({
    Text = "Library v2.4.1",
    Subtext = "Loaded successfully",
})
```

### Label Config

| Property | Type | Default |
| --- | --- | --- |
| `Text` | `string` | `"Label"` |
| `Subtext` | `string?` | `nil` |
| `Visible` | `boolean` | `true` |

### Label Methods

```lua
Label:Set(property, value)
Label:Update(properties)
Label:Destroy()
```

### Label Colors

- primary text: `#D4D4EC`
- subtext: `#5E5E7E`

## Divider

Divider is a plain horizontal line.

```lua
local Divider = Box:AddDivider()
```

### Divider Style

- line color: `#25252E`

## Separator

Separator is a divider with centered text.

```lua
local Separator = Box:AddSeparator({
    Text = "Separator",
})
```

Short form:

```lua
Box:AddSeparator("Separator")
```

### Separator Config

| Property | Type | Default |
| --- | --- | --- |
| `Text` | `string` | `"Separator"` |
| `Visible` | `boolean` | `true` |

### Separator Style

- text color: `#525E72`
- line color: `#25252E`

## Destroying UI

Destroy a single window:

```lua
Window:Destroy()
```

Destroy all mounted Slate windows in the current runtime:

```lua
Slate:Destroy()
```

Slate tracks mounted windows in a shared global registry so cross-load cleanup still works even when the library is reloaded through `loadstring(...)`.

## Harness

The harness exists for fast iteration and MCP-driven verification.

Files:

- `harness/Harness.lua`
- `harness/init.client.lua`

Current harness methods:

```lua
Harness.mount(api, parent)
Harness.unmount()
Harness.snapshotState()
Harness.step(delaySeconds)
Harness:Destroy()
```

Typical usage:

1. mount the library into a known parent
2. create tabs/groupboxes/controls
3. wait a short time like `0.1`
4. inspect state or screenshot
5. repeat until the visual pass is clean

## Example

Current example flow:

```lua
local Slate = loadstring(game:HttpGet("https://raw.githubusercontent.com/j0z4fx/Slate-V2/main/loader.lua"))()

local Window = Slate:CreateWindow({
    Title = "Example",
    Version = "1.0.1",
    Width = 960,
    Height = 540,
})

local Home = Window:AddTab({
    Title = "Home",
    Icon = "house",
    Active = true,
})

local Box = Home:AddGroupbox("leftColumn", {
    Title = "Example",
})

Box:AddLabel({
    Text = "Library v2.4.1",
    Subtext = "Loaded successfully",
})

Box:AddDivider()
Box:AddSeparator("Separator")
Box:AddToggle({
    Text = "Example Toggle",
    Default = false,
})
```
