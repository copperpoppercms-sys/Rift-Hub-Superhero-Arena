local n=0
local function check(value,label) assert(value,label);n+=1 end
local v={}
local Vector3={new=function(x,y,z) return setmetatable({X=x or 0,Y=y or 0,Z=z or 0},v) end}
v.__index=function(a,k)
 if k=='Magnitude' then return math.sqrt(a.X*a.X+a.Y*a.Y+a.Z*a.Z) end
 if k=='Unit' then return Vector3.new(a.X/a.Magnitude,a.Y/a.Magnitude,a.Z/a.Magnitude) end
end
v.__add=function(a,b) return Vector3.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
v.__sub=function(a,b) return Vector3.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
v.__mul=function(a,b) return Vector3.new(a.X*b,a.Y*b,a.Z*b) end
local ctor=(function()
-- SESSION
end)()
local cfg={FastAttack=false,AttackDelay=.2,AutoSafeTeleport=false,SafeHealthThreshold=30,SpeedEnabled=true,WalkSpeed=52}
local attributes={}
local char={GetAttribute=function(_,key) return attributes[key] end}
local hum={Health=100,MaxHealth=100,WalkSpeed=24,MoveTo=function(self,goal) self.Goal=goal end}
local root={Position=Vector3.new()}
local enemy={Position=Vector3.new(6,0,0)}
local manual,canRun,safe,farming,attackOK=false,true,true,false,true
local requests,resumes,scans,stops=0,0,0,0
local tool=ctor({Config=cfg,Body=function(target) if target then return {},{},enemy else return char,hum,root end end,
 CanRun=function() return canRun end,Manual=function() return manual end,
 Farming=function() return farming end,Scan=function() scans+=1 end,Safe=function() return safe end,
 Sight=function() return true end,Nearest=function() return 'enemy' end,
 Resume=function() resumes+=1 end,StopFarmMovement=function() stops+=1 end,
 Attack=function() requests+=1;return attackOK end})
tool.Step(.1);check(hum.WalkSpeed==52,'speed not applied')
manual=true;tool.Step(.1);check(hum.WalkSpeed==52,'speed cancelled during joystick movement');manual=false
hum.WalkSpeed=27;tool.Step(.1);tool.Step(.1);check(hum.WalkSpeed==27,'external speed overwritten')
cfg.WalkSpeed=60;tool.Step(.1);check(hum.WalkSpeed==60,'new speed request ignored')
cfg.SpeedEnabled=false;tool.Step(.1);check(hum.WalkSpeed==27,'speed snapshot not restored')
cfg.FastAttack=true;tool.Step(.2);check(requests==1 and tool.AttackRequests==1,'nearby primary control not requested')
tool.Step(.05);check(requests==1,'attack interval ignored')
attributes.busy=true;tool.Step(.3);check(requests==1,'attack ignored game lock');attributes.busy=false
farming=true;tool.Step(.3);check(requests==1,'farm and standalone attack duplicated');farming=false
manual=true;tool.Step(.3);check(requests==1,'attack ignored manual movement');manual=false
cfg.AutoSafeTeleport=true;hum.Health=20;tool.Step(.3)
check(tool.Retreating and hum.Goal.X==-16 and stops==1,'retreat did not move away from nearby threat')
check(requests==1,'attack continued during retreat')
manual=true;tool.Step(.1);check(not tool.Retreating and resumes==1,'joystick did not cancel retreat');manual=false
safe=false;tool.Step(4);check(not tool.Retreating,'unsafe retreat destination accepted')
safe=true;tool.Step(2);check(tool.Retreating,'safe retreat did not resume')
hum.Health=60;tool.Step(.1);check(not tool.Retreating,'health recovery did not stop retreat')
cfg.SpeedEnabled=true;cfg.WalkSpeed=55;tool.Step(.2);check(hum.WalkSpeed==55,'speed restart failed')
canRun=false;tool.Step(.1);check(hum.WalkSpeed==27 and not tool.Retreating,'focus/character pause failed to restore')
canRun=true;tool.Step(.1);tool.Destroy();check(hum.WalkSpeed==27,'unload left speed modified')
print('PASS: '..n..' speed ownership, attack timing, recovery gates and low-health retreat checks.')
