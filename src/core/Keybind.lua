local Keybind = {}

local SPECIAL_INPUTS = {
    [Enum.UserInputType.MouseButton1] = "MB1",
    [Enum.UserInputType.MouseButton2] = "MB2",
    [Enum.UserInputType.MouseButton3] = "MB3",
}

local activePicker = nil

function Keybind.normalize(value)
    if value == nil then
        return "None"
    end

    if typeof(value) == "EnumItem" then
        if value.EnumType == Enum.UserInputType then
            return SPECIAL_INPUTS[value] or value.Name
        end

        return value.Name
    end

    return tostring(value)
end

function Keybind.inputToKeyName(input)
    if SPECIAL_INPUTS[input.UserInputType] then
        return SPECIAL_INPUTS[input.UserInputType]
    end

    if input.KeyCode and input.KeyCode ~= Enum.KeyCode.Unknown then
        return input.KeyCode.Name
    end

    return nil
end

function Keybind.format(value)
    local key = Keybind.normalize(value)
    if key == "None" then
        return key
    end

    key = key:gsub("(%l)(%u)", "%1 %2")
    key = key:gsub("Button(%d)", "Button %1")

    return key
end

function Keybind.beginCapture(owner)
    activePicker = owner
end

function Keybind.endCapture(owner)
    if activePicker == owner then
        activePicker = nil
    end
end

function Keybind.isCapturing()
    return activePicker ~= nil
end

return Keybind
