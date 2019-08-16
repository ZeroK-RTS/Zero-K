-- $Id: init_start_point_remover.lua 3171 2008-11-06 09:06:29Z det $
function widget:GetInfo()
  return {
    name      = "Start Point Remover & Comm Selector",
    desc      = "Deletes your start point once the game begins & select commander",
    author    = "TheFatController and jK",
    date      = "Jul 11, 2007",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

include("Widgets/COFCTools/ExportUtilities.lua")
local GetRawBoxes = VFS.Include("LuaUI/Headers/startbox_utilities.lua")

local unitCount = 1 -- counter just in case there would be more than one unit spawned with only one being the comm but not being the first one. Note that if the Commander is spawned with an offset from the start point the marker may not be erased.

local campaignBattleID = Spring.GetModOptions().singleplayercampaignbattleid

function widget:Initialize()
	if (CheckForSpec()) then
		return false
	end
end

local init = false
local cameraMoved = false
function widget:GameSetup()
	if not init then
		local startboxes = GetRawBoxes()
		if startboxes and #startboxes > 0 then cameraMoved = true end
		init = true
	end
end

function CheckForSpec()
	if (Spring.GetSpectatingState() or Spring.IsReplay()) and (not Spring.IsCheatingEnabled()) then
		widgetHandler:RemoveWidget()
		return true
	end
end

function widget:GameFrame(f)
	if f == 4 then
		local teamUnits = Spring.GetTeamUnits(Spring.GetMyTeamID())
		for _,unitID in ipairs(teamUnits) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		local unitDef   = UnitDefs[unitDefID]
			if (unitDef.customParams.commtype) then
				local x, y, z = Spring.GetUnitPosition(unitID)
				Spring.MarkerErasePosition(x, y, z)
				if not cameraMoved then
					SetCameraTarget(x, y, z, 1, true, 1000)
				end
				
				-- Do not select commander at the start of campaign battles. The selection UI can clip into the mission
				-- objectives popup and often there are many units to select at the start.
				if not campaignBattleID then
					Spring.SelectUnitArray{teamUnits[unitCount]}
				end
			end
			unitCount = unitCount + 1
		end
	end
	if f == 7 then
		if WG.InitialActiveCommand then
			Spring.Echo("SENDING " .. WG.InitialActiveCommand)
			Spring.SetActiveCommand(WG.InitialActiveCommand)
		end
		widgetHandler:RemoveWidget()
	end
end
