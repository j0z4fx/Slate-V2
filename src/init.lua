local Theme = require(script.theme.Theme)
local Window = require(script.components.Window)

local Slate = {}

Slate.Theme = Theme

function Slate.CreateWindow(parent: Instance?)
    return Window.new(parent)
end

return Slate
