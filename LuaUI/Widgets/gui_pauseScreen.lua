include("keysym.h.lua")
local versionNumber = "1.22"

function widget:GetInfo()
	return {
		name      = "Pause Screen",
		desc      = "[v" .. string.format("%s", versionNumber ) .. "] Displays pause screen when game is paused.",
		author    = "very_bad_soldier",
		date      = "2009.08.16",
		license   = "GNU GPL v2",
		layer     = 2000,	-- make sure it's higher than Chili
		enabled   = true
	}
end


local spGetGameSeconds      = Spring.GetGameSeconds
local spGetMouseState       = Spring.GetMouseState
local spEcho                = Spring.Echo

local spGetGameSpeed 		= Spring.GetGameSpeed

local max					= math.max

local glColor               = gl.Color
local glTexture             = gl.Texture
local glPopMatrix           = gl.PopMatrix
local glPushMatrix          = gl.PushMatrix
local glTranslate           = gl.Translate
local glText                = gl.Text
local glBeginEnd			= gl.BeginEnd
local glTexRect 			= gl.TexRect
local glLoadFont			= gl.LoadFont
local glDeleteFont			= gl.DeleteFont
local glRect				= gl.Rect
local glLineWidth           = gl.LineWidth
local glDepthTest           = gl.DepthTest

local osClock				= os.clock
----------------------------------------------------------------------------------
-- CONFIGURATION
local debug = false
local boxWidth = 300
local boxHeight = 60
local slideTime = 0.4
local fadeTime = 1
local autoFadeTime = 1
local wndBorderSize = 4
local imgWidth = 160 --drawing size of the image (independent from the real image pixel size)
local imgTexCoordX = 0.625  --image texture coordinate X -- textures image's dimension is a power of 2 (i use 0.625 cause my image has a width of 256, but region to use is only 160 pixel -> 160 / 256 = 0.625 )
local imgTexCoordY = 0.625	--image texture coordinate Y -- enter values other than 1.0 to use just a region of the texture image
local fontSizeHeadline = 36
local fontSizeAddon = 24
local windowIconPath = "LuaUI/Images/ZK_logo_pause.png"
local fontPath = "LuaUI/Fonts/MicrogrammaDBold.ttf"
local windowClosePath = "LuaUI/Images/quit.png"
local imgCloseWidth = 32
local minTransparency = 0 -- transparency after [X] is pressed
local minTransparency_autoFade = 0.1
--Color config in drawPause function
	
----------------
local screenx, screeny
local myFont
local clickTimestamp = 0
local pauseTimestamp = 0 --start or end of pause
local lastPause = false
local screenCenterX = nil
local screenCenterY = nil
local wndX1 = nil
local wndY1 = nil
local wndX2 = nil
local wndY2 = nil
local textX = nil
local textY = nil
local lineOffset = nil
local yCenter = nil
local xCut = nil
local mouseOverClose = false

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

options_path = 'Settings/HUD Panels/Pause Screen'

options = {
	hideimage = {
		name='Disable Pause Screen',
		type='bool',
		desc = 'Remember to not display pause-screen anymore. \n\nRemainder: you can revisit this configuration page at any time later at "Settings/HUD Panels/Pause Screen" if needed.',
		value=false,
		noHotkey = true,
	},
	disablesound = {
		name='Disable Voice',
		type='bool',
		desc = 'Remember to not play voice-over for pausing anymore.',
		value=false,
		noHotkey = true,
	},
	autofade = {
		name='Pause Screen automatically fade out',
		type='bool',
		desc = 'Automatically fade to background without needing to click it.',
		value=true,
		noHotkey = true,
	},
	nopicture = {
		name='Disable Logo',
		type='bool',
		desc = 'Only display pause text.',
		value=true,
		noHotkey = true,
	},
}

local SOUND_DIRNAME = 'sounds/reply/advisor/'

local pauseSound = "warzone_paused"
local unpauseSound = "warzone_active"
local tempDisabled = false
local doNotDisableSound = false
local disablePauseSlideTimestamp = 0

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function WG.PauseScreen_SetEnabled(newEnabled, newDoNotDisableSound)
	-- This intentially exists before widgets are fully loaded.
	tempDisabled = not newEnabled
	doNotDisableSound = newDoNotDisableSound
	disablePauseSlideTimestamp = osClock()
end

local function playSound(filename, ...)
	local path = SOUND_DIRNAME..filename..".WAV"
	if (VFS.FileExists(path)) then
		Spring.PlaySoundFile(path, ...)
	else
	--Spring.Echo(filename)
		Spring.Echo("<snd_noises.lua>: Error file "..path.." doesn't exist.")
	end
end


function widget:Initialize()
	myFont = glLoadFont( fontPath, fontSizeHeadline, nil, nil ) -- FIXME: nils are for #2564, remove later
	updateWindowCoords()
end

function widget:Shutdown()
	glDeleteFont( myFont )
end

function widget:DrawScreen()
	local now = osClock()
	local _, _, paused = spGetGameSpeed()
	local diffPauseTime = ( now - pauseTimestamp)
	
	if ( ( not paused and lastPause ) or ( paused and not lastPause ) ) then
		--pause switch
		pauseTimestamp = osClock()
		if ( diffPauseTime <= slideTime ) then
			pauseTimestamp = pauseTimestamp - ( slideTime - diffPauseTime )
		end
	end
	
	if ( paused and not lastPause ) then
		--new pause
		if not (options.disablesound.value or (tempDisabled and not doNotDisableSound)) then
			playSound(pauseSound, 1, 'ui')
		end
		clickTimestamp = nil
	elseif ( not paused and lastPause ) then
		if not (options.disablesound.value or (tempDisabled and not doNotDisableSound)) then
			playSound(unpauseSound, 1, 'ui')
		end
	end

	lastPause = paused
		
	if ( (paused or ( ( now - pauseTimestamp) <= slideTime )) and not (options.hideimage.value or tempDisabled)) then
		if now - disablePauseSlideTimestamp > slideTime then
			drawPause(paused, now)
		end
	end
	
	ResetGl()
end

function isOverWindow(x, y)
	if ( ( x > screenCenterX - boxWidth) and ( y < screenCenterY + boxHeight ) and
		( x < screenCenterX + boxWidth ) and ( y > screenCenterY - boxHeight ) ) then
		return true
	end
	return false
 end

function widget:MousePress(x, y, button)
  if ( not clickTimestamp and (not (options.hideimage.value or tempDisabled) and not options.autofade.value)) then
	if ( isOverWindow(x, y)) then
		--do not update clickTimestamp any more after right mouse button click
		if ( not (options.hideimage.value or tempDisabled) ) then
			clickTimestamp = osClock()
		end
		
		--display setting for Pause Screen when pressing Spacebat+Click on the Pause Screen.
		local alt, ctrl, meta, shift = Spring.GetModKeyState()
		if not meta then  --//skip epicMenu when user didn't press the Spacebar
			return false
		end
		WG.crude.OpenPath(options_path) --click + space will shortcut to option-menu
		WG.crude.ShowMenu() --make epic Chili menu appear.
		--[[
		--hide window for the rest of forever if it was a right mouse button
		if ( button == 3 ) then
			options.hideimage.value = true
		end
		--]]
		
		return true
	end
  end
  
  return false
end

function widget:IsAbove(x,y)
	local _, _, paused = spGetGameSpeed()
	if ( paused and not options.autofade.value and not (options.hideimage.value or tempDisabled) and not clickTimestamp and isOverWindow( x, y ) ) then
		return true
	end
	return false
end

function widget:Update()
	local x,y = spGetMouseState()
	if ( isOverWindow(x, y) ) then
		mouseOverClose = true
	else
		mouseOverClose = false
	end
end

function widget:GetTooltip(x, y)
	if ( ( clickTimestamp == nil and (options.hideimage.value == false or options.autofade.value==false or (not tempDisabled))) and isOverWindow(x, y) ) then
		return "Click here to hide pause window.\nSpace+Click here to show option menu."
	end
end

function drawPause(paused, now)
	--[[
	local _, _, paused = spGetGameSpeed()
	local now = osClock()
	--]]
	local diffPauseTime = ( now - pauseTimestamp)

	local text =  { 1.0, 1.0, 1.0, 1.0 }
	local text2 =  { 0.9, 0.9, 0.9, 1.0 }
	local outline =  { 0.4, 0.4, 0.4, 1.0 }
	local colorWnd = { 0.0, 0.0, 0.0, 0.6 }
	local colorWnd2 = { 0.5, 0.5, 0.5, 0.6 }
	local iconColor = { 1.0, 1.0, 1.0, 1.0 }
	local iconColor2 = { 1.0, 1.0, 1.0, 1.0 }
	local mouseOverColor = { 1.0, 1.0, 0.0, 1.0 }
	
	if options.autofade.value then
		local factor0 = ( 1.0 -  ( diffPauseTime ) / autoFadeTime)
		local factor1 = max(factor0,minTransparency_autoFade)
		colorWnd[4] = colorWnd[4]*factor1
		text[4] = text[4]*factor1
		text2[4] = text2[4]*factor1
		outline[4] = outline[4]*factor1
		iconColor[4] = iconColor[4]*factor1
		iconColor2[4] = iconColor2[4]*0
		mouseOverColor[4] = mouseOverColor[4]*factor1
	end

	--adjust transparency when clicked
	if ( clickTimestamp ~= nil or (options.hideimage.value or tempDisabled)) then
		local factor = 0.0
		if ( clickTimestamp ) then
			factor = ( 1.0 - ( now - clickTimestamp ) / fadeTime )
		end
		factor = max( factor, minTransparency )
    
		if factor == 0 then
			return
		end
    
		colorWnd[4] = colorWnd[4] * factor
		text[4] = text[4] * factor
		text2[4] = text2[4] * factor
		outline[4] = outline[4] * factor
		iconColor[4] = iconColor[4] * factor
		iconColor2[4] = iconColor2[4]* factor
		mouseOverColor[4] = mouseOverColor[4] * factor
	end
	local imgWidthHalf = imgWidth * 0.5
	
	if options.nopicture.value then
		colorWnd[4] = colorWnd[4] * 0
		iconColor[4] = iconColor[4] * 0
		iconColor2[4] = iconColor2[4]* 0
		mouseOverColor[4] = mouseOverColor[4] * 0
	end
	
	
	--draw window
	glPushMatrix()
	
	if ( diffPauseTime <= slideTime ) then
		local group1XOffset = 0
		--we are sliding
		if ( paused ) then
			--sliding in
			group1XOffset = ( screenx - wndX1 ) * ( 1.0 - ( diffPauseTime / slideTime ) )
		else
			--sliding out
			group1XOffset = ( screenx - wndX1 ) * ( ( diffPauseTime / slideTime ) )
		end
		glTranslate( group1XOffset, 0, 0)
	end
	
	glColor( colorWnd )
	glRect( wndX1, wndY1, wndX2, wndY2 )
	glColor( colorWnd )
	glRect( wndX1 - wndBorderSize, wndY1 + wndBorderSize, wndX2 + wndBorderSize, wndY2 - wndBorderSize)
	
	--draw close icon
	glColor(  iconColor2 )
	if ( mouseOverClose and clickTimestamp == nil and (options.hideimage.value == false and options.autofade.value==false and (not tempDisabled))) then
		glColor( mouseOverColor )
	end
	
	glTexture( ":n:" .. windowClosePath )
	glTexRect( wndX2 - imgCloseWidth - wndBorderSize, wndY1 - imgCloseWidth - wndBorderSize, wndX2 - wndBorderSize, wndY1 - wndBorderSize, 0.0, 0.0, 1.0, 1.0 )
	
	--draw text
	local textBegining = options.nopicture.value and (wndX1 + ( wndX2 - wndX1 ) * 0.2) or textX
	
	myFont:Begin()
	myFont:SetOutlineColor( outline )

	myFont:SetTextColor( text )
	myFont:Print( "GAME PAUSED", textBegining, textY, fontSizeHeadline, "O" )
		
	myFont:SetTextColor( text2 )
	myFont:Print( "Press 'Pause' to continue.", textBegining, textY - lineOffset, fontSizeAddon, "O" )
	
	myFont:End()
	
	glPopMatrix()
	
	--draw logo
	glColor(  iconColor )
	glTexture( ":n:" .. windowIconPath )
	glPushMatrix()
	
	if ( diffPauseTime <= slideTime ) then
		--we are sliding
		if ( paused ) then
			--sliding in
			glTranslate( 0, ( ( yCenter + imgWidthHalf ) * ( 1.0 - ( diffPauseTime / slideTime ) ) ), 0)
		else
			--sliding out
			glTranslate( 0, ( yCenter + imgWidthHalf ) * ( diffPauseTime / slideTime ), 0)
		end
	end
	
	glTexRect( xCut - imgWidthHalf, yCenter + imgWidthHalf, xCut + imgWidthHalf, yCenter - imgWidthHalf, 0.0, 0.0, imgTexCoordX, imgTexCoordY )
	glPopMatrix()
	
	glTexture(false)
end

function updateWindowCoords()
	screenx, screeny = widgetHandler:GetViewSizes()
	
	screenCenterX = screenx / 2
	screenCenterY = screeny / 2
	wndX1 = screenCenterX - boxWidth
	wndY1 = screenCenterY + boxHeight
	wndX2 = screenCenterX + boxWidth
	wndY2 = screenCenterY - boxHeight

	textX = wndX1 + ( wndX2 - wndX1 ) * 0.36
	textY = wndY2 + ( wndY1 - wndY2 ) * 0.53
	lineOffset = ( wndY1 - wndY2 ) * 0.3
	
	yCenter = wndY2 + ( wndY1 - wndY2 ) * 0.5
	xCut = wndX1 + ( wndX2 - wndX1 ) * 0.19
end

function widget:ViewResize(viewSizeX, viewSizeY)
  updateWindowCoords()
 end

--Commons
function ResetGl()
	glColor( { 1.0, 1.0, 1.0, 1.0 } )
	glLineWidth( 1.0 )
	glDepthTest(false)
	glTexture(false)
end


function printDebug( value )
	if ( debug ) then
		if ( type( value ) == "boolean" ) then
			if ( value == true ) then spEcho( "true" )
				else spEcho("false") end
		elseif ( type(value ) == "table" ) then
			spEcho("Dumping table:")
			for key,val in pairs(value) do
				spEcho(key,val)
			end
		else
			spEcho( value )
		end
	end
end
	
