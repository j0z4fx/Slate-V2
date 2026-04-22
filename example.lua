local Slate = loadstring(game:HttpGet("https://cdn.jsdelivr.net/gh/j0z4fx/Slate-V2@main/loader.lua"))()
local Window = Slate:CreateWindow({
    Title = "Example",
    Version = "1.0.1",
    Width = 960,
    Height = 540,
})

Window:AddTab({
    Title = "Home",
    Icon = "house",
    Active = true,
})

Window:AddTab({
    Title = "Profile",
    Icon = "user-round",
})

Window:AddGroupbox(Window.leftColumn, { Title = "General" })
