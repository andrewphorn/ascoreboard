


local Scoreboard_data = {}
Scoreboard_data.created = false

 -- Scoreboard_data.init -- called when scoreboard is initialized.

Scoreboard_data.init = function()
	local self = Scoreboard_data
	self.width = math.Clamp(ScrW()*.75,800,4096)
	self.height = math.Clamp(ScrH()*.70,600,4096)
	self.roundness = 4
	self.padding = 5
	self.backgroundcolor = Color(0, 0, 0, 150)
	self.nextrefresh = 0
	self.teams = team.GetAllTeams()

	self.title = {}
	self.title.height = (math.Clamp(ScrH(),600,4096)/16) * .7

	self.fonts = {
		surface.CreateFont("ScoreboardTitleFont", {
			font = "default",
			size = self.title.height,
			weight = 1000,
			antialias = true
		}),

		surface.CreateFont("ScoreboardInfoFont", {
			font = "default",
			size = self.title.height * .5,
			weight = 1000,
			antialias = true
		}),

		surface.CreateFont("ScoreboardPlayerFont", {
			font = "default",
			size = 22,
			weight = 400,
			antialias = true
		})
	}

	self.vgui = {}

	-- self.vgui.TransparentPaint (N/A) ~ Empty paint function. Makes elements draw transparent.
	-- Purpose of using this: I can change the function of all of the frames at the same time.
	self.vgui.TransparentPaint = function() end

	-- self.vgui.Columns (N/A) ~ Empty table, to be filled up with columns.
	self.vgui.Columns = {}

	-- self.vgui.Blur (DFrame) ~ Used to blur the background. I should probably do it better.
	self.vgui.Blur = vgui.Create("DFrame")
	self.vgui.Blur:SetSize(1,1)
	self.vgui.Blur:SetPos(0,0)
	self.vgui.Blur:SetVisible(false)
	self.vgui.Blur:SetBackgroundBlur(true)
	self.vgui.Blur.Open = function(self) self:SetVisible(true) end
	self.vgui.Blur.Close = function(self) self:SetVisible(false) end

	-- self.vgui.ScoreboardFrame (DPanel) ~ Contains the scoreboard.
	self.vgui.ScoreboardFrame = vgui.Create("DPanel")
	self.vgui.ScoreboardFrame:SetSize(self.width,self.height)
	self.vgui.ScoreboardFrame:Center()
	self.vgui.ScoreboardFrame:SetVisible(false)
	self.vgui.ScoreboardFrame.Open = function(Self) Self:SetVisible(true) self.vgui.Blur:Open() end
	self.vgui.ScoreboardFrame.Close = function(Self) Self:SetVisible(false) self.vgui.Blur:Close() end
	self.vgui.ScoreboardFrame.Paint = self.vgui.TransparentPaint-- make it draw transparent

	-- self.vgui.TitleFrame (DPanel) ~ Contains playercount & server name.
	self.vgui.TitleFrame = vgui.Create("DPanel",self.vgui.ScoreboardFrame)
	self.vgui.TitleFrame:SetSize(self.vgui.ScoreboardFrame:GetWide() - (self.padding*2), self.title.height)
	self.vgui.TitleFrame:SetPos(self.padding,0)
	self.vgui.TitleFrame.Paint = self.vgui.TransparentPaint

	-- self.vgui.Title (DLabel) ~ Contains server name.
	self.vgui.Title = vgui.Create("DLabel",self.vgui.TitleFrame)
	self.vgui.Title:SetPos(0,0)
	self.vgui.Title:SetTextColor(Color(255,255,255,250))
	self.vgui.Title:SetExpensiveShadow(2,Color(0,0,0,190))
	self.vgui.Title:SetSize(self.vgui.Title:GetWide(),self.vgui.TitleFrame:GetTall())
	self.vgui.Title.Paint = function(Self)
		Self:SetFont("ScoreboardTitleFont")
		Self:SetText(GetConVarString("hostname"):upper())
		Self:SizeToContentsX()
	end

	-- self.vgui.PlayerCount (DLabel) ~ Contains player count.
	self.vgui.PlayerCount = vgui.Create("DLabel",self.vgui.TitleFrame)
	self.vgui.PlayerCount:SetPos(self.vgui.Title:GetWide(),0)
	self.vgui.PlayerCount:SetTextColor(Color(250,250,250,250))
	self.vgui.PlayerCount:SetExpensiveShadow(1,Color(0,0,0,210))
	self.vgui.PlayerCount:SetSize(self.vgui.TitleFrame:GetWide()-self.vgui.Title:GetWide(),self.vgui.TitleFrame:GetTall())
	self.vgui.PlayerCount.Paint = function(Self)
		local c_word = "players"
		if #player.GetAll() == 1 then
			word = "player"
		end
		Self:SetFont("ScoreboardInfoFont")
		Self:SetText(" has "..#player.GetAll().."/"..GetConVarString("maxplayers").." "..c_word.." online.")
		Self:SizeToContentsY()
		Self:SetPos(self.vgui.Title:GetWide()+(self.padding*.33),self.vgui.TitleFrame:GetTall()-Self:GetTall()-(self.padding*.33))
	end

	-- self.vgui.Scoreboard (DPanel) ~ Contains scoreboards.
	self.vgui.Scoreboard = vgui.Create("DPanel",self.vgui.ScoreboardFrame)
	self.vgui.SCoreboard:SetPos(0,self.title.height)
	self.vgui.SCoreboard:SetSize(self.vgui.SCoreboardFrame:GetWide(),self.vgui.ScoreboardFrame:GetTall()-self.vgui.TitleFrame:GetTall())
	self.vgui.Scoreboard.Paint = self.vgui.TransparentPaint
	self.vgui.Scoreboard.Players = {}
	self.vgui.Scoreboard.Init = function(Self)
		local numteams = #self.teams
		local columntype = 1 -- 1 (one tall column) ~ 2 (2 half-width columns) ~ 3 (2 half-width columns with 1 full-width column at the bottom.)

		if numteams % 2 == 0 then
			columntype = 2
		elseif numteams % 2 == 1 then
			columntype = 3
		end

		if ScrW() < 1024 then
			columntype = 1
		end

		tid = 0
		for teamid,teamdata in pairs(self.teams) do
			-- make one column per team available.
			tid = tid + 1
			local columnwidth = 1
			if columntype == 2 then
				columwidth = .5
			elseif columntype == 3 and tid ~= numteams then
				columwidth = .5
			end
		end
	end
	self.vgui.Scoreboard.Refill = function(Self)
		for _,ply in pairs(player.GetAll()) do
			if IsValid(ply) and ~ply:IsBot() and ply:IsPlayer() then

			end
		end

	end

	self.created = true -- legalize gay weed
	Scoreboard_data = self
end

function ScoreboardOpened()
	if Scoreboard_data.created == false then
		Scoreboard_data.init()
	end
	Scoreboard_data.vgui.ScoreboardFrame:Open()
	gui.EnableScreenClicker(true)
	return true
end
hook.Add("ScoreboardShow", "Open the scoreboard.", ScoreboardOpened)

function ScoreboardClosed()
	if Scoreboard_data.created == false then
		Scoreboard_data.init()
	end
	gui.EnableScreenClicker(false)
	Scoreboard_data.vgui.ScoreboardFrame:Close()
	return true
end
hook.Add("ScoreboardHide", "Close the scoreboard.", ScoreboardClosed)