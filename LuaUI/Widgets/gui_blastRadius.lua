include("keysym.lua")

function widget:GetInfo()
	return {
		name      = "Blast Radius",
		desc      = "Displays death blast radius of selected units (hold Space+X) and while placing buildings (hold Space)",
		author    = "very_bad_soldier",
		date      = "April 7, 2009",
		license   = "GNU GPL v2",
		layer     = 0,
		enabled   = true
	}
end

--These can be modified if needed
local blastCircleDivs = 64
local blastLineWidth = 2.0
local blastAlphaValue = 0.5

--------------------------------------------------------------------------------
local blastColor = { 1.0, 0.0, 0.0 }

local expCycleDir = false
local expCycleTime = 0.5

-------------------------------------------------------------------------------

local udefTab				= UnitDefs
local weapNamTab			= WeaponDefNames
local weapTab				= WeaponDefs

local spGetActiveCommand 	= Spring.GetActiveCommand
local spGetKeyState         = Spring.GetKeyState
local spGetModKeyState      = Spring.GetModKeyState
local spGetSelectedUnits    = Spring.GetSelectedUnits
local spGetUnitDefID        = Spring.GetUnitDefID
local spGetUnitPosition     = Spring.GetUnitPosition
local spGetGameSeconds      = Spring.GetGameSeconds
local spGetActiveCmdDesc 	= Spring.GetActiveCmdDesc
local spGetMouseState       = Spring.GetMouseState
local spTraceScreenRay      = Spring.TraceScreenRay
local spEcho                = Spring.Echo
local spGetBuildFacing	    = Spring.GetBuildFacing
local spPos2BuildPos        = Spring.Pos2BuildPos

local glColor               = gl.Color
local glLineStipple         = gl.LineStipple
local glLineWidth           = gl.LineWidth
local glTexture             = gl.Texture
local glDrawGroundCircle    = gl.DrawGroundCircle
local glPopMatrix           = gl.PopMatrix
local glPushMatrix          = gl.PushMatrix
local glTranslate           = gl.Translate
local glBillboard           = gl.Billboard
local glText                = gl.Text

local max					= math.max
local min					= math.min
local sqrt					= math.sqrt
local lower                 = string.lower
local floor                 = math.floor

-----------------------------------------------------------------------------------
local alwaysDisplay = {
	[UnitDefNames.energyfusion.id] = true,
	[UnitDefNames.energysingu.id] = true,
	[UnitDefNames.staticcon.id] = true,
	[UnitDefNames.staticnuke.id] = true,
	[UnitDefNames.energygeo.id] = true,
}

-----------------------------------------------------------------------------------

function widget:DrawWorld()
	glLineStipple(true)
	glLineWidth(blastLineWidth)

	DrawBuildMenuBlastRange()
	
	--hardcoded: meta + X
	local keyPressed = spGetKeyState( KEYSYMS.X )
	local alt,ctrl,meta,shift = spGetModKeyState()
		
	if (meta and keyPressed) then
		DrawBlastRadiusSelectedUnits()
	end

	glColor(1, 1, 1, 1)
	glLineWidth(1)
	glTexture(false)
	glLineStipple(false)
end

function widget:Update(timediff)
	--cycle red/yellow
	local addValueExp = timediff/ expCycleTime

	if ( blastColor[2] >= 1.0 ) then
		expCycleDir = false
	elseif ( blastColor[2] <= 0.0 ) then
		expCycleDir = true
	end

	if ( expCycleDir == false) then
		blastColor[2] = blastColor[2] - addValueExp
		blastColor[2] = max( 0.0, blastColor[2] )
	else
		blastColor[2] = blastColor[2] + addValueExp
		blastColor[2] = min( 1.0, blastColor[2] )
	end
end

local function DrawRadiusOnUnit(centerX, height, centerZ, blastRadius, text, invert)
	local g = blastColor[2]
	if invert then
		g = 1 - g
	end
	glColor( blastColor[1], g, blastColor[3], blastAlphaValue)

	--draw static ground circle
	glDrawGroundCircle(centerX, 0, centerZ, blastRadius, blastCircleDivs )
	glPushMatrix()

	glTranslate(centerX , height, centerZ)
	glTranslate(-blastRadius / 2, 0, blastRadius / 2 )
	glBillboard()
	glText(text, 0.0, 0.0, sqrt(blastRadius), "cn")
	glPopMatrix()
end

function DrawBuildMenuBlastRange()
	--check if valid command
	local idx, cmd_id, cmd_type, cmd_name = spGetActiveCommand()
	
	if (not cmd_id) then return end
	
	--check if META is pressed
	local alt,ctrl,meta,shift = spGetModKeyState()
		
	if ( not meta ) and not (alwaysDisplay[-cmd_id]) then --and keyPressed) then
		return
	end
	
	--check if build command
	local cmdDesc = spGetActiveCmdDesc( idx )
	
	if ( cmdDesc["type"] ~= 20 ) then
		--quit here if not a build command
		return
	end
	
	local unitDefID = -cmd_id
		
	local udef = udefTab[unitDefID]
	local morphdef = UnitDefs[unitDefID].customParams.morphto and UnitDefNames[UnitDefs[unitDefID].customParams.morphto]
	local baseExplosionDef = weapNamTab[lower(udef["deathExplosion"])]
	local morphExplosionDef = morphdef and weapNamTab[lower(morphdef["deathExplosion"])]
	if not (baseExplosionDef or morphExplosionDef) then
		return
	end
	
	local mx, my = spGetMouseState()
	local _, coords = spTraceScreenRay(mx, my, true, true)
	
	if not coords then return end
		
	local centerX = coords[1]
	local centerZ = coords[3]
		
	centerX, _, centerZ = spPos2BuildPos( unitDefID, centerX, 0, centerZ, spGetBuildFacing() )
	local height = Spring.GetGroundHeight(centerX,centerZ)
	
	if baseExplosionDef then
		local blastRadius = baseExplosionDef.damageAreaOfEffect
		local damage = baseExplosionDef.customParams.stats_damage
		local text = "Damage: " .. floor(damage)
		if baseExplosionDef.paralyzer then
			text = text .. " (EMP)"
		end
		DrawRadiusOnUnit(centerX, height, centerZ, blastRadius, text, false)
	end
	if morphExplosionDef and morphExplosionDef.id ~= baseExplosionDef.id then
		local blastRadius = morphExplosionDef.damageAreaOfEffect
		local defaultDamage = morphExplosionDef.customParams.stats_damage
		local text = "Damage (upgraded): " .. floor(defaultDamage)
		if morphExplosionDef.paralyzer then
			text = text .. " (EMP)"
		end
		DrawRadiusOnUnit(centerX, height, centerZ, blastRadius, text, true)
	end
end

function DrawUnitBlastRadius( unitID )
	local unitDefID = spGetUnitDefID(unitID)
	local udef = udefTab[unitDefID]
	local weaponDef = weapNamTab[lower(udef["selfDExplosion"])]
	if not weaponDef then
		return
	end

	local x, y, z = spGetUnitPosition(unitID)
	local blastRadius = weaponDef.damageAreaOfEffect
	local height = Spring.GetGroundHeight(x, z)
	local text = "Damage: " .. floor(weaponDef.customParams.stats_damage)
	if weaponDef.paralyzer then
		text = text .. " (EMP)"
	end

	glColor(blastColor[1], blastColor[2], blastColor[3], blastAlphaValue)
	glDrawGroundCircle(x, y, z, blastRadius, blastCircleDivs)

	glPushMatrix()
	glTranslate(x - blastRadius / 2, height, z + blastRadius / 2)
	glBillboard()
	glText(text, 0.0, 0.0, sqrt(blastRadius) , "cn")
	glPopMatrix()
end

function DrawBlastRadiusSelectedUnits()
	local units = spGetSelectedUnits()
	for i,unitID in ipairs(units) do
		DrawUnitBlastRadius( unitID )
	end
end
