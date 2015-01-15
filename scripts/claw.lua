local base = piece ('base')

local stalk = {}
for i = 1, 4 do
	stalk[i] = piece ('stalk' .. i)
end

local petals = {}
for i = 1, 3 do
	petals[i] = {}
	for j = 1, 4 do
		petals[i][j] = piece ('petal_' .. i .. j)
	end
end

local bomblets = {}
for i = 1, 5 do
	bomblets[i] = {}
	bomblets[i].hinge = piece ('hinge' .. i)
	bomblets[i].bomb = piece ('bomblet' .. i)
end

local currentBomblet = 1

function script.Create()
	Turn (base, y_axis, math.random()*math.pi);
	Spin (stalk[4], y_axis, math.rad(30))

	for i = 1, #bomblets do
		Turn (bomblets[i].hinge, y_axis, i * 2 * math.pi / #bomblets)
		Turn (bomblets[i].bomb, x_axis, -math.pi / 6, math.rad(15))
	end

	for i = 1, #petals do
		Turn (petals[i][1], y_axis, i * 2 * math.pi / #petals)
		Turn (petals[i][2], x_axis, math.rad(-70), math.rad(49))
		Turn (petals[i][3], x_axis, math.rad(-20), math.rad(14))
		Turn (petals[i][4], x_axis, math.rad(-30), math.rad(21))
	end

	for i = 1, #stalk do
		Move (stalk[i], y_axis, 1, 0.25)
	end

	GG.SetWantedCloaked(unitID, 1)
end

function script.AimFromWeapon (num)
	return bomblets[currentBomblet].bomb
end

function script.QueryWeapon(num)
	return bomblets[currentBomblet].bomb
end

function script.AimWeapon(num, heading, putch)
	return true
end

local firing = false
function script.Shot (num)
	if (not firing) then
		firing = true
	else
		currentBomblet = currentBomblet + 1
		if (currentBomblet == 5) then
			Spring.DestroyUnit(unitID, true, false)
		end
	end
	Hide (bomblets[currentBomblet].bomb)
end