local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Slate = require(ReplicatedStorage:WaitForChild("Slate"))
local Harness = require(script.Parent:WaitForChild("Harness"))

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

Harness.mount(Slate, playerGui)
