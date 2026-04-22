local Theme = require(script.Parent.Parent.theme.Theme)

local Separator = {}
local SeparatorMeta = {}

local HEIGHT = 12
local TEXT_PADDING = 10

local LIVE_PROPERTIES = {
    Text = true,
    Visible = true,
}

local DEFAULTS = {
    Text = "Separator",
    Visible = true,
}

local function getValue(value, fallback)
    if value == nil then
        return fallback
    end

    return value
end

local function normalizePropertyValue(property, value)
    if property == "Text" then
        return tostring(getValue(value, DEFAULTS.Text))
    end

    if property == "Visible" then
        return getValue(value, DEFAULTS.Visible)
    end

    return value
end

local function createSeparator(parent)
    local frame = Instance.new("Frame")
    frame.Name = "Separator"
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

    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.AnchorPoint = Vector2.new(0.5, 0.5)
    label.AutomaticSize = Enum.AutomaticSize.X
    label.BackgroundColor3 = Theme.surface
    label.BackgroundTransparency = 0
    label.BorderSizePixel = 0
    label.Font = Enum.Font.Gotham
    label.Position = UDim2.fromScale(0.5, 0.5)
    label.Size = UDim2.new(0, 0, 1, 0)
    label.TextColor3 = Theme["separator-text"]
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.Parent = frame

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, TEXT_PADDING)
    padding.PaddingRight = UDim.new(0, TEXT_PADDING)
    padding.Parent = label

    return {
        frame = frame,
        line = line,
        label = label,
    }
end

local function ensureProperty(property)
    assert(LIVE_PROPERTIES[property], string.format("Unsupported separator property %q", tostring(property)))
end

local function applyMetadata(self)
    local refs = self._refs
    local state = self._state

    refs.frame.Visible = state.Visible
    refs.label.Text = string.upper(state.Text)
end

function Separator.new(parent, config)
    local refs = createSeparator(parent)
    local cfg = config or {}

    local self = setmetatable({
        Instance = refs.frame,
        _destroyed = false,
        _refs = refs,
        _state = {
            Text = normalizePropertyValue("Text", cfg.Text or cfg.Title),
            Visible = normalizePropertyValue("Visible", cfg.Visible),
        },
    }, SeparatorMeta)

    applyMetadata(self)

    return self
end

function Separator:Set(propertyOrProperties, value)
    if self._destroyed then
        return self
    end

    if type(propertyOrProperties) == "table" then
        for property, nextValue in pairs(propertyOrProperties) do
            ensureProperty(property)
            self._state[property] = normalizePropertyValue(property, nextValue)
        end
    else
        ensureProperty(propertyOrProperties)
        self._state[propertyOrProperties] = normalizePropertyValue(propertyOrProperties, value)
    end

    applyMetadata(self)

    return self
end

function Separator:Update(properties)
    return self:Set(properties)
end

function Separator:Destroy()
    if self._destroyed then
        return
    end

    self._destroyed = true
    self.Instance:Destroy()
end

function SeparatorMeta.__index(self, key)
    local method = Separator[key]
    if method ~= nil then
        return method
    end

    local state = rawget(self, "_state")
    if state and state[key] ~= nil then
        return state[key]
    end

    return rawget(self, key)
end

function SeparatorMeta.__newindex(self, key, value)
    if rawget(self, "_state") and LIVE_PROPERTIES[key] then
        self:Set(key, value)
        return
    end

    error(string.format("Unsupported separator property %q", tostring(key)))
end

return Separator
