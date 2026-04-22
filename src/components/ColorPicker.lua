local Theme = require(script.Parent.Parent.theme.Theme)
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local ColorPicker = {}
local ColorPickerMeta = {}

local BUTTON_SIZE = 18
local MENU_SIZE = Vector2.new(188, 176)
local CURSOR_SIZE = 10
local HUE_WIDTH = 14
local PICKER_TWEEN = TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

local LIVE_PROPERTIES = {
    Title = true,
    Value = true,
}

local DEFAULTS = {
    Default = Color3.new(1, 1, 1),
    Title = "Color",
}

local function getValue(value, fallback)
    if value == nil then
        return fallback
    end

    return value
end

local function normalizePropertyValue(property, value)
    if property == "Title" then
        return tostring(getValue(value, DEFAULTS.Title))
    end

    if property == "Value" then
        if typeof(value) == "Color3" then
            return value
        end

        return DEFAULTS.Default
    end

    return value
end

local function createMenu(parent)
    local button = Instance.new("TextButton")
    button.Name = "ColorPickerButton"
    button.AutoButtonColor = false
    button.BackgroundColor3 = Theme.accent
    button.BorderSizePixel = 0
    button.Size = UDim2.fromOffset(BUTTON_SIZE, BUTTON_SIZE)
    button.Text = ""
    button.Parent = parent

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 4)
    buttonCorner.Parent = button

    local buttonStroke = Instance.new("UIStroke")
    buttonStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    buttonStroke.Color = Theme["surface-stroke"]
    buttonStroke.Thickness = 1
    buttonStroke.Parent = button

    local screenGui = parent:FindFirstAncestorOfClass("ScreenGui")

    local menu = Instance.new("Frame")
    menu.Name = "ColorPickerMenu"
    menu.BackgroundColor3 = Theme.surface
    menu.BorderSizePixel = 0
    menu.Size = UDim2.fromOffset(MENU_SIZE.X, MENU_SIZE.Y)
    menu.Visible = false
    menu.ZIndex = 200
    menu.Parent = screenGui or parent

    local menuCorner = Instance.new("UICorner")
    menuCorner.CornerRadius = UDim.new(0, 6)
    menuCorner.Parent = menu

    local menuStroke = Instance.new("UIStroke")
    menuStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    menuStroke.Color = Theme["surface-stroke"]
    menuStroke.Thickness = 1
    menuStroke.Parent = menu

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 8)
    padding.PaddingBottom = UDim.new(0, 8)
    padding.PaddingLeft = UDim.new(0, 8)
    padding.PaddingRight = UDim.new(0, 8)
    padding.Parent = menu

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.BackgroundTransparency = 1
    title.BorderSizePixel = 0
    title.Font = Enum.Font.GothamMedium
    title.Size = UDim2.new(1, 0, 0, 16)
    title.TextColor3 = Theme["text-primary"]
    title.TextSize = 13
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextYAlignment = Enum.TextYAlignment.Center
    title.ZIndex = 201
    title.Parent = menu

    local picker = Instance.new("Frame")
    picker.Name = "Picker"
    picker.BackgroundColor3 = Color3.new(1, 0, 0)
    picker.BorderSizePixel = 0
    picker.Position = UDim2.fromOffset(0, 24)
    picker.Size = UDim2.fromOffset(150, 120)
    picker.ZIndex = 201
    picker.Parent = menu

    local pickerCorner = Instance.new("UICorner")
    pickerCorner.CornerRadius = UDim.new(0, 4)
    pickerCorner.Parent = picker

    local pickerWhite = Instance.new("Frame")
    pickerWhite.BackgroundColor3 = Color3.new(1, 1, 1)
    pickerWhite.BorderSizePixel = 0
    pickerWhite.Size = UDim2.fromScale(1, 1)
    pickerWhite.ZIndex = 202
    pickerWhite.Parent = picker

    local whiteGradient = Instance.new("UIGradient")
    whiteGradient.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(1, 1, 1))
    whiteGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 1),
    })
    whiteGradient.Rotation = 0
    whiteGradient.Parent = pickerWhite

    local pickerBlack = Instance.new("Frame")
    pickerBlack.BackgroundColor3 = Color3.new(0, 0, 0)
    pickerBlack.BorderSizePixel = 0
    pickerBlack.Size = UDim2.fromScale(1, 1)
    pickerBlack.ZIndex = 203
    pickerBlack.Parent = picker

    local blackGradient = Instance.new("UIGradient")
    blackGradient.Color = ColorSequence.new(Color3.new(0, 0, 0), Color3.new(0, 0, 0))
    blackGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(1, 0),
    })
    blackGradient.Rotation = 90
    blackGradient.Parent = pickerBlack

    local pickerCursor = Instance.new("Frame")
    pickerCursor.Name = "PickerCursor"
    pickerCursor.AnchorPoint = Vector2.new(0.5, 0.5)
    pickerCursor.BackgroundTransparency = 1
    pickerCursor.BorderSizePixel = 0
    pickerCursor.Size = UDim2.fromOffset(CURSOR_SIZE, CURSOR_SIZE)
    pickerCursor.ZIndex = 204
    pickerCursor.Parent = picker

    local pickerCursorStroke = Instance.new("UIStroke")
    pickerCursorStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    pickerCursorStroke.Color = Color3.new(1, 1, 1)
    pickerCursorStroke.Thickness = 1
    pickerCursorStroke.Parent = pickerCursor

    local pickerCursorCorner = Instance.new("UICorner")
    pickerCursorCorner.CornerRadius = UDim.new(1, 0)
    pickerCursorCorner.Parent = pickerCursor

    local hue = Instance.new("Frame")
    hue.Name = "Hue"
    hue.BorderSizePixel = 0
    hue.Position = UDim2.fromOffset(158, 24)
    hue.Size = UDim2.fromOffset(HUE_WIDTH, 120)
    hue.ZIndex = 201
    hue.Parent = menu

    local hueCorner = Instance.new("UICorner")
    hueCorner.CornerRadius = UDim.new(0, 4)
    hueCorner.Parent = hue

    local hueGradient = Instance.new("UIGradient")
    hueGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
        ColorSequenceKeypoint.new(0.16, Color3.fromHSV(0.16, 1, 1)),
        ColorSequenceKeypoint.new(0.33, Color3.fromHSV(0.33, 1, 1)),
        ColorSequenceKeypoint.new(0.5, Color3.fromHSV(0.5, 1, 1)),
        ColorSequenceKeypoint.new(0.66, Color3.fromHSV(0.66, 1, 1)),
        ColorSequenceKeypoint.new(0.83, Color3.fromHSV(0.83, 1, 1)),
        ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1)),
    })
    hueGradient.Rotation = 90
    hueGradient.Parent = hue

    local hueCursor = Instance.new("Frame")
    hueCursor.Name = "HueCursor"
    hueCursor.AnchorPoint = Vector2.new(0.5, 0.5)
    hueCursor.BackgroundColor3 = Color3.new(1, 1, 1)
    hueCursor.BorderSizePixel = 0
    hueCursor.Position = UDim2.fromScale(0.5, 0)
    hueCursor.Size = UDim2.new(1, 4, 0, 2)
    hueCursor.ZIndex = 202
    hueCursor.Parent = hue

    local preview = Instance.new("Frame")
    preview.Name = "Preview"
    preview.BackgroundColor3 = Theme.accent
    preview.BorderSizePixel = 0
    preview.Position = UDim2.fromOffset(0, 152)
    preview.Size = UDim2.new(1, 0, 0, 16)
    preview.ZIndex = 201
    preview.Parent = menu

    local previewCorner = Instance.new("UICorner")
    previewCorner.CornerRadius = UDim.new(0, 4)
    previewCorner.Parent = preview

    return {
        button = button,
        buttonStroke = buttonStroke,
        hue = hue,
        hueCursor = hueCursor,
        menu = menu,
        picker = picker,
        pickerCursor = pickerCursor,
        preview = preview,
        title = title,
    }
end

local function ensureProperty(property)
    assert(LIVE_PROPERTIES[property], string.format("Unsupported color picker property %q", tostring(property)))
end

local function positionMenu(self)
    local refs = self._refs
    local screenGui = refs.menu.Parent
    local absolutePosition = self.Instance.AbsolutePosition

    if screenGui and screenGui:IsA("ScreenGui") then
        refs.menu.Position = UDim2.fromOffset(
            absolutePosition.X + self.Instance.AbsoluteSize.X + 8,
            absolutePosition.Y
        )
    end
end

local function applyVisuals(self)
    local refs = self._refs
    local state = self._state
    local hue, sat, val = state.Value:ToHSV()

    refs.button.BackgroundColor3 = state.Value
    refs.preview.BackgroundColor3 = state.Value
    refs.picker.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
    refs.pickerCursor.Position = UDim2.fromScale(sat, 1 - val)
    refs.hueCursor.Position = UDim2.fromScale(0.5, hue)
    refs.title.Text = state.Title
end

local function closeMenu(self)
    self._refs.menu.Visible = false
    self._open = false
end

local function openMenu(self)
    positionMenu(self)
    self._refs.menu.Visible = true
    self._open = true
end

local function setColorFromPicker(self, xScale, yScale)
    local hue = select(1, self._state.Value:ToHSV())
    local sat = math.clamp(xScale, 0, 1)
    local val = 1 - math.clamp(yScale, 0, 1)

    self:SetValue(Color3.fromHSV(hue, sat, val))
end

local function setColorFromHue(self, yScale)
    local _, sat, val = self._state.Value:ToHSV()
    local hue = math.clamp(yScale, 0, 1)

    self:SetValue(Color3.fromHSV(hue, sat, val))
end

function ColorPicker.new(toggle, config)
    local refs = createMenu(toggle._refs.addonRow)
    local cfg = config or {}

    local self = setmetatable({
        Instance = refs.button,
        Parent = toggle,
        _connections = {},
        _destroyed = false,
        _dragTarget = nil,
        _onChanged = cfg.Changed or cfg.Callback,
        _open = false,
        _refs = refs,
        _state = {
            Title = normalizePropertyValue("Title", cfg.Title or cfg.Text),
            Value = normalizePropertyValue("Value", cfg.Default),
        },
    }, ColorPickerMeta)

    table.insert(self._connections, refs.button.MouseButton1Click:Connect(function()
        if self._open then
            closeMenu(self)
        else
            openMenu(self)
        end
    end))

    table.insert(self._connections, refs.picker.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
            return
        end

        self._dragTarget = "picker"
        local pos = input.Position
        local abs = refs.picker.AbsolutePosition
        local size = refs.picker.AbsoluteSize
        setColorFromPicker(self, (pos.X - abs.X) / size.X, (pos.Y - abs.Y) / size.Y)
    end))

    table.insert(self._connections, refs.hue.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
            return
        end

        self._dragTarget = "hue"
        local pos = input.Position
        local abs = refs.hue.AbsolutePosition
        local size = refs.hue.AbsoluteSize
        setColorFromHue(self, (pos.Y - abs.Y) / size.Y)
    end))

    table.insert(self._connections, UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseMovement then
            return
        end

        if self._dragTarget == "picker" then
            local abs = refs.picker.AbsolutePosition
            local size = refs.picker.AbsoluteSize
            setColorFromPicker(self, (input.Position.X - abs.X) / size.X, (input.Position.Y - abs.Y) / size.Y)
        elseif self._dragTarget == "hue" then
            local abs = refs.hue.AbsolutePosition
            local size = refs.hue.AbsoluteSize
            setColorFromHue(self, (input.Position.Y - abs.Y) / size.Y)
        end
    end))

    table.insert(self._connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self._dragTarget = nil
        end
    end))

    table.insert(self._connections, UserInputService.InputBegan:Connect(function(input, processed)
        if not self._open or processed then
            return
        end

        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
            return
        end

        local mouse = input.Position
        local menuPos = refs.menu.AbsolutePosition
        local menuSize = refs.menu.AbsoluteSize
        local btnPos = refs.button.AbsolutePosition
        local btnSize = refs.button.AbsoluteSize

        local inMenu = mouse.X >= menuPos.X and mouse.X <= menuPos.X + menuSize.X and mouse.Y >= menuPos.Y and mouse.Y <= menuPos.Y + menuSize.Y
        local inButton = mouse.X >= btnPos.X and mouse.X <= btnPos.X + btnSize.X and mouse.Y >= btnPos.Y and mouse.Y <= btnPos.Y + btnSize.Y

        if not inMenu and not inButton then
            closeMenu(self)
        end
    end))

    applyVisuals(self)

    return self
end

function ColorPicker:Set(propertyOrProperties, value)
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

    applyVisuals(self)

    if (propertyOrProperties == "Value" or type(propertyOrProperties) == "table") and self._onChanged then
        self._onChanged(self._state.Value)
    end

    return self
end

function ColorPicker:Update(properties)
    return self:Set(properties)
end

function ColorPicker:SetValue(value)
    return self:Set("Value", value)
end

function ColorPicker:OnChanged(callback)
    self._onChanged = callback

    return self
end

function ColorPicker:Open()
    openMenu(self)

    return self
end

function ColorPicker:Close()
    closeMenu(self)

    return self
end

function ColorPicker:Destroy()
    if self._destroyed then
        return
    end

    self._destroyed = true
    for _, connection in ipairs(self._connections) do
        connection:Disconnect()
    end
    self._connections = {}
    self._refs.menu:Destroy()
    self.Instance:Destroy()
end

function ColorPickerMeta.__index(self, key)
    local method = ColorPicker[key]
    if method ~= nil then
        return method
    end

    local state = rawget(self, "_state")
    if state and state[key] ~= nil then
        return state[key]
    end

    return rawget(self, key)
end

function ColorPickerMeta.__newindex(self, key, value)
    if rawget(self, "_state") and LIVE_PROPERTIES[key] then
        self:Set(key, value)
        return
    end

    error(string.format("Unsupported color picker property %q", tostring(key)))
end

return ColorPicker
