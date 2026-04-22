local Lucide = {}

local SOURCE_URL = "https://github.com/latte-soft/lucide-roblox/releases/latest/download/lucide-roblox.luau"

local ICON_ALIASES = {
    ["circle-question-mark"] = "help-circle",
    house = "home",
}

local cachedModule = nil
local warned = false

local function resolveModule()
    if cachedModule then
        return cachedModule
    end

    assert(type(loadstring) == "function", "Slate requires loadstring support for Lucide icons")

    local source = game:HttpGet(SOURCE_URL)
    cachedModule = loadstring(source)()

    return cachedModule
end

function Lucide.GetAsset(name)
    local success, result = pcall(function()
        local iconName = ICON_ALIASES[name] or name

        return resolveModule().GetAsset(iconName, 48)
    end)

    if success then
        return result
    end

    if not warned then
        warned = true
        warn(string.format("Slate failed to load Lucide icons: %s", tostring(result)))
    end

    return nil
end

return Lucide
