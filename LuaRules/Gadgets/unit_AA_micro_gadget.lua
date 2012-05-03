local versionNumber = "v1.2"

--[[   TO DO::

Basic flight prediction of aircraft (affects single and global targeting)
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
    enabled   = false	--  loaded by default?
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
local GetUnitBasePosition= Spring.GetUnitBasePosition
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
local GetUnitsInSphere   = Spring.GetUnitsInSphere
local GetUnitRules       = Spring.GetUnitRulesParams
local GetUnitRule        = Spring.GetUnitRulesParam
local WeaponState        = Spring.GetUnitWeaponState
local UnitStun           = Spring.GetUnitIsStunned
local Tooltip            = Spring.GetUnitTooltip
local GetHP              = Spring.GetUnitHealth
local isDead             = Spring.GetUnitIsDead
local GetUnitStockpile   = Spring.GetUnitStockpile
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
  tooltip    = 'Toggles smart unit AI for the unit',
  params     = {1, 'AI Off','AI On'}
}
local airtargets         = {} -- {id = unitID, incoming = 0, hp = int, team = allyteam, inrange = {}}
local airtargetsmaxcount = {}
local teamcount          = 0
local airteamcount       = 0
local teams              = {}
local AAdef              = {} -- {id = unitID, range = ud.maxWeaponRange, attacking = nil, counter = 5, reloaded = true, name = ud.name, reloading = {0, 0, 0}, frame = 0, damage = damage per shot, refiredelay = 0, team = allyteam, inrange = {}}
local AAdefmaxcount      = {}
local shot               = {} -- {id = shotID, unitID = ownerID, allyteam = owner's allyteam, prefID = projectilerefID in owner's list)
local shotreference      = {}
local shotmaxcount       = 0
local airunitdefs        = {}
local EscortAA           = {} --{["corrl"] = 60, ["corrazor"] = 150, ["armcir"] = 250, ["corflak"] = 360}
local AAstats            = {}
local AAdelayedsalvo     = {}
local AABurst            = {}
local AADPS              = {}
local CylinderAA         = {}
local StaticAA           = {}
local MobileAA           = {}
MobileAA["amphaa"] = true
AABurst["amphaa"] = true
CylinderAA["amphaa"] = true
AAstats["amphaa"] = { damage = 640, shotdamage = 160, salvosize = 4, range = 800, reload = 8 * 30, dps = 80, velocity = 850 }  --Hardcoded as amphaa's weapon doesn't show up in weaponDefs
local corrlreload = 330
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
local loadmultiplier = 1  -- raise to reduce CPU usage, do not raise above 3

------------------------------
----------CORE LOGIC----------

function checkAAdef()
  local target, airbuff
  local counteris0
  local AAdefbuff
  local weaponready
  local nextshot
  for h = 0, teamcount do
    local teammaxcount = AAdefmaxcount[h]
    ----Echo("checking team" .. h .. ", " .. teammaxcount)
    if teammaxcount ~= nil then
      ----Echo("team initialized")
      for unitID, AAdefbuff in pairs(AAdef[h].units) do
        --Echo(AAdefbuff)
        if AAdefbuff ~= nil then
          --Echo("ID " .. unitID)
          if not UnitIsDead(unitID) then
            local targets = nil
            local morphing = IsMorphing(unitID)
            AAdefbuff.frame = AAdefbuff.frame + 1
            if IsIdle(unitID) then
              AAdefbuff.orderreceived = false
            end
            if ( IsMicroCMD(unitID) and IsBurstAA(AAdefbuff.name) and not IsMobileAA(AAdefbuff.name) ) or AAdefbuff.resetfirestate then
              local firestate = FireState(unitID)
              if firestate ~= nil and firestate ~= AAdefbuff.fire and not AAdefbuff.resetfirestate then
                GiveOrder(unitID, CMD.FIRE_STATE, {AAdefbuff.fire}, h)
              end
              if AAdefbuff.resetfirestate then
                GiveOrder(unitID, CMD.FIRE_STATE, {2}, h)
                AAdefbuff.resetfirestate = false
                unassignTarget(AAdefbuff)
              end
            end
            if AAdefbuff.attacking ~= nil then
              if UnitIsDead(AAdefbuff.attacking) or not InRange(unitID, AAdefbuff.attacking, AAdefbuff.range) then
                AAdefbuff.attacking = nil
                AAdefbuff.gassigncounter = 0
                AAdefbuff.counter = 0
              end
            end
            weaponready, nextshot = WeaponReady(unitID, h)
            AAdefbuff.nextshot = nextshot
            --Echo(nextshot)
            if AAdefbuff.globalassign then
              AAdefbuff.gassigncounter = AAdefbuff.gassigncounter - 1
              if AAdefbuff.gassigncounter <= 0 then
                AAdefbuff.globalassign = false
                AAdefbuff.gassigncounter = 0
                unassignTarget(AAdefbuff)
              end
            end
            --[[if AAdefbuff.rangeupdatetimer <= 0 then
              AAdefbuff.rangeupdate = true
            else
              AAdefbuff.rangeupdatetimer = AAdefbuff.rangeupdatetimer - 1
            end]]--
            counteris0 = false
            if AAdefbuff.counter == 0 then
              AAdefbuff.counter = AAmaxcounter(AAdefbuff.name)
              if IsMicro(unitID) then
                counteris0 = true
                targets = getAATargetsinRange(unitID, h)
              end
            else
              AAdefbuff.counter = AAdefbuff.counter - 1
            end
            if weaponready and not AAdefbuff.globalassign then
              --Echo("weapon ready")
              target = AAdefbuff.attacking
              if target ~= nil then
                airbuff = GetAirUnit(target)
                if airbuff ~= nil then
                  if airbuff.globalassign then
                    unassignTarget(AAdefbuff)
                    counteris0 = true
                    if targets == nil and IsMicro(unitID) then
                      targets = getAATargetsinRange(unitID, h)
                    end
                  end
                end
              end
              if counteris0 then
                if AAdefbuff.attacking == nil then
                  AAdefbuff.skiptarget = 0
                  if IsMicro(unitID) then
                    unassignTarget(AAdefbuff)
                    --Echo("ready, searching for target hp: " .. AAdefbuff.damage)
                    assignTarget(unitID, h, targets)
                  end
                  AAdefbuff.counter = AAmaxcounter(AAdefbuff.name)
                  AAdefbuff.refiredelay = AAmaxrefiredelay(AAdefbuff.name)
                end
                if AAdefbuff.refiredelay == 0 then
                  AAdefbuff.skiptarget = AAdefbuff.skiptarget + 1
                  --Echo(unitID .. "skipping " .. AAdefbuff.skiptarget .. " was attacking " .. AAdefbuff.attacking)
                  unassignTarget(AAdefbuff)
                  if IsMicro(unitID) then
                    local assign = assignTarget(unitID, h, targets)
                  end
                  --Echo(unitID .. " is attacking ", AAdefbuff.attacking)
                  AAdefbuff.counter = 0
                  if assign == nil then
                    AAdefbuff.counter = AAmaxcounter(AAdefbuff.name)
                  end
                  AAdefbuff.refiredelay = AAmaxrefiredelay(AAdefbuff.name)
                elseif AAdefbuff.attacking ~= nil then
                  AAdefbuff.counter = 0
                  AAdefbuff.refiredelay = AAdefbuff.refiredelay - 1
                end
              end
            elseif not AAdefbuff.globalassign then
              --Echo("not ready, deassigning target")
              if IsMicro(unitID) and AAdefbuff.name ~= "missiletower" and not IsIdle(unitID) and not IsMobileAA(AAdefbuff.name) and not IsDPSAA(AAdefbuff.name) then
                removecommand(unitID, i , h)
                GiveOrder(unitID, CMD.STOP, nil, i, h)
              end
              unassignTarget(AAdefbuff)
              AAdefbuff.counter = 0
            end
            for shotID, shotbuff in pairs(AAdefbuff.projectiles) do
			  shotbuff.TOF = shotbuff.TOF - 1
              if shotbuff.TOF <= 0 then
                removeShot(shotID)
              end
            end
          else
            removeAA(unitID, h)
          end
        end
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
    if teammaxcount ~= nil and teammaxcount ~= 0 then
      for unitID, airbuff in pairs(airtargets[h].units) do
        if airbuff ~= nil then
          if not UnitIsDead(unitID) then
            health, _, _, _, _ = GetHP(unitID)
            airbuff.hp = health
            if airbuff.globalassign then
              airbuff.globalassigncount = airbuff.globalassigncount - 1
              --Echo("air gassigncounter", unitID, airbuff.globalassigncount)
              if airbuff.globalassigncount <= 0 then
                airbuff.globalassigncount = 0
                airbuff.globalassign = false
              end
            end
            pdamagecount = airbuff.pdamagecount
            for j = 1, pdamagecount - 1 do
              if airbuff.pdamage[j] ~= nil then
                airbuff.pdamage[j][3] = airbuff.pdamage[j][3] - 1
                if airbuff.pdamage[j][3] <= 0 then
                  airbuff.pdamage[j] = nil
                  if pdamagecount > 1 then
                    airbuff.pdamage[j] = airbuff.pdamage[pdamagecount - 1]
                    airbuff.pdamage[pdamagecount - 1] = nil
                    pdamagecount = pdamagecount - 1
                    airbuff.pdamagecount = pdamagecount
                  end
                end
              else
                airbuff.pdamage[j] = nil
                if pdamagecount > 1 then
                  airbuff.pdamage[j] = airbuff.pdamage[pdamagecount - 1]
                  airbuff.pdamage[pdamagecount - 1] = nil
                  pdamagecount = pdamagecount - 1
                  airbuff.pdamagecount = pdamagecount
                end
              end
            end
          else
            removeAir(unitID, h)
          end
        else
          --removeAir(unitID, h)
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
      for unitID, airbuff in pairs(airtargets[h].units) do
        if airbuff ~= nil then
        --Echo("testing assign 1", airbuff.pdamagecount)
        if airbuff.pdamagecount > 2 and not airbuff.globalassign then
          local tdamage = 0
          for j = 1, airbuff.pdamagecount - 1 do
            --Echo(unitID, airbuff.pdamagecount, airbuff.pdamage[j])
            if airbuff.pdamage[j] ~= nil then
              tdamage = tdamage + airbuff.pdamage[j][2]
            end
          end
          --Echo(tdamage, airbuff.hp, airbuff.incoming, airbuff.tincoming)
          if airbuff.hp > airbuff.incoming and tdamage > airbuff.hp - airbuff.incoming then
            for j = 1, globalassignmentcount - 1 do
              local assignmentBuff = globalassignment[j]
              if assignmentBuff.name == airbuff.name then
                --Echo("coop target! " .. unitID, airbuff.name)
                assignmentBuff.units[assignmentBuff.unitscount] = {id = unitID, hp = airbuff.hp}
                assignmentBuff.unitscount = assignmentBuff.unitscount + 1
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
  local targetID
  local unitID, allyteam, AAdefbuff
  for h = 1, globalassignmentcount - 1 do
    for i = 1, globalassignment[h].unitscount - 1 do
      targetID = globalassignment[h].units[i].id
      airbuff = GetAirUnit(targetID)
      if airbuff ~= nil then
        local tdamage = 0
        local num
        local kill = false
        --Echo("launching coop target! " .. targetID, airbuff.name)
        for j = 1, airbuff.pdamagecount - 1 do
          if airbuff.pdamage[j] ~= nil then
            unitID = airbuff.pdamage[j][1]
            _, _, AAdefbuff = GetAAUnit(unitID)
            if AAdefbuff ~= nil then
            if not AAdefbuff.globalassign and not AAdefbuff.cstate and IsMicro(unitID) then
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
              _, allyteam, AAdefbuff = GetAAUnit(unitID)
              if AAdefbuff ~= nil then
                --Echo("1 global assign!")
                AAdefbuff.globalassign = true
                AAdefbuff.gassigncounter = AAdefbuff.nextshot + AAmaxrefiredelay(AAdefbuff.name)
                unassignTarget(AAdefbuff)
                attackTarget(unitID, targetID, allyteam)
                AAdefbuff.attacking = targetID
                airbuff.tincoming = airbuff.tincoming + AAdefbuff.damage
                --Echo("global assign " .. unitID .. " targeting " .. unitID .. " tincoming " .. airbuff.tincoming)
                airbuff.globalassign = true
                if AAdefbuff.gassigncounter > airbuff.globalassigncount then
                  airbuff.globalassigncount = AAdefbuff.gassigncounter
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

function assignTarget(unitID, allyteam, output)
  local AAdefbuff = AAdef[allyteam].units[unitID]
  local attacking = AAdefbuff.attacking
  local notargets = false
  local assign = nil
  local damage = AAdefbuff.damage
  local skip = AAdefbuff.skiptarget
  if output ~= nil then
    --Echo("enemies in range")
    if output[2] ~= 0 then
      --Echo("visible air in range of tower " .. unitID)
      if hasDelayedSalvo(AAdefbuff.name) and AAdefbuff.reloading[2] ~= 0 then
        if AAdefbuff.reloading[2] ~= 0 then
          damage = AAdefbuff.shotdamage * AAdefbuff.reloading[2]
        end
      end
      if skip > output[2] then
        unassignTarget(AAdefbuff)
        if IsMicro(unitID) and not IsMobileAA(AAdefbuff.name) and not IsDPSAA(AAdefbuff.name) then
          removecommand(unitID, allyteam)
          GiveOrder(unitID, CMD.STOP, nil, allyteam)
        end
      end
      --Echo("anti-bait", AAdefbuff.name)
      if (AAdefbuff.name == "screamer" or AAdefbuff.name == "missiletower") and escortingAA(unitID, allyteam) then
        output[1] = HSPruneTargets(output[1], output[2])
      end
      if IsBurstAA(AAdefbuff.name) then
        assign = BestTarget(output[1], output[2], damage, attacking, skip, output[3])
      else
        assign = DPSBestTarget(output[1], output[2])
      end
      --Echo("tower id " .. unitID, "assigned unit ID", assign)
      if assign ~= nil then
        if assign ~= attacking then
          airbuff = GetAirUnit(assign)
          if airbuff ~= nil then
            unassignTarget(AAdefbuff)
            attackTarget(unitID, assign, allyteam)
            AAdefbuff.attacking = assign
            if IsBurstAA(AAdefbuff.name) then
              airbuff.tincoming = airbuff.tincoming + AAdefbuff.shotdamage
            end
            --Echo("id " .. unitID .. " targeting " .. assign .. " " .. airbuff.name .. ", hp " .. airbuff.hp .. " tincoming " .. airbuff.tincoming)
          end
        end
      end
    end
    if output[2] == 0 or (output[2] ~= 0 and assign == nil) then
      Echo("no air in vision")
      notargets = true
      if AAdefbuff.name == "corrl" then
        if output[5] ~= 0 then
		  Echo("ground in vision")
          AAdefbuff.fire = 2
        else
          AAdefbuff.fire = 0
        end
      end
    end
  else
    notargets = true
    if AAdefbuff.name == "corrl" then
      AAdefbuff.fire = 0
    end
  end
  if notargets == true then
    --Echo("no visible air targets")
    unassignTarget(AAdefbuff)
  end
  return assign
end

function unassignTarget(AAdefbuff)
  if AAdefbuff.attacking ~= nil then
    local airbuff = GetAirUnit(AAdefbuff.attacking)
    if airbuff ~= nil then
      airbuff.tincoming = airbuff.tincoming - AAdefbuff.shotdamage
      --Echo("tower " .. unitID .. " was targeting " .. attacking .. ", deassigning from " .. airbuff.name, "tincoming is now " .. airbuff.tincoming)
      if airbuff.tincoming < 0 then
        airbuff.tincoming = 0
      end
    end
    AAdefbuff.attacking = nil
  end
end

function BestTarget(targets, count, damage, current, skip, cost)
  local onehit = false
  local best = 0  -- best denotes the array index in targets of the best target; 0 = no target assigned
  local bestcost = 0
  local besthp = 0
  local incoming
  local hp
  local airbuff
  local stillskipping = true
  --local hpafter
  while stillskipping do
    stillskipping = false
    for i = 1, count do
      if targets[i] ~= nil then
      if not UnitIsDead(targets[i]) then
        airbuff = GetAirUnit(targets[i])
		Echo(airbuff.hp)
        if airbuff ~= nil then
          incoming = airbuff.incoming + airbuff.tincoming
          hp = airbuff.hp
          if targets[i] == current then
            incoming = incoming - damage
          end
          --Echo("skipping " .. skip, "considering target, id: " .. targets[i] .. ", name: " .. airbuff.name .. ", cost: " .. cost[i] ..  ", hp: " .. hp .. ", incoming: " .. incoming)
          if hp <= incoming + damage then
            --Echo("one-hittable", onehit)
            if not onehit then
              if hp - incoming > 0 then
                --hpafter = hp - incoming
                best = i
                bestcost = cost[i]
                besthp = hp - incoming - damage
                onehit = true
                --Echo("new one-hit")
              end
            else
              if hp - incoming > 0 and bestcost < cost[i] then
                --hpafter = hp - incoming
                best = i
                bestcost = cost[i]
                besthp = hp - incoming - damage
                --Echo("best onehit by new highest cost class")
              elseif hp - incoming > 0 and hp - incoming - damage > besthp and bestcost == cost[i] then
                --hpafter = hp - incoming
                best = i
                bestcost = cost[i]
                besthp = hp - incoming - damage
                --Echo("best onehit by hp, cost tie")
              end
            end
          elseif onehit == false then
            if best ~= 0 then
              if hp - incoming > 0 and hp - incoming < besthp then
                --hpafter = hp - incoming
                best = i
                besthp = hp - incoming
                --Echo("best by lowest hp")
              end
            else
              if hp - incoming > 0 then
                --hpafter = hp - incoming
                best = i
                besthp = hp - incoming
                --Echo("first target")
              end
            end
          end
        end
      end
      end
    end
    if skip > 0 then
      skip = skip - 1
      if best ~= 0 then
        targets[best] = nil
        best = 0
        bestcost = 0
        besthp = 0
        stillskipping = true
      end
    end
  end
  if best ~= 0 then
    --Echo(best, besthp)
    best = targets[best]
    return best
  end
  --Echo("preventing overkill")
  return nil
end

function DPSBestTarget(targets, count)
  local best = nil  -- best denotes the array index in targets of the best target; nil = no target assigned
  local besthp = -1000
  local alldying = true
  for i = 1, count do
    if targets[i] ~= nil then
    if not UnitIsDead(targets[i]) then
      airbuff = GetAirUnit(targets[i])
      if airbuff ~= nil then
        --Echo(alldying, best, besthp, i, airbuff.hp - airbuff.incoming - airbuff.tincoming)
        if alldying then
          if besthp == -1000 or besthp < airbuff.hp - airbuff.incoming - airbuff.tincoming then
            best = i
            besthp = airbuff.hp - airbuff.incoming - airbuff.tincoming
          end
          if airbuff.hp - airbuff.incoming - airbuff.tincoming > 0 then
            best = i
            besthp = airbuff.hp - airbuff.incoming - airbuff.tincoming
            alldying = false
          end
        else
          if besthp > airbuff.hp - airbuff.incoming - airbuff.tincoming and airbuff.hp - airbuff.incoming - airbuff.tincoming > 0 then
            best = i
            besthp = airbuff.hp - airbuff.incoming - airbuff.tincoming
          end
        end
      end
    end
    end
  end
  if best ~= nil then
    best = targets[best]
  end
  return best
end

function HSPruneTargets(targets, count)
  local airbuff
  local unitDefID
  local ud
  local maxhp
  for i = 1, count do
    airbuff = GetAirUnit(targets[i])
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

function getAATargetsinRange(unitID, allyteam)
  local targets = {}
  local targetscost = {}
  local ltargets = {}
  local targetscount = 1
  local ltargetscount = 1
  local x, y, z = GetUnitPosition(unitID)
  local AAdefbuff = AAdef[allyteam].units[unitID]
  local units = {}
  if IsCylinderTargeting(AAdefbuff.name) then
    units = GetUnitsInCylinder(x, z, AAdefbuff.range)
  else
    units = GetUnitsInSphere(x, y, z, AAdefbuff.range)
  end
  --[[local units = {}  --REVERTED ALLOW WEAPON TARGET USAGE, DOES NOT PREVENT OVERKILL
  local unitscount = 0
  for i,inrange in ipairs(AAdefbuff.inrange) do
    if not UnitIsDead(inrange) then
      units[unitscount + 1] = inrange
      unitscount = unitscount + 1
    end
  end]]--
  local nextshot = AAdefbuff.nextshot
  local team
  local ud
  local cost
  local damage = AAdefbuff.damage
  local pdamagecount
  local defID
  local LOS
  local airbuff
  --Echo(units)
  for i,targetID in ipairs(units) do
    team = GetUnitAllyTeam(targetID)
    if not AreTeamsAllied(team, allyteam) then
      defID = GetUnitDefID(targetID)
      ud = UnitDefs[defID]
      LOS = GetLOSState(targetID, allyteam)
      if Isair(ud.name) then
        if LOS["los"] == true or LOS["radar"] == true then
          local timeinrange = TimeInRange(unitID, allyteam, targetID)
          --Echo(timeinrange, nextshot)
          if IsBurstAA(AAdefbuff.name) and timeinrange > nextshot then
            airbuff = GetAirUnit(targetID)
            if airbuff ~= nil then
              if airbuff.hp - airbuff.incoming - airbuff.tincoming > damage then
                pdamagecount = airbuff.pdamagecount
                local pexisting = 0
                for j = 1, pdamagecount - 1 do
                  if airbuff.pdamage[j] ~= nil then
                  if airbuff.pdamage[j][1] == unitID then
                    pexisting = j
                    break
                  end
                  end
                end
                if timeinrange > AAmaxcounter(AAdefbuff.name) then
                  timeinrange = AAmaxcounter(AAdefbuff.name)
                end
                if pexisting == 0 then
                  airbuff.pdamage[pdamagecount] = {unitID, AAdefbuff.damage, timeinrange}
                  airbuff.pdamagecount = pdamagecount + 1
                else
                  airbuff.pdamage[pexisting] = {unitID, AAdefbuff.damage, timeinrange}
                end
                --Echo("posting potential damage! " .. pdamagecount, targetID)
              else
                pdamagecount = airbuff.pdamagecount
                local pexisting = 0
                for j = 1, pdamagecount - 1 do
                  if airbuff.pdamage[j] ~= nil then
                  if airbuff.pdamage[j][1] == unitID then
                    pexisting = j
                    j = pdamagecount
                  end
                  end
                end
                if pexisting ~= 0 then
                  airbuff.pdamage[pexisting] = airbuff.pdamage[pdamagecount - 1]
                  airbuff.pdamage[pdamagecount - 1] = nil
                  airbuff.pdamagecount = pdamagecount - 1
                end
              end
            end
          end
          cost = getairCost(ud.name)
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
  if not GetUnitDefID(targetID) or not GetUnitDefID(unitID) then
    return false
  end
  local ux, uy, uz = GetUnitPosition(unitID)
  local ex, ey, ez = GetUnitPosition(targetID)
  local dist = nil
  if ux ~= nil and ex ~= nil then
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

function WeaponReady(unitID, allyteam)
  local ready
  local nextshot = -1
  local AAdefbuff = AAdef[allyteam].units[unitID]
  local reloadtime = getReloadTime(AAdefbuff.name)
  local lowestreloading
  _, ready, _, _, _ = WeaponState(unitID, 0)
  local rframe = AAdefbuff.frame
  if IsDPSAA(AAdefbuff.name) then
    return true, 0
  end
  if ready == false or ready == true then
    if ready == false then
      --Echo("weapon not ready")
      nextshot = AAdefbuff.reloading[4] + reloadtime - rframe
      if AAdefbuff.name == "corrl" then
        local nextshot2 = AAdefbuff.reloading[4] + 36 - rframe
        lowestreloading = 3
        if AAdefbuff.reloading[2] < AAdefbuff.reloading[lowestreloading] then
          lowestreloading = 2
        end
        if AAdefbuff.reloading[1] < AAdefbuff.reloading[lowestreloading] then
          lowestreloading = 1
        end
        nextshot = AAdefbuff.reloading[lowestreloading] + reloadtime - rframe
        if nextshot < nextshot2 then
          nextshot = nextshot2
        end
      end
      if AAdefbuff.reloaded ~= ready then
        --Echo("weapon fired " .. unitID .. " unassigning ", AAdefbuff.attacking)
        unassignTarget(AAdefbuff)
        AAdefbuff.globalassign = false
        AAdefbuff.gassigncounter = 0
        AAdefbuff.reloaded = ready
        AAdefbuff.skiptarget = 0
        AAdefbuff.reloading[4] = rframe
        nextshot = reloadtime
        if AAdefbuff.name == "corrl" and AAdefbuff.reloading[1] ~= rframe and AAdefbuff.reloading[2] ~= rframe and AAdefbuff.reloading[3] ~= rframe then
          lowestreloading = 3
          if AAdefbuff.reloading[2] < AAdefbuff.reloading[lowestreloading] then
            lowestreloading = 2
          end
          if AAdefbuff.reloading[1] < AAdefbuff.reloading[lowestreloading] then
            lowestreloading = 1
          end
          AAdefbuff.reloading[lowestreloading] = rframe
          lowestreloading = 3
          if AAdefbuff.reloading[2] < AAdefbuff.reloading[lowestreloading] then
            lowestreloading = 2
          end
          if AAdefbuff.reloading[1] < AAdefbuff.reloading[lowestreloading] then
            lowestreloading = 1
          end
          nextshot = AAdefbuff.reloading[lowestreloading] + reloadtime - rframe
          if nextshot < 36 then
            nextshot = 36
          end
        end
        if hasDelayedSalvo(AAdefbuff.name) then
          AAdefbuff.reloading[1] = rframe
          AAdefbuff.reloading[2] = getSalvoSize(AAdefbuff.name) - 1
          nextshot = getSalvoDelay(AAdefbuff.name)
        end
      end
      if hasDelayedSalvo(AAdefbuff.name) then
        local salvoshotdelay = getSalvoDelay(AAdefbuff.name) * (getSalvoSize(AAdefbuff.name) - AAdefbuff.reloading[2])
        if rframe <= AAdefbuff.reloading[1] + salvoshotdelay + 2 and AAdefbuff.reloading[2] ~= 0 then
          nextshot = AAdefbuff.reloading[1] + salvoshotdelay - rframe
        elseif AAdefbuff.reloading[2] == 0 then
          nextshot = AAdefbuff.reloading[1] + reloadtime - rframe
        else
          AAdefbuff.reloading[2] = AAdefbuff.reloading[2] - 1
        end
        if rframe >= AAdefbuff.reloading[1] + salvoshotdelay - 4 and rframe <= AAdefbuff.reloading[1] + salvoshotdelay + 2 and AAdefbuff.reloading[2] ~= 0 then
          --Echo("shot number", AAdefbuff.reloading[2])
          return true, nextshot
        end
      end
      if nextshot < 0 then
        nextshot = 0
      end
      if nextshot < 2 then
        return true, nextshot
      end
      return false, nextshot
    else
      --Echo("weapon ready")
      if AAdefbuff.reloaded ~= ready then
        AAdefbuff.reloaded = ready
      end
      nextshot = 0
      if AAdefbuff.name == "corrl" then
        local nextshot2
        local lowestreloading = 3
        if AAdefbuff.reloading[2] < AAdefbuff.reloading[lowestreloading] then
          lowestreloading = 2
        end
        if AAdefbuff.reloading[1] < AAdefbuff.reloading[lowestreloading] then
          lowestreloading = 1
        end
        --Echo(AAdefbuff.reloading[lowestreloading], rframe)
        if AAdefbuff.reloading[lowestreloading] + reloadtime >= rframe then
          nextshot = AAdefbuff.reloading[lowestreloading] + reloadtime - rframe
          nextshot2 = AAdefbuff.reloading[4] + 36 - rframe
          if nextshot < nextshot2 then
            nextshot = nextshot2
          end
          --Echo(unitID .. "out of missiles" .. AAdefbuff.reloading[lowestreloading] .. " " .. AAdefbuff.frame)
          return false, nextshot
        end
      end
      if AAdefbuff.name == "screamer" then
        if GetUnitStockpile(unitID) == 0 then
          return false, 600
        end
      end
      if hasDelayedSalvo(AAdefbuff.name) then
        AAdefbuff.reloading[2] = getSalvoSize(AAdefbuff.name)
      end
      return true, nextshot
    end
  end
  --Echo("cannot read")
  return false, 0
end

------------------------------
-----------FUNCTIONS----------

function UnitIsDead(unitID)
  local uDef = isDead(unitID)
  if uDef == false then
    return false
  end
  return true
end

function escortingAA(unitID, allyteam)
  local x, y, z = GetUnitPosition(unitID)
  local units = GetUnitsInCylinder(x, z, AAdef[allyteam].units[unitID].range / 2)
  local escort = 0
  for i,AAID in ipairs(units) do
    team = GetUnitAllyTeam(AAID)
    _, _, stun = UnitStun(AAID)
    if AreTeamsAllied(team, allyteam) and not stun then
      local unitDefID = GetUnitDefID(AAID)
      local ud = UnitDefs[unitDefID]
      escort = escort + ( EscortAA[ud.name] or 0 )
    end
  end
  --Echo(unitID, "escort check", escort)
  if escort >= 300 then
    return true
  end
  return false
end

function getTarget(unitID)
  local cQueue1 = GetCommandQueue(unitID, 1)[1]
  if cQueue1 then
    if cQueue1.id == CMD.ATTACK then
      if cQueue1.params[2] == nil then
        return cQueue1.params[1]
      end
    end
  end
  return nil
end

function IsAttacking(unitID)
  local cQueue1 = GetCommandQueue(unitID, 1)[1]
  if cQueue1 then
    if cQueue1.id == CMD.ATTACK then
      if cQueue1.params[2] == nil then
        return true
      end
    end
  end
  return false
end

function attackTarget(unitID, targetID, allyteam)
  local AAdefbuff = AAdef[allyteam].units[unitID]
  if IsMobileAA(AAdefbuff.name) then
    GiveOrder(unitID, CMD_UNIT_SET_TARGET, {targetID}, allyteam)
  else
    GiveOrder(unitID, CMD.ATTACK, {targetID}, allyteam)
  end
  AAdefbuff.attacking = targetID
end

function removecommand(unitID, allyteam)
  local cQueue1 = GetCommandQueue(unitID, 1)[1]
  if cQueue1 then
    GiveOrder(unitID, CMD.REMOVE, {cQueue1.tag}, allyteam)
  end
end

function GiveOrder(unitID, cmdID, params, allyteam)
  if allyteam ~= nil and unitID ~= nil and AAdef[allyteam] ~= nil and AAdef[allyteam].units ~= nil and AAdef[allyteam].units[unitID] ~= nil then
    AAdef[allyteam].units[unitID].orderaccept = true
  end
  if params ~= nil then
    SGiveOrder(unitID, cmdID, params, {})
  else
    SGiveOrder(unitID, cmdID, {}, {})
  end
end

function IsMicro(unitID)
  local morphing = IsMorphing(unitID)
  local finished = IsFinished(unitID)
  local _, _, stun = UnitStun(unitID)
  local unitAI = IsMicroCMD(unitID)
  local playerorder = true
  local abovewater = false
  local _, _, AAdefbuff = GetAAUnit(unitID)
  if AAdefbuff ~= nil then
    playerorder = AAdefbuff.orderreceived
    local height = getAAUnitHeight(AAdefbuff.name)
    local x, y, z = GetUnitBasePosition(unitID)
    abovewater = ( y > (0 - height*0.75) )
  end
  if unitAI and not morphing and not stun and finished and not playerorder and (abovewater or AAdefbuff.name == "amphaa") then
    return true
  end
  unassignTarget(AAdefbuff)
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
  local cQueue1 = GetCommandQueue(unitID, 1)[1]
  if cQueue1 then
    return false
  end
  return true
end

function TimeInRange(unitID, allyteam, targetID)
  local distance = AAdef[allyteam].units[unitID].range - GetUnitSeparation(unitID, targetID, true)
  local tdefID = GetUnitDefID(targetID)
  local ud = UnitDefs[tdefID]
  local movespeed = getairMoveSpeed(ud.name) - getAAMoveSpeed(AAdef[allyteam].units[unitID].name)
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

function IsDPSAA(name)
  return AADPS[name]
end

function IsCylinderTargeting(name)
  return CylinderAA[name]
end

function IsBurstAA(name)
  return AABurst[name]
end

function IsMobileAA(name)
  return MobileAA[name]
end

function IsStaticAA(name)
  return StaticAA[name]
end

function IsAA(name)
  return (AAstats[name] ~= nil)
end

function hasDelayedSalvo(name)
  return (AAdelayedsalvo[name] ~= nil)
end

function AAmaxcounter(name)
  if name == "missiletower" then
    return math.floor(3 * loadmultiplier)
  end
  if name == "screamer" then
    return math.floor(10 * loadmultiplier)
  end
  return math.floor(3 * loadmultiplier)
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
  return airunitdefs[name] or false
end

function getSalvoDamage(name)
  if AAstats[name] ~= nil then
    return AAstats[name].damage
  end
  return 0
end

function getShotDamage(name)
  if AAstats[name] ~= nil then
    return AAstats[name].shotdamage
  end
  return 0
end

function getDPS(name)
  if AAstats[name] ~= nil then
    return AAstats[name].dps
  end
  return 0
end
    
function getRange(name)
  if AAstats[name] ~= nil then
    return AAstats[name].range
  end
  return 0
end

function getshotVelocity(name)
  if AAstats[name] ~= nil then
    return AAstats[name].velocity
  end
  return nil
end

function getReloadTime(name)
  if AAstats[name] ~= nil then
    return AAstats[name].reload
  end
  return -1
end

function getSalvoSize(name)
  if AAstats[name] ~= nil then
    return AAstats[name].salvosize
  end
  return -1
end

function getSalvoDelay(name)
  if AAdelayedsalvo[name] then
    return AAdelayedsalvo[name]
  end
  return -1
end

function getAAMoveSpeed(name)
  if AAstats[name] ~= nil then
    return AAstats[name].movespeed
  end
  return -1
end

function getAAUnitHeight(name)
  if AAstats[name] ~= nil then
    return AAstats[name].height
  end
  return 0
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
  local damage = getSalvoDamage(name)
  local sdamage = getShotDamage(name)
  if allyteam > teamcount then
    teamcount = allyteam
  end
  if AAdef[allyteam] == nil then
    AAdefmaxcount[allyteam] = 0
    AAdef[allyteam] = {units = {}}
  end
  AAdefmaxcount[allyteam] = AAdefmaxcount[allyteam] + 1
  AAdef[allyteam].units[unitID] = {id = unitID, range = getRange(name), attacking = nil, counter = AAmaxcounter(name), reloaded = true, name = name, reloading = {-2000, -2000, -2000, -2000}, frame = 0, deactivate = false, resetfirestate = false, morph = false, damage = damage - 5, shotdamage = sdamage - 5, orderaccept = false, orderreceived = false, refiredelay = 0, team = allyteam, projectiles = {}, projectilescount = 0, shotspeed = getshotVelocity(name), cstate = false, cfire = 2, fire = 2, skiptarget = 0, nextshot = 0, globalassign = false, gassigncounter = 0}
  --inrange = {}, rangeupdate = true, rangeupdatetimer = 10, inrangecount = 0
  if IsStaticAA(name) and IsBurstAA(name) then
    AAdef[allyteam].units[unitID].fire = 0
  end
end

function addAir(unitID, unitDefID, name, allyteam)
  local health, _, _, _, _ = GetHP(unitID)
  if airteamcount < allyteam then
    airteamcount = allyteam
  end
  if airtargets[allyteam] == nil then
    airtargetsmaxcount[allyteam] = 0
	airtargets[allyteam] = {units = {}}
  end
  airtargetsmaxcount[allyteam] = airtargetsmaxcount[allyteam] + 1
  airtargets[allyteam].units[unitID] = {name = name, tincoming = 0, incoming = 0, hp = health, team = allyteam, inrange = {}, pdamage = {}, pdamagecount = 1, globalassign = false, globalassigncount = 0}
end

function removeAA(unitID, allyteam)
  AAdef[allyteam].units[unitID] = nil
  AAdefmaxcount[allyteam] = AAdefmaxcount[allyteam] - 1
end

function transferAA(unitID, newteam, oldteam)
  if newteam > teamcount then
    teamcount = newteam
  end
  if AAdef[newteam] == nil then
    AAdef[newteam] = {units = {}}
    AAdefmaxcount[newteam] = 0
  end
  AAdefmaxcount[newteam] = AAdefmaxcount[newteam] + 1
  AAdef[newteam].units[unitID] = AAdef[oldteam].units[unitID]
  removeAA(unitID, oldteam)
end

function removeAir(unitID, allyteam)
  airtargets[allyteam].units[unitID] = nil
  airtargetsmaxcount[allyteam] = airtargetsmaxcount[allyteam] - 1
end

function transferAir(unitID, newteam, oldteam)
  if airteamcount < newteam then
    airteamcount = newteam
  end
  if airtargetsmaxcount[newteam] == nil then
    airtargetsmaxcount[newteam] = 0
	airtargets[newteam] = {units = {}}
  end
  airtargetsmaxcount[newteam] = airtargetsmaxcount[newteam] + 1
  airtargets[newteam].units[unitID] = airtargets[oldteam].units[unitID]
  removeAir(unitID, oldteam)
end

function addShot(unitID, allyteam, shotID, targetID)
  local AAdefbuff = AAdef[allyteam].units[unitID]
  shot[shotID] = {id = shotID, unitID = unitID, allyteam = allyteam}
  if IsAttacking(unitID) then
    targetID = getTarget(unitID)
  end
  local airbuff = GetAirUnit(targetID)
  if airbuff ~= nil then
    local distance = GetUnitSeparation(unitID, targetID)
    local flighttime = 30 * distance / AAdefbuff.shotspeed
    --Echo("shot fired " .. shotID .. " owner " .. unitID .. " target " .. targetID .. " separation " .. distance ..  " TOF " .. flighttime)
    AAdefbuff.projectiles[shotID] = {id = shotID, target = targetID, TOF = flighttime}
    AAdefbuff.projectilescount = AAdefbuff.projectilescount + 1
    airbuff.incoming = airbuff.incoming + AAdefbuff.shotdamage
  end
  shotreference[shotID] = shotmaxcount + 1
  shotmaxcount = shotmaxcount + 1
end

function removeShot(shotID)
  --Echo("shot hit " .. shotID)
  if shot[shotID] ~= nil then
    local unitID = shot[shotID].unitID
    local allyteam = shot[shotID].allyteam
    local AAdefbuff = AAdef[allyteam].units[unitID]
    if AAdefbuff ~= nil then
    if AAdefbuff.projectiles ~= nil then
    if AAdefbuff.projectiles[shotID] ~= nil then
      local target = AAdefbuff.projectiles[shotID].target
      local airbuff = GetAirUnit(target)
      if airbuff ~= nil then
        airbuff.incoming = airbuff.incoming - AAdefbuff.damage
        if airbuff.incoming < 0 then
          airbuff.incoming = 0
        end
      end
      AAdefbuff.projectiles[shotID] = nil
      AAdefbuff.projectilescount = AAdefbuff.projectilescount - 1
    end
    end
    end
    shot[shotID] = nil
    shotmaxcount = shotmaxcount - 1
  end
end

--[[function addInRange(AAdefbuff, targetID)
  --Echo("added " .. targetID)
  for i,target in ipairs(AAdefbuff.inrange) do
    if target == targetID then
      return true
    end
  end
  AAdefbuff.inrange[AAdefbuff.inrangecount + 1] = targetID
  AAdefbuff.inrangecount = AAdefbuff.inrangecount + 1
  AAdefbuff.rangeupdatetimer = 10
  return false
end]]--

function GetAAUnit(unitID)
  if unitID ~= nil then
    local allyteam = GetUnitAllyTeam(unitID)
	--Echo("getting AA unit", AAdef[allyteam])
	if AAdef[allyteam] ~= nil and AAdef[allyteam].units ~= nil then
      local AAdefbuff = AAdef[allyteam].units[unitID]
	  if AAdefbuff ~= nil then
        return unitID, allyteam, AAdefbuff
      else
        return unitID, allyteam, nil
      end
	end
  end
  return nil, nil, nil
end

function GetAirUnit(unitID)
  if unitID ~= nil and unitID ~= -1 then
    local allyteam = GetUnitAllyTeam(unitID)
	--Echo("getting air unit", airtargets[allyteam])
	if airtargets[allyteam] ~= nil and airtargets[allyteam].units ~= nil then
      return airtargets[allyteam].units[unitID]
	end
  end
  return nil
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
    EditUnitCmdDesc(unitID, cmdDescID, {params = {0, 'AI Off','AI On'}})
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
      local _, allyteam, AAdefbuff = GetAAUnit(unitID)
      if AAdefbuff ~= nil then
        --Echo(AAdefbuff)
        addShot(unitID, allyteam, projID, AAdefbuff.attacking)
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
    globalassignmentcounter = 10
  else
    globalassignmentcounter = globalassignmentcounter - 1
  end
  checkAAdef()
end

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
  local ud = UnitDefs[unitDefID]
  if IsAA(ud.name) then
    local _, _, AAdefbuff = GetAAUnit(unitID)
    if AAdefbuff ~= nil then
      if cmdID == CMD_UNIT_AI then
        local cmdDescID = FindUnitCmdDesc(unitID, CMD_UNIT_AI)
        fcmdDesc = GetUnitCmdDesc(unitID, fcmdDescID, fcmdDescID)
        if cmdParams[1] == 0 then
          Echo("deactivating")
		  nparams = {0, 'AI Off','AI On'}
          if not AAdefbuff.orderaccept then
            AAdefbuff.deactivate = true
            AAdefbuff.resetfirestate = true
          end
        else
		  Echo("activating")
          nparams = {1, 'AI Off','AI On'}
          if not AAdefbuff.orderaccept then
            AAdefbuff.deactivate = false
            AAdefbuff.resetfirestate = false
          end
        end
        EditUnitCmdDesc(unitID, cmdDescID, {params = nparams})
      else
        if AAdefbuff.orderaccept then
          AAdefbuff.orderaccept = false
        elseif cmdID ~= 5 and cmdID ~= 70 and cmdID ~= CMD.MOVE and cmdID ~= CMD.FIGHT and cmdID ~= CMD.PATROL and cmdID ~= CMD.GUARD and cmdID ~= CMD_UNIT_CANCEL_TARGET and cmdID ~= CMD.STOP then
          AAdefbuff.orderreceived = true
          unassignTarget(AAdefbuff)
          --Echo("order received", cmdID, CMD[cmdID])
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
    local exception = true
    local unitDefName = unitDef.name
    if unitDefName == "corsub" or unitDefName == "roost" or unitDefName == "mahlazer" or unitDefName == "funnelweb" or unitDefName == "armorco" or unitDefName:find("test") or unitDefName:find("chicken") or unitDefName:find("fake") then
      exception = false
    end
    local aaexception = false
    if unitDefName == "corrl" then
      aaexception = true
    end
    local dpsaaexception = false
    if unitDefName == "corrl" or unitDefName == "corcrash" then
      dpsaaexception = true
    end
    if exception then
      if unitDef.canFly then
        airunitdefs[unitDefName] = {hp = unitDef.health, maxspeed = unitDef.speed, cost = unitDef.metalCost}
        globalassignment[globalassignmentcount] = {name = unitDefName, def = unitDef, units = {}, unitscount = 1}
        globalassignmentcount = globalassignmentcount + 1
      else
        if unitDefName == "amphaa" then 
          AAstats[unitDefName].height = unitDef.height
          AAstats[unitDefName].movespeed = unitDef.speed
        end 
        for i = 1,#WeaponDefs do
          local wd = WeaponDefs[i]
          if wd.name:find(unitDefName) then
          if not wd.canAttackGround or aaexception then  --air-only weapons
            local damage = 0
            local sdamage = 0
            for i = 1, #wd.damages do
              if damage < wd.damages[i] then
                damage = wd.damages[i]
              end
            end
            sdamage = damage
            damage = damage * wd.salvoSize
            local dps = damage / wd.reload
            if damage > 5 and wd.range > 100 and dps > 20 then  --filters
              if unitDef.speed == 0 then
                StaticAA[unitDefName] = true
              else
                MobileAA[unitDefName] = true
              end
              if wd.salvoDelay > 0.5 and wd.salvoSize > 1 then
                AAdelayedsalvo[unitDefName] = wd.salvoDelay * 30
              end
              if wd.reload > 0.5 then
                AABurst[unitDefName] = true
              else
                AADPS[unitDefName] = true
              end
              if wd.reload <= 1 or dpsaaexception then
                EscortAA[unitDefName] = dps
              end
              if wd.cylinderTargetting == 1 then
                CylinderAA[unitDefName] = true
              else
                CylinderAA[unitDefName] = false
              end
              if AAstats[unitDefName] == nil then
                --Echo(unitDefName, wd.name, wd.range)
                AAstats[unitDefName] = { damage = damage, shotdamage = sdamage, salvosize = wd.salvoSize, range = wd.range, reload = wd.reload * 30, dps = dps, velocity = wd.customParams.weaponvelocity, movespeed = unitDef.speed, height = unitDef.height}
              else
                AAstats[unitDefName].damage = AAstats[unitDefName].damage + damage
                AAstats[unitDefName].dps = AAstats[unitDefName].dps + dps
              end
            end
          end
          end
        end
      end
    end
  end

  AAstats["corrl"].reload = corrlreload
  CylinderAA["hoveraa"] = true

  table.sort(globalassignment, globalassignmentstaticcompare)

  for i = 1,#WeaponDefs do
    local wd = WeaponDefs[i]
    for name,_ in pairs(AABurst) do
      if wd.name:find(name) then
        Script.SetWatchWeapon(i,true)
        weapondefID[name] = i
      end
    end
  end
  for _, unitID in pairs(Spring.GetAllUnits()) do
    local unitDefID = Spring.GetUnitDefID(unitID)
    gadget:UnitCreated(unitID, unitDefID)
  end
end

--[[function gadget:AllowWeaponTarget(attackerID, targetID, attackerWeaponNum, attackerWeaponDefID)
  local unitDefID = GetUnitDefID(attackerID)
  local ud = UnitDefs[unitDefID]
  if IsAA(ud.name) then
    local _, _, AAdefbuff = GetAAUnit(attackerID)
    unitDefID = GetUnitDefID(targetID)
    local tud = UnitDefs[unitDefID]
    if not Isair(tud.name) then
      return false, 1
    else
      if AAdefbuff.rangeupdate then
        AAdefbuff.rangeupdate = false
        AAdefbuff.inrange = {}
        AAdefbuff.inrangecount = 0
        addInRange(AAdefbuff, targetID)
      else
        addInRange(AAdefbuff, targetID)
      end
    end
    if AAdefbuff.attacking == targetID or AAdefbuff.orderreceived == true then
      --Echo("allowing shot", attackerID)
      return false, 1
    end
    if IsStaticAA(ud.name) and IsBurstAA(ud.name) then
      --Echo("preventing overkill", attackerID, ud.name)
      return false, 1
    end
  end
  return true, 1
end]]--
