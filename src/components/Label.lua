local Theme = require(script.Parent.Parent.theme.Theme)

local Label = {}
local LabelMeta = {}

local LIVE_PROPERTIES = {
    Subtext = true,
    Text = true,
    Visible = true,
}

local DEFAULTS = {
    Subtext = nil,
    Text = "Label",
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

    if property == "Subtext" then
        if value == nil or value == "" then
            return nil
        end

        return tostring(value)
    end

    if property == "Visible" then
        return getValue(value, DEFAULTS.Visible)
    end

    return value
end

local function createLabel(parent)
    local frame = Instance.new("Frame")
    frame.Name = "Label"
    frame.AutomaticSize = Enum.AutomaticSize.Y
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Size = UDim2.new(1, 0, 0, 0)
    frame.Parent = parent

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.Padding = UDim.new(0, 2)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = frame

    local primary = Instance.new("TextLabel")
    primary.Name = "Primary"
    primary.AutomaticSize = Enum.AutomaticSize.Y
    primary.BackgroundTransparency = 1
    primary.BorderSizePixel = 0
    primary.Font = Enum.Font.GothamMedium
    primary.Size = UDim2.new(1, 0, 0, 0)
    primary.TextColor3 = Theme["label-primary"]
    primary.TextSize = 14
    primary.TextWrapped = true
    primary.TextXAlignment = Enum.TextXAlignment.Left
    primary.TextYAlignment = Enum.TextYAlignment.Top
    primary.Parent = frame

    local subtext = Instance.new("TextLabel")
    subtext.Name = "Subtext"
    subtext.AutomaticSize = Enum.AutomaticSize.Y
    subtext.BackgroundTransparency = 1
    subtext.BorderSizePixel = 0
    subtext.Font = Enum.Font.Gotham
    subtext.Size = UDim2.new(1, 0, 0, 0)
    subtext.TextColor3 = Theme["label-subtext"]
    subtext.TextSize = 13
    subtext.TextWrapped = true
    subtext.TextXAlignment = Enum.TextXAlignment.Left
    subtext.TextYAlignment = Enum.TextYAlignment.Top
    subtext.Visible = false
    subtext.Parent = frame

    return {
        frame = frame,
        primary = primary,
        subtext = subtext,
    }
end

local function ensureProperty(property)
    assert(LIVE_PROPERTIES[property], string.format("Unsupported label property %q", tostring(property)))
end

local function applyMetadata(self)
    local refs = self._refs
    local state = self._state

    refs.frame.Visible = state.Visible
    refs.primary.Text = state.Text
    refs.subtext.Text = state.Subtext or ""
    refs.subtext.Visible = state.Subtext ~= nil
end

function Label.new(parent, config)
    local refs = createLabel(parent)
    local cfg = config or {}

    local self = setmetatable({
        Instance = refs.frame,
        _destroyed = false,
        _refs = refs,
        _state = {
            Subtext = normalizePropertyValue("Subtext", cfg.Subtext),
            Text = normalizePropertyValue("Text", cfg.Text or cfg.Title),
            Visible = normalizePropertyValue("Visible", cfg.Visible),
        },
    }, LabelMeta)

    applyMetadata(self)

    return self
end

function Label:Set(propertyOrProperties, value)
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

function Label:Update(properties)
    return self:Set(properties)
end

function Label:Destroy()
    if self._destroyed then
        return
    end

    self._destroyed = true
    self.Instance:Destroy()
end

function LabelMeta.__index(self, key)
    local method = Label[key]
    if method ~= nil then
        return method
    end

    local state = rawget(self, "_state")
    if state and state[key] ~= nil then
        return state[key]
    end

    return rawget(self, key)
end

function LabelMeta.__newindex(self, key, value)
    if rawget(self, "_state") and LIVE_PROPERTIES[key] then
        self:Set(key, value)
        return
    end

    error(string.format("Unsupported label property %q", tostring(key)))
end

return Label
