--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "CEG Spawner",
    desc      = 'Spawn CEGs',
    author    = "CarRepairer",
    date      = "2010-11-07",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true,
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:RecvLuaMsg(msg, playerID)
	if not Spring.IsCheatingEnabled() then return end
	
	local ceg_msg_prefix = "*"
	local ceg_msg = (msg:find(ceg_msg_prefix,1,true))
	
	if ceg_msg then
		msg = msg:sub(2)
		msg = Spring.Utilities.ExplodeString('|', msg)
		Spring.Echo('Spawning CEG', msg[1] )
		Spring.SpawnCEG( msg[1], --cegname
			msg[2], msg[3], msg[4],  --pos
			msg[5], msg[6], msg[7],  --dir
			msg[8]  --radius
			)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
