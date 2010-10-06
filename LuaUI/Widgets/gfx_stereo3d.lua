--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Stereo3D",
    desc      = "v0.12 Stereo 3D rendering.",
    author    = "CarRepairer, with assistance of jK",
    date      = "2009",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- todo:
--	* add chroma depth:
--		* http://www.chromatek.com/Image_Design/Color_Lookup_Functions/color_lookup_functions.shtml
--		* http://eclecti.cc/computergraphics/cheap-3d-in-opengl-with-a-chromadepth-glsl-shader

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local spSendCommands			= Spring.SendCommands
local spSetCameraOffset			= Spring.SetCameraOffset
local spSetCameraState			= Spring.SetCameraState
local spGetCameraState			= Spring.GetCameraState
local spGetCameraPosition		= Spring.GetCameraPosition
local spGetCameraDirection		= Spring.GetCameraDirection
local spTraceScreenRay			= Spring.TraceScreenRay
local spGetMouseState			= Spring.GetMouseState
local abs						= math.abs

local glClear				= gl.Clear
local glColorMask			= gl.ColorMask
local glBlending			= gl.Blending
local glLoadIdentity		= glLoadIdentity
local glResetState			= gl.ResetState
local glMatrixMode			= gl.MatrixMode
local glPushMatrix			= gl.PushMatrix
local glPopMatrix			= gl.PopMatrix
local glLoadIdentity		= gl.LoadIdentity
local glRect				= gl.Rect
local glCopyToTexture		= gl.CopyToTexture
local glActiveTexture		= gl.ActiveTexture
local glTexture				= gl.Texture
local glTexRect				= gl.TexRect
local glUseShader			= gl.UseShader
local glBeginEnd			= gl.BeginEnd
local glLineWidth			= gl.LineWidth
local glColor				= gl.Color
local glVertex				= gl.Vertex
local glDrawGroundCircle	= gl.DrawGroundCircle

local GL_ONE				= GL.ONE
local GL_OR					= GL.OR
local GL_DEPTH_BUFFER_BIT	= GL.DEPTH_BUFFER_BIT
local GL_COLOR_BUFFER_BIT	= GL.COLOR_BUFFER_BIT
local GL_ACCUM_BUFFER_BIT	= GL.ACCUM_BUFFER_BIT
local GL_PROJECTION			= GL.PROJECTION
local GL_MODELVIEW			= GL.MODELVIEW
local GL_LINES				= GL.LINES

local echo = Spring.Echo


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local sep = 5
local conv = 0.003
local mode = 'anaglyph'
local hideCursorKeyCombo = false

local vsx = 1						-- current viewport width
local vsy = 1						-- current viewport height

local mpos

local lefttext
local righttext

local left = true

local nx, ny, nz=0,0,0
local lx, ly, lz=0,0,0


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local canShader = (gl.CreateShader ~= nil)
local stereoShader
local stereoShaderPara
local stereoShaderInt
local selected_stereoShader
local init = false

local colorMatrixLeftLoc
local colorMatrixRightLoc

local ColorMatrices = {
	anaglyph = {
		left = {
			1,	0,	0,
			0,	0,	0,
			0,	0,	0,
		},
		right = {
			0,	0,	0,
			0,	1,	0,
			0,	0,	1,
		}
	},

	anaglyphdubois = {
		left = {
			0.456,	-0.04,	-0.015,
			0.5,	-0.038,	-0.021,
			0.176,	-0.016, -0.005,
		},
		right = {
			-0.043, 0.378,	-0.072,	
			-0.088, 0.734,	-0.113,	
			-0.002,-0.018,	1.226
		}
	},		
	
	anaglyphhalfcol = {
		left = {
			0.299,	0,	0,
			0.587,	0,	0,
			0.114,	0,	0,
		},
		right = {
			0,	0,	0,
			0,	1,	0,
			0,	0,	1,
		}
	},

	anaglyphbw = {
		left = {
			0.33,	0,	0,
			0.33,	0,	0,
			0.33,	0,	0,
		},
		right = {
			0,	0.33,	0.33,
			0,	0.33,	0.33,
			0,	0.33,	0.33,
		}
	},

	anaglyphblueyellow = {
		--[[
		left = {
			1,	0,	0,
			0,	0.8,	0,
			0,	0,	0,
		},
		right = {
			0,	0,	0,
			0,	0,	0.2,
			0,	0,	1,
		}
		--]]
		left = {
			1,	0,	0,
			0,	1,	0,
			0,	0,	0,
		},
		right = {
			0,	0,	0,
			0,	0,	0,
			0,	0,	1,
		}
	},

	anaglyphbluered = {
		left = {
			1,	0,	0,
			0,	0,	0,
			0,	0,	0,
		},
		right = {
			0,	0,	0,
			0,	0,	0,
			0,	0,	1,
		}
	},
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local possibleRenderer = {
	{
		key  = 'anaglyph',
		name = 'Anaglyph',
		--desc = 'Normal game mode',
		desc = 'Basic red/cyan anaglyph.'
	},
	{
		key  = 'anaglyph2',
		name = 'Anaglyph (No Shaders)',
		desc = 'Use this mode if your video card is just not very good.'
	},
	{
		key  = 'anaglyphbw',
		name = 'Anaglyph - B&W',
		desc = 'Red/cyan anaglyph with no color information - easy on the eyes.'
	},
	{
		key  = 'anaglyphhalfcol',
		name = 'Anaglyph - Half Color',
		desc = 'Red/cyan anaglyph with less color information - easy on the eyes.'
	},
	{
		key  = 'anaglyphdubois',
		name = 'Anaglyph - Dubois',
		desc = 'Red/cyan anaglyph with less color information - easy on the eyes.'
	},
	{
		key  = 'anaglyphbluered',
		name = 'Anaglyph - Blue/Red',
		desc = 'Red/blue anaglyph.'
	},
	{
		key  = 'anaglyphblueyellow',
		name = 'Anaglyph - Blue/Yellow',
		desc = 'Blue/yellow anaglyph.'
	},
	{
		key  = 'interlaced',
		name = 'Interlaced',
		desc = 'Left and right images are interlaced.'
	},
	{
		key  = 'parallel',
		name = 'Parallel (unfinished)',
		desc = 'Left and right images are side by side.'
	},
}

if (not canShader) then
	possibleRenderer = {
		{
			key  = 'anaglyph2',
			name = 'Anaglyph (No Shaders)',
			desc = 'Your video card is not very good and this is the only mode you can do.'
		},
	}
end

local function UpdateConvSep()
	local swap = options.swapeyes.value == true and -1 or 1
	
	sep = options.sep.value * swap
	conv = options.conv.value * swap
end

options_path = 'Settings/Effects/Stereo3D'
options_order = { 'toggle3d', 'helpwindow', 'lblblank1', 'lblsettings', 'swapeyes', 'lasersight', 'hidecursor', 'sep', 'conv', 'lblblank2', 's3dmode', 'lblblank3',  }
options = {
	
	toggle3d = {
		name = 'Toggle Stereo 3D',
		type = 'bool',
		value = false,
		desc = 'Turn Stereo3D vision on or off.'
	},
	
	helpwindow = {
		name = 'Stereo3D Help',
		type = 'text',
		value = [[
			- Press alt+ctrl+shift to toggle the mouse cursor (doesn't work if gui is hidden).
			- Use "Anaglyph (No Shader)" mode if you are having trouble with your video.
			- Convergence setting only applies when there's a rotatable camera.
			
			Issues: 
				- Facing straight down will not show a 3D effect.
				- Some widgets such as IceUI will interfere with "Anaglyph (No Shader)" mode. Turn them off or try other modes.
		]],
	},
	
	lblsettings = {name='Settings', type='label'},
	
	swapeyes = {
		name = 'Swap Eyes',
		type = 'bool',
		value = false,
		OnChange = UpdateConvSep,
	},
	lasersight = {
		name = 'Laser Sight',
		type = 'bool',
		value = true,
		desc = 'Enable Laser sight for cursor.'
	},
	
	hidecursor = {
		name = 'Hide Cursor',
		type = 'bool',
		value = false,
	},
	
	sep = {
		name = 'Separation',
		type = 'number',
		value = sep,
		min=0,max=30,step=0.1, 
		desc = 'How far apart your eyes are.',
		OnChange = UpdateConvSep,
	},
	
	conv = {
		name = 'Convergence',
		type = 'number',
		value = conv,
		min=0,max=0.05,step=0.001, 
		desc = 'How crosseyed you are.',
		OnChange = UpdateConvSep,
	},
	
	
	s3dmode = {
		name   = '3D Modes',
		type   = 'list',
		items  = possibleRenderer,
		OnChange = function()
			mode = options.s3dmode.value
			widget:UpdateCallIns()
		end,
		value  = 'anaglyph',
	},
	
	--[[
	viewta 		= { name = 'TA Cam', type = 'button', OnChange = function() spSendCommands{'viewta'} end, hotkey = {key=109, mod='ac'}  },
	viewfree 	= { name = 'Free Cam', type = 'button', OnChange = function() spSendCommands{'viewfree'} end,  },
	viewrot 	= { name = 'Rotatable Overhead', type = 'button', OnChange = function() spSendCommands{'viewrot'} end },
	--]]
	
	--[[
	camera = {
		name = 'Camera Type',
		type = 'list',
		items = {
			{name = 'Total Annihilation', 	key = 'viewta'},
			{name = 'Free', 				key = 'viewfree'},
			{name = 'Rotatable Overhead', 	key = 'viewrot'},
			{name = 'Total War', 			key = 'viewtw'},
		},
		value = 'viewta',
		OnChange = function()
			spSendCommands{options.camera.value}
		end
	},
	--]]
	lblblank1 = {name='', type='label'},
	lblblank2 = {name='', type='label'},
	lblblank3 = {name='', type='label'},
	
}

--options.toggle3d.value = true
--options.s3dmode.value = 'anaglyph'
--mode = options.s3dmode.value


function options.toggle3d:OnChange()
	widget:UpdateCallIns()
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:SetConfigData(data)
end
function widget:GetConfigData()
end

local function cross(x1,y1,z1,x2,y2,z2)
	return y1*z2 - z1*y2, z1*x2 - x1*z2, x1*y2 - y1*x2
end

local function drawCursor(x1,y1,z1,x2,y2,z2)
	glVertex( x1,y1,z1 )
	glVertex( x2,y2,z2 )
end

function widget:DrawScreen3D()
	if options.lasersight.value and options.hidecursor.value and mpos then
		Spring.SetMouseCursor("none")
	end
end
function widget:DrawWorld3D()
	if options.lasersight.value then
		if mpos then
			local px, py, pz = mpos[1], mpos[2], mpos[3]
			glLineWidth(2)
			glColor(1, 1, 1, 0.3)
			glBeginEnd(GL_LINES, drawCursor, lx,ly,lz, px, py, pz)
			glDrawGroundCircle(px, py, pz, 20, 32)
			glLineWidth(1)
			glColor(1,1,1,1)
		end
	end
end

local function CopyEyeToTex()
	if left then
		local cs = spGetCameraState()
		nx,ny,nz = cross(cs.dx, cs.dy, cs.dz, 0,1,0)
		cs.px = cs.px + nx*sep
		cs.py = cs.py + ny*sep
		cs.pz = cs.pz + nz*sep
		cs.ry = cs.ry and cs.ry + conv or conv
		spSetCameraState(cs,0)
		
		gl.CopyToTexture(lefttext, 0, 0, 0, 0, vsx, vsy)
		
		local mx, my = spGetMouseState()
		_, mpos = spTraceScreenRay(mx, my, true)
		
		if cs.name == 'ta' then
			local cx,cy,cz = spGetCameraPosition()
			lx = cx +20
			ly = cy -20
			lz = cz -20
		else
			lx = cs.px - cs.dx*sep
			ly = cs.py - cs.dy*sep - 20
			lz = cs.pz - cs.dz*sep
		end
		
	else --if right
		local cs = spGetCameraState()
		cs.px = cs.px - nx*sep
		cs.py = cs.py - ny*sep
		cs.pz = cs.pz - nz*sep
		cs.ry = cs.ry and cs.ry - conv or - conv
		spSetCameraState(cs,0)
	
		gl.CopyToTexture(righttext, 0, 0, 0, 0, vsx, vsy)
	end

	left = not left
end

function widget:DrawScreenEffectsAnaglyphNoShader()
	CopyEyeToTex()
	glTexture(false)
	gl.Blending(false)
	glColor(1, 1, 1, 1)

 	if (not left) then
		gl.ColorMask(false,true,true,true)
		glTexture(righttext)
		glTexRect(0,vsy,vsx,0)
	else
		gl.ColorMask(true,false,false,true)
		glTexture(lefttext)
		glTexRect(0,vsy,vsx,0)
	end

	glTexture(false)
	glColor(1, 1, 1, 1)
	gl.ColorMask(true,true,true,true)
	gl.Blending(true)
end

function widget:DrawScreenEffectsShader()
	CopyEyeToTex()
	glTexture(false)
	gl.Blending(false)

	glUseShader(selected_stereoShader)
		glTexture(0,lefttext);  glTexture(0,false)
		glTexture(1,righttext); glTexture(1,false)
		glTexRect(0,vsy,vsx,0)
	glUseShader(0)

	gl.Blending(true)
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function ToggleStereo3D(_,_,words)
	options.toggle3d.value = not options.toggle3d.value
	widget:UpdateCallIns()
end

function Mode(_,_,words)
	mode = words[1]
	widget:UpdateCallIns()
end

function widget:Initialize()
	if (canShader) then
	  	stereoShader = gl.CreateShader({
			fragment = [[
				uniform mat3 colorleft;
				uniform mat3 colorright;

				uniform sampler2D texLeft;
				uniform sampler2D texRight;
				void main(void)
				{
					gl_FragColor.rgb  = colorleft * texture2D(texLeft, gl_TexCoord[0].xy).rgb;
					gl_FragColor.rgb += colorright * texture2D(texRight, gl_TexCoord[0].xy).rgb;
					gl_FragColor.a = 1.0;
				}
			]],
			uniformInt = { texLeft= 0, texRight= 1,	}
		})

		if (not stereoShader) then
			Spring.Echo("Stereo3D widget: shader0 error:" .. gl.GetShaderLog())
			widgetHandler:RemoveWidget()
			return;
		end

		colorMatrixLeftLoc  = gl.GetUniformLocation(stereoShader, "colorleft")
		colorMatrixRightLoc = gl.GetUniformLocation(stereoShader, "colorright")

		stereoShaderPara = gl.CreateShader({
			fragment = [[
				uniform sampler2D texLeft;
				uniform sampler2D texRight;
				void main(void)
				{
					if(gl_TexCoord[0].x>0.5) {
						gl_FragColor = texture2D(texLeft, gl_TexCoord[0].xy * vec2(2.0,1.0));
					} else {
						gl_FragColor = texture2D(texRight, (gl_TexCoord[0].xy - vec2(0.5,0.0)) * vec2(2.0,1.0));
					}
				}
			]],
			uniformInt = { texLeft= 0, texRight= 1,	}
		})

		if (not stereoShaderPara) then
			Spring.Echo("Stereo3D widget: shader1 error:" .. gl.GetShaderLog())
			widgetHandler:RemoveWidget()
			return;
		end

		stereoShaderInt = gl.CreateShader({
			fragment = [[
				uniform sampler2D texLeft;
				uniform sampler2D texRight;
				void main(void)
				{
					if(mod(floor(gl_FragCoord.y),2.0)>=1.0) {
						gl_FragColor = texture2D(texLeft, gl_TexCoord[0].xy);
					} else {
						gl_FragColor = texture2D(texRight, gl_TexCoord[0].xy);
					}
				}
			]],
			uniformInt = { texLeft= 0, texRight= 1,	}
		})

		if (not stereoShaderInt) then
			Spring.Echo("Stereo3D widget: shader2 error:" .. gl.GetShaderLog())
			widgetHandler:RemoveWidget()
			return;
		end
	end

	widget:ViewResize(widgetHandler:GetViewSizes())
	init = true
	widget:UpdateCallIns()

	widgetHandler:AddAction("stereo3d_toggle3d", ToggleStereo3D, nil, "t")
	widgetHandler:AddAction("stereo3d_mode", Mode, nil, "t")
	
end

function widget:Shutdown()
	if (lefttext) then
		gl.DeleteTexture(lefttext)
	end
	if (righttext) then
		gl.DeleteTexture(righttext)
	end
	if (stereoShader) then
		gl.DeleteShader(stereoShader)
	end
	if (stereoShaderParallel) then
		gl.DeleteShader(stereoShaderParallel)
	end
end

function widget:UpdateCallIns()
	if not init then return end --crash if called before init, due to stereoShader
	--self:ViewResize(vsx, vsy)
	
	if not options.toggle3d.value then
		self.DrawWorld = function() end
		self.DrawScreen = function() end
		self.DrawScreenEffects = function() end
		return
	end
	self.DrawWorld = DrawWorld3D
	self.DrawScreen = DrawScreen3D
	
	self.DrawScreenEffects = DrawScreenEffectsShader
	if (mode == 'anaglyph2')or(not canShader) then
		self.DrawScreenEffects = DrawScreenEffectsAnaglyphNoShader
	elseif (mode == 'interlaced') then
		selected_stereoShader = stereoShaderInt
	elseif (mode == 'parallel') then
		selected_stereoShader = stereoShaderPara
	else
		selected_stereoShader = stereoShader
		gl.ActiveShader(stereoShader, function()
			gl.UniformMatrix(colorMatrixLeftLoc, unpack(ColorMatrices[mode].left))
			gl.UniformMatrix(colorMatrixRightLoc,unpack(ColorMatrices[mode].right))
		end)
	end
	widgetHandler:UpdateCallIn("DrawScreenEffects")
	widgetHandler:UpdateCallIn("DrawScreenEffects") --bug need to call it twice!
	widgetHandler:UpdateCallIn("DrawWorld")
	widgetHandler:UpdateCallIn("DrawWorld")
	widgetHandler:UpdateCallIn("DrawScreen")
	widgetHandler:UpdateCallIn("DrawScreen")
end

function widget:ViewResize(viewSizeX, viewSizeY)
	vsx = viewSizeX
	vsy = viewSizeY

	if (lefttext) then
		gl.DeleteTexture(lefttext)
	end
	if (righttext) then
		gl.DeleteTexture(righttext)
	end

	lefttext = gl.CreateTexture(vsx, vsy, {
		border = false,
		min_filter = GL.NEAREST, mag_filter = GL.NEAREST,
	})
	righttext = gl.CreateTexture(vsx, vsy, {
		border = false,
		min_filter = GL.NEAREST, mag_filter = GL.NEAREST,
	})
end

function widget:Update()
	local alt,ctrl,meta, shift = Spring.GetModKeyState()
	if (ctrl and alt and shift) then
		if not hideCursorKeyCombo then
			hideCursorKeyCombo = true
			options.hidecursor.value = not options.hidecursor.value
		end
	else
		hideCursorKeyCombo = false
	end
end
