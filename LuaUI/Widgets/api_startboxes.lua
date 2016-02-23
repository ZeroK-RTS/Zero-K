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

VFS.Include ("LuaRules/Utilities/startbox_utilities.lua")

local startBoxConfig = ParseBoxes()

WG.startBoxConfig = startBoxConfig