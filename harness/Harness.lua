local Harness = {}

Harness._session = nil

local getGlobalEnvironment = getgenv or function()
    return _G
end

local function readColor(color: Color3)
    return {
        r = math.round(color.R * 255),
        g = math.round(color.G * 255),
        b = math.round(color.B * 255),
    }
end

function Harness.unmount()
    if Harness._session and Harness._session.screenGui then
        Harness._session.screenGui:Destroy()
    end

    Harness._session = nil
    getGlobalEnvironment().SlateHarness = nil
end

function Harness.mount(api, parent: Instance)
    Harness.unmount()

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SlateHarness"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.Parent = parent

    local window = api:CreateWindow({
        Parent = screenGui,
    })

    Harness._session = {
        api = api,
        parent = parent,
        screenGui = screenGui,
        window = window,
    }

    getGlobalEnvironment().SlateHarness = Harness

    return Harness._session
end

function Harness.snapshotState()
    local session = Harness._session

    if not session then
        return nil
    end

    return {
        screenGuiName = session.screenGui.Name,
        windowName = session.window.Instance.Name,
        title = session.window.Title,
        visible = session.window.Visible,
        absolutePosition = {
            x = session.window.Instance.AbsolutePosition.X,
            y = session.window.Instance.AbsolutePosition.Y,
        },
        absoluteSize = {
            x = session.window.Instance.AbsoluteSize.X,
            y = session.window.Instance.AbsoluteSize.Y,
        },
        background = readColor(session.window.Instance.BackgroundColor3),
        sidebarWidth = session.window.SidebarWidth,
        resizable = session.window.Resizable,
        showSidebar = session.window.ShowSidebar,
    }
end

function Harness.step(delaySeconds: number?)
    task.wait(delaySeconds or 0.1)

    return Harness.snapshotState()
end

return Harness
