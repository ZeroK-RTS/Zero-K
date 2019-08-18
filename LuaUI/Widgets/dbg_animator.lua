-------------------------


function widget:GetInfo()
  return {
    name      = "AnimatorGUI",
    desc      = "v0.002 Send animation commands",
    author    = "CarRepairer & knorke",
    date      = "2010-03-05",
    license   = "push button magic",
    layer     = 0,
    enabled   = false,
  }
end


local Chili
local Button
local Label
local Window
local ScrollPanel
local StackPanel
local Grid
local TextBox
local Image
local TreeView
local Trackbar
local screen0


local scrH, scrW 		= 0,0

include("keysym.h.lua")

local PI = 3.14
local B_HEIGHT = 20
	

local window_anim
local selectedUnit
local rotX, rotY, rotZ
local posX, posY, posZ
local showButton, hideButton, printPieceButton
local writeOutButton, resetButton,  pieceTreeControl, scroll1, stack1

--------------------------

local echo = Spring.Echo

--------------------------
-- Helper Functions
-- [[
local function table_to_string(data, indent)
    local str = ""

    if(indent == nil) then
        indent = 0
    end
	local indenter = "    "
    -- Check the type
    if(type(data) == "string") then
        str = str .. (indenter):rep(indent) .. data .. "\n"
    elseif(type(data) == "number") then
        str = str .. (indenter):rep(indent) .. data .. "\n"
    elseif(type(data) == "boolean") then
        if(data == true) then
            str = str .. "true"
        else
            str = str .. "false"
        end
    elseif(type(data) == "table") then
        local i, v
        for i, v in pairs(data) do
            -- Check for a table in a table
            if(type(v) == "table") then
                str = str .. (indenter):rep(indent) .. i .. ":\n"
                str = str .. table_to_string(v, indent + 2)
            else
                str = str .. (indenter):rep(indent) .. i .. ": " .. table_to_string(v, 0)
            end
        end
	elseif(type(data) == "function") then
		str = str .. (indenter):rep(indent) .. 'function' .. "\n"
    else
        echo(1, "Error: unknown data type: %s", type(data))
    end

    return str
end
--]]

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

local function SendMessageCheck(msg)
	if not Spring.IsCheatingEnabled() then
		echo "Cannot do this unless Cheating is enabled."
		return
	end
	Spring.SendLuaRulesMsg(msg)
end

local function PieceInfo(pieceInfo)
	local pieceInfo_t = explode('|', pieceInfo)
	local i = 1
	
	local rx = pieceInfo_t[i] ; i = i + 1
	local ry = pieceInfo_t[i] ; i = i + 1
	local rz = pieceInfo_t[i] ; i = i + 1
	
	local px = pieceInfo_t[i] ; i = i + 1
	local py = pieceInfo_t[i] ; i = i + 1
	local pz = pieceInfo_t[i] ; i = i + 1
	
	rotX:SetValue( rx )
	rotY:SetValue( ry )
	rotZ:SetValue( rz )
	
	posX:SetValue( px )
	posY:SetValue( py )
	posZ:SetValue( pz )
	
	
end


local function PieceTreeRec( unitID, pieceNum )
	local pieceInfo = Spring.GetUnitPieceInfo( unitID, pieceNum )
	local pieceName = pieceInfo.name
	local children = pieceInfo.children
	if #children == 0 then
		return pieceName
	end
	local pieceTree = {}
	for i, chName in ipairs(children) do
		local chNum = Spring.GetUnitPieceMap(unitID)[chName]
		pieceTree[chName] = PieceTreeRec( unitID, chNum )
	end
	return pieceTree
end
local function PieceTree(unitID)
	local pieceInfo = Spring.GetUnitPieceInfo( unitID, 1 )
	local pieceName = pieceInfo.name
	return { [pieceName] = PieceTreeRec( unitID, 1 ) }
end

local function MakePieceTreeNodesRec(unitID, pieceTree, nodes)
	local nodes2 = {}
	for pieceName, pChildren in pairs(pieceTree) do
		local pieceNum = Spring.GetUnitPieceMap(unitID)[pieceName]
		--nodes2[#nodes2+1] = Label:New{ caption = pieceName }
		nodes2[#nodes2+1] = Button:New{
			caption = pieceName,
			OnClick = {function(self)
				SendMessageCheck("animator|getpieceinfo|" .. unitID .. '|' .. pieceNum)
				
				rotX.unitID = unitID
				rotY.unitID = unitID
				rotZ.unitID = unitID
				
				rotX.pieceNum = pieceNum
				rotY.pieceNum = pieceNum
				rotZ.pieceNum = pieceNum
				
				posX.unitID  = unitID
				posY.unitID  = unitID
				posZ.unitID  = unitID
				
				posX.pieceNum = pieceNum
				posY.pieceNum = pieceNum
				posZ.pieceNum = pieceNum
				
				showButton.pieceNum = pieceNum
				hideButton.pieceNum = pieceNum
			end},
		}
		if type( pChildren ) == 'table' then
			nodes2[#nodes2+1] = {
				MakePieceTreeNodesRec(unitID, pChildren, nodes2)
			}
		end
	end
	return nodes2
end


local function MakePieceTreeNodes(unitID)
	local pieceTree = PieceTree(unitID)
	return MakePieceTreeNodesRec(unitID, pieceTree, {})
end

local function UpdateAnimWindow(unitID)
	if unitID == 0 then return end
	writeOutButton.unitID = unitID
	resetButton.unitID = unitID
	
	pieceTreeControl = TreeView:New{
		y = B_HEIGHT,
		nodes = MakePieceTreeNodes(unitID),
	}
	stack1:Dispose()
	
	local children = {}
	
	children[#children+1] = writeOutButton
	children[#children+1] = printPieceButton
	children[#children+1] = resetButton
	
	children[#children+1] = Label:New{ caption = 'Rot X', width=40, height=B_HEIGHT, }; children[#children+1] = rotX
	children[#children+1] = Label:New{ caption = 'Rot Y', width=40, height=B_HEIGHT, }; children[#children+1] = rotY
	children[#children+1] = Label:New{ caption = 'Rot Z', width=40, height=B_HEIGHT, }; children[#children+1] = rotZ
	
	children[#children+1] = Label:New{ caption = 'Pos X', width=40, height=B_HEIGHT, }; children[#children+1] = posX
	children[#children+1] = Label:New{ caption = 'Pos Y', width=40, height=B_HEIGHT, }; children[#children+1] = posY
	children[#children+1] = Label:New{ caption = 'Pos Z', width=40, height=B_HEIGHT, }; children[#children+1] = posZ
	
	children[#children+1] = showButton
	children[#children+1] = hideButton
	children[#children+1] = testAnimButton
	
	showButton.unitID = unitID
	hideButton.unitID = unitID
	testAnimButton.unitID = unitID
	
	

	children[#children+1] = Label:New{ caption = 'Pieces', width='100%', autosize=false, align='center', height=B_HEIGHT }
	
	children[#children+1] = pieceTreeControl
	
	stack1 = StackPanel:New{
		orientation = 'horizontal',
		autosize = true,
		resizeItems = false,
		centerItems = false,
		--bottom=B_HEIGHT,
		width = '100%',
		children = children,
	}
	scroll1:ClearChildren()
	scroll1:AddChild(stack1)
end

local function AnimWindow(unitID)
	
	local children = {}
	
	
	if unitID ~= 0 then
		tnodes = MakePieceTreeNodes(unitID)
	end
	writeOutButton.unitID = unitID
	resetButton.unitID = unitID
	pieceTreeControl = TreeView:New{
		y = B_HEIGHT,
		nodes = tnodes,
	}
	
	children[#children+1] = pieceTreeControl
	
	stack1 = StackPanel:New{
		autosize = true,
		resizeItems = false,
		centerItems = false,
		--bottom=B_HEIGHT,
		width = '100%',
		children = children,
	}
	
	
	scroll1 = ScrollPanel:New{
		y = B_HEIGHT,
		bottom = 0,
		width = "100%",
		children = {
			stack1
		},
	}
	
	local window = Window:New{
		caption = "Animation Control",
		x = scrW/3,
		y = scrH/3,
		width='20%',
		minHeight=300,
		minWidth=200,
		classname = "main_window_small",
		--height = '30%',
		resizable = true,
		parent = screen0,
		dockable = true,
		--autosize = true,
		children = {
			scroll1
		},
	}
	window_anim = window
end






function write_unit_piece_tree (unitID, unitDefID)
	local unitDef = UnitDefs[unitDefID]
	Spring.Echo ("*** pieces tree of " .. unitDef.name .. " ***")
	write_children (unitID,1,0)
end

function write_children (unitID, pID, recdeep)
	PieceInfo = Spring.GetUnitPieceInfo (unitID, pID)
	local pname = PieceInfo.name
	if (recdeep == 0) then Spring.Echo (pname) end
	local pchildren = PieceInfo.children
	for i,cname  in ipairs(pchildren) do
		local cpID = Spring.GetUnitPieceMap(unitID)[cname]
		local spacing = string.rep("-",recdeep+1)
		Spring.Echo (spacing .. cname)
		write_children (unitID, cpID,recdeep+1)
    end
	return
end

function write_piece_list (unitID)
	local allpieces = Spring.GetUnitPieceList (unitID)
	local piece_n = table.getn (allpieces)
	Spring.Echo ("unit has " .. piece_n  .. " pieces")
	for pID=1, piece_n,1  do
		Spring.Echo ("pID:" .. pID)
		PieceInfo = Spring.GetUnitPieceInfo (unitID,pID)
		local pname = PieceInfo.name
		local pchildren = PieceInfo.children
		Spring.Echo (" name:"..pname)
	end
end


--------------------------


function widget:SelectionChanged(selectedUnits)
	if not selectedUnits or not selectedUnits[1] then return end
	selectedUnit = selectedUnits[1]
	SendMessageCheck ("animator|sel|" .. selectedUnit )
	
	--echo( table_to_string( PieceTree(unitID) ) )
	
	UpdateAnimWindow(selectedUnit)
end

function widget:Initialize()
	local devMode = Spring.GetGameRulesParam('devmode') == 1
	if not WG.Chili or not devMode then
		widgetHandler:RemoveWidget(widget)
		return
	end
	
	-- setup Chili
	Chili = WG.Chili
	Button = Chili.Button
	Label = Chili.Label
	Window = Chili.Window
	ScrollPanel = Chili.ScrollPanel
	StackPanel = Chili.StackPanel
	Grid = Chili.Grid
	TextBox = Chili.TextBox
	Image = Chili.Image
	TreeView = Chili.TreeView
	Trackbar = Chili.Trackbar
	screen0 = Chili.Screen0
	
	rotX = Trackbar:New{ min=-PI,max=PI, step=0.1, value = 0, width="80%",right=0, height=B_HEIGHT, unitID=0, pieceNum=0, OnClick = { function(self) SendMessageCheck("animator|turn|x|" .. self.unitID .. '|' .. self.pieceNum .. '|' .. self.value ) end }, }
	rotY = Trackbar:New{ min=-PI,max=PI, step=0.1, value = 0, width="80%",right=0, height=B_HEIGHT, unitID=0, pieceNum=0, OnClick = { function(self) SendMessageCheck("animator|turn|y|" .. self.unitID .. '|' .. self.pieceNum .. '|' .. self.value ) end }, }
	rotZ = Trackbar:New{ min=-PI,max=PI, step=0.1, value = 0, width="80%",right=0, height=B_HEIGHT, unitID=0, pieceNum=0, OnClick = { function(self) SendMessageCheck("animator|turn|z|" .. self.unitID .. '|' .. self.pieceNum .. '|' .. self.value ) end }, }
	
	posX = Trackbar:New{ min=-100,max=100, step=2, value = 0, width="80%",right=0, height=B_HEIGHT, unitID=0, pieceNum=0, OnClick = { function(self) SendMessageCheck("animator|move|x|" .. self.unitID .. '|' .. self.pieceNum .. '|' .. self.value ) end }, }
	posY = Trackbar:New{ min=-100,max=100, step=2, value = 0, width="80%",right=0, height=B_HEIGHT, unitID=0, pieceNum=0, OnClick = { function(self) SendMessageCheck("animator|move|y|" .. self.unitID .. '|' .. self.pieceNum .. '|' .. self.value ) end }, }
	posZ = Trackbar:New{ min=-100,max=100, step=2, value = 0, width="80%",right=0, height=B_HEIGHT, unitID=0, pieceNum=0, OnClick = { function(self) SendMessageCheck("animator|move|z|" .. self.unitID .. '|' .. self.pieceNum .. '|' .. self.value ) end }, }
	
	showButton = Button:New{ caption = 'Show', width='30%', pieceNum=0, height=B_HEIGHT, OnClick = { function(self) SendMessageCheck("animator|show|" .. self.unitID .. '|' .. self.pieceNum ) end }, }
	hideButton = Button:New{ caption = 'Hide', width='30%', pieceNum=0, height=B_HEIGHT, OnClick = { function(self) SendMessageCheck("animator|hide|" .. self.unitID .. '|' .. self.pieceNum ) end }, }
	
	testAnimButton = Button:New{ caption = 'Test Thread', width='30%', height=B_HEIGHT, OnClick = { function(self) SendMessageCheck("animator|testthread|" .. self.unitID ) end }, }


	printPieceButton = Button:New{ caption = 'Print Pieces', width='30%', height=B_HEIGHT*2, OnClick = { function(self) write_piece_list(selectedUnit) end }, }
	writeOutButton = Button:New{
		unitID = 0,
		caption = 'Write Out', width="30%", height=B_HEIGHT*2,
		OnClick = { function(self) SendMessageCheck( 'animator|write|' .. self.unitID ) end },
	}
	
	resetButton = Button:New{
		unitID = 0,
		caption = 'Reset', width="30%", height=B_HEIGHT*2,
		OnClick = { function(self)
			SendMessageCheck( 'animator|reset|' .. self.unitID )
			rotX:SetValue( 0 )
			rotY:SetValue( 0 )
			rotZ:SetValue( 0 )
			
			posX:SetValue( 0 )
			posY:SetValue( 0 )
			posZ:SetValue( 0 )
		end },
	}
	
	
	AnimWindow(0)
	
	widgetHandler:RegisterGlobal("PieceInfo",PieceInfo)
end
function widget:Shutdown()
	widgetHandler:DeregisterGlobal("PieceInfo")
end


function widget:ViewResize(vsx, vsy)
	scrW = vsx
	scrH = vsy
end


