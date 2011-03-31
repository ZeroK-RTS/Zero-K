-- $Id: unit_morph.lua 4651 2009-05-23 17:04:46Z carrepairer $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    unit_morph.lua
--  brief:   Adds unit morphing command
--  author:  Dave Rodgers (improved by jK, Licho and aegis)
--
--  Copyright (C) 2007.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "UnitMorph",
    desc      = "Adds unit morphing",
    author    = "trepan (improved by jK, Licho, aegis, CarRepairer)",
    date      = "Jan, 2008",
    license   = "GNU GPL, v2 or later",
    layer     = -1,
    enabled   = true
  }
end

-- Changes for "The Cursed"
--    CarRepairer: may add a customized texture in the morphdefs, otherwise uses original behavior (unit buildicon and the word Morph). Break changes made in CA.
--    aZaremoth: may add a customized text in the morphdefs


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- Interface with other gadgets:
--
--
-- During Initialize() this morph gadget creates a global table, GG.MorphInfo, from which you can read:
--
-- GG.MorphInfo[unitDefId] -- nil if for units that can't morph, otherwise a table, of key=destinationUnitDefId, value=morphCmdId
--
-- GG.MorphInfo["MAX_MORPH"] -- the number of morph handled
--
-- GG.MorphInfo["CMD_MORPH_BASE_ID"] -- The CMD ID of the generic morph command
-- GG.MorphInfo["CMD_MORPH_BASE_ID"]+1 -- The CMD ID of the first specific morph command
-- GG.MorphInfo["CMD_MORPH_BASE_ID"]+GG.MorphInfo["MAX_MORPH"] -- The CMD ID of the last specific morph command
--
-- GG.MorphInfo["CMD_MORPH_STOP_BASE_ID"] -- The CMD ID of the generic morph stop command
-- GG.MorphInfo["CMD_MORPH_STOP_BASE_ID"]+1 -- The CMD ID of the first specific morph stop command
-- GG.MorphInfo["CMD_MORPH_STOP_BASE_ID"]+GG.MorphInfo["MAX_MORPH"] -- The CMD ID of the last specific morph stop command
--
-- Thus other gadgets can know which morphing commands are available
-- Then they can simply issue:
--    Spring.GiveOrderToUnit(u,genericMorphCmdID,{},{})
-- or Spring.GiveOrderToUnit(u,genericMorphCmdID,{targetUnitDefId},{})
-- or Spring.GiveOrderToUnit(u,specificMorphCmdID,{},{})
--
-- where:
-- genericMorphCmdID is the same unique value, no matter what is the source unit or target unit
-- specificMorphCmdID is a different value for each source<->target morphing pair
--

--[[ Sample codes that could be used in other gadgets:

  -- Morph unit u
  Spring.GiveOrderToUnit(u,31210,{},{})

  -- Morph unit u into a supertank:
  local otherDefId=UnitDefNames["supertank"].id
  Spring.GiveOrderToUnit(u,31210,{otherDefId},{})

  -- In place of writing 31210 you could use a morphCmdID that you'd read with:
  local morphCmdID=(GG.MorphInfo or {})["CMD_MORPH_BASE_ID"]
  if not morphCmdID then
    Spring.Echo("Error! Can't find Morph Cmd ID!"")
    return
  end

  -- Print all the morphing possibilities:
  for src,morph in pairs(GG.MorphInfo) do
    if type(src)=="number" then
      local txt=UnitDefs[src].name.." may morph into "
      for dst,cmd in pairs(morph) do
        txt=txt..UnitDefs[src].name.." with CMD "..cmd
      end
      Spring.Echo(txt)
    end
  end

]]--

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Proposed Command ID Ranges:
--
--    all negative:  Engine (build commands)
--       0 -   999:  Engine
--    1000 -  9999:  Group AI
--   10000 - 19999:  LuaUI
--   20000 - 29999:  LuaCob
--   30000 - 39999:  LuaRules
--

local CMD_MORPH_STOP = 32210
local CMD_MORPH = 31210

local MAX_MORPH = 0 --// will increase dynamically


--------------------------------------------------------------------------------
--  COMMON
--------------------------------------------------------------------------------

--[[ // for use with any mod -_-
function GetTechLevel(udid)
  local ud = UnitDefs[udid];
  return (ud and ud.techLevel) or 0
end
]]--

-- // for use with mods like CA <_<
local function GetTechLevel(UnitDefID)
  --return UnitDefs[UnitDefID].techLevel or 0
  local cats = UnitDefs[UnitDefID].modCategories
  if (cats) then
    --// bugfix, cuz lua don't remove uppercase :(
    if     (cats["LEVEL1"]) then return 1
    elseif (cats["LEVEL2"]) then return 2
    elseif (cats["LEVEL3"]) then return 3
    elseif (cats["level1"]) then return 1
    elseif (cats["level2"]) then return 2
    elseif (cats["level3"]) then return 3
    end
  end
  return 0
end

local function isFactory(UnitDefID)
  return UnitDefs[UnitDefID].isFactory or false
end


local function isFinished(UnitID)
  local _,_,_,_,buildProgress = Spring.GetUnitHealth(UnitID)
  return (buildProgress==nil)or(buildProgress>=1)
end

local function HeadingToFacing(heading)
        return math.floor((heading + 8192) / 16384) % 4
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


if (gadgetHandler:IsSyncedCode()) then
--------------------------------------------------------------------------------
--  SYNCED
--------------------------------------------------------------------------------

include("LuaRules/colors.h.lua")

local stopPenalty  = 0.667
local morphPenalty = 1.0
local upgradingBuildSpeed = 250
local XpScale = 0.50

local XpMorphUnits = {}

local devolution = true            --// remove upgrade capabilities after factory destruction?
local stopMorphOnDevolution = true --// should morphing stop during devolution

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local morphDefs  = {} --// make it global in Initialize()
local extraUnitMorphDefs = {} -- stores mainly planetwars morphs
local hostName = nil -- planetwars hostname
local PWUnits = {} -- planetwars units
local morphUnits = {} --// make it global in Initialize()
local reqDefIDs  = {} --// all possible unitDefID's, which are used as a requirement for a morph
local morphToStart = {} -- morphes to start next frame

--// per team techlevel and owned MorphReq. units table
local teamTechLevel = {}
local teamReqUnits  = {}
local teamList = Spring.GetTeamList()
for i=1,#teamList do
  local teamID = teamList[i]
  teamReqUnits[teamID]  = {}
  teamTechLevel[teamID] = 0
end

local morphCmdDesc = {
--  id     = CMD_MORPH, -- added by the calling function because there is now more than one option
  type   = CMDTYPE.ICON,
  name   = 'Morph',
  cursor = 'Morph',  -- add with LuaUI?
  action = 'morph',
}

--// will be replaced in Initialize()
local RankToXp    = function() return 0 end
local GetUnitRank = function() return 0 end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


--// translate lowercase UnitNames to real unitname (with upper-/lowercases)
local defNamesL = {}
for defName in pairs(UnitDefNames) do
  defNamesL[string.lower(defName)] = defName
end

local function DefCost(paramName, udSrc, udDst)
  local pSrc = udSrc[paramName]
  local pDst = udDst[paramName]
  if ((not pSrc) or (not pDst) or
      (type(pSrc) ~= 'number') or
      (type(pDst) ~= 'number')) then
    return 0
  end
  local cost = (pDst - pSrc) * morphPenalty
  if (cost < 0) then
    cost = 0
  end
  return math.floor(cost)
end

local function BuildMorphDef(udSrc, morphData)
  local udDst = UnitDefNames[defNamesL[string.lower(morphData.into)] or -1]
  if (not udDst) then
    Spring.Echo('Morph gadget: Bad morph dst type: ' .. morphData.into)
    return
  else
    local unitDef = udDst
    local newData = {}
    newData.into = udDst.id
    newData.time = morphData.time or math.floor(unitDef.buildTime*7/upgradingBuildSpeed)
    newData.increment = (1 / (30 * newData.time))
    newData.metal  = morphData.metal  or DefCost('metalCost',  udSrc, udDst)
    newData.energy = morphData.energy or DefCost('energyCost', udSrc, udDst)
	newData.combatMorph = morphData.combatMorph or false
    newData.resTable = {
      m = (newData.increment * newData.metal),
      e = (newData.increment * newData.energy)
    }
    newData.tech = morphData.tech or 0
    newData.xp   = morphData.xp or 0
    newData.rank = morphData.rank or 0
    newData.facing = morphData.facing
    local require = -1
    if (morphData.require) then
      require = (UnitDefNames[defNamesL[string.lower(morphData.require)] or -1] or {}).id
      if (require) then
        reqDefIDs[require]=true
      else
        Spring.Echo('Morph gadget: Bad morph requirement: ' .. morphData.require)
        require = -1
      end
    end
    newData.require = require

    MAX_MORPH = MAX_MORPH + 1 -- CMD_MORPH is the "generic" morph command. "Specific" morph command start at CMD_MORPH+1
    newData.cmd     = CMD_MORPH      + MAX_MORPH
    newData.stopCmd = CMD_MORPH_STOP + MAX_MORPH

    if (type(GG.MorphInfo)~="table") then
        GG.MorphInfo = {["CMD_MORPH_BASE_ID"]=CMD_MORPH,["CMD_MORPH_STOP_BASE_ID"]=CMD_MORPH_STOP}
    end
    if (type(GG.MorphInfo[udSrc.id])~="table") then
        GG.MorphInfo[udSrc.id]={}
    end
    GG.MorphInfo[udSrc.id][udDst.id]=newData.cmd
    GG.MorphInfo["MAX_MORPH"] = MAX_MORPH

    newData.texture = morphData.texture
    newData.text = morphData.text
    return newData
  end
end

local function ValidateMorphDefs(mds)
  local newDefs = {}
  for src,morphData in pairs(mds) do
    local udSrc = UnitDefNames[defNamesL[string.lower(src)] or -1]
    if (not udSrc) then
      Spring.Echo('Morph gadget: Bad morph src type: ' .. src)
    else
      newDefs[udSrc.id] = {}
      if (morphData.into) then
        local morphDef = BuildMorphDef(udSrc, morphData)
        if (morphDef) then newDefs[udSrc.id][morphDef.cmd] = morphDef end
      else
        for _,morphData in pairs(morphData) do
          local morphDef = BuildMorphDef(udSrc, morphData)
          if (morphDef) then newDefs[udSrc.id][morphDef.cmd] = morphDef end
        end
      end
    end
  end
  return newDefs
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


local function UnitReqCheck(teamID, reqUnit)
  if (reqUnit==-1) then return true end

  return ((teamReqUnits[teamID][reqUnit] or 0) > 0)
end

local function GetMorphToolTip(unitID, unitDefID, teamID, morphDef, teamTech, unitXP, unitRank, teamOwnsReqUnit)
  local ud = UnitDefs[morphDef.into]
  local tt = ''
  if (morphDef.text ~= nil) then
    tt = tt .. WhiteStr  .. morphDef.text .. '\n'
  else
    tt = tt .. 'Morph into a ' .. ud.humanName .. '\n'
  end
  tt = tt .. GreenStr  .. 'time: '   .. morphDef.time     .. '\n'
  tt = tt .. CyanStr   .. 'metal: '  .. morphDef.metal    .. '\n'
  tt = tt .. YellowStr .. 'energy: ' .. morphDef.energy   .. '\n'
  if (morphDef.tech > teamTech) or
     (morphDef.xp > unitXP) or
     (morphDef.rank > unitRank) or
     (not teamOwnsReqUnit)
  then
    tt = tt .. RedStr .. 'needs'
    if (morphDef.tech>teamTech) then tt = tt .. ' level: ' .. morphDef.tech end
    if (morphDef.xp>unitXP)     then tt = tt .. ' xp: '    .. string.format('%.2f',morphDef.xp) end
    if (morphDef.rank>unitRank) then tt = tt .. ' rank: '  .. morphDef.rank .. ' (' .. string.format('%.2f',RankToXp(unitDefID,morphDef.rank)) .. 'xp)' end
    if (not teamOwnsReqUnit)    then tt = tt .. ' unit: '  .. UnitDefs[morphDef.require].humanName end
  end
  return tt
end

local function UpdateMorphReqs(teamID)
  local morphCmdDesc = {}

  local teamTech  = teamTechLevel[teamID] or 0
  local teamUnits = Spring.GetTeamUnits(teamID)
  for n=1,#teamUnits do
    local unitID   = teamUnits[n]
    local unitXP   = Spring.GetUnitExperience(unitID)
    local unitRank = GetUnitRank(unitID)
    local unitDefID = Spring.GetUnitDefID(unitID)
    local morphDefs = morphDefs[unitDefID] or {}

    for _,morphDef in pairs(morphDefs) do
      local cmdDescID = Spring.FindUnitCmdDesc(unitID, morphDef.cmd)
      if (cmdDescID) then
        local teamOwnsReqUnit = UnitReqCheck(teamID,morphDef.require)
        morphCmdDesc.disabled = (morphDef.tech > teamTech)or(morphDef.rank > unitRank)or(morphDef.xp > unitXP)or(not teamOwnsReqUnit)
        morphCmdDesc.tooltip  = GetMorphToolTip(unitID, unitDefID, teamID, morphDef, teamTech, unitXP, unitRank, teamOwnsReqUnit)
        Spring.EditUnitCmdDesc(unitID, cmdDescID, morphCmdDesc)
      end
    end
  end
end

local function AddMorphCmdDesc(unitID, unitDefID, teamID, morphDef, teamTech)
  local unitXP   = Spring.GetUnitExperience(unitID)
  local unitRank = GetUnitRank(unitID)
  local teamOwnsReqUnit = UnitReqCheck(teamID,morphDef.require)
  morphCmdDesc.tooltip = GetMorphToolTip(unitID, unitDefID, teamID, morphDef, teamTech, unitXP, unitRank, teamOwnsReqUnit)
  
  if morphDef.texture then
    morphCmdDesc.texture = "LuaRules/Images/Morph/".. morphDef.texture
    morphCmdDesc.name = ''
  else
	morphCmdDesc.texture = "#" .. morphDef.into   --//only works with a patched layout.lua or the TweakedLayout widget!
  end


  morphCmdDesc.disabled= (morphDef.tech > teamTech)or(morphDef.rank > unitRank)or(morphDef.xp > unitXP)or(not teamOwnsReqUnit)

  morphCmdDesc.id = morphDef.cmd

  local cmdDescID = Spring.FindUnitCmdDesc(unitID, morphDef.cmd)
  if (cmdDescID) then
    Spring.EditUnitCmdDesc(unitID, cmdDescID, morphCmdDesc)
  else
    Spring.InsertUnitCmdDesc(unitID, morphCmdDesc)
  end

  morphCmdDesc.tooltip = nil
  morphCmdDesc.texture = nil
  morphCmdDesc.text = nil
end


local function AddExtraUnitMorph(unitID, unitDef, teamID, morphDef)  -- adds extra unit morph (planetwars morphing)
    morphDef = BuildMorphDef(unitDef, morphDef)
    extraUnitMorphDefs[unitID] = morphDef
    AddMorphCmdDesc(unitID, unitDef.id, teamID, morphDef, 0)
end



--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


local function ReAssignAssists(newUnit,oldUnit)
  local ally = Spring.GetUnitAllyTeam(newUnit)
  local alliedTeams = Spring.GetTeamList(ally)
  for n=1,#alliedTeams do
    local teamID = alliedTeams[n]
    local alliedUnits = Spring.GetTeamUnits(teamID)
    for i=1,#alliedUnits do
      local unitID = alliedUnits[i]
      local cmds = Spring.GetCommandQueue(unitID)
      for j=1,#cmds do
        local cmd = cmds[j]
        if (cmd.id == CMD.GUARD)and(cmd.params[1] == oldUnit) then
          Spring.GiveOrderToUnit(unitID,CMD.INSERT,{cmd.tag,CMD.GUARD,0,newUnit},{})
          Spring.GiveOrderToUnit(unitID,CMD.REMOVE,{cmd.tag},{})
        end
      end
    end
  end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


local function StartMorph(unitID, unitDefID, teamID, morphDef)

  -- do not allow morph for unfinsihed units
  if not isFinished(unitID) then return true end

  if not morphDef.combatMorph then 
	Spring.SetUnitHealth(unitID, { paralyze = 1.0e9 })    --// turns mexes and mm off (paralyze the unit)
	Spring.SetUnitResourcing(unitID,"e",0)                --// turns solars off
	Spring.GiveOrderToUnit(unitID, CMD.ONOFF, { 0 }, { "alt" }) --// turns radars/jammers off
  end

  morphUnits[unitID] = {
    def = morphDef,
    progress = 0.0,
    increment = morphDef.increment,
    morphID = morphID,
    teamID = teamID,
	combatMorph = morphDef.combatMorph,
  }

  local cmdDescID = Spring.FindUnitCmdDesc(unitID, morphDef.cmd)
  if (cmdDescID) then
    Spring.EditUnitCmdDesc(unitID, cmdDescID, {id=morphDef.stopCmd, name=RedStr.."Stop"})
  end

  SendToUnsynced("unit_morph_start", unitID, unitDefID, morphDef.cmd)
end


local function StopMorph(unitID, morphData)
  morphUnits[unitID] = nil

  Spring.SetUnitHealth(unitID, { paralyze = -1})
  local scale = morphData.progress * stopPenalty
  local unitDefID = Spring.GetUnitDefID(unitID)

  Spring.SetUnitResourcing(unitID,"e", UnitDefs[unitDefID].energyMake)
  Spring.GiveOrderToUnit(unitID, CMD.ONOFF, { 1 }, { "alt" })
  local usedMetal  = morphData.def.metal  * scale
  Spring.AddUnitResource(unitID, 'metal',  usedMetal)
  --local usedEnergy = morphData.def.energy * scale
  --Spring.AddUnitResource(unitID, 'energy', usedEnergy)

  SendToUnsynced("unit_morph_stop", unitID)

  local cmdDescID = Spring.FindUnitCmdDesc(unitID, morphData.def.stopCmd)
  if (cmdDescID) then
    Spring.EditUnitCmdDesc(unitID, cmdDescID, {id=morphData.def.cmd, name=morphCmdDesc.name})
  end
end


local function FinishMorph(unitID, morphData)
  local udDst = UnitDefs[morphData.def.into]
  local ud = UnitDefs[unitID]
  local defName = udDst.name
  local unitTeam = morphData.teamID
  local px, py, pz = Spring.GetUnitBasePosition(unitID)
  local h = Spring.GetUnitHeading(unitID)
  Spring.SetUnitBlocking(unitID, false)
  morphUnits[unitID] = nil

  local oldHealth,oldMaxHealth,paralyzeDamage,captureProgress,buildProgress = Spring.GetUnitHealth(unitID)
  local isBeingBuilt = false
  if buildProgress < 1 then
    isBeingBuilt = true
  end
  local facplop = GG.HasFacplop(unitID)

  local newUnit

  if udDst.isBuilding or udDst.isFactory then
  --if udDst.isBuilding then

    local x = math.floor(px/16)*16
    local y = py
    local z = math.floor(pz/16)*16
    local face = HeadingToFacing(h)
    local xsize = udDst.xsize
    local zsize =(udDst.zsize or udDst.ysize)
    if ((face == 1) or(face == 3)) then
      xsize, zsize = zsize, xsize
    end
    if xsize/4 ~= math.floor(xsize/4) then
      x = x+8
    end
    if zsize/4 ~= math.floor(zsize/4) then
      z = z+8
    end
    newUnit = Spring.CreateUnit(defName, x, y, z, face, unitTeam, isBeingBuilt)
  if not newUnit then
    StopMorph(unitID, morphData)
    return
  end
    Spring.SetUnitPosition(newUnit, x, y, z)
  else
    newUnit = Spring.CreateUnit(defName, px, py, pz, HeadingToFacing(h), unitTeam, isBeingBuilt)
  if not newUnit then
    StopMorph(unitID, morphData)
    return
  end
    Spring.SetUnitRotation(newUnit, 0, -h * math.pi / 32768, 0)
    Spring.SetUnitPosition(newUnit, px, py, pz)
  end

  if (extraUnitMorphDefs[unitID] ~= nil) then
    -- nothing here for now
  end
  if (hostName ~= nil) and PWUnits[unitID] then
    -- send planetwars deployment message
    PWUnit = PWUnits[unitID]
    PWUnit.currentDef=udDst
    local data = PWUnit.owner..","..defName..","..math.floor(px)..","..math.floor(pz)..",".."S" -- todo determine and apply smart orientation of the structure
    Spring.SendCommands("w "..hostName.." pwmorph:"..data)
    extraUnitMorphDefs[unitID] = nil
    GG.PlanetWars.units[unitID] = nil
    GG.PlanetWars.units[newUnit] = PWUnit
    SendToUnsynced('PWCreate', unitTeam, newUnit)
  elseif (not morphData.def.facing) then  -- set rotation only if unit is not planetwars and facing is not true
    --Spring.Echo(morphData.def.facing)
    Spring.SetUnitRotation(newUnit, 0, -h * math.pi / 32768, 0)
  end


  --//copy experience
  local newXp = Spring.GetUnitExperience(unitID)*XpScale
  local nextMorph = morphDefs[morphData.def.into]
  if nextMorph~= nil and nextMorph.into ~= nil then nextMorph = {morphDefs[morphData.def.into]} end
  if (nextMorph) then --//determine the lowest xp req. of all next possible morphs
    local maxXp = math.huge
    for _, nm in pairs(nextMorph) do
      local rankXpInto = RankToXp(nm.into,nm.rank)
      if (rankXpInto>0)and(rankXpInto<maxXp) then
        maxXp=rankXpInto
      end
      local xpInto     = nm.xp
      if (xpInto>0)and(xpInto<maxXp) then
        maxXp=xpInto
      end
    end
    newXp = math.min( newXp, maxXp*0.9)
  end
  Spring.SetUnitExperience(newUnit, newXp)

  --//copy some state
  local states = Spring.GetUnitStates(unitID)
  Spring.GiveOrderArrayToUnitArray({ newUnit }, {
    { CMD.FIRE_STATE, { states.firestate },             { } },
    { CMD.MOVE_STATE, { states.movestate },             { } },
    { CMD.REPEAT,     { states["repeat"] and 1 or 0 },  { } },
    { CMD.CLOAK,      { states.cloak     and 1 or udDst.initCloaked },  { } },
    { CMD.ONOFF,      { 1 },                            { } },
    { CMD.TRAJECTORY, { states.trajectory and 1 or 0 }, { } },
  })

  --//copy command queue
  local cmds = Spring.GetUnitCommands(unitID)
  for i = 1, cmds.n do
    local cmd = cmds[i]
    Spring.GiveOrderToUnit(newUnit, cmd.id, cmd.params, cmd.options.coded)
  end

  --//reassign assist commands to new unit
  ReAssignAssists(newUnit,unitID)

  --// copy health
  -- old health is declared above
  local _,newMaxHealth         = Spring.GetUnitHealth(newUnit)
  local newHealth = (oldHealth / oldMaxHealth) * newMaxHealth
  local hpercent = newHealth/newMaxHealth
  if newHealth<=1 then newHealth = 1 end

  -- prevent conflict with rezz gadget
  if hpercent > 0.045 and hpercent < 0.055 then
    newHealth = newMaxHealth * 0.056 + 1
  end

  Spring.SetUnitHealth(newUnit, {health = newHealth, build = buildProgress})

  --// copy shield power
  local enabled,oldShieldState = Spring.GetUnitShieldState(unitID)
  if oldShieldState and Spring.GetUnitShieldState(newUnit) then
    Spring.SetUnitShieldState(newUnit, enabled,oldShieldState)
  end

  local lineage = Spring.GetUnitLineage(unitID)
  Spring.SetUnitLineage(newUnit,lineage,true)

  --// copy facplop
  if facplop then GG.GiveFacplop(newUnit) end
  
  --// FIXME: - re-attach to current transport?
  --// update selection
  SendToUnsynced("unit_morph_finished", unitID, newUnit)

  Spring.SetUnitBlocking(newUnit, true)
  Spring.DestroyUnit(unitID, false, true) -- selfd = false, reclaim = true
end


local function UpdateMorph(unitID, morphData)
  if Spring.GetUnitTransporter(unitID) then return true end

  if (Spring.UseUnitResource(unitID, morphData.def.resTable)) then
    morphData.progress = morphData.progress + morphData.increment
  end
  if (morphData.progress >= 1.0) then
    FinishMorph(unitID, morphData)
    return false -- remove from the list, all done
  end
  return true
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


function gadget:Initialize()
  --// RankApi linking
  if (GG.rankHandler) then
    GetUnitRank = GG.rankHandler.GetUnitRank
    RankToXp    = GG.rankHandler.RankToXp
  end

  -- self linking for planetwars
  GG['morphHandler'] = {}
  GG['morphHandler'].AddExtraUnitMorph = AddExtraUnitMorph

  hostName = GG.PlanetWars and GG.PlanetWars.options.hostname or nil
  PWUnits = GG.PlanetWars and GG.PlanetWars.units or {}

  if (type(GG.UnitRanked)~="table") then GG.UnitRanked = {} end
  table.insert(GG.UnitRanked, UnitRanked)

  --// get the morphDefs
  morphDefs = include("LuaRules/Configs/morph_defs.lua")
  if (not morphDefs) then gadgetHandler:RemoveGadget(); return; end
  morphDefs = ValidateMorphDefs(morphDefs)

  --// make it global for unsynced access via SYNCED
  _G.morphUnits = morphUnits
  _G.morphDefs  = morphDefs
  _G.extraUnitMorphDefs  = extraUnitMorphDefs

  --// Register CmdIDs
  for number=0,MAX_MORPH-1 do
    gadgetHandler:RegisterCMDID(CMD_MORPH+number)
    gadgetHandler:RegisterCMDID(CMD_MORPH_STOP+number)
  end


  --// check existing ReqUnits+TechLevel
  local allUnits = Spring.GetAllUnits()
  for i=1,#allUnits do
    local unitID    = allUnits[i]
    local unitDefID = Spring.GetUnitDefID(unitID)
    local teamID    = Spring.GetUnitTeam(unitID)
    if (reqDefIDs[unitDefID])and(isFinished(unitID)) then
      local teamReq = teamReqUnits[teamID]
      teamReq[unitDefID] = (teamReq[unitDefID] or 0) + 1
    end
    AddFactory(unitID, unitDefID, teamID)
  end

  --// add the Morph Menu Button to existing units
  for i=1,#allUnits do
    local unitID    = allUnits[i]
    local teamID    = Spring.GetUnitTeam(unitID)
    local unitDefID = Spring.GetUnitDefID(unitID)
    local morphDefSet  = morphDefs[unitDefID]
    if (morphDefSet) then
      local useXPMorph = false
      for _,morphDef in pairs(morphDefSet) do
        if (morphDef) then
          local cmdDescID = Spring.FindUnitCmdDesc(unitID, morphDef.cmd)
          if (not cmdDescID) then
            AddMorphCmdDesc(unitID, unitDefID, teamID, morphDef, teamTechLevel[teamID])
          end

          useXPMorph = (morphDef.xp>0) or useXPMorph
        end
      end

      if (useXPMorph) then XpMorphUnits[#XpMorphUnits+1] = {id=unitID,defID=unitDefID,team=teamID} end
    end
  end

end


function gadget:Shutdown()
  for i,f in pairs(GG.UnitRanked or {}) do
    if (f==UnitRanked) then
      table.remove(GG.UnitRanked, i)
      break
    end
  end

  local allUnits = Spring.GetAllUnits()
  for i=1,#allUnits do
    local unitID    = allUnits[i]
    local morphData = morphUnits[unitID]
    if (morphData) then
      StopMorph(unitID, morphData)
    end
    for number=0,MAX_MORPH-1 do
      local cmdDescID = Spring.FindUnitCmdDesc(unitID, CMD_MORPH+number)
      if (cmdDescID) then
        Spring.RemoveUnitCmdDesc(unitID, cmdDescID)
      end
    end
  end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


function gadget:UnitCreated(unitID, unitDefID, teamID)
  local morphDefSet = morphDefs[unitDefID]
  if (morphDefSet) then
    local useXPMorph = false
    for _,morphDef in pairs(morphDefSet) do
      if (morphDef) then
        AddMorphCmdDesc(unitID, unitDefID, teamID, morphDef, teamTechLevel[teamID])
        useXPMorph = (morphDef.xp>0) or useXPMorph
      end
    end
    if (useXPMorph) then XpMorphUnits[#XpMorphUnits+1] = {id=unitID,defID=unitDefID,team=teamID} end
  end
end


function gadget:UnitFinished(unitID, unitDefID, teamID)
  local bfrTechLevel = teamTechLevel[teamID] or 0
  AddFactory(unitID, unitDefID, teamID)

  if (reqDefIDs[unitDefID]) then
    local teamReq = teamReqUnits[teamID]
    teamReq[unitDefID] = (teamReq[unitDefID] or 0) + 1
    if (teamReq[unitDefID]==1) then
      UpdateMorphReqs(teamID)
    end
  end

  if (bfrTechLevel~=teamTechLevel[teamID]) then
    UpdateMorphReqs(teamID)
  end
end


function gadget:UnitDestroyed(unitID, unitDefID, teamID)
  if (morphUnits[unitID]) then
    StopMorph(unitID,morphUnits[unitID])
    morphUnits[unitID] = nil
  end
  local bfrTechLevel = teamTechLevel[teamID] or 0

  RemoveFactory(unitID, unitDefID, teamID)

  local updateButtons = false
  if (reqDefIDs[unitDefID])and(isFinished(unitID)) then
    local teamReq = teamReqUnits[teamID]
    teamReq[unitDefID] = (teamReq[unitDefID] or 0) - 1
    if (teamReq[unitDefID]==0) then
      StopMorphsOnDevolution(teamID)
      updateButtons = true
    end
  end

  if (bfrTechLevel~=teamTechLevel[teamID]) then
    StopMorphsOnDevolution(teamID)
    updateButtons = true
  end

  if (updateButtons) then UpdateMorphReqs(teamID) end
end


function gadget:UnitTaken(unitID, unitDefID, oldTeamID, teamID)
  self:UnitCreated(unitID, unitDefID, teamID)
  if (isFinished(unitID)) then
    self:UnitFinished(unitID, unitDefID, teamID)
  end
end


function gadget:UnitGiven(unitID, unitDefID, newTeamID, oldTeamID)
  self:UnitDestroyed(unitID, unitDefID, oldTeamID)
end


function UnitRanked(unitID,unitDefID,teamID,newRank,oldRank)
  local morphDefSet = morphDefs[unitDefID]

  if (morphDefSet) then
    local teamTech = teamTechLevel[teamID] or 0
    local unitXP   = Spring.GetUnitExperience(unitID)
    for _, morphDef in pairs(morphDefSet) do
      if (morphDef) then
        local cmdDescID = Spring.FindUnitCmdDesc(unitID, morphDef.cmd)
        if (cmdDescID) then
          local morphCmdDesc = {}
          local teamOwnsReqUnit = UnitReqCheck(teamID,morphDef.require)
          morphCmdDesc.disabled = (morphDef.tech > teamTech)or(morphDef.rank > newRank)or(morphDef.xp > unitXP)or(not teamOwnsReqUnit)
          morphCmdDesc.tooltip  = GetMorphToolTip(unitID, unitDefID, teamID, morphDef, teamTech, unitXP, newRank, teamOwnsReqUnit)
          Spring.EditUnitCmdDesc(unitID, cmdDescID, morphCmdDesc)
        end
      end
    end
  end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


function AddFactory(unitID, unitDefID, teamID)
  if (isFactory(unitDefID)) then
    local unitTechLevel = GetTechLevel(unitDefID)
    if (unitTechLevel > teamTechLevel[teamID]) then
      teamTechLevel[teamID]=unitTechLevel
    end
  end
end


function RemoveFactory(unitID, unitDefID, teamID)
  if (devolution)and(isFactory(unitDefID))and(isFinished(unitID)) then

    --// check all factories and determine team level
    local level = 0
    local teamUnits = Spring.GetTeamUnits(teamID)
    for i=1,#teamUnits do
      local unitID2 = teamUnits[i]
      if (unitID2 ~= unitID) then
        local unitDefID2 = Spring.GetUnitDefID(unitID2)
        if (isFactory(unitDefID2) and isFinished(unitID2)) then
          local unitTechLevel = GetTechLevel(unitDefID2)
          if (unitTechLevel>level) then level = unitTechLevel end
        end
      end
    end

    if (level ~= teamTechLevel[teamID]) then
      teamTechLevel[teamID] = level
    end

  end
end

function StopMorphsOnDevolution(teamID)
  if (stopMorphOnDevolution) then
    for unitID, morphData in pairs(morphUnits) do
      local morphDef = morphData.def
      if (morphData.teamID == teamID)and
         (
           (morphDef.tech>teamTechLevel[teamID])or
           (not UnitReqCheck(teamID, morphDef.require))
         )
      then
        StopMorph(unitID, morphData)
      end
    end
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


function gadget:GameFrame(n)

  -- start pending morphs
  for unitid, data in pairs(morphToStart) do
    StartMorph(unitid, unpack(data))
  end
  morphToStart = {}

  if ((n+24)%150<1) then
    local unitCount = #XpMorphUnits
    local i = 1

    while (i<=unitCount) do
      local unitdata    = XpMorphUnits[i]
      local unitID      = unitdata.id
      local unitDefID   = unitdata.defID

      local morphDefSet = morphDefs[unitDefID]
      if (morphDefSet) then
        local teamID   = unitdata.team
        local teamTech = teamTechLevel[teamID] or 0
        local unitXP   = Spring.GetUnitExperience(unitID)
        local unitRank = GetUnitRank(unitID)

        local xpMorphLeft = false
        for _,morphDef in pairs(morphDefSet) do
          if (morphDef) then
            local cmdDescID = Spring.FindUnitCmdDesc(unitID, morphDef.cmd)
            if (cmdDescID) then
              local morphCmdDesc = {}
              local teamOwnsReqUnit = UnitReqCheck(teamID,morphDef.require)
              morphCmdDesc.disabled = (morphDef.tech > teamTech)or(morphDef.rank > unitRank)or(morphDef.xp > unitXP)or(not teamOwnsReqUnit)
              morphCmdDesc.tooltip  = GetMorphToolTip(unitID, unitDefID, teamID, morphDef, teamTech, unitXP, unitRank, teamOwnsReqUnit)
              Spring.EditUnitCmdDesc(unitID, cmdDescID, morphCmdDesc)

              xpMorphLeft = morphCmdDesc.disabled or xpMorphLeft
            end
          end
        end
        if (not xpMorphLeft) then
          --// remove unit in list (it fullfills all xp requirements)
          XpMorphUnits[i] = XpMorphUnits[unitCount]
          XpMorphUnits[unitCount] = nil
          unitCount = unitCount - 1
          i = i - 1
        end
      end
      i = i + 1

    end
  end

  for unitID, morphData in pairs(morphUnits) do
    if (not UpdateMorph(unitID, morphData)) then
      morphUnits[unitID] = nil
    end
  end
end


function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	local morphData = morphUnits[unitID]
	if (morphData) then
		if (cmdID==morphData.def.stopCmd)or(cmdID==CMD.STOP and not morphData.def.combatMorph)or(cmdID==CMD_MORPH_STOP) then
			if not Spring.GetUnitTransporter(unitID) then
				StopMorph(unitID, morphData)
				morphUnits[unitID] = nil
				return false
			end
		elseif (cmdID == CMD.ONOFF) then
			return morphData.combatMorph
		elseif cmdID == CMD.SELFD then
			StopMorph(unitID, morphData)
			morphUnits[unitID] = nil
		--else --// disallow ANY command to units in morph
		--	return false
		end
	elseif (cmdID >= CMD_MORPH and cmdID <= CMD_MORPH+MAX_MORPH) then
		local morphDef = nil
		if cmdID==CMD_MORPH then
			if type(GG.MorphInfo[unitDefID])~="table" then
				--Spring.Echo('Morph gadget: AllowCommand generic morph on non morphable unit')
				return false
			elseif #cmdParams==0 then
				--Spring.Echo('Morph gadget: AllowCommand generic morph, default target')
				--return true
				for _,md in pairs(morphDefs[unitDefID]) do
					morphDef=md
					break
				end
			elseif GG.MorphInfo[unitDefID][cmdParams[1]] then
				--Spring.Echo('Morph gadget: AllowCommand generic morph, target valid')
				--return true
				morphDef=(morphDefs[unitDefID] or {})[GG.MorphInfo[unitDefID][cmdParams[1]]]
			else
				--Spring.Echo('Morph gadget: AllowCommand generic morph, invalid target')
				return false
			end
			--Spring.Echo('Morph gadget: AllowCommand morph cannot be here!')
		elseif (cmdID > CMD_MORPH and cmdID <= CMD_MORPH+MAX_MORPH) then
			--Spring.Echo('Morph gadget: AllowCommand specific morph')
			morphDef = (morphDefs[unitDefID] or {})[cmdID] or extraUnitMorphDefs[unitID]
		end
		if ((morphDef)and
				(morphDef.tech<=teamTechLevel[teamID])and
				(morphDef.rank<=GetUnitRank(unitID))and
				(morphDef.xp<=Spring.GetUnitExperience(unitID))and
				(UnitReqCheck(teamID, morphDef.require)) )
				then
			if (isFactory(unitDefID)) then
				--// the factory cai is broken and doesn't call CommandFallback(),
				--// so we have to start the morph here
				-- dont start directly to break recursion
				--StartMorph(unitID, unitDefID, teamID, morphDef)
				morphToStart[unitID] = {unitDefID, teamID, morphDef}
				return false
			else
				--// morph allowed, process it
				local morphDef = nil
				if cmdID == CMD_MORPH then
					if type(GG.MorphInfo[unitDefID])~="table" then
						--Spring.Echo('Morph gadget: CommandFallback generic morph on non morphable unit')
						return false
					end
					if cmdParams[1] then
						--Spring.Echo('Morph gadget: CommandFallback generic morph with target provided')
						morphDef=(morphDefs[unitDefID] or {})[GG.MorphInfo[unitDefID][cmdParams[1]]]
					else
						--Spring.Echo('Morph gadget: CommandFallback generic morph, default target')
						for _,md in pairs(morphDefs[unitDefID]) do
							morphDef=md
							break
						end
					end
				else
					--Spring.Echo('Morph gadget: CommandFallback specific morph')
					morphDef = (morphDefs[unitDefID] or {})[cmdID] or extraUnitMorphDefs[unitID]
				end
				if (morphDef) then
					local morphData = morphUnits[unitID]
					if (not morphData) then
						-- dont start directly to break recursion
						--StartMorph(unitID, unitDefID, teamID, morphDef)
						morphToStart[unitID] = {unitDefID, teamID, morphDef}
					end
				end
				return false
			end
		end
		return false
	end

	return true
end

--------------------------------------------------------------------------------
--  END SYNCED
--------------------------------------------------------------------------------
else
--------------------------------------------------------------------------------
--  UNSYNCED
--------------------------------------------------------------------------------

--// 75b2 compability (removed it in the next release)
if (Spring.GetTeamColor==nil) then
  Spring.GetTeamColor = function(teamID) local _,_,_,_,_,_,r,g,b = Spring.GetTeamInfo(teamID); return r,g,b end
end

--
-- speed-ups
--

local gameFrame;
local SYNCED = SYNCED
local CallAsTeam = CallAsTeam
local spairs = spairs
local snext = snext

local GetUnitTeam         = Spring.GetUnitTeam
local GetUnitHeading      = Spring.GetUnitHeading
local GetUnitBasePosition = Spring.GetUnitBasePosition
local GetGameFrame        = Spring.GetGameFrame
local GetSpectatingState  = Spring.GetSpectatingState
local AddWorldIcon        = Spring.AddWorldIcon
local AddWorldText        = Spring.AddWorldText
local IsUnitVisible       = Spring.IsUnitVisible
local GetLocalTeamID      = Spring.GetLocalTeamID
local spAreTeamsAllied    = Spring.AreTeamsAllied
local spGetGameFrame      = Spring.GetGameFrame

local glBillboard    = gl.Billboard
local glColor        = gl.Color
local glPushMatrix   = gl.PushMatrix
local glTranslate    = gl.Translate
local glRotate       = gl.Rotate
local glUnitShape    = gl.UnitShape
local glPopMatrix    = gl.PopMatrix
local glText         = gl.Text
local glPushAttrib   = gl.PushAttrib
local glPopAttrib    = gl.PopAttrib
local glBlending     = gl.Blending
local glDepthTest    = gl.DepthTest

local GL_LEQUAL      = GL.LEQUAL
local GL_ONE         = GL.ONE
local GL_SRC_ALPHA   = GL.SRC_ALPHA
local GL_ONE_MINUS_SRC_ALPHA = GL.ONE_MINUS_SRC_ALPHA
local GL_COLOR_BUFFER_BIT = GL.COLOR_BUFFER_BIT

local headingToDegree = (360 / 65535)

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local useLuaUI = false
local oldFrame = 0        --//used to save bandwidth between unsynced->LuaUI
local drawProgress = true --//a widget can do this job too (see healthbars)

local morphUnits


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--//synced -> unsynced actions

local function SelectSwap(cmd, oldID, newID)
  local selUnits = Spring.GetSelectedUnits()
  for i=1,#selUnits do
    local unitID = selUnits[i]
    if (unitID == oldID) then
      selUnits[i] = newID
      Spring.SelectUnitArray(selUnits)
      break
    end
  end


  if (Script.LuaUI('MorphFinished')) then
    if (useLuaUI) then
      local readTeam, spec, specFullView = nil,GetSpectatingState()
      if (specFullView)
        then readTeam = Script.ALL_ACCESS_TEAM
        else readTeam = GetLocalTeamID() end
      CallAsTeam({ ['read'] = readTeam }, function()
        if (IsUnitVisible(oldID)) then
          Script.LuaUI.MorphFinished(oldID,newID)
        end
      end)
    end
  end

  return true
end

local function StartMorph(cmd, unitID, unitDefID, morphID)
  if (Script.LuaUI('MorphStart')) then
    if (useLuaUI) then
      local readTeam, spec, specFullView = nil,GetSpectatingState()
      if (specFullView)
        then readTeam = Script.ALL_ACCESS_TEAM
        else readTeam = GetLocalTeamID() end
      CallAsTeam({ ['read'] = readTeam }, function()
        if (unitID)and(IsUnitVisible(unitID)) then
          Script.LuaUI.MorphStart(unitID, (SYNCED.morphDefs[unitDefID] or {})[morphID] or SYNCED.extraUnitMorphDefs[unitID])
        end
      end)
    end
  end
  return true
end

local function StopMorph(cmd, unitID)
  if (Script.LuaUI('MorphStop')) then
    if (useLuaUI) then
      local readTeam, spec, specFullView = nil,GetSpectatingState()
      if (specFullView)
        then readTeam = Script.ALL_ACCESS_TEAM
        else readTeam = GetLocalTeamID() end
      CallAsTeam({ ['read'] = readTeam }, function()
        if (unitID)and(IsUnitVisible(unitID)) then
          Script.LuaUI.MorphStop(unitID)
        end
      end)
    end
  end
  return true
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:Initialize()
  gadgetHandler:AddSyncAction("unit_morph_finished", SelectSwap)
  gadgetHandler:AddSyncAction("unit_morph_start", StartMorph)
  gadgetHandler:AddSyncAction("unit_morph_stop", StopMorph)
end


function gadget:Shutdown()
  gadgetHandler:RemoveSyncAction("unit_morph_finished")
  gadgetHandler:RemoveSyncAction("unit_morph_start")
  gadgetHandler:RemoveSyncAction("unit_morph_stop")
end

function gadget:Update()
  local frame = spGetGameFrame()
  if (frame>oldFrame) then
    oldFrame = frame
    if snext(SYNCED.morphUnits) then
      local useLuaUI_ = Script.LuaUI('MorphUpdate')
      if (useLuaUI_~=useLuaUI) then --//Update Callins on change
        drawProgress = not Script.LuaUI('MorphDrawProgress')
        useLuaUI     = useLuaUI_
      end

      if (useLuaUI) then
        local morphTable = {}
        local readTeam, spec, specFullView = nil,GetSpectatingState()
        if (specFullView)
          then readTeam = Script.ALL_ACCESS_TEAM
          else readTeam = GetLocalTeamID() end
        CallAsTeam({ ['read'] = readTeam }, function()
          for unitID, morphData in spairs(SYNCED.morphUnits) do
            if (unitID and morphData)and(IsUnitVisible(unitID)) then
              morphTable[unitID] = {progress=morphData.progress, into=morphData.def.into}
            end
          end
        end)
        Script.LuaUI.MorphUpdate(morphTable)
      end

    end
  end
end


local teamColors = {}
local function SetTeamColor(teamID,a)
  local color = teamColors[teamID]
  if (color) then
    color[4]=a
    glColor(color)
    return
  end
  local r, g, b = Spring.GetTeamColor(teamID)
  if (r and g and b) then
    color = { r, g, b }
    teamColors[teamID] = color
    glColor(color)
    return
  end
end


--//patchs an annoying popup the first time you morph a unittype(+team)
local alreadyInit = {}
local function InitializeUnitShape(unitDefID,unitTeam)
  local iTeam = alreadyInit[unitTeam]
  if (iTeam)and(iTeam[unitDefID]) then return end

  glPushMatrix()
  gl.ColorMask(false)
  glUnitShape(unitDefID, unitTeam)
  gl.ColorMask(true)
  glPopMatrix()
  if (alreadyInit[unitTeam]==nil) then alreadyInit[unitTeam] = {} end
  alreadyInit[unitTeam][unitDefID] = true
end


local function DrawMorphUnit(unitID, morphData, localTeamID)
  local h = GetUnitHeading(unitID)
  if (h==nil) then
    return  --// bonus, heading is only available when the unit is in LOS
  end
  local px,py,pz = GetUnitBasePosition(unitID)
  if (px==nil) then
    return
  end
  local unitTeam = morphData.teamID

  InitializeUnitShape(morphData.def.into,unitTeam) --BUGFIX

  local frac = ((gameFrame + unitID) % 30) / 30
  local alpha = 2.0 * math.abs(0.5 - frac)
  local angle
  if morphData.def.facing then
    angle = -HeadingToFacing(h) * 90 + 180
  else
    angle = h * headingToDegree
  end

  SetTeamColor(unitTeam,alpha)
  glPushMatrix()
  glTranslate(px, py, pz)
  glRotate(angle, 0, 1, 0)
  glUnitShape(morphData.def.into, unitTeam)
  glPopMatrix()

  --// cheesy progress indicator
  if (drawProgress)and(localTeamID)and
     ( (spAreTeamsAllied(unitTeam,localTeamID)) or (localTeamID==Script.ALL_ACCESS_TEAM) )
  then
    glPushMatrix()
    glPushAttrib(GL_COLOR_BUFFER_BIT)
    glTranslate(px, py+14, pz)
    glBillboard()
    local progStr = string.format("%.1f%%", 100 * morphData.progress)
    gl.Text(progStr, 0, -20, 9, "oc")
    glPopAttrib()
    glPopMatrix()
  end
end


function gadget:DrawWorld()
  if (not morphUnits) then
    morphUnits = SYNCED.morphUnits
    if (not morphUnits) then return end
  end


  if (not snext(morphUnits)) then
    return --//no morphs to draw
  end

  gameFrame = GetGameFrame()

  glBlending(GL_SRC_ALPHA, GL_ONE)
  glDepthTest(GL_LEQUAL)

  local spec, specFullView = GetSpectatingState()
  local readTeam
  if (specFullView) then
    readTeam = Script.ALL_ACCESS_TEAM
  else
    readTeam = GetLocalTeamID()
  end

  CallAsTeam({ ['read'] = readTeam }, function()
    for unitID, morphData in spairs(morphUnits) do
      if (unitID and morphData)and(IsUnitVisible(unitID)) then
        DrawMorphUnit(unitID, morphData,readTeam)
      end
    end
  end)
  glDepthTest(false)
  glBlending(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
end

local function split(msg,sep)
  local s=sep or '|'
  local t={}
  for e in string.gmatch(msg..s,'([^%'..s..']+)%'..s) do
    table.insert(t,e)
  end
  return t
end


-- Exemple of AI messages:
-- "aiShortName|morph|762" -- morph the unit of unitId 762
-- "aiShortName|morph|861|12" -- morph the unit of unitId 861 into an unit of unitDefId 12
--
-- Does not work because apparently Spring.GiveOrderToUnit from unsynced gadgets are ignored.
--
function gadget:AICallIn(data)
  if type(data)=="string" then
    local message = split(data)
    if message[1] == "Shard" or true then-- Because other AI shall be allowed to send such morph command without having to pretend to be Shard
      if message[2] == "morph" and message[3] then
        local unitID = tonumber(message[3])
        if unitID and Spring.ValidUnitID(unitID) then
          if message[4] then
            local destDefId=tonumber(message[4])
            --Spring.Echo("Morph AICallIn: Morphing Unit["..unitID.."] into "..UnitDefs[destDefId].name)
            Spring.GiveOrderToUnit(unitID,CMD_MORPH,{destDefId},{})
          else
            --Spring.Echo("Morph AICallIn: Morphing Unit["..unitID.."] to auto")
            Spring.GiveOrderToUnit(unitID,CMD_MORPH,{},{})
          end
        else
          Spring.Echo("Not a valid unitID in AICallIn morph request: \""..data.."\"")
        end
      end
    end
  end
end

-- Just something to test the above AICallIn
--function gadget:KeyPress(key)
--  if key==32 then--space key
--    gadget:AICallIn("asn|morph|762")
--  end
--end

--------------------------------------------------------------------------------
--  UNSYNCED
--------------------------------------------------------------------------------
end
--------------------------------------------------------------------------------
--  COMMON
--------------------------------------------------------------------------------

