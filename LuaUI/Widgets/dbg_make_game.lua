--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Load all models",
    desc      = "Loads all models",
    author    = "GoogleFrog",
    date      = "28 November 2016",
    license   = "GNU GPL, v2 or later",
    layer     = 1,
    enabled   = true  --  loaded by default?
  }
end

local ACTIVE = false

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local initialized = false
local index = 1

function widget:Update(dt)
	if not ACTIVE then
		return
	end

	local frame = Spring.GetGameFrame() 
	if (frame > 0 and not initialized) then
		-- Set camera in case different engines have different default locations
		Spring.SetCameraState({
			px = 2872,
			py = 91.71875,
			pz = 4596,
			flipped = -1,
			dx = 0,
			dy = -0.8945,
			dz = -0.4472,
			name = "ta",
			zscale = 0.5,
			height = 3000,
			mode = 1,
		}, 0)
		
		Spring.SelectUnitArray(Spring.GetAllUnits())
		
		Spring.WarpMouse(60, 100)
		extraInitialized = initialized
		initialized = true
	end
	
	if not initialized then
		return
	end

	
end
