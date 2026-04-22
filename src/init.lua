local Theme = require(script.theme.Theme)
local Button = require(script.components.Button)
local Checkbox = require(script.components.Checkbox)
local Code = require(script.components.Code)
local ColorPicker = require(script.components.ColorPicker)
local Dialog = require(script.components.Dialog)
local Dropdown = require(script.components.Dropdown)
local Root = require(script.core.Root)
local Input = require(script.components.Input)
local Notification = require(script.components.Notification)
local Paragraph = require(script.components.Paragraph)
local Slider = require(script.components.Slider)
local Tag = require(script.components.Tag)
local Tabbox = require(script.components.Tabbox)
local Window = require(script.components.Window)
local Divider = require(script.components.Divider)
local Groupbox = require(script.components.Groupbox)
local KeyPicker = require(script.components.KeyPicker)
local Label = require(script.components.Label)
local Separator = require(script.components.Separator)
local Toggle = require(script.components.Toggle)

local Slate = {}

local getGlobalEnvironment = getgenv or function()
    return _G
end

local runtime = getGlobalEnvironment()
runtime.__SlateMountedWindows = runtime.__SlateMountedWindows or {}

local mountedWindows = runtime.__SlateMountedWindows

Slate.Theme = Theme
Slate.Button = Button
Slate.Checkbox = Checkbox
Slate.Code = Code
Slate.ColorPicker = ColorPicker
Slate.Dialog = Dialog
Slate.Divider = Divider
Slate.Dropdown = Dropdown
Slate.Groupbox = Groupbox
Slate.Input = Input
Slate.KeyPicker = KeyPicker
Slate.Label = Label
Slate.Notification = Notification
Slate.Paragraph = Paragraph
Slate.Separator = Separator
Slate.Slider = Slider
Slate.Tag = Tag
Slate.Tabbox = Tabbox
Slate.Toggle = Toggle

local function destroyMountedWindows()
    for index = #mountedWindows, 1, -1 do
        local window = mountedWindows[index]
        if window and not window._destroyed then
            window:Destroy()
        end

        mountedWindows[index] = nil
    end
end

local function normalizeWindowConfig(selfOrConfig, config)
    if selfOrConfig == Slate then
        return config or {}
    end

    if type(selfOrConfig) == "table" then
        return selfOrConfig
    end

    return {}
end

function Slate:CreateWindow(config)
    local windowConfig = normalizeWindowConfig(self, config)
    local target = windowConfig.Parent or Root.getOrCreate()
    local window = Window.new(target, windowConfig)

    table.insert(mountedWindows, window)

    return window
end

function Slate:Destroy()
    destroyMountedWindows()
    Root.destroy()
end

destroyMountedWindows()

return Slate
