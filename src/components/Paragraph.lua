local Theme = require(script.Parent.Parent.theme.Theme)

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
