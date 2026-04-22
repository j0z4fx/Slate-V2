local cacheBuster = tostring(os.clock())
local loaderSource = ("https://raw.githubusercontent.com/j0z4fx/Slate-V2/main/loader.lua?cache=%s"):format(cacheBuster)
local Slate = loadstring(game:HttpGet(loaderSource))()
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
local ExampleToggle = HomeGroup:AddToggle({
    Text = "Example Toggle",
    Default = false,
})

ExampleToggle:AddColorPicker({
    Title = "Toggle Color",
    Default = Color3.fromRGB(255, 91, 155),
})

ExampleToggle:AddKeyPicker({
    Default = "RightShift",
    Mode = "Toggle",
    SyncToggleState = false,
})
