local base, bottom, tamper, furnace, door_l, door_r, hinge_l, hinge_r, drill1, drill2, drill3, posts = piece ('base', 'bottom', 'tamper', 'furnace', 'door_l', 'door_r', 'hinge_l', 'hinge_r', 'drill1', 'drill2', 'drill3', 'posts')

include "pieceControl.lua"
include "constants.lua"

local SIG_OPEN = 1

local smokePiece = {tamper}

local metalmult = tonumber(Spring.GetModOptions().metalmult) or 1
local metalmultInv = metalmult > 0 and (1/metalmult) or 1

local od_1, od_2, od_3, od_4 = piece('od1', 'od2', 'od3', 'od4')
local currentWant = false

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function ShowDistortion(mult)
	local want = 0
	if mult >= 2.5 then
		want = 4
	elseif mult >= 1.9 then
		want = 3
	elseif mult >= 1.4 then
		want = 2
	elseif mult >= 1 then
		want = 1
	end
	if want == currentWant then
		return
	end
	currentWant = want
	if want == 0 then
		Hide(od_1)
		Hide(od_2)
		Hide(od_3)
		Hide(od_4)
	elseif want == 1 then
		Show(od_1)
		Hide(od_2)
		Hide(od_3)
		Hide(od_4)
	elseif want == 2 then
		Hide(od_1)
		Show(od_2)
		Hide(od_3)
		Hide(od_4)
	elseif want == 3 then
		Hide(od_1)
		Hide(od_2)
		Show(od_3)
		Hide(od_4)
	elseif want == 4 then
		Hide(od_1)
		Hide(od_2)
		Hide(od_3)
		Show(od_4)
	end
end

local function Open()
	Signal(SIG_OPEN)
	SetSignalMask(SIG_OPEN)
	
	Turn (hinge_r, z_axis, math.rad(-120), math.rad(120))
	Turn (hinge_l, z_axis, math.rad(120), math.rad(120))
	WaitForTurn (hinge_l, z_axis)
	Move (tamper, y_axis, 15, 10)
	WaitForMove (tamper, y_axis)

	local height = 40

	while true do
		local income = Spring.GetUnitRulesParam(unitID, "current_metalIncome") or 0
		local overdrive = Spring.GetUnitRulesParam(unitID, "overdrive_proportion") or 0
		income = income * metalmultInv
		if income > 0 then
			ShowDistortion(1 + overdrive)
			Spin (furnace, y_axis, income, math.rad(1))
			Spin (drill1, y_axis, income, math.rad(1))
			Move (tamper, y_axis, height, income*10)
			WaitForMove (tamper, y_axis)
			height = 60 - height
		else
			ShowDistortion(0)
			StopSpin (furnace, y_axis, math.rad(5))
			StopSpin (drill1, y_axis, math.rad(5))
			Sleep (200)
		end
	end
end

function script.Activate()
	StartThread(Open)
end

function script.Create()
	ShowDistortion(0)
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
	if not Spring.GetUnitIsStunned(unitID) then
		StartThread(Open)
	end
end

local explodables = {door_l, furnace}

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth

	for i = 1, #explodables do
		if (math.random() < severity*1.5) then
			Explode (explodables[i], SFX.FALL + SFX.SMOKE)
		end
	end
	if severity < 0.5 then
		return 1
	else
		Explode (door_r, SFX.FALL + SFX.SMOKE)
		Explode (bottom, SFX.SHATTER)
		return 2
	end
end
