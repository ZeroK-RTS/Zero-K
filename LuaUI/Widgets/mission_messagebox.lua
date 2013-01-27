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
    enabled   = true,  --  loaded by default?
    handler   = true,
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local Chili

local msgBoxPersistent
local imagePersistent
local scrollPersistent
local textPersistent
local stackPersistent
local msgBoxConvo

local convoQueue = {}
local persistentMsgHistory = {}	-- {text = text, width = width, height = height, fontsize = fontsize, image = imageDir}
local persistentMsgIndex = {}

local useChiliConvo = false

local font
local oldDrawScreenWH
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local TIME_TO_FLASH = 3	-- seconds
local CONVO_BOX_HEIGHT = 96
local CONVO_BOX_WIDTH_MIN = 400
local PERSISTENT_SUBBAR_HEIGHT = 24

local convoString 	-- for non-Chili convobox; stores the current string to display
local convoImg		-- for non-Chili convobox; stores the current image to display
local convoFontsize = 14
local flashTime
local convoExpireFrame


local vsx, vsy = gl.GetViewSizes()

local function ShowMessageBox(text, width, height, fontsize, pause)  
  local vsx, vsy = gl.GetViewSizes()
  
  -- reverse compatibility
  if height == 0 or height == nil or type(height) ~= "number" then height = 300 end
  if fontsize == 0 or fontsize == nil or type(fontsize) ~= "number" then fontsize = 14 end
  
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
            fontOutline = true,
          },
        },
      },
    }
  }
end

local function _ShowPersistentMessageBox(text, width, height, fontsize, imageDir)
	local vsx, vsy = gl.GetViewSizes()
	--local x = math.floor((vsx - width)/2)
	local y = math.floor((vsy - height)/2)
	
	if not width then
		width = 320
	end
	if not height then
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
		msgBoxPersistent.height = height + PERSISTENT_SUBBAR_HEIGHT
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
		textPersistent:Invalidate()	-- for some reason the text can fail to update without this
		
		scrollPersistent:SetScrollPos(nil, 0)
		countLabelPersistent:SetCaption(persistentMsgIndex .. "/" .. #persistentMsgHistory)
		msgBoxPersistent:Invalidate()
		return	-- done here, exit
	end
	
	-- no messagebox exists, make one
	msgBoxPersistent = Chili.Window:New{
		parent = Chili.Screen0,
		name   = 'msgWindow';
		width = width,
		height = height + PERSISTENT_SUBBAR_HEIGHT,
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
		scrollbarSize = 6,
	}
	
	textPersistent = Chili.TextBox:New{
		text    = text or '',
		align   = "left";
		width = (width - x - 12),
		padding = {5, 5, 5, 5},
		font    = {
			size   = fontsize or 12;
			shadow = true;
		},
	}	
	scrollPersistent:AddChild(textPersistent)
	
	stackPersistent = Chili.StackPanel:New{
		parent = msgBoxPersistent,
		padding = {0,0,0,0},
		--itemPadding = {0, 0, 0, 0},
		itemMargin = {0, 0, 0, 0},
		columns = 3,
		width= '100%',
		y = height - 4,
		height = 20,
		resizeItems = false,
		orientation = 'horizontal',
		centerItems = true,
	}

	buttonPrevPersistent = Chili.Button:New{
		parent = stackPersistent,
		width = 32,
		caption = "<",
		OnClick = {function(self, x, y, mouse)
				if mouse ~= 1 then return end
				-- TODO add shift modifier
				if persistentMsgIndex == 1 then
					return
				end
				persistentMsgIndex = persistentMsgIndex - 1
				local data = persistentMsgHistory[persistentMsgIndex]
				_ShowPersistentMessageBox(data.text, data.width, data.height, data.fontsize, data.image)
			end
		}
	}	
		
	countLabelPersistent = Chili.Label:New{
		parent = stackPersistent,
		caption = persistentMsgIndex .. "/" .. #persistentMsgHistory,
		y = height,
		align = center,
	}
	
	buttonNextPersistent = Chili.Button:New{
		parent = stackPersistent,
		width = 32,
		caption = ">",
		OnClick = {function(self, x, y, mouse)
				if mouse ~= 1 then return end
				-- TODO add shift modifier
				if persistentMsgIndex == #persistentMsgHistory then
					return
				end
				persistentMsgIndex = persistentMsgIndex + 1
				local data = persistentMsgHistory[persistentMsgIndex]
				_ShowPersistentMessageBox(data.text, data.width, data.height, data.fontsize, data.image)
			end
		}
	}
end

local function ShowPersistentMessageBox(text, width, height, fontsize, imageDir)
	persistentMsgIndex = #persistentMsgHistory + 1
	persistentMsgHistory[persistentMsgIndex] = {text = text, width = width, height = height, fontsize = fontsize, image = imageDir}
	flashTime = TIME_TO_FLASH
	Spring.PlaySoundFile("sounds/message_team.wav", 1, "ui")
	_ShowPersistentMessageBox(text, width, height, fontsize, imageDir)
end

local function HidePersistentMessageBox()
	if msgBoxPersistent then
		msgBoxPersistent:Dispose()
		msgBoxPersistent = nil
	end
end

local function ClearPersistentMessageHistory()
	HidePersistentMessageBox()
	persistentMsgHistory = {}
end

local function ShowConvoBoxNoChili(data)
  convoString = data.text
  convoSize = data.fontsize
  if data.image then
    convoImage = data.image  
  end
  if data.sound then
    Spring.PlaySoundFile(data.sound, 1, 'ui')
  end
  convoExpireFrame = Spring.GetGameFrame() + (data.time or 150)
end

local function ShowConvoBoxChili(data)
  local vsx, vsy = gl.GetViewSizes()
  local width, height = vsx*0.4, CONVO_BOX_HEIGHT
  
  local x = math.floor((vsx - width)/2)
  local y = vsy * 0.2	-- fits under chatbox

  msgBoxConvo = Chili.Window:New{  
    x = x,  
    y = y,
    width  = width,
    height = height,
    dockable = false,
    parent = Chili.Screen0,
    color = {0,0,0,0},
    padding = {0,0,0,0},
    draggable = false,
    resizable = false,
    children = {
      Chili.TextBox:New{
        text = data.text,
	height = height,
        width = width - (height + 8),
	x = height + 8,
	y = 0,
        align = "left",
        font = {
	  size = data.fontsize or 14,
	  outline = true,
	  shadow = true,
	},
        padding = {5, 5, 5, 5},
      },
    }
  }
  
  if data.image then
    Chili.Image:New {
      width = height,
      height = height,
      y = 0;
      x = 0;
      keepAspect = true,
      file = data.image;
      parent = msgBoxConvo;
    }      
  end
  
  if data.sound then
    Spring.PlaySoundFile(data.sound, 1, 'ui')
  end
  
  convoExpireFrame = Spring.GetGameFrame() + (data.time or 150)
end

local function ShowConvoBox(data)
  if useChiliConvo == true then
    ShowConvoBoxChili(data)
  else
    ShowConvoBoxNoChili(data)
  end
end

local function ClearConvoBox(noContinue)
  if msgBoxConvo then
    msgBoxConvo:Dispose()
    msgBoxConvo = nil
    
    table.remove(convoQueue, 1)
  elseif convoString then
    convoString = nil
    font = nil
    table.remove(convoQueue, 1)
  end
  
  if (not noContinue) and convoQueue[1] then
    ShowConvoBox(convoQueue[1])
  end
end

local function AddConvo(text, fontsize, image, sound, time)
  convoQueue[#convoQueue+1] = {text = text, fontsize = fontsize, image = image, sound = sound, time = time}
  if #convoQueue == 1 then ShowConvoBox(convoQueue[1]) end
end

local function ClearConvoQueue()
  ClearConvoBox(true)
  convoQueue = {}
end

function widget:GameFrame(n)
  if convoExpireFrame and convoExpireFrame <= n then
    ClearConvoBox(false)
  end
end

-- the following code handles box flashing
local UPDATE_FREQUENCY = 0.2
local timer = 0
local flashPhase = false

function widget:Update(dt)
	timer = timer + dt
	if timer < UPDATE_FREQUENCY then
		return
	end
	--[[
	if convoExpireTime then
	  convoExpireTime = convoExpireTime - timer
	  if convoExpireTime <= 0 then
	    if msgBoxConvo then
	      msgBoxConvo:Dispose()
	      msgBoxConvo = nil
	      
	      table.remove(convoQueue, 1)
	    elseif convoString then
	      convoString = nil
	      font = nil
	      table.remove(convoQueue, 1)
	    end
	    
	    if convoQueue[1] then
	      ShowConvoBox(convoQueue[1])
	    end
	  end
	end
	]]--
	flashPhase = not flashPhase
	if msgBoxPersistent and flashTime then
		if flashTime > 0 then
			msgBoxPersistent.color = (flashPhase and {0,0,0,1}) or {1,1,1,1}
			msgBoxPersistent:Invalidate()
			flashTime = flashTime - timer
		else	-- done flashing, reset
			msgBoxPersistent.color = {1,1,1,1}
			msgBoxPersistent:Invalidate()
			flasthTime = nil
		end
	end	
	timer = 0
end

function widget:DrawScreen()
  if convoString then
  
    local width, height = math.max(vsx*0.4, CONVO_BOX_WIDTH_MIN), CONVO_BOX_HEIGHT
  
    local x = math.floor((vsx - width)/2)
    local y = vsy * 0.8	-- fits under chatbox
    if WG.Cutscene and WG.Cutscene.IsInCutscene() then
      x = vsx*0.1
      width = vsx*0.8
      y = vsy-16
    end

    if font == nil then
      --font = FontHandler.LoadFont("FreeSansBold.otf",convoFontsize,3,3)
      font = gl.LoadFont("FreeSansBold.otf", convoFontSize,3,3)
      convoString = font:WrapText(convoString, width-(convoImage and height or 0), height, convoFontSize)
    end
    
    gl.Color(0,0,0,0.6)
    gl.Rect(x-2, y+2, x + width + 2, y - height - 2)
    gl.Color(1,1,1,1)
    
    if convoImage then
      gl.Texture(convoImage)
      gl.TexRect(x, y - height, x + height, y)
      gl.Texture(false)
    end
    
    local textHeight, _, numLines = gl.GetTextHeight(convoString)
    textHeight = textHeight*convoFontsize*numLines
    local textWidth = gl.GetTextWidth(convoString)*convoFontsize
    
    local xt = x + (convoImage and height or 0) + 4
    local yt = y - textHeight/numLines - 8
    font:Begin()
    --font:SetTextColor({1,1,1,1})
    --font:SetOutlineColor({0,0,0,1})
    font:SetAutoOutlineColor(true)
    font:Print(convoString, xt, yt,  convoFontSize, "o")
    font:End()
  end
end

function widget:Initialize()
  Chili = WG.Chili

  -- hook widgetHandler to allow us to override the DrawScreen callin
  --local wh = widgetHandler
  --
  --wh.oldDrawScreenWH = wh.DrawScreen
  --wh.DrawScreen = function()
  --  widget:DrawScreenForce()
  --  wh:oldDrawScreenWH()
  --end
  
  if Chili then
    WG.ShowMessageBox = ShowMessageBox
    WG.ShowPersistentMessageBox = ShowPersistentMessageBox
    WG.HidePersistentMessageBox = HidePersistentMessageBox
  end
  WG.AddConvo = AddConvo
  WG.ClearConvoQueue = ClearConvoQueue
  
  if WG.AddNoHideWidget then
    WG.AddNoHideWidget(self)
  end
  
  -- testing
  --[[
  local str = 'In some remote corner of the universe, poured out and glittering in innumerable solar systems, there once was a star on which clever animals invented knowledge. That was the highest and most mendacious minute of "world history"—yet only a minute. After nature had drawn a few breaths the star grew cold, and the clever animals had to die.'
  local str2 = 'Enemy nuclear silo spotted!'
  
  WG.ShowPersistentMessageBox(str, 320, 100, 12, "LuaUI/Images/advisor2.jpg")
  WG.ShowPersistentMessageBox(str2, 320, 100, 12, "LuaUI/Images/advisor2.jpg")
  --WG.AddConvo(str, nil, "LuaUI/Images/advisor2.jpg", "sounds/voice.wav", 22*30)
  --WG.AddConvo(str2, nil, "LuaUI/Images/startup_info_selector/chassis_strike.png", "sounds/reply/advisor/enemy_nuke_spotted.wav", 3*30)
  ]]
  
end

function widget:Shutdown()
  if WG.RemoveNoHideWidget then
    WG.RemoveNoHideWidget(self)
  end
  -- restore old widgetHandler DrawScreen
  --local wh = widgetHandler
  --wh.DrawScreen = wh.oldDrawScreenWH
  --wh.oldDrawScreenWH = nil
  
  WG.ShowMessageBox = nil
  WG.ShowPersistentMessageBox = nil
  WG.HidePersistentMessageBox = nil
  WG.AddConvo = nil
  WG.ClearConvoQueue = nil
end

function widget:ViewResize(viewSizeX, viewSizeY)
  vsx, vsy = viewSizeX, viewSizeY
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

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