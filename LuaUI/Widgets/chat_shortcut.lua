local version = 'v1.01'

function widget:GetInfo()
	return {
		name = "Chat Shortcut",
		desc = version .. " Append chat console with player's names, unit's name, or whisper command using simple mouse button click" ,
		author = "xponen",
		date = "21 February 2012",
		license = "Public domain",
		layer = 0,
		enabled = true
	}
end
--------------------------------------------------------------------------------
-- Spring Function:
local spGetUnitsInRectangle  = Spring.GetUnitsInRectangle
local spGetUnitTeam = Spring.GetUnitTeam 
local spGetTeamInfo  = Spring.GetTeamInfo 
local spGetUnitDefID = Spring.GetUnitDefID
local spGetPlayerInfo  = Spring.GetPlayerInfo 
local spSendCommands = Spring.SendCommands
local spTraceScreenRay = Spring.TraceScreenRay
local spValidUnitID  = Spring.ValidUnitID 
local spGetCameraPosition		= Spring.GetCameraPosition
local tan				= math.tan
local atan				= math.atan
--------------------------------------------------------------------------------
-- Constant:
local pasteCommand = "PasteText "
local whisper = "PasteText /WByNum "
--------------------------------------------------------------------------------
-- Methods:
function widget:MousePress(x, y, button)
	local _, mpos = spTraceScreenRay(x, y, true) --//convert UI coordinate into ground coordinate. Reference: gfx_stereo3d.lua (CarRepairer, jK)
	if mpos == nil then 
		return false
	end
	local _,cy,_= spGetCameraPosition()
	local addedSize = MaintainUnitSize(40, 1000, cy)
	local unit = spGetUnitsInRectangle( mpos[1]-40-addedSize, mpos[3]-40-addedSize, mpos[1]+40+addedSize,mpos[3]+40+addedSize) 
	local unitID = unit[1] --//only take 1st row because since the box is quite small it could only fit 1 unit. 1 unit is a reasonable assumption.
	local validUnitID = spValidUnitID(unitID)
	if validUnitID == false or validUnitID == nil then
		return false
	end
	local teamID = spGetUnitTeam(unitID)
	local _,playerID,_,_,_,_,_,_ = spGetTeamInfo(teamID) --//definition of playerID in this context refer to: http://springrts.com/wiki/Lua_SyncedRead#Player.2CTeam.2CAlly_Lists.2FInfo
	local unitDefID = spGetUnitDefID(unitID)
	local unitDefinition = UnitDefs[unitDefID]
	if unitDefinition == nil then
		return false
	end
	local unitHumanName = unitDefinition.humanName
	local playerName,_,_,_,_,_,_,_,_,_ = spGetPlayerInfo(playerID)

	local leftButton = 1
	local middleButton = 2
	local rightButton = 3
	if button == leftButton then
		local textToBePasted = pasteCommand .. unitHumanName
		spSendCommands(textToBePasted)
	end
	if button == rightButton then
		local textToBePasted = pasteCommand .. (playerName or "")
		spSendCommands(textToBePasted)
	end
	if button == middleButton then
		local textToBePasted = whisper .. (playerID or "")
		spSendCommands(textToBePasted)
	end
end

function MaintainUnitSize(unitOriginalSize, originalViewHeight, currentViewHeight) --//from gui_flat2DView.lua (xponen)
	if (currentViewHeight >originalViewHeight) then
		local viewAngle= atan(unitOriginalSize/originalViewHeight)
		local newSize = tan(viewAngle)*currentViewHeight
		local addedSize = newSize- unitOriginalSize
		return addedSize
	end
	return 0
end
