local player = game:GetService("Players").LocalPlayer
local TweenService = game:GetService("TweenService")

local gui = Instance.new("ScreenGui")
gui.Name = "AIPROJECT"
gui.Parent = player:WaitForChild("PlayerGui")
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999

local overlay = Instance.new("Frame")
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.Position = UDim2.new(0, 0, 0, 0)
overlay.BackgroundColor3 = Color3.new(0, 0, 0)
overlay.BackgroundTransparency = 0
overlay.BorderSizePixel = 0
overlay.Parent = gui

local mainText = Instance.new("TextLabel")
mainText.Size = UDim2.new(0.8, 0, 0.15, 0)
mainText.Position = UDim2.new(0.1, 0, 0.42, 0)
mainText.BackgroundTransparency = 1
mainText.FontFace = Font.new(
    "rbxassetid://12187374273",
    Enum.FontWeight.Regular,
    Enum.FontStyle.Normal
)
mainText.TextColor3 = Color3.new(1, 1, 1)
mainText.TextScaled = true
mainText.Text = "AI   CHEAT > AI   PLACE"
mainText.TextXAlignment = Enum.TextXAlignment.Center
mainText.TextYAlignment = Enum.TextYAlignment.Center
mainText.Parent = overlay

mainText.TextTransparency = 1

TweenService:Create(
    mainText,
    TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    {TextTransparency = 0}
):Play()

task.wait(4.0 + 0.8)

TweenService:Create(
    mainText,
    TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
    {TextTransparency = 1}
):Play()

TweenService:Create(
    overlay,
    TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
    {BackgroundTransparency = 1}
):Play()

task.wait(1.0)
gui:Destroy()

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")
local MaterialService = game:GetService("MaterialService")

local player = Players.LocalPlayer
local GuiTarget = player:WaitForChild("PlayerGui")

local RebirthRemote = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Rebirth")
local SpinAura = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("SpinAura")
local ConfirmAura = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("ConfirmAura")

local Config
pcall(function() Config = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Config")) end)

local function getRequired(rebirths)
    if Config and Config.GetRebirthRequirement then
        return Config.GetRebirthRequirement(rebirths)
    else
        return rebirths + 1
    end
end

local State = {
    AutoRebirth = false,
    AutoTeleport = false,
    Rolling = false,
    StopRolling = false,
    Minimized = false,
    Closing = false,
    AntiAFK = false,
    NoRender = false,
    SpeedBoost = false,
}

local function Create(className, properties, children)
    local inst = Instance.new(className)
    for k, v in pairs(properties or {}) do inst[k] = v end
    for _, child in pairs(children or {}) do child.Parent = inst end
    return inst
end

local function AddCorner(parent, radius)
    return Create("UICorner", { CornerRadius = UDim.new(0, radius or 8), Parent = parent })
end

local function AddStroke(parent, color, thickness, transparency)
    return Create("UIStroke", {
        Color = color or Color3.fromRGB(255, 255, 255),
        Thickness = thickness or 1,
        Transparency = transparency or 0.8,
        Parent = parent
    })
end

local Theme = {
    Window = Color3.fromRGB(0, 0, 0),
    Text = Color3.fromRGB(255, 255, 255),
    TextDim = Color3.fromRGB(200, 200, 200),
    AccentDark = Color3.fromRGB(80, 80, 80),
    Success = Color3.fromRGB(255, 255, 255),
    Error = Color3.fromRGB(0, 0, 0),
    Border = Color3.fromRGB(255, 255, 255),
}

local function getLevel() return player:GetAttribute("Level") or 0 end
local function getRebirths() return player:GetAttribute("Rebirths") or 0 end

local function updateInfoLabels(infoLabel)
    if infoLabel then infoLabel.Text = "Level: " .. getLevel() .. "  Rebirths: " .. getRebirths() end
end

-- Auto Rebirth (spam)
local rebirthLoop = nil
local function startRebirthLoop()
    if rebirthLoop then return end
    rebirthLoop = task.spawn(function()
        while State.AutoRebirth do
            if RebirthRemote then
                pcall(RebirthRemote.InvokeServer, RebirthRemote)
            end
            task.wait(0.1)
        end
        rebirthLoop = nil
    end)
end

local function stopRebirthLoop()
    State.AutoRebirth = false
    if rebirthLoop then
        task.cancel(rebirthLoop)
        rebirthLoop = nil
    end
end

-- Teleport
local teleportLoop
local function startTeleportLoop()
    if teleportLoop then return end
    teleportLoop = task.spawn(function()
        while State.AutoTeleport do
            local char = player.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                char.HumanoidRootPart.CFrame = CFrame.new(687, 15, 847)
            end
            task.wait(0.3)
        end
        teleportLoop = nil
    end)
end

local function stopTeleportLoop()
    State.AutoTeleport = false
    if teleportLoop then
        task.cancel(teleportLoop)
        teleportLoop = nil
    end
end

local function rollForEthereal(rollBtn, stopBtn)
    if State.Rolling then return end
    if not SpinAura or not ConfirmAura then return end
    State.Rolling = true
    State.StopRolling = false
    if rollBtn then rollBtn.Visible = false end
    if stopBtn then stopBtn.Visible = true end

    task.spawn(function()
        local attempts = 0
        local success, err = false, nil
        while not State.StopRolling and not success do
            attempts = attempts + 1
            local ok, res = pcall(function() return SpinAura:InvokeServer(false) end)
            if not ok then
                err = true
                break
            end
            if not res or not res.success then
                err = true
                break
            end
            local aura = res.aura
            if aura and aura.Name == "Ethereal" then
                success = true
                ConfirmAura:FireServer()
                break
            else
                ConfirmAura:FireServer()
            end
            task.wait(0.03)
        end
        State.Rolling = false
        if rollBtn then rollBtn.Visible = true end
        if stopBtn then stopBtn.Visible = false end
        State.StopRolling = false

        if State.SpeedBoost then
            player:SetAttribute("AuraSwingBoost", 999)
        end
    end)
end

local afkInterval = 240
local lastAfkTick = 0

player.Idled:Connect(function()
    if not State.AntiAFK then return end
    VirtualUser:Button2Down(Vector2.new(0,0))
    task.wait(0.1)
    VirtualUser:Button2Up(Vector2.new(0,0))
end)
pcall(function() VirtualUser:CaptureController() end)

task.spawn(function()
    while true do
        if State.AntiAFK then
            local now = os.clock()
            if now - lastAfkTick >= afkInterval then
                pcall(function()
                    VirtualUser:Button2Down(Vector2.new(0,0))
                    task.wait(0.05)
                    VirtualUser:Button2Up(Vector2.new(0,0))
                end)
                lastAfkTick = now
            end
        end
        task.wait(1)
    end
end)

local noRenderBackup = {}
local function applyNoRender()
    if State.NoRender then return end
    State.NoRender = true
    noRenderBackup = {}

    local function safeSet(obj, prop, value)
        pcall(function() obj[prop] = value end)
    end

    noRenderBackup.GlobalShadows = Lighting.GlobalShadows
    noRenderBackup.FogEnd = Lighting.FogEnd
    noRenderBackup.ShadowSoftness = Lighting.ShadowSoftness
    safeSet(Lighting, "GlobalShadows", false)
    safeSet(Lighting, "FogEnd", 9e9)
    safeSet(Lighting, "ShadowSoftness", 0)

    noRenderBackup.QualityLevel = settings().Rendering.QualityLevel
    safeSet(settings().Rendering, "QualityLevel", 1)

    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if terrain then
        noRenderBackup.WaterWaveSize = terrain.WaterWaveSize
        noRenderBackup.WaterWaveSpeed = terrain.WaterWaveSpeed
        noRenderBackup.WaterReflectance = terrain.WaterReflectance
        noRenderBackup.WaterTransparency = terrain.WaterTransparency
        safeSet(terrain, "WaterWaveSize", 0)
        safeSet(terrain, "WaterWaveSpeed", 0)
        safeSet(terrain, "WaterReflectance", 0)
        safeSet(terrain, "WaterTransparency", 0)
    end

    for _, mat in ipairs(MaterialService:GetChildren()) do
        pcall(mat.Destroy, mat)
    end
    pcall(function() MaterialService.Use2022Materials = false end)

    local objects = game:GetDescendants()
    for _, obj in ipairs(objects) do
        if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
            noRenderBackup[obj] = obj.Enabled
            safeSet(obj, "Enabled", false)
        elseif obj:IsA("Explosion") then
            noRenderBackup[obj] = {BlastPressure = obj.BlastPressure, BlastRadius = obj.BlastRadius, Visible = obj.Visible}
            safeSet(obj, "BlastPressure", 1)
            safeSet(obj, "BlastRadius", 1)
            safeSet(obj, "Visible", false)
        elseif obj:IsA("MeshPart") then

            noRenderBackup[obj] = {Reflectance = obj.Reflectance, Material = obj.Material}
            safeSet(obj, "Reflectance", 0)
            safeSet(obj, "Material", Enum.Material.Plastic)
        elseif obj:IsA("BasePart") and not obj:IsA("MeshPart") then
            noRenderBackup[obj] = {Material = obj.Material, Reflectance = obj.Reflectance}
            safeSet(obj, "Material", Enum.Material.Plastic)
            safeSet(obj, "Reflectance", 0)
        elseif obj:IsA("Model") then
            noRenderBackup[obj] = {LevelOfDetail = obj.LevelOfDetail}
            safeSet(obj, "LevelOfDetail", 1)
        elseif obj:IsA("TextLabel") and obj:IsDescendantOf(workspace) then
            noRenderBackup[obj] = {Font = obj.Font, TextScaled = obj.TextScaled, RichText = obj.RichText, TextSize = obj.TextSize, Visible = obj.Visible}
            safeSet(obj, "Font", Enum.Font.SourceSans)
            safeSet(obj, "TextScaled", false)
            safeSet(obj, "RichText", false)
            safeSet(obj, "TextSize", 14)
            safeSet(obj, "Visible", false)
        elseif obj:IsA("PostEffect") then
            noRenderBackup[obj] = obj.Enabled
            safeSet(obj, "Enabled", false)
        end
    end
end

local function revertNoRender()
    if not State.NoRender then return end
    State.NoRender = false

    local function safeSet(obj, prop, value)
        pcall(function() obj[prop] = value end)
    end

    if noRenderBackup.GlobalShadows ~= nil then
        safeSet(Lighting, "GlobalShadows", noRenderBackup.GlobalShadows)
        safeSet(Lighting, "FogEnd", noRenderBackup.FogEnd)
        safeSet(Lighting, "ShadowSoftness", noRenderBackup.ShadowSoftness)
    end
    if noRenderBackup.QualityLevel ~= nil then
        safeSet(settings().Rendering, "QualityLevel", noRenderBackup.QualityLevel)
    end

    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if terrain and noRenderBackup.WaterWaveSize ~= nil then
        safeSet(terrain, "WaterWaveSize", noRenderBackup.WaterWaveSize)
        safeSet(terrain, "WaterWaveSpeed", noRenderBackup.WaterWaveSpeed)
        safeSet(terrain, "WaterReflectance", noRenderBackup.WaterReflectance)
        safeSet(terrain, "WaterTransparency", noRenderBackup.WaterTransparency)
    end

    for obj, data in pairs(noRenderBackup) do
        if obj and obj.Parent then
            if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
                safeSet(obj, "Enabled", data)
            elseif obj:IsA("Explosion") then
                safeSet(obj, "BlastPressure", data.BlastPressure)
                safeSet(obj, "BlastRadius", data.BlastRadius)
                safeSet(obj, "Visible", data.Visible)
            elseif obj:IsA("MeshPart") then
                safeSet(obj, "Reflectance", data.Reflectance)
                safeSet(obj, "Material", data.Material)
            elseif obj:IsA("BasePart") and not obj:IsA("MeshPart") then
                safeSet(obj, "Material", data.Material)
                safeSet(obj, "Reflectance", data.Reflectance)
            elseif obj:IsA("Model") then
                safeSet(obj, "LevelOfDetail", data.LevelOfDetail)
            elseif obj:IsA("TextLabel") and obj:IsDescendantOf(workspace) then
                safeSet(obj, "Font", data.Font)
                safeSet(obj, "TextScaled", data.TextScaled)
                safeSet(obj, "RichText", data.RichText)
                safeSet(obj, "TextSize", data.TextSize)
                safeSet(obj, "Visible", data.Visible)
            elseif obj:IsA("PostEffect") then
                safeSet(obj, "Enabled", data)
            end
        end
    end
    noRenderBackup = {}
end

if GuiTarget:FindFirstChild("AutoTools_Main") then
    GuiTarget:FindFirstChild("AutoTools_Main"):Destroy()
end

local ScreenGui = Create("ScreenGui", {
    Name = "AutoTools_Main",
    DisplayOrder = 999,
    ResetOnSpawn = false,
    Parent = GuiTarget
})

local Shadow = Create("ImageLabel", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundTransparency = 1,
    Position = UDim2.new(0.5, 0, 0.5, 4),
    Size = UDim2.new(1, 50, 1, 50),
    Image = "rbxassetid://5554236805",
    ImageColor3 = Color3.fromRGB(0, 0, 0),
    ImageTransparency = 0.6,
    ScaleType = Enum.ScaleType.Slice,
    SliceCenter = Rect.new(23, 23, 277, 277),
    Parent = ScreenGui
})

local MainFrame = Create("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundColor3 = Theme.Window,
    BackgroundTransparency = 0.25,
    Position = UDim2.new(0.5, 0, 0.5, 0),
    Size = UDim2.new(0, 420, 0, 320),
    Active = true,
    Parent = ScreenGui
})
AddCorner(MainFrame, 12)
AddStroke(MainFrame, Theme.Border, 1.5, 0.3)

local UIScale = Instance.new("UIScale", MainFrame)

local dragging, dragInput, dragStart, startPos
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        Shadow.Position = UDim2.new(MainFrame.Position.X.Scale, MainFrame.Position.X.Offset, MainFrame.Position.Y.Scale, MainFrame.Position.Y.Offset + 4)
    end
end)

local TitleArea = Create("Frame", {
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 0, 50),
    Parent = MainFrame
})

local Title = Create("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 20, 0, 0),
    Size = UDim2.new(0.5, 0, 1, 0),
    Font = Enum.Font.GothamBold,
    Text = "⛏ +1 Pickaxe Swing Escape",
    TextColor3 = Theme.Text,
    TextSize = 18,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = TitleArea
})

local Controls = Create("Frame", {
    BackgroundTransparency = 1,
    Position = UDim2.new(1, -85, 0, 0),
    Size = UDim2.new(0, 75, 1, 0),
    Parent = TitleArea
})

local MinimizeBtn = Create("TextButton", {
    BackgroundColor3 = Theme.AccentDark,
    BackgroundTransparency = 0.4,
    Position = UDim2.new(0, 0, 0.5, -14),
    Size = UDim2.new(0, 28, 0, 28),
    Font = Enum.Font.GothamBold,
    Text = "-",
    TextColor3 = Theme.Text,
    TextSize = 18,
    Parent = Controls
})
AddCorner(MinimizeBtn, 6)

local CloseBtn = Create("TextButton", {
    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
    BackgroundTransparency = 0.4,
    Position = UDim2.new(0, 36, 0.5, -14),
    Size = UDim2.new(0, 28, 0, 28),
    Font = Enum.Font.GothamBold,
    Text = "X",
    TextColor3 = Theme.Text,
    TextSize = 15,
    Parent = Controls
})
AddCorner(CloseBtn, 6)

local ContentFrame = Create("Frame", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 15, 0, 50),
    Size = UDim2.new(1, -30, 1, -65),
    Parent = MainFrame
})

local ContentLayout = Create("UIListLayout", {
    Padding = UDim.new(0, 6),
    SortOrder = Enum.SortOrder.LayoutOrder,
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    Parent = ContentFrame
})

local infoLabel = Create("TextLabel", {
    BackgroundTransparency = 1,
    Size = UDim2.new(0.95, 0, 0, 24),
    Font = Enum.Font.Gotham,
    Text = "Level: 0  Rebirths: 0",
    TextColor3 = Theme.Text,
    TextSize = 16,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = ContentFrame,
    LayoutOrder = 1
})

local function MakeBtn(txt, color, order, txtColor)
    local btn = Create("TextButton", {
        BackgroundColor3 = color,
        BackgroundTransparency = 0.5,
        Size = UDim2.new(0.95, 0, 0, 32),
        Font = Enum.Font.GothamBold,
        Text = txt,
        TextColor3 = txtColor or Theme.Text,
        TextSize = 14,
        Parent = ContentFrame,
        LayoutOrder = order
    })
    AddCorner(btn, 6)
    return btn
end

local tpAutoBtn = MakeBtn("⏸ Win Farm: OFF", Theme.AccentDark, 2)
local autoBtn = MakeBtn("⏸ Auto Rebirth: OFF", Theme.AccentDark, 3)
local rollBtn = MakeBtn("✨ Fast Roll to Ethereal", Theme.AccentDark, 4)
local stopRollBtn = MakeBtn("⏹ Stop Rolling", Theme.Error, 5)
stopRollBtn.Visible = false

local antiBtn = MakeBtn("Anti-AFK: OFF", Theme.AccentDark, 6)
local noRenderBtn = MakeBtn("No Render (FPS) : OFF", Theme.AccentDark, 7)
local speedBtn = MakeBtn("⛏ Speed Pickaxe: OFF", Theme.AccentDark, 8)

local function updateAll()
    updateInfoLabels(infoLabel)
end
updateAll()

player:GetAttributeChangedSignal("Level"):Connect(updateAll)
player:GetAttributeChangedSignal("Rebirths"):Connect(updateAll)

tpAutoBtn.MouseButton1Click:Connect(function()
    State.AutoTeleport = not State.AutoTeleport
    if State.AutoTeleport then
        tpAutoBtn.Text = "▶ Teleport: ON"
        tpAutoBtn.BackgroundColor3 = Theme.Success
        tpAutoBtn.TextColor3 = Color3.fromRGB(0,0,0)
        tpAutoBtn.BackgroundTransparency = 0.3
        startTeleportLoop()
    else
        tpAutoBtn.Text = "⏸ Teleport: OFF"
        tpAutoBtn.BackgroundColor3 = Theme.AccentDark
        tpAutoBtn.TextColor3 = Theme.Text
        tpAutoBtn.BackgroundTransparency = 0.5
        stopTeleportLoop()
    end
end)

autoBtn.MouseButton1Click:Connect(function()
    State.AutoRebirth = not State.AutoRebirth
    if State.AutoRebirth then
        autoBtn.Text = "▶ Auto Rebirth: ON"
        autoBtn.BackgroundColor3 = Theme.Success
        autoBtn.TextColor3 = Color3.fromRGB(0,0,0)
        autoBtn.BackgroundTransparency = 0.3
        startRebirthLoop()
    else
        autoBtn.Text = "⏸ Auto Rebirth: OFF"
        autoBtn.BackgroundColor3 = Theme.AccentDark
        autoBtn.TextColor3 = Theme.Text
        autoBtn.BackgroundTransparency = 0.5
        stopRebirthLoop()
    end
end)

rollBtn.MouseButton1Click:Connect(function()
    rollForEthereal(rollBtn, stopRollBtn)
end)
stopRollBtn.MouseButton1Click:Connect(function()
    State.StopRolling = true
    stopRollBtn.Visible = false
end)

antiBtn.MouseButton1Click:Connect(function()
    State.AntiAFK = not State.AntiAFK
    if State.AntiAFK then
        antiBtn.Text = "Anti-AFK: ON"
        antiBtn.BackgroundColor3 = Theme.Success
        antiBtn.TextColor3 = Color3.fromRGB(0,0,0)
        antiBtn.BackgroundTransparency = 0.3
    else
        antiBtn.Text = "Anti-AFK: OFF"
        antiBtn.BackgroundColor3 = Theme.AccentDark
        antiBtn.TextColor3 = Theme.Text
        antiBtn.BackgroundTransparency = 0.5
    end
end)

noRenderBtn.MouseButton1Click:Connect(function()
    if State.NoRender then
        revertNoRender()
        noRenderBtn.Text = "No Render: OFF"
        noRenderBtn.BackgroundColor3 = Theme.AccentDark
        noRenderBtn.TextColor3 = Theme.Text
        noRenderBtn.BackgroundTransparency = 0.5
    else
        applyNoRender()
        noRenderBtn.Text = "No Render: ON"
        noRenderBtn.BackgroundColor3 = Theme.Success
        noRenderBtn.TextColor3 = Color3.fromRGB(0,0,0)
        noRenderBtn.BackgroundTransparency = 0.3
    end
end)

speedBtn.MouseButton1Click:Connect(function()
    State.SpeedBoost = not State.SpeedBoost
    if State.SpeedBoost then
        speedBtn.Text = "⛏ Speed: ON"
        speedBtn.BackgroundColor3 = Theme.Success
        speedBtn.TextColor3 = Color3.fromRGB(0,0,0)
        speedBtn.BackgroundTransparency = 0.3
        player:SetAttribute("AuraSwingBoost", 999)
    else
        speedBtn.Text = "⛏ Speed: OFF"
        speedBtn.BackgroundColor3 = Theme.AccentDark
        speedBtn.TextColor3 = Theme.Text
        speedBtn.BackgroundTransparency = 0.5
        player:SetAttribute("AuraSwingBoost", 0)
    end
end)

local function setupHover(btn)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundTransparency = 0.1}):Play()
    end)
    btn.MouseLeave:Connect(function()
        local target = 0.5
        if btn == tpAutoBtn and State.AutoTeleport then target = 0.3
        elseif btn == autoBtn and State.AutoRebirth then target = 0.3
        elseif btn == antiBtn and State.AntiAFK then target = 0.3
        elseif btn == noRenderBtn and State.NoRender then target = 0.3
        elseif btn == speedBtn and State.SpeedBoost then target = 0.3
        elseif btn == rollBtn then target = 0.4
        end
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundTransparency = target}):Play()
    end)
end
setupHover(tpAutoBtn)
setupHover(autoBtn)
setupHover(rollBtn)
setupHover(stopRollBtn)
setupHover(antiBtn)
setupHover(noRenderBtn)
setupHover(speedBtn)

local CheeseburgerIcon = Create("TextButton", {
    AnchorPoint = Vector2.new(0, 0),
    BackgroundColor3 = Theme.Window,
    BackgroundTransparency = 0.2,
    Position = UDim2.new(0, 0, 0.25, 0),
    Size = UDim2.new(0, 0, 0, 0),
    Font = Enum.Font.GothamBold,
    Text = "⛏",
    TextColor3 = Theme.Text,
    TextSize = 40,
    Visible = false,
    Parent = ScreenGui
})
AddCorner(CheeseburgerIcon, 12)
AddStroke(CheeseburgerIcon, Theme.Border, 1.5, 0.3)

MinimizeBtn.MouseButton1Click:Connect(function()
    if State.Minimized or State.Closing then return end
    State.Minimized = true
    MainFrame.Visible = false
    Shadow.Visible = false
    CheeseburgerIcon.Visible = true
    TweenService:Create(CheeseburgerIcon, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Size = UDim2.new(0, 70, 0, 70)}):Play()
end)

CheeseburgerIcon.MouseButton1Click:Connect(function()
    if not State.Minimized or State.Closing then return end
    State.Minimized = false
    CheeseburgerIcon.Visible = false
    MainFrame.Visible = true
    Shadow.Visible = true
    MainFrame.Size = UDim2.new(0, 0, 0, 0)
    UIScale.Scale = 1
    TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Size = UDim2.new(0, 420, 0, 320)}):Play()
end)

CloseBtn.MouseButton1Click:Connect(function()
    if State.Closing then return end
    State.Closing = true
    State.AutoRebirth = false
    State.Rolling = false
    State.AutoTeleport = false
    stopRebirthLoop()
    stopTeleportLoop()
    if State.NoRender then revertNoRender() end
    if State.SpeedBoost then player:SetAttribute("AuraSwingBoost", 0) end
    if State.Minimized then
        CheeseburgerIcon.Visible = false
        MainFrame.Visible = true
        Shadow.Visible = true
    end

    local expand = TweenService:Create(UIScale, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Scale = 1.2})
    expand:Play()
    TweenService:Create(Shadow, TweenInfo.new(0.2), {ImageTransparency = 1}):Play()
    expand.Completed:Connect(function()
        local shrink = TweenService:Create(UIScale, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Scale = 0.01})
        shrink:Play()
        TweenService:Create(MainFrame, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
        shrink.Completed:Connect(function()
            ScreenGui:Destroy()
        end)
    end)
end)

MinimizeBtn.MouseEnter:Connect(function()
    TweenService:Create(MinimizeBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0.1}):Play()
end)
MinimizeBtn.MouseLeave:Connect(function()
    TweenService:Create(MinimizeBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0.4}):Play()
end)
CloseBtn.MouseEnter:Connect(function()
    TweenService:Create(CloseBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0.1}):Play()
end)
CloseBtn.MouseLeave:Connect(function()
    TweenService:Create(CloseBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0.4}):Play()
end)

if State.AntiAFK then
    antiBtn.Text = "Anti-AFK: ON"
    antiBtn.BackgroundColor3 = Theme.Success
    antiBtn.TextColor3 = Color3.fromRGB(0,0,0)
    antiBtn.BackgroundTransparency = 0.3
end