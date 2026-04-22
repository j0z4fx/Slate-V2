local Theme = require(script.Parent.Parent.theme.Theme)

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
