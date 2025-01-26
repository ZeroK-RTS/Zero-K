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

include("keysym.lua")
local _, ToKeysyms = include("Configs/integral_menu_special_keys.lua")

local unit2group = {} -- list of unit types to group

local isBuilding = {}
for unitDefID, unitDef in pairs(UnitDefs) do
	if unitDef.isImmobile then
		isBuilding[unitDefID] = true
	end
end

local removeAutogroupKey = KEYSYMS.BACKQUOTE
local function HotkeyChangeNotification()
	local key = WG.crude.GetHotkeyRaw("epic_auto_group_removefromgroup")
	removeAutogroupKey = ToKeysyms(key and key[1])
end

local hotkeyPath = 'Hotkeys/Selection/Control Groups'

i18nPrefix = 'autogroup_'
options_order = { 'mainlabel', 'text_hotkey', 'cleargroups', 'removefromgroup', 'loadgroups', 'addall', 'verbose', 'immediate', 'groupnumbers', }
options_path = 'Settings/Interface/Control Groups'
options = {
	mainlabel = {name='Auto Group', type='label'},
	loadgroups = {
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
		type = 'bool',
		value = false,
		noHotkey = true,
	},
	groupnumbers = { -- FIXME why is this handled by autogroups? it's standalone functionality
		type = 'bool',
		value = true,
		noHotkey = true,
	},
	
	text_hotkey = {
		type = 'text',
		path = hotkeyPath,
	},
	
	cleargroups = {
		type = 'button',
		OnChange = function()
			unit2group = {}
			Spring.Echo('game_message: Cleared Autogroups.')
		end,
		path = hotkeyPath,
	},
	removefromgroup = {
		type = 'button',
		hotkey = "`",
		bindWithAny = true,
		dontRegisterAction = true,
		OnHotkeyChange = HotkeyChangeNotification,
		path = hotkeyPath,
	},
}

-- Hidden until working
--for i = 0, 9 do
	--options["autogroup_" .. i] = {
	--	name = 'Autogroup ' .. i,
	--	type = 'button',
	--	OnChange = function()
	--		-- The issue is that if you press '1' then the 'Any+1' hotkey for 'select group 1' is done before the more specific hotkey 'Alt+1'
	--	end,
	--	path = hotkeyPath,
	--}
	--options_order[#options_order + 1] = "autogroup_" .. i
--end

local finiGroup = {}
local myTeam
local textColor = {0.7, 1.0, 0.7, 1.0} -- r g b alpha
local textSize = 13.0

local IterableMap = VFS.Include("LuaRules/Gadgets/Include/IterableMap.lua")
local screwyWaypointUnits = IterableMap.New()

-- gr = groupe selected/wanted

-- speedups
local SetUnitGroup     = Spring.SetUnitGroup
local GetSelectedUnits = Spring.GetSelectedUnits
local GetUnitDefID     = Spring.GetUnitDefID
local GetUnitHealth    = Spring.GetUnitHealth
local GetMouseState    = Spring.GetMouseState
local SelectUnitArray  = Spring.SelectUnitArray
local TraceScreenRay   = Spring.TraceScreenRay
local GetUnitPosition  = Spring.GetUnitPosition
local GetGroupList     = Spring.GetGroupList
local GetGroupUnits    = Spring.GetGroupUnits
local IsGuiHidden      = Spring.IsGUIHidden

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
				local units = GetGroupUnits(inGroup)
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

local function SetGroupFromAuto(unitID, unitDefID)
	local autoGroup = unit2group[unitDefID]
	if not autoGroup then
		return
	end

	local currentGroup = Spring.GetUnitGroup(unitID)
	if currentGroup then
		return
	end

	SetUnitGroup(unitID, autoGroup)
end

function widget:UnitFinished(unitID, unitDefID, unitTeam)
	if unitTeam ~= myTeam then
		return
	end

	if options.immediate.value
	or isBuilding[unitDefID] then
		SetGroupFromAuto(unitID, unitDefID)
	else
		IterableMap.Add(screwyWaypointUnits, unitID, {})
		finiGroup[unitID] = true
	end
end

function widget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
	if unitTeam == myTeam and not Spring.GetUnitIsBeingBuilt(unitID) then
		-- handle spawned units (morph, wolverine etc)
		SetGroupFromAuto(unitID, unitDefID)
	end
end

function widget:UnitDestroyed(unitID, unitDefID, teamID)
	finiGroup[unitID] = nil
	IterableMap.Remove(screwyWaypointUnits, unitID)
end

function widget:UnitGiven(unitID, unitDefID, newTeamID, teamID)
	if (newTeamID == myTeam) then
		SetGroupFromAuto(unitID, unitDefID)
	end
	finiGroup[unitID] = nil
end

function widget:UnitTaken(unitID, unitDefID, oldTeamID, teamID)
	if (teamID == myTeam) then
		SetGroupFromAuto(unitID, unitDefID)
		IterableMap.Remove(screwyWaypointUnits, unitID)
	end
	finiGroup[unitID] = nil
end

function widget:UnitIdle(unitID, unitDefID, unitTeam)
	if (unitTeam == myTeam and finiGroup[unitID]~=nil) then
		SetGroupFromAuto(unitID, unitDefID)
		IterableMap.Remove(screwyWaypointUnits, unitID)
		finiGroup[unitID] = nil
	end
end

function widget:KeyPress(key, modifier, isRepeat)
	if (modifier.alt and not modifier.meta ) then
		local gr = groupNumber[key]
		if (key == removeAutogroupKey) then gr = -1 end
		if (gr ~= nil) then
			if (gr == -1) then
				gr = nil
			end
			local selUnitDefIDs = {}
			local exec = false --set to true when there is at least one unit to process
			for _, unitID in ipairs(GetSelectedUnits()) do
				local udid = GetUnitDefID(unitID)
				selUnitDefIDs[udid] = true
				unit2group[udid] = gr
				exec = true
				if (gr==nil) then
					SetUnitGroup(unitID, -1)
				else
					SetUnitGroup(unitID, gr)
				end
			end
			if exec == false then
				return false -- nothing to do
			end
			for udid, _ in pairs(selUnitDefIDs) do
				if options.verbose.value then
					if gr then
						Spring.Echo('game_message: Added '..  Spring.Utilities.GetHumanName(UnitDefs[udid]) ..' to autogroup #'.. gr ..'.')
					else
						Spring.Echo('game_message: Removed '..  Spring.Utilities.GetHumanName(UnitDefs[udid]) ..' from autogroups.')
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
				local dist = (pos[1]-x)^2 + (pos[3]-z)^2
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
		local queueSize = Spring.GetCommandQueue(unitID, 0)
		if queueSize and queueSize > 1 then
			return
		end
		local x, y, z = Spring.GetUnitPosition(unitID)
		if not unitData.x then
			unitData.x, unitData.y, unitData.z = x, y, z
			return
		end
		if math.abs(x - unitData.x) < 32 and math.abs(z - unitData.z) < 32 then
			Spring.GiveOrderToUnit(unitID, CMD.STOP, 0, 0)
			return true
		end
		unitData.x, unitData.y, unitData.z = x, y, z
	end
end

function widget:GameFrame(n)
	if n%113 == 7 then
		IterableMap.Apply(screwyWaypointUnits, UnstickUpdate)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
