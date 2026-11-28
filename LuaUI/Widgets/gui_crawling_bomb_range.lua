function widget:GetInfo()
	return {
		name      = "Crawling Bomb Range",
		desc      = "Draws the explosion radius of allied crawling bombs and of enemy crawling bombs in line of sight.",
		author    = "Claude Code, requested by Sparkezel",
		date      = "2026-11-02",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = false,
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local spGetUnitPosition       = Spring.GetUnitPosition
local spGetUnitDefID          = Spring.GetUnitDefID
local spGetUnitAllyTeam       = Spring.GetUnitAllyTeam
local spGetUnitLosState       = Spring.GetUnitLosState
local spGetUnitIsBeingBuilt   = Spring.GetUnitIsBeingBuilt
local spIsSphereInView        = Spring.IsSphereInView

local glColor            = gl.Color
local glLineWidth        = gl.LineWidth
local glDrawGroundCircle = gl.DrawGroundCircle

local CIRCLE_DIVS = 48
local ALLY_COLOR  = {1, 0.8, 0.2, 0.6}
local ENEMY_COLOR = {1, 0.2, 0.2, 0.7}

-- Ground units that kamikaze. The radius is that of the explosion the context menu shows.
local bombRadius = {}
for unitDefID = 1, #UnitDefs do
	local ud = UnitDefs[unitDefID]
	if ud.canKamikaze and not ud.canFly then
		local weaponDef = WeaponDefNames[ud.customParams.stats_detonate_weapon or ud.deathExplosion:lower()]
		if weaponDef then
			bombRadius[unitDefID] = weaponDef.damageAreaOfEffect
		end
	end
end

local allyBombs = {}
local enemyBombs = {}
local myAllyTeamID, fullView

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function AddUnit(unitID, unitDefID)
	local radius = bombRadius[unitDefID]
	if not radius then
		return
	end
	-- Own, allied and full view units have every LOS bit; enemies need the LOS bit, not only radar.
	local losState = spGetUnitLosState(unitID, nil, true)
	if not (losState and losState % 2 == 1) then
		return
	end
	-- A captured enemy unit gets UnitGiven but no UnitTaken, so clear the other table.
	if spGetUnitAllyTeam(unitID) == myAllyTeamID then
		allyBombs[unitID] = radius
		enemyBombs[unitID] = nil
	else
		enemyBombs[unitID] = radius
		allyBombs[unitID] = nil
	end
end

local function RemoveUnit(unitID)
	allyBombs[unitID] = nil
	enemyBombs[unitID] = nil
end

local function AddAllUnits()
	myAllyTeamID = Spring.GetMyAllyTeamID()
	fullView = select(2, Spring.GetSpectatingState())
	allyBombs = {}
	enemyBombs = {}
	local units = Spring.GetAllUnits()
	for i = 1, #units do
		AddUnit(units[i], spGetUnitDefID(units[i]))
	end
end

function widget:Initialize()
	AddAllUnits()
end

function widget:PlayerChanged()
	if myAllyTeamID ~= Spring.GetMyAllyTeamID() or fullView ~= select(2, Spring.GetSpectatingState()) then
		AddAllUnits()
	end
end

function widget:UnitCreated(unitID, unitDefID)
	AddUnit(unitID, unitDefID)
end

function widget:UnitDestroyed(unitID)
	RemoveUnit(unitID)
end

-- The engine calls UnitTaken before the transfer and UnitGiven or UnitEnteredLos after it.
function widget:UnitTaken(unitID)
	RemoveUnit(unitID)
end

function widget:UnitGiven(unitID, unitDefID)
	AddUnit(unitID, unitDefID)
end

function widget:UnitEnteredLos(unitID)
	AddUnit(unitID, spGetUnitDefID(unitID))
end

function widget:UnitLeftLos(unitID)
	-- In full view the unit only left the LOS of some ally team.
	if not fullView then
		enemyBombs[unitID] = nil
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function DrawBombs(bombs)
	for unitID, radius in pairs(bombs) do
		local x, y, z = spGetUnitPosition(unitID)
		-- A nanoframe does not explode when it dies.
		if spIsSphereInView(x, y, z, radius) and not spGetUnitIsBeingBuilt(unitID) then
			glDrawGroundCircle(x, y, z, radius, CIRCLE_DIVS)
		end
	end
end

function widget:DrawWorldPreUnit()
	glLineWidth(2)
	glColor(ALLY_COLOR)
	DrawBombs(allyBombs)
	glColor(ENEMY_COLOR)
	DrawBombs(enemyBombs)
	glColor(1, 1, 1, 1)
	glLineWidth(1)
end
