-- $Id: unit_noselfpwn.lua 3171 2008-11-06 09:06:29Z det $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Mod statistics",
    desc      = "Gathers mod statistics",
    author    = "Licho",
    date      = "29.3.2009",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

if VFS.FileExists("mission.lua") then
  -- stats are meaningless in missions
  return
end


if (not gadgetHandler:IsSyncedCode()) then
  return false  --  silent removal
end

local damages = {}     -- damages[attacker][victim] = { damage, emp}
local unitCounts = {}  -- unitCounts[defID] = { created, destroyed}
local lastPara = {}

local plops = {}

local Echo = Spring.Echo
local spGetUnitHealth = Spring.GetUnitHealth
local spAreTeamsAllied = Spring.AreTeamsAllied

local gaiaTeamID = Spring.GetGaiaTeamID()
  
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- drones are counted as parent for damage done, ignored for damage received
-- key = drone, value = true
local drones = {
	dronecarry = true,
	wolverine_mine = true,
}

-- remembers parent unitDefID while parent unit is alive, because minelayer unit can get destroyed before mines do
local unitIDToParentDefID = {}

local checkParentList = {}
local checkParentCount = 0

-- fallback for when attacker is already dead at damage event - attackerDefID == nil
local weaponIDToUnitDefID = {}
-- temporary variable used to exclude weapons used by multiple unit types
local weaponIDFirstUnitDefID = {}

local function addWeaponIDToUnitMapping(weaponDefID, unitDefID)
	if (not weaponIDFirstUnitDefID[weaponDefID]) then
		weaponIDFirstUnitDefID[weaponDefID] = unitDefID
		weaponIDToUnitDefID[weaponDefID] = unitDefID
	elseif (unitDefID ~= weaponIDFirstUnitDefID[weaponDefID]) then -- ignores multiple instances of same weapon on single unit
		weaponIDToUnitDefID[weaponDefID] = nil -- remove weapons used by multiple unit types
	end
end

local function addWeaponNameToUnitMapping(weaponName, unitDefID)
	local wd = WeaponDefNames[weaponName]
	if wd then
		local weaponDefID = wd.id
		addWeaponIDToUnitMapping(weaponDefID, unitDefID)
	end
end

for unitDefID = 1, #UnitDefs do
	local ud = UnitDefs[unitDefID]

	local unitDefStatsID = unitDefID
	local unitDefAlias = ud.customParams.statsname
	if unitDefAlias and UnitDefNames[unitDefAlias] then
		unitDefStatsID = UnitDefNames[unitDefAlias].id
	end

	local weapons = ud.weapons
	if (weapons) then
        for i = 1, #weapons do
			local weaponDefID = weapons[i].weaponDef
			addWeaponIDToUnitMapping(weaponDefID, unitDefStatsID)
        end
    end

	addWeaponNameToUnitMapping(ud.deathExplosion, unitDefStatsID)
	addWeaponNameToUnitMapping(ud.selfDExplosion, unitDefStatsID)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Factory Plop

local function AddFactoryPlop(teamID, plopUnitDefID)
	plops[#plops + 1] = {
		teamID = teamID,
		plopUnitDefID = plopUnitDefID,
	}
end
GG.mod_stats_AddFactoryPlop = AddFactoryPlop
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer,
                            weaponID, attackerID, attackerDefID, attackerTeam)

	if unitTeam == gaiaTeamID then
		return
	end
	
	if weaponID and (not attackerDefID) then
		attackerDefID = weaponIDToUnitDefID[weaponID]
		--Spring.Echo(UnitDefs[attackerDefID].humanName)
	end
	if (attackerDefID == nil or  unitDefID == nil or damage == nil) or (not attackerTeam) or (attackerTeam == unitTeam) or (damage < 0)  or spAreTeamsAllied(attackerTeam, unitTeam) then
		if (paralyzer) then
			local hp, maxHp, paraDam = spGetUnitHealth(unitID)
			local paraHp = maxHp - paraDam
			if paraHp < 0 then paraHp = 0 end
			lastPara[unitID] = paraHp
		end
		return
	end
	
	
	-- treat as different unit as needed
	if drones[UnitDefs[unitDefID].name] then
		return
	end
	if drones[UnitDefs[attackerDefID].name] then
		local parentUnitDefID = attackerID and unitIDToParentDefID[attackerID]
		attackerDefID = parentUnitDefID or attackerDefID
	end
	local attackerAlias = UnitDefs[attackerDefID].customParams.statsname
	if attackerAlias and UnitDefNames[attackerAlias] then
		attackerDefID = UnitDefNames[attackerAlias].id
	end
	local defenderAlias = UnitDefs[unitDefID].customParams.statsname
	if defenderAlias and UnitDefNames[defenderAlias] then
		unitDefID = UnitDefNames[defenderAlias].id
	end
	
	
	local hp, maxHp, paraDam, capture, build = spGetUnitHealth(unitID)
	
	if build >= 1 then

		local tab = damages[attackerDefID]
		if (tab == nil) then
			tab = {}
			damages[attackerDefID] = tab
		end
		local dam = tab[unitDefID]
		if (dam == nil) then
			dam = {0,0}
			tab[unitDefID] = dam
		end

		local h
		if (paralyzer)  then h = lastPara[unitID] or maxHp
		else h = hp + damage end
	
		if h < 0 then h = 0 end
		if h > maxHp then h = maxHp end
		if (damage > h) then damage = h end

		if (paralyzer) then
			dam[2] = dam[2] + damage
		else
			dam[1] = dam[1] + damage
		end
	end

	local paraHp = maxHp - paraDam
	if paraHp < 0 then paraHp = 0 end
	lastPara[unitID] = paraHp
end


function gadget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
	lastPara[unitID] = nil
	unitIDToParentDefID[unitID] = nil

	if (drones[UnitDefs[unitDefID].name]) then
		checkParentCount = checkParentCount + 1
		checkParentList[checkParentCount] = unitID
	end

	local unitAlias = UnitDefs[unitDefID].customParams.statsname
	if unitAlias and UnitDefNames[unitAlias] then
		unitDefID = UnitDefNames[unitAlias].id
	end
	
	if (builderID == nil) then
		local tab = unitCounts[unitDefID]
		if (tab == nil) then
			tab = {0,0}
			unitCounts[unitDefID] = tab
		end
		tab[1] = tab[1] + 1
	end
end


function gadget:UnitFinished(unitID, unitDefID, unitTeam)
	lastPara[unitID] = nil

	local unitAlias = UnitDefs[unitDefID].customParams.statsname
	if unitAlias and UnitDefNames[unitAlias] then
		unitDefID = UnitDefNames[unitAlias].id
	end
	
	local tab = unitCounts[unitDefID]
	if (tab == nil) then
		tab = {0,0}
		unitCounts[unitDefID] = tab
	end
	tab[1] = tab[1] + 1
end


function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
	lastPara[unitID] = nil
	-- Not clearing unitIDToParentDefID here, because fired projectiles may still exist

	local unitAlias = UnitDefs[unitDefID].customParams.statsname
	if unitAlias and UnitDefNames[unitAlias] then
		unitDefID = UnitDefNames[unitAlias].id
	end
	
	local tab = unitCounts[unitDefID]
	if (tab == nil) then
		tab = {0,0}
		unitCounts[unitDefID] = tab
	end
	tab[2] = tab[2] + 1
end

function gadget:GameFrame(frame)
	if checkParentCount > 0 then
		for i = 1, checkParentCount do
			local unitID = checkParentList[i]
			local parentUnitID = Spring.GetUnitRulesParam(unitID, "parent_unit_id")
			if (parentUnitID) then -- can be null if minelayer unit dies before mine even spawns
				local parentUnitDefID = Spring.GetUnitDefID(parentUnitID)
				if (parentUnitDefID) then
					unitIDToParentDefID[unitID] = parentUnitDefID -- remember parent unitDefID, because parent unit may die later
				end
			end
		end

		checkParentCount = 0
	end
end

function SendData(statsData)
	Spring.SendCommands("wbynum 255 SPRINGIE:stats,".. statsData)
end

function gadget:GameOver()
	if GG.Chicken then
		Spring.Log(gadget:GetInfo().name, LOG.INFO, "Chicken game; unit stats disabled")
		return -- don't report stats in chicken
	end
	Spring.Echo("Submitting stats")
	for atk, victims in pairs(damages) do
		for victim, dam in pairs(victims) do
			SendData("dmg,"..UnitDefs[atk].name .. ",".. UnitDefs[victim].name .. "," .. dam[1] .. "," .. dam[2])
		end
	end

	for unit, counts in pairs(unitCounts) do
		SendData("unit,"..UnitDefs[unit].name .. ",".. UnitDefs[unit].metalCost ..",".. counts[1] .. "," .. counts[2] .. "," .. UnitDefs[unit].health)
	end
	
	for _, data in ipairs(plops) do
		-- Send Data here
	end

	local teams = Spring.GetTeamList()
	local humanAlly = {}
	local players = 0
	gaiaTeam = Spring.GetGaiaTeamID()
	for _, teamID in ipairs(teams) do

		local teamLuaAI = Spring.GetTeamLuaAI(teamID)
		if ((teamLuaAI == nil or teamLuaAI == "") and teamID ~= gaiaTeam) then
			local _,_,_,ai,side,ally = Spring.GetTeamInfo(teamID, false)
			if (not ai) then
				humanAlly[ally] = 1
				players = players + 1
			end
		end
	end
	local allycount = 0
	for _,_ in pairs(humanAlly) do allycount = allycount + 1 end

	SendData("teams,"..players .. ",".. allycount)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
