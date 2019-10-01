
function gadget:GetInfo()
	return {
		name      = "Mantis 6282",
		desc      = "Mantis 6282",
		author    = "GoogleFrog",
		date      = "15 August 2019",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = true  --  loaded by default?
	}
end

if (not gadgetHandler:IsSyncedCode()) then
	return
end

local REVERSE_COMPAT = not Spring.Utilities.IsCurrentVersionNewerThan(104, 1350)

local lastX, lastY, lastZ, lastFeatureDefID, lastGameFrame

local function Close(x1, x2)
	return x1 and x2 and ((x1 - x2 < 0.0001) or (x2 - x1 < 0.0001))
end

function gadget:AllowFeatureCreation(featureDefID, teamID, x, y, z)
	local frame = Spring.GetGameFrame()
	if Close(x, lastX) and Close(y, lastY) and Close(z, lastZ) and featureDefID == lastFeatureDefID and frame == lastGameFrame then
		--Spring.Echo("Blocked", x, y, z, featureDefID, frame, math.random())
		return false
	end
	lastX, lastY, lastZ, lastFeatureDefID, lastGameFrame = x, y, z, featureDefID, frame
	--Spring.Echo("Allowed", x, y, z, featureDefID, frame, math.random())
	return true
end

function gadget:Initialize()
	if not REVERSE_COMPAT then
		gadgetHandler:RemoveGadget()
	end
end
