include "constants.lua"

local dyncomm = include('dynamicCommander.lua')
_G.dyncomm = dyncomm

local AntennaTip = piece('AntennaTip')
local ArmLeft = piece('ArmLeft')
local ArmRight = piece('ArmRight')
local AssLeft = piece('AssLeft')
local AssRight = piece('AssRight')
local Breast = piece('Breast')
local CalfLeft = piece('CalfLeft')
local CalfRight = piece('CalfRight')
local FingerA = piece('FingerA')
local FingerB = piece('FingerB')
local FingerC = piece('FingerC')
local FootLeft = piece('FootLeft')
local FootRight = piece('FootRight')
local Gun = piece('Gun')
local HandRight = piece('HandRight')
local Head = piece('Head')
local HipLeft = piece('HipLeft')
local HipRight = piece('HipRight')
local Muzzle = piece('Muzzle')
local Palm = piece('Palm')
local Stomach = piece('Stomach')
local Base = piece('Base')
local Nano = piece('Nano')
local UnderGun = piece('UnderGun')
local UnderMuzzle = piece('UnderMuzzle')
local Eye = piece('Eye')
local Shield = piece('Shield')
local FingerTipA = piece('FingerTipA')
local FingerTipB = piece('FingerTipB')
local FingerTipC = piece('FingerTipC')

local TORSO_SPEED_YAW = math.rad(300)
local ARM_SPEED_PITCH = math.rad(180)

local smokePiece = {Breast, Head}
local nanoPieces = {Nano}
local nanoing = false
local aiming = false

local FINGER_ANGLE_IN = math.rad(10)
local FINGER_ANGLE_OUT = math.rad(-25)
local FINGER_SPEED = math.rad(60)

local SIG_RIGHT = 1
local SIG_RESTORE_RIGHT = 2
local SIG_LEFT = 4
local SIG_RESTORE_LEFT = 8
local SIG_RESTORE_TORSO = 16
local SIG_WALK = 32
local SIG_NANO = 64

local RESTORE_DELAY = 2500

---------------------------------------------------------------------
---  blender-exported animation: data (move to include file?)     ---
---------------------------------------------------------------------
local Animations = {};
Animations['die'] = {
	{
		['time'] = 0,
		['commands'] = {
		}
	},
	{
		['time'] = 5,
		['commands'] = {
			{['c']='turn',['p']=Base, ['a']=x_axis, ['t']=0.232016, ['s']=0.696048},
			{['c']='turn',['p']=Base, ['a']=y_axis, ['t']=0.004894, ['s']=0.014683},
			{['c']='turn',['p']=Base, ['a']=z_axis, ['t']=0.250887, ['s']=0.032047},
			{['c']='move',['p']=Base, ['a']=y_axis, ['t']=-10.286314, ['s']=16.366669},
			{['c']='move',['p']=Base, ['a']=z_axis, ['t']=25.215321, ['s']=28.891800},
			{['c']='turn',['p']=CalfRight, ['a']=x_axis, ['t']=1.605359, ['s']=4.816078},
			{['c']='turn',['p']=CalfRight, ['a']=y_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=CalfRight, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=Stomach, ['a']=x_axis, ['t']=-0.541880, ['s']=0.587425},
			{['c']='turn',['p']=Stomach, ['a']=y_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=Stomach, ['a']=z_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=CalfLeft, ['a']=x_axis, ['t']=1.114193, ['s']=2.644143},
			{['c']='turn',['p']=CalfLeft, ['a']=y_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=CalfLeft, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=Breast, ['a']=x_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=Breast, ['a']=y_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=Breast, ['a']=z_axis, ['t']=0.161811, ['s']=0.485432},
			{['c']='turn',['p']=HipRight, ['a']=x_axis, ['t']=-0.286401, ['s']=0.859202},
			{['c']='turn',['p']=HipRight, ['a']=y_axis, ['t']=-0.000001, ['s']=0.000000},
			{['c']='turn',['p']=HipRight, ['a']=z_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=Head, ['a']=x_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=Head, ['a']=y_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=Head, ['a']=z_axis, ['t']=0.432971, ['s']=1.298912},
			{['c']='turn',['p']=ArmLeft, ['a']=x_axis, ['t']=-0.192287, ['s']=1.014448},
			{['c']='turn',['p']=ArmLeft, ['a']=z_axis, ['t']=0.015827, ['s']=0.000000},
			{['c']='turn',['p']=HipLeft, ['a']=x_axis, ['t']=-0.094390, ['s']=0.283170},
			{['c']='turn',['p']=HipLeft, ['a']=y_axis, ['t']=-0.245644, ['s']=0.736933},
			{['c']='turn',['p']=HipLeft, ['a']=z_axis, ['t']=0.163177, ['s']=0.489530},
			{['c']='turn',['p']=ArmRight, ['a']=x_axis, ['t']=-0.083255, ['s']=1.066882},
			{['c']='turn',['p']=ArmRight, ['a']=y_axis, ['t']=0.413306, ['s']=0.676712},
			{['c']='turn',['p']=ArmRight, ['a']=z_axis, ['t']=0.238749, ['s']=0.331098},
		}
	},
	{
		['time'] = 15,
		['commands'] = {
			{['c']='move',['p']=Base, ['a']=y_axis, ['t']=-6.303279, ['s']=8.535074},
			{['c']='move',['p']=Base, ['a']=z_axis, ['t']=23.746590, ['s']=3.147281},
			{['c']='turn',['p']=CalfRight, ['a']=x_axis, ['t']=2.268937, ['s']=1.421952},
			{['c']='turn',['p']=CalfRight, ['a']=y_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=CalfRight, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=Stomach, ['a']=x_axis, ['t']=-0.411610, ['s']=0.279149},
			{['c']='turn',['p']=Stomach, ['a']=y_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=Stomach, ['a']=z_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=HandRight, ['a']=x_axis, ['t']=-0.298665, ['s']=0.639996},
			{['c']='turn',['p']=HandRight, ['a']=y_axis, ['t']=0.057640, ['s']=0.123514},
			{['c']='turn',['p']=HandRight, ['a']=z_axis, ['t']=-0.052757, ['s']=0.113051},
			{['c']='turn',['p']=CalfLeft, ['a']=x_axis, ['t']=1.883354, ['s']=1.648202},
			{['c']='turn',['p']=CalfLeft, ['a']=y_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=CalfLeft, ['a']=z_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=HipRight, ['a']=x_axis, ['t']=-0.791779, ['s']=1.082954},
			{['c']='turn',['p']=HipRight, ['a']=y_axis, ['t']=-0.000001, ['s']=0.000000},
			{['c']='turn',['p']=HipRight, ['a']=z_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=ArmLeft, ['a']=x_axis, ['t']=-0.419692, ['s']=0.487297},
			{['c']='turn',['p']=ArmLeft, ['a']=y_axis, ['t']=-0.208858, ['s']=0.000000},
			{['c']='turn',['p']=ArmLeft, ['a']=z_axis, ['t']=0.015827, ['s']=0.000000},
			{['c']='turn',['p']=HipLeft, ['a']=x_axis, ['t']=-0.641872, ['s']=1.173175},
			{['c']='turn',['p']=HipLeft, ['a']=y_axis, ['t']=-0.245644, ['s']=0.000000},
			{['c']='turn',['p']=HipLeft, ['a']=z_axis, ['t']=0.163177, ['s']=0.000000},
			{['c']='turn',['p']=Gun, ['a']=x_axis, ['t']=-0.221850, ['s']=0.475394},
			{['c']='turn',['p']=Gun, ['a']=y_axis, ['t']=-0.304574, ['s']=0.652659},
			{['c']='turn',['p']=Gun, ['a']=z_axis, ['t']=-0.036910, ['s']=0.079093},
		}
	},
	{
		['time'] = 29,
		['commands'] = {
			{['c']='move',['p']=Base, ['a']=y_axis, ['t']=-11.554915, ['s']=26.258180},
			{['c']='turn',['p']=CalfRight, ['a']=x_axis, ['t']=1.680374, ['s']=2.942814},
			{['c']='turn',['p']=CalfRight, ['a']=y_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=CalfRight, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=HandRight, ['a']=x_axis, ['t']=-0.603072, ['s']=1.522036},
			{['c']='turn',['p']=HandRight, ['a']=y_axis, ['t']=0.111299, ['s']=0.268299},
			{['c']='turn',['p']=HandRight, ['a']=z_axis, ['t']=-0.147644, ['s']=0.474433},
			{['c']='turn',['p']=AssLeft, ['a']=x_axis, ['t']=0.575311, ['s']=1.871441},
			{['c']='turn',['p']=AssLeft, ['a']=y_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=AssLeft, ['a']=z_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=CalfLeft, ['a']=x_axis, ['t']=1.425336, ['s']=2.290088},
			{['c']='turn',['p']=CalfLeft, ['a']=y_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=CalfLeft, ['a']=z_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=Breast, ['a']=x_axis, ['t']=0.186159, ['s']=0.930793},
			{['c']='turn',['p']=Breast, ['a']=y_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=Breast, ['a']=z_axis, ['t']=0.161811, ['s']=0.000000},
			{['c']='turn',['p']=HipRight, ['a']=x_axis, ['t']=-0.144300, ['s']=3.237398},
			{['c']='turn',['p']=HipRight, ['a']=y_axis, ['t']=-0.000001, ['s']=0.000000},
			{['c']='turn',['p']=HipRight, ['a']=z_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=ArmLeft, ['a']=x_axis, ['t']=-0.921177, ['s']=2.507425},
			{['c']='turn',['p']=ArmLeft, ['a']=y_axis, ['t']=-0.108622, ['s']=0.501180},
			{['c']='turn',['p']=ArmLeft, ['a']=z_axis, ['t']=-0.047991, ['s']=0.319091},
			{['c']='turn',['p']=HipLeft, ['a']=x_axis, ['t']=-0.523475, ['s']=0.591982},
			{['c']='turn',['p']=HipLeft, ['a']=z_axis, ['t']=0.163177, ['s']=0.000000},
			{['c']='turn',['p']=ArmRight, ['a']=x_axis, ['t']=-0.697045, ['s']=3.068952},
			{['c']='turn',['p']=ArmRight, ['a']=y_axis, ['t']=0.503615, ['s']=0.451545},
			{['c']='turn',['p']=ArmRight, ['a']=z_axis, ['t']=0.051914, ['s']=0.934174},
			{['c']='turn',['p']=Gun, ['a']=x_axis, ['t']=-0.563546, ['s']=1.708478},
			{['c']='turn',['p']=Gun, ['a']=y_axis, ['t']=-0.222652, ['s']=0.409613},
			{['c']='turn',['p']=Gun, ['a']=z_axis, ['t']=0.061517, ['s']=0.492138},
		}
	},
	{
		['time'] = 35,
		['commands'] = {
			{['c']='turn',['p']=Base, ['a']=x_axis, ['t']=1.191343, ['s']=4.796636},
			{['c']='turn',['p']=Base, ['a']=y_axis, ['t']=0.004894, ['s']=0.000000},
			{['c']='turn',['p']=Base, ['a']=z_axis, ['t']=0.250887, ['s']=0.000000},
			{['c']='move',['p']=Base, ['a']=x_axis, ['t']=4.315906, ['s']=13.935559},
			{['c']='move',['p']=Base, ['a']=y_axis, ['t']=-21.297955, ['s']=48.715196},
			{['c']='move',['p']=Base, ['a']=z_axis, ['t']=15.503991, ['s']=41.212993},
			{['c']='turn',['p']=CalfRight, ['a']=x_axis, ['t']=0.670799, ['s']=5.047876},
			{['c']='turn',['p']=CalfRight, ['a']=y_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=CalfRight, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=HandRight, ['a']=x_axis, ['t']=-1.360638, ['s']=3.787832},
			{['c']='turn',['p']=HandRight, ['a']=y_axis, ['t']=0.111299, ['s']=0.000001},
			{['c']='turn',['p']=HandRight, ['a']=z_axis, ['t']=-0.147644, ['s']=0.000000},
			{['c']='turn',['p']=CalfLeft, ['a']=x_axis, ['t']=0.396744, ['s']=5.142960},
			{['c']='turn',['p']=CalfLeft, ['a']=y_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=CalfLeft, ['a']=z_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=Breast, ['a']=x_axis, ['t']=0.517826, ['s']=1.658337},
			{['c']='turn',['p']=Breast, ['a']=y_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=Breast, ['a']=z_axis, ['t']=0.161811, ['s']=0.000000},
			{['c']='turn',['p']=ArmLeft, ['a']=x_axis, ['t']=-1.242896, ['s']=1.608593},
			{['c']='turn',['p']=ArmLeft, ['a']=y_axis, ['t']=-0.108622, ['s']=0.000000},
			{['c']='turn',['p']=ArmLeft, ['a']=z_axis, ['t']=-0.047991, ['s']=0.000000},
			{['c']='turn',['p']=FootRight, ['a']=x_axis, ['t']=0.448296, ['s']=2.241478},
			{['c']='turn',['p']=FootRight, ['a']=y_axis, ['t']=0.000001, ['s']=0.000000},
			{['c']='turn',['p']=FootRight, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=ArmRight, ['a']=x_axis, ['t']=-1.191173, ['s']=2.470638},
			{['c']='turn',['p']=ArmRight, ['a']=y_axis, ['t']=0.503615, ['s']=0.000000},
			{['c']='turn',['p']=ArmRight, ['a']=z_axis, ['t']=0.051914, ['s']=0.000000},
			{['c']='turn',['p']=Gun, ['a']=x_axis, ['t']=-1.308940, ['s']=3.726971},
			{['c']='turn',['p']=Gun, ['a']=y_axis, ['t']=-0.222652, ['s']=0.000000},
			{['c']='turn',['p']=Gun, ['a']=z_axis, ['t']=0.061517, ['s']=0.000000},
		}
	},
	{
		['time'] = 41,
		['commands'] = {
			{['c']='turn',['p']=Base, ['a']=x_axis, ['t']=1.511230, ['s']=2.399147},
			{['c']='turn',['p']=Base, ['a']=y_axis, ['t']=0.004894, ['s']=0.000000},
			{['c']='turn',['p']=Base, ['a']=z_axis, ['t']=0.250887, ['s']=0.000000},
			{['c']='move',['p']=Base, ['a']=y_axis, ['t']=-25.564775, ['s']=32.001157},
			{['c']='move',['p']=Base, ['a']=z_axis, ['t']=7.163431, ['s']=62.554203},
			{['c']='turn',['p']=CalfRight, ['a']=x_axis, ['t']=0.215270, ['s']=3.416467},
			{['c']='turn',['p']=CalfRight, ['a']=y_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=CalfRight, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=FootLeft, ['a']=x_axis, ['t']=0.205250, ['s']=2.591299},
			{['c']='turn',['p']=FootLeft, ['a']=y_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=FootLeft, ['a']=z_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=CalfLeft, ['a']=x_axis, ['t']=0.168139, ['s']=1.714537},
			{['c']='turn',['p']=CalfLeft, ['a']=y_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=CalfLeft, ['a']=z_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=ArmLeft, ['a']=x_axis, ['t']=-1.695927, ['s']=3.397732},
			{['c']='turn',['p']=ArmLeft, ['a']=y_axis, ['t']=-0.003014, ['s']=0.792059},
			{['c']='turn',['p']=ArmLeft, ['a']=z_axis, ['t']=0.707491, ['s']=5.666117},
			{['c']='turn',['p']=HipLeft, ['a']=x_axis, ['t']=-0.615074, ['s']=0.686993},
			{['c']='turn',['p']=HipLeft, ['a']=z_axis, ['t']=0.163177, ['s']=0.000000},
			{['c']='turn',['p']=ArmRight, ['a']=x_axis, ['t']=-1.601538, ['s']=3.077738},
			{['c']='turn',['p']=ArmRight, ['a']=y_axis, ['t']=0.078940, ['s']=3.185058},
			{['c']='turn',['p']=ArmRight, ['a']=z_axis, ['t']=-1.185024, ['s']=9.277040},
		}
	},
	{
		['time'] = 45,
		['commands'] = {
		}
	},
}

---------------------------------------------------------------------
---  blender-exported animation: framework code             ---------
---------------------------------------------------------------------

local animCmd = {['turn']=Turn,['move']=Move};
function PlayAnimation(animname)
    local anim = Animations[animname];
    for i = 1, #anim do
        local commands = anim[i].commands;
        for j = 1,#commands do
            local cmd = commands[j];
            animCmd[cmd.c](cmd.p,cmd.a,cmd.t,cmd.s);
        end
        if(i < #anim) then
            local t = anim[i+1]['time'] - anim[i]['time'];
            Sleep(t*33); -- sleep works on milliseconds
        end
    end
end

function constructSkeleton(unit, piece, offset)
    if (offset == nil) then
        offset = {0,0,0};
    end

    local bones = {};
    local info = Spring.GetUnitPieceInfo(unit,piece);

    for i=1,3 do
        info.offset[i] = offset[i]+info.offset[i];
    end

    bones[piece] = info.offset;
    local map = Spring.GetUnitPieceMap(unit);
    local children = info.children;

    if (children) then
        for i, childName in pairs(children) do
            local childId = map[childName];
            local childBones = constructSkeleton(unit, childId, info.offset);
            for cid, cinfo in pairs(childBones) do
                bones[cid] = cinfo;
            end
        end
    end
    return bones;
end

---------------------------------------------------------------------
-- Walking

local BASE_PACE = 2.05
local BASE_VELOCITY = UnitDefNames.benzcom1.speed or 1.25*30
local VELOCITY = UnitDefs[unitDefID].speed or BASE_VELOCITY
local PACE = BASE_PACE * VELOCITY/BASE_VELOCITY

local SLEEP_TIME = 1000*10/30 -- Empirically determined

local walkCycle = 1 -- Alternate between 1 and 2

local walkAngle = {
	{ -- Moving forwards
		wait = HipLeft,
		{
			hip = {math.rad(-12), math.rad(40) * PACE},
			leg = {math.rad(80), math.rad(100) * PACE},
			foot = {math.rad(15), math.rad(150) * PACE},
			arm = {math.rad(5), math.rad(20) * PACE},
			hand = {math.rad(0), math.rad(20) * PACE},
		},
		{
			hip = {math.rad(-32), math.rad(30) * PACE},
			leg = {math.rad(16), math.rad(90) * PACE},
			foot = {math.rad(-30), math.rad(160) * PACE},
		},
	},
	{ -- Moving backwards
		wait = HipRight,
		{
			hip = {math.rad(8), math.rad(35) * PACE},
			leg = {math.rad(2), math.rad(50) * PACE},
			foot = {math.rad(10), math.rad(40) * PACE},
			arm = {math.rad(-20), math.rad(20) * PACE},
			hand = {math.rad(-25), math.rad(20) * PACE},
		},
		{
			hip = {math.rad(20), math.rad(35) * PACE},
			leg = {math.rad(15), math.rad(25) * PACE},
			foot = {math.rad(60), math.rad(30) * PACE},
		}
		
	},
}

local function Walk()
	Signal(SIG_WALK)
	SetSignalMask(SIG_WALK)
	
	while true do
		walkCycle = 3 - walkCycle
		local speedMult = math.max(0.05, (Spring.GetUnitRulesParam(unitID,"totalMoveSpeedChange") or 1)*dyncomm.GetPace())
		
		local left = walkAngle[walkCycle]
		local right = walkAngle[3 - walkCycle]
		-----------------------------------------------------------------------------------
		
		Turn(HipLeft, x_axis,  left[1].hip[1],  left[1].hip[2] * speedMult)
		Turn(CalfLeft, x_axis, left[1].leg[1],  left[1].leg[2] * speedMult)
		Turn(FootLeft, x_axis, left[1].foot[1], left[1].foot[2] * speedMult)
		
		Turn(HipRight, x_axis,  right[1].hip[1],  right[1].hip[2] * speedMult)
		Turn(CalfRight, x_axis, right[1].leg[1],  right[1].leg[2] * speedMult)
		Turn(FootRight, x_axis,  right[1].foot[1], right[1].foot[2] * speedMult)
		
		if not aiming then
			Turn(ArmLeft, x_axis, left[1].arm[1],  left[1].arm[2] * speedMult)
			Turn(Gun, x_axis, left[1].hand[1], left[1].hand[2] * speedMult)
			
			Turn(ArmRight, x_axis, right[1].arm[1],  right[1].arm[2] * speedMult)
			Turn(HandRight, x_axis, right[1].hand[1], right[1].hand[2] * speedMult)
		end
		
		Move(Base, z_axis, 1, 2 * speedMult)
		
		--WaitForTurn(left.wait, x_axis)
		--Spring.Echo(Spring.GetGameFrame())
		Sleep(SLEEP_TIME / speedMult)
		-----------------------------------------------------------------------------------
		
		Turn(HipLeft, x_axis,  left[2].hip[1],  left[2].hip[2] * speedMult)
		Turn(CalfLeft, x_axis, left[2].leg[1],  left[2].leg[2] * speedMult)
		Turn(FootLeft, x_axis, left[2].foot[1], left[2].foot[2] * speedMult)
		
		Turn(HipRight, x_axis,  right[2].hip[1],  right[2].hip[2] * speedMult)
		Turn(CalfRight, x_axis, right[2].leg[1],  right[2].leg[2] * speedMult)
		Turn(FootRight, x_axis,  right[2].foot[1], right[2].foot[2] * speedMult)
		
		if not aiming then
			Turn(Stomach, z_axis, -0.3*(walkCycle - 1.5), 0.4 * speedMult)
		end
		
		Move(Base, z_axis, 0, 2 * speedMult)
		
		--WaitForTurn(left.wait, x_axis)
		--Spring.Echo(Spring.GetGameFrame())
		Sleep(SLEEP_TIME / speedMult)
	end
end

local function RestoreLegs()
	Signal(SIG_WALK)
	SetSignalMask(SIG_WALK)
	
	Turn(HipLeft,  x_axis, 0, 1)
	Turn(CalfLeft, x_axis, 0, 3)
	Turn(FootLeft, x_axis, 0, 2.5)
	
	Turn(HipRight,  x_axis, 0, 1)
	Turn(CalfRight, x_axis, 0, 3)
	Turn(FootRight, x_axis, 0, 2.5)
	
	if not aiming then
		Turn(ArmLeft, x_axis, math.rad(-5), 2)
		Turn(Gun, x_axis, math.rad(-5), 2)
		
		Turn(ArmRight, x_axis, math.rad(-5), 2)
		Turn(HandRight, x_axis, math.rad(-5), 2)
	
		Turn(Stomach, z_axis, 0, 1)
	end
	Move(Base, z_axis, 0, 4)
end

function script.StartMoving()
	StartThread(Walk)
end

function script.StopMoving()
	StartThread(RestoreLegs)
end

---------------------------------------------------------------------
---------------------------------------------------------------------
-- Aiming and Firing

function script.AimFromWeapon(num)
	if num == 5 then
		return Palm
	elseif num == 3 then
		return UnderMuzzle
	end
	return Shield
end

function script.QueryWeapon(num)
	if num == 5 then
		return Muzzle
	elseif num == 3 then
		return UnderMuzzle
	end
	return Shield
end

local function RestoreTorsoAim(sleepTime)
	Signal(SIG_RESTORE_TORSO)
	SetSignalMask(SIG_RESTORE_TORSO)
	Sleep(sleepTime or RESTORE_DELAY)
	if not nanoing then
		Turn(Stomach, z_axis, 0, TORSO_SPEED_YAW)
		aiming = false
	end
end

local function RestoreRightAim(sleepTime)
	StartThread(RestoreTorsoAim, sleepTime)
	Signal(SIG_RESTORE_RIGHT)
	SetSignalMask(SIG_RESTORE_RIGHT)
	Sleep(sleepTime or RESTORE_DELAY)
	if not nanoing then
		Turn(ArmRight, x_axis, math.rad(-5), ARM_SPEED_PITCH)
		Turn(HandRight, x_axis, math.rad(-5), ARM_SPEED_PITCH)
	end
end

local function RestoreLeftAim(sleepTime)
	StartThread(RestoreTorsoAim, sleepTime)
	Signal(SIG_RESTORE_LEFT)
	SetSignalMask(SIG_RESTORE_LEFT)
	Sleep(sleepTime or RESTORE_DELAY)
	Turn(ArmLeft, x_axis, math.rad(-5), ARM_SPEED_PITCH)
	Turn(Gun, x_axis, math.rad(-5), ARM_SPEED_PITCH)
end

local function AimArm(heading, pitch, arm, hand, wait)
	aiming = true
	Turn(arm, x_axis, -pitch/2 - 0.7, ARM_SPEED_PITCH)
	Turn(Stomach, z_axis, heading, TORSO_SPEED_YAW)
	Turn(hand, x_axis, -pitch/2 - 0.85, ARM_SPEED_PITCH)
	if wait then
		WaitForTurn(Stomach, z_axis)
		WaitForTurn(arm, x_axis)
	end
end

function script.AimWeapon(num, heading, pitch)
	if num == 5 then
		Signal(SIG_LEFT)
		SetSignalMask(SIG_LEFT)
		Signal(SIG_RESTORE_LEFT)
		Signal(SIG_RESTORE_TORSO)
		AimArm(heading, pitch, ArmLeft, Gun, true)
		StartThread(RestoreLeftAim)
		return true
	elseif num == 3 then
		Signal(SIG_RIGHT)
		SetSignalMask(SIG_RIGHT)
		Signal(SIG_RESTORE_RIGHT)
		Signal(SIG_RESTORE_TORSO)
		AimArm(heading, pitch, ArmRight, HandRight, true)
		StartThread(RestoreRightAim)
		return true
	elseif num == 2 or num == 4 then
		return true
	end
	return false
end

function script.FireWeapon(num)
	if num == 5 then
		EmitSfx(Muzzle, 1024)
	elseif num == 3 then
		EmitSfx(UnderMuzzle, 1026)
	end
end

function script.Shot(num)
	if num == 5 then
		EmitSfx(Muzzle, 1025)
	elseif num == 3 then
		EmitSfx(UnderMuzzle, 1027)
	end
end

local function NanoAnimation()
	Signal(SIG_NANO)
	SetSignalMask(SIG_NANO)
	while true do
		Turn(FingerA, x_axis, FINGER_ANGLE_OUT, FINGER_SPEED)
		Sleep(200)
		Turn(FingerB, x_axis, FINGER_ANGLE_IN, FINGER_SPEED)
		Sleep(200)
		Turn(FingerC, x_axis, FINGER_ANGLE_OUT, FINGER_SPEED)
		Sleep(200)
		Turn(FingerA, x_axis, FINGER_ANGLE_IN, FINGER_SPEED)
		Sleep(200)
		Turn(FingerB, x_axis, FINGER_ANGLE_OUT, FINGER_SPEED)
		Sleep(200)
		Turn(FingerC, x_axis, FINGER_ANGLE_IN, FINGER_SPEED)
		Sleep(200)
	end
end

local function NanoRestore()
	Signal(SIG_NANO)
	SetSignalMask(SIG_NANO)
	Sleep(500)
	Turn(FingerA, x_axis, 0, FINGER_SPEED)
	Turn(FingerB, x_axis, 0, FINGER_SPEED)
	Turn(FingerC, x_axis, 0, FINGER_SPEED)
end

function script.StopBuilding()
	SetUnitValue(COB.INBUILDSTANCE, 0)
	StartThread(RestoreRightAim, 200)
	StartThread(NanoRestore)
	nanoing = false
end

function script.StartBuilding(heading, pitch)
	AimArm(heading, pitch, ArmRight, HandRight, false)
	SetUnitValue(COB.INBUILDSTANCE, 1)
	StartThread(NanoAnimation)
	nanoing = true
end

---------------------------------------------------------------------
---------------------------------------------------------------------
-- Creation and Death

function script.Create()
	local map = Spring.GetUnitPieceMap(unitID);
	local offsets = constructSkeleton(unitID,map.Scene, {0,0,0});
	
	for a,anim in pairs(Animations) do
	    for i,keyframe in pairs(anim) do
		local commands = keyframe.commands;
		for k,command in pairs(commands) do
		    -- commands are described in (c)ommand,(p)iece,(a)xis,(t)arget,(s)peed format
		    -- the t attribute needs to be adjusted for move commands from blender's absolute values
		    if (command.c == "move") then
			local adjusted =  command.t - (offsets[command.p][command.a]);
			Animations[a][i]['commands'][k].t = command.t - (offsets[command.p][command.a]);
		    end
		end
	    end
	end
	
	Turn(Muzzle, x_axis, math.rad(180))
	Turn(UnderMuzzle,x_axis, math.rad(180))
	
	--dyncomm.Create()
	Spring.SetUnitNanoPieces(unitID, nanoPieces)
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity < 0.5 then
		-- Pointless because deathclone contains head.
		--Explode(Head, SFX.FALL)
		--Hide(Head)
		
		GG.Script.InitializeDeathAnimation(unitID)
		PlayAnimation('die')
		
		Explode(ArmLeft, SFX.NONE)
		Explode(ArmRight, SFX.NONE)
		Explode(CalfLeft, SFX.NONE)
		Explode(CalfRight, SFX.NONE)
		
		--dyncomm.SpawnModuleWrecks(1)
		--dyncomm.SpawnWreck(1)
	else
		Explode(Head, SFX.FALL + SFX.FIRE)
		Explode(Stomach, SFX.FALL + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE)
		Explode(ArmLeft, SFX.FALL + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE)
		Explode(ArmRight, SFX.FALL + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE)
		Explode(HandRight, SFX.FALL + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE)
		Explode(Gun, SFX.FALL + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE)
		Explode(CalfLeft, SFX.FALL + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE)
		Explode(CalfRight, SFX.FALL + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE)
		Explode(HipLeft, SFX.FALL + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE)
		Explode(HipRight, SFX.FALL + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE)
		Explode(Breast, SFX.SHATTER + SFX.EXPLODE)
		--dyncomm.SpawnModuleWrecks(2)
		--dyncomm.SpawnWreck(2)
	end
end
