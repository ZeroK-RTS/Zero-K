--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Automatically generated local definitions

local spCallCOBScript        = Spring.CallCOBScript
local spGetLocalTeamID       = Spring.GetLocalTeamID
local spGetTeamList          = Spring.GetTeamList
local spGetTeamUnits         = Spring.GetTeamUnits
local spSetUnitCOBValue      = Spring.SetUnitCOBValue
local spGetUnitDefID         = Spring.GetUnitDefID
local spGetUnitTeam		     = Spring.GetUnitTeam
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
		enabled = true,
	}
end

if tobool(Spring.GetModOptions().enableunlocks) == false then
	return
end

if (gadgetHandler:IsSyncedCode()) then

--------------------------------------------------------------------------------
--SYNCED
--------------------------------------------------------------------------------
local perks = {}
local playerIDsByName = {}

local unlocks = {} -- indexed by teamID, value is a table of key unitDefID and value true or nil

local unlockUnits = {
	-- units
	"spherepole",

	"capturecar",
	
	"panther",
	"corgol",
	
	"blackdawn",
	"corcrw",
	
	"armcybr",
	
	"armcarry",
	
	"armbanth",
	"gorg",
	"armorco",
	
	-- defenses and superweapons
    "corgrav",
	"screamer",
	"armanni",
	"cordoom",
	"corbhmth",
	"armbrtha",
	"corsilo",
	"mahlazer",
	"raveparty",

	"cafus",
	
	-- factories
	--"factorycloak",
	"factoryshield",
	"factoryjump",
	"factorytank",
	"factoryplane",
	"armcsa",
}

local unlockUnitsMap = {}
for i=1,#unlockUnits do
	if UnitDefNames[unlockUnits[i]] then unlockUnitsMap[UnitDefNames[unlockUnits[i]].id] = true end
end

local luaTeam = {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function UnlockUnit(unitID, lockDefID, team)
    local cmdDescID = Spring.FindUnitCmdDesc(unitID, -lockDefID)
    if (cmdDescID) then
        local cmdArray = {disabled = false}
        Spring.EditUnitCmdDesc(unitID, cmdDescID, cmdArray)
    end
end

local function LockUnit(unitID, lockDefID, team)
    local cmdDescID = Spring.FindUnitCmdDesc(unitID, -lockDefID)
    if (cmdDescID) then
        local cmdArray = {disabled = true}
        Spring.EditUnitCmdDesc(unitID, cmdDescID, cmdArray)
    end
end

-- right now we don't check if something else disabled/enabled the command before modifying it
-- this isn't a problem right now, but we may want it to be more robust
local function SetBuildOptions(unitID, unitDefID, team)
	local unitDef = UnitDefs[unitDefID]
	if (unitDef.builder) then
		for _, buildoptionID in pairs(unitDef.buildOptions) do
			if unlockUnitsMap[buildoptionID] then
				if not (unlocks[team] and unlocks[team][buildoptionID]) then 
					LockUnit(unitID, buildoptionID, team)
				else
					UnlockUnit(unitID, buildoptionID, team)
				end
			end
		end
	end
end


-- for midgame modification - shouldn't be needed
function EnableUnit(unitDefID, team)
	local units = spGetTeamUnits(team)
	for i=1,#units do
		local udid2 = spGetUnitDefID(units[i])
		if UnitDefs[udid2].builder then UnlockUnit(units[i], unitDefID, team) end
	end
end

function DisableUnit(unitDefID, team)
	local units = spGetTeamUnits(team)
	for i=1,#units do
		local udid2 = spGetUnitDefID(units[i])
		if UnitDefs[udid2].builder then LockUnit(units[i], unitDefID, team) end
	end
end


function gadget:UnitCreated(unitID, unitDefID, team)
	if not luaTeam[team] then SetBuildOptions(unitID, unitDefID, team) end
end

function gadget:AllowUnitTransfer(unitID, unitDefID, oldTeam, newTeam, capture)
	gadget:UnitCreated(unitID, unitDefID, newTeam)
	return true
end

-- blocks command - prevent widget hax
function gadget:AllowCommand(unitID, unitDefID, team, cmdID, cmdParams, cmdOpts)
	if unlockUnitsMap[-cmdID] then
		if not (unlocks[team] and unlocks[team][-cmdID]) and (not cmdOpts.right) then 
			return false
		end
	end
	return true
end

function gadget:AllowUnitCreation(unitDefID, builderID, builderTeam, x, y, z)
	if unlockUnitsMap[unitDefID] then
		if not (unlocks[builderTeam] and unlocks[builderTeam][unitDefID]) then 
			return false
		end
	end
	return true
end

local function InitUnsafe()
	-- for name, id in pairs(playerIDsByName) do
	for index, id in pairs(Spring.GetPlayerList()) do	
		-- copied from PlanetWars
		local unlockData, success
		local customKeys = select(10, Spring.GetPlayerInfo(id))
		local unlocksRaw = customKeys and customKeys.unlocks
		if not (unlocksRaw and type(unlocksRaw) == 'string') then
			err = "Unlock data entry for player "..id.." is empty or in invalid format"
			unlockData = {}
		else
			unlocksRaw = string.gsub(unlocksRaw, '_', '=')
			unlocksRaw = Spring.Utilities.Base64Decode(unlocksRaw)
			local unlockFunc, err = loadstring("return "..unlocksRaw)
			if unlockFunc then 
				success, unlockData = pcall(unlockFunc)
				if not success then
					err = unlockData
					unlockData = {}
				end
			end
		end
		if err then 
			Spring.Echo('Unlock system error: ' .. err)
		end

		for index, name in pairs(unlockData) do
			local team = select(4, Spring.GetPlayerInfo(id))
			local udid = UnitDefNames[name] and UnitDefNames[name].id
			if udid then
				unlocks[team] = unlocks[team] or {}
				unlocks[team][udid] = true
			end
		end
		
		-- /luarules reload compatibility
		local units = Spring.GetAllUnits()
		for i=1,#units do
			local udid = spGetUnitDefID(units[i])
			local teamID = spGetUnitTeam(units[i])
			gadget:UnitCreated(units[i], udid, teamID)
		end
	end
end

function gadget:Initialize()
	local teams = Spring.GetTeamList()
	for _, teamID in ipairs(teams) do
		local teamLuaAI = Spring.GetTeamLuaAI(teamID)
		if (teamLuaAI and teamLuaAI ~= "") then
			luaTeam[teamID] = true
		end
	end
	
	InitUnsafe()
	local allUnits = Spring.GetAllUnits()
	for _, unitID in pairs(allUnits) do
		local udid = Spring.GetUnitDefID(unitID)
		if udid then
			gadget:UnitCreated(unitID, udid, Spring.GetUnitTeam(unitID))
		end
	end
end
--[[
function gadget:RecvLuaMsg(msg, playerID)
	if (msg:find("<perks>playername:",1,true)) then
		local name = msg:gsub('.*:([^=]*)=.*', '%1')
		local id = msg:gsub('.*:.*=(.*)', '%1')
		playerIDsByName[name] = tonumber(id)
	elseif (msg:find("<perks>playernames",1,true)) then
		InitUnsafe()
		local allUnits = Spring.GetAllUnits()
		for _, unitID in pairs(allUnits) do
			local udid = Spring.GetUnitDefID(unitID)
			if udid then
				gadget:UnitCreated(unitID, udid, Spring.GetUnitTeam(unitID))
			end
		end
	end	
end
]]--
else

--UNSYNCED
--[[
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

--[[
function gadget:Initialize()
--  gadgetHandler:AddSyncAction('PWCreate',WrapToLuaUI)
--  gadgetHandler:AddSyncAction("whisper", whisper)
  
	local playerroster = Spring.GetPlayerList()
	local playercount = #playerroster
	for i=1,playercount do
		local name = Spring.GetPlayerInfo(playerroster[i])
		Spring.SendLuaRulesMsg('<perks>playername:'..name..'='..playerroster[i])
	end
	Spring.SendLuaRulesMsg('<perks>playernames')
end
]]--

end
