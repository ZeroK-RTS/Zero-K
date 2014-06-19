--//=============================================================================

--- TabPanel module

--- TabPanel fields.
-- Inherits from LayoutPanel.
-- @see layoutpanel.LayoutPanel
-- @table TabPanel
-- @tparam {tab1,tab2,...} tabs contained in the tab panel, each tab has a .name (string) and a .children field (table of Controls)(default {})
-- @tparam chili.Control currentTab currently visible tab
TabPanel = LayoutPanel:Inherit{
  classname = "tabpanel",
  orientation = "vertical",
  resizeItems = false,
  itemPadding = {0, 0, 0, 0},
  itemMargin  = {0, 0, 0, 0},
  barHeight = 40,
  tabs = {},
  currentTab = {},
}

local this = TabPanel
local inherited = this.inherited

--//=============================================================================

function TabPanel:New(obj)
	obj = inherited.New(self,obj)
	
	local tabNames = {}
	for i=1,#obj.tabs do
		tabNames[i] = obj.tabs[i].name
	end
	obj:AddChild(
		TabBar:New {
			tabs = tabNames,
			x = 0,
			y = 0,
			right = 0,
			height = obj.barHeight,
		}
	)
  
	obj.currentTab = Control:New {
		x = 0,
		y = obj.barHeight,
		right = 0,
		bottom = 0,
		--width = "100%",
		--height = "100%",
		padding = {0, 0, 0, 0},
	}
	obj:AddChild(obj.currentTab)
	obj.tabIndexMapping = {}
	for i=1, #obj.tabs do
		local tabName = obj.tabs[i].name	
		local tabFrame = Control:New {
			padding = {0, 0, 0, 0},
			x = 0,
			y = 0,
			right = 0,
			bottom = 0,
			children = obj.tabs[i].children
		}
		obj.tabIndexMapping[tabName] = tabFrame
		obj.currentTab:AddChild(tabFrame)
		if i == 1 then
			obj.currentFrame = tabFrame
		else
			tabFrame:SetVisibility(false)
		end
	end
	obj.children[1].OnChange = { function(tabbar, tabname) obj:ChangeTab(tabname) end }
	return obj
end

--//=============================================================================

function TabPanel:ChangeTab(tabname)
	if not tabname or not self.tabIndexMapping[tabname] then
		return
	end
	self.currentFrame:SetVisibility(false)
	self.currentFrame = self.tabIndexMapping[tabname]
	self.currentFrame:SetVisibility(true)
end
--//=============================================================================
