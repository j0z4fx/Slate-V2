local Theme = require(script.Parent.Parent.theme.Theme)

local Divider = {}
local DividerMeta = {}

local HEIGHT = 8

local function createDivider(parent)
    local frame = Instance.new("Frame")
    frame.Name = "Divider"
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Size = UDim2.new(1, 0, 0, HEIGHT)
    frame.Parent = parent

    local line = Instance.new("Frame")
    line.Name = "Line"
    line.AnchorPoint = Vector2.new(0, 0.5)
    line.BackgroundColor3 = Theme["divider-line"]
    line.BorderSizePixel = 0
    line.Position = UDim2.new(0, 0, 0.5, 0)
    line.Size = UDim2.new(1, 0, 0, 1)
    line.Parent = frame

    return {
        frame = frame,
        line = line,
    }
end

function Divider.new(parent)
    local refs = createDivider(parent)

    local self = setmetatable({
        Instance = refs.frame,
        _destroyed = false,
        _refs = refs,
    }, DividerMeta)

    return self
end

function Divider:Destroy()
    if self._destroyed then
        return
    end

    self._destroyed = true
    self.Instance:Destroy()
end

function DividerMeta.__index(self, key)
    local method = Divider[key]
    if method ~= nil then
        return method
    end

    return rawget(self, key)
end

return Divider
