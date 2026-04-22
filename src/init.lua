local Theme = require(script.theme.Theme)
local Root = require(script.core.Root)
local Window = require(script.components.Window)

local Slate = {}

Slate.Theme = Theme

function Slate.CreateWindow(parent: Instance?)
    local target = parent or Root.getOrCreate()

    return Window.new(target)
end

return Slate
