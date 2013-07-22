if SERVER then
	AddCSLuaFile('cl_scoreboard.lua')
else
	include('cl_scoreboard.lua')
end