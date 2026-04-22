local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

local protectGui = protectgui or (syn and syn.protect_gui) or function() end
local getHiddenUi = gethui

local Root = {}
local ROOT_NAME = "Slate"
local ROOT_ATTRIBUTE = "SlateOwned"

local function resolveContainer()
    if typeof(getHiddenUi) == "function" then
        local success, hiddenUi = pcall(getHiddenUi)
        if success and typeof(hiddenUi) == "Instance" then
            return hiddenUi
        end
    end

    local localPlayer = Players.LocalPlayer
    local playerGui = localPlayer and (localPlayer:FindFirstChildOfClass("PlayerGui") or localPlayer:WaitForChild("PlayerGui"))

    if RunService:IsStudio() and playerGui then
        return playerGui
    end

    if CoreGui then
        return CoreGui
    end

    return playerGui
end

local function findOwnedRoot(container)
    for _, child in ipairs(container:GetChildren()) do
        if child.Name == ROOT_NAME and child:GetAttribute(ROOT_ATTRIBUTE) then
            return child
        end
    end

    return nil
end

function Root.getOrCreate()
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

function Root.getExisting()
    local container = resolveContainer()

    return findOwnedRoot(container)
end

function Root.destroy(target)
    local existing = target or Root.getExisting()

    if existing then
        pcall(function()
            existing:Destroy()
        end)
    end
end

return Root
