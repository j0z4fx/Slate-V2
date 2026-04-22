local Theme = require(script.Parent.Parent.theme.Theme)
local Keybind = require(script.Parent.Parent.core.Keybind)
local TextService = game:GetService("TextService")
local UserInputService = game:GetService("UserInputService")

local KeyPicker = {}
local KeyPickerMeta = {}

local BUTTON_HEIGHT = 18
local CORNER_RADIUS = 4
local FONT = Enum.Font.Gotham
local FONT_SIZE = 11
local OPTICAL_CENTER_OFFSET_Y = 1
local PADDING_X = 8

local LIVE_PROPERTIES = {
    Mode = true,
    Value = true,
}

local DEFAULTS = {
    Default = "None",
    Mode = "Toggle",
    Text = "Keybind",
}

local function getButtonWidth(text)
    local textWidth = TextService:GetTextSize(text, FONT_SIZE, FONT, Vector2.new(math.huge, BUTTON_HEIGHT)).X

    return math.max(BUTTON_HEIGHT, textWidth + (PADDING_X * 2))
end

local function notifyParentLayout(self)
    if self.Parent and self.Parent._syncAddonLayout then
        self.Parent:_syncAddonLayout()
    end
end

local function createKeyPicker(parent)
    local button = Instance.new("TextButton")
    button.Name = "KeyPicker"
    button.AutoButtonColor = false
    button.BackgroundColor3 = Theme["toggle-body"]
    button.BorderSizePixel = 0
    button.Size = UDim2.fromOffset(BUTTON_HEIGHT, BUTTON_HEIGHT)
    button.Text = ""
    button.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, CORNER_RADIUS)
    corner.Parent = button

    local overlay = Instance.new("Frame")
    overlay.Name = "Overlay"
    overlay.BackgroundColor3 = Theme.accent
    overlay.BackgroundTransparency = 1
    overlay.BorderSizePixel = 0
    overlay.Size = UDim2.fromScale(1, 1)
    overlay.Parent = button

    local overlayCorner = Instance.new("UICorner")
    overlayCorner.CornerRadius = UDim.new(0, CORNER_RADIUS)
    overlayCorner.Parent = overlay

    local stroke = Instance.new("UIStroke")
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Color = Theme["toggle-stroke"]
    stroke.Thickness = 1
    stroke.Parent = button

    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.BackgroundTransparency = 1
    label.BorderSizePixel = 0
    label.Font = FONT
    label.Position = UDim2.fromOffset(0, OPTICAL_CENTER_OFFSET_Y)
    label.Size = UDim2.new(1, 0, 1, 0)
    label.TextColor3 = Theme["text-secondary"]
    label.TextSize = FONT_SIZE
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.Parent = button

    return {
        button = button,
        label = label,
        overlay = overlay,
        stroke = stroke,
    }
end

local function ensureProperty(property)
    assert(LIVE_PROPERTIES[property], string.format("Unsupported key picker property %q", tostring(property)))
end

local function applyMetadata(self)
    local refs = self._refs
    local text = self._picking and "..." or Keybind.format(self._state.Value)

    refs.label.Text = text
    refs.button.Size = UDim2.fromOffset(getButtonWidth(text), BUTTON_HEIGHT)
    refs.stroke.Color = self._picking and Theme.accent or Theme["toggle-stroke"]
    refs.stroke.Transparency = 0
    refs.overlay.BackgroundTransparency = self._picking and 0.84 or 1

    notifyParentLayout(self)
end

local function syncParentToggle(self, state)
    if self._state.SyncToggleState and self.Parent and self.Parent.SetValue then
        self.Parent:SetValue(state)
    end
end

local function handleTriggered(self, state)
    self._state.Toggled = state
    syncParentToggle(self, state)

    if self._onClicked then
        self._onClicked(state)
    end

    if self._onChanged then
        self._onChanged(state)
    end
end

function KeyPicker.new(toggle, config)
    local refs = createKeyPicker(toggle._refs.addonRow)
    local cfg = config or {}

    local self = setmetatable({
        Instance = refs.button,
        Parent = toggle,
        _connections = {},
        _destroyed = false,
        _onChanged = cfg.Changed or cfg.ChangedCallback or cfg.Callback,
        _onClicked = cfg.Clicked or cfg.Callback,
        _picking = false,
        _refs = refs,
        _state = {
            Mode = tostring(cfg.Mode or DEFAULTS.Mode),
            SyncToggleState = cfg.SyncToggleState == true,
            Toggled = false,
            Value = Keybind.normalize(cfg.Default),
        },
    }, KeyPickerMeta)

    table.insert(self._connections, refs.button.MouseButton1Click:Connect(function()
        Keybind.beginCapture(self)
        self._picking = true
        applyMetadata(self)
    end))

    table.insert(self._connections, UserInputService.InputBegan:Connect(function(input, processed)
        if processed then
            return
        end

        local keyName = Keybind.inputToKeyName(input)
        if not keyName then
            return
        end

        if self._picking then
            Keybind.endCapture(self)
            self._picking = false
            self._state.Value = keyName
            applyMetadata(self)

            if self._onChanged then
                self._onChanged(self._state.Value)
            end
            return
        end

        if keyName ~= self._state.Value then
            return
        end

        if self._state.Mode == "Hold" then
            handleTriggered(self, true)
        elseif self._state.Mode == "Always" then
            handleTriggered(self, true)
        else
            handleTriggered(self, not self._state.Toggled)
        end
    end))

    table.insert(self._connections, UserInputService.InputEnded:Connect(function(input)
        local keyName = Keybind.inputToKeyName(input)
        if keyName ~= self._state.Value then
            return
        end

        if self._state.Mode == "Hold" then
            handleTriggered(self, false)
        end
    end))

    applyMetadata(self)

    return self
end

function KeyPicker:Set(propertyOrProperties, value)
    if self._destroyed then
        return self
    end

    if type(propertyOrProperties) == "table" then
        local changedValue = false

        for property, nextValue in pairs(propertyOrProperties) do
            ensureProperty(property)
            if property == "Value" then
                local normalized = Keybind.normalize(nextValue)
                if self._state.Value ~= normalized then
                    self._state.Value = normalized
                    changedValue = true
                end
            else
                local normalized = tostring(nextValue)
                if self._state[property] ~= normalized then
                    self._state[property] = normalized
                end
            end
        end

        if changedValue and self._onChanged then
            self._onChanged(self._state.Value)
        end
    else
        ensureProperty(propertyOrProperties)
        if propertyOrProperties == "Value" then
            local normalized = Keybind.normalize(value)
            if self._state.Value == normalized then
                applyMetadata(self)
                return self
            end
            self._state.Value = normalized
            if self._onChanged then
                self._onChanged(self._state.Value)
            end
        else
            local normalized = tostring(value)
            if self._state[propertyOrProperties] == normalized then
                applyMetadata(self)
                return self
            end
            self._state[propertyOrProperties] = normalized
        end
    end

    applyMetadata(self)

    return self
end

function KeyPicker:Update(properties)
    return self:Set(properties)
end

function KeyPicker:SetValue(value)
    return self:Set("Value", value)
end

function KeyPicker:SetMode(mode)
    return self:Set("Mode", mode)
end

function KeyPicker:GetState()
    return self._state.Toggled
end

function KeyPicker:OnChanged(callback)
    self._onChanged = callback

    return self
end

function KeyPicker:OnClick(callback)
    self._onClicked = callback

    return self
end

function KeyPicker:Destroy()
    if self._destroyed then
        return
    end

    self._destroyed = true
    Keybind.endCapture(self)
    for _, connection in ipairs(self._connections) do
        connection:Disconnect()
    end
    self._connections = {}
    self.Instance:Destroy()
end

function KeyPickerMeta.__index(self, key)
    local method = KeyPicker[key]
    if method ~= nil then
        return method
    end

    local state = rawget(self, "_state")
    if state and state[key] ~= nil then
        return state[key]
    end

    return rawget(self, key)
end

function KeyPickerMeta.__newindex(self, key, value)
    if rawget(self, "_state") and LIVE_PROPERTIES[key] then
        self:Set(key, value)
        return
    end

    error(string.format("Unsupported key picker property %q", tostring(key)))
end

return KeyPicker
