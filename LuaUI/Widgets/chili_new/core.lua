local includes = {
  --"headers/autolocalizer.lua",
  "headers/util.lua",
  "headers/links.lua",
  "headers/backwardcompability.lua",
  "headers/unicode.lua",

  "handlers/debughandler.lua",
  "handlers/taskhandler.lua",
  "handlers/skinhandler.lua",
  "handlers/themehandler.lua",
  "handlers/fonthandler.lua",
  "handlers/texturehandler.lua",

  "controls/object.lua",
  "controls/font.lua",
  "controls/control.lua",
  "controls/screen.lua",
  "controls/window.lua",
  "controls/label.lua",
  "controls/button.lua",
  "controls/textbox.lua",
  "controls/checkbox.lua",
  "controls/trackbar.lua",
  "controls/colorbars.lua",
  "controls/scrollpanel.lua",
  "controls/image.lua",
  "controls/textbox.lua",
  "controls/layoutpanel.lua",
  "controls/grid.lua",
  "controls/stackpanel.lua",
  "controls/imagelistview.lua",
  "controls/progressbar.lua",
  "controls/multiprogressbar.lua",
  "controls/scale.lua",
  "controls/panel.lua",
  "controls/treeviewnode.lua",
  "controls/treeview.lua",
  "controls/editbox.lua",
  "controls/line.lua",
  "controls/combobox.lua",
  "controls/tabbaritem.lua",
  "controls/tabbar.lua",
  "controls/tabpanel.lua",
}

local Chili = widget

Chili.CHILI_DIRNAME = CHILI_DIRNAME or (LUAUI_DIRNAME .. "Widgets/chili/")
Chili.SKIN_DIRNAME  =  SKIN_DIRNAME or (CHILI_DIRNAME .. "skins/")

if (-1>0) then
  Chili = {}
  -- make the table strict
  VFS.Include(Chili.CHILI_DIRNAME .. "headers/strict.lua")(Chili, widget)
end

for _, file in ipairs(includes) do
  VFS.Include(Chili.CHILI_DIRNAME .. file, Chili, VFS.RAW_FIRST)
end


return Chili
