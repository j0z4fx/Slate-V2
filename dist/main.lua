local Slate = {}

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

local protectGui = protectgui or (syn and syn.protect_gui) or function() end
local getHiddenUi = gethui

Slate.Theme = {
    background = Color3.fromRGB(15, 15, 24),
}

local DEFAULTS = {
    Title = "Slate",
    Width = 960,
    Height = 540,
    Resizable = true,
    SidebarWidth = 220,
    ShowSidebar = true,
    AutoShow = true,
}

local function getValue(value, fallback)
    if value == nil then
        return fallback
    end

    return value
end

local function getOrCreateRoot()
    local container = nil

    if typeof(getHiddenUi) == "function" then
        local success, hiddenUi = pcall(getHiddenUi)
        if success and typeof(hiddenUi) == "Instance" then
            container = hiddenUi
        end
    end

    if not container then
        local localPlayer = Players.LocalPlayer
        if RunService:IsStudio() and localPlayer then
            container = localPlayer:FindFirstChildOfClass("PlayerGui") or localPlayer:WaitForChild("PlayerGui")
        else
            container = CoreGui
        end
    end

    local existing = container:FindFirstChild("Slate")
    if existing then
        existing:Destroy()
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "Slate"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true

    pcall(protectGui, screenGui)
    screenGui.Parent = container

    return screenGui
end

local Window = {}
Window.__index = Window

local function resolveSize(config)
    if typeof(config.Size) == "UDim2" then
        return config.Size
    end

    local width = getValue(config.Width, DEFAULTS.Width)
    local height = getValue(config.Height, DEFAULTS.Height)

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

local function normalizeWindowConfig(selfOrConfig, config)
    if selfOrConfig == Slate then
        return config or {}
    end

    if type(selfOrConfig) == "table" then
        return selfOrConfig
    end

    return {}
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

function Window:SetTitle(title)
    self.Title = title
    applyMetadata(self)

    return self
end

function Window:SetResizable(resizable)
    self.Resizable = resizable
    applyMetadata(self)

    return self
end

function Window:SetSidebarWidth(sidebarWidth)
    self.SidebarWidth = sidebarWidth
    applyMetadata(self)

    return self
end

function Window:SetSidebarVisible(showSidebar)
    self.ShowSidebar = showSidebar
    applyMetadata(self)

    return self
end

function Window:SetSize(size)
    if typeof(size) == "UDim2" then
        self.Size = size
    else
        self.Size = UDim2.fromOffset(getValue(size.Width, DEFAULTS.Width), getValue(size.Height, DEFAULTS.Height))
    end

    applyMetadata(self)

    return self
end

function Window:Destroy()
    self.Instance:Destroy()
end

function Slate:CreateWindow(config)
    local windowConfig = normalizeWindowConfig(self, config)
    local target = windowConfig.Parent or getOrCreateRoot()
    local frame = Instance.new("Frame")
    frame.Name = "Window"
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Position = UDim2.fromScale(0.5, 0.5)
    frame.BackgroundColor3 = Slate.Theme.background
    frame.BorderSizePixel = 0
    frame.Parent = target

    local window = setmetatable({
        Instance = frame,
        Parent = target,
        Title = getValue(windowConfig.Title, DEFAULTS.Title),
        Size = resolveSize(windowConfig),
        Resizable = getValue(windowConfig.Resizable, DEFAULTS.Resizable),
        SidebarWidth = getValue(windowConfig.SidebarWidth, DEFAULTS.SidebarWidth),
        ShowSidebar = getValue(windowConfig.ShowSidebar, DEFAULTS.ShowSidebar),
        Visible = getValue(windowConfig.AutoShow, DEFAULTS.AutoShow),
    }, Window)

    applyMetadata(window)

    return window
end

return Slate
