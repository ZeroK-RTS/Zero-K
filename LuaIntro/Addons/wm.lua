
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
	local name = Game.modName
	Spring.SetWMIcon("LuaUI/Images/ZK_logo.png")
	Spring.SetWMCaption(name .. " (Spring " .. Game.version .. ")", name)
end