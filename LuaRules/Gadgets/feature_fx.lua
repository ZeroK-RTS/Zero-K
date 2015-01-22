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
    desc      = "Does effects related to feature life and death",
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

local CEG_SPAWN = [[feature_poof_spawner]];

function gadget:FeatureDestroyed(id, allyTeam)
	local _,_,_,x,y,z = spGetFeaturePosition(id, true);
	local r = spGetFeatureRadius(id);
	
	spSpawnCEG( CEG_SPAWN,
		x,y,z,
		0,0,0,
		1+r, 1+r
	);

	--This could be used to later play sounds without betraying events or positions of destroyed features
	--SendToUnsynced("feature_destroyed", x, y, z);
end
