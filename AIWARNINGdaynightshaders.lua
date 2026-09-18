local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- 0. Сохраняем исходные настройки освещения
local defaultClockTime = Lighting.ClockTime
local defaultBrightness = Lighting.Brightness
local defaultOutdoorAmbient = Lighting.OutdoorAmbient
local defaultAmbient = Lighting.Ambient
local defaultFogEnd = Lighting.FogEnd
local defaultFogColor = Lighting.FogColor

-- 1. Создаем ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ShaderMenuGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- 2. Топбар Кнопка (Свернуть/Развернуть меню)
local topbarButton = Instance.new("TextButton")
topbarButton.Name = "TopbarToggle"
topbarButton.Size = UDim2.new(0, 110, 0, 36)
topbarButton.Position = UDim2.new(0, 10, 0, 8) -- В верхнем левом углу
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

-- 3. Главный фрейм меню
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 200, 0, 255)
mainFrame.Position = UDim2.new(0, 10, 0, 50) -- Позиция под топбаром
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true -- Перетаскивание
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 10)
mainCorner.Parent = mainFrame

-- Заголовок
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, 0, 0, 35)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Шейдеры / Освещение"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 15
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.Parent = mainFrame

-- Вспомогательная функция для быстрого создания кнопок
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

-- Создаем кнопки в меню
local btnDay = createButton("BtnDay", "Day (День)", 40, Color3.fromRGB(50, 150, 250))
local btnNight = createButton("BtnNight", "Night (Жесткая ночь)", 80, Color3.fromRGB(20, 20, 40))
local btnOff = createButton("BtnOff", "OFF (Сброс света)", 120, Color3.fromRGB(80, 80, 90))
local btnUnload = createButton("BtnUnload", "⚠️ Полная отгрузка", 165, Color3.fromRGB(180, 40, 40))

-- 4. Функции шейдеров

-- День
local function setDayMode()
	Lighting.ClockTime = 14
	Lighting.Brightness = 3
	Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
	Lighting.Ambient = Color3.fromRGB(100, 100, 100)
	Lighting.FogEnd = 100000
end

-- Ночь (Жесткая, ничего не видно)
local function setNightMode()
	Lighting.ClockTime = 0
	Lighting.Brightness = 0
	Lighting.OutdoorAmbient = Color3.fromRGB(0, 0, 0)
	Lighting.Ambient = Color3.fromRGB(2, 2, 5)
	Lighting.FogColor = Color3.fromRGB(0, 0, 0)
	Lighting.FogEnd = 100
end

-- Сбросить настройки (OFF)
local function resetLighting()
	Lighting.ClockTime = defaultClockTime
	Lighting.Brightness = defaultBrightness
	Lighting.OutdoorAmbient = defaultOutdoorAmbient
	Lighting.Ambient = defaultAmbient
	Lighting.FogEnd = defaultFogEnd
	Lighting.FogColor = defaultFogColor
end

-- Полная отгрузка (Unload): сброс освещения и полная очистка интерфейса и скрипта
local function unloadScript()
	resetLighting() -- Возвращаем исходный свет
	screenGui:Destroy() -- Удаляем GUI
	script:Destroy() -- Удаляем сам скрипт из памяти
end

-- 5. Подключение событий

-- Переключение видимости через Топбар
topbarButton.MouseButton1Click:Connect(function()
	mainFrame.Visible = not mainFrame.Visible
end)

-- Клики по кнопкам
btnDay.MouseButton1Click:Connect(setDayMode)
btnNight.MouseButton1Click:Connect(setNightMode)
btnOff.MouseButton1Click:Connect(resetLighting)
btnUnload.MouseButton1Click:Connect(unloadScript)
