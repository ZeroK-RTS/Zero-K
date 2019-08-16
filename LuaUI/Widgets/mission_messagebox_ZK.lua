--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "MessageBoxes ZK",
    desc      = "Displays messages from missions.",
    author    = "quantum",
    date      = "Nov 2010",
    license   = "GNU GPL, v2 or later",
    layer     = 2,
    enabled   = true,  --  loaded by default?
  }
end

if not VFS.FileExists("mission.lua") then
	return
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

local nextButton

local convoQueue = {}
local persistentMsgHistory = {}	-- {text = text, width = width, height = height, fontsize = fontsize, image = imagePath}
local persistentMsgIndex = {}

local useChiliConvo = false

local font
local oldDrawScreenWH
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local TIME_TO_FLASH = 1.5	-- seconds
local CONVO_BOX_HEIGHT = 96
local CONVO_BOX_WIDTH_MIN = 400
local PERSISTENT_SUBBAR_HEIGHT = 24
local PERSISTENT_IMAGE_HEIGHT = 96

local TEST_MODE = false

local convoString 	-- for non-Chili convobox; stores the current string to display
local convoImg		-- for non-Chili convobox; stores the current image to display
local convoFontsize = 14
local flashTime
local convoExpireFrame

local nextButtonLocked = false

local vsx, vsy = gl.GetViewSizes()
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local COLOR_CODED_PATTERN = "\\%d+\\%d+\\%d+\\%d+\\.-\\008"

local function SplitString(str, sep)
  local sep, fields = sep or ":", {}
  local pattern = string.format("([^%s]+)", sep)
  string.gsub(str, pattern, function(c) fields[#fields+1] = c end)
  return fields
end

local function ProcessColorCodes(text)
  if text == nil then
    return
  end
  
  local coloredStrs = string.gmatch(text, COLOR_CODED_PATTERN)
  for str in coloredStrs do
    local fields = SplitString(str, "\\")
    -- fields 1-4 are our color codes, the last field is the \008
    --Spring.Echo(#fields)
    --for i, v in ipairs(fields) do
    --  Spring.Echo(i, v)
    --end
    if (#fields >= 6) then
      local a, r, g, b = tonumber(fields[1]), tonumber(fields[2]), tonumber(fields[3]), tonumber(fields[4])
      local newStr = string.char(a,r,g,b)
      for j=5,#fields-1 do
        newStr = newStr .. fields[j]
        if j ~= #fields-1 then
          newStr = newStr .. "\\"
        end
      end
      newStr = newStr .. "\255\255\255\255"
      text = string.gsub(text, str, newStr)
    end
  end

  return text
end

local function GetHaveNextButton()
	return Spring.GetGameRulesParam("tutorial_has_next_button") == 1
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function ShowMessageBox(text, width, height, fontsize, pause)
  text = ProcessColorCodes(text)
  
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
        OnClick = { function(self)
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

local function CreateNextButton(parent)
	nextButton = Chili.Button:New {
		parent = parent,
		width = 64,
		height = 24,
		right = 4,
		bottom = 8,
		caption = "Next",
		font = {size = 14},
		OnClick = { function(self, x, y, mouse)
				if mouse == 1 and not nextButtonLocked then
					Spring.SendLuaRulesMsg("tutorial_next")
					nextButtonLocked = true -- only allow one click per gameframe, so it doesn't super increment when paused
				end
			end
		},
	}
	stackPersistent.right = 72
	stackPersistent:Invalidate()
end

local function _ShowPersistentMessageBox(text, width, height, fontsize, imagePath)
	local vsx, vsy = gl.GetViewSizes()
	--local x = math.floor((vsx - width)/2)
	local y = math.floor((vsy - height)/2)
	
	width = width or 360
	height = height or 160
	
	-- we have an existing box, dispose of it
	--if msgBoxPersistent then
	--	msgBoxPersistent:ClearChildren()
	--	msgBoxPersistent:Dispose()
	--end
	
	-- we have an existing box, modify that one instead of making a new one
	if msgBoxPersistent then
		local widthChange = width - msgBoxPersistent.width
		msgBoxPersistent.width = width
		msgBoxPersistent.height = height + PERSISTENT_SUBBAR_HEIGHT
		local onRightSide = msgBoxPersistent.x + (width/2) > (vsx/2)
		if onRightSide then
			msgBoxPersistent.x = msgBoxPersistent.x - widthChange
		end
		
		local x = ((imagePath and imagePersistent.width + imagePersistent.x) or 0) + 5
		if imagePath then
			imagePersistent.width = PERSISTENT_IMAGE_HEIGHT
			imagePersistent.height = PERSISTENT_IMAGE_HEIGHT
			imagePersistent.file = imagePath
			imagePersistent.color = {1, 1, 1, 1}
			
			scrollPersistent.width = (width - x - 12)
		else
			imagePersistent.color = {1, 1, 1, 0}
			scrollPersistent.width = (width - 6 - 8)
		end
		imagePersistent:Invalidate()
		
		scrollPersistent.height	= height - 8 - 8
		--scrollPersistent:Invalidate()
		
		stackPersistent.y = height - 6
		--stackPersistent.Invalidate()
		
		-- recreate textbox to make sure it never fails to update text
		textPersistent:Dispose()
		
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
		
		if (not nextButton) and GetHaveNextButton() then
			CreateNextButton(msgBoxPersistent)
		end
		
		scrollPersistent:SetScrollPos(nil, 0)
		countLabelPersistent:SetCaption(persistentMsgIndex .. " / " .. #persistentMsgHistory)
		msgBoxPersistent:Invalidate()
		return	-- done here, exit
	end
	
	-- no messagebox exists, make one
	msgBoxPersistent = Chili.Window:New{
		parent = Chili.Screen0,
		name   = 'msgPersistentWindow';
		width = width,
		height = height + PERSISTENT_SUBBAR_HEIGHT,
		y = y,
		right = 0;
		dockable = true;
		draggable = false,
		resizable = false,
		tweakDraggable = true,
		tweakResizable = false,
		padding = {6, 0, 6, 0},
		--minimizable = true,
		--itemMargin  = {0, 0, 0, 0},
	}
	msgBoxPersistent.origColor = msgBoxPersistent.color

	imagePersistent = Chili.Image:New {
		width = PERSISTENT_IMAGE_HEIGHT,
		height = PERSISTENT_IMAGE_HEIGHT,
		y = 10;
		x = 5;
		keepAspect = true,
		file = imagePath;
		parent = msgBoxPersistent;
	}
	
	local x = ((imagePath and imagePersistent.width + imagePersistent.x) or 0) + 5
	scrollPersistent = Chili.ScrollPanel:New{
		parent  = msgBoxPersistent;
		right	= 4,
		y		= 8,
		height	= height - 8 - 8,
		width   = width - x - 12,
		horizontalScrollbar = false,
		scrollbarSize = 6,
	}
	
	textPersistent = Chili.TextBox:New{
		text    = text or '',
		align   = "left";
		x       = 0,
		right   = 0,
		padding = {5, 5, 5, 5},
		font    = {
			size   = fontsize or 12;
			shadow = true;
		},
		parent = scrollPersistent,
	}
	
	stackPersistent = Chili.StackPanel:New{
		parent = msgBoxPersistent,
		padding = {0,0,0,0},
		--itemPadding = {0, 0, 0, 0},
		itemMargin = {0, 0, 0, 0},
		columns = 3,
		x = 0,
		right = GetHaveNextButton() and 72 or 0,
		y = height - 6,
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
		caption = persistentMsgIndex .. " / " .. #persistentMsgHistory,
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
	
	if GetHaveNextButton() then
		CreateNextButton(msgBoxPersistent)
	end
end

local function ShowPersistentMessageBox(text, width, height, fontsize, imagePath)
	text = ProcessColorCodes(text)
	persistentMsgIndex = #persistentMsgHistory + 1
	persistentMsgHistory[persistentMsgIndex] = {text = text, width = width, height = height, fontsize = fontsize, image = imagePath}
	flashTime = TIME_TO_FLASH
	Spring.PlaySoundFile("sounds/message_team.wav", 1, "ui")
	_ShowPersistentMessageBox(text, width, height, fontsize, imagePath)
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
  convoString = ProcessColorCodes(data.text)
  convoSize = data.fontsize
  if data.image then
    convoImage = data.image
  end
  if data.sound then
    Spring.PlaySoundFile(data.sound, 1, 'ui')
  else
    Spring.PlaySoundFile("sounds/message_team.wav", 1, "ui")
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
  else
    Spring.PlaySoundFile("sounds/message_team.wav", 1, "ui")
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
  text = ProcessColorCodes(text)
  convoQueue[#convoQueue+1] = {text = text, fontsize = fontsize, image = image, sound = sound, time = time}
  if #convoQueue == 1 then ShowConvoBox(convoQueue[1]) end
end

local function ClearConvoQueue()
  ClearConvoBox(true)
  convoQueue = {}
end

function ReceivePersistentMessages(newMessages)
  if #newMessages == #persistentMsgHistory then
    return
  end
  
  ClearPersistentMessageHistory()
  for index, msg in pairs(newMessages) do
    local image = msg.image and ((msg.imageFromArchive and "" or "LuaUI/Images/") .. msg.image) or nil
    ShowPersistentMessageBox(msg.message, msg.width, msg.height, msg.fontSize, image)
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function widget:GameFrame(n)
	if convoExpireFrame and convoExpireFrame <= n then
		ClearConvoBox(false)
	end
	nextButtonLocked = false
end

-- the following code handles box flashing
local UPDATE_FREQUENCY = 0.2
local timer = 0
local flashPhase = false


function widget:Update(dt)
	if nextButton then
		if Spring.GetGameRulesParam("tutorial_show_next_button") == 1 then
			if not nextButton.visible then
				nextButton:Show()
			end
		else
			if nextButton.visible then
				nextButton:Hide()
			end
		end
	end
	
	timer = timer + dt
	if timer < UPDATE_FREQUENCY then
		return
	end
	
	flashPhase = not flashPhase
	if msgBoxPersistent and flashTime then
		if flashTime > 0 then
			msgBoxPersistent.color = (flashPhase and {0,0,0,1}) or msgBoxPersistent.origColor
			msgBoxPersistent:Invalidate()
			flashTime = flashTime - timer
		else	-- done flashing, reset
			msgBoxPersistent.color = msgBoxPersistent.origColor
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
  
  widgetHandler:RegisterGlobal("MissionPersistentMessagesFromSynced", ReceivePersistentMessages)
  Spring.SendLuaRulesMsg("sendMissionPersistentMessages")
  
  -- testing
  if TEST_MODE then
    local str = '\255\255\255\0In some remote\255\255\255\255 corner of the universe, poured out and glittering in innumerable solar systems, there once was a star on which clever animals invented knowledge. That was the highest and most mendacious minute of "world history" – yet only a minute. After nature had drawn a few breaths the star grew cold, and the clever animals had to die.'
    local str2 = 'Enemy nuclear silo spotted!'
    
    local str3 = '\255\255\255\0Colored\008 text'
    local str4 = '\255\255\255\0Colored text\008 2'
    
    WG.ShowPersistentMessageBox(str, 320, 100, 12, "LuaUI/Images/advisor2.jpg")
    --WG.ShowPersistentMessageBox(str4, 320, 100, 12, "LuaUI/Images/advisor2.jpg")
    --WG.AddConvo(str3, nil, "LuaUI/Images/advisor2.jpg", "sounds/voice.wav", 10*30)
    --WG.AddConvo(str4, nil, "LuaUI/Images/startup_info_selector/chassis_strike.png", "sounds/reply/advisor/enemy_nuke_spotted.wav", 3*30)
  end
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
  widgetHandler:DeregisterGlobal("MissionPersistentMessagesFromSynced")
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
			WG.ShowPersistentMessageBox("Now you see me...", 320, 100, 12, "LuaUI/Images/advisor2.jpg")
		else
			WG.ShowPersistentMessageBox("Now you don't!", 320, 100, 14, nil)
		end
		timer = 0
		bool = not bool
	end
end
]]--
