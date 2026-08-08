if not game:IsLoaded() then
    game.Loaded:Wait()
end

local BASE = 'https://raw.githubusercontent.com/cryptobussinesrus/loader/main/games/'

local games = {
    [137233438285284] = 'chicken-farm.lua',
    [18687417158]  = 'Forsaken.lua',
    [82554996468034] = '+1-Pickaxe-Swing-Escape.lua'
}

local file = games[game.PlaceId]
if file then
    task.wait(math.random())
    loadstring(game:HttpGet(BASE .. file))()
end