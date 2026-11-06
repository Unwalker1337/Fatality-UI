-- Integrated below into source.luau; this module is kept separately for maintenance.
local function install(Fatality, UserInputService, RunService)
    local windows = {}
    Fatality.BindingWindows = windows

    local function make(class, properties, parent)
        local object = Instance.new(class)
        for key, value in pairs(properties) do object[key] = value end
        object.Parent = parent
        return object
    end
    local function text(parent, value, size)
        return make('TextLabel', {BackgroundTransparency = 1, BorderSizePixel = 0,
            FontFace = Fatality.FontSemiBold, TextSize = size or 12, Text = value,
            TextColor3 = Color3.fromRGB(230, 230, 230), TextXAlignment = Enum.TextXAlignment.Left}, parent)
    end
    local function button(parent, value)
        return make('TextButton', {BackgroundColor3 = Color3.fromRGB(31, 31, 31), BorderSizePixel = 0,
            AutoButtonColor = false, FontFace = Fatality.FontSemiBold, TextSize = 12,
            Text = value, TextColor3 = Color3.fromRGB(220, 220, 220)}, parent)
    end
    local function normalizeKey(key)
        if typeof(key) == 'EnumItem' then key = key.Name end
        if type(key) ~= 'string' or key == '' or key == 'None' or key == 'Unknown' then return nil end
        local aliases = {MouseLeft = 'MouseButton1', MouseRight = 'MouseButton2', MouseMiddle = 'MouseButton3'}
        key = aliases[key] or key
        local ok, value = pcall(function() return Enum.KeyCode[key] end)
        if ok and value or key == 'MouseButton1' or key == 'MouseButton2' or key == 'MouseButton3' then return key end
    end
    local function inputKey(input)
        if input.UserInputType == Enum.UserInputType.Keyboard then return normalizeKey(input.KeyCode) end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then return 'MouseButton1' end
        if input.UserInputType == Enum.UserInputType.MouseButton2 then return 'MouseButton2' end
        if input.UserInputType == Enum.UserInputType.MouseButton3 then return 'MouseButton3' end
    end
    local function shown(frame)
        local current = frame
        while current do
            if current:IsA('GuiObject') and not current.Visible then return false end
            if current:IsA('ScreenGui') then return current.Enabled end
            current = current.Parent
        end
        return false
    end
    local function contains(frame, point)
        local position, size = frame.AbsolutePosition, frame.AbsoluteSize
        return point.X >= position.X and point.Y >= position.Y and point.X <= position.X + size.X and point.Y <= position.Y + size.Y
    end
    local function connect(state, signal, callback)
        local connection = signal:Connect(callback)
        state.Connections[#state.Connections + 1] = connection
        return connection
    end
    local function active(entry)
        if entry.Kind == 'Toggle' then return entry.Control:GetValue() == true end
        return entry.Active == true
    end
    local function release(entry)
        if entry.Held and entry.Bind.Mode == 'Hold' and entry.Kind == 'Toggle' then
            entry.Control:SetValue(entry.BeforeHold == true)
        end
        entry.Held, entry.Active = false, false
    end
    local function setBind(entry, options)
        options = options or {}
        local previous = entry.Bind
        local key = options.Key
        if key == nil then key = options.key end
        if key == nil then key = previous.Key end
        local visible = options.Visible
        if visible == nil then visible = options.visible end
        if visible == nil then visible = previous.Visible end
        local mode = options.Mode or options.mode or previous.Mode
        if mode ~= 'Hold' and mode ~= 'Toggle' and mode ~= 'Always' then mode = 'Toggle' end
        key = normalizeKey(key)
        if key ~= previous.Key or mode ~= previous.Mode then release(entry) end
        entry.Bind = {Key = key, Mode = mode, Visible = visible ~= false}
        if mode == 'Always' and entry.Kind == 'Toggle' then entry.Control:SetValue(true) end
        return entry.Control
    end
    local function popupClose(state)
        state.Popup.Visible, state.Tooltip.Visible, state.Listening = false, false, nil
    end
    local function popupRefresh(state)
        local entry = state.PopupEntry
        if not entry then return end
        state.PopupTitle.Text = entry.Name
        state.KeyButton.Text = state.Listening and '[press a key]' or '[' .. (entry.Bind.Key or 'none') .. ']'
        state.VisibleButton.Text = (entry.Bind.Visible and '[x]  ' or '[ ]  ') .. 'Visible'
        for mode, item in pairs(state.ModeButtons) do
            item.TextColor3 = entry.Bind.Mode == mode and Fatality.Colors.Main or Color3.fromRGB(170, 170, 170)
        end
    end
    local function popupOpen(state, entry)
        state.PopupEntry, state.Listening = entry, nil
        local mouse, viewport = UserInputService:GetMouseLocation(), workspace.CurrentCamera.ViewportSize
        state.Popup.Position = UDim2.fromOffset(math.max(0, math.min(mouse.X + 6, viewport.X - 242)), math.max(0, math.min(mouse.Y + 6, viewport.Y - 170)))
        state.Popup.Visible = true
        popupRefresh(state)
    end
    local function refreshList(state)
        local entries = {}
        for _, entry in ipairs(state.Order) do
            if entry.Frame.Parent and entry.Bind.Visible and (entry.Bind.Key or entry.Bind.Mode == 'Always') and active(entry) then entries[#entries + 1] = entry end
        end
        for index, entry in ipairs(entries) do
            local row = state.Rows[index]
            if not row then row = text(state.List, '', 12); state.Rows[index] = row end
            row.Size, row.Position = UDim2.new(1, -16, 0, 20), UDim2.fromOffset(8, 25 + (index - 1) * 20)
            row.Text, row.Visible = entry.Name .. '  [' .. (entry.Bind.Mode == 'Always' and 'always' or entry.Bind.Key) .. ']', true
        end
        for index = #entries + 1, #state.Rows do state.Rows[index].Visible = false end
        state.List.Size = UDim2.fromOffset(230, 31 + #entries * 20)
        state.List.Visible = state.ListVisible and #entries > 0
    end
    local function import(state, saved, reset)
        if type(saved) ~= 'table' then return end
        if reset then
            for _, entry in ipairs(state.Order) do setBind(entry, {Key = false, Mode = 'Toggle', Visible = true}) end
            state.Pending = {}
        end
        for id, options in pairs(saved) do
            if type(id) == 'string' and type(options) == 'table' then
                local target = state.Aliases[id] or id
                state.Pending[target] = options
                if state.Entries[target] then setBind(state.Entries[target], {Key = options.Key or options.key or false,
                    Mode = options.Mode or options.mode, Visible = options.Visible, visible = options.visible}) end
            end
        end
        refreshList(state)
    end
    local function dispose(state)
        if state.Destroyed then return end
        state.Destroyed = true
        for _, connection in ipairs(state.Connections) do connection:Disconnect() end
        for _, entry in ipairs(state.Order) do release(entry) end
        state.Gui:Destroy()
        windows[state.Root] = nil
    end
    local function createBindings(window, root)
        local state = {Window = window, Root = root, Entries = {}, Order = {}, Aliases = {}, Pending = {}, Connections = {}, Rows = {}, ListVisible = true}
        state.Gui = make('ScreenGui', {Name = 'FatalityBindings', ResetOnSpawn = false, IgnoreGuiInset = true,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = root.DisplayOrder + 40}, root.Parent)
        state.List = make('Frame', {Name = 'KeybindList', BackgroundColor3 = Color3.fromRGB(19, 19, 19), BorderSizePixel = 0,
            Position = UDim2.new(0, 16, 0.5, -60), Size = UDim2.fromOffset(230, 80), Visible = false}, state.Gui)
        local title = text(state.List, 'Keybinds', 13)
        title.Size, title.Position, title.Active = UDim2.new(1, -16, 0, 24), UDim2.fromOffset(8, 0), true
        title.TextColor3 = Fatality.Colors.Main
        local dragStart, dragPosition
        connect(state, title.InputBegan, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragStart, dragPosition = input.Position, state.List.Position end
        end)
        connect(state, UserInputService.InputChanged, function(input)
            if dragStart and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                state.List.Position = dragPosition + UDim2.fromOffset(delta.X, delta.Y)
            end
        end)
        state.Popup = make('Frame', {Name = 'KeybindPopup', BackgroundColor3 = Color3.fromRGB(21, 21, 21), BorderSizePixel = 0,
            Size = UDim2.fromOffset(236, 164), Visible = false, Active = true, ZIndex = 100}, state.Gui)
        make('UIStroke', {Color = Color3.fromRGB(65, 65, 65)}, state.Popup)
        state.PopupTitle = text(state.Popup, '', 13)
        state.PopupTitle.Position, state.PopupTitle.Size = UDim2.fromOffset(10, 5), UDim2.new(1, -20, 0, 20)
        state.PopupTitle.TextTruncate = Enum.TextTruncate.AtEnd
        local keyLabel = text(state.Popup, 'Key')
        keyLabel.Position, keyLabel.Size = UDim2.fromOffset(10, 33), UDim2.fromOffset(42, 24)
        state.KeyButton = button(state.Popup, '[none]')
        state.KeyButton.Position, state.KeyButton.Size = UDim2.fromOffset(58, 33), UDim2.fromOffset(168, 24)
        state.ModeButtons = {}
        for index, mode in ipairs({'Hold', 'Toggle', 'Always'}) do
            local modeButton = button(state.Popup, mode)
            modeButton.Position, modeButton.Size = UDim2.fromOffset(10 + (index - 1) * 73, 66), UDim2.fromOffset(70, 24)
            state.ModeButtons[mode] = modeButton
            connect(state, modeButton.MouseButton1Click, function()
                if state.PopupEntry then setBind(state.PopupEntry, {Mode = mode}); popupRefresh(state); refreshList(state) end
            end)
        end
        state.VisibleButton = button(state.Popup, '[x]  Visible')
        state.VisibleButton.Position, state.VisibleButton.Size = UDim2.fromOffset(10, 99), UDim2.fromOffset(216, 24)
        local hint = text(state.Popup, 'Esc: cancel   Backspace / Delete: clear', 10)
        hint.Position, hint.Size = UDim2.fromOffset(10, 133), UDim2.fromOffset(216, 18)
        state.Tooltip = text(state.Gui, 'visible in keybinds list', 12)
        state.Tooltip.BackgroundColor3, state.Tooltip.BackgroundTransparency = Color3.fromRGB(30, 30, 30), 0
        state.Tooltip.Size, state.Tooltip.Visible, state.Tooltip.ZIndex = UDim2.fromOffset(160, 24), false, 200
        connect(state, state.KeyButton.MouseButton1Click, function() state.Listening = state.PopupEntry; popupRefresh(state) end)
        connect(state, state.VisibleButton.MouseButton1Click, function()
            if state.PopupEntry then setBind(state.PopupEntry, {Visible = not state.PopupEntry.Bind.Visible}); popupRefresh(state); refreshList(state) end
        end)
        connect(state, state.VisibleButton.MouseEnter, function()
            local mouse, viewport = UserInputService:GetMouseLocation(), workspace.CurrentCamera.ViewportSize
            state.Tooltip.Position = UDim2.fromOffset(math.max(0, math.min(mouse.X + 12, viewport.X - 164)), math.max(0, math.min(mouse.Y + 18, viewport.Y - 28)))
            state.Tooltip.Visible = state.Popup.Visible
        end)
        connect(state, state.VisibleButton.MouseLeave, function() state.Tooltip.Visible = false end)
        connect(state, UserInputService.InputBegan, function(input, processed)
            if state.Destroyed then return end
            local key = inputKey(input)
            if state.Listening then
                if input.KeyCode == Enum.KeyCode.Escape then state.Listening = nil
                elseif input.KeyCode == Enum.KeyCode.Backspace or input.KeyCode == Enum.KeyCode.Delete then
                    setBind(state.Listening, {Key = false, Mode = 'Toggle'}); state.Listening = nil
                elseif key then setBind(state.Listening, {Key = key}); state.Listening = nil end
                popupRefresh(state); refreshList(state)
                return
            end
            if input.UserInputType == Enum.UserInputType.MouseButton2 and window.Toggle then
                local point = UserInputService:GetMouseLocation()
                if state.Popup.Visible and contains(state.Popup, point) then return end
                for index = #state.Order, 1, -1 do
                    local entry = state.Order[index]
                    if entry.Frame.Parent and shown(entry.Frame) and contains(entry.Frame, point) then popupOpen(state, entry); return end
                end
            end
            if state.Popup.Visible then
                if input.KeyCode == Enum.KeyCode.Escape then popupClose(state); return end
                if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2)
                    and not contains(state.Popup, UserInputService:GetMouseLocation()) then popupClose(state) end
                return
            end
            if processed or UserInputService:GetFocusedTextBox() or not key then return end
            for _, entry in ipairs(state.Order) do
                if entry.Frame.Parent and entry.Bind.Key == key and entry.Bind.Mode ~= 'Always' and not entry.Held then
                    entry.Held = true
                    if entry.Kind == 'Toggle' then
                        if entry.Bind.Mode == 'Hold' then entry.BeforeHold = entry.Control:GetValue(); entry.Control:SetValue(true)
                        else entry.Control:SetValue(not entry.Control:GetValue()) end
                    else
                        if entry.Bind.Mode == 'Toggle' then entry.Active = not entry.Active else entry.Active = true end
                        if entry.Active then entry.Control:Fire() end
                    end
                end
            end
            refreshList(state)
        end)
        connect(state, UserInputService.InputEnded, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragStart = nil end
            local key = inputKey(input)
            for _, entry in ipairs(state.Order) do
                if key and entry.Bind.Key == key then
                    if entry.Bind.Mode == 'Hold' then release(entry) else entry.Held = false end
                end
            end
            refreshList(state)
        end)
        if UserInputService.WindowFocusReleased then connect(state, UserInputService.WindowFocusReleased, function()
            for _, entry in ipairs(state.Order) do if entry.Bind.Mode == 'Hold' then release(entry) end end
        end) end
        local elapsed = 0
        connect(state, RunService.Heartbeat, function(delta)
            if state.Destroyed then return end
            if not window.Toggle then popupClose(state) end
            local order = math.min(2147483647, root.DisplayOrder + 40)
            if state.Gui.DisplayOrder ~= order then state.Gui.DisplayOrder = order end
            elapsed += delta
            if elapsed < 0.12 then return end
            elapsed = 0
            for _, entry in ipairs(state.Order) do
                if entry.Frame.Parent then
                    if entry.Bind.Mode == 'Always' then
                        if entry.Kind == 'Toggle' then if not entry.Control:GetValue() then entry.Control:SetValue(true) end
                        else entry.Active = true; entry.Control:Fire() end
                    elseif entry.Kind == 'Button' and entry.Active and not UserInputService:GetFocusedTextBox() then entry.Control:Fire() end
                end
            end
            refreshList(state)
        end)
        connect(state, root.Destroying, function() dispose(state) end)
        windows[root], window.BindingState = state, state
        function window:SetKeybindListVisible(value) state.ListVisible = value ~= false; refreshList(state) end
        function window:DestroyKeybinds() dispose(state) end
        function window:GetKeybinds()
            local saved = {}
            for _, entry in ipairs(state.Order) do saved[entry.Id] = {Key = entry.Bind.Key, Mode = entry.Bind.Mode, Visible = entry.Bind.Visible} end
            return saved
        end
        function window:ImportKeybinds(saved, reset) import(state, saved, reset) end
        function window:OpenKeybind(id)
            local entry = state.Entries[state.Aliases[id] or id]
            if entry then popupOpen(state, entry) end
        end
        Fatality.WindowFlags[root].__FatalityBindings = {
            Flag = '__FatalityBindings',
            GetValue = function() return {Bindings = window:GetKeybinds(), ListVisible = state.ListVisible} end,
            SetValue = function(_, value)
                if type(value) ~= 'table' then return end
                import(state, value.Bindings or {}, true)
                window:SetKeybindListVisible(value.ListVisible ~= false)
            end,
        }
        return state
    end

    local createElements = Fatality.CreateElements
    function Fatality:CreateElements(parent, zIndex, event, search)
        local elements = createElements(self, parent, zIndex, event, search)
        for _, method in ipairs({'AddToggle', 'AddButton'}) do
            local create, kind = elements[method], method == 'AddToggle' and 'Toggle' or 'Button'
            elements[method] = function(container, config)
                config = config or {}
                local before = {}
                for _, child in ipairs(parent:GetChildren()) do before[child] = true end
                local control = create(container, config)
                for _, child in ipairs(parent:GetChildren()) do if not before[child] and child:IsA('GuiObject') then control.ElementFrame = child; break end end
                local root = self:GetWindowFromElement(parent)
                local state = windows[root]
                if config.Bindable == false or not state or not control.ElementFrame then return control end
                local id = config.BindId or config.Flag and config.Flag .. kind or (search and search.Path or 'Controls') .. '/' .. (config.Name or kind)
                local base, index = id, 1
                while state.Entries[id] do index += 1; id = base .. '#' .. index end
                local entry = {Id = id, Name = config.Name or kind, Kind = kind, Control = control, Frame = control.ElementFrame,
                    Bind = {Mode = 'Toggle', Visible = true}, Active = false, Held = false}
                state.Entries[id], state.Order[#state.Order + 1], control.Binding = entry, entry, entry
                function control:SetBind(options) setBind(entry, options); refreshList(state); return self end
                function control:GetBind() return {Key = entry.Bind.Key, Mode = entry.Bind.Mode, Visible = entry.Bind.Visible} end
                function control:ClearBind() return self:SetBind({Key = false, Mode = 'Toggle'}) end
                function control:SetBindId(newId)
                    assert(type(newId) == 'string' and newId ~= '', 'BindId must be a non-empty string')
                    assert(not state.Entries[newId] or state.Entries[newId] == entry, 'Duplicate BindId: ' .. newId)
                    local oldId = entry.Id
                    state.Entries[oldId], state.Entries[newId], state.Aliases[oldId], entry.Id = nil, entry, newId, newId
                    for alias, target in pairs(state.Aliases) do if target == oldId then state.Aliases[alias] = newId end end
                    if state.Pending[newId] or state.Pending[oldId] then setBind(entry, state.Pending[newId] or state.Pending[oldId]) end
                    return self
                end
                if state.Pending[id] or config.Bind then setBind(entry, state.Pending[id] or config.Bind) end
                return control
            end
        end
        return elements
    end

    local function position(value)
        value = string.lower(value or 'top')
        assert(value == 'top' or value == 'bottom' or value == 'left' or value == 'right', 'TabsPosition must be top, bottom, left or right')
        return value
    end
    local function decorate(window, menu, config)
        menu.Tabs, menu.TabsPosition = {}, position(config.TabsPosition)
        local nativeSelect = menu.State.ValueSelect
        menu.State.ValueSelect = function(visible)
            nativeSelect(visible)
            if menu.SelectedTab then
                for _, column in ipairs(menu.Columns) do column.Visible = false end
                for _, child in ipairs(menu.Tabs) do child.State.ValueSelect(visible and child == menu.SelectedTab) end
            end
        end
        function menu:Select()
            if self.ParentTab then self.ParentTab:Select(); self.ParentTab:SelectTab(self)
            else
                window.MenuSelected = self.State
                for _, state in ipairs(window.Menus) do state.ValueSelect(state == self.State and window.Toggle) end
            end
            return self
        end
        menu.State.Activate = function() menu:Select() end
        function menu:SelectTab(tab)
            if type(tab) == 'string' then for _, child in ipairs(self.Tabs) do if child.Name == tab then tab = child; break end end end
            assert(type(tab) == 'table' and tab.ParentTab == self, 'Tab must belong to this parent')
            self.SelectedTab = tab
            for _, column in ipairs(self.Columns) do column.Visible = false end
            for _, child in ipairs(self.Tabs) do child.State.ValueSelect(child == tab and self.State.Bindable:GetAttribute('V') == true) end
            return tab
        end
        function menu:SetTabsPosition(value)
            self.TabsPosition = position(value)
            if not self.TabsBar then return self end
            local vertical = self.TabsPosition == 'left' or self.TabsPosition == 'right'
            self.TabsLayout.FillDirection = vertical and Enum.FillDirection.Vertical or Enum.FillDirection.Horizontal
            self.TabsBar.ScrollingDirection = vertical and Enum.ScrollingDirection.Y or Enum.ScrollingDirection.X
            self.TabsBar.AnchorPoint = Vector2.new(self.TabsPosition == 'right' and 1 or 0, self.TabsPosition == 'bottom' and 1 or 0)
            self.TabsBar.Position = UDim2.new(self.TabsPosition == 'right' and 1 or 0, 0, self.TabsPosition == 'bottom' and 1 or 0, 0)
            self.TabsBar.Size = vertical and UDim2.new(0, 112, 1, 0) or UDim2.new(1, 0, 0, 30)
            self.TabContent.Position = UDim2.fromOffset(self.TabsPosition == 'left' and 118 or 0, self.TabsPosition == 'top' and 34 or 0)
            self.TabContent.Size = vertical and UDim2.new(1, -118, 1, 0) or UDim2.new(1, 0, 1, -34)
            for _, child in ipairs(self.Tabs) do child.Button.Size = vertical and UDim2.new(1, -4, 0, 28) or UDim2.fromOffset(106, 28) end
            return self
        end
        function menu:AddTab(options)
            options = options or {}
            if not self.TabsBar then
                self.TabsBar = make('ScrollingFrame', {Name = 'Subtabs', BackgroundTransparency = 1, BorderSizePixel = 0,
                    ScrollBarThickness = 2, ClipsDescendants = true, CanvasSize = UDim2.fromOffset(0, 0)}, self.Root)
                self.TabsLayout = make('UIListLayout', {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, self.TabsBar)
                self.TabContent = make('Frame', {Name = 'TabContent', BackgroundTransparency = 1, BorderSizePixel = 0}, self.Root)
                self._TabLayoutConnection = self.TabsLayout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
                    local size = self.TabsLayout.AbsoluteContentSize
                    self.TabsBar.CanvasSize = UDim2.fromOffset(size.X, size.Y)
                end)
            end
            local child = window:AddMenu({Name = options.Name or 'TAB', Icon = options.Icon or 'folder', AutoFill = options.AutoFill == nil and false or options.AutoFill, TabsPosition = options.TabsPosition})
            local index = table.find(window.Menus, child.State)
            if index then table.remove(window.Menus, index) end
            child.ParentTab, child.Name = self, options.Name or 'TAB'
            child.Root.Parent, child.Button.Parent = self.TabContent, self.TabsBar
            child.Root.Size, child.Root.Position = UDim2.fromScale(1, 1), UDim2.fromOffset(0, 0)
            child.Button.LayoutOrder = #self.Tabs + 1
            local click = child.Button:FindFirstChildOfClass('TextButton')
            if click then click:Destroy() end
            local input = Fatality:NewInput(child.Button, function() self:SelectTab(child) end)
            child.Input = input
            self.Tabs[#self.Tabs + 1] = child
            self:SetTabsPosition(options.Position or self.TabsPosition)
            self:SelectTab(self.SelectedTab or child)
            return child
        end
        return menu
    end
    local newWindow = Fatality.new
    function Fatality.new(config)
        local window = newWindow(config)
        local root = Fatality.Windows[#Fatality.Windows]
        local addMenu = window.AddMenu
        function window:AddMenu(options)
            local menu = addMenu(self, options)
            menu.Name = (options and options.Name) or 'MENU'
            return decorate(self, menu, options or {})
        end
        createBindings(window, root)
        return window
    end
    Fatality.Version = '1.7.0'
end

return install
