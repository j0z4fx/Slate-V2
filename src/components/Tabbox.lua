local Theme = require(script.Parent.Parent.theme.Theme)
local Ui = require(script.Parent.Parent.core.Ui)
local ControlFactory = require(script.Parent.Parent.core.ControlFactory)

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
