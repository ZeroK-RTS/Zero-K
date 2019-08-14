--
-- This table translates keysysms keys to chars
--

local transkey = {
	backquote 		= '`',
	
	leftbracket 	= '[',
	rightbracket 	= ']',
	--delete 			= 'del',
	comma 			= ',',
	period 			= '.',
	slash 			= '/',
	backslash 			= '\\',
	equals 			= '=',
	
	colon 			= ':',
	semicolon 		= ';',
	
	quote 			= "'",
	
	kp_multiply		= 'numpad*',
	kp_divide		= 'numpad/',
	kp_plus			= 'numpad+',
	kp_minus		= 'numpad-',
	kp_period		= 'numpad.',
	
	kp0				= 'numpad0',
	kp1				= 'numpad1',
	kp2				= 'numpad2',
	kp3				= 'numpad3',
	kp4				= 'numpad4',
	kp5				= 'numpad5',
	kp6				= 'numpad6',
	kp7				= 'numpad7',
	kp8				= 'numpad8',
	kp9				= 'numpad9',
	
	lshift = 'shift',
	rshift = 'shift',
	lctrl = 'ctrl',
	rctrl = 'ctrl',
	lalt = 'alt',
	ralt = 'alt',

    -- for french keyboard
	--groupping
		ampersand               = '&',
		world_73                = '0x0e9',
		quotedbl                = '"',
		leftparen               = '(',
		minus                   = '-',
		world_72                = '0x0e8',
		underscore              = '_',
		world_71                = '0x0e7',
		world_64                = '0x0e0',
	
	--other
		leftparen               = ')',
		world_89				= '0x0f9',
		dollar					= '$',
		asterisk                = '*',


}
return transkey
