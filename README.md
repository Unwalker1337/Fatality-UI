# Fatality

Fatality.Win UI for Roblox — dark theme.

![image](https://github.com/user-attachments/assets/f1023175-a33b-44fc-8a24-636103e8324e)

## Usage

- [Original documentation](https://cat-sus.gitbook.io/fatality)
- [Main example](example.luau)
- [Binds and nested tabs](examples/binds-and-tabs.luau)
- [Native configs](examples/config-manager.luau)

## 1.7.0: context keybinds

Right-click a toggle or button to open its keybind editor. Click the key field, then press a keyboard key or mouse button. Choose **Hold**, **Toggle**, or **Always**. **Visible** controls whether the active bind appears in the keybind list; its tooltip is `visible in keybinds list`. Changing Visible does not disable the function.

Escape cancels key capture; Backspace or Delete clears the bind. Hold restores the toggle's previous state on release or focus loss. Button binds execute the action on press and repeat at most once every 0.12 seconds while active. Processed input and typing do not trigger binds.

```lua
local enabled = Section:AddToggle({
    Name = "Enabled",
    Flag = "enabled", -- stable control identity and native value persistence
    Bind = {Key = "Q", Mode = "Hold", Visible = true}, -- optional preset
    Callback = function(value) print(value) end,
})

enabled:SetBind({Key = "MouseButton3", Mode = "Toggle"})
enabled:SetBind({Visible = false}) -- only hides the keybind-list entry
print(enabled:GetBind().Mode)
enabled:ClearBind()

-- Optional stable identity for buttons or renamed controls:
enabled:SetBindId("feature/enabled")
-- Opt out of the context editor: Bindable = false in AddToggle/AddButton.
Window:SetKeybindListVisible(true)
```

`BindId` can also be supplied in the control options. Use a unique `Flag` or `BindId` for controls that should survive changes to labels or creation order. `Window:GetKeybinds()` returns a snapshot, and `Window:ImportKeybinds(snapshot, reset)` restores it. The optional reset argument clears existing assignments first. Lowercase `key`, `mode`, and `visible` fields are accepted for imports.

The keybind editor and draggable list belong to the library. Keys, modes, per-bind visibility and list visibility are saved automatically by `Window:GetFlagConfig()` and restored by `Window:LoadConfig()`, including through the built-in config panel. No separate keybind file is required.

## Nested tabs

`AddMenu` still creates a top-level menu. Both menus and child tabs support `AddTab`, `AddSection`, `Select`, `SelectTab`, and `SetTabsPosition`. Nested tabs do not add entries to the top-level menu bar.

```lua
local menu = Window:AddMenu({Name = "SETTINGS", TabsPosition = "top"})
local general = menu:AddTab({Name = "General"})
local advanced = menu:AddTab({Name = "Advanced"})
local inputs = advanced:AddTab({Name = "Inputs", Position = "left"})

inputs:AddSection({Name = "KEYBOARD", Position = "center"}):AddToggle({
    Name = "Enabled", Flag = "keyboard_enabled",
})

menu:SetTabsPosition("bottom") -- top, bottom, left, right
advanced:SetTabsPosition("right") -- independent at each nesting level
inputs:Select() -- activates all ancestors
menu:SelectTab("General")
```

`TabsPosition` sets a container's default tab-bar location. `Position` on `AddTab` changes that parent's tab-bar location for all siblings. Section `Position` continues to mean its content column (`left`, `center`, or `right`). When using nested tabs, put sections inside the child tabs rather than mixing direct parent sections with child content. Selection survives window hide/show, and global search activates the matching nested page.

## Build and checks

`src/source.luau` is the standalone loader and requires no extra HTTP requests. The extension implementation is maintained in `src/extensions.luau`; after editing it, rebuild with:

```text
python build_source.py
python tests/run.py --luau /path/to/luau
```

The tests exercise the actual bundled library against an offline Roblox API model. Rendering and behavior inside Roblox require a separate live check.
