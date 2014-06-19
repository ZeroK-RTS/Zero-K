-- $Id: KOMTXT___16.lua 3171 2008-11-06 09:06:29Z det $

local fontSpecs = {
  srcFile  = [[KOMTXT__.ttf]],
  family   = [[Komika Text]],
  style    = [[Regular]],
  yStep    = 20,
  height   = 16,
  xTexSize = 512,
  yTexSize = 256,
  outlineRadius = 2,
  outlineWeight = 100,
}

local glyphs = {}

glyphs[32] = { --' '--
  num = 32,
  adv = 4,
  oxn =   -2, oyn =   -3, oxp =    3, oyp =    2,
  txn =    1, tyn =    1, txp =    6, typ =    6,
}
glyphs[33] = { --'!'--
  num = 33,
  adv = 4,
  oxn =   -2, oyn =   -3, oxp =    6, oyp =   13,
  txn =   25, tyn =    1, txp =   33, typ =   17,
}
glyphs[34] = { --'"'--
  num = 34,
  adv = 6,
  oxn =   -2, oyn =    4, oxp =    8, oyp =   14,
  txn =   49, tyn =    1, txp =   59, typ =   11,
}
glyphs[35] = { --'#'--
  num = 35,
  adv = 11,
  oxn =   -1, oyn =   -3, oxp =   13, oyp =   13,
  txn =   73, tyn =    1, txp =   87, typ =   17,
}
glyphs[36] = { --'$'--
  num = 36,
  adv = 8,
  oxn =   -2, oyn =   -4, oxp =   10, oyp =   14,
  txn =   97, tyn =    1, txp =  109, typ =   19,
}
glyphs[37] = { --'%'--
  num = 37,
  adv = 11,
  oxn =   -1, oyn =   -3, oxp =   13, oyp =   13,
  txn =  121, tyn =    1, txp =  135, typ =   17,
}
glyphs[38] = { --'&'--
  num = 38,
  adv = 10,
  oxn =   -2, oyn =   -3, oxp =   12, oyp =   13,
  txn =  145, tyn =    1, txp =  159, typ =   17,
}
glyphs[39] = { --'''--
  num = 39,
  adv = 3,
  oxn =   -2, oyn =    4, oxp =    5, oyp =   14,
  txn =  169, tyn =    1, txp =  176, typ =   11,
}
glyphs[40] = { --'('--
  num = 40,
  adv = 6,
  oxn =   -1, oyn =   -4, oxp =    9, oyp =   16,
  txn =  193, tyn =    1, txp =  203, typ =   21,
}
glyphs[41] = { --')'--
  num = 41,
  adv = 6,
  oxn =   -1, oyn =   -4, oxp =    8, oyp =   16,
  txn =  217, tyn =    1, txp =  226, typ =   21,
}
glyphs[42] = { --'*'--
  num = 42,
  adv = 9,
  oxn =   -2, oyn =    2, oxp =   11, oyp =   16,
  txn =  241, tyn =    1, txp =  254, typ =   15,
}
glyphs[43] = { --'+'--
  num = 43,
  adv = 9,
  oxn =   -2, oyn =   -3, oxp =   11, oyp =   10,
  txn =  265, tyn =    1, txp =  278, typ =   14,
}
glyphs[44] = { --','--
  num = 44,
  adv = 3,
  oxn =   -2, oyn =   -4, oxp =    5, oyp =    4,
  txn =  289, tyn =    1, txp =  296, typ =    9,
}
glyphs[45] = { --'-'--
  num = 45,
  adv = 6,
  oxn =   -2, oyn =    1, oxp =    9, oyp =    8,
  txn =  313, tyn =    1, txp =  324, typ =    8,
}
glyphs[46] = { --'.'--
  num = 46,
  adv = 3,
  oxn =   -2, oyn =   -3, oxp =    5, oyp =    5,
  txn =  337, tyn =    1, txp =  344, typ =    9,
}
glyphs[47] = { --'/'--
  num = 47,
  adv = 6,
  oxn =   -2, oyn =   -3, oxp =    9, oyp =   13,
  txn =  361, tyn =    1, txp =  372, typ =   17,
}
glyphs[48] = { --'0'--
  num = 48,
  adv = 8,
  oxn =   -2, oyn =   -2, oxp =   10, oyp =   13,
  txn =  385, tyn =    1, txp =  397, typ =   16,
}
glyphs[49] = { --'1'--
  num = 49,
  adv = 4,
  oxn =   -2, oyn =   -2, oxp =    6, oyp =   13,
  txn =  409, tyn =    1, txp =  417, typ =   16,
}
glyphs[50] = { --'2'--
  num = 50,
  adv = 8,
  oxn =   -3, oyn =   -2, oxp =   10, oyp =   13,
  txn =  433, tyn =    1, txp =  446, typ =   16,
}
glyphs[51] = { --'3'--
  num = 51,
  adv = 8,
  oxn =   -3, oyn =   -2, oxp =   11, oyp =   13,
  txn =  457, tyn =    1, txp =  471, typ =   16,
}
glyphs[52] = { --'4'--
  num = 52,
  adv = 10,
  oxn =   -2, oyn =   -2, oxp =   12, oyp =   13,
  txn =  481, tyn =    1, txp =  495, typ =   16,
}
glyphs[53] = { --'5'--
  num = 53,
  adv = 8,
  oxn =   -2, oyn =   -2, oxp =   10, oyp =   13,
  txn =    1, tyn =   24, txp =   13, typ =   39,
}
glyphs[54] = { --'6'--
  num = 54,
  adv = 9,
  oxn =   -2, oyn =   -2, oxp =   11, oyp =   13,
  txn =   25, tyn =   24, txp =   38, typ =   39,
}
glyphs[55] = { --'7'--
  num = 55,
  adv = 8,
  oxn =   -2, oyn =   -2, oxp =   10, oyp =   13,
  txn =   49, tyn =   24, txp =   61, typ =   39,
}
glyphs[56] = { --'8'--
  num = 56,
  adv = 8,
  oxn =   -2, oyn =   -2, oxp =   10, oyp =   13,
  txn =   73, tyn =   24, txp =   85, typ =   39,
}
glyphs[57] = { --'9'--
  num = 57,
  adv = 8,
  oxn =   -2, oyn =   -2, oxp =   11, oyp =   13,
  txn =   97, tyn =   24, txp =  110, typ =   39,
}
glyphs[58] = { --':'--
  num = 58,
  adv = 3,
  oxn =   -2, oyn =   -3, oxp =    6, oyp =    9,
  txn =  121, tyn =   24, txp =  129, typ =   36,
}
glyphs[59] = { --';'--
  num = 59,
  adv = 3,
  oxn =   -3, oyn =   -4, oxp =    6, oyp =    9,
  txn =  145, tyn =   24, txp =  154, typ =   37,
}
glyphs[60] = { --'<'--
  num = 60,
  adv = 8,
  oxn =   -1, oyn =   -3, oxp =   10, oyp =   10,
  txn =  169, tyn =   24, txp =  180, typ =   37,
}
glyphs[61] = { --'='--
  num = 61,
  adv = 9,
  oxn =   -1, oyn =    0, oxp =   11, oyp =   10,
  txn =  193, tyn =   24, txp =  205, typ =   34,
}
glyphs[62] = { --'>'--
  num = 62,
  adv = 8,
  oxn =   -1, oyn =   -3, oxp =   10, oyp =   10,
  txn =  217, tyn =   24, txp =  228, typ =   37,
}
glyphs[63] = { --'?'--
  num = 63,
  adv = 9,
  oxn =   -2, oyn =   -3, oxp =   10, oyp =   13,
  txn =  241, tyn =   24, txp =  253, typ =   40,
}
glyphs[64] = { --'@'--
  num = 64,
  adv = 13,
  oxn =   -2, oyn =   -3, oxp =   15, oyp =   13,
  txn =  265, tyn =   24, txp =  282, typ =   40,
}
glyphs[65] = { --'A'--
  num = 65,
  adv = 10,
  oxn =   -2, oyn =   -3, oxp =   12, oyp =   13,
  txn =  289, tyn =   24, txp =  303, typ =   40,
}
glyphs[66] = { --'B'--
  num = 66,
  adv = 10,
  oxn =   -1, oyn =   -3, oxp =   12, oyp =   13,
  txn =  313, tyn =   24, txp =  326, typ =   40,
}
glyphs[67] = { --'C'--
  num = 67,
  adv = 9,
  oxn =   -2, oyn =   -3, oxp =   12, oyp =   13,
  txn =  337, tyn =   24, txp =  351, typ =   40,
}
glyphs[68] = { --'D'--
  num = 68,
  adv = 10,
  oxn =   -1, oyn =   -3, oxp =   12, oyp =   13,
  txn =  361, tyn =   24, txp =  374, typ =   40,
}
glyphs[69] = { --'E'--
  num = 69,
  adv = 9,
  oxn =   -1, oyn =   -3, oxp =   11, oyp =   13,
  txn =  385, tyn =   24, txp =  397, typ =   40,
}
glyphs[70] = { --'F'--
  num = 70,
  adv = 8,
  oxn =   -2, oyn =   -3, oxp =   11, oyp =   13,
  txn =  409, tyn =   24, txp =  422, typ =   40,
}
glyphs[71] = { --'G'--
  num = 71,
  adv = 12,
  oxn =   -2, oyn =   -3, oxp =   14, oyp =   13,
  txn =  433, tyn =   24, txp =  449, typ =   40,
}
glyphs[72] = { --'H'--
  num = 72,
  adv = 10,
  oxn =   -2, oyn =   -3, oxp =   12, oyp =   14,
  txn =  457, tyn =   24, txp =  471, typ =   41,
}
glyphs[73] = { --'I'--
  num = 73,
  adv = 4,
  oxn =   -1, oyn =   -3, oxp =    6, oyp =   13,
  txn =  481, tyn =   24, txp =  488, typ =   40,
}
glyphs[74] = { --'J'--
  num = 74,
  adv = 8,
  oxn =   -2, oyn =   -3, oxp =   11, oyp =   13,
  txn =    1, tyn =   47, txp =   14, typ =   63,
}
glyphs[75] = { --'K'--
  num = 75,
  adv = 9,
  oxn =   -1, oyn =   -3, oxp =   11, oyp =   13,
  txn =   25, tyn =   47, txp =   37, typ =   63,
}
glyphs[76] = { --'L'--
  num = 76,
  adv = 7,
  oxn =   -1, oyn =   -3, oxp =   10, oyp =   13,
  txn =   49, tyn =   47, txp =   60, typ =   63,
}
glyphs[77] = { --'M'--
  num = 77,
  adv = 12,
  oxn =   -1, oyn =   -3, oxp =   15, oyp =   13,
  txn =   73, tyn =   47, txp =   89, typ =   63,
}
glyphs[78] = { --'N'--
  num = 78,
  adv = 10,
  oxn =   -2, oyn =   -3, oxp =   13, oyp =   13,
  txn =   97, tyn =   47, txp =  112, typ =   63,
}
glyphs[79] = { --'O'--
  num = 79,
  adv = 10,
  oxn =   -2, oyn =   -3, oxp =   13, oyp =   13,
  txn =  121, tyn =   47, txp =  136, typ =   63,
}
glyphs[80] = { --'P'--
  num = 80,
  adv = 9,
  oxn =   -1, oyn =   -3, oxp =   12, oyp =   13,
  txn =  145, tyn =   47, txp =  158, typ =   63,
}
glyphs[81] = { --'Q'--
  num = 81,
  adv = 11,
  oxn =   -2, oyn =   -3, oxp =   13, oyp =   13,
  txn =  169, tyn =   47, txp =  184, typ =   63,
}
glyphs[82] = { --'R'--
  num = 82,
  adv = 9,
  oxn =   -1, oyn =   -3, oxp =   12, oyp =   13,
  txn =  193, tyn =   47, txp =  206, typ =   63,
}
glyphs[83] = { --'S'--
  num = 83,
  adv = 10,
  oxn =   -2, oyn =   -3, oxp =   13, oyp =   13,
  txn =  217, tyn =   47, txp =  232, typ =   63,
}
glyphs[84] = { --'T'--
  num = 84,
  adv = 8,
  oxn =   -2, oyn =   -3, oxp =   12, oyp =   13,
  txn =  241, tyn =   47, txp =  255, typ =   63,
}
glyphs[85] = { --'U'--
  num = 85,
  adv = 10,
  oxn =   -1, oyn =   -3, oxp =   12, oyp =   13,
  txn =  265, tyn =   47, txp =  278, typ =   63,
}
glyphs[86] = { --'V'--
  num = 86,
  adv = 8,
  oxn =   -2, oyn =   -3, oxp =   12, oyp =   13,
  txn =  289, tyn =   47, txp =  303, typ =   63,
}
glyphs[87] = { --'W'--
  num = 87,
  adv = 12,
  oxn =   -2, oyn =   -3, oxp =   15, oyp =   13,
  txn =  313, tyn =   47, txp =  330, typ =   63,
}
glyphs[88] = { --'X'--
  num = 88,
  adv = 8,
  oxn =   -2, oyn =   -3, oxp =   11, oyp =   13,
  txn =  337, tyn =   47, txp =  350, typ =   63,
}
glyphs[89] = { --'Y'--
  num = 89,
  adv = 10,
  oxn =   -2, oyn =   -3, oxp =   13, oyp =   13,
  txn =  361, tyn =   47, txp =  376, typ =   63,
}
glyphs[90] = { --'Z'--
  num = 90,
  adv = 9,
  oxn =   -2, oyn =   -3, oxp =   12, oyp =   13,
  txn =  385, tyn =   47, txp =  399, typ =   63,
}
glyphs[91] = { --'['--
  num = 91,
  adv = 6,
  oxn =   -2, oyn =   -5, oxp =    9, oyp =   15,
  txn =  409, tyn =   47, txp =  420, typ =   67,
}
glyphs[92] = { --'\'--
  num = 92,
  adv = 7,
  oxn =   -1, oyn =   -3, oxp =    9, oyp =   14,
  txn =  433, tyn =   47, txp =  443, typ =   64,
}
glyphs[93] = { --']'--
  num = 93,
  adv = 6,
  oxn =   -1, oyn =   -5, oxp =    9, oyp =   15,
  txn =  457, tyn =   47, txp =  467, typ =   67,
}
glyphs[94] = { --'^'--
  num = 94,
  adv = 6,
  oxn =    1, oyn =    6, oxp =   11, oyp =   14,
  txn =  481, tyn =   47, txp =  491, typ =   55,
}
glyphs[95] = { --'_'--
  num = 95,
  adv = 8,
  oxn =   -3, oyn =   -4, oxp =   10, oyp =    2,
  txn =    1, tyn =   70, txp =   14, typ =   76,
}
glyphs[96] = { --'`'--
  num = 96,
  adv = 8,
  oxn =    0, oyn =    5, oxp =    9, oyp =   14,
  txn =   25, tyn =   70, txp =   34, typ =   79,
}
glyphs[97] = { --'a'--
  num = 97,
  adv = 8,
  oxn =   -2, oyn =   -3, oxp =   10, oyp =   10,
  txn =   49, tyn =   70, txp =   61, typ =   83,
}
glyphs[98] = { --'b'--
  num = 98,
  adv = 8,
  oxn =   -1, oyn =   -3, oxp =   11, oyp =   13,
  txn =   73, tyn =   70, txp =   85, typ =   86,
}
glyphs[99] = { --'c'--
  num = 99,
  adv = 7,
  oxn =   -2, oyn =   -3, oxp =   10, oyp =   10,
  txn =   97, tyn =   70, txp =  109, typ =   83,
}
glyphs[100] = { --'d'--
  num = 100,
  adv = 9,
  oxn =   -2, oyn =   -3, oxp =   11, oyp =   13,
  txn =  121, tyn =   70, txp =  134, typ =   86,
}
glyphs[101] = { --'e'--
  num = 101,
  adv = 8,
  oxn =   -2, oyn =   -3, oxp =   10, oyp =   10,
  txn =  145, tyn =   70, txp =  157, typ =   83,
}
glyphs[102] = { --'f'--
  num = 102,
  adv = 6,
  oxn =   -2, oyn =   -3, oxp =   10, oyp =   13,
  txn =  169, tyn =   70, txp =  181, typ =   86,
}
glyphs[103] = { --'g'--
  num = 103,
  adv = 8,
  oxn =   -2, oyn =   -6, oxp =   10, oyp =   10,
  txn =  193, tyn =   70, txp =  205, typ =   86,
}
glyphs[104] = { --'h'--
  num = 104,
  adv = 8,
  oxn =   -1, oyn =   -3, oxp =   10, oyp =   13,
  txn =  217, tyn =   70, txp =  228, typ =   86,
}
glyphs[105] = { --'i'--
  num = 105,
  adv = 4,
  oxn =   -1, oyn =   -3, oxp =    6, oyp =   13,
  txn =  241, tyn =   70, txp =  248, typ =   86,
}
glyphs[106] = { --'j'--
  num = 106,
  adv = 4,
  oxn =   -5, oyn =   -7, oxp =    6, oyp =   13,
  txn =  265, tyn =   70, txp =  276, typ =   90,
}
glyphs[107] = { --'k'--
  num = 107,
  adv = 7,
  oxn =   -1, oyn =   -3, oxp =   10, oyp =   13,
  txn =  289, tyn =   70, txp =  300, typ =   86,
}
glyphs[108] = { --'l'--
  num = 108,
  adv = 4,
  oxn =   -1, oyn =   -3, oxp =    6, oyp =   13,
  txn =  313, tyn =   70, txp =  320, typ =   86,
}
glyphs[109] = { --'m'--
  num = 109,
  adv = 12,
  oxn =   -1, oyn =   -3, oxp =   14, oyp =   10,
  txn =  337, tyn =   70, txp =  352, typ =   83,
}
glyphs[110] = { --'n'--
  num = 110,
  adv = 8,
  oxn =   -1, oyn =   -3, oxp =   10, oyp =   10,
  txn =  361, tyn =   70, txp =  372, typ =   83,
}
glyphs[111] = { --'o'--
  num = 111,
  adv = 8,
  oxn =   -2, oyn =   -3, oxp =   11, oyp =   10,
  txn =  385, tyn =   70, txp =  398, typ =   83,
}
glyphs[112] = { --'p'--
  num = 112,
  adv = 8,
  oxn =   -2, oyn =   -7, oxp =   11, oyp =   10,
  txn =  409, tyn =   70, txp =  422, typ =   87,
}
glyphs[113] = { --'q'--
  num = 113,
  adv = 9,
  oxn =   -2, oyn =   -7, oxp =   12, oyp =   10,
  txn =  433, tyn =   70, txp =  447, typ =   87,
}
glyphs[114] = { --'r'--
  num = 114,
  adv = 6,
  oxn =   -1, oyn =   -3, oxp =    9, oyp =   10,
  txn =  457, tyn =   70, txp =  467, typ =   83,
}
glyphs[115] = { --'s'--
  num = 115,
  adv = 8,
  oxn =   -2, oyn =   -3, oxp =   11, oyp =   10,
  txn =  481, tyn =   70, txp =  494, typ =   83,
}
glyphs[116] = { --'t'--
  num = 116,
  adv = 7,
  oxn =   -2, oyn =   -3, oxp =    9, oyp =   12,
  txn =    1, tyn =   93, txp =   12, typ =  108,
}
glyphs[117] = { --'u'--
  num = 117,
  adv = 8,
  oxn =   -1, oyn =   -3, oxp =   10, oyp =   10,
  txn =   25, tyn =   93, txp =   36, typ =  106,
}
glyphs[118] = { --'v'--
  num = 118,
  adv = 7,
  oxn =   -2, oyn =   -3, oxp =    9, oyp =   10,
  txn =   49, tyn =   93, txp =   60, typ =  106,
}
glyphs[119] = { --'w'--
  num = 119,
  adv = 10,
  oxn =   -2, oyn =   -3, oxp =   13, oyp =   10,
  txn =   73, tyn =   93, txp =   88, typ =  106,
}
glyphs[120] = { --'x'--
  num = 120,
  adv = 7,
  oxn =   -2, oyn =   -3, oxp =    9, oyp =   10,
  txn =   97, tyn =   93, txp =  108, typ =  106,
}
glyphs[121] = { --'y'--
  num = 121,
  adv = 7,
  oxn =   -2, oyn =   -6, oxp =   10, oyp =   10,
  txn =  121, tyn =   93, txp =  133, typ =  109,
}
glyphs[122] = { --'z'--
  num = 122,
  adv = 7,
  oxn =   -2, oyn =   -3, oxp =   10, oyp =   10,
  txn =  145, tyn =   93, txp =  157, typ =  106,
}
glyphs[123] = { --'{'--
  num = 123,
  adv = 8,
  oxn =   -1, oyn =   -5, oxp =   10, oyp =   15,
  txn =  169, tyn =   93, txp =  180, typ =  113,
}
glyphs[124] = { --'|'--
  num = 124,
  adv = 4,
  oxn =   -2, oyn =   -5, oxp =    6, oyp =   15,
  txn =  193, tyn =   93, txp =  201, typ =  113,
}
glyphs[125] = { --'}'--
  num = 125,
  adv = 8,
  oxn =   -1, oyn =   -5, oxp =   10, oyp =   16,
  txn =  217, tyn =   93, txp =  228, typ =  114,
}
glyphs[126] = { --'~'--
  num = 126,
  adv = 8,
  oxn =   -1, oyn =    6, oxp =   10, oyp =   13,
  txn =  241, tyn =   93, txp =  252, typ =  100,
}
glyphs[127] = { --''--
  num = 127,
  adv = 8,
  oxn =   -2, oyn =   -3, oxp =    3, oyp =    2,
  txn =  265, tyn =   93, txp =  270, typ =   98,
}
glyphs[128] = { --'Ä'--
  num = 128,
  adv = 8,
  oxn =   -2, oyn =   -3, oxp =    3, oyp =    2,
  txn =  289, tyn =   93, txp =  294, typ =   98,
}
glyphs[129] = { --'Å'--
  num = 129,
  adv = 8,
  oxn =   -2, oyn =   -3, oxp =    3, oyp =    2,
  txn =  313, tyn =   93, txp =  318, typ =   98,
}
glyphs[130] = { --'Ç'--
  num = 130,
  adv = 8,
  oxn =   -2, oyn =   -3, oxp =    3, oyp =    2,
  txn =  337, tyn =   93, txp =  342, typ =   98,
}
glyphs[131] = { --'É'--
  num = 131,
  adv = 8,
  oxn =   -2, oyn =   -3, oxp =    3, oyp =    2,
  txn =  361, tyn =   93, txp =  366, typ =   98,
}
glyphs[132] = { --'Ñ'--
  num = 132,
  adv = 8,
  oxn =   -2, oyn =   -3, oxp =    3, oyp =    2,
  txn =  385, tyn =   93, txp =  390, typ =   98,
}
glyphs[133] = { --'Ö'--
  num = 133,
  adv = 8,
  oxn =   -2, oyn =   -3, oxp =    3, oyp =    2,
  txn =  409, tyn =   93, txp =  414, typ =   98,
}
glyphs[134] = { --'Ü'--
  num = 134,
  adv = 8,
  oxn =   -2, oyn =   -3, oxp =    3, oyp =    2,
  txn =  433, tyn =   93, txp =  438, typ =   98,
}
glyphs[135] = { --'á'--
  num = 135,
  adv = 8,
  oxn =   -2, oyn =   -3, oxp =    3, oyp =    2,
  txn =  457, tyn =   93, txp =  462, typ =   98,
}
glyphs[136] = { --'à'--
  num = 136,
  adv = 8,
  oxn =   -2, oyn =   -3, oxp =    3, oyp =    2,
  txn =  481, tyn =   93, txp =  486, typ =   98,
}
glyphs[137] = { --'â'--
  num = 137,
  adv = 8,
  oxn =   -2, oyn =   -3, oxp =    3, oyp =    2,
  txn =    1, tyn =  116, txp =    6, typ =  121,
}
glyphs[138] = { --'ä'--
  num = 138,
  adv = 8,
  oxn =   -2, oyn =   -3, oxp =    3, oyp =    2,
  txn =   25, tyn =  116, txp =   30, typ =  121,
}
glyphs[139] = { --'ã'--
  num = 139,
  adv = 8,
  oxn =   -2, oyn =   -3, oxp =    3, oyp =    2,
  txn =   49, tyn =  116, txp =   54, typ =  121,
}
glyphs[140] = { --'å'--
  num = 140,
  adv = 8,
  oxn =   -2, oyn =   -3, oxp =    3, oyp =    2,
  txn =   73, tyn =  116, txp =   78, typ =  121,
}
glyphs[141] = { --'ç'--
  num = 141,
  adv = 8,
  oxn =   -2, oyn =   -3, oxp =    3, oyp =    2,
  txn =   97, tyn =  116, txp =  102, typ =  121,
}
glyphs[142] = { --'é'--
  num = 142,
  adv = 8,
  oxn =   -2, oyn =   -3, oxp =    3, oyp =    2,
  txn =  121, tyn =  116, txp =  126, typ =  121,
}
glyphs[143] = { --'è'--
  num = 143,
  adv = 8,
  oxn =   -2, oyn =   -3, oxp =    3, oyp =    2,
  txn =  145, tyn =  116, txp =  150, typ =  121,
}
glyphs[144] = { --'ê'--
  num = 144,
  adv = 8,
  oxn =   -2, oyn =   -3, oxp =    3, oyp =    2,
  txn =  169, tyn =  116, txp =  174, typ =  121,
}
glyphs[145] = { --'ë'--
  num = 145,
  adv = 8,
  oxn =   -2, oyn =   -3, oxp =    3, oyp =    2,
  txn =  193, tyn =  116, txp =  198, typ =  121,
}
glyphs[146] = { --'í'--
  num = 146,
  adv = 8,
  oxn =   -2, oyn =   -3, oxp =    3, oyp =    2,
  txn =  217, tyn =  116, txp =  222, typ =  121,
}
glyphs[147] = { --'ì'--
  num = 147,
  adv = 8,
  oxn =   -2, oyn =   -3, oxp =    3, oyp =    2,
  txn =  241, tyn =  116, txp =  246, typ =  121,
}
glyphs[148] = { --'î'--
  num = 148,
  adv = 8,
  oxn =   -2, oyn =   -3, oxp =    3, oyp =    2,
  txn =  265, tyn =  116, txp =  270, typ =  121,
}
glyphs[149] = { --'ï'--
  num = 149,
  adv = 8,
  oxn =   -2, oyn =   -3, oxp =    3, oyp =    2,
  txn =  289, tyn =  116, txp =  294, typ =  121,
}
glyphs[150] = { --'ñ'--
  num = 150,
  adv = 8,
  oxn =   -2, oyn =   -3, oxp =    3, oyp =    2,
  txn =  313, tyn =  116, txp =  318, typ =  121,
}
glyphs[151] = { --'ó'--
  num = 151,
  adv = 8,
  oxn =   -2, oyn =   -3, oxp =    3, oyp =    2,
  txn =  337, tyn =  116, txp =  342, typ =  121,
}
glyphs[152] = { --'ò'--
  num = 152,
  adv = 8,
  oxn =   -2, oyn =   -3, oxp =    3, oyp =    2,
  txn =  361, tyn =  116, txp =  366, typ =  121,
}
glyphs[153] = { --'ô'--
  num = 153,
  adv = 8,
  oxn =   -2, oyn =   -3, oxp =    3, oyp =    2,
  txn =  385, tyn =  116, txp =  390, typ =  121,
}
glyphs[154] = { --'ö'--
  num = 154,
  adv = 8,
  oxn =   -2, oyn =   -3, oxp =    3, oyp =    2,
  txn =  409, tyn =  116, txp =  414, typ =  121,
}
glyphs[155] = { --'õ'--
  num = 155,
  adv = 8,
  oxn =   -2, oyn =   -3, oxp =    3, oyp =    2,
  txn =  433, tyn =  116, txp =  438, typ =  121,
}
glyphs[156] = { --'ú'--
  num = 156,
  adv = 8,
  oxn =   -2, oyn =   -3, oxp =    3, oyp =    2,
  txn =  457, tyn =  116, txp =  462, typ =  121,
}
glyphs[157] = { --'ù'--
  num = 157,
  adv = 8,
  oxn =   -2, oyn =   -3, oxp =    3, oyp =    2,
  txn =  481, tyn =  116, txp =  486, typ =  121,
}
glyphs[158] = { --'û'--
  num = 158,
  adv = 8,
  oxn =   -2, oyn =   -3, oxp =    3, oyp =    2,
  txn =    1, tyn =  139, txp =    6, typ =  144,
}
glyphs[159] = { --'ü'--
  num = 159,
  adv = 8,
  oxn =   -2, oyn =   -3, oxp =    3, oyp =    2,
  txn =   25, tyn =  139, txp =   30, typ =  144,
}
glyphs[160] = { --'†'--
  num = 160,
  adv = 4,
  oxn =   -2, oyn =   -3, oxp =    3, oyp =    2,
  txn =   49, tyn =  139, txp =   54, typ =  144,
}
glyphs[161] = { --'°'--
  num = 161,
  adv = 4,
  oxn =   -2, oyn =   -6, oxp =    6, oyp =   11,
  txn =   73, tyn =  139, txp =   81, typ =  156,
}
glyphs[162] = { --'¢'--
  num = 162,
  adv = 8,
  oxn =   -2, oyn =   -3, oxp =   11, oyp =   13,
  txn =   97, tyn =  139, txp =  110, typ =  155,
}
glyphs[163] = { --'£'--
  num = 163,
  adv = 9,
  oxn =   -2, oyn =   -3, oxp =   12, oyp =   13,
  txn =  121, tyn =  139, txp =  135, typ =  155,
}
glyphs[164] = { --'§'--
  num = 164,
  adv = 8,
  oxn =   -2, oyn =   -3, oxp =    3, oyp =    2,
  txn =  145, tyn =  139, txp =  150, typ =  144,
}
glyphs[165] = { --'•'--
  num = 165,
  adv = 10,
  oxn =   -2, oyn =   -3, oxp =   13, oyp =   13,
  txn =  169, tyn =  139, txp =  184, typ =  155,
}
glyphs[166] = { --'¶'--
  num = 166,
  adv = 4,
  oxn =   -2, oyn =   -5, oxp =    6, oyp =   15,
  txn =  193, tyn =  139, txp =  201, typ =  159,
}
glyphs[167] = { --'ß'--
  num = 167,
  adv = 7,
  oxn =   -2, oyn =    2, oxp =    9, oyp =   14,
  txn =  217, tyn =  139, txp =  228, typ =  151,
}
glyphs[168] = { --'®'--
  num = 168,
  adv = 7,
  oxn =   -1, oyn =    6, oxp =    9, oyp =   13,
  txn =  241, tyn =  139, txp =  251, typ =  146,
}
glyphs[169] = { --'©'--
  num = 169,
  adv = 12,
  oxn =   -2, oyn =   -4, oxp =   14, oyp =   14,
  txn =  265, tyn =  139, txp =  281, typ =  157,
}
glyphs[170] = { --'™'--
  num = 170,
  adv = 6,
  oxn =   -2, oyn =    1, oxp =    8, oyp =   13,
  txn =  289, tyn =  139, txp =  299, typ =  151,
}
glyphs[171] = { --'´'--
  num = 171,
  adv = 7,
  oxn =   -2, oyn =    0, oxp =   10, oyp =   10,
  txn =  313, tyn =  139, txp =  325, typ =  149,
}
glyphs[172] = { --'¨'--
  num = 172,
  adv = 15,
  oxn =   -2, oyn =   -3, oxp =   18, oyp =   15,
  txn =  337, tyn =  139, txp =  357, typ =  157,
}
glyphs[173] = { --'≠'--
  num = 173,
  adv = 8,
  oxn =   -2, oyn =   -3, oxp =    3, oyp =    2,
  txn =  361, tyn =  139, txp =  366, typ =  144,
}
glyphs[174] = { --'Æ'--
  num = 174,
  adv = 8,
  oxn =   -2, oyn =    1, oxp =   11, oyp =   14,
  txn =  385, tyn =  139, txp =  398, typ =  152,
}
glyphs[175] = { --'Ø'--
  num = 175,
  adv = 6,
  oxn =   -2, oyn =    6, oxp =    9, oyp =   12,
  txn =  409, tyn =  139, txp =  420, typ =  145,
}
glyphs[176] = { --'∞'--
  num = 176,
  adv = 4,
  oxn =   -2, oyn =    5, oxp =    7, oyp =   13,
  txn =  433, tyn =  139, txp =  442, typ =  147,
}
glyphs[177] = { --'±'--
  num = 177,
  adv = 7,
  oxn =   -2, oyn =   -1, oxp =    9, oyp =   11,
  txn =  457, tyn =  139, txp =  468, typ =  151,
}
glyphs[178] = { --'≤'--
  num = 178,
  adv = 6,
  oxn =   -2, oyn =    2, oxp =    8, oyp =   14,
  txn =  481, tyn =  139, txp =  491, typ =  151,
}
glyphs[179] = { --'≥'--
  num = 179,
  adv = 6,
  oxn =   -2, oyn =    2, oxp =    8, oyp =   14,
  txn =    1, tyn =  162, txp =   11, typ =  174,
}
glyphs[180] = { --'¥'--
  num = 180,
  adv = 8,
  oxn =    0, oyn =    5, oxp =    9, oyp =   14,
  txn =   25, tyn =  162, txp =   34, typ =  171,
}
glyphs[181] = { --'µ'--
  num = 181,
  adv = 8,
  oxn =   -2, oyn =   -5, oxp =   10, oyp =   10,
  txn =   49, tyn =  162, txp =   61, typ =  177,
}
glyphs[182] = { --'∂'--
  num = 182,
  adv = 8,
  oxn =   -2, oyn =   -5, oxp =   11, oyp =   12,
  txn =   73, tyn =  162, txp =   86, typ =  179,
}
glyphs[183] = { --'∑'--
  num = 183,
  adv = 3,
  oxn =   -2, oyn =    1, oxp =    6, oyp =    9,
  txn =   97, tyn =  162, txp =  105, typ =  170,
}
glyphs[184] = { --'∏'--
  num = 184,
  adv = 8,
  oxn =    1, oyn =   -5, oxp =    8, oyp =    4,
  txn =  121, tyn =  162, txp =  128, typ =  171,
}
glyphs[185] = { --'π'--
  num = 185,
  adv = 3,
  oxn =   -2, oyn =    2, oxp =    5, oyp =   14,
  txn =  145, tyn =  162, txp =  152, typ =  174,
}
glyphs[186] = { --'∫'--
  num = 186,
  adv = 6,
  oxn =   -2, oyn =    1, oxp =    9, oyp =   13,
  txn =  169, tyn =  162, txp =  180, typ =  174,
}
glyphs[187] = { --'ª'--
  num = 187,
  adv = 7,
  oxn =   -2, oyn =    0, oxp =   10, oyp =   10,
  txn =  193, tyn =  162, txp =  205, typ =  172,
}
glyphs[188] = { --'º'--
  num = 188,
  adv = 10,
  oxn =   -2, oyn =   -3, oxp =   13, oyp =   13,
  txn =  217, tyn =  162, txp =  232, typ =  178,
}
glyphs[189] = { --'Ω'--
  num = 189,
  adv = 10,
  oxn =   -2, oyn =   -3, oxp =   13, oyp =   13,
  txn =  241, tyn =  162, txp =  256, typ =  178,
}
glyphs[190] = { --'æ'--
  num = 190,
  adv = 13,
  oxn =   -2, oyn =   -3, oxp =   16, oyp =   14,
  txn =  265, tyn =  162, txp =  283, typ =  179,
}
glyphs[191] = { --'ø'--
  num = 191,
  adv = 9,
  oxn =   -2, oyn =   -6, oxp =   10, oyp =   11,
  txn =  289, tyn =  162, txp =  301, typ =  179,
}
glyphs[192] = { --'¿'--
  num = 192,
  adv = 10,
  oxn =   -2, oyn =   -3, oxp =   12, oyp =   17,
  txn =  313, tyn =  162, txp =  327, typ =  182,
}
glyphs[193] = { --'¡'--
  num = 193,
  adv = 10,
  oxn =   -2, oyn =   -3, oxp =   12, oyp =   17,
  txn =  337, tyn =  162, txp =  351, typ =  182,
}
glyphs[194] = { --'¬'--
  num = 194,
  adv = 10,
  oxn =   -2, oyn =   -3, oxp =   12, oyp =   17,
  txn =  361, tyn =  162, txp =  375, typ =  182,
}
glyphs[195] = { --'√'--
  num = 195,
  adv = 10,
  oxn =   -2, oyn =   -3, oxp =   12, oyp =   16,
  txn =  385, tyn =  162, txp =  399, typ =  181,
}
glyphs[196] = { --'ƒ'--
  num = 196,
  adv = 10,
  oxn =   -2, oyn =   -3, oxp =   12, oyp =   16,
  txn =  409, tyn =  162, txp =  423, typ =  181,
}
glyphs[197] = { --'≈'--
  num = 197,
  adv = 10,
  oxn =   -2, oyn =   -3, oxp =   12, oyp =   17,
  txn =  433, tyn =  162, txp =  447, typ =  182,
}
glyphs[198] = { --'∆'--
  num = 198,
  adv = 16,
  oxn =   -3, oyn =   -3, oxp =   19, oyp =   13,
  txn =  457, tyn =  162, txp =  479, typ =  178,
}
glyphs[199] = { --'«'--
  num = 199,
  adv = 9,
  oxn =   -2, oyn =   -5, oxp =   12, oyp =   13,
  txn =  481, tyn =  162, txp =  495, typ =  180,
}
glyphs[200] = { --'»'--
  num = 200,
  adv = 9,
  oxn =   -1, oyn =   -3, oxp =   11, oyp =   17,
  txn =    1, tyn =  185, txp =   13, typ =  205,
}
glyphs[201] = { --'…'--
  num = 201,
  adv = 9,
  oxn =   -1, oyn =   -3, oxp =   11, oyp =   17,
  txn =   25, tyn =  185, txp =   37, typ =  205,
}
glyphs[202] = { --' '--
  num = 202,
  adv = 9,
  oxn =   -1, oyn =   -3, oxp =   11, oyp =   17,
  txn =   49, tyn =  185, txp =   61, typ =  205,
}
glyphs[203] = { --'À'--
  num = 203,
  adv = 9,
  oxn =   -1, oyn =   -3, oxp =   11, oyp =   16,
  txn =   73, tyn =  185, txp =   85, typ =  204,
}
glyphs[204] = { --'Ã'--
  num = 204,
  adv = 4,
  oxn =   -1, oyn =   -3, oxp =    7, oyp =   17,
  txn =   97, tyn =  185, txp =  105, typ =  205,
}
glyphs[205] = { --'Õ'--
  num = 205,
  adv = 4,
  oxn =   -1, oyn =   -3, oxp =    7, oyp =   17,
  txn =  121, tyn =  185, txp =  129, typ =  205,
}
glyphs[206] = { --'Œ'--
  num = 206,
  adv = 4,
  oxn =   -2, oyn =   -3, oxp =    8, oyp =   17,
  txn =  145, tyn =  185, txp =  155, typ =  205,
}
glyphs[207] = { --'œ'--
  num = 207,
  adv = 4,
  oxn =   -2, oyn =   -3, oxp =    8, oyp =   16,
  txn =  169, tyn =  185, txp =  179, typ =  204,
}
glyphs[208] = { --'–'--
  num = 208,
  adv = 10,
  oxn =   -3, oyn =   -3, oxp =   12, oyp =   13,
  txn =  193, tyn =  185, txp =  208, typ =  201,
}
glyphs[209] = { --'—'--
  num = 209,
  adv = 10,
  oxn =   -2, oyn =   -3, oxp =   13, oyp =   16,
  txn =  217, tyn =  185, txp =  232, typ =  204,
}
glyphs[210] = { --'“'--
  num = 210,
  adv = 10,
  oxn =   -2, oyn =   -3, oxp =   13, oyp =   17,
  txn =  241, tyn =  185, txp =  256, typ =  205,
}
glyphs[211] = { --'”'--
  num = 211,
  adv = 10,
  oxn =   -2, oyn =   -3, oxp =   13, oyp =   17,
  txn =  265, tyn =  185, txp =  280, typ =  205,
}
glyphs[212] = { --'‘'--
  num = 212,
  adv = 10,
  oxn =   -2, oyn =   -3, oxp =   13, oyp =   17,
  txn =  289, tyn =  185, txp =  304, typ =  205,
}
glyphs[213] = { --'’'--
  num = 213,
  adv = 10,
  oxn =   -2, oyn =   -3, oxp =   13, oyp =   16,
  txn =  313, tyn =  185, txp =  328, typ =  204,
}
glyphs[214] = { --'÷'--
  num = 214,
  adv = 10,
  oxn =   -2, oyn =   -3, oxp =   13, oyp =   16,
  txn =  337, tyn =  185, txp =  352, typ =  204,
}
glyphs[215] = { --'◊'--
  num = 215,
  adv = 7,
  oxn =   -2, oyn =   -2, oxp =   10, oyp =    9,
  txn =  361, tyn =  185, txp =  373, typ =  196,
}
glyphs[216] = { --'ÿ'--
  num = 216,
  adv = 10,
  oxn =   -2, oyn =   -4, oxp =   13, oyp =   14,
  txn =  385, tyn =  185, txp =  400, typ =  203,
}
glyphs[217] = { --'Ÿ'--
  num = 217,
  adv = 10,
  oxn =   -1, oyn =   -3, oxp =   12, oyp =   17,
  txn =  409, tyn =  185, txp =  422, typ =  205,
}
glyphs[218] = { --'⁄'--
  num = 218,
  adv = 10,
  oxn =   -1, oyn =   -3, oxp =   12, oyp =   17,
  txn =  433, tyn =  185, txp =  446, typ =  205,
}
glyphs[219] = { --'€'--
  num = 219,
  adv = 10,
  oxn =   -1, oyn =   -3, oxp =   12, oyp =   17,
  txn =  457, tyn =  185, txp =  470, typ =  205,
}
glyphs[220] = { --'‹'--
  num = 220,
  adv = 10,
  oxn =   -1, oyn =   -3, oxp =   12, oyp =   16,
  txn =  481, tyn =  185, txp =  494, typ =  204,
}
glyphs[221] = { --'›'--
  num = 221,
  adv = 10,
  oxn =   -2, oyn =   -3, oxp =   13, oyp =   17,
  txn =    1, tyn =  208, txp =   16, typ =  228,
}
glyphs[222] = { --'ﬁ'--
  num = 222,
  adv = 8,
  oxn =   -1, oyn =   -3, oxp =   11, oyp =   13,
  txn =   25, tyn =  208, txp =   37, typ =  224,
}
glyphs[223] = { --'ﬂ'--
  num = 223,
  adv = 10,
  oxn =   -2, oyn =   -4, oxp =   12, oyp =   13,
  txn =   49, tyn =  208, txp =   63, typ =  225,
}
glyphs[224] = { --'‡'--
  num = 224,
  adv = 8,
  oxn =   -2, oyn =   -3, oxp =   10, oyp =   14,
  txn =   73, tyn =  208, txp =   85, typ =  225,
}
glyphs[225] = { --'·'--
  num = 225,
  adv = 8,
  oxn =   -2, oyn =   -3, oxp =   10, oyp =   14,
  txn =   97, tyn =  208, txp =  109, typ =  225,
}
glyphs[226] = { --'‚'--
  num = 226,
  adv = 8,
  oxn =   -2, oyn =   -3, oxp =   10, oyp =   14,
  txn =  121, tyn =  208, txp =  133, typ =  225,
}
glyphs[227] = { --'„'--
  num = 227,
  adv = 8,
  oxn =   -2, oyn =   -3, oxp =   10, oyp =   13,
  txn =  145, tyn =  208, txp =  157, typ =  224,
}
glyphs[228] = { --'‰'--
  num = 228,
  adv = 8,
  oxn =   -2, oyn =   -3, oxp =   10, oyp =   13,
  txn =  169, tyn =  208, txp =  181, typ =  224,
}
glyphs[229] = { --'Â'--
  num = 229,
  adv = 8,
  oxn =   -2, oyn =   -3, oxp =   10, oyp =   14,
  txn =  193, tyn =  208, txp =  205, typ =  225,
}
glyphs[230] = { --'Ê'--
  num = 230,
  adv = 13,
  oxn =   -2, oyn =   -3, oxp =   15, oyp =   10,
  txn =  217, tyn =  208, txp =  234, typ =  221,
}
glyphs[231] = { --'Á'--
  num = 231,
  adv = 7,
  oxn =   -2, oyn =   -5, oxp =   10, oyp =   10,
  txn =  241, tyn =  208, txp =  253, typ =  223,
}
glyphs[232] = { --'Ë'--
  num = 232,
  adv = 8,
  oxn =   -2, oyn =   -3, oxp =   10, oyp =   14,
  txn =  265, tyn =  208, txp =  277, typ =  225,
}
glyphs[233] = { --'È'--
  num = 233,
  adv = 8,
  oxn =   -2, oyn =   -3, oxp =   10, oyp =   14,
  txn =  289, tyn =  208, txp =  301, typ =  225,
}
glyphs[234] = { --'Í'--
  num = 234,
  adv = 8,
  oxn =   -2, oyn =   -3, oxp =   10, oyp =   14,
  txn =  313, tyn =  208, txp =  325, typ =  225,
}
glyphs[235] = { --'Î'--
  num = 235,
  adv = 8,
  oxn =   -2, oyn =   -3, oxp =   10, oyp =   13,
  txn =  337, tyn =  208, txp =  349, typ =  224,
}
glyphs[236] = { --'Ï'--
  num = 236,
  adv = 4,
  oxn =   -2, oyn =   -3, oxp =    6, oyp =   14,
  txn =  361, tyn =  208, txp =  369, typ =  225,
}
glyphs[237] = { --'Ì'--
  num = 237,
  adv = 4,
  oxn =   -1, oyn =   -3, oxp =    7, oyp =   14,
  txn =  385, tyn =  208, txp =  393, typ =  225,
}
glyphs[238] = { --'Ó'--
  num = 238,
  adv = 4,
  oxn =   -3, oyn =   -3, oxp =    7, oyp =   14,
  txn =  409, tyn =  208, txp =  419, typ =  225,
}
glyphs[239] = { --'Ô'--
  num = 239,
  adv = 4,
  oxn =   -3, oyn =   -3, oxp =    7, oyp =   13,
  txn =  433, tyn =  208, txp =  443, typ =  224,
}
glyphs[240] = { --''--
  num = 240,
  adv = 8,
  oxn =   -2, oyn =   -2, oxp =   11, oyp =   14,
  txn =  457, tyn =  208, txp =  470, typ =  224,
}
glyphs[241] = { --'Ò'--
  num = 241,
  adv = 8,
  oxn =   -1, oyn =   -3, oxp =   10, oyp =   13,
  txn =  481, tyn =  208, txp =  492, typ =  224,
}
glyphs[242] = { --'Ú'--
  num = 242,
  adv = 8,
  oxn =   -2, oyn =   -3, oxp =   11, oyp =   14,
  txn =    1, tyn =  231, txp =   14, typ =  248,
}
glyphs[243] = { --'Û'--
  num = 243,
  adv = 8,
  oxn =   -2, oyn =   -3, oxp =   11, oyp =   14,
  txn =   25, tyn =  231, txp =   38, typ =  248,
}
glyphs[244] = { --'Ù'--
  num = 244,
  adv = 8,
  oxn =   -2, oyn =   -3, oxp =   11, oyp =   14,
  txn =   49, tyn =  231, txp =   62, typ =  248,
}
glyphs[245] = { --'ı'--
  num = 245,
  adv = 8,
  oxn =   -2, oyn =   -3, oxp =   11, oyp =   13,
  txn =   73, tyn =  231, txp =   86, typ =  247,
}
glyphs[246] = { --'ˆ'--
  num = 246,
  adv = 8,
  oxn =   -2, oyn =   -3, oxp =   11, oyp =   13,
  txn =   97, tyn =  231, txp =  110, typ =  247,
}
glyphs[247] = { --'˜'--
  num = 247,
  adv = 6,
  oxn =   -2, oyn =   -3, oxp =    9, oyp =   10,
  txn =  121, tyn =  231, txp =  132, typ =  244,
}
glyphs[248] = { --'¯'--
  num = 248,
  adv = 8,
  oxn =   -2, oyn =   -5, oxp =   11, oyp =   11,
  txn =  145, tyn =  231, txp =  158, typ =  247,
}
glyphs[249] = { --'˘'--
  num = 249,
  adv = 8,
  oxn =   -1, oyn =   -3, oxp =   10, oyp =   14,
  txn =  169, tyn =  231, txp =  180, typ =  248,
}
glyphs[250] = { --'˙'--
  num = 250,
  adv = 8,
  oxn =   -1, oyn =   -3, oxp =   10, oyp =   14,
  txn =  193, tyn =  231, txp =  204, typ =  248,
}
glyphs[251] = { --'˚'--
  num = 251,
  adv = 8,
  oxn =   -1, oyn =   -3, oxp =   10, oyp =   14,
  txn =  217, tyn =  231, txp =  228, typ =  248,
}
glyphs[252] = { --'¸'--
  num = 252,
  adv = 8,
  oxn =   -1, oyn =   -3, oxp =   10, oyp =   13,
  txn =  241, tyn =  231, txp =  252, typ =  247,
}
glyphs[253] = { --'˝'--
  num = 253,
  adv = 7,
  oxn =   -2, oyn =   -6, oxp =   10, oyp =   14,
  txn =  265, tyn =  231, txp =  277, typ =  251,
}
glyphs[254] = { --'˛'--
  num = 254,
  adv = 8,
  oxn =   -2, oyn =   -7, oxp =   11, oyp =   13,
  txn =  289, tyn =  231, txp =  302, typ =  251,
}
glyphs[255] = { --'ˇ'--
  num = 255,
  adv = 7,
  oxn =   -2, oyn =   -6, oxp =   10, oyp =   13,
  txn =  313, tyn =  231, txp =  325, typ =  250,
}

fontSpecs.glyphs = glyphs

return fontSpecs

