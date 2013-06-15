--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "ChiliInspector",
    desc      = "",
    author    = "",
    date      = "2013",
    license   = "GPLv2",
    layer     = 3,
    enabled   = false  --  loaded by default?
  }
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local Chili
local window0
local tree0
local label0

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function GetBooleanStr(b)
	return (b and "true") or "false"
end

local function trace(children, node, level, max_level)
	if not node then return end
	if (level or 0) > (max_level or math.huge) then return end
	for i=1,#children do
		local obj = children[i]
		if obj and (obj.name ~= "wnd_inspector") then
			local caption = ("%s: %s (redrawn: %i/%i)"):format(obj.classname, obj.name, obj._redrawSelfCounter or 0, obj._redrawCounter or 0)
			local nodec = node:Add(caption)
			trace(obj.children, nodec, (level or 0) + 1, max_level)
		end
	end
end


local function traceLost(node)

	for i,obj in pairs(Chili.DebugHandler.allObjects) do
		if obj.name ~= "wnd_inspector" then
			if (not obj.parent)and(not obj:InheritsFrom("screen")) then
				local caption = ("%s: %s (redrawn: %i; disposed: %s)"):format(obj.classname, obj.name, obj._redrawCounter or 0, GetBooleanStr(obj.disposed))
				local nodec = node:Add(caption)
				trace(obj.children, nodec, 1, 1)
			end
		end
	end
end


local function tracePerWidget(node)
	collectgarbage("collect")
	for w,t in pairs(Chili.DebugHandler.objectsOwnedByWidgets) do
		if (w.whInfo.name ~= widget.whInfo.name) then
			local caption = ("%s"):format(w.whInfo.name)
			local nodec = node:Add(caption)
			for i,obj in pairs(t) do
				local caption = ("%s: %s (redrawn: %i)"):format(obj.classname, obj.name, obj._redrawCounter or 0)
				local nodec2 = nodec:Add(caption)
			end
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Initialize()
	Chili = WG.Chili

	if (not Chili) then
		widgetHandler:RemoveWidget()
		return
	end

	window0 = Chili.Window:New{
		name = "wnd_inspector",
		caption = "Chili Inspector",
		x = 1200,
		y = 250,
		width  = 400,
		height = 400,
		parent = Chili.Screen0,

		children = {
			Chili.Label:New{
				name = "lbl_inspector_memusage",
				x=0, right = 50,
				y=0, bottom=-25,
				align = "right", valign = "bottom",
				caption = "Lua MemUsage: 0MB",
				
			},
			Chili.Button:New{
				right = 0, width = 50,
				y=5, bottom=-25,
				caption="gc",
				OnMouseUp = {function() collectgarbage("collect") end},
			},
			Chili.ScrollPanel:New{
				x=0, right=0,
				y=25, bottom=20,
				children = {
					Chili.TreeView:New{
						name = "tree_inspector";
						width="100%";
						height="100%";
					},
				},
			},
			Chili.StackPanel:New{
				x=0, right=0,
				y=-20, bottom=0,
				orientation = "horizontal",
				padding     = {0,0,0,0},
				itemMargin  = {0,0,0,0},
				itemPadding = {0,0,0,0},
				children = {
					Chili.Button:New{
						caption="visible objects",
						OnMouseUp = {function() tree0.root:Clear(); trace(Chili.Screen0.children, tree0.root) end},
					},
					Chili.Button:New{
						caption="lost objects",
						OnMouseUp = {function() tree0.root:Clear(); traceLost(tree0.root) end},
					},
					Chili.Button:New{
						caption="per widget",
						OnMouseUp = {function() tree0.root:Clear(); tracePerWidget(tree0.root) end},
					},
				},
			},
		},
	}

	tree0 = window0:GetObjectByName("tree_inspector")
	label0 = window0:GetObjectByName("lbl_inspector_memusage")

	trace(Chili.Screen0.children, tree0.root)
end

function widget:Shutdown()
	if (window0) then
		window0:Dispose()
	end
end

local next = -math.huge
function widget:Update()
	if (os.clock() <= next) then
		return
	end
	next = os.clock() + 3

	local curUsage, gcLimit = gcinfo()
	local caption = ("Lua MemUsage: %.2fMB"):format(curUsage / 1024)
	label0:SetCaption(caption)
end
