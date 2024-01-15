if gadgetHandler:IsSyncedCode() then
	return false
end

function gadget:GetInfo() return {
	name    = "test Script.LuaUI",
	layer   = 0,
	enabled = true,
} end

function gadget:GamePreload()
	Spring.Echo("CollectGarbage available?", Script.LuaUI('CollectGarbage'))
	Script.LuaUI.CollectGarbage()

	Spring.Echo("Explosion available?", Script.LuaUI('Explosion'))
	Script.LuaUI.Explosion()

	Spring.Echo("trololo available?", Script.LuaUI('trololo'))
	Script.LuaUI.trololo()

	Spring.Echo("UnitCreated available?", Script.LuaUI('UnitCreated'))
	Script.LuaUI.UnitCreated(123) -- will error but that's fine, we just need to know if it ran
end
