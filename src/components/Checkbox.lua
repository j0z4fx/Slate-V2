local Theme = require(script.Parent.Parent.theme.Theme)
local Ui = require(script.Parent.Parent.core.Ui)
local ColorPicker = require(script.Parent.ColorPicker)
local KeyPicker = require(script.Parent.KeyPicker)

local Checkbox = {}
local CheckboxMeta = {}

local BOX_SIZE = 18
local CHECKBOX_TWEEN_INFO = TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local RIGHT_GAP = 6
local ROW_HEIGHT = 20

local LIVE_PROPERTIES = {
    Disabled = true,
    Text = true,
    Value = true,
    Visible = true,
}

local DEFAULTS = {
    Default = false,
    Disabled = false,
    Text = "Checkbox",
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

local function createCheckbox(parent)
    local button = Instance.new("TextButton")
    button.Name = "Checkbox"
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
    label.Font = Enum.Font.Gotham
    label.Size = UDim2.new(1, -(BOX_SIZE + 10), 1, 0)
    label.TextColor3 = Theme["text-secondary"]
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.Parent = button

    local addonRow = Instance.new("Frame")
    addonRow.Name = "AddonRow"
    addonRow.AnchorPoint = Vector2.new(1, 0.5)
    addonRow.AutomaticSize = Enum.AutomaticSize.X
    addonRow.BackgroundTransparency = 1
    addonRow.BorderSizePixel = 0
    addonRow.Position = UDim2.new(1, -(BOX_SIZE + RIGHT_GAP), 0.5, 0)
    addonRow.Size = UDim2.fromOffset(0, ROW_HEIGHT)
    addonRow.Parent = button

    local addonLayout = Instance.new("UIListLayout")
    addonLayout.FillDirection = Enum.FillDirection.Horizontal
    addonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    addonLayout.Padding = UDim.new(0, 6)
    addonLayout.SortOrder = Enum.SortOrder.LayoutOrder
    addonLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    addonLayout.Parent = addonRow

    local box = Instance.new("Frame")
    box.Name = "Box"
    box.AnchorPoint = Vector2.new(1, 0.5)
    box.BackgroundColor3 = Theme["checkbox-bg"]
    box.BorderSizePixel = 0
    box.Position = UDim2.new(1, 0, 0.5, 0)
    box.Size = UDim2.fromOffset(BOX_SIZE, BOX_SIZE)
    box.Parent = button

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 5)
    corner.Parent = box

    local stroke = Instance.new("UIStroke")
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Color = Theme["checkbox-stroke"]
    stroke.Thickness = 1
    stroke.Parent = box

    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.AnchorPoint = Vector2.new(0.5, 0.5)
    fill.BackgroundColor3 = Theme.accent
    fill.BorderSizePixel = 0
    fill.Position = UDim2.fromScale(0.5, 0.5)
    fill.Size = UDim2.fromOffset(BOX_SIZE - 4, BOX_SIZE - 4)
    fill.Parent = box

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 4)
    fillCorner.Parent = fill

    local check = Instance.new("TextLabel")
    check.Name = "Check"
    check.BackgroundTransparency = 1
    check.BorderSizePixel = 0
    check.Size = UDim2.fromScale(1, 1)
    check.Font = Enum.Font.GothamBold
    check.Text = "✓"
    check.TextColor3 = Color3.new(1, 1, 1)
    check.TextSize = 12
    check.TextXAlignment = Enum.TextXAlignment.Center
    check.TextYAlignment = Enum.TextYAlignment.Center
    check.Parent = fill

    return {
        addonLayout = addonLayout,
        addonRow = addonRow,
        box = box,
        button = button,
        check = check,
        fill = fill,
        label = label,
        stroke = stroke,
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

    local reservedWidth = BOX_SIZE + 10 + addonWidth
    if addonWidth > 0 then
        reservedWidth += RIGHT_GAP
    end

    refs.addonRow.Position = UDim2.new(1, -(BOX_SIZE + RIGHT_GAP), 0.5, 0)
    refs.label.Size = UDim2.new(1, -reservedWidth, 1, 0)
end

local function ensureProperty(property)
    assert(LIVE_PROPERTIES[property], string.format("Unsupported checkbox property %q", tostring(property)))
end

local function applyMetadata(self, instant)
    local refs = self._refs
    local state = self._state
    local checked = state.Value
    local disabled = state.Disabled
    local fillTransparency = checked and 0 or 1
    local checkTransparency = checked and 0 or 1
    local labelColor = checked and Theme["text-primary"] or Theme["text-secondary"]
    local backgroundTransparency = disabled and 0.15 or 0
    local labelTransparency = disabled and 0.35 or 0

    refs.button.Active = not disabled
    refs.button.Visible = state.Visible
    refs.label.Text = state.Text
    updateLayout(self)

    Ui.cancel(self._tweens.fill)
    Ui.cancel(self._tweens.check)
    Ui.cancel(self._tweens.label)
    Ui.cancel(self._tweens.box)

    if instant or not Ui.animationsEnabled(refs.button) then
        refs.box.BackgroundTransparency = backgroundTransparency
        refs.fill.BackgroundTransparency = fillTransparency
        refs.check.TextTransparency = checkTransparency
        refs.label.TextColor3 = labelColor
        refs.label.TextTransparency = labelTransparency
        return
    end

    self._tweens.box = Ui.play(refs.box, CHECKBOX_TWEEN_INFO, {
        BackgroundTransparency = backgroundTransparency,
    })
    self._tweens.fill = Ui.play(refs.fill, CHECKBOX_TWEEN_INFO, {
        BackgroundTransparency = fillTransparency,
    })
    self._tweens.check = Ui.play(refs.check, CHECKBOX_TWEEN_INFO, {
        TextTransparency = checkTransparency,
    })
    self._tweens.label = Ui.play(refs.label, CHECKBOX_TWEEN_INFO, {
        TextColor3 = labelColor,
        TextTransparency = labelTransparency,
    })
end

function Checkbox.new(parent, config)
    local refs = createCheckbox(parent)
    local cfg = config or {}

    local self = setmetatable({
        Instance = refs.button,
        Parent = parent,
        _addons = {},
        _destroyed = false,
        _onChanged = cfg.Changed or cfg.Callback,
        _refs = refs,
        _state = {
            Disabled = normalizePropertyValue("Disabled", cfg.Disabled),
            Text = normalizePropertyValue("Text", cfg.Text or cfg.Title),
            Value = normalizePropertyValue("Value", cfg.Default),
            Visible = normalizePropertyValue("Visible", cfg.Visible),
        },
        _tweens = {},
    }, CheckboxMeta)

    refs.button.MouseButton1Click:Connect(function()
        if self._destroyed or self._state.Disabled then
            return
        end

        self:SetValue(not self._state.Value)
    end)

    applyMetadata(self, true)

    return self
end

function Checkbox:Set(propertyOrProperties, value)
    if self._destroyed then
        return self
    end

    if type(propertyOrProperties) == "table" then
        local changedValue = false

        for property, nextValue in pairs(propertyOrProperties) do
            ensureProperty(property)
            local normalized = normalizePropertyValue(property, nextValue)
            if self._state[property] ~= normalized then
                self._state[property] = normalized
                changedValue = changedValue or property == "Value"
            end
        end

        applyMetadata(self, false)
        if changedValue and self._onChanged then
            self._onChanged(self._state.Value)
        end

        return self
    end

    ensureProperty(propertyOrProperties)
    local normalized = normalizePropertyValue(propertyOrProperties, value)
    if self._state[propertyOrProperties] == normalized then
        applyMetadata(self, false)
        return self
    end

    self._state[propertyOrProperties] = normalized
    applyMetadata(self, false)

    if propertyOrProperties == "Value" and self._onChanged then
        self._onChanged(self._state.Value)
    end

    return self
end

function Checkbox:Update(properties)
    return self:Set(properties)
end

function Checkbox:SetValue(value)
    return self:Set("Value", value)
end

function Checkbox:SetText(text)
    return self:Set("Text", text)
end

function Checkbox:SetDisabled(disabled)
    return self:Set("Disabled", disabled)
end

function Checkbox:SetVisible(visible)
    return self:Set("Visible", visible)
end

function Checkbox:OnChanged(callback)
    self._onChanged = callback

    return self
end

function Checkbox:AddColorPicker(config)
    local colorPicker = ColorPicker.new(self, config or {})
    table.insert(self._addons, colorPicker)
    updateLayout(self)

    return colorPicker
end

function Checkbox:AddKeyPicker(config)
    local keyPicker = KeyPicker.new(self, config or {})
    table.insert(self._addons, keyPicker)
    updateLayout(self)

    return keyPicker
end

function Checkbox:_syncAddonLayout()
    if self._destroyed then
        return self
    end

    updateLayout(self)

    return self
end

function Checkbox:Destroy()
    if self._destroyed then
        return
    end

    self._destroyed = true

    for _, addon in ipairs(self._addons) do
        addon:Destroy()
    end

    self._addons = {}
    for _, tween in pairs(self._tweens) do
        Ui.cancel(tween)
    end

    self._tweens = {}
    self.Instance:Destroy()
end

function CheckboxMeta.__index(self, key)
    local method = Checkbox[key]
    if method ~= nil then
        return method
    end

    local state = rawget(self, "_state")
    if state and state[key] ~= nil then
        return state[key]
    end

    return rawget(self, key)
end

function CheckboxMeta.__newindex(self, key, value)
    if rawget(self, "_state") and LIVE_PROPERTIES[key] then
        self:Set(key, value)
        return
    end

    error(string.format("Unsupported checkbox property %q", tostring(key)))
end

return Checkbox
