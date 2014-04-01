--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local version = "0.1.1" -- this now has it's own changelog

function widget:GetInfo()
  return {
    name      = "pAI",
    desc      = "Personal Artificial Intelligence assistant. Use for your own risk. Version "..version,
    author    = "Tom Fyuri",
    date      = "Mar 2014",
    license   = "GPL v2 or later",
    layer     = 4,
    enabled   = false,	-- i will re-enable this once it's player more friendly
    handler   = true,	-- geh
  }
end

-- changelog
-- 30 march 2014 - 0.1.0. First release.
-- 31 march 2014 - 0.1.1. Nothing new imporant...

-- TODO, this I want to implement:
-- Energy logic: <- right now it has idiot logic but kinda works, lel, also has no idea about geo spots yet
-- pAI should have energy lines always layed out in some form always, and order immediate additional E structures to be constructed at/near those lines should it be appropriate.
-- Wise retreat:
-- Gather all enemy weapon ranges, if AI controlled unit is near any of weapon ranges it should fall back a bit and area should be marker as dangerous, any ghost jobs should be suspended unless permited by user.
-- Global construction menu:
-- Actually because of this I started coding this widget, I want a way to design my defenses/grid layout myself sometimes, but before the match starts.
-- So pAI will just build/rebuild it and I can keep my eyes focuses on battlefield at hand. Also once basic design is completed pAI should have freewill to spend any excess probabilities into more overdriving.

-- What can it do now?
-- It can retreat once hurt. Repair/reclaim/assist stuff. Claim gaia oremexes (oremex gamemode). And tries to construct solars/winds near mexes, albeit only 1 yet.

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local spValidUnitID		= Spring.ValidUnitID
local spGetUnitDefID	  	= Spring.GetUnitDefID
local spFindUnitCmdDesc		= Spring.FindUnitCmdDesc
local spEditUnitCmdDesc		= Spring.EditUnitCmdDesc
local spGetMyTeamID         	= Spring.GetMyTeamID
local spGetTeamResources    	= Spring.GetTeamResources
local spGetSpectatingState	= Spring.GetSpectatingState
local spGetUnitTeam		= Spring.GetUnitTeam
local spGetUnitsInCylinder	= Spring.GetUnitsInCylinder
local spGetUnitPosition 	= Spring.GetUnitPosition
local spIsUnitAllied		= Spring.IsUnitAllied
local spGiveOrderToUnit   	= Spring.GiveOrderToUnit
local spGetSelectedUnits	= Spring.GetSelectedUnits
local spGetFeaturesInRectangle	= Spring.GetFeaturesInRectangle
local spGetFeatureDefID		= Spring.GetFeatureDefID
local spGetUnitHealth		= Spring.GetUnitHealth
local spGetCommandQueue 	= Spring.GetCommandQueue
local spGetGameFrame		= Spring.GetGameFrame
local spTestBuildOrder		= Spring.TestBuildOrder
local spGetUnitDirection	= Spring.GetUnitDirection
local spGetGroundHeight    	= Spring.GetGroundHeight
local spGetMyPlayerID     	= Spring.GetMyPlayerID
local spIsAABBInView		= Spring.IsAABBInView
local spGetFactoryCommands	= Spring.GetFactoryCommands
local spGetTeamInfo		= Spring.GetTeamInfo
local spGetUnitDefDimensions	= Spring.GetUnitDefDimensions
local spGetPositionLosState	= Spring.GetPositionLosState
local spGetMyAllyTeamID		= Spring.GetMyAllyTeamID
local spGetAllyTeamStartBox	= Spring.GetAllyTeamStartBox
local spGetTeamUnits 	  	= Spring.GetTeamUnits
local spGetAllUnits 	  	= Spring.GetAllUnits
local spIsUnitInView 		= Spring.IsUnitInView
local GaiaTeamID		= Spring.GetGaiaTeamID()
local spGetUnitsInRectangle	= Spring.GetUnitsInRectangle
local spGetUnitViewPosition 	= Spring.GetUnitViewPosition
local spGetTeamList         	= Spring.GetTeamList
local spGetFeatureResources	= Spring.GetFeatureResources
local spGetFeaturePosition	= Spring.GetFeaturePosition
local spValidUnitID		= Spring.ValidUnitID
local spValidFeatureID		= Spring.ValidFeatureID
local spGiveOrderArrayToUnitArray	= Spring.GiveOrderArrayToUnitArray

local getMovetype 		= Spring.Utilities.getMovetype
VFS.Include("LuaRules/Configs/CAI/accessory/targetReachableTester.lua")
local CopyTable			= Spring.Utilities.CopyTable

local mapWidth
local mapHeight

local glPushMatrix	= gl.PushMatrix
local glPopMatrix	= gl.PopMatrix
local glTranslate	= gl.Translate
local glBillboard	= gl.Billboard
local glColor		= gl.Color
local glText		= gl.Text
local glBeginEnd	= gl.BeginEnd
local GL_LINE_STRIP	= GL.LINE_STRIP
local glDepthTest	= gl.DepthTest
local glRotate		= gl.Rotate
local glUnitShape	= gl.UnitShape
local glVertex		= gl.Vertex
local glDrawGroundCircle= gl.DrawGroundCircle
local glLineWidth	= gl.LineWidth
local glAlphaTest	= gl.AlphaTest
local GL_GREATER	= GL.GREATER
local glTexture		= gl.Texture
local glTexRect		= gl.TexRect

local modOptions = Spring.GetModOptions()
local waterLevel = modOptions.waterlevel and tonumber(modOptions.waterlevel) or 0
local oremex = modOptions.oremex and (tonumber(modOptions.oremex) == 1) or false
local oremex_overdrive = modOptions.oremex_overdrive and (tonumber(modOptions.oremex_overdrive) == 1) or true
local oremex_prespawn = modOptions.oremex_prespawn and (tonumber(modOptions.oremex_prespawn) == 1) or true

local MexDefs = {
	[UnitDefNames["cormex"].id] = true,
}
local EnergyDefs = { -- importance (higher better), pylon range.
	[UnitDefNames["armestor"].id] = { 3, UnitDefNames["armestor"].customParams.pylonrange }, -- pylon
	[UnitDefNames["armwin"].id] = { 4, UnitDefNames["armwin"].customParams.pylonrange }, -- wind
	[UnitDefNames["armsolar"].id] = { 4, UnitDefNames["armsolar"].customParams.pylonrange }, -- solar
	[UnitDefNames["armfus"].id] = { 1, UnitDefNames["armfus"].customParams.pylonrange }, -- fusion
	[UnitDefNames["cafus"].id] = { 1, UnitDefNames["cafus"].customParams.pylonrange }, -- singuloth
	[UnitDefNames["geo"].id] = { 3, UnitDefNames["geo"].customParams.pylonrange }, -- geo
	[UnitDefNames["amgeo"].id] = { 2, UnitDefNames["amgeo"].customParams.pylonrange }, -- moho
}
local GridDefs = {}
for unitID, data in pairs(EnergyDefs) do
	EnergyDefs[unitID] = {data[1],data[2]}
end
for unitID, data in pairs(MexDefs) do
	GridDefs[unitID] = { 0, UnitDefs[unitID].customParams.pylonrange }
end
for unitID, data in pairs(EnergyDefs) do
	GridDefs[unitID] = data
end
local PylonRange = UnitDefNames["armestor"].customParams.pylonrange + 39

local CMD_AUTOECO = 35301

local OnDefaultDefs = {} -- populated by options

local EcoDefs = {
	[UnitDefNames["armnanotc"].id] = true,
}
local CareTakerDefs = {
	[UnitDefNames["armnanotc"].id] = true,
}
local AirFactoryDefs = {
	[UnitDefNames["factorygunship"].id] = true,
	[UnitDefNames["factoryplane"].id] = true,
}
-- more setup
for i=1,#UnitDefs do
	local ud = UnitDefs[i]
	if (ud.isBuilder and not(ud.isFactory)) or (ud.customParams.commtype) then
		EcoDefs[i] = true
	end
end

local wepRanges = {}
local wDefs = WeaponDefs

local we_are_good = false
local show_ai_info = false
local tries = 0
local ecoUnit = {} -- pAI only works for econs/cons/caretakers/factories...
local pAI = {} -- by unitID, holds table that holds anything
local pAI_jobs = {} -- by 1,2,3... holds job for pAI controlled units to do
local pAI_econ -- on Init is populated, and updated on gameframe, holds current income + income for previous 30th second, 60th, 90th. to see whether you are doing good or bad
local pAI_danger = {}
local pAI_enemy = {} -- by unitID, holds weapon range or -1 if weapon is yet unknown

local myTeamID
local myTeamIDs = {} -- allies

local CMD_OPT_SHIFT = CMD.OPT_SHIFT 
local CMD_RECLAIM = CMD.RECLAIM
local CMD_PATROL = CMD.PATROL
local CMD_REPAIR = CMD.REPAIR
local CMD_FIGHT = CMD.FIGHT
local CMD_GUARD = CMD.GUARD
local CMD_MOVE = CMD.MOVE
local CMD_INSERT = CMD.INSERT

local random = math.random
local floor = math.floor
local abs = math.abs
local sqrt = math.sqrt

local textSize = 12.0
local textColor = {0.3, 0.7, 1.0, 1.0}

local CONFRONT_DIST = 900

local JOB_BUILD = 1
local JOB_RETREAT = 2
local JOB_SCOUT = 3
-- self removal jobs below
local JOB_RECLAIM = 4
local JOB_REPAIR = 5
local JOB_ASSIST = 6
local JOB_HELP_FACTORY = 7
local JOB_RELOCATE = 8

local MAX_CARETAKER_RANGE_SQ = 500*500
local MAX_MEX_DIST_SQ = 1800*1800
local MAX_JOB_CLOSE_SQ = 900*900

local tooltips = { "pAI: off.\nHuman control, not under AI control.", "pAI: this unit.\nUnit is under control of AI should it idle.", "pAI: this unit and children.\nUnit is under control of AI should it idle.\nAnything unit builds will be under AI control, too." }

local currentGameFrame = 0

local OreExtractors = {}

local DEBUG = true

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- misc stuff

local function InsideMap(x,z)
	if (x >= 0) and (x <= mapWidth) and (z >= 0) and (z <= mapHeight) then
		return true
	else
		return false
	end
end

local function disSQ(x1,y1,x2,y2)
	return (x1 - x2)^2 + (y1 - y2)^2
end

local function IgnoreGaia(unitID)
	local ud = UnitDefs[spGetUnitDefID(unitID)]
	if ud and not(ud.canAttack) then
		return true
	end
	return false
end

local function CheckMyTeam()
	if (spGetSpectatingState()) then
		widgetHandler:RemoveCallIn("GameFrame") -- traitors win!
		return false
	end
	myTeamID = spGetMyTeamID()
	return true
end

local function DrawOutline(cmd,x,y,z,h)
	local ud = UnitDefs[cmd]
	local baseX = ud.xsize * 4 -- ud.buildingDecalSizeX
	local baseZ = ud.zsize * 4 -- ud.buildingDecalSizeY
	if (h == 1 or h==3) then
		baseX,baseZ = baseZ,baseX
	end
	glVertex(x-baseX,y,z-baseZ)
	glVertex(x-baseX,y,z+baseZ)
	glVertex(x+baseX,y,z+baseZ)
	glVertex(x+baseX,y,z-baseZ)
	glVertex(x-baseX,y,z-baseZ)
end

function widget:DrawWorld()
	if not Spring.IsGUIHidden() and (we_are_good) and (show_ai_info) then
		local fade = abs((currentGameFrame % 40) - 20) / 20
		for jobID, data in pairs(pAI_jobs) do
			local x, y, z, h = data.x, data.y, data.z, data.h
			if (data.type == JOB_BUILD) or ((data.type == JOB_SCOUT) and (UnitDefs[data.cmdID])) then
				local text1 = data.type==JOB_BUILD and "build" or "scout"
				local degrees = h * 90
				if spIsAABBInView(x-1,y-1,z-1,x+1,y+1,z+1) then
					glColor(0.0, 1.0, 0.0, 1 )
					glBeginEnd(GL_LINE_STRIP, DrawOutline, data.cmdID, x, y, z, h)
					glColor(1.0, 1.0, 1.0, 0.35 ) -- ghost value 0.35
					glDepthTest(true)
					glPushMatrix()
					glTranslate( x, y, z )
					glRotate( degrees, 0, 1.0, 0 )
					glUnitShape( data.cmdID, spGetMyTeamID())
					glRotate( degrees, 0, -1.0, 0 )
					glBillboard() -- also show some debug stuff
					glColor(textColor)
					glText("jobID"..jobID..":"..text1..":a"..data.assigned_count..":i"..data.importance, 20.0, 25.0, textSize, "pai")
					glText(UnitDefs[data.cmdID].humanName, 20.0, 15.0, textSize, "pai")
					glPopMatrix()
					glDepthTest(false)
					glColor(1, 1, 1, 1)
				end -- if inview
			elseif (data.type == JOB_RETREAT) then
				glPushMatrix()
				glTranslate( x, y, z )
				glBillboard() -- also show some debug stuff
				glColor(textColor)
				glText("jobID:"..jobID..":retreat:a"..data.assigned_count..":i"..data.importance, 20.0, 25.0, textSize, "pai")
				glPopMatrix()
				glColor(1, 1, 1, 1)
			elseif (data.type > JOB_SCOUT) then
				if spValidFeatureID(data.cmdID) and (data.type == JOB_RECLAIM) then
					x,y,z = spGetFeaturePosition(data.cmdID)
				elseif spValidUnitID(data.cmdID) then
					x,y,z = spGetUnitPosition(data.cmdID)
				end
				if x and spIsAABBInView(x-1,y-1,z-1,x+1,y+1,z+1) then
					local text1 = "wtf?"
					if data.type==JOB_RECLAIM then text1 = "reclaim"
					elseif data.type==JOB_REPAIR then text1 = "repair"
					elseif data.type==JOB_ASSIST then text1 = "assist"
					elseif data.type==JOB_HELP_FACTORY then text1 = "help"
					elseif data.type==JOB_RELOCATE then text1 = "relocate" end
					glPushMatrix()
					glTranslate( x, y, z )
					glBillboard() -- also show some debug stuff
					glColor(textColor)
					glText("jobID:"..jobID..":"..text1..":a"..data.assigned_count..":i"..data.importance, 20.0, 25.0, textSize, "pai")
					glPopMatrix()
					glColor(1, 1, 1, 1)
				end -- if inview
			end
		end
		if (pAI_econ.base) then
			local x = pAI_econ.base[1]
			local y = pAI_econ.base[2]+80
			local z = pAI_econ.base[3]
			if spIsAABBInView(x-1,y-1,z-1,x+1,y+1,z+1) then
				glPushMatrix()
				glTranslate( x, y, z )
				glBillboard() -- also show some debug stuff
				glColor(textColor)
				glText("pAI:base", 0.0, 0.0, textSize, "pai")
				glPopMatrix()
				glColor(1, 1, 1, 1)
			end -- if inview
		end
		for unitID, data in pairs(pAI) do
			if (data.control > 0) and spIsUnitInView(unitID) then
				local ux, uy, uz = spGetUnitViewPosition(unitID)
				glPushMatrix()
				glTranslate(ux, uy, uz)
				glBillboard()
				glColor(textColor)
				local humancontrol = data.humanorders and "human" or data.job
				glText("pAI:u"..unitID..":"..humancontrol, 20.0, 15.0, textSize, "pai")
				glPopMatrix()
				glColor(1, 1, 1, 1)
			end -- if InView
		end
		if (DEBUG) then
			for unitID, data in pairs(pAI_econ.extractor) do
				if spIsUnitInView(unitID) then
					local ux, uy, uz = spGetUnitViewPosition(unitID)
					glPushMatrix()
					glTranslate(ux, uy, uz)
					glBillboard()
					glColor(textColor)
					local overdrive = pAI_econ.overdrive[unitID] and pAI_econ.overdrive[unitID] or 0
					glText("pAI:extractor:g"..overdrive, 20.0, 5.0, textSize, "pai")
					glPopMatrix()
					glColor(1, 1, 1, 1)
				end -- if InView
			end
			for unitID, data in pairs(pAI_econ.energy) do
				if spIsUnitInView(unitID) then
					local ux, uy, uz = spGetUnitViewPosition(unitID)
					glPushMatrix()
					glTranslate(ux, uy, uz)
					glBillboard()
					glColor(textColor)
					local overdrive = pAI_econ.overdrive[unitID] and pAI_econ.overdrive[unitID] or 0
					glText("pAI:energy:g"..overdrive, 20.0, 5.0, textSize, "pai")
					glPopMatrix()
					glColor(1, 1, 1, 1)
				end -- if InView
			end
			for unitID, data in pairs(pAI_econ.factory) do
				if spIsUnitInView(unitID) then
					local ux, uy, uz = spGetUnitViewPosition(unitID)
					glPushMatrix()
					glTranslate(ux, uy, uz)
					glBillboard()
					glColor(textColor)
					glText("pAI:factory", 20.0, 5.0, textSize, "pai")
					glPopMatrix()
					glColor(1, 1, 1, 1)
				end -- if InView
			end
			for unitID, data in pairs(pAI_econ.builder) do
				if spIsUnitInView(unitID) then
					local ux, uy, uz = spGetUnitViewPosition(unitID)
					glPushMatrix()
					glTranslate(ux, uy, uz)
					glBillboard()
					glColor(textColor)
					glText("pAI:cons", 20.0, 5.0, textSize, "pai")
					glPopMatrix()
					glColor(1, 1, 1, 1)
				end -- if InView
			end
			for unitID, data in pairs(pAI_econ.commander) do
				if spIsUnitInView(unitID) then
					local ux, uy, uz = spGetUnitViewPosition(unitID)
					glPushMatrix()
					glTranslate(ux, uy, uz)
					glBillboard()
					glColor(textColor)
					glText("pAI:com", 20.0, 5.0, textSize, "pai")
					glPopMatrix()
					glColor(1, 1, 1, 1)
				end -- if InView
			end
			for unitID, data in pairs(pAI_econ.caretaker) do
				if spIsUnitInView(unitID) then
					local ux, uy, uz = spGetUnitViewPosition(unitID)
					glPushMatrix()
					glTranslate(ux, uy, uz)
					glBillboard()
					glColor(textColor)
					glText("pAI:caretaker", 20.0, 5.0, textSize, "pai")
					glPopMatrix()
					glColor(1, 1, 1, 1)
				end -- if InView
			end
		end
		for unitID, data in pairs(pAI_econ.retreat) do
			local x, y, z = data.x, data.y, data.z
			if spIsAABBInView(x-1,y-1,z-1,x+1,y+1,z+1) then
				glPushMatrix()
				glTranslate( x, y+40, z )
				glBillboard() -- also show some debug stuff
				glColor(textColor)
				glText("pAI:retreat", 0.0, 0.0, textSize, "pai")
				glPopMatrix()
				glColor(1, 1, 1, 1)
				
				glPushMatrix()
				glLineWidth(4)
				glColor(1, 1, 1, 0.5)
				glDrawGroundCircle(x, y, z, 120, 32)

				glLineWidth(2)
				glColor(0.3, 0.7, 1.0, 0.8)
				glDrawGroundCircle(x, y, z, 120, 32)
				glPopMatrix()
				
				glAlphaTest(GL_GREATER, 0)
				glColor(1,fade,fade,fade+0.1)
				glTexture('LuaUI/Images/commands/Bold/retreat.png')
				glPushMatrix()
				glTranslate(x, y+40, z)
				glBillboard()
				glTexRect(-10, 0, 10, 20)
				glPopMatrix()
				glTexture(false)
				glAlphaTest(false)
-- 				glDepthTest(false)
				glColor(1, 1, 1, 1)
			end -- if InView
		end
	end
end

local function ReInit(init)
	-- well players need base
	if WG.metalSpots then
		local units = spGetTeamUnits(myTeamID)
		local count = 0
		local x = 0
		local z = 0
		for i=1,#units do
			local unitID = units[i]
			local teamID = spGetUnitTeam(unitID)
			ux,uy,uz = spGetUnitPosition(unitID)
			count = count + 1
			x = x + ux
			z = z + uz
		end
		if (count > 0) then
			x = x / count
			z = z / count
			pAI_econ.base = {x, spGetGroundHeight(x,z), z}
			we_are_good = true
		end
	else
		tries = tries + 1
		if (tries > 10) then
			widgetHandler:RemoveWidget()
		end
	end
	-- otherwise gameframe will try to extract "first unit" position
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- pAI local functions, internal stuff

local function pAI_isControlled(unitID)
	if (pAI[unitID]) then
		if (pAI[unitID].control==0) then
			return false
		else
			return pAI[unitID].control
		end
	else
		return false
	end
end

local function pAI_SwitchControl(unitID, unitDefID, newControl)
	local control = pAI_isControlled(unitID)
	if (control) then
		if (newControl == -1) then
			pAI[unitID] = nil
		elseif (control ~= newControl) then
			pAI[unitID].control = newControl
		end
	elseif (newControl) then
		local _,_,_,_,build = spGetUnitHealth(unitID)
		pAI[unitID] = {
			control = newControl,	-- control level, 0 - none, 1 - only this unit, 2 - also children get AI controlled too
			humanorders = false,	-- whether to do human orders first
			completed = (build == 1),	-- true once unit is finished and ready to accept orders
			job = 0,		-- points to pAI_jobs, once pAI_jobs[id] is completed all minions are reassigned, jobs are issued by central command
			commander = UnitDefs[unitDefID].customParams.commtype and true or false,
			factory = UnitDefs[unitDefID].isFactory,
			builder = UnitDefs[unitDefID].isBuilder,
			caretaker = UnitDefs[unitDefID].name == "armnanotc",
			limited = UnitDefs[unitDefID].name == "armcsa",
			last_attacked = -100,
		}
	end
end

local function pAI_JobAt(x,z)
	for jobID, data in pairs(pAI_jobs) do
		if (data.x == x) and (data.z == z) then
			return jobID
		end
	end
	return false
end

local function pAI_JobByTarget(cmdID) -- only for reclaim/assist/repair tbh
	for jobID, data in pairs(pAI_jobs) do
		if (data.cmdID == cmdID) and (data.type > JOB_SCOUT) then
			return jobID
		end
	end
	return false
end

local function pAI_JobCreate(type, cmdID, x, y, z, h, importance, user)
	local jobID = #pAI_jobs+1
	if (type == JOB_BUILD) or ((type == JOB_SCOUT) and (UnitDefs[cmdID])) then
		-- TODO check for overlapping too?
		pAI_jobs[jobID] = {
			cmdID = cmdID,
			x = x,
			y = y,
			z = z,
			h = h,
			importance = importance,
			type = type,
			user = user,
			assigned = {},
			assigned_count = 0,
		}
		if (UnitDefs[cmdID].isFactory) then
			pAI_econ.factory_count = pAI_econ.factory_count + 1
		elseif (CareTakerDefs[cmdID]) then
			pAI_econ.caretaker_count = pAI_econ.caretaker_count + 1
		elseif (UnitDefs[cmdID].customParams.commtype) then
			pAI_econ.commander_count = pAI_econ.commander_count + 1
		elseif (UnitDefs[cmdID].isBuilder) then
			pAI_econ.builder_count = pAI_econ.builder_count + 1
		elseif (MexDefs[cmdID]) then
			pAI_econ.extractor_count = pAI_econ.extractor_count + 1
		elseif (EnergyDefs[cmdID]) then
			pAI_econ.energy_count = pAI_econ.energy_count + 1
		end
	else
		local exist = false
		if (type > JOB_SCOUT) then
			exist = pAI_JobByTarget(cmdID)
		end
		if not(exist) then
			pAI_jobs[jobID] = {
				cmdID = cmdID,
				x = x,
				y = y,
				z = z,
				h = h,
				importance = importance,
				type = type,
				user = user,
				assigned = {},
				assigned_count = 0,
			}
		else
			jobID = exist
		end
	end
	return jobID
end

local function pAI_JobDestroyed(jobID, unassign)
	local job = pAI_jobs[jobID]
	if (job.type == JOB_BUILD) then
		local cmdID = job.cmdID
		if (UnitDefs[cmdID].isFactory) then
			pAI_econ.factory_count = pAI_econ.factory_count - 1
		elseif (CareTakerDefs[cmdID]) then
			pAI_econ.caretaker_count = pAI_econ.caretaker_count - 1
		elseif (UnitDefs[cmdID].customParams.commtype) then
			pAI_econ.commander_count = pAI_econ.commander_count - 1
		elseif (UnitDefs[cmdID].isBuilder) then
			pAI_econ.builder_count = pAI_econ.builder_count - 1
		elseif (MexDefs[cmdID]) then
			pAI_econ.extractor_count = pAI_econ.extractor_count - 1
		elseif (EnergyDefs[cmdID]) then
			pAI_econ.energy_count = pAI_econ.energy_count - 1
		end
	end
	if (unassign) then
		for unitID, data in pairs(pAI) do
			if data.job == jobID then
				pAI[unitID].job = 0
			end
		end
	end
	pAI_jobs[jobID] = nil
end

local function pAI_JobAssign(unitID, jobID)
	if (pAI_jobs[jobID]) and not(pAI_jobs[jobID].assigned[unitID]) then
-- 		Spring.Echo(unitID.." trying to assign "..jobID)
		pAI_jobs[jobID].assigned_count = pAI_jobs[jobID].assigned_count + 1
		pAI_jobs[jobID].assigned[unitID] = true
		pAI[unitID].job = jobID
	end
end

local function pAI_JobUnassign(unitID)
	if (pAI[unitID].job > 0) then
		local jobID = pAI[unitID].job
-- 		Spring.Echo(unitID.." trying to unassign "..jobID)
		if (pAI_jobs[jobID]) and (pAI_jobs[jobID].assigned[unitID]) then
			pAI_jobs[jobID].assigned[unitID] = nil
			pAI_jobs[jobID].assigned_count = pAI_jobs[jobID].assigned_count - 1
			if (pAI_jobs[jobID].assigned_count == 0) and (pAI_jobs[jobID].type > JOB_SCOUT) then
				pAI_JobDestroyed(jobID, true)
			end
		end
		pAI[unitID].job = 0
	end
end

local function IsInsideGridConnected(badID, x, z, arraylist, consider_queued)
	local units = spGetUnitsInCylinder(x, z, PylonRange)
	local list = {}
	for i=1,#units do
		local unitID = units[i]
		local unitDefID = spGetUnitDefID(unitID)
		local unitTeam = spGetUnitTeam(unitID)
-- 		local unitAllyTeam = spGetUnitAllyTeam(unitID)
		if ((badID == nil) or (badID ~= unitID)) and ((pAI_econ.extractor[unitID]) or (pAI_econ.energy[unitID])) and (unitTeam~=GaiaTeamID) then
			local maxdist = GridDefs[unitDefID][2]
			if (badID ~= nil) then
				local badUnitDefID = spGetUnitDefID(badID)
				maxdist = maxdist + GridDefs[badUnitDefID][2]
			else
				maxdist = maxdist + 39
			end
			maxdist=maxdist*maxdist
			local x2,_,z2 = spGetUnitPosition(unitID)
			if (disSQ(x,z,x2,z2) <= maxdist) or ((badID ~= nil) and (UnitDefs[spGetUnitDefID(badID)].name == "armestor")) then
				if not(arraylist) then
					return true
				else
					list[#list+1] = unitID
				end
			end
		end
	end
	if not(arraylist) then
		if (consider_queued) then
			for jobID, data in pairs(pAI_jobs) do
				if ((data.type == JOB_BUILD) or (data.type == JOB_SCOUT)) and (GridDefs[data.cmdID]) then
					local x2,z2 = data.x,data.z
					local maxdist = GridDefs[data.cmdID][2] + 39
					maxdist = maxdist*maxdist
					if (disSQ(x,z,x2,z2) <= maxdist) or ((badID ~= nil) and (UnitDefs[spGetUnitDefID(badID)].name == "armestor")) then
						return true
					end
				end
			end
		end
		return false
	else
		return list
	end
end

local function FreeGridNumber(num)
	local bad = falsetest
	for _, grid in pairs(pAI_econ.overdrive) do
		if (grid == num) then
			bad = true
			break
		end
	end
	if (bad) then
		return FreeGridNumber(num+1)
	else
		return num
	end
end

local function MergeAllGrids(unitID, grid, badIDs) -- TODO needs serious improvement
	-- uh uh
	local x,_,z = spGetUnitPosition(unitID)
-- 	Spring.Echo(unitID.." merges2 all units to "..grid)
-- 	Spring.MarkerAddPoint(x,0,z,unitID.." to "..grid)
	local list = IsInsideGridConnected(unitID, x, z, true, false)
	badIDs[unitID] = true
	for _,ecoID in pairs(list) do
-- 		if (pAI_econ.overdrive[ecoID] ~= grid) then
	  	if not(badIDs[ecoID]) then
			pAI_econ.overdrive[ecoID] = grid
			MergeAllGrids(ecoID, grid, badIDs)
			badIDs[ecoID] = true
		end
	end
end

local function ConnectEcon(unitID)
	local x,_,z = spGetUnitPosition(unitID)
--   Spring.Echo(unitID.." new grid")
	local list = IsInsideGridConnected(unitID, x, z, true, false)
-- 	Spring.Echo(unitID.." "..#list)
	if (#list > 0) then
		local same_grid = true
		local test = pAI_econ.overdrive[list[1]]
		if (test == nil) or (test == 0) then
			test = FreeGridNumber(1)
			pAI_econ.overdrive[list[1]] = test
		end
-- 	Spring.Echo(unitID.." merges1 all units to "..test)
-- 	Spring.MarkerAddPoint(x,0,z,unitID.." to "..test)
		for i=2,#list do
			if (pAI_econ.overdrive[list[i]] ~= test) then
				same_grid = false
				break
			end
		end
		pAI_econ.overdrive[unitID] = test
		if not(same_grid) then
			MergeAllGrids(unitID, test, {})
		end
	else
		pAI_econ.overdrive[unitID] = 0
	end
end

local function DisconnectEcon(unitID)
	-- well that's a shame
	local x,_,z = spGetUnitPosition(unitID)
	local test = pAI_econ.overdrive[unitID]
	pAI_econ.overdrive[unitID] = nil
	local list = IsInsideGridConnected(unitID, x, z, true, false)
	if (#list > 0) then
		local same_grid = false
		for i=1,#list do
			if (pAI_econ.overdrive[list[i]] == test) then
				same_grid = true
				break
			end
		end
		if (same_grid) then
			for i=1,#list do
				if (IsInsideGridConnected(list[i], x, z, false, false)) then
					pAI_econ.overdrive[list[i]] = 1
				else
					pAI_econ.overdrive[list[i]] = 0
				end
			end
			for i=1,#list do
				if (pAI_econ.overdrive[list[i]] > 0) then
					MergeAllGrids(list[i], test)
				end
			end
		end
	end
end

local function AnyMexNear(tx,tz,dis)
	local closest_dist = nil
	for unitID, _ in pairs(pAI_econ.extractor) do
		local x,_,z = spGetUnitPosition(unitID)
		local dist = disSQ(x,z,tx,tz)
		if (dist < dis) then
			if (closest_dist == nil) or (dist < closest_dist) then
				closest_dist = dist
			end
		end
	end
	return closest_dist
end

local function AlliesHaveFullE()
	for teamID, _ in pairs(myTeamIDs) do
		local eCur, eMax, ePull, eInc, _, _, _, _ = spGetTeamResources(myTeamID, "energy")
		if (eCur+(eInc*3)) < eMax then return false end
	end
	return true
end

local function AlliesHaveFullM()
	for teamID, _ in pairs(myTeamIDs) do
		local mCur, mMax, mPull, mInc, _, _, _, _ = spGetTeamResources(myTeamID, "metal")
		if (mCur+(mInc*3)) < mMax then return false end
	end
	return true
end

local function PlaceRetreatLocation(unitID)
	local x,y,z = spGetUnitPosition(unitID)
	local dx,dy,dz = spGetUnitDirection(unitID)
	if (dx > 0) then
		x = x + 160
	elseif (dx < 0) then
		x = x - 160
	end
	if (dy > 0) then
		z = z + 160
	elseif (dy < 0) then
		z = z - 160
	end
	if not(InsideMap(x,y,z)) then
		x = x + random(-160,160)
		z = z + random(-160,160)
	end
	pAI_econ.retreat[unitID] = {x=x,y=y,z=z}
end

local function DestroyRetreat(unitID)
	pAI_econ.retreat[unitID] = nil
end

local function FactoryBlock(tx,ty,tz,large) -- returns true if tx,tz will block some factory
	local units = spGetUnitsInCylinder(tx,tz,350)
	local size = 60
	if (large) then
		size = 160
	end
	for i=1,#units do
		local unitID = units[i]
		if (spIsUnitAllied(unitID)) then
			local unitDefID = spGetUnitDefID(unitID)
			if (UnitDefs[unitDefID].isFactory) and not(AirFactoryDefs[unitDefID]) then
				local x,y,z = spGetUnitPosition(unitID)
				local dx,dy,dz = spGetUnitDirection(unitID)
				if (dx > 0) then
					x = x + size
				elseif (dx < 0) then
					x = x - size
				end
				if (dy > 0) then
					z = z + size
				elseif (dy < 0) then
					z = z - size
				end
				min_x = x - 120
				max_x = x + 120
				min_z = z - 120
				max_z = z + 120
				if ((min_x < tx) and (tx < max_x) and (min_z < tz) and (tz < max_z)) then
					return true
				end
			end
		end
	end
	return false
end

local function CheckAllJobsIn(x,z,size) -- TODO detect overlap
	local min_x = x - size
	local max_x = x + size
	local min_z = z - size
	local max_z = z + size
	for jobID, data in pairs(pAI_jobs) do
		if (data.type == JOB_BUILD) then
			if (data.x >= min_x) and (data.x <= max_x) and (data.z >= min_z) and (data.z <= max_z) then
				if (FactoryBlock(data.x,data.y,data.z,false)) or (spTestBuildOrder(data.cmdID, data.x, data.y, data.z, data.h) == 0) then
					-- job died
					pAI_JobDestroyed(jobID, false)
				end
			end
		end
	end
end

local function ScoutScore(ox,oz,base_x,base_z,dist)
	-- simply go north/west/east/south in steps, more steps, are scouted, the better
	if (disSQ(ox,oz,base_x,base_z) <= dist) then
		return 10 -- oh it's inside base, inside base bonus
	end
	local step = 1
	local score = -3
	local inlos = true
	local x,y,z
	local north_inLos, south_inLos, west_inLos, east_inLos
	local myAllyTeamID = spGetMyAllyTeamID()
	while ((step <= 2) and (inlos)) do
		if (step == 1) then
			x = ox; z = oz - 400; y = spGetGroundHeight(x,z)
			north_inLos = not(InsideMap(x,z)) or (select(2,spGetPositionLosState(x,y,z, myAllyTeamID)))
			x = ox; z = oz + 400; y = spGetGroundHeight(x,z)
			south_inLos = not(InsideMap(x,z)) or (select(2,spGetPositionLosState(x,y,z, myAllyTeamID)))
			x = ox - 400; z = oz; y = spGetGroundHeight(x,z)
			west_inLos = not(InsideMap(x,z)) or (select(2,spGetPositionLosState(x,y,z, myAllyTeamID)))
			x = ox + 400; z = oz; y = spGetGroundHeight(x,z)
			east_inLos = not(InsideMap(x,z)) or (select(2,spGetPositionLosState(x,y,z, myAllyTeamID)))
			if not(north_inLos) or not(south_inLos) or not(west_inLos) or not(east_inLos) then
				inlos = false
			else
				score = 0
			end
		elseif (step == 2) then
			x = ox; z = oz - 900; y = spGetGroundHeight(x,z)
			north_inLos = not(InsideMap(x,z)) or (select(2,spGetPositionLosState(x,y,z, myAllyTeamID)))
			x = ox; z = oz + 900; y = spGetGroundHeight(x,z)
			south_inLos = not(InsideMap(x,z)) or (select(2,spGetPositionLosState(x,y,z, myAllyTeamID)))
			x = ox - 900; z = oz; y = spGetGroundHeight(x,z)
			west_inLos = not(InsideMap(x,z)) or (select(2,spGetPositionLosState(x,y,z, myAllyTeamID)))
			x = ox + 900; z = oz; y = spGetGroundHeight(x,z)
			east_inLos = not(InsideMap(x,z)) or (select(2,spGetPositionLosState(x,y,z, myAllyTeamID)))
			if not(north_inLos) or not(south_inLos) or not(west_inLos) or not(east_inLos) then
				inlos = false
			else
				score = 3
			end
		end
		step = step + 1
	end
	return score
end

local function ConfrontationScore(x,z)
	local units = spGetUnitsInCylinder(x,z,CONFRONT_DIST)
	local allies = 0
	local enemies = 0
	-- consider anything non allied as dangerous
	for i=1,#units do
		if (spIsUnitAllied(units[i])) then
			allies = allies+UnitDefs[spGetUnitDefID(units[i])].metalCost
		else
			local unitID = units[i]
			if (pAI_enemy[unitID] >= 32) then
				enemies = enemies+UnitDefs[spGetUnitDefID(units[i])].metalCost
			end
		end
	end
	if (allies == 0) and (enemies > 0) then
		return -10
	elseif (enemies == 0) then
		return 3
	else
		if (allies/enemies < 1) then
			return -10
		elseif (allies/enemies >= 2) then
			return 3
		else
			return 0 -- allies have advantage but they have chance to lose
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- pAI brains + central command (job issuer)

local function BuildEnergyCloseToMex(ox,oz) -- that's oremex function
	local solars = 1==random(0,1)
	local try = 0
	while (try < 2) do
		if (solars) then
			local x = random(40,80)
			local z = random(40,80)
			if (random(0,1)==1) then x = x*-1 end
			if (random(0,1)==1) then z = z*-1 end
			x = x + ox;
			z = z + oz;
			if (InsideMap(x,z)) then
				y = spGetGroundHeight(x,z)
				if (y > waterLevel) then
					if not(FactoryBlock(x,y,z,false)) and (spTestBuildOrder(UnitDefNames["armsolar"].id, x, 0 ,z, 0) >= 1) then
						pAI_JobCreate(JOB_BUILD, UnitDefNames["armsolar"].id, x, y, z, 0, 0, false)
						return -- success
					end
				else
					try = try - 1
				end
			end
			solars = false
			try = try + 1
		else
			local x = random(40,80)
			local z = random(40,80)
			if (random(0,1)==1) then x = x*-1 end
			if (random(0,1)==1) then z = z*-1 end
			x = x + ox;
			z = z + oz;
			if (InsideMap(x,z)) then
				y = spGetGroundHeight(x,z)
				if not(FactoryBlock(x,y,z,false)) and (spTestBuildOrder(UnitDefNames["armwin"].id, x, 0 ,z, 0) >= 1) then
					pAI_JobCreate(JOB_BUILD, UnitDefNames["armwin"].id, x, y, z, 0, 0, false)
					return -- success
				end
			end
			solars = true
			try = try + 1
		end
	end
end

local function Magnitude(x, z)
	return sqrt(x * x + z * z)
end

local function Normalized(x, z)
	local mag = Magnitude(x, z)
	if mag == 0 then
		return 0, 0, 0, 0
	else
		return x / mag, z / mag, mag
	end
end

local function AdditionalE(base_x,base_z,at_base) -- TODO teach it to build closer to existing energy buildings but space them properly
	local income = pAI_econ.aveMInc
	local storagem = pAI_econ[0].mCur
	local storagee = pAI_econ[0].eCur
	if (at_base) then
		local dist = 400 + 100 * random(-1,3)
		while (dist <= 1000) do
			local x = random(0,dist)
			local z = random(0,dist)
			if (random(0,1) == 1) then x = x*-1 end
			if (random(0,1) == 1) then z = z*-1 end
			x = x + base_x
			z = z + base_z
			if (InsideMap(x,z)) then
				y = spGetGroundHeight(x,z)
				local type = UnitDefNames["armwin"].id
				if (y > waterLevel) then
					local chance = y/3
					if (chance < random(0,100)) then
						type = UnitDefNames["armsolar"].id
					end
				end
				if (income > 10) and (random(0,2)==2) and (storagee > 450) then
					type = UnitDefNames["armfus"].id
				end
				if (income > 20) and (random(0,5)>=4) and (storagee > 450) and (storagem > (50*random(0,4))) then
					type = UnitDefNames["cafus"].id
				end
				if not(FactoryBlock(x,y,z,false)) and (spTestBuildOrder(type, x, 0 ,z, 0) == 2) then
					pAI_JobCreate(JOB_BUILD, type, x, y, z, 0, 0, false)
					return -- success
				elseif (type == UnitDefNames["armsolar"].id) then
					type = UnitDefNames["armwin"].id
					if --[[not(FactoryBlock(x,y,z,false)) and]] (spTestBuildOrder(type, x, 0 ,z, 0) >= 1) then
						pAI_JobCreate(JOB_BUILD, type, x, y, z, 0, 0, false)
						return -- success
					end
				end
			end
			dist = dist+100
		end
	else
		local x,z = base_x,base_z
		for jobID, data in pairs(pAI_jobs) do
			if ((data.type == JOB_SCOUT) or (data.type == JOB_BUILD)) and (EnergyDefs[data.cmdID]) then
				if (data.x-20 <= x) and (x <= data.x+20) and (data.z-20 <= z) and (z <= data.z+20) then
-- 		Spring.MarkerAddPoint(base_x,0,base_z,"FAIL")
					return -- oh
				end
			end
		end
		local y = spGetGroundHeight(x,z)
		local type = UnitDefNames["armwin"].id
-- 		Spring.MarkerAddPoint(base_x,0,base_z,"oh "..spTestBuildOrder(type, base_x, 0 ,base_z, 0))
		if (y > waterLevel) then
			local chance = y/3
			if (chance < random(0,100)) then
				type = UnitDefNames["armsolar"].id
			end
		end
		if --[[not(FactoryBlock(x,y,z,false)) and]] (spTestBuildOrder(type, x, 0 ,z, 0) >= 1) then
			pAI_JobCreate(JOB_BUILD, type, x, y, z, 0, 0, false)
			return -- success
		elseif (type == UnitDefNames["armsolar"].id) then
			type = UnitDefNames["armwin"].id
			if --[[not(FactoryBlock(x,y,z,false)) and]] (spTestBuildOrder(type, x, 0 ,z, 0) >= 1) then
				pAI_JobCreate(JOB_BUILD, type, x, y, z, 0, 0, false)
				return -- success
			end
		end
	end
end

local function ConnectGrid(unitID1, unitID2)
	local x1,_,z1 = spGetUnitPosition(unitID1)
	local x2,_,z2 = spGetUnitPosition(unitID2)
-- 		Spring.MarkerAddPoint(x1,0,z1,"oh1")
-- 		Spring.MarkerAddPoint(x2,0,z2,"oh2")
	local dist = disSQ(x1,z1,x2,z2)
	local max_dist = PylonRange*PylonRange*1.9
	local min_dist = PylonRange*PylonRange*1.4
	local income = pAI_econ.aveMInc
	local encome = pAI_econ.aveEInc
	local storagem = pAI_econ[0].mCur
	local storagee = pAI_econ[0].eCur
	if (encome > 10) and (dist < max_dist) and (dist > min_dist) then
-- 	  Spring.Echo("[debug] pylon is enough to connect shit")
		local ox = (x1+x2)/2; local oz = (z1+z2)/2
		try = 0
		for jobID, data in pairs(pAI_jobs) do
			if ((data.type == JOB_SCOUT) or (data.type == JOB_BUILD)) and (data.cmdID == UnitDefNames["armestor"].id) then
				if (data.x-20 <= ox) and (ox <= data.x+20) and (data.z-20 <= oz) and (oz <= data.z+20) then
					try = 3
				end
			end
		end
		while (try < 3) do
			local x = ox + random(-20,20)
			local z = oz + random(-20,20)
			local y = spGetGroundHeight(x,z)
			if (InsideMap(x,z)) then
				pAI_JobCreate(JOB_BUILD, UnitDefNames["armestor"].id, x, y, z, 0, 0, false)
				try = 3
			else
				try = try + 1
			end
		end
	elseif (dist > (140*140)) then
-- 	  Spring.Echo("[debug] long line")
		-- from unitID1 to unitID2
		local vector_x = x2-x1
		local vector_z = z2-z1
		local mag
		vector_x, vector_z, mag = Normalized(vector_x, vector_z)
		mag = mag - 80
		vector_x = vector_x * mag
		vector_z = vector_z * mag
		local vx = x1 + vector_x
		local vz = z1 + vector_z
		vector_x = x1-x2
		vector_z = z1-z2
		vector_x, vector_z, mag = Normalized(vector_x, vector_z)
		mag = mag - 80
		vector_x = vector_x * mag
		vector_z = vector_z * mag
		local vx2 = x2 + vector_x
		local vz2 = z2 + vector_z
		if (disSQ(vx,vz,vx2,vz2) > (80*80)) then
-- 		  Spring.Echo("[debug] yea")
			AdditionalE(vx, vz, false)
			AdditionalE(vx2, vz2, false)
		else
-- 		  Spring.Echo("[debug] nea")
			local ox = (vx+vx2)/2; local oz = (vz+vz2)/2
			local x = ox + random(-15,15)
			local z = oz + random(-15,15)
			AdditionalE(x, z, false)
		end
	else
-- 	  Spring.Echo("[debug] singleunit")
		local ox = (x1+x2)/2; local oz = (z1+z2)/2
		local x = ox + random(-15,15)
		local z = oz + random(-15,15)
		AdditionalE(x, z, false)
	end
end

local function CreateCaretaker(unitID, x,y,z)
	local steps=0
	local direction = random(0,3)
	while (steps <= 18) do
		if not(FactoryBlock(x,y,z,true)) and (spTestBuildOrder(UnitDefNames["armnanotc"].id, x, 0 ,z, 0) >= 1) then
			pAI_JobCreate(JOB_BUILD, UnitDefNames["armnanotc"].id, x, spGetGroundHeight(x,z), z, 0, 0, false)
			return -- success
		end
		local way = random(0,3)
		if (way ~= direction) then
			if (way==0) then
				if ((x-40)<=0) then
					return
				end
				x=x-40
			elseif (way==2) then
				if ((x+40)>=mapWidth) then
					return
				end
				x=x+40
			elseif (way==1) then
				if ((z-40)<=0) then
					return
				end
				z=z-40
			elseif (way==3) then
				if ((z+40)>=mapHeight) then
					return
				end
				z=z+40
			end -- otherwise stay at place
		end
		steps = steps+1
	end
end

local function ReclaimSomeFeature(unitID, x, z, max_dist, need_e, need_m, e_first)
	if (max_dist) then -- caretaker
		local features = spGetFeaturesInRectangle(x-max_dist,z-max_dist,x+max_dist,z+max_dist)
		max_dist = max_dist*max_dist
		local oreid
		local best_dist
		for i=1,#features do
			local featureID = features[i]
			local featureDefID = spGetFeatureDefID(featureID)
			local fm,_,fe  = spGetFeatureResources(featureID)
			if (need_e and (fe > 0)) or (not(efirst) and (need_m) and (fm > 0)) then
				local ox,_,oz = spGetFeaturePosition(featureID)
				local dist = disSQ(x,z,ox,oz)
				if IsTargetReallyReachable(unitID, ox, spGetGroundHeight(ox,oz), oz, x, spGetGroundHeight(x,z), z) and ((best_dist == nil) or (dist < best_dist)) and (dist <= max_dist) then
					oreid = featureID
					best_dist = dist
				end
			end
		end
		if (oreid) then
			local ox,oy,oz = spGetFeaturePosition(oreid)
			local jobID = pAI_JobCreate(JOB_RECLAIM, oreid, ox, oy, oz, 0, 0, false)
			pAI_JobAssign(unitID, jobID)
			spGiveOrderArrayToUnitArray({unitID}, {{CMD_RECLAIM, {oreid}, {}}, {CMD_RECLAIM, {ox,oy,oz,80}, CMD_OPT_SHIFT}})
			return true
		end
	else -- walky type, TODO rework this!
		local features = spGetFeaturesInRectangle(x-CONFRONT_DIST,z-CONFRONT_DIST,x+CONFRONT_DIST,z+CONFRONT_DIST)
		local oreid
		local best_dist
		for i=1,#features do
			local featureID = features[i]
			local featureDefID = spGetFeatureDefID(featureID)
			local fm,_,fe  = spGetFeatureResources(featureID)
			if (need_e and (fe > 0)) or (not(efirst) and (need_m) and (fm > 0)) then
				local ox,_,oz = spGetFeaturePosition(featureID)
				local dist = disSQ(x,z,ox,oz)
				if IsTargetReallyReachable(unitID, ox, spGetGroundHeight(ox,oz), oz, x, spGetGroundHeight(x,z), z) and ((best_dist == nil) or (dist < best_dist)) and (ConfrontationScore(ox,oz) > 0) then
					oreid = featureID
					best_dist = dist
				end
			end
		end
		if (oreid) then
			local ox,oy,oz = spGetFeaturePosition(oreid)
			local jobID = pAI_JobCreate(JOB_RECLAIM, oreid, ox, oy, oz, 0, 0, false)
			pAI_JobAssign(unitID, jobID)
			spGiveOrderArrayToUnitArray({unitID}, {{CMD_RECLAIM, {oreid}, {}}, {CMD_RECLAIM, {ox,oy,oz,80}, CMD_OPT_SHIFT}})
			return true
		end
	end
	return false
end

local function RepairSomething(unitID, x, z, max_dist)
	if (max_dist) then -- caretaker
		local units = spGetUnitsInCylinder(x,z,max_dist)
		max_dist = max_dist*max_dist
		local bestID
		local best_dist
		for i=1,#units do
			local targetID = units[i]
			if (spIsUnitAllied(targetID) and (unitID ~= targetID)) then
				local hp,maxHp,_,_,build = spGetUnitHealth(targetID)
				if (build == 1) and (hp < maxHp) then
					local ox,_,oz = spGetUnitPosition(targetID)
					local dist = disSQ(x,z,ox,oz)
					if IsTargetReallyReachable(unitID, ox, spGetGroundHeight(ox,oz), oz, x, spGetGroundHeight(x,z), z) and ((best_dist == nil) or (dist < best_dist)) and (dist <= max_dist) then
						bestID = targetID
						best_dist = dist
					end
				end
			end
		end
		if (bestID) then
			local ox,oy,oz = spGetUnitPosition(bestID)
			pAI_JobAssign(unitID, pAI_JobCreate(JOB_REPAIR, bestID, ox, oy, oz, 0, 0, false))
			spGiveOrderToUnit(unitID, CMD_REPAIR, {bestID}, {})
			return true
		end
	else -- walky type, TODO rework this!
		local units = spGetUnitsInCylinder(x,z,CONFRONT_DIST)
		local bestID
		local best_dist
		for i=1,#units do
			local targetID = units[i]
			if (spIsUnitAllied(targetID) and (unitID ~= targetID)) then
				local hp,maxHp,_,_,build = spGetUnitHealth(targetID)
				if (build == 1) and (hp < maxHp) then
					local ox,_,oz = spGetUnitPosition(targetID)
					local dist = disSQ(x,z,ox,oz)
					if IsTargetReallyReachable(unitID, ox, spGetGroundHeight(ox,oz), oz, x, spGetGroundHeight(x,z), z) and ((best_dist == nil) or (dist < best_dist)) and (ConfrontationScore(ox,oz) > 0) then
						bestID = targetID
						best_dist = dist
					end
				end
			end
		end
		if (bestID) then
			local ox,oy,oz = spGetUnitPosition(bestID)
			pAI_JobAssign(unitID, pAI_JobCreate(JOB_REPAIR, bestID, ox, oy, oz, 0, 0, false))
			spGiveOrderToUnit(unitID, CMD_REPAIR, {bestID}, {})
			return true
		end
	end
	return false
end

local function HelpFactory(unitID, x, z, max_dist) -- TODO logic should be better for movable cons...
	local units = spGetUnitsInCylinder(x,z,max_dist)
	max_dist = max_dist*max_dist
	local good_units = {}
	for i=1,#units do
		local targetID = units[i]
		if (spIsUnitAllied(targetID) and (unitID ~= targetID)) and (pAI_econ.factory[targetID]) then
			local ox,_,oz = spGetUnitPosition(targetID)
			local dist = disSQ(x,z,ox,oz)
			local queue = spGetFactoryCommands(targetID, 1)
			local teamID = spGetUnitTeam(targetID)
			if IsTargetReallyReachable(unitID, ox, spGetGroundHeight(ox,oz), oz, x, spGetGroundHeight(x,z), z) and (#queue > 0) and (dist <= max_dist) and ((random(0,5) > 2) or (teamID == myTeamID)) then
				good_units[#good_units+1] = targetID
			end
		end
	end
	if (#good_units > 0) then
		local bestID = good_units[random(1,#good_units)]
		local ox,oy,oz = spGetUnitPosition(bestID)
		pAI_JobAssign(unitID, pAI_JobCreate(JOB_HELP_FACTORY, bestID, ox, oy, oz, 0, 0, false))
		spGiveOrderToUnit(unitID, CMD_GUARD, {bestID}, {})
		return true
	end
end

local function AssistSomething(unitID, x, z, max_dist)
	if (max_dist) then -- caretaker
		local units = spGetUnitsInCylinder(x,z,max_dist)
		max_dist = max_dist*max_dist
		local bestID
		local best_dist
		for i=1,#units do
			local targetID = units[i]
			if (spIsUnitAllied(targetID) and (unitID ~= targetID)) then
				local hp,maxHp,_,_,build = spGetUnitHealth(targetID)
				if (build < 1) then
					local ox,_,oz = spGetUnitPosition(targetID)
					local dist = disSQ(x,z,ox,oz)
					if IsTargetReallyReachable(unitID, ox, spGetGroundHeight(ox,oz), oz, x, spGetGroundHeight(x,z), z) and ((best_dist == nil) or (dist < best_dist)) and (dist <= max_dist) then
						bestID = targetID
						best_dist = dist
					end
				end
			end
		end
		if (bestID) then
			local ox,oy,oz = spGetUnitPosition(bestID)
			local jobID = pAI_JobCreate(JOB_ASSIST, bestID, ox, oy, oz, 0, 0, false)
			pAI_JobAssign(unitID, jobID)
			spGiveOrderToUnit(unitID, CMD_REPAIR, {bestID}, {})
			return true
		end
	else -- walky type, TODO rework this!
		local units = spGetUnitsInCylinder(x,z,CONFRONT_DIST)
		local bestID
		local best_dist
		for i=1,#units do
			local targetID = units[i]
			if (spIsUnitAllied(targetID) and (unitID ~= targetID)) then
				local hp,maxHp,_,_,build = spGetUnitHealth(targetID)
				if (build < 1) then
					local ox,_,oz = spGetUnitPosition(targetID)
					local dist = disSQ(x,z,ox,oz)
					if IsTargetReallyReachable(unitID, ox, spGetGroundHeight(ox,oz), oz, x, spGetGroundHeight(x,z), z) and ((best_dist == nil) or (dist < best_dist)) and (ConfrontationScore(ox,oz) > 0) then
						bestID = targetID
						best_dist = dist
					end
				end
			end
		end
		if (bestID) then
			local ox,oy,oz = spGetUnitPosition(bestID)
			local jobID = pAI_JobCreate(JOB_ASSIST, bestID, ox, oy, oz, 0, 0, false)
			pAI_JobAssign(unitID, jobID)
			spGiveOrderToUnit(unitID, CMD_REPAIR, {bestID}, {})
			return true
		end
	end
	return false
end

-- BUILDING importance
-- User job: +1000.
-- Extractor: +5.
-- Energy solar/wind +4, pylon +3, fusion +1, singu +1, geo + 3, moho +2.
-- Close to anyther energydef/extractor: +1.
-- Scouted: none/somewhat/well/inbase: -3,0,+3,+10.
-- Enemy metalcost is bigger than allymetal cost: -10.
-- Ally metalcost is much bigger than enemymetalcost: +3.
-- Any assigned con will reduce importance by one.
local function pAI_CalculateJobImportance(jobID, data)
	local x = data.x
	local y = data.y
	local z = data.z
	local _, inLos = spGetPositionLosState(x,y,z, myAllyTeamID)
	local cmdID = data.cmdID
	local type = data.type
	local importance = 0
	if (type == JOB_BUILD) then
		-- unitdefs bonus
		if (MexDefs[cmdID]) then
			importance = importance + 5
			if not(good_m) then
			      importance = importance + 10 -- triple points because its even more needed
			end
		elseif (EnergyDefs[cmdID]) then
			importance = importance + EnergyDefs[cmdID][1]
			if not(good_e) then -- double points because its needed
				importance = importance + EnergyDefs[cmdID][1]
			end
		end
		-- close to another building of type?
		if (IsInsideGridConnected(nil,x,z,false, false)) then -- TODO importance should grow the more stuff it has?
			importance = importance + 1
		end
	end
	if (type ~= JOB_SCOUT) and (type ~= JOB_RETREAT) and (type ~= JOB_RECLAIM) then
		if not(good_e) then
			importance = importance - 3
		end
		if not(good_m) and (type ~= JOB_REPAIR) then
			importance = importance - 7
		end
	end
	-- final score
	data.importance = importance + ScoutScore(x,z,pAI_econ.base[1],pAI_econ.base[3],pAI_econ.base[4]) + ConfrontationScore(x,z) - data.assigned_count
end

local function pAI_CentralCommandOrders(f)
	if ((f%900)==0) then
		pAI_econ[3] = CopyTable(pAI_econ[2])
		pAI_econ[2] = CopyTable(pAI_econ[1])
		pAI_econ[1] = CopyTable(pAI_econ[0])
	end
	local eCur, eMax, ePull, eInc, eExp, eShare, eSent, eRec = spGetTeamResources(myTeamID, "energy")
	local mCur, mMax, mPull, mInc, mExp, mShare, mSent, mRec = spGetTeamResources(myTeamID, "metal")
	pAI_econ[0] = {
		eCur = eCur, eMax = eMax, ePull = ePull, eInc = eInc,
		mCur = mCur, mMax = mMax, mPull = mPull, mInc = mInc,
	}
	-- CAI econ code is very good for needs of pAI
	aveEInc = 0
	aveMInc = 0
	aveActiveBP = 0
	i = 0
	while (i <= 3) do
		aveEInc = aveEInc + pAI_econ[i].eInc
		aveMInc = aveMInc + pAI_econ[i].mInc
		aveActiveBP = aveActiveBP + pAI_econ[i].mPull
		i = i + 1
	end
	aveEInc = aveEInc/4
	aveMInc = aveMInc/4
	aveActiveBP = aveActiveBP/4
	  
	if aveMInc > 0 then
		pAI_econ.energyToMetalRatio = aveEInc/aveMInc
		pAI_econ.activeBpToMetalRatio = aveActiveBP/aveMInc
	else
		pAI_econ.energyToMetalRatio = 0
		pAI_econ.activeBpToMetalRatio = 0
	end
	pAI_econ.aveEInc = aveEInc
	pAI_econ.aveMInc = aveMInc
	pAI_econ.aveActiveBP = aveActiveBP
	
	local good_m = (aveMInc > aveActiveBP) or ((mCur+aveMInc) > mMax*0.5)
	local good_e = (aveEInc > aveActiveBP) or ((eCur+aveEInc) > eMax*0.1)
	local good_eco = good_m and good_e
	-- make jobs!
	if ((f%90)==0) then
		-- 1) Create extractor points.
		local base_x = pAI_econ.base[1]
		local base_z = pAI_econ.base[3]
		local closest_dist = nil
		local myAllyTeamID = spGetMyAllyTeamID()
		local TestSpot = {}
		if not(oremex) or not(oremex_prespawn) then
			for i=1,#WG.metalSpots do
				local x = WG.metalSpots[i].x
				local z = WG.metalSpots[i].z
				if not(pAI_JobAt(x,z)) and (spTestBuildOrder(UnitDefNames["cormex"].id, x, 0 ,z, 0) >= 1) then
					local dist = AnyMexNear(x,z,MAX_JOB_CLOSE_SQ) or disSQ(x,z,base_x,base_z)
					TestSpot[#TestSpot+1] = {
					  x = x,
					  z = z,
					  dist = dist,
					}
					if (closest_dist == nil) or (dist < closest_dist) then
						closest_dist = dist
					end
				end
			end
		end
		if (closest_dist == nil) then
			closest_dist = MAX_MEX_DIST_SQ
		else
			closest_dist = closest_dist + 600*600 -- now any spots within that range get "ScoutMe" or "Build" job depending if they are outside LoS or in.
			if (closest_dist > MAX_MEX_DIST_SQ) then
				closest_dist = MAX_MEX_DIST_SQ
			end
		end
		pAI_econ.base[4] = closest_dist
		-- 2) InLos points are for build, otherwise scouting. Cons/commanders are free to scout, if it's inbase range.
		for i=1,#TestSpot do
			local x = TestSpot[i].x
			local z = TestSpot[i].z
			local dist = TestSpot[i].dist
			if (dist <= closest_dist) then
				local y = spGetGroundHeight(x,z)
				local _, inLos = spGetPositionLosState(x,y,z, myAllyTeamID)
				if (inLos) then
					pAI_JobCreate(JOB_BUILD, UnitDefNames["cormex"].id, x, y, z, 0, 0, false)
				else
-- 					Spring.MarkerAddPoint(x,y,z,"test")
					pAI_JobCreate(JOB_SCOUT, UnitDefNames["cormex"].id, x, y, z, 0, 0, false)
				end
			end
		end
		-- 3) Capture any extractor that belongs to gaia with solar or windgen...
		if (mCur > 35) or (pAI_econ.energy_count < 10) then
			if (oremex) and (oremex_overdrive) then
				for unitID, _ in pairs(OreExtractors) do
					local unitDefID = spGetUnitDefID(unitID)
					if (unitDefID) and (MexDefs[unitDefID]) then
						-- check whether it's possible to connect it
						local x, y, z = spGetUnitPosition(unitID)
						local _, inLos = spGetPositionLosState(x,y,z, myAllyTeamID)
						if inLos and not(IsInsideGridConnected(nil, x, z, false, true)) then
							BuildEnergyCloseToMex(x, z) -- create job
						end
					end
				end
			else
				for unitID, _ in pairs(pAI_econ.extractor) do
					if (pAI_econ.overdrive[unitID] == 0) then
						-- check whether it's possible to connect it
						local x, y, z = spGetUnitPosition(unitID)
						local _, inLos = spGetPositionLosState(x,y,z, myAllyTeamID)
						if inLos and not(IsInsideGridConnected(nil, x, z, false, true)) then
							BuildEnergyCloseToMex(x, z) -- create job
						end
					end
				end
			end
			-- 4) Any built extractor inlos deserves econ, riiight? So let's check grid.
			local energy_jobs_cost = 0
			for jobID, data in pairs(pAI_jobs) do
				if (data.type == BUILD) and (EnergyDefs[data.cmdID]) then
					energy_jobs_cost = energy_jobs_cost + EnergyDefs[data.cmdID].metalCost
				end
			end
			for unitID,_ in pairs(pAI_econ.energy) do
				local _,_,_,_,build = spGetUnitHealth(unitID)
				local teamID = spGetUnitTeam(unitID)
				if (build < 1) and (teamID == myTeamID) then
					energy_jobs_cost = energy_jobs_cost + UnitDefs[spGetUnitDefID(unitID)].metalCost*(1-build)
				end
			end
			if (energy_jobs_cost < aveMInc*50) then
				-- more jobs !
				local single_grid = true
				local test = 0
				for _, grid in pairs(pAI_econ.overdrive) do
				      if (test == 0) then test = grid 
				      elseif (test ~= grid) and (grid > 0) then single_grid = false break end
				end
				if not(single_grid) then
					local grids = {}
					for unitID, grid in pairs(pAI_econ.overdrive) do
						if (grids[grid] == nil) then
							grids[grid] = {
								units = {},
								x = 0,
								z = 0,
								count = 0,
							}
						else
							grids[grid].units[unitID] = true
							local x,_,z = spGetUnitPosition(unitID)
							grids[grid].x = grids[grid].x + x
							grids[grid].z = grids[grid].z + z
							grids[grid].count = grids[grid].count + 1
						end
					end
					for grid, data in pairs(grids) do
						grids[grid].x = data.x / data.count
						grids[grid].z = data.z / data.count
					end
					local grid1, grid2
					local best_dist = nil
					if (#grids > 2) then
						-- pick 2 closest grids to playerbase
						for grid, data in pairs(grids) do
							local dist = disSQ(data.x,data.z,base_x,base_z)
							if ((best_dist == nil) or (dist < best_dist)) then
								if (best_dist ~= nil) then
									grid2 = grid1
								end
								grid1 = grid
								best_dist = dist
							end
						end
					else
						for grid, _ in pairs(grids) do
							if not(grid1) then
								grid1 = grid
							else
								grid2 = grid
							end
						end
					end
					if (grid1) and (grid2) then
						-- loop through all buildings within these 2 grids and order to build energydefs to connect them
-- 						local pylon1 = PylonRange*PylonRange*2
-- 						if (dist <= pylon1) and (mCur >= 400) and (mInc >= 5) then
-- 							-- order pylon in between
-- 						end
						best_dist = nil
						local best_unit1,best_unit2
						for unitID1,_ in pairs(grids[grid1].units) do
							for unitID2,_ in pairs(grids[grid2].units) do
								local x1,_,z1 = spGetUnitPosition(unitID1)
								local x2,_,z2 = spGetUnitPosition(unitID2)
								local dist = disSQ(x1,z1,x2,z2)
								if (best_dist==nil) or (best_dist > dist) then
									best_dist = dist
									best_unit1 = unitID1
									best_unit2 = unitID2
								end
							end
						end
						if (best_unit1) and (best_unit2) then
-- 				  Spring.Echo("[debug] connect grid")
							ConnectGrid(best_unit1, best_unit2)
						end
					else
						single_grid = true
					end
-- 					if (single_grid) then
-- -- 				  Spring.Echo("[debug] additionale single grid")
-- 						AdditionalE(base_x, base_z, true)
-- 					end
					-- if single grid or "single grid" just build E somewhere close at the end of the base
				end
			end
		end
		-- 5) Scout job is swapped into Build job if it has building unitdef as cmdID. otherwise destroyed.
		-- The idea is, should building be outside los it's swapped into scout job first, so no cons will venture out there
		for jobID, data in pairs(pAI_jobs) do
			local x = data.x
			local y = data.y
			local z = data.z
			local _, inLos = spGetPositionLosState(x,y,z, myAllyTeamID)
			local type = data.type
			if (type == JOB_BUILD) then
				if not(inLos) then
					if (data.cmdID > 0) then
						pAI_jobs[jobID].type = JOB_SCOUT -- inLOS, switch for scout order
					else
						pAI_JobDestroyed(jobID, false)
					end
				end
			elseif (type == JOB_SCOUT) then
				if (inLos) then
					if (data.cmdID > 0) and (spTestBuildOrder(UnitDefNames["cormex"].id, x, 0 ,z, 0) >= 1) then
						pAI_jobs[jobID].type = JOB_BUILD -- inLOS, switch for build order
					else
						pAI_JobDestroyed(jobID, false)
					end
				end
			elseif (type == JOB_RECLAIM) then -- destroyable jobs
				if not(inLos) or not(spValidFeatureID(data.cmdID)) then
					pAI_JobDestroyed(jobID, true)
				end
			elseif (type == JOB_REPAIR) then
				if not(inLos) or not(spValidUnitID(data.cmdID)) then
					pAI_JobDestroyed(jobID, true)
				else
					local hp,maxHp,_,_,build = spGetUnitHealth(data.cmdID)
					if (hp >= maxHp) or (build < 1) then
						pAI_JobDestroyed(jobID, true)
					end
				end
			elseif (type == JOB_ASSIST) then
				if not(inLos) or not(spValidUnitID(data.cmdID)) then
					pAI_JobDestroyed(jobID, true)
				else
					local hp,maxHp,_,_,build = spGetUnitHealth(data.cmdID)
					if (hp >= maxHp) and (build == 1) then
						pAI_JobDestroyed(jobID, true)
					end
				end
			elseif (type == JOB_HELP_FACTORY) then
				if not(inLos) or not(spValidUnitID(data.cmdID)) then
					pAI_JobDestroyed(jobID, true)
				end
			elseif (type == JOB_RELOCATE) then
				if not(inLos) or not(spValidUnitID(data.cmdID)) then
					pAI_JobDestroyed(jobID, true)
				else
					for unitID, data2 in pairs(pAI) do
						if (data2.job == jobID) then
							local ux,_,uz = spGetUnitPosition(unitID)
							if (disSQ(ux,uz,x,z)<=(400*400)) then
								pAI_JobUnassign(unitID)
							end
						end
					end
				end
			end
			if (data.importance < 0) and (random(0,20)==20) then
				pAI_JobDestroyed(jobID, true)
			end
		end
		-- 6) Calculate job's importance levels.
		for jobID, data in pairs(pAI_jobs) do
			pAI_CalculateJobImportance(jobID, data, good_e, good_m)
		end
		-- Note that the decision if building is buildable is decided by cons, they check whether there is some income to spend and start building most important structure.
		-- While Job Creator will give out jobs regardless if they are even possible to complete or dangerous.
		local factory_caretakers = {}
		local factories = false
		for unitID, data in pairs(pAI_econ.factory) do
			if (spGetUnitTeam(unitID) == myTeamID) then
				local x,y,z = spGetUnitPosition(unitID)
				local queue = spGetFactoryCommands(unitID, 1)
				if (#queue > 0) then -- idle factories dont get caretakers
					factory_caretakers[unitID] = 0
					if not(factories) then factories = unitID end
					local units = spGetUnitsInCylinder(x,z,500)
					for i=1,#units do
						local unit = units[i]
						if (spIsUnitAllied(unit) and pAI_econ.caretaker[unit]) then
							factory_caretakers[unitID] = factory_caretakers[unitID] + 1
						end
					end
					for jobID, data in pairs(pAI_jobs) do
						if (data.cmdID == UnitDefNames["armnanotc"].id) then
							local cx, cz = data.x, data.z
							local dist = disSQ(x,z,cx,cz)
							if (dist < MAX_CARETAKER_RANGE_SQ) then
								factory_caretakers[unitID] = factory_caretakers[unitID] + 1
							end
						end
					end
				end
			end
		end
		local bp_users = pAI_econ.factory_count + pAI_econ.caretaker_count
		if (factories) and (good_eco) and (aveMInc >= (bp_users*10)) and (mCur > 110) and (eCur > 110) then
			local lowest = factories
			local lowest_amount = factory_caretakers[factories]
			for unitID, amount in pairs(factory_caretakers) do
				if (amount < lowest_amount) then
					lowest_amount = amount
					lowest = unitID
				end
			end
			local x,y,z = spGetUnitPosition(lowest)
			CreateCaretaker(lowest, x,y,z)
		end
	end
	return good_m, good_e
end

local function pAI_Think(f,good_m,good_e)
	local good_eco = good_m and good_e
	local any = false
	for unitID, data in pairs(pAI) do
		if not(any) then any = true end
		if (data.humanorders == false) and (data.completed) then
			if (data.job > 0) then
				if (pAI_jobs[data.job] == nil) or (pAI_jobs[data.job].importance < 0) or
				    ((pAI_jobs[data.job].type == JOB_RETREAT) and (data.last_attacked-150 > f)) or
				    ((random(0,3)==3) and ((pAI_jobs[data.job].type == JOB_BUILD) or (pAI_jobs[data.job].type == JOB_ASSIST)) and not(good_eco)) or
				    ((data.builder) and (pAI_jobs[data.job].type == JOB_HELP_FACTORY) and not(good_eco)) or
				    (pAI_jobs[data.job].type == JOB_RECLAIM and (AlliesHaveFullM()) and (AlliesHaveFullE())) then
					pAI[unitID].job = 0
				end
			end
			if (data.builder) and (data.job == 0) then
				-- no time to waste!
				local closest_job = nil
				local closest_dist = nil
				local x,y,z = spGetUnitPosition(unitID)
				local goodJobs = {}
				local farJobs = {}
				for jobID, job_data in pairs(pAI_jobs) do
					if (not(data.limited) or not(JOB_BUILD)) then
						local jx, jy, jz = job_data.x, job_data.y, job_data.z
						if IsTargetReallyReachable(unitID, jx, jy, jz, x, y, z) then
							local dist = disSQ(jx,jz,x,z)
							if (dist < MAX_JOB_CLOSE_SQ) then
								goodJobs[#goodJobs+1] = jobID
							else
								farJobs[#farJobs+1] = jobID
							end
						end
					end
				end
				local assigned = false
				if (good_eco) then
					if (#goodJobs > 0) then
						-- pick most important one and with the least cons?
						local most_important = goodJobs[1]
						local importance = pAI_jobs[goodJobs[1]].importance
						local closest_dist
						for i=2,#goodJobs do
							local jobID = goodJobs[i]
							local job_data = pAI_jobs[jobID]
							local dist = disSQ(job_data.x,job_data.z,x,z)
							if ((random(0,2)==2) and (job_data.importance > importance)) or ((job_data.importance == importance) and ((closest_dist == nil) or (closest_dist < dist))) then
								 importance = job_data.importance
								 most_important = jobID
								 closest_dist = dist
							end
						end
-- 						CheckAllJobsIn(data.x,data.z,100)
						local data = pAI_jobs[most_important]
						if (data) and (data.type == JOB_BUILD) and (data.importance >= 0) then
							local units = spGetUnitsInRectangle(data.x-1,data.z-1,data.x+1,data.z+1)
							if (#units > 0) then
								local orders = {}
								local first = true
-- 								orders[1] ={CMD_RECLAIM, {data.x,data.y,data.z,10}, {}}
								for i=1,#units do
									local unitID = units[i]
									if (spIsUnitAllied(unitID)) then
										orders[1] = {CMD_REPAIR, {unitID}, {}}
										first = false
										break
									end
								end
								orders[#orders+1] = {CMD_REPAIR, {data.x,data.y,data.z,data.h}, first and CMD_OPT_SHIFT or {}}
								spGiveOrderArrayToUnitArray({unitID},orders)
							else
								spGiveOrderToUnit(unitID, -data.cmdID, {data.x,data.y,data.z,data.h}, {})
							end
							assigned = pAI_JobAssign(unitID, most_important)
-- 						elseif (data.type == JOB_SCOUT) and (data.commander) then -- TODO this
-- 							spGiveOrderToUnit(unitID, -data.cmdID, {data.x,data.y,data.z,data.h}, {})
-- 							pAI_JobAssign(unitID, most_important)
						end
					end
				end
				local minimum_resource = pAI_econ[0].mCur
				if (pAI_econ[0].eCur < minimum_resource) then
					minimum_resource = pAI_econ[0].eCur
				end
				local max_resource = pAI_econ[0].mMax
				if (max_resource < 500) then max_resource = 500 end
				local skip_reclaim = minimum_resource / pAI_econ[0].mMax * 100
				if not(assigned) and (skip_reclaim < random(1,100)) then -- income is lower than activebp, any reclaimablities?
					local e_first = false
					if (pAI_econ[0].eCur <= pAI_econ[0].eMax*0.1) then
						e_first = true
					end
					local need_e = true
					local need_m = true
					if (AlliesHaveFullE()) then
						need_e = false
					end
					if (AlliesHaveFullM()) then
						need_m = false
					end
					if (need_m) or (need_e) then
						-- select any closest feature of interest, create job, assign yourself
						if (data.caretaker) then
							assigned = ReclaimSomeFeature(unitID, x, z, 500, need_e, need_m, e_first)
						else
							assigned = ReclaimSomeFeature(unitID, x, z, nil, need_e, need_m, e_first)
						end
					end
				end
				if not(assigned) then -- nothing to reclaim? if we have energy lets repair stuff, if we have good_eco lets assist unfinished stuff
					-- if it's possible try to spend metal first, then repair
					if (good_e) and not(good_m) then
						if (data.caretaker) then
							assigned = RepairSomething(unitID, x, z, 500)
						else
							assigned = RepairSomething(unitID, x, z, nil)
						end
					elseif (good_eco) then
						if (data.caretaker) then
							assigned = AssistSomething(unitID, x, z, 500)
						else
							assigned = AssistSomething(unitID, x, z, nil)
						end
					end
					if not(assigned) then
						if (data.caretaker) then
							assigned = RepairSomething(unitID, x, z, 500)
						elseif (good_e) then
							assigned = RepairSomething(unitID, x, z, nil)
						end
					end
					if not(assigned) and (good_eco) then -- nothing at all? help nearest player/ally factory ?
						assigned = HelpFactory(unitID, x, z, 500)
					end
				end
				if not(data.caretaker) and not(assigned) and (random(0,5)>=4) then
					if (#farJobs > 0) then
						local randJob = farJobs[random(1,#farJobs)]
						local ox = pAI_jobs[randJob].x
						local oz = pAI_jobs[randJob].z
						local oy = spGetGroundHeight(ox,oz)
						if IsTargetReallyReachable(unitID, ox, oy, oz, x, y, z) then
							assigned = pAI_JobAssign(unitID, pAI_JobCreate(JOB_RELOCATE, 0, ox, oy, oz, 0, 0, false))
						end
					end
				end
			end
		end
	end
	if (show_ai_info ~= any) then show_ai_info = any end
end

function widget:GameFrame(n)
	currentGameFrame = n
	if (we_are_good) then
		if ((n%30)==0) then
			if (CheckMyTeam()) then
				local good_m,good_e = pAI_CentralCommandOrders(n) -- manages existing jobs and creates new one, basically internal HoP/Cap'n or something similar
				pAI_Think(n,good_m,good_e) -- gives minions orders and makes sure they are performing them
			end
		end
	else
		if ((n%30)==0) then
			ReInit(false)
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Command Handling

-- unsure if these 2 are needed
function widget:AllowCommand_GetWantedCommand()
	return {[CMD_AUTOECO] = true}
end

function widget:AllowCommand_GetWantedUnitDefID()
	return true
end

function widget:CommandNotify(cmdID, cmdParams, cmdOptions)
	if cmdID == CMD_AUTOECO then
		local foundValidUnit = false
		local newEcoOrder = 0
		local selectedUnits = spGetSelectedUnits()
		for i=1, #selectedUnits do
			local unitID = selectedUnits[i]
			local unitDefID = spGetUnitDefID(unitID)
			if EcoDefs[unitDefID] or UnitDefs[unitDefID].isFactory then
				if not foundValidUnit then
					foundValidUnit = true
					if not cmdOptions.right then
						if pAI_isControlled(unitID)==1 then
							newEcoOrder = 2
						elseif pAI_isControlled(unitID)==2 then
							newEcoOrder = 0
						else
							newEcoOrder = 1
						end
					else
						if pAI_isControlled(unitID)==1 then
							newEcoOrder = 0
						elseif pAI_isControlled(unitID)==2 then
							newEcoOrder = 1
						else
							newEcoOrder = 2
						end
					end
				end
				pAI_SwitchControl(unitID, unitDefID, newEcoOrder)
				if (newEcoOrder > 0) then
					local ud = UnitDefs[unitDefID]
					if not(ud.isFactory) and (getMovetype(ud) == false) then
					      pAI[unitID].humanorders = false
					elseif (#spGetCommandQueue(unitID,2)>0) then
					      pAI[unitID].humanorders = true
					end
				end
			end
		end
		return true
	else
		local selectedUnits = spGetSelectedUnits()
		for i=1, #selectedUnits do
			local unitID = selectedUnits[i]
			if pAI_isControlled(unitID) then
				pAI_JobUnassign(unitID)
				pAI[unitID].humanorders = true
			end
		end
	end
end

function widget:CommandsChanged()
	local selectedUnits = spGetSelectedUnits()
	local foundGood = false
	local customCommands = widgetHandler.customCommands
	for i=1,#selectedUnits do
		local unitID = selectedUnits[i]
		local unitDefID = spGetUnitDefID(unitID)
		if not foundGood and (EcoDefs[unitDefID] or UnitDefs[unitDefID].isFactory) then
			foundGood = true
			local ecoOrder = 0
			if (pAI_isControlled(unitID) == 1) then
				ecoOrder = 1
			elseif (pAI_isControlled(unitID) == 2) then
				ecoOrder = 2
			end
			table.insert(customCommands,
			{
				id      = CMD_AUTOECO,
				type    = CMDTYPE.ICON_MODE,
				name    = 'pAI',
				action  = 'pAI',
				tooltip	= tooltips[ecoOrder+1],
				params 	= {ecoOrder, "pAI: off.","pAI: this unit.","pAI: this unit and children."}
			})
			end
		
		if foundGood then
			return
		end
	end 
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Unit Handling

function widget:UnitIdle(unitID, unitDefID, teamID)
	if (pAI_isControlled(unitID)) and (pAI[unitID].completed) then
		if (pAI[unitID].humanorders) then
			pAI[unitID].humanorders = false
		end
		if (pAI[unitID].job > 0) and not(pAI_jobs[pAI[unitID].job]) then
-- 			Spring.Echo(unitID.." applies for job")
			pAI[unitID].job = 0
		end
	end
end

function widget:UnitDamaged(unitID, unitDefID, unitTeam)
	if (pAI_isControlled(unitID)) and (pAI[unitID].completed) and not(pAI[unitID].humanorders) then
		local hp,maxHp,_,_,build = spGetUnitHealth(unitID)
		if (hp < maxHp*0.8) then
			local best_retreat
			local best_dist
			local x,y,z = spGetUnitPosition(unitID)
			for targetID, data in pairs(pAI_econ.retreat) do
				local ox, oy, oz = data.x, data.y, data.z
				local dist = disSQ(x,z,ox,oz)
				if IsTargetReallyReachable(unitID, ox, oy, oz, x, y, z) and ((best_dist == nil) or (dist < best_dist)) then
					best_retreat = targetID
					best_dist = dist
				end
			end
			if (best_retreat) then
				if (pAI[unitID].job > 0) then
					pAI_JobUnassign(unitID, pAI[unitID].job)
				end
				local data = pAI_econ.retreat[best_retreat]
				local ox, oy, oz = data.x, data.y, data.z
				pAI_JobAssign(JOB_RETREAT, best_retreat, ox,oy,oz, 0, 0, false)
				pAI[unitID].last_attacked = spGetGameFrame()
				spGiveOrderToUnit(unitID, CMD_MOVE, {ox,oy,oz}, {})
			end
		end
	end
end

local function ProcessUnitCreated(unitID, unitDefID, teamID, builderID)
	if EcoDefs[unitDefID] then
		ecoUnit[unitID] = true	
	end
	if (teamID == myTeamID) then
		if OnDefaultDefs[unitDefID] or pAI_isControlled(builderID)==2 then
			if OnDefaultDefs[unitDefID] then
				pAI_SwitchControl(unitID, unitDefID, OnDefaultDefs[unitDefID])
			else
				pAI_SwitchControl(unitID, unitDefID, 2)
			end
			pAI[unitID].humanorders = true -- hacky way to force con to complete factory orders first
		end	
	end
	if (UnitDefs[unitDefID].isFactory) and not(pAI_econ.factory[unitID]) then
		pAI_econ.factory[unitID] = true
		pAI_econ.factory_count = pAI_econ.factory_count + 1
		PlaceRetreatLocation(unitID)
	elseif (CareTakerDefs[unitDefID]) and not (pAI_econ.caretaker[unitID]) then
		pAI_econ.caretaker[unitID] = true
		pAI_econ.caretaker_count = pAI_econ.caretaker_count + 1
	elseif (UnitDefs[unitDefID].customParams.commtype) and not (pAI_econ.commander[unitID]) then
		pAI_econ.commander[unitID] = true
		pAI_econ.commander_count = pAI_econ.commander_count + 1
	elseif (UnitDefs[unitDefID].isBuilder) and not (pAI_econ.builder[unitID]) then
		pAI_econ.builder[unitID] = true
		pAI_econ.builder_count = pAI_econ.builder_count + 1
	elseif (EnergyDefs[unitDefID]) and not (pAI_econ.energy[unitID]) then
		pAI_econ.energy[unitID] = true
		pAI_econ.energy_count = pAI_econ.energy_count + 1
		ConnectEcon(unitID)
	elseif (MexDefs[unitDefID]) and not (pAI_econ.extractor[unitID]) then
		pAI_econ.extractor[unitID] = true
		pAI_econ.extractor_count = pAI_econ.extractor_count + 1
		ConnectEcon(unitID)
	end
	-- if it's building render job that is inside building impossible to build
	if (getMovetype(UnitDefs[unitDefID]) == false) then
		local x,y,z = spGetUnitPosition(unitID)
		local radius = spGetUnitDefDimensions(unitDefID)[2]
		if (radius == nil) then radius = 300 end
		radius = radius * 2
		CheckAllJobsIn(x,z,radius)
	end
end

local function ProcessUnitFinished(unitID, unitDefID, teamID)
	if (pAI_isControlled(unitID)) then
-- 		if (#spGetCommandQueue(unitID,1) > 0) then
-- 			Spring.Echo("HUMAN ORDERZ")
-- 			pAI[unitID].humanorders = true
-- 		else
-- 			pAI[unitID].humanorders = false
-- 		end
		pAI[unitID].completed = true
	end
end

local function ProcessUnitDestroyed(unitID, unitDefID, teamID)
	if ecoUnit[unitID] then
		if (pAI_isControlled(unitID)) then
			pAI_JobUnassign(unitID)
			pAI_SwitchControl(unitID, unitDefID, -1)
		end
		ecoUnit[unitID] = nil
	end
	if (UnitDefs[unitDefID].isFactory) and (pAI_econ.factory[unitID]) then
		pAI_econ.factory[unitID] = nil
		pAI_econ.factory_count = pAI_econ.factory_count - 1
		DestroyRetreat(unitID)
	elseif (CareTakerDefs[unitDefID]) and (pAI_econ.caretaker[unitID]) then
		pAI_econ.caretaker[unitID] = nil
		pAI_econ.caretaker_count = pAI_econ.caretaker_count - 1
	elseif (UnitDefs[unitDefID].customParams.commtype) and (pAI_econ.commander[unitID]) then
		pAI_econ.commander[unitID] = nil
		pAI_econ.commander_count = pAI_econ.commander_count - 1
	elseif (UnitDefs[unitDefID].isBuilder) and (pAI_econ.builder[unitID]) then
		pAI_econ.builder[unitID] = nil
		pAI_econ.builder_count = pAI_econ.builder_count - 1
	elseif (MexDefs[unitDefID]) and (pAI_econ.extractor[unitID]) then
		pAI_econ.extractor[unitID] = nil
		pAI_econ.extractor_count = pAI_econ.extractor_count - 1
		DisconnectEcon(unitID)
	elseif (EnergyDefs[unitDefID]) and (pAI_econ.energy[unitID]) then
		pAI_econ.energy[unitID] = nil
		pAI_econ.energy_count = pAI_econ.energy_count - 1
		DisconnectEcon(unitID)
	end
	if pAI_enemy[unitID] then
-- 		if (pAI_econ.danger[unitID]) then
-- 			pAI_econ.danger = nil
-- 			local x,y,z = spGetUnitPosition(unitID)
-- 			if (x) and (InsideMap(x,z)) then
-- 				MakeScoutJobs(x,z)
-- 			end
-- 		end
		pAI_enemy[unitID] = nil
	end
	if (OreExtractors[unitID]) then
		OreExtractors[unitID] = nil
	end
end

function widget:UnitCreated(unitID, unitDefID, teamID, builderID)
	ProcessUnitCreated(unitID, unitDefID, teamID, builderID)
end

function widget:UnitFinished(unitID, unitDefID, teamID)
	ProcessUnitFinished(unitID, unitDefID, teamID)
end

function widget:UnitGiven(unitID, unitDefID, teamID, oldTeamID)
	widget:UnitDestroyed(unitID, unitDefID, oldTeamID)
	widget:UnitCreated(unitID, unitDefID, teamID)
	local _,_,_,_,build = spGetUnitHealth(unitID)
	if build == 1 then -- will catch reverse build, UnitFinished will not ever be called for this unit
		widget:UnitFinished(unitID, unitDefID, teamID)
	end
end

function widget:UnitTaken(unitID, unitDefID, teamID, newTeamID) -- remove unit
	ProcessUnitDestroyed(unitID, unitDefID)
end

function widget:UnitEnteredLos(unitID, teamID)
	if not(spIsUnitAllied(unitID)) then
		local unitDefID = spGetUnitDefID(unitID)
		if not(unitDefID) then
			pAI_enemy[unitID] = 500 -- let's assume it has at least 500 weapon attack range
		else
			pAI_enemy[unitID] = 32
			local uWepRanges = wepRanges[unitDefID]
			if uWepRanges then
				for r = 1, #uWepRanges do
					if (uWepRanges[r] > pAI_enemy[unitID]) then
						pAI_enemy[unitID] = uWepRanges[r]
					end
				end
			end
		end
		if (oremex) and (oremex_overdrive) then
			if (teamID == GaiaTeamID) then
				local unitDefID = spGetUnitDefID(unitID)
				if (unitDefID) and (MexDefs[unitDefID]) then
					OreExtractors[unitID] = true
				end
			end
		end
	end
end

function widget:UnitLeftLos(unitID, teamID)
	if (pAI_enemy[unitID]) then
-- 		local x,y,z = spGetUnitPosition(unitID)
-- 		if (x) and (InsideMap(x,z)) then
-- 			MakeScoutJobs(x,z)
-- 		end
		pAI_enemy[unitID] = nil
	end
	if (OreExtractors[unitID]) then
		OreExtractors[unitID] = nil
	end
end

function widget:UnitDestroyed(unitID, unitDefID, teamID)
	ProcessUnitDestroyed(unitID, unitDefID, teamID)
end

local function AnnouncerUnitDestroyed(PlayerID, unitID, attackerID)
	local unitDefID = spGetUnitDefID(unitID)
	local teamID = spGetUnitTeam(unitID)
-- 	local attackerDefID, attackerTeamID
-- 	if (attackerID ~= nil) then
-- 		attackerDefID = spGetUnitDefID(attackerID)
-- 		attackerTeamID = spGetUnitTeam(attackerID)
-- 	end
	ProcessUnitDestroyed(unitID, unitDefID, teamID)
-- 	UnitDead(unitID, unitDefID, teamID, attackerID, attackerDefID, attackerTeamID)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Initialize()
	mapWidth = Game.mapSizeX
	mapHeight = Game.mapSizeZ
	myTeamID = spGetMyTeamID()
	
	-- get resourcing
	local eCur, eMax, ePull, eInc, eExp, eShare, eSent, eRec = spGetTeamResources(myTeamID, "energy")
	local mCur, mMax, mPull, mInc, mExp, mShare, mSent, mRec = spGetTeamResources(myTeamID, "metal")
	pAI_econ = {
		aveEInc = 0,
		aveMInc = 0,
		aveActiveBP = 0,
		energyToMetalRatio = 0,
		activeBpToMetalRatio = 0,
		[0] = {
			eCur = eCur, eMax = eMax, ePull = ePull, eInc = eInc,
			mCur = mCur, mMax = mMax, mPull = mPull, mInc = mInc,
		},
		[1] = {
			eCur = eCur, eMax = eMax, ePull = ePull, eInc = eInc,
			mCur = mCur, mMax = mMax, mPull = mPull, mInc = mInc,
		},
		[2] = {
			eCur = eCur, eMax = eMax, ePull = ePull, eInc = eInc,
			mCur = mCur, mMax = mMax, mPull = mPull, mInc = mInc,
		},
		[3] = {
			eCur = eCur, eMax = eMax, ePull = ePull, eInc = eInc,
			mCur = mCur, mMax = mMax, mPull = mPull, mInc = mInc,
		},
		--
		base = {},
		factory = {},
		factory_count = 0,
		commander = {},
		commander_count = 0,
		builder = {},
		builder_count = 0,
		extractor = {},
		extractor_count = 0,
		energy = {},
		energy_count = 0,
		caretaker = {},
		caretaker_count = 0,
		retreat = {},
		overdrive = {},
	}
  
	local units = spGetTeamUnits(myTeamID)
	for i=1,#units do
		local unitID = units[i]
		local unitDefID = spGetUnitDefID(unitID)
		local teamID = spGetUnitTeam(unitID)
		if EcoDefs[unitDefID] then
			ecoUnit[unitID] = true
			if OnDefaultDefs[unitDefID] then
				pAI_SwitchControl(unitID, unitDefID, OnDefaultDefs[unitDefID])
			end
		end
		widget:UnitCreated(unitID, unitDefID, teamID)
		local _,_,_,_,build = spGetUnitHealth(unitID)
		if build == 1 then -- will catch reverse build, UnitFinished will not ever be called for this unit
			widget:UnitFinished(unitID, unitDefID, teamID)
		end
	end
	local units = spGetAllUnits()
	for i=1,#units do
		local unitID = units[i]
		if not(spIsUnitAllied(unitID)) then
			local teamID = spGetUnitTeam(unitID)
			widget:UnitEnteredLos(unitID, teamID)
		end
	end
	
	-- very good code from defenseRange
	for uDefID, uDef in pairs(UnitDefs) do
		wepRanges[uDefID] = {}
		local weapons = uDef.weapons
		local entryIndex = 0
		for weaponIndex=1, #weapons do
			local weaponRange = wDefs[weapons[weaponIndex].weaponDef].range -- take the value of 'range' in each 'weapons' in 'weaponDefs'
			if (weaponRange > 32) then -- many 'fake' weapons have <= 16 range. ->Up to 32 for outlaw.
				entryIndex = entryIndex + 1
				wepRanges[uDefID][entryIndex] = weaponRange
			end
		end
	end
	
	-- allies
	local myAllyTeam = spGetMyAllyTeamID()
	for _,t in pairs(spGetTeamList()) do
		if myAllyTeam == select(6,spGetTeamInfo(t)) then
			myTeamIDs[t] = true
		end
	end
	
	if (spGetGameFrame() > 1) then
		ReInit(true)
	end
	
	widgetHandler:RegisterGlobal("unitDiedInLos", AnnouncerUnitDestroyed)
end

function widget:Shutdown()
	widgetHandler:DeregisterGlobal("unitDiedInLos", AnnouncerUnitDestroyed)
end

function widget:GameStart()
	ReInit(false)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------