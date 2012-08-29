function gadget:GetInfo()
	return {
		name = "AoS",
		desc = "AoS Mode",
		author = "Sprung, modified by Rafal",
		date = "25/8/2012",
		license = "PD",
		layer = 1,
		enabled = true,
	}
end

if (Spring.GetModOptions().zkmode ~= "dota") then
  return
end

if (not gadgetHandler:IsSyncedCode()) then
	return
end

local random = math.random

local hq0
local hq1

local basecoms = {}

local edge_dist = 1000 -- cc 
local edge_dist2 = 1200 -- creep spawnpoint
local edge_dist3 = 1600 -- corner waypoint
local edge_dist4 = 400 -- com respawnpoint
local fountain = 500 -- autoheal

local team1 = Spring.GetTeamList(0)[1]
local team2 = Spring.GetTeamList(1)[1]

-- creeps
local creep1 = "spiderassault"
local creep2 = "corstorm"

-- current creep count per wave
local creepcount = 2

local y0 = Spring.GetGroundHeight(edge_dist, edge_dist)
local y02 = Spring.GetGroundHeight(edge_dist2, edge_dist2)
local y1 = Spring.GetGroundHeight(Game.mapSizeX - edge_dist, Game.mapSizeZ - edge_dist)
local y12 = Spring.GetGroundHeight(Game.mapSizeX - edge_dist2, Game.mapSizeZ - edge_dist2)
local y04 = Spring.GetGroundHeight(edge_dist4, edge_dist4)
local y14 = Spring.GetGroundHeight(Game.mapSizeX - edge_dist4, Game.mapSizeZ - edge_dist4)

local yc1 = Spring.GetGroundHeight(Game.mapSizeX - edge_dist3, edge_dist3)
local yc2 = Spring.GetGroundHeight(edge_dist3, Game.mapSizeZ - edge_dist3)

local midy = Spring.GetGroundHeight(Game.mapSizeX/2, Game.mapSizeZ/2)

function gadget:UnitCreated(unitID, unitDefID, unitTeam)
	if(UnitDefs[unitDefID].customParams.commtype and not basecoms[unitTeam]) then
		basecoms[unitTeam] = UnitDefs[unitDefID].name
	end
	
	Spring.SetUnitCloak(unitID, false)
	Spring.GiveOrderToUnit(unitID, CMD.CLOAK, {0}, {})

	local cmdDescID = Spring.FindUnitCmdDesc(unitID, 32101)  --areacloak
	if (cmdDescID) then
		Spring.RemoveUnitCmdDesc(unitID, cmdDescID)
	end

	if(unitDefID == UnitDefNames[creep1].id or unitDefID == UnitDefNames[creep2].id) then
		Spring.SetUnitNoSelect(unitID,true) -- creeps uncontrollable
	end
	Spring.SetUnitCosts(unitID, {metalCost = 1})
end

function gadget:AllowFeatureCreation()
	return false
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam, attackerID)
	_,_,_,_,_,allyteam = Spring.GetTeamInfo(unitTeam)
	if(unitID == hq0) then 
		for _,aunitID in ipairs(Spring.GetAllUnits()) do
			if (Spring.GetUnitAllyTeam(aunitID) == 0) then Spring.DestroyUnit(aunitID, true, false) end
		end
		for _,allyteam in ipairs(Spring.GetAllyTeamList()) do
			if(allyteam ~= 1) then
				for _,teams in ipairs(Spring.GetTeamList(allyteam)) do
					Spring.KillTeam(teams)
				end
			end
		end
		Spring.GameOver({1})
	elseif (unitID == hq1) then
		for _,aunitID in ipairs(Spring.GetAllUnits()) do
			if (Spring.GetUnitAllyTeam(aunitID) == 1) then Spring.DestroyUnit(aunitID, true, false) end
		end
		for _,allyteam in ipairs(Spring.GetAllyTeamList()) do
			if(allyteam ~= 0) then
				for _,teams in ipairs(Spring.GetTeamList(allyteam)) do
					Spring.KillTeam(teams)
				end
			end
		end
		Spring.GameOver({0})
	elseif (unitDefID == UnitDefNames["heavyturret"].id) then
		if(allyteam == 0) then
			_,_,_,eu = Spring.GetUnitResources(hq0)
			Spring.SetUnitResourcing(hq0, "uue", eu - 25) -- stop hq from using up the free E from turret
		else
			_,_,_,eu = Spring.GetUnitResources(hq1)
			Spring.SetUnitResourcing(hq1, "uue", eu - 25)
		end
	elseif(UnitDefs[unitDefID].name == creep1 or UnitDefs[unitDefID].name == creep2) then
		if(attackerID and Spring.GetUnitTeam(attackerID) and (not Spring.AreTeamsAllied(unitTeam, Spring.GetUnitTeam(attackerID))) and Spring.GetUnitDefID(attackerID) and UnitDefs[Spring.GetUnitDefID(attackerID)].customParams.commtype) then
			Spring.AddTeamResource(Spring.GetUnitTeam(attackerID), "metal", 50)
			Spring.AddTeamResource(Spring.GetUnitTeam(attackerID), "energy", 20) -- less E so ecell is still viable
		end
	elseif(UnitDefs[unitDefID].name == "amphtele") then
		if(allyteam == 0) then Spring.CreateUnit("amphtele", edge_dist4, y04, edge_dist4, 0, unitTeam)
		else Spring.CreateUnit("amphtele", Game.mapSizeX - edge_dist4, y14, Game.mapSizeZ - edge_dist4, 2, unitTeam)
		end
	elseif(UnitDefs[unitDefID].customParams.commtype) then
		if(attackerID == nil and Spring.GetUnitHealth(unitID) > 0) then return end -- blocks respawn at morph (also blocks respawn at self-d. pwned.)
		if(attackerID and Spring.GetUnitTeam(attackerID) and not Spring.AreTeamsAllied(unitTeam, Spring.GetUnitTeam(attackerID)) and Spring.GetUnitDefID(attackerID) and UnitDefs[Spring.GetUnitDefID(attackerID)].customParams.commtype) then
			local attackerTeam = Spring.GetUnitTeam(attackerID)
			killer = Spring.GetPlayerInfo(select(2, Spring.GetTeamInfo(attackerTeam)))
			failer = Spring.GetPlayerInfo(select(2, Spring.GetTeamInfo(unitTeam)))
			Spring.Echo(killer .. " pwned " .. failer .. "!")
			Spring.AddTeamResource(attackerTeam, "metal", 500)
			Spring.AddTeamResource(attackerTeam, "energy", 200) -- less E so ecell is still viable
		end
		if(allyteam == 0) then Spring.CreateUnit(basecoms[unitTeam], edge_dist4, y04, edge_dist4, 0, unitTeam)
		else Spring.CreateUnit(basecoms[unitTeam], Game.mapSizeX - edge_dist4, y14, Game.mapSizeZ - edge_dist4, 2, unitTeam)
		end
	end
end

function SpawnT2(x, z, t)
	local turret = Spring.CreateUnit("corllt", x, Spring.GetGroundHeight(x, z), z, 0, t)
	Spring.SetUnitWeaponState(turret, 0,
	{
     range = 580,
     projectiles = 5,
     burst = 8,
	 burstRate = 0.01,
	 sprayAngle = 0.08,
    } )
	Spring.SetUnitSensorRadius(turret, "los", 1000)
	Spring.SetUnitNoSelect(turret, true)
	Spring.SetUnitMaxHealth(turret, 4250)
	Spring.SetUnitHealth(turret, 4250)
end

function SpawnT1(x, z, t)
	local turret = Spring.CreateUnit("corpre", x, Spring.GetGroundHeight(x, z), z, 0, t)
	Spring.SetUnitWeaponState(turret, 0,
	{
	 reloadTime = 0.04,
    } )
	Spring.SetUnitSensorRadius(turret, "los", 600)
	Spring.SetUnitNoSelect(turret, true)
	Spring.SetUnitMaxHealth(turret, 2500)
	Spring.SetUnitHealth(turret, 2500)
end

function SpawnT3(x, z, t)
	Spring.LevelHeightMap(x-Game.squareSize, z-Game.squareSize, x+Game.squareSize, z+Game.squareSize, Spring.GetGroundHeight(x, z) + 50)
	local turret = Spring.CreateUnit("heavyturret", x, Spring.GetGroundHeight(x, z), z, 0, t)
	Spring.SetUnitResourcing(turret, "ume", 25) -- needs 25 E to fire like anni/ddm
	Spring.SetUnitWeaponState(turret, 0,
	{
     range = 730,
	 reloadTime = 8,
    } )
	Spring.SetUnitSensorRadius(turret, "los", 1250)
	Spring.SetUnitNoSelect(turret, true)
	Spring.SetUnitMaxHealth(turret, 4500)
	Spring.SetUnitHealth(turret, 4500)
end

function gadget:GameStart()
	hq0 = Spring.CreateUnit("pw_hq", edge_dist, y0, edge_dist, 0, team1)
	hq1 = Spring.CreateUnit("pw_hq", Game.mapSizeX - edge_dist, y1, Game.mapSizeZ - edge_dist, 2, team2)
	Spring.SetUnitNoSelect(hq0, true)
	Spring.SetUnitNoSelect(hq1, true)
	
	-- use 100 E to offset t3 turrets
	Spring.SetUnitResourcing(hq0, "uue", 75)
	Spring.SetUnitResourcing(hq1, "uue", 75)

	Spring.SetUnitSensorRadius(hq0, "seismic", 4000)
	Spring.SetUnitSensorRadius(hq1, "seismic", 4000)
	
	-- lane turrets
	SpawnT1(3470,3652, team1)
	SpawnT1(4867,1317, team1)
	SpawnT1(1487,5302, team1)
	SpawnT2(3452,825, team1)
	SpawnT2(2442,2487, team1)
	SpawnT2(900,2920, team1)
	SpawnT3(467,1467, team1)
	SpawnT3(1467,587, team1)
	SpawnT3(1638,1408, team1)

	SpawnT1(4463,4583, team2)
	SpawnT1(6406,2844, team2)
	SpawnT1(3118,6641, team2)
	SpawnT2(7158,4648, team2)
	SpawnT2(5675,5684, team2)
	SpawnT2(4824,7162, team2)
	SpawnT3(6259,7674, team2)
	SpawnT3(7665,6682, team2)
	SpawnT3(6666,6666, team2)
	
	-- baes
	SpawnT2(edge_dist - 150, edge_dist + 150, team1)
	SpawnT2(edge_dist + 150, edge_dist - 150, team1)

	SpawnT2(Game.mapSizeX - edge_dist - 150, Game.mapSizeX - edge_dist + 150, team2)
	SpawnT2(Game.mapSizeX - edge_dist + 150, Game.mapSizeX - edge_dist - 150, team2)
	
	-- djinns
	allyteams0 = Spring.GetTeamList(0)
	for i=1, #allyteams0 do
		Spring.CreateUnit("amphtele", edge_dist2 - random(-50, 50), y02, edge_dist2 - random(-50, 50), 0, allyteams0[i])
	end
	allyteams1 = Spring.GetTeamList(1)
	for i=1, #allyteams1 do
		Spring.CreateUnit("amphtele", Game.mapSizeX - edge_dist2 - random(-50, 50), y12, Game.mapSizeZ - edge_dist2 - random(-50, 50), 0, allyteams1[i])
	end
	
	-- mark fountain
	Spring.LevelHeightMap(fountain-Game.squareSize, fountain-Game.squareSize, fountain, fountain, Spring.GetGroundHeight(fountain, fountain) + 120)
	Spring.LevelHeightMap(Game.mapSizeX-fountain, Game.mapSizeZ-fountain, Game.mapSizeX-fountain+Game.squareSize, Game.mapSizeZ-fountain+Game.squareSize, Spring.GetGroundHeight(Game.mapSizeX-fountain, Game.mapSizeZ-fountain) + 120)
end

function gadget:AllowCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions, cmdTag, synced)
	if(cmdID and ((cmdID == CMD.CLOAK and cmdParams and (cmdParams[1] == 1)) -- block cloak
	or (cmdID == CMD.RECLAIM) or (cmdID == CMD.RESURRECT) or (cmdID < 0) or ((cmdID == CMD.INSERT) and cmdParams and (cmdParams[2] < 0)))) -- block rez
	then return false
	else return true end
end

-- changing units' damage
function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponID, attackerID, atkrDefID, attackerTeam)
	
	if(weaponID and WeaponDefs[weaponID] and WeaponDefs[weaponID].name:find("shockrifle")) then damage = damage*0.6 end

	-- secret buffs to sprung for being awesome
	if(UnitDefs[unitDefID].name:find("c47367")) then damage = damage * 0.7 end
	if(atkrDefID and UnitDefs[atkrDefID].name:find("c47367")) then damage = damage * 1.3 end

	return damage
end

local function SpawnCreep1 (x, y, z, teamID)
  local creep = Spring.CreateUnit(creep1, x + random(-50,50), y, z + random(-50,50), 0, teamID)
  --Spring.MoveCtrl.SetGroundMoveTypeData(creep, "maxSpeed", 1.95)
  return creep
end

function gadget:GameFrame(n)
	if((n % 30) == 17) then
		everything = Spring.GetAllUnits()
		for i=1, #everything do
			if(Spring.GetUnitDefID(everything[i] ) ~= UnitDefNames["terraunit"].id) then
				local x,_,z = Spring.GetUnitBasePosition(everything[i])
				allyteam = select(6, Spring.GetTeamInfo(Spring.GetUnitTeam(everything[i])))
				if ((allyteam==0 and x<fountain and z<fountain) or (allyteam==1 and x > Game.mapSizeX - fountain and z > Game.mapSizeZ - fountain)) then
					local hp, maxHp = Spring.GetUnitHealth(everything[i])
					Spring.SetUnitHealth(everything[i], math.min(hp + 150, maxHp))
				end
			end
		end
	end
	if((n % (5*1350)) == 850) then creepcount = math.min(creepcount + 1, 7) end
	if((n % 1350) ~= 900) then return end
	local creep
	for i = 1,creepcount do -- top right, team 0
		creep = SpawnCreep1(edge_dist2, y02, edge_dist2, team1)
		Spring.GiveOrderToUnit(creep, CMD.FIGHT, {Game.mapSizeX - edge_dist3, yc1, edge_dist3}, {"shift"})
		Spring.GiveOrderToUnit(creep, CMD.FIGHT, {Game.mapSizeX - edge_dist, y1, Game.mapSizeZ - edge_dist}, {"shift"})
    end
	creep = Spring.CreateUnit(creep2, edge_dist2 + random(0,100), y02, edge_dist2 + random(0,100), 0, team1)
    Spring.GiveOrderToUnit(creep, CMD.FIGHT, {Game.mapSizeX - edge_dist3, yc1, edge_dist3}, {"shift"})
	Spring.GiveOrderToUnit(creep, CMD.FIGHT, {Game.mapSizeX - edge_dist, y1, Game.mapSizeZ - edge_dist}, {"shift"})
	
	for i = 1,creepcount do -- bottom left, team 1
		creep = SpawnCreep1(Game.mapSizeX - edge_dist2, y12, Game.mapSizeZ - edge_dist2, team2)
		Spring.GiveOrderToUnit(creep, CMD.FIGHT, {edge_dist3, yc2, Game.mapSizeZ - edge_dist3}, {"shift"})
		Spring.GiveOrderToUnit(creep, CMD.FIGHT, {edge_dist, y0, edge_dist}, {"shift"})
    end
	creep = Spring.CreateUnit(creep2, Game.mapSizeX - edge_dist2 - random(0,100), y12, Game.mapSizeZ - edge_dist2 - random(0,100), 0, team2)
    Spring.GiveOrderToUnit(creep, CMD.FIGHT, {edge_dist3, yc2, Game.mapSizeZ - edge_dist3}, {"shift"})
	Spring.GiveOrderToUnit(creep, CMD.FIGHT, {edge_dist, y0, edge_dist}, {"shift"})
	
	for i = 1,creepcount do -- top right, team 1
		creep = SpawnCreep1(Game.mapSizeX - edge_dist2, y12, Game.mapSizeZ - edge_dist2, team2)
		Spring.GiveOrderToUnit(creep, CMD.FIGHT, {Game.mapSizeX - edge_dist3, yc1, edge_dist3}, {"shift"})
		Spring.GiveOrderToUnit(creep, CMD.FIGHT, {edge_dist, y0, edge_dist}, {"shift"})
    end
	creep = Spring.CreateUnit(creep2, Game.mapSizeX - edge_dist2 - random(0,100), y12, Game.mapSizeZ - edge_dist2 - random(0,100), 0, team2)
    Spring.GiveOrderToUnit(creep, CMD.FIGHT, {Game.mapSizeX - edge_dist3, yc1, edge_dist3}, {"shift"})
	Spring.GiveOrderToUnit(creep, CMD.FIGHT, {edge_dist, y0, edge_dist}, {"shift"})

	for i = 1,creepcount do -- bottom left, team 0
		creep = SpawnCreep1(edge_dist2, y02, edge_dist2, team1)
		Spring.GiveOrderToUnit(creep, CMD.FIGHT, {edge_dist3, yc2, Game.mapSizeZ - edge_dist3}, {"shift"})
		Spring.GiveOrderToUnit(creep, CMD.FIGHT, {Game.mapSizeX - edge_dist, y1, Game.mapSizeZ - edge_dist}, {"shift"})
    end
	creep = Spring.CreateUnit(creep2, edge_dist2 + random(0,100), y02, edge_dist2 + random(0,100), 0, team1)
    Spring.GiveOrderToUnit(creep, CMD.FIGHT, {edge_dist3, yc2, Game.mapSizeZ - edge_dist3}, {"shift"})
	Spring.GiveOrderToUnit(creep, CMD.FIGHT, {Game.mapSizeX - edge_dist, y1, Game.mapSizeZ - edge_dist}, {"shift"})
		
	for i = 1,creepcount do -- mid, team 0
		creep = SpawnCreep1(edge_dist2, y02, edge_dist2, team1)
		Spring.GiveOrderToUnit(creep, CMD.FIGHT, {Game.mapSizeX/2, midy, Game.mapSizeZ/2}, {"shift"})
		Spring.GiveOrderToUnit(creep, CMD.FIGHT, {Game.mapSizeX - edge_dist, y1, Game.mapSizeZ - edge_dist}, {"shift"})
    end
	creep = Spring.CreateUnit(creep2, edge_dist2 + random(0,100), y02, edge_dist2 + random(0,100), 0, team1)
    Spring.GiveOrderToUnit(creep, CMD.FIGHT, {Game.mapSizeX/2, midy, Game.mapSizeZ/2}, {"shift"})
	Spring.GiveOrderToUnit(creep, CMD.FIGHT, {Game.mapSizeX - edge_dist, y1, Game.mapSizeZ - edge_dist}, {"shift"})
	
	for i = 1,creepcount do -- mid, team 1
		creep = SpawnCreep1(Game.mapSizeX - edge_dist2, y12, Game.mapSizeZ - edge_dist2, team2)
		Spring.GiveOrderToUnit(creep, CMD.FIGHT, {Game.mapSizeX/2, midy, Game.mapSizeZ/2}, {"shift"})
		Spring.GiveOrderToUnit(creep, CMD.FIGHT, {edge_dist, y0, edge_dist}, {"shift"})
    end
	creep = Spring.CreateUnit(creep2, Game.mapSizeX - edge_dist2 - random(0,100), y12, Game.mapSizeZ - edge_dist2 - random(0,100), 0, team2)
    Spring.GiveOrderToUnit(creep, CMD.FIGHT, {Game.mapSizeX/2, midy, Game.mapSizeZ/2}, {"shift"})
	Spring.GiveOrderToUnit(creep, CMD.FIGHT, {edge_dist, y0, edge_dist}, {"shift"})

end