local version = "v1.0"
function widget:GetInfo()
  return {
    name      = "Auto-toggle false color vision",
    desc      = version .. " provide options to automatically toggle Spring's false color vision" ..
				" by detecting current active command.",
	author    = "Msafwan",
    date      = "17 July 2013",
    license   = "none",
    layer     = 21,
    enabled   = true
  }
end


local spGetMapDrawMode = Spring.GetMapDrawMode
local spGetActiveCommand = Spring.GetActiveCommand
local spGetActiveCmdDesc = Spring.GetActiveCmdDesc
local spSendCommands = Spring.SendCommands
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--options for epicmenu:
options_path = 'Settings/Interface/Map/Auto Toggle Overlay'
options_order = {'enginemetalview','engineheightview','enginepathview'}
options={
	enginemetalview ={
		name = 'Metalview Color',
		desc = 'RECLAIM & RESURRECT toggle metalmap vision.',
		type = 'bool',
		value = false,
	},
	engineheightview ={
		name = 'Heightview Color',
		desc = 'TERRAFORM & BUILD toggle heightmap vision.',
		type = 'bool',
		value = false,
	},
	enginepathview ={
		name = 'Pathview Color',
		desc = 'MOVE & JUMP toggle pathmap vision.',
		type = 'bool',
		value = false,
	},
}
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local currCmd =  spGetActiveCommand() --remember current command
function widget:Update()
	if not (options.enginemetalview.value or
	options.engineheightview.value or
	options.enginepathview.value) or
	(currCmd == spGetActiveCommand())
	then
		return --if detect no change in command selection: --skip whole thing
	end
	currCmd = spGetActiveCommand() --update active command
	local activeCmd = spGetActiveCmdDesc(currCmd)
	UntoggleMapView()
	if activeCmd then
		local match = false
		local activeCmdName = activeCmd.name
		if options.enginemetalview.value then
			match = ToggleMapView(activeCmdName,{"Reclaim","Resurrect"},"metal","showmetalmap")
		end
		if options.engineheightview.value and not match then
			if activeCmd.id < 0 then
				activeCmdName = "Build"
			end
			match = ToggleMapView(activeCmdName,{"Build","Ramp","Level","Raise","Smooth","Restore"},"height","showelevation")
		end
		if options.enginepathview.value and not match then
			ToggleMapView(activeCmdName,{"Move","Jump"},"pathTraversability","showpathtraversability")
		end
	end
end
---------------------------------------------------------------------------------------------------------------------------------------------------------------------
----auto-change ANY mapview mode into selected mapview and toggle back to previous view (except if user toggle a new mode in between) when called the second time:---
local memPrevMapView = nil --remember map-view prior to changes
local memPrevToggledView = nil --remember setup map-view
function UntoggleMapView()
	if memPrevMapView and (spGetMapDrawMode() == memPrevToggledView) then --if remember previous map-view & current view is from previous set up: restore previous map-view
		if memPrevMapView == 'normal' then
			spSendCommands("showstandard")
		elseif memPrevMapView == 'height' then
			spSendCommands("showelevation")
		elseif memPrevMapView == 'pathTraversability' then
			spSendCommands("showpathtraversability")
		elseif memPrevMapView == 'los' then
			spSendCommands("togglelos")
		elseif memPrevMapView == 'metal' then
			spSendCommands("showmetalmap")
		end
		memPrevMapView = nil --forget about previous map-view
		memPrevToggledView = nil
	end
end

function ToggleMapView(activeCmdName,trigger,mapMode,activateCommand)
	if (spGetMapDrawMode() ~= mapMode) then --if not yet in required mapview: check for active command
		local nameMatch = false
		for i=1, #trigger do
			if activeCmdName == trigger[i] then
				nameMatch=true
				break
			end
		end
		if nameMatch then --if current command match: remember current map-view & set up new map view
			memPrevMapView = spGetMapDrawMode()
			memPrevToggledView = mapMode
			spSendCommands(activateCommand)
			return true
		end
	end
	return false
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
