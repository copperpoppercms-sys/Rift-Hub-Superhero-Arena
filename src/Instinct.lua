-- One-shot, local escapes. Never disables controls, holds movement, or forces humanoid state.
return function(ctx)
    local Players=game:GetService("Players")
    local M={Status="Off",Dodging=false,Reactions=0,LastCue=nil,LastMode=nil,LastDistance=0,TrackedHitboxes=0}
    local records,tracked,pending={},{ },{}
    local clock,age,retry,holdUntil=0,0,0,0
    local enabled,dead=false,false
    local addedConnection
    local states={attack=true,attacking=true,casting=true,charging=true,windup=true,swinging=true,usingability=true}
    local containers={projectiles=true,abilities=true,effects=true,vfx=true,hitboxes=true,attacks=true,damagezones=true}
    local function norm(s) return type(s)=="string" and s:lower():gsub("[^%w]","") or "" end
    local function finite(n) return type(n)=="number" and n==n and math.abs(n)<math.huge end
    local function cue(record,reason,ability) record.Cue={At=clock,Reason=reason,Ability=ability};M.LastCue=reason end
    function M.Stop() M.Dodging=false;holdUntil=0 end
    -- Kept as a no-op for the render callback; default Roblox controls stay in charge.
    function M.Steer() end
    local function remove(plr)
        local record=records[plr];if record and record.Connection then record.Connection:Disconnect() end;records[plr]=nil
    end
    local function clear()
        for plr in pairs(records) do remove(plr) end
        table.clear(tracked);table.clear(pending);M.TrackedHitboxes=0
    end
    local function ownerOf(part)
        local node=part
        for _=1,5 do
            if not node or node==workspace then break end
            for _,plr in ipairs(Players:GetPlayers()) do
                if node==plr.Character then return plr end
            end
            for _,key in ipairs({"OwnerUserId","CasterUserId","AttackerUserId","Owner","Caster","Attacker","Creator","creator"}) do
                local value=node:GetAttribute(key)
                local object=node:FindFirstChild(key)
                if object and object:IsA("ObjectValue") then value=object.Value end
                for _,plr in ipairs(Players:GetPlayers()) do
                    if value~=nil and (value==plr or plr.Character and value==plr.Character or value==plr.UserId or value==tostring(plr.UserId) or value==plr.Name) then return plr end
                end
            end
            node=node.Parent
        end
    end
    local function classification(part)
        if not part:IsA("BasePart") or not part.Parent then return false end
        if part:GetAttribute("Active")==false or part:GetAttribute("DamageActive")==false or part:GetAttribute("Enabled")==false then return false end
        local name=norm(part.Name)
        local explicit=part:GetAttribute("IsAttack")==true or part:GetAttribute("IsHitbox")==true or part:GetAttribute("IsProjectile")==true
        local named=name:find("hitbox",1,true) or name:find("damagezone",1,true) or name:find("projectile",1,true)
        local effect=name:find("repulsor",1,true) or name:find("unibeam",1,true) or name:find("geyser",1,true)
            or name:find("fireball",1,true) or name:find("shockwave",1,true) or name:find("waterbreath",1,true)
        if not explicit and not named and not effect then return false end
        local owner=ownerOf(part)
        if owner==Players.LocalPlayer or owner and not ctx.Opposing(owner) then return false end
        local node=part.Parent;local runtimeFolder=false;local characterPart=false
        for _=1,5 do
            if not node or node==workspace then break end
            if containers[norm(node.Name)] then runtimeFolder=true end
            if node:FindFirstChildOfClass("Humanoid") then characterPart=true end
            node=node.Parent
        end
        -- A character's ordinary body hitbox and static map parts are not attack evidence.
        if characterPart and not explicit then return false end
        if not explicit and not runtimeFolder and not owner then return false end
        return true,owner
    end
    local function remember(node)
        if dead or not ctx.Config.UltraInstinct then return end
        if classification(node) then
            local count=0;for _ in pairs(tracked) do count+=1 end
            if count<256 or tracked[node] then tracked[node]=tracked[node] or {At=clock,ReactedAt=-math.huge} end
        end
    end
    if workspace.DescendantAdded then
        addedConnection=workspace.DescendantAdded:Connect(function(node)
            if dead or not ctx.Config.UltraInstinct or not node:IsA("BasePart") then return end
            local count=0;for _ in pairs(pending) do count+=1 end
            if count<256 then pending[node]=clock end
            remember(node)
        end)
    end
    local function watch(plr,char,hum)
        local record=records[plr]
        if record and record.Character~=char then remove(plr);record=nil end
        if not record then record={Character=char};records[plr]=record end
        local function animationCue(track)
            if dead or not ctx.Config.UltraInstinct then return end
            local animation=track.Animation
            local name=norm(track.Name)..norm(animation and animation.Name)
            local locomotion=name:find("idle",1,true) or name:find("walk",1,true) or name:find("run",1,true) or name:find("jump",1,true) or name:find("fall",1,true)
            if locomotion then return end
            local attacking=track:GetAttribute("IsAttack")==true or animation and animation:GetAttribute("IsAttack")==true
            for _,word in ipairs({"punch","swing","attack","windup","repulsor","unibeam","geyser","waterbreath","tentaclesmack","ability","cast","charge"}) do
                if name:find(word,1,true) then attacking=true;break end
            end
            if attacking then cue(record,"Attack animation",not name:find("punch",1,true) and not name:find("swing",1,true))
            elseif track.Priority==Enum.AnimationPriority.Action or track.Priority==Enum.AnimationPriority.Action2 or track.Priority==Enum.AnimationPriority.Action3 or track.Priority==Enum.AnimationPriority.Action4 then
                record.ActionAt=clock
            end
        end
        local animator=hum:FindFirstChildOfClass("Animator")
        if animator and animator~=record.Animator then
            if record.Connection then record.Connection:Disconnect() end;record.Animator=animator
            record.Connection=animator.AnimationPlayed:Connect(animationCue)
            pcall(function() for _,track in ipairs(animator:GetPlayingAnimationTracks()) do animationCue(track) end end)
        end
        local stateName=norm(char:GetAttribute("state"))
        local ability=({casting=true,charging=true,windup=true,usingability=true})[stateName]==true or char:GetAttribute("IsCasting")==true
        local state=states[stateName]==true or char:GetAttribute("IsAttacking")==true or char:GetAttribute("IsCasting")==true
        local swing=tonumber(char:GetAttribute("lastSwing") or char:GetAttribute("m1Resolved") or char:GetAttribute("lastAttack"))
        local cast=char:GetAttribute("CastStartedAt") or char:GetAttribute("AbilityStartedAt") or char:GetAttribute("lastCast") or char:GetAttribute("LastAbility")
        local combo=tonumber(char:GetAttribute("combo"))
        local locked=char:GetAttribute("busy")==true and char:GetAttribute("canAttack")==false
        if record.Initialized then
            if state and not record.Attacking then cue(record,"Attack used",ability) end
            if finite(swing) and finite(record.Swing) and swing>record.Swing then cue(record,"Melee used",false) end
            if cast~=nil and cast~=record.Cast then cue(record,"Ability used",true) end
            if combo and combo>0 and combo~=record.Combo then cue(record,"Combo advanced",false) end
        elseif state then cue(record,"Active attack",ability) end
        if record.ActionAt and clock-record.ActionAt<0.25 and locked then cue(record,"Action animation + combat lock",true);record.ActionAt=nil end
        record.Initialized=true;record.Attacking=state;record.Swing=swing;record.Cast=cast;record.Combo=combo
        return record
    end
    local function eligible(char,hum,root)
        return root and not root.Anchored and not hum.PlatformStand and char:GetAttribute("inArena")~=false
            and char:GetAttribute("MorphAppearanceReady")~=false and char:GetAttribute("cutsceneLock")~=true
    end
    local function geometry(part,root)
        local ok,value=pcall(function()
            local cf=part.CFrame;local size=part.Size
            local half=Vector3.new(size.X*0.5+root.Size.X*0.5+0.7,size.Y*0.5+2.4,size.Z*0.5+root.Size.Z*0.5+0.7)
            local p=cf:PointToObjectSpace(root.Position)
            return {Part=part,CF=cf,Half=half,Local=p,Inside=math.abs(p.X)<=half.X and math.abs(p.Y)<=half.Y and math.abs(p.Z)<=half.Z}
        end)
        return ok and value or nil
    end
    local function interval(box,direction)
        local d=box.CF:VectorToObjectSpace(direction);local p=box.Local;local lo,hi=-math.huge,math.huge
        for _,axis in ipairs({"X","Y","Z"}) do
            local v=d[axis];local x=p[axis];local h=box.Half[axis]
            if math.abs(v)<0.00001 then if math.abs(x)>h then return nil end
            else
                local a,b=(-h-x)/v,(h-x)/v;if a>b then a,b=b,a end
                lo=math.max(lo,a);hi=math.min(hi,b);if lo>hi then return nil end
            end
        end
        if hi<0 then return nil end
        return lo,hi
    end
    local function inside(box,point)
        local p=box.CF:PointToObjectSpace(point);return math.abs(p.X)<=box.Half.X and math.abs(p.Y)<=box.Half.Y and math.abs(p.Z)<=box.Half.Z
    end
    local function nearby(root)
        pcall(function()
            local overlap=OverlapParams.new();overlap.MaxParts=100;overlap.FilterType=Enum.RaycastFilterType.Exclude
            overlap.FilterDescendantsInstances={ctx.Body(Players.LocalPlayer)}
            for _,part in ipairs(workspace:GetPartBoundsInRadius(root.Position,16,overlap)) do remember(part) end
        end)
        local boxes,overlapping={},{}
        local count=0
        for part,entry in pairs(tracked) do
            if not part.Parent or not classification(part) or clock-entry.At>8 then tracked[part]=nil
            else
                count+=1
                if (part.Position-root.Position).Magnitude<=part.Size.Magnitude*0.5+18 then
                    local box=geometry(part,root)
                    if box then table.insert(boxes,box);if box.Inside and clock-entry.ReactedAt>0.6 then table.insert(overlapping,box) end end
                end
            end
        end
        M.TrackedHitboxes=count;return boxes,overlapping
    end
    local function execute(root,goal,mode,reason)
        local offset=goal-root.Position;local distance=offset.Magnitude
        if distance<0.2 or distance>ctx.Config.InstinctMaxDistance+0.001 then return false end
        -- Single local move. Preserve velocity, rotation direction, movement controls and humanoid state.
        root.CFrame=CFrame.lookAt(goal,goal+root.CFrame.LookVector)
        M.Reactions+=1;M.LastDistance=distance;M.LastDestination=goal;M.LastMode=mode;M.LastCue=reason
        M.Dodging=true;holdUntil=clock+0.08;retry=clock+0.18;M.Status=mode
        return true
    end
    function M.Step(dt)
        if dead then return end
        clock+=dt;age+=dt
        if not ctx.Config.UltraInstinct then
            if enabled then clear() end;enabled=false;M.Stop();retry=0;age=0;M.Status="Off";return
        end
        if not enabled then
            enabled=true
            -- Existing non-queryable effects are discovered once; subsequent effects use DescendantAdded.
            local inspected=0
            for _,node in ipairs(workspace:GetDescendants()) do remember(node);inspected+=1;if inspected>=12000 then break end end
        end
        if M.Dodging and clock>=holdUntil then M.Stop() end
        if not ctx.CanRun() then M.Stop();M.Status="Paused";return end
        local char,hum,root=ctx.Body(Players.LocalPlayer)
        if not eligible(char,hum,root) then M.Stop();M.Status="Waiting for character";return end
        if age<0.025 then return end;age=0
        -- Parenting can precede names/attributes; give new parts a short metadata window.
        for part,at in pairs(pending) do
            if part.Parent then remember(part) end
            if tracked[part] or not part.Parent or clock-at>0.5 then pending[part]=nil end
        end
        local boxes,overlapping=nearby(root)
        if #overlapping>0 and clock>=retry then
            local bestGoal,bestDistance
            for i=0,15 do
                local angle=i*math.pi/8;local direction=Vector3.new(math.cos(angle),0,math.sin(angle));local distance=0
                for _,box in ipairs(overlapping) do local _,exit=interval(box,direction);if exit then distance=math.max(distance,exit+0.5) end end
                for _=1,3 do
                    local extended=false
                    for _,box in ipairs(boxes) do local enter,exit=interval(box,direction);if exit and distance>=enter and distance<=exit+0.001 then distance=exit+0.5;extended=true end end
                    if not extended then break end
                end
                if distance>0.2 and distance<=ctx.Config.InstinctMaxDistance and (not bestDistance or distance<bestDistance) then
                    local goal=root.Position+direction*distance;local outside=true
                    for _,box in ipairs(boxes) do if inside(box,goal) then outside=false;break end end
                    if outside and ctx.Safe(root,goal,nil,boxes) then bestGoal,bestDistance=goal,distance end
                end
            end
            if bestGoal and execute(root,bestGoal,"Local hitbox escape","Nearby active attack volume") then
                for _,box in ipairs(overlapping) do tracked[box.Part].ReactedAt=clock end
                return
            end
            M.Status="Attack too large or no clear local exit";retry=clock+0.12;return
        end
        local bestRecord,bestRoot,bestDistance
        for _,plr in ipairs(Players:GetPlayers()) do
            if ctx.Opposing(plr) then
                local otherChar,otherHum,otherRoot=ctx.Body(plr)
                if otherRoot and otherChar:GetAttribute("inArena")~=false then
                    local record=watch(plr,otherChar,otherHum);local distance=(root.Position-otherRoot.Position).Magnitude
                    local range=record.Cue and record.Cue.Ability and ctx.Config.InstinctRange or 10
                    if record.Cue and clock-record.Cue.At<0.4 and distance>0.2 and distance<=range and math.abs(root.Position.Y-otherRoot.Position.Y)<8
                        and ctx.Sight(root.Position,otherRoot.Position,otherChar) and (not bestDistance or distance<bestDistance) then
                        bestRecord,bestRoot,bestDistance=record,otherRoot,distance
                    end
                else remove(plr) end
            else remove(plr) end
        end
        local stale={};for plr in pairs(records) do if plr.Parent~=Players then table.insert(stale,plr) end end;for _,plr in ipairs(stale) do remove(plr) end
        if not bestRoot or clock<retry or #overlapping>0 then if not M.Dodging then M.Status="Watching nearby attacks" end;return end
        -- No replicated hitbox: this is an estimate, not an assertion about the game's damage volume.
        local toward=Vector3.new(bestRoot.Position.X-root.Position.X,0,bestRoot.Position.Z-root.Position.Z)
        if toward.Magnitude<0.2 then return end;toward=toward.Unit
        local side=Vector3.new(-toward.Z,0,toward.X)
        local candidates={side,side*(-1),(side-toward*0.4).Unit,(side*(-1)-toward*0.4).Unit,toward*(-1)}
        local reason=bestRecord.Cue.Reason;bestRecord.Cue=nil
        for _,length in ipairs({6,4,3}) do
            if length<=ctx.Config.InstinctMaxDistance then
                for _,direction in ipairs(candidates) do
                    local goal=root.Position+direction*length;local outside=true
                    for _,box in ipairs(boxes) do if inside(box,goal) then outside=false;break end end
                    if outside and ctx.Safe(root,goal,bestRecord.Character,boxes) and execute(root,goal,"Short dodge · hitbox unknown",reason) then return end
                end
            end
        end
        retry=clock+0.12;M.Status="No clear local exit"
    end
    function M.Destroy()
        if dead then return end;dead=true;M.Stop();clear();if addedConnection then addedConnection:Disconnect() end
    end
    return M
end
