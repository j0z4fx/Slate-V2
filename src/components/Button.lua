local Theme = require(script.Parent.Parent.theme.Theme)
local Ui = require(script.Parent.Parent.core.Ui)

local Button = {}
local ButtonMeta = {}

local BUTTON_HEIGHT = 24
local BUTTON_TWEEN_INFO = TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local DOUBLE_CLICK_TIMEOUT = 0.35

local LIVE_PROPERTIES = {
    Disabled = true,
    Text = true,
    Visible = true,
}

local DEFAULTS = {
    Disabled = false,
    DoubleClick = false,
    Text = "Button",
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

    if property == "Disabled" or property == "Visible" then
        return getValue(value, DEFAULTS[property])
    end

    return value
end

local function createButton(parent)
    local button = Instance.new("TextButton")
    button.Name = "Button"
    button.AutoButtonColor = false
    button.BackgroundColor3 = Theme["button-bg"]
    button.BorderSizePixel = 0
    button.Size = UDim2.new(1, 0, 0, BUTTON_HEIGHT)
    button.Text = ""
    button.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = button

    local stroke = Instance.new("UIStroke")
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Color = Theme["button-stroke"]
    stroke.Thickness = 1
    stroke.Parent = button

    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.BackgroundTransparency = 1
    label.BorderSizePixel = 0
    label.Size = UDim2.fromScale(1, 1)
    label.Font = Enum.Font.GothamMedium
    label.TextColor3 = Theme["text-primary"]
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.Parent = button

    return {
        button = button,
        label = label,
        stroke = stroke,
    }
end

local function ensureProperty(property)
    assert(LIVE_PROPERTIES[property], string.format("Unsupported button property %q", tostring(property)))
end

local function applyMetadata(self, instant)
    local refs = self._refs
    local state = self._state
    local hovered = self._hovered and not state.Disabled
    local pressed = self._pressed and not state.Disabled
    local backgroundColor = Theme["button-bg"]

    if pressed then
        backgroundColor = Theme["button-bg-pressed"]
    elseif hovered then
        backgroundColor = Theme["button-bg-hover"]
    end

    local labelColor = state.Disabled and Theme["text-secondary"] or Theme["text-primary"]
    local backgroundTransparency = state.Disabled and 0.18 or 0
    local strokeTransparency = state.Disabled and 0.24 or 0

    refs.button.Active = not state.Disabled
    refs.button.Visible = state.Visible
    refs.label.Text = state.Text

    Ui.cancel(self._tweens.background)
    Ui.cancel(self._tweens.stroke)
    Ui.cancel(self._tweens.label)

    if instant or not Ui.animationsEnabled(refs.button) then
        refs.button.BackgroundColor3 = backgroundColor
        refs.button.BackgroundTransparency = backgroundTransparency
        refs.stroke.Transparency = strokeTransparency
        refs.label.TextColor3 = labelColor
        return
    end

    self._tweens.background = Ui.play(refs.button, BUTTON_TWEEN_INFO, {
        BackgroundColor3 = backgroundColor,
        BackgroundTransparency = backgroundTransparency,
    })
    self._tweens.stroke = Ui.play(refs.stroke, BUTTON_TWEEN_INFO, {
        Transparency = strokeTransparency,
    })
    self._tweens.label = Ui.play(refs.label, BUTTON_TWEEN_INFO, {
        TextColor3 = labelColor,
    })
end

function Button.new(parent, config)
    local refs = createButton(parent)
    local cfg = config or {}

    local self = setmetatable({
        Instance = refs.button,
        Parent = parent,
        _awaitingDouble = false,
        _destroyed = false,
        _hovered = false,
        _onClick = cfg.Clicked or cfg.Callback or cfg.Func,
        _pressed = false,
        _refs = refs,
        _state = {
            Disabled = normalizePropertyValue("Disabled", cfg.Disabled),
            DoubleClick = cfg.DoubleClick == true,
            Text = normalizePropertyValue("Text", cfg.Text or cfg.Title),
            Visible = normalizePropertyValue("Visible", cfg.Visible),
        },
        _tweens = {},
    }, ButtonMeta)

    refs.button.MouseEnter:Connect(function()
        self._hovered = true
        applyMetadata(self, false)
    end)

    refs.button.MouseLeave:Connect(function()
        self._hovered = false
        self._pressed = false
        applyMetadata(self, false)
    end)

    refs.button.MouseButton1Down:Connect(function()
        self._pressed = true
        applyMetadata(self, false)
    end)

    refs.button.MouseButton1Up:Connect(function()
        self._pressed = false
        applyMetadata(self, false)
    end)

    refs.button.MouseButton1Click:Connect(function()
        if self._destroyed or self._state.Disabled then
            return
        end

        if self._state.DoubleClick then
            if self._awaitingDouble then
                self._awaitingDouble = false
            else
                self._awaitingDouble = true
                task.delay(DOUBLE_CLICK_TIMEOUT, function()
                    if not self._destroyed then
                        self._awaitingDouble = false
                    end
                end)
                return
            end
        end

        if self._onClick then
            self._onClick()
        end
    end)

    applyMetadata(self, true)

    return self
end

function Button:Set(propertyOrProperties, value)
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

    applyMetadata(self, false)

    return self
end

function Button:Update(properties)
    return self:Set(properties)
end

function Button:SetText(text)
    return self:Set("Text", text)
end

function Button:SetDisabled(disabled)
    return self:Set("Disabled", disabled)
end

function Button:SetVisible(visible)
    return self:Set("Visible", visible)
end

function Button:OnClick(callback)
    self._onClick = callback

    return self
end

function Button:Destroy()
    if self._destroyed then
        return
    end

    self._destroyed = true

    for _, tween in pairs(self._tweens) do
        Ui.cancel(tween)
    end

    self._tweens = {}
    self.Instance:Destroy()
end

function ButtonMeta.__index(self, key)
    local method = Button[key]
    if method ~= nil then
        return method
    end

    local state = rawget(self, "_state")
    if state and state[key] ~= nil then
        return state[key]
    end

    return rawget(self, key)
end

function ButtonMeta.__newindex(self, key, value)
    if rawget(self, "_state") and LIVE_PROPERTIES[key] then
        self:Set(key, value)
        return
    end

    error(string.format("Unsupported button property %q", tostring(key)))
end

return Button
