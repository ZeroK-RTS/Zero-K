-- SPDX-License-Identifier: GPL-2.0-or-later
-- Run from the game root with lua5.1 tools/portal_worlds/test_recording_adapter.lua.
local received
gadget = {}
VFS = {Include = function(path, environment)
	assert(path == "tools/portal_worlds/dots/recorder.lua")
	assert(environment.gadget == gadget)
	function gadget:UnitDamaged(...) received = {...} end
end}
assert(loadfile("LuaRules/Gadgets/dbg_portal_recording.lua"))()
gadget:UnitDamaged(101, 102, 103, 104, false, 105, 106, 107, 108, 109)
assert(#received == 8)
assert(received[6] == 105 and received[7] == 109 and received[8] == 106)
gadget:UnitDamaged(101, 102, 103, 104, false, 105, nil, nil, nil, nil)
assert(received[7] == nil and received[8] == nil)
print("Recording callback adapter checks passed")
