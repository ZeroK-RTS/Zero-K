function widget:GetInfo()
    
    return {
        name      = "Persistent Build Spacing",
        desc      = "Recalls last build spacing set for each building and game [v2.0]\n fixed pre-game, added mouse wheel and previsualization options(Helwor)",
        author    = "Niobium & DrHash-,Helwor",
        date      = "Sep 6, 2011",
        license   = "GNU GPL, v3 or later",
        layer     = 1,
        enabled   = true,  --  loaded by default?
    }
    
end

-- Config
local defaultSpacing = 4 -- Big makes for more navigable bases for new players.

-- Speedups
local spGetActiveCommand    = Spring.GetActiveCommand
local spGetBuildSpacing     = Spring.GetBuildSpacing
local spSetBuildSpacing     = Spring.SetBuildSpacing
local spGetBuildFacing      = Spring.GetBuildFacing
local spGetMouseState       = Spring.GetMouseState
local spTraceScreenRay      = Spring.TraceScreenRay
local spGetGroundHeight     = Spring.GetGroundHeight
local spGetGameSeconds      = Spring.GetGameSeconds
local spGetSpectatingState  = Spring.GetSpectatingState
local spGetModKeyState      = Spring.GetModKeyState
local Echo                  = Spring.Echo

local floor,round,huge = math.floor,math.round,math.huge

local GL_LINES      = GL.LINES
local glLineWidth   = gl.LineWidth
local glColor       = gl.Color
local glBeginEnd    = gl.BeginEnd
local glVertex      = gl.Vertex
local glLineStipple = gl.LineStipple
local glPushMatrix  = gl.PushMatrix
local glPopMatrix   = gl.PopMatrix
local glTranslate   = gl.Translate
local glBillboard   = gl.Billboard
local glText        = gl.Text

include("keysym.lua")
local _, ToKeysyms  = include("Configs/integral_menu_special_keys.lua")



---- Shared variables
local cmdID, lastCmdID
local buildStarted
local buildSpacing = {}
local identified=false
local p
local preGame=spGetGameSeconds()<0.1
local spacing,newspacing,facing
local spacedRects={}
local time=0
local x,y,z
local dwOn,draw,drawValue, drawRects

-- related to options
local requestUpdate
local wheelSpacing,reverseWheel
local showSpacingRects, only2Rects, showRectsOnChange
local showSpacingValue, showValueOnChange
local showRectsTime=1
local showValueTime=1
local spacingIncrease
local spacingDecrease
----

------- Options functions
local function UpdateKeys()
    local key = WG.crude.GetHotkeyRaw("buildspacing inc")
    spacingIncrease = ToKeysyms(key and key[1])
    key = WG.crude.GetHotkeyRaw("buildspacing dec")
    spacingDecrease = ToKeysyms(key and key[1])
end
-- Menu detection, update and refresh
local function UpdateOptionsDisplay(options_path)
    local greyed = "\255\155\155\155"
    for _,option in pairs(options) do
        local value     = option.value
        local origname  = option.origname
        local parents   = option.parents
        local children  = option.children
        if parents then --if the option is a child -- CANDO: better with scanning child by parents instead of parents by child, keep in mind child can have multiple parents
            -- greying out if its value is false/nil
            if origname then option.name = value and origname or greyed..origname end      
            -- masking itself if all its parents have false/nil value
            local parentsVal
            for _,parentname in pairs(parents) do
                parentsVal = options[parentname].value
                if parentsVal then break end
            end
            option.hidden = not parentsVal
        end
        if children and origname then -- if its a parent
            option.name = value and origname or origname.."..."
        end
    end
    -- refreshing menu if it's active
    for _,v in pairs(WG.Chili.Screen0.children) do
        if 	type(v)=='table' and v.classname=="main_window_tall" then
            if v.caption==options_path then
                WG.crude.OpenPath(options_path)
            end
        end
    end
end
-------

-------- Options
local hotkeys_path = 'Hotkeys/Construction'
options_path = 'Settings/Interface/Building Placement'
options_order = {
    'text_hotkey',
    'hotkey_inc', 'hotkey_dec', 'hotkey_facing_inc', 'hotkey_facing_dec',
    'spacing_label',
    'wheel_spacing', 'reverse_wheel',
    'show_spacing_rects', 'show_only_2_rects', 'show_rects_only_on_change', 'show_time_rects',
    'show_spacing_value', 'show_value_only_on_change', 'show_time_value',
    'separator_label'
}
-- hotkeys
options = {
    text_hotkey = {
        name            = 'Structure Placement Modifiers',
        type            = 'label',
        path            = hotkeys_path
    },
  hotkey_inc = {
        name            = 'Increase Build Spacing',
        type            = 'button',
        desc            = 'Increase the spacing between structures queued in a line or rectangle. Hold Shift to queue a line of structures. Add Alt to queue a rectangle. Add Ctrl to queue a hollow rectangle.',
        action          = "buildspacing inc",
        bindWithAny     = true,
        path            = hotkeys_path,
        OnHotkeyChange  = UpdateKeys,
    },
    hotkey_dec = {
        name            = 'Decrease Build Spacing',
        type            = 'button',
        desc            = 'Decrease the spacing between structures queued in a line or rectangle. Hold Shift to queue a line of structures. Add Alt to queue a rectangle. Add Ctrl to queue a hollow rectangle.',
        action          = "buildspacing dec",
        bindWithAny     = true,
        path            = hotkeys_path,
        OnHotkeyChange  = UpdateKeys,
        
    },
    hotkey_facing_inc = {
        name            = 'Rotate Counterclockwise',
        type            = 'button',
        desc            = 'Rotate the structure placement blueprint counterclockwise.',
        action          = "buildfacing inc",
        bindWithAny     = true,
        path            = hotkeys_path,
    },
    hotkey_facing_dec = {
        name            = 'Rotate Clockwise',
        type            = 'button',
        desc            = 'Rotate the structure placement blueprint clockwise.',
        action          = "buildfacing dec",
        bindWithAny     = true,
        path            = hotkeys_path,
    },
    -- wheel and visualization implementation
    spacing_label = {
        name            = 'Build Spacing',
        type            = 'label',
    },
    -- wheel
    wheel_spacing = {
        origname        = 'On Shift + MouseWheel',
        type            = 'bool',		
        desc            = 'Change the spacing with the Mousewheel and Shift down',
        noHotkey        = true,
        OnChange        = function(self) 
                            wheelSpacing = self.value
                            requestUpdate=options_path
                          end,
        children        = {'reverse_wheel'}
    },
    reverse_wheel = {
        origname        = ' ..reversed',
        type            = 'bool',
        noHotkey        = true,
        OnChange        = function(self)
                            reverseWheel = self.value and -1 or 1
                            requestUpdate=options_path
                          end,
        parents         = {'wheel_spacing'}
    },
    -- rectangle showing options
    show_spacing_rects = {
        origname        = 'Previsualization',
        type            = 'bool',
        desc            = "Briefly show spaced rectangles in all directions around the cursor",
        noHotkey        = true,
        OnChange        = function(self) 
                            showSpacingRects = self.value				
                            spacedRects={}
                            requestUpdate=options_path
                          end,
        children        = {'show_only_2_rects','show_rects_only_on_change','show_time_rects'}
    },
    
    show_only_2_rects = {
        origname        = ' ..of only two rectangles,',
        type            = 'bool',
        desc            = "If 8 rectangles bug you too much, only show 2 horizontal rectangles",
        noHotkey        = true,
        OnChange        = function(self)
                            spacedRects={}
                            only2Rects = self.value
                            requestUpdate=options_path
                          end,
        parents         = {'show_spacing_rects'}
    },
    show_rects_only_on_change = {
        origname        = ' ..only on spacing change,',
        type            = 'bool',
        desc            = "If you don't want to see those rectangles until you change the current spacing",
        noHotkey        = true,
        OnChange        = function(self)
                            showRectsOnChange = self.value
                            requestUpdate=options_path
                          end,
        parents         = {'show_spacing_rects'}
    },
    show_time_rects = {
        name            = ' ..within 1 sec.',
        type            = 'number',
        min             = 0.1,
        max             = 5,
        step            = 0.1,
        value           = 1,
        tooltipFunction = function(self)
                            return self.value<5 and round(self.value,1).." sec" or "forever"
                          end,
        OnChange        = function(self)
                            showRectsTime = self.value<5 and self.value or huge
                            local str = self.tooltipFunction(self) -- just using the return
                            if str=='forever'
                            then self.name = " ..forever."
                            else self.name = ' ..within '..str..'.' end
                            requestUpdate=options_path
                          end,
        parents        = {'show_spacing_rects'}
    },
    -- value showing options
    show_spacing_value = {
        origname        = 'Show spacing value',
        type            = 'bool',
        desc            = "Briefly show separation value",
        noHotkey        = true,
        OnChange        = function(self)
                            showSpacingValue = self.value
                            requestUpdate=options_path
                          end,
        children        = {'show_value_only_on_change','show_time_value'}
    },
    
    show_value_only_on_change = {
        origname        = ' ..only on spacing change,',
        type            = 'bool',
        desc            = "If you don't want to see the above helper until you change the current spacing",
        noHotkey        = true,
        OnChange        = function(self)
                            showValueOnChange = self.value
                            requestUpdate=options_path
                          end,
        parents         = {'show_spacing_value'}
    },
    
    show_time_value = {
        name            = ' ..within 1 sec.',
        type            = 'number',
        min             = 0.1,
        max             = 5,
        step            = 0.1,
        value           = 1,
        tooltipFunction	= function(self)
                            return self.value<5 and round(self.value,1).." sec" or "forever"
                          end,
        OnChange        = function(self)
                            showValueTime = self.value<5 and self.value or huge
                            local str = self.tooltipFunction(self) -- just using the return
                            if str=='forever'
                            then self.name = " ..forever."
                            else self.name = ' ..within '..str..'.' end
                            requestUpdate=options_path
                          end,
        parents 		= {'show_spacing_value'},
    },
    --
    separator_label = {
        name = '¯¯',
        type = 'label',
    },
}
--

-- for drawing later...
local function IdentifyPlacement(PID,facing)
    local ud = UnitDefs[PID]
    local offFacing = facing==1 or facing==3
    local sx = ud.xsize*8 
    local sz = ud.zsize*8 
    if offFacing then sx, sz = sz, sx	end
    local oddx,oddz = (sx/2)%16,(sz/2)%16
    return {oddx=oddx,
            oddz=oddz,
            sx=sx,
            sz=sz,
            floatOnWater=ud.floatOnWater  }
end
local function toValidPlacement(x,z,oddx,oddz)
    x = floor((x + 8 - oddx)/16)*16 + oddx
    z = floor((z + 8 - oddz)/16)*16 + oddz
    return x,z
end
local function DrawFlatRect(rect,y)
    local x,z,sx,sz = unpack(rect)
    local sx,sz= sx/2,sz/2
    local c1= {x-sx, y, z-sz}
    local c2= {x-sx, y, z+sz}
    local c3= {x+sx, y, z+sz}
    local c4= {x+sx, y, z-sz}
    local cornersdraw={c1,c2,c2,c3,c3,c4,c4,c1}
    for i,corner in ipairs(cornersdraw) do
        glVertex(unpack(corner))
    end
end
--
-- Callins
function widget:KeyPress(key)
    if cmdID and cmdID<0 then
        local change = key==spacingIncrease and 1 or key==spacingDecrease and -1
        if change then 
            spacing=spacing+change
            spacing=spacing>0 and spacing or 0
            time=0
            newspacing=true
            buildStarted=false
            if preGame then
                spSetBuildSpacing(spacing)-- action is recognized but still doesnt work, so we do change spacing directly
                return true -- make it override construction tab hotkey in pregame as it would do in game
            end
        end
    end
end

function widget:MouseWheel(up,value)
    local shift = select(4,spGetModKeyState())
    if wheelSpacing and shift and cmdID then
        spacing = spacing + reverseWheel*value
        spacing = spacing>0 and spacing or 0
        spSetBuildSpacing(spacing)
        time=0
        newspacing = true
        buildStarted = false
        return true -- blocking the zooming
    end
end

function widget:Update(dt)
    if requestUpdate then
        UpdateOptionsDisplay(requestUpdate)
        requestUpdate=false
    end
    
    cmdID = select(2,spGetActiveCommand())
    if not cmdID or cmdID>=0 then
        time=0
        draw=false
        buildStarted=nil
        return
    end
    
    if preGame then preGame=spGetGameSeconds()<0.1 end    
    
    if buildStarted==nil then buildStarted=true end
    
    if cmdID ~= lastCmdID then
        spacing=buildSpacing[-cmdID] or tonumber(UnitDefs[-cmdID].customParams.default_spacing) or defaultSpacing
        spSetBuildSpacing(spacing)
        lastCmdID = cmdID
        identified=false
        time=0
    end
    if newspacing then buildSpacing[-cmdID] = spacing end
    
    -- Drawing set up
    draw, drawRects, drawValue = true,true,true
    
    if	not showSpacingRects
        or time>showRectsTime
        or showRectsOnChange and buildStarted
        then
        drawRects=false
    end
    if not showSpacingValue
        or time>showValueTime
        or showValueOnChange and buildStarted
        then
        drawValue=false
    end
    
    if not drawValue and not drawRects then draw = false return end
    
    time = time + dt
    
    local f = spGetBuildFacing()
    if facing~=f or not identified then
        facing=f
        p=IdentifyPlacement(-cmdID,facing)
        identified = true
    end
    
    local mx,my,leftClick,_,rightClick = spGetMouseState()
    if leftClick or rightClick then draw=false  return end
    
    local pos = select(2,spTraceScreenRay(mx, my, true, false, false, p.floatOnWater))
    if not pos then draw=false return end
    
    local nx,nz = toValidPlacement(pos[1],pos[3],p.oddx,p.oddz)
    if x==nx and z==nz and not(newspacing or buildStarted) then return end -- only recalculate rectangles when needed
    
    newspacing = false
    x,z=nx,nz
    
    y = spGetGroundHeight(x,z)
    local count=0
    local sx,sz = p.sx,p.sz
    for offx=-1,1 do
        for offz=-1,1 do
            if not(offx==0 and offz==0) then -- skipping the middle one
                if not only2Rects or offz==0 then
                    count=count+1
                    spacedRects[count]={ x + offx*(spacing*16 + sx), z + offz*(spacing*16 + sz), sx, sz}
                end
            end
        end
    end
    if not dwOn then widgetHandler:UpdateCallIn("DrawWorld") end
    --
end


------------- Drawing
function widget:DrawWorld()
    if not draw then dwOn=false spacedRects={} widgetHandler:RemoveCallIn("DrawWorld") return end
    dwOn=true
    if drawRects then
        local alpha
        if time<(showRectsTime-1) then
            alpha = 0.6
        else
            local ftime = time-(showRectsTime-1)
            alpha = 0.6/(ftime+1)^ftime -- fading out in the last second
        end
        glLineWidth(1.5)
        glColor(0.5, 1, 0.5, alpha)
        glLineStipple(true)
        for _,rect in ipairs(spacedRects) do
            local y = spGetGroundHeight(rect[1],rect[2])
            glBeginEnd(GL_LINES, DrawFlatRect, rect, y)
        end
        glLineWidth(1)
        glLineStipple(false)
        glColor(1, 1, 1, 1)
    end	
    --
    if drawValue then
        glPushMatrix()
        glTranslate(x,y,z)
        glBillboard()
        glColor(1, 1, 1, 0.4)
        glText(spacing, p.sx/2,p.sz/2,30,'h')
        glPopMatrix()
        glColor(1, 1, 1, 1)
    end
    --
end
------------

-- Save/Load spacing values
function widget:GetConfigData()
    local spacingByName = {}
    for unitDefID, spacing in pairs(buildSpacing) do
        local name = UnitDefs[unitDefID] and UnitDefs[unitDefID].name
        if name then
            spacingByName[name] = spacing
        end
    end
    return { buildSpacing = spacingByName }
end

function widget:SetConfigData(data)
    local spacingByName = data.buildSpacing or {}
    for name, spacing in pairs(spacingByName) do
        local unitDefID = UnitDefNames[name] and UnitDefNames[name].id
        if unitDefID then
            buildSpacing[unitDefID] = spacing
        end
    end
end

-- Init
function widget:Initialize()-- fixing the missing hotkey recognition in pre-game
    if spGetSpectatingState() then widgetHandler:RemoveWidget() end
    UpdateKeys() 
end


