if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

local BASE = "https://raw.githubusercontent.com/cryptobussinesrus/loader/main/games/"

local games = {

    {
        Name = "Chicken Farm",
        File = "chicken-farm.lua",
        Places = {
            137233438285284,
        },
    },

    {
        Name = "Murder Mystery 2",
        File = "mm2.lua",
        Places = {
            142823291,
        },
    },
    
    {
        Name = "Forsaken",
        File = "Forsaken.lua",
        Places = {
            83645629621104,
        },
    },

    {
        Name = "+1 Pickaxe Swing Escape",
        File = "+1-Pickaxe-Swing-Escape.lua",
        Places = {
            82554996468034,
        },
    },

    {
        Name = "+1 Speed Monkey Escape",
        File = "+1-Speed-Monkey-Escape.lua",
        Places = {
            114697347887839,
        },
    },

    {
        Name = "+1 Cut Grass Adventure",
        File = "+1-Cut-Grass-Adventure.lua",
        Places = {
            90086669327265,
        },
    },

    {
        Name = "Throw a Coin",
        File = "Throw-a-Coin.lua",
        Places = {
        115681808123944,
        72042130041700,
        100875131717601,
        --world 4 - give me placeid
        },
    },
}

local placeId = game.PlaceId
local universeId = game.GameId

local selectedGame = nil

for _, gameInfo in ipairs(games) do
    for _, id in ipairs(gameInfo.Places) do
        if id == placeId then
            selectedGame = gameInfo
            break
        end
    end

    if selectedGame then
        break
    end
end

print("========================================")
print(" Universal Game Loader")
print("========================================")
print("Player:", LocalPlayer.Name)
print("UniverseId:", universeId)
print("PlaceId:", placeId)

if not selectedGame then
    warn("No script configured for this PlaceId.")
    print("PlaceId:", placeId)
    print("========================================")
    return
end

print("Game:", selectedGame.Name)
print("File:", selectedGame.File)
print("========================================")

local url = BASE .. selectedGame.File

local MAX_ATTEMPTS = 3
local loaded = false

for attempt = 1, MAX_ATTEMPTS do

    print(
        string.format(
            "[Loader] Loading %s... (%d/%d)",
            selectedGame.File,
            attempt,
            MAX_ATTEMPTS
        )
    )

    local success, result = pcall(function()
        local source = game:HttpGet(url)

        if not source or source == "" then
            error("Downloaded script is empty.")
        end

        local func, compileError = loadstring(source)

        if not func then
            error("Compile error: " .. tostring(compileError))
        end

        return func()
    end)

    if success then
        loaded = true

        print(
            "[Loader] Successfully loaded:",
            selectedGame.File
        )

        break
    else
        warn(
            string.format(
                "[Loader] Attempt %d failed: %s",
                attempt,
                tostring(result)
            )
        )

        if attempt < MAX_ATTEMPTS then
            task.wait(1.5)
        end
    end
end

if not loaded then
    warn("========================================")
    warn("[Loader] FAILED TO LOAD SCRIPT")
    warn("File:", selectedGame.File)
    warn("URL:", url)
    warn("PlaceId:", placeId)
    warn("========================================")
end
