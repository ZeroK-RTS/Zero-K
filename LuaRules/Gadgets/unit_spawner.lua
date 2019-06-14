--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name     = "Chicken Spawner",
		desc     = "Spawns burrows and chickens",
		author   = "quantum, improved by KingRaptor",
		date     = "April 29, 2008", --last update: Mei 7, 2014
		license  = "GNU GPL, v2 or later",
		layer    = 1000001,	-- must do the GameOver() thing only after gadget:awards.lua has finishes detect queen destroyed else queenKill award won't appear.
		enabled  = true --	loaded by default?
	}
end

include("LuaRules/Configs/customcmds.h.lua")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local SAVE_FILE = "Gadgets/unit_spawner.lua"
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if (gadgetHandler:IsSyncedCode()) then
-- BEGIN SYNCED

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- Speed-ups and upvalues
--

local Spring		= Spring
local math			= math
local Game			= Game
local table			= table
local ipairs		= ipairs
local pairs			= pairs

local random				= math.random

local CMD_FIGHT				= CMD.FIGHT
local CMD_ATTACK			= CMD.ATTACK
local CMD_STOP				= CMD.STOP
local spGiveOrderToUnit		= Spring.GiveOrderToUnit
local spGetTeamUnits		= Spring.GetTeamUnits
local spGetUnitTeam			= Spring.GetUnitTeam
local spGetCommandQueue		= Spring.GetCommandQueue
local spGetGameSeconds		= Spring.GetGameSeconds
local spGetGroundBlocked	= Spring.GetGroundBlocked
local spCreateUnit			= Spring.CreateUnit
local spGetUnitPosition		= Spring.GetUnitPosition
local spGetUnitDefID		= Spring.GetUnitDefID
local spGetUnitSeparation	= Spring.GetUnitSeparation
local spGetGameFrame		= Spring.GetGameFrame
local spSetUnitHealth		= Spring.SetUnitHealth
local spGetUnitsInCylinder	= Spring.GetUnitsInCylinder
local spValidUnitID			= Spring.ValidUnitID

local echo = Spring.Echo

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local emptyTable	= {}
local roamParam		= {2}
local maxTries		= 500
local maxTriesSmall	= 100
local lava = (Game.waterDamage > 0)
local eggs = tobool(Spring.GetModOptions().eggs)
local pvp = false
local respawnBurrows = false	--the always respawn, not % respawn chance

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local luaAI
local chickenTeamID
local computerTeams	= {}
local humanTeams	= {}
local gameFrameOffset = 0

-- anything that needs saving goes in here
local data = {
	queenID = nil,
	miniQueenNum = 1,
	targetCache = nil,
	burrows	= {},
	chickenBirths = {},
	timeOfLastSpawn	= 0,	-- when the last burrow was spawned
	waveSchedule = math.huge,	-- wave spawns when this gameframe is reached
	waveNumber	= 0,
	
	eggDecay = {},	-- indexed by featureID, value = game second
	targets = {},	--indexed by unitID, value = teamID
	
	totalTechAccel = 0,
	defensePool = 0,
	defenseQuota = 0,
	
	humanAggro = 0,		-- decreases linearly
	humanAggroDelta = 0,	-- resets to zero every wave
	humanAggroPerWave = {},	-- for stats tracking
	
	endgame = false,
	victory = false,
	endMiniQueenNum = 0,
	
	morphFrame = -1,
	morphed = false,
	specialPowerCooldown = 0,
	
	queenTime = 0,
}

_G.data = data
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- Load Config
--

do -- load config file
	local CONFIG_FILE = "LuaRules/Configs/spawn_defs.lua"
	local VFSMODE = VFS.RAW_FIRST
	local s = assert(VFS.LoadFile(CONFIG_FILE, VFSMODE))
	local chunk = assert(loadstring(s, file))
	setfenv(chunk, gadget)
	chunk()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- Utility
--

local function SetToList(set)
	local list = {}
	for k in pairs(set) do
		list[#list+1] = k
	end
	return list
end


local function SetCount(set)
	local count = 0
	for k in pairs(set) do
		count = count + 1
	end
	return count
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- Teams
--

for i, v in ipairs(modes) do -- make it bi-directional
	modes[v] = i
end


local function CompareDifficulty(...)
	level = 1
	for _, difficulty in ipairs{...} do
		if (modes[difficulty] > level) then
			level = modes[difficulty]
		end
	end
	return modes[level]
end


if (not gameMode) then -- set human and computer teams
	humanTeams[0]		= true
	computerTeams[1]	= true
	chickenTeamID		= 1
	luaAI			= 0 --defaultDifficulty
else
	local teams = Spring.GetTeamList()
	local lastChickenTeam = nil
	-- the problem is with human controlled chickens, otherwise it counts them as robot-players and difficulty increases very much
	-- probably, ideally this needs to be taught to differentiate between human chickens and human robots...
	for _, teamID in pairs(teams) do
		local luaAI = Spring.GetTeamLuaAI(teamID)
		if luaAI and string.find(string.lower(luaAI), "chicken") then
			lastChickenTeam = teamID
			--break
		end
	end
	local highestLevel = 0
	for _, teamID in pairs(teams) do
		local teamLuaAI = Spring.GetTeamLuaAI(teamID)
		-- check only for chicken AI teams
		if (teamLuaAI and teamLuaAI ~= "" and modes[teamLuaAI]) then
			luaAI = teamLuaAI
			highestLevel = CompareDifficulty(teamLuaAI, highestLevel)
			chickenTeamID = teamID
			computerTeams[teamID] = true
		elseif lastChickenTeam and Spring.AreTeamsAllied(teamID,lastChickenTeam) then
			computerTeams[teamID] = true -- count as computer
		else --if not (chickenTeamID and Spring.AreTeamsAllied(teamID, chickenTeamID))
	--then -- well as far as I understood this means to check whether team is chicken enemy then do next
			humanTeams[teamID] = true
		end
	end
	if chickenTeamID then
		Spring.SetGameRulesParam("chickenTeamID", chickenTeamID)
	end
	luaAI = highestLevel
end

local gaiaTeamID = Spring.GetGaiaTeamID()
computerTeams[gaiaTeamID] = nil
humanTeams[gaiaTeamID] = nil

local humanTeamsOrdered = {}
for id,_ in ipairs(humanTeams) do humanTeamsOrdered[#humanTeamsOrdered+1] = id end
for i=1, #humanTeamsOrdered do
	if humanTeamsOrdered[i+1] and not Spring.AreTeamsAllied(humanTeamsOrdered[i], humanTeamsOrdered[i+1]) then
		pvp = true
		Spring.Log(gadget:GetInfo().name, LOG.INFO, "Chicken: PvP mode detected")
		break
	end
end

if (luaAI == 0) then
	return false	-- nothing to do here, go home
end

GG.Chicken = {}
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- Difficulty
--


local function SetGlobals(difficulty)
	for key, value in pairs(gadget.difficulties[difficulty]) do
		gadget[key] = value
	end
	gadget.difficulties = nil
end

SetGlobals(luaAI or defaultDifficulty) -- set difficulty

-- adjust for player and chicken bot count
local playerCount = SetCount(humanTeams)
local malus = playerCount^playerMalus

burrowRegressTime = burrowRegressTime/playerCount
humanAggroPerBurrow = humanAggroPerBurrow/playerCount
humanAggroDefenseFactor = humanAggroDefenseFactor*playerCount
defensePerWave	= defensePerWave*playerCount

echo("Chicken configured for "..playerCount.." players")

burrowSpawnRate = burrowSpawnRate/(malus*0.8 + 0.2)/SetCount(computerTeams)
gracePeriod = math.max(gracePeriod - gracePenalty*(playerCount - 1), gracePeriodMin)
--humanAggroDecay = humanAggroDecay/playerCount

local function DisableBuildButtons(unitID, buildNames)
	for _, unitName in ipairs(buildNames) do
		if (UnitDefNames[unitName]) then
			local cmdDescID = Spring.FindUnitCmdDesc(unitID, -UnitDefNames[unitName].id)
			if (cmdDescID) then
				local cmdArray = {disabled = true, tooltip = tooltipMessage}
				Spring.EditUnitCmdDesc(unitID, cmdDescID, cmdArray)
			end
		end
	end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- Game Rules
--


local function SetupUnit(unitName)
	Spring.SetGameRulesParam(unitName.."Count", 0)
	Spring.SetGameRulesParam(unitName.."Kills", 0)
end

local baseQueenTime = queenTime
data.queenTime = queenTime


local difficulty = modes[luaAI or defaultDifficulty]

--if tobool(Spring.GetModOptions().burrowrespawn) or forceBurrowRespawn then respawnBurrows = true end

local function UpdateUnitCount()
	local teamUnitCounts = Spring.GetTeamUnitsCounts(chickenTeamID)

	--[[ if there are no more chickens of one type, the counter for this type
			 is not updated anymore -> counter keeps last known quantity
			 that's why we force to set all counters to zero first ]]
	for id, type in pairs(chickenTypes) do
		Spring.SetGameRulesParam(id.."Count", 0)
	end
	for id, type in pairs(defenders) do
		Spring.SetGameRulesParam(id.."Count", 0)
	end
	for unitDefID, count in pairs(teamUnitCounts) do
		if (unitDefID ~= "n") then
			Spring.SetGameRulesParam(UnitDefs[unitDefID].name.."Count", count)
		end
	end
end

local function KillOldChicken()
	local now = spGetGameSeconds()
	for unitID, birthDate in pairs(data.chickenBirths) do
		local age = now - birthDate
		if (age > maxAge + random(10)) then
			Spring.DestroyUnit(unitID)
		end
	end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- Game End Stuff
--

local function KillAllComputerUnits()
	data.victory = true
	for teamID in pairs(computerTeams) do
		--local teamUnits = spGetTeamUnits(teamID)
		--for i=1,#teamUnits do
		--	Spring.DestroyUnit(teamUnits[i])
		--end
		local allyTeam = select(6, Spring.GetTeamInfo(teamID, false))
		if GG.DestroyAlliance then
			GG.DestroyAlliance(allyTeam)
		end
	end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- Spawn Dynamics
--

local function IsPlayerUnitNear(x, z, r)
	for teamID in pairs(humanTeams) do	 
		if (spGetUnitsInCylinder(x, z, r, teamID)[1]) then
			return true
		end
	end
end

-- used to generate eggs from burrows
local function SpawnEggs(x, y, z)
	local choices,choisesN = {},0
	local now = spGetGameSeconds() + math.floor(gameFrameOffset/30)

	for name in pairs(chickenTypes) do
		if (not chickenTypes[name].noegg and chickenTypes[name].time <= now) then
			choisesN = choisesN + 1
			choices[choisesN] = name
		end
	end
	for name in pairs(defenders) do
		if (not defenders[name].noegg and defenders[name].time <= now) then
			choisesN = choisesN + 1
			choices[choisesN] = name
		end
	end
	if choisesN <= 0 then return end
	for i=1, burrowEggs do
		local choice = choices[random(choisesN)]
		local rx, rz = random(-30, 30), random(-30, 30)
		local eggID = Spring.CreateFeature(choice.."_egg", x+rx, y, z+rz, random(-32000, 32000))
		--if (eggID and (not eggs)) then data.eggDecay[eggID] = spGetGameSeconds() + eggDecayTime end
	end
end

--cleans up old eggs
local function DecayEggs()
	if eggs then return end
	for eggID, decayTime in pairs(data.eggDecay) do
		if spGetGameSeconds() >= decayTime then
			Spring.DestroyFeature(eggID)
			data.eggDecay[eggID] = nil
		end
	end
end

--[[
HOW BURROW TARGETING WORKS
In normal mode, burrows will send chickens after a random unit of the owner of the enemy unit closest to the burrow.
In PvP mode, each burrow caches a target ID: that of the nearest enemy structure (but not mines or terraform). This cache is updated every UnitCreated and UnitDestroyed.
	The chickens will attack a random unit belonging to cached target owner.
Idle chickens are automatically set to attack a random target (in GameFrame).
]]--

local function UpdateBurrowTarget(burrowID, targetArg)
	local targetData = data.burrows[burrowID]
	local oldTarget = targetData.targetID
	if not targetArg then
		for id,_ in pairs(data.targets) do
			local testDistance = spGetUnitSeparation(burrowID, id, true) or 100000
			if testDistance < targetData.targetDistance then
				targetData.targetDistance = testDistance
				targetData.targetID = id
			end
		end
	else
		local testDistance = spGetUnitSeparation(burrowID, targetArg, true) or targetData.targetDistance
		if testDistance < targetData.targetDistance then
			targetData.targetDistance = testDistance
			targetData.targetID = targetArg
		end
	end
	--echo("Final selected target ID: "..data.targetID)
	local validUnitID = spValidUnitID(data.targetID) --in case multiple UnitDestroyed() is called at same frame and burrow happen to choose a target before all Destroyed unit is registered.
	if validUnitID and targetData.targetID ~= oldTarget then
		targetData.targetTeam = spGetUnitTeam(data.targets[data.targetID])
		--spGiveOrderToUnit(burrowID, CMD_ATTACK, {data.targetID}, 0)
		--echo("Target for burrow ID ".. burrowID .." updated to target ID " .. data.targetID)
	elseif not validUnitID then
		targetData.targetID = nil
		--spGiveOrderToUnit(burrowID, CMD_STOP, {}, 0)
		--echo("Target for burrow ID ".. burrowID .." lost, waiting")
	end
end

local function AttackNearestEnemy(unitID)
	local targetID = Spring.GetUnitNearestEnemy(unitID)
	if (targetID) then
		local tx, ty, tz = spGetUnitPosition(targetID)
		spGiveOrderToUnit(unitID, CMD_FIGHT, {tx, ty, tz}, 0)
	end
end

local function ChooseTarget(unitID)
	local tries = 0
	local units = {}
	if (not unitID) or (spGetUnitTeam(unitID) == gaiaTeamID) then 
		--makes chicken go for random unit belonging to owner of random player if unitID is NIL
		local humanTeamList = SetToList(humanTeams)
		if (not humanTeamList[1]) then
			return
		end
		repeat
			local teamID = humanTeamList[random(#humanTeamList)]
			units	= spGetTeamUnits(teamID)
			tries = tries + 1
		until (#units > 0 or tries >= 100)
	else 
		--makes chicken go for random unit belonging to owner of closest enemy
		local teamID = spGetUnitTeam(unitID)
		units = spGetTeamUnits(teamID)
	end
	tries = 0
	local targetID
	if (units[2]) then
		repeat
		targetID = units[random(1,#units)]
			tries = tries + 1
		until (targetID and not (noTarget[UnitDefs[Spring.GetUnitDefID(targetID)].name]) or tries>=100)
	else
		targetID = units[1]
	end
	if not targetID then return end
	return {spGetUnitPosition(targetID)}
end

local function IsChickenTechAvailable(chickenName, chickenDef, time, techMod)
	local currTech = time + techMod
	local min = time * techTimeFloorFactor	
	if currTech < min then
		currTech = min
	end
	if currTech > techTimeMax then	-- note max may be lower than min, max takes priority
		currTech = techTimeMax
	end
	
	if currTech < chickenDef.time then
		return false
	end
	if chickenDef.obsolete and (chickenDef.obsolete < currTech) then
		return false
	end
	return true
end

local function ChooseChicken(units, useTech)
	local s = spGetGameSeconds() + math.floor(gameFrameOffset/30)
	units = units or chickenTypes
	local choices,choisesN = {},0
	local techMod = 0
	if useTech then
		techMod = data.totalTechAccel
	end
	for chickenName, c in pairs(units) do
		if IsChickenTechAvailable(chickenName, c, s, techMod) then
			local chance = math.floor((c.initialChance or 1) + (s - (c.time/60)) * (c.timeChanceMult or 0))
			for i=1, chance do
				choisesN = choisesN + 1
				choices[choisesN] = chickenName
			end
		end
	end
	if (choisesN==0) then
		return
	else
		return choices[random(choisesN)], choices[random(choisesN)]
	end
end


local function SpawnChicken(burrowID, spawnNumber, chickenName)
	if Spring.IsGameOver() then return end
	
	local x, z
	local bx, by, bz = spGetUnitPosition(burrowID)
	if (not bx or not by or not bz) then
		return
	end
	local tries		 = 0
	local s			= spawnSquare
	local now		= spGetGameSeconds()
	local burrowTarget	= Spring.GetUnitNearestEnemy(burrowID, 20000, false)
	local tloc = data.targetCache
	if (burrowTarget) then tloc = ChooseTarget(burrowTarget) end
	if pvp and data.burrows[burrowID].targetID then
	local tx, ty, tz = spGetUnitPosition(data.burrows[burrowID].targetID)
	tloc = {tx, ty, tz}
	end

	for i=1, spawnNumber do
		repeat
			x = random(bx - s, bx + s)
			z = random(bz - s, bz + s)
			s = s + spawnSquareIncrement
			tries = tries + 1
		until (not spGetGroundBlocked(x, z) or tries > spawnNumber + maxTriesSmall)
		local unitID = spCreateUnit(chickenName, x, by, z, "n", chickenTeamID)
		if unitID then
			spGiveOrderToUnit(unitID, CMD.MOVE_STATE, roamParam, 0) --// set moveState to roam
			if (tloc) then spGiveOrderToUnit(unitID, CMD_FIGHT, tloc, 0) end
			data.chickenBirths[unitID] = now 
		end
	end
end

local function SpawnTurret(burrowID, turret, number, force)
	if (not turret) or Spring.GetUnitIsDead(burrowID) then return end
	if data.victory or Spring.IsGameOver() then
		return
	end
	
	local cost = (defenders[turret] and defenders[turret].cost) or 1
	local squadSize = (defenders[turret] and defenders[turret].squadSize) or 1
	squadSize = squadSize*data.defenseQuota/cost * random(75, 125)/100
	
	if ((not force) and random() > squadSize) then
		return
	end
	
	local x, z
	local bx, by, bz = spGetUnitPosition(burrowID)
	if not bx then return end
	local tries = 0
	local s	 = spawnSquare
	local spawnNumber = number or math.max(squadSize, 1)
	local now = spGetGameSeconds()
	local turretDef

	if not force then
		data.defensePool = data.defensePool - cost*spawnNumber
	end	
	
	for i=1, spawnNumber do	
		repeat
			x = random(bx - s, bx + s)
			z = random(bz - s, bz + s)
			s = s + spawnSquareIncrement
			tries = tries + 1
		until (not spGetGroundBlocked(x, z) or tries > spawnNumber + maxTriesSmall)
		
		local unitID = spCreateUnit(turret, x, by, z, "n", chickenTeamID) -- FIXME
		turretDef = unitID and UnitDefs[spGetUnitDefID(unitID)]
		if turretDef and turretDef.canMove then
			local burrowTarget = Spring.GetUnitNearestEnemy(burrowID, 20000, false)
			if (burrowTarget) then
				local tloc = ChooseTarget(burrowTarget)
				if tloc then
					spGiveOrderToUnit(unitID, CMD_FIGHT, tloc, 0)
				end
			end
		--else
		--	Spring.SetUnitBlocking(unitID, false)
		end
	end
end

local function SpawnSupport(burrowID, support, number, force)
	if (not support) or Spring.GetUnitIsDead(burrowID) then return end
	if Spring.IsGameOver() then return end
	local squadSize = (supporters[support] and supporters[support].squadSize) or 1
	squadSize = squadSize * waveSizeMult * random(75, 125)/100
	
	local t = spGetGameSeconds()
	if (t < rampUpTime) then
		squadSize = squadSize * t/rampUpTime
	end
	
	if ((not force) and random() > squadSize)	then
		return
	end
	
	local x, z
	local bx, by, bz = spGetUnitPosition(burrowID)
	if not bx then return end
	local tries = 0
	local s = spawnSquare
	local spawnNumber = number or math.max(math.floor(squadSize), 1)

	for i=1, spawnNumber do	
		repeat
			x = random(bx - s, bx + s)
			z = random(bz - s, bz + s)
			s = s + spawnSquareIncrement
			tries = tries + 1
		until (not spGetGroundBlocked(x, z) or tries > spawnNumber + maxTriesSmall)
		
		local unitID = spCreateUnit(support, x, by, z, "n", chickenTeamID) -- FIXME
		local burrowTarget	= Spring.GetUnitNearestEnemy(burrowID, 20000, false)
		if unitID and (burrowTarget) then
			local tloc = ChooseTarget(burrowTarget)
			if tloc then
				spGiveOrderToUnit(unitID, CMD_FIGHT, tloc, 0)
			end
		end
	end
end

local function SpawnBurrow(number, loc, burrowLevel)
	if (data.victory or data.endgame) then return end
	if Spring.IsGameOver() then return end
	
	local t		 = spGetGameSeconds()
	local unitID
	--if t < (gracePeriod/4) then return end
		
	for i=1, (number or 1) do
		local x, y, z
		local tries = 0
		if loc then
			x, y, z = unpack(loc)
		else
			repeat
				x = random(spawnSquare, Game.mapSizeX - spawnSquare)
				z = random(spawnSquare, Game.mapSizeZ - spawnSquare)
				y = Spring.GetGroundHeight(x, z)
				tries = tries + 1
				local blocking = Spring.TestBuildOrder(testBuilding, x, y, z, 1)
				if (blocking == 2) then
					if (lava and Spring.GetGroundHeight(x,z) <= 0) then
						blocking = 1
					end
					
					local proximity = spGetUnitsInCylinder(x, z, minBaseDistance)
					local vicinity = spGetUnitsInCylinder(x, z, maxBaseDistance)
					local humanUnitsInVicinity = false
					local humanUnitsInProximity = false
					for i=1, #vicinity, 1 do
						if (spGetUnitTeam(vicinity[i]) ~= chickenTeamID) then
							humanUnitsInVicinity = true
							break
						end
					end
				
					for i=1, #proximity, 1 do
						if (spGetUnitTeam(proximity[i]) ~= chickenTeamID) then
							humanUnitsInProximity = true
							break
						end
					end
				
					if (humanUnitsInProximity or not humanUnitsInVicinity) then
						blocking = 1
					end
				end
			until (blocking == 2 or tries > maxTriesSmall)
		end

		unitID = spCreateUnit(burrowName, x, y, z, "n", chickenTeamID)
		-- handled in UnitCreated()
		--data.burrows[unitID] = {targetID = unitID, targetDistance = 100000}
		--UpdateBurrowTarget(unitID, nil)
		--Spring.SetUnitBlocking(unitID, false)
	end
	return unitID
end
GG.Chicken.SpawnBurrow = SpawnBurrow

-- spawns arbitrary unit(s) obeying min and max distance from human units
-- supports spawning in batches
local function SpawnUnit(unitName, number, minDist, maxDist, target)
	if data.victory then return end
	minDist = minDist or minBaseDistance
	maxDist = maxDist or maxBaseDistance

	local x, y, z
	local tries = 0
	local block = false
	
	repeat
		if not target then
			x = random(spawnSquare, Game.mapSizeX - spawnSquare)
			z = random(spawnSquare, Game.mapSizeZ - spawnSquare)
		else
			x = random(target[1] - maxDist, target[1] + maxDist)
			z = random(target[3] - maxDist, target[3] + maxDist)
		end
		y = Spring.GetGroundHeight(x, z)
		tries = tries + 1
		block = false
		
		local proximity = spGetUnitsInCylinder(x, z, minDist)
		local vicinity = spGetUnitsInCylinder(x, z, maxDist)
		local humanUnitsInVicinity = false
		local humanUnitsInProximity = false
		for i=1, #vicinity, 1 do
			if (spGetUnitTeam(vicinity[i]) ~= chickenTeamID) then
				humanUnitsInVicinity = true
				break
			end
		end
		
		for i=1, #proximity, 1 do
			if (spGetUnitTeam(proximity[i]) ~= chickenTeamID) then
				humanUnitsInProximity = true
				break
			end
		end
		
		if (humanUnitsInProximity or not humanUnitsInVicinity) then
			block = true
		end
	until (not spGetGroundBlocked(x, z) or (not block) or (tries > number + maxTries))
	
	for i=1, (number or 1) do
		local unitID = spCreateUnit(unitName, x + random(-spawnSquare, spawnSquare), y, z + random(-spawnSquare, spawnSquare), "n", chickenTeamID)
		if unitID then
			spGiveOrderToUnit(unitID, CMD.MOVE_STATE, roamParam, 0) --// set moveState to roam
		end
	end
end

local function SetMorphFrame()
	data.morphFrame = spGetGameFrame() + random(queenMorphTime[1], queenMorphTime[2])
	--Spring.Echo("Morph frame set to: " .. data.morphFrame)
	Spring.Echo("Next morph in: " .. math.ceil((data.morphFrame - spGetGameFrame())/30) .. " seconds")
end

local function SpawnQueen()
	local x, y, z
	local tries = 0
	 
	repeat
		x = random(0, Game.mapSizeX)
		z = random(0, Game.mapSizeZ)
		y = Spring.GetGroundHeight(x, z)
		tries = tries + 1
		local blocking = Spring.TestBuildOrder(testBuildingQ, x, y, z, 1)
		if (blocking == 2) then
			local proximity = spGetUnitsInCylinder(x, z, minBaseDistance)
			for i=1, #proximity, 1 do
				if (spGetUnitTeam(proximity[i]) ~= chickenTeamID) then
					blocking = 1
					break
				end
			end
		end
	until (blocking == 2 or tries > maxTries)
	
	queenHealthMod = queenHealthMod * (0.5*(data.queenTime/baseQueenTime) + 0.5) * ((playerCount/2) + 0.5)
	
	if queenMorphName ~= '' then SetMorphFrame() end
	return spCreateUnit(queenName, x, y, z, "n", chickenTeamID)
end

local function SpawnMiniQueen()
	local x, y, z
	local tries = 0
	 
	repeat
		x = random(0, Game.mapSizeX)
		z = random(0, Game.mapSizeZ)
		y = Spring.GetGroundHeight(x, z)
		tries = tries + 1
		local blocking = Spring.TestBuildOrder(testBuildingQ, x, y, z, 1)
		if (blocking == 2) then
			local proximity = spGetUnitsInCylinder(x, z, minBaseDistance)
			for i=1, #proximity, 1 do
				if (spGetUnitTeam(proximity[i]) ~= chickenTeamID) then
					blocking = 1
					break
				end
			end
		end
	until (blocking == 2 or tries > maxTries)
	local unitID = spCreateUnit(miniQueenName, x, y, z, "n", chickenTeamID)
	
	if unitID then
		local miniQueenTarget	= Spring.GetUnitNearestEnemy(unitID, 20000, false)
		local tloc
		if (miniQueenTarget) then tloc = ChooseTarget(miniQueenTarget) end
		if (tloc) then spGiveOrderToUnit(unitID, CMD_RAW_MOVE, tloc, 0) end
	end
end


local function ProcessSpecialPowers()
	if data.specialPowerCooldown > 0 then
		return
	end
	local selection
	local time = spGetGameSeconds()
	for i=#specialPowers, 1, -1 do
		--Spring.Echo(specialPowers[i].name)
		if (specialPowers[i].time < time) and ((specialPowers[i].obsolete or math.huge) > time) and (specialPowers[i].maxAggro > data.humanAggro) then
			selection = specialPowers[i]
			break
		end
	end
	if not selection then
		return
	end
	--Spring.Echo(selection.name .. " selected")
	local count = selection.count or (selection.burrowRatio and (selection.burrowRatio * SetCount(data.burrows))) or 1
	count = math.ceil(count)
	
	if selection.tieToBurrow then
		local burrowsOrdered = {}
		for id in pairs(data.burrows) do
			burrowsOrdered[#burrowsOrdered + 1] = id
		end
		local burrowID = burrowsOrdered[math.random(#burrowsOrdered)]
		SpawnTurret(burrowID, selection.unit, count, true)
	else
		local target = selection.targetHuman and ChooseTarget()
		SpawnUnit(selection.unit, count, selection.minDist, selection.maxDist, target)
	end
	data.specialPowerCooldown = selection.cooldown or 1
	Spring.Echo("Chickens unleashing plot: "..selection.name.."!!")
end


local function Wave()
	local t = spGetGameSeconds()
	
	if data.victory or Spring.IsGameOver() then
		return
	end
	
	if data.endgame and pvp then
		data.endMiniQueenNum = data.endMiniQueenNum + 1
		if data.endMiniQueenNum == endMiniQueenWaves then
			for i=1,playerCount do SpawnMiniQueen() end
				endMiniQueenNum = 0 
			end
	end
	data.specialPowerCooldown = data.specialPowerCooldown - 1
	ProcessSpecialPowers()
	
	data.waveNumber = data.waveNumber + 1
	data.humanAggroPerWave[data.waveNumber] = data.humanAggro
	
	local burrowCount = SetCount(data.burrows)
	--echo("Wave bonus delta this round: "..data.humanAggroDelta)
	--echo("Wave bonus this round: "..humanAggro)
	--reduce all chicken appearance times
	local techDecel = 0
	if data.humanAggro > 0 then
		techDecel = data.humanAggro * humanAggroTechTimeRegress
	else
		techDecel = data.humanAggro * humanAggroTechTimeProgress
	end
	data.totalTechAccel = data.totalTechAccel - techDecel + techAccelPerPlayer*(playerCount-1)
	Spring.SetGameRulesParam("techAccel", data.totalTechAccel)
	
	--[[
	for chickenName, c in pairs(chickenTypes) do
		c.time = c.time + techDecel
		if c.obsolete then c.obsolete = c.obsolete + techDecel end
	end
	for chickenName, c in pairs(supporters) do
		c.time = c.time + techDecel
		if c.obsolete then c.obsolete = c.obsolete + techDecel end
	end
	]]--
	--echo(burrowCount .. " burrows have reduced tech time by " .. math.ceil(timeReduction) .. " seconds")
	--echo("Lifetime tech time reduction: " .. math.ceil(data.totalTechAccel) .. " seconds")
	
	local chicken1Name, chicken2Name = ChooseChicken(chickenTypes, true)
	local turret = ChooseChicken(defenders)
	local support = ChooseChicken(supporters, true)
	local squadNumber = (t*timeSpawnBonus+waveSizeMult) * (baseWaveSize + math.min(math.max(data.humanAggro*humanAggroWaveFactor, 0), humanAggroWaveMax)	+ burrowCount*burrowWaveSize) / math.max(burrowCount, 1)
	if (t < rampUpTime) then
		local oldNumber = squadNumber
		squadNumber = squadNumber * t/rampUpTime
		Spring.Echo("Ramping up", oldNumber, squadNumber, t, rampUpTime)
	end
	
	--if data.queenID then squadNumber = squadNumber/2 end
	local chicken1Number = math.ceil(waveRatio * squadNumber * chickenTypes[chicken1Name].squadSize)
	local chicken2Number = math.floor((1-waveRatio) * squadNumber * chickenTypes[chicken2Name].squadSize)
	if (data.queenID) then
		SpawnChicken(data.queenID, chicken1Number*queenSpawnMult, chicken1Name)
		SpawnChicken(data.queenID, chicken2Number*queenSpawnMult, chicken2Name)
	end

	-- some code for defenses
	local defensePoolDelta = data.humanAggro * humanAggroDefenseFactor
	if turret then
		defensePoolDelta = defensePoolDelta + defensePerWave	-- don't add defensePerWave for the waves where no turrets can be spawned anyway
	end
	if defensePoolDelta < 0 then defensePoolDelta = 0 end
	data.defensePool = data.defensePool + defensePoolDelta
	data.defenseQuota = data.defensePool/burrowCount 
	
	local spawnDef = false
	local cost = (defenders[turret] and defenders[turret].cost) or 1
	if turret and cost < data.defenseQuota then
		spawnDef = true
		--Spring.Echo("Defense pool/quota: " .. data.defensePool .. " / " .. data.defenseQuota)		
	end
	
 
	
	for burrowID in pairs(data.burrows) do
		SpawnChicken(burrowID, chicken1Number, chicken1Name)
		SpawnChicken(burrowID, chicken2Number, chicken2Name)
		
		if spawnDef and not data.endgame then SpawnTurret(burrowID, turret) end
		SpawnSupport(burrowID, support)
	end
	data.humanAggro = data.humanAggro - humanAggroDecay
	if data.humanAggro > humanAggroMax then
		data.humanAggro = humanAggroMax
	elseif data.humanAggro < humanAggroMin then
		data.humanAggro = humanAggroMin
	end
	
	data.humanAggroDelta = 0
	Spring.SetGameRulesParam("humanAggro", data.humanAggro)
	return chicken1Name, chicken2Name, chicken1Number, chicken2Number
end

local function MorphQueen()
	-- store values to be copied
	local tempID = data.queenID
	local x, y, z = spGetUnitPosition(tempID)
	if not (x and y and z) then	-- invalid position somehow, try again in a bit
		data.morphFrame = data.morphFrame + 60
		return
	end
	
	local oldHealth,oldMaxHealth,paralyzeDamage,captureProgress,buildProgress = Spring.GetUnitHealth(tempID)
	local xp = Spring.GetUnitExperience(tempID)
	local heading = Spring.GetUnitHeading(tempID)
	local cmdQueue = spGetCommandQueue(tempID, -1)
	local queenOwner = spGetUnitTeam(tempID)
	
	if Spring.GetUnitIsStunned(tempID) or (Spring.GetUnitRulesParam(tempID, "disarmed") == 1) then	-- postpone morph
		data.morphFrame = data.morphFrame + 60
		return
	end
	
	-- perform switcheroo
	data.queenID = nil
	Spring.DestroyUnit(tempID, false, true)
	if data.morphed == true then
		data.queenID = spCreateUnit(queenName, x, y, z, "n", queenOwner)
	else
		data.queenID = spCreateUnit(queenMorphName, x, y, z, "n", queenOwner)
	end

	if not data.queenID then
		Spring.Echo("LUA_ERRRUN chicken queen was not recreated correctly")
		return
	end

	data.morphed = not data.morphed
	SetMorphFrame()
	
	-- copy values
	-- position
	Spring.MoveCtrl.Enable(data.queenID)
	--Spring.MoveCtrl.SetPosition(data.queenID, x, y, z)	--needed to reset y-axis position
	--Spring.SpawnCEG("dirt", x, y, z)	--helps mask the transition
	Spring.MoveCtrl.SetHeading(data.queenID, heading)
	Spring.MoveCtrl.Disable(data.queenID)
	local env = Spring.UnitScript.GetScriptEnv(data.queenID)
	Spring.UnitScript.CallAsUnit(data.queenID, env.MorphFunc)
	--health handling
	local _,newMaxHealth				 = Spring.GetUnitHealth(data.queenID)
	newMaxHealth = newMaxHealth * queenHealthMod
	local newHealth = (oldHealth / oldMaxHealth) * newMaxHealth
	-- if newHealth >= 1 then newHealth = 1 end
	Spring.SetUnitMaxHealth(data.queenID, newMaxHealth)
	spSetUnitHealth(data.queenID, {health = newHealth, capture = captureProgress, paralyze = paralyzeDamage, build = buildProgress, })
	-- orders, XP
	Spring.SetUnitExperience(data.queenID, xp)
	if (cmdQueue and cmdQueue[1]) then		--copy order queue
		for i=1,#cmdQueue do
			spGiveOrderToUnit(data.queenID, cmdQueue[i].id, cmdQueue[i].params, cmdQueue[i].options.coded)
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- Call-ins
--

function gadget:UnitCreated(unitID, unitDefID, unitTeam)
	local name = UnitDefs[unitDefID].name
	if ( chickenTeamID == unitTeam ) then
		if name == burrowName then
			data.burrows[unitID] = {targetID = unitID, targetDistance = 100000}
			UpdateBurrowTarget(unitID, nil)
		end
		local n = Spring.GetGameRulesParam(name.."Count") or 0
		Spring.SetGameRulesParam(name.."Count", n+1)
	end
	if (alwaysVisible and unitTeam == chickenTeamID) then
		Spring.SetUnitAlwaysVisible(unitID, true)
	end
	if (eggs) then
		DisableBuildButtons(unitID, mexes)
	end
end

function gadget:UnitFinished(unitID, unitDefID, unitTeam)
	--burrow targetting
	local name = UnitDefs[unitDefID].name
	if (humanTeams[unitTeam]) and UnitDefs[unitDefID].isImmobile and (not noTarget.name) then
		--echo("Building ID "..unitID .." added to target array")
		local x, y, z = spGetUnitPosition(unitID)
		data.targets[unitID] = unitTeam
		--distance check for existing burrows goes here
		for burrow, data in pairs(data.burrows) do
			UpdateBurrowTarget(burrow, unitID)
		end
	end
end

function gadget:GameStart()
	if pvp then Spring.Echo("Chicken: PvP mode initialized") end
	--data.waveSchedule[gracePeriod*30] = true	-- schedule first wave
	data.waveSchedule = gracePeriod * 30
end

function gadget:GameFrame(n)
	--if ((n+19 - gracePeriod*30) % (30 * chickenSpawnRate) < 0.1) and (n - gracePeriod*30 > 0) then
	--if data.waveSchedule[n] then
	if n > data.waveSchedule then
		--data.waveSchedule[n + (30 * chickenSpawnRate)] = true
		data.waveSchedule = n + (30 * chickenSpawnRate)
		--Spring.Echo(data.waveSchedule)
		local args = {Wave()}
		if (args[1]) then
			_G.chickenEventArgs = {type="wave", unpack(args)}
			SendToUnsynced("ChickenEvent")
			_G.chickenEventArgs = nil
		end
	--data.waveSchedule[n] = nil	-- just to be sure
	end

	if ((n+17) % 30 < 0.1) then
		UpdateUnitCount()
		local burrowCount = SetCount(data.burrows)
		
		local t = spGetGameSeconds()

		local timeSinceLastSpawn = t - data.timeOfLastSpawn
		local burrowSpawnTime = burrowSpawnRate*0.25*(burrowCount+1)
		
		if (burrowSpawnTime < timeSinceLastSpawn and burrowCount < maxBurrows) then
			SpawnBurrow()
			data.timeOfLastSpawn = t
			_G.chickenEventArgs = {type="burrowSpawn"}
			SendToUnsynced("ChickenEvent")
			_G.chickenEventArgs = nil
		end
	
		if (t >= data.queenTime) and (not endlessMode) then
			if (not data.endgame) then
				_G.chickenEventArgs = {type="queen"}
				SendToUnsynced("ChickenEvent")
				_G.chickenEventArgs = nil
				if not pvp then
					local queenID = SpawnQueen()
					if queenID then
						local xp = (malus or 1) - 1
						--Spring.SetUnitExperience(queenID, xp)
						local _, maxHealth = Spring.GetUnitHealth(queenID)
						maxHealth = maxHealth * queenHealthMod
						Spring.SetUnitMaxHealth(queenID, maxHealth)
						spSetUnitHealth(queenID, maxHealth)
						data.queenID = queenID
					end
				else
					--chickenSpawnRate = chickenSpawnRate/2
					for i=1,playerCount do
						SpawnMiniQueen()
					end
				end
				data.endgame = true
			end
		end
		
		if data.miniQueenNum <= #miniQueenTime and (t >= (miniQueenTime[data.miniQueenNum]*data.queenTime)) then
			_G.chickenEventArgs = {type="miniQueen"}
			SendToUnsynced("ChickenEvent")
			_G.chickenEventArgs = nil
			for i=1,playerCount do
				SpawnMiniQueen()
			end
			data.miniQueenNum = data.miniQueenNum + 1
		end
	end
	
	if ((n+29) % 90) < 0.1 then
		KillOldChicken()
		DecayEggs()
	
		data.targetCache = ChooseTarget()

		if (data.targetCache) then
			local chickens = spGetTeamUnits(chickenTeamID) 
			for i=1,#chickens do
				local unitID = chickens[i]
				if (not Spring.Utilities.GetUnitFirstCommand(unitID)) then
					--AttackNearestEnemy(unitID)
					if (difficulty > 1) and (unitID == data.queenID) then
						spGiveOrderToUnit(unitID, CMD_RAW_MOVE, data.targetCache, CMD.OPT_SHIFT)
					else
						spGiveOrderToUnit(unitID, CMD_FIGHT, data.targetCache, CMD.OPT_SHIFT)
					end
				end
			end
		end
		-- FIXME: don't make chickens lose if they won
		--if (not data.victory) and Spring.IsGameOver() then
		--	KillAllComputerUnits()
		--end
	end
	
	--morphs queen
	if n == data.morphFrame then
		--Spring.Echo("Morphing queen")
		MorphQueen()
	end
end


function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
	data.chickenBirths[unitID] = nil
	if data.targets[unitID] then
		data.targets[unitID] = nil
		for burrow, data in pairs(data.burrows) do
			if data.targetID == unitID then		--retarget burrows if needed
				data.targetID = burrow
				data.targetDistance = 1000000
				UpdateBurrowTarget(burrow, nil)
			end
		end
	end
	if (unitID == data.queenID) then
		KillAllComputerUnits()
	end
	local name = UnitDefs[unitDefID].name
	if (unitTeam == chickenTeamID) then
		if (chickenTypes[name] or (name == burrowName)) then
			local kills = Spring.GetGameRulesParam(name.."Kills")
			Spring.SetGameRulesParam(name.."Kills", kills + 1)
		end
	end
	if (data.burrows[unitID]) then
		data.burrows[unitID] = nil
		local count = 0
		local burrowsOrdered = {}
		for _,id in pairs(data.burrows) do
			burrowsOrdered[#burrowsOrdered + 1] = id
			count = count + 1
		end
		
		local aggro = math.max(data.humanAggro, humanAggroQueenTimeMin)
		aggro = math.min(aggro, humanAggroQueenTimeMax)
		local reduction = burrowQueenTime*humanAggroQueenTimeFactor*aggro
		reduction = math.max(reduction, 0)
		data.queenTime = math.max(data.queenTime - reduction, 1)
		
		local oldAggro = data.humanAggro
		data.humanAggro = data.humanAggro + humanAggroPerBurrow
		if data.humanAggro > humanAggroMax then
			data.humanAggro = humanAggroMax
		end
		data.humanAggroDelta = data.humanAggroDelta + data.humanAggro - oldAggro
		Spring.SetGameRulesParam("queenTime", data.queenTime)
		Spring.SetGameRulesParam("humanAggro", data.humanAggro)
		
		local techDecel = burrowRegressTime
		data.totalTechAccel = data.totalTechAccel - techDecel
		Spring.SetGameRulesParam("techAccel", data.totalTechAccel)
		
		data.defensePool = data.defensePool + defensePerBurrowKill
		
		-- spawn turrets
		--[[
		if not data.endgame then
			local turret = ChooseChicken(defenders)
			local burrowToDefend = burrowsOrdered[(random(#burrowsOrdered))]
			SpawnTurret(burrowToDefend, turret)
		end
		]]--
	
		if alwaysEggs then SpawnEggs(spGetUnitPosition(unitID)) end
		if (eggs) then SpawnEggs(spGetUnitPosition(unitID)) end
		if (respawnBurrows) or (random() < burrowRespawnChance) then
			--echo("Respawning burrow")
			SpawnBurrow()
		end
	
		if pvp and data.endgame then
			if count == 0 then KillAllComputerUnits() end
		end
	end
	if (chickenTypes[name] and not chickenTypes[name].noegg) or (defenders[name] and not defenders[name].noegg) or (miniQueenName == name) then
		local x, y, z = spGetUnitPosition(unitID)
		if alwaysEggs then
		local eggID = Spring.CreateFeature(name.."_egg", x, y, z, random(-32000, 32000))
		if eggDecayTime > 0 and not eggs then data.eggDecay[eggID] = spGetGameSeconds() + eggDecayTime end
	end
	if eggs then Spring.CreateFeature(name.."_egg", x, y, z, random(-32000, 32000)) end
	end
end

--capturing a chicken counts as killing it
function gadget:AllowUnitTransfer(unitID, unitDefID, oldTeam, newTeam, capture)
	if capture then gadget:UnitDestroyed(unitID, unitDefID, oldTeam) end
	return true
end

function gadget:TeamDied(teamID)
	humanTeams[teamID] = nil
	computerTeams[teamID] = nil
end

function gadget:AllowCommand_GetWantedCommand()
	return mexesUnitDefID
end

function gadget:AllowCommand_GetWantedUnitDefID()
	return true
end

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	if (eggs) then
		if (mexesUnitDefID[cmdID]) then
			return false -- command was used
		end
	end
	return true	-- command was not used
end

function gadget:FeatureDestroyed(featureID, allyTeam)
	data.eggDecay[featureID] = nil
end

function gadget:GameOver()

	data.morphFrame = -1

	local function ExceedsOne(num)
		num = tonumber(num) or 1
		return num > 1
	end
	local modopts = Spring.GetModOptions()
	local metalmult = tonumber(Spring.GetModOptions().metalmult) or 1
	local energymult = tonumber(Spring.GetModOptions().energymult) or 1
	if ExceedsOne(modopts.metalmult) or ExceedsOne(modopts.metalmult) or (not ExceedsOne((modopts.terracostmult or 1) + 0.001)) then
		Spring.Log(gadget:GetInfo().name, LOG.INFO, "<Chicken> Cheating modoptions, no score sent")
		return
	end
	
	--Spring.Echo("<Chicken> AGGRO STATS")
	--for waveNum,aggro in ipairs(data.humanAggroPerWave) do
	--	Spring.Echo(waveNum, aggro)
	--end
	
	local time = Spring.GetGameSeconds()
	local score = math.min(time/data.queenTime, 1) * 1000	-- 1000 points * queen anger %
	if data.endgame then
		score = score + 250	-- +250 points for making it to endgame
	end
	if data.victory then
		score = score + math.max(60*60 - time, 0) + 250	-- +250 points for winning, +1 point for each second under par
	end
	score = math.floor(score * scoreMult)	-- multiply by mult
	Spring.SendCommands("wbynum 255 SPRINGIE:score,ID: "..Spring.Utilities.Base64Encode(tostring(spGetGameFrame() + gameFrameOffset).."/"..tostring(math.floor(score))))
end

function gadget:Load(zip)
	if not (GG.SaveLoad and GG.SaveLoad.ReadFile) then
		Spring.Log(gadget:GetInfo().name, LOG.ERROR, "ERROR: Chicken Spawner failed to access save/load API")
		return
	end
	
	gameFrameOffset = GG.SaveLoad.GetSavedGameFrame()
	
	local saveData = GG.SaveLoad.ReadFile(zip, "Chicken", SAVE_FILE) or {}
	data.queenID = GG.SaveLoad.GetNewUnitID(saveData.queenID)
	data.queenTime = (saveData.queenTime or baseQueenTime) - gameFrameOffset/30
	data.miniQueenNum = saveData.miniQueenNum
	--data.targetCache = saveData.targetCache	-- not needed
	data.burrows = GG.SaveLoad.GetNewUnitIDKeys(saveData.burrows)
	for burrowID, targetData in pairs(data.burrows) do
		targetData.targetID = GG.SaveLoad.GetNewUnitID(targetData.targetID)
	end
	data.chickenBirths = GG.SaveLoad.GetNewUnitIDKeys(saveData.chickenBirths)
	data.timeOfLastSpawn = saveData.timeOfLastSpawn - math.floor(gameFrameOffset/30)
	data.waveSchedule = saveData.waveSchedule - gameFrameOffset
	data.waveNumber = saveData.waveNumber
	data.eggDecay = GG.SaveLoad.GetNewFeatureIDKeys(saveData.eggDecay)
	data.targets = GG.SaveLoad.GetNewUnitIDKeys(saveData.targets)
	data.totalTechAccel = saveData.totalTechAccel
	data.defensePool = saveData.defensePool
	data.defenseQuota = saveData.defenseQuota
	
	data.humanAggro = saveData.humanAggro
	data.humanAggroDelta = saveData.humanAggroDelta
	data.humanAggroPerWave = saveData.humanAggroPerWave
	
	data.endgame = saveData.endgame
	data.victory = saveData.victory
	data.endMiniQueenNum = saveData.endMiniQueenNum
	
	data.morphFrame = saveData.morphFrame - gameFrameOffset
	data.morphed = saveData.morphed
	data.specialPowerCooldown = saveData.specialPowerCooldown
	
	Spring.SetGameRulesParam("queenTime", data.queenTime)
	_G.chickenEventArgs = {type="refresh"}
	SendToUnsynced("ChickenEvent")
	_G.chickenEventArgs = nil
end

function gadget:Initialize()
	Spring.SetGameRulesParam("malus", malus)
	Spring.SetGameRulesParam("lagging", 0)
	Spring.SetGameRulesParam("techAccel", 0)
	Spring.SetGameRulesParam("queenTime", data.queenTime)
	Spring.SetGameRulesParam("humanAggro", 0)
	Spring.SetGameRulesParam("difficulty", difficulty)

	for unitName in pairs(chickenTypes) do
		SetupUnit(unitName)
	end

	for unitName in pairs(defenders) do
		SetupUnit(unitName)
	end

	for unitName in pairs(supporters) do
		SetupUnit(unitName)
	end

	SetupUnit(burrowName)
	SetupUnit(queenName)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
else
-- END SYNCED
-- BEGIN UNSYNCED
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function WrapToLuaUI()
	if (Script.LuaUI('ChickenEvent')) then
		local chickenEventArgs = {}
		for k, v in spairs(SYNCED.chickenEventArgs) do
			chickenEventArgs[k] = v
		end
		Script.LuaUI.ChickenEvent(chickenEventArgs)
	end
end


function gadget:Initialize()
	gadgetHandler:AddSyncAction('ChickenEvent', WrapToLuaUI)
end

function gadget:Save(zip)
	if not GG.SaveLoad then
		Spring.Log(gadget:GetInfo().name, LOG.ERROR, "ERROR: Chicken Spawner failed to access save/load API")
		return
	end
	
	local chickenTable = SYNCED.data
	chickenTable = Spring.Utilities.MakeRealTable(chickenTable, "Chicken")
	GG.SaveLoad.WriteSaveData(zip, SAVE_FILE, chickenTable)
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
end
-- END UNSYNCED
--------------------------------------------------------------------------------

