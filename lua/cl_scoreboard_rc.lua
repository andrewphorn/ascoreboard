local function tLength(tabel)
	local len = 0
	for k,_ in pairs(tabel) do
		if k == nil then
			len = len - 1
		end
		len = len + 1
	end
	return len
end

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
	self.Refill = 0

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
	self.vgui.TitleFrame:SetSize(self.vgui.ScoreboardFrame:GetWide(), self.title.height)
	self.vgui.TitleFrame:SetPos(0,0)
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
	self.vgui.Scoreboard:SetPos(0,self.title.height)
	self.vgui.Scoreboard:SetSize(self.vgui.ScoreboardFrame:GetWide(),self.vgui.ScoreboardFrame:GetTall()-self.vgui.TitleFrame:GetTall())
	self.vgui.Scoreboard.Players = {}
	self.vgui.Scoreboard.Teams = {}
	self.vgui.Scoreboard.Paint = self.vgui.TransparentPaint
	self.vgui.Scoreboard.Think = function(Self) -- Refresh think
		if Self:IsVisible() then
			if self.Refill < CurTime() then
				for teamid,thing in pairs(self.vgui.Columns) do
					thing:Refill()
				end
				self.Refill = CurTime() + 1
			end
		end
	end
	self.vgui.Scoreboard.Init = function(Self) -- Create all scoreboards.
		Self:Clear()
		Self.Teams = team.GetAllTeams()
		-- Some filtering and such.
		for team,data in pairs(Self.Teams) do
			if data.Name == "Joining/Connecting" then Self.Teams[team].Name = "Connecting" end
			if data.Name == "Unassigned" and gamemode.Get("sandbox") then Self.Teams[team].Name = "Players" end
			if data.Name == "Spectator" then Self.Teams[team].Name = "Spectators" end
			if gamemode.Get("sandbox") and data.Name == "Spectators" then Self.Teams[team] = nil end
		end


		local numteams = tLength(Self.Teams)
		local columntype = 1 -- 1 (one tall column) ~ 2 (2 half-width columns) ~ 3 (2 half-width columns with 1 full-width column at the bottom.)

		if numteams % 2 == 0 then
			columntype = 2
		elseif numteams % 2 == 1 then
			columntype = 3
		end

		if ScrW() < 1024 then
			columntype = 1
		end

		local tid = 0
		local odd = 1
		for teamid,teamdata in pairs(Self.Teams) do
			-- make one column per team available.
			tid = tid + 1
			if odd == 0 then odd = 1 else odd = 0 end
			local columnwidth = 1
			if columntype == 2 then
				columnwidth = .5
			end
			if columntype == 3 and tid ~= numteams then
				columnwidth = .5
			end

			local width = columnwidth * (self.vgui.ScoreboardFrame:GetWide()-(self.padding*2))
			local height = (self.vgui.Scoreboard:GetTall()/2) - (self.padding*2)
			if numteams == 1 or numteams == 2 then
				height = self.vgui.Scoreboard:GetTall() - (self.padding*2)
			end

			self.vgui.Columns[teamid] = vgui.Create("DPanelList",self.vgui.Scoreboard)
			self.vgui.Columns[teamid]:EnableHorizontal(false)
			self.vgui.Columns[teamid]:EnableVerticalScrollbar(true)
			self.vgui.Columns[teamid]:SetSize(height,width)
			self.vgui.Columns[teamid]:SetSpacing(self.padding)

			self.vgui.Columns[teamid].Title = vgui.Create("DLabel",self.vgui.Scoreboard)
			self.vgui.Columns[teamid].Title:SetText(teamdata.Name)
			self.vgui.Columns[teamid].Title:SetTextColor(Color(255,255,255,250))
			self.vgui.Columns[teamid].Title:SetExpensiveShadow(1,Color(0,0,0,210))
			self.vgui.Columns[teamid].Title:SetFont("ScoreboardPlayerFont")

			local position_x = self.padding
			local position_y = ((tid-1)*(height))+self.padding+(32*tid*columnwidth)

			if columnwidth == .5 then
				position_y = ((math.floor((tid-1)/2))*(height))+(self.padding*(columnwidth*2))
				position_x = (width*(odd))+(self.padding*(2*(odd)))
			end

			if columnwidth == 1 and columntype == 3 then
				position_y = ((math.floor((tid-1)/2))*(height))+(self.padding*(columnwidth*2))
			end

			self.vgui.Columns[teamid]:SetSize(width,height)
			self.vgui.Columns[teamid]:SetPos(position_x,position_y+32+self.padding)

			self.vgui.Columns[teamid].Title:SetSize(self.vgui.Columns[teamid]:GetWide(),32-self.padding)

			self.vgui.Columns[teamid].Title.UnderBar = vgui.Create("DPanel", self.vgui.Columns[teamid].Title)
			self.vgui.Columns[teamid].Title.UnderBar:SetSize(self.vgui.Columns[teamid].Title:GetWide(),self.vgui.Columns[teamid].Title:GetTall())
			self.vgui.Columns[teamid].Title.UnderBar.Paint = function(Self)
				local x,y = self.vgui.Columns[teamid].Title:GetPos()
				surface.SetDrawColor(team.GetColor(teamid))
				surface.DrawRect(0,self.vgui.Columns[teamid].Title:GetTall()-2,self.vgui.Columns[teamid]:GetWide(),3)
			end

			local tx,ty = self.vgui.Columns[teamid]:GetPos()
			self.vgui.Columns[teamid].Title:SetPos(tx,ty-32)
			self.vgui.Columns[teamid].Refill = function(Self) -- Fill scoreboards up with players.
				self.vgui.Scoreboard.Players = {}
				for _,ply in pairs(player.GetAll()) do
					if ply:Team() == teamid then
						table.insert(self.vgui.Scoreboard.Players,ply)

					end
				end

				for x,col in pairs(Self:GetItems()) do
					local delete = true
					for _,ply in pairs(self.vgui.Scoreboard.Players) do
						if ply:UserID() == col.UserID then delete = false end
					end
					if delete == true then
						Self:RemoveItem(col)
					end
				end

				for _,ply in pairs(self.vgui.Scoreboard.Players) do
					local alreadyexists = false
					for n,col in pairs(Self:GetItems()) do
						if ply:UserID() == col.UserID then
							alreadyexists = true
						end
					end
					if alreadyexists == false then
						local PlayerBar = vgui.Create("DPanel")
						local PlayerAv = vgui.Create("AvatarImage",PlayerBar)
						local PlayerMute = vgui.Create("DImageButton",PlayerBar)
						local PlayerName = vgui.Create("DLabel",PlayerBar)
						local PlayerPing = vgui.Create("DLabel",PlayerBar)
						local AvatarPadding = 3
						PlayerBar:SetSize(Self:GetWide(),32)
						PlayerBar:SetPos(0,0)
						PlayerBar.UserID = ply:UserID()
						PlayerBar.Paint = function(Self)
							local teamcolor = team.GetColor(teamid)
							teamcolor.r = teamcolor.r * .75
							teamcolor.g = teamcolor.g * .75
							teamcolor.b = teamcolor.b * .75
							surface.SetDrawColor(teamcolor)
							surface.DrawRect(0,0,Self:GetWide(),Self:GetTall())
						end

						PlayerAv:SetPos(AvatarPadding,AvatarPadding)
						PlayerAv:SetSize(32-(AvatarPadding*2),32-(AvatarPadding*2))
						PlayerAv:SetPlayer(ply,32)

						PlayerName:SetPos((AvatarPadding*2)+32,5)
						PlayerName:SetFont("ScoreboardPlayerFont")
						PlayerName:SetText(ply:Name())
						PlayerName:SizeToContentsX()
						PlayerName:SetTextColor(Color(255,255,255,250))
						PlayerName:SetExpensiveShadow(1,Color(0,0,0,210))
						PlayerName.Paint = function(Self) 
							if IsValid(ply) then
								Self:SetText(ply:Name())
								Self:SizeToContentsX()
							end
						end

						PlayerPing:SetSize(64,32)
						PlayerPing:Dock(RIGHT)
						PlayerPing:SetPos(AvatarPadding,(AvatarPadding*2)+32)
						PlayerPing:SetFont("ScoreboardPlayerFont")
						PlayerPing:SetText(ply:Ping())
						PlayerPing:SetTextColor(Color(255,255,255,250))
						PlayerPing:SetExpensiveShadow(1,Color(0,0,0,210))
						PlayerPing.Paint = function(Self)
							if IsValid(ply) then
								Self:SetText(ply:Ping())
							end
						end

						PlayerMute:SetSize(32,32)
						PlayerMute:Dock(RIGHT)
						PlayerMute:SetPos(AvatarPadding,AvatarPadding)
						PlayerMute.Think = function(Self)
							if IsValid(ply) then
								if ply:IsMuted() then
									Self:SetImage("icon32/muted.png")
								else
									Self:SetImage("icon32/unmuted.png")
								end
								Self.DoClick = function(self) ply:SetMuted(!ply:IsMuted()) end
							end
						end
						Self:AddItem(PlayerBar)
					end
				end
			end
			self.vgui.Columns[teamid]:Refill()
		end
	end

	self.vgui.Scoreboard:Init()
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