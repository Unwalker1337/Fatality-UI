-- Offline Roblox API model. Used with the actual downloaded Fatality-UI source.
local builtinTypeof = typeof
function typeof(value)
    return type(value) == 'table' and rawget(value, '__type') or builtinTypeof(value)
end
local errors, connections, threads = {}, {}, {}
createdObjects={}
controlInstances={}
local function signal()
    local result = {handlers = {}}
    function result:Connect(callback)
        local connection = {Connected = true, callback = callback}
        function connection:Disconnect() self.Connected = false end
        self.handlers[#self.handlers + 1] = connection
        connections[#connections + 1] = connection
        return connection
    end
    function result:Once(callback)
        local connection
        connection = self:Connect(function(...) connection:Disconnect(); callback(...) end)
        return connection
    end
    function result:Wait() coroutine.yield() end
    function result:Fire(...)
        for _, connection in ipairs(self.handlers) do
            if connection.Connected then
                local ok, reason = pcall(connection.callback, ...)
                if not ok then errors[#errors + 1] = reason end
            end
        end
    end
    return result
end
Enum = setmetatable({}, {__index = function(self, category)
    local items = setmetatable({}, {__index = function(values, name)
        local item = {__type = 'EnumItem', Name = name}
        rawset(values, name, item)
        return item
    end})
    rawset(self, category, items)
    return items
end})
local vectorMethods = {}
local vectorMeta = {__index = vectorMethods}
function vectorMeta.__add(a,b) return Vector2.new(a.X+b.X,a.Y+b.Y) end
function vectorMeta.__sub(a,b) return Vector2.new(a.X-b.X,a.Y-b.Y) end
function vectorMeta.__mul(a,b) return Vector2.new(a.X*b,a.Y*b) end
function vectorMeta.__div(a,b) return Vector2.new(a.X/b,a.Y/b) end
Vector2 = {new = function(x,y) return setmetatable({X=x or 0,Y=y or 0,__type='Vector2'},vectorMeta) end}
Vector3 = {new = function(x,y,z) local v=Vector2.new(x,y); v.Z=z or 0; return v end}
UDim = {new = function(scale,offset) return {Scale=scale or 0,Offset=offset or 0} end}
local dimMeta = {}
UDim2 = {new = function(xs,xo,ys,yo) return setmetatable({X=UDim.new(xs,xo),Y=UDim.new(ys,yo),__type='UDim2'},dimMeta) end}
function dimMeta.__add(a,b) return UDim2.new(a.X.Scale+b.X.Scale,a.X.Offset+b.X.Offset,a.Y.Scale+b.Y.Scale,a.Y.Offset+b.Y.Offset) end
function UDim2.fromOffset(x,y) return UDim2.new(0,x,0,y) end
function UDim2.fromScale(x,y) return UDim2.new(x,0,y,0) end
local colorMeta = {__index = {}}
Color3 = {new = function(r,g,b) return setmetatable({R=r or 0,G=g or 0,B=b or 0,__type='Color3'},colorMeta) end}
function Color3.fromRGB(r,g,b) return Color3.new(r/255,g/255,b/255) end
function Color3.fromHex(hex)
    hex = hex:gsub('#','')
    return Color3.fromRGB(tonumber(hex:sub(1,2),16),tonumber(hex:sub(3,4),16),tonumber(hex:sub(5,6),16))
end
function Color3.fromHSV(h,s,v) return Color3.new(v,v*(1-s),v*(1-s)) end
function colorMeta.__eq(a,b) return a.R==b.R and a.G==b.G and a.B==b.B end
function colorMeta.__index:ToHex() return string.format('%02X%02X%02X',math.floor(self.R*255+0.5),math.floor(self.G*255+0.5),math.floor(self.B*255+0.5)) end
function colorMeta.__index:ToHSV() return 0,0,math.max(self.R,self.G,self.B) end
function colorMeta.__index:Lerp(other,alpha) return Color3.new(self.R+(other.R-self.R)*alpha,self.G+(other.G-self.G)*alpha,self.B+(other.B-self.B)*alpha) end
Font = {new = function(...) return {...} end, fromEnum = function(...) return {...} end}
TweenInfo = {new = function(...) return {...} end}
for _, name in ipairs({'NumberSequence','ColorSequence','NumberSequenceKeypoint','ColorSequenceKeypoint','NumberRange','Rect'}) do
    getfenv()[name] = {new = function(...) return {...} end}
end
local objectMethods, objectMeta = {}, {}
local signalNames = {InputBegan=true,InputEnded=true,InputChanged=true,Changed=true,MouseEnter=true,MouseLeave=true,
    MouseButton1Click=true,WindowFocusReleased=true,FocusLost=true,Focused=true,Destroying=true,RenderStepped=true,Heartbeat=true,Completed=true,Event=true}
function objectMeta.__index(self,key)
    if objectMethods[key] then return objectMethods[key] end
    local properties = rawget(self,'properties')
    if properties[key] ~= nil then return properties[key] end
    if signalNames[key] then properties[key]=signal(); return properties[key] end
    if key == 'AbsoluteSize' or key == 'TextBounds' then return Vector2.new(1000,640) end
    if key == 'AbsolutePosition' or key == 'AbsoluteContentSize' then return Vector2.new(0,0) end
    if key == 'ZIndex' then return 1 end
    if key == 'DisplayOrder' then return 0 end
    if key == 'BackgroundTransparency' or key == 'TextTransparency' then return 0 end
    if key == 'Visible' or key == 'Enabled' then return true end
    return nil
end
function objectMeta.__newindex(self,key,value)
    local properties = rawget(self,'properties')
    if key == 'Parent' and properties.Parent ~= value then
        local previous = properties.Parent
        if previous then
            local index = table.find(previous.children,self)
            if index then table.remove(previous.children,index) end
        end
        if value then table.insert(value.children,self) end
    end
    properties[key] = value
end
Instance = {new = function(class,parent)
    local result = setmetatable({__type='Instance',properties={ClassName=class,Name=class},children={},attributes={},changes={}},objectMeta)
    if parent then result.Parent=parent end
    createdObjects[#createdObjects+1]=result
    return result
end}
function objectMethods:IsA(class)
    return self.ClassName==class or class=='Instance' or class=='GuiObject' and table.find({'Frame','TextLabel','TextBox','TextButton','ImageButton','ImageLabel','ScrollingFrame'},self.ClassName)~=nil
end
function objectMethods:GetChildren() return table.clone(self.children) end
function objectMethods:GetDescendants()
    local children = {}
    for _, child in ipairs(self.children) do
        table.insert(children,child)
        for _, descendant in ipairs(child:GetDescendants()) do table.insert(children,descendant) end
    end
    return children
end
function objectMethods:FindFirstChild(name,recursive)
    for _,child in ipairs(recursive and self:GetDescendants() or self.children) do if child.Name==name then return child end end
end
function objectMethods:FindFirstChildOfClass(class)
    for _,child in ipairs(self.children) do if child:IsA(class) then return child end end
end
function objectMethods:FindFirstAncestorOfClass(class)
    local parent=self.Parent
    while parent do if parent:IsA(class) then return parent end; parent=parent.Parent end
end
function objectMethods:IsDescendantOf(parent)
    local current=self.Parent
    while current do if current==parent then return true end; current=current.Parent end
    return false
end
function objectMethods:GetAttribute(name) return self.attributes[name] end
function objectMethods:SetAttribute(name,value) self.attributes[name]=value end
function objectMethods:GetPropertyChangedSignal(name)
    self.changes[name]=self.changes[name] or signal()
    return self.changes[name]
end
function objectMethods:Destroy()
    self.Destroying:Fire()
    for _,child in ipairs(self:GetChildren()) do child:Destroy() end
    self.Parent=nil
    self.properties.Destroyed=true
end
function objectMethods:Fire(...) self.Event:Fire(...) end
local folders, files, json = {}, {}, {}
local function clone(value)
    if type(value)~='table' then return value end
    local result={}
    for key,entry in pairs(value) do result[key]=clone(entry) end
    return result
end
function isfolder(path) return folders[path] or false end
function makefolder(path) folders[path]=true end
function isfile(path) return files[path]~=nil end
function writefile(path,value) files[path]=value end
function readfile(path) assert(files[path],path); return files[path] end
function delfile(path) files[path]=nil end
function listfiles(path)
    local result={}
    for name in pairs(files) do if name:sub(1,#path+1)==path..'/' and not name:sub(#path+2):find('/') then result[#result+1]=name end end
    return result
end
local services={}
game=Instance.new('DataModel')
function game:GetService(name) return services[name] end
function game:HttpGet() return LIB_SOURCE end
workspace=Instance.new('Workspace',game)
workspace.CurrentCamera=Instance.new('Camera',workspace)
workspace.CurrentCamera.ViewportSize=Vector2.new(1280,800)
for _,name in ipairs({'Players','RunService','CoreGui','UserInputService','TweenService','TextService','HttpService','GuiService','Lighting'}) do services[name]=Instance.new(name,game) end
services.RunService.IsStudio=function() return false end
services.UserInputService.TouchEnabled=false
services.UserInputService.GetFocusedTextBox=function() return nil end
services.UserInputService.GetMouseLocation=function() return Vector2.new(100,100) end
services.Players.LocalPlayer={Name='Tester',DisplayName='Tester',UserId=1,GetMouse=function() return {X=10,Y=10} end}
services.Players.GetUserThumbnailAsync=function() return 'rbxassetid://1' end
services.TextService.GetTextSize=function(_,text) return Vector2.new(#text*7,15) end
services.GuiService.GetGuiInset=function() return Vector2.new(0,0) end
services.HttpService.JSONEncode=function(_,value) json[#json+1]=clone(value); return 'json:'..#json end
services.HttpService.JSONDecode=function(_,value) return clone(assert(json[tonumber(value:match('json:(%d+)'))],value)) end
services.TweenService.Create=function(_,target,info,properties)
    return {Completed=signal(), Play=function() for key,value in pairs(properties) do target[key]=value end end,Cancel=function() end}
end
task={}
function task.spawn(callback,...)
    local thread=coroutine.create(callback)
    threads[#threads+1]=thread
    local ok,reason=coroutine.resume(thread,...)
    assert(ok,reason)
    return thread
end
function task.wait() coroutine.yield() end
function task.delay(duration,callback,...) return task.spawn(function(...) task.wait(); callback(...) end,...) end
function task.cancel(thread) if coroutine.status(thread)~='dead' then coroutine.close(thread) end end
function gethui() return services.CoreGui end
function getgenv() return getfenv() end
function tick() return os.clock() end
aa={conns={},cleanups={},unloaded=false}
function aa.connect(event,callback) local connection=event:Connect(callback); table.insert(aa.conns,connection); return connection end
function aa.onUnload(callback) table.insert(aa.cleanups,callback) end
function aa.unload()
    if aa.unloaded then return end
    aa.unloaded=true
    for _,connection in ipairs(aa.conns) do connection:Disconnect() end
    for i=#aa.cleanups,1,-1 do aa.cleanups[i]() end
end

