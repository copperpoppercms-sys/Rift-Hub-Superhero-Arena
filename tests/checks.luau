-- A minimal simulated Roblox client; exercises the complete standalone file.
local allSignals, allInstances, checks = {}, {}, 0
math.randomseed(145)
local function check(value, message)
	checks += 1
	assert(value, message)
end
local function signal()
	local s = { handlers = {} }; table.insert(allSignals, s)
	function s:Connect(fn)
		local c = { Connected = true, fn = fn, Function = fn }
		function c:Disconnect() self.Connected = false end
		table.insert(self.handlers, c)
		return c
	end
	function s:Fire(...)
		for _, c in ipairs(table.clone(self.handlers)) do if c.Connected then c.fn(...) end end
	end
	return s
end
local function enum()
	return setmetatable({}, { __index = function(t, key) local v = enum(); rawset(t, key, v); return v end })
end
local Enum = enum()
Enum.RenderPriority.Camera.Value = 200
local V2 = {}
V2.__index = function(t, k) if k == "Magnitude" then return math.sqrt(t.X*t.X+t.Y*t.Y) end; return V2[k] end
V2.__add = function(a,b) return setmetatable({ X=a.X+b.X, Y=a.Y+b.Y }, V2) end
V2.__sub = function(a,b) return setmetatable({ X=a.X-b.X, Y=a.Y-b.Y }, V2) end
V2.__eq = function(a,b) return a.X == b.X and a.Y == b.Y end
V2.__mul = function(a,b) return setmetatable({X=a.X*b,Y=a.Y*b},V2) end
local Vector2 = { new = function(x,y) return setmetatable({ X=x or 0, Y=y or 0 }, V2) end }
local V3 = {}
V3.__index = function(t,k)
	if k == "Magnitude" then return math.sqrt(t.X*t.X+t.Y*t.Y+t.Z*t.Z) end
	if k == "Unit" then local m=math.sqrt(t.X*t.X+t.Y*t.Y+t.Z*t.Z); return setmetatable({X=t.X/m,Y=t.Y/m,Z=t.Z/m},V3) end
	return V3[k]
end
V3.__sub = function(a,b) return setmetatable({ X=a.X-b.X,Y=a.Y-b.Y,Z=a.Z-b.Z }, V3) end
V3.__add = function(a,b) return setmetatable({ X=a.X+b.X,Y=a.Y+b.Y,Z=a.Z+b.Z }, V3) end
V3.__mul = function(a,b) if type(a)=="number" then a,b=b,a end; return setmetatable({ X=a.X*b,Y=a.Y*b,Z=a.Z*b }, V3) end
function V3:Dot(b) return self.X*b.X+self.Y*b.Y+self.Z*b.Z end
local Vector3 = { new = function(x,y,z) return setmetatable({ X=x or 0,Y=y or 0,Z=z or 0 }, V3) end }
local RaycastParams={new=function() return {} end}
local UDim = { new = function(scale, offset) return { Scale=scale or 0, Offset=offset or 0 } end }
local UDim2 = {
	new = function(xs,xo,ys,yo) return { X=UDim.new(xs,xo), Y=UDim.new(ys,yo) } end,
	fromOffset = function(x,y) return { X=UDim.new(0,x), Y=UDim.new(0,y) } end,
	fromScale = function(x,y) return { X=UDim.new(x,0), Y=UDim.new(y,0) } end,
}
local Color3 = { new=function(...) return {...} end, fromRGB=function(...) return {...} end, fromHSV=function(...) return {...} end }
local ColorSequence = { new=function(...) return {...} end }
local TweenInfo = { new=function(...) return {...} end }
local pending = {}
local spawned={}
local task = { delay = function(_,fn) table.insert(pending,fn) end,spawn=function(fn) table.insert(spawned,fn) end }
local function flushSpawn() local jobs=spawned; spawned={}; for _,fn in ipairs(jobs) do fn() end end
local function flush() local calls=pending; pending={}; for _,fn in ipairs(calls) do fn() end end
local lookCalls, lastLook, lastAlpha = 0,nil,nil
local CFrame = {}
function CFrame.lookAt(position, point)
	local frame={Position=position,Point=point,LookVector=(point-position).Unit}
	function frame:Lerp(goal) return CFrame.lookAt(goal.Position,goal.Point) end
	return frame
end
local cameraFrame = {Position=Vector3.new(),LookVector=Vector3.new(0,0,-1)}
function cameraFrame:Lerp(goal, alpha)
	self.LookVector=(goal.Point-goal.Position).Unit
	lookCalls+=1; lastLook=goal.Point; lastAlpha=alpha
	return self
end
local camera = { FieldOfView=70, ViewportSize=Vector2.new(1280,720), CFrame=cameraFrame }

function camera:WorldToViewportPoint(p) return Vector3.new(640+p.X*10,360-p.Y*10,20),true end
local instanceMethods = {}
local guiClasses = { Frame=true, CanvasGroup=true, TextLabel=true, TextButton=true, TextBox=true, ScrollingFrame=true, ImageLabel=true, ImageButton=true }
local function isA(node, class)
	return node.ClassName == class or class == "Instance" or (class == "GuiObject" and guiClasses[node.ClassName])
		or (class == "GuiButton" and (node.ClassName == "TextButton" or node.ClassName == "ImageButton"))
		or (class == "BasePart" and (node.ClassName == "Part" or node.ClassName == "MeshPart"))
end
local mt = {}
mt.__index = function(t, key)
	if instanceMethods[key] then return instanceMethods[key] end
	local props=rawget(t,"_props")
	if key == "AbsoluteSize" then
		if props.ClassName == "ScreenGui" or props.ClassName == "Workspace" or not props.Parent then return camera.ViewportSize end
		local parentSize = props.Parent.AbsoluteSize
		local size=props.Size or UDim2.fromOffset(100,40)
		local scale=1
		for _, child in ipairs(rawget(t,"_children")) do if child.ClassName == "UIScale" then scale=child.Scale end end
		return Vector2.new((parentSize.X*size.X.Scale+size.X.Offset)*scale,(parentSize.Y*size.Y.Scale+size.Y.Offset)*scale)
	end
	if key == "AbsolutePosition" then
		local pos=props.Position or UDim2.new()
		local ps=props.Parent and props.Parent.AbsoluteSize or camera.ViewportSize
		return Vector2.new(ps.X*pos.X.Scale+pos.X.Offset,ps.Y*pos.Y.Scale+pos.Y.Offset)
	end
	return props[key]
end
mt.__newindex = function(t, key, value)
	local props = rawget(t,"_props")
	if key == "Parent" then
		if props.Parent then
			local children=rawget(props.Parent,"_children")
			local index=table.find(children,t); if index then table.remove(children,index) end
		end
		if value then table.insert(rawget(value,"_children"),t) end
	end
	props[key]=value
	local event = rawget(t,"_changes")[key]; if event then event:Fire() end
end
local Instance = {}
function Instance.new(class)
	local obj=setmetatable({ _props={ClassName=class,Name=class,Visible=true,Enabled=true,Text="",Health=100,MaxHealth=100,AssemblyLinearVelocity=Vector3.new(),
		IgnoreGuiInset=false,DisplayOrder=0,GroupTransparency=0,AbsoluteRotation=0,CanCollide=true},
		_children={},_attributes={},_changes={},_destroyed=false },mt)
	for _,name in ipairs({"Destroying","MouseEnter","MouseLeave","Activated","MouseButton1Click","MouseButton1Down","MouseButton1Up","InputBegan","AnimationPlayed"}) do obj[name]=signal() end
	table.insert(allInstances,obj); return obj
end
function instanceMethods:IsA(class) return isA(self,class) end
function instanceMethods:GetChildren() return table.clone(rawget(self,"_children")) end
function instanceMethods:GetDescendants()
	local result={}
	local function visit(parent)
		for _,child in ipairs(parent:GetChildren()) do table.insert(result,child); visit(child) end
	end
	visit(self); return result
end
function instanceMethods:GetAttributes() return table.clone(rawget(self,"_attributes")) end
function instanceMethods:SetAttribute(key,value) rawget(self,"_attributes")[key]=value end
function instanceMethods:GetAttribute(key) return rawget(self,"_attributes")[key] end
function instanceMethods:FindFirstChild(name)
	for _,child in ipairs(self:GetChildren()) do if child.Name==name then return child end end
end
function instanceMethods:FindFirstChildOfClass(class)
	for _,child in ipairs(self:GetChildren()) do if child:IsA(class) then return child end end
end
function instanceMethods:FindFirstAncestorWhichIsA(class)
	local parent=self.Parent
	while parent do if parent:IsA(class) then return parent end; parent=parent.Parent end
end
function instanceMethods:GetFullName() return self.Parent and self.Parent:GetFullName().."."..self.Name or self.Name end
function instanceMethods:GetPropertyChangedSignal(name)
	local changes=rawget(self,"_changes"); if not changes[name] then changes[name]=signal() end; return changes[name]
end
function instanceMethods:WaitForChild(name) return assert(self:FindFirstChild(name)) end
function instanceMethods:IsDescendantOf(parent)
	local ancestor=self.Parent
	while ancestor do if ancestor==parent then return true end; ancestor=ancestor.Parent end
	return false
end
local guiHits={}
function instanceMethods:GetGuiObjectsAtPosition() return guiHits[self] or {} end
function instanceMethods:ReleaseFocus() end
function instanceMethods:Move(direction) self.LastMove=direction end
function instanceMethods:MoveTo(position) self.LastMoveTo=position; self.Moves=(self.Moves or 0)+1 end
function instanceMethods:ChangeState(state) self.LastState=state end
function instanceMethods:Activate() self.Activations=(self.Activations or 0)+1 end
function instanceMethods:GetBoundingBox()
	return { PointToWorldSpace=function(_,p) return p end },Vector3.new(4,6,2)
end
local loadedTracks={}
function instanceMethods:LoadAnimation(animation)
	local track=Instance.new("AnimationTrack"); track.Animation=animation; track.Name=animation.Name
	track.Length=0.24; track.IsPlaying=false; track.Animator=self
	table.insert(loadedTracks,track); return track
end
function instanceMethods:Play() self.IsPlaying=true; if self.Animator then self.Animator.AnimationPlayed:Fire(self) end end
function instanceMethods:Stop() self.IsPlaying=false end
function instanceMethods:Destroy()
	if rawget(self,"_destroyed") then return end
	rawset(self,"_destroyed",true); self.Destroying:Fire()
	for _,child in ipairs(self:GetChildren()) do child:Destroy() end
	for _,v in pairs(rawget(self,"_props")) do if type(v)=="table" and v.handlers then for _,c in ipairs(v.handlers) do c:Disconnect() end end end
	for _,v in pairs(rawget(self,"_changes")) do for _,c in ipairs(v.handlers) do c:Disconnect() end end
	self.Parent=nil
end
local function node(class,name,parent,value)
	local obj=Instance.new(class); obj.Name=name; obj.Parent=parent
	if value~=nil then obj.Value=value end
	return obj
end
local workspace = node("Workspace","Workspace"); workspace.Gravity=196.2; workspace.CurrentCamera=camera
local wall=false
local forcedHit
local ground=true
function workspace:Raycast(origin,direction) if direction and direction.Y < -2 then return ground and {Instance=workspace} or nil end; return forcedHit and {Instance=forcedHit} or wall and {Instance=workspace} or nil end
local blockcasts=0
function workspace:Blockcast() blockcasts+=1; return wall and {Instance=workspace} or nil end
local replicated=node("Folder","ReplicatedStorage")
local players = node("Players","Players"); players.PlayerRemoving=signal()
local people={}
function players:GetPlayers() return table.clone(people) end
local function player(name,id)
	local p=node("Player",name,players); p.UserId=id; p.DisplayName=name.." Display"
	table.insert(people,p); return p
end
local localPlayer=player("Owner",1); players.LocalPlayer=localPlayer
local other=player("Other",2)
local function character(plr)
	local model=node("Model",plr.Name,workspace)
	local head=node("Part","Head",model); head.Position=Vector3.new(0,4,0)
	local root=node("Part","HumanoidRootPart",model); root.Position=Vector3.new()
	root.AssemblyLinearVelocity=Vector3.new(); root.Anchored=false
	root.Size=Vector3.new(2,2,1)
	root.CFrame=CFrame.lookAt(root.Position,root.Position+Vector3.new(0,0,-1))
	model.PrimaryPart=root
	local h=node("Humanoid","Humanoid",model); h.JumpPower=50; h.JumpHeight=7.2; h.UseJumpPower=true; h.MoveDirection=Vector3.new(); h.WalkSpeed=16; h.AutoRotate=true
	node("Animator","Animator",h); plr.Character=model
	return model
end
character(localPlayer); character(other)
node("PlayerGui","PlayerGui",localPlayer)
local coreGui=node("CoreGui","CoreGui")
local run={ Heartbeat=signal(), RenderStepped=signal(),PreSimulation=signal() }
local renderBindings={}
function run:BindToRenderStep(name, priority, fn) renderBindings[name]={priority=priority,fn=fn} end
function run:UnbindFromRenderStep(name) renderBindings[name]=nil end
local function renderAim(dt) for _,binding in pairs(renderBindings) do binding.fn(dt or 1/60) end end
local focusedBox
local input={ InputBegan=signal(),InputChanged=signal(),InputEnded=signal(),WindowFocusReleased=signal(),WindowFocused=signal(),JumpRequest=signal(),GetFocusedTextBox=function() return focusedBox end }
local tweens={ Create=function(_,item,_,props)
	return { Cancel=function() end, Play=function() for k,v in pairs(props) do item[k]=v end end }
end }
local sentKeys, sentMouse, sentTouches, rejectKeys = {},{},{},false
local vim={SendKeyEvent=function(_,down,key)
	if rejectKeys then error("virtual input unavailable") end
	table.insert(sentKeys,{down=down,key=key})
end,SendMouseButtonEvent=function(_,x,y,button,down) table.insert(sentMouse,{down=down,x=x,y=y}) end,
SendTouchEvent=function(_,id,state,x,y) table.insert(sentTouches,{id=id,state=state,x=x,y=y}) end}
local lighting=node("Lighting","Lighting")
lighting.Brightness=1; lighting.Ambient="Ambient"; lighting.OutdoorAmbient="Outdoor"; lighting.GlobalShadows=true; lighting.FogStart=15; lighting.FogEnd=400
local atmosphere=node("Atmosphere","Atmosphere",lighting); atmosphere.Density=0.4; atmosphere.Haze=2
local teleports,lastTeleport=0,nil
local teleportService={TeleportToPlaceInstance=function(_,place,job,plr) teleports+=1; lastTeleport=job end,Teleport=function() teleports+=1 end}
local pathSuccess=true
local pathPoints={}
local pathfinder={CreatePath=function()
	return {ComputeAsync=function(self,origin,goal) self.Origin=origin; self.Goal=goal; self.Status=pathSuccess and Enum.PathStatus.Success or Enum.PathStatus.NoPath end,GetWaypoints=function(self) if #pathPoints>0 then return pathPoints end; return {{Position=self.Origin},{Position=self.Goal}} end}
end}
local nativeActions={}
local services={ContextActionService={GetAllBoundActionInfo=function() return nativeActions end},GuiService={GetGuiInset=function() return Vector2.new(0,36) end},PathfindingService=pathfinder,TeleportService=teleportService,Lighting=lighting,Players=players,RunService=run,UserInputService=input,TweenService=tweens,CoreGui=coreGui,VirtualInputManager=vim,ReplicatedStorage=replicated}
local game={PlaceId=123456,JobId="current-server",GetService=function(_,name) return assert(services[name],name) end}
local env={}
local warnings={}
local warn=function(value) table.insert(warnings,value) end
local getgenv=function() return env end
local clipboard
local setclipboard=function(value) clipboard=value end
local firesignal=function(s,...) s:Fire(...) end
local getconnections=function(s)
	local connected={}; for _,c in ipairs(s.handlers) do if c.Connected then table.insert(connected,c) end end
	return connected
end
local function boot()
-- INSERT STANDALONE HUB
end
local function find(root,class,text)
	if root.ClassName==class and root.Text==text then return root end
	for _,child in ipairs(root:GetChildren()) do local result=find(child,class,text); if result then return result end end
end
local function findName(root,name)
	if root.Name==name then return root end
	for _,child in ipairs(root:GetChildren()) do local result=findName(child,name); if result then return result end end
end
local api=boot()
check(api.Version=="4.6" and not api.Enabled,"auto play should start off")
local play=findName(api.Gui,"Play")
check(play and play.Text=="PLAY","one Play button missing")
local buttons=0
for _,item in ipairs(api.Gui:GetDescendants()) do
	if item:IsA("GuiButton") then buttons+=1 end
	check(not item:IsA("ScrollingFrame"),"tabs or scrolling panels remain")
end
check(buttons==2,"UI should contain only Play and close")
local own=localPlayer.Character; local hum=own:FindFirstChildOfClass("Humanoid"); local root=own:FindFirstChild("HumanoidRootPart")
local target=other.Character; local enemyHum=target:FindFirstChildOfClass("Humanoid"); local enemyRoot=target:FindFirstChild("HumanoidRootPart")
enemyRoot.Position=Vector3.new(5,0,0)
local hud=node("ScreenGui","NativeHUD",localPlayer:FindFirstChild("PlayerGui"))
local attack=node("TextButton","AttackButton",hud); attack.Text="Attack"
local primary=node("TextButton","PrimarySkill",hud); primary:SetAttribute("SkillName","Repulsor Blast")
local tertiary=node("TextButton","TertiarySkill",hud); tertiary:SetAttribute("SkillName","Unibeam")
local hits,p1,p3=0,0,0
attack.MouseButton1Click:Connect(function() hits+=1 end)
primary.Activated:Connect(function() p1+=1 end)
tertiary.Activated:Connect(function() p3+=1 end)
own:SetAttribute("MorphCurrent","Iron Man")
local function tick(n)
	for _=1,n do api.Step(0.1); renderAim(0.1); flush() end
end
play.Activated:Fire(); tick(5)
check(api.Enabled and play.Text=="STOP" and api.Target==other,"Play did not enable and select target")
check(p1==1 and hum.AutoRotate==false,"auto play did not face and request the opening skill")
check(root.CFrame.Position==root.Position and root.CFrame.Point.X==5,"facing moved the character or aimed wrongly")
check(lastLook.X==5 and lastAlpha>0 and lastAlpha<1,"camera target aiming missing")
check(hum.WalkSpeed==16 and enemyRoot.Size.X==2,"removed speed/hitbox changes remain")
tick(12)
check(p1>=1 and p3>=1,"automatic available skill rotation missing")
primary:SetAttribute("OnCooldown",true); tertiary:SetAttribute("Ready",false)
local skillTotal=p1+p3; tick(10)
check(p1+p3==skillTotal,"known ability cooldowns ignored")
primary:SetAttribute("OnCooldown",nil); tertiary:SetAttribute("Ready",nil)
focusedBox={}; local before=hits; tick(8)
check(hits==before and hum.AutoRotate==true,"typing did not pause and restore control")
focusedBox=nil; input.WindowFocusReleased:Fire(); tick(8)
check(hits==before,"unfocused auto play attacked")
input.WindowFocused:Fire(); camera.CameraType=Enum.CameraType.Scriptable; tick(8)
check(hits==before and hum.AutoRotate==true,"cutscene camera was overridden")
camera.CameraType=Enum.CameraType.Custom
root.Anchored=true; tick(8)
check(hits==before,"anchored character tried attacking")
root.Anchored=false
local teammate=player("Teammate",3); local teamChar=character(teammate); teamChar:FindFirstChild("HumanoidRootPart").Position=Vector3.new(1,0,0)
localPlayer.Team="Blue"; teammate.Team="Blue"; other.Team="Red"
api.SetEnabled(false); api.SetEnabled(true); tick(2)
check(api.Target==other,"teammate incorrectly selected")
localPlayer.Team=nil; teammate.Team=nil; other.Team=nil
teamChar:FindFirstChildOfClass("Humanoid").Health=0
local replacement=player("Replacement",4); local replacementChar=character(replacement); replacementChar:FindFirstChild("HumanoidRootPart").Position=Vector3.new(2,0,0)
tick(2)
check(api.Target==other,"valid target was not retained")
enemyHum.Health=0; tick(2)
check(api.Target==replacement,"dead target not replaced")
enemyHum.Health=100; replacementChar:FindFirstChildOfClass("Humanoid").Health=0
api.SetEnabled(false); api.SetEnabled(true); enemyRoot.Position=Vector3.new(35,0,0); tick(2)
check((hum.LastMoveTo-enemyRoot.Position).Magnitude<0.001,"normal walking chase missing")
local hitBefore=hits
tick(8)
check(hits==hitBefore,"melee attacks sent outside melee range")
local waypoint=Vector3.new(0,0,12)
pathPoints={{Position=root.Position},{Position=waypoint,Action=Enum.PathWaypointAction.Jump},{Position=enemyRoot.Position}}
wall=true; api.SetEnabled(false); api.SetEnabled(true); tick(1); flushSpawn(); tick(1)
check(hum.LastMoveTo==waypoint and hum.Jump==true,"obstacle route or jump waypoint missing")
check(hits==hitBefore,"attacked through blocked line of sight")
root.Position=waypoint; tick(1)
check((hum.LastMoveTo-enemyRoot.Position).Magnitude<0.001,"waypoint route did not advance")
root.Position=Vector3.new()
api.SetEnabled(false); api.SetEnabled(true); tick(1)
api.SetEnabled(false); local stopped=hum.LastMoveTo; flushSpawn()
check(hum.LastMoveTo==stopped and not api.Enabled,"stale path resumed movement after Stop")
pathSuccess=false; api.SetEnabled(true); tick(1); flushSpawn(); tick(1)
check(api.Target==nil,"unreachable target was not released")
pathSuccess=true; wall=false; enemyRoot.Position=Vector3.new(5,0,0)
api.SetEnabled(false); hum.AutoRotate=false; api.SetEnabled(true); tick(1); api.SetEnabled(false)
check(hum.AutoRotate==false,"original false AutoRotate setting lost")
hum.AutoRotate=true
-- Confirm real key input handlers release promptly and stale callbacks stay harmless.
primary:Destroy(); tertiary:Destroy(); attack.Visible=false
local skill=node("TextButton","PrimarySkill",hud); skill:SetAttribute("KeyCode","E")
own:SetAttribute("MorphCurrent","Hulk")
input.TouchEnabled=true
api.SetEnabled(true)
for _=1,10 do api.Step(0.1); renderAim(0.1) end
check(#sentKeys>0 and sentKeys[#sentKeys].down,"detected skill key was not pressed")
api.SetEnabled(false)
check(not sentKeys[#sentKeys].down,"Stop left a native skill key held")
local keyCount=#sentKeys; flush()
check(#sentKeys==keyCount,"stale delayed release sent input after Stop")
-- Replacing a target rig invalidates an in-flight path and allows a fresh route.
wall=true; api.SetEnabled(true); tick(1)
local fresh=character(other); fresh:FindFirstChild("HumanoidRootPart").Position=Vector3.new(20,0,0)
tick(1); flushSpawn(); tick(1)
check(api.Target==other,"respawned target was lost during path replacement")
api.SetEnabled(false)
check(hum.AutoRotate==true,"Stop after path replacement did not restore rotation")
-- Stateful exchanges: metadata ordering, channel/recovery windows, spacing and native dash.
local function advancedChecks()
	api.Unload(); hud:Destroy(); wall=false; ground=true; input.TouchEnabled=true
	hud=node("ScreenGui","NativeHUD",localPlayer:FindFirstChild("PlayerGui"))
	root.Position=Vector3.new(); hum.Health=100; hum.AutoRotate=true
	local enemy=other.Character:FindFirstChild("HumanoidRootPart"); enemy.Position=Vector3.new(5,0,0)
	own:SetAttribute("MorphCurrent","Iron Man"); own:SetAttribute("busy",false)
	local a=node("TextButton","AttackButton",hud); a.Text="Attack"
	local one=node("TextButton","PrimarySkill",hud); one:SetAttribute("SkillName","Repulsor Blast"); one:SetAttribute("ComboOrder",2); one:SetAttribute("CooldownDuration",5)
	local beam=node("TextButton","TertiarySkill",hud); beam:SetAttribute("SkillName","Unibeam"); beam:SetAttribute("ComboOrder",1); beam:SetAttribute("CastTime",0.2); beam:SetAttribute("ChannelTime",0.6); beam:SetAttribute("RecoveryTime",0.3); beam:SetAttribute("CooldownDuration",5)
	local ult=node("TextButton","Ultimate",hud); ult:SetAttribute("SkillSlot",5); ult:SetAttribute("ComboOrder",3); ult:SetAttribute("CooldownDuration",5)
	local locked=node("TextButton","Skill4",hud); locked:SetAttribute("Available",false)
	local lockedCalls,ultimateCalls=0,0
	locked.Activated:Connect(function() lockedCalls+=1 end)
	ult.Activated:Connect(function() ultimateCalls+=1 end)
	local events={}; local clock=0
	a.Activated:Connect(function() table.insert(events,{Name="Melee",Time=clock}) end)
	one.Activated:Connect(function() table.insert(events,{Name="Primary",Time=clock}) end)
	beam.Activated:Connect(function() table.insert(events,{Name="Beam",Time=clock}) end)
	api=boot(); api.SetEnabled(true)
	local function advance(n,move)
		for _=1,n do if move then root.Position=root.Position+Vector3.new(0.2,0,0) end; clock+=0.1; api.Step(0.1); renderAim(0.1); flush() end
	end
	advance(5)
	check(events[1] and events[1].Name=="Beam","explicit combo order ignored")
	local eventCount=#events
	advance(4)
	check(#events==eventCount and hum.LastMoveTo==root.Position,"channel was interrupted by movement or another action")
	api.SetEnabled(false); api.SetEnabled(true); advance(3)
	check(#events==eventCount,"Stop/restart bypassed remaining cast recovery")
	advance(6)
	check(events[2] and events[2].Name=="Primary" and events[2].Time-events[1].Time>=1.1-0.001,"recovery or next ability ordering failed")
	check(api.Brain.MoveGoal and (api.Brain.MoveGoal-root.Position).Magnitude>0,"no spacing movement between exchanges")
	advance(15)
	local lastMelee,meleeCount=nil,0
	for _,e in ipairs(events) do if e.Name=="Melee" then if lastMelee then check(e.Time-lastMelee>=0.35,"melee inputs were spammed") end; lastMelee=e.Time; meleeCount+=1 end end
	check(meleeCount>=2,"melee fillers between skill cooldowns missing")
	check(ultimateCalls>=1,"exposed extra power slot did not join the combo")
	check(lockedCalls==0,"locked or unavailable power was activated")
	own:SetAttribute("busy",true); eventCount=#events; advance(8)
	check(#events==eventCount,"cast requests ignored native busy state")
	own:SetAttribute("busy",false); own:SetAttribute("canAttack",false); advance(5)
	check(#events==eventCount,"native canAttack gate ignored")
	own:SetAttribute("canAttack",true); other.Character:SetAttribute("iframes",true); advance(5)
	check(#events==eventCount,"skills wasted during known target invulnerability")
	other.Character:SetAttribute("iframes",nil)
	-- Known projectile metadata affects the aim lead; hitscan removes it.
	api.Brain.Cast=nil; api.Brain.AimSkill={Button=one}; one:SetAttribute("ProjectileSpeed",50)
	enemy.AssemblyLinearVelocity=Vector3.new(10,0,0); api.Aim(0.1)
	check(math.abs(lastLook.X-(enemy.Position.X+1))<0.001,"projectile-speed prediction not used")
	one:SetAttribute("Hitscan",true); api.Aim(0.1)
	check(lastLook.X==enemy.Position.X,"hitscan aiming incorrectly led the target")
	one:SetAttribute("Hitscan",nil); enemy.AssemblyLinearVelocity=Vector3.new()
	-- Dash uses the real button, measured spacing and native cooldown flags.
	api.Unload(); one:Destroy(); beam:Destroy(); ult:Destroy(); locked:Destroy()
	local dash=node("TextButton","DashButton",hud); dash.Text="Dash"; dash:SetAttribute("CooldownDuration",2.5)
	local dashes=0; dash.Activated:Connect(function() dashes+=1 end)
	root.Position=Vector3.new(); enemy.Position=Vector3.new(25,0,0)
	api=boot(); api.SetEnabled(true); advance(5)
	check(dashes==1 and api.Brain.StillUntil>0,"native gap-closing dash missing")
	advance(1,true)
	check(hum.LastMove.Magnitude>0.9,"dash steering was released during native recovery")
	advance(19,true)
	check(dashes==1,"dash repeated before its cooldown")
	enemy.Position=root.Position+Vector3.new(6,0,0)
	advance(7,true)
	dash:SetAttribute("OnCooldown",true); hum.Health=90; advance(1)
	check(dashes==1,"defensive dash ignored native cooldown")
	dash:SetAttribute("OnCooldown",false); advance(1)
	check(dashes==2 and math.abs(hum.LastMove.X)<0.01 and math.abs(hum.LastMove.Z)>0.9,"damage response did not request lateral native dash")
	api.SetEnabled(false)
	check(hum.LastMove.Magnitude==0 and hum.AutoRotate==true,"Stop left dash steering or rotation held")
	-- No gap-closing dash may be sent when ground cannot be verified.
	api.Unload(); ground=false; root.Position=Vector3.new(); enemy.Position=Vector3.new(25,0,0)
	api=boot(); api.SetEnabled(true); local previousDashes=dashes; advance(6)
	check(dashes==previousDashes,"dash was requested across unverified ground")
	ground=true; hum.Health=100; api.SetEnabled(false)
end
advancedChecks()

-- Regression: a mobile HUD without Activated/Click listeners still gets real taps.
local function mobileRegressionChecks()
	api.Unload(); hud:Destroy(); wall=false; input.TouchEnabled=true
	hud=node("ScreenGui","NativeHUD",localPlayer:FindFirstChild("PlayerGui"))
	local frame=node("Frame","Skill1",hud)
	local button=node("ImageButton","ImageButton",frame)
	button.Position=UDim2.fromOffset(50,60); button.Size=UDim2.fromOffset(80,40)
	local key=node("TextLabel","Keybind",frame); key.Text=""
	local caption=node("TextLabel","Caption",frame); caption.Text="Test skill"
	root.Position=Vector3.new(); local enemy=other.Character:FindFirstChild("HumanoidRootPart"); enemy.Position=Vector3.new(10,0,0)
	local before=#sentTouches
	api=boot(); api.SetEnabled(true); tick(6)
	check(#sentTouches>=before+2,"mobile InputBegan-only button received no touch pair")
	local touch=sentTouches[before+1]
	check(touch.state==Enum.UserInputState.Begin and touch.x==90 and touch.y==116,"mobile button tap coordinates or GUI inset wrong")
	check(sentTouches[before+2].id==touch.id and sentTouches[before+2].state==Enum.UserInputState.End,"mobile tap not released")
	-- Simulate ControlModule overwriting Move each frame: our render pass must restore it.
	hum:Move(Vector3.new()); renderAim(0.1)
	check(hum.LastMove.Magnitude>0.9,"default mobile controls canceled pursuit")
	api.SetEnabled(false)
	check(hum.LastMove.Magnitude==0,"Stop did not release sustained walking")
	local report=api.Diagnostics()
	check(report:find("Skill1.ImageButton",1,true) and report:find("slot=1",1,true),"HUD report lost ancestor slot detection")
	-- Confirm character resolution at the path from the user's actual report.
	local entities=node("Folder","Entities",workspace)
	own.Parent=entities; localPlayer.Character=nil
	api.SetEnabled(true); tick(3)
	check(api.Target==other and api.Diagnostics():find("Workspace.Entities.Owner",1,true),"replicated Entities character fallback failed")
	localPlayer.Character=own; own.Parent=workspace; entities:Destroy()
	api.SetEnabled(false)
	-- Key hints only become bindings when explicitly labeled as keys.
	key.Text="E"; api.SetEnabled(true); local keysBefore=#sentKeys; tick(30)
	check(#sentKeys>keysBefore,"native sibling Keybind label was not detected")
	api.SetEnabled(false); key.Text=""; frame:Destroy()
	local unrelated=node("TextButton","Inventory",hud); unrelated.Text="Inventory"
	api.SetEnabled(true); tick(8)
	check(api.Status=="No attack/skill buttons detected","missing game controls were not reported clearly")
	check(api.Diagnostics():find("Inventory",1,true),"report should expose unknown HUD names")
	-- Runtime failures must stop safely instead of leaving an aim-only controller enabled.
	local raycast=workspace.Raycast
	workspace.Raycast=function() error("simulated raycast failure") end
	tick(1)
	check(not api.Enabled and api.LastError and api.LastError:find("simulated raycast failure",1,true),"runtime exception left bot enabled or hid failure")
	check(hum.LastMove.Magnitude==0 and hum.AutoRotate==true,"error recovery left movement or rotation owned")
	workspace.Raycast=raycast
	api.SetEnabled(false)
end
mobileRegressionChecks()

-- A game can expose its actual bindings through CAS without named HUD buttons.
local function actionBindingChecks()
	api.Unload(); hud:Destroy(); wall=false; ground=true; input.TouchEnabled=true
	hud=node("ScreenGui","NativeHUD",localPlayer:FindFirstChild("PlayerGui"))
	for _,key in ipairs({Enum.KeyCode.Q,Enum.KeyCode.E,Enum.KeyCode.R}) do key.EnumType=Enum.KeyCode end
	nativeActions={CombatDashAction={inputTypes={Enum.KeyCode.Q}},HeroSkill1={inputTypes={Enum.KeyCode.E}},
		HeroSkill3={inputTypes={Enum.KeyCode.R}},CombatAttack={inputTypes={Enum.UserInputType.MouseButton1}},
		OpenShop={inputTypes={Enum.KeyCode.P}}}
	root.Position=Vector3.new(); hum.Health=100; own:SetAttribute("MorphCurrent","Iron Man")
	local enemy=other.Character:FindFirstChild("HumanoidRootPart"); enemy.Position=Vector3.new(25,0,0)
	api=boot(); api.SetEnabled(true)
	local keysBefore=#sentKeys; tick(6)
	local dashed=false
	for i=keysBefore+1,#sentKeys do if sentKeys[i].key==Enum.KeyCode.Q and sentKeys[i].down then dashed=true end end
	check(dashed,"discovered native dash binding was not requested")
	enemy.Position=Vector3.new(5,0,0)
	local mouseBefore=#sentMouse
	local firstSkill,thirdSkill=false,false
	tick(30)
	for i=keysBefore+1,#sentKeys do
		if sentKeys[i].down and sentKeys[i].key==Enum.KeyCode.E then firstSkill=true end
		if sentKeys[i].down and sentKeys[i].key==Enum.KeyCode.R then thirdSkill=true end
		check(sentKeys[i].key~=Enum.KeyCode.P,"unrecognized noncombat action was activated")
	end
	check(firstSkill and thirdSkill,"native action skills were not sequenced")
	check(#sentMouse>mouseBefore,"ready skill rotation starved punches")
	check(api.Diagnostics():find("OpenShop",1,true),"unfamiliar binding missing from report")
	local report,copied=api.CopyDiagnostics()
	check(copied and clipboard==report,"diagnostic report was not copied")
	-- A duplicate action and HUD skill must not make the slot unusable.
	local button=node("TextButton","PrimarySkill",hud); local calls=0
	button.Activated:Connect(function() calls+=1 end)
	api.SetEnabled(false); api.SetEnabled(true); tick(7)
	check(calls>0,"matching native/HUD bindings disabled a valid skill slot")
	api.SetEnabled(false); nativeActions={}
end
actionBindingChecks()

-- Reproduce the paths and bindings in the user's actual Superhero Arena report.
local function reportedHudChecks()
	api.Unload(); hud:Destroy(); input.TouchEnabled=true; wall=false; ground=true
	hud=node("ScreenGui","HUD_Mobile",localPlayer:FindFirstChild("PlayerGui"))
	local bar=node("Frame","AbilityBar",hud)
	local cosmetics=0
	local icons={}
	for slot,info in pairs({[2]={"E","Geyser"},[3]={"F","Water Breath"},[4]={"R","Tentacle Smack"}}) do
		local icon=node("ImageButton","AbilityIcon"..slot,bar); icons[slot]=icon
		local frame=node("Frame","Frame",icon)
		local tile=node("Frame","KeyTile",frame); node("TextLabel","Keybind",tile).Text=info[1]
		local plate=node("Frame","Nameplate",frame); node("TextLabel","AbilityName",plate).Text=info[2]
		-- A connected cosmetic callback must not take priority over the displayed key.
		icon.Activated:Connect(function() cosmetics+=1 end)
	end
	local dashFrame=node("Frame","Dash",hud)
	local dash=node("TextButton","DashButton",dashFrame)
	dash.Activated:Connect(function() cosmetics+=1 end)
	local attackFrame=node("Frame","Attack",hud)
	local attack=node("TextButton","AttackButton",attackFrame)
	local punches,releases=0,0
	attack.MouseButton1Down:Connect(function() punches+=1 end)
	attack.MouseButton1Up:Connect(function() releases+=1 end)
	nativeActions={Dash={inputTypes={Enum.KeyCode.Q,Enum.KeyCode.ButtonY}},RunW={inputTypes={Enum.KeyCode.W}}}
	root.Position=Vector3.new(); local enemy=other.Character:FindFirstChild("HumanoidRootPart"); enemy.Position=Vector3.new(25,0,0)
	own:SetAttribute("MorphCurrent","Water"); own:SetAttribute("canRun",true)
	api=boot(); api.SetEnabled(true)
	local before=#sentKeys
	tick(6)
	local dashRequested=false
	for i=before+1,#sentKeys do if sentKeys[i].down and sentKeys[i].key==Enum.KeyCode.Q then dashRequested=true end end
	check(dashRequested,"reported Q dash binding was discarded in favor of the HUD button")
	enemy.Position=Vector3.new(5,0,0); tick(38)
	local requested={}
	for i=before+1,#sentKeys do if sentKeys[i].down then requested[sentKeys[i].key]=true end end
	check(requested[Enum.KeyCode.E] and requested[Enum.KeyCode.F] and requested[Enum.KeyCode.R],"reported AbilityIcon2/3/4 did not enter the skill rotation")
	check(not requested[Enum.KeyCode.W],"unrelated RunW binding was pressed")
	check(cosmetics==0,"cosmetic Activated callbacks took priority over confirmed skill/dash bindings")
	check(punches>0 and releases==punches,"MouseButton1Down-only attack was not pressed/released")
	local report=api.Diagnostics()
	check(report:find("AbilityIcon2 | slot=2",1,true) and report:find("AbilityIcon4 | slot=4",1,true),"reported HUD slot mapping missing from diagnostics")
	check(report:find("Down=1",1,true),"diagnostics omitted attack press handlers")
	local activeStatus=api.Status; api.SetEnabled(false)
	check(api.Diagnostics():find("Last active status: "..activeStatus,1,true),"Stop erased the last active status")
	-- Stopping before the delayed release must still release a held punch once.
	icons[2].Visible=false; icons[3].Visible=false; icons[4].Visible=false
	api.SetEnabled(true)
	for _=1,12 do api.Step(0.1); renderAim(0.1) end
	check(punches>releases,"fixture did not leave a punch awaiting release: "..api.Status.." punches="..punches.." releases="..releases.." error="..tostring(api.LastError))
	api.SetEnabled(false); local count=releases; flush()
	check(punches==releases and releases==count,"Stop missed or duplicated a punch release")
	nativeActions={}
end
reportedHudChecks()

local function tacticalChecks()
	api.Unload(); hud:Destroy(); input.TouchEnabled=true; wall=false; ground=true; nativeActions={}
	hud=node("ScreenGui","HUD_Mobile",localPlayer:FindFirstChild("PlayerGui"))
	local bar=node("Frame","AbilityBar",hud)
	local skill=node("ImageButton","AbilityIcon2",bar)
	skill:SetAttribute("MinRange",6); skill:SetAttribute("MaxRange",18); skill:SetAttribute("CooldownDuration",0.4)
	local casts=0; skill.Activated:Connect(function() casts+=1 end)
	root.Position=Vector3.new(); hum.Health=100
	local enemy=other.Character:FindFirstChild("HumanoidRootPart")
	enemy.Position=Vector3.new(20,0,0)
	other.Character:SetAttribute("state","neutral"); other.Character:SetAttribute("lastSwing",10)
	api=boot(); api.SetEnabled(true); tick(4)
	local plan=api.Brain.Plans[skill]
	check(plan and plan.Trigger>=6 and plan.Trigger<=18,"sampled skill range escaped native limits")
	local threshold=plan.Trigger; tick(4)
	check(casts==0 and api.Brain.Plans[skill].Trigger==threshold,"range preference rerolled each tick or fired beyond hard range")
	enemy.Position=Vector3.new(4,0,0); tick(5)
	check(casts==0,"skill fired inside its native minimum range")
	local observed,distances={},{}
	for _,distance in ipairs({8,10,12}) do
		for _=1,12 do
			root.Position=root.Position+Vector3.new(0.25,0,0)
			enemy.Position=root.Position+Vector3.new(distance,0,0)
			local previous=casts; tick(1)
			if casts>previous then table.insert(observed,api.LastCast.Trigger); distances[api.LastCast.Distance]=true end
		end
	end
	local low,high=math.huge,0
	for _,value in ipairs(observed) do low=math.min(low,value); high=math.max(high,value) end
	check(#observed>=3 and high-low>0.05,"skill preferences did not vary between uses")
	check(distances[8] and distances[10] and distances[12],"skills were restricted to a single cast distance")
	hum.Health=25
	for _=1,10 do root.Position=root.Position+Vector3.new(0.25,0,0); enemy.Position=root.Position+Vector3.new(8,0,0); tick(1) end
	check((hum.LastMoveTo-enemy.Position).Magnitude>=9,"low health did not create extra spacing: "..api.Status.." gap="..(hum.LastMoveTo-enemy.Position).Magnitude)
	api.SetEnabled(false); skill:Destroy(); hum.Health=100
	local dashFrame=node("Frame","Dash",hud)
	local dash=node("TextButton","DashButton",dashFrame)
	local dashes=0; dash.Activated:Connect(function() dashes+=1 end)
	root.Position=Vector3.new(); enemy.Position=Vector3.new(10,0,0); enemy.CFrame={LookVector=Vector3.new(-1,0,0)}
	local function moveTicks(n)
		for _=1,n do root.Position=root.Position+Vector3.new(0.25,0,0); enemy.Position=root.Position+Vector3.new(10,0,0); tick(1) end
	end
	other.Character:SetAttribute("state","neutral"); other.Character:SetAttribute("lastSwing",10)
	api.Unload(); api=boot(); api.SetEnabled(true); tick(5)
	check(dashes==0,"idle opponent caused an unprovoked defensive dash")
	other.Character:SetAttribute("state","attacking"); other.Character:SetAttribute("lastSwing",11)
	tick(1)
	check(dashes==0 and api.Brain.Threat,"attack cue ignored or reaction was instantaneous")
	tick(3)
	check(dashes==1 and hum.Health==100,"incoming attack was not dodged before taking damage")
	moveTicks(8)
	check(dashes==1,"unchanged attack state retriggered a dodge")
	dash:SetAttribute("OnCooldown",true)
	other.Character:SetAttribute("lastSwing",12); moveTicks(4)
	check(dashes==1,"proactive defense bypassed the native dash cooldown")
	check(math.abs(hum.LastMoveTo.X-root.Position.X)<2 and math.abs(hum.LastMoveTo.Z)>=3,"dash cooldown did not fall back to a safe sidestep")
	-- Turning away clears an outstanding windup instead of triggering a late dodge.
	enemy.CFrame={LookVector=Vector3.new(1,0,0)}; dash:SetAttribute("OnCooldown",false); moveTicks(5)
	check(not api.Brain.Threat and dashes==1,"opponent facing away retained a false threat")
	wall=true; enemy.CFrame={LookVector=Vector3.new(-1,0,0)}
	other.Character:SetAttribute("lastSwing",13); moveTicks(4)
	check(not api.Brain.Threat and dashes==1,"attack behind an obstruction caused a dodge")
	wall=false; ground=false; other.Character:SetAttribute("lastSwing",14); moveTicks(4)
	check(dashes==1,"defensive dash crossed unverified ground")
	ground=true; moveTicks(5)
	-- A second nearby attacker is observed even while the selected target is retained.
	local attacker=player("NearbyAttacker",9); local rig=character(attacker)
	local attackerRoot=rig:FindFirstChild("HumanoidRootPart")
	attackerRoot.Position=root.Position+Vector3.new(-8,0,0); attackerRoot.CFrame={LookVector=Vector3.new(1,0,0)}
	rig:SetAttribute("state","neutral"); rig:SetAttribute("lastSwing",1)
	dash:SetAttribute("OnCooldown",true); moveTicks(2)
	rig:SetAttribute("lastSwing",2); moveTicks(4)
	check(api.Target==other and api.Brain.Threat and api.Brain.Threat.Player==attacker,"nearby third-party attack was ignored")
	api.SetEnabled(false)
	check(not api.Brain.Threat and hum.LastMove.Magnitude==0,"Stop left defensive steering active")
	rig:Destroy(); attacker:Destroy(); other.Character:SetAttribute("state","neutral")
	flushSpawn(); flush()
end
tacticalChecks()

local function groupAndMovementChecks()
	api.Unload(); hud:Destroy(); input.TouchEnabled=true; wall=false; ground=true; nativeActions={}
	hud=node("ScreenGui","HUD_Mobile",localPlayer:FindFirstChild("PlayerGui"))
	root.Position=Vector3.new(); hum.Health=100; own:SetAttribute("canRun",true)
	local enemy=other.Character:FindFirstChild("HumanoidRootPart")
	other.Character:SetAttribute("state","neutral"); enemy.AssemblyLinearVelocity=Vector3.new()
	local flankOne=player("GroupOne",20); local rigOne=character(flankOne); local partOne=rigOne:FindFirstChild("HumanoidRootPart")
	local flankTwo=player("GroupTwo",21); local rigTwo=character(flankTwo); local partTwo=rigTwo:FindFirstChild("HumanoidRootPart")
	local function arrange()
		enemy.Position=root.Position+Vector3.new(12,0,0)
		partOne.Position=root.Position+Vector3.new(12,0,6)
		partTwo.Position=root.Position+Vector3.new(14,0,-4)
	end
	arrange(); api=boot(); api.SetEnabled(true)
	local seen,last,lastAt,switches={},nil,0,0
	local flanked=false
	for i=1,120 do
		root.Position=root.Position+Vector3.new(0.25,0,0); arrange(); tick(1)
		if api.Brain.Mode=="flank" then flanked=true end
		local target=api.Target
		if target then seen[target]=true end
		if target and last and target~=last then
			check(i*0.1-lastAt>=1.5,"group targeting flicked between opponents too quickly")
			lastAt=i*0.1; switches+=1
		end
		if target and not last then lastAt=i*0.1 end
		last=target
	end
	local count=0; for _ in pairs(seen) do count+=1 end
	check(count>=2 and switches>=2,"nearby group never produced committed target switches")
	check(flanked,"group pressure never produced a flank")
	-- Protected targets and replicated teammates cannot become fresh group targets.
	rigOne:SetAttribute("iframes",true); rigOne:FindFirstChildOfClass("Humanoid").Health=5
	local previous=api.Target
	for _=1,65 do
		root.Position=root.Position+Vector3.new(0.25,0,0); arrange(); tick(1)
		if api.Target~=previous then check(api.Target~=flankOne,"group switch selected a protected opponent") end
		previous=api.Target
	end
	localPlayer.Team="Blue"; flankTwo.Team="Blue"; other.Team="Red"; flankOne.Team="Red"
	tick(1); check(api.Target~=flankTwo,"group targeting retained a teammate")
	localPlayer.Team=nil; flankTwo.Team=nil; other.Team=nil; flankOne.Team=nil; rigOne:SetAttribute("iframes",nil)
	wall=true; local held=api.Target
	for _=1,12 do root.Position=root.Position+Vector3.new(0.25,0,0); arrange(); tick(1) end
	check(api.Target==held,"group switch selected an opponent through an obstruction")
	api.SetEnabled(false); flushSpawn(); wall=false
	-- Switching must wait for an active channel to finish.
	local skill=node("TextButton","PrimarySkill",hud); skill:SetAttribute("MaxRange",30); skill:SetAttribute("ChannelTime",1.2)
	local clock,castAt,castTarget,casts=0,-100,nil,0
	skill.Activated:Connect(function() castAt=clock; castTarget=api.Target; casts+=1 end)
	api.SetEnabled(true)
	for _=1,80 do
		clock+=0.1; root.Position=root.Position+Vector3.new(0.25,0,0); arrange(); tick(1)
		if clock-castAt<1.2 then check(api.Target==castTarget,"group target changed during an active channel") end
	end
	check(casts>=2,"group channel fixture did not exercise casting")
	api.Unload(); skill:Destroy(); rigOne:Destroy(); flankOne:Destroy(); rigTwo:Destroy(); flankTwo:Destroy()
	-- Side runs stay committed to a destination rather than rerolling every tick.
	math.randomseed(246)
	root.Position=Vector3.new(); enemy.Position=Vector3.new(18,0,0); hum.Health=100
	api=boot(); api.SetEnabled(true)
	local sideRuns,stableSide,lastGoal=0,0,nil
	for _=1,90 do
		root.Position=root.Position+Vector3.new(0.25,0,0); enemy.Position=root.Position+Vector3.new(18,0,0); tick(1)
		if api.Brain.Mode=="side run" then
			sideRuns+=1
			if lastGoal==hum.LastMoveTo then stableSide+=1 end
			lastGoal=hum.LastMoveTo
			check(not api.Brain.SuppressAttack,"side running unnecessarily disabled combat")
		else lastGoal=nil end
	end
	check(sideRuns>0 and stableSide>0,"side runs were absent or changed direction every tick")
	api.Unload()
	-- Turning the camera alone must not fire punches while the body still faces away.
	local attack=node("TextButton","AttackButton",hud); local punches=0
	attack.Activated:Connect(function() punches+=1 end)
	enemy.Position=root.Position+Vector3.new(5,0,0)
	root.CFrame=CFrame.lookAt(root.Position,root.Position+Vector3.new(-1,0,0))
	cameraFrame.LookVector=(enemy.Position-cameraFrame.Position).Unit
	api=boot(); api.SetEnabled(true)
	for _=1,10 do api.Step(0.1); flush() end
	check(punches==0,"combat fired while body orientation lagged behind the camera")
	renderAim(0.1); tick(5)
	check(punches>0,"combat did not resume after the body faced its target")
	api.Unload(); attack:Destroy()
	-- A moving opponent behind the player prompts a run, turn and backpedal.
	local chaser=player("Pursuer",23); local chaserRig=character(chaser); local chaserHum=chaserRig:FindFirstChildOfClass("Humanoid")
	local chaserRoot=chaserRig:FindFirstChild("HumanoidRootPart")
	chaserRoot.CFrame=CFrame.lookAt(Vector3.new(-8,0,0),Vector3.new())
	chaserRoot.AssemblyLinearVelocity=Vector3.new(12,0,0); chaserHum.Health=0
	root.Position=Vector3.new(); enemy.Position=Vector3.new(12,0,0)
	api=boot(); api.SetEnabled(true); tick(2); chaserHum.Health=100
	local ran,lookedBack=false,false
	for _=1,18 do
		root.Position=root.Position+Vector3.new(0.25,0,0); enemy.Position=root.Position+Vector3.new(12,0,0)
		chaserRoot.Position=root.Position+Vector3.new(-8,0,0); tick(1)
		if api.Brain.Mode=="retreat turn" then
			ran=true
			check(hum.LastMoveTo.X>root.Position.X and api.Brain.SuppressAttack,"retreat ran toward the pursuer or fired while turning away")
		elseif api.Brain.Mode=="backpedal" then
			lookedBack=true
			check(root.CFrame.LookVector.X<0 and cameraFrame.LookVector.X<0,"backpedal did not turn toward the pursuer")
			check(api.Target==other,"brief look-back incorrectly replaced the committed target")
		end
	end
	check(ran and lookedBack,"pursuit did not produce both retreat and backpedal phases")
	check(root.CFrame.Position==root.Position and hum.WalkSpeed==16,"movement pattern changed position by teleport or modified speed")
	chaserHum.Health=0
	for _=1,18 do root.Position=root.Position+Vector3.new(0.25,0,0); enemy.Position=root.Position+Vector3.new(12,0,0); tick(1) end
	check(not api.Brain.Chaser and not api.Brain.SuppressAttack,"retreat did not finish after pursuer disappeared")
	api.SetEnabled(false); chaserHum.Health=100; root.AssemblyLinearVelocity=Vector3.new(12,0,0); api.SetEnabled(true)
	for _=1,16 do chaserRoot.Position=root.Position+Vector3.new(-8,0,0); tick(1); if api.Brain.Chaser then break end end
	check(api.Brain.Chaser~=nil,"equal-speed pursuer following behind was not recognized")
	api.SetEnabled(false); local stoppedFacing=root.CFrame; renderAim(0.1)
	check(root.CFrame==stoppedFacing and hum.LastMove.Magnitude==0 and hum.AutoRotate==true,"Stop left a retreat turn or movement running")
	check(not api.Brain.FaceRoot and not api.Brain.ModeGoal and not api.Brain.SuppressAttack,"Stop retained movement-pattern state")
	root.AssemblyLinearVelocity=Vector3.new()
	api.Unload(); ground=false; api=boot(); api.SetEnabled(true)
	for _=1,18 do tick(1) end
	check(not api.Brain.ModeGoal,"retreat selected a destination without verified ground")
	ground=true; api.SetEnabled(false); chaserRig:Destroy(); chaser:Destroy(); flushSpawn(); flush()
end
groupAndMovementChecks()

-- Unload during a pending route; all owned controls and callbacks disappear.
wall=true; api.SetEnabled(true); tick(1)
local oldGui=api.Gui; api=boot(); flushSpawn(); flush()
check(oldGui.Parent==nil and env.SuperheroArenaHub==api and not api.Enabled,"re-execution did not unload old play controller")
api.Unload(); api.Unload(); hud:Destroy(); flushSpawn(); flush()
check(api.Gui.Parent==nil and env.SuperheroArenaHub==nil,"unload not idempotent")
check(next(renderBindings)==nil,"camera render binding leaked")
local leaks=0
for _,sig in ipairs(allSignals) do for _,c in ipairs(sig.handlers) do if c.Connected then leaks+=1 end end end
check(leaks==0,"unload leaked "..leaks.." signal handlers")
print("PASS: "..checks.." checks covering one-button UI, combo sequencing, cast/channel timing, native dash, aim, movement, pauses and cleanup.")
