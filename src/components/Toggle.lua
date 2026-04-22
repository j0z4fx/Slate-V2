local Theme = require(script.Parent.Parent.theme.Theme)
local ColorPicker = require(script.Parent.ColorPicker)
local KeyPicker = require(script.Parent.KeyPicker)
local TweenService = game:GetService("TweenService")

local Toggle = {}
local ToggleMeta = {}

local FONT = Enum.Font.Gotham
local FONT_SIZE = 14
local ROW_HEIGHT = 20
local SWITCH_WIDTH = 34
local SWITCH_HEIGHT = 20
local SWITCH_PADDING = 2
local RIGHT_GAP = 6
local TOGGLE_TWEEN_INFO = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

local LIVE_PROPERTIES = {
    Disabled = true,
    Text = true,
    Value = true,
    Visible = true,
}

local DEFAULTS = {
    Default = false,
    Disabled = false,
    Text = "Toggle",
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

    if property == "Value" then
        return getValue(value, DEFAULTS.Default)
    end

    if property == "Disabled" or property == "Visible" then
        return getValue(value, DEFAULTS[property])
    end

    return value
end

local function createToggle(parent)
    local button = Instance.new("TextButton")
    button.Name = "Toggle"
    button.AutoButtonColor = false
    button.BackgroundTransparency = 1
    button.BorderSizePixel = 0
    button.Size = UDim2.new(1, 0, 0, ROW_HEIGHT)
    button.Text = ""
    button.Parent = parent

    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.BackgroundTransparency = 1
    label.BorderSizePixel = 0
    label.Font = FONT
    label.Size = UDim2.new(1, -(SWITCH_WIDTH + 10), 1, 0)
    label.TextSize = FONT_SIZE
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.Parent = button

    local addonRow = Instance.new("Frame")
    addonRow.Name = "AddonRow"
    addonRow.AnchorPoint = Vector2.new(1, 0.5)
    addonRow.AutomaticSize = Enum.AutomaticSize.X
    addonRow.BackgroundTransparency = 1
    addonRow.BorderSizePixel = 0
    addonRow.Position = UDim2.new(1, -(SWITCH_WIDTH + RIGHT_GAP), 0.5, 0)
    addonRow.Size = UDim2.fromOffset(0, ROW_HEIGHT)
    addonRow.Parent = button

    local addonLayout = Instance.new("UIListLayout")
    addonLayout.FillDirection = Enum.FillDirection.Horizontal
    addonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    addonLayout.Padding = UDim.new(0, 6)
    addonLayout.SortOrder = Enum.SortOrder.LayoutOrder
    addonLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    addonLayout.Parent = addonRow

    local switch = Instance.new("Frame")
    switch.Name = "Switch"
    switch.AnchorPoint = Vector2.new(1, 0.5)
    switch.BackgroundColor3 = Theme["toggle-body"]
    switch.BorderSizePixel = 0
    switch.Position = UDim2.new(1, 0, 0.5, 0)
    switch.Size = UDim2.fromOffset(SWITCH_WIDTH, SWITCH_HEIGHT)
    switch.Parent = button

    local switchCorner = Instance.new("UICorner")
    switchCorner.CornerRadius = UDim.new(1, 0)
    switchCorner.Parent = switch

    local switchStroke = Instance.new("UIStroke")
    switchStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    switchStroke.Color = Theme["toggle-stroke"]
    switchStroke.Thickness = 1
    switchStroke.Parent = switch

    local dot = Instance.new("Frame")
    dot.Name = "Dot"
    dot.AnchorPoint = Vector2.new(0, 0.5)
    dot.BackgroundColor3 = Theme["toggle-dot"]
    dot.BorderSizePixel = 0
    dot.Position = UDim2.fromOffset(SWITCH_PADDING, SWITCH_HEIGHT / 2)
    dot.Size = UDim2.fromOffset(SWITCH_HEIGHT - (SWITCH_PADDING * 2), SWITCH_HEIGHT - (SWITCH_PADDING * 2))
    dot.Parent = switch

    local dotCorner = Instance.new("UICorner")
    dotCorner.CornerRadius = UDim.new(1, 0)
    dotCorner.Parent = dot

    return {
        button = button,
        label = label,
        addonLayout = addonLayout,
        addonRow = addonRow,
        switch = switch,
        switchStroke = switchStroke,
        dot = dot,
    }
end

local function updateLayout(self)
    local refs = self._refs
    local addonWidth = refs.addonRow.AbsoluteSize.X
    if addonWidth <= 0 then
        addonWidth = 0
        for _, addon in ipairs(self._addons) do
            if addon.Instance then
                addonWidth += addon.Instance.Size.X.Offset
            end
        end

        if #self._addons > 1 then
            addonWidth += (#self._addons - 1) * refs.addonLayout.Padding.Offset
        end
    end

    local reservedWidth = SWITCH_WIDTH + 10 + addonWidth
    if addonWidth > 0 then
        reservedWidth += RIGHT_GAP
    end

    refs.addonRow.Position = UDim2.new(1, -(SWITCH_WIDTH + RIGHT_GAP), 0.5, 0)
    refs.label.Size = UDim2.new(1, -reservedWidth, 1, 0)
end

local function stopTween(tween)
    if tween then
        tween:Cancel()
    end
end

local function applyMetadata(self, instant)
    local refs = self._refs
    local state = self._state
    local value = state.Value
    local disabled = state.Disabled
    local dotOffset = value and (SWITCH_WIDTH - SWITCH_HEIGHT + SWITCH_PADDING) or SWITCH_PADDING
    local dotColor = value and Color3.new(1, 1, 1) or Theme["toggle-dot"]
    local switchColor = value and Theme.accent or Theme["toggle-body"]
    local strokeTransparency = value and 1 or 0
    local labelColor = value and Theme["text-primary"] or Theme["text-secondary"]
    local labelTransparency = disabled and 0.45 or 0
    local switchTransparency = disabled and 0.2 or 0
    local dotTransparency = disabled and 0.2 or 0
    local strokeColor = Theme["toggle-stroke"]

    refs.button.Active = not disabled
    refs.button.Visible = state.Visible
    refs.label.Text = state.Text
    updateLayout(self)

    stopTween(self._tweens.label)
    stopTween(self._tweens.switch)
    stopTween(self._tweens.stroke)
    stopTween(self._tweens.dot)

    if instant then
        refs.label.TextColor3 = labelColor
        refs.label.TextTransparency = labelTransparency
        refs.switch.BackgroundColor3 = switchColor
        refs.switch.BackgroundTransparency = switchTransparency
        refs.switchStroke.Color = strokeColor
        refs.switchStroke.Transparency = strokeTransparency
        refs.dot.BackgroundColor3 = dotColor
        refs.dot.BackgroundTransparency = dotTransparency
        refs.dot.Position = UDim2.fromOffset(dotOffset, SWITCH_HEIGHT / 2)
        return
    end

    self._tweens.label = TweenService:Create(refs.label, TOGGLE_TWEEN_INFO, {
        TextColor3 = labelColor,
        TextTransparency = labelTransparency,
    })
    self._tweens.switch = TweenService:Create(refs.switch, TOGGLE_TWEEN_INFO, {
        BackgroundColor3 = switchColor,
        BackgroundTransparency = switchTransparency,
    })
    self._tweens.stroke = TweenService:Create(refs.switchStroke, TOGGLE_TWEEN_INFO, {
        Transparency = strokeTransparency,
    })
    self._tweens.dot = TweenService:Create(refs.dot, TOGGLE_TWEEN_INFO, {
        BackgroundColor3 = dotColor,
        BackgroundTransparency = dotTransparency,
        Position = UDim2.fromOffset(dotOffset, SWITCH_HEIGHT / 2),
    })

    self._tweens.label:Play()
    self._tweens.switch:Play()
    self._tweens.stroke:Play()
    self._tweens.dot:Play()
end

local function ensureProperty(property)
    assert(LIVE_PROPERTIES[property], string.format("Unsupported toggle property %q", tostring(property)))
end

function Toggle.new(parent, config)
    local refs = createToggle(parent)
    local cfg = config or {}

    local self = setmetatable({
        Instance = refs.button,
        Parent = parent,
        _destroyed = false,
        _addons = {},
        _onChanged = cfg.Changed or cfg.Callback,
        _refs = refs,
        _state = {
            Disabled = normalizePropertyValue("Disabled", cfg.Disabled),
            Text = normalizePropertyValue("Text", cfg.Text or cfg.Title),
            Value = normalizePropertyValue("Value", cfg.Default),
            Visible = normalizePropertyValue("Visible", cfg.Visible),
        },
        _tweens = {},
    }, ToggleMeta)

    refs.button.MouseButton1Click:Connect(function()
        if self._destroyed or self._state.Disabled then
            return
        end

        self:SetValue(not self._state.Value)
    end)

    applyMetadata(self, true)

    return self
end

function Toggle:Get(property)
    return self._state[property]
end

function Toggle:Set(propertyOrProperties, value)
    if self._destroyed then
        return self
    end

    if type(propertyOrProperties) == "table" then
        for property, nextValue in pairs(propertyOrProperties) do
            ensureProperty(property)
            self._state[property] = normalizePropertyValue(property, nextValue)
        end
        applyMetadata(self, false)
        return self
    end

    ensureProperty(propertyOrProperties)
    self._state[propertyOrProperties] = normalizePropertyValue(propertyOrProperties, value)
    applyMetadata(self, false)

    if propertyOrProperties == "Value" and self._onChanged then
        self._onChanged(self._state.Value)
    end

    return self
end

function Toggle:Update(properties)
    return self:Set(properties)
end

function Toggle:SetValue(value)
    return self:Set("Value", value)
end

function Toggle:SetText(text)
    return self:Set("Text", text)
end

function Toggle:SetDisabled(disabled)
    return self:Set("Disabled", disabled)
end

function Toggle:SetVisible(visible)
    return self:Set("Visible", visible)
end

function Toggle:Toggle()
    return self:SetValue(not self._state.Value)
end

function Toggle:OnChanged(callback)
    self._onChanged = callback

    return self
end

function Toggle:AddColorPicker(config)
    local colorPicker = ColorPicker.new(self, config or {})
    table.insert(self._addons, colorPicker)
    updateLayout(self)

    return colorPicker
end

function Toggle:AddKeyPicker(config)
    local keyPicker = KeyPicker.new(self, config or {})
    table.insert(self._addons, keyPicker)
    updateLayout(self)

    return keyPicker
end

function Toggle:Destroy()
    if self._destroyed then
        return
    end

    self._destroyed = true

    for _, addon in ipairs(self._addons) do
        addon:Destroy()
    end

    self._addons = {}
    for _, tween in pairs(self._tweens) do
        stopTween(tween)
    end

    self._tweens = {}
    self.Instance:Destroy()
end

function ToggleMeta.__index(self, key)
    local method = Toggle[key]
    if method ~= nil then
        return method
    end

    local state = rawget(self, "_state")
    if state and state[key] ~= nil then
        return state[key]
    end

    return rawget(self, key)
end

function ToggleMeta.__newindex(self, key, value)
    if rawget(self, "_state") and LIVE_PROPERTIES[key] then
        self:Set(key, value)
        return
    end

    error(string.format("Unsupported toggle property %q", tostring(key)))
end

return Toggle
