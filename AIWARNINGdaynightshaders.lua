local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local PathfindingService = game:GetService("PathfindingService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local playerGui = player:WaitForChild("PlayerGui")

-- Исходные настройки
local defaultClockTime = Lighting.ClockTime
local defaultBrightness = Lighting.Brightness
local defaultOutdoorAmbient = Lighting.OutdoorAmbient
local defaultAmbient = Lighting.Ambient
local defaultFogEnd = Lighting.FogEnd
local defaultFogColor = Lighting.FogColor

local horrorModeActive = false
local nightAudioEnabled = true -- Состояние звука ночи
local currentEntity = nil
local isTriggered = false
local sightTimer = 0
local unseenTimer = 0
local isWandering = false

-- Сохранение оригинальной громкости звуков птиц
local originalBirdVolumes = {}

for _, desc in ipairs(workspace:GetDescendants()) do
	if desc:IsA("Sound") then
		if desc.Name:find("BirdSound") or desc.SoundId:find("1520928") or desc.Name:lower():find("bird") then
			originalBirdVolumes[desc] = desc.Volume
		end
	end
end

-- Звук сверчков / фонового эмбиента
local cricketSound = Instance.new("Sound")
cricketSound.Name = "FTAP_Crickets"
cricketSound.SoundId = "rbxassetid://86300687"
cricketSound.Volume = 0.75 -- Громкость 0.75
cricketSound.PlaybackSpeed = 1.25 -- Увеличенная скорость
cricketSound.Looped = true
cricketSound.Parent = SoundService

local function updateFTAPAudio(isNight)
	local shouldPlay = isNight and nightAudioEnabled
	if shouldPlay then
		if not cricketSound.IsPlaying then cricketSound:Play() end
	else
		if cricketSound.IsPlaying then cricketSound:Stop() end
	end

	for desc, origVol in pairs(originalBirdVolumes) do
		if desc and desc.Parent then
			desc.Volume = shouldPlay and 0 or origVol
		end
	end
end

-- 1. GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ShaderMenuGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local topbarButton = Instance.new("TextButton")
topbarButton.Name = "TopbarToggle"
topbarButton.Size = UDim2.new(0, 110, 0, 36)
topbarButton.Position = UDim2.new(0, 10, 0, 8)
topbarButton.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
topbarButton.BackgroundTransparency = 0.2
topbarButton.Text = "☀️ Шейдеры"
topbarButton.TextColor3 = Color3.fromRGB(255, 255, 255)
topbarButton.TextSize = 14
topbarButton.Font = Enum.Font.SourceSansBold
topbarButton.Parent = screenGui

local topbarCorner = Instance.new("UICorner")
topbarCorner.CornerRadius = UDim.new(0, 8)
topbarCorner.Parent = topbarButton

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 200, 0, 335)
mainFrame.Position = UDim2.new(0, 10, 0, 50)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 10)
mainCorner.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, 0, 0, 35)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "FTAP Шейдеры"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 15
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.Parent = mainFrame

local function createButton(name, text, positionY, color)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = UDim2.new(0.88, 0, 0, 32)
	button.Position = UDim2.new(0.06, 0, 0, positionY)
	button.BackgroundColor3 = color
	button.Text = text
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = 14
	button.Font = Enum.Font.SourceSansSemibold
	button.Parent = mainFrame

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 6)
	btnCorner.Parent = button

	return button
end

local btnDay = createButton("BtnDay", "Day (День)", 40, Color3.fromRGB(50, 150, 250))
local btnNight = createButton("BtnNight", "Night (Жесткая ночь)", 80, Color3.fromRGB(20, 20, 40))
local btnOff = createButton("BtnOff", "OFF (Сброс света)", 120, Color3.fromRGB(80, 80, 90))
local btnAudioToggle = createButton("BtnAudioToggle", "🔊 Звуки ночи: ON", 160, Color3.fromRGB(40, 140, 80))
local btnHorror = createButton("BtnHorror", "💀 Horror Mode: OFF", 200, Color3.fromRGB(60, 60, 60))
local btnUnload = createButton("BtnUnload", "⚠️ Полная отгрузка", 245, Color3.fromRGB(180, 40, 40))

-- 2. Режимы Освещения
local function isNightTime()
	return Lighting.ClockTime < 6 or Lighting.ClockTime > 18 or horrorModeActive
end

local function setDayMode()
	Lighting.ClockTime = 14
	Lighting.Brightness = 3
	Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
	Lighting.Ambient = Color3.fromRGB(100, 100, 100)
	Lighting.FogEnd = 100000
	updateFTAPAudio(false)
end

local function setNightMode()
	Lighting.ClockTime = 0
	Lighting.Brightness = 0
	Lighting.OutdoorAmbient = Color3.fromRGB(0, 0, 0)
	Lighting.Ambient = Color3.fromRGB(2, 2, 5)
	Lighting.FogColor = Color3.fromRGB(0, 0, 0)
	Lighting.FogEnd = 120
	updateFTAPAudio(true)
end

local function resetLighting()
	Lighting.ClockTime = defaultClockTime
	Lighting.Brightness = defaultBrightness
	Lighting.OutdoorAmbient = defaultOutdoorAmbient
	Lighting.Ambient = defaultAmbient
	Lighting.FogEnd = defaultFogEnd
	Lighting.FogColor = defaultFogColor
	updateFTAPAudio(false)
end

-- 3. Создание черного NPC
local function createBlackNPC()
	if currentEntity then currentEntity:Destroy() end

	local model = Instance.new("Model")
	model.Name = "FTAP_BlackNPC"

	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(2, 2, 1)

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(1.2, 1.2, 1.2)

	local leftArm = Instance.new("Part")
	leftArm.Name = "Left Arm"
	leftArm.Size = Vector3.new(1, 2, 1)

	local rightArm = Instance.new("Part")
	rightArm.Name = "Right Arm"
	rightArm.Size = Vector3.new(1, 2, 1)

	local leftLeg = Instance.new("Part")
	leftLeg.Name = "Left Leg"
	leftLeg.Size = Vector3.new(1, 2, 1)

	local rightLeg = Instance.new("Part")
	rightLeg.Name = "Right Leg"
	rightLeg.Size = Vector3.new(1, 2, 1)

	local parts = {torso, head, leftArm, rightArm, leftLeg, rightLeg}

	for _, part in ipairs(parts) do
		part.Color = Color3.fromRGB(0, 0, 0)
		part.Material = Enum.Material.SmoothPlastic
		part.CanCollide = true
		part.Anchored = false
		part.Parent = model
	end

	model.PrimaryPart = torso

	local function weld(p0, p1, cframe)
		p1.CFrame = p0.CFrame * cframe
		local w = Instance.new("WeldConstraint")
		w.Part0 = p0
		w.Part1 = p1
		w.Parent = p0
	end

	weld(torso, head, CFrame.new(0, 1.6, 0))
	weld(torso, leftArm, CFrame.new(-1.5, 0, 0))
	weld(torso, rightArm, CFrame.new(1.5, 0, 0))
	weld(torso, leftLeg, CFrame.new(-0.5, -2, 0))
	weld(torso, rightLeg, CFrame.new(0.5, -2, 0))

	-- Звук шагов при блуждании
	local stepSound = Instance.new("Sound")
	stepSound.Name = "Footsteps"
	stepSound.SoundId = "rbxassetid://142665239"
	stepSound.Volume = 0.75
	stepSound.PlaybackSpeed = 1.2
	stepSound.Looped = true
	stepSound.Parent = torso

	model.Parent = workspace
	return model
end

-- Поиск доступной точки для спавна (от 471 до 1071 стадов)
local function getValidSpawnPosition(hrp, minDist, maxDist)
	for i = 1, 12 do
		local angle = math.rad(math.random(0, 360))
		local targetDist = math.random(minDist, maxDist)
		local testPos = hrp.Position + Vector3.new(math.cos(angle) * targetDist, 5, math.sin(angle) * targetDist)

		local ray = workspace:Raycast(testPos, Vector3.new(0, -100, 0))
		if ray and ray.Position then
			local groundPos = ray.Position + Vector3.new(0, 3.5, 0)
			local path = PathfindingService:CreatePath()
			path:ComputeAsync(hrp.Position, groundPos)

			if path.Status == Enum.PathStatus.Success then
				return groundPos
			end
		end
	end
	local fallbackDist = math.random(minDist, maxDist)
	return hrp.Position + hrp.CFrame.LookVector * fallbackDist
end

-- Проверки видимости
local function isPartOnScreen(part)
	if not part then return false end
	local screenPos, onScreen = camera:WorldToViewportPoint(part.Position)
	return onScreen and screenPos.Z > 0
end

local function isLookingDirectlyAt(part)
	if not part then return false end
	local unitRay = camera:ViewportPointToRay(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	if player.Character then
		raycastParams.FilterDescendantsInstances = {player.Character}
	end

	local result = workspace:Raycast(unitRay.Origin, unitRay.Direction * 1200, raycastParams)
	return result and result.Instance and result.Instance:IsDescendantOf(part.Parent)
end

-- 4. Логика Спавна (от 471 до 1071 стадов)
local function spawnLogic()
	task.spawn(function()
		while task.wait(math.random(12, 22)) do
			if isTriggered or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
				continue
			end

			local hrp = player.Character.HumanoidRootPart
			sightTimer = 0
			unseenTimer = 0
			isWandering = false

			local spawnPos = getValidSpawnPosition(hrp, 471, 1071)
			currentEntity = createBlackNPC()
			currentEntity:SetPrimaryPartCFrame(CFrame.new(spawnPos, Vector3.new(hrp.Position.X, spawnPos.Y, hrp.Position.Z)))
		end
	end)
end

-- Логика Блуждания
local function startWandering()
	if isWandering or not currentEntity or not currentEntity.PrimaryPart then return end
	isWandering = true

	local torso = currentEntity.PrimaryPart
	local sound = torso:FindFirstChild("Footsteps")
	if sound then sound:Play() end

	task.spawn(function()
		while isWandering and currentEntity and currentEntity.PrimaryPart and not isTriggered do
			local randomOffset = Vector3.new(math.random(-12, 12), 0, math.random(-12, 12))
			local targetPos = torso.Position + randomOffset
			
			local startTime = tick()
			while tick() - startTime < 3 and currentEntity and currentEntity.PrimaryPart and isWandering and not isTriggered do
				local dir = (targetPos - torso.Position).Unit
				torso.CFrame = CFrame.new(torso.Position + dir * (7 * RunService.RenderStepped:Wait()), torso.Position + dir)
			end
			task.wait(math.random(1, 2))
		end
		if sound then sound:Stop() end
	end)
end

-- 5. Обработчик кадров (RenderStepped)
RunService.RenderStepped:Connect(function(dt)
	if currentEntity and currentEntity.PrimaryPart and not isTriggered then
		local npcPart = currentEntity.PrimaryPart

		-- Прямой взгляд прицелом
		if isLookingDirectlyAt(npcPart) then
			if not horrorModeActive then
				currentEntity:Destroy()
				currentEntity = nil
				sightTimer = 0
				unseenTimer = 0
				return
			end
		end

		-- В зоне экрана
		if isPartOnScreen(npcPart) then
			unseenTimer = 0
			isWandering = false
			local sound = npcPart:FindFirstChild("Footsteps")
			if sound then sound:Stop() end

			if horrorModeActive then
				-- Нападение при Horror Mode
				isTriggered = true
				local npcModel = currentEntity

				local scream = Instance.new("Sound")
				scream.SoundId = "rbxassetid://9114223179"
				scream.Volume = 4
				scream.Parent = npcPart
				scream:Play()

				for _, part in ipairs(npcModel:GetChildren()) do
					if part:IsA("BasePart") then part.Anchored = true end
				end

				local stretchDuration = 3
				for _, part in ipairs(npcModel:GetChildren()) do
					if part:IsA("BasePart") then
						local targetScale = part.Size * Vector3.new(1.8, 3.2, 1.8)
						TweenService:Create(part, TweenInfo.new(stretchDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Size = targetScale}):Play()
					end
				end

				task.wait(stretchDuration)

				-- Погоня
				task.spawn(function()
					local speed = 32
					while npcModel and npcModel.PrimaryPart and player.Character and player.Character:FindFirstChild("HumanoidRootPart") do
						local hrp = player.Character.HumanoidRootPart
						local currentPos = npcModel.PrimaryPart.Position
						local targetPos = Vector3.new(hrp.Position.X, currentPos.Y, hrp.Position.Z)
						local distance = (targetPos - currentPos).Magnitude

						if distance < 4.5 then
							if player.Character:FindFirstChild("Humanoid") then
								player.Character.Humanoid.Health = 0
							end
							task.wait(0.2)
							player:Kick("💀 Черный силуэт нагнал вас.")
							break
						end

						local newPos = currentPos + (targetPos - currentPos).Unit * (speed * RunService.RenderStepped:Wait())
						npcModel:SetPrimaryPartCFrame(CFrame.new(newPos, targetPos))
					end
				end)
			else
				-- Задержка 3 сек в обычном режиме перед исчезновением
				sightTimer = sightTimer + dt
				if sightTimer >= 3 then
					currentEntity:Destroy()
					currentEntity = nil
					sightTimer = 0
				end
			end
		else
			-- Не видно силуэт
			sightTimer = 0
			unseenTimer = unseenTimer + dt
			if unseenTimer >= 4 then
				startWandering()
			end
		end
	end
end)

-- 6. Кнопки
btnAudioToggle.MouseButton1Click:Connect(function()
	nightAudioEnabled = not nightAudioEnabled
	if nightAudioEnabled then
		btnAudioToggle.Text = "🔊 Звуки ночи: ON"
		btnAudioToggle.BackgroundColor3 = Color3.fromRGB(40, 140, 80)
	else
		btnAudioToggle.Text = "🔇 Звуки ночи: OFF"
		btnAudioToggle.BackgroundColor3 = Color3.fromRGB(120, 60, 60)
	end
	updateFTAPAudio(isNightTime())
end)

btnHorror.MouseButton1Click:Connect(function()
	horrorModeActive = not horrorModeActive
	if horrorModeActive then
		btnHorror.Text = "💀 Horror Mode: ON"
		btnHorror.BackgroundColor3 = Color3.fromRGB(200, 20, 20)
		setNightMode()
	else
		btnHorror.Text = "💀 Horror Mode: OFF"
		btnHorror.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	end
end)

local function unloadScript()
	resetLighting()
	if currentEntity then currentEntity:Destroy() end
	screenGui:Destroy()
	script:Destroy()
end

topbarButton.MouseButton1Click:Connect(function()
	mainFrame.Visible = not mainFrame.Visible
end)

btnDay.MouseButton1Click:Connect(setDayMode)
btnNight.MouseButton1Click:Connect(setNightMode)
btnOff.MouseButton1Click:Connect(resetLighting)
btnUnload.MouseButton1Click:Connect(unloadScript)

spawnLogic()
