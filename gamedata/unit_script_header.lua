-- Author: Tobi Vollebregt

-- Do not overuse this:
-- there is a limit of 200 locals and 60 upvalues per Lua function!

local unitID = unitID
local unitDefID = unitDefID
local UnitDef = UnitDefs[unitDefID]

local UnitScript = Spring.UnitScript

local EmitSfx = UnitScript.EmitSfx
local Explode = UnitScript.Explode
local GetUnitValue = UnitScript.GetUnitValue
local SetUnitValue = UnitScript.SetUnitValue
local Hide = UnitScript.Hide
local Show = UnitScript.Show

local Move = UnitScript.Move
local Turn = UnitScript.Turn
local Spin = UnitScript.Spin
local StopSpin = UnitScript.StopSpin
local Scale = UnitScript.Scale

local MultiSetPieceVisibility = UnitScript.MultiSetPieceVisibility
local MultiMove = UnitScript.MultiMove
local MultiTurn = UnitScript.MultiTurn
local MultiSpin = UnitScript.MultiSpin
local MultiStopSpin = UnitScript.MultiStopSpin
local MultiScale = UnitScript.MultiScale
local MultiExplode = UnitScript.MultiExplode

local StartThread = UnitScript.StartThread
local Signal = UnitScript.Signal
local SetSignalMask = UnitScript.SetSignalMask
local Sleep = UnitScript.Sleep
local WaitForMove = UnitScript.WaitForMove
local WaitForTurn = UnitScript.WaitForTurn
local WaitForScale = UnitScript.WaitForScale

local x_axis = 1
local y_axis = 2
local z_axis = 3
