--------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name		= "Chatroom",
		desc		= "Chatroom",
		author		= "CarRepairer",
		date 		= "2010-12-16",
		license		= "GNU GPL, v2 or later",
		layer		= -999,
		enabled		= true,  --  loaded by default?
	}
end


if not (Spring.GetModOptions() and Spring.GetModOptions().chatroom) then
	return false
end
Spring.SetGameRulesParam("chatroom",1)

local echo = Spring.Echo

if gadgetHandler:IsSyncedCode() then
--SYNCED-------------------------------------------------------------------

local avatars = {}
local want_avatar = {}

---------------------------------------------------------------------------

local function SwapUnits(playerID)
	local _,_,_,teamID, allianceID = Spring.GetPlayerInfo(playerID)
	
	local unitID = avatars[teamID]
	
	local x,y,z = 200,10,200
	if unitID then
		x,y,z = Spring.GetUnitPosition(unitID)
	end
	local newUnitID = Spring.CreateUnit(want_avatar[playerID], x,y,z, 0, teamID) -- selfd = false, reclaim = true
	Spring.SetCameraTarget(x, y, z)
	Spring.SelectUnitArray{newUnitID}
	
	if unitID then
		Spring.DestroyUnit(unitID, false, true) -- selfd = false, reclaim = true
	end
end


--CALLINS-------------------------------------------------------------------
function gadget:AllowUnitBuildStep(builderID, teamID, unitID, unitDefID, step) 
	local ud = UnitDefs[unitDefID]
	if ud and ud.name == 'terraunit' then
		return true
	end
	return false
end

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	
	if cmdID == CMD.ATTACK 
		or cmdID == CMD.SELFD
		or cmdID < 0
		then
		
		return false
	end
	
	return true
end


function gadget:UnitCreated(unitID, unitDefID, teamID)
	Spring.GiveOrderToUnit(unitID, CMD.FIRE_STATE, { 0 }, {})
	avatars[teamID] = unitID
end

function gadget:UnitPreDamaged()
	return 0
end


function gadget:RecvLuaMsg(msg, playerID)
	local prefix = "^"
	local found = msg:find(prefix,1,true)
	
	if found then
		local _,_, spec, teamID, allianceID = Spring.GetPlayerInfo(playerID)
		
		local udid = msg:sub(#prefix+1)
		
		if( type(udid+0) ~= 'number' ) then
			echo ('<Chatroom> (A) Player ' .. playerID .. ' on team ' .. teamID .. ' tried to send a nonsensical command.')
			return false
		end
		
		want_avatar[playerID] = udid+0
		
	end

end

function gadget:GameFrame(f)
	if ( f % (32 * 20) ) < 0.1 then
		--echo 'Swapping avatars'
		for playerID, udid in pairs(want_avatar) do
			SwapUnits(playerID)
		end
		want_avatar = {}
	end
end

function gadget:Initialize()
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		local team = Spring.GetUnitTeam(unitID)
		gadget:UnitCreated(unitID, unitDefID, team)
	end
end


--SYNCED-----------------------------------------------------------------------
else
--UNSYNCED-----------------------------------------------------------------------



--UNSYNCED-----------------------------------------------------------------------
end

