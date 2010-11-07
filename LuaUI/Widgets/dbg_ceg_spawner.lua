--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "CEG Spawner",
    desc      = "Spawn CEGs",
    author    = "CarRepairer",
    date      = "2010-11-07",
    license   = "GPLv2",
    layer     = 5,
    enabled   = false,  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local echo = Spring.Echo
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

options = {}


local vsx, vsy = widgetHandler:GetViewSizes()
local cx,cy = vsx * 0.5,vsy * 0.5

local explosionDefs = VFS.Include("gamedata/explosions.lua")


local function AddCEGButton(cegname)
	options[cegname] = {
		type = 'button',
		name = cegname,
		OnChange = function()
			if not Spring.IsCheatingEnabled() then 
				echo "Cannot do this unless Cheating is enabled."
				return 
			end		
			cx,cy = vsx * 0.5,vsy * 0.5
			local ttype,pos = Spring.TraceScreenRay(cx, cy, true)
			if ttype == 'ground' then
				Spring.SendLuaRulesMsg( '*' .. cegname
					.. '|' .. pos[1]
					.. '|' .. pos[2]
					.. '|' .. pos[3]
				) 
			else
				echo "Cannot do this with a unit in the center of the screen."
			end
		end,
	}
end

for k,v in pairs(explosionDefs) do
	--echo(k,v)
	AddCEGButton(k)
end


function widget:ViewResize(viewSizeX, viewSizeY)
	vsx = viewSizeX
	vsy = viewSizeY
	cx = vsx * 0.5
	cy = vsy * 0.5
end
