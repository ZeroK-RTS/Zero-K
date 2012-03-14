local versionNumber = "v1.0"

--[[   TO DO::

Restructure memory to use ipairs and table.remove, instead of unitID <-> refID
Basic flight prediction of aircraft (affects single and global targeting)
Control targeting of razor and flak
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
--[[
Spring.GetUnitHeading 
 ( number unitID ) -> nil | number heading
 
Spring.GetUnitVelocity 
 ( number unitID ) -> nil | number velx, number vely, number velz
]]--
local GetCommandQueue    = Spring.GetCommandQueue
local GetUnitAllyTeam    = Spring.GetUnitAllyTeam
local GetUnitTeam        = Spring.GetUnitTeam
local GetUnitDefID       = Spring.GetUnitDefID
local GetUnitSeparation  = Spring.GetUnitSeparation
local AreTeamsAllied     = Spring.AreTeamsAllied
local SGiveOrder         = Spring.GiveOrderToUnit
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
local airteamcount       = 0
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
local globalassignment   = {}
local globalassignmentcount   = 1
local globalassignmentcounter = 30
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
  local target, trefID, tallyteam, airbuff
  local counteris0
  local AAdefbuff
  local weaponready
  local nextshot
  for h = 0, teamcount do
  local teammaxcount = AAdefmaxcount[h]
  ----Echo("checking team" .. h .. ", " .. teammaxcount)
    if teammaxcount ~= nil then
	----Echo("team initialized")
  local i = 1
  while i <= teammaxcount do
    AAdefbuff = AAdef[h].units[i]
    --Echo(AAdefbuff)
	if AAdefbuff ~= nil then
	  --Echo("ID " .. AAdefbuff.id)
	  if not UnitIsDead(AAdefbuff.id) then
        local targets = nil
		local cstate = isUnitCloaked(AAdefbuff.id)
		local morphing = IsMorphing(AAdefbuff.id)
		AAdef[h].units[i].frame = AAdefbuff.frame + 1
		if AAdefbuff.frame == 1 then
          local cmdDescID = FindUnitCmdDesc(AAdefbuff.id, CMD.FIRE_STATE)
          local cmdDesc = GetUnitCmdDesc(AAdefbuff.id, cmdDescID, cmdDescID)
          local nparams = cmdDesc[1].params
	      AAdef[h].units[i].cfire = nparams[1] + 0
		  GiveOrder(AAdefbuff.id, CMD.FIRE_STATE, 0, i, h)
		end
		if cstate ~= nil and cstate ~= AAdefbuff.cstate then
		  AAdef[h].units[i].cstate = cstate
		end
		if AAdefbuff.morph ~= morphing then
		  AAdef[h].units[i].morph = morphing
		end
		if IsIdle(AAdefbuff.id) then
		  AAdef[h].units[i].orderreceived = false
		end
		if morphing or cstate or AAdefbuff.orderreceived then
		  if IsMicroCMD(AAdefbuff.id) then
		    --Echo("player order, disabling control")
		    GiveOrder(AAdefbuff.id, CMD_UNIT_AI, 0, i, h)
		    GiveOrder(AAdefbuff.id, CMD.FIRE_STATE, AAdefbuff.cfire, i, h)
		  end
		end
		if IsIdle(AAdefbuff.id) and not cstate and not morphing then
		  if not IsMicroCMD(AAdefbuff.id) and not AAdefbuff.deactivate then
		    GiveOrder(AAdefbuff.id, CMD_UNIT_AI, 1, i, h)
		    GiveOrder(AAdefbuff.id, CMD.FIRE_STATE, AAdefbuff.fire, i, h)
		  end
		end
		weaponready, nextshot = WeaponReady(AAdefbuff.id, i, h)
		AAdef[h].units[i].nextshot = nextshot
		--Echo(nextshot)
		if AAdef[h].units[i].globalassign then
		  AAdef[h].units[i].gassigncounter = AAdef[h].units[i].gassigncounter - 1
		  if AAdef[h].units[i].gassigncounter <= 0 then
		    AAdef[h].units[i].globalassign = false
		    AAdef[h].units[i].gassigncounter = 0
			unassignTarget(AAdefbuff.id, i, h)
		  end
		end
		if AAdefbuff.counter == 0 then
		  AAdef[h].units[i].counter = AAmaxcounter(AAdefbuff.name)
		  counteris0 = true
		  if IsMicro(AAdefbuff.id) then
		    targets = getAATargetsinRange(AAdefbuff.id, i, h)
          end
		else
		  counteris0 = false
		  AAdef[h].units[i].counter = AAdef[h].units[i].counter - 1
		end
		if weaponready and not AAdef[h].units[i].globalassign then
		  --Echo("weapon ready")
		  target = AAdefbuff.attacking
		  if target ~= nil then
		    _, trefID, tallyteam, airbuff = GetAirUnit(target)
			if airbuff ~= nil then
			  if airbuff.globalassign then
			    unassignTarget(AAdefbuff.id, i, h)
			    counteris0 = true
				if targets == nil and IsMicro(AAdefbuff.id) then
				  targets = getAATargetsinRange(AAdefbuff.id, i, h)
				end
			  end
			end
		  end
		  if counteris0 then
		    --Echo("ready, searching for target hp: " .. AAdef[h].units[i].damage)
			if AAdefbuff.attacking == nil then
			  unassignTarget(AAdefbuff.id, i, h)
			  if IsMicro(AAdefbuff.id) then
				assignTarget(AAdefbuff.id, i, h, targets)
			  end
			  AAdef[h].units[i].counter = AAmaxcounter(AAdefbuff.name)
			  AAdef[h].units[i].refiredelay = AAmaxrefiredelay(AAdefbuff.name)
			end
			if AAdefbuff.refiredelay == 0 then
			  AAdef[h].units[i].skiptarget = AAdef[h].units[i].skiptarget + 1
			  --Echo("skipping " .. AAdef[h].units[i].skiptarget)
			  unassignTarget(AAdefbuff.id, i, h)
			  if IsMicro(AAdefbuff.id) then
			    assignTarget(AAdefbuff.id, i, h)
			  end
			  AAdef[h].units[i].counter = 0
			  AAdef[h].units[i].refiredelay = AAmaxrefiredelay(AAdefbuff.name)
			elseif AAdefbuff.attacking ~= nil then
			  AAdef[h].units[i].counter = 0
			  AAdef[h].units[i].refiredelay = AAdef[h].units[i].refiredelay - 1
			end
		  end
		elseif not AAdef[h].units[i].globalassign then
		  --Echo("not ready, deassigning target")
	      if IsMicro(AAdefbuff.id) and AAdefbuff.name ~= "missiletower" and not IsIdle(AAdefbuff.id) then
	        removecommand(AAdefbuff.id, i , h)
			GiveOrder(AAdefbuff.id, CMD.STOP, nil, i, h)
		  end
		  unassignTarget(AAdefbuff.id, i, h)
		  AAdef[h].units[i].counter = 0
		end
		local j = 1
		while j <= AAdef[h].units[i].projectilescount do
		  AAdef[h].units[i].projectiles[j].TOF = AAdef[h].units[i].projectiles[j].TOF - 1
		  if AAdef[h].units[i].projectiles[j].TOF <= 0 then
		    removeShot(AAdef[h].units[i].projectiles[j].id)
			j = j - 1
		  end
		  j = j + 1
		end
	  else
	    removeAA(AAdefbuff.id, h)
		i = i - 1
	  end
	end
	i = i + 1
  end
    end
  end
end

function checkairs()
  local airbuff
  local health
  local pdamagecount
  for h = 0, airteamcount do
  local teammaxcount = airtargetsmaxcount[h]
    if teammaxcount ~= nil then
      for i = 1, teammaxcount do
         airbuff = airtargets[h].units[i]
	     if airbuff ~= nil then
		   if not UnitIsDead(airbuff.id) then
	         health, _, _, _, _ = GetHP(airtargets[h].units[i].id)
	         airtargets[h].units[i].hp = health
		     --Echo(airtargets[h].units[i].id, health, airtargets[h].units[i].tincoming)
			 if airtargets[h].units[i].globalassign then
			   airtargets[h].units[i].globalassigncount = airtargets[h].units[i].globalassigncount - 1
			   --Echo("air gassigncounter", airbuff.id, airbuff.globalassigncount)
			   if airtargets[h].units[i].globalassigncount <= 0 then
			     airtargets[h].units[i].globalassigncount = 0
			     airtargets[h].units[i].globalassign = false
			   end
			 end
			 pdamagecount = airtargets[h].units[i].pdamagecount
			 for j = 1, pdamagecount - 1 do
			   if airtargets[h].units[i].pdamage[j] ~= nil then
			     airtargets[h].units[i].pdamage[j][3] = airtargets[h].units[i].pdamage[j][3] - 1
			     if airtargets[h].units[i].pdamage[j][3] <= 0 then
				   airtargets[h].units[i].pdamage[j] = nil
				   if pdamagecount > 1 then
			         airtargets[h].units[i].pdamage[j] = airtargets[h].units[i].pdamage[pdamagecount - 1]
					 airtargets[h].units[i].pdamage[pdamagecount - 1] = nil
					 pdamagecount = pdamagecount - 1
				     airtargets[h].units[i].pdamagecount = pdamagecount
				   end
			     end
			   else
			     airtargets[h].units[i].pdamage[j] = nil
				 if pdamagecount > 1 then
			       airtargets[h].units[i].pdamage[j] = airtargets[h].units[i].pdamage[pdamagecount - 1]
				   airtargets[h].units[i].pdamage[pdamagecount - 1] = nil
				   pdamagecount = pdamagecount - 1
				   airtargets[h].units[i].pdamagecount = pdamagecount
				 end
			   end
			 end
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

function globalassign()
  local airbuff
  for j = 1, globalassignmentcount - 1 do
    globalassignment[j].units = {}
	globalassignment[j].unitscount = 1
  end
  for h = 0, airteamcount do
  local teammaxcount = airtargetsmaxcount[h]
    if teammaxcount ~= nil then
      for i = 1, teammaxcount do
        airbuff = airtargets[h].units[i]
	    if airbuff ~= nil then
		--Echo("testing assign 1", airbuff.pdamagecount)
		if airbuff.pdamagecount > 2 and not airbuff.globalassign then
		  local tdamage = 0
		  for j = 1, airbuff.pdamagecount - 1 do
		    --Echo(airbuff.id, airbuff.pdamagecount, airbuff.pdamage[j])
			if airbuff.pdamage[j] ~= nil then
		      tdamage = tdamage + airbuff.pdamage[j][2]
			end
		  end
		  --Echo(tdamage, airbuff.hp, airbuff.incoming, airbuff.tincoming)
		  if airbuff.hp > airbuff.incoming and tdamage > airbuff.hp - airbuff.incoming then
		    for j = 1, globalassignmentcount - 1 do
		      if globalassignment[j].name == airbuff.name then
		        --Echo("coop target! " .. airbuff.id, airbuff.name)
		        globalassignment[j].units[globalassignment[j].unitscount] = {id = airbuff.id, hp = airbuff.hp}
				globalassignment[j].unitscount = globalassignment[j].unitscount + 1
				j = globalassignmentcount
				break
		      end
		    end
		  end
		end
	    end
      end
    end
  end
  for j = 1, globalassignmentcount - 1 do
    table.sort(globalassignment[j].units, globalassigndynamiccompare)
  end
  local targetID, trefID, tallyteam
  local unitID, refID, allyteam, AAdefbuff
  for h = 1, globalassignmentcount - 1 do
    for i = 1, globalassignment[h].unitscount - 1 do
	  targetID = globalassignment[h].units[i].id
	  _, trefID, tallyteam, airbuff = GetAirUnit(targetID)
	  if airbuff ~= nil then
	    local tdamage = 0
		local num
		local kill = false
		--Echo("launching coop target! " .. airbuff.id, airbuff.name)
	    for j = 1, airbuff.pdamagecount - 1 do
		if airbuff.pdamage[j] ~= nil then
		  unitID = airbuff.pdamage[j][1]
		  _, refID, allyteam, AAdefbuff = GetAAUnit(unitID)
		  if AAdefbuff ~= nil then
		  if not AAdefbuff.globalassign and not AAdefbuff.cstate and IsMicro(AAdefbuff.id) then
		    tdamage = tdamage + airbuff.pdamage[j][2]
		    if tdamage > airbuff.hp - airbuff.incoming then
		      num = j
			  j = airbuff.pdamagecount
			  kill = true
			  --Echo("enough allocated", num, tdamage, j)
			  break
		    end
	      else
		    airbuff.pdamage[j] = nil
	      end
		  end
		end
		end
		if kill then
		  --Echo("global assigning!")
	      for j = 1, num do
		  if airbuff.pdamage[j] ~= nil then
		    unitID = airbuff.pdamage[j][1]
		    _, refID, allyteam, AAdefbuff = GetAAUnit(unitID)
		    if AAdefbuff ~= nil then
			  --Echo("1 global assign!")
		      AAdef[allyteam].units[refID].globalassign = true
			  AAdef[allyteam].units[refID].gassigncounter = AAdefbuff.nextshot + AAmaxrefiredelay(AAdefbuff.name)
			  unassignTarget(unitID, refID, allyteam)
			  attackTarget(unitID, airbuff.id, refID, allyteam)
			  AAdef[allyteam].units[refID].attacking = airbuff.id
			  airtargets[tallyteam].units[trefID].tincoming = airtargets[tallyteam].units[trefID].tincoming + AAdefbuff.damage
			  --Echo("global assign " .. AAdefbuff.id .. " targeting " .. airbuff.id .. " tincoming " .. airtargets[tallyteam].units[trefID].tincoming)
			  airtargets[tallyteam].units[trefID].globalassign = true
			  if AAdef[allyteam].units[refID].gassigncounter > airtargets[tallyteam].units[trefID].globalassigncount then
			    airtargets[tallyteam].units[trefID].globalassigncount = AAdef[allyteam].units[refID].gassigncounter
			  end
		    end
		  end
		  end
		end
	  end
	end
  end
end

function globalassigndynamiccompare(unit1, unit2)
  if unit1.hp < unit2.hp then
    return true
  end
  return false
end

function assignTarget(unitID, refID, allyteam, output)
  local AAdefbuff = AAdef[allyteam].units[refID]
  local attacking = AAdefbuff.attacking
  local notargets = false
  local assign = nil
  local damage = AAdefbuff.damage
  local skip = AAdefbuff.skiptarget
  local cdamage = damage
  if output ~= nil then
    --Echo("enemies in range")
    if output[2] ~= 0 then
	  --Echo("visible air in range of tower " .. unitID)
	  if AAdefbuff.name == "missiletower" and AAdefbuff.reloading[2] ~= 0 then
		damage = damage * 2
	  end
	  if skip > output[2] then
	    AAdef[allyteam].units[refID].skiptarget = 0
	    unassignTarget(unitID, refID, allyteam)
	    if IsMicro(AAdefbuff.id) then
	      removecommand(AAdefbuff.id, refID, allyteam)
		  GiveOrder(AAdefbuff.id, CMD.STOP, nil, refID, allyteam)
		end
	  end
	  if AAdefbuff.name == "screamer" and AAdefbuff.name == "missiletower" and escortingAA(unitID, refID, allyteam) then
	    output[1] = HSPruneTargets(output[1], output[2])
	  end
	  assign = BestTarget(output[1], output[2], damage, attacking, cdamage, skip, output[3])
	  if assign ~= nil then
		if assign ~= attacking then
	      local ateam = GetUnitAllyTeam(assign)
	      local arefID = airtargetsref[ateam].units[assign]
	      unassignTarget(unitID, refID, allyteam)
	      attackTarget(unitID, assign, refID, allyteam)
	      AAdef[allyteam].units[refID].attacking = assign
	      airtargets[ateam].units[arefID].tincoming = airtargets[ateam].units[arefID].tincoming + AAdefbuff.damage
		  --Echo("id " .. unitID .. " targeting " .. assign .. " " .. airtargets[ateam].units[arefID].name .. ", hp " .. airtargets[ateam].units[arefID].hp .. " tincoming " .. airtargets[ateam].units[arefID].tincoming)
		end
	  end
	end
	if output[2] == 0 or (output[2]~= 0 and assign == nil) then
	  --Echo("no air in vision")
	  notargets = true
	  local state = GetUnitStates(unitID)
      if AAdefbuff.name == "corrl" and output[5] ~= 0 then
	    --Echo("Land targets in range " .. output[5])
        AAdef[allyteam].units[refID].landtarget = true
		GiveOrder(AAdef[allyteam].units[refID].id, CMD.FIRE_STATE, 2, refID, allyteam)
	  end
    end
  else
	notargets = true
  end
  if AAdefbuff.name == "corrl" then
    local landtargets = false
	if output ~= nil then
      if output[5] ~= 0 then
	    landtargets = true
	  end
	end
	if not landtargets and FireState(AAdefbuff.id) ~= AAdefbuff.fire then
      GiveOrder(AAdef[allyteam].units[refID].id, CMD.FIRE_STATE, AAdefbuff.fire, refID, allyteam)
	end
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
	local _, trefID, tteam, airbuff = GetAirUnit(attacking)
	if airbuff ~= nil then
	  airtargets[tteam].units[trefID].tincoming = airtargets[tteam].units[trefID].tincoming - AAdef[allyteam].units[refID].damage
      --Echo("tower " .. unitID .. " was targeting " .. attacking .. ", deassigning from " .. airtargets[tteam].units[trefID].name, "tincoming is now " .. airtargets[tteam].units[trefID].tincoming)
	  if airtargets[tteam].units[trefID].tincoming < 0 then
	    airtargets[tteam].units[trefID].tincoming = 0
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
  if targets[i] ~= nil then
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
end
  if best ~= 0 then
    best = targets[best]
    ----Echo("best target found, expected hp after damage " .. hpafter)
    return best
  end
  --Echo("preventing overkill")
  return nil
end

function HSPruneTargets(targets, count)
  local refID
  local targetteam
  local airbuff
  local unitDefID
  local ud
  local maxhp
  for i = 1, count do
    _, refID, targetteam, airbuff = GetAirUnit(targets[i])
	if airbuff ~= nil then
	  _, maxhp = GetHP(targets[i])
	  unitDefID = GetUnitDefID(targets[i])
	  ud = UnitDefs[unitDefID]
      if (maxhp < 650 and ud.name ~= "corhurc2") or ud.name == "corvamp" then
	    targets[i] = nil
	  end
	end
  end
  return targets
end

function getAATargetsinRange(unitID, refID, allyteam)
  local targets = {}
  local targetscost = {}
  local ltargets = {}
  local targetscount = 1
  local ltargetscount = 1
  local x, y, z = GetUnitPosition(unitID)
  --Echo("getting targets")
  local AAdefbuff = AAdef[allyteam].units[refID]
  local units = GetUnitsInRange(x, y, z, AAdefbuff.range)
  local nextshot = AAdefbuff.nextshot
  local team
  local ud
  local cost
  local damage = AAdefbuff.damage
  local pdamagecount
  local defID
  local LOS
  local trefID, tallyteam, airbuff
  --Echo(units)
  for i,targetID in ipairs(units) do
    team = GetUnitAllyTeam(targetID)
	if not AreTeamsAllied(team, allyteam) then
	  defID = GetUnitDefID(targetID)
	  ud = UnitDefs[defID]
	  LOS = GetLOSState(targetID, allyteam)
	  if Isair(ud.name) then
	    if LOS["los"] == true or LOS["radar"] == true then
		  local timeinrange = TimeInRange(unitID, refID, allyteam, targetID)
		  --Echo(timeinrange, nextshot)
		  if timeinrange > nextshot then
		    _, trefID, tallyteam, airbuff = GetAirUnit(targetID)
			if airbuff ~= nil then
			if airbuff.hp - airbuff.incoming - airbuff.tincoming > damage then
			  pdamagecount = airbuff.pdamagecount
			  local pexisting = 0
			  for j = 1, pdamagecount - 1 do
			    if airbuff.pdamage[j] ~= nil then
			    if airbuff.pdamage[j][1] == AAdefbuff.id then
				  pexisting = j
				  break
				end
				end
			  end
			  if timeinrange > AAmaxcounter(AAdefbuff.name) then
			    timeinrange = AAmaxcounter(AAdefbuff.name)
			  end
			  if pexisting == 0 then
			    airtargets[tallyteam].units[trefID].pdamage[pdamagecount] = {AAdefbuff.id, AAdefbuff.damage, timeinrange}
			    airtargets[tallyteam].units[trefID].pdamagecount = pdamagecount + 1
		      else
			    airtargets[tallyteam].units[trefID].pdamage[pexisting] = {AAdefbuff.id, AAdefbuff.damage, timeinrange}
			  end
			  --Echo("posting potential damage! " .. pdamagecount, targetID)
			else
			  pdamagecount = airbuff.pdamagecount
			  local pexisting = 0
			  for j = 1, pdamagecount - 1 do
			    if airbuff.pdamage[j] ~= nil then
			    if airbuff.pdamage[j][1] == AAdefbuff.id then
				  pexisting = j
				  j = pdamagecount
				end
				end
			  end
			  if pexisting ~= 0 then
			    airtargets[tallyteam].units[trefID].pdamage[pexisting] = airtargets[tallyteam].units[trefID].pdamage[pdamagecount - 1]
				airtargets[tallyteam].units[trefID].pdamage[pdamagecount - 1] = nil
			    airtargets[tallyteam].units[trefID].pdamagecount = pdamagecount - 1
			  end
			end
			end
		  end
		  ud = airunitdefs[ud.name]
		  cost = ud.cost
		  targets[targetscount] = targetID
		  targetscost[targetscount] = cost
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
    dist = (ux-ex)^2 + (uy-ey)^2 +(uz-ez)^2
  end
  if dist ~= nil then
    if dist < (urange - 1)^2 then
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
  local nextshot = -1
  local reloadtime = getReloadTime(AAdef[allyteam].units[refID].name)
  local lowestreloading
  _, ready, _, _, _ = WeaponState(unitID, 0)
  rframe = AAdef[allyteam].units[refID].frame
  if ready == false or ready == true then
  if ready == false then
    --Echo("weapon not ready")
	nextshot = AAdef[allyteam].units[refID].reloading[4] + reloadtime - rframe
	if AAdef[allyteam].units[refID].name == "corrl" then
	  local nextshot2 = AAdef[allyteam].units[refID].reloading[4] + 36 - rframe
	  lowestreloading = 3
	  if AAdef[allyteam].units[refID].reloading[2] < AAdef[allyteam].units[refID].reloading[lowestreloading] then
		lowestreloading = 2
	  end
	  if AAdef[allyteam].units[refID].reloading[1] < AAdef[allyteam].units[refID].reloading[lowestreloading] then
	    lowestreloading = 1
	  end
	  nextshot = AAdef[allyteam].units[refID].reloading[lowestreloading] + reloadtime - rframe
	  if nextshot < nextshot2 then
	    nextshot = nextshot2
	  end
	end
	if AAdef[allyteam].units[refID].reloaded ~= ready then
      --Echo("weapon fired " .. AAdef[allyteam].units[refID].id .. " unassigning ", AAdef[allyteam].units[refID].attacking)
	  unassignTarget(unitID, refID, allyteam)
	  AAdef[allyteam].units[refID].globalassign = false
	  AAdef[allyteam].units[refID].gassigncounter = 0
	  AAdef[allyteam].units[refID].reloaded = ready
	  AAdef[allyteam].units[refID].skiptarget = 0
	  AAdef[allyteam].units[refID].reloading[4] = rframe
	  nextshot = reloadtime
	  if AAdef[allyteam].units[refID].name == "corrl" and AAdef[allyteam].units[refID].reloading[1] ~= rframe and AAdef[allyteam].units[refID].reloading[2] ~= rframe and AAdef[allyteam].units[refID].reloading[3] ~= rframe then
	    lowestreloading = 3
	    if AAdef[allyteam].units[refID].reloading[2] < AAdef[allyteam].units[refID].reloading[lowestreloading] then
		  lowestreloading = 2
	    end
	    if AAdef[allyteam].units[refID].reloading[1] < AAdef[allyteam].units[refID].reloading[lowestreloading] then
	      lowestreloading = 1
	    end
        AAdef[allyteam].units[refID].reloading[lowestreloading] = rframe
		lowestreloading = 3
	    if AAdef[allyteam].units[refID].reloading[2] < AAdef[allyteam].units[refID].reloading[lowestreloading] then
		  lowestreloading = 2
	    end
	    if AAdef[allyteam].units[refID].reloading[1] < AAdef[allyteam].units[refID].reloading[lowestreloading] then
	      lowestreloading = 1
	    end
		nextshot = AAdef[allyteam].units[refID].reloading[lowestreloading] + reloadtime - rframe
		if nextshot < 36 then
		  nextshot = 36
		end
	  end
	  if AAdef[allyteam].units[refID].name == "missiletower" then
	    AAdef[allyteam].units[refID].reloading[1] = rframe
		nextshot = 42
	  end
	end
	if AAdef[allyteam].units[refID].name == "missiletower" and rframe <= AAdef[allyteam].units[refID].reloading[1] + 44 then
      nextshot = AAdef[allyteam].units[refID].reloading[1] + 42 - rframe
	elseif AAdef[allyteam].units[refID].name == "missiletower" then
	  nextshot = AAdef[allyteam].units[refID].reloading[1] + reloadtime - rframe
	end
	if AAdef[allyteam].units[refID].name == "missiletower" and rframe >= AAdef[allyteam].units[refID].reloading[1] + 30 and rframe <= AAdef[allyteam].units[refID].reloading[1] + 44 then
	  AAdef[allyteam].units[refID].reloading[2] = 0
	  --Echo("missile tower 2nd")
	  return true, nextshot
	end
	if nextshot < 0 then
	  nextshot = 0
	end
	--Echo("id " .. unitID .. "weapon fired! " .. nextshot .. " " .. lowestreloading)
	return false, nextshot
  else
    --Echo("weapon ready")
	if AAdef[allyteam].units[refID].reloaded ~= ready then
	  AAdef[allyteam].units[refID].reloaded = ready
	end
	nextshot = 0
	if AAdef[allyteam].units[refID].name == "corrl" then
	  local nextshot2
	  local lowestreloading = 3
	  if AAdef[allyteam].units[refID].reloading[2] < AAdef[allyteam].units[refID].reloading[lowestreloading] then
	    lowestreloading = 2
	  end
	  if AAdef[allyteam].units[refID].reloading[1] < AAdef[allyteam].units[refID].reloading[lowestreloading] then
	    lowestreloading = 1
	  end
      --Echo(AAdef[allyteam].units[refID].reloading[lowestreloading])
      if AAdef[allyteam].units[refID].reloading[lowestreloading] + reloadtime >= rframe then
		nextshot = AAdef[allyteam].units[refID].reloading[lowestreloading] + reloadtime - rframe
		nextshot2 = AAdef[allyteam].units[refID].reloading[4] + 36 - rframe
		if nextshot < nextshot2 then
		  nextshot = nextshot2
		end
		--Echo("out of missiles" .. AAdef[allyteam].units[refID].reloading[lowestreloading] .. " " .. AAdef[allyteam].units[refID].frame)
		return false, nextshot
      end
	end
	if AAdef[allyteam].units[refID].name == "screamer" then
	  if GetUnitStockpile(unitID) == 0 then
	    return false, 600
	  end
	end
	if AAdef[allyteam].units[refID].name == "missiletower" then
	  AAdef[allyteam].units[refID].reloading[2] = -2000
	end
	return true, nextshot
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
  GiveOrder(unitID, CMD.ATTACK, targetID, refID, allyteam)
  AAdef[allyteam].units[refID].attacking = targetID
end

function removecommand(unitID, refID, allyteam)
  local cQueue = GetCommandQueue(unitID)
  if cQueue[1] ~= nil then
    GiveOrder(unitID, CMD.REMOVE, cQueue[1].tag, refID, allyteam)
  end
end

function GiveOrder(unitID, cmdID, params, refID, allyteam)
  if refID ~= nil and allyteam ~= nil then
    AAdef[allyteam].units[refID].orderaccept = true
  end
  if params ~= nil then
    SGiveOrder(unitID, cmdID, {params}, {})
  else
    SGiveOrder(unitID, cmdID, {}, {})
  end
end

function IsMicro(unitID)
  local cstate = isUnitCloaked(unitID)
  local morphing = IsMorphing(unitID)
  local _, _, stun = UnitStun(unitID)
  local unitAI = IsMicroCMD(unitID)
  if unitAI and not morphing and not cstate and not stun then
    return true
  end
  return false
end

function IsMicroCMD(unitID)
if unitID ~= nil then
  local cmdDescID = FindUnitCmdDesc(unitID, CMD_UNIT_AI)
  local cmdDesc = GetUnitCmdDesc(unitID, cmdDescID, cmdDescID)
  local nparams = cmdDesc[1].params
  if nparams[1] == '1' then
    return true
  end
end
  return false
end

function IsIdle(unitID)
  local cQueue = GetCommandQueue(unitID)
  if cQueue[1] ~= nil then
    return false
  end
  return true
end

function TimeInRange(unitID, refID, allyteam, targetID)
  local distance = AAdef[allyteam].units[refID].range - GetUnitSeparation(unitID, targetID, true)
  local tdefID = GetUnitDefID(targetID)
  local ud = UnitDefs[tdefID]
  local movespeed = getairMoveSpeed(ud.name)
  if movespeed ~= 0 then
    return (30 * distance / movespeed)
  end
  return -1
end

function IsFinished(unitID)
  local _,_,_,_,buildProgress = GetHP(unitID)
  return (buildProgress == nil) or (buildProgress >= 1)
end

function IsMorphing(unitID)
  if GetUnitRule(unitID, "morphing") == 1 then
    return true
  end
  return false
end

function FireState(unitID)
  local cmdDescID = FindUnitCmdDesc(unitID, CMD.FIRE_STATE)
  local cmdDesc = GetUnitCmdDesc(unitID, cmdDescID, cmdDescID)
  local nparams = cmdDesc[1].params
  return (nparams[1] + 0)
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

function Isair(name)
  --Echo(name, airunitdefs[name])
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

function getReloadTime(name)
  if name == "corrl" then
    return 340
  end
  if name == "missiletower" then
    return 390
  end
  if name == "armcir" then
    return 30
  end
  if name == "screamer" then
    return 54
  end
  return -1
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
    AAdef[allyteam].units[AAdefmaxcount[allyteam] + 1] = {id = unitID, range = ud.maxWeaponRange, attacking = nil, counter = AAmaxcounter(name), reloaded = true, name = name, reloading = {-2000, -2000, -2000, -2000}, frame = 0, deactivate = false, morph = false, damage = sdamage - 5, landtarget = false, orderaccept = false, orderreceived = false, refiredelay = 0, team = allyteam, inrange = {}, projectiles = {}, projectilescount = 0, shotspeed = getshotVelocity(name), cstate = false, cfire = 2, fire = 0, skiptarget = 0, nextshot = 0, globalassign = false, gassigncounter = 0}
    AAdefreference[allyteam].units[unitID] = AAdefmaxcount[allyteam] + 1
    AAdefmaxcount[allyteam] = AAdefmaxcount[allyteam] + 1
end

function addAir(unitID, unitDefID, name, allyteam)
  local health, _, _, _, _ = GetHP(unitID)
  if airtargets[allyteam] == nil then
	airtargets[allyteam] = {units = {}}
	airtargetsref[allyteam] = {units = {}}
	airtargetsmaxcount[allyteam] = 0
	if allyteam > airteamcount then
	  airteamcount = allyteam
	end
  end
  airtargets[allyteam].units[airtargetsmaxcount[allyteam] + 1] = {id = unitID, name = name, tincoming = 0, incoming = 0, hp = health, team = allyteam, inrange = {}, pdamage = {}, pdamagecount = 1, globalassign = false, globalassigncount = 0}
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
  removeAA(unitID, oldteam)
	--GiveOrder(unitID, CMD.FIRE_STATE, {1}, {})
    --Echo("AA unit transferred, hold fire order given")
end

function removeAir(unitID, allyteam)
  if airtargetsref[allyteam] ~= nil then
  if airtargetsref[allyteam].units[unitID] ~= nil then
    local refID = airtargetsref[allyteam].units[unitID]
	--Echo("removing " .. airtargets[allyteam].units[refID].id .. " tincoming " .. airtargets[allyteam].units[refID].tincoming)
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
	if newteam > airteamcount then
	  airteamcount = newteam
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
  local AAdefbuff = AAdef[allyteam].units[refID]
  shot[shotmaxcount + 1] = {id = shotID, unitID = unitID, refID = refID, allyteam = allyteam, prefID = nil}
  if IsAttacking(unitID) then
    targetID = getTarget(unitID)
  end
  local _, arefID, tallyteam, airbuff = GetAirUnit(targetID)
  if airbuff ~= nil then
	local distance = GetUnitSeparation(unitID, targetID)
	local flighttime = 30 * distance / AAdefbuff.shotspeed
	--Echo("shot fired " .. shotID .. " owner " .. unitID .. " target " .. targetID .. " separation " .. distance ..  " TOF " .. flighttime)
    AAdef[allyteam].units[refID].projectiles[AAdefbuff.projectilescount + 1] = {id = shotID, target = targetID, TOF = flighttime}
	shot[shotmaxcount + 1].prefID = AAdefbuff.projectilescount + 1
	AAdef[allyteam].units[refID].projectilescount = AAdefbuff.projectilescount + 1
	airtargets[tallyteam].units[arefID].incoming = airtargets[tallyteam].units[arefID].incoming + AAdefbuff.damage
  end
  if AAdefbuff.landtarget == 2 then
    GiveOrder(AAdef[allyteam].units[refID].id, CMD.FIRE_STATE, AAdefbuff.fire, refID, allyteam)
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
  if globalassignmentcounter == 0 then
    globalassign()
	globalassignmentcounter = 30
  else
    globalassignmentcounter = globalassignmentcounter - 1
  end
  checkAAdef()
end

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
  local ud = UnitDefs[unitDefID]
if IsAA(ud.name) then
  local _, refID, allyteam, AAdefbuff = GetAAUnit(unitID)
  if cmdID == CMD_UNIT_AI then
    local cmdDescID = FindUnitCmdDesc(unitID, CMD_UNIT_AI)
    local fcmdDescID = FindUnitCmdDesc(unitID, CMD.FIRE_STATE)
	fcmdDesc = GetUnitCmdDesc(unitID, fcmdDescID, fcmdDescID)
	fnparams = fcmdDesc[1].params
    if cmdParams[1] == 0 then
	  nparams = {0, 'AI Off','AI On'}
      if not AAdefbuff.orderaccept then
	    AAdef[allyteam].units[refID].deactivate = true
	  end
	  fnparams[1] = AAdef[allyteam].units[refID].cfire
    else
	  nparams = {1, 'AI Off','AI On'}
      if not AAdefbuff.orderaccept then
	    AAdef[allyteam].units[refID].deactivate = false
	  end
	  fnparams[1] = AAdef[allyteam].units[refID].fire
    end
    EditUnitCmdDesc(unitID, cmdDescID, {params = nparams})
    EditUnitCmdDesc(unitID, fcmdDescID, {params = fnparams})
  elseif cmdID == CMD.FIRE_STATE then
    if not IsMicro(unitID) then
	  local _, refID, allyteam, AAdefbuff = GetAAUnit(unitID)
	  if allyteam ~= nil and refID ~= nil and AAdefbuff ~= nil then
	    --Echo("cloaked state " .. cmdParams[1])
		if not AAdefbuff.landtarget then
          if cmdParams[1] == 2 then
            AAdef[allyteam].units[refID].cfire = 2
          elseif cmdParams[1] == 1 then
            AAdef[allyteam].units[refID].cfire = 1
	      else
            AAdef[allyteam].units[refID].cfire = 0
          end
		else
		  AAdef[allyteam].units[refID].landtarget = false
		end
	  end
	else
	  local _, refID, allyteam, AAdefbuff = GetAAUnit(unitID)
	  if allyteam ~= nil and refID ~= nil and AAdefbuff ~= nil then
		if not AAdefbuff.landtarget then
		  --Echo("uncloaked state " .. cmdParams[1])
          if cmdParams[1] == 2 then
            AAdef[allyteam].units[refID].fire = 2
          elseif cmdParams[1] == 1 then
            AAdef[allyteam].units[refID].fire = 1
	      else
            AAdef[allyteam].units[refID].fire = 0
          end
		else
		  AAdef[allyteam].units[refID].landtarget = false
		end
	  end
	end
  else
	if AAdefbuff ~= nil then
	  --Echo("AA micro order?", AAdefbuff.orderaccept)
	  if AAdefbuff.orderaccept then
	    AAdefbuff.orderaccept = false
	  else
        AAdef[allyteam].units[refID].orderreceived = true
	  end
	end
  end
end
  return true
end

function globalassignmentstaticcompare(gassign1, gassign2)
  if gassign1.def.cost > gassign2.def.cost then
    return true
  end
  return false
end

function gadget:Initialize()
  Echo("AA Micro Gadget Enabled")
  
  for id,unitDef in pairs(UnitDefs) do
    if unitDef.name ~= "fakeunit_aatarget" then
      if unitDef.canFly then
   --[[for name,param in unitDef:pairs() do
     Spring.Echo(name,param)
   end]]--
	    airunitdefs[unitDef.name] = {hp = unitDef.health, maxspeed = unitDef.speed, cost = unitDef.metalCost}
		globalassignment[globalassignmentcount] = {name = unitDef.name, def = airunitdefs[unitDef.name], units = {}, unitscount = 1}
		globalassignmentcount = globalassignmentcount + 1
		--Echo(unitDef.name, airunitdefs[unitDef.name].hp, airunitdefs[unitDef.name].maxspeed, airunitdefs[unitDef.name].cost)
      end
	end
  end
  
  table.sort(globalassignment, globalassignmentstaticcompare)
  
  for i = 1,#WeaponDefs do
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
  for _, unitID in ipairs(Spring.GetAllUnits()) do
    local unitDefID = Spring.GetUnitDefID(unitID) 
    gadget:UnitCreated(unitID, unitDefID) 
  end 
end
