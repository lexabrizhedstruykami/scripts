--[[
  example.lua
  Пример скрипта на OriginLoader. Работает и на origin lib, и на origin new.
  Замените URL ниже на raw-ссылку вашего OriginLoader.lua.
]]

local lib = loadstring(game:HttpGet("URL_К_OriginLoader.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

-- Вступительная плашка
lib:ShowIntro("My Hub", 2)

-- Окно. Вкладка настроек со всеми опциями создаётся сама.
local window = lib:Window({ Title = "My Hub" })

-- ===== Вкладка Main =====
local main = window:Tab("Main")

main:Section("Info")
main:Paragraph("Добро пожаловать", "Это пример скрипта. Все элементы ниже работают в обеих библиотеках.")
main:Label("Меню открывается и закрывается клавишей из настроек.")
main:Divider()

local status = main:Notice("Авто-фарм выключен", Color3.fromRGB(150, 150, 170))

main:Section("Actions")

main:Button("Показать уведомление", function()
    lib:Notify({
        Title = "Привет",
        Content = "Кнопка нажата.",
        Duration = 3,
    })
end)

-- Авто-фарм: цикл на Heartbeat, который выключается и при снятии тоггла,
-- и при выгрузке скрипта.
local farmConnection
local function stopFarm()
    if farmConnection then
        farmConnection:Disconnect()
        farmConnection = nil
    end
end

main:Toggle("Auto Farm", false, function(state)
    stopFarm()
    if state then
        status.Set("Авто-фарм включён", Color3.fromRGB(110, 210, 140))
        farmConnection = RunService.Heartbeat:Connect(function()
            -- Здесь ваша логика фарма.
        end)
    else
        status.Set("Авто-фарм выключен", Color3.fromRGB(150, 150, 170))
    end
end)

-- ===== Вкладка Player =====
local playerTab = window:Tab("Player")

playerTab:Section("Movement")

playerTab:Slider("WalkSpeed", 16, 120, 16, function(value)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid then humanoid.WalkSpeed = value end
end)

playerTab:Slider("JumpPower", 50, 200, 50, function(value)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.UseJumpPower = true
        humanoid.JumpPower = value
    end
end)

playerTab:Section("Input")

playerTab:TextBox("Имя игрока", "Введите ник...", function(text)
    print("Введено:", text)
end)

playerTab:Keybind("Быстрое действие", Enum.KeyCode.F, function()
    lib:Notify({ Title = "Keybind", Content = "Нажата клавиша F.", Duration = 2 })
end)

-- ===== Вкладка Visuals =====
local visuals = window:Tab("Visuals")

visuals:Section("Colors")

visuals:ColorPicker("Цвет ESP", Color3.fromRGB(255, 80, 80), function(color)
    print("Цвет ESP:", color)
end)

visuals:Section("Lists")

visuals:Dropdown("Оружие", { "Sword", "Bow", "Staff" }, "Sword", function(selected)
    print("Оружие:", selected)
end)

visuals:MultiDropdown("Модули", { "ESP", "Tracers", "Names" }, { "ESP" }, function(list)
    print("Модули:", table.concat(list, ", "))
end)

-- ===== Очистка =====
-- Выполняется при нажатии Unload Script в настройках.
lib:OnUnload(function()
    stopFarm()
end)

-- Очистка только этого окна (если у вас несколько окон):
-- window:OnUnload(function() print("Окно закрыто") end)
