-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
if (not gadgetHandler:IsSyncedCode()) then
    return
end
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Allow Builder Hold Fire",
    desc      = "Sets whether a builder can fire while doing anything nanolathe related.",
    author    = "Google Frog",
    date      = "22 June 2014",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end



function gadget:AllowBuilderHoldFire(unitID, unitDefID, action)
	return false
end
