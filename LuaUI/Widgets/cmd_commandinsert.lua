-- $Id: gui_commandinsert.lua 3171 2008-11-06 09:06:29Z det $
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
local version= "1.003"
function widget:GetInfo()
	return {
		name = "CommandInsert",
		desc = "[v" .. version .. "] Allow you to add command into existing queue. Based on FrontInsert by jK" ..
		  "\n• SPACEBAR + SHIFT insert command to arbitrary places in queue." ..
		  "\n• SPACEBAR insert command in front of queue.",
		author = "dizekat, GoogleFrog (structure block order)",
		date = "Jan,2008", --16 October 2013
		license = "GNU GPL, v2 or later",
		layer = 5,
		enabled = true,
		api = true,
	}
end

VFS.Include("LuaRules/Configs/customcmds.h.lua")

local CMD_OPT_ALT = CMD.OPT_ALT
local CMD_OPT_CTRL = CMD.OPT_CTRL
local CMD_OPT_META = CMD.OPT_META
local CMD_OPT_SHIFT = CMD.OPT_SHIFT
local CMD_OPT_RIGHT = CMD.OPT_RIGHT

local positionCommand = {
	[CMD.MOVE] = true,
	[CMD_RAW_MOVE] = true,
	[CMD_RAW_BUILD] = true,
	[CMD.REPAIR] = true,
	[CMD.RECLAIM] = true,
	[CMD.RESURRECT] = true,
	[CMD.MANUALFIRE] = true,
	[CMD.GUARD] = true,
	[CMD.FIGHT] = true,
	[CMD.ATTACK] = true,
	[CMD_JUMP] = true,
	[CMD_LEVEL] = true,
}

local EMPTY_TABLE = {}
--[[
-- use this for debugging:
function table.val_to_str ( v )
	if "string" == type( v ) then
		v = string.gsub( v, "\n", "\\n" )
		if string.match( string.gsub(v,"[^'\"]",""), '^" + $' ) then
			return "'" .. v .. "'"
		end
		return '"' .. string.gsub(v,'"', '\\"' ) .. '"'
	else
		return "table" == type( v ) and table.tostring( v ) or
			tostring( v )
	end
end

function table.key_to_str ( k )
	if "string" == type( k ) and string.match( k, "^[_%a][_%a%d]*$" ) then
		return k
	else
		return "[" .. table.val_to_str( k ) .. "]"
	end
end

function table.tostring( tbl )
	local result, done = {}, {}
	for k, v in ipairs( tbl ) do
		table.insert( result, table.val_to_str( v ) )
		done[ k ] = true
	end
	for k, v in pairs( tbl ) do
		if not done[ k ] then
			table.insert( result,
				table.key_to_str( k ) .. "=" .. table.val_to_str( v ) )
		end
	end
	return "{" .. table.concat( result, "," ) .. "}"
end
--]]

-- Place the structure commands in the order issued by the user.
local structureSquenceCount

-- Use the first position in a block of structure commands as the command position
-- to keep the block together.
local structOverrideX, structOverrideY, structOverrideZ

local function GetUnitOrFeaturePosition(id)
	if id <= Game.maxUnits then
		return Spring.GetUnitPosition(id)
	else
		return Spring.GetFeaturePosition(id - Game.maxUnits)
	end
end

local function GetCommandPos(command) -- get the command position
	if command.id < 0 or positionCommand[command.id] then
		if #command.params >= 3 then
			return command.params[1], command.params[2], command.params[3]
		elseif #command.params >= 1 then
			local x, y, z = GetUnitOrFeaturePosition(command.params[1])
			if x then
				return x, y, z
			else
				return -10,-10,-10
			end
		end	
	end
	return -10,-10,-10
end

local function ProcessCommand(id, params, options, sequence_order)

	local cx, cy, cz -- command position
	local setPositionOverride = false

	-- Structure block checking
	-- Note that Area Mex will queue a bunch of mexes at the same time
	-- which looks a lot like a block, but it can be told apart because
	-- unlike blocks queued by hand (i.e. through the default engine UI)
	-- automex supplies non-zero sequence order
	local shift = options.shift
	if shift and id < 0 and sequence_order == 0 then
		-- If the command is possibly part of a block of structures
		if structureSquenceCount then
			structureSquenceCount = structureSquenceCount + 1
			cx, cy, cz = structOverrideX, structOverrideY, structOverrideZ
		else
			setPositionOverride = true
			structureSquenceCount = 0
		end
		sequence_order = structureSquenceCount
	end
	
	-- Redefine the way in which modifiers apply to Area- Repair and Rez
	local ctrl = options.ctrl
	local meta = options.meta
	if ctrl and not meta and id == CMD.REPAIR then
		-- Engine CTRL means "keep repairing even when being reclaimed" (now inaccessible)
		-- Engine META means "only repair live units, don't assist construction" (now CTRL)
		Spring.GiveOrder(id, params, options.coded - CMD.OPT_CTRL + CMD.OPT_META)
		return true
	end
	if not meta and id == CMD.RESURRECT then
		-- Engine CTRL means "keep rezzing even when being reclaimed" (now inaccessible)
		-- Engine META means "only rez fresh wrecks, don't refill partially-reclaimed" (now default, CTRL disables)
		Spring.GiveOrder(id, params, options.coded - (ctrl and CMD.OPT_CTRL or 0) + (ctrl and 0 or CMD.OPT_META))
		return true
	end

	-- Command insert
	if meta then
		local coded = options.coded
		if id == CMD.REPAIR and ctrl then
			coded = coded - CMD.OPT_CTRL
		elseif id == CMD.RESURRECT then
			if ctrl then
				coded = coded - CMD.OPT_CTRL - CMD.OPT.META
			else
				coded = coded
			end
		else
			coded = coded - CMD.OPT_META
		end

		if not shift then
			Spring.GiveOrder(CMD.INSERT, {sequence_order, id, coded, unpack(params)}, CMD.OPT_ALT)
			return true
		end

		local my_command = {["id"] = id, ["params"] = params}
		if not cx then
			-- cx has a value if it has been overridden
			cx, cy, cz = GetCommandPos(my_command)
		end
		--Spring.Echo("cx, cy, cz", cx, cy, cz)
		if setPositionOverride then
			structOverrideX, structOverrideY, structOverrideZ = cx, cy, cz
		end
		if cx < -1 then
			return false
		end
		
		-- Insert the command at the appropriate spot in each selected units queue.
		local units = Spring.GetSelectedUnits()
		for i = 1, #units do
			local unitID = units[i]
			local commands = Spring.GetCommandQueue(unitID, -1)
			local px,py,pz = Spring.GetUnitPosition(unitID)
			local min_dlen = 1000000
			local insert_pos = 0
			for j = 1, #commands do
				local command = commands[j]
				--Spring.Echo("cmd:"..table.tostring(command))
				local px2, py2, pz2 = GetCommandPos(command)
				if px2 > -1 then
					-- dlen is the change in travel distance if the command is inserted at this position.
					local dlen = math.sqrt(((px2-cx)^2) + ((py2-cy)^2) + ((pz2-cz)^2)) + math.sqrt(((px-cx)^2) + ((py-cy)^2) + ((pz-cz)^2)) - math.sqrt((((px2-px)^2) + ((py2-py)^2) + ((pz2-pz)^2)))
					--Spring.Echo("dlen", #commands, dlen, min_dlen, px, py, pz, px2, py2, pz2, cx, cy, cz)
					if dlen < min_dlen then
						min_dlen = dlen
						insert_pos = j - 1
					end
					px, py, pz = px2, py2, pz2
				end	 
			end
			-- check for insert at end of queue if its shortest walk.
			local dlen = math.sqrt(((px-cx)^2) + ((py-cy)^2) + ((pz-cz)^2))
			--Spring.Echo("insert_pos", insert_pos, sequence_order, dlen, min_dlen)
			if dlen < min_dlen then
				insert_pos = #commands
			end
			Spring.GiveOrderToUnit(unitID, CMD.INSERT, {insert_pos + sequence_order, id, coded, unpack(params)}, CMD.OPT_ALT)
		end
		return true
	end
	return false
end

function widget:Update()
	if structureSquenceCount then
		structureSquenceCount = nil
	end
end

function widget:CommandNotify(id, params, options)
	return ProcessCommand(id, params, options, 0)
end

local function EncodeOptions(options)
	local coded = 0
	if options.alt   then coded = coded + CMD_OPT_ALT   end
	if options.ctrl  then coded = coded + CMD_OPT_CTRL  end
	if options.meta  then coded = coded + CMD_OPT_META  end
	if options.shift then coded = coded + CMD_OPT_SHIFT end
	if options.right then coded = coded + CMD_OPT_RIGHT end
	return coded
end

function WG.CommandInsert(id, params, options, seq)
	options.coded = (options.coded or EncodeOptions(options))
	seq = seq or 0

	if ProcessCommand(id, params, options, seq) then
		return
	end

	if not options.shift then
		if seq == 0 then
			-- ProcessCommand ensures that META is also false at this point
			Spring.GiveOrder (id, params, options.coded)
			return
		end

		-- Technically a SHIFT is not needed, but if you try to copy a queue with a shiftless
		-- order in it verbatim (i.e. without appending missing SHIFT manually) it will erase
		-- anything before it; as far as I can tell some other gadgets/widgets behave that way.
		-- At some point it would be good to fix them (TODO) but until then here's a workaround.
		options.shift = true
		options.coded = options.coded + CMD_OPT_SHIFT
	end

	local units = Spring.GetSelectedUnits()
	for i = 1, #units do
		local unitID = units[i]
		local commands = Spring.GetCommandQueue(unitID, 0)
		if commands then
			Spring.GiveOrderToUnit(unitID, CMD.INSERT, {commands + seq, id, options.coded, unpack(params)}, CMD.OPT_ALT)
		end
	end
end
