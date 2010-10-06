-- $Id: snd_voices.lua 3727 2009-01-08 22:36:55Z licho $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


function widget:GetInfo()
  return {
    name      = "Voices",
    desc      = "Unit replies and notifications",
    author    = "quantum",
    date      = "1/7/2007",
    license   = "GNU GPL, v2 or later",
    layer     = -10,
    enabled   = true --  loaded by default?
  }
end

--TODO:
--unit retreating
--can't reach destination
--chat    'TextCommand'
--captured
--lose
--player exit
--resources/units transferred
--upgrades
--comkill?
--playerdied
--selectsensor
--move plane

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--Speed-ups

local GetTeamUnits     = Spring.GetTeamUnits
local GetTeamUnitStats = Spring.GetTeamUnitStats
local GetSelectedUnits = Spring.GetSelectedUnits
local GetUnitDefID     = Spring.GetUnitDefID
local GetGameSeconds   = Spring.GetGameSeconds
local GetUnitTeam      = Spring.GetUnitTeam
local GetTeamResources = Spring.GetTeamResources
local GetUnitAllyTeam  = Spring.GetUnitAllyTeam
local GetGameSpeed     = Spring.GetGameSpeed
local GetUnitHealth    = Spring.GetUnitHealth
local PlaySoundFile    = Spring.PlaySoundFile
local insert           = table.insert
local random           = math.random
local floor            = math.floor
local VSF              = VSF


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


local SOUND_DIRNAME    = LUAUI_DIRNAME .. 'Sounds/'
local NOISE_SOUND_DIRNAME = 'Sounds/'
local VFSMODE          = VFS.ZIP_FIRST
local CMD_RETREAT      = 10000

local mySide
local myTeamID
local myAllyTeamID
local saidPaused
local saidStarts
--local playProductionS
--local lastComplete     = 0
local counter          = 0
local cooldownList     = {}
local selectBuffer     = {}
local cooldown         = {}
local radarList        = {}
local moveState        = {}
local retreatState     = {}
local fireState        = {}
local sexTable         = {}
local statsBuffer      = {0, 0, 0, 0, 0}
local energyList = {     --FIXME
  "corsolar",
  "armsolar",
  "corfus",
  "armfus", 
  "aafus", 
  "cafus", 
  "cortide", 
  "armtide", 
  "corwin",
  "armwin"
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


local function rand(x)
  return floor(random(1,x))
end

local function assignSex(unitID)
  if (random() > 0.3) then
    sexTable[unitID] = 'f'
  else
    sexTable[unitID] = 'm'
  end
  if (UnitDefNames['armcom'].id == GetUnitDefID(unitID)) then
    sexTable[unitID] = 'f'     
  end
end


local function PlaySound(fileName, ...)
  PlaySoundFile(SOUND_DIRNAME.."Voices/" .. fileName, ...)
end


local function Play(category, sex)
  local fileExclude
  local fileSearch
  local fileName
  local numFiles
  if (mySide == "core") then
    sex = nil
  end
  if (not sex) then
    fileSearch = category.."_"..mySide.."_*.wav"
    fileList = VFS.DirList(SOUND_DIRNAME.."Voices/", fileSearch, VFSMODE)
    fileSearch = category.."_"..mySide.."_*_*.wav"
    fileExclude = VFS.DirList(SOUND_DIRNAME.."Voices/", fileSearch, VFSMODE)
    numFiles = #fileList - #fileExclude
  else
    fileSearch = category.."_"..mySide.."_"..sex.."_*.wav"
    fileList = VFS.DirList(SOUND_DIRNAME.."Voices/", fileSearch, VFSMODE)
    numFiles = #fileList
  end
  
  if (numFiles > 0) then
    local fileNum = rand(numFiles)
    if (not sex) then
      fileName = category.."_"..mySide.."_"..fileNum..".wav"
    else
      fileName = category.."_"..mySide.."_"..sex.."_"..fileNum..".wav"
    end
    local fullName = SOUND_DIRNAME.."Voices/"..fileName
    local exists = VFS.DirList(fullName, fileSearch, VFSMODE)
    if (exists) then
      PlaySound(fileName)
    end
  end
end


local function CheckSelected()
  local unitTable     = GetSelectedUnits()
  local isTurret      = false
  local isFus         = false
  local isSam         = false
  local isCom         = false
  
  for _, unitID in ipairs(unitTable) do
    local unitDefID = GetUnitDefID(unitID)
   
   if ((not UnitDefs[unitDefID].canMove) and
        (UnitDefs[unitDefID].canAttack == 1)) then
      isTurret =true
    end
    
    if ((UnitDefs[unitDefID].name == "corfus") or
        (UnitDefs[unitDefID].name == "armfus") or
        (UnitDefs[unitDefID].name == "cafus") or
        (UnitDefs[unitDefID].name == "aafus")) then --FIXME: sea & cloak
      isFus = true
    end
    
    if ((UnitDefs[unitDefID].name == "corrl") or
        (UnitDefs[unitDefID].name == "armrl")) then --FIXME: more AA
      isSam = true
    end
    
    if (((UnitDefs[unitDefID].name == "armcom") or
        (UnitDefs[unitDefID].name == "corcom")) and
        (GetGameSeconds() > 3)) then
      isCom = true
    end
  end
  
  if (isTurret) then
    Play("turret")
  elseif (isFus) then
    Play("selectfus")
  elseif (isSam) then
    Play("selectsam")
  elseif ((isCom) and
          (GetGameSeconds()) > 2) then
    Play("selectcom")
  elseif (#unitTable > 1) then
    Play("selectgroup")
  else
    Play("select", sexTable[unitTable[1]])
  end 
end


local function IsStructure(unitID)
  local unitDefID = GetUnitDefID(unitID)
  if (UnitDefs[unitDefID].isMetalExtractor or
      UnitDefs[unitDefID].isBuilding or
      UnitDefs[unitDefID].isFactory) then
    return true
  end
end


local function CoolPlay(category, cooldownTime, sex)
  cooldownTime = cooldownTime or 0
  local t = GetGameSeconds()
  if ((not cooldown[category]) or
      (t - cooldown[category] > cooldownTime)) then
    Play(category, sex)
    cooldown[category] = t
  end
end


local function playNoiseSound(filename, ...)
  local path = NOISE_SOUND_DIRNAME..filename..".WAV"
  if (VFS.FileExists(path)) then
    Spring.PlaySoundFile(path, ...)
  else
    print("Error: file "..path.." doest not exist.")
  end
end


local function CoolNoisePlay(category, cooldownTime) 
  cooldownTime = cooldownTime or 0
  local t = GetGameSeconds()
  if ((not cooldown[category]) or
      (t - cooldown[category] > cooldownTime)) then
    playNoiseSound(category)
    cooldown[category] = t
  end

end


-- local function DelayPlay()
  -- t = Spring.GetGameSeconds()
  -- if ((lastComplete > t + 2) and
      -- (playProductionS))  then
    -- Play("constructions")
    -- playProductionS = nil
  -- end
-- end


local function UnitPlay(category, sex, unitID, coolDownTime)
  local selectedUnits = GetSelectedUnits()
  for _, selectedUnit in ipairs(selectedUnits) do
    if (unitID == selectedUnit) then
      if (coolDownTime) then
        CoolPlay(category, cooDownTime, sex)
      else
        Play(category, sex)
      end
    end
  end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


function widget:Initialize()
  local _, _, spec, team = Spring.GetPlayerInfo(Spring.GetMyPlayerID()) 
  myTeamID = team
  myAllyTeamID = Spring.GetMyAllyTeamID()
  local _, _, _, _, side = Spring.GetTeamInfo(myTeamID)
  mySide = side
  if (side == "random") then
    mySide = "arm"
  end
  Play("initialized")
  for _, unitID in ipairs(GetTeamUnits(myTeamID)) do
    assignSex(unitID)
  end
  WG.voices = true

	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = GetUnitDefID(unitID)
		widget:UnitCreated(unitID, unitDefID, myTeamID)
	end
end


function widget:UnitCreated(unitID, unitDefID, unitTeam)
  local name = UnitDefs[unitDefID].name
  if (name == "corcom" and unitTeam == myTeamID) then
    mySide = "core"
  end
  if (UnitDefs[unitDefID].canMove) then
    moveState[unitID] = 1
    retreatState[unitID] = 0
    fireState[unitID] = 2
  end
  -- if ((unitTeam == myTeamID) and
      -- (GetGameSeconds() > 2)) then
    -- if (IsStructure(unitID)) then
      -- Play("constructions")
    -- else
      -- playProductionS = 1
    -- end
  -- end
  assignSex(unitID)
end


-- function widget:UnitFinished(unitID, unitDefID, unitTeam)
  -- local t = GetGameSeconds()
  -- if (unitTeam == myTeamID) then
    -- if (IsStructure(unitID)) then
      -- if ((UnitDefs[UnitDefID]) and
          -- (UnitDefs[UnitDedID].canAttack == 1)) then
        -- Play("constructiontc")  --FIXME
      -- else
        -- Play("constructionc")
      -- end
    -- else
      -- Play("productionc")
      -- lastComplete = t
    -- end
  -- end
-- end


function widget:UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
  if (oldTeam == myTeamID) then
    CoolPlay("unitsgiven", 1)
  end
end


function widget:UnitDamaged(unitID, unitDefID, unitTeam)
  if (unitTeam == myTeamID) then
    if (IsStructure(unitID)) then
      CoolPlay("sdamaged", 20)
    elseif (UnitDefs[unitDefID].isTransport) then
      CoolPlay("tdamaged", 10)
    else
      CoolPlay("udamaged", 20)
    end
    
    if (UnitDefs[unitDefID].isCommander) then
      health, maxHealth = GetUnitHealth(unitID)
      if health/maxHealth < 0.5 then
        CoolNoisePlay("warning2", 2)
      else
        CoolNoisePlay("warning1", 2)
      end
      if health/maxHealth < 0.2 then
        CoolPlay("comdying",1)
      end
    end
  end
end


function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
  moveState[unitID] = nil
  retreatState[unitID] = nil
  fireState[unitID] = nil
  allyTeam = GetUnitAllyTeam(unitID)
  if (allyTeam == myAllyTeamID) then
    UnitPlay("destroyedu", sexTable[unitID], unitID, 20)
    -- for _, energyName in ipairs(energyList) do
      -- if (energyName == UnitDefs[unitDefID].name) then
        --CoolPlay("edestroyed", 0)
      -- end
    -- end
    -- if ((UnitDefs[UnitDefID].name == "corcom") or
        -- (UnitDefs[UnitDefID].name == "armcom")) then
      -- Play("comkill")
    -- end
  end
end


function widget:Update(dt)

  local selectedUnits = GetSelectedUnits()
  local notEqual = false
  for i, unitID in ipairs(selectedUnits) do
    if (selectBuffer[i] ~= selectedUnits[i]) then
      notEqual = true
    end
  end
  if (notEqual) then
    CheckSelected()
  end
  selectBuffer = selectedUnits
  counter = counter+dt

  if (counter > 1) then
    counter = 0
    t = GetGameSeconds()
    if (t > 0) then
      if (not saidStarts) then
        Play("gamestarts")
        saidStarts = true
      end

      local eCur, eMax, ePull, eInc, _, _, _, eRec = GetTeamResources(myTeamID, "energy")
      eCur  = eCur or 1000
      eMax  = eMax or 0
      ePull = ePull or 0
      eInc  = eInc or 0
      local e = eCur + eInc - ePull 
      if (e and (e < 1)) then
        CoolPlay("energylow", 15)
      end
    end
    
    local _, _, isPaused = GetGameSpeed()  
    if (isPaused and (not saidPause)) then
      Play("paused")
      saidPause = true
    end
    if ((not isPaused) and saidPause) then
      Play("unpaused")
      saidPause = nil
    end
    

    if (GetGameSeconds() > 0) then
      local killed, died, captured, _, recieved, sent = GetTeamUnitStats(myTeamID)
      if killed and (killed > statsBuffer[1]) then
        if (random() > 0.5) then
          CoolPlay("kill",20,"f")
        else
          CoolPlay("kill",20,"m")
        end
      end
      if captured and(captured > statsBuffer[3]) then
        Play("capturedu")
      end
      if ((recieved and (recieved > statsBuffer[4])) or
          (sent and (sent > statsBuffer[5])))then
        CoolPlay("unitsgiven", 1)
      end
      statsBuffer[1] = killed   or 0
      statsBuffer[2] = died     or 0
      statsBuffer[3] = captured or 0
      statsBuffer[4] = recieved or 0
      statsBuffer[5] = sent     or 0
    end
    
    --DelayPlay()
  end
end


function widget:CommandNotify(commandID, params ,options)
  --PlaySound(LUAUI_DIRNAME.."Voices/", "left.wav")
  local unitID = GetSelectedUnits()[1]
  local unitDefID = GetUnitDefID(unitID)
  if (not unitID) then
    return false
  end

  if (commandID == CMD_RETREAT) then
	local newRetreatOrder = 0
	local foundValidUnit = false
	local selectedUnits = GetSelectedUnits()
	for _, unitID in ipairs(selectedUnits) do
	
		if UnitDefs[unitDefID].canMove then --Check canmove for mixed selections

			if not foundValidUnit then
				foundValidUnit = true
				if not options.right then
					newRetreatOrder = retreatState[unitID] % 3 + 1
				end
			end
				
			retreatState[unitID] = newRetreatOrder
		end --if canmove
	end --for
	if (newRetreatOrder == 2) then
		Play("retreatm")
	elseif (newRetreatOrder == 3) then
		Play("retreath")
	end
	


  elseif (commandID == CMD.FIRE_STATE) then
    if (fireState[unitID] == 0) then
      fireState[unitID] = 1
    elseif (fireState[unitID] == 1) then
      fireState[unitID] = 2
    else
      fireState[unitID] = 0
      Play("firehold", sexTable[unitID])
    end


  elseif (commandID == CMD.MOVE_STATE) then
    if (moveState[unitID] == 0) then
      moveState[unitID] = 1
    elseif (moveState[unitID] == 1) then
      moveState[unitID] = 2
      Play("moveroam")
    else
      moveState[unitID] = 0
      Play("movehold", sexTable[unitID])
    end

  elseif (commandID == CMD.GUARD)   then
    Play("guard", sexTable[unitID])
  
  elseif (commandID == CMD.PATROL) then
    Play("patrol")

  elseif (commandID == CMD.RECLAIM) then
    Play("reclaim", sexTable[unitID])


  elseif ((commandID == CMD.ATTACK) or
     (commandID == CMD.FIGHT) or
     (commandID == CMD.AREA_ATTACK) or
     (commandID == CMD.DGUN)) then
    if (UnitDefs[unitDefID].canFly) then
      Play("attackp", sexTable[unitID])
    else
      Play("attack", sexTable[unitID])
    end


  elseif (commandID == CMD.MOVE) then
    if (IsStructure(unitID)) then
      Play("movef")
    else
      Play("move", sexTable[unitID])
    end
  end
  return false
end


--function widget:UnitEnteredRadar(unitID, unitTeam)
--  CoolPlay("detected",2)
--  radarList[unitID] = true
--end


--function widget:UnitLeftRadar(unitID, unitTeam)
--  if radarList[unitID] then
--    radarList[unitID] = nil
--  end
--end


--function widget:UnitEnteredLos(unitID, unitDefID, unitTeam)
--  if ((UnitDefs[unitDefID]) and 
--      (UnitDefs[unitDefID].isTransport)) then
--    Play("detectedt")
--  elseif (not radarList[unitID]) then
--    Play("detected")
--  end
--end


function widget:Shutdown()
  WG.voices = nil
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
