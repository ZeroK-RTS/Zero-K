---@meta

---@type integer
unitID=unitID

---@type integer
unitDefID=unitDefID

---@type table
UnitDef=UnitDef

---@enum axis
local axises={
	x_axis=1,
	y_axis=2,
	z_axis=3,
}

x_axis=axises.x_axis
y_axis=axises.y_axis
z_axis=axises.z_axis

---@class Piece:integer

---Get the piece number by piece name
---@param ... string
---@return Piece ...Piece
function piece(...)end

---@param piece Piece
---@param visible boolean
function SetPieceVisibility(piece,visible)end

-- local su=Spring.UnitScript

---@param piece Piece
function Show(piece)end

---@param piece Piece
function Hide(piece)end

---Move piece along axis to the destination position. 
---
---If speed is given, the piece isn't moved immediately, but will move there at the desired speed. 
---
---The X axis is mirrored compared to BOS/COB scripts, to match the direction of the X axis in Spring world space.
---@param piece Piece
---@param axis axis
---@param destination number
---@param speed? number
function Move(piece, axis, destination, speed)end

---Turn piece around axis to the destination angle. 
---
---If speed is given, the piece isn't rotated immediately, but will turn at the desired angular velocity. 
---
---Angles are in radians. 
---
---Always uses the shortest angular towards destination degree, and if at exactly 180 degrees opposite, will go counter-clockwise.
---@param piece Piece
---@param axis axis
---@param destination number
---@param speed? number
function Turn(piece, axis, destination, speed)end

---Makes piece spin around axis at the desired angular velocity. 
---
---If accel is given, the piece does not start at this velocity at once, but will accelerate to it. 
---
---Both negative and positive angular velocities are supported. 
---
---Accel should always be positive, even if speed is negative.
---@param piece Piece
---@param axis axis
---@param speed number
---@param accel? number
function Spin(piece, axis, speed, accel)end

---Stops a piece from spinning around the given axis. 
---
---If decel is given, the piece does not stop at once, but will decelerate to it. 
---
---Decel should always be positive. 
---
---This function is similar to Spin(piece, axis, 0, decel), however, StopSpin also frees up the animation record.
---@param piece Piece
---@param axis axis
---@param decel? number
function StopSpin(piece, axis, decel)end

---@param piece Piece
---@param axis axis
function IsInTurn(piece, axis)end

---@param piece Piece
---@param axis axis
function IsInMove(piece, axis)end

---@param piece Piece
---@param axis axis
function IsInSpin(piece, axis)end

---Get the current translation of a piece. The returned numbers match the values passed into Move and Turn.
---@param piece Piece
---@return number x,number y,number z
function GetPieceTranslation(piece)end


---Get the current Rotation of a piece. The returned numbers match the values passed into Move and Turn.
---@param piece Piece
---@return number x,number y,number z
function GetPieceRotation(piece)end

---Get the piece's position (px, py, pz) and direction (dx, dy, dz) in unit space. 
---
---This is quite similar to Spring.GetUnitPiecePosDir, however that function returns in world space.
---@param piece Piece
---@return number px,number py,number pz,number dx,number dy,number dz
function GetPiecePosDir(piece)end

---Starts a new (animation) thread, which will execute the function 'fun'.
---
---All arguments except the function to run are passed as-is as arguments to 'fun'.
---
---COB-Threads has a decent description on COB threads, which are mimicked here in Lua using coroutines.
---@generic params
---@param fun fun(...:params)
---@param ... `params`
function StartThread(fun,...)end

---SetSignalMask assigns a mask to the currently running thread (any new threads started by this one will inherit the signal mask).
---@param mask integer
function SetSignalMask(mask)end

---Signal immediately stops all threads of this unit for which the bitwise and of mask and signal is not zero.
---@param signal integer
function Signal(signal)end

---Waits until the piece has stopped moving along the axis.
---If the piece is not animating, this functions return at once. 
---@param piece Piece
---@param axis axis
function WaitForMove(piece, axis)end

---Waits until the piece has stopped turning around the axis.
---If the piece is not animating, this functions return at once. 
---@param piece Piece
---@param axis axis
function WaitForTurn(piece, axis)end

---Waits a number of milliseconds before returning.
---@param milliseconds number
function Sleep(milliseconds)end

---Emits a CEG effect or weapon from the given piece. The id is based on one of the effect or weapon ids defined in the units unitdef.
---
---If the piece has no geometry, then the sfx is emitted in the +z direction from the origin of the piece.
---
---If the piece has 1 vertex, the emit dir is the vector from the origin to the the position of the first vertex the emit position is the origin of the piece.
---
---If there is more than one vertex in the piece, then the emit vector is the vector pointing from v[0] to v[1], and the emit position is v[0].
---@param piece Piece
---@param sfxid SFX|integer
function EmitSfx(piece, sfxid)end

---Same as COB's show _inside_ FireWeaponX.
---@param piece Piece
function ShowFlare(piece)end

---Explodes a piece, optionally creating a particle which flies off. Typically used inside Killed. 
---
---Explode does not hide the piece by itself; if using it outside Killed you may want to Hide the piece immediately after.
---
---The flags may be any combination of:
---
---`SFX.NONE`: do nothing after creating a heatcloud. Other flags have no effect, except NO_HEATCLOUD. If that is given too, the call is a no-op.
---
---`SFX.SHATTER`: shatter the piece in many fragments. Only the NO_HEATCLOUD flag has any effect if this is present.
---
---`SFX.EXPLODE` | `SFX.EXPLODE_ON_HIT`: the piece that flies of should explode when it hits something.
---
---`SFX.FALL`: the piece should be affected by gravity (this is currently always forced on by Spring, to prevent pieces that float in air indefinitely).
---
---`SFX.SMOKE`: leave smoke trail.
---
---`SFX.FIRE`: the piece is on fire when it flies off.
---
---`SFX.NO_CEG_TRAIL`: disable a CEG trail, if present.
---
---`SFX.NO_HEATCLOUD`: suppress the heat cloud that's shown by default.
---@param piece Piece
---@param ... SFX flags
function Explode(piece,...)end


---Attaches another unit (a passenger, as this is designed for transports) to this unit. For AttachUnit, piece specifies the attachment point. 
---
---Attaching to piece -1 makes the passenger unit enter a void state whereby it will never:
---
---take damage, even from Lua (but can be killed by Lua)
---
---be rendered through any engine path (nor their icons)
---
---be intersect-able by either synced or unsynced rays
---
---block any other objects from existing on top of them
---
---be selectable
---@param piece Piece
---@param passengerID integer
function AttachUnit(piece, passengerID)end

---Detaches passenger
---@param passengerID integer
function DropUnit(passengerID)end

---@param cobValue COB
---@param ... any
function GetUnitValue(cobValue,...)end

---@param cobValue COB
---@param ... any
function SetUnitValue(cobValue,...)end