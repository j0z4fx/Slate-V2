local Theme = require(script.Parent.Parent.theme.Theme)

local Window = {}
Window.__index = Window

local DEFAULTS = {
    Title = "Slate",
    Width = 960,
    Height = 540,
    Resizable = true,
    SidebarWidth = 220,
    ShowSidebar = true,
    AutoShow = true,
}

local function resolveSize(config)
    if typeof(config.Size) == "UDim2" then
        return config.Size
    end

    local width = config.Width or DEFAULTS.Width
    local height = config.Height or DEFAULTS.Height

    return UDim2.fromOffset(width, height)
end

local function applyMetadata(self)
    self.Instance.Size = self.Size
    self.Instance.Visible = self.Visible
    self.Instance:SetAttribute("Title", self.Title)
    self.Instance:SetAttribute("Resizable", self.Resizable)
    self.Instance:SetAttribute("SidebarWidth", self.SidebarWidth)
    self.Instance:SetAttribute("ShowSidebar", self.ShowSidebar)
end

function Window.new(parent: Instance, config)
    local frame = Instance.new("Frame")
    frame.Name = "Window"
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Position = UDim2.fromScale(0.5, 0.5)
    frame.BackgroundColor3 = Theme.background
    frame.BorderSizePixel = 0
    frame.Parent = parent

    local self = setmetatable({
        Instance = frame,
        Parent = parent,
        Title = config.Title or DEFAULTS.Title,
        Size = resolveSize(config),
        Resizable = if config.Resizable == nil then DEFAULTS.Resizable else config.Resizable,
        SidebarWidth = config.SidebarWidth or DEFAULTS.SidebarWidth,
        ShowSidebar = if config.ShowSidebar == nil then DEFAULTS.ShowSidebar else config.ShowSidebar,
        Visible = if config.AutoShow == nil then DEFAULTS.AutoShow else config.AutoShow,
    }, Window)

    applyMetadata(self)

    return self
end

function Window:Show()
    self.Visible = true
    applyMetadata(self)

    return self
end

function Window:Hide()
    self.Visible = false
    applyMetadata(self)

    return self
end

function Window:SetTitle(title: string)
    self.Title = title
    applyMetadata(self)

    return self
end

function Window:SetResizable(resizable: boolean)
    self.Resizable = resizable
    applyMetadata(self)

    return self
end

function Window:SetSidebarWidth(sidebarWidth: number)
    self.SidebarWidth = sidebarWidth
    applyMetadata(self)

    return self
end

function Window:SetSidebarVisible(showSidebar: boolean)
    self.ShowSidebar = showSidebar
    applyMetadata(self)

    return self
end

function Window:SetSize(size)
    if typeof(size) == "UDim2" then
        self.Size = size
    else
        self.Size = UDim2.fromOffset(size.Width or DEFAULTS.Width, size.Height or DEFAULTS.Height)
    end

    applyMetadata(self)

    return self
end

function Window:Destroy()
    self.Instance:Destroy()
end

return Window
