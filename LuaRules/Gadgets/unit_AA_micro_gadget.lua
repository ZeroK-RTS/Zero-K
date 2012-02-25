local versionNumber = "v0.5"

--[[   TO DO::

Cooperative targeting to bring down bigger targets
Screamers hold fire until unit is killable

]]--

function gadget:GetInfo()
  return {
    name      = "Anti-air micro",
    desc      = versionNumber .. " Micros missile towers, hacksaws, chainsaws and screamers to distribute fire over air swarms. Without hold fire, will not prevent wasting ammo. Targeting watches reload and prevents trivial overkills, but will refire after short delay. Will prioritize weakest and aim to maximize casualties. Requires low ping for best performance. ",
    author    = "Jseah",
    date      = "14/09/11",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

if (not gadgetHandler:IsSyncedCode()) then
  return
end
--SYNCED--

include("LuaRules/Configs/customcmds.h.lua")

local random = math.random
local TeamUnits          = Spring.GetTeamUnits
local GetPlayerInfo      = Spring.GetPlayerInfo
local GetTeamInfo        = Spring.GetTeamInfo
local GetUnitPosition    = Spring.GetUnitPosition
local GetCommandQueue    = Spring.GetCommandQueue
local GetUnitAllyTeam    = Spring.GetUnitAllyTeam
local GetUnitTeam        = Spring.GetUnitTeam
local GetUnitDefID       = Spring.GetUnitDefID
local GetUnitSeparation  = Spring.GetUnitSeparation
local AreTeamsAllied     = Spring.AreTeamsAllied
local GiveOrder          = Spring.GiveOrderToUnit
local GetUnitsInCylinder = Spring.GetUnitsInCylinder
local GetUnitRules       = Spring.GetUnitRulesParams
local GetUnitRule        = Spring.GetUnitRulesParam
local GetUnitsInRange    = Spring.GetUnitsInSphere
local WeaponState        = Spring.GetUnitWeaponState
local UnitStun           = Spring.GetUnitIsStunned
local Tooltip            = Spring.GetUnitTooltip
local GetHP              = Spring.GetUnitHealth
local isDead             = Spring.GetUnitIsDead
local GetUnitStockpile	 = Spring.GetUnitStockpile
local GetUnitStates      = Spring.GetUnitStates
local isUnitCloaked      = Spring.GetUnitIsCloaked
local inALOS             = Spring.IsPosInAirLos
local inRadar            = Spring.IsPosInRadar
local inLOS              = Spring.IsPosInLos
local GetLOSState        = Spring.GetUnitLosState
local FindUnitCmdDesc    = Spring.FindUnitCmdDesc
local EditUnitCmdDesc    = Spring.EditUnitCmdDesc
local GetUnitCmdDesc     = Spring.GetUnitCmdDescs
local InsertUnitCmdDesc  = Spring.InsertUnitCmdDesc
--[[local AAmicrocmd = {
      id      = CMD_AA_MICRO, 
      type    = CMDTYPE.ICON_MODE,
      name    = "AA micro",
      action  = "aamicro",
      tooltip = "Toggles AA Micro usage of this tower",
      params  = {1, 'On','Off'}
}]]--
local unitAICmdDesc = {
	id      = CMD_UNIT_AI,
	type    = CMDTYPE.ICON_MODE,
	name    = 'Unit AI',
	action  = 'unitai',
	tooltip	= 'Toggles smart unit AI for the unit',
	params 	= {1, 'AI Off','AI On'}
}
local airtargets         = {} -- {id = unitID, incoming = 0, hp = int, team = allyteam, inrange = {}}
local airtargetsref      = {}
local airtargetsmaxcount = {}
local teamcount          = 0
local teams              = {}
local AAdef              = {} -- {id = unitID, range = ud.maxWeaponRange, attacking = nil, counter = 5, reloaded = true, name = ud.name, reloading = {0, 0, 0}, frame = 0, damage = damage per shot, refiredelay = 0, team = allyteam, inrange = {}}
local AAdefreference     = {}
local AAdefmaxcount      = {}
local shot               = {} -- {id = shotID, unitID = ownerID, refID = owner's refID, allyteam = owner's allyteam, prefID = projectile refID in owner's list)
local shotreference      = {}
local shotmaxcount       = 0
local airunitdefs        = {}
local DPSAA              = {["corrl"] = 60, ["corrazor"] = 150, ["armcir"] = 250, ["corflak"] = 360}
local weapondefID        = {}
--[[
   :armca       : crane -- "Crane - Construction Aircraft, Builds at 4.8 m/s"
   :armcsa      : athena -- 
 60:blastwing   : blastwing -- "Blastwing - Bomb Drone"
 59:bladew      : gnat -- "Gnat - Light Paralyzer Drone"
   :armkam      : banshee -- "Banshee - Raider Gunship"
120:corape      : rapier -- "Rapier - Multi-Role/AA Gunship"
   :armbrawl    : brawler -- "Brawler - Assault Gunship"
 58:blackdawn   : blackdawn -- "Black Dawn - Riot/Skirmish Gunship"
134:corcrw      : krow -- "Krow - Flying Fortress"
   :corvalk     : valkyrie (transport) -- "Valkyrie - Air Transport"
125:corbtrans   : vindicator (heavy transport) -- "Vindicator - Armed Heavy Air Transport"
   :attackdrone : commander drone
   :carrydrone  : carrier drone
   :fighter     : avenger
   :corvamp     : vamp -- "Vamp - Air Superiority Fighter"
   :armstiletto_laser: stiletto
   :corhurc2    : firestorm -- "Firestorm - Napalm Bomber"
   :corshad     : shadow -- "Shadow - Precision Bomber"
   :armcybr     : licho -- "Licho - Singularity Bomber"
   :corawac     : vulture

   :chicken_pigeon: pigeon
   :chicken_blimpy: blimpy
   :chicken_roc   : roc
   :chickenflyerqueen: flying queen

148:corrl       : missile tower
 (missile reload 330 frames, missile ready to fire 36 frames, 110 dmg per missile, 30 dps)
146:corrazor    : razors kiss
 (100 dps)
   :corflak     : flak gun
 (360 dps)
194:missiletower: hacksaw
 (missile reload 357 frames, 650 dmg)
 15:armcir      : chainsaw
 (missile reload 40 frames?, use weaponstate-no-string 2nd return, 250 dmg, 250 dps)
206:screamer    : screamer
 (use weaponstate-no-string 2nd return, 1750 dmg)
]]--
local Echo = Spring.Echo

------------------------------
----------CORE LOGIC----------

function checkAAdef()
  local cQueue
  local target
  local AAdefbuff
  for h = 0, teamcount do
  local teammaxcount = AAdefmaxcount[h]
  ----Echo("checking team" .. h .. ", " .. teammaxcount)
    if teammaxcount ~= nil then
	----Echo("team initialized")
  for i = 1, teammaxcount do
    AAdefbuff = AAdef[h].units[i]
    ----Echo(AAdefbuff)
	if AAdefbuff ~= nil then
	  --Echo("ID " .. AAdefbuff.id)
	  if not UnitIsDead(AAdefbuff.id) then
		AAdef[h].units[i].frame = AAdef[h].units[i].frame + 1
		if AAdef[h].units[i].frame == 1 then
		  GiveOrder(AAdef[h].units[i].id, CMD.FIRE_STATE, {0}, {})
		end
		local cstate = isUnitCloaked(AAdefbuff.id)
		local _, _, stun = UnitStun(AAdefbuff.id)
		if cstate ~= nil and cstate ~= AAdefbuff.cstate then
		  AAdefbuff.cstate = cstate
		  if cstate and IsMicro(AAdefbuff.id) then
		    GiveOrder(AAdefbuff.id, CMD.FIRE_STATE, {AAdefbuff.cfire}, {})
		  else
		    GiveOrder(AAdefbuff.id, CMD.FIRE_STATE, {AAdefbuff.fire}, {})
		  end
		end
		if WeaponReady(AAdefbuff.id, i, h) then 
		  --Echo("weapon ready")
		  if AAdefbuff.counter == 0 then
		    --Echo("ready, searching for target hp: " .. AAdef[h].units[i].damage)
			if AAdefbuff.attacking == nil then
			  if not AAdefbuff.cstate and IsMicro(AAdefbuff.id) and not stun then
			    assignTarget(AAdefbuff.id, i, h)
			  end
			  AAdef[h].units[i].counter = AAmaxcounter(AAdefbuff.name)
			  AAdef[h].units[i].refiredelay = AAmaxrefiredelay(AAdefbuff.name)
			end
			if AAdefbuff.refiredelay == 0 then
			  AAdef[h].units[i].skiptarget = AAdef[h].units[i].skiptarget + 1
			  --Echo("skipping " .. AAdef[h].units[i].skiptarget)
			  if not AAdefbuff.cstate and IsMicro(AAdefbuff.id) and not stun then
			    assignTarget(AAdefbuff.id, i, h)
			  end
			  AAdef[h].units[i].counter = 0
			  AAdef[h].units[i].refiredelay = AAmaxrefiredelay(AAdefbuff.name)
			elseif AAdefbuff.attacking ~= nil then
			  AAdef[h].units[i].counter = 0
			  AAdef[h].units[i].refiredelay = AAdef[h].units[i].refiredelay - 1
			end
		  else
		    AAdef[h].units[i].counter = AAdef[h].units[i].counter - 1
		  end
		else
		  --Echo("not ready, deassigning target")
	      if IsMicro(AAdefbuff.id) and AAdefbuff.name ~= "missiletower" then
	        removecommand(AAdefbuff.id)
	        stopcommand(AAdefbuff.id)
		  end
		  unassignTarget(AAdefbuff.id, i, h)
		  AAdef[h].units[i].counter = 0
		end
		for j = 1, AAdef[h].units[i].projectilescount do
		  AAdef[h].units[i].projectiles[j].TOF = AAdef[h].units[i].projectiles[j].TOF - 1
		  if AAdef[h].units[i].projectiles[j].TOF <= 0 then
		    removeShot(AAdef[h].units[i].projectiles[j].id)
			j = j - 1
		  end
		end
	  else
	    removeAA(AAdefbuff.id, h)
	  end
	end
  end
    end
  end
end

function checkairs()
  local airbuff
  local health
  for h = 1, teamcount do
  local teammaxcount = airtargetsmaxcount[h]
    if teammaxcount ~= nil then
      for i = 1, teammaxcount do
         airbuff = airtargets[h].units[i]
	     if airbuff ~= nil then
		   if not UnitIsDead(airbuff.id) then
	         health, _, _, _, _ = GetHP(airtargets[h].units[i].id)
	         airtargets[h].units[i].hp = health
		   else
		     removeAir(airbuff.id, h)
		   end
		 else
	       --removeAir(airbuff.id, h)
	     end
      end
    end
  end
end

function assignTarget(unitID, refID, allyteam)
  local output = getAATargetsinRange(unitID, refID, allyteam) 
  local attacking = AAdef[allyteam].units[refID].attacking
  local notargets = false
  local assign = nil
  local damage = AAdef[allyteam].units[refID].damage
  local skip = AAdef[allyteam].units[refID].skiptarget
  local cdamage = damage
  if output ~= nil then
    --Echo("enemies in range")
    if output[2] ~= 0 then
	  --Echo("visible air in range of tower " .. refID)
	  if AAdef[allyteam].units[refID].name == "missiletower" and AAdef[allyteam].units[refID].reloading[2] ~= 0 then
		damage = damage * 2
	  end
	  if skip > output[2] then
	    AAdef[allyteam].units[refID].skiptarget = 0
	    unassignTarget(unitID, refID, allyteam)
	    if IsMicro(AAdef[allyteam].units[refID].id) then
	      removecommand(AAdef[allyteam].units[refID].id)
	      stopcommand(AAdef[allyteam].units[refID].id)
		end
	  end
	  if AAdef[allyteam].units[refID].name == "missiletower" and escortingAA(unitID, refID, allyteam) then
	    assign = HSBestTarget(output[1], output[2], damage, attacking, cdamage, skip, output[3])
	  elseif AAdef[allyteam].units[refID].name == "screamer" and escortingAA(unitID, refID, allyteam) then
	    assign = HSBestTarget(output[1], output[2], damage, attacking, cdamage, skip, output[3])
	  else
	    assign = BestTarget(output[1], output[2], damage, attacking, cdamage, skip, output[3])
	  end
	  if assign ~= nil then
		if assign ~= attacking then
	      local ateam = GetUnitAllyTeam(assign)
	      local arefID = airtargetsref[ateam].units[assign]
	      unassignTarget(unitID, refID, allyteam)
	      attackTarget(unitID, assign, refID, allyteam)
	      AAdef[allyteam].units[refID].attacking = assign
	      airtargets[ateam].units[arefID].tincoming = airtargets[ateam].units[arefID].tincoming + AAdef[allyteam].units[refID].damage
		  --Echo("id " .. unitID .. " targeting " .. assign .. " " .. airtargets[ateam].units[arefID].name .. ", hp " .. airtargets[ateam].units[arefID].hp .. " incoming " .. airtargets[ateam].units[arefID].incoming)
		end
	  end
	end
	if output[2] == 0 or (output[2]~= 0 and assign == nil) then
	  --Echo("no air in vision")
	  notargets = true
	  local state = GetUnitStates(unitID)
      if AAdef[allyteam].units[refID].name == "corrl" and output[5] ~= 0 and state.firestate ~= 2 then
	    --Echo("Land targets in range " .. output[5])
		if AAdef[allyteam].units[refID].lasttarget ~= nil and not UnitIsDead(AAdef[allyteam].units[refID].lasttarget) and InRange(unitID, AAdef[allyteam].units[refID].lasttarget, AAdef[allyteam].units[refID].range) then
		  assign = AAdef[allyteam].units[refID].lasttarget
		else
		  assign = random(1, output[5])
		  assign = output[4][assign]
		  AAdef[allyteam].units[refID].lasttarget = assign
		end
		if not IsAttacking(unitID) then
		  --Echo("not attacking, assigning target")
		  attackTarget(unitID, assign, refID, allyteam)
		elseif not InRange(unitID, getTarget(unitID), AAdef[allyteam].units[refID].range) then
		  --Echo("attack target not in range, reassigning")
		  attackTarget(unitID, assign, refID, allyteam)
		end
      end
    end
  else
	notargets = true
  end
  if notargets == true then
    --Echo("no visible air targets")
    unassignTarget(unitID, refID, allyteam)
  end
end

function unassignTarget(unitID, refID, allyteam)
  local attacking = AAdef[allyteam].units[refID].attacking
  if attacking ~= nil then
	AAdef[allyteam].units[refID].attacking = nil
	if not UnitIsDead(attacking) then
	  local tteam = GetUnitAllyTeam(attacking)
	  local trefID = nil
	  if tteam ~= nil and airtargetsref[tteam] ~= nil then
	    trefID = airtargetsref[tteam].units[attacking]
	  end
	  if trefID ~= nil then
	    airtargets[tteam].units[trefID].tincoming = airtargets[tteam].units[trefID].tincoming - AAdef[allyteam].units[refID].damage
        --Echo("tower " .. refID .. " was targeting " .. attacking .. ", deassigning from " .. airtargets[tteam].units[trefID].name)
	    if airtargets[tteam].units[trefID].tincoming < 0 then
	      airtargets[tteam].units[trefID].tincoming = 0
	    end
	  end
	end
  end
end

function BestTarget(targets, count, damage, current, cdamage, skip, cost)
  local refID
  local onehit = false
  local best = 0
  local bestcost = 0
  local besthp = 0
  local targetteam
  local incoming
  local hp
  local airbuff
  --local hpafter
for i = 1, count do
  if not UnitIsDead(targets[i]) then
    _, refID, targetteam, airbuff = GetAirUnit(targets[i])
	if airbuff ~= nil then
	  incoming = airbuff.incoming + airbuff.tincoming
	  hp = airbuff.hp
	  if airbuff.id == current then
	    incoming = incoming - cdamage
	  end
	  --Echo("considering target, id: " .. targets[i] .. ", name: " .. airtargets[targetteam].units[refID].name .. ", hp: " .. hp .. ", incoming: " .. incoming)
	  if hp <= incoming + damage then
	    if onehit == false then
		  if hp - incoming >= 0 then
		    --hpafter = hp - incoming
			if skip == 0 then
		      best = i
			  bestcost = cost[i]
			  besthp = hp - incoming - damage
	          onehit = true
			  --Echo(best)
			else
			  skip = skip - 1
			end
	      end
		else
		  if hp - incoming >= 0 and bestcost > cost[i] then
		    --hpafter = hp - incoming
			if skip == 0 then
		      best = i
			  bestcost = cost[i]
			  besthp = hp - incoming - damage
			else
			  skip = skip - 1
			end
		  elseif hp - incoming >= 0 and hp - incoming - damage >= besthp and bestcost == cost[i] then
		    --hpafter = hp - incoming
			if skip == 0 then
		      best = i
			  bestcost = cost[i]
			  besthp = hp - incoming - damage
			else
			  skip = skip - 1
			end
		  end
		end
	  elseif onehit == false then
	    if best ~= 0 then
	      if hp - incoming >= 0 and hp - incoming <= besthp then
		    --hpafter = hp - incoming
			if skip == 0 then
		      best = i
			  besthp = hp - incoming
			else
			  skip = skip - 1
			end
		  end
		else
		  if hp - incoming >= 0 then
		    --hpafter = hp - incoming
			if skip == 0 then
		      best = i
			  besthp = hp - incoming
			else
			  skip = skip - 1
			end
		  end
		end
	  end
	end
  end
end
  if best ~= 0 then
    best = targets[best]
    ----Echo("best target found, expected hp after damage " .. hpafter)
    return best
  end
  --Echo("preventing overkill")
  return nil
end

function HSBestTarget(targets, count, damage, current, cdamage, skip, cost)
  local maxhp
  local refID
  local onehit = false
  local best = 0
  local bestcost = 0
  local besthp = 0
  local targetteam
  local incoming
  local hp
  --local hpafter
for i = 1, count do
  if not UnitIsDead(targets[i]) then
    _, refID, targetteam, airbuff = GetAirUnit(targets[i])
	if airbuff ~= nil then
	  incoming = airbuff.incoming + airbuff.tincoming
	  hp = airbuff.hp
	  if airbuff.id == current then
	    incoming = incoming - cdamage
	  end
      _, maxhp = GetHP(targets[i])
	  local unitDefID = GetUnitDefID(targets[i])
	  local ud = UnitDefs[unitDefID]
	  if (maxhp > 650 or ud.name == "corhurc2") and ud.name ~= "corvamp" then
	    if hp <= incoming + damage then
	      if onehit == false then
		    if hp - incoming >= 0 then
		      --hpafter = hp - incoming
			  if skip == 0 then
		        best = i
				bestcost = cost[i]
			    besthp = hp - incoming - damage
	            onehit = true
			  else
			    skip = skip - 1
			  end
		    end
		  else
		    if bestcost > cost[i] then
		      --hpafter = airtargets[refID].hp - airtargets[refID].incoming
		      if skip == 0 then
			    best = i
				bestcost = cost[i]
			    besthp = hp - incoming - damage
			  else
			    skip = skip - 1
			  end
			elseif hp - incoming >= 0 and hp - incoming - damage >= besthp and bestcost == cost[i] then
		      if skip == 0 then
			    best = i
				bestcost = cost[i]
			    besthp = hp - incoming - damage
			  else
			    skip = skip - 1
			  end
		    end
		  end
	    elseif onehit == false then
  	      if best ~= 0 then
	        if hp - incoming >= 0 and hp - incoming <= besthp then
		      --hpafter = airtargets[refID].hp - airtargets[refID].incoming
			  if skip == 0 then
		        best = i
			    besthp = hp - incoming
			  else
			    skip = skip - 1
			  end
		    end
		  else
		    if hp - incoming >= 0 then
		      --hpafter = airtargets[refID].hp - airtargets[refID].incoming
			  if skip == 0 then
		        best = i
			    besthp = hp - incoming
			  else
			    skip = skip - 1
			  end
		    end
		  end
	    end
	  end
	end
  end
end
  if best ~= 0 then
    best = targets[best]
    --Echo("best target found, expected hp after damage " .. hpafter)
    return best
  end
  --Echo("preventing overkill")
  return nil
end

function getAATargetsinRange(unitID, refID, allyteam)
  local targets = {}
  local targetscost = {}
  local ltargets = {}
  local targetscount = 1
  local ltargetscount = 1
  local x, y, z = GetUnitPosition(unitID)
  --Echo("getting targets")
  local units = GetUnitsInRange(x, y, z, AAdef[allyteam].units[refID].range)
  local team
  local ud
  local cost
  local defID
  local LOS
  --local sortcontinue
  --Echo(units)
  for i,targetID in ipairs(units) do
    team = GetUnitAllyTeam(targetID)
	if not AreTeamsAllied(team, allyteam) then
	  defID = GetUnitDefID(targetID)
	  ud = UnitDefs[defID]
	  LOS = GetLOSState(targetID, allyteam)
	  if Isair(ud.name) then
	    if LOS["los"] == true or LOS["radar"] == true then
		  ud = airunitdefs[ud.name]
		  cost = ud.cost
		  --[[sortcontinue = targetscount
		  for j = 1, targetscount - 1 do
		    if sortcontinue == targetscount then
		      if targetscost[j] < cost then
			    sortcontinue = j
			    j = targetscount
			  end
			end
		  end
		  j = targetscount
		  targets[j] = targetID
		  targetscost[j] = cost
		  while j ~= sortcontinue do
	        targets[j] = targets[j - 1]
		    targetscost[j] = targetscost[j - 1]
			j = j - 1
			if j == sortcontinue then
			  targets[j] = targetID
			  targetscost[j] = cost
			end
		  end]]--
		  targets[targetscount] = targetID
		  targetscost[targetscount] = targetID
	      targetscount = targetscount + 1
		end
      else
	    if LOS["los"] == true or LOS["radar"] == true then
	      ltargets[ltargetscount] = targetID
	      ltargetscount = ltargetscount + 1
		end
	  end
	end
  end
  if targetscount == 1 and ltargetscount == 1 then
    return nil
  end
  return {targets, targetscount - 1, targetscost, ltargets, ltargetscount - 1}
end

function InRange(unitID, targetID, urange)
  if unitID == nil or targetID == nil or urange == nil or urange == 0 then
    return false
  end
  local uDef = GetUnitDefID(targetID)
  if uDef == nil then
    return false
  end
  uDef = GetUnitDefID(unitID)
  if uDef == nil then
    return false
  end
  local ux, uy, uz = GetUnitPosition(unitID)
  local ex, ey, ez = GetUnitPosition(targetID)
  local dist = nil
  if ux ~= nil and uy ~= nil and uz ~= nil and ex ~= nil and ey ~= nil and ez ~= nil then
    dist = ((ux-ex)^2 + (uy-ey)^2 +(uz-ez)^2)^0.5
  end
  if dist ~= nil then
    if dist < (urange - 1) then
      return true
    end
	return false
  else
    return false
  end
end

function WeaponReady(unitID, refID, allyteam)
  local ready
  local rframe
  _, ready, _, _, _ = WeaponState(unitID, 0)
  rframe = AAdef[allyteam].units[refID].frame
  if ready == false or ready == true then
  if ready == false then
    --Echo("weapon not ready")
	if AAdef[allyteam].units[refID].reloaded ~= ready then
	  --Echo("id " .. unitID .. "weapon fired!")
	  AAdef[allyteam].units[refID].reloaded = ready
	  AAdef[allyteam].units[refID].skiptarget = 0
	  if AAdef[allyteam].units[refID].name == "corrl" and AAdef[allyteam].units[refID].reloading[1] ~= rframe and AAdef[allyteam].units[refID].reloading[2] ~= rframe and AAdef[allyteam].units[refID].reloading[3] ~= rframe then
	    local lowestreloading = 3
	    if AAdef[allyteam].units[refID].reloading[2] < AAdef[allyteam].units[refID].reloading[lowestreloading] then
	      lowestreloading = 2
	    end
	    if AAdef[allyteam].units[refID].reloading[1] < AAdef[allyteam].units[refID].reloading[lowestreloading] then
	      lowestreloading = 1
	    end
        AAdef[allyteam].units[refID].reloading[lowestreloading] = rframe
	  end
	  if AAdef[allyteam].units[refID].name == "missiletower" then
	    AAdef[allyteam].units[refID].reloading[1] = rframe
	  end
	end
	if AAdef[allyteam].units[refID].name == "missiletower" and rframe >= AAdef[allyteam].units[refID].reloading[1] + 30 and rframe <= AAdef[allyteam].units[refID].reloading[1] + 37 then
	  AAdef[allyteam].units[refID].reloading[2] = 0
	  --Echo("missile tower 2nd")
	  return true
	end
	return false
  else
    --Echo("weapon ready")
	if AAdef[allyteam].units[refID].reloaded ~= ready then
	  AAdef[allyteam].units[refID].reloaded = ready
	end
	if AAdef[allyteam].units[refID].name == "corrl" then
	  local lowestreloading = 3
	  if AAdef[allyteam].units[refID].reloading[2] < AAdef[allyteam].units[refID].reloading[lowestreloading] then
	    lowestreloading = 2
	  end
	  if AAdef[allyteam].units[refID].reloading[1] < AAdef[allyteam].units[refID].reloading[lowestreloading] then
	    lowestreloading = 1
	  end
      --Echo(AAdef[allyteam].units[refID].reloading[lowestreloading])
      if AAdef[allyteam].units[refID].reloading[lowestreloading] + 330 >= AAdef[allyteam].units[refID].frame then
		--Echo("out of missiles" .. AAdef[allyteam].units[refID].reloading[lowestreloading] .. " " .. AAdef[allyteam].units[refID].frame)
		return false
      end
	end
	if AAdef[allyteam].units[refID].name == "screamer" then
	  if GetUnitStockpile(unitID) == 0 then
	    return false
	  end
	end
	if AAdef[allyteam].units[refID].name == "missiletower" then
	  AAdef[allyteam].units[refID].reloading[2] = -2000
	end
	return true
  end
  end
  --Echo("cannot read")
  return false
end

------------------------------
-----------FUNCTIONS----------

function UnitIsDead(unitID)
  local uDef = isDead(unitID)
  if uDef == false and uDef ~= nil then
    return false
  end
  return true
end

function escortingAA(unitID, refID, allyteam)
  local x, y, z = GetUnitPosition(unitID)
  local units = GetUnitsInRange(x, y, z, AAdef[allyteam].units[refID].range / 2)
  local escort = 0
  for i,AAID in ipairs(units) do
    team = GetUnitAllyTeam(AAID)
	_, _, stun = UnitStun(AAID)
	if AreTeamsAllied(team, allyteam) and not stun then
	  local unitDefID = GetUnitDefID(AAID)
	  local ud = UnitDefs[unitDefID]
	  escort = escort + ( DPSAA[ud.name] or 0 )
	end
  end
  if escort >= 300 then
    return true
  end
  return false
end

function getTarget(unitID)
  local cQueue = GetCommandQueue(unitID)
  if cQueue[1] ~= nil then
    if cQueue[1].id == CMD.ATTACK then
	  if cQueue[1].params[2] == nil then
        return cQueue[1].params[1]
	  end
    end
  end
  return nil
end

function IsAttacking(unitID)
  local cQueue = GetCommandQueue(unitID)
  if cQueue[1] ~= nil then
    if cQueue[1].id == CMD.ATTACK then
	  if cQueue[1].params[2] == nil then
	    return true
	  end
	end
  end
  return false
end

function attackTarget(unitID, targetID, refID, allyteam)
  attackcommand(unitID, targetID)
  AAdef[allyteam].units[refID].attacking = targetID
end

function removecommand(unitID)
  local cQueue = GetCommandQueue(unitID)
  if cQueue[1] ~= nil then
    GiveOrder(unitID, CMD.REMOVE, {cQueue[1].tag}, {})
  end
end

function attackcommand(unitID, targetID)
  --GiveOrder(unitID, CMD.INSERT, {0, CMD.ATTACK, CMD.OPT_ALT, targetID}, {"alt"})
  GiveOrder(unitID, CMD.ATTACK, {targetID}, {})
end

function removetarget(unitID)
  --GiveOrder(unitID, CMD.INSERT, {0, CMD.ATTACK, CMD.OPT_ALT, targetID}, {"alt"})
  GiveOrder(unitID, CMD_UNIT_CANCEL_TARGET, {}, {})
end

function stopcommand(unitID)
  GiveOrder(unitID, CMD.STOP, {}, {})
end

function IsMicro(unitID)
if unitID ~= nil then
  local cmdDescID = FindUnitCmdDesc(unitID, CMD_UNIT_AI)
  local cmdDesc = GetUnitCmdDesc(unitID, cmdDescID, cmdDescID)
  local nparams = cmdDesc[1].params
  if nparams[1] == '1' then
    return true
  else
    return false
  end
end
end

function TimeInRange(unitID, refID, allyteam, targetID)
  
end

------------------------------
-----------CONSTANTS----------

function IsAA(name)
  if name == "corrl" or name == "missiletower" or name == "armcir" or name == "screamer" then -- or name == "corrazor"  then
    return true
  end
  --[[if name == "armarad" then
    return true
  end]]--
  return false
end

--[[function DPSAA(name)
  if name == "corrl" then
    return 60
  end
  if name == "corrazor" then
    return 100
  end
  if name == "armcir" then
    return 250
  end
  if name == "corflak" then -- or name == "corrazor"  then
    return 360
  end
  if name == "screamer" then -- or name == "corrazor"  then
    return 1750
  end
  return 0
end]]--

function AAmaxcounter(name)
  if name == "missiletower" then -- or name == "corrazor"  then
    return 3
  end
  if name == "screamer" then -- or name == "corrazor"  then
    return 10
  end
  return 3
end

function AAmaxrefiredelay(name)
  if name == "missiletower" or name == "screamer" then -- or name == "corrazor"  then
    return 20
  end
  if name == "armcir" then
    return 30
  end
  return 25
end

--[[function IsMoveTypeAir(unitID)
  local move = Tooltip(unitID)
  if move == "Blastwing - Bomb Drone" or move == "Gnat - Light Paralyzer Drone" or move == "Banshee - Raider Gunship" or move == "Rapier - Multi-Role/AA Gunship" or move == "Brawler - Assault Gunship" or move == "Black Dawn - Riot/Skirmish Gunship" or move == "Krow - Flying Fortress" or move == "Valkyrie - Air Transport" or move == "Vindicator - Armed Heavy Air Transport" then
    return true
  end
  if move == "Vamp - Air Superiority Fighter" or move == "Firestorm - Napalm Bomber" or move == "Shadow - Precision Bomber" or move == "Licho - Singularity Bomber" then
    return true
  end
  if move == "Pigeon - Flying Spore Scout" or move == "Blimpy - Dodo Bomber" or move == "Roc - Heavy Attack Flyer" or move == "Chicken Flyer Queen - Clucking Hell!" then
    return true
  end
  return false
end]]--

function Isair(name)
  if airunitdefs[name] ~= nil then
    return true
  end
  return false
end

function getShotDamage(name)
  if name == "corrl" then
    return 110
  end
  if name == "missiletower" then
    return 650
  end
  if name == "armcir" then
    return 250
  end
  if name == "screamer" then
    return 1750
  end
  return 0
end

function getshotVelocity(name)
  if name == "corrl" then
    return 750
  end
  if name == "missiletower" then
    return 900
  end
  if name == "armcir" then
    return 800
  end
  if name == "screamer" then
    return 1600
  end
  return nil
end

function getairMoveSpeed(name)
  if airunitdefs[name] ~= nil then
    return airunitdefs[name].maxspeed
  end
  return 0
end

function getairCost(name)
  if airunitdefs[name] ~= nil then
    return airunitdefs[name].cost
  end
  return 0
end

function getairMaxHP(name)
  if airunitdefs[name] ~= nil then
    return airunitdefs[name].hp
  end
  return 0
end

------------------------------
---------MEM MANAGEMENT-------

function addAA(unitID, unitDefID, name, allyteam)
  local ud = UnitDefs[unitDefID]
    local sdamage = getShotDamage(name)
	if AAdef[allyteam] == nil then
	  AAdef[allyteam] = {units = {}}
	  AAdefreference[allyteam] = {units = {}}
	  AAdefmaxcount[allyteam] = 0
	  if allyteam > teamcount then
	    teamcount = allyteam
	  end
	end
    AAdef[allyteam].units[AAdefmaxcount[allyteam] + 1] = {id = unitID, range = ud.maxWeaponRange, attacking = nil, counter = AAmaxcounter(name), reloaded = true, name = name, reloading = {-2000, -2000, -2000}, frame = 0, damage = sdamage - 5, lasttarget = nil, refiredelay = 0, team = allyteam, inrange = {}, projectiles = {}, projectilescount = 0, shotspeed = getshotVelocity(name), cstate = false, cfire = 2, fire = 0, skiptarget = 0}
    AAdefreference[allyteam].units[unitID] = AAdefmaxcount[allyteam] + 1
    AAdefmaxcount[allyteam] = AAdefmaxcount[allyteam] + 1
end

function addAir(unitID, unitDefID, name, allyteam)
  local health, _, _, _, _ = GetHP(unitID)
  if airtargets[allyteam] == nil then
	airtargets[allyteam] = {units = {}}
	airtargetsref[allyteam] = {units = {}}
	airtargetsmaxcount[allyteam] = 0
	if allyteam > teamcount then
	  teamcount = allyteam
	end
  end
  airtargets[allyteam].units[airtargetsmaxcount[allyteam] + 1] = {id = unitID, name = name, tincoming = 0, incoming = 0, hp = health, team = allyteam, inrange = {}}
  airtargetsref[allyteam].units[unitID] = airtargetsmaxcount[allyteam] + 1
  airtargetsmaxcount[allyteam] = airtargetsmaxcount[allyteam] + 1
end

function removeAA(unitID, allyteam)
  if AAdef[allyteam] ~= nil then
  if AAdefreference[allyteam].units[unitID] ~= nil then
    local refID = AAdefreference[allyteam].units[unitID]
	  if AAdefmaxcount[allyteam] > 1 then
        AAdef[allyteam].units[refID] = AAdef[allyteam].units[AAdefmaxcount[allyteam]]
		--Echo("removed unit " .. allyteam .. " " .. refID)
		--Echo(AAdef[allyteam].units[AAdefmaxcount[allyteam]])
	    AAdefreference[allyteam].units[AAdef[allyteam].units[AAdefmaxcount[allyteam]].id] = refID
	  end
	  AAdef[allyteam].units[AAdefmaxcount[allyteam]] = nil
	  AAdefmaxcount[allyteam] = AAdefmaxcount[allyteam] - 1
	AAdefreference[allyteam].units[unitID] = nil
  end
  end
end

function transferAA(unitID, newteam, oldteam)
  refID = AAdefreference[oldteam].units[unitID]
  if AAdef[newteam] == nil then
	AAdef[newteam] = {units = {}}
	AAdefreference[newteam] = {units = {}}
	AAdefmaxcount[newteam] = 0
	if newteam > teamcount then
	  teamcount = newteam
	end
  end
  AAdef[newteam].units[AAdefmaxcount[newteam] + 1] = AAdef[oldteam].units[refID]
  AAdefreference[newteam].units[unitID] = AAdefmaxcount[newteam] + 1
  AAdefmaxcount[newteam] = AAdefmaxcount[newteam] + 1
  removeAA(unitID, oldteam)
	--GiveOrder(unitID, CMD.FIRE_STATE, {1}, {})
    --Echo("AA unit transferred, hold fire order given")
end

function removeAir(unitID, allyteam)
  if airtargetsref[allyteam] ~= nil then
  if airtargetsref[allyteam].units[unitID] ~= nil then
    local refID = airtargetsref[allyteam].units[unitID]
	if airtargetsmaxcount[allyteam] > 1 then
      airtargets[allyteam].units[refID] = airtargets[allyteam].units[airtargetsmaxcount[allyteam]]
	  airtargetsref[allyteam].units[airtargets[allyteam].units[airtargetsmaxcount[allyteam]].id] = refID
	end
	airtargets[allyteam].units[airtargetsmaxcount[allyteam]] = nil
	airtargetsmaxcount[allyteam] = airtargetsmaxcount[allyteam] - 1
	airtargetsref[allyteam].units[unitID] = nil
  end
  end
end

function transferAir(unitID, newteam, oldteam)
  refID = airtargetsref[oldteam].units[unitID]
  if airtargets[newteam] == nil then
	airtargets[newteam] = {units = {}}
	airtargetsref[newteam] = {units = {}}
	airtargetsmaxcount[newteam] = 0
	if newteam > teamcount then
	  teamcount = newteam
	end
  end
  airtargets[newteam].units[airtargetsmaxcount[newteam] + 1] = airtargets[oldteam].units[refID]
  airtargetsref[newteam].units[unitID] = airtargetsmaxcount[newteam] + 1
  airtargetsmaxcount[newteam] = airtargetsmaxcount[newteam] + 1
  removeAir(unitID, oldteam)
	--GiveOrder(unitID, CMD.FIRE_STATE, {1}, {})
    --Echo("AA unit transferred, hold fire order given")
end

function addShot(unitID, refID, allyteam, shotID, targetID)
  shot[shotmaxcount + 1] = {id = shotID, unitID = unitID, refID = refID, allyteam = allyteam, prefID = nil}
  if targetID ~= nil then
    local tallyteam = GetUnitAllyTeam(targetID)
  if airtargetsref[tallyteam] ~= nil then
    local arefID = airtargetsref[tallyteam].units[targetID]
	if airtargets[tallyteam].units[arefID] ~= nil then
      local AAdefbuff = AAdef[allyteam].units[refID]
	  local distance = GetUnitSeparation(unitID, targetID)
	  local flighttime = 30 * distance / AAdefbuff.shotspeed
	  --Echo("shot fired " .. shotID .. " owner " .. unitID .. " target " .. targetID .. " separation " .. distance ..  " TOF " .. flighttime)
      AAdef[allyteam].units[refID].projectiles[AAdefbuff.projectilescount + 1] = {id = shotID, target = targetID, tteam = tallyteam, TOF = flighttime}
	  shot[shotmaxcount + 1].prefID = AAdefbuff.projectilescount + 1
	  AAdef[allyteam].units[refID].projectilescount = AAdefbuff.projectilescount + 1
	  airtargets[tallyteam].units[arefID].incoming = airtargets[tallyteam].units[arefID].incoming + AAdefbuff.damage
	end
  end
  end
  shotreference[shotID] = shotmaxcount + 1
  shotmaxcount = shotmaxcount + 1
end

function removeShot(shotID)
  local shotref = shotreference[shotID]
  if shotref ~= nil then
    local prefID = shot[shotref].prefID
	if prefID ~= nil then
      --Echo("shot hit " .. shotID)
	  local unitID = shot[shotref].unitID
	  local refID = shot[shotref].refID
	  local allyteam = shot[shotref].allyteam
	  local AAdefbuff = AAdef[allyteam].units[refID]
	  if AAdefbuff ~= nil then
	    local target = AAdefbuff.projectiles[prefID].target
	    local _, trefID, tallyteam, airbuff = GetAirUnit(target)
	    if airbuff ~= nil then
		  airtargets[tallyteam].units[trefID].incoming = airtargets[tallyteam].units[trefID].incoming - AAdefbuff.damage
		  if airtargets[tallyteam].units[trefID].incoming < 0 then
		    airtargets[tallyteam].units[trefID].incoming = 0
		  end
	    end
	    if AAdefbuff.projectilescount > 1 then
	      local shotref2 = shotreference[AAdefbuff.projectiles[AAdefbuff.projectilescount].id]
		  shot[shotref2].prefID = prefID
	    end
	    AAdef[allyteam].units[refID].projectiles[prefID] = AAdefbuff.projectiles[AAdefbuff.projectilescount]
	    AAdef[allyteam].units[refID].projectilescount = AAdefbuff.projectilescount - 1
	  end
	end
	if shotmaxcount > 1 and shotref ~= shotmaxcount then
      shot[shotref] = shot[shotmaxcount]
	  shotreference[shot[shotmaxcount].id] = shotref
	end
	shot[shotmaxcount] = nil
	shotmaxcount = shotmaxcount - 1
	shotreference[shotID] = nil
  end
end

function GetUnit(unitID)
if unitID ~= nil then
  local unitDefID = GetUnitDefID(unitID)
  if unitDefID ~= nil then
    local ud = UnitDefs[unitDefID]
  else
    return nil, nil, nil, nil
  end
  local allyteam = GetUnitAllyTeam(unitID)
  if IsAA(ud.name) then
	if AAdefreference[allyteam] ~= nil and AAdefreference[allyteam].units ~= nil then
	  local refID = AAdefreference[allyteam].units[unitID]
	  if refID ~= nil then
	    local AAdefbuff = AAdef[allyteam].units[refID]
	    return unitID, refID, allyteam, AAdefbuff
	  else
	    return unitID, nil, allyteam, nil
	  end
	else
	  return unitID, nil, nil, nil
	end
  end
  if IsAir(ud.name) then
    if airtargetsref[allyteam] ~= nil and airtargetsref[allyteam].units ~= nil then
	  local refID = airtargetsref[allyteam].units[unitID]
	  if refID ~= nil then
	    local airbuff = airtargets[allyteam].units[refID]
	    return unitID, refID, allyteam, airbuff
	  else
	    return unitID, nil, allyteam, nil
	  end
	else
	  return unitID, nil, nil, nil
	end
  end
end
return nil, nil, nil, nil
end

function GetAAUnit(unitID)
if unitID ~= nil then
  --Echo(unitID)
  local allyteam = GetUnitAllyTeam(unitID)
  --Echo(allyteam)
  if AAdefreference[allyteam] ~= nil and AAdefreference[allyteam].units ~= nil then
	local refID = AAdefreference[allyteam].units[unitID]
	--Echo(refID)
	if refID ~= nil then
	  local AAdefbuff = AAdef[allyteam].units[refID]
	  --Echo(AAdefbuff)
	  return unitID, refID, allyteam, AAdefbuff
	else
	  return unitID, nil, allyteam, nil
	end
  else
	return unitID, nil, nil, nil
  end
end
return nil, nil, nil, nil
end

function GetAirUnit(unitID)
if unitID ~= nil then
  local allyteam = GetUnitAllyTeam(unitID)
  if airtargetsref[allyteam] ~= nil and airtargetsref[allyteam].units ~= nil then
	local refID = airtargetsref[allyteam].units[unitID]
	if refID ~= nil then
	  local airbuff = airtargets[allyteam].units[refID]
	  return unitID, refID, allyteam, airbuff
	else
	  return unitID, nil, allyteam, nil
	end
  else
	return unitID, nil, nil, nil
  end
end
return nil, nil, nil, nil
end

------------------------------
-----------CALL INS-----------

function gadget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
  local ud = UnitDefs[unitDefID]
  if Isair(ud.name) then
    addAir(unitID, unitDefID, ud.name, GetUnitAllyTeam(unitID))
	--Echo("air created")
  end
  if IsAA(ud.name) then
    addAA(unitID, unitDefID, ud.name, GetUnitAllyTeam(unitID))
    InsertUnitCmdDesc(unitID, unitAICmdDesc)
	local cmdDescID = FindUnitCmdDesc(unitID, CMD_UNIT_AI)
	--Echo(cmdDescID)
	EditUnitCmdDesc(unitID, cmdDescID, {params = {1, 'AI Off','AI On'}})
  end
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
  local _, _, _, _, _, allyteam, _, _ = GetTeamInfo(unitTeam)
  local ud = UnitDefs[unitDefID]
  --Echo("Unit Destroyed: " .. unitID)
  if IsAA(ud.name) then
    removeAA(unitID, allyteam)
  end
  if Isair(ud.name) then
    removeAir(unitID, allyteam)
  end
end

function gadget:UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
  local _, _, _, _, _, oldteam, _, _ = GetTeamInfo(oldTeam)
  local _, _, _, _, _, newteam, _, _ = GetTeamInfo(unitTeam)
  local ud = UnitDefs[unitDefID]
  if newteam ~= oldteam then
    if Isair(ud.name) then
      transferAir(unitID, newteam, oldteam)
    end
    if IsAA(ud.name) then
      transferAA(unitID, newteam, oldteam)
    end
  end
end

function gadget:ProjectileCreated(projID, unitID)
if unitID ~= 0 and unitID ~= nil then
  unitdefID = GetUnitDefID(unitID)
  local ud = UnitDefs[unitdefID]
  if IsAA(ud.name) then
    local _, refID, allyteam, AAdefbuff = GetAAUnit(unitID)
	if AAdefbuff ~= nil then
	  --Echo(AAdefbuff)
	  addShot(unitID, refID, allyteam, projID, AAdefbuff.attacking)
	end
  end
end
end

function gadget:ProjectileDestroyed(projID)
  removeShot(projID)
end

function gadget:GameFrame()
  ----Echo("update")
  checkairs()
  checkAAdef()
  --[[
  if speccheck == false then
    checkweapon()
  end
  ]]--
end

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
  if cmdID ~= CMD_UNIT_AI and cmdID ~= CMD.FIRE_STATE then
	return true  -- command was not used
  end
  local ud = UnitDefs[unitDefID]
if cmdID == CMD_UNIT_AI then
  local cmdDescID = FindUnitCmdDesc(unitID, CMD_UNIT_AI)
  local cmdDesc = GetUnitCmdDesc(unitID, cmdDescID, cmdDescID)
  local nparams = cmdDesc[1].params
  --Echo(nparams[1])
  if nparams[1] == '0' then
    nparams = {1, 'AI Off','AI On'}
  else
    nparams = {0, 'AI Off','AI On'}
  end
  EditUnitCmdDesc(unitID, cmdDescID, {params = nparams})
else
  if IsAA(ud.name) then
    local cstate = isUnitCloaked(unitID)
    if cstate then
	  local _, refID, allyteam, AAdefbuff = GetAAUnit(unitID)
	  if allyteam ~= nil and refID ~= nil and AAdefbuff ~= nil then
	    --Echo("cloaked state " .. cmdParams[1])
        if cmdParams[1] == 2 then
          AAdef[allyteam].units[refID].cfire = 2
        elseif cmdParams[1] == 1 then
          AAdef[allyteam].units[refID].cfire = 1
		  --Echo("cloak 1")
	    else
          AAdef[allyteam].units[refID].cfire = 0
        end
	  end
	else
	  local _, refID, allyteam, AAdefbuff = GetAAUnit(unitID)
	  if allyteam ~= nil and refID ~= nil and AAdefbuff ~= nil then
	    --Echo("uncloaked state " .. cmdParams[1])
        if cmdParams[1] == 2 then
          AAdef[allyteam].units[refID].fire = 2
        elseif cmdParams[1] == 1 then
          AAdef[allyteam].units[refID].fire = 1
	    else
          AAdef[allyteam].units[refID].fire = 0
        end
	  end
	end
  end
end
  return true
end

function gadget:Initialize()
  Echo("AA Micro Gadget Enabled")
  
  for id,unitDef in pairs(UnitDefs) do
    if unitDef.name ~= "fakeunit_aatarget" then
      if unitDef.canFly then
	    airunitdefs[unitDef.name] = {hp = unitDef.health, maxspeed = unitDef.speed / 30, cost = unitDef.metalCost}
	    --Echo(unitDef.name, airunitdefs[unitDef.name].hp, airunitdefs[unitDef.name].maxspeed, airunitdefs[unitDef.name].cost)
      end
	end
  end
  
  for i=1,#WeaponDefs do
    local wd = WeaponDefs[i]
	if wd.name:find("corrl") then
	  Script.SetWatchWeapon(i,true)
      weapondefID["corrl"] = i
	end
	if wd.name:find("missiletower") then
	  Script.SetWatchWeapon(i,true)
      weapondefID["missiletower"] = i
	end
	if wd.name:find("armcir") then
	  Script.SetWatchWeapon(i,true)
      weapondefID["armcir"] = i
	end
	if wd.name:find("screamer") then
	  Script.SetWatchWeapon(i,true)
      weapondefID["screamer"] = i
	end
	if wd.name:find("corflak") then
	  --Script.SetWatchWeapon(i,true)
      weapondefID["corflak"] = i
	end
	if wd.name:find("corrazor") then
	  --Script.SetWatchWeapon(i,true)
      weapondefID["corrazor"] = i
	end
  end
end
