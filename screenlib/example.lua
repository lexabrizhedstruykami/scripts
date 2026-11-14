--[[
  example.lua
  Пример скрипта на OriginLoader. Работает и на origin lib, и на origin new.
  Возможности, которые есть только в origin new (иконки, описания, контакты,
  меню more), включаются, когда загрузчик выдал origin new.
  Замените URL ниже на raw-ссылку вашего OriginLoader.lua.
]]

local lib = loadstring(game:HttpGet("URL_К_OriginLoader.lua"))()
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
if lib.Mask then
    -- Mask возвращает скрытое имя, пока включён режим стримера. Подпись
    -- обновляется сама, когда режим переключают.
    local who = main:Label("Игрок: " .. lib:Mask(player.DisplayName))
    lib:OnStreamerMode(function()
        who.Text = "Игрок: " .. lib:Mask(player.DisplayName)
    end)
end
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

-- BindButton (функция из functions.lua, есть в обеих библиотеках): кнопка,
-- которую можно нажать мышью и которая срабатывает по клавише. Клавишу игрок
-- меняет сам, нажав на плашку справа.
if main.BindButton then
    main:BindButton("Быстрое уведомление", Enum.KeyCode.B, function()
        lib:Notify({ Title = "BindButton", Content = "Сработало.", Duration = 2 })
    end)
end

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

-- ===== Вкладка Extras: функции из functions.lua (есть в обеих библиотеках) =====
if main.ToggleBind then
    local extras = window:Tab("Extras", 4)

    extras:Section("Toggles")
    extras:ToggleBind("Fly", false, function(on) print("Fly:", on) end, Enum.KeyCode.F)
    extras:LoopToggle("Pulse", false, 1, function() print("pulse") end)
    extras:SliderToggle("Aim FOV", 10, 300, 90, false, function(on, fov) print("Aim", on, fov) end)

    extras:Section("Buttons")
    extras:ConfirmButton("Reset progress", function() print("reset") end)
    extras:TimedButton("Heal", 5, function() print("heal") end)
    extras:CopyButton("Copy user id", function() return player.UserId end)
    extras:DropdownButton("Place", { "Spawn", "Shop" }, "Spawn", "Teleport", function(place) print("tp", place) end)

    extras:Section("Player")
    extras:HumanoidSlider("WalkSpeed", "WalkSpeed", 16, 120, 16)
    extras:Info("Health", function()
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        return humanoid and math.floor(humanoid.Health) or "no character"
    end, 1)
end

-- ===== Меню more (только origin new) =====
-- Три точки справа от ника игрока. Появляются, когда добавлен хотя бы один пункт.
if window.More then
    window:More("Copy user id", function()
        -- В режиме стримера id не копируем и не показываем.
        if lib.GetStreamerMode and lib:GetStreamerMode() then
            lib:Notify({ Title = "More", Content = "Hidden in streamer mode.", Type = "warning" })
            return
        end
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
