local versionNum = '3.031'

function widget:GetInfo()
	return {
		name    = "Auto Group",
		desc    = "v".. (versionNum) .." Alt+0-9 sets autogroup# for selected unit type(s). Newly built units get added to group# equal to their autogroup#. Alt BACKQUOTE (~) remove units. Type '/luaui autogroup help' for help or view settings at: Settings/Interface/AutoGroup'.",
		author  = "Licho",
		date    = "Mar 23, 2007",
		license = "GNU GPL, v2 or later",
		layer   = 0,
		enabled = true  --loaded by default?
	}
end

include("keysym.h.lua")
local _, ToKeysyms = include("Configs/integral_menu_special_keys.lua")

---- CHANGELOG -----
-- versus666,		v3.03	(17dec2011)	: 	Back to alt BACKQUOTE to remove selected units from group
--											to please licho, changed help accordingly.
-- versus666,		v3.02	(16dec2011)	: 	Fixed for 84, removed unused features, now alt backspace to remove
--											selected units from group, changed help accordingly.
-- versus666,		v3.01	(07jan2011)	: 	Added check to comply with F5.
-- wagonrepairer	v3.00	(07dec2010)	:	'Chilified' autogroup.
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
-- none
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local debug = false --of true generates debug messages
local unit2group = {} -- list of unit types to group

local groupableBuildingTypes = { 'tacnuke', 'empmissile', 'napalmmissile', 'seismic' }

local groupableBuildings = {}
for _, v in ipairs( groupableBuildingTypes ) do
	if UnitDefNames[v] then
		groupableBuildings[ UnitDefNames[v].id ] = true
	end
end

local removeAutogroupKey = KEYSYMS.BACKQUOTE
local function HotkeyChangeNotification()
	local key = WG.crude.GetHotkeyRaw("epic_auto_group_removefromgroup")
	removeAutogroupKey = ToKeysyms(key and key[1])
end

local helpText =
	'Alt + Group Hotkey sets autogroup number for selected unit type(s).\nNewly built units get added to the group equal to their autogroup.'..
	'\n (~) deletes autogrouping for selected unit type(s).'
	--'Ctrl+~ removes nearest selected unit from its group and selects it. '
	--'Extra function: Ctrl+q picks single nearest unit from current selection.',

local hotkeyPath = 'Hotkeys/Selection/Control Groups'

options_order = { 'mainlabel', 'text_hotkey', 'cleargroups', 'removefromgroup', 'loadgroups', 'addall', 'verbose', 'immediate', 'groupnumbers', }
options_path = 'Settings/Interface/Control Groups'
options = {
	mainlabel = {name='Auto Group', type='label'},
	loadgroups = {
		name = 'Preserve Auto Groups',
		desc = 'Preserve auto groupings for next game. Unchecking this clears the groups!',
		type = 'bool',
		value = true,
		noHotkey = true,
		OnChange = function(self)
			if not self.value then
				unit2group = {}
			end
		end
	},
	addall = {
		name = 'Add All',
		desc = 'Existing units will be added to group# when setting autogroup#.',
		type = 'bool',
		value = false,
		noHotkey = true,
	},
	verbose = {
		name = 'Verbose Mode',
		type = 'bool',
		value = true,
		noHotkey = true,
	},
	immediate = {
		name = 'Immediate Mode',
		desc = 'Units built/resurrected/received are added to autogroups immediately instead of waiting them to be idle.',
		type = 'bool',
		value = false,
		noHotkey = true,
	},
	groupnumbers = {
		name = 'Display Group Numbers',
		type = 'bool',
		value = true,
		noHotkey = true,
	},
	
	text_hotkey = {
		name = 'Auto Groups',
		type = 'text',
		value = "Alt + <Group Number> sets all selected unit types to automatically be assigned to the group upon completion.\nAlt + <Remove From Autogroup> removes the selected unit types from their auto group. Auto groups persist across games by default.",
		path = hotkeyPath,
	},
	
	cleargroups = {
		name = 'Clear All Auto Groups',
		type = 'button',
		OnChange = function()
			unit2group = {}
			Spring.Echo('game_message: Cleared Autogroups.')
		end,
		path = hotkeyPath,
	},
	removefromgroup = {
		name = 'Remove From Autogroup',
		type = 'button',
		hotkey = "`",
		bindWithAny = true,
		dontRegisterAction = true,
		OnHotkeyChange = HotkeyChangeNotification,
		path = hotkeyPath,
	},
}

-- Hidden until working
for i = 0, 9 do
	--options["autogroup_" .. i] = {
	--	name = 'Autogroup ' .. i,
	--	type = 'button',
	--	OnChange = function()
	--		DoAutogroupAction(i)
	--	end,
	--	path = hotkeyPath,
	--}
	--options_order[#options_order + 1] = "autogroup_" .. i
end

local finiGroup = {}
local myTeam
local selUnitDefs = {}
local loadGroups = true
local createdFrame = {}
local textColor = {0.7, 1.0, 0.7, 1.0} -- r g b alpha
local textSize = 13.0

local IterableMap = VFS.Include("LuaRules/Gadgets/Include/IterableMap.lua")
local screwyWaypointUnits = IterableMap.New()

-- gr = groupe selected/wanted

-- speedups
local SetUnitGroup     = Spring.SetUnitGroup
local GetSelectedUnits = Spring.GetSelectedUnits
local GetUnitDefID     = Spring.GetUnitDefID
local GetAllUnits      = Spring.GetAllUnits
local GetUnitHealth    = Spring.GetUnitHealth
local GetMouseState    = Spring.GetMouseState
local SelectUnitArray  = Spring.SelectUnitArray
local TraceScreenRay   = Spring.TraceScreenRay
local GetUnitPosition  = Spring.GetUnitPosition
local UDefTab          = UnitDefs
local GetGroupList     = Spring.GetGroupList
local GetGroupUnits    = Spring.GetGroupUnits
local GetGameFrame     = Spring.GetGameFrame
local IsGuiHidden      = Spring.IsGUIHidden
local Echo             = Spring.Echo

local groupNumber = {
	[KEYSYMS.N_1] = 1,
	[KEYSYMS.N_2] = 2,
	[KEYSYMS.N_3] = 3,
	[KEYSYMS.N_4] = 4,
	[KEYSYMS.N_5] = 5,
	[KEYSYMS.N_6] = 6,
	[KEYSYMS.N_7] = 7,
	[KEYSYMS.N_8] = 8,
	[KEYSYMS.N_9] = 9,
	[KEYSYMS.N_0] = 0,
}

function WG.AutoGroup_UpdateGroupNumbers(newNumber)
	groupNumber = newNumber
end

function printDebug( value )
	if ( debug ) then
		Echo( value )
	end
end

function widget:PlayerChanged(playerID)
	if playerID ~= Spring.GetMyPlayerID() then
		return
	end

	local myCurrentTeam = Spring.GetMyTeamID()
	if myCurrentTeam == myTeam then
		return
	end
	myTeam = myCurrentTeam

	-- units lose their group on team change (technically they keep it but it's only accessible if you go back to the old team)
	-- but the player is transferred before his units so reassignation happens in UnitGiven
end

function widget:Initialize()
	local _, _, spec, team = Spring.GetPlayerInfo(Spring.GetMyPlayerID(), false)
	if spec then
		widgetHandler:RemoveWidget()
		return false
	end
	HotkeyChangeNotification()
	myTeam = team
end

function widget:DrawWorld()
	if not IsGuiHidden() then
		local existingGroups = GetGroupList()
		if options.groupnumbers.value then
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
		end
	end
end

function widget:UnitFinished(unitID, unitDefID, unitTeam)
	if (unitTeam == myTeam and unitID ~= nil) then
		if (createdFrame[unitID] == GetGameFrame()) then
			local gr = unit2group[unitDefID]
				--printDebug("<AUTOGROUP>: Unit finished " ..  unitID) --
			if gr ~= nil then
				SetUnitGroup(unitID, gr)
			end
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
	if (unitTeam == myTeam) then
		if options.immediate.value or groupableBuildings[unitDefID] then
			createdFrame[unitID] = GetGameFrame()
			local gr = unit2group[unitDefID]
			if gr ~= nil then
				SetUnitGroup(unitID, gr)
			end
			--printDebug("<AUTOGROUP>: Unit from factory " ..  unitID)
		else
			screwyWaypointUnits.Add(unitID, {})
		end
	end
end

function widget:UnitDestroyed(unitID, unitDefID, teamID)
	finiGroup[unitID] = nil
	createdFrame[unitID] = nil
	screwyWaypointUnits.Remove(unitID)
	--printDebug("<AUTOGROUP> : Unit destroyed "..  unitID)
end

function widget:UnitGiven(unitID, unitDefID, newTeamID, teamID)
	if (newTeamID == myTeam) then
		local gr = unit2group[unitDefID]
		--printDebug("<AUTOGROUP> : Unit given "..  unit2group[unitDefID])
		if gr ~= nil then
			SetUnitGroup(unitID, gr)
		end
	end
	createdFrame[unitID] = nil
	finiGroup[unitID] = nil
end

function widget:UnitTaken(unitID, unitDefID, oldTeamID, teamID)
	if (teamID == myTeam) then
		local gr = unit2group[unitDefID]
		--printDebug("<AUTOGROUP> : Unit taken "..  unit2group[unitDefID])
		if gr ~= nil then
			SetUnitGroup(unitID, gr)
		end
		screwyWaypointUnits.Remove(unitID)
	end
	createdFrame[unitID] = nil
	finiGroup[unitID] = nil
end

function widget:UnitIdle(unitID, unitDefID, unitTeam)
	if (unitTeam == myTeam and finiGroup[unitID]~=nil) then
		local gr = unit2group[unitDefID]
		if gr ~= nil then
			SetUnitGroup(unitID, gr)
			--printDebug("<AUTOGROUP> : Unit idle " ..  gr)
		end
		screwyWaypointUnits.Remove(unitID)
		finiGroup[unitID] = nil
	end
end

function DoAutogroupAction(gr)
	Spring.Echo("Todo")
	-- Do stuff
	-- The issue is that if you press '1' then the 'Any+1' hotkey for 'select group 1' is done before the more specific hotkey 'Alt+1'
end

function widget:KeyPress(key, modifier, isRepeat)
	if ( modifier.alt and not modifier.meta ) then
		local gr = groupNumber[key]
 		if (key == removeAutogroupKey) then gr = -1 end
		if (gr ~= nil) then
			if (gr == -1) then
				gr = nil
			end
			selUnitDefIDs = {}
			local exec = false --set to true when there is at least one unit to process
			for _, unitID in ipairs(GetSelectedUnits()) do
				local udid = GetUnitDefID(unitID)
				if ( not UDefTab[udid]["isFactory"] and (groupableBuildings[udid] or not UDefTab[udid]["isBuilding"] )) then
					selUnitDefIDs[udid] = true
					unit2group[udid] = gr
					--local x, y, z = Spring.GetUnitPosition(unitID)
					--Spring.MarkerAddPoint( x, y, z )
					exec = true
					--Echo('<AUTOGROUP> : Add unit ' .. unitID .. 'to group ' .. gr)
					if (gr==nil) then
						SetUnitGroup(unitID, -1)
					else
						SetUnitGroup(unitID, gr)
					end
				end
			end
			if exec == false then
				return false -- nothing to do
			end
			for udid, _ in pairs(selUnitDefIDs) do
				if options.verbose.value then
					if gr then
						Echo('game_message: Added '..  Spring.Utilities.GetHumanName(UnitDefs[udid]) ..' to autogroup #'.. gr ..'.')
					else
						Echo('game_message: Removed '..  Spring.Utilities.GetHumanName(UnitDefs[udid]) ..' from autogroups.')
					end
				end
			end
			if options.addall.value then
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
		if (key == removeAutogroupKey) then
			local mx,my = GetMouseState()
			local _,pos = TraceScreenRay(mx,my,true)
			local mindist = math.huge
			local muid = nil
			if (pos == nil) then
				return
			end
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
		local ret ={
			version = versionNum,
			groups  = groups,
		}
	return ret
end

function widget:SetConfigData(data)
	if (data and type(data) == 'table' and data.version and (data.version+0) > 2.1) then
		local groupData	= data.groups
		if groupData and type(groupData) == 'table' then
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

local function UnstickUpdate(unitID, unitData)
	if not Spring.ValidUnitID(unitID) then
		return true
	end
	local cmdID = Spring.GetUnitCurrentCommand(unitID)
	if not cmdID then
		widget:UnitIdle(unitID, Spring.GetUnitDefID(unitID), Spring.GetUnitTeam(unitID))
		return true
	end
	if cmdID == CMD.FIGHT then
		local x, y, z = Spring.GetUnitPosition(unitID)
		if not unitData.x then
			unitData.x, unitData.y, unitData.z = x, y, z
			return
		end
		if math.abs(x - unitData.x) < 64 and math.abs(z - unitData.z) < 64 then
			Spring.GiveOrderToUnit(unitID, CMD.STOP, {}, 0)
			return true
		end
		unitData.x, unitData.y, unitData.z = x, y, z
	end
end

function widget:GameFrame(n)
	if n%113 == 7 then
		screwyWaypointUnits.Apply(UnstickUpdate)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
