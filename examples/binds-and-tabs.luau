local Fatality = loadstring(game:HttpGet("https://raw.githubusercontent.com/Unwalker1337/Fatality-UI/main/src/source.luau"))()
Fatality:Loader({Name = "FATALITY", Duration = 1.4, Scale = 2})
local Window = Fatality.new({Name = "FATALITY", Scale = UDim2.fromOffset(750, 500)})

for _, direction in ipairs({"top", "bottom", "left", "right"}) do
    local menu = Window:AddMenu({Name = string.upper(direction), Icon = "layout", TabsPosition = direction, AutoFill = false})
    local general = menu:AddTab({Name = "General"})
    local advanced = menu:AddTab({Name = "Advanced"})
    local section = general:AddSection({Name = "CONTROLS", Position = "left"})
    section:AddToggle({
        Name = "Right-click to bind",
        Flag = "enabled_" .. direction,
        Callback = function(value) print(direction, value) end,
    })
    section:AddButton({
        Name = "Action",
        BindId = "action/" .. direction,
        Callback = function() print("Action", direction) end,
    })
    advanced:AddTab({Name = "Inputs", Position = "left"}):AddSection({Name = "INPUTS", Position = "center"}):AddToggle({
        Name = "Nested control", Flag = "nested_" .. direction,
    })
    advanced:AddTab({Name = "Other"})
end

local Config = Window:AddConfig()
Config:Init("Binds-and-tabs", "FATALITY")
Window:AddSave(function() Config:ReloadConfig(); Config:Open() end)
