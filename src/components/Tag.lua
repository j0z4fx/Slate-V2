local Theme = require(script.Parent.Parent.theme.Theme)

local Tag = {}
local TagMeta = {}

local LIVE_PROPERTIES = {
    Text = true,
    Visible = true,
}

local DEFAULTS = {
    Text = "Tag",
    Visible = true,
}

local function getValue(value, fallback)
    if value == nil then
        return fallback
    end

    return value
end

local function createTag(parent)
    local frame = Instance.new("Frame")
    frame.Name = "Tag"
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Size = UDim2.new(1, 0, 0, 20)
    frame.Parent = parent

    local chip = Instance.new("Frame")
    chip.Name = "Chip"
    chip.AutomaticSize = Enum.AutomaticSize.X
    chip.BackgroundColor3 = Theme["tabbox-tab-active"]
    chip.BorderSizePixel = 0
    chip.Size = UDim2.fromOffset(0, 20)
    chip.Parent = frame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = chip

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 8)
    padding.PaddingRight = UDim.new(0, 8)
    padding.Parent = chip

    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.AutomaticSize = Enum.AutomaticSize.X
    label.BackgroundTransparency = 1
    label.BorderSizePixel = 0
    label.Position = UDim2.fromOffset(0, 0)
    label.Size = UDim2.new(0, 0, 1, 0)
    label.Font = Enum.Font.GothamMedium
    label.TextColor3 = Theme.accent
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.Parent = chip

    return {
        chip = chip,
        frame = frame,
        label = label,
    }
end

local function applyMetadata(self)
    local refs = self._refs
    local state = self._state

    refs.frame.Visible = state.Visible
    refs.label.Text = state.Text
end

function Tag.new(parent, config)
    local refs = createTag(parent)
    local cfg = config or {}

    local self = setmetatable({
        Instance = refs.frame,
        _destroyed = false,
        _refs = refs,
        _state = {
            Text = tostring(getValue(cfg.Text or cfg.Title, DEFAULTS.Text)),
            Visible = getValue(cfg.Visible, DEFAULTS.Visible),
        },
    }, TagMeta)

    applyMetadata(self)

    return self
end

function Tag:Set(property, value)
    if self._destroyed then
        return self
    end

    self._state[property] = property == "Visible" and getValue(value, DEFAULTS.Visible) or tostring(getValue(value, DEFAULTS.Text))
    applyMetadata(self)

    return self
end

function Tag:Update(properties)
    for property, value in pairs(properties) do
        self:Set(property, value)
    end

    return self
end

function Tag:Destroy()
    if self._destroyed then
        return
    end

    self._destroyed = true
    self.Instance:Destroy()
end

function TagMeta.__index(self, key)
    local method = Tag[key]
    if method ~= nil then
        return method
    end

    local state = rawget(self, "_state")
    if state and state[key] ~= nil then
        return state[key]
    end

    return rawget(self, key)
end

return Tag
