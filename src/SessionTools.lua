-- Linked-script features adapted to Rift's mobile control discovery and normal movement.
return function(ctx)
 local cfg=ctx.Config
 local M={Retreating=false,Status="Ready",AttackRequests=0}
 local speedHum,speedBase,speedApplied,speedRequest
 local pausedRequest,elapsed,attackAt,scanAt,retryAt= nil,0,0,0,0
 local retreatHum,retreatGoal,retreatUntil
 local function restoreSpeed()
  if speedHum and speedHum.WalkSpeed==speedApplied then speedHum.WalkSpeed=speedBase end
  speedHum,speedBase,speedApplied,speedRequest=nil,nil,nil,nil
 end
 local function endRetreat()
  if retreatHum then pcall(function() ctx.Resume(retreatHum) end) end
  retreatHum,retreatGoal=nil,nil;M.Retreating=false
 end
 function M.Reset()
  endRetreat();restoreSpeed();pausedRequest=nil
 end
 function M.Step(dt)
  elapsed+=dt
  local char,hum,root=ctx.Body()
  local allowed=ctx.CanRun()
  if not root or not hum or not allowed or root.Anchored or hum.PlatformStand or hum.Health<=0 then
   M.Reset();M.Status="Paused";return
  end
  local speedLocked=char:GetAttribute("canRun")==false or char:GetAttribute("LOCKED_INPUTS")==true or char:GetAttribute("cutsceneLock")==true
  -- One write per requested speed. A game override wins until the user changes the setting.
  if speedHum and (speedHum~=hum or speedHum.WalkSpeed~=speedApplied) then
   pausedRequest=speedRequest;restoreSpeed();M.Status="Game changed speed · preserved"
  end
  if not cfg.SpeedEnabled or speedLocked then restoreSpeed()
  elseif pausedRequest~=cfg.WalkSpeed and (speedHum~=hum or speedRequest~=cfg.WalkSpeed) then
   if speedHum~=hum then restoreSpeed();speedHum=hum;speedBase=hum.WalkSpeed end
   speedRequest=cfg.WalkSpeed;speedApplied=speedRequest;hum.WalkSpeed=speedApplied
  end
  if not cfg.SpeedEnabled then pausedRequest=nil end
  if ctx.Manual() then endRetreat();M.Status="Paused for your movement";return end
  local health=hum.Health/math.max(1,hum.MaxHealth)*100
  if M.Retreating then
   if not cfg.AutoSafeTeleport or retreatHum~=hum or speedLocked or elapsed>=retreatUntil or health>=cfg.SafeHealthThreshold+10 or (retreatGoal-root.Position).Magnitude<3 then
    endRetreat();retryAt=elapsed+3
   else hum:MoveTo(retreatGoal);M.Status="Low health · retreating";return end
  end
  if cfg.AutoSafeTeleport and not speedLocked and health<=cfg.SafeHealthThreshold and elapsed>=retryAt then
   local threat=ctx.Nearest(root,40)
   local other
   if threat then other=select(3,ctx.Body(threat)) end
   if other then
    local delta=Vector3.new(root.Position.X-other.Position.X,0,root.Position.Z-other.Position.Z)
    if delta.Magnitude>.1 then
     local away=delta.Unit;local side=Vector3.new(-away.Z,0,away.X)
     for _,direction in ipairs({away,(away+side).Unit,(away-side).Unit,side,side*-1}) do
      local goal=root.Position+direction*16
      if ctx.Safe(root,goal) then
       ctx.StopFarmMovement();retreatHum,retreatGoal,retreatUntil=hum,goal,elapsed+2.5
       M.Retreating=true;hum:MoveTo(goal);M.Status="Low health · retreating";return
      end
     end
    end
   end
   retryAt=elapsed+1;M.Status="Low health · no clear retreat path"
  end
  -- While Auto Farm is active its combo scheduler owns attack requests.
  if cfg.FastAttack and not ctx.Farming() and elapsed>=attackAt and not speedLocked
   and char:GetAttribute("canAttack")~=false and char:GetAttribute("busy")~=true then
   attackAt=elapsed+cfg.AttackDelay
   if elapsed>=scanAt then ctx.Scan();scanAt=elapsed+1 end
   local target=ctx.Nearest(root,8)
   local targetChar,targetRoot
   if target then targetChar,_,targetRoot=ctx.Body(target) end
   if targetRoot and ctx.Sight(root.Position,targetRoot.Position,targetChar) then
    local ok,reason=ctx.Attack(targetRoot)
    if ok then M.AttackRequests+=1;M.Status="Basic attack requested"
    else M.Status=reason or "Attack input unavailable" end
   end
  end
 end
 function M.Steer()
  if M.Retreating and retreatHum and retreatGoal then
   local root=retreatHum.Parent and retreatHum.Parent:FindFirstChild("HumanoidRootPart")
   if root then
    local delta=retreatGoal-root.Position
    retreatHum:Move(delta.Magnitude>.5 and delta.Unit or Vector3.new(),false)
   end
  end
 end
 M.Destroy=M.Reset
 return M
end
