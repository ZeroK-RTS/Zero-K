--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Automatically generated local definitions

local spCallCOBScript        = Spring.CallCOBScript
local spGetLocalTeamID       = Spring.GetLocalTeamID
local spGetTeamList          = Spring.GetTeamList
local spGetTeamUnits         = Spring.GetTeamUnits
local spSetUnitCOBValue      = Spring.SetUnitCOBValue
local spGetUnitDefID	     = Spring.GetUnitDefID
local spGetTeamUnits		 = Spring.GetTeamUnits
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name = "Perks",
		desc = "don't leave the house without",
		author = "KDR_11k (David Becker)",
		date = "2008-03-04",
		license = "Public Domain",
		layer = 1,
		enabled = true
	}
end

local perkCount =  tonumber(Spring.GetModOptions().perkcount) or 3
local CMD_PICK = 32343

local perkList = include("LuaUI/Configs/perks.lua")

if perkCount == -1 then return end

if (gadgetHandler:IsSyncedCode()) then

--SYNCED

local function EnableUnit(unit, team)
	GG.EnableUnit(unit, team)
end

local perks={}
local perkFunc={}

local perkUnits = {
	[1] = "spherepole",
	[2] = "punisher",
	[3] = "armmerl",	
	[4] = "trem",
	[5] = "armbrawl",
	[6] = "corgrav",
	[7] = "armpb",
	[8] = "armcir",
}
GG.perkUnits = perkUnits

local luaTeamID = {}

local function UnlockUnit(unitID, unitDefID, team)
	local cmdDescID = Spring.FindUnitCmdDesc(unitID, -unitDefID)
	if (cmdDescID) then
		local cmdArray = {disabled = false}
		Spring.EditUnitCmdDesc(unitID, cmdDescID, cmdArray)
	end
end

local function LockUnit(unitID, unitDefID, team)
	local cmdDescID = Spring.FindUnitCmdDesc(unitID, -unitDefID)
	if (cmdDescID) then
		local cmdArray = {disabled = true}
		Spring.EditUnitCmdDesc(unitID, cmdDescID, cmdArray)
	end
end

function EnableUnit(unitDefName, team)
	local udid = UnitDefNames[unitDefName].id
	local units = spGetTeamUnits(team)
	for i=1,#units do
		local udid2 = spGetUnitDefID(units[i])
		if UnitDefs[udid2].builder then UnlockUnit(units[i], udid, team) end
	end
end

local function PerkPicked(team, perk)
	local units= spGetTeamUnits(team)
	perks[team].left = perks[team].left - 1
	perks[team].have[perk] = true
	--[[
	for _,u in ipairs(units) do
		uid = spGetUnitDefID(u)
		if not UnitDefs[uid].customParams.luascript then
			spSetUnitCOBValue(u,2048+perk,1)
			break
		end
	end
	for _,u in ipairs(units) do
		--Spring.Echo(UnitDefs[uid].customParams.luascript)
		uid = spGetUnitDefID(u)
		if not UnitDefs[uid].customParams.luascript then
			spCallCOBScript(u, "NewPerk", 0, 2048+perk)
		else
			local env = Spring.UnitScript.GetScriptEnv(u)
			Spring.UnitScript.CallAsUnit(u, env.NewPerk, perk)
		end
	end
	]]--
	if perkFunc[perk] then
		perkFunc[perk](team)
	end
	if perkUnits[perk] then
		EnableUnit(perkUnits[perk], team)
	end
end

function gadget:AllowCommand(u, ud, team, cmd, param, opt)
	if cmd == CMD_PICK then
		if perks[team].left > 0 and not perks[team].have[param[1]] and perkList[param[1]] then
			PerkPicked(team, param[1])
		end
		return false
	end
	return true
end

local function SetBuildOptions(unitID, unitDefID, team)
	local unitDef = UnitDefs[unitDefID]
	if (unitDef.builder) then
		for _, buildoptionID in pairs(unitDef.buildOptions) do
			--Spring.Echo("Comparing "..UnitDefs[buildoptionID].name)
			for perk, unit in pairs(perkUnits) do
				--Spring.Echo("...to "..unit)
				if buildoptionID == (UnitDefNames[unit].id) then
					if not perks[team].have[perk] then LockUnit(unitID, UnitDefNames[unit].id, team)
					else UnlockUnit(unitID, UnitDefNames[unit].id, team) end
				end
			end
		end
	end
end

function gadget:UnitCreated(unitID, unitDefID, team)
	SetBuildOptions(unitID, unitDefID, team)
end

function gadget:AllowUnitCreation(unitDefID, builderID, builderTeam, x, y, z)
	for perk, unit in pairs(perkUnits) do
		if unitDefID == (UnitDefNames[unit].id) and (not perks[builderTeam].have[perk]) then return false end
	end
	return true
end

function gadget:AllowUnitTransfer(unitID, unitDefID, oldTeam, newTeam)
	SetBuildOptions(unitID, unitDefID, newTeam)
	return true
end

function gadget:Initialize()
	local teams = Spring.GetTeamList()
	for _, teamID in ipairs(teams) do
		local teamLuaAI = Spring.GetTeamLuaAI(teamID)
		if (teamLuaAI and teamLuaAI ~= "") then
			luaTeamID[teamID] = true
		end
	end
	for _,t in ipairs(spGetTeamList()) do
		perks[t]={
			left = perkCount,
			have = {},
		}
	end
	--give LuaAI teams all the perks (saves us the trouble of making the AI know not to build stuff it doesn't have the perk for)
	if (luaTeamID[teamID]) then
		perks[teamID].left = 20
		for perkID,_ in pairs(perkList) do
			PerkPicked(luaTeamID, perkID)
		end
	end
	GG.perks = perks
	_G.perks = perks
	--[[
	if perkCount == -1 then
		for _,team in ipairs(spGetTeamList()) do
			for perkID,_ in pairs(perkList) do
				PerkPicked(team, perkID)
			end
		end
	end]]--
end

else

--UNSYNCED

local GL_ONE                 = GL.ONE
local GL_ONE_MINUS_SRC_ALPHA = GL.ONE_MINUS_SRC_ALPHA
local glBlending             = gl.Blending
local glTexRect              = gl.TexRect
local glTexture              = gl.Texture

function gadget:Update()
	if Script.LuaUI("PerkState") then
		Script.LuaUI.PerkState(SYNCED.perks[spGetLocalTeamID()].left)
	end
end

--[[
local panelTop=60
local panelRight=0
local panelWidth=128
local panelHeight=128

local top = panelTop + 64
local right = panelRight + 16
local height = 32
local width = 32

function gadget:DrawScreen(vsx, vsy)
	--glBlending(GL_ONE, GL_ONE_MINUS_SRC_ALPHA)
	glTexture("bitmaps/ui/money_perks.png")
	glTexRect(vsx - panelRight - panelWidth, vsy - panelTop - panelHeight, vsx - panelRight, vsy - panelTop, false, false)
	local n = 0
	for p,_ in spairs(SYNCED.perks[spGetLocalTeamID()].have) do
		glTexture(perkList[p][3])
		glTexRect(vsx - right - n*width - width, vsy - top, vsx - right - n*width, vsy - top - height, false, true)
		n=n+1
	end
	glTexture(false)
end
]]--

end
