local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer

local TYPING_DURATION   = 4
local ASSEMBLY_DURATION = 1.0
local HOLD_DURATION     = 0.5
local EXPLODE_DURATION  = 1.8

local TYPE_SOUND_ID      = "rbxassetid://127105730240202"
local ASSEMBLE_SOUND_ID  = "rbxassetid://166047422"
local EXPLOSION_SOUND_ID = "rbxassetid://119977062667102"

local function makeSound(id: string, volume: number)
	if id == "rbxassetid://0" then
		return nil
	end
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = volume
	s.Parent = SoundService
	return s
end

local CODE_TEMPLATES = {
	"for _,p in pairs(game.Players:GetPlayers())do print('[P]'..p.Name)end print('boot %N%')",
    "a=game.ReplicatedStorage:FindFirstChild('RemoteAuth_%X%')if a then a:FireServer('auth_%X%')end",
    "k='0x%X%'print('decrypt('..k..')->ok')",
    "for i=1,%N%do print('port '..i..' open')end",
    "loadstring('print(\\'loaded\\')')()print('chunk %N%%')",
    "t=game.HttpService:GetAsync('https://www.roblox.com/')or'%X%'print('token='..t)",
    "h=game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild('Humanoid')if h then h.WalkSpeed=100;print('bypass #%N%')end",
    "c=game:GetService('CoreScript')print('root@core:'..(c and c.Name or'nil'))",
    "i=game.MarketplaceService:GetProductInfo(%N%)print('asset['..%N%..']='..i.Name)",
    "h=game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild('Humanoid')if h then h.JumpPower=100;print('patch %X%')end",
    "e=game.ReplicatedStorage:FindFirstChild('%X%')print('handshake('..(e and e.Name or'nil')..')ok')",
    "m=game.ReplicatedStorage:FindFirstChild('Core_%N%')if m then require(m);print('unlock core_'..%N%)end",
    "o=game.Workspace:FindFirstChild('0x%X%')if o then o:Destroy();print('clear 0x%X%')end",
    "task.spawn(function()print('thread %N%')end)",
    "print('csum %X% match')",
    "s=game.ReplicatedStorage:FindFirstChild('Script_%N%.luac')print('decomp '..(s and s.Name or'nf'))",
    "print('sock %N% 200')",
    "n=game.Lighting:FindFirstChild('node_%X%')if n then n:Destroy();print('flush node_'..%X%)end",
    "print('kernel %N%')",
    "print('> GRANT %X%')",
    "print('conn %X%:%N%')",
    "print('probe /api/v%N%/auth')",
    "f=Instance.new('Frame')f.Size=UDim2.new(0,%N%,0,%N%)f.Position=UDim2.new(.5,0,.5,0)f.Parent=game.Players.LocalPlayer.PlayerGui print('inject %N% @0x%X%')",
    "Instance.new('RemoteEvent',game.ReplicatedStorage).Name='ReverseShell'print('revshell ok')",
    "l=%N%if l>5 then print('lvl '..l..' ROOT')end",
    "for h=1,%N%do task.wait(.01)print('hop_'..h..' 12ms')end",
    "db={core='%X%'}print('SQL core_'..db.core)",
    "print('CVE-20'..%N%..'-%X%')",
    "print('spoof '..'%X%:%X%:%X%')",
    "print('crc32 '..%N%..'=0x%X%')",
    "print('session rot 0x%X%')",
    "jobs={}jobs[%N%]={p='HIGH'}print('queue '..%N%)",
    "sandbox=setmetatable({},{__index=_G})print('vm '..%N%)",
    "print('dump 0x%X%-0x%X%')",
    "print('cert '..%N%..' ok')",
    "print('token ref 0x%X%')",
    "op=print;print=function(...)op('[HK]',...)end;print('hook '..%N%)",
    "print('trace 0x%X% clean')",
    "print('proxy['..%N%..']')",
    "print('log ev %X%')",
}

local CREDIT_LINE = "// system author: @vymiw"

local HEX = "0123456789ABCDEF"
local function randHex(len: number)
	local s = ""
	for i = 1, len do
		local idx = math.random(1, #HEX)
		s ..= string.sub(HEX, idx, idx)
	end
	return s
end

local function fillTemplate(t: string)
	t = t:gsub("%%N%%", tostring(math.random(0, 9999)))
	t = t:gsub("%%X%%", randHex(math.random(4, 8)))
	return t
end

local FONT = {
	R = {"11110","10001","10001","11110","10100","10010","10001"},
	O = {"01110","10001","10001","10001","10001","10001","01110"},
	B = {"11110","10001","10001","11110","10001","10001","11110"},
	L = {"10000","10000","10000","10000","10000","10000","11111"},
	X = {"10001","10001","01010","00100","01010","10001","10001"},
	V = {"10001","10001","10001","10001","10001","01010","00100"},
	Y = {"10001","10001","01010","00100","00100","00100","00100"},
	M = {"10001","11011","10101","10101","10001","10001","10001"},
	I = {"11111","00100","00100","00100","00100","00100","11111"},
	W = {"10001","10001","10001","10101","10101","11011","10001"},
}

local LOGO_WORD = {"V","Y","M","I","W"}
local LETTER_W, LETTER_H, GAP = 5, 7, 1

local function buildLogoCells()
	local cells = {}
	for li, letter in ipairs(LOGO_WORD) do
		local glyph = FONT[letter]
		for row = 1, LETTER_H do
			local rowStr = glyph[row]
			for col = 1, LETTER_W do
				if string.sub(rowStr, col, col) == "1" then
					table.insert(cells, {
						col = (li - 1) * (LETTER_W + GAP) + col,
						row = row,
					})
				end
			end
		end
	end
	local totalCols = (#LOGO_WORD - 1) * (LETTER_W + GAP) + LETTER_W
	return cells, totalCols, LETTER_H
end

local function tween(instance: Instance, info: TweenInfo, props: {[string]: any})
	local t = TweenService:Create(instance, info, props)
	t:Play()
	return t
end

local GREEN = Color3.fromRGB(60, 255, 100)
local GREEN_BRIGHT = Color3.fromRGB(170, 255, 180)

local function PlayHackIntro()
	local playerGui = player:WaitForChild("PlayerGui")
	local old = playerGui:FindFirstChild("HackIntroGui")
	if old then old:Destroy() end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "HackIntroGui"
	screenGui.IgnoreGuiInset = true
	screenGui.DisplayOrder = 10_000
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	local bg = Instance.new("Frame")
	bg.Name = "Background"
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = Color3.new(0, 0, 0)
	bg.BorderSizePixel = 0
	bg.ZIndex = 1
	bg.Parent = screenGui

	local TYPE_SOUND_POOL_SIZE = 6
	local MIN_BLIP_INTERVAL = 0.035

	local typeSoundPool = {}
	if TYPE_SOUND_ID ~= "rbxassetid://0" then
		for i = 1, TYPE_SOUND_POOL_SIZE do
			local s = Instance.new("Sound")
			s.SoundId = TYPE_SOUND_ID
			s.Volume = 0.35
			s.Parent = SoundService
			typeSoundPool[i] = s
		end
	end
	local assembleSoundPre = makeSound(ASSEMBLE_SOUND_ID, 0.7)
	local explosionSoundPre = makeSound(EXPLOSION_SOUND_ID, 0.8)

	task.spawn(function()
		local toPreload = {}
		for _, s in ipairs(typeSoundPool) do table.insert(toPreload, s) end
		if assembleSoundPre then table.insert(toPreload, assembleSoundPre) end
		if explosionSoundPre then table.insert(toPreload, explosionSoundPre) end
		if #toPreload > 0 then
			ContentProvider:PreloadAsync(toPreload)
		end
	end)

	local viewport = Instance.new("Frame")
	viewport.Name = "TerminalViewport"
	viewport.Size = UDim2.fromScale(0.5, 0.85)
	viewport.Position = UDim2.fromScale(0.03, 0.08)
	viewport.BackgroundTransparency = 1
	viewport.ClipsDescendants = true
	viewport.ZIndex = 2
	viewport.Parent = bg

	local codeLog = Instance.new("Frame")
	codeLog.Name = "CodeLog"
	codeLog.Size = UDim2.new(1, 0, 0, 0)
	codeLog.AutomaticSize = Enum.AutomaticSize.Y
	codeLog.BackgroundTransparency = 1
	codeLog.ZIndex = 2
	codeLog.Parent = viewport

	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 2)
	listLayout.Parent = codeLog

	local lineOrder = 0
	local allLineLabels = {}

	local function scrollToBottom()
		local contentH = codeLog.AbsoluteSize.Y
		local viewH = viewport.AbsoluteSize.Y
		if contentH > viewH then
			tween(codeLog, TweenInfo.new(0.08, Enum.EasingStyle.Sine), {
				Position = UDim2.new(0, 0, 0, -(contentH - viewH)),
			})
		end
	end

	local poolIndex = 0
	local lastBlipTime = 0

	local function playBlip(pitchMin: number, pitchMax: number)
		if #typeSoundPool == 0 then return end
		local now = os.clock()
		if now - lastBlipTime < MIN_BLIP_INTERVAL then
			return
		end
		lastBlipTime = now

		poolIndex = (poolIndex % #typeSoundPool) + 1
		local s = typeSoundPool[poolIndex]
		s.PlaybackSpeed = pitchMin + math.random() * (pitchMax - pitchMin)
		s.TimePosition = 0
		s:Play()
	end

	local function newLine(): TextLabel
		lineOrder += 1
		local label = Instance.new("TextLabel")
		label.Name = "Line" .. lineOrder
		label.LayoutOrder = lineOrder
		label.Size = UDim2.new(1, 0, 0, 18)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.Code
		label.TextSize = 16
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextColor3 = GREEN
		label.Text = ""
		label.ZIndex = 2
		label.Parent = codeLog
		table.insert(allLineLabels, label)
		return label
	end

	local typingStart = os.clock()
	local lineIndex = 0
	local creditShown = false
	while os.clock() - typingStart < TYPING_DURATION do
		lineIndex += 1

		local line: string
		local forceTyped = false
		if not creditShown and lineIndex == 14 then
			line = CREDIT_LINE
			forceTyped = true
			creditShown = true
		else
			local template = CODE_TEMPLATES[((lineIndex - 1) % #CODE_TEMPLATES) + 1]
			line = fillTemplate(template)
		end

		local label = newLine()

		if forceTyped or lineIndex % 4 == 0 then
			for c = 1, #line do
				label.Text = string.sub(line, 1, c)
				if c % 2 == 0 then playBlip(0.9, 1.3) end
				task.wait(0.001)
			end
		else
			label.Text = line
			playBlip(1.3, 1.7)
			task.wait(0.003)
		end

		scrollToBottom()
	end

	for _, s in ipairs(typeSoundPool) do
		s:Stop()
		Debris:AddItem(s, 0.1)
	end

	if assembleSoundPre then
		assembleSoundPre:Play()
		local cleaned = false
		local function cleanupAssemble()
			if cleaned then return end
			cleaned = true
			assembleSoundPre:Destroy()
		end
		assembleSoundPre.Ended:Connect(cleanupAssemble)
		Debris:AddItem(assembleSoundPre, 6)
	end

	local cells, totalCols, totalRows = buildLogoCells()
	local blockSize = 14
	local logoW = totalCols * blockSize
	local logoH = totalRows * blockSize

	task.wait()
	local screenSize = bg.AbsoluteSize
	local centerX = screenSize.X / 2
	local centerY = screenSize.Y / 2
	local originX = centerX - logoW / 2
	local originY = centerY - logoH / 2

	local particles = {}
	local terminalAbsPos = viewport.AbsolutePosition
	local terminalAbsSize = viewport.AbsoluteSize

	for i, cell in ipairs(cells) do
		local particle = Instance.new("TextLabel")
		particle.Name = "Px" .. i
		particle.AnchorPoint = Vector2.new(0, 0)
		particle.Size = UDim2.fromOffset(blockSize - 2, blockSize - 2)
		particle.BackgroundTransparency = 1
		particle.Font = Enum.Font.Code
		particle.TextSize = 14
		particle.TextColor3 = GREEN
		particle.Text = string.char(math.random(33, 90))
		particle.ZIndex = 3
		local startX = terminalAbsPos.X + math.random(0, math.max(terminalAbsSize.X - blockSize, 1))
		local startY = terminalAbsPos.Y + math.random(0, math.max(terminalAbsSize.Y - blockSize, 1))
		particle.Position = UDim2.fromOffset(startX, startY)
		particle.Parent = bg

		local targetX = originX + (cell.col - 1) * blockSize
		local targetY = originY + (cell.row - 1) * blockSize

		particles[i] = {
			label = particle,
			targetX = targetX,
			targetY = targetY,
		}
	end

	for i, p in ipairs(particles) do
		local delay = math.random() * 0.35
		task.delay(delay, function()
			local tw = tween(p.label, TweenInfo.new(ASSEMBLY_DURATION - delay, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				Position = UDim2.fromOffset(p.targetX, p.targetY),
			})
			tw.Completed:Connect(function()
				p.label.Text = ""
				p.label.BackgroundTransparency = 0
				p.label.BackgroundColor3 = GREEN
			end)
		end)
	end

	for _, l in ipairs(allLineLabels) do
		tween(l, TweenInfo.new(ASSEMBLY_DURATION * 0.6), { TextTransparency = 1 })
	end

	task.wait(ASSEMBLY_DURATION)
	viewport:Destroy()

	for _ = 1, 2 do
		for _, p in ipairs(particles) do
			tween(p.label, TweenInfo.new(HOLD_DURATION / 4), { BackgroundColor3 = GREEN_BRIGHT })
		end
		task.wait(HOLD_DURATION / 4)
		for _, p in ipairs(particles) do
			tween(p.label, TweenInfo.new(HOLD_DURATION / 4), { BackgroundColor3 = GREEN })
		end
		task.wait(HOLD_DURATION / 4)
	end

	local explosionSound = explosionSoundPre
	if explosionSound then
		explosionSound:Play()
		local cleaned = false
		local function cleanup()
			if cleaned then return end
			cleaned = true
			explosionSound:Destroy()
		end
		explosionSound.Ended:Connect(cleanup)
		Debris:AddItem(explosionSound, 12)
	end

	local flash = Instance.new("Frame")
	flash.Size = UDim2.fromScale(1, 1)
	flash.BackgroundColor3 = Color3.new(1, 1, 1)
	flash.BackgroundTransparency = 0
	flash.ZIndex = 10
	flash.Parent = bg
	tween(flash, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { BackgroundTransparency = 1 })
	task.delay(0.5, function() flash:Destroy() end)

	local ring = Instance.new("Frame")
	ring.AnchorPoint = Vector2.new(0.5, 0.5)
	ring.Position = UDim2.fromOffset(centerX, centerY)
	ring.Size = UDim2.fromOffset(0, 0)
	ring.BackgroundTransparency = 1
	ring.ZIndex = 6
	ring.Parent = bg
	local ringCorner = Instance.new("UICorner")
	ringCorner.CornerRadius = UDim.new(1, 0)
	ringCorner.Parent = ring
	local ringStroke = Instance.new("UIStroke")
	ringStroke.Color = GREEN_BRIGHT
	ringStroke.Thickness = 6
	ringStroke.Transparency = 0
	ringStroke.Parent = ring
	tween(ring, TweenInfo.new(0.7, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Size = UDim2.fromOffset(1800, 1800),
	})
	tween(ringStroke, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Transparency = 1,
	})
	task.delay(0.7, function() ring:Destroy() end)

	task.spawn(function()
		local shakeTime = 0.4
		local t0 = os.clock()
		while os.clock() - t0 < shakeTime do
			local mag = (1 - (os.clock() - t0) / shakeTime) * 14
			bg.Position = UDim2.fromOffset(
				math.random(-mag, mag),
				math.random(-mag, mag)
			)
			RunService.Heartbeat:Wait()
		end
		bg.Position = UDim2.fromOffset(0, 0)
	end)

	for i, p in ipairs(particles) do
		local dx = p.targetX - centerX
		local dy = p.targetY - centerY
		local dist = math.sqrt(dx * dx + dy * dy)
		local nx, ny = 0, -1
		if dist > 0.01 then
			nx, ny = dx / dist, dy / dist
		else
			local ang = math.random() * math.pi * 2
			nx, ny = math.cos(ang), math.sin(ang)
		end
		local jitter = (math.random() - 0.5) * 0.6
		local cosj, sinj = math.cos(jitter), math.sin(jitter)
		local fx = nx * cosj - ny * sinj
		local fy = nx * sinj + ny * cosj

		local burstDist = 350 + dist * 1.8 + math.random(0, 400)
		local burstX = p.targetX + fx * burstDist
		local burstY = p.targetY + fy * burstDist

		local spin = (math.random() - 0.5) * 1080

		tween(p.label, TweenInfo.new(0.4, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
			Position = UDim2.fromOffset(burstX, burstY),
			Rotation = spin,
			BackgroundColor3 = GREEN_BRIGHT,
		})

		task.delay(0.38, function()
			local fallX = burstX + math.random(-60, 60)
			local fallY = burstY + math.random(250, 550)
			tween(p.label, TweenInfo.new(EXPLODE_DURATION - 0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Position = UDim2.fromOffset(fallX, fallY),
				Rotation = spin + (math.random() - 0.5) * 360,
				BackgroundTransparency = 1,
			})
		end)
	end

	tween(bg, TweenInfo.new(EXPLODE_DURATION * 0.85, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		BackgroundTransparency = 1,
	})

	task.wait(EXPLODE_DURATION + 0.1)
	screenGui:Destroy()
end

PlayHackIntro()
