local Theme = require(script.Parent.Parent.theme.Theme)

local Window = {}

function Window.new(parent: Instance?)
    local frame = Instance.new("Frame")
    frame.Name = "Window"
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Position = UDim2.fromScale(0.5, 0.5)
    frame.Size = UDim2.fromOffset(960, 540)
    frame.BackgroundColor3 = Theme.background
    frame.BorderSizePixel = 0
    frame.Parent = parent

    return frame
end

return Window
