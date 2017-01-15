-- $Id: snd_voices.lua 3727 2009-01-08 22:36:55Z licho $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local versionNumber = "1.1.4"

function widget:GetInfo()
	return {
	name      = "Voices",
	desc	  = "[v" .. string.format("%s", versionNumber ) .. "] Unit replies and notifications",
	author    = "quantum",
	date      = "1/7/2007",
	license   = "GNU GPL, v2 or later",
	layer     = -10,
	enabled   = false --  loaded by default?
	}
end

--[[
-- Features:
_ Add many units replies.

---- CHANGELOG -----
-- kingraptor, 	v1.1.2  (23nov2010)	:	COOLDOWNS
-- versus666, 	v1.1.1	(30oct2010)	:	Added and Completed some lists, cleaned other things.
-- licho,		v1.1	(08jan2009):	?
-- quantum,		v1.0				:	Creation.

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
--List the sounds used
--make use or HEAVIES list, ENERGY list, only AALIST & COMMANDERLIST are used.
--]]
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

local mySide	--not used for anything right now
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
local energy = {     --FIXME not used, see line 443 in widget:UnitDestroyed
  "armsolar",
  "armfus", 
  "cafus", 
  "armtide", 
  "armwin",
  "geo",
}
local commanders = {}

local heavies = { --not used yet
	"correap",
	"corgol", --goliath
	"corcan",
	"corsumo",
	"dante",
}

local aa = {
	"corrl", --defender
	"corrazor", --razor kiss
	"missiletower",--hacksaw
	"corflak",
	"armcir", --chainsaw
	"screamer",
}

local sea = { --not used yet
	"corcrus", --executioner
	"corbats", --warlord
	"corarch", --Shredder
	"armroy", --crusader
	"corroy", --enforcer
	"armpt", --skeeter
	"armroy", --crusader
	"coresupp", --supporter
	"shipsubtacmissile", --leviathan
	"armboat", --surboat(sea transporter)
}

local energyList = {} --not used yet
local commanderList = {}
local heaviesList = {} --not used yet
local aaList = {}
local seaList = {} --not used yet

for i,v in pairs (energy) do --not used yet
	energyList[v] = true
end
for i=1, #UnitDefs do
	if UnitDefs[i].customParams.commtype then
		commanderList[UnitDefs[i].name] = true
	end
end
for i,v in pairs (heavies) do --not used yet
	heaviesList[v] = true
end
for i,v in pairs (aa) do
	aaList[v] = true
end
for i,v in pairs (sea) do --not used yet
	seaList[v] = true
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


local function rand(x)
  return floor(random(1,x))
end

local function assignSex(unitID)
  if (random() > 0.5) then
    sexTable[unitID] = 'f'
  else
    sexTable[unitID] = 'm'
  end
  local def = UnitDefs[GetUnitDefID(unitID)]
  local statsName = def.customParams and def.customParams.statsname
  if (statsname == "armcom" or statsname == "commsupport")  then
    sexTable[unitID] = 'f'
  elseif (statsname == "corcom" or statsname == "commrecon")  then
    sexTable[unitID] = 'm' 
  end
end


local function PlaySound(fileName, ...)
  PlaySoundFile(SOUND_DIRNAME.."Voices/" .. fileName, ...)
end


local function Play(category, sex, side)
  local fileExclude
  local fileSearch
  local fileName
  local numFiles
  if not side then side = "arm" end
  if category == "selectcom" then side = "core" end
  if (not sex) then
    fileSearch = category.."_"..side.."_*.wav"
    fileList = VFS.DirList(SOUND_DIRNAME.."Voices/", fileSearch, VFSMODE)
    fileSearch = category.."_"..side.."_*_*.wav"
    fileExclude = VFS.DirList(SOUND_DIRNAME.."Voices/", fileSearch, VFSMODE)
    numFiles = #fileList - #fileExclude
  else
    fileSearch = category.."_"..side.."_"..sex.."_*.wav"
    fileList = VFS.DirList(SOUND_DIRNAME.."Voices/", fileSearch, VFSMODE)
    numFiles = #fileList
  end
  
  if (numFiles > 0) then
    local fileNum = rand(numFiles)
    if (not sex) then
      fileName = category.."_"..side.."_"..fileNum..".wav"
    else
      fileName = category.."_"..side.."_"..sex.."_"..fileNum..".wav"
    end
    local fullName = SOUND_DIRNAME.."Voices/"..fileName
    local exists = VFS.DirList(fullName, fileSearch, VFSMODE)
    if (exists) then
      PlaySound(fileName, 1, 'voice')
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
   
    local name = UnitDefs[unitDefID].name
   
   if ((not UnitDefs[unitDefID].canMove) and
        (UnitDefs[unitDefID].canAttack == 1)) then
      isTurret =true
    end
    
    if ((name == "armfus") or -- fusion
	--(name == "corfus") or (name == "aafus") are not in game anymore.
        (name == "cafus"))then  --adv fusion
      isFus = true
    end

	if seaList[name] then 
      isSea = true
    end
	
    if aaList[name] then --FIXME: more AA
      isSam = true
    end
    
    if commanderList[name] then
      isCom = true
    end
  end
  
  if (isSam) then
    Play("selectsam")
  elseif (isTurret) then
    Play("turret")
  elseif (isFus) then
    Play("selectfus")
  elseif ((isCom) and (GetGameSeconds()) > 2) then
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


local function CoolPlay(category, cooldownTime, sex, side)
  cooldownTime = cooldownTime or 2	--default 2 s cooldown
  local t = GetGameSeconds()
  if ((not cooldown[category]) or
      (t - cooldown[category] > cooldownTime)) then
    Play(category, sex, side)
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
        CoolPlay(category, coolDownTime, sex)
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
  mySide = "arm"
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


function widget:UnitDamaged(unitID, unitDefID, unitTeam, damage)
	if (unitTeam == myTeamID) and damage>1 then
		if (GetUnitHealth(unitID) > 0 ) then
			if (IsStructure(unitID)) then
				CoolPlay("sdamaged", 20)
			elseif (UnitDefs[unitDefID].transportCapacity >= 1) then
				CoolPlay("tdamaged", 10)
			else
				CoolPlay("udamaged", 20)
			end
			if (UnitDefs[unitDefID].customParams.commtype) then
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
		else
			moveState[unitID] = nil
			retreatState[unitID] = nil
			fireState[unitID] = nil
			allyTeam = GetUnitAllyTeam(unitID)
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
end


--[[function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
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
]]--

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
      --Play("paused")
      saidPause = true
    end
    if ((not isPaused) and saidPause) then
      --Play("unpaused")
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
  if (not unitID) then
    return false
  end
  local unitDefID = GetUnitDefID(unitID)

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
		CoolPlay("retreatm", 2)
	elseif (newRetreatOrder == 3) then
		CoolPlay("retreath", 2)
	end
	


  elseif (commandID == CMD.FIRE_STATE) then
    if (fireState[unitID] == 0) then
      fireState[unitID] = 1
    elseif (fireState[unitID] == 1) then
      fireState[unitID] = 2
    else
      fireState[unitID] = 0
      CoolPlay("firehold", 2, sexTable[unitID])
    end


  elseif (commandID == CMD.MOVE_STATE) then
    if (moveState[unitID] == 0) then
      moveState[unitID] = 1
    elseif (moveState[unitID] == 1) then
      moveState[unitID] = 2
      CoolPlay("moveroam", 2)
    else
      moveState[unitID] = 0
      CoolPlay("movehold", 2, sexTable[unitID])
    end

  elseif (commandID == CMD.GUARD)   then
    CoolPlay("guard", 2, sexTable[unitID])
  
  elseif (commandID == CMD.PATROL) then
    CoolPlay("patrol", 2)

  elseif (commandID == CMD.RECLAIM) then
    CoolPlay("reclaim", 2, sexTable[unitID])


  elseif ((commandID == CMD.ATTACK) or
     (commandID == CMD.FIGHT) or
     (commandID == CMD.AREA_ATTACK) or
     (commandID == CMD.MANUALFIRE)) then
    if (UnitDefs[unitDefID].canFly) then
      CoolPlay("attackp", 3, sexTable[unitID])
    else
      CoolPlay("attack", 3,  sexTable[unitID])
    end


  elseif (commandID == CMD.MOVE) then
    if (IsStructure(unitID)) then
      CoolPlay("movef", 3)
    else
      CoolPlay("move", 3, sexTable[unitID])
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


--function widget:UnitEnteredLos(unitID, unitTeam)
--  if ((UnitDefs[unitDefID]) and 
--      (UnitDefs[unitDefID].transportCapacity >= 1)) then
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
