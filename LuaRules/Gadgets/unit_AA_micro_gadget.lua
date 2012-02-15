local versionNumber = "v0.33"

function gadget:GetInfo()
  return {
    name      = "Anti-air micro",
    desc      = versionNumber .. " Micros missile towers, hacksaws, chainsaws and screamers to distribute fire over air swarms. Without hold fire, will not prevent wasting ammo. Targeting watches reload and prevents trivial overkills, but will refire after short delay. Will prioritize weakest and aim to maximize casualties. Requires low ping for best performance. ",
    author    = "Jseah",
    date      = "14/09/11",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = false  --  loaded by default?
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
local AreTeamsAllied     = Spring.AreTeamsAllied
local GiveOrder          = Spring.GiveOrderToUnit
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
--[[local FindUnitCmdDesc    = Spring.FindUnitCmdDesc
local InsertUnitCmdDesc  = Spring.InsertUnitCmdDesc
local AAmicrocmd = {
      id      = CMD_AA_MICRO, 
      name    = "AA micro",
      action  = "AA micro",
      type    = CMDTYPE.ICON_MODE,
      tooltip = "Toggles AA Micro usage of this tower",
      params  = { '1', 'On', 'Off'}
}]]--
local airtargets         = {} -- {id = unitID, incoming = 0, hp = int, team = allyteam, inrange = {}}
local airtargetsref      = {}
local airtargetsmaxcount = {}
local teamcount          = 0
local teams              = {}
local AAdef              = {} -- {id = unitID, range = ud.maxWeaponRange, attacking = nil, counter = 5, reloaded = true, name = ud.name, reloading = {0, 0, 0}, frame = 0, damage = damage per shot, refiredelay = 0, team = allyteam, inrange = {}}
local AAdefreference     = {}
local AAdefmaxcount      = {}
local DPSAA              = {["corrl"] = 60, ["corrazor"] = 150, ["armcir"] = 250, ["corflak"] = 360, ["screamer"] = 1750}
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
		if WeaponReady(AAdefbuff.id, i, h) then 
		  --Echo("weapon ready")
		  if AAdefbuff.counter == 0 then
		    --Echo("ready, searching for target hp: " .. AAdef[h].units[i].damage)
			local cstate = isUnitCloaked(AAdefbuff.id)
			if not cstate then
			  assignTarget(AAdefbuff.id, i, h)
			end
			AAdef[h].units[i].counter = AAmaxcounter(AAdefbuff.name)
			AAdef[h].units[i].refiredelay = AAmaxrefiredelay(AAdefbuff.name)
		  else
		    AAdef[h].units[i].counter = AAdef[h].units[i].counter - 1
		  end
		else
		  --Echo("not ready, deassigning target")
		  local state = GetUnitStates(AAdefbuff.id)
		  local cstate = isUnitCloaked(AAdefbuff.id)
	      if state.firestate ~= 2 and not cstate and AAdefbuff.name ~= "missiletower" then
	        removecommand(AAdefbuff.id)
	        stopcommand(AAdefbuff.id)
		  end
		  if AAdefbuff.refiredelay == 0 then
		    unassignTarget(AAdefbuff.id, i, h)
		  else
		    AAdef[h].units[i].refiredelay = AAdef[h].units[i].refiredelay - 1
		  end
		  AAdef[h].units[i].counter = 0
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
  local cdamage = damage
  if output ~= nil then
    --Echo("enemies in range")
    if output[2] ~= 0 then
	  --Echo("visible air in range of tower " .. refID)
	  if AAdef[allyteam].units[refID].name == "missiletower" and AAdef[allyteam].units[refID].reloading[2] ~= 0 then
		damage = damage * 2
	  end
	  if AAdef[allyteam].units[refID].name == "missiletower" and escortingAA(unitID, refID, allyteam) then
	    assign = HSBestTarget(output[1], output[2], damage, attacking, cdamage)
	  else
	    assign = BestTarget(output[1], output[2], damage, attacking, cdamage)
	  end
	  if assign ~= nil then
		if assign ~= attacking then
	      local ateam = GetUnitAllyTeam(assign)
	      local arefID = airtargetsref[ateam].units[assign]
	      unassignTarget(unitID, refID, allyteam)
	      attackTarget(unitID, assign, refID, allyteam)
	      AAdef[allyteam].units[refID].attacking = assign
	      airtargets[ateam].units[arefID].incoming = airtargets[ateam].units[arefID].incoming + AAdef[allyteam].units[refID].damage
		  --Echo("id " .. unitID .. " targeting " .. assign .. " " .. airtargets[ateam].units[arefID].name .. ", hp " .. airtargets[ateam].units[arefID].hp .. " incoming " .. airtargets[ateam].units[arefID].incoming)
		end
	  end
	end
	if output[2] == 0 or (output[2]~= 0 and assign == nil) then
	  --Echo("no air in vision")
	  notargets = true
	  local state = GetUnitStates(unitID)
      if AAdef[allyteam].units[refID].name == "corrl" and output[4] ~= 0 and state.firestate ~= 2 then
	    --Echo("Land targets in range " .. output[4])
		if AAdef[allyteam].units[refID].lasttarget ~= nil and not UnitIsDead(AAdef[allyteam].units[refID].lasttarget) and InRange(unitID, AAdef[allyteam].units[refID].lasttarget, AAdef[allyteam].units[refID].range) then
		  assign = AAdef[allyteam].units[refID].lasttarget
		else
		  assign = random(1, output[4])
		  assign = output[3][assign]
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
	    airtargets[tteam].units[trefID].incoming = airtargets[tteam].units[trefID].incoming - AAdef[allyteam].units[refID].damage
        --Echo("tower " .. refID .. " was targeting " .. attacking .. ", deassigning from " .. airtargets[tteam].units[trefID].name)
	    if airtargets[tteam].units[trefID].incoming < 0 then
	      airtargets[tteam].units[trefID].incoming = 0
	    end
	  end
	end
  end
end

function BestTarget(targets, count, damage, current, cdamage)
  local refID
  local onehit = false
  local best = 0
  local besthp = 0
  local targetteam
  local incoming
  local hp
  --local hpafter
for i = 1, count do
  if not UnitIsDead(targets[i]) then
    targetteam = GetUnitAllyTeam(targets[i])
	refID = airtargetsref[targetteam].units[targets[i]]
	if refID ~= nil then
	  incoming = airtargets[targetteam].units[refID].incoming
	  hp = airtargets[targetteam].units[refID].hp
	  if airtargets[targetteam].units[refID].id == current then
	    incoming = incoming - cdamage
	  end
	  --Echo("considering target, id: " .. targets[i] .. ", name: " .. airtargets[targetteam].units[refID].name .. ", hp: " .. hp .. ", incoming: " .. incoming)
	  if hp <= incoming + damage then
	    if onehit == false then
		  if hp - incoming >= 0 then
		    --hpafter = hp - incoming
		    best = i
			besthp = hp - incoming - damage
	        onehit = true
			end
		else
		  if hp - incoming >= 0 and hp - incoming - damage >= besthp then
		    --hpafter = hp - incoming
		    best = i
			besthp = hp - incoming - damage
		  end
		end
	  elseif onehit == false then
	    if best ~= 0 then
	      if hp - incoming >= 0 and hp - incoming <= besthp then
		    --hpafter = hp - incoming
		    best = i
			besthp = hp - incoming
		  end
		else
		  if hp - incoming >= 0 then
		    --hpafter = hp - incoming
		    best = i
			besthp = hp - incoming
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
  Echo("preventing overkill")
  return nil
end

function HSBestTarget(targets, count, damage, current, cdamage)
  local maxhp
  local refID
  local onehit = false
  local best = 0
  local besthp = 0
  local targetteam
  local incoming
  local hp
  --local hpafter
for i = 1, count do
  if not UnitIsDead(targets[i]) then
    targetteam = GetUnitAllyTeam(targets[i])
    refID = airtargetsref[targetteam].units[targets[i]]
	if refID ~= nil then
	  incoming = incoming
	  hp = airtargets[targetteam].units[refID].hp
	  if airtargets[targetteam].units[refID].id == current then
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
		      best = i
			  besthp = hp - incoming - damage
	          onehit = true
		    end
		  else
		    if hp - incoming >= 0 and hp - incoming - damage >= besthp then
		      --hpafter = airtargets[refID].hp - airtargets[refID].incoming
		      best = i
			  besthp = hp - incoming - damage
		    end
		  end
	    elseif onehit == false then
  	      if best ~= 0 then
	        if hp - incoming >= 0 and hp - incoming <= besthp then
		      --hpafter = airtargets[refID].hp - airtargets[refID].incoming
		      best = i
			  besthp = hp - incoming
		    end
		  else
		    if hp - incoming >= 0 then
		      --hpafter = airtargets[refID].hp - airtargets[refID].incoming
		      best = i
			  besthp = hp - incoming
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
  local ltargets = {}
  local targetscount = 1
  local ltargetscount = 1
  local x, y, z = GetUnitPosition(unitID)
  --Echo("getting targets")
  local units = GetUnitsInRange(x, y, z, AAdef[allyteam].units[refID].range)
  local team
  local ud
  local defID
  local LOS
  --Echo(units)
  for i,targetID in ipairs(units) do
    team = GetUnitAllyTeam(targetID)
	if not AreTeamsAllied(team, allyteam) then
	  defID = GetUnitDefID(targetID)
	  ud = UnitDefs[defID]
	  LOS = GetLOSState(targetID, allyteam)
	  if Isair(ud.name) then
	    if LOS["los"] == true or LOS["radar"] == true then
	      targets[targetscount] = targetID
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
  return {targets, targetscount - 1, ltargets, ltargetscount - 1}
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
    return 7
  end
  if name == "armcir" then
    return 15
  end
  return 4
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

function IsMoveTypeAir(unitID)
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
end

function Isair(name)
  if name == "bladew" or name == "blastwing" or name == "armkam" or name == "corape" or name == "armbrawl" or name == "blackdawn" or name == "corcrw" or name == "corvalk" or name == "corbtrans"  then
    return true
  end
  if name == "armca" or name == "armcsa" or name == "fighter" or name == "corvamp" or name == "armstiletto_laser" or name == "corhurc2" or name == "corshad" or name == "armcybr" or name == "corawac" then
    return true
  end
  if name == "attackdrone" or name == "carrydrone" or name == "chicken_pigeon" or name == "chicken_blimpy" or name == "chicken_roc" or name == "chickenflyerqueen" then
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
    AAdef[allyteam].units[AAdefmaxcount[allyteam] + 1] = {id = unitID, range = ud.maxWeaponRange, attacking = nil, counter = AAmaxcounter(name), reloaded = true, name = name, reloading = {-2000, -2000, -2000}, frame = 0, damage = sdamage - 5, lasttarget = nil, refiredelay = 0, team = allyteam, inrange = {}}
    AAdefreference[allyteam].units[unitID] = AAdefmaxcount[allyteam] + 1
	--insertcommandstate(unitID)
	GiveOrder(unitID, CMD.FIRE_STATE, {1}, {})
    --Echo("new AA, hold fire order given")
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
  airtargets[allyteam].units[airtargetsmaxcount[allyteam] + 1] = {id = unitID, name = name, incoming = 0, hp = health, team = allyteam, inrange = {}, fired = {}, firedtime = {}}
  airtargetsref[allyteam].units[unitID] = airtargetsmaxcount[allyteam] + 1
  airtargetsmaxcount[allyteam] = airtargetsmaxcount[allyteam] + 1
end

function removeAA(unitID, allyteam)
  if AAdef[allyteam] ~= nil then
  if AAdefreference[allyteam].units[unitID] ~= nil then
    local refID = AAdefreference[allyteam].units[unitID]
	if AAdefmaxcount[allyteam] > 1 then
      AAdef[allyteam].units[refID] = AAdef[allyteam].units[AAdefmaxcount[allyteam]]
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
	GiveOrder(unitID, CMD.FIRE_STATE, {1}, {})
    --Echo("AA unit transferred, hold fire order given")
  removeAA(unitID, oldteam)
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
	GiveOrder(unitID, CMD.FIRE_STATE, {1}, {})
    --Echo("AA unit transferred, hold fire order given")
  removeAir(unitID, oldteam)
end

------------------------------
-----------CALL INS-----------

function gadget:UnitFinished(unitID, unitDefID, unitTeam)
  local ud = UnitDefs[unitDefID]
  if IsAA(ud.name) then
    addAA(unitID, unitDefID, ud.name, GetUnitAllyTeam(unitID))
	--Echo("AA created")
  end
  --Echo(GetUnitStates(unitID).firestate)
end

function gadget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
  local ud = UnitDefs[unitDefID]
  if Isair(ud.name) then
    addAir(unitID, unitDefID, ud.name, GetUnitAllyTeam(unitID))
	--Echo("air created")
  end
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
  local _, _, _, _, _, allyteam, _, _ = GetTeamInfo(unitTeam)
  local ud = UnitDefs[unitDefID]
  --Echo("Unit Destroyed: " .. allyteam)
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
  if Isair(ud.name) then
    transferAir(unitID, newteam, oldteam)
  end
  if IsAA(ud.name) then
    transferAA(unitID, newteam, oldteam)
  end
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

function gadget:Initialize()
  Echo("AA Micro Gadget Enabled")
end
