--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Engine Taskbar Stuff",
    desc      = 'Icon, name',
    author    = "KingRaptor",
    date      = "13 July 2011",
    license   = "Public Domain",
    layer     = -math.huge,
    enabled   = true,
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if (gadgetHandler:IsSyncedCode()) then
  return false  --  silent removal
end

function gadget:Initialize()
	local name = Game.modName
	Spring.SetWMIcon("LuaUI/Images/ZK_logo.png")
	--Spring.SetWMCaption(name .. " (Spring " .. Spring.Utilities.GetEngineVersion() .. ")", name)
	Spring.SetWMCaption("Zero-K", "Zero-K")
	gadgetHandler:RemoveGadget()
end