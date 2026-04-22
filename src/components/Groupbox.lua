local Theme = require(script.Parent.Parent.theme.Theme)
local ControlFactory = require(script.Parent.Parent.core.ControlFactory)

local Groupbox = {}
local GroupboxMeta = {}

local TITLE_HEIGHT = 26
local TITLE_FONT_SIZE = 19
local TITLE_COLOR = Color3.fromRGB(94, 94, 126)
local CORNER_RADIUS = 6
local STROKE_THICKNESS = 1
local CONTENT_GAP = 6
local GROUPBOX_ROOT_SIZE = UDim2.new(1, 0, 0, 0)
local GROUPBOX_ROOT_POSITION = UDim2.new()

local function applyRootLayout(frame)
    frame.AnchorPoint = Vector2.zero
    frame.AutomaticSize = Enum.AutomaticSize.Y
    frame.Position = GROUPBOX_ROOT_POSITION
    frame.Size = GROUPBOX_ROOT_SIZE
end

local function createGroupbox(parent)
    local frame = Instance.new("Frame")
    frame.Name = "Groupbox"
    frame.BackgroundColor3 = Theme.surface
    frame.BorderSizePixel = 0
    frame:SetAttribute("SlateComponent", "Groupbox")
    applyRootLayout(frame)
    frame.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, CORNER_RADIUS)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Color = Theme["surface-stroke"]
    stroke.Thickness = STROKE_THICKNESS
    stroke.Parent = frame

    local frameLayout = Instance.new("UIListLayout")
    frameLayout.FillDirection = Enum.FillDirection.Vertical
    frameLayout.Padding = UDim.new(0, 0)
    frameLayout.SortOrder = Enum.SortOrder.LayoutOrder
    frameLayout.Parent = frame

    -- Title bar (UICorner matches frame so top corners render correctly)
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Active = true
    titleBar.BackgroundColor3 = Theme.surface
    titleBar.BorderSizePixel = 0
    titleBar.LayoutOrder = 1
    titleBar.Size = UDim2.new(1, 0, 0, TITLE_HEIGHT)
    titleBar.ZIndex = frame.ZIndex + 1
    titleBar.Parent = frame

    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, CORNER_RADIUS)
    titleCorner.Parent = titleBar

    local titlePadding = Instance.new("UIPadding")
    titlePadding.PaddingTop = UDim.new(0, 7)
    titlePadding.PaddingBottom = UDim.new(0, 6)
    titlePadding.Parent = titleBar

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.BackgroundTransparency = 1
    titleLabel.BorderSizePixel = 0
    titleLabel.Size = UDim2.new(1, 0, 1, 0)
    titleLabel.TextColor3 = TITLE_COLOR
    titleLabel.TextSize = TITLE_FONT_SIZE
    titleLabel.TextScaled = false
    titleLabel.TextXAlignment = Enum.TextXAlignment.Center
    titleLabel.TextYAlignment = Enum.TextYAlignment.Center
    titleLabel.ZIndex = titleBar.ZIndex + 1
    titleLabel.Parent = titleBar

    titleLabel.Font = Enum.Font.GothamMedium

    local separator = Instance.new("Frame")
    separator.Name = "Separator"
    separator.BackgroundColor3 = Theme["surface-stroke"]
    separator.BorderSizePixel = 0
    separator.LayoutOrder = 2
    separator.Size = UDim2.new(1, 0, 0, 1)
    separator.ZIndex = frame.ZIndex + 1
    separator.Parent = frame

    -- Content area
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.AutomaticSize = Enum.AutomaticSize.Y
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.LayoutOrder = 3
    content.Size = UDim2.new(1, 0, 0, 0)
    content.ZIndex = frame.ZIndex + 1
    content.Parent = frame

    local contentPadding = Instance.new("UIPadding")
    contentPadding.PaddingTop = UDim.new(0, 8)
    contentPadding.PaddingBottom = UDim.new(0, 10)
    contentPadding.PaddingLeft = UDim.new(0, 12)
    contentPadding.PaddingRight = UDim.new(0, 12)
    contentPadding.Parent = content

    local contentLayout = Instance.new("UIListLayout")
    contentLayout.FillDirection = Enum.FillDirection.Vertical
    contentLayout.Padding = UDim.new(0, CONTENT_GAP)
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Parent = content

    return {
        frame = frame,
        titleBar = titleBar,
        titleLabel = titleLabel,
        content = content,
    }
end

function Groupbox.new(parent, config)
    local cfg = config or {}
    local refs = createGroupbox(parent)
    refs.frame.LayoutOrder = cfg.LayoutOrder or 1

    local self = setmetatable({
        Instance = refs.frame,
        TitleBar = refs.titleBar,
        Content = refs.content,
        Column = parent,
        LayoutOrder = refs.frame.LayoutOrder,
        Controls = {},
        _refs = refs,
        _dragging = false,
    }, GroupboxMeta)

    refs.titleLabel.Text = string.upper(cfg.Title or "Groupbox")

    return self
end

function Groupbox:_syncLayout()
    applyRootLayout(self.Instance)

    return self
end

function Groupbox:SetPlacement(column, layoutOrder)
    self.Column = column
    self.LayoutOrder = layoutOrder
    self.Instance.LayoutOrder = layoutOrder
    self:_syncLayout()

    return self
end

function GroupboxMeta.__index(self, key)
    local method = Groupbox[key]
    if method ~= nil then
        return method
    end

    local factoryMethod = ControlFactory[key]
    if factoryMethod ~= nil then
        return factoryMethod
    end

    return rawget(self, key)
end

return Groupbox
