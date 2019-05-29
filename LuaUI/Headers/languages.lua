local langs = {
	{ lang = 'en', flag = 'gb', name = 'English' },
	{ lang = 'ru', flag = 'ru', name = 'Русский' },
	{ lang = 'pl', flag = 'pl', name = 'Polski' },
	{ lang = 'de', flag = 'de', name = 'Deutsch' },
	{ lang = 'tr', flag = 'tr', name = 'Türkçe' },
}

--[[ On Windows, far eastern fonts are börkçe by default, and
for them to work the engine needs to have been run with
the `--gen-fontconfig` CLI param at least once. This is
the job for Chobby who should run a parallel instance to
do just that (ideally detecting whether the user's system
language requires it by default) and leave information
about it. ]]
if Platform.osFamily ~= "Windows" or VFS.FileExists("LuaUI/font_config_generated", VFS.RAW) then
	langs[#langs + 1] = { lang = 'zh', flag = 'cn', name = '中文' }
end

local flagByLang, langByFlag = {}, {}
for i = 1, #langs do
	local x = langs[i]
	flagByLang[x.lang] = x.flag
	langByFlag[x.flag] = x.lang
end

setmetatable(langByFlag, { __index = function()
	return 'en'
end})

return langs, flagByLang, langByFlag
	
