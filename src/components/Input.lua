local Theme = require(script.Parent.Parent.theme.Theme)
local Ui = require(script.Parent.Parent.core.Ui)

local Input = {}
local InputMeta = {}

local FIELD_HEIGHT = 30
local INPUT_TWEEN_INFO = TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

local LIVE_PROPERTIES = {
    Disabled = true,
    Placeholder = true,
    Text = true,
    Value = true,
    Visible = true,
}

local DEFAULTS = {
    Default = "",
    Disabled = false,
    Placeholder = "Enter value...",
    Text = "Input",
    Visible = true,
}

local function getValue(value, fallback)
    if value == nil then
        return fallback
    end

    return value
end

local function normalizeText(value)
    return tostring(getValue(value, ""))
end

local function normalizeValue(self, value)
    local text = normalizeText(value)
    if self and self._state and self._state.Numeric then
        local number = tonumber(text)
        if number == nil then
            return self._state.Value
        end

        return number
    end

    return text
end

local function createInput(parent)
    local frame = Instance.new("Frame")
    frame.Name = "Input"
    frame.AutomaticSize = Enum.AutomaticSize.Y
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Size = UDim2.new(1, 0, 0, 0)
    frame.Parent = parent

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.Padding = UDim.new(0, 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = frame

    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.AutomaticSize = Enum.AutomaticSize.Y
    label.BackgroundTransparency = 1
    label.BorderSizePixel = 0
    label.Font = Enum.Font.Gotham
    label.Size = UDim2.new(1, 0, 0, 0)
    label.TextColor3 = Theme["text-secondary"]
    label.TextSize = 14
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Top
    label.Parent = frame

    local field = Instance.new("Frame")
    field.Name = "Field"
    field.BackgroundColor3 = Theme["input-bg"]
    field.BorderSizePixel = 0
    field.Size = UDim2.new(1, 0, 0, FIELD_HEIGHT)
    field.Parent = frame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = field

    local stroke = Instance.new("UIStroke")
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Color = Theme["input-stroke"]
    stroke.Thickness = 1
    stroke.Parent = field

    local textBox = Instance.new("TextBox")
    textBox.Name = "TextBox"
    textBox.BackgroundTransparency = 1
    textBox.BorderSizePixel = 0
    textBox.ClearTextOnFocus = false
    textBox.Font = Enum.Font.Gotham
    textBox.PlaceholderColor3 = Theme["text-placeholder"]
    textBox.Size = UDim2.new(1, -20, 1, 0)
    textBox.Position = UDim2.fromOffset(10, 0)
    textBox.TextColor3 = Theme["text-primary"]
    textBox.TextSize = 13
    textBox.TextXAlignment = Enum.TextXAlignment.Left
    textBox.TextYAlignment = Enum.TextYAlignment.Center
    textBox.Parent = field

    return {
        field = field,
        frame = frame,
        label = label,
        stroke = stroke,
        textBox = textBox,
    }
end

local function ensureProperty(property)
    assert(LIVE_PROPERTIES[property], string.format("Unsupported input property %q", tostring(property)))
end

local function displayValue(value)
    if typeof(value) == "number" then
        return tostring(value)
    end

    return tostring(value or "")
end

local function applyMetadata(self, instant)
    local refs = self._refs
    local state = self._state
    local strokeColor = self._focused and Theme["input-focus"] or Theme["input-stroke"]
    local labelColor = state.Disabled and Theme["text-placeholder"] or Theme["text-secondary"]
    local fieldTransparency = state.Disabled and 0.18 or 0

    refs.frame.Visible = state.Visible
    refs.label.Text = state.Text
    refs.textBox.PlaceholderText = state.Placeholder
    refs.textBox.Text = displayValue(state.Value)
    refs.textBox.ClearTextOnFocus = state.ClearTextOnFocus
    refs.textBox.TextEditable = not state.Disabled
    refs.textBox.TextTransparency = state.Disabled and 0.25 or 0

    Ui.cancel(self._tweens.field)
    Ui.cancel(self._tweens.stroke)
    Ui.cancel(self._tweens.label)

    if instant or not Ui.animationsEnabled(refs.frame) then
        refs.field.BackgroundTransparency = fieldTransparency
        refs.stroke.Color = strokeColor
        refs.label.TextColor3 = labelColor
        return
    end

    self._tweens.field = Ui.play(refs.field, INPUT_TWEEN_INFO, {
        BackgroundTransparency = fieldTransparency,
    })
    self._tweens.stroke = Ui.play(refs.stroke, INPUT_TWEEN_INFO, {
        Color = strokeColor,
    })
    self._tweens.label = Ui.play(refs.label, INPUT_TWEEN_INFO, {
        TextColor3 = labelColor,
    })
end

local function commitInput(self, fireChanged)
    local refs = self._refs
    local nextValue = normalizeValue(self, refs.textBox.Text)
    self._state.Value = nextValue
    refs.textBox.Text = displayValue(nextValue)

    if fireChanged and self._onChanged then
        self._onChanged(self._state.Value)
    end
end

function Input.new(parent, config)
    local refs = createInput(parent)
    local cfg = config or {}

    local self = setmetatable({
        Instance = refs.frame,
        Parent = parent,
        _connections = {},
        _destroyed = false,
        _focused = false,
        _onChanged = cfg.Changed or cfg.Callback,
        _onFinished = cfg.Finished or cfg.FinishedCallback,
        _refs = refs,
        _state = {
            ClearTextOnFocus = cfg.ClearTextOnFocus == true,
            Disabled = getValue(cfg.Disabled, DEFAULTS.Disabled),
            Numeric = cfg.Numeric == true,
            Placeholder = tostring(getValue(cfg.Placeholder, DEFAULTS.Placeholder)),
            Text = tostring(getValue(cfg.Text or cfg.Title, DEFAULTS.Text)),
            Value = cfg.Numeric == true and (tonumber(cfg.Default) or 0) or tostring(getValue(cfg.Default, DEFAULTS.Default)),
            Visible = getValue(cfg.Visible, DEFAULTS.Visible),
        },
        _tweens = {},
    }, InputMeta)

    table.insert(self._connections, refs.textBox.Focused:Connect(function()
        self._focused = true
        applyMetadata(self, false)
    end))

    table.insert(self._connections, refs.textBox.FocusLost:Connect(function(enterPressed)
        self._focused = false
        commitInput(self, true)
        applyMetadata(self, false)

        if self._onFinished then
            self._onFinished(self._state.Value, enterPressed)
        end
    end))

    table.insert(self._connections, refs.textBox:GetPropertyChangedSignal("Text"):Connect(function()
        if self._destroyed then
            return
        end

        if self._state.Numeric and refs.textBox.Text ~= "" and tonumber(refs.textBox.Text) == nil then
            refs.textBox.Text = displayValue(self._state.Value)
            return
        end

        if cfg.Live == true and self._focused then
            commitInput(self, true)
        end
    end))

    applyMetadata(self, true)

    return self
end

function Input:Set(propertyOrProperties, value)
    if self._destroyed then
        return self
    end

    if type(propertyOrProperties) == "table" then
        for property, nextValue in pairs(propertyOrProperties) do
            ensureProperty(property)
            if property == "Value" then
                self._state.Value = normalizeValue(self, nextValue)
            elseif property == "Disabled" or property == "Visible" then
                self._state[property] = getValue(nextValue, DEFAULTS[property])
            else
                self._state[property] = normalizeText(nextValue)
            end
        end
    else
        ensureProperty(propertyOrProperties)
        if propertyOrProperties == "Value" then
            self._state.Value = normalizeValue(self, value)
        elseif propertyOrProperties == "Disabled" or propertyOrProperties == "Visible" then
            self._state[propertyOrProperties] = getValue(value, DEFAULTS[propertyOrProperties])
        else
            self._state[propertyOrProperties] = normalizeText(value)
        end
    end

    applyMetadata(self, false)

    return self
end

function Input:Update(properties)
    return self:Set(properties)
end

function Input:SetValue(value)
    return self:Set("Value", value)
end

function Input:OnChanged(callback)
    self._onChanged = callback

    return self
end

function Input:OnFinished(callback)
    self._onFinished = callback

    return self
end

function Input:Destroy()
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

function InputMeta.__index(self, key)
    local method = Input[key]
    if method ~= nil then
        return method
    end

    local state = rawget(self, "_state")
    if state and state[key] ~= nil then
        return state[key]
    end

    return rawget(self, key)
end

function InputMeta.__newindex(self, key, value)
    if rawget(self, "_state") and LIVE_PROPERTIES[key] then
        self:Set(key, value)
        return
    end

    error(string.format("Unsupported input property %q", tostring(key)))
end

return Input
