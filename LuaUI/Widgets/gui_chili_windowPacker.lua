function widget:GetInfo()
  return {
    name      = "Chili Window Packer",
    desc      = "Provides functionality to automatically arrange windows in space-saving manners. Activate-able thru \"packNow\" button (\255\90\255\90Setting/HUD Panels/Docking\255\255\255\255).",
    author    = "xponen",
    date      = "12 May 2014",
    license   = "GNU GPL, v2 or later",
    layer     = 50,
    enabled   = true  --  loaded by default?
  }
end
--Credit to algorithm author: Jukka Jylänki
--More information: http://clb.demon.fi/projects/rectangle-bin-packing
--Source code: https://github.com/juj/RectangleBinPack


WG.PackChiliWindows = function() end
local alignChoice,heuristicChoice = 2,1
------------------------------------------------------------------------
options_path = 'Settings/HUD Panels/Docking'
options_order = {'lbl','packNow','packSpot','packScheme' }
options = {
	lbl = {name='Automatic Window Tile Packer:', type='label'},
	packNow = {
		name = "packNow",
		desc = "Arrange Chili windows to minimize wasted space."..
				"\n\nTips: resize, minimize, use docking or close windows to tweak the results."..
				"\n\nTips2: Press ESCAPE to exit GuiTweak mode",
		type = 'button',
        OnChange= function()
			WG.PackChiliWindows()
		end,
	},
	packSpot = {
		name = "Layout (left or right aligned):",
		type = 'number',
		advanced = false,
		desc = "TopLeft,BottomLeft <-> BottomRight,TopRight",
		value = 2,
		min=1,max=4,step=1,
		OnChange = function(self)
			alignChoice = math.modf(self.value)
		end,
	},	
	packScheme = {
		name = "Algorithm (window arrangement):",
		type = 'number',
		advanced = false,
		desc = "MinimizeSideSpace,MaximizeAdjacentWindow,BestAreaFit,CornerFirst",
		value = 1,
		min=1,max=4,step=1,
		OnChange = function(self)
			heuristicChoice = math.modf(self.value)
		end,
	},	
}

------------------------------------------------------------------------
WG.PackChiliWindows = function()
	Spring.SendCommands("luaui tweakgui")
	local rectList = {}
	local count= 1
	local screen0 = WG.Chili.Screen0
	for _, win in ipairs(screen0.children) do
		if win.dockable and not win.hidden then
			local winName = win.name
			rectList[count] = CreateRect(win.x,win.y,win.width,win.height)
			rectList[count].name = win.name
			rectList[count].object = win
			count = count + 1
		end
	end
	local choice = {"BestShortSideFit", "ContactPointRule","RectBestAreaFit","RectBottomLeftRule","RectBestLongSideFit"}
	local xMult,yMult,xOffset,yOffset
	local choiceMsg = "CHOICE : ".. choice[heuristicChoice]
	if alignChoice==1 then
		xMult,yMult,xOffset,yOffset = 1,1,0,0
		choiceMsg = choiceMsg .. " TopLeft-Aligned"
	elseif alignChoice==4 then
		xMult,yMult,xOffset,yOffset = -1,1,1,0
		choiceMsg = choiceMsg .. " TopRight-Aligned"
	elseif alignChoice==3 then
		xMult,yMult,xOffset,yOffset = -1,-1,1,1
		choiceMsg = choiceMsg .. " BottomRight-Aligned"
	elseif alignChoice==2 then
		xMult,yMult,xOffset,yOffset = 1,-1,0,1
		choiceMsg = choiceMsg .. " BottomLeft-Aligned"
	end
	Spring.Echo(choiceMsg)
	local scrW,scrH = widgetHandler:GetViewSizes()
	rectList = PackMaxRectangleNow(rectList,scrW,scrH,choice[heuristicChoice])
	local set = {}
	for i=1, #rectList do
		local winName = rectList[i].name
		local x,y,width,height = 0,0,rectList[i].width,rectList[i].height
		local x = rectList[i].x*xMult+xOffset*(scrW - width)
		local y = rectList[i].y*yMult+yOffset*(scrH - height)
		local width,height = rectList[i].width,rectList[i].height
		rectList[i].object:SetPos(x, y)
		
	end
end

------------------------------------------------------------------------
function CreateRect(x,y,width,height)
	x = x or 0
	y = y or 0
	width = width or 0
	height = height or 0
	return {x=x,y=y,width=width, height=height}
end
----------------
----------------
	local function FindPositionForNewNodeBestLongSideFit(width, height,freeRectangles)
		local bestNode = CreateRect(0,0,0,0);
		local bestLongSideFit = math.huge;
		local bestShortSideFit

		for i=1,#freeRectangles,1 do
			-- Try to place the rectangle in upright (non-flipped) orientation.
			if (freeRectangles[i].width >= width and freeRectangles[i].height >= height) then
				local leftoverHoriz = math.abs(freeRectangles[i].width - width);
				local leftoverVert = math.abs(freeRectangles[i].height - height);
				local shortSideFit = math.min(leftoverHoriz, leftoverVert);
				local longSideFit = math.max(leftoverHoriz, leftoverVert);

				if (longSideFit < bestLongSideFit or (longSideFit == bestLongSideFit and shortSideFit < bestShortSideFit)) then
					bestNode.x = freeRectangles[i].x;
					bestNode.y = freeRectangles[i].y;
					bestNode.width = width;
					bestNode.height = height;
					bestShortSideFit = shortSideFit;
					bestLongSideFit = longSideFit;
				end
			end
		end
		return bestNode,bestLongSideFit,bestShortSideFit;
	end

	local function FindPositionForNewNodeBottomLeft(width, height,freeRectangles)
		local bestNode = CreateRect(0,0,0,0);
		local bestY = math.huge;

		for i=1,#freeRectangles,1 do
			--Try to place the rectangle in upright (non-flipped) orientation.
			if (freeRectangles[i].width >= width and freeRectangles[i].height >= height) then
				local topSideY = freeRectangles[i].y + height;
				if (topSideY < bestY or (topSideY == bestY and freeRectangles[i].x < bestX)) then
					bestNode.x = freeRectangles[i].x;
					bestNode.y = freeRectangles[i].y;
					bestNode.width = width;
					bestNode.height = height;
					bestY = topSideY;
					bestX = freeRectangles[i].x;
				end
			end
		end
		return bestNode,bestY,bestX
	end

	local function FindPositionForNewNodeBestAreaFit(width, height,freeRectangles)
		local bestNode = CreateRect(0,0,0,0);
		local bestAreaFit = math.huge;
		local bestShortSideFit

		for i=1,#freeRectangles,1 do
			local areaFit = freeRectangles[i].width * freeRectangles[i].height - width * height;

			-- Try to place the rectangle in upright (non-flipped) orientation.
			if (freeRectangles[i].width >= width and freeRectangles[i].height >= height) then
				local leftoverHoriz = math.abs(freeRectangles[i].width - width);
				local leftoverVert = math.abs(freeRectangles[i].height - height);
				local shortSideFit = math.min(leftoverHoriz, leftoverVert);

				if (areaFit < bestAreaFit or (areaFit == bestAreaFit and shortSideFit < bestShortSideFit)) then
					bestNode.x = freeRectangles[i].x;
					bestNode.y = freeRectangles[i].y;
					bestNode.width = width;
					bestNode.height = height;
					bestShortSideFit = shortSideFit;
					bestAreaFit = areaFit;
				end
			end
		end
		return bestNode,bestAreaFit,bestShortSideFit;
	end

	-- Returns 0 if the two intervals i1 and i2 are disjoint, or the length of their overlap otherwise.
	local function CommonIntervalLength(i1start, i1end, i2start, i2end)
		if (i1end < i2start or i2end < i1start) then
			return 0;
		end
		return math.min(i1end, i2end) - math.max(i1start, i2start);
	end

	local function ContactPointScoreNode(x,y, width,height,usedRectangles,binWidth,binHeight)
		local score = 0;
		if (x == 0 or x + width == binWidth) then
			score = score + height;
		end
		if (y == 0 or y + height == binHeight) then
			score = score + width;
		end

		for i=1,#usedRectangles,1 do
			if (usedRectangles[i].x == x + width or usedRectangles[i].x + usedRectangles[i].width == x) then
				score = score + CommonIntervalLength(usedRectangles[i].y, usedRectangles[i].y + usedRectangles[i].height, y, y + height);
			end
			if (usedRectangles[i].y == y + height or usedRectangles[i].y + usedRectangles[i].height == y) then
				score = score + CommonIntervalLength(usedRectangles[i].x, usedRectangles[i].x + usedRectangles[i].width, x, x + width);
			end
		end
		return score;
	end

	local function FindPositionForNewNodeContactPoint(width,height,freeRectangles,usedRectangles,binWidth,binHeight)

		local bestNode = CreateRect(0,0,0,0);
		local bestContactScore = -1;
		for i=1,#freeRectangles,1 do
			--Try to place the rectangle in upright (non-flipped) orientation.
			if (freeRectangles[i].width >= width and freeRectangles[i].height >= height) then
				local score = ContactPointScoreNode(freeRectangles[i].x, freeRectangles[i].y, width, height,usedRectangles,binWidth,binHeight);
				if (score > bestContactScore) then
					bestNode.x = freeRectangles[i].x;
					bestNode.y = freeRectangles[i].y;
					bestNode.width = width;
					bestNode.height = height;
					bestContactScore = score;
				end
			end
		end
		return bestNode,bestContactScore;
	end

	local function FindPositionForNewNodeBestShortSideFit(width,height,freeRectangles)
		
		local bestNode = CreateRect(0,0,0,0)
		local bestShortSideFit = math.huge
		local bestLongSideFit = math.huge
		for i=1,#freeRectangles,1 do
			--Try to place the rectangle in upright (non-flipped) orientation.
			if(freeRectangles[i].width>=width and freeRectangles[i].height >= height) then
				local leftOverHoriz =math.abs(freeRectangles[i].width - width)
				local leftOverVert = math.abs(freeRectangles[i].height - height)
				local shortSideFit = math.min(leftOverHoriz,leftOverVert)
				local longSideFit = math.max(leftOverHoriz,leftOverVert)
				
				if (shortSideFit < bestShortSideFit or (shortSideFit == bestShortSideFit and longSideFit < bestLongSideFit)) then
					bestNode.x = freeRectangles[i].x
					bestNode.y = freeRectangles[i].y
					bestNode.width = width
					bestNode.height = height
					bestShortSideFit = shortSideFit
					bestLongSideFit = longSideFit
				end
			end
		end
		
		return bestNode, bestShortSideFit,bestLongSideFit
	end
----------------
----------------
local function ScoreRect(width,height, rectChoiceHeuristic,freeRectangles,usedRectangles,binWidth,binHeight)
	local newNode
	local score1
	local score2
	if rectChoiceHeuristic=="BestShortSideFit" then
		newNode,score1,score2 = FindPositionForNewNodeBestShortSideFit(width, height, freeRectangles)
	elseif rectChoiceHeuristic=="ContactPointRule" then
		newNode,score1 = FindPositionForNewNodeContactPoint(width, height, freeRectangles,usedRectangles,binWidth,binHeight); 
		score1 = -score1; --Reverse since we are minimizing, but for contact point score bigger is better.
		score2 = math.huge;
	elseif rectChoiceHeuristic=="RectBestAreaFit" then
		newNode,score1,score2 = FindPositionForNewNodeBestAreaFit(width, height, freeRectangles); 
	elseif rectChoiceHeuristic=="RectBottomLeftRule" then
		newNode,score1, score2 = FindPositionForNewNodeBottomLeft(width, height, freeRectangles);
	elseif rectChoiceHeuristic == "RectBestLongSideFit" then
		newNode,score1, score2 = FindPositionForNewNodeBestLongSideFit(width, height, freeRectangles);
	end
	
	--Cannot fit the current rectangle.
	if (newNode.height == 0) then
		score1 = math.huge
		score2 = math.huge
	end
	return newNode, score1,score2
end

local function SplitFreeNode(freeNode, usedNode,freeRectangles)
	local freeNode_upperBound = freeNode.y + freeNode.height
	local freeNode_sideBound = freeNode.x + freeNode.width
	local usedNode_upperBound = usedNode.y + usedNode.height
	local usedNode_sideBound = usedNode.x + usedNode.width
	-- Spring.Echo("ADD FREESPACE")
	--Test with SAT if the rectangles even intersect
	if (usedNode.x >= freeNode_sideBound or usedNode_sideBound <= freeNode.x or
	usedNode.y >= freeNode_upperBound or usedNode_upperBound <= freeNode.y) then
		-- Spring.Echo("NO SPACE")
		return freeRectangles, 0
	end
	local insertedNode,insertCount ={nil,nil,nil,nil},0
	if (usedNode.x < freeNode_sideBound and usedNode_sideBound > freeNode.x) then
		-- Spring.Echo("VERTICAL SPACE")
		--new node at the top side of the used node
		if (usedNode.y > freeNode.y and usedNode.y < freeNode_upperBound) then
			local newNode = CreateRect(freeNode.x,freeNode.y,freeNode.width,freeNode.height);
			newNode.height = usedNode.y - newNode.y
			-- Spring.Echo("INSERT TOP")
			insertCount = insertCount + 1
			insertedNode[insertCount] = newNode
		end
		-- New node at the bottom side of the used node.
		if (usedNode_upperBound < freeNode_upperBound) then
			local newNode = CreateRect(freeNode.x,freeNode.y,freeNode.width,freeNode.height);
			newNode.y = usedNode_upperBound;
			newNode.height = freeNode_upperBound - (usedNode_upperBound);
			-- Spring.Echo("INSERT BOTTOM")
			insertCount = insertCount + 1
			insertedNode[insertCount] = newNode
		end	
	end	
	if (usedNode.y < freeNode_upperBound and usedNode_upperBound > freeNode.y) then
		-- Spring.Echo("HORIZONTAL SPACE")
		--New node at the left side of the used node.
		if (usedNode.x > freeNode.x and usedNode.x < freeNode_sideBound) then
			local newNode = CreateRect(freeNode.x,freeNode.y,freeNode.width,freeNode.height);
			newNode.width = usedNode.x - newNode.x;
			-- Spring.Echo("INSERT LEFT")
			insertCount = insertCount + 1
			insertedNode[insertCount] = newNode
		end

		--New node at the right side of the used node.
		if (usedNode_sideBound < freeNode_sideBound) then
			local newNode = CreateRect(freeNode.x,freeNode.y,freeNode.width,freeNode.height);
			newNode.x = usedNode_sideBound;
			newNode.width = freeNode_sideBound - (usedNode_sideBound);
			-- Spring.Echo("INSERT RIGHT")
			insertCount = insertCount + 1
			insertedNode[insertCount] = newNode
		end
	end
	for i=1,#insertedNode,1 do
		table.insert(freeRectangles,1,insertedNode[i])
	end
	return freeRectangles, insertCount
end

local function IsContainedIn(a,b)
	return a.x >= b.x and a.y >= b.y 
		and a.x+a.width <= b.x+b.width 
		and a.y+a.height <= b.y+b.height;
end

local function PruneFreeList(freeRectangles)
	--Go through each pair and remove any rectangle that is redundant.
	local i = 1
	while(i <= #freeRectangles) do
		local j = i+1
		while(j<= #freeRectangles) do
			if (IsContainedIn(freeRectangles[i], freeRectangles[j])) then
				table.remove(freeRectangles,i);
				i =i-1;
				break;
			end
			if (IsContainedIn(freeRectangles[j], freeRectangles[i])) then
				table.remove(freeRectangles,j);
				j=j-1;
			end
			j=j+1;
		end
		i = i + 1
	end
	return freeRectangles
end
--Note: there's difference in this function compared to original,see if can share with author
local function PlaceRect(node,freeRectangles,usedRectangles)
	local numRectanglesToProcess = #freeRectangles
	local i = 1
	while(i<=numRectanglesToProcess)do
		local freeNodeSplited = 0
		freeRectangles, freeNodeSplited = SplitFreeNode(freeRectangles[i],node,freeRectangles)
		if (freeNodeSplited>0) then
			table.remove(freeRectangles,i+freeNodeSplited)
			i=i-1
			numRectanglesToProcess=numRectanglesToProcess-1 + freeNodeSplited
		end
		i = i + 1 + freeNodeSplited
	end
	freeRectangles = PruneFreeList(freeRectangles)
	table.insert(usedRectangles,1, node)
	return freeRectangles,usedRectangles
end

function PackMaxRectangleNow(rectList,binWidth, binHeight, heuristicChoice)
	local rect_n = CreateRect(0,0,binWidth,binHeight)
	local usedRectangles ={}
	local freeRectangles ={rect_n}
	while (#rectList > 0) do
		local bestScore1 = math.huge
		local bestScore2 = math.huge
		local bestRectIndex = -1
		local bestNode = CreateRect()
		
		for i=1,#rectList,1 do
			local newNode,score1,score2 = ScoreRect(rectList[i].width,rectList[i].height,heuristicChoice,freeRectangles,usedRectangles,binWidth,binHeight)
				
			if(score1 < bestScore1 or (score1==bestScore1 and score2 < bestScore2)) then
				bestScore1 = score1
				bestScore2 = score2
				bestNode = newNode
				bestNode.name = rectList[i].name
				bestNode.object = rectList[i].object
				bestRectIndex = i
			end
		end
	
		if (bestRectIndex == -1) then
			return usedRectangles
		end
		freeRectangles,usedRectangles = PlaceRect(bestNode,freeRectangles,usedRectangles)
		table.remove(rectList,bestRectIndex)
	end
	return usedRectangles
end
------------------------------------------------------------------------'
function widget:Initialize()
	if (not WG.Chili) then
		widgetHandler:RemoveWidget()
		return
	end
end 