local spots = { -- standalone (not startpos related)
	{
		x = 1919.51953,
		z = 9439.90723,
	}, {
		x = 5635.61475,
		z = 3191.08496,
	}, {
		x = 1034.95581,
		z = 10903.1191,
	}, {
		x = 9259.19824,
		z = 5567.50684,
	}, {
		x = 3026.17212,
		z = 2057.94238,
	}, {
		x = 3217.32593,
		z = 6838.99512,
	}, {
		x = 5246.79053,
		z = 3220.1084,
	}, {
		x = 8901.79785,
		z = 5391.76709,
	}, {
		x = 10877.5283,
		z = 11337.9941,
	}, {
		x = 7590.72266,
		z = 7541.05029,
	}, {
		x = 2885.5874,
		z = 6665.87891,
	}, {
		x = 6741.86865,
		z = 8994.70703,
	}, {
		x = 6589.17822,
		z = 9316.10156,
	}, {
		x = 6526.64307,
		z = 2196.75708,
	}, {
		x = 636.727722,
		z = 5644.70313,
	}, {
		x = 9799.89746,
		z = 6535.09717,
	}, {
		x = 5483.71289,
		z = 9877.09668,
	}, {
		x = 1403.021,
		z = 1231.09021,
	}, {
		x = 10184.1729,
		z = 2744.94189,
	}, {
		x = 10969.1934,
		z = 1382.90369,
	}, {
		x = 11501.165,
		z = 6415.09814,
	}, {
		x = 6263.67725,
		z = 575.947205,
	}, {
		x = 4707.60059,
		z = 4648.54395,
	}, {
		x = 2475.01001,
		z = 5561.63281,
	}, {
		x = 5657.81494,
		z = 11597.1836,
	}, {
		x = 7584.63965,
		z = 4746.24658,
	}, {
		x = 4597.22998,
		z = 7470.46484,
	}, {
		x = 9345.05078,
		z = 10467.9502,
	}, {
		x = 4702.1167,
		z = 4020.50659,
	}, {
		x = 8245,
		z = 4746,
	}, {
		x = 3820.32593,
		z = 7502.66846,
	}, {
		x = 7514,
		z = 8238,
	}, {
		x = 1702.63293,
		z = 1474.41077,
	}, {
		x = 10826.7832,
		z = 1614.9967,
	}, {
		x = 10533,
		z = 11079,
	}, {
		x = 1283,
		z = 10672,
	},
}

-- occupied boxes get triplets, else a single mex
local potential_boxes = {
	{ 3389,  9071},
	{ 3355,  3466},
	{ 8765,  3235},
	{ 8910,  8835},
	{  955,  7866},
	{ 4324,   992},
	{11148,  4376},
	{ 7317, 11477},
	{ 1030,  3951},
	{ 8326,   995},
	{11035,  8169},
	{ 3967, 11202},
	{ 5126,  6158},
	{ 6096,  5051},
	{ 7120,  6071},
	{ 6194,  7151},
}

local used_boxes = {}
local shuffleMode = Spring.GetGameRulesParam("shuffleMode")
if shuffleMode == "allshuffle" then
	local startbox_max_n = Spring.GetGameRulesParam("startbox_max_n")
	for i = 0, startbox_max_n do
		used_boxes[#used_boxes + 1] = {
			Spring.GetGameRulesParam("startpos_x_" .. i .. "_1"),
			Spring.GetGameRulesParam("startpos_z_" .. i .. "_1"),
		}
	end
else
	local teams = Spring.GetTeamList()
	for i = 1, #teams do
		local boxID = Spring.GetTeamRulesParam(teams[i], "start_box_id")
		if boxID then -- usually impossible but maybe somebody plays a 17-man game or something
			used_boxes[#used_boxes + 1] = {
				Spring.GetGameRulesParam("startpos_x_" .. boxID .. "_1"),
				Spring.GetGameRulesParam("startpos_z_" .. boxID .. "_1"),
			}
		end
	end
end

for i = 1, #potential_boxes do
	local isUsed = false
	for j = 1, #used_boxes do
		if  potential_boxes[i][1] == used_boxes[j][1]
		and potential_boxes[i][2] == used_boxes[j][2] then
			isUsed = true
			break
		end
	end

	if isUsed then
		local angle = 2 * math.pi / 3
		local theta = math.random() * angle
		for j = 1, 3 do
			spots[#spots + 1] = {
				x = potential_boxes[i][1] + 128 * math.cos(theta),
				z = potential_boxes[i][2] + 128 * math.sin(theta),
			}
			theta = theta + angle
		end
	else
		spots[#spots + 1] = {
			x = potential_boxes[i][1],
			z = potential_boxes[i][2],
		}
	end
end

return {
	metalValueOverride = 2,
	spots = spots,
}
