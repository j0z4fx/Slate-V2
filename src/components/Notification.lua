local Theme = require(script.Parent.Parent.theme.Theme)
local TweenService = game:GetService("TweenService")

local Notification = {}

local TOAST_TWEEN_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

local function getContainer(parent)
    local existing = parent:FindFirstChild("SlateNotifications")
    if existing then
        return existing
    end

    local container = Instance.new("Frame")
    container.Name = "SlateNotifications"
    container.AnchorPoint = Vector2.new(1, 0)
    container.AutomaticSize = Enum.AutomaticSize.Y
    container.BackgroundTransparency = 1
    container.BorderSizePixel = 0
    container.Position = UDim2.new(1, -16, 0, 16)
    container.Size = UDim2.fromOffset(280, 0)
    container.ZIndex = 50
    container.Parent = parent

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = container

    return container
end

function Notification.Notify(window, config)
    local root = window.Parent
    local container = getContainer(root)
    local cfg = config or {}

    local toast = Instance.new("Frame")
    toast.Name = "Toast"
    toast.AutomaticSize = Enum.AutomaticSize.Y
    toast.BackgroundColor3 = Theme["toast-bg"]
    toast.BorderSizePixel = 0
    toast.Size = UDim2.new(1, 0, 0, 0)
    toast.ZIndex = container.ZIndex
    toast.Parent = container

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = toast

    local stroke = Instance.new("UIStroke")
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Color = Theme["toast-stroke"]
    stroke.Thickness = 1
    stroke.Parent = toast

    local padding = Instance.new("UIPadding")
    padding.PaddingBottom = UDim.new(0, 10)
    padding.PaddingLeft = UDim.new(0, 12)
    padding.PaddingRight = UDim.new(0, 12)
    padding.PaddingTop = UDim.new(0, 10)
    padding.Parent = toast

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.Padding = UDim.new(0, 4)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = toast

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.AutomaticSize = Enum.AutomaticSize.Y
    title.BackgroundTransparency = 1
    title.BorderSizePixel = 0
    title.Font = Enum.Font.GothamMedium
    title.Size = UDim2.new(1, 0, 0, 0)
    title.Text = tostring(cfg.Title or "Slate")
    title.TextColor3 = Theme["text-primary"]
    title.TextSize = 14
    title.TextWrapped = true
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextYAlignment = Enum.TextYAlignment.Top
    title.Parent = toast

    local body = Instance.new("TextLabel")
    body.Name = "Body"
    body.AutomaticSize = Enum.AutomaticSize.Y
    body.BackgroundTransparency = 1
    body.BorderSizePixel = 0
    body.Font = Enum.Font.Gotham
    body.Size = UDim2.new(1, 0, 0, 0)
    body.Text = tostring(cfg.Content or cfg.Text or "")
    body.TextColor3 = Theme["text-secondary"]
    body.TextSize = 13
    body.TextWrapped = true
    body.TextXAlignment = Enum.TextXAlignment.Left
    body.TextYAlignment = Enum.TextYAlignment.Top
    body.Parent = toast

    local accent = Instance.new("Frame")
    accent.Name = "Accent"
    accent.BackgroundColor3 = cfg.Color or Theme.accent
    accent.BorderSizePixel = 0
    accent.Position = UDim2.fromOffset(0, 0)
    accent.Size = UDim2.new(1, 0, 0, 2)
    accent.ZIndex = toast.ZIndex + 1
    accent.Parent = toast

    local lifetime = tonumber(cfg.Duration) or 4

    if window._state.Animations then
        toast.BackgroundTransparency = 1
        stroke.Transparency = 1
        title.TextTransparency = 1
        body.TextTransparency = 1
        TweenService:Create(toast, TOAST_TWEEN_INFO, {
            BackgroundTransparency = 0,
        }):Play()
        TweenService:Create(stroke, TOAST_TWEEN_INFO, {
            Transparency = 0,
        }):Play()
        TweenService:Create(title, TOAST_TWEEN_INFO, {
            TextTransparency = 0,
        }):Play()
        TweenService:Create(body, TOAST_TWEEN_INFO, {
            TextTransparency = 0,
        }):Play()
    end

    local dismissed = false

    local function dismiss()
        if dismissed then
            return
        end

        dismissed = true

        if not window._state.Animations then
            toast:Destroy()
            return
        end

        local fade = TweenService:Create(toast, TOAST_TWEEN_INFO, {
            BackgroundTransparency = 1,
        })
        TweenService:Create(stroke, TOAST_TWEEN_INFO, {
            Transparency = 1,
        }):Play()
        TweenService:Create(title, TOAST_TWEEN_INFO, {
            TextTransparency = 1,
        }):Play()
        TweenService:Create(body, TOAST_TWEEN_INFO, {
            TextTransparency = 1,
        }):Play()
        fade:Play()
        fade.Completed:Connect(function()
            toast:Destroy()
        end)
    end

    task.delay(lifetime, dismiss)

    return {
        Instance = toast,
        Destroy = dismiss,
    }
end

return Notification
