-- $Id: gui_commandinsert.lua 3171 2008-11-06 09:06:29Z det $
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
local version= "1.003"
function widget:GetInfo()
  return {
    name = "CommandInsert",
    desc = "[v" .. version .. "] Allow you to add command into existing queue. Based on FrontInsert by jK"..
			"\n• SPACEBAR+SHIFT insert command to arbitrary places in queue."..
			"\n• SPACEBAR insert command in front of queue.",
	author = "dizekat",
    date = "Jan,2008", --16 October 2013
    license = "GNU GPL, v2 or later",
    layer = 5,
    enabled = true,
    api = true,
    hidden = true,
  }
end

VFS.Include("LuaRules/Configs/customcmds.h.lua")

--[[
-- use this for debugging:
function table.val_to_str ( v )
  if "string" == type( v ) then
    v = string.gsub( v, "\n", "\\n" )
    if string.match( string.gsub(v,"[^'\"]",""), '^"+$' ) then
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



local function GetUnitOrFeaturePosition(id)
	if id<=Game.maxUnits then
		return Spring.GetUnitPosition(id)
	else
		return Spring.GetFeaturePosition(id-Game.maxUnits)
	end
end

local function GetCommandPos(command)	--- get the command position
  if command.id<0 or command.id==CMD.MOVE or command.id==CMD.REPAIR or command.id==CMD.RECLAIM or 
  command.id==CMD.RESURRECT or command.id==CMD.MANUALFIRE or command.id==CMD.GUARD or 
  command.id==CMD.FIGHT or command.id==CMD.ATTACK or command.id == CMD_JUMP or command.id == CMD_LEVEL then
    if table.getn(command.params)>=3 then
		  return command.params[1], command.params[2], command.params[3]			
	  elseif table.getn(command.params)>=1 then
		  return GetUnitOrFeaturePosition(command.params[1])
	  end	
	end
  return -10,-10,-10
end

local function ProcessCommand(id, params, options, sequence_order)
  local alt,ctrl,meta,shift = Spring.GetModKeyState() --must use this because "options" table turn into different format when right+click. Similar problem with different trigger see: https://code.google.com/p/zero-k/issues/detail?id=1824 (options in online game coded different than in local game)
  if (ctrl) and not (meta) and id==CMD.REPAIR then
	local opt = 0
	if options.alt or alt then opt = opt + CMD.OPT_ALT end
	opt = opt + CMD.OPT_META
	if options.right then opt = opt + CMD.OPT_RIGHT end
	if options.shift or shift then opt = opt + CMD.OPT_SHIFT end
	Spring.GiveOrder(id,params,opt)
	return true
  end
  if (meta) then
    local opt = 0
    local insertfront=false
    if options.alt or alt then opt = opt + CMD.OPT_ALT end
	if options.ctrl or ctrl then
		if id == CMD.REPAIR then  
			opt = opt + CMD.OPT_META
		else
			opt = opt + CMD.OPT_CTRL
		end
	end
    if options.right then opt = opt + CMD.OPT_RIGHT end
    if options.shift or shift then 
      opt = opt + CMD.OPT_SHIFT       
    else
      Spring.GiveOrder(CMD.INSERT,{sequence_order or 0,id,opt,unpack(params)},{"alt"})
      return true
    end
    
    -- Spring.GiveOrder(CMD.INSERT,{0,id,opt,unpack(params)},{"alt"})
    local my_command={["id"]=id,["params"]=params}
    local cx,cy,cz=GetCommandPos(my_command)
    if cx < -1 then
      return false
    end
    
    local units=Spring.GetSelectedUnits()
    for i, unit_id in ipairs(units) do
      local commands=Spring.GetCommandQueue(unit_id, -1)
      local px,py,pz=Spring.GetUnitPosition(unit_id)
      local min_dlen=1000000
      local insert_tag=0
      local insert_pos=0
      for j=1, #commands do
        local command = commands[j]
        --Spring.Echo("cmd:"..table.tostring(command))
        local px2,py2,pz2=GetCommandPos(command)
        if px2>-1 then
          local dlen=math.sqrt(((px2-cx)^2)+((py2-cy)^2)+((pz2-cz)^2))+math.sqrt(((px-cx)^2)+((py-cy)^2)+((pz-cz)^2)) - math.sqrt((((px2-px)^2)+((py2-py)^2)+((pz2-pz)^2)))
          --Spring.Echo("dlen "..dlen)
          if dlen<min_dlen then
            min_dlen=dlen
            insert_tag=command.tag
            insert_pos=j
          end
          px,py,pz=px2,py2,pz2
        end   
      end
      -- check for insert at end of queue if its shortest walk.
      local dlen=math.sqrt(((px-cx)^2)+((py-cy)^2)+((pz-cz)^2))          
      if dlen<min_dlen then
        --options.meta=nil
        --options.shift=true
        --Spring.GiveOrderToUnit(unit_id,id,params,options)
        Spring.GiveOrderToUnit(unit_id,id,params,{"shift"})
      else   
        Spring.GiveOrderToUnit(unit_id,CMD.INSERT,{insert_pos - 1 + (sequence_order or 0),id,opt,unpack(params)},{"alt"})
      end
    end
    return true
  end
  return false
end 

function widget:CommandNotify(id, params, options)
  return ProcessCommand(id, params, options)
end

local shift_table = {"shift"}
function WG.CommandInsert(id, params, options, seq)
	if not ProcessCommand(id, params, options, seq) then
		Spring.GiveOrder(id, params, (seq or 0) > 0 and shift_table or options)
	end
end
