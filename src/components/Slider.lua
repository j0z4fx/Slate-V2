local Theme = require(script.Parent.Parent.theme.Theme)
local Ui = require(script.Parent.Parent.core.Ui)
local UserInputService = game:GetService("UserInputService")

local Slider = {}
local SliderMeta = {}

local KNOB_SIZE = 12
local SLIDER_HEIGHT = 46
local TRACK_HEIGHT = 6
local SLIDER_TWEEN_INFO = TweenInfo.new(0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

local LIVE_PROPERTIES = {
    Disabled = true,
    Text = true,
    Value = true,
    Visible = true,
}

local DEFAULTS = {
    Default = 0,
    Disabled = false,
    Max = 100,
    Min = 0,
    Text = "Slider",
    Visible = true,
}

local function getValue(value, fallback)
    if value == nil then
        return fallback
    end

    return value
end

local function clampValue(self, value)
    local min = self._state.Min
    local max = self._state.Max
    local step = self._state.Increment
    local nextValue = math.clamp(tonumber(value) or min, min, max)

    if step > 0 then
        nextValue = math.floor((nextValue / step) + 0.5) * step
    end

    if self._state.Rounding > 0 then
        local precision = 10 ^ self._state.Rounding
        nextValue = math.round(nextValue * precision) / precision
    else
        nextValue = math.round(nextValue)
    end

    return math.clamp(nextValue, min, max)
end

local function formatValue(self, value)
    if self._formatDisplay then
        return tostring(self._formatDisplay(self, value))
    end

    local text = tostring(value)
    if self._state.Suffix then
        text = text .. tostring(self._state.Suffix)
    end

    return text
end

local function createSlider(parent)
    local frame = Instance.new("Frame")
    frame.Name = "Slider"
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Size = UDim2.new(1, 0, 0, SLIDER_HEIGHT)
    frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.BackgroundTransparency = 1
    label.BorderSizePixel = 0
    label.Font = Enum.Font.Gotham
    label.Size = UDim2.new(1, -70, 0, 18)
    label.TextColor3 = Theme["text-secondary"]
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.Parent = frame

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Name = "Value"
    valueLabel.AnchorPoint = Vector2.new(1, 0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.BorderSizePixel = 0
    valueLabel.Font = Enum.Font.GothamMedium
    valueLabel.Position = UDim2.new(1, 0, 0, 0)
    valueLabel.Size = UDim2.fromOffset(68, 18)
    valueLabel.TextColor3 = Theme["text-primary"]
    valueLabel.TextSize = 13
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.TextYAlignment = Enum.TextYAlignment.Center
    valueLabel.Parent = frame

    local barButton = Instance.new("TextButton")
    barButton.Name = "Bar"
    barButton.AutoButtonColor = false
    barButton.BackgroundTransparency = 1
    barButton.BorderSizePixel = 0
    barButton.Position = UDim2.fromOffset(0, 28)
    barButton.Size = UDim2.new(1, 0, 0, KNOB_SIZE)
    barButton.Text = ""
    barButton.Parent = frame

    local track = Instance.new("Frame")
    track.Name = "Track"
    track.AnchorPoint = Vector2.new(0, 0.5)
    track.BackgroundColor3 = Theme["slider-track"]
    track.BorderSizePixel = 0
    track.Position = UDim2.new(0, 0, 0.5, 0)
    track.Size = UDim2.new(1, 0, 0, TRACK_HEIGHT)
    track.Parent = barButton

    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent = track

    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.BackgroundColor3 = Theme.accent
    fill.BorderSizePixel = 0
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.Parent = track

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = fill

    local knob = Instance.new("Frame")
    knob.Name = "Knob"
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.BackgroundColor3 = Theme["slider-knob"]
    knob.BorderSizePixel = 0
    knob.Position = UDim2.new(0, 0, 0.5, 0)
    knob.Size = UDim2.fromOffset(KNOB_SIZE, KNOB_SIZE)
    knob.Parent = barButton

    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob

    return {
        barButton = barButton,
        fill = fill,
        frame = frame,
        knob = knob,
        label = label,
        track = track,
        valueLabel = valueLabel,
    }
end

local function ensureProperty(property)
    assert(LIVE_PROPERTIES[property], string.format("Unsupported slider property %q", tostring(property)))
end

local function valueToAlpha(self)
    local range = self._state.Max - self._state.Min
    if range <= 0 then
        return 0
    end

    return (self._state.Value - self._state.Min) / range
end

local function updateVisuals(self, instant)
    local refs = self._refs
    local alpha = valueToAlpha(self)
    local fillSize = UDim2.new(alpha, 0, 1, 0)
    local knobPosition = UDim2.new(alpha, 0, 0.5, 0)
    local labelColor = self._state.Disabled and Theme["text-placeholder"] or Theme["text-secondary"]
    local valueColor = self._state.Disabled and Theme["text-placeholder"] or Theme["text-primary"]

    refs.frame.Visible = self._state.Visible
    refs.label.Text = self._state.Text
    refs.valueLabel.Text = formatValue(self, self._state.Value)
    refs.barButton.Active = not self._state.Disabled
    refs.knob.BackgroundTransparency = self._state.Disabled and 0.2 or 0

    Ui.cancel(self._tweens.fill)
    Ui.cancel(self._tweens.knob)
    Ui.cancel(self._tweens.label)
    Ui.cancel(self._tweens.value)

    if instant or not Ui.animationsEnabled(refs.frame) then
        refs.fill.Size = fillSize
        refs.knob.Position = knobPosition
        refs.label.TextColor3 = labelColor
        refs.valueLabel.TextColor3 = valueColor
        return
    end

    self._tweens.fill = Ui.play(refs.fill, SLIDER_TWEEN_INFO, {
        Size = fillSize,
    })
    self._tweens.knob = Ui.play(refs.knob, SLIDER_TWEEN_INFO, {
        Position = knobPosition,
    })
    self._tweens.label = Ui.play(refs.label, SLIDER_TWEEN_INFO, {
        TextColor3 = labelColor,
    })
    self._tweens.value = Ui.play(refs.valueLabel, SLIDER_TWEEN_INFO, {
        TextColor3 = valueColor,
    })
end

local function setFromInput(self, xPosition, fireChanged)
    local refs = self._refs
    local startX = refs.track.AbsolutePosition.X
    local width = math.max(1, refs.track.AbsoluteSize.X)
    local alpha = math.clamp((xPosition - startX) / width, 0, 1)
    local rawValue = self._state.Min + ((self._state.Max - self._state.Min) * alpha)
    local nextValue = clampValue(self, rawValue)

    if self._state.Value == nextValue then
        updateVisuals(self, false)
        return
    end

    self._state.Value = nextValue
    updateVisuals(self, false)

    if fireChanged and self._onChanged then
        self._onChanged(self._state.Value)
    end
end

function Slider.new(parent, config)
    local refs = createSlider(parent)
    local cfg = config or {}
    local rounding = math.max(0, tonumber(cfg.Rounding) or 0)
    local increment = tonumber(cfg.Increment)
    if increment == nil then
        increment = 1 / (10 ^ rounding)
    end

    local self = setmetatable({
        Instance = refs.frame,
        Parent = parent,
        _connections = {},
        _destroyed = false,
        _dragging = false,
        _formatDisplay = cfg.FormatDisplayValue or cfg.Format,
        _onChanged = cfg.Changed or cfg.Callback,
        _refs = refs,
        _state = {
            Disabled = getValue(cfg.Disabled, DEFAULTS.Disabled),
            Increment = math.max(increment, 0.0001),
            Max = tonumber(getValue(cfg.Max, DEFAULTS.Max)) or DEFAULTS.Max,
            Min = tonumber(getValue(cfg.Min, DEFAULTS.Min)) or DEFAULTS.Min,
            Rounding = rounding,
            Suffix = cfg.Suffix,
            Text = tostring(getValue(cfg.Text or cfg.Title, DEFAULTS.Text)),
            Value = 0,
            Visible = getValue(cfg.Visible, DEFAULTS.Visible),
        },
        _tweens = {},
    }, SliderMeta)

    self._state.Value = clampValue(self, getValue(cfg.Default, self._state.Min))

    table.insert(self._connections, refs.barButton.MouseButton1Down:Connect(function()
        if self._destroyed or self._state.Disabled then
            return
        end

        self._dragging = true
        setFromInput(self, UserInputService:GetMouseLocation().X, true)
    end))

    table.insert(self._connections, UserInputService.InputChanged:Connect(function(input)
        if not self._dragging or input.UserInputType ~= Enum.UserInputType.MouseMovement then
            return
        end

        setFromInput(self, input.Position.X, true)
    end))

    table.insert(self._connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self._dragging = false
        end
    end))

    updateVisuals(self, true)

    return self
end

function Slider:Set(propertyOrProperties, value)
    if self._destroyed then
        return self
    end

    if type(propertyOrProperties) == "table" then
        for property, nextValue in pairs(propertyOrProperties) do
            ensureProperty(property)
            if property == "Value" then
                self._state.Value = clampValue(self, nextValue)
            elseif property == "Disabled" or property == "Visible" then
                self._state[property] = getValue(nextValue, DEFAULTS[property])
            else
                self._state[property] = tostring(getValue(nextValue, DEFAULTS[property]))
            end
        end
    else
        ensureProperty(propertyOrProperties)
        if propertyOrProperties == "Value" then
            self._state.Value = clampValue(self, value)
        elseif propertyOrProperties == "Disabled" or propertyOrProperties == "Visible" then
            self._state[propertyOrProperties] = getValue(value, DEFAULTS[propertyOrProperties])
        else
            self._state[propertyOrProperties] = tostring(getValue(value, DEFAULTS[propertyOrProperties]))
        end
    end

    updateVisuals(self, false)

    return self
end

function Slider:Update(properties)
    return self:Set(properties)
end

function Slider:SetValue(value)
    local nextValue = clampValue(self, value)
    if self._state.Value == nextValue then
        updateVisuals(self, false)
        return self
    end

    self._state.Value = nextValue
    updateVisuals(self, false)

    if self._onChanged then
        self._onChanged(self._state.Value)
    end

    return self
end

function Slider:OnChanged(callback)
    self._onChanged = callback

    return self
end

function Slider:Destroy()
    if self._destroyed then
        return
    end

    self._destroyed = true

    for _, connection in ipairs(self._connections) do
        connection:Disconnect()
    end

    self._connections = {}

    for _, tween in pairs(self._tweens) do
        Ui.cancel(tween)
    end

    self._tweens = {}
    self.Instance:Destroy()
end

function SliderMeta.__index(self, key)
    local method = Slider[key]
    if method ~= nil then
        return method
    end

    local state = rawget(self, "_state")
    if state and state[key] ~= nil then
        return state[key]
    end

    return rawget(self, key)
end

function SliderMeta.__newindex(self, key, value)
    if rawget(self, "_state") and LIVE_PROPERTIES[key] then
        self:Set(key, value)
        return
    end

    error(string.format("Unsupported slider property %q", tostring(key)))
end

return Slider
