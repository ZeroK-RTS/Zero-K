--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Feature Effects",
    desc      = "Spawns and plays various effects related to feature life and death",
    author    = "Anarchid",
    date      = "January 2015",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

local spSpawnCEG = Spring.SpawnCEG;
local spGetFeaturePosition     = Spring.GetFeaturePosition;
local spGetFeatureResources    = Spring.GetFeatureResources;
local spGetFeatureRadius       = Spring.GetFeatureRadius;

local CEG_SPAWN = [[feature_poof]];

function gadget:FeatureDestroyed(id, allyTeam)
	local x,y,z = spGetFeaturePosition(id);
	local r = spGetFeatureRadius(id);
	
	spSpawnCEG( CEG_SPAWN,
		x,y,z,
		0,0,0,
		1+r, 1+r
	);

	--SendToUnsynced("feature_destroyed", x, y, z);
end
