if gadgetHandler:IsSyncedCode() then return end

function gadget:GetInfo() return {
	name    = "Sniper bullets only visible to own allyteam",
	layer   = 0,
	enabled = true,
} end

local sniperWeaponDefID = WeaponDefNames.armsnipe_shockrifle.id
local spGetProjectileDefID = Spring.GetProjectileDefID
local spGetProjectileTeamID = Spring.GetProjectileTeamID
local spGetTeamInfo = Spring.GetTeamInfo

local specFullView
local myAllyTeamID

-- all the processing would ideally be cached but unsynced gadgets don't receive ProjectileCreated (yet)
function gadget:DrawProjectile(pID, pass)
	if specFullView then
		return false
	end

	local pWeaponDefID = spGetProjectileDefID(pID)
	if pWeaponDefID ~= sniperWeaponDefID then
		return false
	end

	local teamID = spGetProjectileTeamID(pID)
	local allyTeamID = select(6, spGetTeamInfo(teamID))
	if allyTeamID == myAllyTeamID then
		return false
	end

	return true
end

local function UpdateVariables()
	myAllyTeamID = Spring.GetLocalAllyTeamID()
	specFullView = select(2, Spring.GetSpectatingState())
end

function gadget:Initialize()
	UpdateVariables()
end

function gadget:PlayerChanged()
	UpdateVariables()
end

function gadget:TeamChanged()
	UpdateVariables()
end
