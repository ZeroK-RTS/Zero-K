-- $Id$

--[[
local versionName = "v1.0b"

function widget:GetInfo()
  return {
	name	  = "Shield Guard",
	desc	  = versionName .. " Units walking with Area Shield will move at same speed. Area Shield will slow down for slow unit and fast unit will slow down for Area Shield. Work with GUARD (Area Shield) command & MOVE command, but doesn't work with queueing (result only apply to first queue).",
	author    = "Google Frog, +renovated by msafwan",
	date	  = "9 Mar, 2009, +9 April 2012",
	license   = "GNU GPL, v2 or later",
	layer	 = 5,
	enabled   = false --  loaded by default?
  }
end

-- Speedups

local CMD_MOVE = CMD.MOVE
local CMD_GUARD = CMD.GUARD

local CMD_SET_WANTED_MAX_SPEED = CMD.SET_WANTED_MAX_SPEED
local CMD_WAITCODE_GATHER = CMD.WAITCODE_GATHER

local spGetSelectedUnits     = Spring.GetSelectedUnits
local spGetUnitDefID 	    = Spring.GetUnitDefID
local spGetTeamUnits 	    = Spring.GetTeamUnits
local spSendCommands = Spring.SendCommands
local spGiveOrderToUnitArray = Spring.GiveOrderToUnitArray


local team = Spring.GetMyTeamID()

local areaShieldUnit = {} --//variable: store all relevant Area Shield's unitIDs & its follower's unitIDs
local follower_to_areaShieldUnit_meta = {} --//variable: remember which unit was placed under which Area Shield unit
local enableEcho = false --//constant: tools to fix bug
local areaShieldCount = 0
local shieldSpeed=0
----------------------------
--  CONFIG
local shieldUnitName = { 
  "shieldshield",
  "shieldassault",
}

----------------------------
-- Add/remove shielded
-- Override and add units guarding areaShieldUnit

function widget:CommandNotify(id, params, options)
	--if enableEcho then Spring.Echo(areaShieldCount) end
	--if enableEcho then Spring.Echo(options) end
	if areaShieldCount > 0 and not options.shift then --//skip everything if player never build any Area Shield unit, and skip "SHIFT" since qeueuing is not supported by this widget.
		local selectedUnits = spGetSelectedUnits()
		local availableAreaShieldUnit = {}
		for i=1, #selectedUnits, 1 do
			local selectedUnitID = selectedUnits[i]
			if areaShieldUnit[selectedUnitID] then
				availableAreaShieldUnit[#availableAreaShieldUnit+1] = selectedUnitID
			end
		end
		if #availableAreaShieldUnit > 0 and id == CMD_MOVE then --//perform command substitution when areaShield is part of the selection and is using MOVE command.
			local maxSpeed=shieldSpeed
			for i=1, #availableAreaShieldUnit, 1 do --//append "selectedUnit" with the list of unit that guarding the area-Shield. These extra unit will also be given the same move command
				local areaShieldID = availableAreaShieldUnit[i]
				local followerList = Deepcopy(areaShieldUnit[areaShieldID].guardedBy) --//NEEDED: because LUA didn't copy the table's value, instead it refer to the table itself and any changes made to the copy is not localized & will propagate to the original table
				local listLenght = #followerList
				for j=1, listLenght, 1 do
					local endOfFollowerIndex = #followerList
					selectedUnits[#selectedUnits+1]=followerList[endOfFollowerIndex]
					local unitDefID = spGetUnitDefID(followerList[endOfFollowerIndex])
					local unitDef = UnitDefs[unitDefID]
					local speed = unitDef.speed/30
					if speed< maxSpeed then
						maxSpeed= speed
					end
					followerList[endOfFollowerIndex] = nil --//add nil to endOfTable so that '#' index shifted down by 1. So "followerList" will be read from top-down as the cycle continue
				end
			end
			--if enableEcho then Spring.Echo(maxSpeed .. " maxSpeed ") Spring.Echo(CMD_WAITCODE_GATHER .." " .. CMD.GATHERWAIT .. " waitcodeGather, gatherwait") end
			spGiveOrderToUnitArray(selectedUnits, id, params,{}) --//use "ctrl" to activate engine's formation move, use "shift" to add this command on top of previous command.
			--spGiveOrderToUnitArray(selectedUnits, CMD_SET_WANTED_MAX_SPEED, {maxSpeed},{"shift",})
			--spGiveOrderToUnitArray(selectedUnits, CMD_WAITCODE_GATHER, {},{"shift"}) --// allow units to wait each other before going to next queue (assuming player will queue another command)
			
			for i=1, #availableAreaShieldUnit, 1 do --//go over the areaShield's "guardBy" list and queue a (preserve the) GUARD order
				local areaShieldUnitID = availableAreaShieldUnit[i]
				local followerList = areaShieldUnit[areaShieldUnitID].guardedBy
				if enableEcho then Spring.Echo(areaShieldUnitID .. " areaShieldUnitID") end
				spGiveOrderToUnitArray(followerList, CMD_GUARD, {areaShieldUnitID,},{"shift"}) --//tell units to queue GUARD the area shield units
			end
			return true --//make Spring skip user's command (because we already replaced with a new one)
			
		elseif #availableAreaShieldUnit == 0 then --//remove any unit from the "guarding Area Shield ('guardBy')" list if unit receive command which did not involve any Area Shield units
			for i=1, #selectedUnits, 1 do
				local unitID = selectedUnits[i]
				if follower_to_areaShieldUnit_meta[unitID] then
					local areaShieldUnitID = follower_to_areaShieldUnit_meta[unitID].areaShieldUnitID
					local positionInTable =  follower_to_areaShieldUnit_meta[unitID].positionInTable
					local guardedBy = areaShieldUnit[areaShieldUnitID].guardedBy
					if enableEcho then Spring.Echo(guardedBy) end
					guardedBy, follower_to_areaShieldUnit_meta = RemoveTableEntry(guardedBy, positionInTable, follower_to_areaShieldUnit_meta) --//remove table entry & metaTable entry and fill the space
					areaShieldUnit[areaShieldUnitID].guardedBy = guardedBy --//update the "guardedBy" table with the latest changes
				end
			end
		end
		if (id == CMD_GUARD) then
			if enableEcho then Spring.Echo("isGuard command") end
			local targetID = params[1]
			if areaShieldUnit[targetID] then --//if targetID is an areaShield unit, then put the selected unit into the "guardedBy" list in the areaShield's table...
				for i=1, #selectedUnits, 1 do
					local notAreaShield = true
					for areaShieldID, _ in pairs(areaShieldUnit) do --//exclude any Area Shield unit from the "guardedBy" list. This prevent bug and also gave nice feature
						local unitID = selectedUnits[i] 
						if areaShieldID == unitID then 
							notAreaShield = false
						end
					end
					if notAreaShield then
						local placeToPut = #areaShieldUnit[targetID].guardedBy +1
						areaShieldUnit[targetID].guardedBy[placeToPut] = selectedUnits[i] --//insert selected unitID into the areaShield's "guardedBy" table
						--if enableEcho then Spring.Echo(targetID .. " targetID") end
						follower_to_areaShieldUnit_meta[selectedUnits[i] ]= {areaShieldUnitID = targetID,positionInTable = placeToPut,}
					end
				end			
			end
		end
	end
end
  
-----------------------
--Add shield

function Deepcopy(object) --//method to actually copy a table instead of refering to the table's object (to fix a bug). Reference: http://lua-users.org/wiki/CopyTable, http://stackoverflow.com/questions/640642/how-do-you-copy-a-lua-table-by-value
	local lookup_table = {}
	local function _copy(object)
		if type(object) ~= "table" then
			return object
		elseif lookup_table[object] then
			return lookup_table[object]
		end
		local new_table = {}
		lookup_table[object] = new_table
		for index, value in pairs(object) do
			new_table[_copy(index)] = _copy(value)
		end
		return setmetatable(new_table, getmetatable(object))
	end
	return _copy(object)
end



function widget:UnitCreated(unitID, unitDefID, unitTeam) --//record all Area Shield unit into "areaShieldUnit". 
	if unitTeam ~= team then
		return
	end
	local unitDef = UnitDefs[unitDefID]
	if (unitDef ~= nil) then
		for i=1, #shieldUnitName,1 do
			if enableEcho then Spring.Echo(unitDef.name .. " " .. shieldUnitName[i]) end
			if (unitDef.name == shieldUnitName[i]) then
				shieldSpeed = unitDef.speed/30
				--local waits = shieldWait[unitDef.name]
				if enableEcho then Spring.Echo("areaShield Insert") end
				areaShieldUnit[unitID] = {guardedBy = {},} --waits = waits,}
				areaShieldCount = areaShieldCount +1
				break
			end
		end
	end
end

-----------------------
--Remove shield or follower_to_areaShieldUnit_meta

function RemoveTableEntry(unitIDTable, index, metaTable) --//will remove an entry and then fill the void with entry from the top index
	local normalEntry = true
	local endOfTable = #unitIDTable
	if index == endOfTable then normalEntry = false end--//check if index is on the endOfTable or not. If is endOfTable then just remove entry and done.
	metaTable[unitIDTable[index] ] = nil --//empty the metaTable associated with current index
	unitIDTable[index] = nil --//empty the current index
	if normalEntry then
		unitIDTable[index] = unitIDTable[endOfTable] --//move endOfTable entry to the current index
		local unitID = unitIDTable[endOfTable]
		metaTable[unitID].positionInTable = index --//after moving unitID to current index: also update its meta table accordingly.
		unitIDTable[endOfTable] = nil
	end
	return unitIDTable, metaTable
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
	if areaShieldUnit[unitID] then -- remove Area Shield unit from record
		for i=1, #areaShieldUnit[unitID].guardedBy, 1 do
			local followerID = areaShieldUnit[unitID].guardedBy[i]
			follower_to_areaShieldUnit_meta[followerID] = nil
		end
		areaShieldUnit[unitID] = nil
		areaShieldCount = areaShieldCount -1
	end
  
	if follower_to_areaShieldUnit_meta[unitID] then -- clear the mapping between AreaShield unit and follower's unitID.
		local areaShieldUnitID = follower_to_areaShieldUnit_meta[unitID].areaShieldUnitID
		local positionInTable =  follower_to_areaShieldUnit_meta[unitID].positionInTable
		local guardedBy = areaShieldUnit[areaShieldUnitID].guardedBy
		guardedBy, follower_to_areaShieldUnit_meta = RemoveTableEntry(guardedBy, positionInTable, follower_to_areaShieldUnit_meta) --//remove table entry & metaTable entry and fill the space
		areaShieldUnit[areaShieldUnitID].guardedBy = guardedBy --//update the "guardedBy" table with the latest changes
	end
end

-----------------------
--Add/Remove shield or follower_to_areaShieldUnit_meta if given/taken

function widget:UnitTaken(unitID, unitDefID, oldTeam, newTeam)
  
  if (newTeam == team) then
	widget:UnitCreated(unitID, unitDefID, newTeam)
  end
  
  if (oldTeam == team) then
	widget:UnitDestroyed(unitID, unitDefID, newTeam)
  end
  
end

-----------------------
--Add shield names to array

function widget:Initialize() 
  
  local units = spGetTeamUnits(team)
  for i, id in ipairs(units) do 
	widget:UnitCreated(id, spGetUnitDefID(id),team)
  end
	
end
--]]
--Previous implementation (for future reference). It work by sending several individual command every half a second, but this might be considered a spam by Spring and is causing user command to be delayed (probably able to use "spGiveOrderToUnitArray" to fix but not tested yet).

function widget:GetInfo()
	return {
		name	  = "Shield Guard",
		desc	  = "Replaces guarding mobile shields with follow. Shields move at speed of slowest unit following and wait for stragglers.",
		author    = "Google Frog",
		date	  = "9 Mar, 2009",
		license   = "GNU GPL, v2 or later",
		layer	 = 5,
		enabled   = true --  loaded by default?
	}
end


-- Speedups
VFS.Include("LuaRules/Configs/customcmds.h.lua")
local CMD_WAIT = CMD.WAIT
local CMD_STOP = CMD.STOP
local CMD_GUARD = CMD.GUARD
local CMD_SET_WANTED_MAX_SPEED = CMD.SET_WANTED_MAX_SPEED

local CMD_OPT_SHIFT = CMD.OPT_SHIFT
local CMD_OPT_RIGHT = CMD.OPT_RIGHT

local CMD_INSERT = CMD.INSERT
local CMD_REMOVE = CMD.REMOVE

local EMPTY_TABLE = {}
local TABLE_1 = {1}

local spGiveOrderToUnit = Spring.GiveOrderToUnit

local spGetUnitPosition     = Spring.GetUnitPosition
local spGetSelectedUnits    = Spring.GetSelectedUnits
local spValidUnitID         = Spring.ValidUnitID
local spGetUnitDefID        = Spring.GetUnitDefID
local spGetUnitCurrentCommand = Spring.GetUnitCurrentCommand
local spGetTeamUnits        = Spring.GetTeamUnits
local spGetUnitSeparation   = Spring.GetUnitSeparation

VFS.Include("LuaRules/Utilities/ClampPosition.lua")
local GiveClampedOrderToUnit = Spring.Utilities.GiveClampedOrderToUnit

local team = Spring.GetMyTeamID()

local shields = {}
local follower = {}

----------------------------
--  CONFIG

local shieldRangeSafety = 20 -- how close to the edge shields should wait at
local shieldReactivateRange = 100 -- how far from the edge shields should reactivate at
local shieldieeStopDis = 120 -- how far from the shield the shieldiees should stop

local shieldRadius = {shieldshield = 300, shieldassault = 80, shieldcon = 80}
local shieldWait = {shieldshield = true, shieldassault = false, shieldcon = false}

local shieldArray = { 
	"shieldassault",
	"shieldcon",
}


----------------------------
--  Removes all CMD_SET_WANTED_MAX_SPEED from unitIDs queue

--local function removeSetMaxSpeed(unit)
 
----------------------------
-- Update shield info and wait if units are lagging behind

local function updateShields()
	for unit, i in pairs(shields) do
		i.ux,i.uy,i.uz = spGetUnitPosition(unit)
		if i.waits then
			spGiveOrderToUnit(unit, CMD_REMOVE, TABLE_1, CMD.OPT_ALT)
			
			-- Prevent the shield from outpacing its units
			if CMD_SET_WANTED_MAX_SPEED then
				spGiveOrderToUnit(unit, CMD_INSERT, {1, CMD_SET_WANTED_MAX_SPEED, CMD.OPT_RIGHT, i.maxVel }, CMD.OPT_ALT)
			else
				spGiveOrderToUnit(unit, CMD_WANTED_SPEED, {i.maxVel*30}, 0)
			end
			local cmdID = spGetUnitCurrentCommand(unit)

			if cmdID and (i.folCount ~= 0) then
				local wait = (cmdID == CMD_WAIT)
				if wait then
					wait = false
					for cid, j in pairs(i.shieldiees) do
						local dis = spGetUnitSeparation(unit,cid)
						if dis > i.reactiveRange then
							wait = true
						end
					end
					
					if (not wait) then
						spGiveOrderToUnit(unit,CMD_WAIT, EMPTY_TABLE, CMD_OPT_RIGHT)
					end
				else
					wait = false
					for cid, j in pairs(i.shieldiees) do
						local dis = spGetUnitSeparation(unit,cid)
						if dis > i.range then
							wait = true
						end
					end
					
					if wait then
						spGiveOrderToUnit(unit,CMD_WAIT, EMPTY_TABLE, CMD_OPT_RIGHT)
					end
				end
			end
		end
	end
  
end


----------------------------
-- Update shield info and wait if units are lagging behind

local function updateFollowers()
	for unit, v in pairs(follower) do
		if (v.fol) then -- give move orders to shieldiees
			local dis = spGetUnitSeparation(unit,v.fol)
			if dis > v.range then
				GiveClampedOrderToUnit(unit,CMD_RAW_MOVE,{shields[v.fol].ux,shields[v.fol].uy,shields[v.fol].uz},CMD_OPT_RIGHT)
			elseif (shieldieeStopDis < dis) then
				GiveClampedOrderToUnit(unit,CMD_RAW_MOVE,{shields[v.fol].ux,shields[v.fol].uy,shields[v.fol].uz},CMD_OPT_RIGHT)
			else
				spGiveOrderToUnit(unit,CMD_STOP, EMPTY_TABLE, CMD_OPT_RIGHT)
			end
		end
	end
end

-- update following and shield

function widget:GameFrame(n)
	if (n%15<1) then 
		updateShields()
		updateFollowers()
	end
end 


----------------------------
-- Add/remove shielded
-- Override and add units guarding shields

local function ProcessNotify(sid)
	if follower[sid] then
		local c = shields[follower[sid].fol]
		c.shieldiees[sid] = nil
		if c.maxVelID == sid then
			c.maxVel = c.selfVel
			c.maxVelID = -1
			if CMD_SET_WANTED_MAX_SPEED then
				spGiveOrderToUnit(follower[sid].fol, CMD_INSERT, {1, CMD_SET_WANTED_MAX_SPEED, CMD.OPT_RIGHT, c.selfVel }, CMD.OPT_ALT)
			else
				spGiveOrderToUnit(follower[sid].fol, CMD_WANTED_SPEED, {c.selfVel*30}, 0)
			end
			for cid, j in pairs(c.shieldiees) do
				if j.vel < c.maxVel then
					c.maxVel = j.vel
					c.maxVelID = cid
				end
			end
		end
		c.folCount = c.folCount-1
		follower[sid] = nil
	end
end

function widget:UnitCommandNotify(unitID, cmdID, params, options)
	ProcessNotify(unitID)
end

function widget:CommandNotify(id, params, options)
	local units = spGetSelectedUnits()
	for _,sid in ipairs(units) do
		ProcessNotify(sid)
	end

	if (id == CMD_GUARD) then
		local uid = params[1]
		for cid,v in pairs(shields) do
			if (uid == cid) then
				for _,sid in ipairs(units) do
					local ud = UnitDefs[spGetUnitDefID(sid)]
					if ud.canMove and not ud.isFactory and ud.buildSpeed == 0 then
						local speed = ud.speed/30
						if speed < v.maxVel then
							v.maxVel = speed
							v.maxVelID = sid
						end
						follower[sid] = {
							fol = cid, 
							vel = speed,
							range = v.range
						}
						v.shieldiees[sid] = follower[sid]
						v.folCount = v.folCount+1
					else
						spGiveOrderToUnit(sid, id, params, options)	
					end
				end
				return true
			end
		end
	end

end

-----------------------
--Add shield

function widget:UnitCreated(unitID, unitDefID, unitTeam)
	if unitTeam ~= team then
		return
	end
	local ud = UnitDefs[unitDefID]

	if (ud ~= nil) then
		for i, name in pairs(shieldArray) do
			if (ud.name == name) then
				local ux,uy,uz = spGetUnitPosition(unitID)
				local speed = ud.speed/30
				local shieldRange = shieldRadius[ud.name]
				local waits = shieldWait[ud.name]
				shields[unitID] = {
					id = unitID, ux = ux, uy = uy, uz = uz, 
					range = shieldRange-shieldRangeSafety, 
					reactiveRange = shieldRange-shieldReactivateRange, 
					shieldiees = {},
					folCount = 0,
					waits = waits,
					selfVel = speed, 
					maxVel = speed,
					maxVelID = -1
				}
				break
			end
		end
	end
end

-----------------------
--Remove shield or follower

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
	local ud = UnitDefs[unitDefID]
	if shields[unitID] then -- remove shield
		for fid, j in pairs(shields[unitID].shieldiees) do
			follower[fid] = nil
		end
		shields[unitID] = nil
	end

	if follower[unitID] then -- remove follower
		local c = shields[follower[unitID].fol]
		c.shieldiees[unitID] = nil
		if c.maxVelID == unitID then
			c.maxVel = c.selfVel
			c.maxVelID = -1
			if CMD_SET_WANTED_MAX_SPEED then
				spGiveOrderToUnit(follower[unitID].fol, CMD_INSERT, {1, CMD_SET_WANTED_MAX_SPEED, CMD.OPT_RIGHT, c.selfVel }, CMD.OPT_ALT)
			else
				spGiveOrderToUnit(follower[sid].fol, CMD_WANTED_SPEED, {c.selfVel*30}, 0)
			end
			for cid, j in pairs(c.shieldiees) do
				if j.vel < c.maxVel then
					c.maxVel = j.vel
					c.maxVelID = cid
				end
			end
		end
		c.folCount = c.folCount-1
		follower[unitID] = nil
	end
end

-----------------------
--Add/Remove shield or follower if given/taken

function widget:UnitTaken(unitID, unitDefID, oldTeam, newTeam)
	if (newTeam == team) then
		widget:UnitCreated(unitID, unitDefID, newTeam)
	end

	if (oldTeam == team) then
		widget:UnitDestroyed(unitID, unitDefID, newTeam)
	end
end

-----------------------
--Add shield names to array

function widget:Initialize() 
	local units = spGetTeamUnits(team)
	for i, id in ipairs(units) do 
		widget:UnitCreated(id, spGetUnitDefID(id),team)
	end
end


