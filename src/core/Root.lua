local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

local protectGui = protectgui or (syn and syn.protect_gui) or function() end
local getHiddenUi = gethui

local Root = {}

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

function Root.getOrCreate()
    local container = resolveContainer()
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

return Root
