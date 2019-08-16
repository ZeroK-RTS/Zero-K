--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "CEG Spawner",
    desc      = "v0.031 Spawn CEGs",
    author    = "CarRepairer",
    date      = "2010-11-07",
    license   = "GPLv2",
    layer     = 5,
    enabled   = false,  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--Set to true to sort CEGs into alphabetic submenus. This cannot be added to epicmenu options because it's used to actually change those options.
local ALPHA = true

local echo = Spring.Echo
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
options_order = { 'reload', 'xdir', 'ydir', 'zdir', 'radius', }
options_path = 'Settings/Toolbox/CEG Spawner'
options = {
	reload = {
		name = 'Reload CEGs',
		type = 'button',
		OnChange = function() Spring.SendCommands('reloadcegs') end,
	},
	
	xdir = {
		name = 'X (-1,1)',
		type = 'number',
		min = -1, max = 1, step = 0.1,
		value = 0,
	},
	ydir = {
		name = 'Y (-1,1)',
		type = 'number',
		min = -1, max = 1, step = 0.1,
		value = 0,
	},
	zdir = {
		name = 'Z (-1,1)',
		type = 'number',
		min = -1, max = 1, step = 0.1,
		value = 0,
	},
	radius = {
		name = 'Radius (0 - 100)',
		type = 'number',
		min = 0, max = 100, step = 1,
		value = 20,
	},
}

local vsx, vsy = widgetHandler:GetViewSizes()
local cx,cy = vsx * 0.5,vsy * 0.5

function OnChangeFunc(self)
	if not Spring.IsCheatingEnabled() then
		echo "Cannot do this unless Cheating is enabled."
		return
	end
	cx,cy = vsx * 0.5,vsy * 0.5
	local ttype,pos = Spring.TraceScreenRay(cx, cy, true)
	if ttype == 'ground' then
		Spring.SendLuaRulesMsg( '*' .. self.cegname
			.. '|' .. pos[1]
			.. '|' .. pos[2]
			.. '|' .. pos[3]
			
			.. '|' .. options.xdir.value
			.. '|' .. options.ydir.value
			.. '|' .. options.zdir.value
			.. '|' .. options.radius.value
			
			
		)
	else
		echo "Cannot do this with a unit in the center of the screen."
	end
end
		
local function AddCEGButton(cegname)
	options_order[#options_order+1] = cegname
	
	options[cegname] = {
		type = 'button',
		name = cegname,
		cegname = cegname,
		OnChange = OnChangeFunc,
	}
	
	if ALPHA then
		options[cegname].path = options_path..'/' .. cegname:sub(1,1):upper()
		--echo ( options[cegname].path )
	end
end

local function SetupOptions()
	local explosionDefs = VFS.Include("gamedata/explosions.lua")

	local explosions2 = {}
	for k,v in pairs(explosionDefs) do
		--echo(k,v)
		explosions2[#explosions2+1] = k
	end
	table.sort(explosions2)
	for i,v in ipairs(explosions2) do
		AddCEGButton(v)
	end
end

function widget:ViewResize(viewSizeX, viewSizeY)
	vsx = viewSizeX
	vsy = viewSizeY
	cx = vsx * 0.5
	cy = vsy * 0.5
end

function widget:Initialize()
  SetupOptions()
end
