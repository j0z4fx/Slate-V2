local Slate = {}

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

local protectGui = protectgui or (syn and syn.protect_gui) or function() end
local getHiddenUi = gethui
local ROOT_NAME = "Slate"
local ROOT_ATTRIBUTE = "SlateOwned"

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

local function normalizePropertyValue(property, value)
    if property == "Title" then
        return getValue(value, DEFAULTS.Title)
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

local function resolveContainer()
    if typeof(getHiddenUi) == "function" then
        local success, hiddenUi = pcall(getHiddenUi)
        if success and typeof(hiddenUi) == "Instance" then
            return hiddenUi
        end
    end

    local localPlayer = Players.LocalPlayer
    if RunService:IsStudio() and localPlayer then
        local playerGui = localPlayer:FindFirstChildOfClass("PlayerGui") or localPlayer:WaitForChild("PlayerGui")
        if playerGui then
            return playerGui
        end
    end

    return CoreGui
end

local function findOwnedRoot(container)
    for _, child in ipairs(container:GetChildren()) do
        if child.Name == ROOT_NAME and child:GetAttribute(ROOT_ATTRIBUTE) then
            return child
        end
    end

    return nil
end

local function getOrCreateRoot()
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

local function getExistingRoot()
    local container = resolveContainer()

    return findOwnedRoot(container)
end

local Window = {}
local WindowMeta = {}

local LIVE_PROPERTIES = {
    AutoShow = true,
    Height = true,
    Resizable = true,
    ShowSidebar = true,
    SidebarWidth = true,
    Size = true,
    Title = true,
    Visible = true,
    Width = true,
}

local function resolveSize(config)
    if typeof(config.Size) == "UDim2" then
        return config.Size
    end

    local width = getValue(config.Width, DEFAULTS.Width)
    local height = getValue(config.Height, DEFAULTS.Height)

    return UDim2.fromOffset(width, height)
end

local function applyMetadata(self)
    local state = self._state

    self.Instance.Size = state.Size
    self.Instance.Visible = state.Visible
    self.Instance:SetAttribute("Title", state.Title)
    self.Instance:SetAttribute("Resizable", state.Resizable)
    self.Instance:SetAttribute("SidebarWidth", state.SidebarWidth)
    self.Instance:SetAttribute("ShowSidebar", state.ShowSidebar)
end

local function createState(config)
    local size = resolveSize(config)
    local visible = getValue(config.AutoShow, DEFAULTS.AutoShow)

    return {
        Title = getValue(config.Title, DEFAULTS.Title),
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
    return self:Set("Visible", true)
end

function Window:Hide()
    return self:Set("Visible", false)
end

function Window:SetTitle(title)
    return self:Set("Title", title)
end

function Window:SetResizable(resizable)
    return self:Set("Resizable", resizable)
end

function Window:SetSidebarWidth(sidebarWidth)
    return self:Set("SidebarWidth", sidebarWidth)
end

function Window:SetSidebarVisible(showSidebar)
    return self:Set("ShowSidebar", showSidebar)
end

function Window:SetSize(size)
    return self:Set("Size", size)
end

function Window:Destroy()
    if self._destroyed then
        return
    end

    self._destroyed = true
    self.Instance:Destroy()
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

function Slate:CreateWindow(config)
    local windowConfig = normalizeWindowConfig(self, config)
    local target = windowConfig.Parent or getOrCreateRoot()
    local frame = Instance.new("Frame")
    frame.Name = "Window"
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Position = UDim2.fromScale(0.5, 0.5)
    frame.BackgroundColor3 = Slate.Theme.background
    frame.Active = true
    frame.BorderSizePixel = 0
    frame.ClipsDescendants = true
    frame.ZIndex = 1
    frame:SetAttribute("SlateComponent", "Window")
    frame.Parent = target

    local window = setmetatable({
        Instance = frame,
        Parent = target,
        _destroyed = false,
        _state = createState(windowConfig),
    }, WindowMeta)

    applyMetadata(window)

    return window
end

function Slate:Destroy()
    local existing = getExistingRoot()
    if existing then
        existing:Destroy()
    end
end

return Slate
