$ErrorActionPreference = "Stop"

$root = Split-Path $PSScriptRoot -Parent
$dist = Join-Path $root "dist"
$outFile = Join-Path $dist "main.lua"

$sourceFiles = @(
    "src/theme/Theme.lua",
    "src/core/Root.lua",
    "src/core/Keybind.lua",
    "src/core/Ui.lua",
    "src/core/ControlFactory.lua",
    "src/vendor/Lucide.lua",
    "src/components/Button.lua",
    "src/components/Checkbox.lua",
    "src/components/Code.lua",
    "src/components/ColorPicker.lua",
    "src/components/Dialog.lua",
    "src/components/Divider.lua",
    "src/components/Dropdown.lua",
    "src/components/Input.lua",
    "src/components/KeyPicker.lua",
    "src/components/Label.lua",
    "src/components/Notification.lua",
    "src/components/Paragraph.lua",
    "src/components/Separator.lua",
    "src/components/Slider.lua",
    "src/components/Tag.lua",
    "src/components/Tabbox.lua",
    "src/components/Toggle.lua",
    "src/components/Groupbox.lua",
    "src/components/Tab.lua",
    "src/components/Window.lua",
    "src/init.lua"
)

function Get-ModuleId([string]$relativePath) {
    $moduleId = $relativePath -replace '^src[\\/]', '' -replace '\.lua$', ''
    $moduleId = $moduleId -replace '\\', '/'
    return $moduleId
}

function Resolve-RequireId([string]$currentModuleId, [string]$scriptPathExpression) {
    $segments = @()
    if ($currentModuleId -ne "init") {
        $segments = $currentModuleId.Split('/')
    }

    $parts = $scriptPathExpression.Split('.') | Select-Object -Skip 1
    foreach ($part in $parts) {
        if ($part -eq "Parent") {
            if ($segments.Count -gt 0) {
                if ($segments.Count -eq 1) {
                    $segments = @()
                } else {
                    $segments = $segments[0..($segments.Count - 2)]
                }
            }
            continue
        }

        $segments += $part
    }

    return ($segments -join '/')
}

function Quote-LuaString([string]$value) {
    return "'" + ($value -replace '\\', '\\\\' -replace "'", "\\'") + "'"
}

$moduleEntries = foreach ($relativePath in $sourceFiles) {
    [PSCustomObject]@{
        Id = Get-ModuleId $relativePath
        Path = $relativePath
    }
}

$requirePattern = '^\s*local\s+([A-Za-z_][A-Za-z0-9_]*)\s*=\s*require\((script(?:\.[A-Za-z_][A-Za-z0-9_]*)+)\)\s*$'
$parts = New-Object System.Collections.Generic.List[string]

$parts.Add("local __modules = {}")
$parts.Add("local __cache = {}")
$parts.Add("")
$parts.Add("local function __require(name)")
$parts.Add("    if __cache[name] ~= nil then")
$parts.Add("        return __cache[name]")
$parts.Add("    end")
$parts.Add("")
$parts.Add("    local loader = __modules[name]")
$parts.Add("    assert(loader ~= nil, string.format(""Missing bundled module %q"", tostring(name)))")
$parts.Add("")
$parts.Add("    local value = loader()")
$parts.Add("    __cache[name] = value")
$parts.Add("")
$parts.Add("    return value")
$parts.Add("end")
$parts.Add("")

foreach ($entry in $moduleEntries) {
    $path = Join-Path $root $entry.Path
    if (-not (Test-Path $path)) {
        throw "Missing source file: $($entry.Path)"
    }

    $parts.Add(("-- " + $entry.Path))
    $parts.Add(("__modules[{0}] = function()" -f (Quote-LuaString $entry.Id)))

    foreach ($line in Get-Content $path) {
        $transformed = $line

        if ($line -match $requirePattern) {
            $localName = $matches[1]
            $requirePath = Resolve-RequireId $entry.Id $matches[2]
            $transformed = ("local {0} = __require({1})" -f $localName, (Quote-LuaString $requirePath))
        }

        if ($transformed.Length -gt 0) {
            $parts.Add("    " + $transformed)
        } else {
            $parts.Add("")
        }
    }

    $parts.Add("end")
    $parts.Add("")
}

$parts.Add("return __require('init')")

New-Item -ItemType Directory -Force -Path $dist | Out-Null
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllLines($outFile, $parts, $utf8NoBom)
Write-Host "Built $outFile"
