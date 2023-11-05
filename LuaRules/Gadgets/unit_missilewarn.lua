
function gadget:GetInfo()
	return {
		name = "Missile fired callins",
		desc = "Provide missile impact points and ETAs for allies.",
		author = "esainane",
		date = "2020-07",
		license = "GPL v2.0+",
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
local u_CHAR = string.byte('u')

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

function gadget:ProjectileCreated(proID, proOwnerID, weaponID)
	if not proOwnerID or proOwnerID == -1 then
		return -- tacnuke nanoframe death is technically launching an ownerless, TTL=0 missile
	end
	SendToUnsynced(MAGIC_FIRED, proID, proOwnerID, weaponID)
end

function gadget:ProjectileDestroyed(proID, proOwnerID, weaponID)
	SendToUnsynced(MAGIC_DESTROYED, proID, proOwnerID, weaponID)
end

else
--
-- Unsynced code
--

-- Impact ETA is an IMPORTANT FEATURE that is NOT SUNK COST at all
include("LuaRules/Gadgets/Include/StarburstPredict.lua")
-- luacheck: read globals StarburstPredictPrecache StarburstPredict

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
local function ProjectileCreated(proID, proOwnerID, weaponID)
	deferredProjectiles[#deferredProjectiles + 1] = {proID, proOwnerID, weaponID}
end

local function ProjectileCreatedDeferred(proID, proOwnerID, weaponDefID)
	if not trackedMissiles[weaponDefID] then
		return
	end
	local teamID = spGetUnitTeam(proOwnerID)
	local myTeamID = spGetMyTeamID()
	if not (teamID and myTeamID) then
		return
	end
	local spec, specFullView = spGetSpectatingState()
	local isAlly = spAreTeamsAllied(teamID, myTeamID)

	if not (isAlly or (spec and specFullView)) then
		return
	end

	-- We send MissileDestroyed events for anything that would get a MissileCreated event,
	-- even if there wasn't anything listening for MissileCreated
	projectilesTracked[proID] = true

	if not Script.LuaUI('MissileFired') then
		return
	end
	
	local rx, ry, rz, rt = StarburstPredict(proID, weaponDefID, curFrame)
	if not rx then
		return
	end
	local targetID = false
	local weaponDefConfig = trackedMissiles[weaponDefID]
	if weaponDefConfig.homing then
		local t, tpos = Spring.GetProjectileTarget(proID)
		if t == u_CHAR then
			targetID = tpos
		end
	end
	if weaponDefConfig.distanceFudge then
		local px, py, pz = Spring.GetProjectilePosition(proID)
		if pz then
			local dist = math.sqrt((rx - px)^2 + (ry - py)^2 + (rz - pz)^2)
			local frame = Spring.GetGameFrame()
			local mult = weaponDefConfig.distanceFudge(dist)
			rt = frame + (rt - frame) * mult
		end
	end
	
	scriptMissileFired(proID, proOwnerID, weaponDefID, rx, ry, rz, rt, targetID)
end

local function ProjectileDestroyed(proID, proOwnerID, weaponID)
	if not projectilesTracked[proID] then
		return
	end
	if not Script.LuaUI('MissileDestroyed') then
		return
	end
	scriptMissileDestroyed(proID, proOwnerID, weaponID)
	projectilesTracked[proID] = nil
end


function gadget:RecvFromSynced(magic, proID, proOwnerID, weaponID)
	if magic == MAGIC_FIRED then
		ProjectileCreated(proID, proOwnerID, weaponID)
	elseif magic == MAGIC_DESTROYED then
		ProjectileDestroyed(proID, proOwnerID, weaponID)
	else
		return false
	end
	return true
end

function gadget:GameFrame(n)
	curFrame = n
	if #deferredProjectiles == 0 then
		return
	end
	for i = 1, #deferredProjectiles do
		local proData = deferredProjectiles[i]
		ProjectileCreatedDeferred(proData[1], proData[2], proData[3])
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
