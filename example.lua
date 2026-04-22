local Slate = loadstring(game:HttpGet("https://cdn.jsdelivr.net/gh/j0z4fx/Slate-V2@main/loader.lua"))()
local Window = Slate:CreateWindow({
    Title = "Example",
    Version = "1.0.1",
    Width = 960,
    Height = 540,
})

local Home = Window:AddTab({
    Title = "Home",
    Icon = "house",
    Active = true,
})

local Profile = Window:AddTab({
    Title = "Profile",
    Icon = "user-round",
})

Home:AddGroupbox("leftColumn", { Title = "General" })
Profile:AddGroupbox("leftColumn", { Title = "Profile" })
local SettingsGroup = Window.Tabs.Settings:AddGroupbox("leftColumn", { Title = "Settings" })
Window.Tabs.Settings:AddGroupbox("middleColumn", { Title = "Advanced" })
SettingsGroup:AddToggle({
    Text = "Example Toggle",
    Default = false,
})
