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

-- TODO
-- when spring 0.82 is released:
-- * remove killing of engine spawned units
-- * remove GameFrame()

-- storage
local START_CLASSIC_STORAGE=1000
local START_STORAGE=500

local BOOST_RATE = 2.0
local START_BOOST=600
-- extra energy for boost
local START_BOOST_ENERGY=0

local OVERDRIVE_BUFFER=10000

local EXCLUDED_UNITS = {
  [ UnitDefNames['terraunit'].id ] = true,
}

local DEFAULT_UNIT = "armcom"		--FIXME: hardcodey until I cba to identify precise source of problem


if VFS.FileExists("mission.lua") then -- this is a mission, we just want to set starting storage
  if not gadgetHandler:IsSyncedCode() then
    return false -- no unsynced code
  end
  function gadget:GameFrame(n)
    if n == 0 then
      for _, teamID in ipairs(Spring.GetTeamList()) do
        Spring.SetTeamResource(teamID, "es", START_STORAGE + OVERDRIVE_BUFFER)
        Spring.SetTeamResource(teamID, "ms", START_STORAGE)
      end
    end
  end
  return
end


local modOptions = Spring.GetModOptions()
local startMode = Spring.GetModOption("startingresourcetype",false,"facplopboost")

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

local coop = false
coop = Spring.GetModOption("coop", false, false)

include "LuaRules/Configs/start_setup.lua"

local startUnits = {
	nova = 'armcom',
	logos = 'corcom',
	supportcomm = 'commsupport',
	reconcomm = 'commrecon',
}

local gaiateam = Spring.GetGaiaTeamID()
local gaiaally = select(6, Spring.GetTeamInfo(gaiateam))

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
local commSpawned = {}
local createBeforeGameStart = {}
local scheduledSpawn = {}
local startPosition = {} -- [teamID] = {x, y, z}
local shuffledStartPosition = {}
local playerSides = {} -- sides selected ingame from widget  - per players
local teamSides = {} -- sides selected ingame from widgets - per teams 

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function AddBoost(unitID, newBoost, newBoostMax)
	boost[unitID]  = newBoost or START_STORAGE
	boostMax[unitID] = newBoostMax or START_STORAGE
	SendToUnsynced("UpdateBoost", unitID, boost[unitID], boostMax[unitID])   
end


function gadget:UnitCreated(unitID, unitDefID, teamID, builderID)
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

	if plop and ploppableDefs[unitDefID] and facplops[builderID] then
		facplops[builderID] = nil
		-- 3 seconds to build with commander
		Spring.SetUnitCosts(unitID, {
			buildTime = 36,
			metalCost = 1,
			energyCost = 1
		})
		local x,y,z = Spring.GetUnitPosition(unitID)
		Spring.SpawnCEG("riotball", x, y, z)
		-- remember to plop, can't do it here else other gadgets etc. see UnitFinished before UnitCreated
		facplopsrunning[unitID] = true
	end
end


function gadget:UnitDestroyed(unitID)
	if plop and facplopsrunning[unitID] then
		facplopsrunning[unitID] = nil
	end

	if (boost[unitID] == nil) then return end

	if gamestart then disableBoost(unitID) end
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
	local cnt = 0
	for _,_ in pairs(boost) do
		cnt = cnt+1
	end
	for _,_ in pairs(facplops) do
		cnt = cnt+1
	end
	if (cnt == 0) and Spring.GetGameSeconds() > 5 then
		gadgetHandler.RemoveGadget(self)
	end
end


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

function gadget:Initialize()
  -- self linking
  GG['boostHandler'] = {}
  GG['boostHandler'].AddBoost = AddBoost

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
  end

  -- needed if you reload luarules
  local frame = Spring.GetGameFrame()
  if frame and frame > 0 then
    gamestart = true
  end
end


local function GetStartUnit(teamID, playerID)
  local side = select(5, Spring.GetTeamInfo(teamID))
  local sideCase = select(2, Spring.GetSideData(side)) -- case pls
  local startUnit = Spring.GetSideData(side)
  local chickens = modOptions and tobool(modOptions.chickens)
	
  if (playerID and playerSides[playerID]) then 
	return startUnits[playerSides[playerID]]
  end 
  
  if (teamID and teamSides[teamID]) then 
	return startUnits[teamSides[teamID]]
  end
  --didn't pick a comm, wait for user to pick
  return nil	-- startUnit or DEFAULT_UNIT
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
		local allyID = select(6, Spring.GetTeamInfo(teamID))
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

		local dirX = x - midPosX
		local dirZ = z - midPosZ

		if (math.abs(dirX) > math.abs(dirZ)) then
			facing = (dirX < 0)and("west")or("east")
		else
			facing = (dirZ < 0)and("south")or("north")
		end
	end

	return facing
end


local function SpawnStartUnit(teamID, playerID)
  -- get start unit
  if commSpawned[teamID] then return end	-- no getting double comms now!
  local startUnit = GetStartUnit(teamID, playerID)

  if startUnit then
    -- replace with shuffled position
    local x,y,z = unpack(shuffledStartPosition[teamID])

    -- get facing direction
    local facing = GetFacingDirection(x, z, teamID)

    -- CREATE UNIT
	local unitID
    if Spring.GetGameFrame() <= 1 then
		unitID = Spring.CreateUnit(startUnit, x, y, z, facing, teamID)
	else
		unitID = GG.DropUnit(startUnit, x, y, z, facing, teamID)
	end
	commSpawned[teamID] = true
	
    -- set the *team's* lineage root
    if Spring.SetUnitLineage then
      Spring.SetUnitLineage(unitID, teamID, true)
    end

    -- add boost and facplop
    local teamLuaAI = Spring.GetTeamLuaAI(teamID)
    local udef = UnitDefs[Spring.GetUnitDefID(unitID)]

    local validTeam = (teamID ~= gaiateam and ((not teamLuaAI) or teamLuaAI == "" or teamLuaAI == "CAI"))
    local boost = (startMode == "boost"
                or startMode == "limitboost"
                or startMode == "facplopboost")

    if validTeam then

      if boost then

        Spring.SetTeamResource(teamID, 'energy', START_BOOST_ENERGY)
        Spring.SetTeamResource(teamID, 'metal', 0)

        if (udef.isCommander and udef.name ~= "chickenbroodqueen") then
          if (startMode == "facplopboost") then
            AddBoost(unitID, START_BOOST, START_BOOST)
          elseif (startMode == "boost") then
            AddBoost(unitID, START_BOOST, START_BOOST)
          else
            AddBoost(unitID)
          end
        end

      else

        if startMode == "classic" then
          Spring.SetTeamResource(teamID, "es", START_CLASSIC_STORAGE + OVERDRIVE_BUFFER)
          Spring.SetTeamResource(teamID, "ms", START_CLASSIC_STORAGE)
          Spring.SetTeamResource(teamID, "energy", START_CLASSIC_STORAGE)
          Spring.SetTeamResource(teamID, "metal", START_CLASSIC_STORAGE)
        else
          Spring.SetTeamResource(teamID, "energy", START_STORAGE)
          Spring.SetTeamResource(teamID, "metal", START_STORAGE)
        end

      end

      if (udef.isCommander and udef.name ~= "chickenbroodqueen") then
        if plop then
          facplops[unitID] = 1
        end
      end

    end

  end
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
      startPosition[teamID] = {Spring.GetTeamStartPosition(teamID)}
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
      local _,_,spec = Spring.GetPlayerInfo(playerlist[i])
      if spec then specs = specs + 1 end
    end
    if players == specs then
      return nil
    end
  end
  return playerlist
end

function gadget:GameStart()
  gamestart = true

  -- shuffle start unit positions
  Shuffle()

  -- spawn units
  for i,team in ipairs(Spring.GetTeamList()) do

    -- clear resources
    -- actual resources are set depending on spawned unit and setup
    Spring.SetTeamResource(team, "es", START_STORAGE + OVERDRIVE_BUFFER)
    Spring.SetTeamResource(team, "ms", START_STORAGE)
    Spring.SetTeamResource(team, "energy", 0)
    Spring.SetTeamResource(team, "metal", 0)
	

    if team ~= gaiateam then
      if coop then
        -- 1 start unit per player
        local playerlist = Spring.GetPlayerList(team, true)
        playerlist = workAroundSpecsInTeamZero(playerlist, team)
        if playerlist and (#playerlist > 0) then
          for i=1,#playerlist do
            local _,_,spec = Spring.GetPlayerInfo(playerlist[i])
            if (not spec) then 
              SpawnStartUnit(team, playerlist[i])
            end
          end
        else
          -- AI etc.
          SpawnStartUnit(team)
        end
      else -- no coop
        SpawnStartUnit(team)
      end
    end
  end

  -- kill units if engine spawned
  for i,u in ipairs(createBeforeGameStart) do
    Spring.DestroyUnit(u, false, true) -- selfd = false, reclaim = true
  end
end

function gadget:RecvLuaMsg(msg, playerID)
	if msg:find("faction:",1,true) then
		local side = msg:sub(9)
		playerSides[playerID] = side
		local _,_,_,teamID = Spring.GetPlayerInfo(playerID)
		teamSides[teamID] = side
		if gamestart then
			-- picked commander after game start, prep for orbital drop
			-- can't do it directly because that's an unsafe change
			local frame = Spring.GetGameFrame() + 3
			if not scheduledSpawn[frame] then scheduledSpawn[frame] = {} end
			scheduledSpawn[frame][#scheduledSpawn[frame] + 1] = {teamID, playerID}
		end
	end
end

local function SetFaction(side, teamID)
    teamSides[teamID] = side
end
GG.SetFaction = SetFaction

function gadget:GameFrame(n)
  -- reset resources in frame 33 because of pre 0.82 engine
  if (n == 33) then
	local teamIDs = Spring.GetTeamList()
	for i=1,#teamIDs do
		local teamID = teamIDs[i]
		local gaiaID = Spring.GetGaiaTeamID()
		local teamLuaAI = Spring.GetTeamLuaAI(teamID)
		if	teamID ~= gaiaID 
			and ((not teamLuaAI) or teamLuaAI == "" or teamLuaAI == "CAI")
			and (
				startMode == "boost" 
				or startMode == "limitboost" 
				or startMode == "facplopboost"
			)
		then

			Spring.SetTeamResource(teamID, 'energy', START_BOOST_ENERGY)
			Spring.SetTeamResource(teamID, 'metal', 0)

    else

      if startMode == "classic" then
        Spring.SetTeamResource(teamID, "energy", START_CLASSIC_STORAGE)
        Spring.SetTeamResource(teamID, "metal", START_CLASSIC_STORAGE)
      else
        Spring.SetTeamResource(teamID, "energy", START_STORAGE)
        Spring.SetTeamResource(teamID, "metal", START_STORAGE)
      end

    end

	end
  end
  if scheduledSpawn[n] then
	for _, spawnData in pairs(scheduledSpawn[n]) do
		SpawnStartUnit(spawnData[1], spawnData[2])
	end
  end
end

--------------------------------------------------------------------
-- unsynced code
--------------------------------------------------------------------
else

local teamID = Spring.GetLocalTeamID()
local boost = {}
local boostMax = {}

function gadget:Initialize()
  gadgetHandler:AddSyncAction("UpdateBoost",UpdateBoost)
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
	teamID = Spring.GetLocalTeamID()
	local spec, fullview = Spring.GetSpectatingState()
	spec = spec or fullview
	for unitID, value in pairs(boost) do
		local ut = Spring.GetUnitTeam(unitID)
		if (ut ~= nil and (spec or Spring.AreTeamsAllied(teamID, ut))) then
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
end


end
