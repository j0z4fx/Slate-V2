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

local HomeGroup = Home:AddGroupbox("leftColumn", { Title = "Example" })
Profile:AddGroupbox("leftColumn", { Title = "Profile" })
Window.Tabs.Settings:AddGroupbox("leftColumn", { Title = "Settings" })
Window.Tabs.Settings:AddGroupbox("middleColumn", { Title = "Configuration" })
HomeGroup:AddLabel({
    Text = "Example Label",
    Subtext = "Label Subtext",
})
HomeGroup:AddDivider()
HomeGroup:AddSeparator("Separator")
HomeGroup:AddToggle({
    Text = "Example Toggle",
    Default = false,
})
