--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "MessageBoxes",
    desc      = "Displays messages from missions.",
    author    = "quantum",
    date      = "Nov 2010",
    license   = "GNU GPL, v2 or later",
    layer     = 1, 
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local msgBoxPersistent

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


function WG.ShowMessageBox(text, width, height, fontsize, pause)  
  local Chili = WG.Chili
  local vsx, vsy = gl.GetViewSizes()
  
  -- reverse compatibility
  if height == 0 or height == nil then height = 300 end
  if fontsize == 0 or fontsize == nil then fontsize = 14 end
  
  local x = math.floor((vsx - width)/2)
  local y = math.floor((vsy - height)/2)

  if pause then
    Spring.SendCommands("pause 1")
  end
  local window
  window = Chili.Window:New{  
    x = x,  
    y = y,
	--autosize	 = true,	-- donut work
    clientWidth  = width,
    clientHeight = height,
    resizable = true,
    draggable = true,
    parent = Chili.Screen0,
    children = {
      Chili.Button:New{ 
        caption = 'Close', 
        OnMouseUp = { function(self) 
          window:Dispose()
          if pause then
            Spring.SendCommands("pause 0")
          end
        end },           
        x=0,
        height=30,
        right=10,
        bottom=1,
      },
      Chili.ScrollPanel:New{
        x = 5,
        y = 5,
        bottom = 40,
        right=5,
        horizontalScrollbar = false,
        children = {
          Chili.TextBox:New{
            text = text,
            width = '90%',
            align="left",
            fontsize = fontsize or 16,
            padding = {5, 5, 5, 5},
            lineSpacing = 0,
            fontOutline = true,
          },
        },
      },
    }
  }
end

function WG.ShowPersistentMessageBox(text, width, height, fontsize, imageDir)  
	local Chili = WG.Chili
	local vsx, vsy = gl.GetViewSizes()
	local image
	
	--local x = math.floor((vsx - width)/2)
	local y = math.floor((vsy - height)/2)
	
	if not width then
		Spring.Echo("Width is nil")
		width = 320
	end
	if not height then
		Spring.Echo("Height is nil")
		height = 100
	end
	
	-- get rid of existing box if we have one
	if msgBoxPersistent then
		msgBoxPersistent:Dispose()
	end
	msgBoxPersistent = Chili.Window:New{
		parent = Chili.Screen0,
		name   = 'msgWindow';
		width = width,
		height = height,
		y = y,
		right = vsx; 
		dockable = true;
		draggable = false,
		resizable = false,
		tweakDraggable = true,
		tweakResizable = false,
		padding = {5, 0, 5, 0},
		minimizable = true,
		--itemMargin  = {0, 0, 0, 0},
	}
	if imageDir then image = Chili.Image:New {
			width = height * 0.8,
			height = height * 0.8,
			bottom = 10,
			y= 10;
			x= 5;
			keepAspect = true,
			file = imageDir;
			parent = msgBoxPersistent;
		}
	end
	local x = ((image and image.width + image.x) or 0) + 5
	local scroll = Chili.ScrollPanel:New{
		parent  = msgBoxPersistent;
		x       = x,
		y		= 8,
		height	= height - 8 - 8,
		width   = (width - x - 10),
        horizontalScrollbar = false,
		children = {
			Chili.TextBox:New{
				parent  = scroll;
				text    = text or '',
				width   = "100%",
				height	= "100%",
				valign  = "ascender";
				align   = "left";
				padding = {5, 5, 5, 5},
				lineSpacing = 0,
				font    = {
					size   = fontsize or 12;
					shadow = true;
				},
			}		
		}
    }

end

function WG.HidePersistentMessageBox()
	if msgBoxPersistent then
		msgBoxPersistent:Dispose()
	end
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------