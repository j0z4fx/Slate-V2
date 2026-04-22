local Theme = require(script.Parent.Parent.theme.Theme)
local UserInputService = game:GetService("UserInputService")

local KeyPicker = {}
local KeyPickerMeta = {}

local BUTTON_HEIGHT = 18
local BUTTON_MIN_WIDTH = 42

local LIVE_PROPERTIES = {
    Mode = true,
    Value = true,
}

local DEFAULTS = {
    Default = "None",
    Mode = "Toggle",
    Text = "Keybind",
}

local SPECIAL_INPUTS = {
    [Enum.UserInputType.MouseButton1] = "MB1",
    [Enum.UserInputType.MouseButton2] = "MB2",
    [Enum.UserInputType.MouseButton3] = "MB3",
}

local function normalizeKey(value)
    if value == nil then
        return DEFAULTS.Default
    end

    if typeof(value) == "EnumItem" then
        return value.Name
    end

    return tostring(value)
end

local function inputToKeyName(input)
    if SPECIAL_INPUTS[input.UserInputType] then
        return SPECIAL_INPUTS[input.UserInputType]
    end

    if input.KeyCode and input.KeyCode ~= Enum.KeyCode.Unknown then
        return input.KeyCode.Name
    end

    return nil
end

local function createKeyPicker(parent)
    local button = Instance.new("TextButton")
    button.Name = "KeyPicker"
    button.AutoButtonColor = false
    button.AutomaticSize = Enum.AutomaticSize.X
    button.BackgroundColor3 = Theme["toggle-body"]
    button.BorderSizePixel = 0
    button.Size = UDim2.fromOffset(BUTTON_MIN_WIDTH, BUTTON_HEIGHT)
    button.Text = ""
    button.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = button

    local stroke = Instance.new("UIStroke")
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Color = Theme["toggle-stroke"]
    stroke.Thickness = 1
    stroke.Parent = button

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 8)
    padding.PaddingRight = UDim.new(0, 8)
    padding.Parent = button

    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.AutomaticSize = Enum.AutomaticSize.X
    label.BackgroundTransparency = 1
    label.BorderSizePixel = 0
    label.Font = Enum.Font.Gotham
    label.Size = UDim2.new(0, 0, 1, 0)
    label.TextColor3 = Theme["text-secondary"]
    label.TextSize = 11
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
    assert(LIVE_PROPERTIES[property], string.format("Unsupported key picker property %q", tostring(property)))
end

local function applyMetadata(self)
    local refs = self._refs
    refs.label.Text = self._picking and "..." or self._state.Value
    refs.stroke.Color = self._picking and Theme.accent or Theme["toggle-stroke"]
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
            Value = normalizeKey(cfg.Default),
        },
    }, KeyPickerMeta)

    table.insert(self._connections, refs.button.MouseButton1Click:Connect(function()
        self._picking = true
        applyMetadata(self)
    end))

    table.insert(self._connections, UserInputService.InputBegan:Connect(function(input, processed)
        if processed then
            return
        end

        local keyName = inputToKeyName(input)
        if not keyName then
            return
        end

        if self._picking then
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
        local keyName = inputToKeyName(input)
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
        for property, nextValue in pairs(propertyOrProperties) do
            ensureProperty(property)
            if property == "Value" then
                self._state.Value = normalizeKey(nextValue)
            else
                self._state[property] = tostring(nextValue)
            end
        end
    else
        ensureProperty(propertyOrProperties)
        if propertyOrProperties == "Value" then
            self._state.Value = normalizeKey(value)
        else
            self._state[propertyOrProperties] = tostring(value)
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
