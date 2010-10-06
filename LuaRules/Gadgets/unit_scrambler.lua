-- $Id: unit_scrambler.lua 4345 2009-04-11 10:26:26Z licho $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Scramblers",
    desc      = "Radar scramblers can create fake radar contacts.",
    author    = "quantum",
    date      = "Jul 24, 2007",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = false  --  loaded by default?
  }
end

--[[
Changelog:
	CarRepairer: 
		- Scramble command is no longer a mode but rather issued on the map. Fake blips will be localized to the spot issued.
		- Right clicking when only a scrambler is selected will default to issuing the scramble command.
		- Press stop to make the scrambling stop.
		- Using losmasking instead of cloaking.
		- Graphical indication of scramble area with circles and lines.
		- Fake blips vanish only to players who can see the area.
		- No scrambling until it's fully built

--]]


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Automatically generated local definitions

local CMDTYPE_ICON_MAP	    = CMDTYPE.ICON_MAP
local spCreateUnit          = Spring.CreateUnit
local spDestroyUnit         = Spring.DestroyUnit
local spEditUnitCmdDesc     = Spring.EditUnitCmdDesc
local spFindUnitCmdDesc     = Spring.FindUnitCmdDesc
local spGetAllUnits         = Spring.GetAllUnits
local spGetGroundHeight     = Spring.GetGroundHeight
local spGetLocalAllyTeamID  = Spring.GetLocalAllyTeamID
local spGetSpectatingState  = Spring.GetSpectatingState
local spGetTeamList         = Spring.GetTeamList
local spGetTeamUnitsByDefs  = Spring.GetTeamUnitsByDefs
local spGetUnitAllyTeam     = Spring.GetUnitAllyTeam
local spGetUnitDefID        = Spring.GetUnitDefID
local spGetUnitIsActive     = Spring.GetUnitIsActive
local spGetUnitNearestEnemy = Spring.GetUnitNearestEnemy
local spGetUnitPosition     = Spring.GetUnitPosition
local spGetUnitTeam         = Spring.GetUnitTeam
local spGiveOrderToUnit     = Spring.GiveOrderToUnit
local spInsertUnitCmdDesc   = Spring.InsertUnitCmdDesc
local spIsUnitAllied        = Spring.IsUnitAllied
local spRemoveUnitCmdDesc   = Spring.RemoveUnitCmdDesc
local spSetUnitBlocking     = Spring.SetUnitBlocking
local spSetUnitCloak        = Spring.SetUnitCloak
local spSetUnitNoMinimap    = Spring.SetUnitNoMinimap
local spSetUnitNoSelect     = Spring.SetUnitNoSelect
local spSetUnitNoDraw       = Spring.SetUnitNoDraw

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local Spring = Spring
local UnitDefs = UnitDefs

local SYNCSTR1 = 'scramble_unit'
local SYNCSTR2 = 'scramble_unit2'

local fakeDefID = UnitDefNames['fakeunit'].id

local scrambleRadius = 200
local atan2 	= math.atan2
local cos 		= math.cos
local sin 		= math.sin
local random	= math.random

--  Proposed Command ID Ranges:
--
--    all negative:  Engine (build commands)
--       0 -   999:  Engine
--    1000 -  9999:  Group AI
--   10000 - 19999:  LuaUI
--   20000 - 29999:  LuaCob
--   30000 - 39999:  LuaRules
--

local CMD_SCRAMBLE = 35128


local scramblerNameList = {
--  "armjamt",
"armjamt",
--"corshroud",
}
--------------------------------------------------------------------------------
--  COMMON
--------------------------------------------------------------------------------
if (gadgetHandler:IsSyncedCode()) then
--------------------------------------------------------------------------------
--  SYNCED
--------------------------------------------------------------------------------

local spUseUnitResource 	= Spring.UseUnitResource
local spGetAllyTeamList		= Spring.GetAllyTeamList
local spSetUnitLosState		= Spring.SetUnitLosState
local spSetUnitLosMask		= Spring.SetUnitLosMask
--local spGetUnitLosState		= Spring.GetUnitLosState
local spIsPosInLos			= Spring.IsPosInLos
local spGetTeamInfo			= Spring.GetTeamInfo
local CMD_STOP				= CMD.STOP

local scramblerIDSet = {}
for _, unitName in ipairs(scramblerNameList) do
  local unitDefID = UnitDefNames[unitName].id
  scramblerIDSet[unitDefID] = true
end


local scramblerUnitSet = {}
local scramblerKillMe = {}

local fakeContacts = 10
local scrambleHeight = 0
local jamDist = 900
local jamDistSqr = jamDist*jamDist

local gaiaAlliance, gaiaTeam

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------



local scrambleCmdDesc = {
  id      = CMD_SCRAMBLE,
  type    = CMDTYPE_ICON_MAP,
  name    = 'Scramble',
  cursor  = 'Attack',
  action  = 'scramble',
  tooltip = 'Make fake radar dots.',
  params  = {0,0,0},
}


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function AddScrambleCmdDesc(unitID)
  local insertID = 1
  spInsertUnitCmdDesc(unitID, insertID + 1, scrambleCmdDesc)
end


local function AddScrambleUnit(unitID)
  AddScrambleCmdDesc(unitID)
  scramblerUnitSet[unitID] = {}
end


local function ScrambleCommand(unitID, cmdParams)
  if (type(cmdParams[1]) ~= 'number') then
    return false
  end
  
  local px, py, pz = cmdParams[1], cmdParams[2], cmdParams[3]
  local ux, uy, uz = spGetUnitPosition(unitID)
  if (ux-px)*(ux-px) + (uz-pz)*(uz-pz) > jamDistSqr then
	local angle = atan2(pz-uz, px-ux)
	px = ux + jamDist * cos(angle)
	pz = uz + jamDist * sin(angle)
  end
  scramblerUnitSet[unitID].pos = {px, py, pz}
  scramblerUnitSet[unitID].deadContacts = 0
  scramblerUnitSet[unitID].enabling = true
  SendToUnsynced(SYNCSTR2, unitID, px, pz)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function AddContact(unitID, unitTeam, sx, sy, sz)
	if (not unitTeam) then
		unitTeam = spGetUnitTeam(unitID)
	end
	if (not sx) then
		sx, sy, sz = spGetUnitPosition(unitID)
	end
	
	local x = random(-scrambleRadius*0.5, scrambleRadius*0.5) + sx
	local z = random(-scrambleRadius*0.5, scrambleRadius*0.5) + sz
	local y = spGetGroundHeight(x, z)
	local contactID = spCreateUnit("fakeunit", x, y, z, "n", unitTeam)
	local MC = Spring.MoveCtrl
	MC.Enable(contactID)
	MC.SetPosition(contactID, x, y+5, z)

	local allyTeamList = spGetAllyTeamList()
	local _,_,_,_,_,unitAllyTeam = spGetTeamInfo(unitTeam)
	for _,allyID in ipairs (allyTeamList) do
		if allyID ~= unitAllyTeam and allyID ~= gaiaAlliance then
			spSetUnitLosMask(contactID, allyID, {los=true, prevLos=true, contRadar=true } )
			spSetUnitLosState(contactID, allyID, {los=false, prevLos=false, contRadar=false } )
			if spIsPosInLos(x,y,z, allyID) then
				spSetUnitLosMask(contactID, allyID, {radar=true } )
				spSetUnitLosState(contactID, allyID, {radar=false } )
			end
		end
	end
  
	spSetUnitNoSelect(contactID, true)
	spSetUnitBlocking(contactID, false)
	scramblerUnitSet[unitID].contacts[contactID] = {x,y,z}
	SendToUnsynced(SYNCSTR1, contactID)
end


local function RemoveContacts(unitID)
  local contacts = scramblerUnitSet[unitID].contacts
  if (contacts) then
    for contactID in pairs(contacts) do
      spDestroyUnit(contactID, false, true)
    end
  end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


function gadget:Initialize()
	gaiaTeam = Spring.GetGaiaTeamID()
	_,_,_,_,_, gaiaAlliance = spGetTeamInfo(gaiaTeam)
	
  gadgetHandler:RegisterCMDID(CMD_SCRAMBLE)
  local allUnits = spGetAllUnits()
  for _, unitID in ipairs(allUnits) do
    local unitDefID = spGetUnitDefID(unitID)
    if (scramblerIDSet[unitDefID]) then
      AddScrambleUnit(unitID)
    end
    if (unitDefID == fakeDefID) then
      spDestroyUnit(unitID, false, true)
    end
  end
end


function gadget:UnitFinished(unitID, unitDefID)
  if (scramblerIDSet[unitDefID]) then
    AddScrambleUnit(unitID)
  end
end


function gadget:UnitDestroyed(unitID, unitDefID)
  if (scramblerUnitSet[unitID]) then
    scramblerKillMe[unitID]  = true
    return
  end
  for scramblerID, status in pairs(scramblerUnitSet) do
    local contacts = status.contacts
    if (contacts) then
      for contactID in pairs(contacts) do
        if (contactID == unitID) then
          contacts[contactID] = nil
        end
      end
    end
  end
end


function gadget:GameFrame(n)
	for unitID,_ in pairs(scramblerKillMe) do
		RemoveContacts(unitID)
		scramblerUnitSet[unitID] = nil
		SendToUnsynced(SYNCSTR2, unitID, false)
	end
	scramblerKillMe = {}

	if ((n+2) % 35 > 0) then
		return
	end
	for unitID, status in pairs(scramblerUnitSet) do
		if (status.disabling or status.enabling) and status.enabled  then
			RemoveContacts(unitID)
			status.enabled = nil
			status.disabling = nil
			status.contacts = {}
		elseif (status.enabling) then
			local sx, sy, sz = status.pos[1], status.pos[2], status.pos[3]
			local unitTeam = spGetUnitTeam(unitID)
			status.contacts = {}
			for i=1, fakeContacts do
				local contactID = AddContact(unitID, unitTeam, sx, sy, sz)
			end
			status.enabling = nil
			status.enabled = true
		end

		if status.enabled  then 
			spUseUnitResource(unitID, 'e', 4)
		end

		if (status.contacts) then
			for contactID,pos in pairs(status.contacts) do
				local sx, sy, sz = pos[1], pos[2], pos[3]
				local allyTeamList = spGetAllyTeamList()
				for _,allyID in ipairs(allyTeamList) do
					if allyID ~= gaiaAlliance then
						if spIsPosInLos(sx,sy,sz, allyID) then
							spSetUnitLosMask(contactID, allyID, {radar=true} )
							spSetUnitLosState(contactID, allyID, {radar=false} )
						else
							spSetUnitLosMask(contactID, allyID, {radar=false} )
						end
					end
				end
			end
		end
	end
end
      
      
function gadget:Shutdown()
  if (scramblerUnitSet[unitName]) then
    local cmdDescID = spFindUnitCmdDesc(unitID, CMD_SCRAMBLE)
    if (cmdDescID) then
      spRemoveUnitCmdDesc(unitID, cmdDescID)
    end
  end
  for _,teamID in ipairs(spGetTeamList()) do
    for _,unitID in ipairs(spGetTeamUnitsByDefs(teamID, fakeDefID)) do
      spDestroyUnit(unitID, false, true)          
    end
  end
end
      
      
function gadget:AllowCommand(unitID, unitDefID, teamID,
                             cmdID, cmdParams, cmdOptions)
	
  if (cmdID == CMD_SCRAMBLE)and(scramblerIDSet[unitDefID]) then
    ScrambleCommand(unitID, cmdParams)
    return false  -- command was used
  elseif (cmdID == CMD_STOP)and(scramblerIDSet[unitDefID]) then
	scramblerUnitSet[unitID].disabling = true
	SendToUnsynced(SYNCSTR2, unitID, false)
  end
  return true  -- command was not used
end


--------------------------------------------------------------------------------
--  SYNCED
--------------------------------------------------------------------------------
else
--------------------------------------------------------------------------------
--  UNSYNCED
--------------------------------------------------------------------------------

local spGetGameFrame		= Spring.GetGameFrame
local spGetSelectedUnits 	= Spring.GetSelectedUnits

local glDrawGroundCircle	= gl.DrawGroundCircle
local glLineWidth			= gl.LineWidth
local glColor				= gl.Color
local glBeginEnd			= gl.BeginEnd
local glVertex				= gl.Vertex
local glDepthTest			= gl.DepthTest
local GL_LINE_STRIP			= GL.LINE_STRIP
local GL_LINES				= GL.LINES

local abs					= math.abs
local sqrt					= math.sqrt
local scramblerspots = {}
local counter = 1
local modu = 200
local halfmodu = modu / 2
local scramblerDefIDs = {}

if (spSetUnitNoMinimap == nil) then
  return false
end

--------------------------------------------------------------------------------

local myAllyTeam = spGetLocalAllyTeamID()

local fullSpec

local _,fv,_ = spGetSpectatingState()
local fullSpec = fv



--------------------------------------------------------------------------------

local function AddContact(cmd, unitID)
  if (type(unitID) ~= 'number') then
    return
  end
  if fullSpec or (myAllyTeam == spGetUnitAllyTeam(unitID)) then
    --spSetUnitNoDraw(unitID, true)
    spSetUnitNoMinimap(unitID, true)
  end
end

local function Scramble(cmd, unitID, x,z)
  if (type(unitID) ~= 'number') then
    return
  end
  
  if fullSpec or (myAllyTeam == spGetUnitAllyTeam(unitID)) then
	if x then
		local y = spGetGroundHeight(x, z)
		local ux,uy,uz = spGetUnitPosition(unitID)
		
	    scramblerspots[unitID] = {
			sx = x,
			sy = y,
			sz = z,
			ux = ux,
			uy = uy,
			uz = uz,
			dist = sqrt((ux-x)*(ux-x) + (uz-z)*(uz-z))
			}
	else
		scramblerspots[unitID] = nil
	end
  end
end
function drawV(x1,y1,z1,  x2,y2,z2, x3,y3,z3)
	glVertex( x1,y1,z1 )
	glVertex( x2,y2,z2 )
	
	glVertex( x2,y2,z2 )
	glVertex( x3,y3,z3 )
end

function drawScramble(rad1, rad2)
	for unitID, data in pairs(scramblerspots) do
		local px,py,pz = data.sx, data.sy, data.sz
		local ux,uy,uz = data.ux, data.uy, data.uz
		
		local angle = atan2(pz-uz, px-ux)
		local scramDist = data.dist
		local hypA = sqrt(scramDist*scramDist + rad1*rad1)
		local hypB = sqrt(scramDist*scramDist + rad2*rad2)
		
		local angleA = atan2(rad1, scramDist)
		local lx1a = ux + hypA * cos(angle + angleA)
		local lz1a = uz + hypA * sin(angle + angleA)
		local ly1a = spGetGroundHeight(lx1a, lz1a)+5
		local lx2a = ux + hypA * cos(angle - angleA)
		local lz2a = uz + hypA * sin(angle - angleA)
		local ly2a = spGetGroundHeight(lx1a, lz1a)+5
		
		local angleB = atan2(rad2, scramDist)
		local lx1b = ux + hypB * cos(angle + angleB)
		local lz1b = uz + hypB * sin(angle + angleB)
		local ly1b = spGetGroundHeight(lx1a, lz1a)+5
		local lx2b = ux + hypB * cos(angle - angleB)
		local lz2b = uz + hypB * sin(angle - angleB)
		local ly2b = spGetGroundHeight(lx1a, lz1a)+5
		
		drawV(lx1a,ly1a,lz1a,  ux,uy,uz,  lx2a,ly2a,lz2a)
		drawV(lx1b,ly1b,lz1b, ux,uy,uz, lx2b,ly2b,lz2b)
	end
	
end

function gadget:Initialize()
  gadgetHandler:AddSyncAction(SYNCSTR1, AddContact)
  gadgetHandler:AddSyncAction(SYNCSTR2, Scramble)
  
  for _, unitName in ipairs(scramblerNameList) do
	local unitDefID = UnitDefNames[unitName].id
	scramblerDefIDs[unitDefID] = true
  end
end


function gadget:Shutdown(unitID)
  gadgetHandler:RemoveSyncAction(SYNCSTR1) 
  gadgetHandler:RemoveSyncAction(SYNCSTR2) 
end


-- Someone should add a PlayerTeamChange() call-in   ;-)
function gadget:Update()
  local newAllyTeam = spGetLocalAllyTeamID()
  local _,newFullSpec,_ = spGetSpectatingState()

  if ((newAllyTeam == myAllyTeam) and (newFullSpec == fullSpec)) then
    return
  end

  fullSpec = newFullSpec
  myAllyTeam = newAllyTeam

  for _,teamID in ipairs(spGetTeamList()) do
    for _,unitID in ipairs(spGetTeamUnitsByDefs(teamID, fakeDefID)) do
      local noMM = fullSpec or (spGetUnitAllyTeam(unitID) == myAllyTeam)
      --spSetUnitNoDraw(unitID, noMM)     
      spSetUnitNoMinimap(unitID, noMM)          
    end
  end
end

function gadget:DrawWorld()
	counter = (counter + 1) % modu
	local pulse = abs(counter - halfmodu) / halfmodu	
		
	glLineWidth(2)
	glColor(1, 0, 0, 0.3)
	glDepthTest(true)

	local rad1 = scrambleRadius*pulse
	local rad2 = scrambleRadius - rad1
	glBeginEnd(GL_LINES, drawScramble, rad1, rad2)
	for unitID, data in pairs(scramblerspots) do
		local px,py,pz = data.sx, data.sy, data.sz
		glDrawGroundCircle(px,0,pz, rad1, 32)
		glDrawGroundCircle(px,0,pz, rad2, 32)
	end
	
	glDepthTest(false)
	glLineWidth(1)
	glColor(1,1,1,1)
end

function gadget:DefaultCommand(type,id)
	local selUnits = spGetSelectedUnits()
	local unitID    = selUnits[1]
    if unitID then
		local unitDefID = spGetUnitDefID(unitID)
		if scramblerDefIDs[unitDefID] then
			return CMD_SCRAMBLE
		end
	end
end


--------------------------------------------------------------------------------
--  UNSYNCED
--------------------------------------------------------------------------------
end
--------------------------------------------------------------------------------
--  COMMON
--------------------------------------------------------------------------------
