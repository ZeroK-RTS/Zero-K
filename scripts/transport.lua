local base = piece 'base' 


--New bits
local lUpperCl1 	= piece 'lUpperCl1'
local rUpperCl1 	= piece 'rUpperCl1'
local lLowerCl1 	= piece 'lLowerCl1'
local rLowerCl1 	= piece 'rLowerCl1'
local lUpperCl2 	= piece 'lUpperCl2'
local rUpperCl2 	= piece 'rUpperCl2'
local lLowerCl2 	= piece 'lLowerCl2'
local rLowerCl2 	= piece 'rLowerCl2'
local engineEmit 	= piece 'engineEmit'
local link 			= piece 'link'

local AttachUnit = Spring.UnitScript.AttachUnit
local DropUnit = Spring.UnitScript.DropUnit

local loaded = false
local unitLoaded = nil

local SIG_OPENDOORS = 1
local SIG_CLOSEDOORS = 2

smokePiece = {base, engineEmit}

include "constants.lua"


local function openDoors()

	Signal(SIG_OPENDOORS)
	SetSignalMask(SIG_OPENDOORS)
	
	Turn(lUpperCl1,z_axis, rad(-140),6)
	Turn(rUpperCl1,z_axis, rad(140), 6)
	Sleep(100)
		                             
	Turn(lUpperCl2,z_axis, rad(-140),6)	
	Turn(rUpperCl2,z_axis, rad(140), 6)
	WaitForTurn( lUpperCl1, z_axis ) 
	WaitForTurn( rUpperCl1, z_axis ) 
	WaitForTurn( lUpperCl2, z_axis )
	WaitForTurn( rUpperCl2, z_axis )
	
end


function closeDoors()
	Signal(SIG_CLOSEDOORS)
    SetSignalMask(SIG_CLOSEDOORS)
	Turn(lUpperCl1,z_axis, rad(0),4)
	Turn(rUpperCl1,z_axis, rad(0),4)
	Sleep(100)

	Turn(lUpperCl2,z_axis, rad(0),4)	
	Turn(rUpperCl2,z_axis, rad(0),4)

	WaitForTurn( lUpperCl1, z_axis )
	WaitForTurn( rUpperCl1, z_axis )	
	WaitForTurn( lUpperCl2, z_axis )
	WaitForTurn( rUpperCl2, z_axis )
end






function script.Create()

	StartThread(SmokeUnit)
end

function script.Activate()
	
end

function script.Deactivate()
	StartThread(closeDoors)
end


function QueryTransport ( passengerID )
	return link
end

--fetch unit id of passenger (from the load command)
function getPassengerId() 
	local cmd=Spring.GetUnitCommands(unitID)
	local unitId = nil	
	
    if cmd and cmd[1] then					
		if  cmd[1]['id'] == 75  then -- CMDTYPE.LOAD_UNITS = 75
			unitId = cmd[1]['params'][1]				
		end
	end
	
	return unitId
end


--fetch id of command
function getCommandId() 

	local cmd=Spring.GetUnitCommands(unitID)		
    if cmd and cmd[1] then		
		return cmd[1]['id']		
	end
	
	return nil
end

--fetch unit id of passenger (from the load command)
function getDropPoint() 

	local cmd=Spring.GetUnitCommands(unitID)
	local dropx, dropy ,dropz = nil	
	
    if cmd and cmd[1] then					
		if  cmd[1]['id'] == 81  then -- CMDTYPE.LOAD_UNITS = 75
			dropx, dropy ,dropz = cmd[1]['params'][1], cmd[1]['params'][2], cmd[1]['params'][3]				
		end
	end
	
	return {dropx, dropy ,dropz}
end

function isNearPickupPoint(passengerId)

	if passengerId == nil then
		return false
	end

	local px, py, pz = Spring.GetUnitBasePosition(passengerId)
	local px2, py2, pz2 = Spring.GetUnitBasePosition(unitID)	
	local dx = px2 - px
	local dz = pz2 - pz
	local dist = (dx^2 + dz^2)
		
	if dist  < 1000^2 then	
		return true
	else
		return false
	end	
end


function isNearDropPoint(transportUnitId)

	if transportUnitId == nil then
		return false
	end

	local px, py, pz = Spring.GetUnitBasePosition(transportUnitId)
	local dropPoint = getDropPoint()
	local px2, py2, pz2 = dropPoint[1], dropPoint[2], dropPoint[3]
	
	local dx = px - px2
	local dz = pz - pz2  
	local dist = (dx^2 + dz^2)
	
	
	if dist  < 1000^2 then
		return true
	else
		return false
	end	
end



function script.MoveRate(curRate)
	
	local passengerId = getPassengerId()

	if getCommandId() == 75 and isNearPickupPoint(passengerId) then
		StartThread(openDoors)
	elseif getCommandId() == 81 and isNearDropPoint(unitLoaded) then
		StartThread(openDoors)
	end
end




function script.BeginTransport ( passengerID )
	
	if loaded then 
		return 
	end

	local px, py, pz = Spring.GetUnitBasePosition(passengerID)
	SetUnitValue(COB.BUSY, 1)

	AttachUnit(link, passengerID)
	unitLoaded = passengerID
	loaded = true
	
	Sleep(500)
	StartThread(closeDoors)
end

-- note x, y z is in worldspace
--function script.TransportDrop(passengerID, x, y, z)
function script.EndTransport ( ) 

	StartThread(openDoors)
	if (unitLoaded ~= nil) then
		DropUnit(unitLoaded)
	end
	loaded = false	
	SetUnitValue(COB.BUSY, 0)
	Sleep(500)
	StartThread(closeDoors)
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if severity <= 0.25 then
		Explode(base, sfxFall)
		return 1
	elseif severity <= 0.50 then
		Explode(base, sfxShatter)
		return 1
	else
		Explode(base, sfxShatter)

		return 2
	end
end