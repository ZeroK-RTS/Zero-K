--THIS GOES IN YOUR GAME GADGETS FOLDER
function gadget:GetInfo()
  return {
    name      = "BOXXY R1 w volume type",
    desc      = "experiments with changing hitboxes ingame",
    author    = "knorke, modified by Google Frog (volume type)",
    date      = "dec 1010",
    license   = "raubkopierer sind verbrecher",
    layer     = 0,
    enabled   = false,
  }
end

local d = 10	--step size for moving/resizing

if (gadgetHandler:IsSyncedCode()) then
  KP0 = 256
  KP1 = 257
  KP2 = 258
  KP3 = 259
  KP4 = 260
  KP5 = 261
  KP6 = 262
  KP7 = 263
  KP8 = 264
  KP9 = 265

local euID = nil
--local boxxy = nil
  
function gadget:RecvLuaMsg(msg, playerID)
pre = "boxxy"
--if (msg:find(pre,1,true)) then Spring.Echo ("its a loveNtrolls message") end
local data = explode( '|', msg:sub(#pre+1) )
	local key = data[2]
	if (euID) then
		boxxy = ({Spring.GetUnitCollisionVolumeData (euID)})	
		if (key=="8") then boxxy[2]=boxxy[2]+d end
		if (key=="2") then boxxy[2]=boxxy[2]-d end
		if (key=="6") then boxxy[1]=boxxy[1]+d end
		if (key=="4") then boxxy[1]=boxxy[1]-d end
		if (key=="7") then boxxy[3]=boxxy[3]-d end
		if (key=="9") then boxxy[3]=boxxy[3]+d end
		if (key=="W") then boxxy[6]=boxxy[6]-d end
		if (key=="S") then boxxy[6]=boxxy[6]+d end
		if (key=="A") then boxxy[4]=boxxy[4]-d end
		if (key=="D") then boxxy[4]=boxxy[4]+d end
		if (key=="Q") then boxxy[5]=boxxy[5]-d end
		if (key=="E") then boxxy[5]=boxxy[5]+d end
		if (key=="5") then 
			if d==1 then d=10 else d = 1 end
			Spring.Echo ("now moving and scaling with stepsize=" .. d)
		end	
		if (key=="1") then 
			if boxxy[7] == 0 then
				boxxy[7] = 1
				boxxy[9] = 0
			elseif boxxy[7] == 1 then
				boxxy[9] = boxxy[9]+1
				if boxxy[9] > 2 then
					boxxy[7] = 2
				end
			elseif boxxy[7] == 2 then
				boxxy[7] = 0
			else 
				Spring.Echo("Cannot toggle volume with no collisionVolumeType in unitdef")
			end
		end		
		if (key=="3") then 
			if boxxy[7] == 0 then
				boxxy[7] = 2
			elseif boxxy[7] == 1 then
				boxxy[9]=boxxy[9]-1
				if boxxy[9] < 0 then
					boxxy[7] = 0
				end
			elseif boxxy[7] == 2 then
				boxxy[7] = 1
				boxxy[9] = 2
			else 
				Spring.Echo("Cannot toggle volume with no collisionVolumeType in unitdef")
			end
		end	
		if (key=="0") then
			if boxxy[8] == 1 then boxxy[8] = 0 else boxxy[8] = 1 end
		end		
		Spring.SetUnitCollisionVolumeData  (euID, unpack(boxxy))
		--for i,v in pairs(boxxy) do Spring.Echo (i,v) end
		printhitbox (boxxy)
	end
--Spring.Echo ("RecvLuaMsg: " .. msg .. " from " .. playerID)
	
end

function gadget:UnitFinished(unitID, unitDefID, teamID)
	euID = unitID
	Spring.Echo ("now editing: " .. euID)
	marker_on_unit (euID, "you can now edit the hitbox of this unit, press alt b to see it")
end



function printhitbox (box)
if (box) then
	local scaleX = box[1] or "nil"	local scaleY = box[2] or "nil"	local scaleZ = box[3] or "nil"
	local offsetX =box[4] or "nil"	local offsetY =box[5] or "nil"	local offsetZ =box[6] or "nil"
	local volumeTest = box[8] or "nil"
	local volumeType = "nil"
	if box[7] == 0 or box[7] == 4 then
		volumeType = "ellipsoid"
	elseif box[7] == 1 then
		if box[9] == 0 then
			volumeType = "CylX"
		elseif box[9] == 1 then
			volumeType = "CylY"
		else
			volumeType = "CylZ"
		end
	elseif box[7] == 2 then
		volumeType = "box"
	end
	
	Spring.Echo ("collisionVolumeScales		= [[" .. scaleX .. " " .. scaleY .. " " .. scaleZ .. "]],")
	Spring.Echo ("collisionVolumeOffsets	= [[" .. offsetX .. " " .. offsetY .. " " .. offsetZ .. "]],")
	Spring.Echo ("collisionVolumeTest	    = " .. volumeTest .. ",")
	Spring.Echo ("collisionVolumeType	    = [[" .. volumeType .. "]],")
 end
 --[[
 ( number unitID )
 -> number scaleX, number scaleY, number scaleZ,
 number offsetX, number offsetY, number offsetZ,
 number volumeType, number testType, number primaryAxis, boolean disabled
 ]]--

end

function gadget:Initialize()
	Spring.Echo ("BOXXY HERE U MAD?")
end


function explode(div,str)
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

function marker_on_unit (_uID, _text)
	if (_uID == nil) then return end
	if (_text == nil) then return end
	local x,y,z=Spring.GetUnitPosition (_uID)
	if (x == nil or y == nil or z == nil) then return end
	--Spring.MarkerAddPoint (x,y,z, _text .. "id:" .. _uID)
	Spring.MarkerAddPoint (x,y,z, _text)
end
else -- ab hier unsync


end