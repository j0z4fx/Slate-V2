local Theme = require(script.Parent.Parent.theme.Theme)
local Tab = require(script.Parent.Tab)
local Groupbox = require(script.Parent.Groupbox)
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

    local groupboxStates = {}

    for _, groupbox in ipairs(activeTab._groupboxes or {}) do
        if not groupbox._destroyed and groupbox.Instance and groupbox.Instance.Parent ~= nil then
            table.insert(groupboxStates, captureTransparencyState(groupbox.Instance))
        end
    end

    self._boot.contentVisible = true
    applyMetadata(self)

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

return Window
