-- Reacts to observable attack windups. Unknown animations and busy alone are not attack evidence.
return function(ctx)
    local Players=game:GetService("Players")
    local M={Status="Off",Dodging=false,Reactions=0,LastCue=nil}
    local records={}
    local clock,age,retry,untilAt=0,0,0,0
    local direction,ownHum,ownRoot,attacker
    local dead=false
    local states={attack=true,attacking=true,casting=true,charging=true,windup=true,swinging=true,usingability=true}
    local function norm(s) return type(s)=="string" and s:lower():gsub("[^%w]","") or "" end
    local function cue(record,reason,ability)
        record.Cue={At=clock,Reason=reason,Ability=ability};M.LastCue=reason
    end
    local function stop()
        if ownHum then pcall(function() ownHum:Move(Vector3.new(),false) end) end
        M.Dodging=false;direction=nil;ownHum=nil;ownRoot=nil;attacker=nil
    end
    M.Stop=stop
    local function remove(plr)
        local record=records[plr];if record and record.Connection then record.Connection:Disconnect() end;records[plr]=nil
    end
    local function watch(plr,char,hum)
        local record=records[plr]
        if record and record.Character~=char then remove(plr);record=nil end
        if not record then record={Character=char};records[plr]=record end
        local animator=hum:FindFirstChildOfClass("Animator")
        if animator and animator~=record.Animator then
            if record.Connection then record.Connection:Disconnect() end;record.Animator=animator
            record.Connection=animator.AnimationPlayed:Connect(function(track)
                if dead or not ctx.Config.UltraInstinct then return end
                local animation=track.Animation
                local name=norm(track.Name)..norm(animation and animation.Name)
                local attacking=track:GetAttribute("IsAttack")==true or animation and animation:GetAttribute("IsAttack")==true
                for _,word in ipairs({"punch","swing","attack","windup","repulsor","unibeam","geyser","waterbreath","tentaclesmack","ability","cast","charge"}) do
                    if name:find(word,1,true) then attacking=true;break end
                end
                if attacking then cue(record,"Attack animation",not name:find("punch",1,true) and not name:find("swing",1,true)) end
            end)
        end
        local stateName=norm(char:GetAttribute("state"))
        local state=states[stateName]==true or char:GetAttribute("IsAttacking")==true or char:GetAttribute("IsCasting")==true
        local ability=({casting=true,charging=true,windup=true,usingability=true})[stateName]==true or char:GetAttribute("IsCasting")==true
        local swing=tonumber(char:GetAttribute("lastSwing"))
        local cast=tonumber(char:GetAttribute("CastStartedAt") or char:GetAttribute("AbilityStartedAt") or char:GetAttribute("lastCast"))
        if record.Initialized then
            if state and not record.Attacking then cue(record,"Attack windup",ability) end
            if swing and record.Swing and swing>record.Swing then cue(record,"Melee windup",false) end
            if cast and (not record.Cast or cast>record.Cast) then cue(record,"Ability windup",true) end
        elseif state then cue(record,"Visible attack windup",ability) end
        record.Initialized=true;record.Attacking=state;record.Swing=swing;record.Cast=cast
        return record
    end
    local function eligible(char,hum,root)
        return root and not root.Anchored and not hum.PlatformStand and char:GetAttribute("inArena")~=false and char:GetAttribute("MorphAppearanceReady")~=false
            and char:GetAttribute("cutsceneLock")~=true and char:GetAttribute("canRun")~=false and char:GetAttribute("busy")~=true
    end
    function M.Steer()
        if not M.Dodging then return end
        local char,hum,root=ctx.Body(Players.LocalPlayer)
        if not ctx.Config.UltraInstinct or not ctx.CanRun() or root~=ownRoot or not eligible(char,hum,root)
            or clock>=untilAt or not ctx.Safe(root,root.Position+direction*3,attacker) then stop();return end
        hum:Move(direction,false)
    end
    function M.Step(dt)
        if dead then return end
        clock+=dt;age+=dt
        if not ctx.Config.UltraInstinct then
            stop();retry=0;age=0;M.Status="Off";for plr in pairs(records) do remove(plr) end;return
        end
        if not ctx.CanRun() then stop();M.Status="Paused";return end
        local char,hum,root=ctx.Body(Players.LocalPlayer)
        if not eligible(char,hum,root) then stop();M.Status="Movement locked";return end
        if M.Dodging and clock>=untilAt then stop() end
        if age<0.05 then return end;age=0
        local best,bestRecord,bestDistance
        for _,plr in ipairs(Players:GetPlayers()) do
            if ctx.Opposing(plr) then
                local otherChar,otherHum,otherRoot=ctx.Body(plr)
                if otherRoot and otherChar:GetAttribute("inArena")~=false then
                    local record=watch(plr,otherChar,otherHum)
                    local delta=Vector3.new(root.Position.X-otherRoot.Position.X,0,root.Position.Z-otherRoot.Position.Z)
                    local facing=otherRoot.CFrame.LookVector;local flat=Vector3.new(facing.X,0,facing.Z)
                    local range=record.Cue and record.Cue.Ability and ctx.Config.InstinctRange or 15
                    if record.Cue and clock-record.Cue.At<0.55 and delta.Magnitude>0.2 and delta.Magnitude<=range
                        and math.abs(root.Position.Y-otherRoot.Position.Y)<10 and flat.Magnitude>0.1 and flat.Unit:Dot(delta.Unit)>0.4
                        and ctx.Sight(root.Position,otherRoot.Position,otherChar) and (not bestDistance or delta.Magnitude<bestDistance) then
                        best=otherRoot;bestRecord=record;bestDistance=delta.Magnitude
                    end
                else remove(plr) end
            else remove(plr) end
        end
        local stale={};for plr in pairs(records) do if plr.Parent~=Players then table.insert(stale,plr) end end;for _,plr in ipairs(stale) do remove(plr) end
        if M.Dodging then M.Status="Evading";return end
        if not best or clock<retry then M.Status="Watching attack cues";return end
        local toward=Vector3.new(best.Position.X-root.Position.X,0,best.Position.Z-root.Position.Z).Unit
        local side=Vector3.new(-toward.Z,0,toward.X)
        local length=bestRecord.Cue.Ability and 7 or 5
        local candidates={side,side*(-1),(side-toward*0.65).Unit,(side*(-1)-toward*0.65).Unit,toward*(-1)}
        local chosen
        for _,candidate in ipairs(candidates) do
            local safe=true
            for _,distance in ipairs({2,4,length}) do if not ctx.Safe(root,root.Position+candidate*distance,bestRecord.Character) then safe=false;break end end
            if safe then chosen=candidate;break end
        end
        bestRecord.Cue=nil
        if not chosen then M.Status="No clear dodge route";retry=clock+0.2;return end
        direction=chosen;ownHum=hum;ownRoot=root;attacker=bestRecord.Character;untilAt=clock+0.36;retry=clock+0.7
        M.Dodging=true;M.Reactions+=1;M.Status="Evading";hum:Move(direction,false)
        if ctx.Config.InstinctDash then ctx.Dash(chosen) end
    end
    function M.Destroy()
        if dead then return end;dead=true;stop()
        for plr in pairs(records) do remove(plr) end
    end
    return M
end
