--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
   return {
      name      = "Blocking Tag Implementation",
      desc      = "Implements the blocking tag correctly.",
      author    = "Google Frog",
      date      = "3 Nov 2013",
      license   = "GNU GPL, v2 or later",
      layer     = 0,
      enabled   = true
   }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--SYNCED
if (not gadgetHandler:IsSyncedCode()) then
   return false
end

local spGetFeatureBlocking = Spring.GetFeatureBlocking
local spSetFeatureBlocking = Spring.SetFeatureBlocking
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:FeatureCreated(featureID)
	local blocking = spGetFeatureBlocking(featureID)
	if not blocking then
		spSetFeatureBlocking(featureID,
			false, -- isBlocking
			false, -- isSolidObjectCollidable
			false, -- isProjectileCollidable
			false, -- isRaySegmentCollidable
			false, -- crushable
			false, -- blockEnemyPushing
			false -- blockHeightChanges
		)
	end
end
