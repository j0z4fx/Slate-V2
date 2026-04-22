local cacheBuster = tostring(os.clock())
local source = ("https://cdn.jsdelivr.net/gh/j0z4fx/Slate-V2@main/dist/main.lua?cache=%s"):format(cacheBuster)

return loadstring(game:HttpGet(source))()
