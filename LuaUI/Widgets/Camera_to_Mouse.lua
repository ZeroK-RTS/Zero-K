-- Default widget stuff
function widget:GetInfo()
  return {
    name      = "Camera to mouse-pointer",
    desc      = "Camera moves to your mouse-pointer when alt+space is clicked",
    author    = "Tumulten",
    date      = "Mar 4, 2014",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true
  }
end
-- This function is called whenever any key is pressed down
function widget:KeyPress(key, mods, isRepeat, label, unicode)
	-- This function will return boolean which are true or false depending on if that button is pressed down, true if down
	local altDown,ctrlDown,metaDown,shiftDown = Spring.GetModKeyState()
	-- If ctrl and meta buttons are pressed down
	if ctrlDown and metaDown then
			-- We call function MoveCamera
			MoveCamera()
	end
	-- Script ends
end

function MoveCamera()
	-- Camera has 3 coordinate variables
	-- X,Y and Z in that order
	-- X is horizontal
	-- Y is levitation(height)
	-- Z is vertical
	-- Get the cameras current coordinates, split into X,Y,Z
	local camX,camY,camZ = Spring.GetCameraPosition()
	-- Get the mouse coordinates, split into X,Z
	local mouseX,mouseZ = Spring.GetMouseState()
	-- Convert the mouse screen-coordinates into world-coordinates
	local ignore,mouseWorldCord = Spring.TraceScreenRay(mouseX,mouseZ,true)
	-- If the mouse is outside of the map Spring.TraceScreenRay will return nil so we have to check that it is not nil
	if mouseWorldCord ~= nil then
	-- Now the camera can be moved to the new location which is mouseWorldCord X, the cameras height from before (Y) and mouseWorldCord Z
		Spring.SetCameraTarget(mouseWorldCord[1],camY,mouseWorldCord[3], 0)
		
		
		if Spring.GetModUICtrl then
			-- Get the screen resolution
			local screenSizeX, screenSizeY = Spring.GetScreenGeometry() 
			-- This will centre the mouse pointer back to the middle of the screen
			Spring.WarpMouse(screenSizeX/2,screenSizeY/2)
		end
	end
	-- Script goes back up to function KeyPress(the function that called this one)
end