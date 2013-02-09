--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "chiliGUIDemo",
    desc      = "GUI demo for robocracy",
    author    = "quantum",
    date      = "WIP",
    license   = "WIP",
    layer     = 1,
    enabled   = false  --  loaded by default?
  }
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- gui elements
local window0
local window01
local gridWindow0
local gridWindow1
local windowImageList
local window1
local window2
local window3

function widget:Initialize()
	Chili = WG.Chili

	local function ToggleOrientation(self)
		local panel = self:FindParent"layoutpanel"
		panel.orientation = ((panel.orientation == "horizontal") and "vertical") or "horizontal"
		panel:UpdateClientArea()
	end

	--------------------------------------------------------------------------------
	--------------------------------------------------------------------------------

	local testText =
	[[Bolivians are voting in a referendum on a new constitution that President Evo Morales says will empower the country's indigenous majority.

The changes also include strengthening state control of Bolivia's natural resources, and no longer recognising Catholicism as the official religion.

The constitution is widely expected to be approved.
Mr Morales, an Aymara Indian, has pursued political reform but has met fierce resistance from some sectors.
Opponents concentrated in Bolivia's eastern provinces, which hold rich gas deposits, argue that the new constitution would create two classes of citizenship - putting indigenous people ahead of others.

The wrangling has spilled over into, at times, deadly violence. At least 30 peasant farmers were ambushed and killed on their way home from a pro-government rally in a northern region in September.

President Morales has said the new constitution will pave the way for correcting the historic inequalities of Bolivian society, where the economic elite is largely of European descent.
]]

	local testText2 = 
	"\255\001\255\250Bolivians\b are voting in a referendum on a \255\255\255\000new\b constitution "

	local testText3 = 
	[[Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod]]

	--------------------------------------------------------------------------------
	--------------------------------------------------------------------------------

	local cs = {
		Chili.Button:New{
			x      = 20,
			y      = 20,
		},
		Chili.Label:New{
			x      = 20,
			y      = 50,
			caption= 'FOOBAR',
		},
		Chili.ScrollPanel:New{
			backgroundColor = {0,0,0,0.5},
			children = {
				Chili.Button:New{caption="foo", width = 100, height = 100},
			}
		},
		Chili.Checkbox:New{
			x     = 20,
			y     = 70,
			caption = 'foo',
		},
		Chili.Trackbar:New{
			x     = 20,
			y     = 90,
		},
		Chili.Colorbars:New{
			x     = 20,
			y     = 120,
		},
		Chili.ComboBox:New{items = { "opt1", "opt2", "opt3", "opt4", "opt5", "opt6", "opt7", "opt8", "opt9", "opt10", "opt11", "opt12", }},
	}

	window0 = Chili.Window:New{
		x = 200,
		y = 450,
		width  = 200,
		height = 200,
		parent = Chili.Screen0,

		children = {
			Chili.StackPanel:New{
				height = "100%";
				width  = "100%";
				weightedResize = true;
				children = {
					Chili.Button:New{caption="height: 70%", weight = 7; width = "90%"},
					Chili.Button:New{caption="height: 30%", weight = 3},
				};
			}
		},
	}

	local btn0 = Chili.Button:New{
		caption = "Dispose Me",
		name = "btn_dispose_me1",
	}
	btn0:Dispose()

	-- we need a container that supports margin if the control inside uses margins
	window01 = Chili.Window:New{
		x = 200,
		y = 200,
		clientWidth  = 200,
		clientHeight = 200,
		parent = Chili.Screen0,
	}

	local panel1 = Chili.StackPanel:New{
		width = 200,
		height = 200,
		--resizeItems = false,
		x=0, right=0,
		y=0, bottom=0,
		margin = {10, 10, 10, 10},
		parent = window01,
		children = cs,
	}

	local gridControl = Chili.Grid:New{
		name = 'foogrid',
		width = 200,
		height = 200,
		children = {
			Chili.Button:New{backgroundColor = {0,0.6,0,1}, textColor = {1,1,1,1}, caption = "Toggle", OnMouseUp = {ToggleOrientation}},
			Chili.Button:New{caption = "2"},
			Chili.Button:New{caption = "3"},
			Chili.Button:New{caption = "4", margin = {10, 10, 10, 10}},
			Chili.Button:New{caption = "5"},
			Chili.Button:New{caption = "6"},
			Chili.Button:New{caption = "7"},
		}
	}

	gridWindow0 = Chili.Window:New{
		parent = Chili.Screen0,
		x = 450,
		y = 450,
		clientWidth = 200,
		clientHeight = 200,
		children = {
			gridControl
		},
	}

	gridWindow1 = Chili.Window:New{
		parent = Chili.Screen0,
		x = 650,
		y = 750,
		clientWidth = 200,
		clientHeight = 200,
		children = {
			Chili.Button:New{right=0, bottom=0, caption = "2", OnClick={function()
				--gridWindow1:GetObjectByName("tree_inspector")
			end}},
			Chili.TextBox:New{x=0, right=0, y=0, text = testText2},
			Chili.EditBox:New{width = 200, y = 40, --[[autosize = true,]] text = testText3},
			Chili.ComboBox:New{right = 10, x = 0, y = 90, items = { "opt1", "opt2", "opt3", "opt4", "opt5", "opt6", "opt7", "opt8", "opt9", "opt10", "opt11", "opt12", }},
			Chili.Button:New{
				caption = "Dispose Me",
				name = "btn_dispose_me2",
				x="5%", y=70,
				width = "90%",
				OnClick = {function(self) self:Dispose() end},
			},
			Chili.Button:New{
				caption = "Dispose Me",
				name = "btn_dispose_me3",
				x="5%", y=90,
				width = "90%",
			},
			Chili.Button:New{
				caption = "Dispose Me",
				name = "btn_dispose_me4",
				x=0, y=120,
			},
		},
	}
	gridWindow1:GetObjectByName("btn_dispose_me4"):Dispose()

	--------------------------------------------------------------------------------
	--------------------------------------------------------------------------------

	windowImageList = Chili.Window:New{
		x = 700,
		y = 200,
		clientWidth = 410,
		clientHeight = 400,
		parent = Chili.Screen0,
	}

	local control = Chili.ScrollPanel:New{
		x=0, right=0,
		y=0, bottom=0,
		parent = windowImageList,
		children = {
			--Button:New{width = 410, height = 400, anchors = {top=true,left=true,bottom=true,right=true}},
			Chili.ImageListView:New{
				name = "MyImageListView",
				x=0, right=0,
				y=0, bottom=0,
				dir = "LuaUI/Images/",
				OnSelectItem = {
					function(obj,itemIdx,selected)
						Spring.Echo("image selected ",itemIdx,selected)
					end,
				},
				OnDblClickItem = {
					function(obj,itemIdx)
						Spring.Echo("image dblclicked ",itemIdx)
					end,
				},
				OnDirChange = {
					function(obj,itemIdx)
						if obj.parent and obj.parent:InheritsFrom("scrollpanel") then
							obj.parent:SetScrollPos(0,0)
						end
					end,
				}
			}
		}
	}


	--------------------------------------------------------------------------------
	--------------------------------------------------------------------------------

	window1 = Chili.Window:New{
		x = 450,  
		y = 200,  
		clientWidth  = 200,
		clientHeight = 200,
		resizable = true,
		draggable = true,
		parent = Chili.Screen0,
		dockable = true,
		children = {
		Chili.ScrollPanel:New{
			width = 200,
			height = 200,
			x=0, right=0,
			y=0, bottom=0,
			horizontalScrollbar = false,
			children = {
					Chili.TextBox:New{width = 200, x=0, right=0, y=0, bottom=0, text = testText}
				},
			},
		}
	}

	window2 = Chili.Window:New{
		x = 900,
		y = 650,
		width  = 200,
		height = 200,
		parent = Chili.Screen0,
		dockable = true,

		children = {
			Chili.TabBar:New{
				x=0, right=0,
				y=0, height=20,
				minItemWidth = 50,
				tabs = {"tab1", "tab2", "tab3",},
			},
			Chili.ScrollPanel:New{
				x=0, right=0,
				y=30, bottom=0,
				children = {
					Chili.TreeView:New{
						x=0, right=0,
						y=0, bottom=0,
						defaultExpanded = true,
						nodes = {
							"foo",
							{ "bar" },
							"do",
							{ "re", {"mi"} },
							"la",
							{ "le", "lu" },
						},
					},
				},
			},
		},
	}

	local warnDispose = function(self)
		local ref = 0
		for i,v in pairs(self._hlinks) do
			ref = ref + 1
		end
		Spring.Echo("Warning object disposed!", self.classname, self.name, ref)
	end

	window3 = Chili.Window:New{
		caption = "autosize test",
		x = 1200,
		y = 650,
		width  = 200,
		height = 200,
		parent = Chili.Screen0,
		autosize = true,
		savespace = true,
		--debug = true,

		children = {
			Chili.Button:New{name = "btn_0", y = 20, width = 120, caption = "dispose btns below", OnClick = {function(self)
				local btna = window3:GetObjectByName("btn_a");
				local btnb = window3:GetObjectByName("btn_b");
				window3:RemoveChild(btna);
				window3:RemoveChild(btnb);
			end}},
			Chili.Button:New{name = "btn_a", y = 50, width = 120, caption = "autosize", OnDispose = {warnDispose}, OnClick = {function(self) window3:GetObjectByName("btn_a"):ToggleVisibility(); window3:GetObjectByName("btn_b"):ToggleVisibility(); end}},
			Chili.Button:New{name = "btn_b", y = 80, width = 120, caption = "autosize", OnDispose = {warnDispose}, OnClick = {function(self) window3:GetObjectByName("btn_a"):ToggleVisibility(); window3:GetObjectByName("btn_b"):ToggleVisibility(); end}},
		},
	}

	window3:GetObjectByName("btn_b"):Hide()
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
end --Initialize


function widget:Update()
	local btn = gridWindow1:GetObjectByName("btn_dispose_me3")
	btn:Dispose()
	widgetHandler:RemoveCallIn("Update")
end


function widget:Shutdown()
	window0:Dispose()
	window01:Dispose()
	gridWindow0:Dispose()
	gridWindow1:Dispose()
	windowImageList:Dispose()
	window1:Dispose()
	window2:Dispose()
	window3:Dispose()
end

