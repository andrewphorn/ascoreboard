local function half(i) return i/2 end
local function clamp(inv, min, max)
	if inv > max then
		return max
	elseif inv < min then
		return min
	else
		return inv
	end
end

scb = {}
scb.initd = 0

scb.width = clamp(ScrW()*.75,800,4096)
scb.height = clamp(ScrH()*.70,600,4096)
scb.roundness = 4
scb.color = Color(255,255,255,0)
scb.padding = 5

scb.title = {}
scb.title.height = (clamp(ScrH(),600,4096)/16)*.7
scb.nextrefresh = 0
nextcheckcheck = 0


scb.init = function()
	scb.initd = 1

	-- Fonts
	surface.CreateFont("ScoreboardTitleFont", {
		font		= "default",
		size		= scb.title.height,
		weight		= 1000,
		antialias 	= true
	})
	surface.CreateFont("ScoreboardInfoFont", {
		font 		= "default",
		size 		= scb.title.height * .50,
		weight 		= 1000,
		antialias 	= true
	})
	surface.CreateFont("ScoreboardPlayerFont", {
		font 		= "default",
		size 		= 22,
		weight 		= 400,
		antialias 	= true
	})

	-- Blur (DFrame)
	Blur = vgui.Create("DFrame")
	Blur:SetSize(1,1)
	Blur:SetPos(0,0)
	Blur:SetVisible(false)
	Blur:SetBackgroundBlur(true)
	Blur.Open = function(self) self:SetVisible(true) end
	Blur.Close = function(self) self:SetVisible(false) end

	-- ScoreboardFrame (DPanel)
	ScoreboardFrame = vgui.Create("DPanel")
	ScoreboardFrame:SetSize(scb.width,scb.height)
	ScoreboardFrame:Center()
	ScoreboardFrame:SetVisible(false)
	ScoreboardFrame.Open = function(self) self:SetVisible(true) Blur:Open() end
	ScoreboardFrame.Close = function(self) self:SetVisible(false) Blur:Close() end
	ScoreboardFrame.Paint = function(self)
		draw.RoundedBox(scb.roundness,0,0,self:GetWide(),self:GetTall(),Color(0,0,0,0))
	end
	ScoreboardFrame.Think = function(self)
		if self:IsVisible() then
			if nextcheckcheck < CurTime() then
				nextcheckcheck = CurTime() + 3
				Scoreboard:Refill()
			end
		end
	end

	-- TitleFrame (DPanel)
	TitleFrame = vgui.Create("DPanel",ScoreboardFrame)
	TitleFrame:SetSize(ScoreboardFrame:GetWide()-(scb.padding*2),scb.title.height)
	TitleFrame:SetPos(scb.padding,0)
	TitleFrame.Paint = function(self)
		draw.RoundedBox(scb.roundness,0,0,self:GetWide(),self:GetTall(),Color(0,0,0,0))
	end

	-- Title (DLabel)
	Title = vgui.Create("DLabel",TitleFrame)
	Title:SetPos(0,0)
	Title:SetTextColor(Color(255,255,255,255))
	Title:SetExpensiveShadow( 2, Color( 0, 0, 0, 190 ) )
	Title:SetSize(Title:GetWide(),TitleFrame:GetTall())
	Title.Paint = function(self)
		self:SetFont("ScoreboardTitleFont")
		self:SetText(GetConVarString("hostname"))
		self:SizeToContentsX()
	end

	-- PlayerCount (DLabel)
	PlayerCount = vgui.Create("DLabel",TitleFrame)
	PlayerCount:SetPos(Title:GetWide(),0)
	PlayerCount:SetTextColor(Color(250,250,250,255))
	PlayerCount:SetExpensiveShadow( 1, Color( 0, 0, 0, 190 ) )
	PlayerCount:SetSize(TitleFrame:GetWide()-Title:GetWide(),TitleFrame:GetTall())
	PlayerCount.Paint = function(self)
		local word = 'players'
		if #player.GetAll() == 1 then
			word = 'player'
		end
		self:SetFont("ScoreboardInfoFont")
		self:SetText(" has "..#player.GetAll().."/"..GetConVarString("maxplayers").." "..word.." online.")
		self:SizeToContentsY()
		self:SetPos(Title:GetWide()+(scb.padding*.33),TitleFrame:GetTall()-self:GetTall()-(scb.padding*.33))
	end


	-- Scoreboard (DPanel)
	Scoreboard = vgui.Create("DPanel",ScoreboardFrame)
	Scoreboard:SetPos(0,scb.title.height)
	Scoreboard:SetSize(ScoreboardFrame:GetWide(),ScoreboardFrame:GetTall()-TitleFrame:GetTall())
	Scoreboard.Paint = function(self)
		draw.RoundedBox(scb.roundness,-scb.padding,0,self:GetWide(),self:GetTall(),scb.color)
	end
	Scoreboard.Refill = function(self)
		local players = {}
		for _,ply in pairs(player.GetAll()) do
			if not players[ply:Team()] then players[ply:Team()] = {} end
			table.insert(players[ply:Team()],ply)
		end

		self.sscoreboards = {}
		local lt = nil
		local col = 1 -- not number of columns, usually. 1 and 2 are numbers of columns, but if it's 3 then it does two and the last column is extra large.
		if #players == 1 then
			col = 1
		elseif math.fmod(#players, 2) == 0 then
			col = 1
		elseif math.fmod(#players, 2) ~= 0 then
			col = 3
		end
		local x = 1
		for team,plys in pairs(players) do
			print(team)
			self.sscoreboards[x] = vgui.Create("DPanelList",Scoreboard)
			if col == 1 then
				self.sscoreboards[x]:SetSize((Scoreboard:GetWide())-(scb.padding*2),Scoreboard:GetTall()-(scb.padding*2))
				self.sscoreboards[x]:SetPos(scb.padding,scb.padding)
			elseif col == 2 or col == 3 then
				if x == #players and col == 3 then
					self.sscoreboards[x]:SetSize((Scoreboard:GetWide())-(scb.padding*2),Scoreboard:GetTall()-(scb.padding*2))
				else
					self.sscoreboards[x]:SetSize((Scoreboard:GetWide()/2)-(scb.padding*2),Scoreboard:GetTall()-(scb.padding*2))
				end
			end
			self.sscoreboards[x]:EnableHorizontal(false)
			self.sscoreboards[x]:EnableVerticalScrollbar(true)
			self.sscoreboards[x]:SetSpacing(scb.padding/5)
			self.sscoreboards[x].players = {}
			for _,ply in ipairs(plys) do
				local pcolor = Color(110,250,150,150)
				local p = vgui.Create("DPanel")
				local ID = tostring(ply:SteamID())
				local av = vgui.Create("AvatarImage", p)
				local mB = vgui.Create("DImageButton",p)
				local avp = 3
				p:SetPos(0,0)
				p:SetSize(self.sscoreboards[x]:GetWide() - (scb.padding*2),32)

				av:SetPos(avp,avp)
				av:SetSize(32-(avp*2),32-(avp*2))
				av:SetPlayer(ply,32)

				mB:SetSize(32,32)
				mB:Dock(RIGHT)
				mB:SetPos(avp,avp)
				p.Paint = function(self)
					draw.RoundedBox(4,0,0,self:GetWide(),self:GetTall(),pcolor)
					surface.SetFont("ScoreboardPlayerFont")
					surface.SetTextPos( 32+ (avp),self:GetTall()/2-(22/2) )
					surface.SetTextColor(Color(25,25,25,250))
					surface.DrawText(ply:GetName())	
				end
				mB.Think = function(self)
					if ply:IsMuted() then
						mB:SetImage("icon32/muted.png")
					else 
						mB:SetImage("icon32/unmuted.png")
					end
					mB.DoClick = function (self) ply:SetMuted(!ply:IsMuted()) end
				end
			self.sscoreboards[x]:AddItem(p)
			end	
		end
	end
	Scoreboard:Refill()
end

function ScoreboardOpened()
	if scb.initd == 0 then
		scb.init()
	end
	ScoreboardFrame:Open()
	gui.EnableScreenClicker(true)
	return true
end
hook.Add("ScoreboardShow", "Open scoreboard.", ScoreboardOpened)

function ScoreboardClosed()
	if scb.initd == 0 then
		scb.init()
	end
	gui.EnableScreenClicker(false)
	ScoreboardFrame:Close()
	return true
end
hook.Add("ScoreboardHide", "Close scoreboard.", ScoreboardClosed)