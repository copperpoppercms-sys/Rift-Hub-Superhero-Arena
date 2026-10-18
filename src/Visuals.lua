-- Only hero-colored chams, a role label, and the exact username are drawn.
return function(ctx)
    local Players=game:GetService("Players")
    local LocalPlayer=Players.LocalPlayer
    local M={Rows={}}
    local cfg=ctx.Config
    local elapsed,menuAge=0,2
    local learned={}
    local function norm(s) return type(s)=="string" and s:lower():gsub("[^%w]","") or "" end
    local colors={
	["Iron Man"] = Color3.fromRGB(220, 65, 48), ["Hulk"] = Color3.fromRGB(78, 214, 112),
	["Aquaman"] = Color3.fromRGB(48, 180, 173), ["Spiderman"] = Color3.fromRGB(230, 57, 65),
	["Frozone"] = Color3.fromRGB(130, 216, 255), ["Captain America"] = Color3.fromRGB(91, 146, 244),
	["Flash"] = Color3.fromRGB(240, 75, 65), ["Storm"] = Color3.fromRGB(233, 232, 248),
	["Magneto"] = Color3.fromRGB(194, 83, 224), ["Ghost Rider"] = Color3.fromRGB(255, 136, 53),
	["Thor"] = Color3.fromRGB(107, 180, 248), ["Doctor Strange"] = Color3.fromRGB(240, 183, 80),
	["Raven"] = Color3.fromRGB(159, 100, 232), ["Groot"] = Color3.fromRGB(177, 141, 93),
	["Wolverine"] = Color3.fromRGB(245, 211, 63), ["Superman"] = Color3.fromRGB(79, 139, 237),
	["Red Hulk"] = Color3.fromRGB(242, 72, 65), ["Billy Butcher"] = Color3.fromRGB(172, 175, 184),
	["War Machine"] = Color3.fromRGB(164, 181, 195), ["Deadpool"] = Color3.fromRGB(213, 61, 77),
	["Batman"] = Color3.fromRGB(164, 174, 195), ["Thanos"] = Color3.fromRGB(173, 116, 230),
	["Loki"] = Color3.fromRGB(157, 203, 85), ["Venom"] = Color3.fromRGB(182, 181, 204),
	["Galactic Thanos"] = "RAINBOW",
}
    local known={}
    for name in pairs(colors) do known[norm(name)]=name end
    local aliases={water="Aquaman",earth="Hulk",knight="Thor",samurai="Deadpool",nature="Groot",drstrange="Doctor Strange",theflash="Flash",spiderman="Spiderman"}
    for key,name in pairs(aliases) do known[key]=name end
    local estimates={fire="Ghost Rider",ice="Frozone",wind="Storm",tech="Iron Man",technology="Iron Man",armor="Iron Man",spider="Spiderman",web="Spiderman",
        shield="Captain America",speed="Flash",metal="Magneto",lightning="Thor",thunder="Thor",magic="Doctor Strange",sorcery="Doctor Strange",darkness="Raven",
        claws="Wolverine",redearth="Red Hulk",butcher="Billy Butcher",arsenal="War Machine",shadow="Batman",cosmic="Thanos",illusion="Loki",symbiote="Venom",galactic="Galactic Thanos"}
    local function valid(raw)
        return type(raw)=="string" and raw~="" and #raw<=64 and not raw:find("%c") and not tonumber(raw)
            and not ({unknown=true,none=true,default=true,loading=true,unselected=true})[norm(raw)]
    end
    function M.LearnMenu()
        table.clear(learned)
        local pg=LocalPlayer:FindFirstChild("PlayerGui");if not pg then return end
        local scopes,conflicts={},{ }
        local count=0
        for _,node in ipairs(pg:GetDescendants()) do
            count+=1;if count>4000 then break end
            if not node:IsDescendantOf(ctx.Gui) and (node:IsA("TextLabel") or node:IsA("TextButton")) then
                local hero=known[norm(node.Text)]
                if hero then
                    local parent=node.Parent
                    for _=1,2 do
                        if not parent or parent:IsA("ScreenGui") then break end
                        scopes[parent]=scopes[parent] or {};scopes[parent][hero]=true;parent=parent.Parent
                    end
                end
            end
        end
        for scope,names in pairs(scopes) do
            local name,total=nil,0;for hero in pairs(names) do name=hero;total+=1 end
            if total==1 then
                local values=scope:GetAttributes()
                for _,child in ipairs(scope:GetChildren()) do if child:IsA("StringValue") then values[child.Name]=child.Value end end
                for key,value in pairs(values) do
                    if ({morphcurrent=true,morphid=true,power=true,powerid=true,heroid=true,characterid=true,internalname=true})[norm(key)] and valid(value) and not known[norm(value)] then
                        local id=norm(value)
                        if learned[id] and learned[id]~=name then conflicts[id]=true else learned[id]=name end
                    end
                end
            end
        end
        for id in pairs(conflicts) do learned[id]=nil end
    end
    function M.Resolve(plr)
        local char=ctx.Body(plr)
        local raw,source
        for _,node in ipairs({char or false,plr}) do
            if node then
                for _,key in ipairs({"MorphCurrent","power","Hero","HeroName","CharacterName","SelectedHero","Role"}) do
                    local value=node:GetAttribute(key)
                    if not valid(value) then local child=node:FindFirstChild(key);value=child and child:IsA("StringValue") and child.Value end
                    if valid(value) then raw=value;source=node.Name.."."..key;break end
                end
            end
            if raw then break end
        end
        local key=norm(raw);local hero=known[key] or learned[key]
        local kind=hero and "confirmed" or "unmapped"
        if not hero and cfg.GuessRoles and estimates[key] then hero=estimates[key];kind="estimate" end
        hero=hero or raw
        local color=colors[hero] or Color3.fromRGB(178,161,255)
        if color=="RAINBOW" then color=Color3.fromHSV((elapsed*0.15)%1,0.78,1) end
        return hero,kind,color,source
    end
    local function make(class,props,parent)
        local node=Instance.new(class);for k,v in pairs(props) do node[k]=v end;node.Parent=parent;return node
    end
    local function remove(plr)
        local row=M.Rows[plr];if not row then return end
        row.Highlight:Destroy();row.Tag:Destroy();M.Rows[plr]=nil
    end
    function M.Step(dt)
        elapsed+=dt;menuAge+=dt
        if cfg.ESP and menuAge>=2 then menuAge=0;M.LearnMenu() end
        for _,plr in ipairs(Players:GetPlayers()) do
            if plr~=LocalPlayer then
                local char,hum,root=ctx.Body(plr)
                local row=M.Rows[plr]
                if row and (row.Character~=char or not char) then remove(plr);row=nil end
                if char and cfg.ESP then
                    if not row then
                        local h=make("Highlight",{Name="RiftSHA_Highlight",Adornee=char,DepthMode=Enum.HighlightDepthMode.AlwaysOnTop,OutlineTransparency=0.05},char)
                        local tag=make("BillboardGui",{Name="RiftSHA_Tag",Size=UDim2.fromOffset(230,44),StudsOffsetWorldSpace=Vector3.new(0,2,0),AlwaysOnTop=true,MaxDistance=2000},char)
                        local function label(name,y,size)
                            return make("TextLabel",{Name=name,Position=UDim2.fromOffset(0,y),Size=UDim2.new(1,0,0,20),BackgroundTransparency=1,Font=Enum.Font.GothamBold,TextSize=size,TextStrokeTransparency=0.3},tag)
                        end
                        row={Character=char,Highlight=h,Tag=tag,Role=label("Role",0,13),Username=label("Username",22,12)};M.Rows[plr]=row
                    end
                    local hero,kind,color=M.Resolve(plr)
                    row.Highlight.Enabled=cfg.Chams;row.Highlight.FillColor=color;row.Highlight.OutlineColor=color;row.Highlight.FillTransparency=1-cfg.ChamOpacity
                    row.Tag.Enabled=cfg.Names or cfg.Roles;row.Tag.Adornee=char:FindFirstChild("Head") or root
                    row.Role.Visible=cfg.Roles;row.Role.Text=(hero or "Role unavailable")..(kind=="estimate" and " · estimate" or hero and kind=="unmapped" and " · unmapped" or "");row.Role.TextColor3=color
                    row.Username.Visible=cfg.Names;row.Username.Text="@"..plr.Name;row.Username.TextColor3=Color3.fromRGB(240,240,246)
                elseif row then remove(plr) end
            end
        end
        local stale={};for plr in pairs(M.Rows) do if plr.Parent~=Players then table.insert(stale,plr) end end
        for _,plr in ipairs(stale) do remove(plr) end
    end
    function M.Destroy() local players={};for plr in pairs(M.Rows) do table.insert(players,plr) end;for _,plr in ipairs(players) do remove(plr) end end
    return M
end
