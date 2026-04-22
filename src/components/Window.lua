local Theme = require(script.Parent.Parent.theme.Theme)
local Tab = require(script.Parent.Tab)
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
local DEFAULT_SIDEBAR_WIDTH = math.floor((48 * 1.15) + 0.5)
local COLUMN_GAP = 8
local COLUMN_OFFSET = -math.floor(2 * COLUMN_GAP / 3)
local CONTENT_PADDING = 6
local FADE_HEIGHT = 20

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

local function createCursor(frame: Frame)
    local cursor = Instance.new("Frame")
    cursor.Name = "Cursor"
    cursor.AnchorPoint = Vector2.new(0.5, 0.5)
    cursor.BackgroundTransparency = 1
    cursor.BorderSizePixel = 0
    cursor.Size = UDim2.fromOffset(CURSOR_SIZE, CURSOR_SIZE)
    cursor.Visible = false
    cursor.ZIndex = frame.ZIndex + 10
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

local function createTabContent(content)
    local tabContent = Instance.new("Frame")
    tabContent.Name = "tabContent"
    tabContent.BackgroundTransparency = 1
    tabContent.BorderSizePixel = 0
    tabContent.Size = UDim2.fromScale(1, 1)
    tabContent.ZIndex = content.ZIndex
    tabContent.Parent = content

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, COLUMN_GAP)
    padding.PaddingRight = UDim.new(0, COLUMN_GAP)
    padding.PaddingTop = UDim.new(0, COLUMN_GAP)
    padding.Parent = tabContent

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.Padding = UDim.new(0, COLUMN_GAP)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = tabContent

    local function makeColumn(name, order)
        local col = Instance.new("Frame")
        col.Name = name
        col.BackgroundTransparency = 1
        col.BorderSizePixel = 0
        col.LayoutOrder = order
        col.Size = UDim2.new(1 / 3, COLUMN_OFFSET, 1, 0)
        col.ZIndex = tabContent.ZIndex + 1
        col.Parent = tabContent

        createColumnFade(col, col.ZIndex)

        return col
    end

    return {
        tabContent = tabContent,
        leftColumn = makeColumn("leftColumn", 1),
        middleColumn = makeColumn("middleColumn", 2),
        rightColumn = makeColumn("rightColumn", 3),
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

local function applyMetadata(self)
    local state = self._state
    local refs = self._refs

    self.Instance.Size = state.Size
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
    refs.sidebar.Visible = state.ShowSidebar
    refs.sidebarStroke.Color = Theme["nav-stroke"]
    refs.sidebarStroke.Thickness = SIDEBAR_STROKE
    refs.content.Position = UDim2.fromOffset(state.ShowSidebar and state.SidebarWidth or 0, TITLE_BAR_HEIGHT)
    refs.content.Size = UDim2.new(1, -(state.ShowSidebar and state.SidebarWidth or 0), 1, -TITLE_BAR_HEIGHT)
    refs.cursorHorizontal.BackgroundColor3 = Theme.accent
    refs.cursorVertical.BackgroundColor3 = Theme.accent

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

        return
    end

    local width = getValue(size.Width, state.Width)
    local height = getValue(size.Height, state.Height)

    state.Width = width
    state.Height = height
    state.Size = UDim2.fromOffset(width, height)
end

local function updateWidth(self, width)
    local state = self._state

    state.Width = width
    state.Size = UDim2.new(state.Size.X.Scale, width, state.Size.Y.Scale, state.Size.Y.Offset)
end

local function updateHeight(self, height)
    local state = self._state

    state.Height = height
    state.Size = UDim2.new(state.Size.X.Scale, state.Size.X.Offset, state.Size.Y.Scale, height)
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

    local refs = createTitleBar(frame)
    for key, value in pairs(createSidebar(frame)) do
        refs[key] = value
    end
    for key, value in pairs(createCursor(frame)) do
        refs[key] = value
    end
    for key, value in pairs(createTabContent(refs.content)) do
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
        _refs = refs,
        _state = createState(config),
        _tabs = {},
    }, WindowMeta)

    applyMetadata(self)
    attachInteractions(self)

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

function Window:AddTab(config)
    local tabConfig = config or {}
    local tab = Tab.new(self, tabConfig, #self._tabs + 1)

    table.insert(self._tabs, tab)
    self.Tabs[tab.Title] = tab
    self:_reconcileTabs(tabConfig.Active and tab or nil)

    return tab
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

return Window
