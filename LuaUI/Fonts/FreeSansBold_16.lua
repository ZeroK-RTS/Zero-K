-- $Id: FreeSansBold_16.lua 3171 2008-11-06 09:06:29Z det $

local fontSpecs = {
  srcFile  = [[FreeSansBold.ttf]],
  family   = [[FreeSans]],
  style    = [[Bold]],
  yStep    = 17,
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
  adv = 5,
  oxn =   -1, oyn =   -2, oxp =    7, oyp =   14,
  txn =   23, tyn =    1, txp =   31, typ =   17,
}
glyphs[34] = { --'"'--
  num = 34,
  adv = 8,
  oxn =   -2, oyn =    5, oxp =    9, oyp =   14,
  txn =   45, tyn =    1, txp =   56, typ =   10,
}
glyphs[35] = { --'#'--
  num = 35,
  adv = 9,
  oxn =   -2, oyn =   -3, oxp =   11, oyp =   14,
  txn =   67, tyn =    1, txp =   80, typ =   18,
}
glyphs[36] = { --'$'--
  num = 36,
  adv = 9,
  oxn =   -2, oyn =   -5, oxp =   11, oyp =   15,
  txn =   89, tyn =    1, txp =  102, typ =   21,
}
glyphs[37] = { --'%'--
  num = 37,
  adv = 14,
  oxn =   -2, oyn =   -3, oxp =   16, oyp =   14,
  txn =  111, tyn =    1, txp =  129, typ =   18,
}
glyphs[38] = { --'&'--
  num = 38,
  adv = 12,
  oxn =   -2, oyn =   -3, oxp =   14, oyp =   14,
  txn =  133, tyn =    1, txp =  149, typ =   18,
}
glyphs[39] = { --'''--
  num = 39,
  adv = 4,
  oxn =   -2, oyn =    5, oxp =    6, oyp =   14,
  txn =  155, tyn =    1, txp =  163, typ =   10,
}
glyphs[40] = { --'('--
  num = 40,
  adv = 5,
  oxn =   -2, oyn =   -6, oxp =    7, oyp =   14,
  txn =  177, tyn =    1, txp =  186, typ =   21,
}
glyphs[41] = { --')'--
  num = 41,
  adv = 5,
  oxn =   -2, oyn =   -6, oxp =    7, oyp =   14,
  txn =  199, tyn =    1, txp =  208, typ =   21,
}
glyphs[42] = { --'*'--
  num = 42,
  adv = 6,
  oxn =   -2, oyn =    4, oxp =    8, oyp =   14,
  txn =  221, tyn =    1, txp =  231, typ =   11,
}
glyphs[43] = { --'+'--
  num = 43,
  adv = 9,
  oxn =   -2, oyn =   -3, oxp =   11, oyp =   10,
  txn =  243, tyn =    1, txp =  256, typ =   14,
}
glyphs[44] = { --','--
  num = 44,
  adv = 4,
  oxn =   -1, oyn =   -5, oxp =    6, oyp =    5,
  txn =  265, tyn =    1, txp =  272, typ =   11,
}
glyphs[45] = { --'-'--
  num = 45,
  adv = 5,
  oxn =   -2, oyn =    1, oxp =    7, oyp =    8,
  txn =  287, tyn =    1, txp =  296, typ =    8,
}
glyphs[46] = { --'.'--
  num = 46,
  adv = 4,
  oxn =   -1, oyn =   -2, oxp =    6, oyp =    5,
  txn =  309, tyn =    1, txp =  316, typ =    8,
}
glyphs[47] = { --'/'--
  num = 47,
  adv = 4,
  oxn =   -2, oyn =   -3, oxp =    7, oyp =   14,
  txn =  331, tyn =    1, txp =  340, typ =   18,
}
glyphs[48] = { --'0'--
  num = 48,
  adv = 9,
  oxn =   -2, oyn =   -3, oxp =   11, oyp =   14,
  txn =  353, tyn =    1, txp =  366, typ =   18,
}
glyphs[49] = { --'1'--
  num = 49,
  adv = 9,
  oxn =   -1, oyn =   -2, oxp =    9, oyp =   14,
  txn =  375, tyn =    1, txp =  385, typ =   17,
}
glyphs[50] = { --'2'--
  num = 50,
  adv = 9,
  oxn =   -2, oyn =   -2, oxp =   11, oyp =   14,
  txn =  397, tyn =    1, txp =  410, typ =   17,
}
glyphs[51] = { --'3'--
  num = 51,
  adv = 9,
  oxn =   -2, oyn =   -3, oxp =   11, oyp =   14,
  txn =  419, tyn =    1, txp =  432, typ =   18,
}
glyphs[52] = { --'4'--
  num = 52,
  adv = 9,
  oxn =   -2, oyn =   -2, oxp =   11, oyp =   14,
  txn =  441, tyn =    1, txp =  454, typ =   17,
}
glyphs[53] = { --'5'--
  num = 53,
  adv = 9,
  oxn =   -2, oyn =   -3, oxp =   11, oyp =   14,
  txn =  463, tyn =    1, txp =  476, typ =   18,
}
glyphs[54] = { --'6'--
  num = 54,
  adv = 9,
  oxn =   -2, oyn =   -3, oxp =   11, oyp =   14,
  txn =  485, tyn =    1, txp =  498, typ =   18,
}
glyphs[55] = { --'7'--
  num = 55,
  adv = 9,
  oxn =   -2, oyn =   -2, oxp =   11, oyp =   14,
  txn =    1, tyn =   24, txp =   14, typ =   40,
}
glyphs[56] = { --'8'--
  num = 56,
  adv = 9,
  oxn =   -2, oyn =   -3, oxp =   11, oyp =   14,
  txn =   23, tyn =   24, txp =   36, typ =   41,
}
glyphs[57] = { --'9'--
  num = 57,
  adv = 9,
  oxn =   -2, oyn =   -3, oxp =   11, oyp =   14,
  txn =   45, tyn =   24, txp =   58, typ =   41,
}
glyphs[58] = { --':'--
  num = 58,
  adv = 5,
  oxn =   -1, oyn =   -2, oxp =    7, oyp =   11,
  txn =   67, tyn =   24, txp =   75, typ =   37,
}
glyphs[59] = { --';'--
  num = 59,
  adv = 5,
  oxn =   -1, oyn =   -5, oxp =    7, oyp =   11,
  txn =   89, tyn =   24, txp =   97, typ =   40,
}
glyphs[60] = { --'<'--
  num = 60,
  adv = 9,
  oxn =   -2, oyn =   -3, oxp =   11, oyp =   10,
  txn =  111, tyn =   24, txp =  124, typ =   37,
}
glyphs[61] = { --'='--
  num = 61,
  adv = 9,
  oxn =   -2, oyn =   -2, oxp =   11, oyp =    9,
  txn =  133, tyn =   24, txp =  146, typ =   35,
}
glyphs[62] = { --'>'--
  num = 62,
  adv = 9,
  oxn =   -2, oyn =   -3, oxp =   11, oyp =   10,
  txn =  155, tyn =   24, txp =  168, typ =   37,
}
glyphs[63] = { --'?'--
  num = 63,
  adv = 10,
  oxn =   -1, oyn =   -2, oxp =   11, oyp =   14,
  txn =  177, tyn =   24, txp =  189, typ =   40,
}
glyphs[64] = { --'@'--
  num = 64,
  adv = 16,
  oxn =   -2, oyn =   -5, oxp =   18, oyp =   14,
  txn =  199, tyn =   24, txp =  219, typ =   43,
}
glyphs[65] = { --'A'--
  num = 65,
  adv = 12,
  oxn =   -2, oyn =   -2, oxp =   14, oyp =   14,
  txn =  221, tyn =   24, txp =  237, typ =   40,
}
glyphs[66] = { --'B'--
  num = 66,
  adv = 12,
  oxn =   -1, oyn =   -2, oxp =   13, oyp =   14,
  txn =  243, tyn =   24, txp =  257, typ =   40,
}
glyphs[67] = { --'C'--
  num = 67,
  adv = 12,
  oxn =   -2, oyn =   -3, oxp =   13, oyp =   14,
  txn =  265, tyn =   24, txp =  280, typ =   41,
}
glyphs[68] = { --'D'--
  num = 68,
  adv = 12,
  oxn =   -1, oyn =   -2, oxp =   13, oyp =   14,
  txn =  287, tyn =   24, txp =  301, typ =   40,
}
glyphs[69] = { --'E'--
  num = 69,
  adv = 11,
  oxn =   -1, oyn =   -2, oxp =   12, oyp =   14,
  txn =  309, tyn =   24, txp =  322, typ =   40,
}
glyphs[70] = { --'F'--
  num = 70,
  adv = 10,
  oxn =   -1, oyn =   -2, oxp =   12, oyp =   14,
  txn =  331, tyn =   24, txp =  344, typ =   40,
}
glyphs[71] = { --'G'--
  num = 71,
  adv = 12,
  oxn =   -2, oyn =   -3, oxp =   14, oyp =   14,
  txn =  353, tyn =   24, txp =  369, typ =   41,
}
glyphs[72] = { --'H'--
  num = 72,
  adv = 12,
  oxn =   -1, oyn =   -2, oxp =   13, oyp =   14,
  txn =  375, tyn =   24, txp =  389, typ =   40,
}
glyphs[73] = { --'I'--
  num = 73,
  adv = 4,
  oxn =   -1, oyn =   -2, oxp =    6, oyp =   14,
  txn =  397, tyn =   24, txp =  404, typ =   40,
}
glyphs[74] = { --'J'--
  num = 74,
  adv = 9,
  oxn =   -2, oyn =   -3, oxp =   10, oyp =   14,
  txn =  419, tyn =   24, txp =  431, typ =   41,
}
glyphs[75] = { --'K'--
  num = 75,
  adv = 12,
  oxn =   -1, oyn =   -2, oxp =   14, oyp =   14,
  txn =  441, tyn =   24, txp =  456, typ =   40,
}
glyphs[76] = { --'L'--
  num = 76,
  adv = 10,
  oxn =   -1, oyn =   -2, oxp =   12, oyp =   14,
  txn =  463, tyn =   24, txp =  476, typ =   40,
}
glyphs[77] = { --'M'--
  num = 77,
  adv = 13,
  oxn =   -1, oyn =   -2, oxp =   15, oyp =   14,
  txn =  485, tyn =   24, txp =  501, typ =   40,
}
glyphs[78] = { --'N'--
  num = 78,
  adv = 12,
  oxn =   -1, oyn =   -2, oxp =   13, oyp =   14,
  txn =    1, tyn =   47, txp =   15, typ =   63,
}
glyphs[79] = { --'O'--
  num = 79,
  adv = 12,
  oxn =   -2, oyn =   -3, oxp =   14, oyp =   14,
  txn =   23, tyn =   47, txp =   39, typ =   64,
}
glyphs[80] = { --'P'--
  num = 80,
  adv = 11,
  oxn =   -1, oyn =   -2, oxp =   13, oyp =   14,
  txn =   45, tyn =   47, txp =   59, typ =   63,
}
glyphs[81] = { --'Q'--
  num = 81,
  adv = 12,
  oxn =   -2, oyn =   -3, oxp =   14, oyp =   14,
  txn =   67, tyn =   47, txp =   83, typ =   64,
}
glyphs[82] = { --'R'--
  num = 82,
  adv = 12,
  oxn =   -1, oyn =   -2, oxp =   13, oyp =   14,
  txn =   89, tyn =   47, txp =  103, typ =   63,
}
glyphs[83] = { --'S'--
  num = 83,
  adv = 11,
  oxn =   -2, oyn =   -3, oxp =   13, oyp =   14,
  txn =  111, tyn =   47, txp =  126, typ =   64,
}
glyphs[84] = { --'T'--
  num = 84,
  adv = 10,
  oxn =   -2, oyn =   -2, oxp =   12, oyp =   14,
  txn =  133, tyn =   47, txp =  147, typ =   63,
}
glyphs[85] = { --'U'--
  num = 85,
  adv = 12,
  oxn =   -1, oyn =   -3, oxp =   13, oyp =   14,
  txn =  155, tyn =   47, txp =  169, typ =   64,
}
glyphs[86] = { --'V'--
  num = 86,
  adv = 11,
  oxn =   -2, oyn =   -2, oxp =   13, oyp =   14,
  txn =  177, tyn =   47, txp =  192, typ =   63,
}
glyphs[87] = { --'W'--
  num = 87,
  adv = 15,
  oxn =   -2, oyn =   -2, oxp =   17, oyp =   14,
  txn =  199, tyn =   47, txp =  218, typ =   63,
}
glyphs[88] = { --'X'--
  num = 88,
  adv = 11,
  oxn =   -2, oyn =   -2, oxp =   13, oyp =   14,
  txn =  221, tyn =   47, txp =  236, typ =   63,
}
glyphs[89] = { --'Y'--
  num = 89,
  adv = 11,
  oxn =   -2, oyn =   -2, oxp =   13, oyp =   14,
  txn =  243, tyn =   47, txp =  258, typ =   63,
}
glyphs[90] = { --'Z'--
  num = 90,
  adv = 10,
  oxn =   -2, oyn =   -2, oxp =   12, oyp =   14,
  txn =  265, tyn =   47, txp =  279, typ =   63,
}
glyphs[91] = { --'['--
  num = 91,
  adv = 5,
  oxn =   -1, oyn =   -6, oxp =    7, oyp =   14,
  txn =  287, tyn =   47, txp =  295, typ =   67,
}
glyphs[92] = { --'\'--
  num = 92,
  adv = 4,
  oxn =   -3, oyn =   -3, oxp =    7, oyp =   14,
  txn =  309, tyn =   47, txp =  319, typ =   64,
}
glyphs[93] = { --']'--
  num = 93,
  adv = 5,
  oxn =   -2, oyn =   -6, oxp =    7, oyp =   14,
  txn =  331, tyn =   47, txp =  340, typ =   67,
}
glyphs[94] = { --'^'--
  num = 94,
  adv = 9,
  oxn =   -2, oyn =    2, oxp =   11, oyp =   14,
  txn =  353, tyn =   47, txp =  366, typ =   59,
}
glyphs[95] = { --'_'--
  num = 95,
  adv = 9,
  oxn =   -3, oyn =   -6, oxp =   12, oyp =    1,
  txn =  375, tyn =   47, txp =  390, typ =   54,
}
glyphs[96] = { --'`'--
  num = 96,
  adv = 5,
  oxn =   -2, oyn =    7, oxp =    6, oyp =   15,
  txn =  397, tyn =   47, txp =  405, typ =   55,
}
glyphs[97] = { --'a'--
  num = 97,
  adv = 9,
  oxn =   -2, oyn =   -3, oxp =   11, oyp =   11,
  txn =  419, tyn =   47, txp =  432, typ =   61,
}
glyphs[98] = { --'b'--
  num = 98,
  adv = 10,
  oxn =   -2, oyn =   -3, oxp =   12, oyp =   14,
  txn =  441, tyn =   47, txp =  455, typ =   64,
}
glyphs[99] = { --'c'--
  num = 99,
  adv = 9,
  oxn =   -2, oyn =   -3, oxp =   11, oyp =   11,
  txn =  463, tyn =   47, txp =  476, typ =   61,
}
glyphs[100] = { --'d'--
  num = 100,
  adv = 10,
  oxn =   -2, oyn =   -3, oxp =   11, oyp =   14,
  txn =  485, tyn =   47, txp =  498, typ =   64,
}
glyphs[101] = { --'e'--
  num = 101,
  adv = 9,
  oxn =   -2, oyn =   -3, oxp =   11, oyp =   11,
  txn =    1, tyn =   70, txp =   14, typ =   84,
}
glyphs[102] = { --'f'--
  num = 102,
  adv = 5,
  oxn =   -2, oyn =   -2, oxp =    8, oyp =   14,
  txn =   23, tyn =   70, txp =   33, typ =   86,
}
glyphs[103] = { --'g'--
  num = 103,
  adv = 10,
  oxn =   -2, oyn =   -6, oxp =   11, oyp =   11,
  txn =   45, tyn =   70, txp =   58, typ =   87,
}
glyphs[104] = { --'h'--
  num = 104,
  adv = 10,
  oxn =   -1, oyn =   -2, oxp =   11, oyp =   14,
  txn =   67, tyn =   70, txp =   79, typ =   86,
}
glyphs[105] = { --'i'--
  num = 105,
  adv = 4,
  oxn =   -1, oyn =   -2, oxp =    6, oyp =   14,
  txn =   89, tyn =   70, txp =   96, typ =   86,
}
glyphs[106] = { --'j'--
  num = 106,
  adv = 4,
  oxn =   -2, oyn =   -6, oxp =    6, oyp =   14,
  txn =  111, tyn =   70, txp =  119, typ =   90,
}
glyphs[107] = { --'k'--
  num = 107,
  adv = 9,
  oxn =   -2, oyn =   -2, oxp =   11, oyp =   14,
  txn =  133, tyn =   70, txp =  146, typ =   86,
}
glyphs[108] = { --'l'--
  num = 108,
  adv = 4,
  oxn =   -1, oyn =   -2, oxp =    6, oyp =   14,
  txn =  155, tyn =   70, txp =  162, typ =   86,
}
glyphs[109] = { --'m'--
  num = 109,
  adv = 14,
  oxn =   -2, oyn =   -2, oxp =   16, oyp =   11,
  txn =  177, tyn =   70, txp =  195, typ =   83,
}
glyphs[110] = { --'n'--
  num = 110,
  adv = 10,
  oxn =   -1, oyn =   -2, oxp =   11, oyp =   11,
  txn =  199, tyn =   70, txp =  211, typ =   83,
}
glyphs[111] = { --'o'--
  num = 111,
  adv = 10,
  oxn =   -2, oyn =   -3, oxp =   12, oyp =   11,
  txn =  221, tyn =   70, txp =  235, typ =   84,
}
glyphs[112] = { --'p'--
  num = 112,
  adv = 10,
  oxn =   -2, oyn =   -6, oxp =   12, oyp =   11,
  txn =  243, tyn =   70, txp =  257, typ =   87,
}
glyphs[113] = { --'q'--
  num = 113,
  adv = 10,
  oxn =   -2, oyn =   -6, oxp =   11, oyp =   11,
  txn =  265, tyn =   70, txp =  278, typ =   87,
}
glyphs[114] = { --'r'--
  num = 114,
  adv = 6,
  oxn =   -1, oyn =   -2, oxp =    8, oyp =   11,
  txn =  287, tyn =   70, txp =  296, typ =   83,
}
glyphs[115] = { --'s'--
  num = 115,
  adv = 9,
  oxn =   -2, oyn =   -3, oxp =   11, oyp =   11,
  txn =  309, tyn =   70, txp =  322, typ =   84,
}
glyphs[116] = { --'t'--
  num = 116,
  adv = 5,
  oxn =   -2, oyn =   -3, oxp =    7, oyp =   13,
  txn =  331, tyn =   70, txp =  340, typ =   86,
}
glyphs[117] = { --'u'--
  num = 117,
  adv = 10,
  oxn =   -2, oyn =   -3, oxp =   11, oyp =   11,
  txn =  353, tyn =   70, txp =  366, typ =   84,
}
glyphs[118] = { --'v'--
  num = 118,
  adv = 9,
  oxn =   -2, oyn =   -2, oxp =   11, oyp =   11,
  txn =  375, tyn =   70, txp =  388, typ =   83,
}
glyphs[119] = { --'w'--
  num = 119,
  adv = 12,
  oxn =   -2, oyn =   -2, oxp =   15, oyp =   11,
  txn =  397, tyn =   70, txp =  414, typ =   83,
}
glyphs[120] = { --'x'--
  num = 120,
  adv = 9,
  oxn =   -2, oyn =   -2, oxp =   11, oyp =   11,
  txn =  419, tyn =   70, txp =  432, typ =   83,
}
glyphs[121] = { --'y'--
  num = 121,
  adv = 9,
  oxn =   -2, oyn =   -6, oxp =   11, oyp =   11,
  txn =  441, tyn =   70, txp =  454, typ =   87,
}
glyphs[122] = { --'z'--
  num = 122,
  adv = 8,
  oxn =   -2, oyn =   -2, oxp =   10, oyp =   11,
  txn =  463, tyn =   70, txp =  475, typ =   83,
}
glyphs[123] = { --'{'--
  num = 123,
  adv = 6,
  oxn =   -2, oyn =   -6, oxp =    8, oyp =   14,
  txn =  485, tyn =   70, txp =  495, typ =   90,
}
glyphs[124] = { --'|'--
  num = 124,
  adv = 4,
  oxn =   -1, oyn =   -6, oxp =    5, oyp =   14,
  txn =    1, tyn =   93, txp =    7, typ =  113,
}
glyphs[125] = { --'}'--
  num = 125,
  adv = 6,
  oxn =   -1, oyn =   -6, oxp =    8, oyp =   14,
  txn =   23, tyn =   93, txp =   32, typ =  113,
}
glyphs[126] = { --'~'--
  num = 126,
  adv = 9,
  oxn =   -2, oyn =    0, oxp =   11, oyp =    8,
  txn =   45, tyn =   93, txp =   58, typ =  101,
}
glyphs[127] = { --''--
  num = 127,
  adv = 7,
  oxn =   -1, oyn =   -2, oxp =    9, oyp =   13,
  txn =   67, tyn =   93, txp =   77, typ =  108,
}
glyphs[128] = { --'Ä'--
  num = 128,
  adv = 7,
  oxn =   -1, oyn =   -2, oxp =    9, oyp =   13,
  txn =   89, tyn =   93, txp =   99, typ =  108,
}
glyphs[129] = { --'Å'--
  num = 129,
  adv = 7,
  oxn =   -1, oyn =   -2, oxp =    9, oyp =   13,
  txn =  111, tyn =   93, txp =  121, typ =  108,
}
glyphs[130] = { --'Ç'--
  num = 130,
  adv = 7,
  oxn =   -1, oyn =   -2, oxp =    9, oyp =   13,
  txn =  133, tyn =   93, txp =  143, typ =  108,
}
glyphs[131] = { --'É'--
  num = 131,
  adv = 7,
  oxn =   -1, oyn =   -2, oxp =    9, oyp =   13,
  txn =  155, tyn =   93, txp =  165, typ =  108,
}
glyphs[132] = { --'Ñ'--
  num = 132,
  adv = 7,
  oxn =   -1, oyn =   -2, oxp =    9, oyp =   13,
  txn =  177, tyn =   93, txp =  187, typ =  108,
}
glyphs[133] = { --'Ö'--
  num = 133,
  adv = 7,
  oxn =   -1, oyn =   -2, oxp =    9, oyp =   13,
  txn =  199, tyn =   93, txp =  209, typ =  108,
}
glyphs[134] = { --'Ü'--
  num = 134,
  adv = 7,
  oxn =   -1, oyn =   -2, oxp =    9, oyp =   13,
  txn =  221, tyn =   93, txp =  231, typ =  108,
}
glyphs[135] = { --'á'--
  num = 135,
  adv = 7,
  oxn =   -1, oyn =   -2, oxp =    9, oyp =   13,
  txn =  243, tyn =   93, txp =  253, typ =  108,
}
glyphs[136] = { --'à'--
  num = 136,
  adv = 7,
  oxn =   -1, oyn =   -2, oxp =    9, oyp =   13,
  txn =  265, tyn =   93, txp =  275, typ =  108,
}
glyphs[137] = { --'â'--
  num = 137,
  adv = 7,
  oxn =   -1, oyn =   -2, oxp =    9, oyp =   13,
  txn =  287, tyn =   93, txp =  297, typ =  108,
}
glyphs[138] = { --'ä'--
  num = 138,
  adv = 7,
  oxn =   -1, oyn =   -2, oxp =    9, oyp =   13,
  txn =  309, tyn =   93, txp =  319, typ =  108,
}
glyphs[139] = { --'ã'--
  num = 139,
  adv = 7,
  oxn =   -1, oyn =   -2, oxp =    9, oyp =   13,
  txn =  331, tyn =   93, txp =  341, typ =  108,
}
glyphs[140] = { --'å'--
  num = 140,
  adv = 7,
  oxn =   -1, oyn =   -2, oxp =    9, oyp =   13,
  txn =  353, tyn =   93, txp =  363, typ =  108,
}
glyphs[141] = { --'ç'--
  num = 141,
  adv = 7,
  oxn =   -1, oyn =   -2, oxp =    9, oyp =   13,
  txn =  375, tyn =   93, txp =  385, typ =  108,
}
glyphs[142] = { --'é'--
  num = 142,
  adv = 7,
  oxn =   -1, oyn =   -2, oxp =    9, oyp =   13,
  txn =  397, tyn =   93, txp =  407, typ =  108,
}
glyphs[143] = { --'è'--
  num = 143,
  adv = 7,
  oxn =   -1, oyn =   -2, oxp =    9, oyp =   13,
  txn =  419, tyn =   93, txp =  429, typ =  108,
}
glyphs[144] = { --'ê'--
  num = 144,
  adv = 7,
  oxn =   -1, oyn =   -2, oxp =    9, oyp =   13,
  txn =  441, tyn =   93, txp =  451, typ =  108,
}
glyphs[145] = { --'ë'--
  num = 145,
  adv = 7,
  oxn =   -1, oyn =   -2, oxp =    9, oyp =   13,
  txn =  463, tyn =   93, txp =  473, typ =  108,
}
glyphs[146] = { --'í'--
  num = 146,
  adv = 7,
  oxn =   -1, oyn =   -2, oxp =    9, oyp =   13,
  txn =  485, tyn =   93, txp =  495, typ =  108,
}
glyphs[147] = { --'ì'--
  num = 147,
  adv = 7,
  oxn =   -1, oyn =   -2, oxp =    9, oyp =   13,
  txn =    1, tyn =  116, txp =   11, typ =  131,
}
glyphs[148] = { --'î'--
  num = 148,
  adv = 7,
  oxn =   -1, oyn =   -2, oxp =    9, oyp =   13,
  txn =   23, tyn =  116, txp =   33, typ =  131,
}
glyphs[149] = { --'ï'--
  num = 149,
  adv = 7,
  oxn =   -1, oyn =   -2, oxp =    9, oyp =   13,
  txn =   45, tyn =  116, txp =   55, typ =  131,
}
glyphs[150] = { --'ñ'--
  num = 150,
  adv = 7,
  oxn =   -1, oyn =   -2, oxp =    9, oyp =   13,
  txn =   67, tyn =  116, txp =   77, typ =  131,
}
glyphs[151] = { --'ó'--
  num = 151,
  adv = 7,
  oxn =   -1, oyn =   -2, oxp =    9, oyp =   13,
  txn =   89, tyn =  116, txp =   99, typ =  131,
}
glyphs[152] = { --'ò'--
  num = 152,
  adv = 7,
  oxn =   -1, oyn =   -2, oxp =    9, oyp =   13,
  txn =  111, tyn =  116, txp =  121, typ =  131,
}
glyphs[153] = { --'ô'--
  num = 153,
  adv = 7,
  oxn =   -1, oyn =   -2, oxp =    9, oyp =   13,
  txn =  133, tyn =  116, txp =  143, typ =  131,
}
glyphs[154] = { --'ö'--
  num = 154,
  adv = 7,
  oxn =   -1, oyn =   -2, oxp =    9, oyp =   13,
  txn =  155, tyn =  116, txp =  165, typ =  131,
}
glyphs[155] = { --'õ'--
  num = 155,
  adv = 7,
  oxn =   -1, oyn =   -2, oxp =    9, oyp =   13,
  txn =  177, tyn =  116, txp =  187, typ =  131,
}
glyphs[156] = { --'ú'--
  num = 156,
  adv = 7,
  oxn =   -1, oyn =   -2, oxp =    9, oyp =   13,
  txn =  199, tyn =  116, txp =  209, typ =  131,
}
glyphs[157] = { --'ù'--
  num = 157,
  adv = 7,
  oxn =   -1, oyn =   -2, oxp =    9, oyp =   13,
  txn =  221, tyn =  116, txp =  231, typ =  131,
}
glyphs[158] = { --'û'--
  num = 158,
  adv = 7,
  oxn =   -1, oyn =   -2, oxp =    9, oyp =   13,
  txn =  243, tyn =  116, txp =  253, typ =  131,
}
glyphs[159] = { --'ü'--
  num = 159,
  adv = 7,
  oxn =   -1, oyn =   -2, oxp =    9, oyp =   13,
  txn =  265, tyn =  116, txp =  275, typ =  131,
}
glyphs[160] = { --'†'--
  num = 160,
  adv = 7,
  oxn =   -1, oyn =   -2, oxp =    9, oyp =   13,
  txn =  287, tyn =  116, txp =  297, typ =  131,
}
glyphs[161] = { --'°'--
  num = 161,
  adv = 5,
  oxn =   -1, oyn =   -5, oxp =    6, oyp =   11,
  txn =  309, tyn =  116, txp =  316, typ =  132,
}
glyphs[162] = { --'¢'--
  num = 162,
  adv = 9,
  oxn =   -2, oyn =   -4, oxp =   11, oyp =   13,
  txn =  331, tyn =  116, txp =  344, typ =  133,
}
glyphs[163] = { --'£'--
  num = 163,
  adv = 9,
  oxn =   -2, oyn =   -3, oxp =   11, oyp =   14,
  txn =  353, tyn =  116, txp =  366, typ =  133,
}
glyphs[164] = { --'§'--
  num = 164,
  adv = 9,
  oxn =   -2, oyn =   -1, oxp =   11, oyp =   12,
  txn =  375, tyn =  116, txp =  388, typ =  129,
}
glyphs[165] = { --'•'--
  num = 165,
  adv = 9,
  oxn =   -2, oyn =   -2, oxp =   11, oyp =   14,
  txn =  397, tyn =  116, txp =  410, typ =  132,
}
glyphs[166] = { --'¶'--
  num = 166,
  adv = 4,
  oxn =   -1, oyn =   -6, oxp =    5, oyp =   14,
  txn =  419, tyn =  116, txp =  425, typ =  136,
}
glyphs[167] = { --'ß'--
  num = 167,
  adv = 9,
  oxn =   -2, oyn =   -6, oxp =   11, oyp =   14,
  txn =  441, tyn =  116, txp =  454, typ =  136,
}
glyphs[168] = { --'®'--
  num = 168,
  adv = 5,
  oxn =   -2, oyn =    7, oxp =    8, oyp =   14,
  txn =  463, tyn =  116, txp =  473, typ =  123,
}
glyphs[169] = { --'©'--
  num = 169,
  adv = 12,
  oxn =   -3, oyn =   -3, oxp =   15, oyp =   14,
  txn =  485, tyn =  116, txp =  503, typ =  133,
}
glyphs[170] = { --'™'--
  num = 170,
  adv = 6,
  oxn =   -2, oyn =    2, oxp =    8, oyp =   14,
  txn =    1, tyn =  139, txp =   11, typ =  151,
}
glyphs[171] = { --'´'--
  num = 171,
  adv = 9,
  oxn =   -1, oyn =   -1, oxp =   10, oyp =   10,
  txn =   23, tyn =  139, txp =   34, typ =  150,
}
glyphs[172] = { --'¨'--
  num = 172,
  adv = 9,
  oxn =   -2, oyn =   -1, oxp =   11, oyp =    8,
  txn =   45, tyn =  139, txp =   58, typ =  148,
}
glyphs[173] = { --'≠'--
  num = 173,
  adv = 7,
  oxn =   -1, oyn =   -2, oxp =    9, oyp =   13,
  txn =   67, tyn =  139, txp =   77, typ =  154,
}
glyphs[174] = { --'Æ'--
  num = 174,
  adv = 12,
  oxn =   -3, oyn =   -3, oxp =   15, oyp =   14,
  txn =   89, tyn =  139, txp =  107, typ =  156,
}
glyphs[175] = { --'Ø'--
  num = 175,
  adv = 5,
  oxn =   -2, oyn =    8, oxp =    8, oyp =   14,
  txn =  111, tyn =  139, txp =  121, typ =  145,
}
glyphs[176] = { --'∞'--
  num = 176,
  adv = 10,
  oxn =    0, oyn =    4, oxp =   10, oyp =   13,
  txn =  133, tyn =  139, txp =  143, typ =  148,
}
glyphs[177] = { --'±'--
  num = 177,
  adv = 9,
  oxn =   -2, oyn =   -3, oxp =   11, oyp =   12,
  txn =  155, tyn =  139, txp =  168, typ =  154,
}
glyphs[178] = { --'≤'--
  num = 178,
  adv = 6,
  oxn =   -2, oyn =    2, oxp =    8, oyp =   14,
  txn =  177, tyn =  139, txp =  187, typ =  151,
}
glyphs[179] = { --'≥'--
  num = 179,
  adv = 6,
  oxn =   -2, oyn =    2, oxp =    8, oyp =   14,
  txn =  199, tyn =  139, txp =  209, typ =  151,
}
glyphs[180] = { --'¥'--
  num = 180,
  adv = 5,
  oxn =   -1, oyn =    7, oxp =    8, oyp =   15,
  txn =  221, tyn =  139, txp =  230, typ =  147,
}
glyphs[181] = { --'µ'--
  num = 181,
  adv = 10,
  oxn =   -2, oyn =   -6, oxp =   12, oyp =   11,
  txn =  243, tyn =  139, txp =  257, typ =  156,
}
glyphs[182] = { --'∂'--
  num = 182,
  adv = 9,
  oxn =   -2, oyn =   -6, oxp =   11, oyp =   14,
  txn =  265, tyn =  139, txp =  278, typ =  159,
}
glyphs[183] = { --'∑'--
  num = 183,
  adv = 4,
  oxn =   -1, oyn =    0, oxp =    6, oyp =    7,
  txn =  287, tyn =  139, txp =  294, typ =  146,
}
glyphs[184] = { --'∏'--
  num = 184,
  adv = 5,
  oxn =   -2, oyn =   -6, oxp =    7, oyp =    2,
  txn =  309, tyn =  139, txp =  318, typ =  147,
}
glyphs[185] = { --'π'--
  num = 185,
  adv = 6,
  oxn =   -2, oyn =    2, oxp =    6, oyp =   14,
  txn =  331, tyn =  139, txp =  339, typ =  151,
}
glyphs[186] = { --'∫'--
  num = 186,
  adv = 6,
  oxn =   -2, oyn =    2, oxp =    8, oyp =   14,
  txn =  353, tyn =  139, txp =  363, typ =  151,
}
glyphs[187] = { --'ª'--
  num = 187,
  adv = 9,
  oxn =   -1, oyn =   -1, oxp =   10, oyp =   10,
  txn =  375, tyn =  139, txp =  386, typ =  150,
}
glyphs[188] = { --'º'--
  num = 188,
  adv = 14,
  oxn =   -2, oyn =   -3, oxp =   16, oyp =   14,
  txn =  397, tyn =  139, txp =  415, typ =  156,
}
glyphs[189] = { --'Ω'--
  num = 189,
  adv = 14,
  oxn =   -2, oyn =   -3, oxp =   16, oyp =   14,
  txn =  419, tyn =  139, txp =  437, typ =  156,
}
glyphs[190] = { --'æ'--
  num = 190,
  adv = 14,
  oxn =   -2, oyn =   -3, oxp =   16, oyp =   14,
  txn =  441, tyn =  139, txp =  459, typ =  156,
}
glyphs[191] = { --'ø'--
  num = 191,
  adv = 10,
  oxn =   -2, oyn =   -6, oxp =   11, oyp =   11,
  txn =  463, tyn =  139, txp =  476, typ =  156,
}
glyphs[192] = { --'¿'--
  num = 192,
  adv = 12,
  oxn =   -2, oyn =   -2, oxp =   14, oyp =   18,
  txn =  485, tyn =  139, txp =  501, typ =  159,
}
glyphs[193] = { --'¡'--
  num = 193,
  adv = 12,
  oxn =   -2, oyn =   -2, oxp =   14, oyp =   18,
  txn =    1, tyn =  162, txp =   17, typ =  182,
}
glyphs[194] = { --'¬'--
  num = 194,
  adv = 12,
  oxn =   -2, oyn =   -2, oxp =   14, oyp =   18,
  txn =   23, tyn =  162, txp =   39, typ =  182,
}
glyphs[195] = { --'√'--
  num = 195,
  adv = 12,
  oxn =   -2, oyn =   -2, oxp =   14, oyp =   17,
  txn =   45, tyn =  162, txp =   61, typ =  181,
}
glyphs[196] = { --'ƒ'--
  num = 196,
  adv = 12,
  oxn =   -2, oyn =   -2, oxp =   14, oyp =   17,
  txn =   67, tyn =  162, txp =   83, typ =  181,
}
glyphs[197] = { --'≈'--
  num = 197,
  adv = 12,
  oxn =   -2, oyn =   -2, oxp =   14, oyp =   18,
  txn =   89, tyn =  162, txp =  105, typ =  182,
}
glyphs[198] = { --'∆'--
  num = 198,
  adv = 16,
  oxn =   -2, oyn =   -2, oxp =   18, oyp =   14,
  txn =  111, tyn =  162, txp =  131, typ =  178,
}
glyphs[199] = { --'«'--
  num = 199,
  adv = 12,
  oxn =   -2, oyn =   -6, oxp =   13, oyp =   14,
  txn =  133, tyn =  162, txp =  148, typ =  182,
}
glyphs[200] = { --'»'--
  num = 200,
  adv = 11,
  oxn =   -1, oyn =   -2, oxp =   12, oyp =   18,
  txn =  155, tyn =  162, txp =  168, typ =  182,
}
glyphs[201] = { --'…'--
  num = 201,
  adv = 11,
  oxn =   -1, oyn =   -2, oxp =   12, oyp =   18,
  txn =  177, tyn =  162, txp =  190, typ =  182,
}
glyphs[202] = { --' '--
  num = 202,
  adv = 11,
  oxn =   -1, oyn =   -2, oxp =   12, oyp =   18,
  txn =  199, tyn =  162, txp =  212, typ =  182,
}
glyphs[203] = { --'À'--
  num = 203,
  adv = 11,
  oxn =   -1, oyn =   -2, oxp =   12, oyp =   17,
  txn =  221, tyn =  162, txp =  234, typ =  181,
}
glyphs[204] = { --'Ã'--
  num = 204,
  adv = 4,
  oxn =   -2, oyn =   -2, oxp =    6, oyp =   18,
  txn =  243, tyn =  162, txp =  251, typ =  182,
}
glyphs[205] = { --'Õ'--
  num = 205,
  adv = 4,
  oxn =   -1, oyn =   -2, oxp =    8, oyp =   18,
  txn =  265, tyn =  162, txp =  274, typ =  182,
}
glyphs[206] = { --'Œ'--
  num = 206,
  adv = 4,
  oxn =   -2, oyn =   -2, oxp =    8, oyp =   18,
  txn =  287, tyn =  162, txp =  297, typ =  182,
}
glyphs[207] = { --'œ'--
  num = 207,
  adv = 4,
  oxn =   -2, oyn =   -2, oxp =    8, oyp =   17,
  txn =  309, tyn =  162, txp =  319, typ =  181,
}
glyphs[208] = { --'–'--
  num = 208,
  adv = 12,
  oxn =   -2, oyn =   -2, oxp =   13, oyp =   14,
  txn =  331, tyn =  162, txp =  346, typ =  178,
}
glyphs[209] = { --'—'--
  num = 209,
  adv = 12,
  oxn =   -1, oyn =   -2, oxp =   13, oyp =   17,
  txn =  353, tyn =  162, txp =  367, typ =  181,
}
glyphs[210] = { --'“'--
  num = 210,
  adv = 12,
  oxn =   -2, oyn =   -3, oxp =   14, oyp =   18,
  txn =  375, tyn =  162, txp =  391, typ =  183,
}
glyphs[211] = { --'”'--
  num = 211,
  adv = 12,
  oxn =   -2, oyn =   -3, oxp =   14, oyp =   18,
  txn =  397, tyn =  162, txp =  413, typ =  183,
}
glyphs[212] = { --'‘'--
  num = 212,
  adv = 12,
  oxn =   -2, oyn =   -3, oxp =   14, oyp =   18,
  txn =  419, tyn =  162, txp =  435, typ =  183,
}
glyphs[213] = { --'’'--
  num = 213,
  adv = 12,
  oxn =   -2, oyn =   -3, oxp =   14, oyp =   17,
  txn =  441, tyn =  162, txp =  457, typ =  182,
}
glyphs[214] = { --'÷'--
  num = 214,
  adv = 12,
  oxn =   -2, oyn =   -3, oxp =   14, oyp =   17,
  txn =  463, tyn =  162, txp =  479, typ =  182,
}
glyphs[215] = { --'◊'--
  num = 215,
  adv = 9,
  oxn =   -1, oyn =   -2, oxp =   11, oyp =   10,
  txn =  485, tyn =  162, txp =  497, typ =  174,
}
glyphs[216] = { --'ÿ'--
  num = 216,
  adv = 12,
  oxn =   -2, oyn =   -3, oxp =   15, oyp =   14,
  txn =    1, tyn =  185, txp =   18, typ =  202,
}
glyphs[217] = { --'Ÿ'--
  num = 217,
  adv = 12,
  oxn =   -1, oyn =   -3, oxp =   13, oyp =   18,
  txn =   23, tyn =  185, txp =   37, typ =  206,
}
glyphs[218] = { --'⁄'--
  num = 218,
  adv = 12,
  oxn =   -1, oyn =   -3, oxp =   13, oyp =   18,
  txn =   45, tyn =  185, txp =   59, typ =  206,
}
glyphs[219] = { --'€'--
  num = 219,
  adv = 12,
  oxn =   -1, oyn =   -3, oxp =   13, oyp =   18,
  txn =   67, tyn =  185, txp =   81, typ =  206,
}
glyphs[220] = { --'‹'--
  num = 220,
  adv = 12,
  oxn =   -1, oyn =   -3, oxp =   13, oyp =   17,
  txn =   89, tyn =  185, txp =  103, typ =  205,
}
glyphs[221] = { --'›'--
  num = 221,
  adv = 11,
  oxn =   -2, oyn =   -2, oxp =   13, oyp =   18,
  txn =  111, tyn =  185, txp =  126, typ =  205,
}
glyphs[222] = { --'ﬁ'--
  num = 222,
  adv = 11,
  oxn =   -1, oyn =   -2, oxp =   13, oyp =   14,
  txn =  133, tyn =  185, txp =  147, typ =  201,
}
glyphs[223] = { --'ﬂ'--
  num = 223,
  adv = 10,
  oxn =   -1, oyn =   -3, oxp =   12, oyp =   14,
  txn =  155, tyn =  185, txp =  168, typ =  202,
}
glyphs[224] = { --'‡'--
  num = 224,
  adv = 9,
  oxn =   -2, oyn =   -3, oxp =   11, oyp =   15,
  txn =  177, tyn =  185, txp =  190, typ =  203,
}
glyphs[225] = { --'·'--
  num = 225,
  adv = 9,
  oxn =   -2, oyn =   -3, oxp =   11, oyp =   15,
  txn =  199, tyn =  185, txp =  212, typ =  203,
}
glyphs[226] = { --'‚'--
  num = 226,
  adv = 9,
  oxn =   -2, oyn =   -3, oxp =   11, oyp =   15,
  txn =  221, tyn =  185, txp =  234, typ =  203,
}
glyphs[227] = { --'„'--
  num = 227,
  adv = 9,
  oxn =   -2, oyn =   -3, oxp =   11, oyp =   14,
  txn =  243, tyn =  185, txp =  256, typ =  202,
}
glyphs[228] = { --'‰'--
  num = 228,
  adv = 9,
  oxn =   -2, oyn =   -3, oxp =   11, oyp =   14,
  txn =  265, tyn =  185, txp =  278, typ =  202,
}
glyphs[229] = { --'Â'--
  num = 229,
  adv = 9,
  oxn =   -2, oyn =   -3, oxp =   11, oyp =   15,
  txn =  287, tyn =  185, txp =  300, typ =  203,
}
glyphs[230] = { --'Ê'--
  num = 230,
  adv = 14,
  oxn =   -2, oyn =   -3, oxp =   16, oyp =   11,
  txn =  309, tyn =  185, txp =  327, typ =  199,
}
glyphs[231] = { --'Á'--
  num = 231,
  adv = 9,
  oxn =   -2, oyn =   -6, oxp =   11, oyp =   11,
  txn =  331, tyn =  185, txp =  344, typ =  202,
}
glyphs[232] = { --'Ë'--
  num = 232,
  adv = 9,
  oxn =   -2, oyn =   -3, oxp =   11, oyp =   15,
  txn =  353, tyn =  185, txp =  366, typ =  203,
}
glyphs[233] = { --'È'--
  num = 233,
  adv = 9,
  oxn =   -2, oyn =   -3, oxp =   11, oyp =   15,
  txn =  375, tyn =  185, txp =  388, typ =  203,
}
glyphs[234] = { --'Í'--
  num = 234,
  adv = 9,
  oxn =   -2, oyn =   -3, oxp =   11, oyp =   15,
  txn =  397, tyn =  185, txp =  410, typ =  203,
}
glyphs[235] = { --'Î'--
  num = 235,
  adv = 9,
  oxn =   -2, oyn =   -3, oxp =   11, oyp =   14,
  txn =  419, tyn =  185, txp =  432, typ =  202,
}
glyphs[236] = { --'Ï'--
  num = 236,
  adv = 4,
  oxn =   -2, oyn =   -2, oxp =    6, oyp =   15,
  txn =  441, tyn =  185, txp =  449, typ =  202,
}
glyphs[237] = { --'Ì'--
  num = 237,
  adv = 4,
  oxn =   -1, oyn =   -2, oxp =    8, oyp =   15,
  txn =  463, tyn =  185, txp =  472, typ =  202,
}
glyphs[238] = { --'Ó'--
  num = 238,
  adv = 4,
  oxn =   -2, oyn =   -2, oxp =    8, oyp =   15,
  txn =  485, tyn =  185, txp =  495, typ =  202,
}
glyphs[239] = { --'Ô'--
  num = 239,
  adv = 4,
  oxn =   -2, oyn =   -2, oxp =    8, oyp =   14,
  txn =    1, tyn =  208, txp =   11, typ =  224,
}
glyphs[240] = { --''--
  num = 240,
  adv = 10,
  oxn =   -2, oyn =   -3, oxp =   12, oyp =   14,
  txn =   23, tyn =  208, txp =   37, typ =  225,
}
glyphs[241] = { --'Ò'--
  num = 241,
  adv = 10,
  oxn =   -1, oyn =   -2, oxp =   11, oyp =   14,
  txn =   45, tyn =  208, txp =   57, typ =  224,
}
glyphs[242] = { --'Ú'--
  num = 242,
  adv = 10,
  oxn =   -2, oyn =   -3, oxp =   12, oyp =   15,
  txn =   67, tyn =  208, txp =   81, typ =  226,
}
glyphs[243] = { --'Û'--
  num = 243,
  adv = 10,
  oxn =   -2, oyn =   -3, oxp =   12, oyp =   15,
  txn =   89, tyn =  208, txp =  103, typ =  226,
}
glyphs[244] = { --'Ù'--
  num = 244,
  adv = 10,
  oxn =   -2, oyn =   -3, oxp =   12, oyp =   15,
  txn =  111, tyn =  208, txp =  125, typ =  226,
}
glyphs[245] = { --'ı'--
  num = 245,
  adv = 10,
  oxn =   -2, oyn =   -3, oxp =   12, oyp =   14,
  txn =  133, tyn =  208, txp =  147, typ =  225,
}
glyphs[246] = { --'ˆ'--
  num = 246,
  adv = 10,
  oxn =   -2, oyn =   -3, oxp =   12, oyp =   14,
  txn =  155, tyn =  208, txp =  169, typ =  225,
}
glyphs[247] = { --'˜'--
  num = 247,
  adv = 9,
  oxn =   -2, oyn =   -3, oxp =   11, oyp =   10,
  txn =  177, tyn =  208, txp =  190, typ =  221,
}
glyphs[248] = { --'¯'--
  num = 248,
  adv = 10,
  oxn =   -2, oyn =   -3, oxp =   12, oyp =   11,
  txn =  199, tyn =  208, txp =  213, typ =  222,
}
glyphs[249] = { --'˘'--
  num = 249,
  adv = 10,
  oxn =   -2, oyn =   -3, oxp =   11, oyp =   15,
  txn =  221, tyn =  208, txp =  234, typ =  226,
}
glyphs[250] = { --'˙'--
  num = 250,
  adv = 10,
  oxn =   -2, oyn =   -3, oxp =   11, oyp =   15,
  txn =  243, tyn =  208, txp =  256, typ =  226,
}
glyphs[251] = { --'˚'--
  num = 251,
  adv = 10,
  oxn =   -2, oyn =   -3, oxp =   11, oyp =   15,
  txn =  265, tyn =  208, txp =  278, typ =  226,
}
glyphs[252] = { --'¸'--
  num = 252,
  adv = 10,
  oxn =   -2, oyn =   -3, oxp =   11, oyp =   14,
  txn =  287, tyn =  208, txp =  300, typ =  225,
}
glyphs[253] = { --'˝'--
  num = 253,
  adv = 9,
  oxn =   -2, oyn =   -6, oxp =   11, oyp =   15,
  txn =  309, tyn =  208, txp =  322, typ =  229,
}
glyphs[254] = { --'˛'--
  num = 254,
  adv = 10,
  oxn =   -2, oyn =   -6, oxp =   12, oyp =   14,
  txn =  331, tyn =  208, txp =  345, typ =  228,
}
glyphs[255] = { --'ˇ'--
  num = 255,
  adv = 9,
  oxn =   -2, oyn =   -6, oxp =   11, oyp =   14,
  txn =  353, tyn =  208, txp =  366, typ =  228,
}

fontSpecs.glyphs = glyphs

return fontSpecs

