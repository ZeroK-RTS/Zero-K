-- $Id: main.lua 4534 2009-05-04 23:35:06Z licho $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    LuaRules/Deploy/main.lua
--  brief:   deployment game mode
--  author:  Dave Rodgers
--
--  Copyright (C) 2007.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  TODO:  - better storage handling for reloads
--         - better checkAllTeams
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

VFS.Include("LuaRules/colors.h.lua")

local SetupBuilds = VFS.Include("LuaRules/Deploy/builds.lua")

local options
if (Spring.GetModOption("zkmode")=="tactics") then
  options = VFS.Include("LuaRules/Configs/tactics.lua")
else
  options = VFS.Include("LuaRules/Configs/deployment.lua")
end


--
--  Config variables
--

--
--  Hide the comm during deployment, and destroy it when the game starts
--  FIXME: need to move the comm away, it blocks builds
--
local noComm = false
if (Game.commEnds) then
  noComm = false
end

--
--  Check teams without players when looking for ready teams
--
local checkAllTeams = true


--
--  Global variables
--

Deploy = true

teams = {}

maxUnits  = options.maxUnits
maxMetal  = options.maxMetal
maxEnergy = options.maxEnergy
maxRadius = options.maxRadius
maxFrames = options.maxFrames    -- FIXME: too long (testing)

frames = 0


local function DeleteGlobals()
  Deploy     = nil
  teams      = nil
  maxMetal   = nil
  maxEnergy  = nil
  maxRadius  = nil
  frames     = nil
  -- functions
  UpdateAllTeams  = nil
  UpdateTeamUnits = nil
end


local function DeleteCallIns()
  Shutdown          = nil; Script.UpdateCallIn('Shutdown')
  GameFrame         = nil; Script.UpdateCallIn('GameFrame')
  GotChatMsg        = nil; Script.UpdateCallIn('GotChatMsg')
  UnitCreated       = nil; Script.UpdateCallIn('UnitCreated')
  UnitDamaged       = nil; Script.UpdateCallIn('UnitDamaged')
  AllowCommand      = nil; Script.UpdateCallIn('AllowCommand')
  UnitDestroyed     = nil; Script.UpdateCallIn('UnitDestroyed')
  AllowUnitTransfer = nil; Script.UpdateCallIn('AllowUnitTransfer')
end


--
-- custom command IDs
--

local CMD_DEPLOY_READY  = 33300
local CMD_DEPLOY_DELETE = 33301


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function RawCreateUnit(...)
  local tmpUnitCreated = UnitCreated
  UnitCreated = nil
  local unitID = Spring.CreateUnit(...)
  UnitCreated = tmpUnitCreated
  return unitID
end


local function RawGiveOrderToUnit(...)
  local tmpAllowCommand = AllowCommand
  AllowCommand = nil
  Spring.GiveOrderToUnit(...)
  AllowCommand = tmpAllowCommand
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Command Description Utilities
--

local function HideCmdDescs(unitID)
  local cds = Spring.GetUnitCmdDescs(unitID)
  if (cds) then
    for i = 1, #cds do
      if ((cds[i].id >= 0) and (cds[i].id ~= CMD_DEPLOY_READY)) then
        Spring.EditUnitCmdDesc(unitID, i, { hidden = true })
      end
    end 
  end    
end


local function ClearCmdDescs(unitID)
  local cds = Spring.GetUnitCmdDescs(unitID)
  if (cds) then
    for i = 1, #cds do
      Spring.RemoveUnitCmdDesc(unitID)
    end
  end    
end


local function RemoveCmdDescID(unitID, cmdDescID)
  local index = Spring.FindUnitCmdDesc(unitID, cmdDescID)
  if (index) then
    Spring.RemoveUnitCmdDesc(unitID, index)
  end
end


local function ClearBuildCmdDescs(unitID)
  local cds = Spring.GetUnitCmdDescs(unitID)
  if (cds) then
    local offset = 0
    for i = 1, #cds do
      if (cds[i].id < 0) then
        Spring.RemoveUnitCmdDesc(unitID, i + offset)
        offset = offset - 1
      end
    end
  end    
end


local function AddBuildCmdDesc(unitID, buildDefID)
  local ud = UnitDefs[buildDefID]
  if (ud == nil) then
    return
  end
  if (Spring.FindUnitCmdDesc(unitID, -buildDefID)) then
    return
  end
  Spring.InsertUnitCmdDesc(unitID, {
    id     = -buildDefID,
    type   = CMDTYPE.ICON_BUILDING,
    name   = ud.name,
    action = 'buildunit_' .. ud.name:lower(),
    tooltip = "Build: "      .. ud.humanName  .. "\n" ..
              "Health "      .. ud.health     .. "\n" ..
              "Metal cost "  .. ud.metalCost  .. "\n" ..
              "Energy cost " .. ud.energyCost ..
              " Build time " .. ud.buildTime,
    params = { GreenStr .. '123', RedStr .. '12' },
  })
end


local function AddReadyCmdDesc(unitID)
  local w = '\255\255\255\255'
  local r = '\255\255\100\100'
  local g = '\255\100\255\100'
  local b = '\255\160\160\255'

  Spring.InsertUnitCmdDesc(unitID, 1, {
    id      = CMD_DEPLOY_READY,
    type    = CMDTYPE.ICON,
    name    = RedStr .. 'Ready',
    tooltip = g..'GO TIME!\n' ..
              w..'('..b..'can '..r..'not'..b..' be turned off'..w..')'
  })
end


local function AddDeleteCmdDesc(unitID)
  Spring.InsertUnitCmdDesc(unitID, 1, {
    id      = CMD_DEPLOY_DELETE,
    type    = CMDTYPE.ICON,
    name    = RedStr .. 'Delete',
    action  = 'selfd',
    tooltip = 'Remove this unit from the current deployment'
  })
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Dummy Units
--

local function SetupDummyUnit(unitID)
--  ClearCmdDescs(unitID)
  RemoveCmdDescID(unitID, CMD.SELFD)
  AddDeleteCmdDesc(unitID)
  Spring.MoveCtrl.Enable(unitID)
  Spring.MoveCtrl.SetGravity(unitID, 0)
  Spring.SetUnitStealth(unitID, true)
  Spring.SetUnitMetalExtraction(unitID, 0, 0)
  Spring.SetUnitHealth(unitID, { paralyze = math.huge })
  RawGiveOrderToUnit(unitID, CMD.STOP, {}, {})
end


local function DummyBuild(unitDefID)
  
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  StartGame()
--

local unitCmds = {}   -- { oldID = { cmds, fcmds } }

local unitIDMap = {}  -- { oldID = newID }

local unitCmdTypeID = {
  [ CMDTYPE.ICON_UNIT                 ] = true,
  [ CMDTYPE.ICON_UNIT_OR_MAP          ] = true,
  [ CMDTYPE.ICON_UNIT_OR_AREA         ] = true,
  [ CMDTYPE.ICON_UNIT_FEATURE_OR_AREA ] = true,
  [ CMDTYPE.ICON_UNIT_OR_RECTANGLE    ] = true,
}


local function IsUnitCommand(unitID, cmdID, cmdParams)
  if (#cmdParams ~= 1) then
    return false
  end
  if (cmdParams[1] >= Game.maxUnits) then
    return false  -- a feature ID
  end
  local cdID = Spring.FindUnitCmdDesc(unitID, cmdID)
  if (cdID) then
    local cd = Spring.GetUnitCmdDescs(unitID, cdID)[1]
    if (unitCmdTypeID[cd.type]) then
      return true
    end
  end
  return false
end


local function CopyCommands()
  for oldID, cmdSet in pairs(unitCmds) do
    local newID = unitIDMap[oldID]
    if (newID and Spring.GetUnitDefID(newID)) then
      local cmds = cmdSet.cmds
      if (cmds) then
        for _,cmd in ipairs(cmds) do
          if (not IsUnitCommand(newID, cmd.id, cmd.params)) then
            RawGiveOrderToUnit(newID, cmd.id, cmd.params, cmd.options.coded)
          else
            cmd.params[1] = unitIDMap[cmd.params[1]]
            if (cmd.params[1]) then
              RawGiveOrderToUnit(newID, cmd.id, cmd.params, cmd.options.coded)
            end
          end
        end
      end
      local fcmds = cmdSet.fcmds
      if (fcmds) then
        for _,cmd in ipairs(fcmds) do
          RawGiveOrderToUnit(newID, cmd.id, {}, {})
        end
      end
    end
  end
  unitCmds = nil
end


local function CopyUnit(unitID)
  local _,_,_,_,bp = Spring.GetUnitHealth(unitID)
  if ((not bp) or (bp < 1.0)) then
    Spring.SetUnitBlocking(unitID, false)
    Spring.DestroyUnit(unitID, false, true)
    return
  end
  local udid = Spring.GetUnitDefID(unitID)
  local ud = UnitDefs[udid]
  local px, py, pz = Spring.GetUnitBasePosition(unitID)
  local facing = Spring.GetUnitBuildFacing(unitID)
  local team   = Spring.GetUnitTeam(unitID)
  local cmds   = Spring.GetUnitCommands(unitID)
  local fcmds  = Spring.GetFactoryCommands(unitID)
  local states = Spring.GetUnitStates(unitID)

  unitCmds[unitID] = { cmds = cmds, fcmds = fcmds }

  Spring.RemoveBuildingDecal(unitID)
  Spring.SetUnitBlocking(unitID, false)
  Spring.DestroyUnit(unitID, false, true)

  local newUnit = RawCreateUnit(ud.name, px, py, pz, facing, team)

  unitIDMap[unitID] = newUnit

  -- copy some state
  local states = Spring.GetUnitStates(unitID)
  Spring.GiveOrderArrayToUnitArray({ newUnit }, {
    { CMD.FIRE_STATE, { states.firestate },             {} },
    { CMD.MOVE_STATE, { states.movestate },             {} },
    { CMD.REPEAT,     { states['repeat']  and 1 or 0 }, {} },
    { CMD.CLOAK,      { states.cloak      and 1 or 0 }, {} },
    { CMD.ONOFF,      { states.active     and 1 or 0 }, {} },
    { CMD.TRAJECTORY, { states.trajectory and 1 or 0 }, {} },
  })
  
  return newUnit
end


local function StartGame()

  DeleteCallIns()
  
  Spring.SetNoPause(false)
  Spring.SetUnitToFeature(true)

  for id,team in pairs(teams) do
    for _,unitID in ipairs(team.units) do
      local px, py, pz = Spring.GetUnitBasePosition(unitID)
      if (px) then -- FIXME?
      local d = 100 -- FIXME  (block flattening, or use the right value)
      Spring.RevertHeightMap(px - d, pz - d, px + d, pz + d, 1.0)
      end
    end

    for _,unitID in ipairs(team.units) do
      CopyUnit(unitID)
    end
    if (not noComm) then
      team.comm = CopyUnit(team.comm)
    else
      Spring.DestroyUnit(team.comm, false, true)
    end
    
    Spring.SetTeamResource(team.id, 'metal',  maxMetal - team.metal)
    Spring.SetTeamResource(team.id, 'energy', maxEnergy - team.energy)
  end

  CopyCommands()

  SendToUnsynced('StartGame')

  DeleteGlobals()

  VFS.Include("LuaRules/gadgets.lua")

  Spring.PlaySoundFile('LuaRules/Deploy/gotime.wav', 1.0)
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  AddBuild() & RemoveBuild()
--

local function CheckNewBuild(team, defID)
  local ud = UnitDefs[defID]
  if (#team.units >= maxUnits) then
    return false
  end
  if ((team.metal + ud.metalCost) > maxMetal) then
    return false
  end
  if ((team.energy + ud.energyCost) > maxEnergy) then
    return false
  end
  return true
end


local function AddBuild(team, defID, params)
  if (not CheckNewBuild(team, defID)) then
    return
  end
  if ((#params ~= 4) or (team.buildsMap[defID] == nil)) then
    return
  end

  local px, py, pz = params[1], params[2], params[3]
  local dx, dz = team.x - px, team.z - pz
  local dist = math.sqrt((dx * dx) + (dz * dz))
  if (dist > maxRadius) then return end

  local facing = params[4]
  local ud = UnitDefs[defID]
  if (ud == nil)  then return end

  local state, feature = Spring.TestBuildOrder(defID, px, py, pz, facing)
  if ((state ~= 2) or (feature ~= nil)) then return end

  local unitID = RawCreateUnit(ud.name, px, py, pz, facing, team.id)

  SetupDummyUnit(unitID)
  table.insert(team.units, unitID)
  UpdateTeamUnits(team)

  local d = 100 -- FIXME  (block flattening, or use the right value)
  Spring.RevertHeightMap(px - d, pz - d, px + d, pz + d, 1.0)
end


local function RemoveBuild(team, unitID)
  if (unitID == team.comm) then
    return
  end
  local index
  for i,uid in ipairs(team.units) do
    if (uid == unitID) then
      index = i
      break
    end
  end
  if (index ~= nil) then
    table.remove(team.units, index)
    Spring.RemoveBuildingDecal(unitID)

    local d = 100 -- FIXME  (block flattening, or use the right value)
    local px, py, pz = Spring.GetUnitBasePosition(unitID)

    Spring.RevertHeightMap(px - d, pz - d, px + d, pz + d, 1.0)
    Spring.SetUnitBlocking(unitID, false)
    Spring.DestroyUnit(unitID, false, true)
    UpdateTeamUnits(team)
  end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  UpdateTeamUnits()
--

function UpdateAllTeams()
  for _,team in pairs(teams) do
    UpdateTeamUnits(team)
  end
end


function UpdateTeamUnits(team)
  local metal = 0
  local energy = 0
  local buildCounts = {}
  for _,uid in ipairs(team.units) do
    local udid = Spring.GetUnitDefID(uid)
    local ud = UnitDefs[udid]
    metal  = metal  + ud.metalCost
    energy = energy + ud.energyCost
    buildCounts[udid] = buildCounts[udid] and (buildCounts[udid] + 1) or 1
  end
  team.metal = metal
  team.energy = energy

  local cmdDescs = Spring.GetUnitCmdDescs(team.comm)
  for i,cd in ipairs(cmdDescs) do
    if (cd.id < 0) then
      local ud = UnitDefs[-cd.id]
      local mMax = math.floor((maxMetal  - team.metal)  / ud.metalCost)
      local eMax = math.floor((maxEnergy - team.energy) / ud.energyCost)
      local max = maxUnits
      if (mMax < max) then max = mMax end
      if (eMax < max) then max = eMax end
      local bc = buildCounts[-cd.id]
      local countStr = bc and (GreenStr .. bc) or ''
      local maxStr = '\255\255\200\100' .. max
      Spring.EditUnitCmdDesc(team.comm, i, {
        disabled = (max <= 0),
        params = { countStr, maxStr }
      })
    end
  end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  AllowCommand
--

local function GetCancelBuildID(teamID, buildID, cmdParams)
  if (#cmdParams < 3) then
    return nil
  end
  local bud = UnitDefs[buildID]
  if (not bud) then
    return nil
  end
  local bx, by, bz = cmdParams[1], cmdParams[2], cmdParams[3]
  local bfacing = (#cmdParams >= 4) and cmdParams[4] or 0

  local btwist = ((bfacing % 2) == 1)
  local bsx = btwist and bud.ysize or bud.xsize
  local bsz = btwist and bud.xsize or bud.ysize
  
  local function max(a, b) return (a > b) and a or b end

  local ss = Game.squareSize
  local units = Spring.GetTeamUnits(teamID)
  for _,uid in ipairs(units) do
    local udid = Spring.GetUnitDefID(uid)
    local ud = UnitDefs[udid]
    local facing = Spring.GetUnitBuildFacing(uid)
    local twist = ((facing % 2) == 1)
    local sx = twist and ud.ysize or ud.xsize
    local sz = twist and ud.xsize or ud.ysize
    local x, y, z = Spring.GetUnitBasePosition(uid)
    if (((math.abs(bx - x) * 2) <= (ss * max(sx, bsx))) and
        ((math.abs(bz - z) * 2) <= (ss * max(sz, bsz)))) then
      return uid
    end
  end

  return nil
end


local function ReadyCommand(team, cmdOptions)
  if (cmdOptions.alt and cmdOptions.ctrl) then
    local name,active,spec,hostTeam = Spring.GetPlayerInfo(0)
    if (team.id == hostTeam) then
      for _,t in pairs(teams) do
        t.ready = true
      end
      Spring.Echo("Host player forced the game start")
      return
    end
  end
  if (noComm and (#team.units <= 0)) then
    Spring.SendMessageToTeam(team.id,
      "You have no units, you are not ready"
    )
    return
  end
  team.ready = true
  local cdID = Spring.FindUnitCmdDesc(team.comm, CMD_DEPLOY_READY)
  if (cdID) then
    local c = '\255\100\255\255'
    local w = '\255\255\255\255'
    local y = '\255\225\225\100'
    local m = '\255\255\100\255'
    Spring.EditUnitCmdDesc(team.comm, cdID, {
      name = GreenStr .. 'Ready',
      tooltip = c..'Waiting for the other players\n' ..
                y..'Host can use '..
                m..'ALT'..w..'+'..m..'CTRL'..w..'+'..m..'CLICK'..
                y..' to force start the game'
    })
  end
end


function AllowCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions)
  local team = teams[unitTeam]
  if (team == nil) then
    return false
  end

  if ((cmdID < 0) and (unitID	== team.comm)) then
    local cancelID = GetCancelBuildID(unitTeam, -cmdID, cmdParams)
    if (cancelID == nil) then
      AddBuild(team, -cmdID, cmdParams)
    else
      if (cancelID ~= team.comm) then
        RemoveBuild(team, cancelID)
      end
    end
  elseif (cmdID == CMD_DEPLOY_DELETE) then
    for _,team in pairs(teams) do
      if (unitID == team.comm) then
        return false
      end
    end
    RemoveBuild(team, unitID)
  elseif ((#cmdParams == 1) and (cmdOptions.right) and (cmdOptions.alt)) then
    for _,team in pairs(teams) do
      if (unitID == team.comm) then
        RemoveBuild(team, cmdParams[1])
      end
    end
  elseif (cmdID == CMD_DEPLOY_READY) then
    ReadyCommand(team, cmdOptions)
  else
    return true
  end
  
  return false
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  UnitCreated
--

function UnitCreated(unitID, unitDefID, unitTeam)
  team = teams[unitTeam]
  if (team) then
    local destroy = false
    if (team.buildsMap[unitDefID] == nil) then
      destroy = true
    end
    local px, py, pz = Spring.GetUnitBasePosition(unitID)
    local dx, dz = (team.x - px), (team.z - pz)
    local dist = math.sqrt((dx * dx) + (dz * dz))
    if (dist > maxRadius) then
      destroy = true
    end
    if (destroy) then
      local d = 100 -- FIXME  (block flattening, or use the right value)
      Spring.RevertHeightMap(px - d, pz - d, px + d, pz + d, 1.0)
      Spring.RemoveBuildingDecal(unitID)
      Spring.SetUnitBlocking(unitID, false)
      Spring.DestroyUnit(unitID, true)
      return
    end
    table.insert(team.units, unitID)
    SetupDummyUnit(unitID)
    UpdateTeamUnits(team)
  end
end


function UnitDamaged(unitID)
  Spring.SetUnitHealth(unitID,math.huge)
end


function UnitDestroyed(unitID, _, unitTeam)
  local team = teams[unitTeam]
  RemoveBuild(team, unitID)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Team Limit Checks
--

local function GetLastUnit(team)
  local unitID = team.units[#team.units]
  local udid = Spring.GetUnitDefID(unitID)
  local ud = UnitDefs[udid]
  return unitID, ud
end


local function CheckCount(team)
  while (#team.units > maxUnits) do
    local unitID = GetLastUnit(team)
    RemoveBuild(team, unitID)
  end
end


local function CheckMetal(team)
  while (team.metal > maxMetal) do
    local unitID, ud = GetLastUnit(team)
    team.metal = team.metal - ud.metalCost
    RemoveBuild(team, unitID)
  end
  if (update) then UpdateTeamUnits(team) end
end


local function CheckEnergy(team)
  while (team.energy > maxEnergy) do
    local unitID, ud = GetLastUnit(team)
    team.energy = team.energy - ud.energyCost
    RemoveBuild(team, unitID)
  end
end


local function CheckRadius(team)
  for i = #team.units, 1, -1 do
    local unitID = team.units[i]
    local px, py, pz = Spring.GetUnitBasePosition(unitID)
    local dx, dz = team.x - px, team.z - pz
    local dist = math.sqrt((dx * dx) + (dz * dz))
    if (dist > maxRadius) then
      RemoveBuild(team, unitID)
    end
  end
end


local function CheckType(team)
  for i = #team.units, 1, -1 do
    local unitID = team.units[i]
    local udid = Spring.GetUnitDefID(unitID)
    if (not team.buildsMap[udid]) then
      RemoveBuild(team, unitID)
    end
  end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  GotChatMsg()
--

local function MakeWords(line)
  local words = {}
  for w in line:gmatch("[^%s]+") do
    table.insert(words, w)
  end   
  return words
end


function GotChatMsg(msg, playerID)
  print('GotChatMsg: ' .. msg)
  if (playerID ~= 0) then
    Spring.Echo('Only the host can configure deployment parameters')
    return true
  end
  local words = MakeWords(msg)
  local cmd = words[1]
  
  if ((cmd == 'run') or (cmd == 'echo')) then
    if (not Spring.IsCheatingEnabled()) then
      Spring.Echo('run & echo require that cheating be enabled')
      return true
    end
    local _,_,line = msg:find("[%s]*[^%s]+[%s]+(.*)")
    if (cmd == 'run') then
      local chunk, err = loadstring(line, "run", _G)
      if (chunk) then
        chunk()
      end
    elseif (cmd == 'echo') then
      local chunk, err = loadstring("return " .. line, "echo", _G)
      if (chunk) then
        Spring.Echo(chunk())
      end
    end
    return true
  elseif ((cmd == 'urun') or (cmd == 'uecho')) then
    if (not Spring.IsCheatingEnabled()) then
      Spring.Echo('urun & uecho require that cheating be enabled')
      return true
    end
    local _,_,line = msg:find("[%s]*[^%s]+[%s]+(.*)")
    SendToUnsynced(cmd, line)
    return true
  end

  if (cmd ~= 'deploy') then
    return false
  end

  cmd = words[2]
  local value  = tonumber(words[3])
  if (value) then
    if (value < 1) then value = 1 end
  end

  if (cmd == nil) then
    Spring.Echo( 'deploy "start"')
    Spring.Echo(
      'deploy [ "time" | "units" | "metal" | "energy" | "radius" ] <value>'
    )
    return true
  end
    
  if (cmd == 'start') then
    for _,team in pairs(teams) do
      team.ready = true
    end
    return true
  end
  
  if (not Spring.IsCheatingEnabled()) then
    Spring.Echo('deploy [ "time" | "units" | "metal" | "energy" | "radius" ]')
    Spring.Echo('require that cheating be enabled')
    return true
  end

  if ((cmd == 't') or (cmd == 'time')) then
    if (value) then
      maxFrames = value * Game.gameSpeed
      frames = 0
    end
  elseif ((cmd == 'u') or (cmd == 'units')) then
    if (value) then
      maxUnits = value
      for _,team in pairs(teams) do
        CheckCount(team)
        UpdateTeamUnits(team)
      end
    end
  elseif ((cmd == 'm') or (cmd == 'metal')) then
    if (value) then
      maxMetal = value
      for _,team in pairs(teams) do
        CheckMetal(team)
        UpdateTeamUnits(team)
      end
    end
  elseif ((cmd == 'e') or (cmd == 'energy')) then
    if (value ) then
      maxEnergy = value
      for _,team in pairs(teams) do
        CheckEnergy(team)
        UpdateTeamUnits(team)
      end
    end
  elseif ((cmd == 'r') or (cmd == 'radius')) then
    if (value) then
      maxRadius = value
      for _,team in pairs(teams) do
        CheckRadius(team)
        UpdateTeamUnits(team)
      end
      SendToUnsynced('NewRadius')
    end
  end

  return true
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Team Setup
--

local function SetupCommander(team)
  if (noComm) then
    HideCmdDescs(team.comm)
  else
    ClearBuildCmdDescs(team.comm)
  end
  RemoveCmdDescID(team.comm, CMD.SELFD)
  AddReadyCmdDesc(team.comm)
  for _,bid in ipairs(team.builds) do
    AddBuildCmdDesc(team.comm, bid)
  end

--  Spring.MoveCtrl.Enable(team.comm)  
  if (noComm) then
--    Spring.SetUnitNoSelect(team.comm, true)
    Spring.SetUnitNoDraw(team.comm, true)
    Spring.SetUnitNoMinimap(team.comm, true)
    Spring.SetUnitBlocking(team.comm, false)
    local x,y,z = Spring.GetUnitPosition(team.comm)
    Spring.SetUnitPosition(team.comm, x, 10000, z)
  end
  Spring.SetUnitHealth(team.comm, { paralyze = math.huge })
  Spring.SetUnitStealth(team.comm, true)
  Spring.SetUnitMetalExtraction(team.comm, 0, 0)
  Spring.SetUnitRotation(team.comm, 0, 0, 0)
  RawGiveOrderToUnit(team.comm, CMD.STOP, {}, {})
end


local function MakeTeam(teamID)
  if ((teamID == Spring.GetGaiaTeamID()) or
      (teamID == (Game.maxTeams - 1))) then
    return nil
  end

  local units = Spring.GetTeamUnits(teamID)
  local commID, commIndex
  for i,unitID in ipairs(Spring.GetTeamUnits(teamID)) do
    if (UnitDefs[Spring.GetUnitDefID(unitID)].customParms.commtype) then
      commID = unitID
      commIndex = i
      break
    end
  end
  if (not commID) then return end
  table.remove(units, commIndex)

  -- sort in reverse numerical order (first come, first served)
  table.sort(units, function(a, b) return (a > b) end)

  local team = {}
  team.id     = teamID
  team.comm   = commID
  team.builds = {}
  team.units  = units
  team.metal  = 0
  team.energy = 0
  team.ready  = false
  team.x, team.y, team.z = Spring.GetUnitPosition(team.comm)
  team.y = Spring.GetGroundHeight(team.x, team.z)

  local _,mStorage = Spring.GetTeamResources(team.id, 'metal')
  local _,eStorage = Spring.GetTeamResources(team.id, 'energy')
  team.metalStorage  = mStorage
  team.energyStorage = eStorage

  team.builds, team.buildsMap = SetupBuilds(team.comm)

  SetupCommander(team)

  return team
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function AllowUnitTransfer()
  Spring.Echo('No unit sharing while deploying')
  return false
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function Shutdown()
--  StartGame()
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Initialize
--

local needInit = true


local function KillTeamFeatures(teamID)
  local features = Spring.GetFeaturesInRectangle(0, 0, 1e9, 1e9)
  for _,fid in ipairs(features) do
    if (Spring.GetFeatureTeam(fid) == teamID) then
      Spring.DestroyFeature(fid)
    end
  end
end


do
  local tmpUnitCreated   = UnitCreated
  local tmpUnitDamaged   = UnitDamaged
  local tmpUnitDestroyed = UnitDestroyed
  local tmpAllowCommand  = AllowCommand

  function RestoreCallIns()
    UnitCreated   = tmpUnitCreated;   Script.UpdateCallIn('UnitCreated')
    UnitDamaged   = tmpUnitDamaged;   Script.UpdateCallIn('UnitDamaged')
    UnitDestroyed = tmpUnitDestroyed; Script.UpdateCallIn('UnitDestroyed')
    AllowCommand  = tmpAllowCommand;  Script.UpdateCallIn('AllowCommand')
    RestoreCallIns = nil
  end
  UnitCreated  = nil
  AllowCommand = nil
end


local function Initialize()

  Spring.PlaySoundFile('LuaRules/Deploy/deploy.wav', 1.0)

  needInit = false

  RestoreCallIns()

  for _,tid in ipairs(Spring.GetTeamList()) do
    local team = MakeTeam(tid)
    if (team) then
      teams[tid] = team
      KillTeamFeatures(tid)
      for _,unitID in ipairs(team.units) do
        SetupDummyUnit(unitID)
      end

      CheckType(team)
      CheckCount(team)
      CheckMetal(team)
      CheckEnergy(team)
      CheckRadius(team)

      UpdateTeamUnits(team)
    end
  end

  Spring.SetNoPause(true)
  Spring.SetUnitToFeature(false)

  Script.AddActionFallback(
    'deploy ',
    ' [ "time" | "units" | "metal" | "energy" | "radius" ] <value>'
  )
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  GameFrame()
--

local function TeamHasPlayer(teamID)
  local havePlayer = false
  local players = Spring.GetPlayerList()
  for _,pid in ipairs(players) do
    local name,active,spec,team = Spring.GetPlayerInfo(pid)
    if ((team == teamID) and active and (not spec)) then
      return true
    end
  end
  return false
end


function GameFrame(frameNum)
  if (needInit) then
    Initialize()
  end

  frames = frames + 1
  if (frames >= maxFrames) then
    StartGame()
    return
  end

  local allReady = true
  for teamID,team in pairs(teams) do
    local _, _, _, isDead = Spring.GetTeamInfo(team.id)
    if (isDead) then
      teams[teamID] = nil
    else
      Spring.SetTeamResource(team.id, 'metal',  0)
      Spring.SetTeamResource(team.id, 'energy', 0)
      if (not team.ready) then
        if (checkAllTeams or TeamHasPlayer(team.id)) then
          allReady = false
        end
      end
    end
  end

  if (allReady) then
    StartGame()
    return
  end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
