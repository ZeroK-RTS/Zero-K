function gadget:GetInfo()
  return {
    name      = "Halloween ghost possession",
    desc      = "v0.002 Ghosts randomly possess units, inspired by Duke Nukem map by wolas...",
    author    = "Tom Fyuri",
    date      = "Jan 2013",
    license   = "GPL v2 or later",
    layer     = 11,
    enabled   = true
  }
end

--[[ Basic idea for 0.001 version, rules:
1. Commander, terraform unit are ignored for possession, henceforth unpossassable.
1.1. Units undergoing morphing should be unpossassable, since if they finish morph somehow they will become another unit. (subject to change)
2. Grace period of 30 seconds (read below to understand how possession works).
3. Unit's health that goes below 33% or is 33% is unpossessed and unpossessable.
4. Even slight EMP damage unpossess any unit (subject to change, probably better idea would be to paralize unit fully).
5. Capture unit at least 90% and it is unpossessed automaticly! (subject to change)
6. Player's last unit is unpossassable (this rule is subject to change, too), commander counts for last unit as well.
7. And the last, but not the least!
  Ghost team gets imaginable storage with zero metal, but constant income that increases over game time.
  Ghost team can possess any unit in exchange for their imaginable metal, if they have enough of course.
  Ghost team will try to store metal and ocassionaly to "buy" expensive units/factories/defences from players.
  Ghost team will then don't possess anything until they restore their bank a bit.

0.002 version, new rule:
8. Difficulty, it scales the friquency of massive waves, amount of units each waves might be possessed, their cost, and grace periods between waves.
  Also nightmare difficulty is something to convert every map to duke nukem. :)

TODO:
- Public demanded commanders to become possessable, so make it as an option in some near future.
- Figure out how to give unlimited resources (or is it even needed?) to "ghosts".
- Unit actual expirience should also act as ghost resistant, so more elite unit is, the more expensive it is for ghosts to possess.
- Sounds/markers/music(?) anything to notify players what happens.
- Make silencer and tac silo attack random things.
- Make possessed factories produce units and produce them for free (lulz).
- Make any possessed defense structure resource independent (anni, ddm).
- Make some actual ghosts in future, so this more resembles chickens, and not random hell like Duke Nukem map.
- The bigger version of this gamemode is, the more optimised this code should be, if possible,
  it shouldn't waste cpu doing something totally useless without good reason, please think about players with bad cpu.

]]--

if(not Spring.GetModOptions()) then
      return false
end

local modOptions = Spring.GetModOptions()
if (modOptions.zkmode ~= "halloween") then
      return
end

--SYNCED-------------------------------------------------------------------
if (gadgetHandler:IsSyncedCode()) then

--local sin    = math.sin
local random = math.random
local floor  = math.floor
local spGetAllUnits         = Spring.GetAllUnits
local spGetUnitDefID        = Spring.GetUnitDefID
local spGetUnitTeam	    = Spring.GetUnitTeam
local spGetTeamUnits 	    = Spring.GetTeamUnits
local spGetUnitHealth	    = Spring.GetUnitHealth
local spTransferUnit        = Spring.TransferUnit
local spGetGaiaTeamID 	    = Spring.GetGaiaTeamID
local spGetUnitIsDead	    = Spring.GetUnitIsDead
local spGiveOrderToUnit	    = Spring.GiveOrderToUnit
local spGetUnitHealth	    = Spring.GetUnitHealth
local spSetTeamResources    = Spring.SetTeamResources
local spGetTeamResources    = Spring.GetTeamResources
local spGetUnitRulesParam   = Spring.GetUnitRulesParam
local spCreateUnit	    = Spring.CreateUnit
local spGetUnitDefID	    = Spring.GetUnitDefID
--local spGetUnitBasePosition = Spring.GetUnitBasePosition
local spEcho                = Spring.Echo

local spGetPlayerList	    = Spring.GetPlayerList
local spGetTeamList	    = Spring.GetTeamList
local spGetTeamInfo	    = Spring.GetTeamInfo
local spGetPlayerInfo	    = Spring.GetPlayerInfo

-- actually im not sure what com names are exactly so
local unpossassableUnitsDef = {
  -- commander excludement went to if statement in respective places
	--[ UnitDefNames['corcom1'].id ] = true, -- battle commander
	--[ UnitDefNames['commsupport1'].id ] = true, -- support commander
	--[ UnitDefNames['commrecon1'].id ] = true, -- recon commander
	--[ UnitDefNames['armcom1'].id ] = true, -- strike commander
	--[ UnitDefNames['benzcom1'].id ] = true, -- bombard commander
	[ UnitDefNames['terraunit'].id ] = true, -- terraform thing
	-- other commanders, singleplayer and whatnot
	--[ UnitDefNames['armcom3'].id ] = true,
	--[ UnitDefNames['armcom2'].id ] = true,
	--[ UnitDefNames['corcom2'].id ] = true,
	--[ UnitDefNames['commrecon2'].id ] = true,
	--[ UnitDefNames['armcom2'].id ] = true,
	--[ UnitDefNames['commsupport2'].id ] = true,
	--[ UnitDefNames['corcom2'].id ] = true,
	--[ UnitDefNames['commrecon2'].id ] = true,
	--[ UnitDefNames['commsupport2'].id ] = true,
}

-- these are to remember original value
local halloweenGhostSavingsDeviation = (modOptions.ghostsavingsrate or 0.02) -- anything that's cheaper than savebank is unlikely to being bought

-- these are values may or may not be modified during the game on fly
local halloweenGhostBank = (modOptions.ghostmoney or 0)
local halloweenGhostMinBank = 0
local halloweenGhostCurrentIncome = (modOptions.ghoststartincome or 1.0)
local halloweenGhostIncomeBasedOnMexCount = (modOptions.ghostincomebasedonmex or true)
local halloweenGhostCurrentDeviation = (modOptions.ghostincomesingularity or 1.1)
local halloweenHellMode = false

local halloweenGhostDifficulty = (modOptions.ghostdiff or "normal")

local PossessedUnitList = {}
local PossessedCount = {}

local waveNumber = 0
local possessGoal = 0
local ownedThings = 0 -- owned in like "pwned"
local graceTimer = (modOptions.halloweenInitialGracePeriod or 30)
local bossWave = 10

function gadget:Initialize()
    if(modOptions.zkmode ~= "halloween") then
	gadgetHandler:RemoveGadget()
    end
end

function gadget:GameStart()
    if (halloweenGhostDifficulty == "easy") then
      bossWave = 15
    elseif (halloweenGhostDifficulty == "hard") then
      bossWave = 8
    elseif (halloweenGhostDifficulty == "extreme") then
      bossWave = 5
    elseif (halloweenGhostDifficulty == "nightmare") then
      bossWave = 3
    end
    
    spEcho("Halloween - Ghost Possession gamemode detected.")
    spEcho("After " .. (modOptions.halloweenInitialGracePeriod or 30) .. " seconds, ghosts will start to harass you, players.")
    -- interesting thing, probably on lolcat or speedmetal players need to specify StartIncome like 10x times :D
    if (GG.metalSpots and halloweenGhostIncomeBasedOnMexCount) then
      --------------------------------------------------------------------------
      local playerCount = 0
      local playerlist = spGetPlayerList()
      local teamsSorted = spGetTeamList()
      for i=1,#teamsSorted do
	local teamID = teamsSorted[i]
	if teamID ~= spGetGaiaTeamID() then
	  local _,_,_,isAI,_,_ = spGetTeamInfo(teamID)
	  if isAI then
	    playerCount = playerCount + 1
	  end
	end
      end
      for i=1, #playerlist do
	local playerID = playerlist[i]
	local _,_,spectator,_,_,_,_,_,_ = spGetPlayerInfo(playerID)
	if not spectator then
	  playerCount = playerCount + 1
	end
      end
      --spEcho("Debug non-spec player + ai count: " .. playerCount .. ".")
      --------------------------------------------------------------------------
      halloweenGhostCurrentIncome = floor(0.5 + (#GG.metalSpots / 32.0 * playerCount)) -- subject to balance
      --spEcho("Debug: mc: " .. #GG.metalSpots .. ", gi: " .. halloweenGhostCurrentIncome .. ".")
      -- apply difficulty, normal doesn't change income at all
      if (halloweenGhostDifficulty == "easy") then
	halloweenGhostCurrentIncome = halloweenGhostCurrentIncome * 0.5
      elseif (halloweenGhostDifficulty == "hard") then
	halloweenGhostCurrentIncome = halloweenGhostCurrentIncome * 2
      elseif (halloweenGhostDifficulty == "extreme") then
	halloweenGhostCurrentIncome = halloweenGhostCurrentIncome * 4
      elseif (halloweenGhostDifficulty == "nightmare") then
	halloweenGhostCurrentIncome = halloweenGhostCurrentIncome * 8
      end
      --spEcho("Ghost diff: " .. halloweenGhostDifficulty .. ".")
      spEcho("Initial ghost income is based on mex count, so it's: " .. halloweenGhostCurrentIncome .. " m/s.")
      -- for instance titan duel has 32 mexes, and battle with 6 players may end in 15 minutes,
      -- while with ghost income 2 they don't even possess anything significant to mess with both teams
      -- while icy run has only 12 mexes and with income greater than 2 ghost team floors both teams within 5 minutes just about right :D
    else
      spEcho("Initial ghost income is: " .. halloweenGhostCurrentIncome .. " m/s.")      
    end
    spEcho("You better rush EMP weapons or take a note that ghosts quit damaged units (<=33%).")
    if (halloweenGhostDifficulty ~= "nightmare") then
      spEcho("Have fun and good luck!")
    else
      spEcho("Have... IT COMES! YOU CAN'T SURVIVE! NOOO!!!")
      -- for lulz
      local zalgo
      local x = random(0,Game.mapSizeX)
      local z = random(0,Game.mapSizeZ)

      zalgo = spCreateUnit("armorco",x,10000,z,"n",spGetGaiaTeamID())
      if (zalgo ~= nil) then
	spGiveOrderToUnit(zalgo,CMD.REPEAT,{1},{})
	spGiveOrderToUnit(zalgo,CMD.MOVE_STATE,{2},{})
	for i=1,10 do
	  if (spGetUnitIsDead(zalgo) == false) then
	    x = random(0,Game.mapSizeX)
	    z = random(0,Game.mapSizeZ)
	    spGiveOrderToUnit(zalgo,CMD.INSERT,{-1,CMD.FIGHT,CMD.OPT_SHIFT,x,0,z},{"alt"});
	  end
	end
      end
    end
end

function gadget:GameFrame (f)
    -- waves and possessions
    if (halloweenHellMode and waveNumber > 0) then
      if (ownedThings >= possessGoal) then
	halloweenHellMode = false
	graceTimer = random(1+2*waveNumber, 2+4*waveNumber)
	if (halloweenGhostDifficulty == "easy") then
	  graceTimer = graceTimer * 2 -- subject to change
	elseif (halloweenGhostDifficulty == "hard") then
	  graceTimer = floor(0.5 + (graceTimer * 1.5)) -- subject to change
	elseif (halloweenGhostDifficulty == "extreme") then
	  graceTimer = floor(0.5 + (graceTimer * 2.2)) -- subject to change
	elseif (halloweenGhostDifficulty == "nightmare") then
	  graceTimer = graceTimer * 3 -- subject to change
	end
	spEcho("Wave " .. waveNumber .. " ended. Grace period: " .. graceTimer .. " seconds.")
	ownedThings = 0
      elseif (f%10 == 0) then
	HellBreaksLoose() -- searching for random prey
      end
    elseif (graceTimer > 0) then -- grace period
      if (f%30 == 0) then
	graceTimer = graceTimer - 1
	if (graceTimer == 30) then
	  spEcho("Wave " .. waveNumber + 1 .. " begins in 30 seconds!")
	end
      end
    else
      halloweenHellMode = true
      if (((waveNumber + 1) > bossWave) and ((waveNumber % bossWave) == 0)) then
	possessGoal = possessGoal - waveNumber -- boss wave ended
      end
      waveNumber = waveNumber + 1
      -- subject to change
      if (halloweenGhostDifficulty == "easy") then
	possessGoal = random(1*waveNumber, 2*waveNumber)
      elseif (halloweenGhostDifficulty == "hard") then
	possessGoal = random(2*waveNumber, 4*waveNumber)
      elseif (halloweenGhostDifficulty == "extreme") then
	possessGoal = random(2*waveNumber, 6*waveNumber)
      elseif (halloweenGhostDifficulty == "nightmare") then
	possessGoal = random(3*waveNumber, 10*waveNumber)
      else
	possessGoal = random(1*waveNumber, 3*waveNumber)
      end
      if (waveNumber % bossWave == 0) then
	halloweenGhostMinBank = 0 -- every 10 waves start possess ANYTHING
	possessGoal = possessGoal + waveNumber -- boss wave
      end
      spEcho("Wave " .. waveNumber .. " begins! Ghosts may possess at least " .. halloweenGhostBank .. " metal!")
    end
    -- income stuff
    if (f%30 == 0) then
      halloweenGhostBank = halloweenGhostBank + halloweenGhostCurrentIncome
    end
    if (f%1800 == 0) then
      -- probably difficulty should affect this one too
      halloweenGhostCurrentIncome = halloweenGhostCurrentIncome * halloweenGhostCurrentDeviation
    end
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
    -- unit destroyed, but was possessed? forget about owner, doesn't matter anymore
    if (PossessedUnitList[unitID] ~= nil) then
	PossessedCount[unitID] = nil -- it's dead Sam
	deletePossession(unitID)
    end
end

function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponID, attackerID, attackerDefID, attackerTeam)
    -- if unit is possessed, but health drops to 33% or EMPed even slightly - return to owner
    if (unitTeam == spGetGaiaTeamID() and spGetUnitIsDead(unitID) == false and PossessedUnitList[unitID] ~= nil) then
      if (GhostIsHealthy(unitID) == false) then
	-- interesting thing, if this is player or ai that is dead, return unit to attacker and NOT player
	--------------------------------------------------------------------------
	local playerlist = spGetPlayerList()
	local teamsSorted = spGetTeamList()
	local found = false
	for i=1,#teamsSorted do
	  local teamID = teamsSorted[i]
	  if teamID ~= spGetGaiaTeamID() then
	    local _,_,isDead,isAI,_,_ = spGetTeamInfo(teamID)
	    if (PossessedUnitList[unitID] == teamID and isAI and isDead) then
	      if (attackerTeam ~= spGetGaiaTeamID()) then
		PossessedUnitList[unitID] = attackerID
		found = true -- so we don't enter next for loop
	      else
		PossessedUnitList[unitID] = nil
		deletePossession(unitID)
	      end
	      break
	    end
	  end
	end
	if (found == false) then
	  for i=1, #playerlist do
	    local playerID = playerlist[i]
	    local _,active,spectator,_,_,_,_,_,_ = spGetPlayerInfo(playerID)
	    if ((PossessedUnitList[unitID] == playerID) and (spectator or not active)) then
	      if (attackerTeam ~= spGetGaiaTeamID()) then
		PossessedUnitList[unitID] = attackerID
	      else
		PossessedUnitList[unitID] = nil
		deletePossession(unitID)
	      end
	      break
	    end
	  end
	end
	--spEcho("Debug non-spec player + ai count: " .. playerCount .. ".")
	--------------------------------------------------------------------------
	if (PossessedUnitList[unitID]) then -- if there is someone to return unit to
	  UnPossess(unitID, unitDefID) -- the ghost dies
	end
      end
    end
end

function GhostIsHealthy(unitID)
  local health,maxHealth,paralyzeDamage,emp,hp,build,cap
  health,maxHealth,paralyzeDamage,cap = spGetUnitHealth(unitID)
  local empHP = maxHealth
  emp = (paralyzeDamage or 0)/empHP
  hp  = (health or 0)/maxHealth
  if (hp <= 0.33 or emp > 0.0 or cap >= 0.9) then
    return false
  else
    return true
  end
end

function nanoframed(unitID)
  local _,_,_,_,build = spGetUnitHealth(unitID)
  if (build == 1) then -- my guess it's actually 1.00
    return false
  else
    return true
  end
end

function morphing(unitID)
  -- is this implemented... correctly?
  if spGetUnitRulesParam(unitID, 'morphing') then
    return true
  else
    return false
  end
end

function IsntCom(unitDefID)
  if (UnitDefs[unitDefID].commander or UnitDefs[unitDefID].customParams.level) then
    return false
  else
    return true
  end
end

function HellBreaksLoose()
  local allUnits = spGetAllUnits()
  local anythingpossessed = false
  if (#allUnits > 1) then
    local unitID = allUnits[random(1,#allUnits)]
    if (spGetUnitIsDead(unitID) == false and spGetUnitTeam(unitID) ~= spGetGaiaTeamID()) then
      local unitDefID = spGetUnitDefID(unitID)
      if ((GhostIsHealthy(unitID)) and (not nanoframed(unitID)) and (not morphing(unitID)) and IsntCom(unitDefID) and (not unpossassableUnitsDef[unitDefID])) then
	-- we found unit, and it's possessable, now check how much units that player has and how much unit costs
	local unitTeam = spGetUnitTeam(unitID)
	local teamUnits = spGetTeamUnits(unitTeam)
	local possessableCount = 0
	local iunitID, iunitDefID
	for i = 1, #teamUnits do
	  iunitID = teamUnits[i]
	  iunitDefID = spGetUnitDefID(iunitID)
	  -- maybe make it so only units but not structures count towards possessable things?
	  if ((GhostIsHealthy(iunitID)) and (not nanoframed(iunitID)) and (not morphing(iunitID)) and (not unpossassableUnitsDef[iunitDefID])) then
	    possessableCount = possessableCount + 1
	  end
	  -- to make loop end faster
	  if (possessableCount > 2) then
	    break -- more than 2 units? enough, don't spend precious cpu bothering counting more units
	  end
	end
	if (possessableCount > 1) then -- good, player has more than 1 unit and its possessable type, last check, can we "buy" it?
	  local price = UnitDefs[unitDefID].metalCost
	  if (PossessedCount[unitID]) then
	    price = price * PossessedCount[unitID] -- every next possession cost is increased a lot, so units literally become veterans in willpower :)
	  end
	  -- in 1% cases ghosts will ignore minbank and still buy unit even if it's expensive
	  if (1 == random(1,100) and price <= halloweenGhostBank) then
	    Possess(unitID, unitDefID, unitTeam, price)
	    anythingpossessed = true
	  -- in 99% cases don't bother with cheap things and try to buy expensive ones -- this way ghosts won't possess EVERY mex and EVERY windgen etc etc etc
	  elseif (price >= halloweenGhostMinBank and price <= halloweenGhostBank) then
	    Possess(unitID, unitDefID, unitTeam, price)
	    anythingpossessed = true
	  end
	end
      end
    end
  end
  if (anythingpossessed) then
    --spEcho("Something was possessed!")
    ownedThings = ownedThings + 1
  end
end

function Possess(unitID, unitDefID, owner, price)
  halloweenGhostBank = halloweenGhostBank - price
  halloweenGhostMinBank = halloweenGhostMinBank + (price * halloweenGhostSavingsDeviation)
  -- add to list
  addPossession(unitID, owner)
  -- transfer ownership
  spTransferUnit(unitID, spGetGaiaTeamID(), false)
  -- TODO find out if unit is actually something that can't fight at all or maybe silencer/silo.
  if (spGetUnitIsDead(unitID) == false and UnitDefs[unitDefID]["canMove"]) then
    spGiveOrderToUnit(unitID, CMD.STOP, {}, {})
  end
  if (spGetUnitIsDead(unitID) == false and UnitDefs[unitDefID]["canMove"]) then -- this section doesn't work at all for some reason =/
    -- wolas duke style
    spGiveOrderToUnit(unitID,CMD.REPEAT,{1},{})
    spGiveOrderToUnit(unitID,CMD.MOVE_STATE,{2},{})
    for i=1,10 do
      if (spGetUnitIsDead(unitID) == false) then
	local x = random(0,Game.mapSizeX)
	local z = random(0,Game.mapSizeZ)
	spGiveOrderToUnit(unitID,CMD.INSERT,{-1,CMD.FIGHT,CMD.OPT_SHIFT,x,0,z},{"alt"});
      end
    end
  end
end

function UnPossess(unitID, unitDefID)
  spTransferUnit(unitID, PossessedUnitList[unitID], false)
  if (UnitDefs[unitDefID]["canMove"]) then
    spGiveOrderToUnit(unitID, CMD.STOP, {}, {})
  end
  deletePossession(unitID)
end

function deletePossession( unitID )
  if ( PossessedUnitList[unitID] ~= nil ) then
    PossessedUnitList[unitID] = nil
  end
end

function addPossession( unitID, owner )
  PossessedUnitList[unitID] = owner
  if (PossessedCount[unitID]) then
    PossessedCount[unitID] = PossessedCount[unitID] + 1
  else
    PossessedCount[unitID] = 0
  end
end


else
---------------------------------------------------------------------------------

--UNSYNCED-----------------------------------------------------------------------

-- ?? i'm unbeknownst to what should or shouldn't be here...

end  --UNSYNCED
