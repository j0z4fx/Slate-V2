local Theme = {
    background = Color3.fromRGB(15, 15, 24),
    ["nav-bg"] = Color3.fromRGB(12, 12, 20),
    ["nav-stroke"] = Color3.fromRGB(37, 37, 46),
    ["text-primary"] = Color3.fromRGB(212, 212, 236),
    ["text-secondary"] = Color3.fromRGB(94, 94, 126),
    accent = Color3.fromRGB(255, 91, 155),
    surface = Color3.fromRGB(21, 21, 33),
    ["surface-stroke"] = Color3.fromRGB(38, 38, 58),
    ["divider-line"] = Color3.fromRGB(37, 37, 46),
    ["separator-text"] = Color3.fromRGB(82, 94, 114),
    ["label-primary"] = Color3.fromRGB(212, 212, 236),
    ["label-subtext"] = Color3.fromRGB(94, 94, 126),
    ["toggle-body"] = Color3.fromRGB(32, 32, 46),
    ["toggle-dot"] = Color3.fromRGB(94, 94, 126),
    ["toggle-stroke"] = Color3.fromRGB(46, 46, 68),
}

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

local protectGui = protectgui or (syn and syn.protect_gui) or function() end
local getHiddenUi = gethui

local Root = {}
local ROOT_NAME = "Slate"
local ROOT_ATTRIBUTE = "SlateOwned"

local function resolveContainer()
    if typeof(getHiddenUi) == "function" then
        local success, hiddenUi = pcall(getHiddenUi)
        if success and typeof(hiddenUi) == "Instance" then
            return hiddenUi
        end
    end

    local localPlayer = Players.LocalPlayer
    local playerGui = localPlayer and (localPlayer:FindFirstChildOfClass("PlayerGui") or localPlayer:WaitForChild("PlayerGui"))

    if RunService:IsStudio() and playerGui then
        return playerGui
    end

    if CoreGui then
        return CoreGui
    end

    return playerGui
end

local function findOwnedRoot(container)
    for _, child in ipairs(container:GetChildren()) do
        if child.Name == ROOT_NAME and child:GetAttribute(ROOT_ATTRIBUTE) then
            return child
        end
    end

    return nil
end

function Root.getOrCreate()
    local container = resolveContainer()
    local existing = findOwnedRoot(container)

    if existing then
        existing:Destroy()
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = ROOT_NAME
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.Enabled = true
    screenGui.DisplayOrder = 100
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui:SetAttribute(ROOT_ATTRIBUTE, true)

    pcall(protectGui, screenGui)
    screenGui.Parent = container

    return screenGui
end

function Root.getExisting()
    local container = resolveContainer()

    return findOwnedRoot(container)
end

function Root.destroy(target)
    local existing = target or Root.getExisting()

    if existing then
        pcall(function()
            existing:Destroy()
        end)
    end
end

local Lucide = {}

local SOURCE_URL = "https://github.com/latte-soft/lucide-roblox/releases/latest/download/lucide-roblox.luau"

local ICON_ALIASES = {
    ["circle-question-mark"] = "help-circle",
    house = "home",
}

local cachedModule = nil
local warned = false

local function resolveModule()
    if cachedModule then
        return cachedModule
    end

    assert(type(loadstring) == "function", "Slate requires loadstring support for Lucide icons")

    local source = game:HttpGet(SOURCE_URL)
    cachedModule = loadstring(source)()

    return cachedModule
end

function Lucide.GetAsset(name)
    local success, result = pcall(function()
        local iconName = ICON_ALIASES[name] or name

        return resolveModule().GetAsset(iconName, 48)
    end)

    if success then
        return result
    end

    if not warned then
        warned = true
        warn(string.format("Slate failed to load Lucide icons: %s", tostring(result)))
    end

    return nil
end

local UserInputService = game:GetService("UserInputService")

local ColorPicker = {}
local ColorPickerMeta = {}

local BUTTON_SIZE = 18
local MENU_SIZE = Vector2.new(188, 184)
local CURSOR_SIZE = 10
local HUE_WIDTH = 14
local MENU_MARGIN = 10

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

local function setInternal(self, key, value)
    rawset(self, key, value)
end

local function findWindowRoot(instance)
    local current = instance

    while current do
        if current.GetAttribute and current:GetAttribute("SlateComponent") == "Window" then
            return current
        end

        current = current.Parent
    end

    return nil
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

    local windowRoot = findWindowRoot(parent)

    local menu = Instance.new("Frame")
    menu.Name = "ColorPickerMenu"
    menu.BackgroundColor3 = Theme.surface
    menu.BorderSizePixel = 0
    menu.ClipsDescendants = true
    menu.Size = UDim2.fromOffset(MENU_SIZE.X, MENU_SIZE.Y)
    menu.Visible = false
    menu.ZIndex = 150
    menu.Parent = windowRoot or parent

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

    local pickerBody = Instance.new("Frame")
    pickerBody.Name = "PickerBody"
    pickerBody.BackgroundTransparency = 1
    pickerBody.BorderSizePixel = 0
    pickerBody.Position = UDim2.fromOffset(0, 24)
    pickerBody.Size = UDim2.fromOffset(150, 120)
    pickerBody.ZIndex = 201
    pickerBody.Parent = menu

    local picker = Instance.new("Frame")
    picker.Name = "Picker"
    picker.BackgroundColor3 = Color3.new(1, 0, 0)
    picker.BorderSizePixel = 0
    picker.ClipsDescendants = true
    picker.Size = UDim2.fromScale(1, 1)
    picker.ZIndex = 201
    picker.Parent = pickerBody

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
    preview.Position = UDim2.fromOffset(0, 156)
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
        pickerBody = pickerBody,
        picker = picker,
        pickerCursor = pickerCursor,
        preview = preview,
        title = title,
        windowRoot = windowRoot,
    }
end

local function ensureProperty(property)
    assert(LIVE_PROPERTIES[property], string.format("Unsupported color picker property %q", tostring(property)))
end

local function positionMenu(self)
    local refs = self._refs
    local absolutePosition = self.Instance.AbsolutePosition
    local buttonSize = self.Instance.AbsoluteSize
    local windowRoot = refs.windowRoot

    if windowRoot then
        local rootPosition = windowRoot.AbsolutePosition
        local rootSize = windowRoot.AbsoluteSize
        local targetX = absolutePosition.X - rootPosition.X + buttonSize.X + 8
        local targetY = absolutePosition.Y - rootPosition.Y

        targetX = math.clamp(targetX, MENU_MARGIN, math.max(MENU_MARGIN, rootSize.X - refs.menu.AbsoluteSize.X - MENU_MARGIN))
        targetY = math.clamp(targetY, MENU_MARGIN, math.max(MENU_MARGIN, rootSize.Y - refs.menu.AbsoluteSize.Y - MENU_MARGIN))

        refs.menu.Position = UDim2.fromOffset(
            targetX,
            targetY
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
        _dragTarget = false,
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

        setInternal(self, "_dragTarget", "picker")
        local pos = input.Position
        local abs = refs.picker.AbsolutePosition
        local size = refs.picker.AbsoluteSize
        setColorFromPicker(self, (pos.X - abs.X) / size.X, (pos.Y - abs.Y) / size.Y)
    end))

    table.insert(self._connections, refs.hue.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
            return
        end

        setInternal(self, "_dragTarget", "hue")
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
            setInternal(self, "_dragTarget", false)
        end
    end))

    table.insert(self._connections, UserInputService.InputBegan:Connect(function(input, processed)
        if not self._open then
            return
        end

        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
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


local Divider = {}
local DividerMeta = {}

local HEIGHT = 8

local function createDivider(parent)
    local frame = Instance.new("Frame")
    frame.Name = "Divider"
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Size = UDim2.new(1, 0, 0, HEIGHT)
    frame.Parent = parent

    local line = Instance.new("Frame")
    line.Name = "Line"
    line.AnchorPoint = Vector2.new(0, 0.5)
    line.BackgroundColor3 = Theme["divider-line"]
    line.BorderSizePixel = 0
    line.Position = UDim2.new(0, 0, 0.5, 0)
    line.Size = UDim2.new(1, 0, 0, 1)
    line.Parent = frame

    return {
        frame = frame,
        line = line,
    }
end

function Divider.new(parent)
    local refs = createDivider(parent)

    local self = setmetatable({
        Instance = refs.frame,
        _destroyed = false,
        _refs = refs,
    }, DividerMeta)

    return self
end

function Divider:Destroy()
    if self._destroyed then
        return
    end

    self._destroyed = true
    self.Instance:Destroy()
end

function DividerMeta.__index(self, key)
    local method = Divider[key]
    if method ~= nil then
        return method
    end

    return rawget(self, key)
end

local UserInputService = game:GetService("UserInputService")

local KeyPicker = {}
local KeyPickerMeta = {}

local BUTTON_HEIGHT = 18
local CORNER_RADIUS = 4
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

local function formatKeyName(value)
    local key = normalizeKey(value)
    if key == "None" then
        return key
    end

    key = key:gsub("(%l)(%u)", "%1 %2")
    key = key:gsub("Button(%d)", "Button %1")

    return key
end

local function createKeyPicker(parent)
    local button = Instance.new("TextButton")
    button.Name = "KeyPicker"
    button.AutoButtonColor = false
    button.AutomaticSize = Enum.AutomaticSize.X
    button.BackgroundColor3 = Theme["toggle-body"]
    button.BorderSizePixel = 0
    button.Size = UDim2.fromOffset(0, BUTTON_HEIGHT)
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
    overlay.Position = UDim2.new(0, -PADDING_X, 0, 0)
    overlay.Size = UDim2.new(1, PADDING_X * 2, 1, 0)
    overlay.Parent = button

    local overlayCorner = Instance.new("UICorner")
    overlayCorner.CornerRadius = UDim.new(0, CORNER_RADIUS)
    overlayCorner.Parent = overlay

    local stroke = Instance.new("UIStroke")
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Color = Theme["toggle-stroke"]
    stroke.Thickness = 1
    stroke.Parent = button

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, PADDING_X)
    padding.PaddingRight = UDim.new(0, PADDING_X)
    padding.Parent = button

    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.AutomaticSize = Enum.AutomaticSize.X
    label.BackgroundTransparency = 1
    label.BorderSizePixel = 0
    label.Font = Enum.Font.Gotham
    label.Size = UDim2.new(0, 0, 0, BUTTON_HEIGHT)
    label.TextColor3 = Theme["text-secondary"]
    label.TextSize = 11
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
    refs.label.Text = self._picking and "..." or formatKeyName(self._state.Value)
    refs.stroke.Color = self._picking and Theme.accent or Theme["toggle-stroke"]
    refs.stroke.Transparency = 0
    refs.overlay.BackgroundTransparency = self._picking and 0.84 or 1
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


local Separator = {}
local SeparatorMeta = {}

local HEIGHT = 12
local TEXT_PADDING = 10

local LIVE_PROPERTIES = {
    Text = true,
    Visible = true,
}

local DEFAULTS = {
    Text = "Separator",
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

    if property == "Visible" then
        return getValue(value, DEFAULTS.Visible)
    end

    return value
end

local function createSeparator(parent)
    local frame = Instance.new("Frame")
    frame.Name = "Separator"
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Size = UDim2.new(1, 0, 0, HEIGHT)
    frame.Parent = parent

    local line = Instance.new("Frame")
    line.Name = "Line"
    line.AnchorPoint = Vector2.new(0, 0.5)
    line.BackgroundColor3 = Theme["divider-line"]
    line.BorderSizePixel = 0
    line.Position = UDim2.new(0, 0, 0.5, 0)
    line.Size = UDim2.new(1, 0, 0, 1)
    line.Parent = frame

    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.AnchorPoint = Vector2.new(0.5, 0.5)
    label.AutomaticSize = Enum.AutomaticSize.X
    label.BackgroundColor3 = Theme.surface
    label.BackgroundTransparency = 0
    label.BorderSizePixel = 0
    label.Font = Enum.Font.Gotham
    label.Position = UDim2.fromScale(0.5, 0.5)
    label.Size = UDim2.new(0, 0, 1, 0)
    label.TextColor3 = Theme["separator-text"]
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.Parent = frame

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, TEXT_PADDING)
    padding.PaddingRight = UDim.new(0, TEXT_PADDING)
    padding.Parent = label

    return {
        frame = frame,
        line = line,
        label = label,
    }
end

local function ensureProperty(property)
    assert(LIVE_PROPERTIES[property], string.format("Unsupported separator property %q", tostring(property)))
end

local function applyMetadata(self)
    local refs = self._refs
    local state = self._state

    refs.frame.Visible = state.Visible
    refs.label.Text = string.upper(state.Text)
end

function Separator.new(parent, config)
    local refs = createSeparator(parent)
    local cfg = config or {}

    local self = setmetatable({
        Instance = refs.frame,
        _destroyed = false,
        _refs = refs,
        _state = {
            Text = normalizePropertyValue("Text", cfg.Text or cfg.Title),
            Visible = normalizePropertyValue("Visible", cfg.Visible),
        },
    }, SeparatorMeta)

    applyMetadata(self)

    return self
end

function Separator:Set(propertyOrProperties, value)
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

function Separator:Update(properties)
    return self:Set(properties)
end

function Separator:Destroy()
    if self._destroyed then
        return
    end

    self._destroyed = true
    self.Instance:Destroy()
end

function SeparatorMeta.__index(self, key)
    local method = Separator[key]
    if method ~= nil then
        return method
    end

    local state = rawget(self, "_state")
    if state and state[key] ~= nil then
        return state[key]
    end

    return rawget(self, key)
end

function SeparatorMeta.__newindex(self, key, value)
    if rawget(self, "_state") and LIVE_PROPERTIES[key] then
        self:Set(key, value)
        return
    end

    error(string.format("Unsupported separator property %q", tostring(key)))
end

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


local Groupbox = {}
local GroupboxMeta = {}

local TITLE_HEIGHT = 26
local TITLE_FONT_SIZE = 19
local TITLE_COLOR = Color3.fromRGB(94, 94, 126)
local CORNER_RADIUS = 6
local STROKE_THICKNESS = 1
local CONTENT_GAP = 6
local GROUPBOX_ROOT_SIZE = UDim2.new(1, 0, 0, 0)
local GROUPBOX_ROOT_POSITION = UDim2.new()

local function applyRootLayout(frame)
    frame.AnchorPoint = Vector2.zero
    frame.AutomaticSize = Enum.AutomaticSize.Y
    frame.Position = GROUPBOX_ROOT_POSITION
    frame.Size = GROUPBOX_ROOT_SIZE
end

local function createGroupbox(parent)
    local frame = Instance.new("Frame")
    frame.Name = "Groupbox"
    frame.BackgroundColor3 = Theme.surface
    frame.BorderSizePixel = 0
    frame:SetAttribute("SlateComponent", "Groupbox")
    applyRootLayout(frame)
    frame.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, CORNER_RADIUS)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Color = Theme["surface-stroke"]
    stroke.Thickness = STROKE_THICKNESS
    stroke.Parent = frame

    local frameLayout = Instance.new("UIListLayout")
    frameLayout.FillDirection = Enum.FillDirection.Vertical
    frameLayout.Padding = UDim.new(0, 0)
    frameLayout.SortOrder = Enum.SortOrder.LayoutOrder
    frameLayout.Parent = frame

    -- Title bar (UICorner matches frame so top corners render correctly)
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Active = true
    titleBar.BackgroundColor3 = Theme.surface
    titleBar.BorderSizePixel = 0
    titleBar.LayoutOrder = 1
    titleBar.Size = UDim2.new(1, 0, 0, TITLE_HEIGHT)
    titleBar.ZIndex = frame.ZIndex + 1
    titleBar.Parent = frame

    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, CORNER_RADIUS)
    titleCorner.Parent = titleBar

    local titlePadding = Instance.new("UIPadding")
    titlePadding.PaddingTop = UDim.new(0, 7)
    titlePadding.PaddingBottom = UDim.new(0, 6)
    titlePadding.Parent = titleBar

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.BackgroundTransparency = 1
    titleLabel.BorderSizePixel = 0
    titleLabel.Size = UDim2.new(1, 0, 1, 0)
    titleLabel.TextColor3 = TITLE_COLOR
    titleLabel.TextSize = TITLE_FONT_SIZE
    titleLabel.TextScaled = false
    titleLabel.TextXAlignment = Enum.TextXAlignment.Center
    titleLabel.TextYAlignment = Enum.TextYAlignment.Center
    titleLabel.ZIndex = titleBar.ZIndex + 1
    titleLabel.Parent = titleBar

    local fontOk, font = pcall(Font.new, "rbxasset://fonts/families/Inter.json", Enum.FontWeight.Medium)
    if fontOk then
        titleLabel.FontFace = font
    else
        titleLabel.Font = Enum.Font.GothamMedium
    end

    local separator = Instance.new("Frame")
    separator.Name = "Separator"
    separator.BackgroundColor3 = Theme["surface-stroke"]
    separator.BorderSizePixel = 0
    separator.LayoutOrder = 2
    separator.Size = UDim2.new(1, 0, 0, 1)
    separator.ZIndex = frame.ZIndex + 1
    separator.Parent = frame

    -- Content area
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.AutomaticSize = Enum.AutomaticSize.Y
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.LayoutOrder = 3
    content.Size = UDim2.new(1, 0, 0, 0)
    content.ZIndex = frame.ZIndex + 1
    content.Parent = frame

    local contentPadding = Instance.new("UIPadding")
    contentPadding.PaddingTop = UDim.new(0, 8)
    contentPadding.PaddingBottom = UDim.new(0, 10)
    contentPadding.PaddingLeft = UDim.new(0, 12)
    contentPadding.PaddingRight = UDim.new(0, 12)
    contentPadding.Parent = content

    local contentLayout = Instance.new("UIListLayout")
    contentLayout.FillDirection = Enum.FillDirection.Vertical
    contentLayout.Padding = UDim.new(0, CONTENT_GAP)
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Parent = content

    return {
        frame = frame,
        titleBar = titleBar,
        titleLabel = titleLabel,
        content = content,
    }
end

function Groupbox.new(parent, config)
    local cfg = config or {}
    local refs = createGroupbox(parent)
    refs.frame.LayoutOrder = cfg.LayoutOrder or 1

    local self = setmetatable({
        Instance = refs.frame,
        TitleBar = refs.titleBar,
        Content = refs.content,
        Column = parent,
        LayoutOrder = refs.frame.LayoutOrder,
        Controls = {},
        _refs = refs,
        _dragging = false,
    }, GroupboxMeta)

    refs.titleLabel.Text = string.upper(cfg.Title or "Groupbox")

    return self
end

function Groupbox:_syncLayout()
    applyRootLayout(self.Instance)

    return self
end

function Groupbox:AddToggle(configOrText, config)
    local toggleConfig

    if type(configOrText) == "table" then
        toggleConfig = configOrText
    else
        toggleConfig = config or {}
        toggleConfig.Text = configOrText
    end

    local toggle = Toggle.new(self.Content, toggleConfig)
    table.insert(self.Controls, toggle)

    return toggle
end

function Groupbox:AddDivider()
    local divider = Divider.new(self.Content)
    table.insert(self.Controls, divider)

    return divider
end

function Groupbox:AddSeparator(configOrText, config)
    local separatorConfig

    if type(configOrText) == "table" then
        separatorConfig = configOrText
    else
        separatorConfig = config or {}
        separatorConfig.Text = configOrText
    end

    local separator = Separator.new(self.Content, separatorConfig)
    table.insert(self.Controls, separator)

    return separator
end

function Groupbox:AddLabel(configOrText, config)
    local labelConfig

    if type(configOrText) == "table" then
        labelConfig = configOrText
    else
        labelConfig = config or {}
        labelConfig.Text = configOrText
    end

    local label = Label.new(self.Content, labelConfig)
    table.insert(self.Controls, label)

    return label
end

function Groupbox:SetPlacement(column, layoutOrder)
    self.Column = column
    self.LayoutOrder = layoutOrder
    self.Instance.LayoutOrder = layoutOrder
    self:_syncLayout()

    return self
end

function GroupboxMeta.__index(self, key)
    local method = Groupbox[key]
    if method ~= nil then
        return method
    end
    return rawget(self, key)
end


local Tab = {}
local TabMeta = {}

local ACTIVE_FILL_TRANSPARENCY = 0.84
local ACTIVE_ICON_TRANSPARENCY = 0.1
local ACTIVE_LINE_WIDTH = 3
local COLUMN_GAP = 8
local FADE_HEIGHT = 20
local DEFAULT_ICON = "circle-question-mark"
local TAB_HEIGHT = 48
local TAB_ICON_SIZE = 20

local LIVE_PROPERTIES = {
    Active = true,
    Icon = true,
    Order = true,
    Title = true,
    Visible = true,
}

local DEFAULTS = {
    Active = false,
    Icon = DEFAULT_ICON,
    LayoutColumns = 3,
    Order = 0,
    Title = "Tab",
    Visible = true,
}

local function getValue(value, fallback)
    if value == nil then
        return fallback
    end

    return value
end

local function normalizePropertyValue(property, value)
    if property == "Active" or property == "Visible" then
        return getValue(value, DEFAULTS[property])
    end

    if property == "Icon" then
        local nextIcon = tostring(getValue(value, DEFAULTS.Icon))

        if Lucide.GetAsset(nextIcon) then
            return nextIcon
        end

        return DEFAULT_ICON
    end

    if property == "Order" then
        return tonumber(getValue(value, DEFAULTS.Order)) or DEFAULTS.Order
    end

    if property == "LayoutColumns" then
        local columns = tonumber(getValue(value, DEFAULTS.LayoutColumns)) or DEFAULTS.LayoutColumns

        return math.clamp(columns, 1, 3)
    end

    if property == "Title" then
        return tostring(getValue(value, DEFAULTS.Title))
    end

    return value
end

local function ensureProperty(property)
    assert(LIVE_PROPERTIES[property], string.format("Unsupported tab property %q", tostring(property)))
end

local function createButton(window, order)
    local refs = window._refs

    local button = Instance.new("TextButton")
    button.Name = "TabButton"
    button.AutoButtonColor = false
    button.BackgroundTransparency = 1
    button.BorderSizePixel = 0
    button.Size = UDim2.new(1, 0, 0, TAB_HEIGHT)
    button.LayoutOrder = order
    button.Text = ""
    button.ZIndex = refs.sidebar.ZIndex + 1
    button:SetAttribute("SlateComponent", "TabButton")
    button.Parent = refs.sidebarTabs

    local activeFill = Instance.new("Frame")
    activeFill.Name = "ActiveFill"
    activeFill.BackgroundColor3 = Theme.accent
    activeFill.BackgroundTransparency = ACTIVE_FILL_TRANSPARENCY
    activeFill.BorderSizePixel = 0
    activeFill.Position = UDim2.fromOffset(ACTIVE_LINE_WIDTH, 0)
    activeFill.Size = UDim2.new(1, -ACTIVE_LINE_WIDTH, 1, 0)
    activeFill.Visible = false
    activeFill.ZIndex = button.ZIndex
    activeFill.Parent = button

    local activeLine = Instance.new("Frame")
    activeLine.Name = "ActiveLine"
    activeLine.BackgroundColor3 = Theme.accent
    activeLine.BorderSizePixel = 0
    activeLine.Size = UDim2.fromOffset(ACTIVE_LINE_WIDTH, TAB_HEIGHT)
    activeLine.Visible = false
    activeLine.ZIndex = button.ZIndex + 1
    activeLine.Parent = button

    local icon = Instance.new("ImageLabel")
    icon.Name = "Icon"
    icon.AnchorPoint = Vector2.new(0.5, 0.5)
    icon.BackgroundTransparency = 1
    icon.BorderSizePixel = 0
    icon.Position = UDim2.fromScale(0.5, 0.5)
    icon.Size = UDim2.fromOffset(TAB_ICON_SIZE, TAB_ICON_SIZE)
    icon.ZIndex = button.ZIndex + 2
    icon.Parent = button

    local page = Instance.new("Frame")
    page.Name = "Page"
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.Size = UDim2.fromScale(1, 1)
    page.Visible = false
    page.ZIndex = refs.content.ZIndex
    page:SetAttribute("SlateComponent", "TabPage")
    page.Parent = refs.content

    return {
        button = button,
        activeFill = activeFill,
        activeLine = activeLine,
        icon = icon,
        page = page,
    }
end

local function createColumnFade(parent, zIndex)
    local fade = Instance.new("Frame")
    fade.Name = "BottomFade"
    fade.AnchorPoint = Vector2.new(0, 1)
    fade.BackgroundColor3 = Theme.background
    fade.BorderSizePixel = 0
    fade.Position = UDim2.new(0, 0, 1, 0)
    fade.Size = UDim2.new(1, 0, 0, FADE_HEIGHT)
    fade.ZIndex = zIndex + 1
    fade.Parent = parent

    local gradient = Instance.new("UIGradient")
    gradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(1, 0),
    })
    gradient.Rotation = 90
    gradient.Parent = fade
end

local function createPageLayout(page, columnCount)
    local tabContent = Instance.new("Frame")
    tabContent.Name = "tabContent"
    tabContent.BackgroundTransparency = 1
    tabContent.BorderSizePixel = 0
    tabContent.Size = UDim2.fromScale(1, 1)
    tabContent.ZIndex = page.ZIndex
    tabContent.Parent = page

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, COLUMN_GAP)
    padding.PaddingRight = UDim.new(0, COLUMN_GAP)
    padding.PaddingTop = UDim.new(0, COLUMN_GAP)
    padding.Parent = tabContent

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    layout.Padding = UDim.new(0, COLUMN_GAP)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.VerticalAlignment = Enum.VerticalAlignment.Top
    layout.Parent = tabContent

    local sizeOffset = -math.floor(((columnCount - 1) * COLUMN_GAP) / columnCount)

    local function makeColumn(name, order)
        local container = Instance.new("Frame")
        container.Name = name
        container.AnchorPoint = Vector2.zero
        container.BackgroundTransparency = 1
        container.BorderSizePixel = 0
        container.LayoutOrder = order
        container.Position = UDim2.new()
        container.Size = UDim2.new(1 / columnCount, sizeOffset, 1, 0)
        container.ZIndex = tabContent.ZIndex + 1
        container.Parent = tabContent

        local content = Instance.new("Frame")
        content.Name = "Content"
        content.AnchorPoint = Vector2.zero
        content.BackgroundTransparency = 1
        content.BorderSizePixel = 0
        content.Position = UDim2.new()
        content.Size = UDim2.fromScale(1, 1)
        content.ZIndex = container.ZIndex
        content.Parent = container

        local contentLayout = Instance.new("UIListLayout")
        contentLayout.FillDirection = Enum.FillDirection.Vertical
        contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
        contentLayout.Padding = UDim.new(0, 8)
        contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
        contentLayout.Parent = content

        createColumnFade(container, container.ZIndex + 1)

        return {
            container = container,
            content = content,
        }
    end

    local names = { "leftColumn", "middleColumn", "rightColumn" }
    local refs = {
        tabContent = tabContent,
    }

    for index = 1, columnCount do
        local column = makeColumn(names[index], index)
        refs[names[index] .. "Frame"] = column.container
        refs[names[index]] = column.content
    end

    return refs
end

local function applyIcon(iconLabel, iconName)
    local asset = Lucide.GetAsset(iconName) or Lucide.GetAsset(DEFAULT_ICON)
    if not asset then
        iconLabel.Image = ""
        return
    end

    iconLabel.Image = asset.Url
    iconLabel.ImageRectOffset = asset.ImageRectOffset
    iconLabel.ImageRectSize = asset.ImageRectSize
end

local function applyMetadata(self)
    local refs = self._refs
    local state = self._state
    if not refs or not refs.button or not refs.page or not state then
        return
    end

    local isActive = state.Active and state.Visible
    local window = self.Window
    local boot = window and window._boot
    local bootActive = boot and boot.active or false
    local bootRevealStarted = boot and boot.revealStarted or false
    local contentVisible = boot and boot.contentVisible or true
    local buttonsReady = (not bootActive and not bootRevealStarted) or self._bootVisible
    local pageReady = (not bootActive and not bootRevealStarted) or contentVisible

    refs.button.LayoutOrder = state.Order
    refs.button.Visible = state.Visible and buttonsReady
    refs.button:SetAttribute("Title", state.Title)
    refs.button:SetAttribute("Icon", state.Icon)
    refs.button:SetAttribute("Active", isActive)

    refs.activeLine.Visible = isActive
    refs.activeFill.Visible = isActive
    refs.activeLine.BackgroundColor3 = Theme.accent
    refs.activeFill.BackgroundColor3 = Theme.accent
    refs.activeFill.BackgroundTransparency = ACTIVE_FILL_TRANSPARENCY

    applyIcon(refs.icon, state.Icon)
    refs.icon.ImageColor3 = isActive and Theme.accent or Theme["text-secondary"]
    refs.icon.ImageTransparency = isActive and ACTIVE_ICON_TRANSPARENCY or 0

    refs.page.Visible = isActive and pageReady
end

local function applyProperty(self, property, value)
    ensureProperty(property)
    self._state[property] = normalizePropertyValue(property, value)
end

function Tab.new(window, config, order)
    local refs = createButton(window, order)
    local title = normalizePropertyValue("Title", config.Title or config.Id or config.Name)
    local layoutColumns = normalizePropertyValue(
        "LayoutColumns",
        config.LayoutColumns or ((string.lower(title) == "settings") and 2 or nil)
    )

    for key, value in pairs(createPageLayout(refs.page, layoutColumns)) do
        refs[key] = value
    end

    local self = setmetatable({
        Window = window,
        Instance = refs.button,
        Page = refs.page,
        leftColumn = refs.leftColumn,
        middleColumn = refs.middleColumn,
        rightColumn = refs.rightColumn,
        _bootVisible = not window._boot.active,
        _destroyed = false,
        _groupboxes = {},
        _refs = refs,
        _state = {
            Active = normalizePropertyValue("Active", config.Active),
            Icon = normalizePropertyValue("Icon", config.Icon),
            LayoutColumns = layoutColumns,
            Order = normalizePropertyValue("Order", config.Order or order),
            Title = title,
            Visible = normalizePropertyValue("Visible", config.Visible),
        },
    }, TabMeta)

    refs.button.MouseButton1Click:Connect(function()
        if self._destroyed then
            return
        end

        window:SelectTab(self)
    end)

    applyMetadata(self)

    return self
end

function Tab:Get(property)
    return self._state[property]
end

function Tab:Set(propertyOrProperties, value)
    if self._destroyed then
        return self
    end

    local preferredTab = nil

    if type(propertyOrProperties) == "table" then
        for property, nextValue in pairs(propertyOrProperties) do
            applyProperty(self, property, nextValue)
        end
    else
        applyProperty(self, propertyOrProperties, value)
    end

    if self.Active and self.Visible then
        preferredTab = self
    end

    self.Window:_reconcileTabs(preferredTab)

    return self
end

function Tab:Update(properties)
    return self:Set(properties)
end

function Tab:Select()
    self.Window:SelectTab(self)

    return self
end

function Tab:Show()
    return self:Set("Visible", true)
end

function Tab:Hide()
    return self:Set("Visible", false)
end

function Tab:AddGroupbox(column, config)
    local targetColumn = column

    if type(column) == "string" then
        targetColumn = self[column]
    end

    if targetColumn == nil then
        targetColumn = self.leftColumn or self.middleColumn or self.rightColumn
    end

    assert(targetColumn ~= nil, "Tab has no valid columns for groupbox placement")

    return self.Window:_addGroupbox(self, targetColumn, config)
end

function Tab:Destroy()
    if self._destroyed then
        return
    end

    self._destroyed = true
    self.Window:_removeGroupboxesForTab(self)
    self.Window:_removeTab(self)
    self._refs.page:Destroy()
    self._refs.button:Destroy()
end

function Tab._applyMetadata(self)
    applyMetadata(self)
end

function TabMeta.__index(self, key)
    local method = Tab[key]
    if method ~= nil then
        return method
    end

    local state = rawget(self, "_state")
    if state and state[key] ~= nil then
        return state[key]
    end

    return rawget(self, key)
end

function TabMeta.__newindex(self, key, value)
    if rawget(self, "_state") and LIVE_PROPERTIES[key] then
        self:Set(key, value)
        return
    end

    error(string.format("Unsupported tab property %q", tostring(key)))
end

local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")
local UserInputService = game:GetService("UserInputService")

local Window = {}
local WindowMeta = {}
local CHIP_FONT = Enum.Font.GothamBold
local CHIP_FONT_SIZE = 12
local CHIP_HEIGHT = 20
local CHIP_PADDING_X = 24
local CHIP_TWEEN_INFO = TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TITLE_BAR_HEIGHT = 36
local TITLE_BAR_STROKE = 1
local SIDEBAR_STROKE = 1
local CURSOR_SIZE = 16
local CURSOR_LINE_THICKNESS = 2
local CURSOR_ZINDEX = 1000
local DEFAULT_SIDEBAR_WIDTH = math.floor((48 * 1.15) + 0.5)
local COLUMN_GAP = 8
local COLUMN_OFFSET = -math.floor(2 * COLUMN_GAP / 3)
local CONTENT_PADDING = 6
local WINDOW_CORNER_RADIUS = 6
local FADE_HEIGHT = 20
local GROUPBOX_DRAG_PLACEHOLDER_INSET = 7
local GROUPBOX_DRAG_ZINDEX_OFFSET = 100
local GROUPBOX_DRAG_TWEEN_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local LOADER_BASE_PROGRESS = 0.2
local LOADER_COMPACT_WIDTH_SCALE = 0.33
local LOADER_COMPACT_HEIGHT_SCALE = 0.25
local LOADER_MIN_WIDTH = 320
local LOADER_MIN_HEIGHT = 135
local LOADER_FINAL_HOLD = 1
local LOADER_TRACK_HEIGHT = 3
local LOADER_PANEL_HEIGHT = 68
local LOADER_PANEL_HORIZONTAL_INSET = 56
local LOADER_TRACK_TOP = 8
local LOADER_LABEL_CENTER_Y = 34
local LOADER_BAR_TWEEN_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local LOADER_PANEL_TWEEN_INFO = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local WINDOW_BOOT_EXPAND_TWEEN_INFO = TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local WINDOW_BOOT_TITLE_TWEEN_INFO = TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local WINDOW_BOOT_SIDEBAR_TWEEN_INFO = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local WINDOW_BOOT_TAB_TWEEN_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local WINDOW_BOOT_CONTENT_TWEEN_INFO = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local WINDOW_BOOT_TAB_STAGGER = 0.055
local DEFAULT_LOADER_STATUS = "Initializing Slate..."
local TRANSPARENCY_PROPERTIES = {
    "BackgroundTransparency",
    "ImageTransparency",
    "TextStrokeTransparency",
    "TextTransparency",
}

local DEFAULTS = {
    Title = "Slate",
    Version = nil,
    Width = 960,
    Height = 540,
    Resizable = true,
    SidebarWidth = DEFAULT_SIDEBAR_WIDTH,
    ShowSidebar = true,
    AutoShow = true,
}

local LIVE_PROPERTIES = {
    AutoShow = true,
    Height = true,
    Resizable = true,
    ShowSidebar = true,
    SidebarWidth = true,
    Size = true,
    Title = true,
    Version = true,
    Visible = true,
    Width = true,
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

    if property == "Version" then
        if value == nil or value == "" then
            return nil
        end

        return tostring(value)
    end

    if property == "Resizable" then
        return getValue(value, DEFAULTS.Resizable)
    end

    if property == "SidebarWidth" then
        return getValue(value, DEFAULTS.SidebarWidth)
    end

    if property == "ShowSidebar" then
        return getValue(value, DEFAULTS.ShowSidebar)
    end

    if property == "Visible" or property == "AutoShow" then
        return getValue(value, DEFAULTS.AutoShow)
    end

    return value
end

local function resolveSize(config)
    if typeof(config.Size) == "UDim2" then
        return config.Size
    end

    local width = getValue(config.Width, DEFAULTS.Width)
    local height = getValue(config.Height, DEFAULTS.Height)

    return UDim2.fromOffset(width, height)
end

local function createTextLabel(name, font, textSize, textColor, zIndex)
    local label = Instance.new("TextLabel")
    label.Name = name
    label.BackgroundTransparency = 1
    label.BorderSizePixel = 0
    label.Font = font
    label.TextColor3 = textColor
    label.TextSize = textSize
    label.TextWrapped = false
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.ZIndex = zIndex

    return label
end

local function setInternal(self, key, value)
    rawset(self, key, value)
end

local function safeDisconnect(connection)
    if connection then
        connection:Disconnect()
    end
end

local function getCompactSize(size)
    return UDim2.new(
        size.X.Scale,
        math.max(LOADER_MIN_WIDTH, math.floor(size.X.Offset * LOADER_COMPACT_WIDTH_SCALE)),
        size.Y.Scale,
        math.max(LOADER_MIN_HEIGHT, math.floor(size.Y.Offset * LOADER_COMPACT_HEIGHT_SCALE))
    )
end

local function captureTransparencyState(root)
    local state = {}
    local instances = { root }

    for _, descendant in ipairs(root:GetDescendants()) do
        table.insert(instances, descendant)
    end

    for _, instance in ipairs(instances) do
        local properties = {}

        for _, property in ipairs(TRANSPARENCY_PROPERTIES) do
            local ok, value = pcall(function()
                return instance[property]
            end)

            if ok then
                properties[property] = value
            end
        end

        if instance:IsA("UIStroke") then
            properties.Transparency = instance.Transparency
        end

        if next(properties) ~= nil then
            state[instance] = properties
        end
    end

    return state
end

local function applyTransparencyAlpha(state, alpha)
    for instance, properties in pairs(state) do
        if instance.Parent ~= nil then
            for property, value in pairs(properties) do
                instance[property] = value + ((1 - value) * alpha)
            end
        end
    end
end

local function tweenTransparencyAlpha(state, fromAlpha, toAlpha, tweenInfo, shouldWait)
    local driver = Instance.new("NumberValue")
    driver.Value = fromAlpha

    local connection = driver:GetPropertyChangedSignal("Value"):Connect(function()
        applyTransparencyAlpha(state, driver.Value)
    end)

    applyTransparencyAlpha(state, fromAlpha)

    local tween = TweenService:Create(driver, tweenInfo, {
        Value = toAlpha,
    })

    tween:Play()

    local playbackState = Enum.PlaybackState.Completed
    if shouldWait == nil or shouldWait then
        playbackState = tween.Completed:Wait()
    else
        task.wait(tweenInfo.Time)
    end

    connection:Disconnect()
    driver:Destroy()
    applyTransparencyAlpha(state, toAlpha)

    return playbackState
end

local function getActiveTab(self)
    for _, tab in ipairs(self._tabs) do
        if not tab._destroyed and tab.Active and tab.Visible then
            return tab
        end
    end

    return nil
end

local function createCursor(frame: Frame)
    local cursor = Instance.new("Frame")
    cursor.Name = "Cursor"
    cursor.AnchorPoint = Vector2.new(0.5, 0.5)
    cursor.BackgroundTransparency = 1
    cursor.BorderSizePixel = 0
    cursor.Size = UDim2.fromOffset(CURSOR_SIZE, CURSOR_SIZE)
    cursor.Visible = false
    cursor.ZIndex = CURSOR_ZINDEX
    cursor:SetAttribute("SlateComponent", "Cursor")
    cursor.Parent = frame

    local horizontal = Instance.new("Frame")
    horizontal.Name = "Horizontal"
    horizontal.AnchorPoint = Vector2.new(0.5, 0.5)
    horizontal.BackgroundColor3 = Theme.accent
    horizontal.BorderSizePixel = 0
    horizontal.Position = UDim2.fromScale(0.5, 0.5)
    horizontal.Size = UDim2.fromOffset(CURSOR_SIZE, CURSOR_LINE_THICKNESS)
    horizontal.ZIndex = cursor.ZIndex
    horizontal.Parent = cursor

    local vertical = Instance.new("Frame")
    vertical.Name = "Vertical"
    vertical.AnchorPoint = Vector2.new(0.5, 0.5)
    vertical.BackgroundColor3 = Theme.accent
    vertical.BorderSizePixel = 0
    vertical.Position = UDim2.fromScale(0.5, 0.5)
    vertical.Size = UDim2.fromOffset(CURSOR_LINE_THICKNESS, CURSOR_SIZE)
    vertical.ZIndex = cursor.ZIndex
    vertical.Parent = cursor

    return {
        cursor = cursor,
        cursorHorizontal = horizontal,
        cursorVertical = vertical,
    }
end

local function createLoader(frame: Frame)
    local overlay = Instance.new("Frame")
    overlay.Name = "LoaderOverlay"
    overlay.BackgroundTransparency = 1
    overlay.BorderSizePixel = 0
    overlay.Size = UDim2.fromScale(1, 1)
    overlay.ZIndex = frame.ZIndex + 10
    overlay:SetAttribute("SlateComponent", "LoaderOverlay")
    overlay.Parent = frame

    local panel = Instance.new("Frame")
    panel.Name = "LoaderPanel"
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.BackgroundTransparency = 1
    panel.BorderSizePixel = 0
    panel.Position = UDim2.fromScale(0.5, 0.5)
    panel.Size = UDim2.new(1, -LOADER_PANEL_HORIZONTAL_INSET, 0, LOADER_PANEL_HEIGHT)
    panel.ZIndex = overlay.ZIndex + 1
    panel.Parent = overlay

    local panelCorner = Instance.new("UICorner")
    panelCorner.CornerRadius = UDim.new(0, WINDOW_CORNER_RADIUS)
    panelCorner.Parent = panel

    local track = Instance.new("Frame")
    track.Name = "Track"
    track.BackgroundColor3 = Theme["nav-stroke"]
    track.BackgroundTransparency = 0.3
    track.BorderSizePixel = 0
    track.Position = UDim2.fromOffset(0, LOADER_TRACK_TOP)
    track.Size = UDim2.new(1, 0, 0, LOADER_TRACK_HEIGHT)
    track.ZIndex = panel.ZIndex
    track.Parent = panel

    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(0, WINDOW_CORNER_RADIUS)
    trackCorner.Parent = track

    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.BackgroundColor3 = Theme.accent
    fill.BorderSizePixel = 0
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.ZIndex = track.ZIndex + 1
    fill.Parent = track

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, WINDOW_CORNER_RADIUS)
    fillCorner.Parent = fill

    local statusLabel = createTextLabel("StatusLabel", Enum.Font.Gotham, 16, Theme["text-secondary"], panel.ZIndex)
    statusLabel.AnchorPoint = Vector2.new(0, 0.5)
    statusLabel.Position = UDim2.new(0, 0, 0, LOADER_LABEL_CENTER_Y)
    statusLabel.Size = UDim2.new(1, -64, 0, 22)
    statusLabel.Text = DEFAULT_LOADER_STATUS
    statusLabel.Parent = panel

    local percentLabel = createTextLabel("PercentLabel", Enum.Font.GothamMedium, 16, Theme.accent, panel.ZIndex)
    percentLabel.AnchorPoint = Vector2.new(1, 0.5)
    percentLabel.Position = UDim2.new(1, 0, 0, LOADER_LABEL_CENTER_Y)
    percentLabel.Size = UDim2.fromOffset(60, 22)
    percentLabel.Text = "0%"
    percentLabel.TextXAlignment = Enum.TextXAlignment.Right
    percentLabel.Parent = panel

    return {
        loaderOverlay = overlay,
        loaderPanel = panel,
        loaderTrack = track,
        loaderFill = fill,
        loaderStatus = statusLabel,
        loaderPercent = percentLabel,
    }
end

local function createTitleBar(frame: Frame)
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Active = true
    titleBar.BackgroundColor3 = Theme["nav-bg"]
    titleBar.BorderSizePixel = 0
    titleBar.Position = UDim2.fromOffset(0, 0)
    titleBar.Size = UDim2.new(1, 0, 0, TITLE_BAR_HEIGHT)
    titleBar.ZIndex = frame.ZIndex + 1
    titleBar:SetAttribute("SlateComponent", "TitleBar")
    titleBar.Parent = frame

    local titleBarStroke = Instance.new("UIStroke")
    titleBarStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    titleBarStroke.Color = Theme["nav-stroke"]
    titleBarStroke.Thickness = TITLE_BAR_STROKE
    titleBarStroke.Parent = titleBar

    local titleCluster = Instance.new("Frame")
    titleCluster.Name = "TitleCluster"
    titleCluster.AnchorPoint = Vector2.new(0, 0.5)
    titleCluster.AutomaticSize = Enum.AutomaticSize.X
    titleCluster.BackgroundTransparency = 1
    titleCluster.Position = UDim2.new(0, 14, 0.5, 0)
    titleCluster.Size = UDim2.new(0, 0, 1, 0)
    titleCluster.ZIndex = titleBar.ZIndex + 1
    titleCluster.Parent = titleBar

    local titleLayout = Instance.new("UIListLayout")
    titleLayout.FillDirection = Enum.FillDirection.Horizontal
    titleLayout.Padding = UDim.new(0, 8)
    titleLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    titleLayout.Parent = titleCluster

    local titleLabel = createTextLabel("TitleLabel", Enum.Font.GothamMedium, 14, Theme["text-primary"], titleCluster.ZIndex)
    titleLabel.AutomaticSize = Enum.AutomaticSize.X
    titleLabel.Size = UDim2.new(0, 0, 1, 0)
    titleLabel.Parent = titleCluster

    local versionLabel = createTextLabel("VersionLabel", Enum.Font.Gotham, 13, Theme["text-secondary"], titleCluster.ZIndex)
    versionLabel.AutomaticSize = Enum.AutomaticSize.X
    versionLabel.Size = UDim2.new(0, 0, 1, 0)
    versionLabel.Visible = false
    versionLabel.Parent = titleCluster

    local accentChip = Instance.new("Frame")
    accentChip.Name = "AccentChip"
    accentChip.AnchorPoint = Vector2.new(0.5, 0.5)
    accentChip.BackgroundColor3 = Theme.accent
    accentChip.BackgroundTransparency = 0.84
    accentChip.BorderSizePixel = 0
    accentChip.Position = UDim2.fromScale(0.5, 0.5)
    accentChip.Size = UDim2.fromOffset(74, CHIP_HEIGHT)
    accentChip.ZIndex = titleBar.ZIndex + 1
    accentChip:SetAttribute("SlateComponent", "AccentChip")
    accentChip.Parent = titleBar

    local accentCorner = Instance.new("UICorner")
    accentCorner.CornerRadius = UDim.new(1, 0)
    accentCorner.Parent = accentChip

    local accentLabel = createTextLabel("ChipLabel", CHIP_FONT, CHIP_FONT_SIZE, Theme.accent, accentChip.ZIndex + 1)
    accentLabel.Size = UDim2.fromScale(1, 1)
    accentLabel.Text = ""
    accentLabel.TextXAlignment = Enum.TextXAlignment.Center
    accentLabel.Parent = accentChip

    return {
        titleBar = titleBar,
        titleBarStroke = titleBarStroke,
        titleLabel = titleLabel,
        versionLabel = versionLabel,
        accentChip = accentChip,
        accentLabel = accentLabel,
    }
end

local function createSidebar(frame: Frame)
    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.BackgroundColor3 = Theme["nav-bg"]
    sidebar.BorderSizePixel = 0
    sidebar.Position = UDim2.fromOffset(0, TITLE_BAR_HEIGHT)
    sidebar.Size = UDim2.new(0, DEFAULTS.SidebarWidth, 1, -TITLE_BAR_HEIGHT)
    sidebar.ZIndex = frame.ZIndex
    sidebar:SetAttribute("SlateComponent", "Sidebar")
    sidebar.Parent = frame

    local sidebarStroke = Instance.new("UIStroke")
    sidebarStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    sidebarStroke.Color = Theme["nav-stroke"]
    sidebarStroke.Thickness = SIDEBAR_STROKE
    sidebarStroke.Parent = sidebar

    local sidebarTabs = Instance.new("Frame")
    sidebarTabs.Name = "Tabs"
    sidebarTabs.BackgroundTransparency = 1
    sidebarTabs.BorderSizePixel = 0
    sidebarTabs.Size = UDim2.fromScale(1, 1)
    sidebarTabs.ZIndex = sidebar.ZIndex + 1
    sidebarTabs:SetAttribute("SlateComponent", "SidebarTabs")
    sidebarTabs.Parent = sidebar

    local tabsLayout = Instance.new("UIListLayout")
    tabsLayout.FillDirection = Enum.FillDirection.Vertical
    tabsLayout.Padding = UDim.new(0, 0)
    tabsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabsLayout.Parent = sidebarTabs

    local content = Instance.new("Frame")
    content.Name = "Content"
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.Position = UDim2.fromOffset(DEFAULTS.SidebarWidth, TITLE_BAR_HEIGHT)
    content.Size = UDim2.new(1, -DEFAULTS.SidebarWidth, 1, -TITLE_BAR_HEIGHT)
    content.ZIndex = frame.ZIndex
    content:SetAttribute("SlateComponent", "Content")
    content.Parent = frame

    local contentPadding = Instance.new("UIPadding")
    contentPadding.PaddingLeft = UDim.new(0, CONTENT_PADDING)
    contentPadding.PaddingRight = UDim.new(0, CONTENT_PADDING)
    contentPadding.PaddingTop = UDim.new(0, CONTENT_PADDING)
    contentPadding.PaddingBottom = UDim.new(0, CONTENT_PADDING)
    contentPadding.Parent = content

    return {
        sidebar = sidebar,
        sidebarStroke = sidebarStroke,
        sidebarTabs = sidebarTabs,
        tabsLayout = tabsLayout,
        content = content,
    }
end

local function createBootState(windowSize)
    return {
        active = true,
        autoFinishScheduled = false,
        compactSize = getCompactSize(windowSize),
        contentVisible = false,
        deferredBoot = false,
        loaderFillTween = nil,
        loaderVisible = true,
        progress = 0,
        revealStarted = false,
        sidebarVisible = false,
        statusText = DEFAULT_LOADER_STATUS,
        tabsVisible = false,
        titleBarVisible = false,
        totalUserWeight = 0,
        userProgress = 0,
        userStepCount = 0,
    }
end

local function connect(self, signal, callback)
    local connection = signal:Connect(callback)
    table.insert(self._connections, connection)

    return connection
end

local function updateCursorPosition(self, mouseLocation)
    local refs = self._refs

    refs.cursor.Position = UDim2.fromOffset(
        mouseLocation.X - self.Instance.AbsolutePosition.X,
        mouseLocation.Y - self.Instance.AbsolutePosition.Y
    )
end

local function setCursorVisible(self, isVisible)
    setInternal(self, "_cursorVisible", isVisible)
    self._refs.cursor.Visible = isVisible
    UserInputService.MouseIconEnabled = not isVisible

    if isVisible then
        updateCursorPosition(self, UserInputService:GetMouseLocation())
    end
end

local updateDraggedGroupboxPosition
local updateDragPlaceholder
local endGroupboxDrag

local function attachInteractions(self)
    local refs = self._refs

    connect(self, self.Instance.MouseEnter, function()
        setCursorVisible(self, true)
    end)

    connect(self, self.Instance.MouseLeave, function()
        setCursorVisible(self, false)
    end)

    connect(self, refs.titleBar.InputBegan, function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
            return
        end

        setInternal(self, "_dragging", true)
        setInternal(self, "_dragStart", input.Position)
        setInternal(self, "_dragOrigin", self.Instance.Position)
    end)

    connect(self, UserInputService.InputChanged, function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseMovement then
            return
        end

        if self._groupboxDrag.dragging then
            self._groupboxDrag.pointer = input.Position
            updateDraggedGroupboxPosition(self)
            updateDragPlaceholder(self)
        end

        if self._cursorVisible then
            updateCursorPosition(self, input.Position)
        end

        if not self._dragging then
            return
        end

        local delta = input.Position - self._dragStart
        local origin = self._dragOrigin

        self.Instance.Position = UDim2.new(
            origin.X.Scale,
            origin.X.Offset + delta.X,
            origin.Y.Scale,
            origin.Y.Offset + delta.Y
        )
    end)

    connect(self, UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            setInternal(self, "_dragging", false)
            endGroupboxDrag(self)
        end
    end)
end

local function getVisibleTabs(self)
    local visibleTabs = {}

    for _, tab in ipairs(self._tabs) do
        if not tab._destroyed and tab.Visible then
            table.insert(visibleTabs, tab)
        end
    end

    table.sort(visibleTabs, function(left, right)
        if left.Order == right.Order then
            return left.Title < right.Title
        end

        return left.Order < right.Order
    end)

    return visibleTabs
end

local function getGroupboxesInColumn(self, column, exclude)
    local groupboxes = {}

    for _, groupbox in ipairs(self._groupboxes) do
        if not groupbox._destroyed and groupbox.Column == column and groupbox ~= exclude then
            table.insert(groupboxes, groupbox)
        end
    end

    table.sort(groupboxes, function(left, right)
        return left.LayoutOrder < right.LayoutOrder
    end)

    return groupboxes
end

local function commitColumnLayout(self, column)
    local order = 1

    for _, groupbox in ipairs(getGroupboxesInColumn(self, column, nil)) do
        groupbox:SetPlacement(column, order)
        order = order + 1
    end
end

local function getColumnDefinitions(tab)
    local refs = tab and tab._refs
    if not refs then
        return {}
    end

    local definitions = {}
    local columns = {
        {
            frame = refs.leftColumnFrame,
            content = tab.leftColumn,
            name = "left",
        },
        {
            frame = refs.middleColumnFrame,
            content = tab.middleColumn,
            name = "middle",
        },
        {
            frame = refs.rightColumnFrame,
            content = tab.rightColumn,
            name = "right",
        },
    }

    for _, definition in ipairs(columns) do
        if definition.frame and definition.content then
            table.insert(definitions, definition)
        end
    end

    return definitions
end

local function setGroupboxZOffset(root, delta)
    if root:IsA("GuiObject") then
        root.ZIndex += delta
    end

    for _, descendant in ipairs(root:GetDescendants()) do
        if descendant:IsA("GuiObject") then
            descendant.ZIndex += delta
        end
    end
end

updateDraggedGroupboxPosition = function(self)
    local dragState = self._groupboxDrag
    if not dragState.dragging or not dragState.groupbox then
        return
    end

    local rootGui = self.Parent
    local rootGuiPosition = rootGui.AbsolutePosition

    dragState.groupbox.Instance.Position = UDim2.fromOffset(
        dragState.pointer.X - dragState.offset.X - rootGuiPosition.X,
        dragState.pointer.Y - dragState.offset.Y - rootGuiPosition.Y
    )
end

updateDragPlaceholder = function(self)
    local dragState = self._groupboxDrag
    if not dragState.dragging or not dragState.groupbox or not dragState.placeholder then
        return
    end

    local targetColumn = nil
    local bestDistance = math.huge

    for _, definition in ipairs(getColumnDefinitions(dragState.tab)) do
        local frame = definition.frame
        local absPos = frame.AbsolutePosition
        local absSize = frame.AbsoluteSize
        local clampedX = math.clamp(dragState.pointer.X, absPos.X, absPos.X + absSize.X)
        local distance = math.abs(dragState.pointer.X - clampedX)

        if distance < bestDistance then
            bestDistance = distance
            targetColumn = definition
        end
    end

    if not targetColumn then
        return
    end

    dragState.targetColumn = targetColumn.content

    local groupboxes = getGroupboxesInColumn(self, targetColumn.content, dragState.groupbox)
    local insertIndex = #groupboxes + 1

    for index, groupbox in ipairs(groupboxes) do
        local root = groupbox.Instance
        local midY = root.AbsolutePosition.Y + (root.AbsoluteSize.Y / 2)
        if dragState.pointer.Y < midY then
            insertIndex = index
            break
        end
    end

    if dragState.placeholder.Parent ~= targetColumn.content then
        dragState.placeholder.Parent = targetColumn.content
    end

    local order = 1
    for index, groupbox in ipairs(groupboxes) do
        if index == insertIndex then
            dragState.placeholder.LayoutOrder = order
            order += 1
        end

        groupbox:SetPlacement(targetColumn.content, order)
        order += 1
    end

    if insertIndex > #groupboxes then
        dragState.placeholder.LayoutOrder = order
    end
end

local function clearGroupboxDrag(self)
    local dragState = self._groupboxDrag

    if dragState.snapConnection then
        safeDisconnect(dragState.snapConnection)
        dragState.snapConnection = nil
    end

    if dragState.placeholder then
        dragState.placeholder:Destroy()
        dragState.placeholder = nil
    end

    dragState.dragging = false
    dragState.groupbox = nil
    dragState.sourceColumn = nil
    dragState.tab = nil
    dragState.targetColumn = nil
end

local function beginGroupboxDrag(self, groupbox, inputPosition)
    local dragState = self._groupboxDrag
    if dragState.dragging or self._dragging then
        return
    end

    local root = groupbox.Instance
    local absPos = root.AbsolutePosition
    local absSize = root.AbsoluteSize
    local rootGui = self.Parent
    local rootGuiPosition = rootGui.AbsolutePosition

    dragState.dragging = true
    dragState.groupbox = groupbox
    dragState.sourceColumn = groupbox.Column
    dragState.tab = groupbox.Tab
    dragState.targetColumn = groupbox.Column
    dragState.pointer = inputPosition
    dragState.offset = Vector2.new(inputPosition.X - absPos.X, inputPosition.Y - absPos.Y)
    dragState.originalAutomaticSize = root.AutomaticSize
    dragState.originalSize = root.Size

    local placeholderWidth = math.max(1, absSize.X - GROUPBOX_DRAG_PLACEHOLDER_INSET * 2)
    local placeholderHeight = math.max(1, absSize.Y - GROUPBOX_DRAG_PLACEHOLDER_INSET * 2)

    local placeholder = Instance.new("Frame")
    placeholder.Name = "GroupboxDragPlaceholder"
    placeholder.BackgroundTransparency = 1
    placeholder.BorderSizePixel = 0
    placeholder.LayoutOrder = groupbox.LayoutOrder
    placeholder.Size = UDim2.fromOffset(absSize.X, absSize.Y)

    local outline = Instance.new("Frame")
    outline.Name = "Outline"
    outline.AnchorPoint = Vector2.new(0.5, 0.5)
    outline.BackgroundColor3 = Theme.accent
    outline.BackgroundTransparency = 0.88
    outline.BorderSizePixel = 0
    outline.Position = UDim2.fromScale(0.5, 0.5)
    outline.Size = UDim2.fromOffset(placeholderWidth, placeholderHeight)
    outline.Parent = placeholder

    local outlineCorner = Instance.new("UICorner")
    outlineCorner.CornerRadius = UDim.new(0, 6)
    outlineCorner.Parent = outline

    local outlineStroke = Instance.new("UIStroke")
    outlineStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    outlineStroke.Color = Theme.accent
    outlineStroke.Thickness = 2
    outlineStroke.Parent = outline

    dragState.placeholder = placeholder
    placeholder.Parent = groupbox.Column

    root.AutomaticSize = Enum.AutomaticSize.None
    root.Size = UDim2.fromOffset(absSize.X, absSize.Y)
    root.Parent = rootGui
    root.Position = UDim2.fromOffset(absPos.X - rootGuiPosition.X, absPos.Y - rootGuiPosition.Y)
    setGroupboxZOffset(root, GROUPBOX_DRAG_ZINDEX_OFFSET)
    setInternal(groupbox, "_dragging", true)

    updateDraggedGroupboxPosition(self)
    updateDragPlaceholder(self)
end

endGroupboxDrag = function(self)
    local dragState = self._groupboxDrag
    if not dragState.dragging or not dragState.groupbox then
        return
    end

    local groupbox = dragState.groupbox
    local root = groupbox.Instance
    local placeholder = dragState.placeholder
    local sourceColumn = dragState.sourceColumn
    local targetColumn = dragState.targetColumn or groupbox.Column
    local targetLayoutOrder = placeholder and placeholder.LayoutOrder or groupbox.LayoutOrder
    local targetY = placeholder and placeholder.AbsolutePosition.Y or root.AbsolutePosition.Y
    local targetX = targetColumn.AbsolutePosition.X
    local rootGuiPosition = self.Parent.AbsolutePosition

    if dragState.snapTween then
        dragState.snapTween:Cancel()
    end

    dragState.dragging = false

    local snapTween = TweenService:Create(
        root,
        GROUPBOX_DRAG_TWEEN_INFO,
        {
            Position = UDim2.fromOffset(
                targetX - rootGuiPosition.X,
                targetY - rootGuiPosition.Y
            ),
        }
    )

    dragState.snapTween = snapTween

    local outline = placeholder and placeholder:FindFirstChild("Outline")
    if outline then
        TweenService:Create(outline, GROUPBOX_DRAG_TWEEN_INFO, {
            BackgroundTransparency = 1,
        }):Play()

        local stroke = outline:FindFirstChildOfClass("UIStroke")
        if stroke then
            TweenService:Create(stroke, GROUPBOX_DRAG_TWEEN_INFO, {
                Transparency = 1,
            }):Play()
        end
    end

    dragState.snapConnection = snapTween.Completed:Connect(function(playbackState)
        dragState.snapConnection = nil
        dragState.snapTween = nil

        if playbackState ~= Enum.PlaybackState.Completed then
            clearGroupboxDrag(self)
            return
        end

        setGroupboxZOffset(root, -GROUPBOX_DRAG_ZINDEX_OFFSET)
        root.Parent = targetColumn
        root.AutomaticSize = dragState.originalAutomaticSize or Enum.AutomaticSize.Y
        root.Size = dragState.originalSize or UDim2.new(1, 0, 0, 0)
        root.Position = UDim2.new()
        groupbox:SetPlacement(targetColumn, targetLayoutOrder)
        setInternal(groupbox, "_dragging", false)

        clearGroupboxDrag(self)
        commitColumnLayout(self, targetColumn)

        if sourceColumn and sourceColumn ~= targetColumn then
            commitColumnLayout(self, sourceColumn)
        end
    end)

    snapTween:Play()
end

local function bindGroupboxDragging(self, groupbox)
    local connection = groupbox.TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
            return
        end

        beginGroupboxDrag(self, groupbox, input.Position)
    end)

    self._groupboxConnections[groupbox] = connection
end

local function computeLoaderProgress(self)
    local boot = self._boot

    if boot.totalUserWeight <= 0 then
        return LOADER_BASE_PROGRESS
    end

    return LOADER_BASE_PROGRESS + (math.clamp(boot.userProgress / boot.totalUserWeight, 0, 1) * (1 - LOADER_BASE_PROGRESS))
end

local function setLoaderProgress(self, progress, text, instant)
    local boot = self._boot
    local refs = self._refs
    local nextProgress = math.clamp(progress, 0, 1)

    boot.progress = nextProgress

    if text ~= nil then
        boot.statusText = tostring(text)
    end

    refs.loaderStatus.Text = boot.statusText
    refs.loaderPercent.Text = string.format("%d%%", math.floor((nextProgress * 100) + 0.5))

    if boot.loaderFillTween then
        boot.loaderFillTween:Cancel()
        boot.loaderFillTween = nil
    end

    if instant then
        refs.loaderFill.Size = UDim2.new(nextProgress, 0, 1, 0)
        return
    end

    local tween = TweenService:Create(refs.loaderFill, LOADER_BAR_TWEEN_INFO, {
        Size = UDim2.new(nextProgress, 0, 1, 0),
    })

    boot.loaderFillTween = tween
    tween.Completed:Connect(function()
        if boot.loaderFillTween == tween then
            boot.loaderFillTween = nil
        end
    end)
    tween:Play()
end

local function scheduleAutoFinish(self)
    local boot = self._boot
    if boot.autoFinishScheduled then
        return
    end

    boot.autoFinishScheduled = true
    task.delay(0.15, function()
        boot.autoFinishScheduled = false

        if self._destroyed or not boot.active or boot.revealStarted then
            return
        end

        if boot.userStepCount == 0 or boot.userProgress >= boot.totalUserWeight then
            self:FinishLoading()
        end
    end)
end

local function forceBootVisible(self)
    local boot = self._boot
    local state = self._state
    local refs = self._refs

    boot.active = false
    boot.loaderVisible = false
    boot.revealStarted = false
    boot.titleBarVisible = true
    boot.sidebarVisible = state.ShowSidebar
    boot.contentVisible = true

    refs.titleBar.Visible = true
    refs.titleBar.Position = UDim2.fromOffset(0, 0)
    refs.sidebar.Visible = state.ShowSidebar
    refs.sidebar.Position = UDim2.fromOffset(0, TITLE_BAR_HEIGHT)
    refs.content.Visible = true

    for _, tab in ipairs(self._tabs) do
        tab._bootVisible = true
    end

    applyMetadata(self)
end

local function hideLoaderOverlay(self)
    local boot = self._boot
    local refs = self._refs

    if not refs.loaderOverlay.Visible then
        return
    end

    local state = captureTransparencyState(refs.loaderOverlay)
    local playbackState = tweenTransparencyAlpha(state, 0, 1, LOADER_PANEL_TWEEN_INFO, false)

    if playbackState == Enum.PlaybackState.Completed and refs.loaderOverlay.Parent ~= nil then
        refs.loaderOverlay.Visible = false
        boot.loaderVisible = false
        applyTransparencyAlpha(state, 0)
    end
end

local function revealTabs(self)
    local visibleTabs = getVisibleTabs(self)

    for _, tab in ipairs(visibleTabs) do
        local button = tab._refs.button
        local state = captureTransparencyState(button)

        tab._bootVisible = true
        button.Size = UDim2.new(1, 0, 0, 0)
        button.Visible = true
        applyTransparencyAlpha(state, 1)

        local sizeTween = TweenService:Create(button, WINDOW_BOOT_TAB_TWEEN_INFO, {
            Size = UDim2.new(1, 0, 0, 48),
        })

        sizeTween:Play()
        tweenTransparencyAlpha(state, 1, 0, WINDOW_BOOT_TAB_TWEEN_INFO)
        task.wait(WINDOW_BOOT_TAB_STAGGER)
    end
end

local function revealActivePage(self)
    local activeTab = getActiveTab(self)
    if not activeTab then
        return
    end

    self._boot.contentVisible = true
    applyMetadata(self)

    if not activeTab.Page.Visible then
        return
    end

    local state = captureTransparencyState(activeTab.Page)
    applyTransparencyAlpha(state, 1)
    tweenTransparencyAlpha(state, 1, 0, WINDOW_BOOT_CONTENT_TWEEN_INFO)
end

local function playBootReveal(self)
    local boot = self._boot
    local refs = self._refs
    local state = self._state

    task.wait(LOADER_FINAL_HOLD)
    hideLoaderOverlay(self)

    local expandTween = TweenService:Create(self.Instance, WINDOW_BOOT_EXPAND_TWEEN_INFO, {
        Size = state.Size,
    })
    expandTween:Play()
    task.wait(WINDOW_BOOT_EXPAND_TWEEN_INFO.Time)
    self.Instance.Size = state.Size

    boot.active = false
    boot.compactSize = getCompactSize(state.Size)

    boot.titleBarVisible = true
    refs.titleBar.Visible = true
    refs.titleBar.Position = UDim2.fromOffset(0, -TITLE_BAR_HEIGHT)
    local titleTween = TweenService:Create(refs.titleBar, WINDOW_BOOT_TITLE_TWEEN_INFO, {
        Position = UDim2.fromOffset(0, 0),
    })
    titleTween:Play()
    task.wait(WINDOW_BOOT_TITLE_TWEEN_INFO.Time)
    refs.titleBar.Position = UDim2.fromOffset(0, 0)

    if state.ShowSidebar then
        boot.sidebarVisible = true
        refs.sidebar.Visible = true
        refs.sidebar.Position = UDim2.fromOffset(-state.SidebarWidth, TITLE_BAR_HEIGHT)
        local sidebarTween = TweenService:Create(refs.sidebar, WINDOW_BOOT_SIDEBAR_TWEEN_INFO, {
            Position = UDim2.fromOffset(0, TITLE_BAR_HEIGHT),
        })
        sidebarTween:Play()
        task.wait(WINDOW_BOOT_SIDEBAR_TWEEN_INFO.Time)
        refs.sidebar.Position = UDim2.fromOffset(0, TITLE_BAR_HEIGHT)
    end

    boot.tabsVisible = true
    applyMetadata(self)
    revealTabs(self)
    revealActivePage(self)
    boot.revealStarted = false
    boot.contentVisible = true
    refs.content.Visible = true
    refs.sidebar.Visible = state.ShowSidebar and boot.sidebarVisible
    refs.titleBar.Visible = true
end

local function applyMetadata(self)
    local state = self._state
    local refs = self._refs
    local boot = self._boot
    local renderSize = boot.active and boot.compactSize or state.Size
    local shellReady = (not boot.active) and (not boot.revealStarted)
    local sidebarReady = (state.ShowSidebar and boot.sidebarVisible) or (shellReady and state.ShowSidebar)
    local contentReady = boot.contentVisible or shellReady

    self.Instance.Size = renderSize
    self.Instance.Visible = state.Visible
    self.Instance:SetAttribute("Title", state.Title)
    self.Instance:SetAttribute("Version", state.Version)
    self.Instance:SetAttribute("Resizable", state.Resizable)
    self.Instance:SetAttribute("SidebarWidth", state.SidebarWidth)
    self.Instance:SetAttribute("ShowSidebar", state.ShowSidebar)

    refs.titleBar.BackgroundColor3 = Theme["nav-bg"]
    refs.titleBarStroke.Color = Theme["nav-stroke"]
    refs.titleBarStroke.Thickness = TITLE_BAR_STROKE
    refs.titleLabel.Text = state.Title
    refs.titleLabel.TextColor3 = Theme["text-primary"]
    refs.versionLabel.Text = state.Version or ""
    refs.versionLabel.TextColor3 = Theme["text-secondary"]
    refs.versionLabel.Visible = state.Version ~= nil
    refs.accentChip.BackgroundColor3 = Theme.accent
    refs.accentChip.BackgroundTransparency = 0.84
    refs.accentLabel.TextColor3 = Theme.accent
    refs.loaderTrack.BackgroundColor3 = Theme["nav-stroke"]
    refs.loaderFill.BackgroundColor3 = Theme.accent
    refs.loaderStatus.TextColor3 = Theme["text-secondary"]
    refs.loaderPercent.TextColor3 = Theme.accent
    refs.loaderOverlay.Visible = boot.loaderVisible

    local activeTabTitle = "Slate"
    for _, tab in ipairs(self._tabs) do
        if tab.Active and tab.Visible then
            activeTabTitle = tab.Title
            break
        end
    end

    if refs.accentLabel.Text ~= activeTabTitle then
        refs.accentLabel.Text = activeTabTitle

        local textWidth = TextService:GetTextSize(
            activeTabTitle, CHIP_FONT_SIZE, CHIP_FONT, Vector2.new(math.huge, math.huge)
        ).X
        local targetWidth = textWidth + CHIP_PADDING_X

        TweenService:Create(refs.accentChip, CHIP_TWEEN_INFO, {
            Size = UDim2.fromOffset(targetWidth, CHIP_HEIGHT)
        }):Play()
    end
    refs.sidebar.BackgroundColor3 = Theme["nav-bg"]
    refs.sidebar.Size = UDim2.new(0, state.SidebarWidth, 1, -TITLE_BAR_HEIGHT)
    refs.sidebar.Visible = sidebarReady
    refs.sidebarStroke.Color = Theme["nav-stroke"]
    refs.sidebarStroke.Thickness = SIDEBAR_STROKE
    refs.content.Position = UDim2.fromOffset(state.ShowSidebar and state.SidebarWidth or 0, TITLE_BAR_HEIGHT)
    refs.content.Size = UDim2.new(1, -(state.ShowSidebar and state.SidebarWidth or 0), 1, -TITLE_BAR_HEIGHT)
    refs.content.Visible = contentReady
    refs.cursorHorizontal.BackgroundColor3 = Theme.accent
    refs.cursorVertical.BackgroundColor3 = Theme.accent
    refs.titleBar.Visible = boot.titleBarVisible or shellReady

    for _, tab in ipairs(self._tabs) do
        Tab._applyMetadata(tab)
    end
end

local function createState(config)
    local size = resolveSize(config)
    local visible = getValue(config.AutoShow, DEFAULTS.AutoShow)

    return {
        Title = normalizePropertyValue("Title", config.Title),
        Version = normalizePropertyValue("Version", config.Version),
        Width = getValue(config.Width, size.X.Offset),
        Height = getValue(config.Height, size.Y.Offset),
        Size = size,
        Resizable = getValue(config.Resizable, DEFAULTS.Resizable),
        SidebarWidth = getValue(config.SidebarWidth, DEFAULTS.SidebarWidth),
        ShowSidebar = getValue(config.ShowSidebar, DEFAULTS.ShowSidebar),
        Visible = visible,
        AutoShow = visible,
    }
end

local function ensureProperty(property)
    assert(LIVE_PROPERTIES[property], string.format("Unsupported window property %q", tostring(property)))
end

local function setSize(self, size)
    local state = self._state

    if typeof(size) == "UDim2" then
        state.Size = size
        state.Width = size.X.Offset
        state.Height = size.Y.Offset

        if self._boot and self._boot.active then
            self._boot.compactSize = getCompactSize(state.Size)
        end

        return
    end

    local width = getValue(size.Width, state.Width)
    local height = getValue(size.Height, state.Height)

    state.Width = width
    state.Height = height
    state.Size = UDim2.fromOffset(width, height)

    if self._boot and self._boot.active then
        self._boot.compactSize = getCompactSize(state.Size)
    end
end

local function updateWidth(self, width)
    local state = self._state

    state.Width = width
    state.Size = UDim2.new(state.Size.X.Scale, width, state.Size.Y.Scale, state.Size.Y.Offset)

    if self._boot and self._boot.active then
        self._boot.compactSize = getCompactSize(state.Size)
    end
end

local function updateHeight(self, height)
    local state = self._state

    state.Height = height
    state.Size = UDim2.new(state.Size.X.Scale, state.Size.X.Offset, state.Size.Y.Scale, height)

    if self._boot and self._boot.active then
        self._boot.compactSize = getCompactSize(state.Size)
    end
end

local function applyProperty(self, property, value)
    ensureProperty(property)

    local state = self._state

    if property == "Size" then
        setSize(self, value)
        return
    end

    if property == "Width" then
        updateWidth(self, getValue(value, DEFAULTS.Width))
        return
    end

    if property == "Height" then
        updateHeight(self, getValue(value, DEFAULTS.Height))
        return
    end

    if property == "Visible" or property == "AutoShow" then
        local visible = normalizePropertyValue(property, value)

        state.Visible = visible
        state.AutoShow = visible
        return
    end

    state[property] = normalizePropertyValue(property, value)
end

function Window.new(parent: Instance, config)
    local state = createState(config)
    local frame = Instance.new("Frame")
    frame.Name = "Window"
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Position = UDim2.fromScale(0.5, 0.5)
    frame.BackgroundColor3 = Theme.background
    frame.Active = true
    frame.BorderSizePixel = 0
    frame.ClipsDescendants = true
    frame.ZIndex = 1
    frame:SetAttribute("SlateComponent", "Window")
    frame.Parent = parent

    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, WINDOW_CORNER_RADIUS)
    frameCorner.Parent = frame

    local refs = createTitleBar(frame)
    for key, value in pairs(createSidebar(frame)) do
        refs[key] = value
    end
    for key, value in pairs(createLoader(frame)) do
        refs[key] = value
    end
    for key, value in pairs(createCursor(frame)) do
        refs[key] = value
    end
    local self = setmetatable({
        Instance = frame,
        Parent = parent,
        Tabs = {},
        _connections = {},
        _cursorVisible = false,
        _dragging = false,
        _destroyed = false,
        _groupboxes = {},
        _groupboxConnections = {},
        _groupboxDrag = {
            dragging = false,
            groupbox = nil,
            offset = Vector2.zero,
            originalAutomaticSize = nil,
            originalSize = nil,
            placeholder = nil,
            pointer = Vector2.zero,
            snapConnection = nil,
            snapTween = nil,
            sourceColumn = nil,
            tab = nil,
            targetColumn = nil,
        },
        _boot = createBootState(state.Size),
        _refs = refs,
        _state = state,
        _tabs = {},
    }, WindowMeta)

    applyMetadata(self)
    setLoaderProgress(self, 0.08, "Preparing Slate...", true)
    attachInteractions(self)
    Window.AddTab(self, {
        Title = "Settings",
        Icon = "settings",
        LayoutColumns = 2,
        Order = 9999,
    })
    setLoaderProgress(self, LOADER_BASE_PROGRESS, "Slate ready", false)
    scheduleAutoFinish(self)

    return self
end

function Window:Get(property)
    return self._state[property]
end

function Window:Set(propertyOrProperties, value)
    if self._destroyed then
        return self
    end

    if type(propertyOrProperties) == "table" then
        for property, nextValue in pairs(propertyOrProperties) do
            applyProperty(self, property, nextValue)
        end
    else
        applyProperty(self, propertyOrProperties, value)
    end

    applyMetadata(self)

    return self
end

function Window:Update(properties)
    return self:Set(properties)
end

function Window:Show()
    return self:Set("Visible", true)
end

function Window:Hide()
    return self:Set("Visible", false)
end

function Window:SetTitle(title: string)
    return self:Set("Title", title)
end

function Window:SetVersion(version: string?)
    return self:Set("Version", version)
end

function Window:SetResizable(resizable: boolean)
    return self:Set("Resizable", resizable)
end

function Window:SetSidebarWidth(sidebarWidth: number)
    return self:Set("SidebarWidth", sidebarWidth)
end

function Window:SetSidebarVisible(showSidebar: boolean)
    return self:Set("ShowSidebar", showSidebar)
end

function Window:SetSize(size)
    return self:Set("Size", size)
end

function Window:SetLoaderStatus(text)
    if self._destroyed or not self._boot.active then
        return self
    end

    setLoaderProgress(self, self._boot.progress, text, true)

    return self
end

function Window:QueueLoadStep(configOrText, weight)
    if self._destroyed or not self._boot.active then
        return nil
    end

    local config
    if type(configOrText) == "table" then
        config = configOrText
    else
        config = {
            Text = configOrText,
            Weight = weight,
        }
    end

    local step = {
        Completed = false,
        Text = tostring(config.Text or "Loading..."),
        Weight = math.max(tonumber(config.Weight) or 1, 0.01),
    }

    self._boot.userStepCount += 1
    self._boot.totalUserWeight += step.Weight
    setLoaderProgress(self, computeLoaderProgress(self), step.Text, true)

    return {
        Complete = function(_, text)
            if self._destroyed or step.Completed then
                return self
            end

            step.Completed = true
            self._boot.userProgress += step.Weight
            setLoaderProgress(self, computeLoaderProgress(self), text or step.Text, false)

            if self._boot.userProgress >= self._boot.totalUserWeight then
                self:FinishLoading()
            end

            return self
        end,
        SetStatus = function(_, text)
            if self._destroyed or step.Completed then
                return self
            end

            step.Text = tostring(text or step.Text)
            self:SetLoaderStatus(step.Text)

            return self
        end,
    }
end

function Window:FinishLoading(text)
    if self._destroyed or not self._boot.active or self._boot.revealStarted then
        return self
    end

    self._boot.revealStarted = true
    setLoaderProgress(self, 1, text or "Ready", false)

    task.spawn(function()
        if self._destroyed then
            return
        end

        task.wait(0.08)
        if self._destroyed then
            return
        end

        local ok, err = pcall(playBootReveal, self)
        if not ok and not self._destroyed then
            warn(string.format("Slate boot reveal failed: %s", tostring(err)))
            forceBootVisible(self)
        end
    end)

    return self
end

function Window:AddTab(config)
    local tabConfig = config or {}
    if string.lower(tostring(tabConfig.Title or tabConfig.Id or tabConfig.Name or "")) == "settings" then
        tabConfig.LayoutColumns = 2
    end
    local tab = Tab.new(self, tabConfig, #self._tabs + 1)

    table.insert(self._tabs, tab)
    self.Tabs[tab.Title] = tab
    self:_reconcileTabs(tabConfig.Active and tab or nil)

    return tab
end

function Window:AddGroupbox(column, config)
    error("Window:AddGroupbox() has moved. Use Tab:AddGroupbox(column, config) instead.")
end

function Window:_addGroupbox(tab, column, config)
    local groupbox = Groupbox.new(column, config)
    groupbox.Tab = tab

    table.insert(self._groupboxes, groupbox)
    table.insert(tab._groupboxes, groupbox)
    bindGroupboxDragging(self, groupbox)
    commitColumnLayout(self, column)

    return groupbox
end

function Window:SelectTab(tab)
    if self._destroyed or tab._destroyed then
        return self
    end

    for _, candidate in ipairs(self._tabs) do
        candidate._state.Active = candidate == tab and candidate.Visible
    end

    applyMetadata(self)

    return self
end

function Window:_reconcileTabs(preferredTab)
    local visibleTabs = getVisibleTabs(self)
    local activeTab = nil

    for _, tab in ipairs(self._tabs) do
        if tab.Active and tab.Visible and not tab._destroyed then
            activeTab = tab
            break
        end
    end

    if preferredTab and preferredTab.Visible and not preferredTab._destroyed then
        activeTab = preferredTab
    end

    if not activeTab then
        activeTab = visibleTabs[1]
    end

    self.Tabs = {}

    for _, tab in ipairs(self._tabs) do
        tab._state.Active = activeTab ~= nil and tab == activeTab
        self.Tabs[tab.Title] = tab
    end

    applyMetadata(self)
end

function Window:_removeTab(tab)
    local nextTabs = {}

    for _, candidate in ipairs(self._tabs) do
        if candidate ~= tab then
            table.insert(nextTabs, candidate)
        end
    end

    self.Tabs[tab.Title] = nil
    self._tabs = nextTabs
    self:_reconcileTabs(nil)
end

function Window:_removeGroupboxesForTab(tab)
    local remaining = {}

    for _, groupbox in ipairs(self._groupboxes) do
        if groupbox.Tab == tab then
            if self._groupboxDrag.groupbox == groupbox then
                endGroupboxDrag(self)
            end

            safeDisconnect(self._groupboxConnections[groupbox])
            self._groupboxConnections[groupbox] = nil
            groupbox._destroyed = true
            groupbox.Instance:Destroy()
        else
            table.insert(remaining, groupbox)
        end
    end

    self._groupboxes = remaining
    tab._groupboxes = {}
end

function Window:Destroy()
    if self._destroyed then
        return
    end

    setInternal(self, "_destroyed", true)
    setInternal(self, "_dragging", false)
    setCursorVisible(self, false)

    local tabs = table.clone(self._tabs)
    for _, tab in ipairs(tabs) do
        tab:Destroy()
    end

    if self._groupboxDrag.dragging then
        endGroupboxDrag(self)
    end

    for _, connection in pairs(self._groupboxConnections) do
        safeDisconnect(connection)
    end

    self._groupboxConnections = {}
    self._groupboxes = {}
    self._tabs = {}
    self.Tabs = {}

    for _, connection in ipairs(self._connections) do
        connection:Disconnect()
    end

    self._connections = {}
    self.Instance:Destroy()
end

function WindowMeta.__index(self, key)
    local method = Window[key]
    if method ~= nil then
        return method
    end

    local state = rawget(self, "_state")
    if state and state[key] ~= nil then
        return state[key]
    end

    return rawget(self, key)
end

function WindowMeta.__newindex(self, key, value)
    if rawget(self, "_state") and LIVE_PROPERTIES[key] then
        self:Set(key, value)
        return
    end

    error(string.format("Unsupported window property %q", tostring(key)))
end


local Slate = {}

local getGlobalEnvironment = getgenv or function()
    return _G
end

local runtime = getGlobalEnvironment()
runtime.__SlateMountedWindows = runtime.__SlateMountedWindows or {}

local mountedWindows = runtime.__SlateMountedWindows

Slate.Theme = Theme
Slate.ColorPicker = ColorPicker
Slate.Divider = Divider
Slate.Groupbox = Groupbox
Slate.KeyPicker = KeyPicker
Slate.Label = Label
Slate.Separator = Separator
Slate.Toggle = Toggle

local function destroyMountedWindows()
    for index = #mountedWindows, 1, -1 do
        local window = mountedWindows[index]
        if window and not window._destroyed then
            window:Destroy()
        end

        mountedWindows[index] = nil
    end
end

local function normalizeWindowConfig(selfOrConfig, config)
    if selfOrConfig == Slate then
        return config or {}
    end

    if type(selfOrConfig) == "table" then
        return selfOrConfig
    end

    return {}
end

function Slate:CreateWindow(config)
    local windowConfig = normalizeWindowConfig(self, config)
    local target = windowConfig.Parent or Root.getOrCreate()
    local window = Window.new(target, windowConfig)

    table.insert(mountedWindows, window)

    return window
end

function Slate:Destroy()
    destroyMountedWindows()
    Root.destroy()
end

destroyMountedWindows()

return Slate
