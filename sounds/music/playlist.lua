-- IMPORTANT: No table specified for a type means autodetect,
-- empty table specified for a type means no tracks for that type!
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