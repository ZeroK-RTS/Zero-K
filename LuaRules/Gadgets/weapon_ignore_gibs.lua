--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function gadget:GetInfo()
	return {
		name = "Ignore Gibs",
		desc = "Makes shrapnel not call ProjectileCreated and ProjectileDestroyed",
		author = "GoogleFrog",
		date = "3 March 2019",
		license = "Public domain",
		layer = 0,
		enabled = true
	}
end

function gadget:Initialize()
	Script.SetWatchWeapon(-1, false)
	gadgetHandler:RemoveGadget()
end
