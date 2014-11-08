function gadget:GetInfo()
  return {
    name      = "StartSetup",
    desc      = "Implements initial setup: start units, resources, boost and plop for construction",
    author    = "Licho, CarRepairer, Google Frog, SirMaverick",
    date      = "2008-2010",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end


-- partially based on Spring's unit spawn gadget
include "LuaRules/Configs/start_setup.lua"

if VFS.FileExists("mission.lua") then -- this is a mission, we just want to set starting storage (and enable facplopping)
  if not gadgetHandler:IsSyncedCode() then
    return false -- no unsynced code
  end

  local facplops = {}
  local ploppableDefs = {}  
    
  GG.SetFaction = function() end
  
  function gadget:Initialize()
    for _, teamID in ipairs(Spring.GetTeamList()) do
      Spring.SetTeamResource(teamID, "es", START_STORAGE + OVERDRIVE_BUFFER)
      Spring.SetTeamResource(teamID, "ms", START_STORAGE)
    end
    for i, v in pairs(ploppables) do
      local name = UnitDefNames[v]
      if name then
        local ud = name.id
        if ud then
          ploppableDefs[ud] = true
        end
      end
    end
    if(Spring.GetModOption("air_ploppable", true, true)) then
	    for i, v in pairs(air_ploppables) do
	      local name = UnitDefNames[v]
	      if name then
		    local ud = name.id
		    if ud then
		      ploppableDefs[ud] = true
		    end
	      end
	    end
    end
  end
  
  function GG.GiveFacplop(unitID)
    if dotaMode then return end
    facplops[unitID] = 1
    Spring.SetUnitRulesParam(unitID,"facplop",1, {inlos = true})
  end
  
  function GG.HasFacplop(unitID)
    return plop and facplops[unitID]
  end
  
  function GG.SetStartLocation() end
  
  function gadget:UnitCreated(unitID, unitDefID, teamID, builderID)
    if ploppableDefs[unitDefID] and facplops[builderID] then
      facplops[builderID] = nil
      Spring.SetUnitRulesParam(builderID,"facplop",0, {inlos = true})
      local maxHealth = select(2,Spring.GetUnitHealth(unitID))
      Spring.SetUnitHealth(unitID, {health = maxHealth, build = 1})
      local x,y,z = Spring.GetUnitPosition(unitID)
      Spring.SpawnCEG("gate", x, y, z)
    end
  end
  
  return
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local spGetTeamInfo 		= Spring.GetTeamInfo
local spGetPlayerInfo 		= Spring.GetPlayerInfo
local spGetSpectatingState 	= Spring.GetSpectatingState

local modOptions = Spring.GetModOptions()
local startMode = Spring.GetModOption("startingresourcetype",false,"facplop")


if (startMode == "limitboost") then
	for udid, ud in pairs(UnitDefs) do
		if ud.canAttack and not ud.isFactory then
			EXCLUDED_UNITS[udid] = true
		end
	end
end

local plop = false
if startMode == "facplop" or startMode == "facplopboost" then
  plop = true
end

local shuffleMode = Spring.GetModOption("shuffle", false, "off")

local coop = Spring.Utilities.tobool(Spring.GetModOption("coop", false, false))
local dotaMode = Spring.GetModOptions().zkmode == "dota"
local ctfMode = Spring.GetModOptions().zkmode == "ctf"
local playerChickens = Spring.Utilities.tobool(Spring.GetModOption("playerchickens", false, false))

--Spring.Echo(coop == 1, coop == 0)

local gaiateam = Spring.GetGaiaTeamID()
local gaiaally = select(6, spGetTeamInfo(gaiateam))

local SAVE_FILE = "Gadgets/start_unit_setup.lua"

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

if (gadgetHandler:IsSyncedCode()) then
  
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local boost = {}
local boostMax = {}

local facplops = {}
local ploppableDefs = {}
local facplopsrunning = {}

local gamestart = false
--local createBeforeGameStart = {}	-- no longer used
local scheduledSpawn = {}
local startPosition = {} -- [teamID] = {x, y, z}
local shuffledStartPosition = {}
local luaSetStartPositions = {}
local playerSides = {} -- sides selected ingame from widget  - per players
local teamSides = {} -- sides selected ingame from widgets - per teams
local teamSidesAI = {} 

local playerIDsByName = {}
local customComms = {}
local commChoice = {}
local customKeys = {}	-- [playerID] = {}

--local prespawnedCommIDs = {}	-- [teamID] = unitID

GG.startUnits = {}
GG.CommanderSpawnLocation = {}

local waitingForComm = {}
GG.waitingForComm = waitingForComm

-- overlaps with the rulesparam
local commSpawnedTeam = {}
local commSpawnedPlayer = {}

-- allow gadget:Save (unsynced) to reach them
_G.facplops = facplops
_G.waitingForComm = waitingForComm
_G.scheduledSpawn = scheduledSpawn
_G.playerSides = playerSides
_G.teamSides = teamSides
_G.teamSidesAI = teamSidesAI
_G.commSpawnedTeam = commSpawnedTeam
_G.commSpawnedPlayer = commSpawnedPlayer

local loadGame = false	-- was this loaded from a savegame?

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function AddBoost(unitID, newBoost, newBoostMax)
	boost[unitID]  = newBoost or START_STORAGE
	boostMax[unitID] = newBoostMax or START_STORAGE
	SendToUnsynced("UpdateBoost", unitID, boost[unitID], boostMax[unitID])   
end

-- TODO: do for boost
function GG.HasFacplop(unitID)
	return plop and facplops[unitID]
end

function GG.GiveFacplop(unitID)
	if dotaMode then return end
	facplops[unitID] = 1
	Spring.SetUnitRulesParam(unitID,"facplop",1, {inlos = true})
end

local function CheckForShutdown()
	if dotaMode or ctfMode then
	    return
	end
	
	local cnt = 0
	--for _,_ in pairs(boost) do
	--	cnt = cnt+1
	--end
	for _,_ in pairs(facplops) do
		cnt = cnt+1
	end
	for team,_ in pairs(waitingForComm) do
		cnt = cnt+1
	end
	if (cnt == 0) and Spring.GetGameSeconds() > 5 then
		gadgetHandler.RemoveGadget(self)
	end
end

function gadget:UnitCreated(unitID, unitDefID, teamID, builderID)
	--[[
	if not gamestart then
		createBeforeGameStart[#createBeforeGameStart + 1] = unitID

		-- make units blind, so that you don't see shuffled units
		Spring.SetUnitSensorRadius(unitID,"los",0)
		Spring.SetUnitSensorRadius(unitID,"airLos",0)
		Spring.SetUnitCloak(unitID, 4)
		Spring.SetUnitStealth(unitID, true)
		Spring.SetUnitNoDraw(unitID, true)
		Spring.SetUnitNoSelect(unitID, true)
		Spring.SetUnitNoMinimap(unitID, true)
		return
	end
	]]--

	if plop and ploppableDefs[unitDefID] and facplops[builderID] then
		facplops[builderID] = nil
		Spring.SetUnitRulesParam(builderID,"facplop",0, {inlos = true})
		local maxHealth = select(2,Spring.GetUnitHealth(unitID))
		Spring.SetUnitHealth(unitID, {health = maxHealth, build = 1 })
		local x,y,z = Spring.GetUnitPosition(unitID)
		Spring.SpawnCEG("gate", x, y, z)
		
		-- remember to plop, can't do it here else other gadgets etc. see UnitFinished before UnitCreated
		--facplopsrunning[unitID] = true
		CheckForShutdown()
	end
end



function gadget:UnitDestroyed(unitID)
	if plop then
		facplops[unitID] = nil
		--facplopsrunning[unitID] = nil
	end
	
	--if (boost[unitID] == nil) then return end

	--if gamestart then disableBoost(unitID) end
end


function gadget:UnitFinished(unitID, unitDefID)
	if plop and facplopsrunning[unitID] then
		facplopsrunning[unitID] = nil
		-- reset to original costs
		Spring.SetUnitCosts(unitID, {
			buildTime = UnitDefs[unitDefID].buildTime,
			metalCost = UnitDefs[unitDefID].metalCost,
			energyCost = UnitDefs[unitDefID].energyCost
		})
	end
end

function disableBoost(unitID) 
	boost[unitID] = nil
	CheckForShutdown()
end

--[[
function gadget:AllowUnitBuildStep(builderID, teamID, unitID, unitDefID, step) 
	if plop and facplopsrunning[unitID] then
		return true -- dont waste boost on facplops
	elseif (boost[builderID]) and (not EXCLUDED_UNITS[unitDefID]) and (step>0) then
		local cost = UnitDefs[unitDefID].metalCost
		local oldHealth, maxHealth, _, _, oldProgress = Spring.GetUnitHealth(unitID)
		if (boost[builderID] > BOOST_RATE) then 
			local progress  = oldProgress + BOOST_RATE / cost
			if (progress > 1) then progress = 1 end
			local newHealth = oldHealth + (BOOST_RATE / cost)*maxHealth
			if (newHealth > maxHealth) then newHealth = maxHealth end
			boost[builderID] = boost[builderID] - BOOST_RATE
			Spring.SetUnitHealth(unitID, { health = newHealth,  build  = progress })
			SendToUnsynced("UpdateBoost", builderID, boost[builderID], boostMax[builderID])   
			return false
		else 
			disableBoost(builderID)
		end
	end
	return true
end
]]


local function InitUnsafe()
	-- for name, id in pairs(playerIDsByName) do
	for index, id in pairs(Spring.GetPlayerList()) do	
		-- copied from PlanetWars
		local commData, success
		customKeys[id] = select(10, spGetPlayerInfo(id))
		local commDataRaw = customKeys[id] and customKeys[id].commanders
		if not (commDataRaw and type(commDataRaw) == 'string') then
			err = "Comm data entry for player "..id.." is empty or in invalid format"
			commData = {}
		else
			commDataRaw = string.gsub(commDataRaw, '_', '=')
			commDataRaw = Spring.Utilities.Base64Decode(commDataRaw)
			--Spring.Echo(commDataRaw)
			local commDataFunc, err = loadstring("return "..commDataRaw)
			if commDataFunc then 
				success, commData = pcall(commDataFunc)
				if not success then
					err = commData
					commData = {}
				end
			end
		end
		if err then 
			Spring.Log(gadget:GetInfo().name, LOG.WARNING, 'Start Unit Setup warning: ' .. err)
		end

		-- record the player's first-level comm def for each chassis
		for commSeries, subdata in pairs(commData) do
			customComms[id] = customComms[id] or {}
			customComms[id][commSeries] = subdata[1]
			--Spring.Echo(id,"comm"..chassis, subdata[1])
		end
		
		-- this method makes no sense, it's not like any given generated def will be used for more than one replacement/player!
		-- would be more logical to use replacee as key and replacement as value in player customkeys
		--[[
		customComms[id] = customComms[id] or {}
		for replacementComm, replacees in pairs(commData) do
			for _,name in pairs(replacees) do
				customComms[id][name] = replacementComm
			end
		end
		]]--
	end
end


function gadget:Initialize()
  -- self linking
  --GG['boostHandler'] = {}
  --GG['boostHandler'].AddBoost = AddBoost

  if plop then
    for i, v in pairs(ploppables) do
      local name = UnitDefNames[v]
      if name then
        local ud = name.id
        if ud then
          ploppableDefs[ud] = true
        end
      end
    end
    if(Spring.GetModOption("air_ploppable", true, true)) then
	    for i, v in pairs(air_ploppables) do
	      local name = UnitDefNames[v]
	      if name then
		    local ud = name.id
		    if ud then
		      ploppableDefs[ud] = true
		    end
	      end
	    end
    end
  end

  -- needed if you reload luarules
  local frame = Spring.GetGameFrame()
  if frame and frame > 0 then
    gamestart = true
	Shuffle()
  end
  
  InitUnsafe()
  local allUnits = Spring.GetAllUnits()
  for _, unitID in pairs(allUnits) do
	local udid = Spring.GetUnitDefID(unitID)
	if udid then
		gadget:UnitCreated(unitID, udid, Spring.GetUnitTeam(unitID))
	end
  end
  
  -- legacy save/load compat
  --[[
  local teams = Spring.GetTeamList()
  for i=1,#teams do
	if Spring.GetGameRulesParam("commSpawnedTeam"..teams[i]) == 1 then
		commSpawnedTeam[teams[i] ] = true
	end
  end
  local players = Spring.GetPlayerList()
  for i=1,#players do
	if Spring.GetGameRulesParam("commSpawnedPlayer"..players[i]) == 1 then
		commSpawnedPlayer[players[i] ] = true
	end  
  end
  ]]--
end

local forcejunior = Spring.GetModOption("forcejunior", true, false)

local function GetStartUnit(teamID, playerID, isAI)

  if forcejunior then return "commbasic" end
  
  local startUnit

  if isAI and (not teamSidesAI[teamID]) then -- AI that didn't pick comm type gets default comm
    teamSidesAI[teamID] = "armcom1"
  end
  
  if teamSidesAI[teamID] then 
	return startUnitsAI[teamSidesAI[teamID]]
  end
  
  if (teamID and teamSides[teamID]) then 
	startUnit = startUnits[teamSides[teamID]]
  end

  if (playerID and playerSides[playerID]) then 
	startUnit = startUnits[playerSides[playerID]]
  end
  
  -- if a replacement def is available, use it  
  playerID = playerID or (teamID and select(2, spGetTeamInfo(teamID)) )
  if (playerID and commChoice[playerID]) then
	--Spring.Echo("Attempting to load alternate comm")
	local altComm = customComms[playerID][(commChoice[playerID])]
	startUnit = (altComm and UnitDefNames[altComm] and altComm) or startUnit
  end
  
  -- hack workaround for chicken
  --local luaAI = Spring.GetTeamLuaAI(teamID)
  --if luaAI and string.find(string.lower(luaAI), "chicken") then startUnit = nil end
  
  --if didn't pick a comm, wait for user to pick
  return startUnit or nil	-- startUnit or DEFAULT_UNIT
end


local function GetFacingDirection(x, z, teamID)
	local facing = "south"

	local allyCount = #Spring.GetAllyTeamList()
	if (allyCount ~= 2+1) then -- +1 cause of gaia
		-- face to map center
		facing = (math.abs(Game.mapSizeX/2 - x) > math.abs(Game.mapSizeZ/2 - z))
			and ((x>Game.mapSizeX/2) and "west" or "east")
			or ((z>Game.mapSizeZ/2) and "north" or "south")
	else
		local allyID = select(6, spGetTeamInfo(teamID))
		local enemyAllyID = gaiaally

		-- detect enemy allyid
		local allyList = Spring.GetAllyTeamList()
		for i=1,#allyList do
			if (allyList[i] ~= allyID)and(allyList[i] ~= gaiaally) then
				enemyAllyID = allyList[i]
				break
			end
		end
		assert(enemyAllyID ~= gaiaally, "couldn't detect enemy ally id!")

		-- face to enemy
		local enemyStartbox = {Spring.GetAllyTeamStartBox(enemyAllyID)}
		local midPosX = (enemyStartbox[1] + enemyStartbox[3]) * 0.5
		local midPosZ = (enemyStartbox[2] + enemyStartbox[4]) * 0.5

		local dirX = midPosX - x
		local dirZ = midPosZ - z

		if (math.abs(dirX) > math.abs(dirZ)) then --distance in X direction is greater than distance in Z direction?
			facing = (dirX < 0)and("west")or("east") --is distance (X) in negative direction? (left?)
		else --if distance in Z direction is greater, then:
			facing = (dirZ > 0)and("south")or("north") --is distance (Z) in positive direction? (down?)
		end
	end

	return facing
end

local function getMiddleOfStartBox(teamID)
	local allyTeam = select(6, spGetTeamInfo(teamID))
	local x1, z1, x2, z2 = Spring.GetAllyTeamStartBox(allyTeam)
	
	local x = x1 + (x2 - x1)*0.5
	local z = z1 + (z2 - z1)*0.5
	local y = Spring.GetGroundHeight(x,z)

	return x, y, z
end


local function SpawnStartUnit(teamID, playerID, isAI, bonusSpawn, notAtTheStartOfTheGame)
  local luaAI = Spring.GetTeamLuaAI(teamID)
  if luaAI and string.find(string.lower(luaAI), "chicken") then
    return false
  elseif playerChickens then
    -- allied to latest chicken team? no com for you
    local chickenTeamID = -1
    for _,t in pairs(Spring.GetTeamList()) do
      local luaAI = Spring.GetTeamLuaAI(t)
      if luaAI and string.find(string.lower(luaAI), "chicken") then
	chickenTeamID = t
      end
    end
    if (chickenTeamID > -1) and (Spring.AreTeamsAllied(teamID,chickenTeamID)) then
      --Spring.Echo("chicken_control detected no com for "..playerID)
      return false
    end
  end
  
  -- get start unit
  local startUnit = GetStartUnit(teamID, playerID, isAI)
  
  if ((coop and playerID and commSpawnedPlayer[playerID]) or (not coop and commSpawnedTeam[teamID]))
  and not bonusSpawn then
    return false
  end

  if bonusSpawn then
  	--startUnit = DEFAULT_UNIT
  end
  
  local keys = customKeys[playerID] or customKeys[select(2, spGetTeamInfo(teamID))]
  if keys and keys.jokecomm then
	startUnit = DEFAULT_UNIT
  end    
  
  if startUnit then
    -- replace with shuffled position
	local startPosition = luaSetStartPositions[teamID] or shuffledStartPosition[teamID]
	local x,y,z = startPosition.x, startPosition.y, startPosition.z

	if notAtTheStartOfTheGame and Game.startPosType == 2 then
		x, y, z = getMiddleOfStartBox(teamID)
	end
	
    -- get facing direction
    local facing = GetFacingDirection(x, z, teamID)

	GG.startUnits[teamID] = startUnit
	GG.CommanderSpawnLocation[teamID] = {x = x, y = y, z = z, facing = facing}
	
    -- CREATE UNIT
	local unitID
    --if Spring.GetGameFrame() <= 1 then
	--	unitID = Spring.CreateUnit(startUnit, x, y, z, facing, teamID)
	--else
		unitID = GG.DropUnit(startUnit, x, y, z, facing, teamID)
	--end
	if Spring.GetGameFrame() <= 1 then Spring.SpawnCEG("teleport_in", x, y, z) end
	
	if not bonusSpawn then
		Spring.SetTeamRulesParam(teamID, "commSpawned", 1, {allied = true})
		commSpawnedTeam[teamID] = true
		if playerID then
		  Spring.SetGameRulesParam("commSpawnedPlayer"..playerID, 1, {allied = true})
		  commSpawnedPlayer[playerID] = true 
		end
		waitingForComm[teamID] = nil
	end
	
    -- set the *team's* lineage root
    if Spring.SetUnitLineage then
      Spring.SetUnitLineage(unitID, teamID, true)
    end

    -- add boost and facplop
    local teamLuaAI = Spring.GetTeamLuaAI(teamID)
    local udef = UnitDefs[Spring.GetUnitDefID(unitID)]

    local validTeam = (teamID ~= gaiateam and ((not teamLuaAI) or teamLuaAI == "" or teamLuaAI:sub(1,3) == "CAI"))
    local boost = (startMode == "boost"
                or startMode == "limitboost"
                or startMode == "facplopboost")

	local commCost = (udef.metalCost or BASE_COMM_COST) - BASE_COMM_COST			
				
    if validTeam then

	  local metal, metalStore = Spring.GetTeamResources(teamID, "metal")
	  local energy, energyStore = Spring.GetTeamResources(teamID, "energy")
		
      if boost then
        Spring.SetTeamResource(teamID, 'energy', 0)
        Spring.SetTeamResource(teamID, 'metal', 0)
		Spring.SetTeamResource(teamID, "es", START_STORAGE + energyStore)
		Spring.SetTeamResource(teamID, "ms", START_STORAGE + metalStore)		
		local boostAmount = START_BOOST + BASE_COMM_COST - commCost
		
        if (udef.name ~= "chickenbroodqueen") then
          if (startMode == "facplopboost") then
            AddBoost(unitID, boostAmount, boostAmount)
          elseif (startMode == "boost") then
            AddBoost(unitID, boostAmount, boostAmount)
          else
            AddBoost(unitID)
          end
        end

      else
		-- the adding of existing resources is necessary for handling /take and spawn
		local bonus = (keys and tonumber(keys.bonusresources)) or 0
		
        if startMode == "classic" then
          Spring.SetTeamResource(teamID, "es", START_STORAGE_CLASSIC + energyStore + bonus)
          Spring.SetTeamResource(teamID, "ms", START_STORAGE_CLASSIC + metalStore + bonus)
          Spring.SetTeamResource(teamID, "energy", START_STORAGE_CLASSIC + energy - commCost + bonus)
          Spring.SetTeamResource(teamID, "metal", START_STORAGE_CLASSIC + metal - commCost + bonus)
        elseif startMode == "facplop" then
          Spring.SetTeamResource(teamID, "es", START_STORAGE_FACPLOP + energyStore  + bonus)
          Spring.SetTeamResource(teamID, "ms", START_STORAGE_FACPLOP + metalStore + bonus)
          Spring.SetTeamResource(teamID, "energy", START_ENERGY_FACPLOP + energy - commCost + bonus)
          Spring.SetTeamResource(teamID, "metal", START_METAL_FACPLOP + metal - commCost + bonus)		  
        else
		  Spring.SetTeamResource(teamID, "es", START_STORAGE + energyStore)
		  Spring.SetTeamResource(teamID, "ms", START_STORAGE + metalStore)		
          Spring.SetTeamResource(teamID, "energy", START_STORAGE + energy - commCost + bonus)
          Spring.SetTeamResource(teamID, "metal", START_STORAGE + metal - commCost + bonus)
        end

      end

      if (udef.customParams.level and udef.name ~= "chickenbroodqueen") then
        if plop then
		  GG.GiveFacplop(unitID)
        end
      end

    end

    return true
  end
  return false
end

local function StartUnitPicked(playerID, name)
	local _,_,spec,teamID = spGetPlayerInfo(playerID)
	if spec then return end
	teamSides[teamID] = name
	local startUnit = GetStartUnit(teamID, playerID)
	if startUnit then
		Spring.SetTeamRulesParam(teamID, "commChoice", UnitDefNames[startUnit].id)
	end
	if gamestart then
		-- picked commander after game start, prep for orbital drop
		-- can't do it directly because that's an unsafe change
		local frame = Spring.GetGameFrame() + 3
		if not scheduledSpawn[frame] then scheduledSpawn[frame] = {} end
		scheduledSpawn[frame][#scheduledSpawn[frame] + 1] = {teamID, playerID}
	else
		--[[
		if startPosition[teamID] then
			local oldCommID = prespawnedCommIDs[teamID]
			local pos = startPosition[teamID]
			local startUnit = GetStartUnit(teamID, playerID, isAI)
			if startUnit then
				local newCommID = Spring.CreateUnit(startUnit, pos.x, pos.y, pos.z , "s", 0)
				if oldCommID then
					local cmds = Spring.GetCommandQueue(oldCommID, -1)
					--//transfer command queue
					for i = 1, #cmds do
						local cmd = cmds[i]
						Spring.GiveOrderToUnit(newUnit, cmd.id, cmd.params, cmd.options.coded)
					end
					Spring.DestroyUnit(oldCommID, false, true)
				end
				prespawnedCommIDs[teamID] = newCommID
			end
		end
		]]
	end
	GG.startUnits[teamID] = GetStartUnit(teamID) -- ctf compatibility
end

-- {[1] = 1, [2] = 3, [3] = 4} -> {[3] = 1, [1] = 4, [4] = 3}
local function ShuffleSequence(nums)
  local seq, shufseq = {}, {}
  for i = 1, #nums do
    seq[i] = {nums[i], math.random()}
  end
  table.sort(seq, function(a,b) return a[2] < b[2] end)
  for i = 1, #nums do
    shufseq[nums[i]] = seq[i][1]
  end
  return shufseq
end

function GetAllTeamsList()
  teamList = {}
  -- create list with all teams
  for _, alliance in ipairs(Spring.GetAllyTeamList()) do
    if alliance ~= gaiaally then
      local teams = Spring.GetTeamList(alliance)
      for _, team in ipairs(teams) do
        teamList[#teamList + 1] = team
      end
    end
  end
  return teamList
end

function Shuffle()
  -- setup startpos
  local teamIDs = Spring.GetTeamList()
  for i=1,#teamIDs do
    teamID = teamIDs[i]
    if teamID ~= gaiateam then
      local x, y, z = Spring.GetTeamStartPosition(teamID)
      startPosition[teamID] = {x=x, y=y, z=z}
      shuffledStartPosition[teamID] = startPosition[teamID]
    end
  end

  if (not shuffleMode) or (shuffleMode and shuffleMode == "off") then
    -- nothing to do

  elseif shuffleMode then

    if shuffleMode == "box" then
 
     -- shuffle for each alliance
      for _, alliance in ipairs(Spring.GetAllyTeamList()) do
        if alliance ~= gaiaally then
          local teamList = Spring.GetTeamList(alliance)
          local shuffled = ShuffleSequence(teamList)
          for _, team in ipairs(teamList) do
            shuffledStartPosition[team] = startPosition[shuffled[team]]
          end
        end

      end

    elseif shuffleMode == "all" then

      teamList = GetAllTeamsList()
      -- shuffle
      local shuffled = ShuffleSequence(teamList)
      for _, team in ipairs(teamList) do
        shuffledStartPosition[team] = startPosition[shuffled[team]]
      end      

    elseif shuffleMode == "allboxes" then

      teamList = GetAllTeamsList()
      boxPosition = {}
      --[[ Spring will replace a missing box by adding one covering the whole map.
           So if two or more boxes are missing, serveral commanders will be placed
           in the middle of the map. ]]
      -- get box middle positions
      for _,a in ipairs(Spring.GetAllyTeamList()) do
        if a ~= gaiaally then
          local xmin, zmin, xmax, zmax = Spring.GetAllyTeamStartBox(a)
          local xmid = (xmax + xmin) / 2
          local zmid = (zmax + zmin) / 2
          local ymid = Spring.GetGroundHeight(xmid, zmid)
          local i = #boxPosition + 1
          boxPosition[i] = {xmid, ymid, zmid}
          --teamList[i] = i - 1 -- team number starts at 0
        end
      end

      if #boxPosition >= #teamList then
        -- shuffle all positions, use first #teamList positions to shuffle teams
        local nums = {}
        for i=1,#boxPosition do
          nums[#nums + 1] = i
        end
        local shuffledNums = ShuffleSequence(nums)
        for i=1,#teamList do
          startPosition[teamList[i]] = boxPosition[shuffledNums[nums[i]]]
        end

        -- shuffle
        local shuffled = ShuffleSequence(teamList)
        teamList = GetAllTeamsList()
        for _, team in ipairs(teamList) do
          shuffledStartPosition[team] = startPosition[shuffled[team]]
        end
      else
        Spring.Echo("Not enough boxes. Teams not shuffled.")
      end

    end
  end
end

--[[
   spring puts all specs on team 0, so we have to check if team 0 is
   a team with players or a ai team with specs
   if team 0 is ai team with only specs, nil is returned else
   this functions returns the playerlist unchanged
--]]
local function workAroundSpecsInTeamZero(playerlist, team)
  if team == 0 then
    local players = #playerlist
    local specs = 0
    -- count specs
    for i=1,#playerlist do
      local _,_,spec = spGetPlayerInfo(playerlist[i])
      if spec then specs = specs + 1 end
    end
    if players == specs then
      return nil
    end
  end
  return playerlist
end

function gadget:GameStart()
	if Spring.Utilities.tobool(Spring.GetGameRulesParam("loadedGame")) then
		return
	end
  gamestart = true

  -- shuffle start unit positions
  Shuffle()

  -- spawn units
  for i,team in ipairs(Spring.GetTeamList()) do

    -- clear resources
    -- actual resources are set depending on spawned unit and setup
	if not loadGame then
		Spring.SetTeamResource(team, "es", 0 + OVERDRIVE_BUFFER)
		Spring.SetTeamResource(team, "ms", 0)
		Spring.SetTeamResource(team, "energy", 0)
		Spring.SetTeamResource(team, "metal", 0)
	end
	

    if team ~= gaiateam then
	  local luaAI = Spring.GetTeamLuaAI(team)
	  if luaAI and string.find(string.lower(luaAI), "chicken") then
	  else
		waitingForComm[team] = true
	  end
      if coop then
        -- 1 start unit per player
        local playerlist = Spring.GetPlayerList(team, true)
        playerlist = workAroundSpecsInTeamZero(playerlist, team)
        if playerlist and (#playerlist > 0) then
          for i=1,#playerlist do
          	local _,_,spec = spGetPlayerInfo(playerlist[i])
            if (not spec) then
              SpawnStartUnit(team, playerlist[i])
            end
          end
        else
          -- AI etc.
          SpawnStartUnit(team, nil, true)
        end
      else -- no coop
        local _,playerID,_,isAI = spGetTeamInfo(team)
        if (playerID) then
          local _,_,spec,teamID = spGetPlayerInfo(playerID)
          if (teamID == team and not spec) then
            isAI = false
          else
            playerID = nil
          end
        end
        
        SpawnStartUnit(team, playerID, isAI)
      end
	  
	  -- extra comms
	  local playerlist = Spring.GetPlayerList(team, true)
      playerlist = workAroundSpecsInTeamZero(playerlist, team)
      if playerlist then
        for i=1,#playerlist do
			if customKeys[playerlist[i]] and customKeys[playerlist[i]].extracomm then
				for j=1, tonumber(customKeys[playerlist[i]].extracomm) do
					SpawnStartUnit(team, playerlist[i], false, true)
				end
			end
        end
      end
    end
  end
  
  -- kill units if engine spawned
  --[[
  for i,u in ipairs(createBeforeGameStart) do
    Spring.DestroyUnit(u, false, true) -- selfd = false, reclaim = true
  end
  ]]--
end

function gadget:RecvLuaMsg(msg, playerID)
	if msg:find("faction:",1,true) then
		local side = msg:sub(9)
		playerSides[playerID] = side
		commChoice[playerID] = nil	-- unselect existing custom comm, if any
		StartUnitPicked(playerID, side)
	elseif msg:find("customcomm:",1,true) then
		local name = msg:sub(12)
		SendToUnsynced("CommSelected",playerID, name) --activate an event called "CommSelected" that can be detected in unsynced part
		commChoice[playerID] = name
		StartUnitPicked(playerID, name)
	--[[
	elseif (msg:find("<startsetup>playername:",1,true)) then
		local name = msg:gsub('.*:([^=]*)=.*', '%1')
		local id = msg:gsub('.*:.*=(.*)', '%1')
		playerIDsByName[name] = tonumber(id)
	elseif (msg:find("<startsetup>playernames",1,true)) then
		InitUnsafe()
		local allUnits = Spring.GetAllUnits()
		for _, unitID in pairs(allUnits) do
			local udid = Spring.GetUnitDefID(unitID)
			if udid then
				gadget:UnitCreated(unitID, udid, Spring.GetUnitTeam(unitID))
			end
		end]]--
	end	
end

--[[
function gadget:AllowStartPosition(cx, cy, cz, playerID, readyState, rx, ry, rz)
	local teamID = select(4, spGetPlayerInfo(playerID))
	startPosition[teamID] = {x = cx, y = cy, z = cz}
	local oldCommID = prespawnedCommIDs[teamID]
	if oldCommID then
		Spring.SetUnitPosition(oldCommID, cx, cz)
	end
	return true
end
]]

-- (no longer) used by CAI
local function SetFaction(side, playerID, teamID)
    teamSidesAI[teamID] = side
	teamSides[teamID] = side
	if playerID then
		--playerSides[playerID] = side
	end
end
GG.SetFaction = SetFaction

-- used by CAI. Could be extended to allow widgets to set start location? 
local function SetStartLocation(teamID, x, z)
    luaSetStartPositions[teamID] = {x = x, y = Spring.GetGroundHeight(x,z), z = z}
end
GG.SetStartLocation = SetStartLocation

function gadget:GameFrame(n)
  if n == (COMM_SELECT_TIMEOUT) then
	for team in pairs(waitingForComm) do
		local _,playerID = spGetTeamInfo(team)
		teamSides[team] = DEFAULT_UNIT_TEAMSIDES
		--playerSides[playerID] = "basiccomm"
		scheduledSpawn[n] = scheduledSpawn[n] or {}
		scheduledSpawn[n][#scheduledSpawn[n] + 1] = {team, playerID} -- playerID is needed here so the player can't spawn coms 2 times in coop mode
	end
  end
  if scheduledSpawn[n] then
	for _, spawnData in pairs(scheduledSpawn[n]) do
    local teamID, playerID = spawnData[1], spawnData[2]
    local canSpawn = SpawnStartUnit(teamID, playerID, false, false, true)
    
    if (canSpawn) then
      -- extra comms
      if playerID and customKeys[playerID] and customKeys[playerID].extracomm then
        for j=1, tonumber(customKeys[playerID].extracomm) do
          SpawnStartUnit(teamID, playerID, false, true, true)
        end
      end
    end
	end
	scheduledSpawn[n] = nil
  end
end

function gadget:Shutdown()
	--Spring.Echo("<Start Unit Setup> Going to sleep...")
end


function gadget:Load(zip)
	if not GG.SaveLoad then
		Spring.Log(gadget:GetInfo().name, LOG.ERROR, "Start Unit Setup failed to access save/load API")
		return
	end
	loadGame = true
	local data = GG.SaveLoad.ReadFile(zip, "Start Unit Setup", SAVE_FILE) or {}

	-- load data wholesale
	waitingForComm = data.waitingForComm or {}
	scheduledSpawn = data.scheduledSpawn or {}
	playerSides = data.playerSides or {}
	teamSides = data.teamSides or {}
	teamSidesAI = data.teamSidesAI or {}
	commSpawnedPlayer = data.commSpawnedPlayer or {}
	commSpawnedTeam = data.commSpawnedTeam or {}
	boost = data.boost
	facplops = data.facplops
	
	--[[
	-- these require special handling because they involve unitIDs
	for oldID in pairs(data.boost) do
		newID = GG.SaveLoad.GetNewUnitID(oldID)
		boost[newID] = true
	end
	for oldID in pairs(data.facplops) do
		newID = GG.SaveLoad.GetNewUnitID(oldID)
		GG.GiveFacplop(newID)
	end
	]]
end

--------------------------------------------------------------------
-- unsynced code
--------------------------------------------------------------------
else

local teamID 			= Spring.GetLocalTeamID()
local spGetUnitDefID 	= Spring.GetUnitDefID
local spGetUnitLosState = Spring.GetUnitLosState
local spValidUnitID 	= Spring.ValidUnitID
local spAreTeamsAllied 	= Spring.AreTeamsAllied
local spGetUnitTeam 	= Spring.GetUnitTeam

local boost = {}
local boostMax = {}

function gadget:Initialize()
  gadgetHandler:AddSyncAction("UpdateBoost",UpdateBoost)
  gadgetHandler:AddSyncAction('CommSelected',CommSelection) --Associate "CommSelected" event to "WrapToLuaUI". Reference: http://springrts.com/phpbb/viewtopic.php?f=23&t=24781 "Gadget and Widget Cross Communication"
--[[
--  gadgetHandler:AddSyncAction('PWCreate',WrapToLuaUI)
--  gadgetHandler:AddSyncAction("whisper", whisper)
  
	local playerroster = Spring.GetPlayerList()
	local playercount = #playerroster
	for i=1,playercount do
		local name = spGetPlayerInfo(playerroster[i])
		Spring.SendLuaRulesMsg('<startsetup>playername:'..name..'='..playerroster[i])
	end
	Spring.SendLuaRulesMsg('<startsetup>playernames')
end
]]--  
end
  

function CommSelection(_,playerID,commSeries)
	if (Script.LuaUI('CommSelection')) then --if there is widgets subscribing to "CommSelection" function then:
		local isSpec = Spring.GetSpectatingState() --receiver player is spectator?
		local myAllyID = Spring.GetMyAllyTeamID() --receiver player's alliance?
		local _,_,_,_, eventAllyID,_,_,_,_ = Spring.GetPlayerInfo(playerID) --source alliance?
		if isSpec or myAllyID == eventAllyID then
			Script.LuaUI.CommSelection(playerID, commSeries) --send to widgets as event
		end
	end
end  
  
function UpdateBoost(_, uid, value, valueMax) 
	boost[uid] = value
	boostMax[uid] = valueMax
end
  
  
local function circleLines(percentage, radius)
	gl.BeginEnd(GL.LINE_STRIP, function()
		local radstep = (2.0 * math.pi) / 50
		for i = 0, 50 * percentage do
			local a = (i * radstep)
			gl.Vertex(math.sin(a)*radius, 0, math.cos(a)*radius)
		end
	end)
end  

function gadget:DrawWorldPreUnit()
	if Spring.IsGUIHidden() then return end
	teamID = Spring.GetLocalTeamID()
	local spec, fullview = spGetSpectatingState()
	spec = spec or fullview
	for unitID, value in pairs(boost) do
		local ut = spGetUnitTeam(unitID)
		if (ut ~= nil and (spec or spAreTeamsAllied(teamID, ut))) then
			if (value > 0 and boostMax[unitID] ~= nil) then 
				gl.DepthTest(false)
				gl.LineWidth(6.5)
				gl.Color({255,0,0})
				local radius = 30
				while value > START_BOOST do 
					gl.DrawFuncAtUnit(unitID, false, circleLines, 1, radius)
					radius = radius + 8
					value = value - START_BOOST
				end
				gl.DrawFuncAtUnit(unitID, false, circleLines, value / START_BOOST, radius)
				gl.DepthTest(true)
			end
		end
	end
	gl.Color(1,1,1,1)
end
--[[ moved to widget
local function DrawUnitFunc(yshift)
	gl.Translate(0,yshift,0)
	gl.Billboard()
	gl.TexRect(-10, -10, 10, 10)
end

local facplopTexture = 'LuaUI/Images/gift.png'

function gadget:DrawWorld()
	if Spring.IsGUIHidden() then return end
	local facplops = SYNCED.facplops
	local spec, fullview = Spring.GetSpectatingState()
	local myAllyID = Spring.GetMyAllyTeamID()

	spec = spec or fullview
	gl.Texture(facplopTexture )	
	gl.Color(1,1,1,1)
	for id,_ in spairs(facplops) do
		local los = spGetUnitLosState(id, myAllyID, false)
		if spValidUnitID(id) and spGetUnitDefID(id) and ((los and los.los) or spec) then
			gl.DrawFuncAtUnit(id, false, DrawUnitFunc,  UnitDefs[spGetUnitDefID(id)].height+30)
		end
	end
	gl.Texture("")
end
--]]

-- need this because SYNCED.tables are merely proxies, not real tables
local function MakeRealTable(proxy)
	local proxyLocal = proxy
	local ret = {}
	for i,v in spairs(proxyLocal) do
		if type(v) == "table" then
			ret[i] = MakeRealTable(v)
		else
			ret[i] = v
		end
	end
	return ret
end

function gadget:Save(zip)
	if not GG.SaveLoad then
		Spring.Log(gadget:GetInfo().name, LOG.ERROR, "Start Unit Setup failed to access save/load API")
		return
	end
	local toSave = {
		boost = boost,
		facplops = MakeRealTable(SYNCED.facplops),
		waitingForComm = MakeRealTable(SYNCED.waitingForComm),
		scheduledSpawn = MakeRealTable(SYNCED.scheduledSpawn),
		playerSides = MakeRealTable(SYNCED.playerSides),
		teamSides = MakeRealTable(SYNCED.teamSides),
		teamSidesAI = MakeRealTable(SYNCED.teamSidesAI),
		commSpawnedPlayer = MakeRealTable(SYNCED.commSpawnedPlayer),
		commSpawnedTeam = MakeRealTable(SYNCED.commSpawnedTeam),
	}
	GG.SaveLoad.WriteSaveData(zip, SAVE_FILE, toSave)
end

end
