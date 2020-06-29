
if addon.InGetInfo then
  return {
    name      = "WM Stuff",
    desc      = 'Icon, name',
    author    = "KingRaptor",
    date      = "13 July 2011",
    license   = "Public Domain",
    layer     = -math.huge,
    enabled   = true,
  }
end

------------------------------------------
function addon.Initialize()
	-- not putting the version allows detection
	-- by external programs, such as Discord
	Spring.SetWMCaption("Zero-K", "Zero-K")

	Spring.SetWMIcon("LuaUI/Images/ZK_logo.png")
end
