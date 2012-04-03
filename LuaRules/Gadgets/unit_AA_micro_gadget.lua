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
local EscortAA           = {} --{["corrl"] = 60, ["corrazor"] = 150, ["armcir"] = 250, ["corflak"] = 360}
local AAstats            = {}
local AAdelayedsalvo     = {}
local AABurst            = {}
local AADPS              = {}
local StaticAA           = {}
local MobileAA           = {}
MobileAA["amphaa"] = true
AABurst["amphaa"] = true
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
local loadmultiplier = 1

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
      local i = 1
      while i <= teammaxcount do
        AAdefbuff = AAdef[h].units[i]
        --Echo(AAdefbuff)
        if AAdefbuff ~= nil then
          --Echo("ID " .. AAdefbuff.id)
          if not UnitIsDead(AAdefbuff.id) then
            local targets = nil
            local morphing = IsMorphing(AAdefbuff.id)
            AAdefbuff.frame = AAdefbuff.frame + 1
            if IsIdle(AAdefbuff.id) then
              AAdefbuff.orderreceived = false
            end
            if ( IsMicroCMD(AAdefbuff.id) and IsBurstAA(AAdefbuff.name) and not IsMobileAA(AAdefbuff.name) ) or AAdefbuff.resetfirestate then
              local firestate = FireState(AAdefbuff.id)
              if firestate ~= nil and firestate ~= AAdefbuff.fire and not AAdefbuff.resetfirestate then
                GiveOrder(AAdefbuff.id, CMD.FIRE_STATE, {AAdefbuff.fire}, i, h)
              end
              if AAdefbuff.resetfirestate then
                GiveOrder(AAdefbuff.id, CMD.FIRE_STATE, {2}, i, h)
                AAdefbuff.resetfirestate = false
              end
            end
            if AAdefbuff.attacking ~= nil then
              if UnitIsDead(AAdefbuff.attacking) or not InRange(AAdefbuff.id, AAdefbuff.attacking, AAdefbuff.range) then
                AAdefbuff.attacking = nil
                AAdefbuff.gassigncounter = 0
                AAdefbuff.counter = 0
              end
            end
            weaponready, nextshot = WeaponReady(AAdefbuff.id, i, h)
            AAdefbuff.nextshot = nextshot
            --Echo(nextshot)
            if AAdefbuff.globalassign then
              AAdefbuff.gassigncounter = AAdefbuff.gassigncounter - 1
              if AAdefbuff.gassigncounter <= 0 then
                AAdefbuff.globalassign = false
                AAdefbuff.gassigncounter = 0
                unassignTarget(AAdefbuff.id, i, h)
              end
            end
            counteris0 = false
            if AAdefbuff.counter == 0 then
              AAdefbuff.counter = AAmaxcounter(AAdefbuff.name)
              if IsMicro(AAdefbuff.id) then
                counteris0 = true
                targets = getAATargetsinRange(AAdefbuff.id, i, h)
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
                    unassignTarget(AAdefbuff.id, i, h)
                    counteris0 = true
                    if targets == nil and IsMicro(AAdefbuff.id) then
                      targets = getAATargetsinRange(AAdefbuff.id, i, h)
                    end
                  end
                end
              end
              if counteris0 then
                if AAdefbuff.attacking == nil then
                  AAdefbuff.skiptarget = 0
                  if IsMicro(AAdefbuff.id) then
                    unassignTarget(AAdefbuff.id, i, h)
                    --Echo("ready, searching for target hp: " .. AAdefbuff.damage)
                    assignTarget(AAdefbuff.id, i, h, targets)
                  end
                  AAdefbuff.counter = AAmaxcounter(AAdefbuff.name)
                  AAdefbuff.refiredelay = AAmaxrefiredelay(AAdefbuff.name)
                end
                if AAdefbuff.refiredelay == 0 then
                  AAdefbuff.skiptarget = AAdefbuff.skiptarget + 1
                  --Echo(AAdefbuff.id .. "skipping " .. AAdefbuff.skiptarget .. " was attacking " .. AAdefbuff.attacking)
                  unassignTarget(AAdefbuff.id, i, h)
                  if IsMicro(AAdefbuff.id) then
                    assignTarget(AAdefbuff.id, i, h, targets)
                  end
                  --Echo(AAdefbuff.id .. " is attacking ", AAdefbuff.attacking)
                  AAdefbuff.counter = 0
                  AAdefbuff.refiredelay = AAmaxrefiredelay(AAdefbuff.name)
                elseif AAdefbuff.attacking ~= nil then
                  AAdefbuff.counter = 0
                  AAdefbuff.refiredelay = AAdefbuff.refiredelay - 1
                end
              end
            elseif not AAdefbuff.globalassign then
              --Echo("not ready, deassigning target")
              if IsMicro(AAdefbuff.id) and AAdefbuff.name ~= "missiletower" and not IsIdle(AAdefbuff.id) and not IsMobileAA(AAdefbuff.name) and not IsDPSAA(AAdefbuff.name) then
                removecommand(AAdefbuff.id, i , h)
                GiveOrder(AAdefbuff.id, CMD.STOP, nil, i, h)
              end
              unassignTarget(AAdefbuff.id, i, h)
              AAdefbuff.counter = 0
            end
            local j = 1
            while j <= AAdefbuff.projectilescount do
              AAdefbuff.projectiles[j].TOF = AAdefbuff.projectiles[j].TOF - 1
              if AAdefbuff.projectiles[j].TOF <= 0 then
                removeShot(AAdefbuff.projectiles[j].id)
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
            health, _, _, _, _ = GetHP(airbuff.id)
            airbuff.hp = health
            --Echo(airbuff.id, health, airbuff.tincoming, airtargets[h].units[i].hp)
            if airbuff.globalassign then
              airbuff.globalassigncount = airbuff.globalassigncount - 1
              --Echo("air gassigncounter", airbuff.id, airbuff.globalassigncount)
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
              local assignmentBuff = globalassignment[j]
              if assignmentBuff.name == airbuff.name then
                --Echo("coop target! " .. airbuff.id, airbuff.name)
                assignmentBuff.units[assignmentBuff.unitscount] = {id = airbuff.id, hp = airbuff.hp}
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
  local unitID, refID, allyteam, AAdefbuff
  for h = 1, globalassignmentcount - 1 do
    for i = 1, globalassignment[h].unitscount - 1 do
      targetID = globalassignment[h].units[i].id
      airbuff = GetAirUnit(targetID)
      if airbuff ~= nil then
        local tdamage = 0
        local num
        local kill = false
        --Echo("launching coop target! " .. airbuff.id, airbuff.name)
        for j = 1, airbuff.pdamagecount - 1 do
          if airbuff.pdamage[j] ~= nil then
            unitID = airbuff.pdamage[j][1]
            _, _, _, AAdefbuff = GetAAUnit(unitID)
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
                AAdefbuff.globalassign = true
                AAdefbuff.gassigncounter = AAdefbuff.nextshot + AAmaxrefiredelay(AAdefbuff.name)
                unassignTarget(unitID, refID, allyteam)
                attackTarget(unitID, airbuff.id, refID, allyteam)
                AAdefbuff.attacking = airbuff.id
                airbuff.tincoming = airbuff.tincoming + AAdefbuff.damage
                --Echo("global assign " .. AAdefbuff.id .. " targeting " .. airbuff.id .. " tincoming " .. airbuff.tincoming)
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

function assignTarget(unitID, refID, allyteam, output)
  local AAdefbuff = AAdef[allyteam].units[refID]
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
        AAdefbuff.skiptarget = 0
        unassignTarget(unitID, refID, allyteam)
        if IsMicro(AAdefbuff.id) and not IsMobileAA(AAdefbuff.name) and not IsDPSAA(AAdefbuff.name) then
          removecommand(AAdefbuff.id, refID, allyteam)
          GiveOrder(AAdefbuff.id, CMD.STOP, nil, refID, allyteam)
        end
      end
      if (AAdefbuff.name == "screamer" or AAdefbuff.name == "missiletower") and escortingAA(unitID, refID, allyteam) then
        output[1] = HSPruneTargets(output[1], output[2])
      end
      if IsBurstAA(AAdefbuff.name) then
        assign = BestTarget(output[1], output[2], damage, attacking, skip, output[3])
      else
        assign = DPSBestTarget(output[1], output[2])
      end
      --Echo("tower id " .. AAdefbuff.id, "assigned unit ID", assign)
      if assign ~= nil then
        if assign ~= attacking then
          airbuff = GetAirUnit(assign)
          if airbuff ~= nil then
            unassignTarget(unitID, refID, allyteam)
            attackTarget(unitID, assign, refID, allyteam)
            AAdefbuff.attacking = assign
            airbuff.tincoming = airbuff.tincoming + AAdefbuff.shotdamage
            --Echo("id " .. unitID .. " targeting " .. assign .. " " .. airbuff.name .. ", hp " .. airbuff.hp .. " tincoming " .. airbuff.tincoming)
          end
        end
      end
    end
    if output[2] == 0 or (output[2]~= 0 and assign == nil) then
      --Echo("no air in vision")
      notargets = true
      local state = GetUnitStates(unitID)
      if AAdefbuff.name == "corrl" and output[5] ~= 0 then
        --Echo("Land targets in range " .. output[5])
        AAdefbuff.fire = 2
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
    if not landtargets then
      AAdefbuff.fire = 0  --For now, defenders are always fire-at-will
    end
  end
  if notargets == true then
    --Echo("no visible air targets")
    unassignTarget(unitID, refID, allyteam)
  end
end

function unassignTarget(unitID, refID, allyteam)
  local AAdefbuf = AAdef[allyteam].units[refID]
  if AAdefbuf.attacking ~= nil then
    local airbuff = GetAirUnit(AAdefbuf.attacking)
    if airbuff ~= nil then
      airbuff.tincoming = airbuff.tincoming - AAdefbuf.shotdamage
      --Echo("tower " .. unitID .. " was targeting " .. attacking .. ", deassigning from " .. airbuff.name, "tincoming is now " .. airbuff.tincoming)
      if airbuff.tincoming < 0 then
        airbuff.tincoming = 0
      end
    end
    AAdefbuf.attacking = nil
  end
end

function BestTarget(targets, count, damage, current, skip, cost)
  local onehit = false
  local best = 0
  local bestcost = 0
  local besthp = 0
  local incoming
  local hp
  local airbuff
  --local hpafter
  for i = 1, count do
    if targets[i] ~= nil then
    if not UnitIsDead(targets[i]) then
      airbuff = GetAirUnit(targets[i])
      if airbuff ~= nil then
        incoming = airbuff.incoming + airbuff.tincoming
        hp = airbuff.hp
        if airbuff.id == current then
          incoming = incoming - damage
        end
        --Echo("skipping " .. skip, "considering target, id: " .. targets[i] .. ", name: " .. airbuff.name .. ", cost: " .. cost[i] ..  ", hp: " .. hp .. ", incoming: " .. incoming)
        if hp <= incoming + damage then
          --Echo("one-hittable", onehit)
          if not onehit then
            if hp - incoming >= 0 then
              --hpafter = hp - incoming
              if skip == 0 then
                best = i
                bestcost = cost[i]
                besthp = hp - incoming - damage
                onehit = true
                --Echo("new one-hit")
              else
                skip = skip - 1
              end
            end
          else
            if hp - incoming >= 0 and bestcost < cost[i] then
              --hpafter = hp - incoming
              if skip == 0 then
                best = i
                bestcost = cost[i]
                besthp = hp - incoming - damage
                --Echo("best onehit by new highest cost class")
              else
                skip = skip - 1
              end
            elseif hp - incoming >= 0 and hp - incoming - damage > besthp and bestcost == cost[i] then
              --hpafter = hp - incoming
              if skip == 0 then
                best = i
                bestcost = cost[i]
                besthp = hp - incoming - damage
                --Echo("best onehit by hp, cost tie")
              else
                skip = skip - 1
              end
            end
          end
        elseif onehit == false then
          if best ~= 0 then
            if hp - incoming >= 0 and hp - incoming < besthp then
              --hpafter = hp - incoming
              if skip == 0 then
                best = i
                besthp = hp - incoming
                --Echo("best by lowest hp")
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
                --Echo("first target")
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
    --Echo(best, besthp)
    best = targets[best]
    return best
  end
  --Echo("preventing overkill")
  return nil
end

function DPSBestTarget(targets, count)
  local best = nil
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

function getAATargetsinRange(unitID, refID, allyteam)
  local targets = {}
  local targetscost = {}
  local ltargets = {}
  local targetscount = 1
  local ltargetscount = 1
  local x, y, z = GetUnitPosition(unitID)
  local AAdefbuff = AAdef[allyteam].units[refID]
  local units = GetUnitsInCylinder(x, z, AAdefbuff.range)
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
          local timeinrange = TimeInRange(unitID, refID, allyteam, targetID)
          --Echo(timeinrange, nextshot)
          if IsBurstAA(AAdefbuff.name) and timeinrange > nextshot then
            airbuff = GetAirUnit(targetID)
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
                  airbuff.pdamage[pdamagecount] = {AAdefbuff.id, AAdefbuff.damage, timeinrange}
                  airbuff.pdamagecount = pdamagecount + 1
                else
                  airbuff.pdamage[pexisting] = {AAdefbuff.id, AAdefbuff.damage, timeinrange}
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

function WeaponReady(unitID, refID, allyteam)
  local ready
  local nextshot = -1
  local AAdefbuff = AAdef[allyteam].units[refID]
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
        --Echo("weapon fired " .. AAdefbuff.id .. " unassigning ", AAdefbuff.attacking)
        unassignTarget(unitID, refID, allyteam)
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
          --Echo(AAdefbuff.id .. "out of missiles" .. AAdefbuff.reloading[lowestreloading] .. " " .. AAdefbuff.frame)
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
      escort = escort + ( EscortAA[ud.name] or 0 )
    end
  end
  if escort >= 300 then
    return true
  end
  return false
end

function getTarget(unitID)
  local cQueue1 = GetCommandQueue(unitID)[1]
  if cQueue1 ~= nil then
    if cQueue1.id == CMD.ATTACK then
      if cQueue1.params[2] == nil then
        return cQueue1.params[1]
      end
    end
  end
  return nil
end

function IsAttacking(unitID)
  local cQueue1 = GetCommandQueue(unitID)[1]
  if cQueue1 ~= nil then
    if cQueue1.id == CMD.ATTACK then
      if cQueue1.params[2] == nil then
        return true
      end
    end
  end
  return false
end

function attackTarget(unitID, targetID, refID, allyteam)
  local AAdefbuff = AAdef[allyteam].units[refID]
  if IsMobileAA(AAdefbuff.name) then
    GiveOrder(unitID, CMD_UNIT_SET_TARGET, {targetID}, refID, allyteam)
  else
    GiveOrder(unitID, CMD.ATTACK, {targetID}, refID, allyteam)
  end
  AAdefbuff.attacking = targetID
end

function removecommand(unitID, refID, allyteam)
  local cQueue1 = GetCommandQueue(unitID)[1]
  if cQueue1 ~= nil then
    GiveOrder(unitID, CMD.REMOVE, {cQueue1.tag}, refID, allyteam)
  end
end

function GiveOrder(unitID, cmdID, params, refID, allyteam)
  if refID ~= nil and allyteam ~= nil then
    AAdef[allyteam].units[refID].orderaccept = true
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
  local _, _, _, AAdefbuff = GetAAUnit(unitID)
  if AAdefbuff ~= nil then
    playerorder = AAdefbuff.orderreceived
    local height = getAAUnitHeight(AAdefbuff.name)
    local x, y, z = GetUnitBasePosition(unitID)
    abovewater = ( y > (0 - height*0.75) )
  end
  if unitAI and not morphing and not stun and finished and not playerorder and (abovewater or AAdefbuff.name == "amphaa") then
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
  local movespeed = getairMoveSpeed(ud.name) - getAAMoveSpeed(AAdef[allyteam].units[refID].name)
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
  if AAdef[allyteam] == nil then
    AAdef[allyteam] = {units = {}}
    AAdefmaxcount[allyteam] = 0
    if allyteam > teamcount then
      teamcount = allyteam
    end
  end
  local refID = AAdefmaxcount[allyteam] + 1
  AAdef[allyteam].units[refID] = {id = unitID, range = getRange(name), attacking = nil, counter = AAmaxcounter(name), reloaded = true, name = name, reloading = {-2000, -2000, -2000, -2000}, frame = 0, deactivate = false, resetfirestate = false, morph = false, damage = damage - 5, shotdamage = sdamage - 5, orderaccept = false, orderreceived = false, refiredelay = 0, team = allyteam, inrange = {}, projectiles = {}, projectilescount = 0, shotspeed = getshotVelocity(name), cstate = false, cfire = 2, fire = 0, skiptarget = 0, nextshot = 0, globalassign = false, gassigncounter = 0}
  if IsDPSAA(name) or IsMobileAA(name) then
    AAdef[allyteam].units[refID].fire = 2
  end
  if name == "corrl" then  -- For now, all defenders are fire-at-will
    AAdef[allyteam].units[refID].fire = 0
  end
  AAdefreference[unitID] = refID
  AAdefmaxcount[allyteam] = refID
end

function addAir(unitID, unitDefID, name, allyteam)
  local health, _, _, _, _ = GetHP(unitID)
  if airtargets[allyteam] == nil then
    airtargets[allyteam] = {units = {}}
    airtargetsmaxcount[allyteam] = 0
    if allyteam > airteamcount then
      airteamcount = allyteam
    end
  end
  local refID = airtargetsmaxcount[allyteam] + 1
  airtargets[allyteam].units[refID] = {id = unitID, name = name, tincoming = 0, incoming = 0, hp = health, team = allyteam, inrange = {}, pdamage = {}, pdamagecount = 1, globalassign = false, globalassigncount = 0}
  airtargetsref[unitID] = refID
  airtargetsmaxcount[allyteam] = refID
end

function removeAA(unitID, allyteam)
  if AAdefreference[unitID] then
    local refID = AAdefreference[unitID]
    local maxID = AAdefmaxcount[allyteam]
    if maxID > 1 then
      AAdef[allyteam].units[refID] = AAdef[allyteam].units[maxID]
      AAdefreference[AAdef[allyteam].units[maxID].id] = refID
    end
    AAdef[allyteam].units[maxID] = nil
    AAdefmaxcount[allyteam] = maxID - 1
    AAdefreference[unitID] = nil
  end
end

function transferAA(unitID, newteam, oldteam)
  if AAdef[newteam] == nil then
    AAdef[newteam] = {units = {}}
    AAdefmaxcount[newteam] = 0
    if newteam > teamcount then
      teamcount = newteam
    end
  end
  local refID = AAdefmaxcount[newteam] + 1
  AAdef[newteam].units[refID] = AAdef[oldteam].units[AAdefreference[unitID]]
  AAdefmaxcount[newteam] = refID
  removeAA(unitID, oldteam)
  AAdefreference[unitID] = refID
end

function removeAir(unitID, allyteam)
  if airtargetsref[unitID] then
    local refID = airtargetsref[unitID]
    local maxID = airtargetsmaxcount[allyteam]
    --Echo("removing " .. airtargets[allyteam].units[refID].id .. " tincoming " .. airtargets[allyteam].units[refID].tincoming)
    if maxID > 1 then
      airtargets[allyteam].units[refID] = airtargets[allyteam].units[maxID]
      airtargetsref[airtargets[allyteam].units[maxID].id] = refID
    end
    airtargets[allyteam].units[maxID] = nil
    airtargetsmaxcount[allyteam] = maxID - 1
    airtargetsref[unitID] = nil
  end
end

function transferAir(unitID, newteam, oldteam)
  if airtargets[newteam] == nil then
    airtargets[newteam] = {units = {}}
    airtargetsmaxcount[newteam] = 0
    if newteam > airteamcount then
      airteamcount = newteam
    end
  end
  local refID = airtargetsmaxcount[newteam] + 1
  airtargets[newteam].units[refID] = airtargets[oldteam].units[airtargetsref[unitID]]
  airtargetsmaxcount[newteam] = refID
  removeAir(unitID, oldteam)
  airtargetsref[unitID] = refID
end

function addShot(unitID, refID, allyteam, shotID, targetID)
  local AAdefbuff = AAdef[allyteam].units[refID]
  shot[shotmaxcount + 1] = {id = shotID, unitID = unitID, refID = refID, allyteam = allyteam, prefID = nil}
  if IsAttacking(unitID) then
    targetID = getTarget(unitID)
  end
  local airbuff = GetAirUnit(targetID)
  if airbuff ~= nil then
    local distance = GetUnitSeparation(unitID, targetID)
    local flighttime = 30 * distance / AAdefbuff.shotspeed
    --Echo("shot fired " .. shotID .. " owner " .. unitID .. " target " .. targetID .. " separation " .. distance ..  " TOF " .. flighttime)
    AAdefbuff.projectiles[AAdefbuff.projectilescount + 1] = {id = shotID, target = targetID, TOF = flighttime}
    shot[shotmaxcount + 1].prefID = AAdefbuff.projectilescount + 1
    AAdefbuff.projectilescount = AAdefbuff.projectilescount + 1
    airbuff.incoming = airbuff.incoming + AAdefbuff.shotdamage
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
      if AAdefbuff.projectiles ~= nil then
      if AAdefbuff.projectiles[prefID] ~= nil then
        local target = AAdefbuff.projectiles[prefID].target
        local airbuff = GetAirUnit(target)
        if airbuff ~= nil then
          airbuff.incoming = airbuff.incoming - AAdefbuff.damage
          if airbuff.incoming < 0 then
            airbuff.incoming = 0
          end
        end
        if AAdefbuff.projectilescount > 1 then
          local shotref2 = shotreference[AAdefbuff.projectiles[AAdefbuff.projectilescount].id]
          shot[shotref2].prefID = prefID
        end
        AAdefbuff.projectiles[prefID] = AAdefbuff.projectiles[AAdefbuff.projectilescount]
        AAdefbuff.projectilescount = AAdefbuff.projectilescount - 1
      end
      end
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

function GetUnit(unitID)  --unused
  if unitID ~= nil then
    local unitDefID = GetUnitDefID(unitID)
    if unitDefID ~= nil then
      local ud = UnitDefs[unitDefID]
    else
      return nil, nil, nil, nil
    end
    local allyteam = GetUnitAllyTeam(unitID)
    if IsAA(ud.name) then
      local refID = AAdefreference[unitID]
      if refID ~= nil then
        local AAdefbuff = AAdef[allyteam].units[refID]
        return unitID, refID, allyteam, AAdefbuff
      else
        return unitID, nil, allyteam, nil
      end
    end
    if IsAir(ud.name) then
      local refID = airtargetsref[unitID]
      if refID ~= nil then
        local airbuff = airtargets[allyteam].units[refID]
        return unitID, refID, allyteam, airbuff
      else
        return unitID, nil, allyteam, nil
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
    local refID = AAdefreference[unitID]
    --Echo(refID)
    if refID ~= nil then
      local AAdefbuff = AAdef[allyteam].units[refID]
      --Echo(AAdefbuff)
      return unitID, refID, allyteam, AAdefbuff
    else
      return unitID, nil, allyteam, nil
    end
  end
  return nil, nil, nil, nil
end

function GetAirUnit(unitID)
  if unitID ~= nil then
    local allyteam = GetUnitAllyTeam(unitID)
    local refID = airtargetsref[unitID]
    if refID ~= nil then
      return airtargets[allyteam].units[refID]
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
  --local AAcount = 0
  --for h = 0, teamcount do
  --  if AAdefmaxcount[h] ~= nil then
  --    AAcount = AAcount + AAdefmaxcount[h]
  --  end
  --end
  --local aircount = 0
  --for h = 0, airteamcount do
  --  if airtargetsmaxcount[h] ~= nil then
  --    aircount = aircount + airtargetsmaxcount[h]
  --  end
  --end
  --loadmultiplier = math.min(3, math.max(1, 1 + AAcount * aircount / 1000) )
end

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
  local ud = UnitDefs[unitDefID]
  if IsAA(ud.name) then
    local _, _, _, AAdefbuff = GetAAUnit(unitID)
    if AAdefbuff ~= nil then
      if cmdID == CMD_UNIT_AI then
        local cmdDescID = FindUnitCmdDesc(unitID, CMD_UNIT_AI)
        fcmdDesc = GetUnitCmdDesc(unitID, fcmdDescID, fcmdDescID)
        if cmdParams[1] == 0 then
          nparams = {0, 'AI Off','AI On'}
          if not AAdefbuff.orderaccept then
            AAdefbuff.deactivate = true
            AAdefbuff.resetfirestate = true
          end
        else
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
              if AAstats[unitDefName] == nil then
                --Echo(unitDefName, wd.name, damage, wd.range, unitDef.height)
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
  for _, unitID in ipairs(Spring.GetAllUnits()) do
    local unitDefID = Spring.GetUnitDefID(unitID)
    gadget:UnitCreated(unitID, unitDefID)
  end
end
