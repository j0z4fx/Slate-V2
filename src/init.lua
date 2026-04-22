local Theme = require(script.theme.Theme)
local Root = require(script.core.Root)
local Window = require(script.components.Window)
local Groupbox = require(script.components.Groupbox)
local Toggle = require(script.components.Toggle)

local Slate = {}
local mountedWindows = {}

Slate.Theme = Theme
Slate.Groupbox = Groupbox
Slate.Toggle = Toggle

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
    for index = #mountedWindows, 1, -1 do
        local window = mountedWindows[index]
        if window and not window._destroyed then
            window:Destroy()
        end
        mountedWindows[index] = nil
    end

    Root.destroy()
end

return Slate
