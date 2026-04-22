local Theme = require(script.Parent.Parent.theme.Theme)
local ColorPicker = require(script.Parent.ColorPicker)
local KeyPicker = require(script.Parent.KeyPicker)

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

    local row = Instance.new("Frame")
    row.Name = "Row"
    row.BackgroundTransparency = 1
    row.BorderSizePixel = 0
    row.Size = UDim2.new(1, 0, 0, 20)
    row.Parent = frame

    local primary = Instance.new("TextLabel")
    primary.Name = "Primary"
    primary.BackgroundTransparency = 1
    primary.BorderSizePixel = 0
    primary.Font = Enum.Font.GothamMedium
    primary.Size = UDim2.new(1, 0, 0, 20)
    primary.TextColor3 = Theme["label-primary"]
    primary.TextSize = 14
    primary.TextWrapped = false
    primary.TextXAlignment = Enum.TextXAlignment.Left
    primary.TextYAlignment = Enum.TextYAlignment.Center
    primary.Parent = row

    local addonRow = Instance.new("Frame")
    addonRow.Name = "AddonRow"
    addonRow.AnchorPoint = Vector2.new(1, 0)
    addonRow.AutomaticSize = Enum.AutomaticSize.X
    addonRow.BackgroundTransparency = 1
    addonRow.BorderSizePixel = 0
    addonRow.Position = UDim2.new(1, 0, 0, 0)
    addonRow.Size = UDim2.fromOffset(0, 20)
    addonRow.Parent = row

    local addonLayout = Instance.new("UIListLayout")
    addonLayout.FillDirection = Enum.FillDirection.Horizontal
    addonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    addonLayout.Padding = UDim.new(0, 6)
    addonLayout.SortOrder = Enum.SortOrder.LayoutOrder
    addonLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    addonLayout.Parent = addonRow

    local subtext = Instance.new("TextLabel")
    subtext.Name = "Subtext"
    subtext.AutomaticSize = Enum.AutomaticSize.Y
    subtext.BackgroundTransparency = 1
    subtext.BorderSizePixel = 0
    subtext.Font = Enum.Font.Gotham
    subtext.Position = UDim2.fromOffset(0, 22)
    subtext.Size = UDim2.new(1, 0, 0, 0)
    subtext.TextColor3 = Theme["label-subtext"]
    subtext.TextSize = 13
    subtext.TextWrapped = true
    subtext.TextXAlignment = Enum.TextXAlignment.Left
    subtext.TextYAlignment = Enum.TextYAlignment.Top
    subtext.Visible = false
    subtext.Parent = frame

    return {
        addonLayout = addonLayout,
        addonRow = addonRow,
        frame = frame,
        primary = primary,
        row = row,
        subtext = subtext,
    }
end

local function updateLayout(self)
    local refs = self._refs
    local addonWidth = refs.addonRow.AbsoluteSize.X
    local reservedWidth = addonWidth > 0 and (addonWidth + 8) or 0

    refs.primary.Size = UDim2.new(1, -reservedWidth, 0, 20)
    refs.row.Size = UDim2.new(1, 0, 0, 20)
    refs.subtext.Position = UDim2.fromOffset(0, 22)
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
    refs.frame.Size = UDim2.new(1, 0, 0, state.Subtext ~= nil and 38 or 20)
    updateLayout(self)
end

function Label.new(parent, config)
    local refs = createLabel(parent)
    local cfg = config or {}

    local self = setmetatable({
        Instance = refs.frame,
        Parent = parent,
        _addons = {},
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

function Label:AddColorPicker(config)
    local colorPicker = ColorPicker.new(self, config or {})
    table.insert(self._addons, colorPicker)
    updateLayout(self)

    return colorPicker
end

function Label:AddKeyPicker(config)
    local keyPicker = KeyPicker.new(self, config or {})
    table.insert(self._addons, keyPicker)
    updateLayout(self)

    return keyPicker
end

function Label:_syncAddonLayout()
    if self._destroyed then
        return self
    end

    updateLayout(self)

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

    for _, addon in ipairs(self._addons) do
        addon:Destroy()
    end

    self._addons = {}
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
