--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function gadget:GetInfo()
return {
  name      = "Disable Features",
  desc      = "Disable Features",
  author    = "SirMaverick",
  date      = "2009",
  license   = "GPL",
  layer     = 0,
  enabled   = true  --  loaded by default?
  }
end


function gadget:Initialize()
	local modOptions = Spring.GetModOptions()
	if not (modOptions and tobool(modOptions.disablefeatures)) then
		gadgetHandler:RemoveGadget()
	end
end

function gadget:AllowFeatureCreation(featureDefID, teamID, x, y, z)
	return false
end

