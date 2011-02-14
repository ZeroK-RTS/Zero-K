--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Frameskip Detector",
    desc      = "Bawws if a frame is skipped",
    author    = "KingRaptor",
    date      = "Dec 19, 2007",
    license   = "Public Domain",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


local lastFrame = -1
function widget:GameFrame(n)
	if n ~= lastFrame + 1 then
		Spring.Echo("ERROR: Skipped gameframes "..lastFrame .."to ".. n -1 .. ", current frame: " .. n)
	end
	lastFrame = n
end
