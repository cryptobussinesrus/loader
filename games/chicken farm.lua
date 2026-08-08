local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local userInput = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")

local player = Players.LocalPlayer
local configFileName = "ChickenFarm_vymiw_config.json"

local function loadConfig()
    local ok, data = pcall(function()
        if readfile and isfile and isfile(configFileName) then
            return HttpService:JSONDecode(readfile(configFileName))
        end
    end)
    if ok and type(data) == "table" then
        return data
    end
    return nil
end

local savedCfg = loadConfig()

local Settings = {
    AutoCollectEggs = savedCfg and savedCfg.AutoCollectEggs or false,
    DeleteLuckyBlock = savedCfg and savedCfg.DeleteLuckyBlock or false,
    AntiAFK = savedCfg and savedCfg.AntiAFK or false,
    CollectCash = savedCfg and savedCfg.CollectCash or false,
    UpgradeProcess = savedCfg and savedCfg.UpgradeProcess or false,
    BuyChickens = savedCfg and savedCfg.BuyChickens or false,
    BuyTier = savedCfg and savedCfg.BuyTier or false,
    MergeChickens = savedCfg and savedCfg.MergeChickens or false,
    HideLeftUI = savedCfg and savedCfg.HideLeftUI or false,
    AutoRebirth = savedCfg and savedCfg.AutoRebirth or false,
    AutoDeposit = savedCfg and savedCfg.AutoDeposit or false,
    DepositThreshold = savedCfg and savedCfg.DepositThreshold or 1.5
}

local function cleanupOldGUI()
    for _, parent in ipairs({player:FindFirstChild("PlayerGui"), CoreGui}) do
        if parent then
            local oldGui = parent:FindFirstChild("AutoFarmGUI")
            if oldGui then
                oldGui:Destroy()
            end
        end
    end
end
cleanupOldGUI()

local isRunning = true
local connections = {}
local lastAfkTick = 0

local screenGui = Instance.new("ScreenGui")
screenGui.Parent = player:WaitForChild("PlayerGui")
screenGui.Name = "AutoFarmGUI"
screenGui.ResetOnSpawn = false

local frame = Instance.new("Frame")
frame.Parent = screenGui
frame.Size = UDim2.new(0, 395, 0, 460)
frame.Position = UDim2.new(0.8, 0, 0.15, 0)
frame.BackgroundColor3 = Color3.new(0.12, 0.12, 0.12)
frame.BorderSizePixel = 0
frame.Active = true
frame.ClipsDescendants = true
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)
local frStroke = Instance.new("UIStroke", frame); frStroke.Color = Color3.fromRGB(80,80,95); frStroke.Thickness = 1

local titleBar = Instance.new("Frame")
titleBar.Parent = frame
titleBar.Size = UDim2.new(1, 0, 0, 30)
titleBar.Position = UDim2.new(0, 0, 0, 0)
titleBar.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
titleBar.BorderSizePixel = 0
titleBar.Active = true
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 12)

local title = Instance.new("TextLabel")
title.Parent = titleBar
title.Size = UDim2.new(1, -70, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.Text = "Chicken Farm By vymiw"
title.TextColor3 = Color3.new(1, 1, 1)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 15
title.TextXAlignment = Enum.TextXAlignment.Left

local closeBtn = Instance.new("TextButton")
closeBtn.Parent = titleBar
closeBtn.Size = UDim2.new(0, 22, 0, 22)
closeBtn.Position = UDim2.new(1, -26, 0.5, -11)
closeBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 13
closeBtn.BorderSizePixel = 0
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

local minBtn = Instance.new("TextButton")
minBtn.Parent = titleBar
minBtn.Size = UDim2.new(0, 22, 0, 22)
minBtn.Position = UDim2.new(1, -52, 0.5, -11)
minBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 220)
minBtn.Text = "-"
minBtn.TextColor3 = Color3.new(1, 1, 1)
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 16
minBtn.BorderSizePixel = 0
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 6)

local isMinimized = false
table.insert(connections, minBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    local targetHeight = isMinimized and 30 or 460
    
    local tweenInfo = TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    local tween = TweenService:Create(frame, tweenInfo, {Size = UDim2.new(0, 395, 0, targetHeight)})
    tween:Play()
    
    minBtn.Text = isMinimized and "+" or "-"
end))

local function saveConfig()
    pcall(function()
        if writefile then
            writefile(configFileName, HttpService:JSONEncode(Settings))
        end
    end)
end

local function shutdownScript()
    saveConfig()
    isRunning = false
    for _, conn in ipairs(connections) do
        if conn.Connected then conn:Disconnect() end
    end
    table.clear(connections)
    
    pcall(function() 
        local leftUI = player.PlayerGui:FindFirstChild("Main") and player.PlayerGui.Main:FindFirstChild("Left")
        if leftUI then leftUI.Visible = true end
    end)
    
    if screenGui then screenGui:Destroy() end
end

closeBtn.MouseButton1Click:Connect(shutdownScript)

local dragging, dragInput, dragStart, startPos
table.insert(connections, titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
        local inputConn
        inputConn = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
                if inputConn then inputConn:Disconnect() end
            end
        end)
    end
end))

table.insert(connections, titleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end))

table.insert(connections, userInput.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end))

table.insert(connections, userInput.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        frame.Visible = not frame.Visible
    end
end))

local function createToggle(name, labelText, yPos, default)
    local toggleFrame = Instance.new("Frame")
    toggleFrame.Parent = frame
    toggleFrame.Size = UDim2.new(1, -20, 0, 28)
    toggleFrame.Position = UDim2.new(0, 10, 0, yPos)
    toggleFrame.BackgroundTransparency = 1

    local label = Instance.new("TextLabel")
    label.Parent = toggleFrame
    label.Size = UDim2.new(0.55, 0, 1, 0)
    label.Text = labelText
    label.TextColor3 = Color3.new(1, 1, 1)
    label.BackgroundTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.Gotham
    label.TextSize = 13

    local state = Settings[name] ~= nil and Settings[name] or default
    Settings[name] = state

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Parent = toggleFrame
    toggleBtn.Size = UDim2.new(0.42, 0, 1, 0)
    toggleBtn.Position = UDim2.new(0.58, 0, 0, 0)
    toggleBtn.BackgroundColor3 = state and Color3.new(0, 1, 0) or Color3.new(1, 0, 0)
    toggleBtn.Text = state and "ON" or "OFF"
    toggleBtn.TextColor3 = Color3.new(1, 1, 1)
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextSize = 12
    toggleBtn.BorderSizePixel = 0
    Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 6)

    table.insert(connections, toggleBtn.MouseButton1Click:Connect(function()
        state = not state
        toggleBtn.BackgroundColor3 = state and Color3.new(0, 1, 0) or Color3.new(1, 0, 0)
        toggleBtn.Text = state and "ON" or "OFF"
        Settings[name] = state
        saveConfig()
    end))

    return toggleFrame
end

createToggle("AutoCollectEggs", "Auto Collect Eggs", 40, Settings.AutoCollectEggs)
createToggle("DeleteLuckyBlock", "Delete Lucky Block", 74, Settings.DeleteLuckyBlock)
createToggle("AntiAFK", "Anti-AFK", 108, Settings.AntiAFK)
createToggle("CollectCash", "Collect Cash", 142, Settings.CollectCash)
createToggle("UpgradeProcess", "Fast Upgrade Process", 176, Settings.UpgradeProcess)
createToggle("BuyChickens", "Buy Chickens", 210, Settings.BuyChickens)
createToggle("BuyTier", "Buy Tier (Plot)", 244, Settings.BuyTier)
createToggle("MergeChickens", "Merge Chickens", 278, Settings.MergeChickens)
createToggle("AutoRebirth", "Auto Rebirth", 312, Settings.AutoRebirth)
createToggle("HideLeftUI", "Hide Left Game UI", 346, Settings.HideLeftUI)
createToggle("AutoDeposit", "Auto Deposit Eggs", 380, Settings.AutoDeposit)

local sliderContainer = Instance.new("Frame")
sliderContainer.Parent = frame
sliderContainer.Size = UDim2.new(1, -20, 0, 32)
sliderContainer.Position = UDim2.new(0, 10, 0, 414)
sliderContainer.BackgroundTransparency = 1

local sliderLabel = Instance.new("TextLabel")
sliderLabel.Parent = sliderContainer
sliderLabel.Size = UDim2.new(1, 0, 0, 14)
sliderLabel.Text = string.format("Threshold: %.2f", Settings.DepositThreshold)
sliderLabel.TextColor3 = Color3.fromRGB(220, 220, 230)
sliderLabel.BackgroundTransparency = 1
sliderLabel.Font = Enum.Font.Gotham
sliderLabel.TextSize = 11
sliderLabel.TextXAlignment = Enum.TextXAlignment.Left

local sliderBar = Instance.new("Frame")
sliderBar.Parent = sliderContainer
sliderBar.Size = UDim2.new(1, 0, 0, 6)
sliderBar.Position = UDim2.new(0, 0, 0, 18)
sliderBar.BackgroundColor3 = Color3.fromRGB(45, 48, 58)
sliderBar.BorderSizePixel = 0
Instance.new("UICorner", sliderBar).CornerRadius = UDim.new(0, 3)

local sliderFill = Instance.new("Frame")
sliderFill.Parent = sliderBar
local minVal, maxVal = 0.5, 1.5
local initialPos = math.clamp((Settings.DepositThreshold - minVal) / (maxVal - minVal), 0, 1)
sliderFill.Size = UDim2.new(initialPos, 0, 1, 0)
sliderFill.BackgroundColor3 = Color3.fromRGB(80, 140, 255)
sliderFill.BorderSizePixel = 0
Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(0, 3)

local sliderButton = Instance.new("TextButton")
sliderButton.Parent = sliderBar
sliderButton.Size = UDim2.new(0, 10, 0, 14)
sliderButton.Position = UDim2.new(initialPos, -5, 0.5, -7)
sliderButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
sliderButton.Text = ""
sliderButton.BorderSizePixel = 0
Instance.new("UICorner", sliderButton).CornerRadius = UDim.new(0, 3)

local function updateSlider(inputX)
    local absPos = sliderBar.AbsolutePosition.X
    local absSize = sliderBar.AbsoluteSize.X
    local pos = math.clamp((inputX - absPos) / absSize, 0, 1)
    local rawValue = minVal + pos * (maxVal - minVal)
    local steppedValue = math.floor(rawValue * 100 + 0.5) / 100
    local exactPos = (steppedValue - minVal) / (maxVal - minVal)
    sliderFill.Size = UDim2.new(exactPos, 0, 1, 0)
    sliderButton.Position = UDim2.new(exactPos, -5, 0.5, -7)
    Settings.DepositThreshold = steppedValue
    sliderLabel.Text = string.format("Threshold: %.2f", steppedValue)
end

local sliderDragging = false
table.insert(connections, sliderButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        sliderDragging = true
    end
end))

table.insert(connections, sliderBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        sliderDragging = true
        updateSlider(input.Position.X)
        saveConfig()
    end
end))

table.insert(connections, userInput.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if sliderDragging then sliderDragging = false saveConfig() end
    end
end))

table.insert(connections, userInput.InputChanged:Connect(function(input)
    if sliderDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        updateSlider(input.Position.X)
    end
end))

local priceSuffixes = {
    k = 1e3, m = 1e6, b = 1e9, t = 1e12, 
    qa = 1e15, qi = 1e18, sx = 1e21, sp = 1e24, 
    oc = 1e27, no = 1e30, dc = 1e33, un = 1e36
}

local function parseSuffixedNumber(str)
    if not str then return 0 end
    str = str:gsub("[%$,%s]", "")
    local numberPart, suffixPart = str:match("^(-?%d*%.?%d+)(%a*)$")
    if not numberPart then return 0 end
    local base = tonumber(numberPart)
    if not base then return 0 end
    if suffixPart == "" then return base end
    local suffixLower = suffixPart:lower()
    local multiplier = priceSuffixes[suffixLower]
    if multiplier then
        return base * multiplier
    else
        return base
    end
end

task.spawn(function()
    while isRunning do
        task.wait(300) 
        pcall(function() collectgarbage("collect") end)
    end
end)

task.spawn(function()
    local mainEvent, mainFunction, eggMultiplier
    
    while isRunning do
        pcall(function()
            local paper = ReplicatedStorage:FindFirstChild("Paper")
            if paper then
                local remotes = paper:FindFirstChild("Remotes")
                if remotes then
                    mainEvent = remotes:FindFirstChild("__remoteevent")
                    mainFunction = remotes:FindFirstChild("__remotefunction")
                end
            end
            local values = ReplicatedStorage:FindFirstChild("Values")
            if values then
                eggMultiplier = values:FindFirstChild("EggMultiplier")
            end
        end)
        
        if mainEvent and mainFunction then break end
        task.wait(1)
    end

    task.spawn(function()
        local eggsFolder
        while isRunning do
            eggsFolder = Workspace:FindFirstChild("Eggs")
            if eggsFolder then break end
            task.wait(1)
        end
        
        if eggsFolder then
            table.insert(connections, eggsFolder.ChildAdded:Connect(function(obj)
                if not isRunning then return end
                task.wait(0.3) 
                if not obj or not obj.Parent or not isRunning then return end

                local isLucky = obj:GetAttribute("LuckyBlock") ~= nil
                if isLucky and not Settings.DeleteLuckyBlock then return end

                if Settings.AutoCollectEggs and mainEvent then
                    pcall(function() mainEvent:FireServer("Collect Egg", obj.Name) end)
                    task.wait(0.05)
                    pcall(function() if obj and obj.Parent then obj:Destroy() end end)
                end
            end))
        end
    end)

    table.insert(connections, player.Idled:Connect(function()
        if not Settings.AntiAFK or not isRunning then return end
        VirtualUser:Button2Down(Vector2.new(0,0)); task.wait(0.1); VirtualUser:Button2Up(Vector2.new(0,0))
    end))
    pcall(function() VirtualUser:CaptureController() end)

    task.spawn(function()
        while isRunning do
            if not screenGui or not screenGui.Parent then shutdownScript() break end
            if Settings.AntiAFK then
                local now = os.clock()
                if now - lastAfkTick >= 240 then
                    pcall(function() VirtualUser:Button2Down(Vector2.new(0,0)); task.wait(0.05); VirtualUser:Button2Up(Vector2.new(0,0)) end)
                    lastAfkTick = now
                end
            end
            task.wait(1)
        end
    end)

    while isRunning do
        if not screenGui or not screenGui.Parent then shutdownScript() break end
        
        if not (Settings.CollectCash or Settings.BuyChickens or Settings.BuyTier or Settings.MergeChickens or Settings.UpgradeProcess or Settings.AutoDeposit or Settings.AutoRebirth or Settings.HideLeftUI) then
            task.wait(1)
            continue
        end
        
        pcall(function()
            local mainUI = player.PlayerGui:FindFirstChild("Main")
            local leftUI = mainUI and mainUI:FindFirstChild("Left")
            if leftUI then leftUI.Visible = not Settings.HideLeftUI end
        end)
        
        if Settings.CollectCash then
            task.spawn(function()
                pcall(function() mainFunction:InvokeServer("Collect Cash") end)
            end)
        end

local function getMyPlot()
    local plotsFolder = Workspace:FindFirstChild("Plots")
    if not plotsFolder then return nil end
    
    for _, plot in pairs(plotsFolder:GetChildren()) do
    	
        local owner = plot:FindFirstChild("Owner") or plot:FindFirstChild("PlayerId")
        if owner and owner.Value == player.UserId then
            return plot
        end

        if plot.Name == player.Name then
            return plot
        end
    end
    return nil
end

local lastUpgradeTime = 0
local lastBuyTierTime = 0
local clickCooldown = 0.8

local function getMyPlot()
    local plots = Workspace:FindFirstChild("Plots")
    if not plots then return nil end
    
    local myPlot = plots:FindFirstChild(player.Name)
    if myPlot then return myPlot end

    for _, plot in pairs(plots:GetChildren()) do
        local owner = plot:FindFirstChild("Owner") or plot:FindFirstChild("PlayerId")
        if owner and owner.Value == player.UserId then
            return plot
        end

        if plot:GetAttribute("OwnerId") == player.UserId then
            return plot
        end
    end
    return nil
end

local lastUpgradeTime = 0
local lastBuyTierTime = 0
local clickCooldown = 0.5


    while isRunning do
        if not screenGui or not screenGui.Parent then shutdownScript() break end
        
        if not (Settings.CollectCash or Settings.BuyChickens or Settings.BuyTier or Settings.MergeChickens or Settings.UpgradeProcess or Settings.AutoDeposit or Settings.AutoRebirth or Settings.HideLeftUI) then
            task.wait(1)
            continue
        end
        
        pcall(function()
            local mainUI = player.PlayerGui:FindFirstChild("Main")
            local leftUI = mainUI and mainUI:FindFirstChild("Left")
            if leftUI then leftUI.Visible = not Settings.HideLeftUI end
        end)
        
        if Settings.CollectCash then
            task.spawn(function()
                pcall(function() mainFunction:InvokeServer("Collect Cash") end)
            end)
        end

        if Settings.UpgradeProcess then
            task.spawn(function()
                pcall(function()
                	
                    local plotsFolder = Workspace:FindFirstChild("Plots")
                    if not plotsFolder then return end
                    local myPlot = plotsFolder:FindFirstChild(player.Name)
                    if not myPlot then return end

                    local buttons = myPlot:FindFirstChild("Buttons")
                    if not buttons then return end
                    local upgradeBtn = buttons:FindFirstChild("UpgradeProcess")
                    if not upgradeBtn then return end

                    local btnUI = upgradeBtn:FindFirstChild("Button")
                    if not btnUI then return end
                    local ui = btnUI:FindFirstChild("UI")
                    if not ui then return end
                    local costLabel = ui:FindFirstChild("Cost")
                    if not costLabel then return end

                    local costText = costLabel.Text
                    local balanceText = player.PlayerGui.Main.Currencies.Cash.List.Amount.Text

                    local upgradeCost = parseSuffixedNumber(costText)
                    local balance = parseSuffixedNumber(balanceText)

                    if upgradeCost and balance and upgradeCost <= balance * 0.01 then
                        mainFunction:InvokeServer("Upgrade Process Level")
                    end
                end)
            end)
        end

        if Settings.BuyTier then
            task.spawn(function()
                pcall(function()
                	
                    local commands = {
                        "Upgrade Buy Tier Level",
                        "UpgradeBuyTierLevel",
                        "Buy Tier Level",
                        "BuyTierLevel",
                        "Upgrade Plot Level",
                        "Plot Upgrade Level"
                    }
                    for _, cmd in ipairs(commands) do
                        local success = pcall(function() return mainFunction:InvokeServer(cmd) end)
                        if success then 
                            break 
                        end
                    end
                end)
            end)
        end

        if Settings.AutoDeposit then
            task.spawn(function()
                pcall(function()
                    if eggMultiplier and eggMultiplier.Value >= (Settings.DepositThreshold or 1.5) then
                        mainFunction:InvokeServer("Deposit Eggs")
                    end
                end)
            end)
        end

        if Settings.AutoRebirth then
            task.spawn(function()
                pcall(function() mainFunction:InvokeServer("Rebirth") end)
            end)
        end

        if Settings.BuyChickens then
            task.spawn(function()
                pcall(function()
                	
                    for _, amount in ipairs({100, 25, 5, 1}) do
                        local success = mainFunction:InvokeServer("Buy Chickens", amount)
                        if success then break end
                    end
                end)
            end)
        end

        if Settings.MergeChickens then
            task.spawn(function()
                pcall(function() mainFunction:InvokeServer("Merge Chickens") end)
            end)
        end

        task.wait(0.5)
    end

        if Settings.AutoDeposit then
            task.spawn(function()
                pcall(function()
                    if eggMultiplier and eggMultiplier.Value >= (Settings.DepositThreshold or 1.5) then
                        mainFunction:InvokeServer("Deposit Eggs")
                    end
                end)
            end)
        end

        if Settings.AutoRebirth then
            task.spawn(function()
                pcall(function() mainFunction:InvokeServer("Rebirth") end)
            end)
        end

        if Settings.BuyChickens then
            task.spawn(function()
                pcall(function()
                    for _, amount in ipairs({100, 25, 5, 1}) do
                        local success = mainFunction:InvokeServer("Buy Chickens", amount)
                        if success then break end
                    end
                end)
            end)
        end

        if Settings.MergeChickens then
            task.spawn(function()
                pcall(function() mainFunction:InvokeServer("Merge Chickens") end)
            end)
        end

        task.wait(0.5)
    end
end)