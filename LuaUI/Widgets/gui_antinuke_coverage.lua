
function widget:GetInfo()
	return {
		name      = "Antinuke Coverage",
		desc      = "Displays antinuke coverage of enemies and allies. Takes antinuke shadow into account.",
		author    = "Google Frog",
		date      = "Dec 10, 2009", --updated May 3, 2015
		license   = "GNU GPL v2",
		layer     = 0,
		enabled   = true
	}
end


--------------------------------------------------------------------------------
-- Config
--------------------------------------------------------------------------------

local nukeDefs = {}
local intDefs = {}

for unitDefID, ud in pairs(UnitDefs) do
	if ud.customParams.is_nuke then
		nukeDefs[unitDefID] = true
	end

	if ud.customParams.nuke_coverage then
		intDefs[unitDefID] = {
			range = ud.customParams.nuke_coverage,
			static = ud.isImmobile,
			oddX = (ud.xsize % 4) * 4,
			oddY = (ud.zsize % 4) * 4,
		}
	end
end

--------------------------------------------------------------------------------
-- Globals
--------------------------------------------------------------------------------

local GetNukeIntercepted = VFS.Include("LuaRules/Gadgets/Include/GetNukeIntercepted.lua", nil, VFS.GAME)

local enemyInt = {}
local enemyNuke = {}

local allyInt = {}
local allyNuke = {}

local specUnit = {}

local spectating = Spring.GetSpectatingState()
local myTeamID = Spring.GetMyTeamID()
local myAllyTeamID = Spring.GetMyAllyTeamID()
local rangeFudgeMargin = 0

--------------------------------------------------------------------------------
-- Unit handling
--------------------------------------------------------------------------------

local function AddSpecUnit(unitID, unitDefID)
	if intDefs[unitDefID] or nukeDefs[unitDefID] then
		specUnit[unitID] = true
	end
end

local function AddUnit(unitID, unitDefID, intMap, nukeMap)
	if intDefs[unitDefID] then
	
		if intMap[unitID] then
			return
		end
		
		local def = intDefs[unitDefID]
		local _,_,inBuild = Spring.GetUnitIsStunned(unitID)
		
		intMap[unitID] = {
			range = def.range,
			static = def.static,
			incomplete = inBuild,
		}
		
		if def.static then
			local x,_,z = Spring.GetUnitPosition(unitID)
			intMap[unitID].x = x
			intMap[unitID].z = z
		end
	elseif nukeDefs[unitDefID] then
	
		if nukeMap[unitID] then
			return
		end
		
		local _,_,inBuild = Spring.GetUnitIsStunned(unitID)
		local x,y,z = Spring.GetUnitPosition(unitID)
		nukeMap[unitID] = {
			x = x,
			y = y,
			z = z,
			incomplete = inBuild,
		}
	end
end

local function RemoveUnit(unitID)
	enemyInt[unitID] = nil
    enemyNuke[unitID] = nil
    allyInt[unitID] = nil
	allyNuke[unitID] = nil
	specUnit[unitID] = nil
end

local function ReaddUnits()
	enemyInt = {}
	enemyNuke = {}
	allyInt = {}
	allyNuke = {}
	specUnit = {}
	local units = Spring.GetAllUnits()
	for i=1,#units do
		local unitID = units[i]
		local unitDefID = Spring.GetUnitDefID(unitID)
		if spectating then
			AddSpecUnit(unitID, unitDefID)
		else
			local allyTeam = Spring.GetUnitAllyTeam(unitID)
			if allyTeam == myAllyTeamID then
				AddUnit(unitID, unitDefID, allyInt, allyNuke)
			else
				AddUnit(unitID, unitDefID, enemyInt, enemyNuke)
			end
		end
	end
end

function widget:UnitEnteredLos(unitID, unitTeam)
	if not Spring.AreTeamsAllied(myTeamID, unitTeam) and not spectating then
		local unitDefID = Spring.GetUnitDefID(unitID)
		AddUnit(unitID, unitDefID, enemyInt, enemyNuke)
	end
end

function widget:UnitCreated(unitID, unitDefID, unitTeam)
	if spectating then
		AddSpecUnit(unitID, unitDefID)
		local allyTeam = Spring.GetUnitAllyTeam(unitID)
		if allyTeam == myAllyTeamID then
			AddUnit(unitID, unitDefID, allyInt, allyNuke)
		else
			AddUnit(unitID, unitDefID, enemyInt, enemyNuke)
		end
	else
		if Spring.AreTeamsAllied(myTeamID, unitTeam) then
			AddUnit(unitID, unitDefID, allyInt, allyNuke)
		end
	end
end

function widget:UnitFinished(unitID, unitDefID, unitTeam)
	if allyInt[unitID] then
		allyInt[unitID].incomplete = false
	elseif allyNuke[unitID] then
		allyNuke[unitID].incomplete = false
	elseif enemyInt[unitID] then
		enemyInt[unitID].incomplete = false
	elseif enemyNuke[unitID] then
		enemyNuke[unitID].incomplete = false
	end
end

function widget:UnitDestroyed(unitID, unitTeam, unitAllyTeam)
	RemoveUnit(unitID)
end

-- Game frame is used to check whether an enemy unit should be treated as dead.
-- Also updates spectating state.
function widget:GameFrame(n)
	if n%15 ~= 3 or spectating then
		return
	end

	for unitID, def in pairs(enemyInt) do
		local inLos = (not def.static) or select(2, Spring.GetPositionLosState(def.x, 0, def.z))
		if Spring.GetUnitDefID(unitID) then
			if def.incomplete then
				local _,_,inBuild = Spring.GetUnitIsStunned(unitID)
				if not inBuild then
					def.incomplete = false
				end
			end
		else
			if inLos then
				enemyInt[unitID] = nil
			end
		end
	end
	
	for unitID, def in pairs(enemyNuke) do
		local inLos = select(2, Spring.GetPositionLosState(def.x, 0, def.z))
		if Spring.GetUnitDefID(unitID) then
			if def.incomplete then
				local _,_,inBuild = Spring.GetUnitIsStunned(unitID)
				if not inBuild then
					def.incomplete = false
				end
			end
		else
			if inLos then
				enemyNuke[unitID] = nil
			end
		end
	end
	
	local newSpec = Spring.GetSpectatingState()
	if newSpec ~= spectating then
		spectating = newSpec
		ReaddUnits()
	end
end

-- Sorts the spectator units into their correct ally or enemy lists from the point
-- of view of a particular ally team.
local function SortUnitsIntoAllyEnemy(teamID, matchAllyTeam)
	myAllyTeamID = matchAllyTeam
	myTeamID = teamID
	for unitID,_ in pairs(specUnit) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		local allyTeam = Spring.GetUnitAllyTeam(unitID)
		if allyTeam == matchAllyTeam then
			enemyInt[unitID] = nil
			enemyNuke[unitID] = nil
			AddUnit(unitID, unitDefID, allyInt, allyNuke)
		else
			allyInt[unitID] = nil
			allyNuke[unitID] = nil
			AddUnit(unitID, unitDefID, enemyInt, enemyNuke)
		end
	end
end

-- Add All Units
function widget:Initialize()
	ReaddUnits()
end

--------------------------------------------------------------------------------
-- Decide what to draw
--------------------------------------------------------------------------------
local spTraceScreenRay		= Spring.TraceScreenRay
local spGetMouseState       = Spring.GetMouseState
local spGetActiveCommand 	= Spring.GetActiveCommand
local spGetGroundHeight		= Spring.GetGroundHeight
local spGetUnitPosition     = Spring.GetUnitPosition
local spGetFeaturePosition  = Spring.GetFeaturePosition
local spGetFeatureDefID     = Spring.GetFeatureDefID

local nukeSelected
local antinukeSelected

local drawAnti
local drawNuke

-- Keep track of selected units (draw when nukes or antinukes are selected)
function widget:SelectionChanged(newSelection)
	nukeSelected = false
	antinukeSelected = false
	for i = 1, #newSelection do
		local unitID = newSelection[i]
		local unitDefID = Spring.GetUnitDefID(unitID)
		if unitDefID then
			if nukeDefs[unitDefID] then
				if spectating then
					SortUnitsIntoAllyEnemy(Spring.GetUnitTeam(unitID), Spring.GetUnitAllyTeam(unitID))
				end
				local x,y,z = Spring.GetUnitWeaponVectors(unitID, 1)
				nukeSelected = {x,y,z}
				return
			elseif intDefs[unitDefID] then
				if spectating then
					SortUnitsIntoAllyEnemy(Spring.GetUnitTeam(unitID), Spring.GetUnitAllyTeam(unitID))
				end
				antinukeSelected = true
				return
			end
		end
	end
end

local function DrawAntinukeOnMouse(cmdID)
	if not (cmdID and intDefs[-cmdID] and intDefs[-cmdID].static) then
		return false
	end
	
	drawAnti = true
	return not spectating
	-- Code for doing drawing based on placement position
	
	--local def = intDefs[-cmdID]
	--
	--local mx, my = spGetMouseState()
	--local _, mouse = spTraceScreenRay(mx, my, true, true)
	--
	--if mouse then
	--	local x,z
	--	local facing = Spring.GetBuildFacing()
	--	if facing == 1 or facing == 3 then
	--		x = math.floor((mouse[1] + 8 - def.oddX)/16)*16 + def.oddX
	--		z = math.floor((mouse[3] + 8 - def.oddZ)/16)*16 + def.oddZ
	--	else
	--		x = math.floor((mouse[1] + 8 - def.oddZ)/16)*16 + def.oddZ
	--		z = math.floor((mouse[3] + 8 - def.oddX)/16)*16 + def.oddX
	--	end
	--
	--	if drawAnti and drawAnti ~= true then
	--		drawAnti.x = x
	--		drawAnti.y = spGetGroundHeight(x, z)
	--		drawAnti.z = z
	--		drawAnti.range = def.range
	--	else
	--		drawAnti = {
	--			x = x,
	--			y = spGetGroundHeight(x, z),
	--			z = z,
	--			range = def.range
	--		}
	--	end
	--	return true
	--end
	--return false
end

local function GetMouseTargetPosition()
	local mx, my = spGetMouseState()
	local targetType, target = spTraceScreenRay(mx, my, false, true, false, true)
	rangeFudgeMargin = 0
	if targetType == "ground" then
		-- Even though nuke is not water-capable, this traces the ray through water to the sea-floor.
		-- That's what the attack-ground order will do if you click on water, so we have to match it.
		return {target[1], target[2], target[3]}
	elseif targetType == "unit" then
		-- Target coordinate is the center of target unit.
		return {spGetUnitPosition(target)}
	elseif targetType == "feature" then
		-- Target is the exact point where the mouse-ray hits the feature's colvol.
		-- FIXME But TraceScreenRay doesn't tell us that point, so we have to approximate.
		rangeFudgeMargin = FeatureDefs[spGetFeatureDefID(target)].radius
		return {spGetFeaturePosition(target)}
	else
		return nil
	end
end

local function DrawNukeOnMouse(cmdID)
	if cmdID ~= CMD.ATTACK then
		return false
	end
	
	local mouse = GetMouseTargetPosition()
	if not mouse then
		return false
	end
	
	if drawNuke and drawNuke ~= true then
		drawNuke.pos = nukeSelected
		drawNuke.mouse = mouse
	else
		drawNuke = {
			pos = nukeSelected,
			mouse = mouse,
		}
	end
	return true
end

-- Decide what to draw
function widget:Update()
	local _, cmdID = spGetActiveCommand()

	if not DrawAntinukeOnMouse(cmdID) then
		drawAnti = antinukeSelected
	end

	if not (nukeSelected and not drawAnti and DrawNukeOnMouse(cmdID)) then
		drawNuke = false
	end
end

--------------------------------------------------------------------------------
-- Drawing
--------------------------------------------------------------------------------
local glColor               = gl.Color
local glLineWidth           = gl.LineWidth
local glDrawGroundCircle    = gl.DrawGroundCircle
local glBeginEnd            = gl.BeginEnd
local glVertex              = gl.Vertex
local glPopMatrix           = gl.PopMatrix
local glPushMatrix          = gl.PushMatrix
local glTranslate           = gl.Translate
local glScale				= gl.Scale
local glRotate				= gl.Rotate
local glLoadIdentity		= gl.LoadIdentity
local glLighting            = gl.Lighting

local GL_LINES              = GL.LINES

local mapX = Game.mapSizeX
local mapZ = Game.mapSizeZ

local function VertexList(point)
	for i = 1, #point do
		glVertex(point[i])
	end
end

local function DrawEnemyInterceptors(inMinimap)
	local px, pz = drawNuke.pos[1], drawNuke.pos[3]
	local mx, mz = drawNuke.mouse[1], drawNuke.mouse[3]

	local intercepted = 0
	glLineWidth(2)
	
	for unitID, def in pairs(enemyInt) do

		local ux, uz
		if def.static then
			ux, uz = def.x, def.z
		else
			ux,_,uz = Spring.GetUnitPosition(unitID)
		end
		
		if ux then
			local thisIntercepted = GetNukeIntercepted(ux, uz, px, pz, mx, mz, (def.range + rangeFudgeMargin)^2)
			if thisIntercepted then
				if def.incomplete then
					intercepted = math.max(intercepted, 1)
					glColor(0.9, 0.5, 0, 1)
				else
					intercepted = 2
					glColor(1, 0, 0, 1)
				end
			else
				if def.incomplete then
					glColor(0.35, 0.6, 0.4, 1)
				else
					glColor(0, 1, 0, 1)
				end
			end
			
			if inMinimap then
				gl.Utilities.DrawCircle(ux, uz, def.range)
			else
				glDrawGroundCircle(ux, 0, uz, def.range, 40 )
			end
		end
	end
	
	return intercepted
end

local function DrawAllyInterceptors(inMinimap)
	glLineWidth(2)
	for unitID, def in pairs(allyInt) do
		
		if def.incomplete then
			glColor(0.35, 0.6, 0.4, 1)
		else
			glColor(0, 1, 0, 1)
		end
		
		local ux, uz
		if def.static then
			ux, uz = def.x, def.z
		else
			ux,_,uz = Spring.GetUnitPosition(unitID)
		end
		
		if ux then
			if inMinimap then
				gl.Utilities.DrawCircle(ux, uz, def.range)
			else
				glDrawGroundCircle(ux, 0, uz, def.range, 40 )
			end
		end
	end
end


local function Draw()
	
	if drawNuke then
		local intercepted = DrawEnemyInterceptors()
		local vertices = {drawNuke.pos, drawNuke.mouse}
  
		if intercepted == 2 then
			glColor(1,0,0,1)
		elseif intercepted == 1 then
			glColor( 0.9, 0.5, 0, 1)
		else
			glColor(0,1,0,1)
		end
		
		glLineWidth(2)
		glBeginEnd(GL_LINES, VertexList, vertices)
		
		glLineWidth(1)
		glColor(1, 1, 1, 1)
		
	elseif drawAnti then
		
		DrawAllyInterceptors()
		glLineWidth(1)
		glColor(1, 1, 1, 1)
	end
end


local function DrawMinimap(minimapX, minimapY)
	if drawNuke then
		glPushMatrix()
		glTranslate(0,minimapY,0)
		glScale(minimapX/mapX, -minimapY/mapZ, 1)
		
		DrawEnemyInterceptors(true)
		
		glLineWidth(1)
		glColor(1, 1, 1, 1)
		
		glPopMatrix()
	elseif drawAnti then
		glPushMatrix()
		glTranslate(0,minimapY,0)
		glScale(minimapX/mapX, -minimapY/mapZ, 1)
		
		DrawAllyInterceptors(true)
		glLineWidth(1)
		glColor(1, 1, 1, 1)
		
		glPopMatrix()
	end
end

function widget:DrawInMiniMap(minimapX, minimapY)
	DrawMinimap(minimapX, minimapY)
end

function widget:DrawWorldPreUnit()
	Draw()
end
