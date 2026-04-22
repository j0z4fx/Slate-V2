local __modules = {}
local __cache = {}

local function __require(name)
    if __cache[name] ~= nil then
        return __cache[name]
    end

    local loader = __modules[name]
    assert(loader ~= nil, string.format("Missing bundled module %q", tostring(name)))

    local value = loader()
    __cache[name] = value

    return value
end

-- src/theme/Theme.lua
__modules['theme/Theme'] = function()
    local Theme = {
        background = Color3.fromRGB(15, 15, 24),
        ["nav-bg"] = Color3.fromRGB(12, 12, 20),
        ["nav-stroke"] = Color3.fromRGB(37, 37, 46),
        ["modal-scrim"] = Color3.fromRGB(5, 5, 10),
        ["text-primary"] = Color3.fromRGB(212, 212, 236),
        ["text-secondary"] = Color3.fromRGB(94, 94, 126),
        ["text-placeholder"] = Color3.fromRGB(78, 78, 105),
        accent = Color3.fromRGB(255, 91, 155),
        ["accent-soft"] = Color3.fromRGB(255, 132, 181),
        surface = Color3.fromRGB(21, 21, 33),
        ["surface-stroke"] = Color3.fromRGB(38, 38, 58),
        ["divider-line"] = Color3.fromRGB(37, 37, 46),
        ["separator-text"] = Color3.fromRGB(82, 94, 114),
        ["label-primary"] = Color3.fromRGB(212, 212, 236),
        ["label-subtext"] = Color3.fromRGB(94, 94, 126),
        ["paragraph-body"] = Color3.fromRGB(148, 148, 176),
        ["toggle-body"] = Color3.fromRGB(32, 32, 46),
        ["toggle-dot"] = Color3.fromRGB(94, 94, 126),
        ["toggle-stroke"] = Color3.fromRGB(46, 46, 68),
        ["button-bg"] = Color3.fromRGB(34, 34, 50),
        ["button-bg-hover"] = Color3.fromRGB(40, 40, 58),
        ["button-bg-pressed"] = Color3.fromRGB(28, 28, 42),
        ["button-stroke"] = Color3.fromRGB(50, 50, 72),
        ["checkbox-bg"] = Color3.fromRGB(29, 29, 42),
        ["checkbox-stroke"] = Color3.fromRGB(48, 48, 70),
        ["input-bg"] = Color3.fromRGB(19, 19, 30),
        ["input-stroke"] = Color3.fromRGB(44, 44, 64),
        ["input-focus"] = Color3.fromRGB(255, 91, 155),
        ["slider-track"] = Color3.fromRGB(30, 30, 45),
        ["slider-knob"] = Color3.fromRGB(255, 255, 255),
        ["dropdown-item"] = Color3.fromRGB(26, 26, 39),
        ["dropdown-item-hover"] = Color3.fromRGB(31, 31, 47),
        ["code-bg"] = Color3.fromRGB(14, 14, 22),
        ["code-stroke"] = Color3.fromRGB(35, 35, 52),
        ["tabbox-tab"] = Color3.fromRGB(19, 19, 30),
        ["tabbox-tab-active"] = Color3.fromRGB(30, 30, 45),
        ["toast-bg"] = Color3.fromRGB(12, 12, 20),
        ["toast-stroke"] = Color3.fromRGB(42, 42, 60),
    }

    return Theme
end

-- src/core/Root.lua
__modules['core/Root'] = function()
    local Players = game:GetService("Players")
    local CoreGui = game:GetService("CoreGui")
    local RunService = game:GetService("RunService")

    local protectGui = protectgui or (syn and syn.protect_gui) or function() end
    local getHiddenUi = gethui

    local Root = {}
    local ROOT_NAME = "Slate"
    local ROOT_ATTRIBUTE = "SlateOwned"

    local function resolveContainer()
        local localPlayer = Players.LocalPlayer
        local playerGui = localPlayer and (localPlayer:FindFirstChildOfClass("PlayerGui") or localPlayer:WaitForChild("PlayerGui"))

        if RunService:IsStudio() and playerGui then
            return playerGui
        end

        if CoreGui then
            return CoreGui
        end

        if typeof(getHiddenUi) == "function" then
            local success, hiddenUi = pcall(getHiddenUi)
            if success and typeof(hiddenUi) == "Instance" then
                return hiddenUi
            end
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

    return Root
end

-- src/core/Keybind.lua
__modules['core/Keybind'] = function()
    local Keybind = {}

    local SPECIAL_INPUTS = {
        [Enum.UserInputType.MouseButton1] = "MB1",
        [Enum.UserInputType.MouseButton2] = "MB2",
        [Enum.UserInputType.MouseButton3] = "MB3",
    }

    local activePicker = nil

    function Keybind.normalize(value)
        if value == nil then
            return "None"
        end

        if typeof(value) == "EnumItem" then
            if value.EnumType == Enum.UserInputType then
                return SPECIAL_INPUTS[value] or value.Name
            end

            return value.Name
        end

        return tostring(value)
    end

    function Keybind.inputToKeyName(input)
        if SPECIAL_INPUTS[input.UserInputType] then
            return SPECIAL_INPUTS[input.UserInputType]
        end

        if input.KeyCode and input.KeyCode ~= Enum.KeyCode.Unknown then
            return input.KeyCode.Name
        end

        return nil
    end

    function Keybind.format(value)
        local key = Keybind.normalize(value)
        if key == "None" then
            return key
        end

        key = key:gsub("(%l)(%u)", "%1 %2")
        key = key:gsub("Button(%d)", "Button %1")

        return key
    end

    function Keybind.beginCapture(owner)
        activePicker = owner
    end

    function Keybind.endCapture(owner)
        if activePicker == owner then
            activePicker = nil
        end
    end

    function Keybind.isCapturing()
        return activePicker ~= nil
    end

    return Keybind
end

-- src/core/Ui.lua
__modules['core/Ui'] = function()
    local TweenService = game:GetService("TweenService")
    local UserInputService = game:GetService("UserInputService")

    local Ui = {}

    function Ui.apply(instance, properties)
        for property, value in pairs(properties) do
            instance[property] = value
        end
    end

    function Ui.cancel(tween)
        if tween then
            tween:Cancel()
        end
    end

    function Ui.findWindow(instance)
        local current = instance

        while current do
            if current.GetAttribute and current:GetAttribute("SlateComponent") == "Window" then
                return current
            end

            current = current.Parent
        end

        return nil
    end

    function Ui.animationsEnabled(instance)
        local window = Ui.findWindow(instance)
        if window == nil then
            return true
        end

        return window:GetAttribute("SlateAnimationsEnabled") ~= false
    end

    function Ui.play(instance, tweenInfo, properties)
        if not Ui.animationsEnabled(instance) then
            Ui.apply(instance, properties)
            return nil
        end

        local tween = TweenService:Create(instance, tweenInfo, properties)
        tween:Play()

        return tween
    end

    function Ui.isTextInputFocused()
        return UserInputService:GetFocusedTextBox() ~= nil
    end

    return Ui
end

-- src/core/ControlFactory.lua
__modules['core/ControlFactory'] = function()
    local ControlFactory = {}

    local function addControl(self, control)
        table.insert(self.Controls, control)

        return control
    end

    local function normalizeConfig(configOrText, config)
        if type(configOrText) == "table" then
            return configOrText
        end

        local nextConfig = config or {}
        nextConfig.Text = configOrText

        return nextConfig
    end

    function ControlFactory.AddToggle(self, configOrText, config)
    local Toggle = __require('components/Toggle')

        return addControl(self, Toggle.new(self.Content, normalizeConfig(configOrText, config)))
    end

    function ControlFactory.AddSwitch(self, configOrText, config)
        return ControlFactory.AddToggle(self, configOrText, config)
    end

    function ControlFactory.AddCheckbox(self, configOrText, config)
    local Checkbox = __require('components/Checkbox')

        return addControl(self, Checkbox.new(self.Content, normalizeConfig(configOrText, config)))
    end

    function ControlFactory.AddButton(self, configOrText, config)
    local Button = __require('components/Button')

        return addControl(self, Button.new(self.Content, normalizeConfig(configOrText, config)))
    end

    function ControlFactory.AddDivider(self)
    local Divider = __require('components/Divider')

        return addControl(self, Divider.new(self.Content))
    end

    function ControlFactory.AddSeparator(self, configOrText, config)
    local Separator = __require('components/Separator')

        return addControl(self, Separator.new(self.Content, normalizeConfig(configOrText, config)))
    end

    function ControlFactory.AddLabel(self, configOrText, config)
    local Label = __require('components/Label')

        return addControl(self, Label.new(self.Content, normalizeConfig(configOrText, config)))
    end

    function ControlFactory.AddInput(self, configOrText, config)
    local Input = __require('components/Input')

        return addControl(self, Input.new(self.Content, normalizeConfig(configOrText, config)))
    end

    function ControlFactory.AddSlider(self, configOrText, config)
    local Slider = __require('components/Slider')

        return addControl(self, Slider.new(self.Content, normalizeConfig(configOrText, config)))
    end

    function ControlFactory.AddDropdown(self, configOrText, config)
    local Dropdown = __require('components/Dropdown')

        return addControl(self, Dropdown.new(self.Content, normalizeConfig(configOrText, config)))
    end

    function ControlFactory.AddParagraph(self, configOrText, config)
    local Paragraph = __require('components/Paragraph')
        local nextConfig = configOrText

        if type(configOrText) ~= "table" then
            nextConfig = config or {}
            nextConfig.Body = configOrText
        end

        return addControl(self, Paragraph.new(self.Content, nextConfig))
    end

    function ControlFactory.AddCode(self, configOrText, config)
    local Code = __require('components/Code')
        local nextConfig = configOrText

        if type(configOrText) ~= "table" then
            nextConfig = config or {}
            nextConfig.Text = configOrText
        end

        return addControl(self, Code.new(self.Content, nextConfig))
    end

    function ControlFactory.AddTag(self, configOrText, config)
    local Tag = __require('components/Tag')

        return addControl(self, Tag.new(self.Content, normalizeConfig(configOrText, config)))
    end

    function ControlFactory.AddTabbox(self, config)
    local Tabbox = __require('components/Tabbox')

        return addControl(self, Tabbox.new(self.Content, config or {}))
    end

    return ControlFactory
end

-- src/vendor/Lucide.lua
__modules['vendor/Lucide'] = function()
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

    return Lucide
end

-- src/components/Button.lua
__modules['components/Button'] = function()
    local Theme = __require('theme/Theme')
    local Ui = __require('core/Ui')

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
end

-- src/components/Checkbox.lua
__modules['components/Checkbox'] = function()
    local Theme = __require('theme/Theme')
    local Ui = __require('core/Ui')
    local ColorPicker = __require('components/ColorPicker')
    local KeyPicker = __require('components/KeyPicker')

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
        check.Text = "âœ“"
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
end

-- src/components/Code.lua
__modules['components/Code'] = function()
    local Theme = __require('theme/Theme')

    local Code = {}
    local CodeMeta = {}

    local LIVE_PROPERTIES = {
        Text = true,
        Title = true,
        Visible = true,
    }

    local DEFAULTS = {
        Text = "print(\"Slate\")",
        Title = nil,
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

        if property == "Title" then
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

    local function createCode(parent)
        local frame = Instance.new("Frame")
        frame.Name = "Code"
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

        local title = Instance.new("TextLabel")
        title.Name = "Title"
        title.AutomaticSize = Enum.AutomaticSize.Y
        title.BackgroundTransparency = 1
        title.BorderSizePixel = 0
        title.Font = Enum.Font.GothamMedium
        title.Size = UDim2.new(1, 0, 0, 0)
        title.TextColor3 = Theme["text-primary"]
        title.TextSize = 13
        title.TextWrapped = true
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.TextYAlignment = Enum.TextYAlignment.Top
        title.Visible = false
        title.Parent = frame

        local panel = Instance.new("Frame")
        panel.Name = "Panel"
        panel.AutomaticSize = Enum.AutomaticSize.Y
        panel.BackgroundColor3 = Theme["code-bg"]
        panel.BorderSizePixel = 0
        panel.Size = UDim2.new(1, 0, 0, 0)
        panel.Parent = frame

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = panel

        local stroke = Instance.new("UIStroke")
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Color = Theme["code-stroke"]
        stroke.Thickness = 1
        stroke.Parent = panel

        local padding = Instance.new("UIPadding")
        padding.PaddingBottom = UDim.new(0, 10)
        padding.PaddingLeft = UDim.new(0, 10)
        padding.PaddingRight = UDim.new(0, 10)
        padding.PaddingTop = UDim.new(0, 10)
        padding.Parent = panel

        local body = Instance.new("TextLabel")
        body.Name = "Body"
        body.AutomaticSize = Enum.AutomaticSize.Y
        body.BackgroundTransparency = 1
        body.BorderSizePixel = 0
        body.Font = Enum.Font.Code
        body.Size = UDim2.new(1, 0, 0, 0)
        body.TextColor3 = Theme["text-primary"]
        body.TextSize = 13
        body.TextWrapped = true
        body.TextXAlignment = Enum.TextXAlignment.Left
        body.TextYAlignment = Enum.TextYAlignment.Top
        body.Parent = panel

        return {
            body = body,
            frame = frame,
            panel = panel,
            title = title,
        }
    end

    local function ensureProperty(property)
        assert(LIVE_PROPERTIES[property], string.format("Unsupported code property %q", tostring(property)))
    end

    local function applyMetadata(self)
        local refs = self._refs
        local state = self._state

        refs.frame.Visible = state.Visible
        refs.title.Text = state.Title or ""
        refs.title.Visible = state.Title ~= nil
        refs.body.Text = state.Text
    end

    function Code.new(parent, config)
        local refs = createCode(parent)
        local cfg = config or {}

        local self = setmetatable({
            Instance = refs.frame,
            _destroyed = false,
            _refs = refs,
            _state = {
                Text = normalizePropertyValue("Text", cfg.Text or cfg.Code or cfg.Value),
                Title = normalizePropertyValue("Title", cfg.Title),
                Visible = normalizePropertyValue("Visible", cfg.Visible),
            },
        }, CodeMeta)

        applyMetadata(self)

        return self
    end

    function Code:Set(propertyOrProperties, value)
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

    function Code:Update(properties)
        return self:Set(properties)
    end

    function Code:Destroy()
        if self._destroyed then
            return
        end

        self._destroyed = true
        self.Instance:Destroy()
    end

    function CodeMeta.__index(self, key)
        local method = Code[key]
        if method ~= nil then
            return method
        end

        local state = rawget(self, "_state")
        if state and state[key] ~= nil then
            return state[key]
        end

        return rawget(self, key)
    end

    function CodeMeta.__newindex(self, key, value)
        if rawget(self, "_state") and LIVE_PROPERTIES[key] then
            self:Set(key, value)
            return
        end

        error(string.format("Unsupported code property %q", tostring(key)))
    end

    return Code
end

-- src/components/ColorPicker.lua
__modules['components/ColorPicker'] = function()
    local Theme = __require('theme/Theme')
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

    return ColorPicker
end

-- src/components/Dialog.lua
__modules['components/Dialog'] = function()
    local Theme = __require('theme/Theme')
    local TweenService = game:GetService("TweenService")

    local Dialog = {}

    local DIALOG_TWEEN_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

    local function createButton(parent, text, accent)
        local button = Instance.new("TextButton")
        button.AutoButtonColor = false
        button.BackgroundColor3 = accent and Theme.accent or Theme["button-bg"]
        button.BorderSizePixel = 0
        button.Size = UDim2.new(0.5, -4, 0, 28)
        button.Text = ""
        button.Parent = parent

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = button

        local label = Instance.new("TextLabel")
        label.BackgroundTransparency = 1
        label.BorderSizePixel = 0
        label.Size = UDim2.fromScale(1, 1)
        label.Font = Enum.Font.GothamMedium
        label.Text = tostring(text)
        label.TextColor3 = accent and Color3.new(1, 1, 1) or Theme["text-primary"]
        label.TextSize = 13
        label.TextXAlignment = Enum.TextXAlignment.Center
        label.TextYAlignment = Enum.TextYAlignment.Center
        label.Parent = button

        return button
    end

    function Dialog.Open(window, config)
        local root = window.Parent
        local cfg = config or {}

        local overlay = Instance.new("Frame")
        overlay.Name = "SlateDialog"
        overlay.BackgroundColor3 = Theme["modal-scrim"]
        overlay.BackgroundTransparency = window._state.Animations and 1 or 0.18
        overlay.BorderSizePixel = 0
        overlay.Size = UDim2.fromScale(1, 1)
        overlay.ZIndex = 40
        overlay.Parent = root

        local panel = Instance.new("Frame")
        panel.AnchorPoint = Vector2.new(0.5, 0.5)
        panel.AutomaticSize = Enum.AutomaticSize.Y
        panel.BackgroundColor3 = Theme.surface
        panel.BorderSizePixel = 0
        panel.Position = UDim2.fromScale(0.5, 0.5)
        panel.Size = UDim2.new(0, 360, 0, 0)
        panel.ZIndex = overlay.ZIndex + 1
        panel.Parent = overlay

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = panel

        local stroke = Instance.new("UIStroke")
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Color = Theme["surface-stroke"]
        stroke.Thickness = 1
        stroke.Parent = panel

        local padding = Instance.new("UIPadding")
        padding.PaddingBottom = UDim.new(0, 12)
        padding.PaddingLeft = UDim.new(0, 12)
        padding.PaddingRight = UDim.new(0, 12)
        padding.PaddingTop = UDim.new(0, 12)
        padding.Parent = panel

        local layout = Instance.new("UIListLayout")
        layout.FillDirection = Enum.FillDirection.Vertical
        layout.Padding = UDim.new(0, 8)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = panel

        local title = Instance.new("TextLabel")
        title.AutomaticSize = Enum.AutomaticSize.Y
        title.BackgroundTransparency = 1
        title.BorderSizePixel = 0
        title.Font = Enum.Font.GothamMedium
        title.Size = UDim2.new(1, 0, 0, 0)
        title.Text = tostring(cfg.Title or "Confirm")
        title.TextColor3 = Theme["text-primary"]
        title.TextSize = 16
        title.TextWrapped = true
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.TextYAlignment = Enum.TextYAlignment.Top
        title.Parent = panel

        local body = Instance.new("TextLabel")
        body.AutomaticSize = Enum.AutomaticSize.Y
        body.BackgroundTransparency = 1
        body.BorderSizePixel = 0
        body.Font = Enum.Font.Gotham
        body.Size = UDim2.new(1, 0, 0, 0)
        body.Text = tostring(cfg.Content or cfg.Text or "")
        body.TextColor3 = Theme["text-secondary"]
        body.TextSize = 13
        body.TextWrapped = true
        body.TextXAlignment = Enum.TextXAlignment.Left
        body.TextYAlignment = Enum.TextYAlignment.Top
        body.Parent = panel

        local buttons = Instance.new("Frame")
        buttons.BackgroundTransparency = 1
        buttons.BorderSizePixel = 0
        buttons.Size = UDim2.new(1, 0, 0, 28)
        buttons.Parent = panel

        local buttonsLayout = Instance.new("UIListLayout")
        buttonsLayout.FillDirection = Enum.FillDirection.Horizontal
        buttonsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
        buttonsLayout.Padding = UDim.new(0, 8)
        buttonsLayout.SortOrder = Enum.SortOrder.LayoutOrder
        buttonsLayout.Parent = buttons

        local dialog = {}
        local closing = false

        function dialog:Close()
            if closing then
                return
            end

            closing = true

            if not window._state.Animations then
                overlay:Destroy()
                return
            end

            local tween = TweenService:Create(overlay, DIALOG_TWEEN_INFO, {
                BackgroundTransparency = 1,
            })
            TweenService:Create(panel, DIALOG_TWEEN_INFO, {
                BackgroundTransparency = 1,
            }):Play()
            tween:Play()
            tween.Completed:Connect(function()
                overlay:Destroy()
            end)
        end

        local definitions = cfg.Buttons or {
            {
                Accent = true,
                Text = "Okay",
            },
        }

        for _, definition in ipairs(definitions) do
            local button = createButton(buttons, definition.Text or "Okay", definition.Accent == true)
            button.MouseButton1Click:Connect(function()
                local shouldClose = true
                if definition.Callback then
                    local result = definition.Callback()
                    if result == false then
                        shouldClose = false
                    end
                end

                if shouldClose then
                    dialog:Close()
                end
            end)
        end

        if window._state.Animations then
            TweenService:Create(overlay, DIALOG_TWEEN_INFO, {
                BackgroundTransparency = 0.18,
            }):Play()
        end

        dialog.Instance = overlay

        return dialog
    end

    return Dialog
end

-- src/components/Divider.lua
__modules['components/Divider'] = function()
    local Theme = __require('theme/Theme')

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

    return Divider
end

-- src/components/Dropdown.lua
__modules['components/Dropdown'] = function()
    local Theme = __require('theme/Theme')
    local Ui = __require('core/Ui')

    local Dropdown = {}
    local DropdownMeta = {}

    local ITEM_HEIGHT = 24
    local SEARCH_HEIGHT = 26

    local LIVE_PROPERTIES = {
        Disabled = true,
        Text = true,
        Value = true,
        Visible = true,
    }

    local DEFAULTS = {
        Default = nil,
        Disabled = false,
        Text = "Dropdown",
        Visible = true,
    }

    local function getValue(value, fallback)
        if value == nil then
            return fallback
        end

        return value
    end

    local function copyValues(values)
        local nextValues = {}

        for _, value in ipairs(values or {}) do
            table.insert(nextValues, tostring(value))
        end

        return nextValues
    end

    local function normalizeValue(self, value)
        if self and self._state and self._state.Multi then
            local selected = {}

            if type(value) == "table" then
                for key, enabled in pairs(value) do
                    if enabled then
                        selected[tostring(key)] = true
                    end
                end
            elseif value ~= nil then
                selected[tostring(value)] = true
            end

            return selected
        end

        if value == nil then
            return nil
        end

        return tostring(value)
    end

    local function createDropdown(parent)
        local frame = Instance.new("Frame")
        frame.Name = "Dropdown"
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

        local button = Instance.new("TextButton")
        button.Name = "Button"
        button.AutoButtonColor = false
        button.BackgroundColor3 = Theme["input-bg"]
        button.BorderSizePixel = 0
        button.Size = UDim2.new(1, 0, 0, 30)
        button.Text = ""
        button.Parent = frame

        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 6)
        buttonCorner.Parent = button

        local buttonStroke = Instance.new("UIStroke")
        buttonStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        buttonStroke.Color = Theme["input-stroke"]
        buttonStroke.Thickness = 1
        buttonStroke.Parent = button

        local valueLabel = Instance.new("TextLabel")
        valueLabel.Name = "Value"
        valueLabel.BackgroundTransparency = 1
        valueLabel.BorderSizePixel = 0
        valueLabel.Font = Enum.Font.Gotham
        valueLabel.Position = UDim2.fromOffset(10, 0)
        valueLabel.Size = UDim2.new(1, -34, 1, 0)
        valueLabel.TextColor3 = Theme["text-primary"]
        valueLabel.TextSize = 13
        valueLabel.TextXAlignment = Enum.TextXAlignment.Left
        valueLabel.TextYAlignment = Enum.TextYAlignment.Center
        valueLabel.Parent = button

        local arrow = Instance.new("TextLabel")
        arrow.Name = "Arrow"
        arrow.AnchorPoint = Vector2.new(1, 0.5)
        arrow.BackgroundTransparency = 1
        arrow.BorderSizePixel = 0
        arrow.Font = Enum.Font.GothamBold
        arrow.Position = UDim2.new(1, -10, 0.5, 0)
        arrow.Size = UDim2.fromOffset(14, 14)
        arrow.Text = "v"
        arrow.TextColor3 = Theme["text-secondary"]
        arrow.TextSize = 12
        arrow.TextXAlignment = Enum.TextXAlignment.Center
        arrow.TextYAlignment = Enum.TextYAlignment.Center
        arrow.Parent = button

        local menu = Instance.new("Frame")
        menu.Name = "Menu"
        menu.AutomaticSize = Enum.AutomaticSize.Y
        menu.BackgroundColor3 = Theme.surface
        menu.BorderSizePixel = 0
        menu.Size = UDim2.new(1, 0, 0, 0)
        menu.Visible = false
        menu.Parent = frame

        local menuCorner = Instance.new("UICorner")
        menuCorner.CornerRadius = UDim.new(0, 6)
        menuCorner.Parent = menu

        local menuStroke = Instance.new("UIStroke")
        menuStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        menuStroke.Color = Theme["surface-stroke"]
        menuStroke.Thickness = 1
        menuStroke.Parent = menu

        local menuPadding = Instance.new("UIPadding")
        menuPadding.PaddingBottom = UDim.new(0, 8)
        menuPadding.PaddingLeft = UDim.new(0, 8)
        menuPadding.PaddingRight = UDim.new(0, 8)
        menuPadding.PaddingTop = UDim.new(0, 8)
        menuPadding.Parent = menu

        local menuLayout = Instance.new("UIListLayout")
        menuLayout.FillDirection = Enum.FillDirection.Vertical
        menuLayout.Padding = UDim.new(0, 6)
        menuLayout.SortOrder = Enum.SortOrder.LayoutOrder
        menuLayout.Parent = menu

        local search = Instance.new("TextBox")
        search.Name = "Search"
        search.BackgroundColor3 = Theme["input-bg"]
        search.BorderSizePixel = 0
        search.ClearTextOnFocus = false
        search.Font = Enum.Font.Gotham
        search.PlaceholderColor3 = Theme["text-placeholder"]
        search.PlaceholderText = "Search..."
        search.Size = UDim2.new(1, 0, 0, SEARCH_HEIGHT)
        search.Text = ""
        search.TextColor3 = Theme["text-primary"]
        search.TextSize = 13
        search.Visible = false
        search.Parent = menu

        local searchCorner = Instance.new("UICorner")
        searchCorner.CornerRadius = UDim.new(0, 6)
        searchCorner.Parent = search

        local searchPadding = Instance.new("UIPadding")
        searchPadding.PaddingLeft = UDim.new(0, 8)
        searchPadding.PaddingRight = UDim.new(0, 8)
        searchPadding.Parent = search

        local list = Instance.new("ScrollingFrame")
        list.Name = "List"
        list.AutomaticCanvasSize = Enum.AutomaticSize.Y
        list.BackgroundTransparency = 1
        list.BorderSizePixel = 0
        list.CanvasSize = UDim2.new()
        list.ScrollBarImageColor3 = Theme["surface-stroke"]
        list.ScrollBarThickness = 3
        list.Size = UDim2.new(1, 0, 0, ITEM_HEIGHT)
        list.Parent = menu

        local listLayout = Instance.new("UIListLayout")
        listLayout.FillDirection = Enum.FillDirection.Vertical
        listLayout.Padding = UDim.new(0, 4)
        listLayout.SortOrder = Enum.SortOrder.LayoutOrder
        listLayout.Parent = list

        return {
            arrow = arrow,
            button = button,
            buttonStroke = buttonStroke,
            frame = frame,
            label = label,
            list = list,
            listLayout = listLayout,
            menu = menu,
            search = search,
            valueLabel = valueLabel,
        }
    end

    local function ensureProperty(property)
        assert(LIVE_PROPERTIES[property], string.format("Unsupported dropdown property %q", tostring(property)))
    end

    local function countSelected(selected)
        local total = 0

        for _, enabled in pairs(selected or {}) do
            if enabled then
                total += 1
            end
        end

        return total
    end

    local function getDisplayValue(self)
        if self._state.Multi then
            local selected = {}

            for _, value in ipairs(self._state.Values) do
                if self._state.Value[value] then
                    table.insert(selected, value)
                end
            end

            if #selected == 0 then
                return "Select..."
            end

            if #selected <= 2 then
                return table.concat(selected, ", ")
            end

            return string.format("%d selected", #selected)
        end

        return self._state.Value or "Select..."
    end

    local function passesFilter(self, value)
        if self._query == "" then
            return true
        end

        return string.find(string.lower(value), string.lower(self._query), 1, true) ~= nil
    end

    local function updateListHeight(self, visibleCount)
        local rows = math.max(visibleCount, 1)
        rows = math.min(rows, self._state.MaxVisibleItems)
        self._refs.list.Size = UDim2.new(1, 0, 0, rows * (ITEM_HEIGHT + 4))
    end

    local function updateOptionStyles(optionButton, selected, disabled)
        local fill = optionButton:FindFirstChild("Fill")
        local label = optionButton:FindFirstChild("Label")
        if fill == nil or label == nil then
            return
        end

        fill.BackgroundTransparency = selected and 0 or 1
        label.TextColor3 = selected and Color3.new(1, 1, 1) or Theme["text-secondary"]
        optionButton.BackgroundTransparency = disabled and 0.18 or 0
        label.TextTransparency = disabled and 0.35 or 0
    end

    local function rebuildOptions(self)
        local refs = self._refs

        for _, child in ipairs(refs.list:GetChildren()) do
            if child:IsA("GuiButton") then
                child:Destroy()
            end
        end

        local visibleCount = 0

        for _, value in ipairs(self._state.Values) do
            if passesFilter(self, value) then
                visibleCount += 1

                local option = Instance.new("TextButton")
                option.Name = "Option"
                option.AutoButtonColor = false
                option.BackgroundColor3 = Theme["dropdown-item"]
                option.BorderSizePixel = 0
                option.Size = UDim2.new(1, 0, 0, ITEM_HEIGHT)
                option.Text = ""
                option.Parent = refs.list

                local corner = Instance.new("UICorner")
                corner.CornerRadius = UDim.new(0, 6)
                corner.Parent = option

                local fill = Instance.new("Frame")
                fill.Name = "Fill"
                fill.BackgroundColor3 = Theme.accent
                fill.BorderSizePixel = 0
                fill.Size = UDim2.fromScale(1, 1)
                fill.Parent = option

                local fillCorner = Instance.new("UICorner")
                fillCorner.CornerRadius = UDim.new(0, 6)
                fillCorner.Parent = fill

                local label = Instance.new("TextLabel")
                label.Name = "Label"
                label.BackgroundTransparency = 1
                label.BorderSizePixel = 0
                label.Position = UDim2.fromOffset(10, 0)
                label.Size = UDim2.new(1, -20, 1, 0)
                label.Font = Enum.Font.Gotham
                label.Text = value
                label.TextSize = 13
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.TextYAlignment = Enum.TextYAlignment.Center
                label.Parent = option

                updateOptionStyles(option, self._state.Multi and self._state.Value[value] or self._state.Value == value, self._state.Disabled)

                option.MouseButton1Click:Connect(function()
                    if self._destroyed or self._state.Disabled then
                        return
                    end

                    if self._state.Multi then
                        self._state.Value[value] = not self._state.Value[value] or nil
                    else
                        self._state.Value = value
                        self._state.Open = false
                    end

                    self:Refresh(self._state.Values)

                    if self._onChanged then
                        self._onChanged(self._state.Value)
                    end
                end)
            end
        end

        updateListHeight(self, visibleCount)
    end

    local function applyMetadata(self)
        local refs = self._refs
        local state = self._state

        refs.frame.Visible = state.Visible
        refs.label.Text = state.Text
        refs.valueLabel.Text = getDisplayValue(self)
        refs.valueLabel.TextColor3 = state.Disabled and Theme["text-placeholder"] or Theme["text-primary"]
        refs.arrow.Text = state.Open and "^" or "v"
        refs.arrow.TextColor3 = state.Disabled and Theme["text-placeholder"] or Theme["text-secondary"]
        refs.button.Active = not state.Disabled
        refs.button.BackgroundTransparency = state.Disabled and 0.18 or 0
        refs.menu.Visible = state.Open
        refs.search.Visible = state.Open and state.Searchable
        refs.search.Text = self._query

        rebuildOptions(self)
    end

    function Dropdown.new(parent, config)
        local refs = createDropdown(parent)
        local cfg = config or {}

        local self = setmetatable({
            Instance = refs.frame,
            Parent = parent,
            _destroyed = false,
            _onChanged = cfg.Changed or cfg.Callback,
            _query = "",
            _refs = refs,
            _state = {
                Disabled = getValue(cfg.Disabled, DEFAULTS.Disabled),
                MaxVisibleItems = math.max(1, tonumber(cfg.MaxVisibleItems) or 6),
                Multi = cfg.Multi == true,
                Open = false,
                Searchable = cfg.Searchable == true,
                Text = tostring(getValue(cfg.Text or cfg.Title, DEFAULTS.Text)),
                Value = nil,
                Values = copyValues(cfg.Values or {}),
                Visible = getValue(cfg.Visible, DEFAULTS.Visible),
            },
        }, DropdownMeta)

        self._state.Value = normalizeValue(self, cfg.Default)

        refs.button.MouseButton1Click:Connect(function()
            if self._destroyed or self._state.Disabled then
                return
            end

            self._state.Open = not self._state.Open
            applyMetadata(self)
        end)

        refs.search:GetPropertyChangedSignal("Text"):Connect(function()
            self._query = refs.search.Text
            rebuildOptions(self)
        end)

        applyMetadata(self)

        return self
    end

    function Dropdown:Set(propertyOrProperties, value)
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
                    self._state[property] = tostring(getValue(nextValue, DEFAULTS[property]))
                end
            end
        else
            ensureProperty(propertyOrProperties)
            if propertyOrProperties == "Value" then
                self._state.Value = normalizeValue(self, value)
            elseif propertyOrProperties == "Disabled" or propertyOrProperties == "Visible" then
                self._state[propertyOrProperties] = getValue(value, DEFAULTS[propertyOrProperties])
            else
                self._state[propertyOrProperties] = tostring(getValue(value, DEFAULTS[propertyOrProperties]))
            end
        end

        applyMetadata(self)

        return self
    end

    function Dropdown:Update(properties)
        return self:Set(properties)
    end

    function Dropdown:SetValue(value)
        self._state.Value = normalizeValue(self, value)
        applyMetadata(self)

        if self._onChanged then
            self._onChanged(self._state.Value)
        end

        return self
    end

    function Dropdown:Refresh(values)
        if values ~= nil then
            self._state.Values = copyValues(values)
        end

        applyMetadata(self)

        return self
    end

    function Dropdown:Open()
        self._state.Open = true
        applyMetadata(self)

        return self
    end

    function Dropdown:Close()
        self._state.Open = false
        applyMetadata(self)

        return self
    end

    function Dropdown:OnChanged(callback)
        self._onChanged = callback

        return self
    end

    function Dropdown:Destroy()
        if self._destroyed then
            return
        end

        self._destroyed = true
        self.Instance:Destroy()
    end

    function DropdownMeta.__index(self, key)
        local method = Dropdown[key]
        if method ~= nil then
            return method
        end

        local state = rawget(self, "_state")
        if state and state[key] ~= nil then
            return state[key]
        end

        return rawget(self, key)
    end

    function DropdownMeta.__newindex(self, key, value)
        if rawget(self, "_state") and LIVE_PROPERTIES[key] then
            self:Set(key, value)
            return
        end

        error(string.format("Unsupported dropdown property %q", tostring(key)))
    end

    return Dropdown
end

-- src/components/Input.lua
__modules['components/Input'] = function()
    local Theme = __require('theme/Theme')
    local Ui = __require('core/Ui')

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
end

-- src/components/KeyPicker.lua
__modules['components/KeyPicker'] = function()
    local Theme = __require('theme/Theme')
    local Keybind = __require('core/Keybind')
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
end

-- src/components/Label.lua
__modules['components/Label'] = function()
    local Theme = __require('theme/Theme')
    local ColorPicker = __require('components/ColorPicker')
    local KeyPicker = __require('components/KeyPicker')

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
end

-- src/components/Notification.lua
__modules['components/Notification'] = function()
    local Theme = __require('theme/Theme')
    local TweenService = game:GetService("TweenService")

    local Notification = {}

    local TOAST_TWEEN_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

    local function getContainer(parent)
        local existing = parent:FindFirstChild("SlateNotifications")
        if existing then
            return existing
        end

        local container = Instance.new("Frame")
        container.Name = "SlateNotifications"
        container.AnchorPoint = Vector2.new(1, 0)
        container.AutomaticSize = Enum.AutomaticSize.Y
        container.BackgroundTransparency = 1
        container.BorderSizePixel = 0
        container.Position = UDim2.new(1, -16, 0, 16)
        container.Size = UDim2.fromOffset(280, 0)
        container.ZIndex = 50
        container.Parent = parent

        local layout = Instance.new("UIListLayout")
        layout.FillDirection = Enum.FillDirection.Vertical
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
        layout.Padding = UDim.new(0, 8)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = container

        return container
    end

    function Notification.Notify(window, config)
        local root = window.Parent
        local container = getContainer(root)
        local cfg = config or {}

        local toast = Instance.new("Frame")
        toast.Name = "Toast"
        toast.AutomaticSize = Enum.AutomaticSize.Y
        toast.BackgroundColor3 = Theme["toast-bg"]
        toast.BorderSizePixel = 0
        toast.Size = UDim2.new(1, 0, 0, 0)
        toast.ZIndex = container.ZIndex
        toast.Parent = container

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = toast

        local stroke = Instance.new("UIStroke")
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Color = Theme["toast-stroke"]
        stroke.Thickness = 1
        stroke.Parent = toast

        local padding = Instance.new("UIPadding")
        padding.PaddingBottom = UDim.new(0, 10)
        padding.PaddingLeft = UDim.new(0, 12)
        padding.PaddingRight = UDim.new(0, 12)
        padding.PaddingTop = UDim.new(0, 10)
        padding.Parent = toast

        local layout = Instance.new("UIListLayout")
        layout.FillDirection = Enum.FillDirection.Vertical
        layout.Padding = UDim.new(0, 4)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = toast

        local title = Instance.new("TextLabel")
        title.Name = "Title"
        title.AutomaticSize = Enum.AutomaticSize.Y
        title.BackgroundTransparency = 1
        title.BorderSizePixel = 0
        title.Font = Enum.Font.GothamMedium
        title.Size = UDim2.new(1, 0, 0, 0)
        title.Text = tostring(cfg.Title or "Slate")
        title.TextColor3 = Theme["text-primary"]
        title.TextSize = 14
        title.TextWrapped = true
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.TextYAlignment = Enum.TextYAlignment.Top
        title.Parent = toast

        local body = Instance.new("TextLabel")
        body.Name = "Body"
        body.AutomaticSize = Enum.AutomaticSize.Y
        body.BackgroundTransparency = 1
        body.BorderSizePixel = 0
        body.Font = Enum.Font.Gotham
        body.Size = UDim2.new(1, 0, 0, 0)
        body.Text = tostring(cfg.Content or cfg.Text or "")
        body.TextColor3 = Theme["text-secondary"]
        body.TextSize = 13
        body.TextWrapped = true
        body.TextXAlignment = Enum.TextXAlignment.Left
        body.TextYAlignment = Enum.TextYAlignment.Top
        body.Parent = toast

        local accent = Instance.new("Frame")
        accent.Name = "Accent"
        accent.BackgroundColor3 = cfg.Color or Theme.accent
        accent.BorderSizePixel = 0
        accent.Position = UDim2.fromOffset(0, 0)
        accent.Size = UDim2.new(1, 0, 0, 2)
        accent.ZIndex = toast.ZIndex + 1
        accent.Parent = toast

        local lifetime = tonumber(cfg.Duration) or 4

        if window._state.Animations then
            toast.BackgroundTransparency = 1
            stroke.Transparency = 1
            title.TextTransparency = 1
            body.TextTransparency = 1
            TweenService:Create(toast, TOAST_TWEEN_INFO, {
                BackgroundTransparency = 0,
            }):Play()
            TweenService:Create(stroke, TOAST_TWEEN_INFO, {
                Transparency = 0,
            }):Play()
            TweenService:Create(title, TOAST_TWEEN_INFO, {
                TextTransparency = 0,
            }):Play()
            TweenService:Create(body, TOAST_TWEEN_INFO, {
                TextTransparency = 0,
            }):Play()
        end

        local dismissed = false

        local function dismiss()
            if dismissed then
                return
            end

            dismissed = true

            if not window._state.Animations then
                toast:Destroy()
                return
            end

            local fade = TweenService:Create(toast, TOAST_TWEEN_INFO, {
                BackgroundTransparency = 1,
            })
            TweenService:Create(stroke, TOAST_TWEEN_INFO, {
                Transparency = 1,
            }):Play()
            TweenService:Create(title, TOAST_TWEEN_INFO, {
                TextTransparency = 1,
            }):Play()
            TweenService:Create(body, TOAST_TWEEN_INFO, {
                TextTransparency = 1,
            }):Play()
            fade:Play()
            fade.Completed:Connect(function()
                toast:Destroy()
            end)
        end

        task.delay(lifetime, dismiss)

        return {
            Instance = toast,
            Destroy = dismiss,
        }
    end

    return Notification
end

-- src/components/Paragraph.lua
__modules['components/Paragraph'] = function()
    local Theme = __require('theme/Theme')

    local Paragraph = {}
    local ParagraphMeta = {}

    local LIVE_PROPERTIES = {
        Body = true,
        Title = true,
        Visible = true,
    }

    local DEFAULTS = {
        Body = "Paragraph body",
        Title = nil,
        Visible = true,
    }

    local function getValue(value, fallback)
        if value == nil then
            return fallback
        end

        return value
    end

    local function normalizePropertyValue(property, value)
        if property == "Body" then
            return tostring(getValue(value, DEFAULTS.Body))
        end

        if property == "Title" then
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

    local function createParagraph(parent)
        local frame = Instance.new("Frame")
        frame.Name = "Paragraph"
        frame.AutomaticSize = Enum.AutomaticSize.Y
        frame.BackgroundTransparency = 1
        frame.BorderSizePixel = 0
        frame.Size = UDim2.new(1, 0, 0, 0)
        frame.Parent = parent

        local layout = Instance.new("UIListLayout")
        layout.FillDirection = Enum.FillDirection.Vertical
        layout.Padding = UDim.new(0, 4)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = frame

        local title = Instance.new("TextLabel")
        title.Name = "Title"
        title.AutomaticSize = Enum.AutomaticSize.Y
        title.BackgroundTransparency = 1
        title.BorderSizePixel = 0
        title.Font = Enum.Font.GothamMedium
        title.Size = UDim2.new(1, 0, 0, 0)
        title.TextColor3 = Theme["text-primary"]
        title.TextSize = 14
        title.TextWrapped = true
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.TextYAlignment = Enum.TextYAlignment.Top
        title.Visible = false
        title.Parent = frame

        local body = Instance.new("TextLabel")
        body.Name = "Body"
        body.AutomaticSize = Enum.AutomaticSize.Y
        body.BackgroundTransparency = 1
        body.BorderSizePixel = 0
        body.Font = Enum.Font.Gotham
        body.Size = UDim2.new(1, 0, 0, 0)
        body.TextColor3 = Theme["paragraph-body"]
        body.TextSize = 13
        body.TextWrapped = true
        body.TextXAlignment = Enum.TextXAlignment.Left
        body.TextYAlignment = Enum.TextYAlignment.Top
        body.Parent = frame

        return {
            body = body,
            frame = frame,
            title = title,
        }
    end

    local function ensureProperty(property)
        assert(LIVE_PROPERTIES[property], string.format("Unsupported paragraph property %q", tostring(property)))
    end

    local function applyMetadata(self)
        local refs = self._refs
        local state = self._state

        refs.frame.Visible = state.Visible
        refs.title.Text = state.Title or ""
        refs.title.Visible = state.Title ~= nil
        refs.body.Text = state.Body
    end

    function Paragraph.new(parent, config)
        local refs = createParagraph(parent)
        local cfg = config or {}

        local self = setmetatable({
            Instance = refs.frame,
            _destroyed = false,
            _refs = refs,
            _state = {
                Body = normalizePropertyValue("Body", cfg.Body or cfg.Text or cfg.Content),
                Title = normalizePropertyValue("Title", cfg.Title),
                Visible = normalizePropertyValue("Visible", cfg.Visible),
            },
        }, ParagraphMeta)

        applyMetadata(self)

        return self
    end

    function Paragraph:Set(propertyOrProperties, value)
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

    function Paragraph:Update(properties)
        return self:Set(properties)
    end

    function Paragraph:Destroy()
        if self._destroyed then
            return
        end

        self._destroyed = true
        self.Instance:Destroy()
    end

    function ParagraphMeta.__index(self, key)
        local method = Paragraph[key]
        if method ~= nil then
            return method
        end

        local state = rawget(self, "_state")
        if state and state[key] ~= nil then
            return state[key]
        end

        return rawget(self, key)
    end

    function ParagraphMeta.__newindex(self, key, value)
        if rawget(self, "_state") and LIVE_PROPERTIES[key] then
            self:Set(key, value)
            return
        end

        error(string.format("Unsupported paragraph property %q", tostring(key)))
    end

    return Paragraph
end

-- src/components/Separator.lua
__modules['components/Separator'] = function()
    local Theme = __require('theme/Theme')

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

    return Separator
end

-- src/components/Slider.lua
__modules['components/Slider'] = function()
    local Theme = __require('theme/Theme')
    local Ui = __require('core/Ui')
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
end

-- src/components/Tag.lua
__modules['components/Tag'] = function()
    local Theme = __require('theme/Theme')

    local Tag = {}
    local TagMeta = {}

    local LIVE_PROPERTIES = {
        Text = true,
        Visible = true,
    }

    local DEFAULTS = {
        Text = "Tag",
        Visible = true,
    }

    local function getValue(value, fallback)
        if value == nil then
            return fallback
        end

        return value
    end

    local function createTag(parent)
        local frame = Instance.new("Frame")
        frame.Name = "Tag"
        frame.BackgroundTransparency = 1
        frame.BorderSizePixel = 0
        frame.Size = UDim2.new(1, 0, 0, 20)
        frame.Parent = parent

        local chip = Instance.new("Frame")
        chip.Name = "Chip"
        chip.AutomaticSize = Enum.AutomaticSize.X
        chip.BackgroundColor3 = Theme["tabbox-tab-active"]
        chip.BorderSizePixel = 0
        chip.Size = UDim2.fromOffset(0, 20)
        chip.Parent = frame

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = chip

        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = UDim.new(0, 8)
        padding.PaddingRight = UDim.new(0, 8)
        padding.Parent = chip

        local label = Instance.new("TextLabel")
        label.Name = "Label"
        label.AutomaticSize = Enum.AutomaticSize.X
        label.BackgroundTransparency = 1
        label.BorderSizePixel = 0
        label.Position = UDim2.fromOffset(0, 0)
        label.Size = UDim2.new(0, 0, 1, 0)
        label.Font = Enum.Font.GothamMedium
        label.TextColor3 = Theme.accent
        label.TextSize = 12
        label.TextXAlignment = Enum.TextXAlignment.Center
        label.TextYAlignment = Enum.TextYAlignment.Center
        label.Parent = chip

        return {
            chip = chip,
            frame = frame,
            label = label,
        }
    end

    local function applyMetadata(self)
        local refs = self._refs
        local state = self._state

        refs.frame.Visible = state.Visible
        refs.label.Text = state.Text
    end

    function Tag.new(parent, config)
        local refs = createTag(parent)
        local cfg = config or {}

        local self = setmetatable({
            Instance = refs.frame,
            _destroyed = false,
            _refs = refs,
            _state = {
                Text = tostring(getValue(cfg.Text or cfg.Title, DEFAULTS.Text)),
                Visible = getValue(cfg.Visible, DEFAULTS.Visible),
            },
        }, TagMeta)

        applyMetadata(self)

        return self
    end

    function Tag:Set(property, value)
        if self._destroyed then
            return self
        end

        self._state[property] = property == "Visible" and getValue(value, DEFAULTS.Visible) or tostring(getValue(value, DEFAULTS.Text))
        applyMetadata(self)

        return self
    end

    function Tag:Update(properties)
        for property, value in pairs(properties) do
            self:Set(property, value)
        end

        return self
    end

    function Tag:Destroy()
        if self._destroyed then
            return
        end

        self._destroyed = true
        self.Instance:Destroy()
    end

    function TagMeta.__index(self, key)
        local method = Tag[key]
        if method ~= nil then
            return method
        end

        local state = rawget(self, "_state")
        if state and state[key] ~= nil then
            return state[key]
        end

        return rawget(self, key)
    end

    return Tag
end

-- src/components/Tabbox.lua
__modules['components/Tabbox'] = function()
    local Theme = __require('theme/Theme')
    local Ui = __require('core/Ui')
    local ControlFactory = __require('core/ControlFactory')

    local Tabbox = {}
    local TabboxMeta = {}
    local TabboxPageMeta = {}

    local TAB_HEIGHT = 28
    local TAB_TWEEN_INFO = TweenInfo.new(0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

    local function createTabbox(parent)
        local frame = Instance.new("Frame")
        frame.Name = "Tabbox"
        frame.AutomaticSize = Enum.AutomaticSize.Y
        frame.BackgroundColor3 = Theme.surface
        frame.BorderSizePixel = 0
        frame.Size = UDim2.new(1, 0, 0, 0)
        frame.Parent = parent

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = frame

        local stroke = Instance.new("UIStroke")
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Color = Theme["surface-stroke"]
        stroke.Thickness = 1
        stroke.Parent = frame

        local layout = Instance.new("UIListLayout")
        layout.FillDirection = Enum.FillDirection.Vertical
        layout.Padding = UDim.new(0, 8)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = frame

        local padding = Instance.new("UIPadding")
        padding.PaddingBottom = UDim.new(0, 10)
        padding.PaddingLeft = UDim.new(0, 10)
        padding.PaddingRight = UDim.new(0, 10)
        padding.PaddingTop = UDim.new(0, 10)
        padding.Parent = frame

        local title = Instance.new("TextLabel")
        title.Name = "Title"
        title.AutomaticSize = Enum.AutomaticSize.Y
        title.BackgroundTransparency = 1
        title.BorderSizePixel = 0
        title.Font = Enum.Font.GothamMedium
        title.Size = UDim2.new(1, 0, 0, 0)
        title.TextColor3 = Theme["text-primary"]
        title.TextSize = 14
        title.TextWrapped = true
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.TextYAlignment = Enum.TextYAlignment.Top
        title.Visible = false
        title.Parent = frame

        local tabs = Instance.new("Frame")
        tabs.Name = "Tabs"
        tabs.BackgroundTransparency = 1
        tabs.BorderSizePixel = 0
        tabs.Size = UDim2.new(1, 0, 0, TAB_HEIGHT)
        tabs.Parent = frame

        local tabsLayout = Instance.new("UIListLayout")
        tabsLayout.FillDirection = Enum.FillDirection.Horizontal
        tabsLayout.Padding = UDim.new(0, 6)
        tabsLayout.SortOrder = Enum.SortOrder.LayoutOrder
        tabsLayout.Parent = tabs

        local content = Instance.new("Frame")
        content.Name = "Content"
        content.AutomaticSize = Enum.AutomaticSize.Y
        content.BackgroundTransparency = 1
        content.BorderSizePixel = 0
        content.Size = UDim2.new(1, 0, 0, 0)
        content.Parent = frame

        local contentLayout = Instance.new("UIListLayout")
        contentLayout.FillDirection = Enum.FillDirection.Vertical
        contentLayout.Padding = UDim.new(0, 8)
        contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
        contentLayout.Parent = content

        return {
            content = content,
            frame = frame,
            tabs = tabs,
            title = title,
        }
    end

    local function createTab(tabbox, title)
        local button = Instance.new("TextButton")
        button.Name = "TabButton"
        button.AutoButtonColor = false
        button.BackgroundColor3 = Theme["tabbox-tab"]
        button.BorderSizePixel = 0
        button.Size = UDim2.fromOffset(90, TAB_HEIGHT)
        button.Text = ""
        button.Parent = tabbox._refs.tabs

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = button

        local label = Instance.new("TextLabel")
        label.Name = "Label"
        label.BackgroundTransparency = 1
        label.BorderSizePixel = 0
        label.Size = UDim2.fromScale(1, 1)
        label.Font = Enum.Font.GothamMedium
        label.Text = tostring(title)
        label.TextColor3 = Theme["text-secondary"]
        label.TextSize = 13
        label.TextXAlignment = Enum.TextXAlignment.Center
        label.TextYAlignment = Enum.TextYAlignment.Center
        label.Parent = button

        local page = Instance.new("Frame")
        page.Name = "Page"
        page.AutomaticSize = Enum.AutomaticSize.Y
        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0
        page.Size = UDim2.new(1, 0, 0, 0)
        page.Visible = false
        page.Parent = tabbox._refs.content

        local pageLayout = Instance.new("UIListLayout")
        pageLayout.FillDirection = Enum.FillDirection.Vertical
        pageLayout.Padding = UDim.new(0, 6)
        pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        pageLayout.Parent = page

        return {
            button = button,
            label = label,
            page = page,
        }
    end

    local function applyTabButton(tab, instant)
        local active = tab.Active
        local background = active and Theme["tabbox-tab-active"] or Theme["tabbox-tab"]
        local textColor = active and Theme["text-primary"] or Theme["text-secondary"]

        Ui.cancel(tab._tweens.button)
        Ui.cancel(tab._tweens.label)

        if instant or not Ui.animationsEnabled(tab.Instance) then
            tab.Instance.BackgroundColor3 = background
            tab._refs.label.TextColor3 = textColor
            return
        end

        tab._tweens.button = Ui.play(tab.Instance, TAB_TWEEN_INFO, {
            BackgroundColor3 = background,
        })
        tab._tweens.label = Ui.play(tab._refs.label, TAB_TWEEN_INFO, {
            TextColor3 = textColor,
        })
    end

    function Tabbox.new(parent, config)
        local refs = createTabbox(parent)
        local cfg = config or {}

        local self = setmetatable({
            Instance = refs.frame,
            Content = refs.content,
            Controls = {},
            Parent = parent,
            Tabs = {},
            _activeTab = nil,
            _destroyed = false,
            _refs = refs,
            _state = {
                Title = cfg.Title,
                Visible = cfg.Visible ~= false,
            },
        }, TabboxMeta)

        refs.title.Text = tostring(cfg.Title or "")
        refs.title.Visible = cfg.Title ~= nil and cfg.Title ~= ""
        refs.frame.Visible = self._state.Visible

        return self
    end

    function Tabbox:AddTab(title)
        local refs = createTab(self, title)

        local page = setmetatable({
            Active = false,
            Content = refs.page,
            Controls = {},
            Instance = refs.button,
            Parent = self,
            Title = tostring(title),
            _destroyed = false,
            _refs = refs,
            _tweens = {},
        }, TabboxPageMeta)

        table.insert(self.Tabs, page)

        refs.button.MouseButton1Click:Connect(function()
            if self._destroyed or page._destroyed then
                return
            end

            self:SelectTab(page)
        end)

        if self._activeTab == nil then
            self:SelectTab(page)
        else
            applyTabButton(page, true)
        end

        return page
    end

    function Tabbox:SelectTab(tab)
        if self._destroyed or tab == nil or tab._destroyed then
            return self
        end

        self._activeTab = tab

        for _, candidate in ipairs(self.Tabs) do
            candidate.Active = candidate == tab
            candidate._refs.page.Visible = candidate.Active
            applyTabButton(candidate, false)
        end

        return self
    end

    function Tabbox:SetVisible(visible)
        self._state.Visible = visible
        self.Instance.Visible = visible

        return self
    end

    function Tabbox:Destroy()
        if self._destroyed then
            return
        end

        self._destroyed = true

        for _, tab in ipairs(self.Tabs) do
            tab:Destroy()
        end

        self.Tabs = {}
        self.Controls = {}
        self.Instance:Destroy()
    end

    function TabboxMeta.__index(self, key)
        local method = Tabbox[key]
        if method ~= nil then
            return method
        end

        local controlMethod = ControlFactory[key]
        if controlMethod ~= nil then
            return controlMethod
        end

        return rawget(self, key)
    end

    function TabboxPageMeta.__index(self, key)
        local method = TabboxPageMeta[key]
        if method ~= nil then
            return method
        end

        local factoryMethod = ControlFactory[key]
        if factoryMethod ~= nil then
            return factoryMethod
        end

        return rawget(self, key)
    end

    function TabboxPageMeta:Destroy()
        if self._destroyed then
            return
        end

        self._destroyed = true

        for _, control in ipairs(self.Controls) do
            if control.Destroy then
                control:Destroy()
            end
        end

        for _, tween in pairs(self._tweens) do
            Ui.cancel(tween)
        end

        self.Controls = {}
        self._refs.page:Destroy()
        self.Instance:Destroy()
    end

    return Tabbox
end

-- src/components/Toggle.lua
__modules['components/Toggle'] = function()
    local Theme = __require('theme/Theme')
    local Ui = __require('core/Ui')
    local ColorPicker = __require('components/ColorPicker')
    local KeyPicker = __require('components/KeyPicker')

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

        Ui.cancel(self._tweens.label)
        Ui.cancel(self._tweens.switch)
        Ui.cancel(self._tweens.stroke)
        Ui.cancel(self._tweens.dot)

        if instant or not Ui.animationsEnabled(refs.button) then
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

        self._tweens.label = Ui.play(refs.label, TOGGLE_TWEEN_INFO, {
            TextColor3 = labelColor,
            TextTransparency = labelTransparency,
        })
        self._tweens.switch = Ui.play(refs.switch, TOGGLE_TWEEN_INFO, {
            BackgroundColor3 = switchColor,
            BackgroundTransparency = switchTransparency,
        })
        self._tweens.stroke = Ui.play(refs.switchStroke, TOGGLE_TWEEN_INFO, {
            Transparency = strokeTransparency,
        })
        self._tweens.dot = Ui.play(refs.dot, TOGGLE_TWEEN_INFO, {
            BackgroundColor3 = dotColor,
            BackgroundTransparency = dotTransparency,
            Position = UDim2.fromOffset(dotOffset, SWITCH_HEIGHT / 2),
        })
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

    function Toggle:_syncAddonLayout()
        if self._destroyed then
            return self
        end

        updateLayout(self)

        return self
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
            Ui.cancel(tween)
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
end

-- src/components/Groupbox.lua
__modules['components/Groupbox'] = function()
    local Theme = __require('theme/Theme')
    local ControlFactory = __require('core/ControlFactory')

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

        titleLabel.Font = Enum.Font.GothamMedium

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

        local factoryMethod = ControlFactory[key]
        if factoryMethod ~= nil then
            return factoryMethod
        end

        return rawget(self, key)
    end

    return Groupbox
end

-- src/components/Tab.lua
__modules['components/Tab'] = function()
    local Theme = __require('theme/Theme')
    local Lucide = __require('vendor/Lucide')

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
        local transition = window and window._tabTransition
        local bootActive = boot and boot.active or false
        local bootRevealStarted = boot and boot.revealStarted or false
        local contentVisible = boot and boot.contentVisible or true
        local buttonsReady = (not bootActive and not bootRevealStarted) or self._bootVisible
        local pageReady = (not bootActive and not bootRevealStarted) or contentVisible
        local suppressIndicator = transition and transition.active and (self == transition.fromTab or self == transition.toTab)

        refs.button.LayoutOrder = state.Order
        refs.button.Visible = state.Visible and buttonsReady
        refs.button:SetAttribute("Title", state.Title)
        refs.button:SetAttribute("Icon", state.Icon)
        refs.button:SetAttribute("Active", isActive)

        refs.activeLine.Visible = isActive and not suppressIndicator
        refs.activeFill.Visible = isActive and not suppressIndicator
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

    return Tab
end

-- src/components/Window.lua
__modules['components/Window'] = function()
    local Theme = __require('theme/Theme')
    local Keybind = __require('core/Keybind')
    local Ui = __require('core/Ui')
    local Tab = __require('components/Tab')
    local Groupbox = __require('components/Groupbox')
    local Notification = __require('components/Notification')
    local Dialog = __require('components/Dialog')
    local Lighting = game:GetService("Lighting")
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
    local LOADER_PANEL_HEIGHT = 54
    local LOADER_PANEL_HORIZONTAL_INSET = 56
    local LOADER_TRACK_TOP = 8
    local LOADER_LABEL_CENTER_Y = 27
    local LOADER_BAR_TWEEN_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    local LOADER_PANEL_TWEEN_INFO = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    local WINDOW_BOOT_EXPAND_TWEEN_INFO = TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    local WINDOW_BOOT_TITLE_TWEEN_INFO = TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    local WINDOW_BOOT_SIDEBAR_TWEEN_INFO = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    local WINDOW_BOOT_TAB_TWEEN_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    local WINDOW_BOOT_CONTENT_TWEEN_INFO = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    local TAB_SWITCH_FILL_TWEEN_INFO = TweenInfo.new(0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    local TAB_SWITCH_LINE_TWEEN_INFO = TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    local WINDOW_BOOT_TAB_STAGGER = 0.055
    local WINDOW_BLUR_SIZE = 18
    local WINDOW_BLUR_TWEEN_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
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
        ToggleKeybind = "RightControl",
        BackgroundBlur = false,
        Animations = true,
        AutoShow = true,
    }

    local LIVE_PROPERTIES = {
        AutoShow = true,
        Height = true,
        Resizable = true,
        ShowSidebar = true,
        SidebarWidth = true,
        Size = true,
        ToggleKeybind = true,
        BackgroundBlur = true,
        Animations = true,
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

        if property == "ToggleKeybind" then
            return Keybind.normalize(getValue(value, DEFAULTS.ToggleKeybind))
        end

        if property == "BackgroundBlur" or property == "Animations" then
            return getValue(value, DEFAULTS[property])
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

    local function createCornerPatch(parent, name, anchorPoint, position, color, zIndex)
        local patch = Instance.new("Frame")
        patch.Name = name
        patch.AnchorPoint = anchorPoint
        patch.BackgroundColor3 = color
        patch.BorderSizePixel = 0
        patch.Position = position
        patch.Size = UDim2.fromOffset(WINDOW_CORNER_RADIUS * 2, WINDOW_CORNER_RADIUS * 2)
        patch.ZIndex = zIndex
        patch.Parent = parent

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, WINDOW_CORNER_RADIUS)
        corner.Parent = patch

        return patch
    end

    local function setInternal(self, key, value)
        rawset(self, key, value)
    end

    local function safeDisconnect(connection)
        if connection then
            connection:Disconnect()
        end
    end

    local function animationsEnabled(self)
        return self._state.Animations ~= false
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

        local titleBarCorner = Instance.new("UICorner")
        titleBarCorner.CornerRadius = UDim.new(0, WINDOW_CORNER_RADIUS)
        titleBarCorner.Parent = titleBar

        local titleBarBottomSquare = Instance.new("Frame")
        titleBarBottomSquare.Name = "BottomSquare"
        titleBarBottomSquare.BackgroundColor3 = Theme["nav-bg"]
        titleBarBottomSquare.BorderSizePixel = 0
        titleBarBottomSquare.Position = UDim2.fromOffset(0, WINDOW_CORNER_RADIUS)
        titleBarBottomSquare.Size = UDim2.new(1, 0, 1, -WINDOW_CORNER_RADIUS)
        titleBarBottomSquare.ZIndex = titleBar.ZIndex
        titleBarBottomSquare.Parent = titleBar

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

        local topLeftCorner = createCornerPatch(
            frame,
            "TopLeftCornerPatch",
            Vector2.zero,
            UDim2.fromOffset(0, 0),
            Theme["nav-bg"],
            titleBar.ZIndex + 2
        )

        local topRightCorner = createCornerPatch(
            frame,
            "TopRightCornerPatch",
            Vector2.new(1, 0),
            UDim2.new(1, 0, 0, 0),
            Theme["nav-bg"],
            titleBar.ZIndex + 2
        )

        return {
            titleBar = titleBar,
            titleBarStroke = titleBarStroke,
            titleLabel = titleLabel,
            versionLabel = versionLabel,
            accentChip = accentChip,
            accentLabel = accentLabel,
            titleBarBottomSquare = titleBarBottomSquare,
            topLeftCornerPatch = topLeftCorner,
            topRightCornerPatch = topRightCorner,
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

        local sidebarCorner = Instance.new("UICorner")
        sidebarCorner.CornerRadius = UDim.new(0, WINDOW_CORNER_RADIUS)
        sidebarCorner.Parent = sidebar

        local sidebarTopSquare = Instance.new("Frame")
        sidebarTopSquare.Name = "TopSquare"
        sidebarTopSquare.BackgroundColor3 = Theme["nav-bg"]
        sidebarTopSquare.BorderSizePixel = 0
        sidebarTopSquare.Size = UDim2.new(1, 0, 0, WINDOW_CORNER_RADIUS)
        sidebarTopSquare.ZIndex = sidebar.ZIndex
        sidebarTopSquare.Parent = sidebar

        local sidebarRightSquare = Instance.new("Frame")
        sidebarRightSquare.Name = "RightSquare"
        sidebarRightSquare.BackgroundColor3 = Theme["nav-bg"]
        sidebarRightSquare.BorderSizePixel = 0
        sidebarRightSquare.Position = UDim2.fromOffset(WINDOW_CORNER_RADIUS, 0)
        sidebarRightSquare.Size = UDim2.new(1, -WINDOW_CORNER_RADIUS, 1, 0)
        sidebarRightSquare.ZIndex = sidebar.ZIndex
        sidebarRightSquare.Parent = sidebar

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

        local tabTransitionLayer = Instance.new("Frame")
        tabTransitionLayer.Name = "TabTransition"
        tabTransitionLayer.BackgroundTransparency = 1
        tabTransitionLayer.BorderSizePixel = 0
        tabTransitionLayer.ClipsDescendants = true
        tabTransitionLayer.Size = UDim2.fromScale(1, 1)
        tabTransitionLayer.Visible = false
        tabTransitionLayer.ZIndex = sidebarTabs.ZIndex + 1
        tabTransitionLayer:SetAttribute("SlateComponent", "TabTransition")
        tabTransitionLayer.Parent = sidebar

        local tabTransitionFill = Instance.new("Frame")
        tabTransitionFill.Name = "Fill"
        tabTransitionFill.BackgroundColor3 = Theme.accent
        tabTransitionFill.BackgroundTransparency = 0.84
        tabTransitionFill.BorderSizePixel = 0
        tabTransitionFill.Visible = false
        tabTransitionFill.ZIndex = sidebar.ZIndex + 1
        tabTransitionFill.Parent = tabTransitionLayer

        local tabTransitionLine = Instance.new("Frame")
        tabTransitionLine.Name = "Line"
        tabTransitionLine.BackgroundColor3 = Theme.accent
        tabTransitionLine.BorderSizePixel = 0
        tabTransitionLine.Visible = false
        tabTransitionLine.ZIndex = sidebar.ZIndex + 2
        tabTransitionLine.Parent = tabTransitionLayer

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

        local bottomLeftCorner = createCornerPatch(
            frame,
            "BottomLeftCornerPatch",
            Vector2.new(0, 1),
            UDim2.new(0, 0, 1, 0),
            Theme["nav-bg"],
            sidebar.ZIndex + 2
        )

        local bottomRightCorner = createCornerPatch(
            frame,
            "BottomRightCornerPatch",
            Vector2.new(1, 1),
            UDim2.new(1, 0, 1, 0),
            Theme.background,
            content.ZIndex + 1
        )

        return {
            sidebar = sidebar,
            sidebarStroke = sidebarStroke,
            sidebarTabs = sidebarTabs,
            tabTransitionFill = tabTransitionFill,
            tabTransitionLayer = tabTransitionLayer,
            tabTransitionLine = tabTransitionLine,
            tabsLayout = tabsLayout,
            content = content,
            bottomLeftCornerPatch = bottomLeftCorner,
            bottomRightCornerPatch = bottomRightCorner,
            sidebarTopSquare = sidebarTopSquare,
            sidebarRightSquare = sidebarRightSquare,
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
    local applyWindowMetadata
    local applyBlurState
    local buildDefaultSettingsPanel

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

        connect(self, UserInputService.InputBegan, function(input, processed)
            if processed or self._destroyed or Keybind.isCapturing() or Ui.isTextInputFocused() then
                return
            end

            local keyName = Keybind.inputToKeyName(input)
            if keyName == nil or keyName ~= self._state.ToggleKeybind then
                return
            end

            self:Set("Visible", not self._state.Visible)
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

    local function setSelectedTab(self, targetTab)
        for _, candidate in ipairs(self._tabs) do
            candidate._state.Active = candidate == targetTab and candidate.Visible
        end
    end

    local function clearTabTransition(self)
        local transition = self._tabTransition
        local refs = self._refs

        transition.nonce += 1
        transition.active = false
        transition.fromTab = nil
        transition.toTab = nil

        refs.tabTransitionLayer.Visible = false
        refs.tabTransitionFill.Visible = false
        refs.tabTransitionLine.Visible = false
    end

    local function prepareTabTransition(self, fromTab, toTab)
        local refs = self._refs
        local fromRefs = fromTab._refs
        local toRefs = toTab._refs

        if not refs.sidebar.Visible or not fromRefs.button.Visible or not toRefs.button.Visible then
            return false
        end

        local sidebarTabsPosition = refs.tabTransitionLayer.AbsolutePosition
        local fromWidth = math.max(0, math.floor(fromRefs.button.AbsoluteSize.X + 0.5))
        local fromHeight = math.max(0, math.floor(fromRefs.button.AbsoluteSize.Y + 0.5))
        local toWidth = math.max(0, math.floor(toRefs.button.AbsoluteSize.X + 0.5))
        local toHeight = math.max(0, math.floor(toRefs.button.AbsoluteSize.Y + 0.5))

        if fromWidth == 0 or fromHeight == 0 or toWidth == 0 or toHeight == 0 then
            return false
        end

        local lineWidth = math.max(1, math.floor(fromRefs.activeLine.AbsoluteSize.X + 0.5))
        if lineWidth == 1 and fromRefs.activeLine.Size.X.Offset > 0 then
            lineWidth = math.max(1, fromRefs.activeLine.Size.X.Offset)
        end

        local fromY = math.floor((fromRefs.button.AbsolutePosition.Y - sidebarTabsPosition.Y) + 0.5)
        local toY = math.floor((toRefs.button.AbsolutePosition.Y - sidebarTabsPosition.Y) + 0.5)

        refs.tabTransitionLayer.Visible = true
        refs.tabTransitionLine.Visible = true
        refs.tabTransitionFill.Visible = true
        refs.tabTransitionLine.Position = UDim2.fromOffset(0, fromY)
        refs.tabTransitionLine.Size = UDim2.fromOffset(lineWidth, fromHeight)
        refs.tabTransitionFill.Position = UDim2.fromOffset(lineWidth, fromY)
        refs.tabTransitionFill.Size = UDim2.fromOffset(math.max(0, fromWidth - lineWidth), fromHeight)
        refs.tabTransitionFill.BackgroundTransparency = fromRefs.activeFill.BackgroundTransparency

        self._tabTransition.active = true
        self._tabTransition.fromTab = fromTab
        self._tabTransition.toTab = toTab

        return true, {
            fromHeight = fromHeight,
            lineWidth = lineWidth,
            nonce = self._tabTransition.nonce,
            toHeight = toHeight,
            toWidth = toWidth,
            toY = toY,
        }
    end

    local function playTabSwitchTransition(self, fromTab, toTab)
        if not animationsEnabled(self) then
            setSelectedTab(self, toTab)
            clearTabTransition(self)
            applyWindowMetadata(self)
            return
        end

        local prepared, transitionData = prepareTabTransition(self, fromTab, toTab)
        if not prepared then
            setSelectedTab(self, toTab)
            applyWindowMetadata(self)
            return
        end

        applyWindowMetadata(self)

        local refs = self._refs
        local fill = refs.tabTransitionFill
        local line = refs.tabTransitionLine

        local collapseTween = TweenService:Create(fill, TAB_SWITCH_FILL_TWEEN_INFO, {
            Size = UDim2.fromOffset(0, transitionData.fromHeight),
        })
        collapseTween:Play()
        collapseTween.Completed:Wait()
        if self._destroyed or self._tabTransition.nonce ~= transitionData.nonce then
            return
        end
        fill.Size = UDim2.fromOffset(0, transitionData.fromHeight)

        local lineTween = TweenService:Create(line, TAB_SWITCH_LINE_TWEEN_INFO, {
            Position = UDim2.fromOffset(0, transitionData.toY),
            Size = UDim2.fromOffset(transitionData.lineWidth, transitionData.toHeight),
        })
        lineTween:Play()
        lineTween.Completed:Wait()
        if self._destroyed or self._tabTransition.nonce ~= transitionData.nonce then
            return
        end
        line.Position = UDim2.fromOffset(0, transitionData.toY)
        line.Size = UDim2.fromOffset(transitionData.lineWidth, transitionData.toHeight)

        setSelectedTab(self, toTab)
        fill.Position = UDim2.fromOffset(transitionData.lineWidth, transitionData.toY)
        fill.Size = UDim2.fromOffset(0, transitionData.toHeight)
        applyWindowMetadata(self)

        local expandTween = TweenService:Create(fill, TAB_SWITCH_FILL_TWEEN_INFO, {
            Size = UDim2.fromOffset(math.max(0, transitionData.toWidth - transitionData.lineWidth), transitionData.toHeight),
        })
        expandTween:Play()
        expandTween.Completed:Wait()
        if self._destroyed or self._tabTransition.nonce ~= transitionData.nonce then
            return
        end
        fill.Size = UDim2.fromOffset(math.max(0, transitionData.toWidth - transitionData.lineWidth), transitionData.toHeight)

        clearTabTransition(self)
        applyWindowMetadata(self)
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

    local function advanceGroupboxDragVersion(dragState)
        -- Snap tween callbacks run asynchronously, so each drag cycle gets a unique version.
        dragState.version = (dragState.version or 0) + 1

        return dragState.version
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
        advanceGroupboxDragVersion(dragState)

        if dragState.snapConnection then
            safeDisconnect(dragState.snapConnection)
            dragState.snapConnection = nil
        end

        if dragState.snapTween then
            dragState.snapTween:Cancel()
            dragState.snapTween = nil
        end

        if dragState.placeholder then
            dragState.placeholder:Destroy()
            dragState.placeholder = nil
        end

        dragState.dragging = false
        dragState.groupbox = nil
        dragState.offset = Vector2.zero
        dragState.originalAutomaticSize = nil
        dragState.originalSize = nil
        dragState.pointer = Vector2.zero
        dragState.sourceColumn = nil
        dragState.tab = nil
        dragState.targetColumn = nil
    end

    local function finalizePendingGroupboxDrag(self)
        local dragState = self._groupboxDrag
        local groupbox = dragState.groupbox
        if not groupbox or groupbox._destroyed then
            clearGroupboxDrag(self)
            return false
        end

        local root = groupbox.Instance
        local sourceColumn = dragState.sourceColumn
        local targetColumn = dragState.targetColumn or groupbox.Column or sourceColumn
        local placeholder = dragState.placeholder
        local targetLayoutOrder = placeholder and placeholder.LayoutOrder or groupbox.LayoutOrder
        advanceGroupboxDragVersion(dragState)

        if dragState.snapConnection then
            safeDisconnect(dragState.snapConnection)
            dragState.snapConnection = nil
        end

        if dragState.snapTween then
            dragState.snapTween:Cancel()
            dragState.snapTween = nil
        end

        if root and root.Parent ~= nil and targetColumn and targetColumn.Parent ~= nil then
            if groupbox._dragging then
                setGroupboxZOffset(root, -GROUPBOX_DRAG_ZINDEX_OFFSET)
                setInternal(groupbox, "_dragging", false)
            end

            root.Parent = targetColumn
            root.AutomaticSize = dragState.originalAutomaticSize or Enum.AutomaticSize.Y
            root.Size = dragState.originalSize or UDim2.new(1, 0, 0, 0)
            root.Position = UDim2.new()
            groupbox:SetPlacement(targetColumn, targetLayoutOrder)
        end

        clearGroupboxDrag(self)

        if targetColumn and targetColumn.Parent ~= nil then
            commitColumnLayout(self, targetColumn)
        end

        if sourceColumn and sourceColumn ~= targetColumn and sourceColumn.Parent ~= nil then
            commitColumnLayout(self, sourceColumn)
        end

        return true
    end

    local function beginGroupboxDrag(self, groupbox, inputPosition)
        local dragState = self._groupboxDrag
        if dragState.dragging or self._dragging then
            return
        end

        if dragState.groupbox then
            finalizePendingGroupboxDrag(self)
        end

        local root = groupbox.Instance
        local absPos = root.AbsolutePosition
        local absSize = root.AbsoluteSize
        local rootGui = self.Parent
        local rootGuiPosition = rootGui.AbsolutePosition
        advanceGroupboxDragVersion(dragState)

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
        if not dragState.groupbox then
            return
        end

        if not dragState.dragging then
            finalizePendingGroupboxDrag(self)
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
        local dragVersion = dragState.version

        if not animationsEnabled(self) then
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

            return
        end

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
            -- Ignore completions from an older drag if the groupbox was grabbed again mid-snap.
            if dragState.version ~= dragVersion or dragState.groupbox ~= groupbox then
                return
            end

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

        if instant or not animationsEnabled(self) then
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

    local function ensureBlur(self)
        for _, child in ipairs(Lighting:GetChildren()) do
            if child:IsA("BlurEffect") and child.Name == "SlateMenuBlur" and child ~= self._blurEffect then
                child:Destroy()
            end
        end

        if self._blurEffect and self._blurEffect.Parent ~= nil then
            return self._blurEffect
        end

        local blur = Instance.new("BlurEffect")
        blur.Enabled = false
        blur.Name = "SlateMenuBlur"
        blur.Size = 0
        blur.Parent = Lighting

        setInternal(self, "_blurEffect", blur)

        return blur
    end

    applyBlurState = function(self, instant)
        local shouldBlur = self._state.Visible and self._state.BackgroundBlur
        local blur = self._blurEffect

        if not shouldBlur and blur == nil then
            setInternal(self, "_blurTargetVisible", false)
            return
        end

        if not instant and self._blurTargetVisible == shouldBlur then
            if self._blurTween ~= nil then
                return
            end

            if blur ~= nil then
                if shouldBlur and blur.Enabled and math.abs(blur.Size - WINDOW_BLUR_SIZE) < 0.01 then
                    return
                end

                if not shouldBlur and not blur.Enabled and blur.Size <= 0 then
                    return
                end
            end
        end

        blur = ensureBlur(self)

        if self._blurTween then
            self._blurTween:Cancel()
            setInternal(self, "_blurTween", nil)
        end

        if self._blurConnection then
            self._blurConnection:Disconnect()
            setInternal(self, "_blurConnection", nil)
        end

        if self._blurDriver then
            self._blurDriver:Destroy()
            setInternal(self, "_blurDriver", nil)
        end

        setInternal(self, "_blurTargetVisible", shouldBlur)
        blur.Enabled = shouldBlur or blur.Size > 0

        if instant or not animationsEnabled(self) then
            blur.Size = shouldBlur and WINDOW_BLUR_SIZE or 0
            blur.Enabled = shouldBlur
            return
        end

        local driver = Instance.new("NumberValue")
        driver.Value = blur.Size

        local connection = driver:GetPropertyChangedSignal("Value"):Connect(function()
            blur.Size = driver.Value
        end)

        blur.Enabled = true

        local tween = TweenService:Create(driver, WINDOW_BLUR_TWEEN_INFO, {
            Value = shouldBlur and WINDOW_BLUR_SIZE or 0,
        })

        setInternal(self, "_blurDriver", driver)
        setInternal(self, "_blurConnection", connection)
        setInternal(self, "_blurTween", tween)
        tween.Completed:Connect(function()
            if self._blurTween ~= tween then
                return
            end

            connection:Disconnect()
            driver:Destroy()
            setInternal(self, "_blurConnection", nil)
            setInternal(self, "_blurDriver", nil)
            setInternal(self, "_blurTween", nil)
            if not self._blurTargetVisible and blur.Parent ~= nil then
                blur.Enabled = false
                blur.Size = 0
            else
                blur.Enabled = true
                blur.Size = WINDOW_BLUR_SIZE
            end
        end)
        tween:Play()
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

        applyWindowMetadata(self)
    end

    local function hideLoaderOverlay(self)
        local boot = self._boot
        local refs = self._refs

        if not refs.loaderOverlay.Visible then
            return
        end

        if not animationsEnabled(self) then
            refs.loaderOverlay.Visible = false
            boot.loaderVisible = false
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

        if not animationsEnabled(self) then
            for _, tab in ipairs(visibleTabs) do
                tab._bootVisible = true
                tab._refs.button.Size = UDim2.new(1, 0, 0, 48)
                tab._refs.button.Visible = true
            end

            return
        end

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

        if not animationsEnabled(self) then
            self._boot.contentVisible = true
            applyWindowMetadata(self)
            return
        end

        local groupboxStates = {}

        for _, groupbox in ipairs(activeTab._groupboxes or {}) do
            if not groupbox._destroyed and groupbox.Instance and groupbox.Instance.Parent ~= nil then
                table.insert(groupboxStates, captureTransparencyState(groupbox.Instance))
            end
        end

        self._boot.contentVisible = true
        applyWindowMetadata(self)

        if not activeTab.Page.Visible then
            return
        end

        for _, groupboxState in ipairs(groupboxStates) do
            applyTransparencyAlpha(groupboxState, 1)
        end

        for _, groupboxState in ipairs(groupboxStates) do
            tweenTransparencyAlpha(groupboxState, 1, 0, WINDOW_BOOT_CONTENT_TWEEN_INFO, false)
        end
    end

    local function playBootReveal(self)
        local boot = self._boot
        local refs = self._refs
        local state = self._state

        if not animationsEnabled(self) then
            forceBootVisible(self)
            return
        end

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
        applyWindowMetadata(self)
        revealTabs(self)
        revealActivePage(self)
        boot.revealStarted = false
        boot.contentVisible = true
        refs.content.Visible = true
        refs.sidebar.Visible = state.ShowSidebar and boot.sidebarVisible
        refs.titleBar.Visible = true
        applyWindowMetadata(self)
    end

    applyWindowMetadata = function(self)
        local state = self._state
        local refs = self._refs
        local boot = self._boot
        local renderSize = boot.active and boot.compactSize or state.Size
        local shellReady = (not boot.active) and (not boot.revealStarted)
        local sidebarReady = (state.ShowSidebar and boot.sidebarVisible) or (shellReady and state.ShowSidebar)
        local contentReady = boot.contentVisible or shellReady
        local titleBarVisible = boot.titleBarVisible or shellReady

        self.Instance.Size = renderSize
        self.Instance.Visible = state.Visible
        self.Instance:SetAttribute("Title", state.Title)
        self.Instance:SetAttribute("Version", state.Version)
        self.Instance:SetAttribute("Resizable", state.Resizable)
        self.Instance:SetAttribute("SidebarWidth", state.SidebarWidth)
        self.Instance:SetAttribute("ShowSidebar", state.ShowSidebar)
        self.Instance:SetAttribute("ToggleKeybind", state.ToggleKeybind)
        self.Instance:SetAttribute("BackgroundBlur", state.BackgroundBlur)
        self.Instance:SetAttribute("SlateAnimationsEnabled", state.Animations)

        refs.titleBar.BackgroundColor3 = Theme["nav-bg"]
        refs.titleBarStroke.Color = Theme["nav-stroke"]
        refs.titleBarStroke.Thickness = TITLE_BAR_STROKE
        refs.titleBarBottomSquare.BackgroundColor3 = Theme["nav-bg"]
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
        refs.tabTransitionLayer.Visible = self._tabTransition.active
        refs.tabTransitionFill.BackgroundColor3 = Theme.accent
        refs.tabTransitionLine.BackgroundColor3 = Theme.accent

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

            Ui.play(refs.accentChip, CHIP_TWEEN_INFO, {
                Size = UDim2.fromOffset(targetWidth, CHIP_HEIGHT)
            })
        end
        refs.sidebar.BackgroundColor3 = Theme["nav-bg"]
        refs.sidebar.Size = UDim2.new(0, state.SidebarWidth, 1, -TITLE_BAR_HEIGHT)
        refs.sidebar.Visible = sidebarReady
        refs.sidebarStroke.Color = Theme["nav-stroke"]
        refs.sidebarStroke.Thickness = SIDEBAR_STROKE
        refs.sidebarTopSquare.BackgroundColor3 = Theme["nav-bg"]
        refs.sidebarRightSquare.BackgroundColor3 = Theme["nav-bg"]
        refs.content.Position = UDim2.fromOffset(state.ShowSidebar and state.SidebarWidth or 0, TITLE_BAR_HEIGHT)
        refs.content.Size = UDim2.new(1, -(state.ShowSidebar and state.SidebarWidth or 0), 1, -TITLE_BAR_HEIGHT)
        refs.content.Visible = contentReady
        refs.topLeftCornerPatch.BackgroundColor3 = Theme["nav-bg"]
        refs.topLeftCornerPatch.Visible = false
        refs.topRightCornerPatch.BackgroundColor3 = Theme["nav-bg"]
        refs.topRightCornerPatch.Visible = false
        refs.bottomLeftCornerPatch.BackgroundColor3 = state.ShowSidebar and Theme["nav-bg"] or Theme.background
        refs.bottomLeftCornerPatch.Visible = false
        refs.bottomRightCornerPatch.BackgroundColor3 = Theme.background
        refs.bottomRightCornerPatch.Visible = false
        refs.cursorHorizontal.BackgroundColor3 = Theme.accent
        refs.cursorVertical.BackgroundColor3 = Theme.accent
        refs.titleBar.Visible = titleBarVisible

        applyBlurState(self, false)

        for _, tab in ipairs(self._tabs) do
            Tab._applyMetadata(tab)
        end
    end

    buildDefaultSettingsPanel = function(self, settingsTab)
        if self._settingsBuilt or settingsTab == nil then
            return
        end

        setInternal(self, "_settingsBuilt", true)

        local settingsGroup = settingsTab:AddGroupbox("leftColumn", {
            Title = "Preferences",
        })

        local keybindLabel = settingsGroup:AddLabel("Show/Hide Keybind")
        local keybindPicker = keybindLabel:AddKeyPicker({
            Default = self._state.ToggleKeybind,
            Changed = function(value)
                self:Set("ToggleKeybind", value)
            end,
        })

        local blurToggle = settingsGroup:AddToggle({
            Text = "Background Blur",
            Default = self._state.BackgroundBlur,
            Changed = function(value)
                self:Set("BackgroundBlur", value)
            end,
        })

        settingsGroup:AddDivider()

        local animationToggle = settingsGroup:AddToggle({
            Text = "Animations",
            Default = self._state.Animations,
            Changed = function(value)
                self:Set("Animations", value)
            end,
        })

        setInternal(self, "_settingsControls", {
            animationToggle = animationToggle,
            blurToggle = blurToggle,
            keybindLabel = keybindLabel,
            keybindPicker = keybindPicker,
            settingsGroup = settingsGroup,
        })
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
            ToggleKeybind = normalizePropertyValue("ToggleKeybind", config.ToggleKeybind or config.ShowHideKeybind),
            BackgroundBlur = normalizePropertyValue("BackgroundBlur", config.BackgroundBlur),
            Animations = normalizePropertyValue("Animations", config.Animations),
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
            _blurEffect = nil,
            _blurConnection = nil,
            _blurDriver = nil,
            _blurTargetVisible = false,
            _blurTween = nil,
            _connections = {},
            _cursorVisible = false,
            _dragging = false,
            _destroyed = false,
            _groupboxes = {},
            _groupboxConnections = {},
            _settingsBuilt = false,
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
                version = 0,
            },
            _boot = createBootState(state.Size),
            _refs = refs,
            _state = state,
            _tabTransition = {
                active = false,
                fromTab = nil,
                nonce = 0,
                toTab = nil,
            },
            _tabs = {},
        }, WindowMeta)

        applyWindowMetadata(self)
        setLoaderProgress(self, 0.08, "Preparing Slate...", true)
        attachInteractions(self)
        local settingsTab = Window.AddTab(self, {
            Title = "Settings",
            Icon = "settings",
            LayoutColumns = 2,
            Order = 9999,
        })
        buildDefaultSettingsPanel(self, settingsTab)
        setLoaderProgress(self, LOADER_BASE_PROGRESS, "Slate ready", false)

        if state.Animations then
            scheduleAutoFinish(self)
        else
            forceBootVisible(self)
        end

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

        applyWindowMetadata(self)

        local settingsControls = self._settingsControls
        if settingsControls then
            if settingsControls.keybindPicker then
                settingsControls.keybindPicker:SetValue(self._state.ToggleKeybind)
            end

            if settingsControls.blurToggle then
                settingsControls.blurToggle:SetValue(self._state.BackgroundBlur)
            end

            if settingsControls.animationToggle then
                settingsControls.animationToggle:SetValue(self._state.Animations)
            end
        end

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

    function Window:ToggleVisibility()
        return self:Set("Visible", not self._state.Visible)
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

    function Window:SetShowHideKeybind(key)
        return self:Set("ToggleKeybind", key)
    end

    function Window:SetBackgroundBlurEnabled(enabled: boolean)
        return self:Set("BackgroundBlur", enabled)
    end

    function Window:SetAnimationsEnabled(enabled: boolean)
        return self:Set("Animations", enabled)
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

    function Window:Notify(config)
        return Notification.Notify(self, config or {})
    end

    function Window:Dialog(config)
        return Dialog.Open(self, config or {})
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

        if not animationsEnabled(self) then
            setLoaderProgress(self, 1, text or "Ready", true)
            forceBootVisible(self)
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

        if string.lower(tab.Title) == "settings" then
            buildDefaultSettingsPanel(self, tab)
        end

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
        if self._destroyed or tab._destroyed or not tab.Visible then
            return self
        end

        if self._tabTransition.active then
            clearTabTransition(self)
        end

        local currentTab = getActiveTab(self)
        if currentTab == tab then
            applyWindowMetadata(self)
            return self
        end

        if currentTab == nil or self._boot.active or self._boot.revealStarted then
            setSelectedTab(self, tab)
            applyWindowMetadata(self)
            return self
        end

        playTabSwitchTransition(self, currentTab, tab)

        return self
    end

    function Window:_reconcileTabs(preferredTab)
        if self._tabTransition.active then
            clearTabTransition(self)
        end

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

        applyWindowMetadata(self)
    end

    function Window:_removeTab(tab)
        local nextTabs = {}

        for _, candidate in ipairs(self._tabs) do
            if candidate ~= tab then
                table.insert(nextTabs, candidate)
            end
        end

        self.Tabs[tab.Title] = nil
        setInternal(self, "_tabs", nextTabs)
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

        setInternal(self, "_groupboxes", remaining)
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

        if self._groupboxDrag.groupbox then
            clearGroupboxDrag(self)
        end

        for _, connection in pairs(self._groupboxConnections) do
            safeDisconnect(connection)
        end

        setInternal(self, "_groupboxConnections", {})
        setInternal(self, "_groupboxes", {})
        setInternal(self, "_tabs", {})
        self.Tabs = {}

        for _, connection in ipairs(self._connections) do
            connection:Disconnect()
        end

        setInternal(self, "_connections", {})

        if self._blurTween then
            self._blurTween:Cancel()
            setInternal(self, "_blurTween", nil)
        end

        if self._blurConnection then
            self._blurConnection:Disconnect()
            setInternal(self, "_blurConnection", nil)
        end

        if self._blurDriver then
            self._blurDriver:Destroy()
            setInternal(self, "_blurDriver", nil)
        end

        if self._blurEffect then
            self._blurEffect:Destroy()
            setInternal(self, "_blurEffect", nil)
        end

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

    return Window
end

-- src/init.lua
__modules['init'] = function()
    local Theme = __require('theme/Theme')
    local Button = __require('components/Button')
    local Checkbox = __require('components/Checkbox')
    local Code = __require('components/Code')
    local ColorPicker = __require('components/ColorPicker')
    local Dialog = __require('components/Dialog')
    local Dropdown = __require('components/Dropdown')
    local Root = __require('core/Root')
    local Input = __require('components/Input')
    local Notification = __require('components/Notification')
    local Paragraph = __require('components/Paragraph')
    local Slider = __require('components/Slider')
    local Tag = __require('components/Tag')
    local Tabbox = __require('components/Tabbox')
    local Window = __require('components/Window')
    local Divider = __require('components/Divider')
    local Groupbox = __require('components/Groupbox')
    local KeyPicker = __require('components/KeyPicker')
    local Label = __require('components/Label')
    local Separator = __require('components/Separator')
    local Toggle = __require('components/Toggle')

    local Slate = {}

    local getGlobalEnvironment = getgenv or function()
        return _G
    end

    local runtime = getGlobalEnvironment()
    runtime.__SlateMountedWindows = runtime.__SlateMountedWindows or {}

    local mountedWindows = runtime.__SlateMountedWindows

    Slate.Theme = Theme
    Slate.Button = Button
    Slate.Checkbox = Checkbox
    Slate.Code = Code
    Slate.ColorPicker = ColorPicker
    Slate.Dialog = Dialog
    Slate.Divider = Divider
    Slate.Dropdown = Dropdown
    Slate.Groupbox = Groupbox
    Slate.Input = Input
    Slate.KeyPicker = KeyPicker
    Slate.Label = Label
    Slate.Notification = Notification
    Slate.Paragraph = Paragraph
    Slate.Separator = Separator
    Slate.Slider = Slider
    Slate.Tag = Tag
    Slate.Tabbox = Tabbox
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
end

return __require('init')
