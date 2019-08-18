-- IMPORTANT: No table specified for a type means autodetect,
-- empty table specified for a type means no tracks for that type!

-- To change the music used in each circumstance, add the file name of the track, ("Earth.ogg", for example)
-- inside the curly brackets of that circumstance (in the curly brackets of "--peace = {}," for example).
-- The file (e.g. "Earth.ogg") must be in the corresponding sub folder of [InsertGameDataFolderHere]/sounds/music
-- as the circumstance you want it to be played in ([InsertGameDataFolderHere]/sounds/music/peace for example).

local tracks = {
    --war = {},
    --peace = {},
    --victory = {},
    --briefing = {},
    --defeat = {},
}

-- auto-appends directory and extension to the track names
-- can be removed if you want to specify directory yourself
for type,list in pairs(tracks) do
    for i=1,#list do
	list[i] = "sounds/music/"..type.."/"..list[i]..".ogg"
    end
end

return tracks
