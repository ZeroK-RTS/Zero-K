include "constants.lua"

local base = piece 'base'
local lidleft = piece 'lidleft'
local lidright = piece 'lidright'
local lidleft_h = piece 'lidleft_h'
local lidright_h = piece 'lidright_h'
local lidleft_fake = piece 'lidleft_fake'
local lidright_fake = piece 'lidright_fake'
local lidtop = piece 'lidtop'
local sealleft = piece 'sealleft'
local sealright = piece 'sealright'
local sealleft_h = piece 'sealleft_h'
local sealright_h = piece 'sealright_h'
local maindoor = piece 'maindoor'
local sill = piece 'maindoor'
local sliderleft = piece 'sliderleft'
local sliderright = piece 'sliderright'
local slidertop = piece 'slidertop'
local sill = piece 'maindoor'
local wingleft = piece 'wingleft'
local wingright = piece 'wingright'
local portal = piece 'portal'
local pipe1, pipe2, pipe3, pipe4 = piece ('pipe1', 'pipe2', 'pipe3', 'pipe4')
local trunk1, trunk2, trunk3, trunk4, trunknozzle = piece('trunk1', 'trunk2', 'trunk3', 'trunk4', 'trunknozzle')
local ball = piece 'ball'
local canister = piece 'canister'
local armleft, armright = piece ('armleft', 'armright')
local handleft, handright = piece ('handleft', 'handright')
local nozzles = {piece ('nozzleleft'), piece ('nozzleright')}
local alholder = piece ('alholder')
local arholder = piece ('arholder')

local nanoPieces = {nozzleleft, nozzleright}
local smokePiece = {base}

local SIG_BUILD = 1

local function Open()
	Signal (SIG_BUILD)
	SetSignalMask (SIG_BUILD)
	Move(maindoor, y_axis, -15.2, 15.2)
	Turn(lidtop, x_axis, math.rad(-106), math.rad(212)) -- move halfway first to prevent moving the shorter path
	Turn(lidleft, x_axis, math.rad(90), math.rad(180))
	Turn(lidright, x_axis, math.rad(90), math.rad(180))
	Move(ball, z_axis, 15.2, 7.6)

	Sleep(500)
	Turn(lidleft, x_axis, math.rad(225), math.rad(270))
	Turn(lidright, x_axis, math.rad(225), math.rad(270))
	Turn(sealleft_h,  y_axis, math.rad(-18), math.rad(18))
	Turn(sealright_h, y_axis, math.rad( 18), math.rad(18))
	Turn(lidtop, x_axis, math.rad(-212), math.rad(212))

	Sleep(500)
	Move(sliderleft,  y_axis, -15.2, 15.2)
	Move(sliderright, y_axis, -15.2, 15.2)
	Move(slidertop, z_axis, -21.85, 21.85)
	Move(wingleft, z_axis, -4.75, 9.5)
	Move(wingright, z_axis, -4.75, 9.5)
	
	
	Turn(handright, y_axis, math.rad(25), math.rad(25))
	Turn(handleft, y_axis, math.rad(-25), math.rad(25))
	Turn(armleft, y_axis, math.rad(30), math.rad(30))
	Turn(armright, y_axis, math.rad(-30), math.rad(30))
	Sleep(500)
	Move(wingleft, z_axis, -21.85, 34.2)
	Move(wingright, z_axis, -21.85, 34.2)

	Sleep(500)
	SetUnitValue (COB.YARD_OPEN, 1)
	SetUnitValue (COB.INBUILDSTANCE, 1)
	SetUnitValue (COB.BUGGER_OFF, 1)
end

local function Close()
	Signal (SIG_BUILD)
	SetSignalMask (SIG_BUILD)

	SetUnitValue (COB.YARD_OPEN, 0)
	SetUnitValue (COB.BUGGER_OFF, 0)
	SetUnitValue (COB.INBUILDSTANCE, 0)

	Turn(handleft, y_axis, 0, math.rad(25))
	Turn(handright, y_axis,0, math.rad(25))
	Turn(armleft, y_axis, 0, math.rad(30))
	Turn(armright, y_axis, 0, math.rad(30))

	Move(ball, z_axis, 0, 8)
	Move(slidertop, z_axis, 0, 21.85)
	Move(wingleft, z_axis, -4.75, 34.2)
	Move(wingright, z_axis, -4.75, 34.2)
	Move(sliderleft,  y_axis, 0, 15.2)
	Move(sliderright, y_axis, 0, 15.2)
	Sleep(500)
	Move(wingleft, z_axis, 0, 9.5)
	Move(wingright, z_axis, 0, 9.5)
	Turn(sealleft_h,  y_axis, 0, math.rad(-18))
	Turn(sealright_h, y_axis, 0, math.rad(-18))
	Sleep(500)
	

	Turn(lidleft, x_axis, math.rad(90), math.rad(270))
	Turn(lidright, x_axis, math.rad(90), math.rad(270))

	Move(maindoor, y_axis, 0, 15.2)
	Turn(lidtop, x_axis, math.rad(-106), math.rad(-212)) -- move halfway first to prevent moving the shorter path
	
	Sleep(500)
	Turn(lidleft, x_axis, 0, math.rad(180))
	Turn(lidright, x_axis, 0, math.rad(180))
	Turn(lidtop, x_axis, 0, math.rad(-212))
end

function script.Activate()
	StartThread(Open)
end

function script.Deactivate()
	StartThread(Close)
end

function script.Create()
	Hide(lidleft_fake)
	Hide(lidright_fake)
	Hide(trunk1)
	Hide(trunk2)
	Hide(trunk3)
	Hide(trunk4)
	Hide(trunknozzle)
	Hide(canister)
	Move(lidleft_h, y_axis, -85500)
	Move(lidright_h, y_axis, -85500)
	Turn(lidleft, y_axis, math.rad(-45))
	Turn(lidright, y_axis, math.rad(45))
	Turn(alholder, z_axis, math.rad(37))
	Turn(arholder, z_axis, math.rad(-37))
	Spring.SetUnitNanoPieces (unitID, nanoPieces)
	StartThread (SmokeUnit, smokePiece)
end


local nozzle = 1
function script.QueryNanoPiece ()
	local ret = nozzles[nozzle]
	nozzle = 3 - nozzle
	GG.LUPS.QueryNanoPiece (unitID, unitDefID, Spring.GetUnitTeam(unitID), ret)
	return ret
end

function script.QueryBuildInfo ()
	return portal
end

local explodables = {pipe2, pipe3, lidleft_fake, lidright_fake, lidtop, sealright, sealleft, maindoor, slidertop, ball}
function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	local brutal = (severity > 0.5)

	for i = 1, #explodables do
		if math.random() < severity then
			Explode(explodables[i], sfxExplode + (brutal and (sfxSmoke + sfxFire) or 0))
		end
	end

	if not brutal then
		return 1
	else
		Explode(base, sfxShatter)
		Explode(portal, sfxShatter)
		return 2
	end
end
