--[[
    Snork Hub - Ink Game
	Script Open-Source
    
    Recursos:
      - Fly, Noclip, WalkSpeed, TP, Auto QTE, Telecinese
      - ESP (Antena, Nome/Vida, Destaque)
      - Revelar Placas da Ponte de Vidro (Glass ESP)
      - Fullbright (Visão Noturna)
      - Anti-Fling (Proteção contra arremesso)

    Tecla para mostrar/esconder o menu: RightShift
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage") -- Adicionado para o QTE

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local camera = workspace.CurrentCamera

------------------------------------------------------------
-- Cores (Tema Escuro / Preto)
------------------------------------------------------------
local OFF_COLOR = Color3.fromRGB(40, 40, 45)
local PANEL_COLOR = Color3.fromRGB(10, 10, 12)
local CARD_COLOR = Color3.fromRGB(20, 20, 24)
local ACCENT = Color3.fromRGB(255, 255, 255)
local WHITE = Color3.new(1, 1, 1)
local GRAY = Color3.fromRGB(150, 150, 150)

------------------------------------------------------------
-- Helpers de UI
------------------------------------------------------------
local function corner(inst, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 6)
	c.Parent = inst
	return c
end

local function makeButton(parent, text, x, y, w, h)
	local b = Instance.new("TextButton")
	b.Position = UDim2.fromOffset(x, y)
	b.Size = UDim2.fromOffset(w, h)
	b.BackgroundColor3 = OFF_COLOR
	b.Font = Enum.Font.GothamBold
	b.Text = text
	b.TextSize = 14
	b.TextColor3 = WHITE
	b.BorderSizePixel = 0
	b.Parent = parent
	corner(b, 6)
	return b
end

local function makeToggle(parent, text, x, y, w, h, onChange)
	local btn = makeButton(parent, text, x, y, w, h)
	local t = { state = false, btn = btn }
	function t.refresh()
		btn.BackgroundColor3 = t.state and ACCENT or OFF_COLOR
		btn.TextColor3 = t.state and PANEL_COLOR or WHITE
		btn.Text = text .. (t.state and "  [ON]" or "  [OFF]")
	end
	btn.MouseButton1Click:Connect(function()
		t.state = not t.state
		t.refresh()
		onChange(t.state)
	end)
	t.refresh()
	return t
end

------------------------------------------------------------
-- Criação da GUI
------------------------------------------------------------
local playerGui = player:WaitForChild("PlayerGui")
local oldGui = playerGui:FindFirstChild("SnorkHub")
if oldGui then oldGui:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "SnorkHub"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 10
gui.Parent = playerGui

local main = Instance.new("Frame")
main.Name = "Main"
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.Position = UDim2.fromScale(0.5, 0.5)
main.Size = UDim2.fromOffset(500, 420)
main.BackgroundColor3 = PANEL_COLOR
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.Parent = gui
corner(main, 10)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(50, 50, 55)
stroke.Thickness = 1
stroke.Parent = main

-- Top Bar
local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 40)
topBar.BackgroundColor3 = CARD_COLOR
topBar.BorderSizePixel = 0
topBar.Parent = main
corner(topBar, 10)

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Size = UDim2.new(1, -100, 1, 0)
title.Position = UDim2.fromOffset(15, 0)
title.Font = Enum.Font.GothamBold
title.Text = "Snork Hub - Ink Game"
title.TextSize = 16
title.TextColor3 = WHITE
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = topBar

local closeBtn = makeButton(topBar, "X", 460, 5, 30, 30)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.MouseButton1Click:Connect(function() gui:Destroy() end)

local minBtn = makeButton(topBar, "—", 425, 5, 30, 30)
local minimized = false
minBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	minBtn.Text = minimized and "+" or "—"
	TweenService:Create(main, TweenInfo.new(0.2), {
		Size = minimized and UDim2.fromOffset(500, 40) or UDim2.fromOffset(500, 420)
	}):Play()
end)

-- Arrastar
local dragging, dragStart, startPos = false, nil, nil
topBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = main.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then dragging = false end
		end)
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if not dragging then return end
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		local delta = input.Position - dragStart
		main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

-- ==========================================
-- SISTEMA DE ABAS (TABS)
-- ==========================================
local tabContainer = Instance.new("Frame")
tabContainer.Size = UDim2.new(1, -20, 0, 40)
tabContainer.Position = UDim2.fromOffset(10, 50)
tabContainer.BackgroundTransparency = 1
tabContainer.Parent = main

local contentContainer = Instance.new("Frame")
contentContainer.Size = UDim2.new(1, -20, 1, -100)
contentContainer.Position = UDim2.fromOffset(10, 95)
contentContainer.BackgroundColor3 = CARD_COLOR
contentContainer.BorderSizePixel = 0
contentContainer.Parent = main
corner(contentContainer, 8)

local tabs = {}
local activeTab = nil

local function createTab(name, text)
	local btn = makeButton(tabContainer, text, #tabs * 95, 0, 85, 35)
	btn.TextSize = 13
	local page = Instance.new("Frame")
	page.Size = UDim2.fromScale(1, 1)
	page.BackgroundTransparency = 1
	page.Visible = false
	page.Parent = contentContainer
	
	table.insert(tabs, { btn = btn, page = page })
	
	btn.MouseButton1Click:Connect(function()
		for _, t in ipairs(tabs) do
			t.page.Visible = false
			t.btn.BackgroundColor3 = OFF_COLOR
			t.btn.TextColor3 = WHITE
		end
		page.Visible = true
		btn.BackgroundColor3 = ACCENT
		btn.TextColor3 = PANEL_COLOR
	end)
	
	return page
end

local pageMain = createTab("main", "Principal")
local pageEsp = createTab("esp", "Visual")
local pageUtils = createTab("utils", "Utilidades")
local pageBridge = createTab("bridge", "Ponte")

------------------------------------------------------------
-- LÓGICA DO SCRIPT
------------------------------------------------------------
local flying = false
local flySpeed = 60
local noclip = false
local clickTP = false
local tpBlueTeamActive = false
local espLine = false
local espHighlight = false
local espInfo = false
local walkSpeedOn = false
local walkSpeedValue = 16
local autoQTE = false
local qteDelay = 0.2
local validKeys = {Q=true, R=true, F=true, Z=true, X=true, C=true, V=true, E=true}

local fullbrightActive = false
local originalAmbient, originalOutdoor, originalBrightness

local antiFlingActive = false

local function getChar() return player.Character end
local function getHRP() local c = getChar() return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum() local c = getChar() return c and c:FindFirstChildOfClass("Humanoid") end

-- Fly
local flyVel, flyGyro
local function stopFly()
	if flyVel then flyVel:Destroy() flyVel = nil end
	if flyGyro then flyGyro:Destroy() flyGyro = nil end
	local hum = getHum()
	if hum then hum.PlatformStand = false end
end

local function startFly()
	stopFly()
	local hrp, hum = getHRP(), getHum()
	if not hrp or not hum then return end
	hum.PlatformStand = true
	flyVel = Instance.new("BodyVelocity", hrp)
	flyVel.MaxForce = Vector3.new(1e9, 1e9, 1e9)
	flyVel.Velocity = Vector3.zero
	flyGyro = Instance.new("BodyGyro", hrp)
	flyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
	flyGyro.P = 1e4
	flyGyro.CFrame = hrp.CFrame
end

RunService.RenderStepped:Connect(function()
	if not (flying and flyVel and flyGyro) then return end
	local cf = workspace.CurrentCamera.CFrame
	local dir = Vector3.zero
	if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cf.LookVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cf.LookVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cf.RightVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cf.RightVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.yAxis end
	if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.yAxis end
	flyVel.Velocity = dir.Magnitude > 0 and dir.Unit * flySpeed or Vector3.zero
	flyGyro.CFrame = cf
end)

-- Noclip
RunService.Stepped:Connect(function()
	if not noclip then return end
	local char = getChar()
	if not char then return end
	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") then part.CanCollide = false end
	end
end)

-- WalkSpeed
local speedConn
local function applySpeed()
	local hum = getHum()
	if not hum then return end
	if speedConn then speedConn:Disconnect() speedConn = nil end
	if walkSpeedOn then
		hum.WalkSpeed = walkSpeedValue
		speedConn = hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
			if walkSpeedOn and hum.WalkSpeed ~= walkSpeedValue then hum.WalkSpeed = walkSpeedValue end
		end)
	else
		hum.WalkSpeed = 16
	end
end

-- TP Mouse / Shift
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.RightShift then
		main.Visible = not main.Visible
		return
	end
	if clickTP and input.UserInputType == Enum.UserInputType.MouseButton1 then
		local hrp = getHRP()
		if hrp and mouse.Hit then hrp.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0)) end
	end
end)

-- TP Time Azul
task.spawn(function()
	while task.wait(0.1) do
		if not tpBlueTeamActive then continue end
		local myChar = getChar()
		if not myChar then continue end
		local targetChar = nil
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= player and plr.Team and plr.Team.Name == "Azul" then
				local char = plr.Character
				if char and char:FindFirstChild("HumanoidRootPart") then
					targetChar = char
					break
				end
			end
		end
		if targetChar then
			local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
			if targetHRP then myChar:PivotTo(targetHRP.CFrame) end
		end
	end
end)

------------------------------------------------------------
-- AUTO QTE (HACK CIRÚRGICO VIA REMOTE EVENT)
------------------------------------------------------------
task.spawn(function()
	while task.wait(qteDelay) do
		if not autoQTE then continue end
		
		local impactFrames = playerGui:FindFirstChild("ImpactFrames")
		if not impactFrames then continue end
		
		local qteHolder = impactFrames:FindFirstChild("QTEHolder")
		if not qteHolder then continue end
		
		local qteMain = qteHolder:FindFirstChild("QTEMain")
		if not qteMain then continue end
		
		-- 1. Tenta descobrir qual é a tecla que apareceu na tela
		local foundKey = nil
		for _, obj in pairs(qteMain:GetDescendants()) do
			if obj:IsA("TextLabel") and obj.Text ~= "" then
				local text = obj.Text:upper()
				if validKeys[text] then 
					foundKey = text 
					break 
				end
			elseif obj:IsA("ImageLabel") and obj.Name ~= "" then
				local name = obj.Name:upper()
				if validKeys[name] then 
					foundKey = name 
					break 
				end
			elseif validKeys[obj.Name:upper()] then
				foundKey = obj.Name:upper()
				break
			end
		end
		
		-- 2. Se achou a tecla, age!
		if foundKey then
			pcall(function()
				-- Tenta achar o RemoteEvent e mandar pro servidor
				local qteEvents = ReplicatedStorage:FindFirstChild("QTEEvents")
				
				if qteEvents then
					local qteHandler = qteEvents:FindFirstChild("QTEHandler")
					if qteHandler then
						-- Dispara o RemoteEvent (O servidor acha que você clicou)
						qteHandler:FireServer(foundKey) 
					end
				end
				
				-- E também tenta simular o teclado como backup
				if type(keypress) == "function" then keypress(foundKey) end
				if type(VirtualInputManager) ~= "nil" then
					VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[foundKey], false, game)
					task.wait(0.01)
					VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[foundKey], false, game)
				end
			end)
		end
	end
end)

------------------------------------------------------------
-- FULLBRIGHT
------------------------------------------------------------
local function toggleFullbright(on)
	fullbrightActive = on
	if on then
		originalAmbient = Lighting.Ambient
		originalOutdoor = Lighting.OutdoorAmbient
		originalBrightness = Lighting.Brightness
		
		Lighting.Ambient = Color3.fromRGB(255, 255, 255)
		Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
		Lighting.Brightness = 3
	else
		if originalAmbient then Lighting.Ambient = originalAmbient end
		if originalOutdoor then Lighting.OutdoorAmbient = originalOutdoor end
		if originalBrightness then Lighting.Brightness = originalBrightness end
	end
end

------------------------------------------------------------
-- ANTI-FLING
------------------------------------------------------------
RunService.Heartbeat:Connect(function()
	if not antiFlingActive then return end
	local char = getChar()
	if not char then return end
	local hrp = getHRP()
	local hum = getHum()
	
	if hrp and hum then
		local vel = hrp.AssemblyLinearVelocity
		if vel.Magnitude > 100 then
			hrp.AssemblyLinearVelocity = Vector3.zero
		end
		local angVel = hrp.AssemblyAngularVelocity
		if angVel.Magnitude > 50 then
			hrp.AssemblyAngularVelocity = Vector3.zero
		end
	end
end)

------------------------------------------------------------
-- GLASS ESP
------------------------------------------------------------
local glassEspActive = false
local originalColors = {}

local function toggleGlassESP(on)
	glassEspActive = on
	if on then
		local possibleFolders = {
			workspace:FindFirstChild("GlassBridge"),
			workspace:FindFirstChild("Glass"),
			workspace:FindFirstChild("Bridge"),
			workspace:FindFirstChild("Panels"),
			workspace:FindFirstChild("Game")
		}
		local found = false
		for _, folder in ipairs(possibleFolders) do
			if folder then
				for _, obj in ipairs(folder:GetDescendants()) do
					if obj:IsA("BasePart") then
						found = true
						if not originalColors[obj] then originalColors[obj] = obj.Color end
						local name = obj.Name:lower()
						if name:find("fake") or name:find("break") or name:find("weak") or name:find("glass") then
							obj.Color = Color3.fromRGB(255, 0, 0)
						else
							obj.Color = Color3.fromRGB(0, 255, 0)
						end
					end
				end
			end
		end
		if not found then print("Snork Hub: Placas não encontradas.") end
	else
		for part, color in pairs(originalColors) do
			if part and part.Parent then part.Color = color end
		end
		table.clear(originalColors)
	end
end

------------------------------------------------------------
-- ESP
------------------------------------------------------------
local espGui = Instance.new("ScreenGui", playerGui)
espGui.Name = "SnorkESP"
espGui.ResetOnSpawn = false
espGui.DisplayOrder = 5

local lines = {}
local espInfoFrames = {}

local function clearAllESP()
	for plr, line in pairs(lines) do if line then line:Destroy() end end
	table.clear(lines)
	for plr, frame in pairs(espInfoFrames) do if frame then frame:Destroy() end end
	table.clear(espInfoFrames)
end

local function getLine(plr)
	local line = lines[plr]
	if line and line.Parent then return line end
	line = Instance.new("Frame", espGui)
	line.Name = "Antena_" .. plr.Name
	line.AnchorPoint = Vector2.new(0.5, 0.5)
	line.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	line.BorderSizePixel = 0
	line.Visible = false
	lines[plr] = line
	return line
end

local function getInfoFrame(plr)
	local frame = espInfoFrames[plr]
	if frame and frame.Parent then return frame end
	frame = Instance.new("Frame", espGui)
	frame.Name = "Info_" .. plr.Name
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.fromOffset(150, 40)
	frame.AnchorPoint = Vector2.new(0.5, 1)
	frame.Visible = false
	
	local nameLabel = Instance.new("TextLabel", frame)
	nameLabel.Name = "NameLabel"
	nameLabel.BackgroundTransparency = 1
	nameLabel.Size = UDim2.new(1, 0, 0, 20)
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 14
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextStrokeTransparency = 0
	nameLabel.Text = plr.Name
	
	local healthBarBg = Instance.new("Frame", frame)
	healthBarBg.Name = "HealthBg"
	healthBarBg.Size = UDim2.new(1, 0, 0, 8)
	healthBarBg.Position = UDim2.new(0, 0, 0, 22)
	healthBarBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	healthBarBg.BorderSizePixel = 0
	corner(healthBarBg, 4)
	
	local healthBar = Instance.new("Frame", healthBarBg)
	healthBar.Name = "HealthBar"
	healthBar.Size = UDim2.fromScale(1, 1)
	healthBar.BackgroundColor3 = Color3.fromRGB(60, 220, 90)
	healthBar.BorderSizePixel = 0
	corner(healthBar, 4)
	
	espInfoFrames[plr] = frame
	return frame
end

RunService.RenderStepped:Connect(function()
	if not espLine and not espInfo then return end 
	local cam = workspace.CurrentCamera
	local vp = cam.ViewportSize
	local origin = Vector2.new(vp.X / 2, vp.Y)

	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= player then
			local char = plr.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			
			if hrp then
				if espLine then
					local line = getLine(plr)
					local pos, onScreen = cam:WorldToViewportPoint(hrp.Position)
					if onScreen then
						local target = Vector2.new(pos.X, pos.Y)
						local d = target - origin
						line.Size = UDim2.fromOffset(d.Magnitude, 2)
						line.Position = UDim2.fromOffset((origin.X + target.X) / 2, (origin.Y + target.Y) / 2)
						line.Rotation = math.deg(math.atan2(d.Y, d.X))
						line.Visible = true
					else line.Visible = false end
				end
				
				if espInfo then
					local infoFrame = getInfoFrame(plr)
					local pos, onScreen = cam:WorldToViewportPoint(hrp.Position + Vector3.new(0, 3, 0))
					if onScreen then
						infoFrame.Position = UDim2.fromOffset(pos.X, pos.Y)
						infoFrame.Visible = true
						if hum then
							local healthPercent = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
							local healthBar = infoFrame:FindFirstChild("HealthBg"):FindFirstChild("HealthBar")
							healthBar.Size = UDim2.fromScale(healthPercent, 1)
							if healthPercent > 0.6 then healthBar.BackgroundColor3 = Color3.fromRGB(60, 220, 90)
							elseif healthPercent > 0.3 then healthBar.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
							else healthBar.BackgroundColor3 = Color3.fromRGB(255, 60, 60) end
							infoFrame:FindFirstChild("NameLabel").Text = plr.Name .. " [" .. math.floor(hum.Health) .. "]"
						end
					else infoFrame.Visible = false end
				end
			end
		end
	end
end)

local function updateHighlight(plr)
	if plr == player then return end
	local char = plr.Character
	if not char then return end
	local h = char:FindFirstChild("SnorkHighlight")
	if espHighlight then
		if not h then
			h = Instance.new("Highlight", char)
			h.Name = "SnorkHighlight"
			h.FillColor = Color3.fromRGB(255, 0, 0)
			h.FillTransparency = 0.6
			h.OutlineColor = Color3.fromRGB(255, 0, 0)
			h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		end
	elseif h then h:Destroy() end
end

Players.PlayerRemoving:Connect(function(plr)
	if lines[plr] then lines[plr]:Destroy() lines[plr] = nil end
	if espInfoFrames[plr] then espInfoFrames[plr]:Destroy() espInfoFrames[plr] = nil end
end)

-- Telecinese
local tele = false
local teleRange = 80
local teleOrbit = 14
local teleSpeed = 3
local teleMax = 50
local captured = {}
local teleCount = 0
local lastScan = 0

local function releaseAll()
	for part, data in pairs(captured) do
		if part.Parent then
			part.CanCollide = data.canCollide
			part.Gravity = data.gravity
			part.Massless = data.massless
		end
	end
	table.clear(captured)
	teleCount = 0
end

RunService.Heartbeat:Connect(function()
	if not tele then return end
	local hrp = getHRP()
	if not hrp then return end
	local now = os.clock()
	if now - lastScan > 0.2 then
		lastScan = now
		local found = workspace:GetPartBoundsInRadius(hrp.Position, teleRange, OverlapParams.new())
		for _, p in ipairs(found) do
			if teleCount >= teleMax then break end
			if not captured[p] and p:IsA("BasePart") and not p.Anchored and p.Size.Magnitude <= 40 then
				local model = p:FindFirstAncestorOfClass("Model")
				if not (model and model:FindFirstChildOfClass("Humanoid")) then
					captured[p] = { canCollide = p.CanCollide, gravity = p.Gravity, massless = p.Massless }
					teleCount += 1
					p.CanCollide = false
					p.Gravity = 0
					p.Massless = true
				end
			end
		end
	end
	local list = {}
	for part in pairs(captured) do
		if part.Parent == nil or part.Anchored then
			captured[part] = nil
			teleCount -= 1
		else table.insert(list, part) end
	end
	local n = #list
	local t = now * teleSpeed
	for i, part in ipairs(list) do
		local ang = t + (i / n) * math.pi * 2
		local layer = (i % 3) - 1
		local target = hrp.Position + Vector3.new(math.cos(ang) * teleOrbit, 2 + layer * 2 + math.sin(t * 2 + i) * 1.5, math.sin(ang) * teleOrbit)
		local vel = (target - part.Position) * 40
		if vel.Magnitude > 800 then vel = vel.Unit * 800 end
		part.AssemblyLinearVelocity = vel
		part.AssemblyAngularVelocity = Vector3.new(math.sin(t + i) * 30, 30, math.cos(t + i) * 30)
	end
end)

------------------------------------------------------------
-- COLOCANDO OS BOTÕES NAS ABAS
------------------------------------------------------------

-- ABA PRINCIPAL
local y = 20
makeToggle(pageMain, "Fly", 20, y, 200, 40, function(on) flying = on; if on then startFly() else stopFly() end end)
makeToggle(pageMain, "Noclip", 240, y, 200, 40, function(on) noclip = on end)

y += 50
makeToggle(pageMain, "TP com mouse", 20, y, 200, 40, function(on) clickTP = on end)
makeToggle(pageMain, "TP Time Azul", 240, y, 200, 40, function(on) tpBlueTeamActive = on end)

y += 50
makeToggle(pageMain, "Auto QTE", 20, y, 200, 40, function(on) autoQTE = on end)

y += 50
makeToggle(pageMain, "WalkSpeed", 20, y, 200, 40, function(on) walkSpeedOn = on; applySpeed() end)
local speedBox = Instance.new("TextBox", pageMain)
speedBox.Size = UDim2.fromOffset(80, 40)
speedBox.Position = UDim2.fromOffset(240, y)
speedBox.BackgroundColor3 = OFF_COLOR
speedBox.TextColor3 = WHITE
speedBox.Font = Enum.Font.GothamBold
speedBox.TextSize = 14
speedBox.Text = tostring(walkSpeedValue)
corner(speedBox, 6)
speedBox.FocusLost:Connect(function()
	local n = tonumber(speedBox.Text)
	if n then walkSpeedValue = math.clamp(n, 0, 500); applySpeed() end
	speedBox.Text = tostring(walkSpeedValue)
end)

-- ABA VISUAL (ESP)
y = 20
makeToggle(pageEsp, "ESP Antena", 20, y, 200, 40, function(on) 
    espLine = on 
    if not on then clearAllESP() end
end)

y += 50
makeToggle(pageEsp, "ESP Nome/Vida", 20, y, 200, 40, function(on) 
    espInfo = on 
    if not on then clearAllESP() end
end)

y += 50
makeToggle(pageEsp, "ESP Destaque", 20, y, 200, 40, function(on)
	espHighlight = on
	for _, plr in ipairs(Players:GetPlayers()) do updateHighlight(plr) end
end)

-- ABA PONTE (GLASS ESP)
y = 20
makeToggle(pageBridge, "Revelar Placas", 20, y, 200, 40, function(on)
	toggleGlassESP(on)
end)
local infoLabel = Instance.new("TextLabel", pageBridge)
infoLabel.Size = UDim2.fromOffset(400, 60)
infoLabel.Position = UDim2.fromOffset(20, 80)
infoLabel.BackgroundTransparency = 1
infoLabel.Text = "Verde = Segura | Vermelho = Falsa\n(Apenas funciona se o script achar as placas)"
infoLabel.TextColor3 = GRAY
infoLabel.Font = Enum.Font.GothamMedium
infoLabel.TextSize = 12
infoLabel.TextXAlignment = Enum.TextXAlignment.Left
infoLabel.TextWrapped = true

-- ABA UTILIDADES
y = 20
makeToggle(pageUtils, "Telecinese", 20, y, 200, 40, function(on)
	tele = on
	if not on then releaseAll() end
end)

makeToggle(pageUtils, "Fullbright", 240, y, 200, 40, function(on)
	toggleFullbright(on)
end)

y += 50
makeToggle(pageUtils, "Anti-Fling", 20, y, 200, 40, function(on)
	antiFlingActive = on
end)

local function makeInput(parent, text, x, y)
	local lbl = Instance.new("TextLabel", parent)
	lbl.Size = UDim2.fromOffset(70, 40)
	lbl.Position = UDim2.fromOffset(x, y)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextColor3 = GRAY
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 14
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	
	local box = Instance.new("TextBox", parent)
	box.Size = UDim2.fromOffset(80, 40)
	box.Position = UDim2.fromOffset(x + 70, y)
	box.BackgroundColor3 = OFF_COLOR
	box.TextColor3 = WHITE
	box.Font = Enum.Font.GothamBold
	box.TextSize = 14
	corner(box, 6)
	return box
end

local boxAlcance = makeInput(pageUtils, "Alcance:", 20, 130)
boxAlcance.Text = tostring(teleRange)
boxAlcance.FocusLost:Connect(function() 
	local n = tonumber(boxAlcance.Text) if n then teleRange = math.clamp(n, 5, 500) end 
end)

local boxOrbita = makeInput(pageUtils, "Órbita:", 180, 130)
boxOrbita.Text = tostring(teleOrbit)
boxOrbita.FocusLost:Connect(function() 
	local n = tonumber(boxOrbita.Text) if n then teleOrbit = math.clamp(n, 3, 100) end 
end)

-- Ativa a primeira aba por padrão
tabs[1].btn.BackgroundColor3 = ACCENT
tabs[1].btn.TextColor3 = PANEL_COLOR
pageMain.Visible = true
