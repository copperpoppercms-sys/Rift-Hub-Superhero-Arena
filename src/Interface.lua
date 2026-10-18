-- Native animated interface; no downloaded UI library or flashing effects.
return function(ctx)
    local API,cfg,gui=ctx.API,ctx.Config,ctx.Gui
    local Input=game:GetService("UserInputService")
    local Tween=game:GetService("TweenService")
    local C={Base=Color3.fromRGB(16,18,25),Panel=Color3.fromRGB(24,27,37),Raised=Color3.fromRGB(33,37,50),
        Line=Color3.fromRGB(55,61,80),Accent=Color3.fromRGB(178,161,255),Text=Color3.fromRGB(239,240,249),Sub=Color3.fromRGB(151,159,181)}
    local M={};local connections={};local dead=false
    function M.Destroy()
        if dead then return end;dead=true
        for _,c in ipairs(connections) do c:Disconnect() end;table.clear(connections)
    end
    if ctx.RegisterCleanup then ctx.RegisterCleanup(function() M.Destroy() end) end
    local orders=setmetatable({},{__mode="k"})
    local function connect(event,fn) local c=event:Connect(fn);table.insert(connections,c);return c end
    local function make(class,props,parent)
        local node=Instance.new(class);for key,value in pairs(props) do node[key]=value end
        if parent and node:IsA("GuiObject") and props.LayoutOrder==nil then orders[parent]=(orders[parent] or 0)+1;node.LayoutOrder=orders[parent] end
        node.Parent=parent;return node
    end
    local function round(node,r) make("UICorner",{CornerRadius=UDim.new(0,r or 10)},node) end
    local function animate(node,props,t)
        if cfg.ReduceMotion then for key,value in pairs(props) do node[key]=value end;return end
        Tween:Create(node,TweenInfo.new(t or 0.17,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),props):Play()
    end
    local function text(parent,value,size,color,position,dimensions,bold)
        return make("TextLabel",{Text=value,TextSize=size,TextColor3=color or C.Text,Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham,
            Position=position or UDim2.new(),Size=dimensions or UDim2.new(1,0,0,20),BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Left},parent)
    end
    local function hover(button)
        local scale=make("UIScale",{Scale=1},button)
        connect(button.MouseEnter,function() animate(scale,{Scale=1.025},0.14) end)
        connect(button.MouseLeave,function() animate(scale,{Scale=1},0.16) end)
        connect(button.InputBegan,function(input)
            if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
                animate(scale,{Scale=0.975},0.08);task.delay(0.1,function() if not dead and button.Parent then animate(scale,{Scale=1},0.16) end end)
            end
        end)
    end
    local window=make("Frame",{Name="Panel",AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromOffset(680,470),BackgroundTransparency=1},gui)
    local fit=make("UIScale",{Scale=1},window)
    local surface=make("CanvasGroup",{Size=UDim2.fromScale(1,1),BackgroundColor3=C.Base,BorderSizePixel=0,GroupTransparency=1},window);round(surface,15)
    make("UIStroke",{Color=C.Line,Thickness=1},surface)
    local opening=make("UIScale",{Scale=0.96},surface)
    local top=make("Frame",{Name="Handle",Active=true,Size=UDim2.new(1,0,0,64),BackgroundTransparency=1},surface)
    local logoFallback=text(top,"R",25,C.Text,UDim2.fromOffset(18,17),UDim2.fromOffset(30,30),true)
    local logo=make("ImageLabel",{Position=UDim2.fromOffset(18,17),Size=UDim2.fromOffset(30,30),BackgroundTransparency=1},top);ctx.Brand.Apply(logo,logoFallback)
    text(top,"RIFT HUB",15,C.Text,UDim2.fromOffset(61,12),UDim2.new(1,-155,0,23),true)
    text(top,"SUPERHERO ARENA",9,C.Accent,UDim2.fromOffset(62,36),UDim2.new(1,-150,0,16),true)
    local seam=make("Frame",{Position=UDim2.new(0,16,0,63),Size=UDim2.new(1,-32,0,1),BackgroundColor3=C.Accent,BackgroundTransparency=0.45,BorderSizePixel=0},surface)
    make("UIGradient",{Color=ColorSequence.new(C.Accent,C.Line)},seam)
    local function headerButton(name,glyph,x)
        local b=make("TextButton",{Name=name,Position=UDim2.new(1,x,0,18),Size=UDim2.fromOffset(28,28),Text=glyph,TextSize=20,
            Font=Enum.Font.Gotham,TextColor3=C.Sub,BackgroundColor3=C.Panel,BorderSizePixel=0,AutoButtonColor=false},top);round(b,8);hover(b);return b
    end
    local close=headerButton("Close","×",-43);local minimize=headerButton("Minimize","−",-78)
    local side=make("Frame",{Name="Sidebar",Position=UDim2.fromOffset(0,64),Size=UDim2.new(0,136,1,-64),BackgroundColor3=C.Panel,BorderSizePixel=0},surface)
    local content=make("Frame",{Position=UDim2.fromOffset(136,64),Size=UDim2.new(1,-136,1,-91),BackgroundTransparency=1,ClipsDescendants=true},surface)
    local footer=text(surface,"N0VA_0100  /  RIFT 5.6",9,C.Sub,UDim2.new(0,151,1,-23),UDim2.new(1,-166,0,18))
    local pages,tabs,selected={},{},"combat"
    local function select(id)
        selected=id
        for key,page in pairs(pages) do
            page.Visible=key==id
            if key==id then page.GroupTransparency=cfg.ReduceMotion and 0 or 1;animate(page,{GroupTransparency=0},0.22) end
        end
        for key,b in pairs(tabs) do animate(b,{BackgroundTransparency=key==id and 0 or 1,TextColor3=key==id and C.Accent or C.Sub}) end
    end
    for i,entry in ipairs({{"combat","Combat"},{"visuals","Visuals"},{"settings","Settings"}}) do
        local id,title=entry[1],entry[2]
        local tab=make("TextButton",{Name="Tab_"..id,Position=UDim2.fromOffset(10,17+(i-1)*45),Size=UDim2.new(1,-20,0,36),Text="  "..title,
            Font=Enum.Font.GothamBold,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,BackgroundColor3=C.Raised,TextColor3=C.Sub,BorderSizePixel=0,AutoButtonColor=false},side);round(tab,8);hover(tab);tabs[id]=tab
        connect(tab.Activated,function() select(id) end)
        local page=make("CanvasGroup",{Name="Page_"..id,Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Visible=false},content)
        local scroll=make("ScrollingFrame",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,
            ScrollBarImageColor3=C.Line,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y},page)
        make("UIPadding",{PaddingLeft=UDim.new(0,16),PaddingRight=UDim.new(0,16),PaddingTop=UDim.new(0,16),PaddingBottom=UDim.new(0,16)},scroll)
        make("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,12)},scroll)
        text(scroll,title,23,C.Text,nil,UDim2.new(1,0,0,34),true);pages[id]=page;page:SetAttribute("TabId",id)
        M[id]=scroll
    end
    local function section(parent,title,description)
        local box=make("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundColor3=C.Panel,BorderSizePixel=0},parent);round(box,11)
        make("UIStroke",{Color=C.Line,Transparency=0.4},box)
        make("UIPadding",{PaddingLeft=UDim.new(0,14),PaddingRight=UDim.new(0,14),PaddingTop=UDim.new(0,12),PaddingBottom=UDim.new(0,12)},box)
        make("UIListLayout",{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder},box)
        text(box,title,13,C.Text,nil,UDim2.new(1,0,0,22),true)
        if description then local note=text(box,description,11,C.Sub,nil,UDim2.new(1,0,0,0));note.TextWrapped=true;note.AutomaticSize=Enum.AutomaticSize.Y end
        return box
    end
    local paints={};local sliderDrag
    local function toggle(parent,key,title)
        local b=make("TextButton",{Name=key,Size=UDim2.new(1,0,0,40),BackgroundTransparency=1,Text="",AutoButtonColor=false,BorderSizePixel=0},parent);hover(b)
        local caption=text(b,title,12,C.Text,UDim2.fromOffset(0,7),UDim2.new(1,-52,0,28),true);caption.TextWrapped=true
        local track=make("Frame",{AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,0,0.5,0),Size=UDim2.fromOffset(36,20),BackgroundColor3=C.Line,BorderSizePixel=0},b);round(track,12)
        local knob=make("Frame",{Size=UDim2.fromOffset(14,14),Position=UDim2.fromOffset(3,3),BackgroundColor3=C.Sub,BorderSizePixel=0},track);round(knob,8)
        local previous
        local function paint()
            if previous==cfg[key] then return end;previous=cfg[key]
            animate(track,{BackgroundColor3=previous and C.Accent or C.Line})
            animate(knob,{Position=UDim2.fromOffset(previous and 19 or 3,3),BackgroundColor3=previous and C.Base or C.Sub})
        end
        table.insert(paints,paint);paint();connect(b.Activated,function() API.SetOption(key,not cfg[key]) end)
    end
    local function slider(parent,key,title,minimum,maximum,percent)
        local row=make("Frame",{Name=key,Size=UDim2.new(1,0,0,51),BackgroundTransparency=1},parent)
        text(row,title,12,C.Text,nil,UDim2.new(1,-50,0,20),true)
        local value=text(row,"",11,C.Accent,UDim2.new(1,-50,0,0),UDim2.fromOffset(50,20),true);value.TextXAlignment=Enum.TextXAlignment.Right
        local hit=make("TextButton",{Position=UDim2.fromOffset(0,22),Size=UDim2.new(1,0,0,26),Text="",BackgroundTransparency=1,AutoButtonColor=false},row)
        local track=make("Frame",{Position=UDim2.fromOffset(0,10),Size=UDim2.new(1,0,0,4),BackgroundColor3=C.Line,BorderSizePixel=0},hit);round(track,3)
        local fill=make("Frame",{Size=UDim2.fromScale(0,1),BackgroundColor3=C.Accent,BorderSizePixel=0},track);round(fill,3)
        local knob=make("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Size=UDim2.fromOffset(11,11),BackgroundColor3=C.Text,BorderSizePixel=0},track);round(knob,7)
        local function paint()
            local a=(cfg[key]-minimum)/(maximum-minimum);fill.Size=UDim2.fromScale(a,1);knob.Position=UDim2.fromScale(a,0.5)
            value.Text=percent and tostring(math.floor(cfg[key]*100)).."%" or tostring(math.floor(cfg[key]))
        end
        local function update(x)
            if track.AbsoluteSize.X<=0 then return end
            local a=math.clamp((x-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1);local v=minimum+(maximum-minimum)*a
            API.SetOption(key,percent and v or math.floor(v+0.5))
        end
        table.insert(paints,paint);paint()
        connect(hit.InputBegan,function(input)
            if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then sliderDrag={Input=input,Update=update};update(input.Position.X) end
        end)
    end
    local function button(parent,name,title,fn)
        local b=make("TextButton",{Name=name,Text=title,Size=UDim2.new(1,0,0,37),Font=Enum.Font.GothamBold,TextSize=12,
            TextColor3=C.Text,BackgroundColor3=C.Raised,AutoButtonColor=false,BorderSizePixel=0},parent);round(b,8);hover(b);connect(b.Activated,fn)
    end
    local farm=section(M.combat,"AUTO FARM","Automatically selects opponents, moves into position, and requests your hero’s available attacks and abilities.")
    local play=make("TextButton",{Name="Play",Size=UDim2.new(1,0,0,43),Text="PLAY",Font=Enum.Font.GothamBold,TextSize=13,
        TextColor3=C.Base,BackgroundColor3=C.Accent,BorderSizePixel=0,AutoButtonColor=false},farm);round(play,8);hover(play)
    local status=text(farm,"Off",11,C.Sub,nil,UDim2.new(1,0,0,32));status.Name="Status";status.TextWrapped=true
    connect(play.Activated,function() API.SetEnabled(not API.Enabled) end)
    local defense=section(M.combat,"ULTRA INSTINCT","Requests the normal dash when ready; otherwise briefly sidesteps at your current walking speed. Respects dash cooldowns. Walks toward a larger clear escape for up to 0.5 sec. Changing your joystick direction takes control immediately. Attack cues and visible bounds cannot guarantee avoidance.")
    toggle(defense,"UltraInstinct","Enable Ultra Instinct")
    slider(defense,"InstinctRange","Nearby attack range",6,24)
    slider(defense,"InstinctMaxDistance","Sidestep limit",4,12)
    local instinct=text(defense,"Off",11,C.Accent,nil,UDim2.new(1,0,0,48));instinct.TextWrapped=true
    button(defense,"TestDodge","Test normal sidestep",function()
        local ok,reason=API.Instinct.TestDodge();footer.Text=ok and "Normal sidestep requested · see report" or (reason or "Test blocked")
    end)
    button(defense,"RecordDodge","Record nearby attacks · 10 sec",function()
        API.Instinct.RecordEncounter();footer.Text="Recording nearby attacks for 10 seconds"
    end)
    button(defense,"CopyDodgeReport","Copy dodge report",function()
        local _,copied=API.CopyDodgeReport();footer.Text=copied and "Dodge report copied" or "Dodge report printed in console"
    end)
    local esp=section(M.visuals,"PLAYER ESP","Hero-colored chams, role above username. No boxes, tracers, distances or health bars.")
    toggle(esp,"ESP","Enable player ESP");toggle(esp,"Chams","Chams");toggle(esp,"Roles","Hero role");toggle(esp,"Names","Usernames")
    slider(esp,"ChamOpacity","Cham opacity",0,1,true)
    local identity=section(M.visuals,"HERO IDENTIFICATION","Confirmed mappings take priority. Estimated names are labelled; unmapped game IDs stay visible.")
    toggle(identity,"GuessRoles","Estimate unmapped roles")
    local settings=section(M.settings,"INTERFACE","Drag the header to move. Minimize to the Rift emblem; tap it to reopen. RightShift also toggles the window.")
    toggle(settings,"ReduceMotion","Reduce motion")
    local tools=section(M.settings,"SESSION")
    button(tools,"CopyReport","Copy diagnostics",function() local _,copied=API.CopyDiagnostics();footer.Text=copied and "Diagnostics copied" or "Diagnostics printed in console" end)
    button(tools,"Rejoin","Rejoin server",function()
        local p=game:GetService("Players").LocalPlayer;local t=game:GetService("TeleportService")
        if game.JobId~="" then t:TeleportToPlaceInstance(game.PlaceId,game.JobId,p) else t:Teleport(game.PlaceId,p) end
    end)
    button(tools,"Unload","Unload Rift Hub",API.Unload)
    text(M.settings,"Rift Hub · N0VA_0100",11,C.Sub,nil,UDim2.new(1,0,0,24))
    local bubble=make("TextButton",{Name="Restore",Text="R",AnchorPoint=Vector2.new(),Position=UDim2.fromOffset(18,150),Size=UDim2.fromOffset(48,48),TextSize=24,
        Font=Enum.Font.GothamBold,TextColor3=C.Text,BackgroundColor3=C.Base,BorderSizePixel=0,AutoButtonColor=false,Visible=false},gui);round(bubble,13);hover(bubble)
    make("UIStroke",{Color=C.Accent,Transparency=0.3},bubble)
    local miniLogo=make("ImageLabel",{Position=UDim2.fromOffset(8,8),Size=UDim2.fromOffset(32,32),BackgroundTransparency=1},bubble);ctx.Brand.Apply(miniLogo,bubble)
    local minimized=false
    local function minimizeTo(on) minimized=on;window.Visible=not on;bubble.Visible=on end
    connect(minimize.Activated,function() minimizeTo(true) end)
    connect(close.Activated,API.Unload)
    local drag,lastDragAt=nil,-10
    local function draggable(handle,target)
        connect(handle.InputBegan,function(input)
            if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
                drag={Input=input,Start=input.Position,Origin=target.Position,Target=target,Moved=false};ctx.Drag(true)
            end
        end)
    end
    draggable(top,window);draggable(bubble,bubble)
    connect(bubble.Activated,function() if os.clock()-lastDragAt>0.2 then minimizeTo(false) end end)
    connect(Input.InputChanged,function(input)
        local function matches(press) return input==press or input.UserInputType==Enum.UserInputType.MouseMovement and press.UserInputType==Enum.UserInputType.MouseButton1 end
        if sliderDrag and matches(sliderDrag.Input) then sliderDrag.Update(input.Position.X) end
        if drag and matches(drag.Input) then
            local delta=input.Position-drag.Start;if delta.Magnitude>7 then drag.Moved=true end
            local view=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize
            if view then
                local size=drag.Target==window and Vector2.new(window.Size.X.Offset*fit.Scale,window.Size.Y.Offset*fit.Scale) or Vector2.new(48,48)
                local anchor=drag.Target.AnchorPoint;local x=drag.Origin.X.Scale*view.X+drag.Origin.X.Offset+delta.X;local y=drag.Origin.Y.Scale*view.Y+drag.Origin.Y.Offset+delta.Y
                drag.Target.Position=UDim2.fromOffset(math.clamp(x,8+size.X*anchor.X,math.max(8+size.X*anchor.X,view.X-8-size.X*(1-anchor.X))),math.clamp(y,8+size.Y*anchor.Y,math.max(8+size.Y*anchor.Y,view.Y-8-size.Y*(1-anchor.Y))))
            end
        end
    end)
    connect(Input.InputEnded,function(input)
        if sliderDrag and input==sliderDrag.Input then sliderDrag=nil end
        if drag and input==drag.Input then if drag.Moved then lastDragAt=os.clock() end;drag=nil;ctx.Drag(false) end
    end)
    connect(Input.WindowFocusReleased,function() sliderDrag=nil;drag=nil;ctx.Drag(false);ctx.Focus(false) end)
    connect(Input.WindowFocused,function() ctx.Focus(true) end)
    connect(Input.InputBegan,function(input,processed) if not processed and not Input:GetFocusedTextBox() and input.KeyCode==Enum.KeyCode.RightShift then minimizeTo(not minimized) end end)
    local lastView
    function M.Step()
        if dead then return end
        local view=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize
        if view and view~=lastView then
            lastView=view;local w,h=math.clamp(view.X-20,320,680),math.clamp(view.Y-32,280,470)
            window.Size=UDim2.fromOffset(w,h);fit.Scale=math.max(0.1,math.min(1,(view.X-20)/w,(view.Y-32)/h))
            local sideWidth=w<500 and 100 or 136
            side.Size=UDim2.new(0,sideWidth,1,-64);content.Position=UDim2.fromOffset(sideWidth,64);content.Size=UDim2.new(1,-sideWidth,1,-91)
            footer.Position=UDim2.new(0,sideWidth+15,1,-23);footer.Size=UDim2.new(1,-sideWidth-30,0,18);window.Position=UDim2.fromScale(0.5,0.5)
        end
        for _,paint in ipairs(paints) do paint() end
        play.Text=API.Enabled and "STOP" or "PLAY"
        play.BackgroundColor3=API.Enabled and Color3.fromRGB(99,52,70) or C.Accent;play.TextColor3=API.Enabled and C.Text or C.Base
        status.Text=API.Status;instinct.Text=API.Instinct.Status.."  ·  "..API.Instinct.AutomaticMoves.." automatic · "..API.Instinct.TestMoves.." tests"..(API.Instinct.Recording and " · RECORDING" or "")
    end
    function M.Destroy()
        if dead then return end;dead=true;sliderDrag=nil;drag=nil
        for _,c in ipairs(connections) do c:Disconnect() end;table.clear(connections)
    end
    M.Play=play;M.Status=status;M.SelectTab=select;M.Window=window;M.Step();select("combat")
    animate(surface,{GroupTransparency=0},0.25);animate(opening,{Scale=1},0.28)
    return M
end
