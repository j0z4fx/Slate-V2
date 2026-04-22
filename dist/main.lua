local Slate = {}

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

local protectGui = protectgui or (syn and syn.protect_gui) or function() end
local getHiddenUi = gethui

Slate.Theme = {
    background = Color3.fromRGB(15, 15, 24),
}

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

function Slate.CreateWindow(parent)
    local target = parent or getOrCreateRoot()
    local frame = Instance.new("Frame")
    frame.Name = "Window"
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Position = UDim2.fromScale(0.5, 0.5)
    frame.Size = UDim2.fromOffset(960, 540)
    frame.BackgroundColor3 = Slate.Theme.background
    frame.BorderSizePixel = 0
    frame.Parent = target

    return frame
end

return Slate
