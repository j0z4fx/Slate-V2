local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Ui = {}

function Ui.apply(instance, properties)
    for property, value in pairs(properties) do
        instance[property] = value
    end
end

function Ui.cancel(tween)
    if tween then
        tween:Cancel()
    end
end

function Ui.findWindow(instance)
    local current = instance

    while current do
        if current.GetAttribute and current:GetAttribute("SlateComponent") == "Window" then
            return current
        end

        current = current.Parent
    end

    return nil
end

function Ui.animationsEnabled(instance)
    local window = Ui.findWindow(instance)
    if window == nil then
        return true
    end

    return window:GetAttribute("SlateAnimationsEnabled") ~= false
end

function Ui.play(instance, tweenInfo, properties)
    if not Ui.animationsEnabled(instance) then
        Ui.apply(instance, properties)
        return nil
    end

    local tween = TweenService:Create(instance, tweenInfo, properties)
    tween:Play()

    return tween
end

function Ui.isTextInputFocused()
    return UserInputService:GetFocusedTextBox() ~= nil
end

return Ui
