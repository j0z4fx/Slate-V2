local Theme = require(script.Parent.Parent.theme.Theme)
local Ui = require(script.Parent.Parent.core.Ui)

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
