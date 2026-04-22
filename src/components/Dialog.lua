local Theme = require(script.Parent.Parent.theme.Theme)
local TweenService = game:GetService("TweenService")

local Dialog = {}

local DIALOG_TWEEN_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

local function createButton(parent, text, accent)
    local button = Instance.new("TextButton")
    button.AutoButtonColor = false
    button.BackgroundColor3 = accent and Theme.accent or Theme["button-bg"]
    button.BorderSizePixel = 0
    button.Size = UDim2.new(0.5, -4, 0, 28)
    button.Text = ""
    button.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = button

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.BorderSizePixel = 0
    label.Size = UDim2.fromScale(1, 1)
    label.Font = Enum.Font.GothamMedium
    label.Text = tostring(text)
    label.TextColor3 = accent and Color3.new(1, 1, 1) or Theme["text-primary"]
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.Parent = button

    return button
end

function Dialog.Open(window, config)
    local root = window.Parent
    local cfg = config or {}

    local overlay = Instance.new("Frame")
    overlay.Name = "SlateDialog"
    overlay.BackgroundColor3 = Theme["modal-scrim"]
    overlay.BackgroundTransparency = window._state.Animations and 1 or 0.18
    overlay.BorderSizePixel = 0
    overlay.Size = UDim2.fromScale(1, 1)
    overlay.ZIndex = 40
    overlay.Parent = root

    local panel = Instance.new("Frame")
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.AutomaticSize = Enum.AutomaticSize.Y
    panel.BackgroundColor3 = Theme.surface
    panel.BorderSizePixel = 0
    panel.Position = UDim2.fromScale(0.5, 0.5)
    panel.Size = UDim2.new(0, 360, 0, 0)
    panel.ZIndex = overlay.ZIndex + 1
    panel.Parent = overlay

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = panel

    local stroke = Instance.new("UIStroke")
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Color = Theme["surface-stroke"]
    stroke.Thickness = 1
    stroke.Parent = panel

    local padding = Instance.new("UIPadding")
    padding.PaddingBottom = UDim.new(0, 12)
    padding.PaddingLeft = UDim.new(0, 12)
    padding.PaddingRight = UDim.new(0, 12)
    padding.PaddingTop = UDim.new(0, 12)
    padding.Parent = panel

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = panel

    local title = Instance.new("TextLabel")
    title.AutomaticSize = Enum.AutomaticSize.Y
    title.BackgroundTransparency = 1
    title.BorderSizePixel = 0
    title.Font = Enum.Font.GothamMedium
    title.Size = UDim2.new(1, 0, 0, 0)
    title.Text = tostring(cfg.Title or "Confirm")
    title.TextColor3 = Theme["text-primary"]
    title.TextSize = 16
    title.TextWrapped = true
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextYAlignment = Enum.TextYAlignment.Top
    title.Parent = panel

    local body = Instance.new("TextLabel")
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
    body.Parent = panel

    local buttons = Instance.new("Frame")
    buttons.BackgroundTransparency = 1
    buttons.BorderSizePixel = 0
    buttons.Size = UDim2.new(1, 0, 0, 28)
    buttons.Parent = panel

    local buttonsLayout = Instance.new("UIListLayout")
    buttonsLayout.FillDirection = Enum.FillDirection.Horizontal
    buttonsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    buttonsLayout.Padding = UDim.new(0, 8)
    buttonsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    buttonsLayout.Parent = buttons

    local dialog = {}
    local closing = false

    function dialog:Close()
        if closing then
            return
        end

        closing = true

        if not window._state.Animations then
            overlay:Destroy()
            return
        end

        local tween = TweenService:Create(overlay, DIALOG_TWEEN_INFO, {
            BackgroundTransparency = 1,
        })
        TweenService:Create(panel, DIALOG_TWEEN_INFO, {
            BackgroundTransparency = 1,
        }):Play()
        tween:Play()
        tween.Completed:Connect(function()
            overlay:Destroy()
        end)
    end

    local definitions = cfg.Buttons or {
        {
            Accent = true,
            Text = "Okay",
        },
    }

    for _, definition in ipairs(definitions) do
        local button = createButton(buttons, definition.Text or "Okay", definition.Accent == true)
        button.MouseButton1Click:Connect(function()
            local shouldClose = true
            if definition.Callback then
                local result = definition.Callback()
                if result == false then
                    shouldClose = false
                end
            end

            if shouldClose then
                dialog:Close()
            end
        end)
    end

    if window._state.Animations then
        TweenService:Create(overlay, DIALOG_TWEEN_INFO, {
            BackgroundTransparency = 0.18,
        }):Play()
    end

    dialog.Instance = overlay

    return dialog
end

return Dialog
