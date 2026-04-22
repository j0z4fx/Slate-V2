local ControlFactory = {}

local function addControl(self, control)
    table.insert(self.Controls, control)

    return control
end

local function normalizeConfig(configOrText, config)
    if type(configOrText) == "table" then
        return configOrText
    end

    local nextConfig = config or {}
    nextConfig.Text = configOrText

    return nextConfig
end

function ControlFactory.AddToggle(self, configOrText, config)
    local Toggle = require(script.Parent.Parent.components.Toggle)

    return addControl(self, Toggle.new(self.Content, normalizeConfig(configOrText, config)))
end

function ControlFactory.AddSwitch(self, configOrText, config)
    return ControlFactory.AddToggle(self, configOrText, config)
end

function ControlFactory.AddCheckbox(self, configOrText, config)
    local Checkbox = require(script.Parent.Parent.components.Checkbox)

    return addControl(self, Checkbox.new(self.Content, normalizeConfig(configOrText, config)))
end

function ControlFactory.AddButton(self, configOrText, config)
    local Button = require(script.Parent.Parent.components.Button)

    return addControl(self, Button.new(self.Content, normalizeConfig(configOrText, config)))
end

function ControlFactory.AddDivider(self)
    local Divider = require(script.Parent.Parent.components.Divider)

    return addControl(self, Divider.new(self.Content))
end

function ControlFactory.AddSeparator(self, configOrText, config)
    local Separator = require(script.Parent.Parent.components.Separator)

    return addControl(self, Separator.new(self.Content, normalizeConfig(configOrText, config)))
end

function ControlFactory.AddLabel(self, configOrText, config)
    local Label = require(script.Parent.Parent.components.Label)

    return addControl(self, Label.new(self.Content, normalizeConfig(configOrText, config)))
end

function ControlFactory.AddInput(self, configOrText, config)
    local Input = require(script.Parent.Parent.components.Input)

    return addControl(self, Input.new(self.Content, normalizeConfig(configOrText, config)))
end

function ControlFactory.AddSlider(self, configOrText, config)
    local Slider = require(script.Parent.Parent.components.Slider)

    return addControl(self, Slider.new(self.Content, normalizeConfig(configOrText, config)))
end

function ControlFactory.AddDropdown(self, configOrText, config)
    local Dropdown = require(script.Parent.Parent.components.Dropdown)

    return addControl(self, Dropdown.new(self.Content, normalizeConfig(configOrText, config)))
end

function ControlFactory.AddParagraph(self, configOrText, config)
    local Paragraph = require(script.Parent.Parent.components.Paragraph)
    local nextConfig = configOrText

    if type(configOrText) ~= "table" then
        nextConfig = config or {}
        nextConfig.Body = configOrText
    end

    return addControl(self, Paragraph.new(self.Content, nextConfig))
end

function ControlFactory.AddCode(self, configOrText, config)
    local Code = require(script.Parent.Parent.components.Code)
    local nextConfig = configOrText

    if type(configOrText) ~= "table" then
        nextConfig = config or {}
        nextConfig.Text = configOrText
    end

    return addControl(self, Code.new(self.Content, nextConfig))
end

function ControlFactory.AddTag(self, configOrText, config)
    local Tag = require(script.Parent.Parent.components.Tag)

    return addControl(self, Tag.new(self.Content, normalizeConfig(configOrText, config)))
end

function ControlFactory.AddTabbox(self, config)
    local Tabbox = require(script.Parent.Parent.components.Tabbox)

    return addControl(self, Tabbox.new(self.Content, config or {}))
end

return ControlFactory
