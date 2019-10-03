--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Cloak Fire State 2",
		desc      = "Sets units to Hold Fire when cloaked, reverts to original state when decloaked",
		author    = "KingRaptor (L.J. Lim)",
		date      = "Feb 14, 2010",
		license   = "GNU GPL, v2 or later",
		layer     = -1,
		enabled   = true  --  loaded by default?
	}
end

local enabled = true
local function CheckEnable()
	if Spring.GetSpectatingState() or (not options.enable_cloak_holdfire.value) then
		enabled = false
	else
		enabled = true
	end
end

options_path = 'Settings/Unit Behaviour'
options_order = {'enable_cloak_holdfire'}
options = {
	enable_cloak_holdfire = {
		name = "Hold fire when cloaked",
		type = 'bool',
		value = false,
		noHotkey = true,
		desc = 'Units which cloak will hold fire so as not to reveal themselves.',
		OnChange = CheckEnable,
	},
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Speedups
local GiveOrderToUnit  = Spring.GiveOrderToUnit
local GetUnitDefID     = Spring.GetUnitDefID
local GetUnitIsCloaked = Spring.GetUnitIsCloaked

local STATIC_STATE_TABLE = {0}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local myTeam

local exceptionList = { --add exempt units here
	"cloaksnipe",
	"cloakaa",
	"wolverine_mine",
	"gunshipbomb",
}

local exceptionArray = {}
for _,name in pairs(exceptionList) do
	local ud = UnitDefNames[name]
	if ud then
		exceptionArray[ud.id] = true
	end
end

local cloakUnit = {} --stores the desired fire state when decloaked of each unitID

function widget:UnitCloaked(unitID, unitDefID, teamID)
	if (not enabled) or (teamID ~= myTeam) or exceptionArray[unitDefID] then
		return
	end
	local firestate = Spring.Utilities.GetUnitFireState(unitID)
	cloakUnit[unitID] = firestate --store last state
	if firestate ~= 0 then
		STATIC_STATE_TABLE[1] = 0
		GiveOrderToUnit(unitID, CMD.FIRE_STATE, STATIC_STATE_TABLE, 0)
	end
end

function widget:UnitDecloaked(unitID, unitDefID, teamID)
	if (not enabled) or (teamID ~= myTeam) or exceptionArray[unitDefID] or (not cloakUnit[unitID]) then
		return
	end
	if Spring.Utilities.GetUnitFireState(unitID) == 0 then
		local targetState = cloakUnit[unitID]
		STATIC_STATE_TABLE[1] = targetState
		GiveOrderToUnit(unitID, CMD.FIRE_STATE, STATIC_STATE_TABLE, 0) --revert to last state
		--Spring.Echo("Unit compromised - weapons free!")
	end
	cloakUnit[unitID] = nil
end

function widget:PlayerChanged()
	myTeam = Spring.GetMyTeamID()
	CheckEnable()
end

function widget:Initialize()
	myTeam = Spring.GetMyTeamID()
	CheckEnable()
end

function widget:UnitCreated(unitID, unitDefID, unitTeam)
	if (not enabled) then
		return
	end
	if unitTeam == myTeam then
		cloakUnit[unitID] = Spring.Utilities.GetUnitFireState(unitID)
	else
		cloakUnit[unitID] = nil
	end
end

function widget:UnitGiven(unitID, unitDefID, unitTeam)
	widget:UnitCreated(unitID, unitDefID, unitTeam)
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
	if cloakUnit[unitID] then
		cloakUnit[unitID] = nil
	end
end
