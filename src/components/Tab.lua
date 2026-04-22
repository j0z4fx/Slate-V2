local Theme = require(script.Parent.Parent.theme.Theme)
local Lucide = require(script.Parent.Parent.vendor.Lucide)

local Tab = {}
local TabMeta = {}

local ACTIVE_FILL_TRANSPARENCY = 0.84
local ACTIVE_ICON_TRANSPARENCY = 0.1
local ACTIVE_LINE_WIDTH = 3
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
    local isActive = state.Active and state.Visible

    refs.button.LayoutOrder = state.Order
    refs.button.Visible = state.Visible
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

    refs.page.Visible = isActive
end

local function applyProperty(self, property, value)
    ensureProperty(property)
    self._state[property] = normalizePropertyValue(property, value)
end

function Tab.new(window, config, order)
    local refs = createButton(window, order)

    local self = setmetatable({
        Window = window,
        Instance = refs.button,
        Page = refs.page,
        _destroyed = false,
        _refs = refs,
        _state = {
            Active = normalizePropertyValue("Active", config.Active),
            Icon = normalizePropertyValue("Icon", config.Icon),
            Order = normalizePropertyValue("Order", config.Order or order),
            Title = normalizePropertyValue("Title", config.Title or config.Id or config.Name),
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

function Tab:Destroy()
    if self._destroyed then
        return
    end

    self._destroyed = true
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
