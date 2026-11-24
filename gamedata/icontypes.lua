--placed in LuaUI so widgets can read it
local icontypes = VFS.Include("LuaUI/Configs/icontypes.lua")

for name, icon in pairs(icontypes) do
	if string.find(name, "_hidden$") then
		local empty = {}
		for key, value in pairs(icon) do
			empty[key] = value
		end
		empty.bitmap = "LuaUI/Images/resbar/empty.png"
		if name == "default_hidden" then
			empty.radiusadjust = nil -- The engine never scales the default icon by unit radius.
		end
		icontypes[name] = empty
	end
end

return icontypes
