--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name = "GameRules Events",
		desc = "Sets RulesParams to tell widgets what is going on in the game, and tells skirmish AIs the same",
		author = "Google Frog",
		date = "15 August 2015",
		license = "GNU GPL, v2 or later",
		layer = -2, -- Before gadgets whose Explosion can block later ones (exp_nuke_effect_chooser, weapon_trail_burnout)
		enabled = true
	}
end

if gadgetHandler:IsSyncedCode() then
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local globalExplosionNames = include("LuaRules/Configs/globally_visible_explosions.lua")

local globalExplosionPrefix = {}
local globalExplosionList = {}
for weaponDefID, wd in pairs(WeaponDefs) do
	if globalExplosionNames[wd.name] or globalExplosionNames[(wd.name:gsub("^%d+_", ""))] then
		globalExplosionPrefix[weaponDefID] = "GLOBAL_EXPLOSION:" .. wd.name .. ":"
		globalExplosionList[#globalExplosionList + 1] = weaponDefID
	end
end

local function SendAIMessage(msg)
	SendToUnsynced("GameRules_AIMessage", msg)
end

local function PosString(x, y, z)
	return math.floor(x) .. "," .. math.floor(y) .. "," .. math.floor(z)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- The gadget intends to only tell players whether a nuke was launched recently
-- The lack of nuke counting or accurate timing is intentional.

local removeWarningFrame = false

local function GameRules_NukeLaunched()
	local frame = Spring.GetGameFrame()
	Spring.SetGameRulesParam("recentNukeLaunch", 1)
	removeWarningFrame = frame + 150 + 50*math.random()
	SendAIMessage("NUKE_LAUNCHED")
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Zenith and Starlight fire continuously, so instead of a message per explosion
-- AIs are told when their globally visible meteor stream or beam turns on and off.
-- A timeout (in frames) turns it off unless renewed, for weapons without an off state.

local superweaponOn = {} -- unitID -> frame to turn off at, or true

local function GameRules_SetSuperweaponOn(unitID, isOn, timeout)
	local wasOn = superweaponOn[unitID]
	if isOn then
		superweaponOn[unitID] = (timeout and (Spring.GetGameFrame() + timeout)) or true
	else
		superweaponOn[unitID] = nil
	end
	if (not wasOn) == (not isOn) then
		return
	end
	local unitDefID = Spring.GetUnitDefID(unitID)
	local x, y, z = Spring.GetUnitPosition(unitID)
	if unitDefID and x then
		local event = (isOn and "SUPERWEAPON_ON:") or "SUPERWEAPON_OFF:"
		SendAIMessage(event .. UnitDefs[unitDefID].name .. ":" .. PosString(x, y, z))
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:Explosion_GetWantedWeaponDef()
	return globalExplosionList
end

function gadget:Explosion(weaponDefID, px, py, pz)
	if globalExplosionPrefix[weaponDefID] then
		SendAIMessage(globalExplosionPrefix[weaponDefID] .. PosString(px, py, pz))
	end
	return false
end

function gadget:UnitDestroyed(unitID)
	if superweaponOn[unitID] then
		GameRules_SetSuperweaponOn(unitID, false)
	end
end

function gadget:GameFrame(frame)
	if removeWarningFrame and removeWarningFrame < frame then
		Spring.SetGameRulesParam("recentNukeLaunch", 0)
		removeWarningFrame = false
	end
	for unitID, offFrame in pairs(superweaponOn) do
		if offFrame ~= true and offFrame < frame then
			GameRules_SetSuperweaponOn(unitID, false)
		end
	end
end

function gadget:Initialize()
	Spring.SetGameRulesParam("recentNukeLaunch", 0)
	GG.GameRules_NukeLaunched = GameRules_NukeLaunched
	GG.GameRules_SetSuperweaponOn = GameRules_SetSuperweaponOn
	for i = 1, #globalExplosionList do
		Script.SetWatchExplosion(globalExplosionList[i], true)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
else -- UNSYNCED
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function SendAIMessage(_, msg)
	local localPlayer = Spring.GetLocalPlayerID()
	local teamList = Spring.GetTeamList()
	for i = 1, #teamList do
		local teamID = teamList[i]
		local _, _, _, isAI = Spring.GetTeamInfo(teamID, false)
		if isAI then
			local _, _, aiHost = Spring.GetAIInfo(teamID)
			if aiHost == localPlayer then
				Spring.SendSkirmishAIMessage(teamID, msg)
			end
		end
	end
end

function gadget:Initialize()
	gadgetHandler:AddSyncAction("GameRules_AIMessage", SendAIMessage)
end

function gadget:Shutdown()
	gadgetHandler:RemoveSyncAction("GameRules_AIMessage")
end

end
