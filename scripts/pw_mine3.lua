include 'constants.lua'

local base = piece "base"
local coolera1 = piece "coolera1"
local coolera2 = piece "coolera2"
local coolera3 = piece "coolera3"
local coolera4 = piece "coolera4"
local coolerb1 = piece "coolerb1"
local coolerb2 = piece "coolerb2"
local coolerb3 = piece "coolerb3"
local coolerb4 = piece "coolerb4"
local column1 = piece "column1"
local column2 = piece "column2"
local column3 = piece "column3"
local column4 = piece "column4"
local fusionsphere = piece "fusionsphere"

function script.Create ()
	Turn(coolerb1, y_axis, -0.785398163)
	Turn(coolerb2, y_axis, -0.785398163)
	Turn(coolerb3, y_axis, -0.785398163)
	Turn(coolerb4, y_axis, -0.785398163)
end

local function MoveColumn(piece, sleeptime)
	while (true) do
		Sleep (sleeptime)
		Move(piece, y_axis, 30, 3)
		WaitForMove(piece, y_axis)
		Sleep (sleeptime)
		Move(piece, y_axis, 0, 3)
		WaitForMove(piece, y_axis)
	end
end

local function ActiveCoolerT1(piece, sleeptime, specificaxe, axepos)
	while (true) do
		Sleep(sleeptime)
		Move(piece, specificaxe, axepos*-3, 2)
		WaitForMove(piece, specificaxe)
		Sleep(sleeptime)
		Move(piece, specificaxe, 0, 2)
		WaitForMove(piece, specificaxe)
	end
end

local function ActiveCoolerT2(piece, sleeptime, zaxepos, xaxepos)
	while (true) do
		Sleep(sleeptime)
		Move(piece, z_axis, zaxepos*2, 2)
		Move(piece, x_axis, xaxepos*-2, 2)
			WaitForMove(piece, z_axis)
			WaitForMove(piece, x_axis)
		Sleep(sleeptime)
		Move(piece, z_axis, 0, 2)
		Move(piece, x_axis, 0, 2)
		WaitForMove(piece, z_axis)
		WaitForMove(piece, x_axis)
	end
end

local function Initialize()
	Signal(1)
	SetSignalMask(2)

	StartThread(MoveColumn, column1, math.random(300,4000))
	StartThread(MoveColumn, column2, math.random(300,4000))
	StartThread(MoveColumn, column3, math.random(300,4000))
	StartThread(MoveColumn, column4, math.random(300,4000))

	StartThread(ActiveCoolerT1, coolera1, math.random(1000,6000), x_axis, 1)
	StartThread(ActiveCoolerT1, coolera2, math.random(1000,6000), z_axis, -1)
	StartThread(ActiveCoolerT1, coolera3, math.random(1000,6000), x_axis, -1)
	StartThread(ActiveCoolerT1, coolera4, math.random(1000,6000), z_axis, 1)

	StartThread(ActiveCoolerT2, coolerb1, math.random(1000,6000), 1, 1)
	StartThread(ActiveCoolerT2, coolerb2, math.random(1000,6000), 1, -1)
	StartThread(ActiveCoolerT2, coolerb3, math.random(1000,6000), -1, -1)
	StartThread(ActiveCoolerT2, coolerb4, math.random(1000,6000), -1, 1)

	Spin(fusionsphere, y_axis, 0.2, 0.001)

end

local function Deinitialize()
	Signal(2)
	SetSignalMask(1)

	Move(column1, y_axis, 0, 3)
	Move(column2, y_axis, 0, 3)
	Move(column3, y_axis, 0, 3)
	Move(column4, y_axis, 0, 3)

	StopSpin(fusionsphere, y_axis, 0.01)

	Move(coolera1, x_axis, 0, 2)
	Move(coolera2, z_axis, 0, 2)
	Move(coolera3, x_axis, 0, 2)
	Move(coolera4, z_axis, 0, 2)

	Move(coolerb1, z_axis, 0, 2)
	Move(coolerb2, x_axis, 0, 2)
	Move(coolerb3, z_axis, 0, 2)
	Move(coolerb4, x_axis, 0, 2)

	Move(coolerb1, x_axis, 0, 2)
	Move(coolerb2, z_axis, 0, 2)
	Move(coolerb3, x_axis, 0, 2)
	Move(coolerb4, z_axis, 0, 2)
end

function script.Activate ()
	if Spring.GetUnitRulesParam(unitID, "planetwarsDisable") == 1 or GG.applyPlanetwarsDisable then
		return
	end
	
	StartThread(Initialize)
end

function script.Deactivate ()
	StartThread(Deinitialize)
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity < 0.5 then
		Explode(base, SFX.NONE)
		Explode(fusionsphere, SFX.NONE)
		return 1
	else
		Explode(base, SFX.SHATTER)
		Explode(fusionsphere, SFX.SHATTER)
		return 2
	end
end