--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--	HOW TO USE
--	- see http://springrts.com/wiki/Lua_SaveLoad
--	- tl;dr:	/save -y <filename> to save to Spring/Saves, remove the -y to not overwrite
--				/savegame to save to Spring/Saves/QuickSave.ssf
--				open an .ssf with spring.exe to load
--				/reloadgame reloads the save you loaded (doesn't remove existing stuff)
--	NOTES
--	- heightmap saving is implemented by engine
--	- gadgets which wish to save/load their data must either submit a table and
--		filename to save (not implemented), or else handle it themselves
--	TODO
--	- handle features
--	- handle rulesparams, fac command queues
--	- handle gadget data (CAI and chicken are particularly important)
--	- handle nonexistent unitDefs
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Save/Load",
    desc      = "General save/load stuff",
    author    = "KingRaptor (L.J. Lim)",
    date      = "25 September 2011",
    license   = "GNU LGPL, v2 or later",
    layer     = -math.huge,	-- we want this to go first
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local unitFile = "units.lua"
local featureFile = "features.lua"

if (gadgetHandler:IsSyncedCode()) then
-----------------------------------------------------------------------------------
--  SYNCED
-----------------------------------------------------------------------------------
-- speedups
local spCreateUnit			= Spring.CreateUnit
local spSetUnitHealth		= Spring.SetUnitHealth
local spSetUnitMaxHealth	= Spring.SetUnitMaxHealth
local spSetUnitVelocity		= Spring.SetUnitVelocity
local spSetUnitRotation		= Spring.SetUnitRotation
local spSetUnitExperience	= Spring.SetUnitExperience
local spSetUnitShieldState	= Spring.SetUnitShieldState
local spSetUnitWeaponState	= Spring.SetUnitWeaponState
local spSetUnitStockpile	= Spring.SetUnitStockpile
local spGiveOrderToUnit		= Spring.GiveOrderToUnit

local cmdTypeIconModeOrNumber = {
	[CMD.AUTOREPAIRLEVEL] = true,
	[CMD.SET_WANTED_MAX_SPEED] = true,
}

-- vars
local unitDataRaw, unitDataFunc
local unitData = {}
local err

local function boolToNum(bool)
	if bool then return 1
	else return 0 end
end

local function GetNewUnitID(oldUnitID)
	return unitData[oldUnitID] and unitData[oldUnitID].newID
end

-- FIXME: autodetection is fairly broken
local function IsCMDTypeIconModeOrNumber(unitID, cmdID)
	if cmdTypeIconModeOrNumber[cmdID] then return true end	-- check cached results first
	local index = Spring.FindUnitCmdDesc(unitID, cmdID)
	local cmdDescs = Spring.GetUnitCmdDescs(unitID, index, index)
	if cmdDescs[1] and (cmdDescs[1].type == CMDTYPE.ICON_MODE or cmdDescs[1].type == CMDTYPE.NUMBER) then
		cmdTypeIconModeOrNumber[cmdID] = true
		return true
	end
	return false
end
-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------
function gadget:Load(zip)
	-- get save data
	zip:open(unitFile)
	unitDataRaw = zip:read("*all")
	if not (unitDataRaw and type(unitDataRaw) == 'string') then
		err = "Unit save data is empty or in invalid format"
		unitData = {}
	else
		--unitDataRaw = string.gsub(commDataRaw, '_', '=')
		--unitDataRaw = Spring.Utilities.Base64Decode(unitDataRaw)
		--Spring.Echo(commDataRaw)
		unitDataFunc, err = loadstring("return "..unitDataRaw)
		if unitDataFunc then
			success, unitData = pcall(unitDataFunc)
			if not success then	-- execute Borat
				err = unitData
				unitData = {}
			end
		end
	end	
	if err then 
		Spring.Echo('Save/Load error: ' .. err)
	end
	
	-- prep units
	for oldID, data in pairs(unitData) do
		local px, py, pz = unpack(data.pos)
		local unitDefID = UnitDefNames[data.unitDefName].id
		if (not UnitDefs[unitDefID].canMove) then
			py = Spring.GetGroundHeight(px, pz)
		end
		local isNanoFrame = data.buildProgress < 1
		local newID = spCreateUnit(data.unitDefName, px, py, pz, 0, data.unitTeam, isNanoFrame)
		data.newID = newID
		-- position and velocity
		spSetUnitVelocity(newID, unpack(data.vel))
		--spSetUnitRotation(newID, unpack(data.dir))	-- FIXME
		spSetUnitMaxHealth(newID, data.maxHealth)
		-- health
		spSetUnitHealth(newID, {health = data.health, capture = data.captureProgress, paralyze = data.paralyzeDamage, build = data.buildProgress})
		-- experience
		spSetUnitExperience(newID, data.experience)
		-- weapons
		for i,v in pairs(data.weapons) do
			if v.reloadState then
				spSetUnitWeaponState(newID, i, "reloadState", v.reloadState)
			end
			if data.shield[i] then
				spSetUnitShieldState(newID, i, data.shield[i].enabled, data.shield[i].power)
			end
		end
		spSetUnitStockpile(newID, data.stockpile.num, data.stockpile.progress)
		
		-- states
		spGiveOrderToUnit(newID, CMD.FIRE_STATE, {data.states.firestate}, {})
		spGiveOrderToUnit(newID, CMD.MOVE_STATE, {data.states.movestate}, {})
		spGiveOrderToUnit(newID, CMD.REPEAT, {boolToNum(data.states["repeat"])}, {})
		spGiveOrderToUnit(newID, CMD.CLOAK, {boolToNum(data.states.cloak)}, {})
		spGiveOrderToUnit(newID, CMD.ONOFF, {boolToNum(data.states.active)}, {})
		spGiveOrderToUnit(newID, CMD.TRAJECTORY, {boolToNum(data.states.trajectory)}, {})
		spGiveOrderToUnit(newID, CMD.AUTOREPAIRLEVEL, {boolToNum(data.states.autorepairlevel)}, {})
		
		--TODO: rulesparams
	end
	
	-- second pass for orders
	-- FIXME: updates unitID params to use new unitID, but does not do the same for featureIDs!
	for oldID, data in pairs(unitData) do
		for i=1,#data.commands do
			local command = data.commands[i]
			if (#command.params == 1 and not(IsCMDTypeIconModeOrNumber(data.newID, command.id) )) then
				Spring.Echo(CMD[command.id], command.params[1], GetNewUnitID(command.params[1]))
				command.params[1] = unitData[command.params[1]].newID
			end
			
			-- workaround for stupid bug where the coordinates are all mixed up
			local params = {}
			for i=1,#command.params do
				params[i] = command.params[i]
			end
			
			local opts = command.options
			local alt, ctrl, shift, right = opts.alt, opts.ctrl, opts.shift, opts.right
			opts = {(alt and "alt"), (shift and "shift"), (ctrl and "ctrl"), (right and "right")} 
			Spring.GiveOrderToUnit(data.newID, command.id, params, opts)
		end
	end	
end


-----------------------------------------------------------------------------------
--  END SYNCED
-----------------------------------------------------------------------------------
else
-----------------------------------------------------------------------------------
--  UNSYNCED
-----------------------------------------------------------------------------------
-- speedups
local spGetUnitDefID		= Spring.GetUnitDefID
local spGetUnitTeam			= Spring.GetUnitTeam
local spGetUnitNeutral		= Spring.GetUnitNeutral
local spGetUnitHealth		= Spring.GetUnitHealth
local spGetUnitCommands		= Spring.GetUnitCommands
local spGetUnitStates		= Spring.GetUnitStates
local spGetUnitStockpile	= Spring.GetUnitStockpile
local spGetUnitDirection	= Spring.GetUnitDirection
local spGetUnitBasePosition	= Spring.GetUnitBasePosition
local spGetUnitVelocity		= Spring.GetUnitVelocity
local spGetUnitExperience	= Spring.GetUnitExperience
local spGetUnitWeaponState	= Spring.GetUnitWeaponState

-- vars
local unitData = {}
local featureData = {}

-- utility functions
local function WriteIndents(num)
	local str = ""
	for i=1, num do
		str = str .. "\t"
	end
	return str
end

local keywords = {
	["repeat"] = true,
}

local function WriteTable(array, numIndents, endOfFile)
	local str = ""	--WriteIndents(numIndents)
	str = str .. "{\n"
	for i,v in pairs(array) do
		str = str .. WriteIndents(numIndents + 1)
		if type(i) == "number" then
			str = str .. "[" .. i .. "] = "
		elseif keywords[i] then
			str = str .. [[["]] .. i .. [["] ]] .. "= "
		else
			str = str .. i .. " = "
		end
		
		if type(v) == "table" then
			str = str .. WriteTable(v, numIndents + 1)
		elseif type(v) == "boolean" then
			str = str .. tostring(v) .. ",\n"
		elseif type(v) == "string" then
			str = str .. [["]] .. v .. [["]] .. ",\n"
		else
			str = str .. v .. ",\n"
		end
	end
	str = str ..WriteIndents(numIndents) .. "}"
	if not endOfFile then
		str = str .. ",\n"
	end
	
	return str
end

local function WriteSaveData(zip, filename, data)
	zip:open(filename)
	zip:write(WriteTable(data, 0, true))
end

-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------

local function SaveUnits()
	local data = {}
	local units = Spring.GetAllUnits()
	for i=1,#units do
		local unitID = units[i]
		data[unitID] = {}
		local unitInfo = data[unitID]
		
		-- basic unit information
		local unitDefID = spGetUnitDefID(unitID)
		unitInfo.unitDefName = UnitDefs[unitDefID].name
		local unitTeam = spGetUnitTeam(unitID)
		unitInfo.unitTeam = unitTeam
		local neutral = spGetUnitNeutral(unitID)
		-- save position/velocity
		unitInfo.pos = {spGetUnitBasePosition(unitID)}
		unitInfo.dir = {spGetUnitDirection(unitID)}
		unitInfo.vel = {spGetUnitVelocity(unitID)}		
		-- save health
		unitInfo.health, unitInfo.maxHealth, unitInfo.paralyzeDamage, unitInfo.captureProgress, unitInfo.buildProgress = spGetUnitHealth(unitID)
		-- save weapons
		local weapons = UnitDefs[unitDefID].weapons
		unitInfo.weapons = {}
		unitInfo.shield = {}
		for i=1,#weapons do
			unitInfo.weapons[i] = {}
			unitInfo.weapons[i].reloadState = spGetUnitWeaponState(unitID, i, reloadState)
			local enabled, power = Spring.GetUnitShieldState(unitID, i)
			if power then
				unitInfo.shield[i] = {enabled = enabled, power = power}
			end
		end
		unitInfo.stockpile = {}
		unitInfo.stockpile.num, _, unitInfo.stockpile.progress = spGetUnitStockpile(unitID)
		
		-- save commands and states
		local commands = spGetUnitCommands(unitID)
		for i,v in pairs(commands) do
			if (type(v) == "table" and v.params) then v.params.n = nil end
		end
		unitInfo.commands = commands
		unitInfo.states = spGetUnitStates(unitID)
		-- save experience
		unitInfo.experience = spGetUnitExperience(unitID)
		-- save rulesparams (TBD)

	end
	unitData = data
end

local function SaveFeatures()
	-- TBD
end


local function ModifyUnitData(unitID)

end

-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------
-- callins
function gadget:Save(zip)
	SaveUnits()
	SaveFeatures()
	--[[
	for i,v in pairs(unitData) do
		Spring.Echo(i, UnitDefs[v.unitDefID].name, v.unitTeam)
	end
	]]--
	WriteSaveData(zip, unitFile, unitData)
end

function gadget:Initialize()
end
-----------------------------------------------------------------------------------
--  END UNSYNCED
-----------------------------------------------------------------------------------
end