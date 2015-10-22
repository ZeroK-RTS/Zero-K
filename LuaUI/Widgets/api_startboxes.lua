function widget:GetInfo() return {
	name    = "Startbox API",
	desc    = "Processes and exposes startboxes",
	author  = "Sprung",
	layer   = -9001,
	enabled = true,
	api     = true,
	hidden  = true,
} end

if VFS.FileExists("mission.lua") then return end

local startBoxConfig
local mapsideBoxes = "mapconfig/map_startboxes.lua"

VFS.Include ("LuaRules/Utilities/startbox_utilities.lua")

if VFS.FileExists (mapsideBoxes) then
	startBoxConfig = VFS.Include (mapsideBoxes)
	SanitizeBoxes (startBoxConfig)
else
	startBoxConfig = { }
	local startboxString = Spring.GetModOptions().startboxes
	if startboxString then
		local springieBoxes = loadstring(startboxString)()
		for id, box in pairs(springieBoxes) do
			box[1] = box[1]*Game.mapSizeX
			box[2] = box[2]*Game.mapSizeZ
			box[3] = box[3]*Game.mapSizeX
			box[4] = box[4]*Game.mapSizeZ
			startBoxConfig[id] = {
				{box[1], box[2], box[1], box[4], box[3], box[4]}, -- must be counterclockwise
				{box[1], box[2], box[3], box[4], box[3], box[2]}
			}
		end
	end
end

WG.startBoxConfig = startBoxConfig