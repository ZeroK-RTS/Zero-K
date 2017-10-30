include "constants.lua"

local Core = piece('Core');
local CoverL1 = piece('CoverL1');
local CoverL2 = piece('CoverL2');
local CoverL3 = piece('CoverL3');
local CoverMid = piece('CoverMid');
local CoverR1 = piece('CoverR1');
local CoverR2 = piece('CoverR2');
local CoverR3 = piece('CoverR3');
local CraneRoot = piece('CraneRoot');
local CraneWheel = piece('CraneWheel');
local Lid = piece('Lid');
local Nanos = piece('Nanos');
local RailBottom = piece('RailBottom');
local RailTop = piece('RailTop');
local Slider = piece('Slider');
local Train = piece('Train');
local Nano1 = piece('NanoLeft');
local Nano2 = piece('NanoRight');
local nanoPieces = {Nano1,Nano2};
local Nanoframe = piece('Nanoframe');
local scriptEnv = {	Core = Core,
	CoverL1 = CoverL1,
	CoverL2 = CoverL2,
	CoverL3 = CoverL3,
	CoverMid = CoverMid,
	CoverR1 = CoverR1,
	CoverR2 = CoverR2,
	CoverR3 = CoverR3,
	CraneRoot = CraneRoot,
	CraneWheel = CraneWheel,
	Lid = Lid,
	Nanos = Nanos,
	RailBottom = RailBottom,
	RailTop = RailTop,
	Slider = Slider,
	Train = Train,
	x_axis = x_axis,
	y_axis = y_axis,
	z_axis = z_axis,
}

local Animations = {};
-- you can include externally saved animations like this:
-- Animations['importedAnimation'] = VFS.Include("Scripts/animations/animationscript.lua", scriptEnv)
Animations['wrap'] =  {
	{
		['time'] = 1,
		['commands'] = {
			{['c']='move',['p']=RailBottom, ['a']=x_axis, ['t']=-0.000002, ['s']=0.000007},
			{['c']='move',['p']=RailBottom, ['a']=y_axis, ['t']=2.612743, ['s']=35.803078},
			{['c']='move',['p']=RailBottom, ['a']=z_axis, ['t']=5.531182, ['s']=0.000003},
			{['c']='turn',['p']=CraneWheel, ['a']=x_axis, ['t']=-0.022506, ['s']=2.573684},
			{['c']='turn',['p']=CraneWheel, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 10,
		['commands'] = {
			{['c']='move',['p']=RailTop, ['a']=x_axis, ['t']=0.000000, ['s']=0.000015},
			{['c']='move',['p']=RailTop, ['a']=y_axis, ['t']=3.621014, ['s']=141.839333},
			{['c']='move',['p']=RailTop, ['a']=z_axis, ['t']=10.138749, ['s']=0.000172},
		}
	},
	{
		['time'] = 15,
		['commands'] = {
		}
	},
	{
		['time'] = 17,
		['commands'] = {
			{['c']='turn',['p']=CraneRoot, ['a']=x_axis, ['t']=0.014524, ['s']=1.314234},
			{['c']='turn',['p']=CraneRoot, ['a']=y_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=CraneRoot, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 20,
		['commands'] = {
			{['c']='turn',['p']=Lid, ['a']=x_axis, ['t']=0.000000, ['s']=1.554046},
		}
	},
	{
		['time'] = 25,
		['commands'] = {
			{['c']='turn',['p']=CoverR1, ['a']=y_axis, ['t']=0.000000, ['s']=3.926991},
			{['c']='turn',['p']=CoverL1, ['a']=x_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=CoverL1, ['a']=y_axis, ['t']=-0.000000, ['s']=3.926991},
		}
	},
	{
		['time'] = 28,
		['commands'] = {
			{['c']='move',['p']=Slider, ['a']=z_axis, ['t']=7.485815, ['s']=53.597031},
		}
	},
	{
		['time'] = 35,
		['commands'] = {
		}
	},
	{
		['time'] = 37,
		['commands'] = {
		}
	},
	{
		['time'] = 40,
		['commands'] = {
			{['c']='turn',['p']=CoverR3, ['a']=x_axis, ['t']=-0.000000, ['s']=0.000001},
			{['c']='turn',['p']=CoverR3, ['a']=y_axis, ['t']=0.000000, ['s']=4.712389},
			{['c']='turn',['p']=CoverR3, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=CoverL3, ['a']=x_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=CoverL3, ['a']=y_axis, ['t']=0.000000, ['s']=4.712389},
			{['c']='turn',['p']=CoverL3, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 43,
		['commands'] = {
			{['c']='move',['p']=Slider, ['a']=z_axis, ['t']=9.135993, ['s']=16.501784},
			{['c']='turn',['p']=CoverR2, ['a']=x_axis, ['t']=0.000000, ['s']=0.000003},
			{['c']='turn',['p']=CoverR2, ['a']=y_axis, ['t']=-0.000000, ['s']=7.853983},
			{['c']='turn',['p']=CoverR2, ['a']=z_axis, ['t']=0.000000, ['s']=0.000002},
			{['c']='turn',['p']=CoverL2, ['a']=x_axis, ['t']=0.000000, ['s']=0.000002},
			{['c']='turn',['p']=CoverL2, ['a']=y_axis, ['t']=0.000000, ['s']=7.853982},
			{['c']='turn',['p']=CoverL2, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 45,
		['commands'] = {
		}
	},
	{
		['time'] = 46,
		['commands'] = {
		}
	},
}

Animations['unwrap'] = {
	{
		['time'] = 0,
		['commands'] = {
			{['c']='move',['p']=RailBottom, ['a']=x_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='move',['p']=RailBottom, ['a']=y_axis, ['t']=2.155593, ['s']=0.000000},
			{['c']='move',['p']=RailBottom, ['a']=z_axis, ['t']=6.928282, ['s']=0.000000},
			{['c']='turn',['p']=RailBottom, ['a']=x_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=RailBottom, ['a']=y_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=RailBottom, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='move',['p']=CraneRoot, ['a']=x_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='move',['p']=CraneRoot, ['a']=y_axis, ['t']=36.534252, ['s']=0.000000},
			{['c']='move',['p']=CraneRoot, ['a']=z_axis, ['t']=3.615304, ['s']=0.000000},
			{['c']='turn',['p']=CraneRoot, ['a']=x_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=CraneRoot, ['a']=y_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=CraneRoot, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='move',['p']=CoverL2, ['a']=x_axis, ['t']=8.201941, ['s']=0.000000},
			{['c']='move',['p']=CoverL2, ['a']=y_axis, ['t']=-24.489695, ['s']=0.000000},
			{['c']='move',['p']=CoverL2, ['a']=z_axis, ['t']=16.467146, ['s']=0.000000},
			{['c']='turn',['p']=CoverL2, ['a']=x_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=CoverL2, ['a']=y_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=CoverL2, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='move',['p']=Nanos, ['a']=x_axis, ['t']=-0.116086, ['s']=0.000000},
			{['c']='move',['p']=Nanos, ['a']=y_axis, ['t']=-18.875809, ['s']=0.000000},
			{['c']='move',['p']=Nanos, ['a']=z_axis, ['t']=11.748278, ['s']=0.000000},
			{['c']='turn',['p']=Nanos, ['a']=x_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=Nanos, ['a']=y_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=Nanos, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='move',['p']=Lid, ['a']=x_axis, ['t']=-0.000003, ['s']=0.000000},
			{['c']='move',['p']=Lid, ['a']=y_axis, ['t']=39.865829, ['s']=0.000000},
			{['c']='move',['p']=Lid, ['a']=z_axis, ['t']=-0.091102, ['s']=0.000000},
			{['c']='turn',['p']=Lid, ['a']=x_axis, ['t']=-1.132460, ['s']=2.775761},
			{['c']='turn',['p']=Lid, ['a']=y_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=Lid, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='move',['p']=Slider, ['a']=x_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='move',['p']=Slider, ['a']=y_axis, ['t']=-48.281994, ['s']=0.000000},
			{['c']='move',['p']=Slider, ['a']=z_axis, ['t']=-7.269339, ['s']=42.078442},
			{['c']='turn',['p']=Slider, ['a']=x_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=Slider, ['a']=y_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=Slider, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='move',['p']=CoverR3, ['a']=x_axis, ['t']=-5.198719, ['s']=0.000000},
			{['c']='move',['p']=CoverR3, ['a']=y_axis, ['t']=-24.489706, ['s']=0.000000},
			{['c']='move',['p']=CoverR3, ['a']=z_axis, ['t']=19.474293, ['s']=0.000000},
			{['c']='turn',['p']=CoverR3, ['a']=x_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=CoverR3, ['a']=y_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=CoverR3, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='move',['p']=RailTop, ['a']=x_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='move',['p']=RailTop, ['a']=y_axis, ['t']=6.517995, ['s']=0.000000},
			{['c']='move',['p']=RailTop, ['a']=z_axis, ['t']=12.166483, ['s']=0.000000},
			{['c']='turn',['p']=RailTop, ['a']=x_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=RailTop, ['a']=y_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=RailTop, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='move',['p']=CoverL3, ['a']=x_axis, ['t']=5.210072, ['s']=0.000000},
			{['c']='move',['p']=CoverL3, ['a']=y_axis, ['t']=-24.489695, ['s']=0.000000},
			{['c']='move',['p']=CoverL3, ['a']=z_axis, ['t']=19.432764, ['s']=0.000000},
			{['c']='turn',['p']=CoverL3, ['a']=x_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=CoverL3, ['a']=y_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=CoverL3, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='move',['p']=Train, ['a']=x_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='move',['p']=Train, ['a']=y_axis, ['t']=-17.705730, ['s']=0.000000},
			{['c']='move',['p']=Train, ['a']=z_axis, ['t']=13.154654, ['s']=0.000000},
			{['c']='turn',['p']=Train, ['a']=x_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=Train, ['a']=y_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=Train, ['a']=z_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='move',['p']=CraneWheel, ['a']=x_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='move',['p']=CraneWheel, ['a']=y_axis, ['t']=-4.197151, ['s']=0.000000},
			{['c']='move',['p']=CraneWheel, ['a']=z_axis, ['t']=9.536642, ['s']=0.000000},
			{['c']='turn',['p']=CraneWheel, ['a']=x_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=CraneWheel, ['a']=y_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=CraneWheel, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='move',['p']=CoverR2, ['a']=x_axis, ['t']=-8.177095, ['s']=0.000000},
			{['c']='move',['p']=CoverR2, ['a']=y_axis, ['t']=-24.489697, ['s']=0.000000},
			{['c']='move',['p']=CoverR2, ['a']=z_axis, ['t']=16.505508, ['s']=0.000000},
			{['c']='turn',['p']=CoverR2, ['a']=x_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=CoverR2, ['a']=y_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=CoverR2, ['a']=z_axis, ['t']=0.000001, ['s']=0.000000},
			{['c']='move',['p']=CoverR1, ['a']=x_axis, ['t']=-8.190782, ['s']=0.000000},
			{['c']='move',['p']=CoverR1, ['a']=y_axis, ['t']=-24.489697, ['s']=0.000000},
			{['c']='move',['p']=CoverR1, ['a']=z_axis, ['t']=0.775544, ['s']=0.000000},
			{['c']='turn',['p']=CoverR1, ['a']=x_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=CoverR1, ['a']=y_axis, ['t']=-1.570796, ['s']=2.771993},
			{['c']='turn',['p']=CoverR1, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='move',['p']=CoverL1, ['a']=x_axis, ['t']=8.228187, ['s']=0.000000},
			{['c']='move',['p']=CoverL1, ['a']=y_axis, ['t']=-24.489697, ['s']=0.000000},
			{['c']='move',['p']=CoverL1, ['a']=z_axis, ['t']=0.772944, ['s']=0.000000},
			{['c']='turn',['p']=CoverL1, ['a']=x_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=CoverL1, ['a']=y_axis, ['t']=1.570796, ['s']=2.771993},
			{['c']='turn',['p']=CoverL1, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 10,
		['commands'] = {
		}
	},
	{
		['time'] = 13,
		['commands'] = {
			{['c']='turn',['p']=CraneRoot, ['a']=x_axis, ['t']=-0.901103, ['s']=2.252758},
			{['c']='turn',['p']=CraneRoot, ['a']=y_axis, ['t']=0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 16,
		['commands'] = {
			{['c']='move',['p']=RailTop, ['a']=x_axis, ['t']=0.000002, ['s']=0.000008},
			{['c']='move',['p']=RailTop, ['a']=y_axis, ['t']=-24.721771, ['s']=104.132555},
			{['c']='move',['p']=RailTop, ['a']=z_axis, ['t']=11.479476, ['s']=2.290023},
		}
	},
	{
		['time'] = 17,
		['commands'] = {
		}
	},
	{
		['time'] = 19,
		['commands'] = {
			{['c']='turn',['p']=CoverR2, ['a']=x_axis, ['t']=-0.000000, ['s']=0.000001},
			{['c']='turn',['p']=CoverR2, ['a']=y_axis, ['t']=-0.785398, ['s']=2.945243},
			{['c']='turn',['p']=CoverR2, ['a']=z_axis, ['t']=0.000001, ['s']=0.000000},
			{['c']='turn',['p']=CoverL2, ['a']=x_axis, ['t']=0.000000, ['s']=0.000001},
			{['c']='turn',['p']=CoverL2, ['a']=y_axis, ['t']=0.785398, ['s']=2.945243},
			{['c']='turn',['p']=CoverL2, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 21,
		['commands'] = {
			{['c']='turn',['p']=CraneWheel, ['a']=x_axis, ['t']=0.879115, ['s']=2.197788},
			{['c']='turn',['p']=CraneWheel, ['a']=y_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=CraneWheel, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 25,
		['commands'] = {
		}
	},
	{
		['time'] = 27,
		['commands'] = {
			{['c']='turn',['p']=CoverR3, ['a']=x_axis, ['t']=0.000000, ['s']=0.000001},
			{['c']='turn',['p']=CoverR3, ['a']=y_axis, ['t']=-0.785398, ['s']=4.712389},
			{['c']='turn',['p']=CoverR3, ['a']=z_axis, ['t']=-0.000000, ['s']=0.000001},
			{['c']='turn',['p']=CoverL3, ['a']=x_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=CoverL3, ['a']=y_axis, ['t']=0.785398, ['s']=4.712389},
			{['c']='turn',['p']=CoverL3, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 32,
		['commands'] = {
		}
	},
	{
		['time'] = 33,
		['commands'] = {
			{['c']='move',['p']=RailBottom, ['a']=x_axis, ['t']=0.000001, ['s']=0.000004},
			{['c']='move',['p']=RailBottom, ['a']=y_axis, ['t']=-9.905491, ['s']=51.690361},
			{['c']='move',['p']=RailBottom, ['a']=z_axis, ['t']=6.663042, ['s']=1.136744},
		}
	},
	{
		['time'] = 34,
		['commands'] = {
			{['c']='turn',['p']=Nanos, ['a']=x_axis, ['t']=0.171871, ['s']=0.859355},
			{['c']='turn',['p']=Nanos, ['a']=y_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=Nanos, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 40,
		['commands'] = {
		}
	},
}



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

function script.Create()
    local map = Spring.GetUnitPieceMap(unitID);
    local offsets = constructSkeleton(unitID,map.Scene, {0,0,0});

	Spring.SetUnitNanoPieces (unitID, nanoPieces)

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
end


local function Open ()
	SetSignalMask (1)
	PlayAnimation('unwrap')
		-- set values
	SetUnitValue (COB.YARD_OPEN, 1)
	SetUnitValue (COB.INBUILDSTANCE, 1)
	SetUnitValue (COB.BUGGER_OFF, 1)

	while(true) do
		Move(Train,y_axis, 21,4);
		WaitForMove(Train,y_axis);
		Move(Train,y_axis,0,4);
		WaitForMove(Train,y_axis);
	end
end

local function Close()
	Signal (1)

	-- set values
	SetUnitValue (COB.YARD_OPEN, 0)
	SetUnitValue (COB.BUGGER_OFF, 0)
	SetUnitValue (COB.INBUILDSTANCE, 0)

	Move(Train,y_axis,0,10);
	WaitForMove(Train,y_axis);

	PlayAnimation('wrap')
end

function script.QueryNanoPiece ()
	GG.LUPS.QueryNanoPiece (unitID, unitDefID, Spring.GetUnitTeam(unitID), Nano1)
	return Nano1
end

function script.Activate()
	StartThread (Open) -- animation needs its own thread because Sleep and WaitForTurn will not work otherwise
end

function script.Deactivate ()
	StartThread (Close)
end

function script.QueryBuildInfo ()
	return Nanoframe
end

function script.Killed (recentDamage, maxHealth)
	return 1
end
       

            