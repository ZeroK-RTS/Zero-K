include 'constants.lua'

local base = piece "base"
local wheel1 = piece "wheel1"
local wheel2 = piece "wheel2"
local slider = piece "slider"
local sliderturret = piece "sliderturret"
local armabase = piece "armabase"
local armbbase = piece "armbbase"
local armcbase = piece "armcbase"
local armdbase = piece "armdbase"
local armebase = piece "armebase"
local armfbase = piece "armfbase"
local arma = piece "arma"
local armb = piece "armb"
local armc = piece "armc"
local armd = piece "armd"
local arme = piece "arme"
local armf = piece "armf"
local armapick = piece "armapick"
local armbpick = piece "armdpick"
local armcpick = piece "armcpick"
local armdpick = piece "armdpick"
local armepick = piece "armepick"
local armfpick = piece "armfpick"

local anglea = -0.05
local angleb = -0.08
local anglec = -0.1
local speeda = 0.3
local speedb = 0.5

local function armmove(piece1, piece2, piece3)
	while(true) do
		Turn(piece1, z_axis, anglea, speeda)
		Turn(piece2, z_axis, angleb, speeda)
		Turn(piece3, z_axis, anglec, speeda)
	
		WaitForTurn(piece1, z_axis)
		WaitForTurn(piece2, z_axis)
		WaitForTurn(piece3, z_axis)

		Turn(piece1, z_axis, anglea, speedb)
		Turn(piece2, z_axis, angleb, speedb)
		Turn(piece3, z_axis, anglec, speedb)

		WaitForTurn(piece1, z_axis)
		WaitForTurn(piece2, z_axis)
		WaitForTurn(piece3, z_axis)

		Turn(piece1, z_axis, 0, speedb)
		Turn(piece2, z_axis, 0, speedb)
		Turn(piece3, z_axis, 0, speedb)

		Sleep (math.random(200,2000))
	end
end

local function moveslider()
	while(true) do
		Move(slider, z_axis, math.random(-5.8,5.8)*5.8, 10)
		WaitForMove(slider, z_axis)
		Sleep (50)
	end
end

function script.Create()
	if Spring.GetUnitRulesParam(unitID, "planetwarsDisable") == 1 or GG.applyPlanetwarsDisable then
		return
	end
	
	StartThread(armmove, armabase, arma, armapick)
	StartThread(armmove, armbbase, armb, armbpick)
	StartThread(armmove, armcbase, armc, armcpick)
	StartThread(armmove, armdbase, armd, armdpick)
	StartThread(armmove, armebase, arme, armepick)
	StartThread(armmove, armfbase, armf, armfpick)

	StartThread(moveslider)
	Spin(sliderturret, y_axis, 2, 0.2)
	Spin(wheel1, x_axis, 0.5, 0.01)
	Spin(wheel2, x_axis, -0.5, 0.01)
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity < .5 then
		Explode(base, SFX.NONE)
		Explode(sliderturret, SFX.NONE)
		Explode(slider, SFX.NONE)
		return 1
	else
		Explode(base, SFX.SHATTER)
		--Explode(sliderturret, SFX.FALL + SFX.SMOKE + SFX.FIRE)
		Explode(sliderturret, SFX.SHATTER)
		Explode(slider, SFX.FALL)
		return 2
	end
end
