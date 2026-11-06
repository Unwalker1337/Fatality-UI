local Fatality = loadstring(game:HttpGet("https://raw.githubusercontent.com/Unwalker1337/Fatality-UI/main/src/source.luau"))()
Fatality:Loader({Name = "FATALITY", Duration = 1.4})
local Window = Fatality.new({Name = "FATALITY"})
local Menu = Window:AddMenu({Name = "SETTINGS", Icon = "settings", AutoFill = false})
local Section = Menu:AddSection({Name = "GENERAL", Position = "left"})
Section:AddToggle({
    Name = "Enabled",
    Flag = "enabled",
    Default = false,
    Bind = {Key = "Q", Mode = "Hold", Visible = true},
})

local Config = Window:AddConfig()
Config:Init("Config-example", "FATALITY")
Window:AddSave(function() Config:ReloadConfig(); Config:Open() end)
-- The built-in panel saves the control value and keybind key/mode/visibility.
