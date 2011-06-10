
--- unit classes ---
local unitClasses = {
	Mex	= { 'cormex' },
	Solar	= { 'armsolar' },
	LLT	= { 'corllt' },
	BotLab	= { 'factorycloak' },
	Radar	= { 'corrad' },

	Con	= { 'armrectr' },
	Raider	= { 'armpw' },
}
local unitClassNames = {
	Mex	= 'Mex',
	Solar	= 'Solar Collector',
	LLT	= 'LLT',
	BotLab	= 'Bot Lab',
	Radar	= 'Radar',

	Con	= 'Constructor',
	Raider	= 'Raider',
}

local mClasses = { Con=1, Raider=1, }

-- generic sub states
local steps = {	
	intro = {
		--message		= 'Hello! I am Nubtron, the friendly robot. I will teach you how to play Complete Annihilation. <(Click here to continue)>',
		passIfAny	= { 'clickedNubtron', },
	},
	intro2 = {
		--message		= 'Just follow my instructions. You can drag this window around by my face. <(Click here to continue)>',
		passIfAny	= { 'clickedNubtron'},
	},
	intro3 = {
		--message		= 'Practice zooming the camera in and out with your mouse\'s scroll wheel <(Click here to continue)>',
		passIfAny	= { 'clickedNubtron' },
	},
	intro4 = {
		--message		= 'Practice panning the camera up, down, left and right with your arrow keys. <(Click here to continue)>',
		passIfAny	= { 'clickedNubtron' },
	},
	intro5 = {
		--message		= 'Place your starting position by clicking on a nice flat spot on the map, then click on the <Ready> button',
		passIfAny	= { 'gameStarted' },

	},
	selectComm = {
		--message		= 'Select only your commander by clicking on it or pressing <ctrl+c>.',
		passIfAny	= {'commSelected'}
	},
	showMetalMap = {
		--message		= 'View the metal map by pressing <F4>.',
		passIfAny	= { 'metalMapView' }
	},
	hideMetalMap = {
		--message		= 'Hide the metal map by pressing <F4>.',
		passIfAnyNot	= { 'metalMapView' }
	},

	selectBotLab = {
		--message		= 'Select only your Bot Lab by clicking on it (the blue circles will help you find it).',
		passIfAny	= { 'BotLabSelected' }
	},

	selectCon = {
		--message		= 'Select one constructor by clicking on it (the blue circles will help you find it).',
		--image		= { arm='unitpics/'.. unitClasses.Con[1] ..'.png', core='unitpics/'.. unitClasses.Con[2] ..'.png' },
		image		= unitClasses.Con[1] ..'.png',
		passIfAny	= { 'ConSelected' },
	},

	guardFac = {
		--message		= 'Have the constructor guard your Bot Lab by right clicking on the Lab. The constructor will assist it until you give it a different order.',
		errIfAnyNot	= { 'ConSelected' },
	},

	--[[
	rotate = {
		--message		= 'Try rotating.',
		errIfAnyNot	= { 'commSelected', 'BotLabBuildSelected' },
		passIfAny	= { 'clickedNubtron' }
	},
	--]]
	tutorialEnd = {
		--message		= 'This is the end of the tutorial. It is now safe to shut off Nubtron. Goodbye! (Click here to restart tutorial)',
		passIfAny	= {'clickedNubtron'}
	},
}

-- main states
local tasks = {
	
	{
		--desc		= 'Introduction',
		states		= {'intro', 'intro2', 'intro3', 'intro4', 'intro5', },
	},
	{
		--desc		= 'Restore your interface',
		states		= { 'hideMetalMap', },
	},
	{
		--desc		= 'Building a Metal Extractor (mex)',		
		--tip			= 'Metal extractors output metal which is the heart of your economy.',
		states		= { 'selectComm', 'showMetalMap', 'finishMex', 'selectBuildMex', 'startMex', 'buildMex', 'hideMetalMap' },
		passIfAll	= { 'haveMex',},
	},
	{
		--desc		= 'Building a Solar Collector',
		--tip			= 'Energy generating structures power your mexes and factories.',
		states		= { 'selectComm', 'finishSolar', 'selectBuildSolar', 'startSolar', 'buildSolar'},
		errIfAny	= { 'metalMapView' },
		errIfAnyNot	= { 'haveMex' },
		passIfAll	= { 'haveSolar',},
	},
	{
		--desc		= 'Building a Light Laser Tower (LLT)',
		states		= { 'selectComm', 'finishLLT', 'selectBuildLLT', 'startLLT', 'buildLLT' },
		errIfAny	= { 'metalMapView' },
		errIfAnyNot	= { 'haveMex', 'haveSolar' },
		passIfAll	= { 'haveLLT',},
	},
	{
		--desc		= 'Building another mex on a different metal spot.',
		---tip			= 'Always try to acquire more metal spots to build more mexes.',
		states		= { 'selectComm', 'showMetalMap', 'finishMex', 'selectBuildMex', 'startMex', 'buildMex', 'hideMetalMap'},
		errIfAnyNot	= { 'haveMex', 'haveSolar' },
		passIfAnyNot	= { 'lowMetalIncome', },
	},
	{
		--desc		= 'Building another Solar Collector',
		--tip			= 'Always try and build more energy structures to keep your economy growing.',
		states		= { 'selectComm', 'finishSolar', 'selectBuildSolar', 'startSolar', 'buildSolar', },
		errIfAny	= { 'metalMapView', },
		errIfAnyNot	= { 'haveMex', 'haveSolar' },
		passIfAnyNot	= { 'lowEnergyIncome', }
	},
	{
		--desc		= 'Building a Factory',
		states		= { 'selectComm', 'finishBotLab', 'selectBuildBotLab', 'startBotLab', 'buildBotLab' },
		errIfAny	= { 'metalMapView', 'lowMetalIncome', 'lowEnergyIncome', },
		errIfAnyNot	= { 'haveMex', 'haveSolar', 'haveLLT' },
		passIfAll	= { 'haveBotLab',},
	},
	{
		--desc		= 'Building a Radar',
		--tip			= 'Radar coverage shows you distant enemy units as blips.',
		states		= { 'selectComm', 'finishRadar', 'selectBuildRadar', 'startRadar', 'buildRadar' },
		errIfAny	= { 'metalMapView', 'lowMetalIncome', 'lowEnergyIncome', },
		errIfAnyNot	= { 'haveMex', 'haveSolar', 'haveLLT', 'haveBotLab' },
		passIfAll	= { 'haveRadar',},
	},
	{
		--desc		= 'Building a Constructor',
		--tip			= 'Just like your Commander, Constructors build (and assist building of) structures.',
		states		= { 'selectBotLab', 'selectBuildCon', 'buildCon' },
		errIfAny	= { 'metalMapView', 'lowMetalIncome', 'lowEnergyIncome', },
		errIfAnyNot	= { 'haveMex', 'haveSolar', 'haveLLT', 'haveBotLab', 'haveRadar' },
		passIfAll	= { 'haveCon',},
	},
	{
		--desc		= 'Using a constructor to assist your factory',
		--tip			= 'Factories that are assisted by constructors build faster.',
		states		= { 'selectCon', 'guardFac', },
		errIfAny	= { 'metalMapView', 'lowMetalIncome', 'lowEnergyIncome', },
		errIfAnyNot	= { 'haveMex', 'haveSolar', 'haveLLT', 'haveBotLab', 'haveRadar', 'haveCon' },
		passIfAll	= { 'guardFac',},
	},
	{
		--desc		= 'Building Raider Bots in your factory.',
		--tip			= 'Combat units are used to attack your enemies and make them suffer.',
		states		= { 'selectBotLab', 'selectBuildRaider', 'buildRaider', },
		errIfAny	= { 'metalMapView', 'lowMetalIncome', 'lowEnergyIncome', },
		errIfAnyNot	= { 'haveMex', 'haveSolar', 'haveLLT', 'haveBotLab', 'haveRadar', 'haveCon', 'guardFac' },
		passIfAll	= { 'haveRaider',},
	},
	{
		--desc		= 'Congratulations!',
		errIfAny	= { 'metalMapView' },
		states		= { 'tutorialEnd'},
	},
}


return unitClasses, unitClassNames, mClasses, steps, tasks