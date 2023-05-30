------------------------


function gadget:GetInfo()
  return {
    name      = "Animator",
    desc      = "v0.002 Moves and turns pieces.",
    author    = "CarRepairer & knorke",
    date      = "2010-03-05",
    license   = "raubkopierer sind verbrecher",
    layer     = 0,
    enabled   = false,
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

local devMode = tobool(Spring.GetModOptions().devmode)
--if not devMode then return end


local echo = Spring.Echo

if (gadgetHandler:IsSyncedCode()) then

local function WriteCurrent( unitID )
	local env = true -- Spring.UnitScript.GetScriptEnv(unitID)
	if not env then return end
		
	local allpieces = Spring.GetUnitPieceMap(unitID)
	local s = "function POSENAME (mspeed, tspeed)\n"
	
	local allpieces2 = {}
	for pname,pid in pairs(allpieces) do
		allpieces2[#allpieces2+1] = { pname,pid }
	end
	table.sort(allpieces2, function(a,b) return a[1] < b[1]; end )
	
	local unitDefID = Spring.GetUnitDefID(unitID)
	local swapYandZ = UnitDefs[unitDefID].model.type ~= 's3o'
	
	--for pname,pid in pairs(allpieces) do
	for _,item in pairs(allpieces2) do
		local pname = item[1]
		local pid = item[2]
		
		--local pieceInfo = Spring.GetUnitPieceInfo( unitID, pid )
		--local pname = pieceInfo.name
		
		--local mx,my,mz = Spring.UnitScript.GetPieceTranslation (p)
		
		local rx,ry,rz = Spring.UnitScript.CallAsUnit(unitID, Spring.UnitScript.GetPieceRotation, 		pid)
		local px,py,pz = Spring.UnitScript.CallAsUnit(unitID, Spring.UnitScript.GetPieceTranslation,	pid)
		-- [[
		s=s.. "\tMove (" .. pname .. ", x_axis, " ..px ..", mspeed)\n"
		s=s.. "\tMove (" .. pname .. ", y_axis, " ..py ..", mspeed)\n"
		s=s.. "\tMove (" .. pname .. ", z_axis, " ..pz ..", mspeed)\n"
		
		if swapYandZ then
			s=s.. "\tTurn (" .. pname .. ", x_axis, math.rad(" .. math.deg(rx) .."), tspeed)\n"
			s=s.. "\tTurn (" .. pname .. ", y_axis, math.rad(" .. math.deg(rz) .."), tspeed)\n"
			s=s.. "\tTurn (" .. pname .. ", z_axis, math.rad(" .. math.deg(ry) .."), tspeed)\n"
		else
			s=s.. "\tTurn (" .. pname .. ", x_axis, math.rad(" .. math.deg(rx) .."), tspeed)\n"
			s=s.. "\tTurn (" .. pname .. ", y_axis, math.rad(" .. math.deg(ry) .."), tspeed)\n"
			s=s.. "\tTurn (" .. pname .. ", z_axis, math.rad(" .. math.deg(rz) .."), tspeed)\n"
		end
		--]]
	end
	s=s.. "end"
	echo (s)
end

local function Reset(unitID)
	local env = true -- Spring.UnitScript.GetScriptEnv(unitID)
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

local function CallUnitScript(unitID, funcName, ...)
	if Spring.UnitScript.GetScriptEnv(unitID) and Spring.UnitScript.GetScriptEnv(unitID).script[funcName] then
		Spring.UnitScript.CallAsUnit(unitID, Spring.UnitScript.GetScriptEnv(unitID).script[funcName], ...)
	end
end
  
function gadget:RecvLuaMsg(msg, playerID)
  
	if not Spring.IsCheatingEnabled() then return end
  
	--echo (msg)
	pre = "animator"
	--if (msg:find(pre,1,true)) then Spring.Echo ("its a loveNtrolls message") end
	local data = Spring.Utilities.ExplodeString( '|', msg )
	
	
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
		local env = true -- Spring.UnitScript.GetScriptEnv(unitID)
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
		
		local env = true --Spring.UnitScript.GetScriptEnv(unitID)
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
	
	elseif cmd == 'hide' then
		local unitID = param1+0 --convert to num!
		local pieceNum = param2+0 --convert to num!
		Spring.UnitScript.CallAsUnit(unitID, Spring.UnitScript.Hide, 	pieceNum )
	elseif cmd == 'show' then
		local unitID = param1+0 --convert to num!
		local pieceNum = param2+0 --convert to num!
		Spring.UnitScript.CallAsUnit(unitID, Spring.UnitScript.Show, 	pieceNum )
	
	elseif cmd == 'testthread' then
		local unitID = param1+0 --convert to num!
		CallUnitScript(unitID, "TestThread" )
	
	
	
	end
	
	--Spring.Echo ("RecvLuaMsg: " .. msg .. " from " .. playerID)
	
end


function gadget:Initialize()
	Spring.SetGameRulesParam('devmode', 1)
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
