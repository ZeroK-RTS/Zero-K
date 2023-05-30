function gadget:GetInfo()
	return {
		name    = "Awards",
		desc    = "v1.002 Awards players at end of battle with shiny trophies.",
		author  = "CarRepairer",
		date    = "2008-10-15", --2013-09-05
		license = "GNU GPL, v2 or later",
		layer   = 1000000, -- Must be after all other build steps and before unit_spawner.lua for queen kill award.
		enabled = true,
	}
end

include("LuaRules/Configs/constants.lua")

local spGetTeamInfo     = Spring.GetTeamInfo
local gaiaTeamID        = Spring.GetGaiaTeamID()

local echo = Spring.Echo

local totalTeamList = {}

local awardDescs = VFS.Include("LuaRules/Configs/award_names.lua")

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
if (gadgetHandler:IsSyncedCode()) then
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
local spAreTeamsAllied      = Spring.AreTeamsAllied
local spGetUnitHealth       = Spring.GetUnitHealth
local spGetAllUnits         = Spring.GetAllUnits
local spGetUnitTeam         = Spring.GetUnitTeam
local spGetUnitDefID        = Spring.GetUnitDefID
local spGetUnitExperience   = Spring.GetUnitExperience
local spGetTeamResources    = Spring.GetTeamResources
local GetUnitCost           = Spring.Utilities.GetUnitCost

local floor = math.floor

local terraunitDefID = UnitDefNames["terraunit"].id
local terraformCost  = UnitDefNames["terraunit"].metalCost

local mexDefID = UnitDefNames["staticmex"].id
local mexCost  = UnitDefNames["staticmex"].metalCost

local gameOver = false

local cappedComs = {}

local awardData = {}

local basicEasyFactor = 0.5
local veryEasyFactor = 0.3

local empFactor     = veryEasyFactor*4
local reclaimFactor = veryEasyFactor*0.2 -- wrecks aren't guaranteed to leave more than 0.2 of value

local minReclaimRatio = 0.15

local awardAbsolutes = {
	cap         = 1000,
	share       = 5000,
	terra       = 1000,
	rezz        = 3000,
	mex         = 15,
	mexkill     = 15,
	head        = 3,
	dragon      = 3,
	sweeper     = 20,
	heart       = 1*10^9, -- avoid higher values, math.floor starts returning INT_MIN at some point
	vet         = 3,
}

local awardEasyFactors = {
	shell     = basicEasyFactor,
	fire      = basicEasyFactor,

	nux       = veryEasyFactor,
	kam       = veryEasyFactor,
	comm      = veryEasyFactor,

	reclaim   = reclaimFactor,
	emp       = empFactor,
}

local expUnitTeam, expUnitDefID, expUnitExp = 0,0,0

local awardList = {}

local boats, comms = {}, {}

local staticO_small = {
	staticheavyarty = 1,
	seismic = 1,
	tacnuke = 1,
	empmissile = 1,
	napalmmissile = 1,
	wolverine_mine = 1,
}

local staticO_big = {
	staticnuke = 1,
	mahlazer = 1,
	starlight_satellite=1,
	zenith = 1,
	raveparty = 1,
}

--[[ Note that units need to still be alive by the time
     damage is dealt. This means that the death explosion
     has to have an instant shockwave or the unit has to
     be hidden (as happens with Limpet and Puppy). ]]
local kamikaze = {
	shieldbomb=1,
	jumpbomb=1,
	gunshipbomb=1,
	jumpscout=1,
	amphbomb=1,
	subscout=1,
	chicken_dodo=1,
}

local flamerWeaponDefs = {}

------------------------------------------------
-- functions

local function comma_value(amount)
	local formatted = amount .. ''
	local k
	while true do
		formatted, k = formatted:gsub("^(-?%d+)(%d%d%d)", '%1,%2')
		if (k==0) then
			break
		end
	end
	return formatted
end

local function getMeanDamageExcept(excludeTeam)
	local mean = 0
	local count = 0
	--for team,dmg in pairs(damageList) do
	for team,dmg in pairs(awardData.pwn) do
		if team ~= excludeTeam
			and dmg > 100
		then
			mean = mean + dmg
			count = count + 1
		end
	end
	return (count>0) and (mean/count) or 0
end

local function getMaxVal(valList)
	local winTeam, maxVal = false,0
	for team,val in pairs(valList) do
		if val and val > maxVal then
			winTeam = team
			maxVal = val
			--Spring.Echo(" Team ".. winTeam .." maxVal ".. maxVal) --debug
		end
	end

	return winTeam, maxVal
end

local function getMeanMetalIncome()
	local num, sum = 0, 0
	for _,team in pairs(totalTeamList) do
		sum = sum + select(2, Spring.GetTeamResourceStats(team, "metal"))
		num = num + 1
	end
	return (sum/num)
end

local function awardAward(team, awardType, record)
	if not awardList[team] then --random check for devving.
		echo('<Award Error> Missing award list for team ' .. team)
		return
	end
	awardList[team][awardType] = record
end

local function CopyTable(original) -- Warning: circular table references lead to
	local copy = {}                -- an infinite loop.
	for k, v in pairs(original) do
		if (type(v) == "table") then
			copy[k] = CopyTable(v)
		else
			copy[k] = v
		end
	end
	return copy
end

local function AddAwardPoints( awardType, teamID, amount )
	if (teamID and (teamID ~= gaiaTeamID)) then
		awardData[awardType][teamID] = awardData[awardType][teamID] + (amount or 0)
	end
end

local function ProcessAwardData()

	for awardType, data in pairs(awardData) do
		local winningTeam
		local maxVal
		local easyFactor = awardEasyFactors[awardType] or 1
		local absolute = awardAbsolutes[awardType]
		local message

		if awardType == 'vet' then
			maxVal = expUnitExp
			winningTeam = expUnitTeam
		else
			winningTeam, maxVal = getMaxVal(data)

		end

		if winningTeam then

			local compare
			if absolute then
				compare = absolute

			else
				compare = getMeanDamageExcept(winningTeam) * easyFactor
			end

			--if reclaimTeam and maxReclaim > getMeanMetalIncome() * minReclaimRatio then
			if maxVal > compare then
				maxVal = floor(maxVal)
				local maxValWrite = comma_value(maxVal)

				if awardType == 'cap' then
					message = 'Captured value: ' .. maxValWrite
				elseif awardType == 'share' then
					message = 'Shared value: ' .. maxValWrite
				elseif awardType == 'terra' then
					message = 'Terraform: ' .. maxValWrite
				elseif awardType == 'rezz' then
					message = 'Resurrected value: ' .. maxValWrite
				elseif awardType == 'fire' then
					message = 'Burnt value: ' .. maxValWrite
				elseif awardType == 'emp' then
					message = 'Stunned value: ' .. maxValWrite
				elseif awardType == 'slow' then
					message = 'Slowed value: ' .. maxValWrite
				elseif awardType == 'disarm' then
					message = 'Disarmed value: ' .. maxValWrite
				elseif awardType == 'ouch' then
					message = 'Damage received: ' .. maxValWrite
				elseif awardType == 'reclaim' then
					message = 'Reclaimed value: ' .. maxValWrite
				elseif awardType == 'mex' then
					message = 'Mexes built: '.. maxVal
				elseif awardType == 'mexkill' then
					message = 'Mexes destroyed: '.. maxVal
				elseif awardType == 'head' then
					message = maxVal .. ' Commanders eliminated'
				elseif awardType == 'dragon' then
					message = maxVal .. ' White Dragons annihilated'
				elseif awardType == 'heart' then
					local maxQueenKillDamage = maxVal - absolute --remove the queen kill signature: +1000000000 from the total damage
					message = 'Damage: '.. comma_value(maxQueenKillDamage)
				elseif awardType == 'sweeper' then
					message = maxVal .. ' Nests wiped out'

				elseif awardType == 'vet' then
					local vetName = UnitDefs[expUnitDefID] and UnitDefs[expUnitDefID].humanName
					local expUnitExpRounded = floor(expUnitExp * 100)
					message = vetName ..', '.. expUnitExpRounded .. "% cost made"
				else
					message = 'Damaged value: '.. maxValWrite
				end
			end
		end --if winningTeam
		if message then
			awardAward(winningTeam, awardType, message)
		end

	end
end

-------------------
-- Callins

function gadget:Initialize()

	GG.Awards = GG.Awards or {}
	GG.Awards.AddAwardPoints = AddAwardPoints
	
	local tempTeamList = Spring.GetTeamList()
	for i=1, #tempTeamList do
		local team = tempTeamList[i]
		--Spring.Echo('team', team)
		if team ~= gaiaTeamID then
			totalTeamList[team] = team
		end
	end

	--new
	for awardType, _ in pairs(awardDescs) do
		awardData[awardType] = {}
	end
	for _,team in pairs(totalTeamList) do
		awardList[team] = {}

		for awardType, _ in pairs(awardDescs) do
			awardData[awardType][team] = 0
		end
	end

	local shipSMClass = Game.speedModClasses.Ship
	for i = 1, #UnitDefs do
		local ud = UnitDefs[i]

		--[[ NB: ships that extend legs and walk onto land, like
		     the SupCom Cybran Siren or RA3 Soviet Stingray, are
		     technically hovercraft in Spring so would need some
		     extra handling AFAIK. No such ship in vanilla ZK. ]]
		if (ud.moveDef.smClass == shipSMClass) then
			boats[i] = true
		end

		if ud.customParams.dynamic_comm then
			comms[i] = true
		end
	end

	for i=1,#WeaponDefs do
		local wcp = WeaponDefs[i].customParams or {}
		if (wcp.setunitsonfire) then
			flamerWeaponDefs[i] = true
		end
	end
end --Initialize

function gadget:UnitTaken(unitID, unitDefID, oldTeam, newTeam)
	-- Units given to neutral?
	if oldTeam == gaiaTeamID or newTeam == gaiaTeamID then
		return
	end
	if not spAreTeamsAllied(oldTeam,newTeam) then
		if awardData['cap'][newTeam] then --if team exist, then:
			local ud = UnitDefs[unitDefID]
			local mCost = GetUnitCost(unitID, unitDefID)
			AddAwardPoints( 'cap', newTeam, mCost )
			if (ud.customParams.dynamic_comm) then
				if (not cappedComs[unitID]) then
					cappedComs[unitID] = select(6, spGetTeamInfo(oldTeam, false))
				elseif (cappedComs[unitID] == select(6, spGetTeamInfo(newTeam, false))) then
					cappedComs[unitID] = nil
				end
			end
		end
	else -- teams are allied
		if (unitDefID ~= terraunitDefID) then
			local mCost = GetUnitCost(unitID, unitDefID)
			AddAwardPoints('share', oldTeam,  mCost)
			AddAwardPoints('share', newTeam, -mCost)
		end
	end
end

-- wtf, why does each shitty chicken get to have its own award?
local    chicken_dragonDefID = UnitDefNames.chicken_dragon   .id
local chickenflyerqueenDefID = UnitDefNames.chickenflyerqueen.id
local  chickenlandqueenDefID = UnitDefNames.chickenlandqueen .id
local             roostDefID = UnitDefNames.roost            .id

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam, _, _, killerTeam)
	local experience = spGetUnitExperience(unitID)
	if experience > expUnitExp and (experience*UnitDefs[unitDefID].metalCost > 1000) then
		expUnitExp = experience
		expUnitTeam = unitTeam
		expUnitDefID = unitDefID
	end

	if (cappedComs[unitID]) then
		cappedComs[unitID] = nil
		if (unitTeam ~= gaiaTeamID) then
			AddAwardPoints( 'head', unitTeam, 1 )
		end
		return
	end

	if (killerTeam == unitTeam) or (killerTeam == gaiaTeamID) or (unitTeam == gaiaTeamID) or (killerTeam == nil) then
		return
	elseif (unitDefID == mexDefID) then
		if ((not gameOver) and (select(5, spGetUnitHealth(unitID)) > 0.9) and (not spAreTeamsAllied(killerTeam, unitTeam))) then
			AddAwardPoints( 'mexkill', killerTeam, 1 )
		end
	else
		if (comms[unitDefID] and (not spAreTeamsAllied(killerTeam, unitTeam))) then
			AddAwardPoints( 'head', killerTeam, 1 )
		elseif unitDefID == chicken_dragonDefID then
			AddAwardPoints( 'dragon', killerTeam, 1 )
		elseif unitDefID == chickenflyerqueenDefID or unitDefID == chickenlandqueenDefID then
			for killerFrienz, _ in pairs(awardData['heart']) do --give +1000000000 points for all frienz that kill queen and won
				AddAwardPoints( 'heart', killerFrienz, awardAbsolutes['heart']) --the extra points is for id purpose. Will deduct later
			end
		elseif unitDefID == roostDefID then
			AddAwardPoints( 'sweeper', killerTeam, 1 )
		end
	end
end

function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponID,
		attackerID, attackerDefID, attackerTeam)
	if (unitTeam == gaiaTeamID) then return end
	local hp, maxHP = spGetUnitHealth(unitID)
	if (hp < 0) then
		damage = damage + hp
	end
	if damage < 0 then
		-- can happen with the EMP component of mixed weapons, when last-hitting
		return
	end
	AddAwardPoints( 'ouch', unitTeam, damage )

	if (not attackerTeam)
		or (attackerTeam == unitTeam)
		or (attackerTeam == gaiaTeamID)
		then return end

	local costdamage = (damage / maxHP) * GetUnitCost(unitID, unitDefID)

	if not spAreTeamsAllied(attackerTeam, unitTeam) then
		if paralyzer then
			AddAwardPoints( 'emp', attackerTeam, costdamage )
		else
			if unitDefID == chickenflyerqueenDefID or unitDefID == chickenlandqueenDefID then
				AddAwardPoints( 'heart', attackerTeam, damage )
			end
			local ad = UnitDefs[attackerDefID]

			if (flamerWeaponDefs[weaponID]) then
				AddAwardPoints( 'fire', attackerTeam, costdamage )
			end

			-- Static Weapons
			if (not ad.canMove) then

				-- bignukes, zenith, starlight
				if staticO_big[ad.name] then
					AddAwardPoints( 'nux', attackerTeam, costdamage )

				-- not lrpc, tacnuke, emp missile
				elseif not staticO_small[ad.name] then
					AddAwardPoints( 'shell', attackerTeam, costdamage )
				end

			elseif kamikaze[ad.name] then
				AddAwardPoints( 'kam', attackerTeam, costdamage )

			elseif ad.canFly and not (ad.customParams.dontcount or ad.customParams.is_drone) then
				AddAwardPoints( 'air', attackerTeam, costdamage )

			elseif boats[attackerDefID] then
				AddAwardPoints( 'navy', attackerTeam, costdamage )

			elseif comms[attackerDefID] then
				AddAwardPoints( 'comm', attackerTeam, costdamage )

			end
		end
	end
end

function gadget:UnitFinished(unitID, unitDefID, teamID)
	if unitDefID == mexDefID then
		AddAwardPoints( 'mex', teamID, 1 )
	end
end

function gadget:GameOver()
	gameOver = true

	local units = spGetAllUnits()
	for i=1,#units do
		local unitID = units[i]
		local teamID = spGetUnitTeam(unitID)
		local unitDefID = spGetUnitDefID(unitID)
		gadget:UnitDestroyed(unitID, unitDefID, teamID)
	end

	-- read externally tracked values
	local teams = Spring.GetTeamList()
	for i = 1, #teams do
		local team = teams[i]
		if team ~= gaiaTeamID then
			AddAwardPoints('reclaim', team, Spring.GetTeamRulesParam(team, "stats_history_metal_reclaim_current") or 0)
			AddAwardPoints('pwn', team, Spring.Utilities.GetHiddenTeamRulesParam(team, "stats_history_damage_dealt_current") or 0)
		end
	end

	ProcessAwardData()

	_G.awardList = awardList
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
else -- UNSYNCED
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local teamNames     = {}
local awardList

function gadget:Initialize()
	local tempTeamList = Spring.GetTeamList()
	for i=1, #tempTeamList do
		local team = tempTeamList[i]
		--Spring.Echo('team', team)
		if team ~= gaiaTeamID then
			totalTeamList[team] = team
		end
	end

	for _,team in pairs(totalTeamList) do
		local _, leaderPlayerID, _, isAI = spGetTeamInfo(team, false)
		local name
		if isAI then
			local _, aiName, _, shortName = Spring.GetAIInfo(team)
			name = aiName ..' ('.. shortName .. ')'
		else
			name = Spring.GetPlayerInfo(leaderPlayerID, false)
		end
		teamNames[team] = name
	end
end

-- function to convert SYNCED table to regular table. assumes no self referential loops
local function ConvertToRegularTable(stable)
	local ret = {}
	local stableLocal = stable
	for k,v in pairs(stableLocal) do
		if type(v) == 'table' then
			v = ConvertToRegularTable(v)
		end
		ret[k] = v
	end
	return ret
end

function gadget:GameOver()
	awardList = ConvertToRegularTable( SYNCED.awardList )
	Script.LuaUI.SetAwardList( awardList )

	for team,awards in pairs(awardList) do
		for awardType, record in pairs(awards) do
			local planetWarsData = (teamNames[team] or "no_name") ..' '.. awardType ..' '.. awardDescs[awardType] ..', '.. record
			Spring.SendCommands("wbynum 255 SPRINGIE:award,".. planetWarsData)
			--Spring.Echo(planetWarsData)
		end
	end
end

--unsynced
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
end
