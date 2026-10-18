-- Short native-movement defense. No teleport, custom velocity or cooldown bypass. Optional short WalkSpeed bursts restore owned changes.
return function(ctx)
    local Players=game:GetService("Players")
    local M={Status="Off",Dodging=false,Reactions=0,AutomaticMoves=0,TestMoves=0,NativeDashes=0,Sidesteps=0,SpeedBursts=0,LastSpeedResult="No burst",LastDash="Not requested",LastDecision="No automatic cue processed",LastCue=nil,LastMode=nil,LastDistance=0,TrackedHitboxes=0,Cues=0,Attempts=0,Animations=0,LastBlock="None",Motion="No move attempted",Recording=false}
    local records,tracked,pending={},{ },{}
    local clock,age,retry,holdUntil=0,0,0,0
    local enabled,dead=false,false
    local addedConnection
    local trace,recordUntil,probe={},0,nil
    local motion
    local blocks={}
    local function log(message)
        if #trace>=100 then table.remove(trace,1) end
        table.insert(trace,string.format("%.2f %s",clock,message))
    end
    local function observing() return ctx.Config.UltraInstinct or M.Recording end
    local function snapshot(node)
        local fields={};local attrs=node:GetAttributes();local keys={}
        for key,value in pairs(attrs) do
            if type(value)=="string" or type(value)=="number" or type(value)=="boolean" then table.insert(keys,key) end
        end
        table.sort(keys)
        for i,key in ipairs(keys) do if i>48 then break end;table.insert(fields,key.."="..tostring(attrs[key]):sub(1,100)) end
        return table.concat(fields,", ")
    end
    local function safe(root,goal,target,boxes)
        M.Attempts+=1
        local ok,allowed,reason=pcall(ctx.Safe,root,goal,target,boxes)
        if ok and allowed then return true end
        reason=ok and (reason or "Clearance rejected") or ("Clearance error: "..tostring(allowed))
        M.LastBlock=reason;blocks[reason]=(blocks[reason] or 0)+1
        return false
    end
    function M.RecordEncounter()
        if dead then return false end
        table.clear(trace);table.clear(blocks);recordUntil=clock+10;M.Recording=true
        for _,record in pairs(records) do record.LogValues=nil end
        M.EncounterStart={Auto=M.AutomaticMoves,Tests=M.TestMoves,Cues=M.Cues}
        log("Encounter recording started (10 seconds; observational only)")
        return true
    end
    function M.Diagnostics()
        local lines={"Ultra Instinct live report", "Status: "..M.Status,"Recording: "..tostring(M.Recording),
            "Attack cues: "..M.Cues.." | animations seen: "..M.Animations.." | hitboxes tracked: "..M.TrackedHitboxes,
            "Clearance attempts: "..M.Attempts.." | move requests: "..M.Reactions.." (automatic="..M.AutomaticMoves..", manual tests="..M.TestMoves..")",
            "Last automatic decision: "..M.LastDecision,
            "Speed bursts: "..M.SpeedBursts.." | requested speed="..ctx.Config.InstinctBurstSpeed.." | "..M.LastSpeedResult,
            "Movement requests: native dash="..M.NativeDashes..", walking sidesteps="..M.Sidesteps.." | dash status="..M.LastDash,
            "Last cue: "..tostring(M.LastCue).." | last blocker: "..M.LastBlock,
            "Movement observation: "..M.Motion.." | last observed travel="..tostring(M.LastObservedTravel),
            "Manual movement present: "..tostring(ctx.ManualMovement()).." | last assist window="..tostring(M.LastAssistWindow).." seconds (up to 0.5; changed input cancels)","Rejected destinations:"}
        local reasons={};for reason,count in pairs(blocks) do table.insert(reasons,reason.." = "..count) end;table.sort(reasons)
        for _,line in ipairs(reasons) do table.insert(lines,line) end
        if M.EncounterStart then
            table.insert(lines,"Since encounter recording started: automatic="..(M.AutomaticMoves-M.EncounterStart.Auto)..", tests="..(M.TestMoves-M.EncounterStart.Tests)..", cues="..(M.Cues-M.EncounterStart.Cues))
        end
        table.insert(lines,"Enabled: "..tostring(ctx.Config.UltraInstinct).." | cue range="..ctx.Config.InstinctRange.." | walking destination cap="..ctx.Config.InstinctMaxDistance)
        local canRun,pause=ctx.CanRun();table.insert(lines,"Can run: "..tostring(canRun).." | "..tostring(pause))
        local char,hum,root=ctx.Body(Players.LocalPlayer)
        table.insert(lines,"Local body: "..(char and char:GetFullName() or "missing").." | anchored="..tostring(root and root.Anchored).." | PlatformStand="..tostring(hum and hum.PlatformStand))
        if char then table.insert(lines,"Local fields: "..snapshot(char)) end
        for _,plr in ipairs(Players:GetPlayers()) do
            if ctx.Opposing(plr) then
                local model,_,otherRoot=ctx.Body(plr);local record=records[plr]
                local distance=root and otherRoot and string.format("%.1f",(root.Position-otherRoot.Position).Magnitude) or "unknown"
                table.insert(lines,"@"..plr.Name.." distance="..distance.." watched="..tostring(record~=nil).." cue="..tostring(record and record.Cue and record.Cue.Reason).." decision="..tostring(record and record.Decision).." | "..(model and snapshot(model) or "body missing"))
                if #lines>=45 then table.insert(lines,"[nearby player report capped]");break end
            end
        end
        table.insert(lines,"Recent events (client observations; effects are not necessarily damage hitboxes):")
        for _,line in ipairs(trace) do table.insert(lines,line) end
        return table.concat(lines,"\n")
    end
    local states={attack=true,attacking=true,casting=true,charging=true,windup=true,swinging=true,usingability=true,skill=true}
    local containers={projectiles=true,abilities=true,effects=true,vfx=true,hitboxes=true,attacks=true,damagezones=true}
    local function norm(s) return type(s)=="string" and s:lower():gsub("[^%w]","") or "" end
    local function finite(n) return type(n)=="number" and n==n and math.abs(n)<math.huge end
    local function cue(record,reason,ability)
        -- Different replicated fields can describe the same attack. Keep one pending cue.
        local previous=record.Cue
        if previous and clock-previous.At<0.25 then
            if ability then previous.Ability=true;previous.Reason=reason end
            return
        end
        if not previous and record.LastCueAt and clock-record.LastCueAt<0.2 then return end
        record.LastCueAt=clock
        record.Cue={At=clock,Reason=reason,Ability=ability};record.Decision=nil;M.LastCue=reason;M.Cues+=1
        log("Cue @"..record.Player.Name..": "..reason)
    end
    local function decision(record,reason)
        M.LastDecision=reason
        if record.Decision~=reason then record.Decision=reason;log("Automatic @"..record.Player.Name..": "..reason) end
    end
    function M.Stop()
        local old=motion;motion=nil;M.Dodging=false;holdUntil=0
        if old and old.BoostSpeed then
            pcall(function()
                -- Do not overwrite a speed that the game changed during the maneuver.
                if math.abs(old.Hum.WalkSpeed-old.BoostSpeed)<0.01 then
                    old.Hum.WalkSpeed=old.BaseSpeed;M.LastSpeedResult="Restored speed "..old.BaseSpeed
                else M.LastSpeedResult="Game changed speed; preserved "..old.Hum.WalkSpeed end
            end)
        end
        if old and old.Hum.Parent then
            pcall(function()
                if ctx.CanRun() and ctx.ManualMovement() then ctx.ResumeMovement(old.Hum) else old.Hum:Move(Vector3.new(),false) end
            end)
        end
    end
    local function startBurst(active)
        if not ctx.Config.FastSidestep then return end
        local original=active.Hum.WalkSpeed
        local requested=math.max(original,ctx.Config.InstinctBurstSpeed)
        if requested<=original then return end
        active.BaseSpeed=original;active.BoostSpeed=requested
        active.Hum.WalkSpeed=requested
        M.SpeedBursts+=1;M.LastSpeedResult="Burst requested at speed "..requested
        local remaining=(active.Goal-active.Root.Position).Magnitude
        local window=math.min(remaining/requested+0.02,0.25)
        holdUntil=clock+window;active.WallUntil=os.clock()+window;M.LastAssistWindow=window
        log(M.LastSpeedResult.."; planned distance="..string.format("%.2f",remaining))
    end
    function M.Steer(dt)
        if not motion or not M.Dodging then return end
        if not ctx.CanRun() then M.Stop();M.Status="Paused for input or camera";return end
        local intent=ctx.MovementIntent()
        if intent and motion.Intent and (intent-motion.Intent).Magnitude>0.35 then
            M.Stop();M.Status="Your changed movement input took control";return
        end
        local char,hum,root=ctx.Body(Players.LocalPlayer)
        if root~=motion.Root or hum~=motion.Hum or root.Anchored or hum.PlatformStand or char:GetAttribute("canRun")==false then M.Stop();return end
        if motion.BoostSpeed and math.abs(hum.WalkSpeed-motion.BoostSpeed)>0.01 then
            M.Stop();M.Status="Burst stopped: game changed speed";return
        end
        if motion.PendingBoost and clock>=motion.PendingBoost then
            motion.PendingBoost=nil
            -- A native request may be ignored. Only boost if the game did not change speed or start fast travel.
            if hum.WalkSpeed==motion.InitialSpeed and root.AssemblyLinearVelocity.Magnitude<ctx.Config.InstinctBurstSpeed*0.8 then
                startBurst(motion)
            end
        end
        local delta=Vector3.new(motion.Goal.X-root.Position.X,0,motion.Goal.Z-root.Position.Z)
        local travelled=(root.Position-motion.Start).Magnitude
        if clock>=holdUntil or os.clock()>=motion.WallUntil or delta.Magnitude<0.4 or travelled>=motion.Limit or delta:Dot(motion.Direction)<=0 then M.Stop();return end
        if clock>=motion.CheckAt then
            motion.CheckAt=clock+0.05
            local frameTime=math.clamp(tonumber(dt) or 1/60,0.001,0.1)
            local checkGoal=root.Position+delta.Unit*math.min(delta.Magnitude,math.max(1.5,hum.WalkSpeed*frameTime+0.5))
            if not safe(root,checkGoal,nil,motion.Boxes) then M.Stop();M.Status="Sidestep stopped: obstruction";return end
        end
        local frameTime=math.clamp(tonumber(dt) or 1/60,0.001,0.1)
        local strength=math.min(1,delta.Magnitude/(math.max(hum.WalkSpeed,1)*frameTime))
        hum:Move(delta.Unit*strength,false)
    end
    local function remove(plr)
        local record=records[plr]
        if record then
            if record.Connection then record.Connection:Disconnect() end
            for _,connection in ipairs(record.Attributes or {}) do connection:Disconnect() end
        end
        records[plr]=nil
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
        if dead or not observing() then return end
        if classification(node) then
            local count=0;for _ in pairs(tracked) do count+=1 end
            if count<256 or tracked[node] then
                if not tracked[node] and M.Recording then log("Accepted attack candidate "..node:GetFullName().." | "..snapshot(node)) end
                tracked[node]=tracked[node] or {At=clock,ReactedAt=-math.huge}
            end
        end
    end
    if workspace.DescendantAdded then
        addedConnection=workspace.DescendantAdded:Connect(function(node)
            if dead or not observing() or not node:IsA("BasePart") then return end
            local count=0;for _ in pairs(pending) do count+=1 end
            if count<256 then pending[node]=clock end
            remember(node)
            if M.Recording then
                local _,_,root=ctx.Body(Players.LocalPlayer)
                if root and (node.Position-root.Position).Magnitude<48 then
                    log("New part "..node:GetFullName().." size="..tostring(node.Size).." accepted="..tostring(classification(node)).." | "..snapshot(node))
                end
            end
        end)
    end
    local function watch(plr,char,hum)
        local record=records[plr]
        if record and record.Character~=char then remove(plr);record=nil end
        if not record then record={Character=char,Player=plr,Attributes={}};records[plr]=record end
        local function animationCue(track)
            if dead or not observing() then return end
            local animation=track.Animation
            M.Animations+=1
            if M.Recording then log("Animation @"..plr.Name.." "..track.Name.." id="..tostring(animation and animation.AnimationId).." priority="..tostring(track.Priority).." | "..snapshot(char)) end
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
                -- Live report: Action4 + castLocked can occur with busy=false/canAttack=true.
                if char:GetAttribute("castLocked")==true then cue(record,"Action animation + castLocked (estimate)",true);record.ActionAt=nil end
            end
        end
        local animator=hum:FindFirstChildOfClass("Animator")
        if animator and animator~=record.Animator then
            if record.Connection then record.Connection:Disconnect() end;record.Animator=animator
            record.Connection=animator.AnimationPlayed:Connect(animationCue)
            pcall(function() for _,track in ipairs(animator:GetPlayingAnimationTracks()) do animationCue(track) end end)
        end
        local function fields()
            if dead or not observing() then return end
            local stateName=norm(char:GetAttribute("state"))
            local ability=({casting=true,charging=true,windup=true,usingability=true,skill=true})[stateName]==true or char:GetAttribute("IsCasting")==true
            local state=states[stateName]==true or char:GetAttribute("IsAttacking")==true or char:GetAttribute("IsCasting")==true
            local combo=tonumber(char:GetAttribute("combo"))
            local castLocked=char:GetAttribute("castLocked")==true
            if record.Initialized then
                if state and not record.Attacking then cue(record,"Attack state: "..stateName,ability) end
                if castLocked and not record.CastLocked and stateName~="ragdolled" and stateName~="stunned" then
                    cue(record,"castLocked started (estimated ability)",true)
                end
                -- Each source has its own baseline; lastSwing must never mask m1Resolved.
                for _,key in ipairs({"lastSwing","m1Resolved","lastAttack","CastStartedAt","AbilityStartedAt","lastCast","LastAbility"}) do
                    local value=char:GetAttribute(key);local previous=record.Values[key]
                    local isMelee=key=="lastSwing" or key=="m1Resolved" or key=="lastAttack"
                    local changed=value~=nil and value~=previous
                    if isMelee then changed=finite(tonumber(value)) and tonumber(value)>0 and (previous==nil or tonumber(value)>(tonumber(previous) or 0)) end
                    if changed then cue(record,(isMelee and "Melee field: " or "Ability field: ")..key,not isMelee) end
                end
                if combo and combo>0 and combo~=record.Combo then cue(record,"Combo advanced",false) end
            elseif state then cue(record,"Active attack",ability) end
            local locked=char:GetAttribute("busy")==true and char:GetAttribute("canAttack")==false
            if record.ActionAt and clock-record.ActionAt<0.25 and (locked or castLocked) then
                cue(record,castLocked and "Action animation + castLocked (estimate)" or "Action animation + combat lock",true);record.ActionAt=nil
            end
            record.Values={}
            for _,key in ipairs({"lastSwing","m1Resolved","lastAttack","CastStartedAt","AbilityStartedAt","lastCast","LastAbility"}) do record.Values[key]=char:GetAttribute(key) end
            record.Initialized=true;record.Attacking=state;record.Combo=combo;record.CastLocked=castLocked
            if M.Recording then
                local attrs=snapshot(char)
                if attrs~=record.LogValues then log("Fields @"..plr.Name..": "..attrs);record.LogValues=attrs end
            end
        end
        if not record.Bound then
            record.Bound=true
            -- Event listeners retain short attack transitions that can disappear between heartbeats.
            for _,key in ipairs({"state","IsAttacking","IsCasting","lastSwing","m1Resolved","lastAttack","CastStartedAt","AbilityStartedAt","lastCast","LastAbility","combo","busy","canAttack","castLocked"}) do
                pcall(function() table.insert(record.Attributes,char:GetAttributeChangedSignal(key):Connect(fields)) end)
            end
        end
        fields()
        return record
    end
    local function eligible(char,hum,root)
        return root and not root.Anchored and not hum.PlatformStand and char:GetAttribute("inArena")~=false
            and char:GetAttribute("MorphAppearanceReady")~=false and char:GetAttribute("cutsceneLock")~=true and char:GetAttribute("canRun")~=false
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
        local queryOK,queryError=pcall(function()
            local overlap=OverlapParams.new();overlap.MaxParts=100;overlap.FilterType=Enum.RaycastFilterType.Exclude
            overlap.FilterDescendantsInstances={ctx.Body(Players.LocalPlayer)}
            for _,part in ipairs(workspace:GetPartBoundsInRadius(root.Position,16,overlap)) do remember(part) end
        end)
        if not queryOK and M.LastQueryError~=tostring(queryError) then M.LastQueryError=tostring(queryError);log("Nearby query failed: "..M.LastQueryError) end
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
    local function execute(root,goal,mode,reason,manual,boxes)
        local offset=Vector3.new(goal.X-root.Position.X,0,goal.Z-root.Position.Z);local distance=offset.Magnitude
        if distance<0.2 or distance>ctx.Config.InstinctMaxDistance+0.001 then return false end
        local char,hum,current=ctx.Body(Players.LocalPlayer)
        if current~=root or not eligible(char,hum,root) then M.LastBlock="Movement unavailable";return false end
        M.Stop()
        local speed=tonumber(hum.WalkSpeed) or 0
        if speed<=0 then M.LastBlock="Normal walking speed is zero";return false end
        local direction=offset.Unit
        local moving=ctx.ManualMovement()
        local window=math.min(distance/speed,0.5)
        motion={Root=root,Hum=hum,Start=root.Position,Goal=goal,Direction=direction,Limit=distance,Boxes=boxes or {},CheckAt=clock+0.05,InitialSpeed=speed,MovingAssist=moving,Intent=ctx.MovementIntent(),WallUntil=os.clock()+window}
        M.LastAssistWindow=window
        M.Dodging=true
        -- Set a normal walking direction before requesting the game's dash input.
        hum:Move(direction,false)
        local native,dashReason=false,"Manual test: walking only"
        if not manual then native,dashReason=ctx.NativeDash(hum,root,direction) end
        M.LastDash=dashReason or (native and "Dash input requested" or "Dash unavailable")
        if native then
            M.NativeDashes+=1;mode="Native dash requested"
            -- Keep a brief normal walking input too: requesting input does not prove the game accepted a dash.
            holdUntil=clock+window
            if ctx.Config.FastSidestep then motion.PendingBoost=clock+0.08 end
        else
            if not manual then M.Sidesteps+=1 end
            mode=manual and "Test sidestep (normal speed)" or "Walking sidestep · "..M.LastDash
            holdUntil=clock+window
            startBurst(motion)
            if motion.BoostSpeed then mode=manual and "Test speed burst" or "Fast sidestep · "..M.LastDash end
        end
        probe={Root=root,Start=root.Position,Goal=goal,At=clock,Direction=direction,Distance=math.min(distance,speed*0.12)}
        M.Motion="Movement input requested; waiting for position observation"
        log("Move request "..mode.." planned distance="..string.format("%.2f",distance))
        M.Reactions+=1
        if manual then M.TestMoves+=1 else M.AutomaticMoves+=1;M.LastCue=reason;M.LastDecision="Automatic movement requested: "..reason end
        M.LastBlock="None";M.LastDistance=distance;M.LastDestination=goal;M.LastMode=mode
        retry=clock+0.45;M.Status=mode
        return true
    end
    function M.TestDodge()
        if dead or not ctx.CanRun() then return false,"Paused: close typing or dragging first" end
        local char,hum,root=ctx.Body(Players.LocalPlayer)
        if not eligible(char,hum,root) then M.LastBlock="Character cannot move";return false,M.LastBlock end
        local boxes=nearby(root)
        for i=0,7 do
            local angle=i*math.pi/4;local goal=root.Position+Vector3.new(math.cos(angle),0,math.sin(angle))*math.min(4,ctx.Config.InstinctMaxDistance)
            local outside=true;for _,box in ipairs(boxes) do if inside(box,goal) then outside=false;break end end
            if outside and safe(root,goal,nil,boxes) then return execute(root,goal,"Manual test (not attack detection)","Test dodge button",true,boxes) end
        end
        M.Status="Test blocked: "..M.LastBlock;log(M.Status);return false,M.LastBlock
    end
    local function observeMove()
        if not probe then return end
        local _,_,current=ctx.Body(Players.LocalPlayer)
        if not probe.Root.Parent or current~=probe.Root then M.Motion="Character changed before observation";probe=nil;return end
        local elapsed=clock-probe.At
        local progress=(probe.Root.Position-probe.Start):Dot(probe.Direction)
        M.LastObservedTravel=math.max(0,progress)
        if not probe.Checked and elapsed>=0.12 then
            probe.Checked=true;probe.Moved=progress>probe.Distance*0.35
            M.Motion=probe.Moved and "Local displacement observed; server acceptance unverified" or "No walking progress observed (blocked, movement lock or correction)"
            log(M.Motion.." progress="..string.format("%.2f",progress))
        end
        if elapsed>=0.65 then
            if probe.Moved and progress<probe.Distance*0.2 then
                M.Motion="Returned near start (possible correction or later movement)";log(M.Motion)
            end
            probe=nil
        end
    end
    function M.Step(dt)
        if dead then return end
        clock+=dt;age+=dt;observeMove()
        if M.Recording and clock>=recordUntil then M.Recording=false;log("Encounter recording complete; copy dodge report") end
        if not observing() then
            if motion then M.Steer(dt);if motion then return end end
            if enabled then clear() end;enabled=false;M.Stop();retry=0;age=0;M.Status="Off";return
        end
        if not enabled then
            enabled=true
            -- Existing non-queryable effects are discovered once; subsequent effects use DescendantAdded.
            local inspected=0
            for _,node in ipairs(workspace:GetDescendants()) do remember(node);inspected+=1;if inspected>=12000 then break end end
            log("Initial scene scan: "..inspected.." instances")
        end
        if M.Dodging and clock>=holdUntil then M.Stop() end
        local canRun,pause=ctx.CanRun()
        if not canRun then M.Stop();M.Status="Paused: "..(pause or "input or camera");return end
        local char,hum,root=ctx.Body(Players.LocalPlayer)
        if not eligible(char,hum,root) then M.Stop();M.Status="Waiting for movable character";return end
        if motion then M.Steer(dt);if motion then return end end
        if age<0.025 then return end;age=0
        -- Parenting can precede names/attributes; give new parts a short metadata window.
        for part,at in pairs(pending) do
            if part.Parent then remember(part) end
            if tracked[part] or not part.Parent or clock-at>0.5 then pending[part]=nil end
        end
        -- Always establish enemy baselines before any geometry branch can return.
        for _,plr in ipairs(Players:GetPlayers()) do
            if ctx.Opposing(plr) then
                local otherChar,otherHum,otherRoot=ctx.Body(plr)
                if otherRoot and (otherRoot.Position-root.Position).Magnitude<64 then watch(plr,otherChar,otherHum) else remove(plr) end
            else remove(plr) end
        end
        if not ctx.Config.UltraInstinct then M.Status="Recording only · no automatic movement";return end
        local boxes,overlapping=nearby(root)
        if #overlapping>0 and clock>=retry then
            local bestGoal,bestDistance
            local previousAttempts=M.Attempts
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
                    if outside and safe(root,goal,nil,boxes) then bestGoal,bestDistance=goal,distance end
                end
            end
            if bestGoal and execute(root,bestGoal,"Local hitbox escape","Nearby active attack volume",false,boxes) then
                for _,box in ipairs(overlapping) do tracked[box.Part].ReactedAt=clock end
                return
            end
            if M.Attempts==previousAttempts then M.LastBlock="No detected-volume exit within "..ctx.Config.InstinctMaxDistance.." studs" end
            M.Status="Attack exit blocked (see dodge report)";retry=clock+0.12;return
        end
        local bestRecord,bestRoot,bestDistance
        for _,plr in ipairs(Players:GetPlayers()) do
            if ctx.Opposing(plr) then
                local otherChar,otherHum,otherRoot=ctx.Body(plr)
                if otherRoot and otherChar:GetAttribute("inArena")~=false then
                    local record=records[plr];local distance=(root.Position-otherRoot.Position).Magnitude
                    if record and record.Cue then
                        local range=ctx.Config.InstinctRange
                        local age=clock-record.Cue.At
                        local reason
                        if age>=0.4 then reason="Cue expired before a move" end
                        if not reason and (distance<=0.2 or distance>range) then reason="Outside configured nearby range" end
                        if not reason and math.abs(root.Position.Y-otherRoot.Position.Y)>=8 then reason="Different elevation" end
                        if not reason and not ctx.Sight(root.Position,otherRoot.Position,otherChar) then reason="Attacker hidden by solid obstruction" end
                        if reason then
                            decision(record,reason)
                        elseif not bestDistance or distance<bestDistance then
                            bestRecord,bestRoot,bestDistance=record,otherRoot,distance
                        end
                    end
                else remove(plr) end
            else remove(plr) end
        end
        local stale={};for plr in pairs(records) do if plr.Parent~=Players then table.insert(stale,plr) end end;for _,plr in ipairs(stale) do remove(plr) end
        if not bestRoot or clock<retry or #overlapping>0 then
            if bestRecord and clock<retry then decision(bestRecord,"Waiting for short movement cooldown") end
            if not M.Dodging then M.Status="Watching nearby attacks" end
            return
        end
        decision(bestRecord,"Nearby cue accepted; checking destinations")
        -- No replicated hitbox: this is an estimate, not an assertion about the game's damage volume.
        local toward=Vector3.new(bestRoot.Position.X-root.Position.X,0,bestRoot.Position.Z-root.Position.Z)
        if toward.Magnitude<0.2 then return end;toward=toward.Unit
        local side=Vector3.new(-toward.Z,0,toward.X)
        local candidates
        if bestRecord.Cue.Ability then
            candidates={(side-toward*0.8).Unit,(side*(-1)-toward*0.8).Unit,toward*(-1),side,side*(-1)}
        else
            candidates={(side-toward*0.5).Unit,(side*(-1)-toward*0.5).Unit,side,side*(-1),toward*(-1)}
        end
        local reason=bestRecord.Cue.Reason
        local preferred=math.min(bestRecord.Cue.Ability and 10 or 8,ctx.Config.InstinctMaxDistance)
        for _,length in ipairs({preferred,8,6,4,3}) do
            if length<=ctx.Config.InstinctMaxDistance then
                for _,direction in ipairs(candidates) do
                    local goal=root.Position+direction*length;local outside=true
                    for _,box in ipairs(boxes) do if inside(box,goal) then outside=false;break end end
                    if outside and safe(root,goal,bestRecord.Character,boxes) and execute(root,goal,"Short dodge · hitbox unknown",reason,false,boxes) then decision(bestRecord,"Automatic dodge requested");bestRecord.Cue=nil;return end
                end
            end
        end
        decision(bestRecord,"No clear local destination")
        retry=clock+0.12;M.Status="Dodge blocked: "..M.LastBlock
    end
    function M.Destroy()
        if dead then return end;dead=true;M.Recording=false;probe=nil;M.Stop();clear();if addedConnection then addedConnection:Disconnect() end
    end
    return M
end
