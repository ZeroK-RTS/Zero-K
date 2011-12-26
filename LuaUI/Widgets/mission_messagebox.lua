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
local Chili

local msgBoxPersistent
local imagePersistent
local scrollPersistent
local textPersistent

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
	local vsx, vsy = gl.GetViewSizes()
	
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
	
	-- we have an existing box, dispose of it
	--if msgBoxPersistent then
	--	msgBoxPersistent:ClearChildren()
	--	msgBoxPersistent:Dispose()
	--end	
	
	-- we have an existing box, modify that one instead of making a new one
	if msgBoxPersistent then
		msgBoxPersistent.width = width
		msgBoxPersistent.height = height
		msgBoxPersistent.x = vsx - width
		--msgBoxPersistent:Invalidate()
		if imageDir then
			imagePersistent.width = height * 0.8
			imagePersistent.height = height * 0.8
			imagePersistent.file = imageDir
			imagePersistent.color = {1, 1, 1, 1}
			
			local x = imagePersistent.width + imagePersistent.x + 5
			scrollPersistent.width = (width - x - 8)
		else
			imagePersistent.color = {1, 1, 1, 0}
			scrollPersistent.width = (width - 6 - 8)
		end
		imagePersistent:Invalidate()
		
		scrollPersistent.height	= height - 8 - 8
		--scrollPersistent:Invalidate()
		textPersistent:SetText(text or '')
		textPersistent.font.size = fontsize or 12
		--textPersistent:Invalidate()
		
		msgBoxPersistent:Invalidate()
		return	-- done here, exit
	end
	
	-- no messagebox exists, make one
	msgBoxPersistent = Chili.Window:New{
		parent = Chili.Screen0,
		name   = 'msgWindow';
		width = width,
		height = height,
		y = y,
		right = 0; 
		dockable = true;
		draggable = false,
		resizable = false,
		tweakDraggable = true,
		tweakResizable = false,
		padding = {5, 0, 5, 0},
		--minimizable = true,
		--itemMargin  = {0, 0, 0, 0},
	}

	imagePersistent = Chili.Image:New {
		width = height * 0.8,
		height = height * 0.8,
		y = 10;
		x = 5;
		keepAspect = true,
		file = imageDir;
		parent = msgBoxPersistent;
	}
	
	local x = ((imageDir and imagePersistent.width + imagePersistent.x) or 0) + 5
	scrollPersistent = Chili.ScrollPanel:New{
		parent  = msgBoxPersistent;
		right	= 4,
		y		= 8,
		height	= height - 8 - 8,
		width   = (width - x - 8),
        horizontalScrollbar = false,
    }
	
	textPersistent = Chili.TextBox:New{
		text    = text or '',
		autosize = false,
		valign  = "ascender";
		align   = "left";
		padding = {5, 5, 5, 5},
		lineSpacing = 0,
		font    = {
			size   = fontsize or 12;
			shadow = true;
		},
	}	
	scrollPersistent:AddChild(textPersistent)
end

function WG.HidePersistentMessageBox()
	if msgBoxPersistent then
		msgBoxPersistent:Dispose()
	end
end

-- for testing box changes
--[[
local bool = true
local timer = 5
function widget:Update(dt)
	timer = timer + dt
	if timer >= 5 then
		if bool then
			WG.ShowPersistentMessageBox("Now you see me...", 300, 100, 12, "LuaUI/Images/advisor2.jpg")  
		else
			WG.ShowPersistentMessageBox("Now you don't!", 300, 100, 14, nil)  
		end
		timer = 0
		bool = not bool
	end
end
]]--

local str = "It would serve the greater good if\nyou would lay down arms, human.\nThis planet will be returned to\nthe Tau Empire as is proper."
function widget:Initialize()
	Chili = WG.Chili
	--WG.ShowPersistentMessageBox(str, 300, 100, 12, "LuaUI/Images/advisor2.jpg")
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------