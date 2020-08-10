
function gadget:GetInfo()
	return {
		name = "Missile fired callins",
		desc = "Provide missile impact points and ETAs for allies.",
		author = "esainane",
		date = "2020-07",
		license = "GPL v3.0+",
		layer = 0,
		enabled = true
	}
end

--
-- Common code
--
-- Protocol numbers and which missiles to handle are used in both synced and unsynced
local MAGIC_FIRED     = 'missile_fired'
local MAGIC_DESTROYED = 'missile_destroyed'

local trackedMissiles = include("LuaRules/Configs/tracked_missiles.lua")


if gadgetHandler:IsSyncedCode() then
--
-- Synced code, only here to forward to unsynced
--
function gadget:Initialize()
	for weaponDefID in pairs(trackedMissiles) do
		Script.SetWatchProjectile(weaponDefID, true)
	end
end

function gadget:ProjectileCreated(...)
	SendToUnsynced(MAGIC_FIRED, ...)
end

function gadget:ProjectileDestroyed(...)
	SendToUnsynced(MAGIC_DESTROYED, ...)
end

else
--
-- Unsynced code
--

-- Impact ETA is an IMPORTANT FEATURE that is NOT SUNK COST at all
local StarburstPredictPrecache = Spring.Utilities.StarburstPredictPrecache
local StarburstPredict         = Spring.Utilities.StarburstPredict

local spAreTeamsAllied         = Spring.AreTeamsAllied
local spGetMyTeamID            = Spring.GetMyTeamID
local spGetSpectatingState     = Spring.GetSpectatingState
local spGetUnitTeam            = Spring.GetUnitTeam
local scriptMissileFired       = Script.LuaUI.MissileFired
local scriptMissileDestroyed   = Script.LuaUI.MissileDestroyed

local curFrame = -1

local projectilesTracked = {}

local deferredProjectiles = {}
-- ProjectileCreated is too early in a projectile's lifetime to reliably read parameters from
local function ProjectileCreated(...)
	deferredProjectiles[#deferredProjectiles+1] = {...}
end

local function ProjectileCreatedDeferred(proID, proOwnerID, weaponDefID)
	if not trackedMissiles[weaponDefID] then return end
	local teamID = spGetUnitTeam(proOwnerID)
	local spec, specFullView = spGetSpectatingState()
	local isAlly = spAreTeamsAllied(teamID, spGetMyTeamID())

	if not (isAlly or (spec and specFullView)) then
		return
	end

	-- We send MissileDestroyed events for anything that would get a MissileCreated event,
	-- even if there wasn't anything listening for MissileCreated
	projectilesTracked[proID] = true

	if not Script.LuaUI('MissileFired') then
		return
	end

	local rx,ry,rz,rt = StarburstPredict(proID, weaponDefID, curFrame)
	scriptMissileFired(proID, proOwnerID, weaponDefID, rx, ry, rz, rt)

end

local function ProjectileDestroyed(proID)
	if not projectilesTracked[proID] then return end
	if not Script.LuaUI('MissileDestroyed') then return end
	scriptMissileDestroyed(proID)
	projectilesTracked[proID] = nil
end


function gadget:RecvFromSynced(magic, ...)
	if magic == MAGIC_FIRED then
		ProjectileCreated(...)
	elseif magic == MAGIC_DESTROYED then
		ProjectileDestroyed(...)
	else
		return false
	end
	return true
end

function gadget:GameFrame(n)
	curFrame = n
	if #deferredProjectiles == 0 then return end
	for _,deferredArgs in ipairs(deferredProjectiles) do
		ProjectileCreatedDeferred(unpack(deferredArgs))
	end
	deferredProjectiles = {}
end

function gadget:Initialize()
	for weaponDefID in pairs(trackedMissiles) do
		StarburstPredictPrecache(weaponDefID)
	end
end

function gadget:Shutdown()
	if not Script.LuaUI('MissileDestroyed') then return end
	-- don't leave in-flights lying around if we /luarules reload
	for proID in pairs(projectilesTracked) do
		scriptMissileDestroyed(proID)
	end
end


end
