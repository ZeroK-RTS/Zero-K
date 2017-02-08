
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
	local version = (Game and Game.version) or (Engine and Engine.version) or "Engine version error"
	Spring.SetWMIcon("LuaUI/Images/ZK_logo.png")
	--Spring.SetWMCaption(name .. " (Spring " .. version .. ")", name)
	Spring.SetWMCaption("Zero-K", "Zero-K")
end