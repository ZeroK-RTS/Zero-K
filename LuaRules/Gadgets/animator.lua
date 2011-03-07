------------------------


function gadget:GetInfo()
  return {
    name      = "Animator",
    desc      = "Moves and turns pieces.",
    author    = "CarRepairer & knorke",
    date      = "2010-03-05",
    license   = "raubkopierer sind verbrecher",
    layer     = 0,
    enabled   = true,
  }
end


local function tobool(val)
  local t = type(val)
  if (t == 'nil') then
    return false
  elseif (t == 'boolean') then
    return val
  elseif (t == 'number') then
    return (val ~= 0)
  elseif (t == 'string') then
    return ((val ~= '0') and (val ~= 'false'))
  end
  return false
end

local animationMode = tobool(Spring.GetModOptions().animation)
if not animationMode then return end


local echo = Spring.Echo

if (gadgetHandler:IsSyncedCode()) then

Spring.SetGameRulesParam('animation', 1)


local function explode(div,str)
  if (div=='') then return false end
  local pos,arr = 0,{}
  -- for each divider found
  for st,sp in function() return string.find(str,div,pos,true) end do
    table.insert(arr,string.sub(str,pos,st-1)) -- Attach chars left of current divider
    pos = sp + 1 -- Jump past current divider
  end
  table.insert(arr,string.sub(str,pos)) -- Attach chars right of last divider
  return arr
end


local function WriteCurrent( unitID )
	local env = Spring.UnitScript.GetScriptEnv(unitID)
	if not env then return end
		
	local allpieces = Spring.GetUnitPieceMap(unitID)	
	local s = "function POSENAME (mspeed, tspeed)\n"
	
	for pname,pid in pairs(allpieces) do
		
		--local pieceInfo = Spring.GetUnitPieceInfo( unitID, pid )
		--local pname = pieceInfo.name
		
		--local mx,my,mz = Spring.UnitScript.GetPieceTranslation (p)
		
		local rx,ry,rz = Spring.UnitScript.CallAsUnit(unitID, Spring.UnitScript.GetPieceRotation, 		pid)
		local px,py,pz = Spring.UnitScript.CallAsUnit(unitID, Spring.UnitScript.GetPieceTranslation,	pid)
		-- [[
		s=s.. "\tMove (" .. pname .. ", x_axis, " ..px ..", mspeed)\n"
		s=s.. "\tMove (" .. pname .. ", y_axis, " ..py ..", mspeed)\n"
		s=s.. "\tMove (" .. pname .. ", z_axis, " ..pz ..", mspeed)\n"
		
		s=s.. "\tTurn (" .. pname .. ", x_axis, math.rad(" .. math.deg(rx) .."), tspeed)\n"
		s=s.. "\tTurn (" .. pname .. ", y_axis, math.rad(" .. math.deg(ry) .."), tspeed)\n"
		s=s.. "\tTurn (" .. pname .. ", z_axis, math.rad(" .. math.deg(rz) .."), tspeed)\n"
		--]]
	end
	s=s.. "end"
	echo (s)
end

local function Reset(unitID)
	local env = Spring.UnitScript.GetScriptEnv(unitID)
	if env and Spring.UnitScript.GetPieceRotation then
		local allpieces = Spring.GetUnitPieceMap(unitID)	
		
		for pname,pid in pairs(allpieces) do
			for axisnum = 1,3 do
				Spring.UnitScript.CallAsUnit(unitID, Spring.UnitScript.Move, 	pid, axisnum, 0 )
				Spring.UnitScript.CallAsUnit(unitID, Spring.UnitScript.Turn, 	pid, axisnum, 0 )
			end
		end
	end
end
  
function gadget:RecvLuaMsg(msg, playerID)
	--echo (msg)
	pre = "tpkey" --boxxy
	--if (msg:find(pre,1,true)) then Spring.Echo ("its a loveNtrolls message") end
	local data = explode( '|', msg )
	
	
	if data[1] ~= pre then return end
	
	local cmd = data[2]
	
	local param1 = data[3]
	local param2 = data[4]
	local param3 = data[5]
	local param4 = data[6]
	
	
	if cmd == 'sel' and param1 then
		local unitID = param1+0 --convert to int!
		euID = unitID 
		--Spring.Echo ("now editing: " .. euID)
		
	elseif cmd == 'getpieceinfo' and param1 and param2 then
		local unitID = param1+0 --convert to int!
		local pieceNum = param2+0 --convert to int!
		local env = Spring.UnitScript.GetScriptEnv(unitID)
		if env and Spring.UnitScript.GetPieceRotation then
		
			local rx,ry,rz = Spring.UnitScript.CallAsUnit(unitID, Spring.UnitScript.GetPieceRotation, 		pieceNum)
			local px,py,pz = Spring.UnitScript.CallAsUnit(unitID, Spring.UnitScript.GetPieceTranslation,	pieceNum)
			local pieceInfo = {rx, ry, rz, 		px,py,pz}
			SendToUnsynced("PieceInfo", table.concat(pieceInfo,'|') )
		end
	elseif cmd == 'move' or cmd == 'turn' then
		local axis = param1
		local unitID = param2+0 --convert to num!
		local pieceNum = param3+0 --convert to num!
		local val = param4+0 --convert to num!
		
		local axisnum = 1
		if axis == 'y' then
			axisnum = 2
		elseif axis == 'z' then
			axisnum = 3
		end
		
		local env = Spring.UnitScript.GetScriptEnv(unitID)
		if env then
			if cmd == 'move' then
				Spring.UnitScript.CallAsUnit(unitID, Spring.UnitScript.Move, 	pieceNum, axisnum, val )
			elseif cmd == 'turn' then
				Spring.UnitScript.CallAsUnit(unitID, Spring.UnitScript.Turn, 	pieceNum, axisnum, val )
			end
			
			echo("> " ..  cmd .. ' on ' .. axis .. '-axis to ' .. val)
		end
	elseif cmd == 'write' then
		local unitID = param1+0 --convert to num!
		WriteCurrent(unitID)
	
	elseif cmd == 'reset' then
		local unitID = param1+0 --convert to num!
		Reset(unitID)
		
	end
	
	--Spring.Echo ("RecvLuaMsg: " .. msg .. " from " .. playerID)
	
end


function gadget:Initialize()
end


else -- ab hier unsync

local function PieceInfo(_, pieceInfo)
    Script.LuaUI.PieceInfo(pieceInfo)
end

function gadget:Initialize()
	gadgetHandler:AddSyncAction("PieceInfo", PieceInfo)
end

function gadget:Shutdown()
	gadgetHandler:RemoveSyncAction("PieceInfo")
end


end