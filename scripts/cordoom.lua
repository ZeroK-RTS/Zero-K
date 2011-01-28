include "smokeunit.lua"

--pieces
local base = piece "Base"
local shellbase = piece "ShellBase"
local shell_1 = piece "Shell_1"
local shell_2 = piece "Shell_2"

-- guns

local cannonbase = piece "CannonBase"
local cannon = piece "Cannon"
local flare1 = piece "flare1"

local heatraybase = piece "HeatrayBase"
local heatray = piece "Heatray"
local flare2 = piece "flare2"
local flare3 = piece "flare3"

local spGetUnitRulesParam 	= Spring.GetUnitRulesParam

local smokePieces = { shell_1, shell_2, cannonbase, heatray }

--variables
local heat = false
local on = false
--signals
local aim  = 2
local aim2  = 4
local open = 8
local close = 16


local function Open()
	
	--Spring.Echo(Spring.GetUnitArmored(unitID))
	Spring.SetUnitArmored(unitID,false)
	Spring.SetUnitCOBValue(unitID,20,0)
	--Spring.Echo(Spring.GetUnitArmored(unitID))

	Signal(close) --kill the closing animation if it is in process
	SetSignalMask(open) --set the signal to kill the opening animation

	Move(heatray,y_axis,0,15)
	Move(shell_1,x_axis,0,1.2)
	Move(shell_2,x_axis,-0,1.2)
	Move(heatray,z_axis,0,8)

	WaitForMove(shell_1,x_axis)

	Turn(cannonbase,x_axis,-0.0001,1)

	WaitForTurn(cannonbase,x_axis)
	WaitForMove(heatray,x_axis)
	
	on = true

end

--closing animation of the factory
local function Close()
	Signal( aim )
	Signal( aim2 )
	Signal(open) --kill the opening animation if it is in process
	SetSignalMask(close) --set the signal to kill the closing animation
	
	Move(cannon,z_axis,-10,15)
	
	Turn(cannonbase,x_axis,1.57,1)
	Move(heatray,z_axis,-20,9)
	
	WaitForTurn(cannonbase,x_axis)
	WaitForMove(heatray,z_axis)
	
	Move(heatray,y_axis,-20,5)
	Move(shell_1,x_axis,5.256,1.4)
	Move(shell_2,x_axis,-5.256,1.4)
	
	WaitForMove(shell_1,x_axis)
	

	--Spring.Echo(Spring.GetUnitArmored(unitID))
	Spring.SetUnitArmored(unitID,true)
	Spring.SetUnitCOBValue(unitID,20,1)
	--Spring.Echo(Spring.GetUnitArmored(unitID))

end


function script.Activate ( )
	StartThread( Open )
end

function script.Deactivate ( )
	on = false
	StartThread( Close )
end

function script.Create()
	StartThread(SmokeUnit, smokePieces)
end


function script.QueryWeapon1() return flare1 end

function script.AimFromWeapon1() return cannon end

function script.AimWeapon1( heading, pitch )
if not on then return false end
	Signal( aim )
	SetSignalMask( aim )

	Turn( shellbase, y_axis, heading, 1.2 )
	Turn( cannonbase,  x_axis, -pitch, 0.8 ) 
	WaitForTurn (shellbase, y_axis)
	WaitForTurn (cannonbase, x_axis)

	return (spGetUnitRulesParam(unitID, "lowpower") == 0)	--checks for sufficient energy in grid
end

function script.FireWeapon1()
if not on then return false end
	Show(flare1)
	Move(cannon, z_axis, -24)
	Move(cannon, z_axis, 0, 10)
	Sleep(20)
	Hide(flare1)
end

function script.QueryWeapon2()
	if heat then return flare2
	else return flare3
	end
end

function script.AimFromWeapon2() return heatraybase end

function script.AimWeapon2( heading, pitch )
if not on then return false end
	Signal( aim2 )
	SetSignalMask( aim2 )
	Turn( heatraybase, y_axis, heading, 3 )
	Turn( heatray,  x_axis, -pitch, 2 )
	WaitForTurn (heatraybase, y_axis)
	WaitForTurn (heatray, x_axis)
	return true
end

function script.FireWeapon2()
	--effects
	heat = not heat
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth

	if (severity <= .25) then
		return 1 -- corpsetype
	elseif (severity <= .5) then
		return 1 -- corpsetype
	else		
		return 2 -- corpsetype
	end
end