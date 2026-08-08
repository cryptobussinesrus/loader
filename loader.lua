if not game:IsLoaded() then
    game.Loaded:Wait()
end

repeat task.wait() until game.Players.LocalPlayer

local BASE = 'https://raw.githubusercontent.com/cryptobussinesrus/loader/main/games/'

local games = {
    [137233438285284] = 'chicken-farm.lua',
    [83645629621104]  = 'Forsaken.lua',
    [82554996468034]  = '+1-Pickaxe-Swing-Escape.lua',
    [114697347887839] = '+1-Speed-Monkey-Escape.lua',
}

local file = games[game.PlaceId]
print("PlaceId:", game.PlaceId, "File:", file)

if file then
    task.wait(math.random())
    local success, err = pcall(function()
        loadstring(game:HttpGet(BASE .. file))()
    end)
end
