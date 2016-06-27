-- these are satellite pieces
local LimbA1 = piece('LimbA1');
local LimbA2 = piece('LimbA2');
local LimbB1 = piece('LimbB1');
local LimbB2 = piece('LimbB2');
local LimbC1 = piece('LimbC1');
local LimbC2 = piece('LimbC2');
local LimbD1 = piece('LimbD1');
local LimbD2 = piece('LimbD2');
local Satellite = piece('Satellite');
local SatelliteMuzzle = piece('SatelliteMuzzle');

local InnerLimbs = {LimbA1,LimbB1,LimbC1,LimbD1};
local OuterLimbs = {LimbA2,LimbB2,LimbC2,LimbD2};

local SIG_DOCK  = 2;
local SIG_SHOOT = 4;

local on = false;
local shooting = 0;

function script.Create()
    -- um. do nothing i guess.
end

function Dock()
    SetSignalMask(SIG_DOCK);
    for i=1,4 do
        Turn(InnerLimbs[i],y_axis,math.rad(0),1);
        Turn(OuterLimbs[i],y_axis,math.rad(0),1);
    end
end

function Undock()
    SetSignalMask(SIG_DOCK);
    for i=1,4 do
        Turn(InnerLimbs[i],y_axis,math.rad(-85),1);
        Turn(OuterLimbs[i],y_axis,math.rad(-85),1);
    end
end

function Shoot()
    SetSignalMask(SIG_SHOOT)
    while(on) do
        if shooting ~= 0 then
            --EmitSfx(SatelliteMuzzle, FIRE_W2)
            EmitSfx(EmitterMuzzle, FIRE_W3)
            shooting = shooting - 1
        else
            --EmitSfx(SatelliteMuzzle, FIRE_W4)
            EmitSfx(EmitterMuzzle, FIRE_W5)
        end
    end
end

function mahlazer_SetShoot(n)
    shooting = n;
end 

-- prepare the laser beam, i'm gonna use it tonite
function mahlazer_EngageTheLaserBeam() -- it's gonna END YOUR LIFE
    on = true
end

function mahlazer_DisengageTheLaserBeam()
    on = false
end

function mahlazer_AimAt(pitch)

end

function mahlazer_Undock()
    Signal(SIG_DOCK);
    StartThread(Undock);
end

function mahlazer_Dock()
    Signal(SIG_DOCK);
    StartThread(Dock);
end
