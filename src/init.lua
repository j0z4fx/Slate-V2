local Theme = require(script.theme.Theme)
local Root = require(script.core.Root)
local Window = require(script.components.Window)

local Slate = {}

Slate.Theme = Theme

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

    return Window.new(target, windowConfig)
end

return Slate
