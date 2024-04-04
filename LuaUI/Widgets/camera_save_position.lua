function widget:GetInfo()
	return {
		name      = "Camera Save Position",
		desc      = "Adds hotkeys for saving and recalling camera position.",
		author    = "GoogleFrog",
		date      = "19 September 2020",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = true,
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

include("Widgets/COFCTools/ExportUtilities.lua")

local myPlayerID = Spring.GetMyPlayerID()
local myTeamID = Spring.GetMyTeamID()

local lastDamageX, lastDamageY, lastDamageZ
local lastMarkX, lastMarkY, lastMarkZ
local lastAlertX, lastAlertY, lastAlertZ
local zoomTime = 0
local recallTime = 0
local savedCameraPositions = {}
local savedCameraStates = {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

i18nPrefix = 'camerasaveposition_'
options_path = 'Hotkeys/Camera/Camera Position Hotkeys'
options_order = {'lbl_alert', 'zoom_speed', 'zoomAlert', 'zoomDamage', 'zoomMessage', 'lbl_pos', 'savezoom', 'pos_zoom_speed', 'recallStartPos'}
options = {
	lbl_alert = {
		type = 'label',
	},
	zoom_speed = {
		type = "number",
		value = 0,
		min = 0,
		max = 1,
		step = 0.01,
		OnChange = function(self)
			zoomTime = self.value
		end
	},
	zoomAlert = {
		type = 'button',
		OnChange = function()
			if lastDamageX then
				SetCameraTarget(lastAlertX, lastAlertY, lastAlertZ, zoomTime)
			end
		end
	},
	zoomDamage = {
		type = 'button',
		OnChange = function()
			if lastDamageX then
				SetCameraTarget(lastDamageX, lastDamageY, lastDamageZ, zoomTime)
			end
		end
	},
	zoomMessage = {
		type = 'button',
		OnChange = function()
			if lastMarkX then
				SetCameraTarget(lastMarkX, lastMarkY, lastMarkZ, zoomTime)
			end
		end
	},
	lbl_pos = {
		type = 'label',
	},
	savezoom = {
		type = 'bool',
		value = true,
		noHotkey = true,
	},
	pos_zoom_speed = {
		type = "number",
		value = 0,
		min = 0,
		max = 1,
		step = 0.01,
		OnChange = function(self)
			recallTime = self.value
		end
	},
	recallStartPos = {
		type = 'button',
		OnChange = function()
			local x, y, z = Spring.GetTeamStartPosition(myTeamID)
			if x then
				SetCameraTarget(x, y, z, recallTime)
			end
		end
	},
}

for i = 1, 10 do
	local saveName = "savePos_" .. i
	local recallName = "recallPos_" .. i
	
	options[saveName] = {
		name = "Save Camera Position " .. i,
		type = 'button',
		OnChange = function()
			if options.savezoom.value then
				savedCameraStates[i] = Spring.GetCameraState()
			else
				local cx, cy, cz = Spring.GetCameraPosition()
				savedCameraPositions[i] = {cx, cy, cz}
			end
		end
	}
	options_order[#options_order + 1] = saveName
	
	options[recallName] = {
		name = "Recall Camera Position " .. i,
		type = 'button',
		OnChange = function()
			if options.savezoom.value then
				if savedCameraStates[i] then
					SetCameraState(savedCameraStates[i], recallTime)
				end
			else
				local data = savedCameraPositions[i]
				if data[1] and data[2] and data[3] then
					SetCameraTarget(data[1], data[2], data[3], recallTime)
				end
			end
		end
	}
	options_order[#options_order + 1] = recallName
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:UnitDamaged(unitID, unitDefID, unitTeam, damage)
	if unitTeam ~= myTeamID or (not damage) or (damage < 1) then
		return
	end
	
	lastDamageX, lastDamageY, lastDamageZ = Spring.GetUnitPosition(unitID)
	lastAlertX, lastAlertY, lastAlertZ = lastDamageX, lastDamageY, lastDamageZ
end

function widget:MapDrawCmd(playerID, cmdType, px, py, pz, labeltext)
	if not (cmdType == "point" or cmdType == "label") then
		return
	end
	lastMarkX, lastMarkY, lastMarkZ = px, py, pz
	lastAlertX, lastAlertY, lastAlertZ = px, py, pz
end

function widget:PlayerChanged(playerID)
	if playerID ~= myPlayerID then
		return
	end
	myTeamID = Spring.GetMyTeamID()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
