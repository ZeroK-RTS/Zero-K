local AntennaTip = piece('AntennaTip');
local ArmLeft = piece('ArmLeft');
local ArmRight = piece('ArmRight');
local AssLeft = piece('AssLeft');
local AssRight = piece('AssRight');
local Breast = piece('Breast');
local CalfLeft = piece('CalfLeft');
local CalfRight = piece('CalfRight');
local FingerA = piece('FingerA');
local FingerB = piece('FingerB');
local FingerC = piece('FingerC');
local FootLeft = piece('FootLeft');
local FootRight = piece('FootRight');
local Gun = piece('Gun');
local HandRight = piece('HandRight');
local Head = piece('Head');
local HipLeft = piece('HipLeft');
local HipRight = piece('HipRight');
local Muzzle = piece('Muzzle');
local Nano = piece('Nano');
local Stomach = piece('Stomach');
local UnderGun = piece('UnderGun');
local UnderMuzzle = piece('UnderMuzzle');

local scriptEnv = {	AntennaTip = AntennaTip,
	ArmLeft = ArmLeft,
	ArmRight = ArmRight,
	AssLeft = AssLeft,
	AssRight = AssRight,
	Breast = Breast,
	CalfLeft = CalfLeft,
	CalfRight = CalfRight,
	FingerA = FingerA,
	FingerB = FingerB,
	FingerC = FingerC,
	FootLeft = FootLeft,
	FootRight = FootRight,
	Gun = Gun,
	HandRight = HandRight,
	Head = Head,
	HipLeft = HipLeft,
	HipRight = HipRight,
	Muzzle = Muzzle,
	Nano = Nano,
	Stomach = Stomach,
	UnderGun = UnderGun,
	UnderMuzzle = UnderMuzzle,
	x_axis = x_axis,
	y_axis = y_axis,
	z_axis = z_axis,
}

local Animations = {}
--Animations["pose"] = VFS.Include("scripts/strikecom_pose.lua", scriptEnv);

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
    
    --PlayAnimation('pose');
end
            
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

---------------------------

function script.AimFromWeapon(num)
	return Head
end

function script.QueryWeapon(num)
	if num == 1 or num == 2 then 
		return Muzzle
	end
	return Stomach
end

function script.AimWeapon(num, heading, pitch)
	return true;
end

function script.QueryNanoPiece()
	GG.LUPS.QueryNanoPiece(unitID,unitDefID,Spring.GetUnitTeam(unitID),Nano)
	return Nano
end
