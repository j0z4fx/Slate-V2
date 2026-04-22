local Theme = require(script.theme.Theme)
local Root = require(script.core.Root)
local Window = require(script.components.Window)
local Divider = require(script.components.Divider)
local Groupbox = require(script.components.Groupbox)
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
Slate.Divider = Divider
Slate.Groupbox = Groupbox
Slate.Label = Label
Slate.Separator = Separator
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
