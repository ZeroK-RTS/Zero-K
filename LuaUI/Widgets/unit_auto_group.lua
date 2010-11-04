local versionNum = '2.25'

function widget:GetInfo()
  return {
	name		= "Auto group",
	desc 		= "v".. (versionNum) .." Alt+0-9 sets autogroup# for selected unit type(s). Newly built units get added to group# equal to their autogroup#. Type '/luaui autogroup help' for help.",
	author		= "Licho",
	date		= "Mar 23, 2007",
	license		= "GNU GPL, v2 or later",
	layer		= 0,
	enabled		= true  --loaded by default?
  }
end

include("keysym.h.lua")

---- CHANGELOG -----
-- versus666, 		v2.25	(04nov2010)	:	Added switch to show or not group number, by licho's request.
-- versus666, 		v2.24	(27oct2010)	:	Added switch to auto add units when built from factories.
--											Add group label numbers to units in group.
--											Sped up some routines & cleaned code.
--		?,			v2,23				:	Unknown.
-- very_bad_solider,v2.22				:	Ignores buildings and factories.
--											Does not react when META (+ALT) is pressed.
-- CarRepairer,		v2.00				:	Autogroups key is alt instead of alt+ctrl.
--											Added commands: help, loadgroups, cleargroups, verboseMode, addall.
-- Licho,			v1.0				:	Creation.

--REMINDER :
-- LuaUI\Configs\crudemenu_conf.lua need to be adapted with new commands.
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local debug = false --generates debug message
local finiGroup = {}
local unit2group = {} -- list of unit types to group
local myTeam
local selUnitDefs = {}
local loadGroups = true
local verboseMode = true
local addAll = false
local immediateMode = false
local groupNumbers = true
local createdFrame = {}
local textColor = {0.7, 1.0, 0.7, 1.0} -- r g b alpha
local textSize = 13.0

-- gr = groupe selected/wanted

local helpText = {
	'Alt+0-9 sets autogroup# for selected unit type(s). Newly built units get added to group# equal to their autogroup#.',
	'Alt+\~ deletes autogrouping for selected unit type(s).',
	'Ctrl+~ removes nearest selected unit from its group and selects it. ',
	'/luaui autogroup cleargroups -- Clears your autogroupings.',
	'/luaui autogroup loadgroups -- Toggles whether your groups are re-loaded for all future games.',
	'/luaui autogroup verbose -- Toggle whether a notification is made when adding/removing autogroups.',
	'/luaui autogroup addall -- Toggle whether existing units are added to group# when setting autogroup#.',
	'/luaui autogroup immediate -- Toggle whether built units are directly added to group# when from exiting factory or when rally point reached.',
	'/luaui autogroup groupnumbers  -- Toggle whether group units have their group number listed next to them.', 
	--'Extra function: Ctrl+q picks single nearest unit from current selection.',
}
-- speedups
local SetUnitGroup 		= Spring.SetUnitGroup
local GetSelectedUnits 	= Spring.GetSelectedUnits
local GetUnitDefID 		= Spring.GetUnitDefID
local Echo 				= Spring.Echo
local GetAllUnits		= Spring.GetAllUnits
local GetUnitHealth		= Spring.GetUnitHealth
local GetMouseState		= Spring.GetMouseState
--local GetUnitTeam		= Spring.GetUnitTeam --NOT USED FOR NOW
local SelectUnitArray	= Spring.SelectUnitArray
local TraceScreenRay	= Spring.TraceScreenRay
local GetUnitPosition	= Spring.GetUnitPosition
local UDefTab			= UnitDefs
local GetGroupList		= Spring.GetGroupList
local GetGroupUnits		= Spring.GetGroupUnits
local GetGameFrame		= Spring.GetGameFrame


function widget:Initialize() 
	local _, _, spec, team = Spring.GetPlayerInfo(Spring.GetMyPlayerID())
	if spec then
		widgetHandler:RemoveWidget()
		return false
	end
	myTeam = team
end

function widget:DrawWorld()
	local existingGroups = GetGroupList()
	if groupNumbers then
		for inGroup, _ in pairs(existingGroups) do
			units = GetGroupUnits(inGroup)
			for _, unit in ipairs(units) do
				if Spring.IsUnitInView(unit) then
					local ux, uy, uz = Spring.GetUnitViewPosition(unit)
					gl.PushMatrix()
					gl.Translate(ux, uy, uz)
					gl.Billboard()
					gl.Color(textColor)--unused anyway when gl.Text have option 's' (and b & w)
					gl.Text("" .. inGroup, 30.0, -10.0, textSize, "cns")
					gl.PopMatrix()
				end
			end
		end
	else end
end

function widget:UnitFinished(unitID, unitDefID, unitTeam)
	if (unitTeam == myTeam and unitID ~= nil) then
		if (createdFrame[unitID] == GetGameFrame()) then
			local gr = unit2group[unitDefID]
printDebug("<AUTOGROUP>: Unit finished " ..  unitID) --
			if gr ~= nil then SetUnitGroup(unitID, gr) end
		else 
			finiGroup[unitID] = 1
		end
	end
end

function widget:UnitCreated(unitID, unitDefID, unitTeam, builderID) 
	if (unitTeam == myTeam) then
		createdFrame[unitID] = GetGameFrame()
	end
end

function widget:UnitFromFactory(unitID, unitDefID, unitTeam)
	if immediateMode then
		if (unitTeam == myTeam) then
			createdFrame[unitID] = GetGameFrame()
			local gr = unit2group[unitDefID]
			if gr ~= nil then SetUnitGroup(unitID, gr) end
printDebug("<AUTOGROUP>: Unit from factory " ..  unitID)
		end
	end
end

function widget:UnitDestroyed(unitID, unitDefID, teamID)
	finiGroup[unitID] = nil
	createdFrame[unitID] = nil
printDebug("<AUTOGROUP> : Unit destroyed "..  unitID)
end

function widget:UnitGiven(unitID, unitDefID, newTeamID, teamID)
	if (newTeamID == myTeam) then
		local gr = unit2group[unitDefID]
printDebug("<AUTOGROUP> : Unit given "..  unit2group[unitDefID])
		if gr ~= nil then SetUnitGroup(unitID, gr) end
	end
	createdFrame[unitID] = nil
	finiGroup[unitID] = nil
end

function widget:UnitTaken(unitID, unitDefID, oldTeamID, teamID)
	if (teamID == myTeam) then
		local gr = unit2group[unitDefID]
printDebug("<AUTOGROUP> : Unit taken "..  unit2group[unitDefID])
		if gr ~= nil then SetUnitGroup(unitID, gr) end
	end
	createdFrame[unitID] = nil
	finiGroup[unitID] = nil
end

function widget:UnitIdle(unitID, unitDefID, unitTeam) 
	if (unitTeam == myTeam and finiGroup[unitID]~=nil) then
		local gr = unit2group[unitDefID]
		if gr ~= nil then SetUnitGroup(unitID, gr)
printDebug("<AUTOGROUP> : Unit idle " ..  gr)
		end
	finiGroup[unitID] = nil
	end
end

function widget:KeyPress(key, modifier, isRepeat)
	if ( modifier.alt and not modifier.meta ) then
		local gr
		if (key == KEYSYMS.N_0) then gr = 0 end
		if (key == KEYSYMS.N_1) then gr = 1 end
		if (key == KEYSYMS.N_2) then gr = 2 end 
		if (key == KEYSYMS.N_3) then gr = 3 end
		if (key == KEYSYMS.N_4) then gr = 4 end
		if (key == KEYSYMS.N_5) then gr = 5 end
		if (key == KEYSYMS.N_6) then gr = 6 end
		if (key == KEYSYMS.N_7) then gr = 7 end
		if (key == KEYSYMS.N_8) then gr = 8 end
		if (key == KEYSYMS.N_9) then gr = 9 end
 		if (key == KEYSYMS.BACKQUOTE) then gr = -1 end
		if (gr ~= nil) then
				if (gr == -1) then gr = nil end
				selUnitDefIDs = {}
				local exec = false --set to true when there is at least one unit to process
				for _, unitID in ipairs(GetSelectedUnits()) do
					local udid = GetUnitDefID(unitID)
					if ( not UDefTab[udid]["isFactory"] and not UDefTab[udid]["isBuilding"] ) then
						selUnitDefIDs[udid] = true
						unit2group[udid] = gr
						exec = true
						SetUnitGroup(unitID, gr)
						Echo('AUTOGROUP : Add unit ' .. unitID .. 'to group ' .. gr)
					end
				end
				if ( exec == false ) then
					return false --nothing to do
				end
				for udid,_ in pairs(selUnitDefIDs) do
					if verboseMode then
						if gr then
							Echo('Added '..  UnitDefs[udid].humanName ..' to autogroup #'.. gr ..'.')
						else
							Echo('Removed '..  UnitDefs[udid].humanName ..' from autogroups.')
						end
					end
				end
				if addAll then
					local myUnits = Spring.GetTeamUnits(myTeam)
					for _, unitID in pairs(myUnits) do
						local curUnitDefID = GetUnitDefID(unitID)
						if selUnitDefIDs[curUnitDefID] then
							if gr then
								local _, _, _, _, buildProgress = GetUnitHealth(unitID)
								if buildProgress == 1 then
									SetUnitGroup(unitID, gr)
									SelectUnitArray({unitID}, true)
								end
							else
								SetUnitGroup(unitID, -1)
							end
						end
					end
				end
				return true 	--key was processed by widget
			end
	elseif (modifier.ctrl and not modifier.meta) then	
		if (key == KEYSYMS.BACKQUOTE) then
			local mx,my = GetMouseState()
			local _,pos = TraceScreenRay(mx,my,true)     
			local mindist = math.huge
			local muid = nil
			if (pos == nil) then return end
				for _, uid in ipairs(GetSelectedUnits()) do  
					local x,_,z = GetUnitPosition(uid)
					dist = (pos[1]-x)*(pos[1]-x) + (pos[3]-z)*(pos[3]-z)
					if (dist < mindist) then
						mindist = dist
						muid = uid
					end
				end
			if (muid ~= nil) then
				SetUnitGroup(muid,-1)
				SelectUnitArray({muid})
			end
		end
		--[[
		if (key == KEYSYMS.Q) then
		  for _, uid in ipairs(GetSelectedUnits()) do  
			SetUnitGroup(uid,-1)
		  end
		end
		--]]
	end
	return false
end

function widget:GetConfigData()
	local groups = {}
	for id, gr in pairs(unit2group) do 
		table.insert(groups, {UnitDefs[id].name, gr})
		end 
		local ret = 
		{
		version 		= versionNum,
		groups 			= groups,
		loadGroups 		= loadGroups,
		verboseMode		= verboseMode,
		addAll			= addAll,
		immediatemode	= immediateMode,
		}
	return ret
end

function widget:SetConfigData(data)
	if (data and type(data) == 'table' and data.version and (data.version+0) > 2.1) then
		loadGroups	= data.loadGroups
		verbose		= data.verboseMode
		addAll		= data.addAll
		immediateMode	= data.immediatemode
		local groupData	= data.groups
		if loadGroups and groupData and type(groupData) == 'table' then
			for _, nam in ipairs(groupData) do
				if type(nam) == 'table' then
					local gr = UnitDefNames[nam[1]]
					if (gr ~= nil) then
						unit2group[gr.id] = nam[2]
					end
				end
			end
		end
	end
end

function widget:TextCommand(command)
	if command == "autogroup loadgroups" then
		loadGroups = not loadGroups
		Echo('Autogroup: your autogroups will '.. (loadGroups and '' or 'NOT') ..' be preserved for future games') 
		return true
	elseif command == "autogroup cleargroups" then
		unit2group = {}
		Echo('Autogroup: all autogroups cleared.')
		return true
	elseif command == "autogroup verbose" then
		verboseMode = not verboseMode 
		Echo('Autogroup: verbose mode '.. (verboseMode and 'ON' or 'OFF') ..'.')
		return true
	elseif command == "autogroup addall" then
		addAll = not addAll
		Echo('Autogroup: existing units will '.. (addAll and '' or 'NOT') ..' be added to group# when setting autogroup#.')
		return true
	elseif command == "autogroup immediate" then
		immediateMode = not immediateMode
		Echo('Autogroup: immediate mode registering units from factory is '.. (immediateMode and '' or 'NOT') ..' activated.') 
		return true
	elseif command == "autogroup groupnumbers" then
		groupNumbers = not groupNumbers
		Echo('Autogroup: group numbers next to group unit are '.. (groupNumbers and '' or 'NOT') ..' shown.') 
		return true
	elseif command == "autogroup help" then
		for i, text in ipairs(helpText) do
			Echo('['.. i ..'] Autogroup: '.. text)
		end
		return true
	end
	return false
end

function printDebug( value )
	if ( debug ) then Echo( value )
	end
end
--------------------------------------------------------------------------------