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

local echo = Spring.Echo

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


local function explode(div,str)
  if (div=='') then return false end
  local pos,arr = 0,{}
  -- for each divider found
  for st,sp in function() return string.find(str,div,pos,true) end do
    table.insert(arr,string.sub(str,pos,st-1)) -- Attach chars left of current divider
    pos = sp + 1 -- Jump past current divider
  end
  table.insert(arr,string.sub(str,pos)) -- Attach chars right of last divider
  return arr
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:RecvLuaMsg(msg, playerID)
	if not Spring.IsCheatingEnabled() then return end
	
	local ceg_msg_prefix = "*"
	local ceg_msg = (msg:find(ceg_msg_prefix,1,true))
	
	if ceg_msg then
		msg = msg:sub(2)
		msg = explode('|', msg)
		echo ('Spawning CEG', msg[1] )
		Spring.SpawnCEG( msg[1], --cegname
			msg[2], msg[3], msg[4],  --pos
			msg[5], msg[6], msg[7],  --dir
			msg[8]  --radius
			)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
