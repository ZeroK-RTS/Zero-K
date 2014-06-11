--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function widget:GetInfo()
  return {
    name      = "Widget Enabler/Disabler",
    desc      = "Disable or enable a widget once per stable for debugging/fix. Store 'run-once' tag in LUAUI/Configs/widgetdisabler.lua",
    author    = "xponen",
    date      = "2015.06.11",
    license   = "Public Domain",
    layer     = 0, --WARNING: this layer must be LESS than the layer of widget to be auto-enabled or its Chili will crash
	alwaysStart = true, --hide this widget
    enabled   = true --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local configFile = "LuaUI/Configs/zk_widgetdisabler.lua"

function widget:Update()
	Spring.SendCommands("luaui disablewidget ".. "Chili Crude Player List")
	Spring.SendCommands("luaui enablewidget ".. "Chili Deluxe Player List - Alpha 2.02")
	table.save({runOnce = Game.modVersion,}, configFile,"--this ZK file tell a widget auto-enabler/disabler that it have configured user's widget at least once for the following Stable:")
	widgetHandler:RemoveWidget()
end

function widget:Initialize()
	local runOnceInfo = (VFS.FileExists(configFile) and VFS.Include(configFile)) or {}
	Spring.Echo(Game.modVersion)
	if runOnceInfo.runOnce == Game.modVersion or Game.modVersion:find("test") or Game.modVersion:find("$VERSION") then
		Spring.Echo( "Widget Enabler/Disabler: already run once. Widget removed." ) --echo for debugging, because widgetHandler:RemoveWidget() didn't trigger removal message except when it crash.
		widgetHandler:RemoveWidget()
		return
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------