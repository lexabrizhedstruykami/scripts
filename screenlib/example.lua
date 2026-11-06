--[[
  example.lua
  Пример скрипта на OriginLoader. Работает и на origin lib, и на origin new.
  Возможности, которые есть только в origin new (иконки, описания, контакты,
  меню more), включаются, когда загрузчик выдал origin new.
  Замените URL ниже на raw-ссылку вашего OriginLoader.lua.
]]

local lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/lexabrizhedstruykami/scripts/refs/heads/main/screenlib/OriginLoader.lua"))()
local isNew = lib.Name == "origin new"

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

-- В origin new название элемента можно передать таблицей с иконкой и описанием.
-- В origin lib остаётся обычная строка.
local function item(text, icon, desc)
    if not isNew then return text end
    return { Text = text, Icon = icon, Desc = desc }
end

lib:ShowIntro("My Hub", 2)

-- Контакты (только origin new) показываются над ником игрока.
local window = lib:Window({
    Title = "My Hub",
    -- Пресет автора (только origin new). Игрок выбирает его в настройках
    -- в списке Config под именем "preset by script". При первом запуске
    -- эти значения применяются сами.
    Preset = {
        accent = "#394F95",
        uiscale = 100,
        language = "en",
    },
    -- Icon = "https://example.com/logo.png",
    -- HideIcon = "https://example.com/eye.png",
    contdsc = "https://discord.gg/yourcommunity",
    conttg = "https://t.me/yourchannel",
    contcustom = "https://example.com/community",
})

-- ===== Вкладка Main =====
local main = window:Tab("Main", 1, "rbxassetid://7733954760")

main:Section("Info")
main:Paragraph("Добро пожаловать", "Это пример скрипта. Наведите курсор на функцию, чтобы увидеть описание, и попробуйте поиск сверху.")
main:Label("Меню открывается и закрывается клавишей из настроек.")
main:Divider()

local status = main:Notice("Авто-фарм выключен", Color3.fromRGB(150, 150, 170))

main:Section("Actions")

main:Button(item("Показать уведомление", nil, {
    en = "Shows a test notification in the corner.",
    ru = "Показывает тестовое уведомление в углу экрана.",
}), function()
    lib:Notify({ Title = "Привет", Content = "Кнопка нажата.", Duration = 3 })
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

main:Toggle(item("Auto Farm", nil, {
    en = "Runs the farming loop on every frame.",
    ru = "Запускает цикл фарма на каждом кадре.",
}), false, function(state)
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
local playerTab = window:Tab("Player", 2)

playerTab:Section("Movement")

playerTab:Slider(item("WalkSpeed", nil, {
    en = "Walking speed of your character.",
    ru = "Скорость ходьбы вашего персонажа.",
}), 16, 120, 16, function(value)
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
local visuals = window:Tab("Visuals", 3)

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

-- ===== Меню more (только origin new) =====
-- Три точки справа от ника игрока. Появляются, когда добавлен хотя бы один пункт.
if window.More then
    window:More("Copy user id", function()
        if setclipboard then setclipboard(tostring(player.UserId)) end
        lib:Notify({ Title = "More", Content = "User id copied.", Type = "success" })
    end)
    window:More("Print hello", function() print("hello") end)
end

-- ===== Очистка =====
-- Выполняется при нажатии Unload Script в настройках и на крестике.
lib:OnUnload(function()
    stopFarm()
end)
