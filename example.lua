local Slate = loadstring(game:HttpGet("https://raw.githubusercontent.com/j0z4fx/Slate-V2/refs/heads/main/loader.lua"))()

local Players = game:GetService("Players")
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local existingGui = playerGui:FindFirstChild("SlateExample")
if existingGui then
    existingGui:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SlateExample"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

local window = Slate.CreateWindow(screenGui)

return {
    Slate = Slate,
    ScreenGui = screenGui,
    Window = window,
}
