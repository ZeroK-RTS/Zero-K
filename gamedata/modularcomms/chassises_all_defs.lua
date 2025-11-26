
if not Spring.ModularCommAPI then
    Spring.ModularCommAPI={}
end
if not Spring.ModularCommAPI.Chassises then
    local Chassises={}
    Spring.ModularCommAPI.Chassises=Chassises
    local chassisFiles=VFS.DirList("gamedata/modularcomms/chassises", "*.lua") or {}
    for i = 1, #chassisFiles do
        local chassisDef = VFS.Include(chassisFiles[i])
        Chassises[#Chassises+1]=chassisDef
    end
end
return Spring.ModularCommAPI.Chassises