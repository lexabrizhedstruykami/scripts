--[[ ==========================================================================
                                 originNEW v1.1
              Новая UI-библиотека для Roblox с тем же API, что у originLIB
     ==========================================================================

  ЧТО ВНУТРИ
    * Те же методы, что у originLIB: Window, Tab, Button, Toggle, Slider,
      TextBox, Keybind, ColorPicker, Dropdown, MultiDropdown, Paragraph,
      Section, Label, Divider, Notice, Notify, ShowIntro, OnUnload, Unload.
      Скрипт, написанный под originLIB, работает и тут без правок.
    * Стиль: анимированная градиентная обводка и свечение окна, плавное
      появление и скрытие, боковая панель с аватаром, ripple на кнопках,
      слайдеры, которые скользят к значению, HEX-ввод в ColorPicker,
      уведомления с типами (info, success, warning, error).
    * Акцент по умолчанию Ember Night (#394F95). Буква логотипа, ручки
      тогглов и слайдеров, текст на тёмном фоне подстраиваются под любой
      акцент, в том числе белый.
    * Поиск ищет по названию и по описанию, подсвечивает найденное.
    * Описания функций на разных языках, показываются при наведении.
    * Иконки: в заголовке, у вкладок, у элементов, у контактов и в меню more.
      Принимаются ассет Roblox, ссылка (скачивается в OriginNew/icons) и
      файл из папки workspace. Для ссылок и файлов нужен getcustomasset.
    * Кнопки окна: крестик выгружает меню, минус сворачивает (остаются
      название вкладки и игрок), глаз скрывает (откроется по бинду).
    * Контакты над разделителем футера: contdsc, conttg, contcustom.
    * Меню more (три точки справа от игрока): window:More(...).
    * Стеклянный блюр (Enable Blur): парт-стекло и DepthOfField.
    * Настройки сохраняются в OriginNewGuiSettings.cfg.
    * Пресет автора скрипта (Window({ Preset = {...} })) и список конфигов в
      настройках: "preset by script" и свои конфиги в OriginNew/configs.
    * Выбор библиотеки ("UI lib"): строка lib в том же cfg. После смены
      приходит сообщение о перезапуске, новая библиотека включится при
      следующем запуске через OriginLoader.lua.

  БЫСТРЫЙ СТАРТ
    local originNew = loadstring(game:HttpGet("URL"))()
    local window = originNew:Window({ Title = "My Hub" })
    local tab = window:Tab("Main")
    tab:Toggle("Auto Farm", false, function(state) print(state) end)

  ПАРАМЕТРЫ ОКНА
    Title, Subtitle, Icon, HideIcon, DisableSettings, Preset,
    contdsc, conttg, contcustom (ссылки), Contacts = { "contdsc:URL", ... }

  ЭЛЕМЕНТ С ИКОНКОЙ И ОПИСАНИЕМ
    tab:Button({ Text = "Fly", Icon = "https://...png",
                 Desc = { en = "Lets you fly", ru = "Позволяет летать" } }, cb)

  ИСТОРИЯ ИЗМЕНЕНИЙ
  v1.1
    [FIX]     Вкладка настроек падала на кнопке Unload: поле tab.Button
              перекрывало метод Tab:Button. Поле теперь tab.TabButton.
    [FIX]     Тогглы настроек не выключаются при Unload и не затирают конфиг.
    [FEATURE] Конфиг OriginNewGuiSettings.cfg (accent, ToggleKey, uiscale,
              opacity, resize, glow, lib, unlockcur, fullscreenblur,
              fullblurlevel, language, glass, glassdark, glassoffset,
              autoloadme).
    [FEATURE] Акцент по умолчанию #394F95 и подстройка цветов под акцент.
    [FEATURE] Иконки, описания на нескольких языках, поиск по описанию.
    [FEATURE] Контакты, меню more, кнопки "глаз", "минус", "крестик".
    [FEATURE] Свёрнутый режим: только название вкладки и игрок.
    [FEATURE] Стеклянный блюр, плавные слайдеры.
    [FEATURE] Пресет автора скрипта и именованные конфиги в настройках.

  v1.0
    Первая версия.
============================================================================ ]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local TextService = game:GetService("TextService")
local Workspace = game:GetService("Workspace")

local LIB_NAME = "origin new"
local UI_LIB_NAMES = { "origin lib", "origin new" }
local UI_LIB_FILE = "originLIB_uilib.txt"
local RESTART_MESSAGE = "Restart the script to enable other ui lib"

local originNew = {
    Version = "1.1",
    Name = LIB_NAME,
    Windows = {},
    GlobalUnloadTasks = {},
    NotificationHolder = nil,
    NotifGui = nil,
    _notifCounter = 0,
    _openWindowCount = 0,
    -- Курсор
    _cursorUnlockEnabled = true,
    _cursorChanged = false,
    _cursorConn = nil,
    _savedMouseIconEnabled = nil,
    _savedMouseBehavior = nil,
    -- Размытие экрана
    _blurEnabled = false,
    _blurSize = 12,
    BlurEffect = nil,
    -- Стеклянный парт (общий DepthOfField на все окна с включённым стеклом)
    _glassUsers = 0,
    _glassDOF = nil,
    -- Конфиг
    _cfg = nil,
    _preset = {},
    _autoSave = true,
    _saveToken = 0,
    Languages = { "en", "ru", "uk", "es", "de", "fr", "pt", "tr", "pl" },
}

local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

-- ==========================================
-- ПАЛИТРА
-- ==========================================
local C = {
    Bg        = Color3.fromRGB(11, 11, 16),
    Panel     = Color3.fromRGB(15, 15, 21),
    Card      = Color3.fromRGB(21, 21, 29),
    CardHover = Color3.fromRGB(27, 27, 38),
    Field     = Color3.fromRGB(14, 14, 20),
    Stroke    = Color3.fromRGB(38, 38, 52),
    StrokeHi  = Color3.fromRGB(66, 66, 92),
    Text      = Color3.fromRGB(236, 236, 246),
    SubText   = Color3.fromRGB(152, 152, 176),
    Dim       = Color3.fromRGB(98, 98, 122),
    Off       = Color3.fromRGB(48, 48, 64),
    Success   = Color3.fromRGB(88, 220, 138),
    Warning   = Color3.fromRGB(255, 190, 80),
    Error     = Color3.fromRGB(255, 96, 112),
}

-- Яркость цвета (0..1). Нужна, чтобы подбирать читаемые цвета под любой акцент.
local function luminance(c)
    return 0.2126 * c.R + 0.7152 * c.G + 0.0722 * c.B
end

-- Цвет элементов, которые лежат НА акценте (буква в логотипе, ручка тоггла).
-- Светлый акцент получает тёмный элемент, тёмный акцент получает белый.
local function contrastOn(c)
    if luminance(c) > 0.6 then return Color3.fromRGB(16, 16, 22) end
    return Color3.fromRGB(255, 255, 255)
end

-- Акцент для текста на тёмном фоне окна: тёмный акцент осветляется до читаемого.
local function readableAccent(c)
    local l = luminance(c)
    local target = 0.42
    if l >= target then return c end
    local t = (target - l) / (1 - l)
    return Color3.new(c.R + (1 - c.R) * t, c.G + (1 - c.G) * t, c.B + (1 - c.B) * t)
end

-- Ember Night, #394F95
local DEFAULT_ACCENT = Color3.fromRGB(57, 79, 149)

local NOTIF_COLORS = {
    info = readableAccent(DEFAULT_ACCENT),
    success = C.Success,
    warning = C.Warning,
    error = C.Error,
}

-- ==========================================
-- УТИЛИТЫ
-- ==========================================
local function tween(object, properties, duration, style, direction)
    local info = TweenInfo.new(
        duration or 0.2,
        style or Enum.EasingStyle.Quint,
        direction or Enum.EasingDirection.Out
    )
    local anim = TweenService:Create(object, info, properties)
    anim:Play()
    return anim
end

local function safeCall(fn, ...)
    if type(fn) ~= "function" then return end
    local ok, err = pcall(fn, ...)
    if not ok then
        warn("[originNEW] Ошибка в колбэке: " .. tostring(err))
    end
end

local function protectUI(gui)
    if syn and syn.protect_gui then
        syn.protect_gui(gui)
        gui.Parent = CoreGui
    elseif gethui then
        gui.Parent = gethui()
    else
        gui.Parent = CoreGui
    end
end

-- Создаёт Instance, выставляет свойства и только потом родителя (быстрее).
local function create(class, props, parent)
    local obj = Instance.new(class)
    if props then
        for k, v in pairs(props) do
            obj[k] = v
        end
    end
    if parent then obj.Parent = parent end
    return obj
end

local function corner(obj, radius)
    return create("UICorner", { CornerRadius = UDim.new(0, radius) }, obj)
end

local function stroke(obj, color, thickness, transparency)
    return create("UIStroke", {
        Color = color,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, obj)
end

local function padding(obj, l, t, r, b)
    return create("UIPadding", {
        PaddingLeft = UDim.new(0, l), PaddingTop = UDim.new(0, t),
        PaddingRight = UDim.new(0, r), PaddingBottom = UDim.new(0, b),
    }, obj)
end

local function text(parent, str, size, color, font, xalign)
    return create("TextLabel", {
        BackgroundTransparency = 1,
        Text = str or "",
        TextSize = size or 13,
        TextColor3 = color or C.Text,
        Font = font or Enum.Font.GothamMedium,
        TextXAlignment = xalign or Enum.TextXAlignment.Left,
    }, parent)
end

local function isPress(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch
end

local function isMove(input)
    return input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
end

-- Вторая точка градиента. Для светлого акцента (например, белого) она темнее,
-- для очень тёмного светлее, иначе градиент пропадал бы на фоне.
local function accent2Of(c)
    local h, s, v = Color3.toHSV(c)
    if luminance(c) > 0.7 then
        return Color3.fromHSV(h, s, math.clamp(v * 0.72, 0, 1))
    elseif v < 0.3 then
        return Color3.fromHSV((h + 0.04) % 1, math.clamp(s * 0.9, 0, 1), math.clamp(v + 0.18, 0, 1))
    end
    return Color3.fromHSV((h + 0.06) % 1, math.clamp(s * 0.9, 0, 1), math.clamp(v * 1.12 + 0.03, 0, 1))
end

local function accentSeq(c)
    return ColorSequence.new(c, accent2Of(c))
end

local function toHex(color)
    return string.format("#%02X%02X%02X", math.floor(color.R * 255 + 0.5), math.floor(color.G * 255 + 0.5), math.floor(color.B * 255 + 0.5))
end

local function parseHex(str)
    if type(str) ~= "string" then return nil end
    str = str:gsub("^%s*#?", ""):gsub("%s+$", "")
    if #str == 3 then
        str = str:sub(1, 1):rep(2) .. str:sub(2, 2):rep(2) .. str:sub(3, 3):rep(2)
    end
    if not str:match("^%x%x%x%x%x%x$") then return nil end
    return Color3.fromRGB(
        tonumber(str:sub(1, 2), 16),
        tonumber(str:sub(3, 4), 16),
        tonumber(str:sub(5, 6), 16)
    )
end

-- Ripple-эффект: круг расходится от точки нажатия внутри `host`.
local function ripple(host, input)
    local ok = pcall(function()
        local rel = Vector2.new(input.Position.X - host.AbsolutePosition.X, input.Position.Y - host.AbsolutePosition.Y)
        local maxSide = math.max(host.AbsoluteSize.X, host.AbsoluteSize.Y) * 2.2
        local dot = create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0, rel.X, 0, rel.Y),
            Size = UDim2.new(0, 0, 0, 0),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 0.86,
            BorderSizePixel = 0,
            ZIndex = 5,
        }, host)
        corner(dot, 999)
        tween(dot, { Size = UDim2.new(0, maxSide, 0, maxSide), BackgroundTransparency = 1 }, 0.55)
        task.delay(0.6, function() dot:Destroy() end)
    end)
    return ok
end

-- ==========================================
-- ТЕКСТ: регистр, подсветка, описания
-- ==========================================

-- string.lower не понимает кириллицу, поэтому переводим регистр сами.
-- Длина в байтах не меняется, так что позиции совпадают с исходной строкой.
local function lowerU(str)
    str = tostring(str or "")
    local ok, result = pcall(function()
        local out = {}
        for _, cp in utf8.codes(str) do
            if cp >= 0x410 and cp <= 0x42F then
                cp = cp + 32
            elseif cp >= 0x400 and cp <= 0x40F then
                cp = cp + 80
            elseif cp >= 65 and cp <= 90 then
                cp = cp + 32
            elseif cp >= 0xC0 and cp <= 0xDE and cp ~= 0xD7 then
                cp = cp + 32
            end
            out[#out + 1] = utf8.char(cp)
        end
        return table.concat(out)
    end)
    if ok then return result end
    return string.lower(str)
end

local function escapeRich(str)
    str = tostring(str or "")
    str = str:gsub("&", "&amp;")
    str = str:gsub("<", "&lt;")
    str = str:gsub(">", "&gt;")
    return str
end

-- Возвращает строку с RichText-подсветкой найденного фрагмента и флаг "нашли".
local function highlight(plain, queryLower, hex)
    plain = tostring(plain or "")
    local a, b = lowerU(plain):find(queryLower, 1, true)
    if not a then return escapeRich(plain), false end
    return escapeRich(plain:sub(1, a - 1))
        .. '<font color="' .. hex .. '"><b>' .. escapeRich(plain:sub(a, b)) .. "</b></font>"
        .. escapeRich(plain:sub(b + 1)), true
end

-- Элемент можно описать строкой или таблицей:
--   tab:Button({ Text = "Fly", Icon = "https://...", Desc = { en = "...", ru = "..." } }, cb)
local function parseSpec(label)
    if type(label) == "table" then
        return {
            text = tostring(label.Text or label.Name or label.Title or ""),
            icon = label.Icon,
            desc = label.Desc or label.Description,
        }
    end
    return { text = tostring(label == nil and "" or label) }
end

local function descFor(desc, lang)
    if type(desc) == "string" then return desc end
    if type(desc) ~= "table" then return nil end
    if desc[lang] then return desc[lang] end
    if desc.en then return desc.en end
    for _, value in pairs(desc) do
        if type(value) == "string" then return value end
    end
    return nil
end

local function descList(desc)
    local list = {}
    if type(desc) == "string" then
        list[1] = lowerU(desc)
    elseif type(desc) == "table" then
        for _, value in pairs(desc) do
            if type(value) == "string" then list[#list + 1] = lowerU(value) end
        end
    end
    return list
end

-- ==========================================
-- ИКОНКИ
-- Принимаются: число или "rbxassetid://..." (ассет Roblox), ссылка http(s)
-- (скачивается один раз в OriginNew/icons) или путь к файлу в папке workspace
-- executor-а. Для ссылок и файлов нужен getcustomasset. Форматы: png, jpg.
-- ==========================================
local ICON_DIR = "OriginNew/icons"
local iconCache = {}

local function hashStr(str)
    local h = 5381
    for i = 1, #str do
        h = (h * 33 + str:byte(i)) % 4294967296
    end
    return string.format("%08x", h)
end

local function resolveIcon(spec, apply)
    if spec == nil or spec == "" then return end
    if type(spec) == "number" then
        apply("rbxassetid://" .. tostring(spec))
        return
    end
    if type(spec) ~= "string" then return end
    if spec:match("^rbx%a*://") then
        apply(spec)
        return
    end
    if spec:match("^%d+$") then
        apply("rbxassetid://" .. spec)
        return
    end
    if iconCache[spec] then
        apply(iconCache[spec])
        return
    end
    task.spawn(function()
        local asset
        pcall(function()
            if not getcustomasset then return end
            local path = spec
            if spec:match("^https?://") then
                local clean = spec:gsub("[%?#].*$", "")
                local ext = (clean:match("%.(%w+)$") or "png"):lower()
                if ext ~= "png" and ext ~= "jpg" and ext ~= "jpeg" then ext = "png" end
                path = ICON_DIR .. "/" .. hashStr(spec) .. "." .. ext
                if not (isfile and isfile(path)) then
                    local data
                    local ok, res = pcall(function() return game:HttpGet(spec) end)
                    if ok and type(res) == "string" and #res > 0 then
                        data = res
                    elseif request then
                        local r = request({ Url = spec, Method = "GET" })
                        data = r and r.Body
                    end
                    if not data or #data == 0 then return end
                    if makefolder then
                        pcall(makefolder, "OriginNew")
                        pcall(makefolder, ICON_DIR)
                    end
                    writefile(path, data)
                end
            elseif not (isfile and isfile(spec)) then
                return
            end
            asset = getcustomasset(path)
        end)
        if asset then
            iconCache[spec] = asset
            apply(asset)
        end
    end)
end

local function iconImage(parent, spec, size, color)
    local img = create("ImageLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, size, 0, size),
        Image = "",
        ImageColor3 = color or Color3.fromRGB(255, 255, 255),
    }, parent)
    resolveIcon(spec, function(asset)
        if img.Parent then img.Image = asset end
    end)
    return img
end

-- ==========================================
-- КОНФИГ (OriginNewGuiSettings.cfg)
-- Строки вида "ключ:значение". Читается и пишется целиком, неизвестные ключи
-- сохраняются. Ключ lib читает загрузчик, чтобы выбрать библиотеку.
-- ==========================================
local CFG_FILE = "OriginNewGuiSettings.cfg"
local CFG_ORDER = {
    "autoloadme", "accent", "ToggleKey", "uiscale", "opacity", "resize", "glow",
    "lib", "unlockcur", "fullscreenblur", "fullblurlevel", "language",
    "glass", "glassdark", "glassoffset", "config",
}

local function cfgRead(path)
    path = path or CFG_FILE
    local data = {}
    local raw
    pcall(function()
        if readfile and isfile and isfile(path) then raw = readfile(path) end
    end)
    if type(raw) == "string" then
        for line in (raw .. "\n"):gmatch("(.-)\r?\n") do
            local key, value = line:match("^%s*([%w_]+)%s*:%s*(.-)%s*$")
            if key then
                -- "#23 (control)": комментарий в скобках отбрасываем
                value = value:gsub("%s+%(.*%)%s*$", "")
                data[key:lower()] = value
            end
        end
    end
    return data
end

local function cfgWrite(data, path)
    path = path or CFG_FILE
    local lines, seen = {}, {}
    for _, key in ipairs(CFG_ORDER) do
        local value = data[key:lower()]
        if value ~= nil then
            lines[#lines + 1] = key .. ":" .. tostring(value)
            seen[key:lower()] = true
        end
    end
    for key, value in pairs(data) do
        if not seen[key] then lines[#lines + 1] = key .. ":" .. tostring(value) end
    end
    local ok = pcall(function() writefile(path, table.concat(lines, "\n") .. "\n") end)
    return ok
end

local function toBool(raw, default)
    if raw == nil then return default end
    raw = tostring(raw):lower()
    if raw == "true" or raw == "yes" or raw == "1" or raw == "on" then return true end
    if raw == "false" or raw == "no" or raw == "0" or raw == "off" then return false end
    return default
end

local function parseKey(raw)
    if raw == nil then return nil end
    raw = tostring(raw)
    local name = raw:match("^%s*#?(%a%w*)")
    if name then
        local ok, item = pcall(function() return Enum.KeyCode[name] end)
        if ok and item and typeof(item) == "EnumItem" then return item end
    end
    local num = tonumber(raw:match("#?(%d+)"))
    if num then
        local ok, found = pcall(function()
            for _, item in ipairs(Enum.KeyCode:GetEnumItems()) do
                if item.Value == num then return item end
            end
        end)
        if ok then return found end
    end
    return nil
end

-- ==========================================
-- ИМЕНОВАННЫЕ КОНФИГИ И ПРЕСЕТ СКРИПТА
-- Конфиги лежат в OriginNew/configs/<имя>.cfg в том же формате "ключ:значение".
-- Пресет задаёт автор скрипта (Window({ Preset = {...} }) или lib:SetPreset).
-- Пресет не пишется на диск: он живёт в коде скрипта и выбирается в списке
-- Config под именем "preset by script". Ключи lib, autoloadme и config в
-- конфиги и пресеты не входят.
-- ==========================================
local CFG_DIR = "OriginNew/configs"
local CFG_INDEX = CFG_DIR .. "/index.txt"
local PRESET_NAME = "preset by script"
local CFG_SKIP = { lib = true, autoloadme = true, config = true }

local function cleanConfigName(name)
    name = tostring(name or "")
    name = name:gsub("[^%w _%-%.\128-\255]", "")
    name = name:gsub("^%s+", "")
    name = name:gsub("%s+$", "")
    name = name:sub(1, 32)
    local low = lowerU(name)
    if name == "" or low == PRESET_NAME or low == "index" or low == "(none)" then return nil end
    return name
end

local function configPath(name)
    return CFG_DIR .. "/" .. name .. ".cfg"
end

local function ensureConfigDir()
    if not makefolder then return end
    pcall(makefolder, "OriginNew")
    pcall(makefolder, CFG_DIR)
end

local function indexRead()
    local names = {}
    pcall(function()
        if readfile and isfile and isfile(CFG_INDEX) then
            for line in (readfile(CFG_INDEX) .. "\n"):gmatch("(.-)\r?\n") do
                local n = cleanConfigName(line)
                if n then names[#names + 1] = n end
            end
        end
    end)
    return names
end

local function indexWrite(names)
    pcall(function()
        ensureConfigDir()
        writefile(CFG_INDEX, table.concat(names, "\n") .. "\n")
    end)
end

local function presetValue(value)
    if typeof(value) == "Color3" then return toHex(value) end
    if typeof(value) == "EnumItem" then return value.Name end
    return tostring(value)
end

-- Пресет автора скрипта. Значения: строки, числа, булевы, Color3, KeyCode.
--   lib:SetPreset({ accent = Color3.fromRGB(255, 80, 80), uiscale = 95, language = "ru" })
function originNew:SetPreset(preset)
    self._preset = {}
    if type(preset) ~= "table" then return end
    for key, value in pairs(preset) do
        local lk = tostring(key):lower()
        if not CFG_SKIP[lk] then self._preset[lk] = presetValue(value) end
    end
end

function originNew:GetPreset() return self._preset end
function originNew:HasPreset() return next(self._preset) ~= nil end

-- Имена сохранённых конфигов по алфавиту. Берутся из listfiles, а если его нет
-- (или папка пуста), из файла index.txt. Остаются только существующие файлы.
function originNew:ListConfigs()
    local seen, names = {}, {}
    local function add(name)
        name = cleanConfigName(name)
        if name and not seen[name] then
            seen[name] = true
            names[#names + 1] = name
        end
    end
    pcall(function()
        if listfiles and isfolder and isfolder(CFG_DIR) then
            for _, path in ipairs(listfiles(CFG_DIR)) do
                local n = tostring(path):match("([^/\\]+)%.cfg$")
                if n then add(n) end
            end
        end
    end)
    for _, n in ipairs(indexRead()) do
        local exists = false
        pcall(function() exists = isfile and isfile(configPath(n)) end)
        if exists then add(n) end
    end
    table.sort(names, function(a, b) return lowerU(a) < lowerU(b) end)
    return names
end

-- Сохраняет значения (по умолчанию текущие настройки) под именем. Возвращает
-- имя при успехе, либо false и причину.
function originNew:SaveNamedConfig(name, data)
    local clean = cleanConfigName(name)
    if not clean then return false, "invalid name" end
    if not writefile then return false, "no writefile" end
    self:_initConfig()
    local out = {}
    for key, value in pairs(data or self._cfg) do
        if not CFG_SKIP[key] then out[key] = value end
    end
    ensureConfigDir()
    if not cfgWrite(out, configPath(clean)) then return false, "write failed" end
    local names = indexRead()
    local present = false
    for _, n in ipairs(names) do
        if n == clean then present = true end
    end
    if not present then
        names[#names + 1] = clean
        indexWrite(names)
    end
    return clean
end

-- Возвращает таблицу значений конфига или nil, если файла нет.
function originNew:LoadNamedConfig(name)
    local clean = cleanConfigName(name)
    if not clean then return nil end
    local exists = false
    pcall(function() exists = isfile and isfile(configPath(clean)) end)
    if not exists then return nil end
    return cfgRead(configPath(clean))
end

function originNew:DeleteNamedConfig(name)
    local clean = cleanConfigName(name)
    if not clean then return false, "invalid name" end
    if not delfile then return false, "no delfile" end
    local ok = pcall(function() delfile(configPath(clean)) end)
    if not ok then return false, "delete failed" end
    local names, kept = indexRead(), {}
    for _, n in ipairs(names) do
        if n ~= clean then kept[#kept + 1] = n end
    end
    indexWrite(kept)
    return true
end

function originNew:_initConfig()
    if self._cfg then return end
    self._cfg = cfgRead()
    self._autoSave = toBool(self._cfg.autoloadme, true)
end

function originNew:LoadConfig()
    self._cfg = cfgRead()
    self._autoSave = toBool(self._cfg.autoloadme, true)
    return self._cfg
end

-- Значение из конфига (ключ без учёта регистра) или nil.
function originNew:GetConfig(key)
    self:_initConfig()
    return self._cfg[tostring(key):lower()]
end

-- Меняет значение в памяти. На диск пишет сразу, если включён автосейв
-- (или force), с задержкой 0.6 с, чтобы перетаскивание слайдера не било по диску.
function originNew:SetConfig(key, value, force)
    self:_initConfig()
    self._cfg[tostring(key):lower()] = tostring(value)
    if not (self._autoSave or force) then return end
    self._saveToken = self._saveToken + 1
    local token = self._saveToken
    task.delay(0.6, function()
        if token == self._saveToken then cfgWrite(self._cfg) end
    end)
end

function originNew:SaveConfig()
    self:_initConfig()
    self._saveToken = self._saveToken + 1
    return cfgWrite(self._cfg)
end

-- ==========================================
-- ВЫБОР UI LIB (общий формат с originLIB)
-- ==========================================
local function normalizeChoice(value)
    if type(value) ~= "string" then return nil end
    value = (value:gsub("^%s*(.-)%s*$", "%1")):lower()
    for _, name in ipairs(UI_LIB_NAMES) do
        if name == value then return name end
    end
    return nil
end

-- Возвращает сохранённый выбор ("origin lib" / "origin new") или nil.
function originNew:GetUILib()
    local choice = normalizeChoice(cfgRead().lib)
    if not choice then
        pcall(function()
            if readfile and isfile and isfile(UI_LIB_FILE) then
                choice = normalizeChoice(readfile(UI_LIB_FILE))
            end
        end)
    end
    if not choice then
        pcall(function() choice = normalizeChoice(getgenv().originLIB_UILib) end)
    end
    return choice
end

-- Сохраняет выбор. Возвращает true, если записать удалось хоть куда-то.
function originNew:SetUILib(name)
    name = normalizeChoice(name)
    if not name then return false end
    local saved = false
    -- Строка lib в конфиге (её читает загрузчик). Пишем сразу, без задержки,
    -- и не трогаем остальные настройки на диске.
    pcall(function()
        local data = cfgRead()
        data.lib = name
        if writefile and cfgWrite(data) then saved = true end
        if self._cfg then self._cfg.lib = name end
    end)
    pcall(function()
        if writefile then writefile(UI_LIB_FILE, name) end
    end)
    pcall(function()
        getgenv().originLIB_UILib = name
        saved = true
    end)
    return saved
end

-- ==========================================
-- КУРСОР
-- Пока открыто окно, курсор должен быть свободен. Если он уже свободен,
-- не трогаем вообще. Действуем, только когда он реально закрыт (LockCenter
-- или скрыт), и возвращаем исходное состояние, только если меняли мы.
-- ==========================================
local function cursorIsClosed()
    return UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter
        or not UserInputService.MouseIconEnabled
end

function originNew:_unlockCursorIfClosed()
    if not cursorIsClosed() then return end
    if not self._cursorChanged then
        self._savedMouseBehavior = UserInputService.MouseBehavior
        self._savedMouseIconEnabled = UserInputService.MouseIconEnabled
        self._cursorChanged = true
    end
    UserInputService.MouseIconEnabled = true
    if UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    end
end

function originNew:_restoreCursor()
    if not self._cursorChanged then return end
    self._cursorChanged = false
    if self._savedMouseBehavior ~= nil then
        UserInputService.MouseBehavior = self._savedMouseBehavior
    end
    if self._savedMouseIconEnabled ~= nil then
        UserInputService.MouseIconEnabled = self._savedMouseIconEnabled
    end
    self._savedMouseBehavior = nil
    self._savedMouseIconEnabled = nil
end

function originNew:_applyCursorState()
    local manage = self._cursorUnlockEnabled and self._openWindowCount > 0
    if manage then
        self:_unlockCursorIfClosed()
        if not self._cursorConn then
            self._cursorConn = RunService.RenderStepped:Connect(function()
                self:_unlockCursorIfClosed()
            end)
        end
    else
        if self._cursorConn then
            self._cursorConn:Disconnect()
            self._cursorConn = nil
        end
        self:_restoreCursor()
    end
end

function originNew:SetCursorUnlock(state)
    self._cursorUnlockEnabled = state and true or false
    self:_applyCursorState()
end

-- ==========================================
-- РАЗМЫТИЕ ЭКРАНА (Lighting.BlurEffect)
-- ==========================================
function originNew:_applyBlurState()
    local shouldBlur = self._blurEnabled and self._openWindowCount > 0

    if shouldBlur and not self.BlurEffect then
        local blur = Instance.new("BlurEffect")
        blur.Name = "originNEW_Blur"
        blur.Size = 0
        blur.Parent = Lighting
        self.BlurEffect = blur
    end
    if not self.BlurEffect then return end

    if shouldBlur then
        self.BlurEffect.Enabled = true
        tween(self.BlurEffect, { Size = self._blurSize }, 0.3)
    else
        local anim = tween(self.BlurEffect, { Size = 0 }, 0.3)
        anim.Completed:Connect(function()
            if self.BlurEffect then self.BlurEffect.Enabled = false end
        end)
    end
end

function originNew:SetBlurEnabled(state)
    self._blurEnabled = state and true or false
    self:_applyBlurState()
end

function originNew:SetBlurSize(size)
    self._blurSize = math.clamp(size, 0, 56)
    if self._blurEnabled and self.BlurEffect then
        tween(self.BlurEffect, { Size = self._blurSize }, 0.15)
    end
end

-- Вызывается окнами при открытии (+1) / закрытии (-1).
function originNew:_adjustMouseCapture(delta)
    self._openWindowCount = math.max(0, self._openWindowCount + delta)
    self:_applyCursorState()
    self:_applyBlurState()
end

-- ==========================================
-- УВЕДОМЛЕНИЯ
-- Notify({ Title, Content, Duration, Color, Type = "info"|"success"|"warning"|"error" })
-- ==========================================
function originNew:InitNotifications()
    if self.NotificationHolder then return end

    local gui = create("ScreenGui", {
        Name = "originNEW_Notifications",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = 200,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    protectUI(gui)

    local holder = create("Frame", {
        Name = "Holder",
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 320, 1, -24),
        Position = UDim2.new(1, -336, 0, 12),
    }, gui)
    create("UIListLayout", {
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
    }, holder)

    self.NotifGui = gui
    self.NotificationHolder = holder
end

local function measureText(str, size, font, width)
    local ok, result = pcall(function()
        return TextService:GetTextSize(str, size, font, Vector2.new(width, 10000)).Y
    end)
    if ok and type(result) == "number" then return result end
    return math.ceil(#str / 42) * (size + 3)
end

function originNew:Notify(config)
    config = config or {}
    local title = tostring(config.Title or "Notification")
    local content = tostring(config.Content or "")
    local duration = config.Duration or 4
    local kind = tostring(config.Type or "info"):lower()
    local color = config.Color or NOTIF_COLORS[kind] or DEFAULT_ACCENT

    self:InitNotifications()
    self._notifCounter = self._notifCounter + 1

    local contentHeight = content ~= "" and measureText(content, 12, Enum.Font.Gotham, 262) or 0
    local height = 20 + 18 + (content ~= "" and (contentHeight + 4) or 0) + 14

    local wrapper = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, height),
        LayoutOrder = self._notifCounter,
    }, self.NotificationHolder)

    local card = create("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 340, 0, 0),
        BackgroundColor3 = C.Card,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, wrapper)
    corner(card, 12)
    stroke(card, C.Stroke, 1, 0)

    local bar = create("Frame", {
        Size = UDim2.new(0, 3, 1, -20), Position = UDim2.new(0, 8, 0, 10),
        BackgroundColor3 = color, BorderSizePixel = 0,
    }, card)
    corner(bar, 2)

    local titleLabel = text(card, title, 13, C.Text, Enum.Font.GothamBold)
    titleLabel.Position = UDim2.new(0, 22, 0, 10)
    titleLabel.Size = UDim2.new(1, -34, 0, 18)

    if content ~= "" then
        local body = text(card, content, 12, C.SubText, Enum.Font.Gotham)
        body.Position = UDim2.new(0, 22, 0, 30)
        body.Size = UDim2.new(1, -34, 0, contentHeight)
        body.TextWrapped = true
        body.TextYAlignment = Enum.TextYAlignment.Top
    end

    local progress = create("Frame", {
        Size = UDim2.new(1, 0, 0, 2), Position = UDim2.new(0, 0, 1, -2),
        BackgroundColor3 = color, BackgroundTransparency = 0.25, BorderSizePixel = 0,
    }, card)

    tween(card, { Position = UDim2.new(0, 0, 0, 0) }, 0.45, Enum.EasingStyle.Back)
    tween(progress, { Size = UDim2.new(0, 0, 0, 2) }, duration, Enum.EasingStyle.Linear)

    task.delay(duration, function()
        if not card.Parent then return end
        local out = tween(card, { Position = UDim2.new(0, 340, 0, 0) }, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        out.Completed:Connect(function() wrapper:Destroy() end)
    end)
end

-- ==========================================
-- ВСТУПИТЕЛЬНАЯ ЗАСТАВКА
-- ==========================================
function originNew:ShowIntro(label, duration)
    duration = duration or 2.5

    local gui = create("ScreenGui", {
        Name = "originNEW_Intro", ResetOnSpawn = false, IgnoreGuiInset = true,
        DisplayOrder = 300, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    protectUI(gui)

    local card = create("CanvasGroup", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 320, 0, 92),
        BackgroundColor3 = C.Bg,
        BorderSizePixel = 0,
        GroupTransparency = 1,
    }, gui)
    corner(card, 16)
    local st = stroke(card, Color3.fromRGB(255, 255, 255), 1.5, 0)
    local grad = create("UIGradient", { Color = accentSeq(DEFAULT_ACCENT) }, st)
    local scale = create("UIScale", { Scale = 0.9 }, card)

    local title = text(card, label or "originNEW", 18, C.Text, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
    title.Position = UDim2.new(0, 0, 0, 20)
    title.Size = UDim2.new(1, 0, 0, 26)

    local sub = text(card, "powered by originNEW", 11, C.SubText, Enum.Font.GothamMedium, Enum.TextXAlignment.Center)
    sub.Position = UDim2.new(0, 0, 0, 48)
    sub.Size = UDim2.new(1, 0, 0, 14)

    local track = create("Frame", {
        Position = UDim2.new(0, 28, 1, -22), Size = UDim2.new(1, -56, 0, 4),
        BackgroundColor3 = C.Off, BorderSizePixel = 0,
    }, card)
    corner(track, 2)
    local fill = create("Frame", {
        Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0,
    }, track)
    corner(fill, 2)
    create("UIGradient", { Color = accentSeq(DEFAULT_ACCENT) }, fill)

    local spin = RunService.RenderStepped:Connect(function()
        grad.Rotation = (os.clock() * 90) % 360
    end)

    tween(card, { GroupTransparency = 0 }, 0.3)
    tween(scale, { Scale = 1 }, 0.45, Enum.EasingStyle.Back)
    tween(fill, { Size = UDim2.new(1, 0, 1, 0) }, duration, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

    task.wait(duration)

    tween(scale, { Scale = 0.94 }, 0.25)
    local fade = tween(card, { GroupTransparency = 1 }, 0.25)
    fade.Completed:Connect(function()
        spin:Disconnect()
        gui:Destroy()
    end)
end

-- ==========================================
-- ГЛОБАЛЬНЫЙ UNLOAD
-- ==========================================
function originNew:OnUnload(taskFunc)
    if type(taskFunc) == "function" then
        table.insert(self.GlobalUnloadTasks, taskFunc)
    end
end

function originNew:Unload()
    local snapshot = table.clone(self.Windows)
    for _, window in ipairs(snapshot) do
        window:Unload()
    end

    for _, taskFunc in ipairs(self.GlobalUnloadTasks) do
        safeCall(taskFunc)
    end
    self.GlobalUnloadTasks = {}

    if self.NotifGui then
        self.NotifGui:Destroy()
        self.NotifGui = nil
        self.NotificationHolder = nil
    end

    self._openWindowCount = 0
    self:_applyCursorState()

    if self.BlurEffect then
        self.BlurEffect:Destroy()
        self.BlurEffect = nil
    end
    self._blurEnabled = false

    if self._glassDOF then
        self._glassDOF:Destroy()
        self._glassDOF = nil
    end
    self._glassUsers = 0
end

function originNew:UnloadAll()
    self:Unload()
end

-- ==========================================
-- ОКНО
-- ==========================================
function originNew:Window(config)
    local options = type(config) == "table" and config or { Title = tostring(config or "originNEW") }
    local window = setmetatable({}, Window)

    window.Toggles = {}
    window.UnloadTasks = {}
    window.Connections = {}
    window.Tabs = {}
    window.Dropdowns = {}
    window.KeybindMap = {}
    window.ListeningKeybind = nil
    window.DragState = nil
    window.ActiveTab = nil
    window.SearchQuery = ""
    window._themeFns = {}
    window._open = false
    window._scale = 1
    window._opacity = 0.06
    window._allowResize = true
    window._minimized = false
    window._animToken = 0
    window._unloaded = false
    window.Language = "en"
    window.Contacts = {}
    window.MoreItems = {}
    window.GlassEnabled = false
    window.GlassDark = true
    window.GlassOffsetY = 0
    window._glassActive = false
    window._id = #originNew.Windows + 1
    window.Theme = {
        Accent = DEFAULT_ACCENT,
        Accent2 = accent2Of(DEFAULT_ACCENT),
        AccentText = readableAccent(DEFAULT_ACCENT),
    }

    table.insert(originNew.Windows, window)

    local viewport = Vector2.new(1280, 720)
    pcall(function()
        local cam = Workspace.CurrentCamera
        if cam and cam.ViewportSize.X > 0 then viewport = cam.ViewportSize end
    end)
    local width = math.clamp(viewport.X - 40, 360, 660)
    local height = math.clamp(viewport.Y - 60, 280, 430)
    window._size = Vector2.new(width, height)

    local gui = create("ScreenGui", {
        Name = "originNEW_UI",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = 100,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    pcall(function() gui.ScreenInsets = Enum.ScreenInsets.None end)
    protectUI(gui)

    -- Holder: невидимый контейнер, который двигаем/масштабируем/ресайзим.
    local holder = create("Frame", {
        Name = "Holder",
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0.5, -height / 2),
        Size = UDim2.new(0, width, 0, height),
        BackgroundTransparency = 1,
        Visible = false,
    }, gui)
    local uiScale = create("UIScale", { Scale = 1 }, holder)

    -- Свечение за окном (два слоя), цвет задаёт градиент акцента.
    local glows = {}
    for i, def in ipairs({ { 22, 0.90 }, { 46, 0.95 } }) do
        local glow = create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(1, def[1], 1, def[1]),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 0,
        }, holder)
        corner(glow, 14 + def[1] / 2)
        local g = create("UIGradient", { Color = accentSeq(DEFAULT_ACCENT), Rotation = 45 }, glow)
        glows[i] = { frame = glow, gradient = g, base = def[2] }
    end

    local main = create("CanvasGroup", {
        Name = "Main",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = C.Bg,
        BackgroundTransparency = window._opacity,
        BorderSizePixel = 0,
        GroupTransparency = 1,
        ZIndex = 1,
    }, holder)
    corner(main, 14)
    local borderStroke = stroke(main, Color3.fromRGB(255, 255, 255), 1.5, 0.15)
    local borderGradient = create("UIGradient", { Color = accentSeq(DEFAULT_ACCENT) }, borderStroke)

    -- ===== Боковая панель =====
    local sidebar = create("Frame", {
        Name = "Sidebar", Size = UDim2.new(0, 176, 1, 0),
        BackgroundColor3 = C.Panel, BorderSizePixel = 0,
    }, main)
    window.Sidebar = sidebar
    create("Frame", {
        Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(1, -1, 0, 0),
        BackgroundColor3 = C.Stroke, BorderSizePixel = 0,
    }, sidebar)

    -- Бренд
    local brand = create("Frame", {
        Size = UDim2.new(1, 0, 0, 62), BackgroundTransparency = 1,
    }, sidebar)
    local logo = create("Frame", {
        Size = UDim2.new(0, 32, 0, 32), Position = UDim2.new(0, 16, 0, 15),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0,
    }, brand)
    corner(logo, 10)
    local logoGradient = create("UIGradient", { Color = accentSeq(DEFAULT_ACCENT), Rotation = 45 }, logo)
    local logoText = text(logo, "O", 16, Color3.fromRGB(255, 255, 255), Enum.Font.GothamBlack, Enum.TextXAlignment.Center)
    logoText.Size = UDim2.new(1, 0, 1, 0)
    local logoImage = create("ImageLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 22, 0, 22), BackgroundTransparency = 1, Image = "", Visible = false,
    }, logo)
    window._logoText = logoText
    window._logoImage = logoImage

    local titleLabel = text(brand, tostring(options.Title or "originNEW"), 14, C.Text, Enum.Font.GothamBold)
    titleLabel.Position = UDim2.new(0, 56, 0, 14)
    titleLabel.Size = UDim2.new(1, -64, 0, 18)
    titleLabel.TextTruncate = Enum.TextTruncate.AtEnd

    local subtitleLabel = text(brand, tostring(options.Subtitle or ("originNEW v" .. originNew.Version)), 10, C.Dim, Enum.Font.GothamMedium)
    subtitleLabel.Position = UDim2.new(0, 56, 0, 32)
    subtitleLabel.Size = UDim2.new(1, -64, 0, 14)

    -- Список вкладок
    local tabList = create("ScrollingFrame", {
        Name = "Tabs",
        Position = UDim2.new(0, 0, 0, 66), Size = UDim2.new(1, 0, 1, -66 - 62),
        BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 0,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(0, 0, 0, 0),
    }, sidebar)
    create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, tabList)
    padding(tabList, 10, 2, 10, 2)

    -- Контакты (над разделителем футера)
    local contactsFrame = create("Frame", {
        Name = "Contacts", BackgroundTransparency = 1, Visible = false,
        Position = UDim2.new(0, 0, 1, -62), Size = UDim2.new(1, 0, 0, 0),
    }, sidebar)

    -- Футер: аватар + имя + кнопка more (три точки)
    local footer = create("Frame", {
        Size = UDim2.new(1, 0, 0, 62), Position = UDim2.new(0, 0, 1, -62), BackgroundTransparency = 1,
    }, sidebar)
    create("Frame", {
        Size = UDim2.new(1, -24, 0, 1), Position = UDim2.new(0, 12, 0, 0),
        BackgroundColor3 = C.Stroke, BorderSizePixel = 0,
    }, footer)
    local avatar = create("ImageLabel", {
        Size = UDim2.new(0, 34, 0, 34), Position = UDim2.new(0, 16, 0, 15),
        BackgroundColor3 = C.Card, BorderSizePixel = 0, Image = "",
    }, footer)
    corner(avatar, 999)
    stroke(avatar, C.StrokeHi, 1, 0)
    local lp = Players.LocalPlayer
    local nameLabel = text(footer, lp and lp.DisplayName or "player", 12, C.Text, Enum.Font.GothamBold)
    nameLabel.Position = UDim2.new(0, 60, 0, 16)
    nameLabel.Size = UDim2.new(1, -96, 0, 16)
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    local tagLabel = text(footer, lp and ("@" .. lp.Name) or "@player", 10, C.Dim, Enum.Font.Gotham)
    tagLabel.Position = UDim2.new(0, 60, 0, 32)
    tagLabel.Size = UDim2.new(1, -96, 0, 14)
    tagLabel.TextTruncate = Enum.TextTruncate.AtEnd
    task.spawn(function()
        pcall(function()
            if lp then
                local img = Players:GetUserThumbnailAsync(lp.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
                if avatar and avatar.Parent then avatar.Image = img end
            end
        end)
    end)

    local moreBtn = create("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 1),
        Size = UDim2.new(0, 26, 0, 30), BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Visible = false,
    }, footer)
    corner(moreBtn, 8)
    for i = 0, 2 do
        local dot = create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, (i - 1) * 6),
            Size = UDim2.new(0, 3, 0, 3), BackgroundColor3 = C.SubText, BorderSizePixel = 0,
        }, moreBtn)
        corner(dot, 2)
    end
    moreBtn.MouseEnter:Connect(function() tween(moreBtn, { BackgroundTransparency = 0.9 }, 0.15) end)
    moreBtn.MouseLeave:Connect(function() tween(moreBtn, { BackgroundTransparency = 1 }, 0.15) end)

    -- ===== Правая часть =====
    local content = create("Frame", {
        Name = "Content", Position = UDim2.new(0, 176, 0, 0), Size = UDim2.new(1, -176, 1, 0),
        BackgroundTransparency = 1,
    }, main)

    local topbar = create("Frame", {
        Name = "TopBar", Size = UDim2.new(1, 0, 0, 52), BackgroundTransparency = 1,
    }, content)

    local pageTitle = text(topbar, "", 16, C.Text, Enum.Font.GothamBold)
    pageTitle.Position = UDim2.new(0, 20, 0, 0)
    pageTitle.Size = UDim2.new(0.4, 0, 1, 0)

    -- Кнопки управления окном (иконки нарисованы фреймами, без Unicode-глифов)
    local function controlButton(offsetFromRight, hoverColor)
        local btn = create("TextButton", {
            Size = UDim2.new(0, 28, 0, 28), Position = UDim2.new(1, -offsetFromRight, 0.5, -14),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 1,
            Text = "", AutoButtonColor = false,
        }, topbar)
        corner(btn, 8)
        btn.MouseEnter:Connect(function()
            tween(btn, { BackgroundTransparency = 0.9, BackgroundColor3 = hoverColor or Color3.fromRGB(255, 255, 255) }, 0.15)
        end)
        btn.MouseLeave:Connect(function()
            tween(btn, { BackgroundTransparency = 1 }, 0.15)
        end)
        return btn
    end
    -- Крестик выгружает меню, минус сворачивает, глаз скрывает (откроется по бинду).
    local closeBtn = controlButton(40, C.Error)
    for _, rot in ipairs({ 45, -45 }) do
        create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(0, 14, 0, 2), Rotation = rot,
            BackgroundColor3 = C.SubText, BorderSizePixel = 0,
        }, closeBtn)
    end
    local minBtn = controlButton(74)
    create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 12, 0, 2), BackgroundColor3 = C.SubText, BorderSizePixel = 0,
    }, minBtn)

    local eyeBtn = controlButton(108)
    local eyeDraw = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
    }, eyeBtn)
    local eyeShape = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 18, 0, 10), BackgroundTransparency = 1, BorderSizePixel = 0,
    }, eyeDraw)
    corner(eyeShape, 5)
    stroke(eyeShape, C.SubText, 1.6, 0)
    local eyePupil = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 4, 0, 4), BackgroundColor3 = C.SubText, BorderSizePixel = 0,
    }, eyeDraw)
    corner(eyePupil, 2)
    local eyeImage = create("ImageLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 18, 0, 18), BackgroundTransparency = 1, Image = "", Visible = false,
    }, eyeBtn)
    window._eyeDraw = eyeDraw
    window._eyeImage = eyeImage

    -- Поиск
    local searchBox = create("Frame", {
        Size = UDim2.new(0, 160, 0, 30), Position = UDim2.new(1, -108 - 8 - 160 - 4, 0.5, -15),
        BackgroundColor3 = C.Field, BorderSizePixel = 0,
    }, topbar)
    corner(searchBox, 10)
    local searchStroke = stroke(searchBox, C.Stroke, 1, 0)
    local searchInput = create("TextBox", {
        Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -24, 1, 0),
        BackgroundTransparency = 1, Text = "", PlaceholderText = "Search...",
        PlaceholderColor3 = C.Dim, TextColor3 = C.Text,
        Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
    }, searchBox)
    searchInput.Focused:Connect(function() tween(searchStroke, { Color = window.Theme.Accent }, 0.15) end)
    searchInput.FocusLost:Connect(function() tween(searchStroke, { Color = C.Stroke }, 0.15) end)

    local pages = create("Frame", {
        Name = "Pages", Position = UDim2.new(0, 0, 0, 52), Size = UDim2.new(1, 0, 1, -52),
        BackgroundTransparency = 1, ClipsDescendants = true,
    }, content)

    -- Уголок ресайза (три точки)
    local grip = create("TextButton", {
        Size = UDim2.new(0, 22, 0, 22), Position = UDim2.new(1, -22, 1, -22),
        BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 10,
    }, main)
    for _, p in ipairs({ { 14, 14 }, { 8, 14 }, { 14, 8 } }) do
        local dot = create("Frame", {
            Position = UDim2.new(0, p[1], 0, p[2]), Size = UDim2.new(0, 3, 0, 3),
            BackgroundColor3 = C.Dim, BorderSizePixel = 0, ZIndex = 10,
        }, grip)
        corner(dot, 2)
    end

    -- ===== Сохраняем ссылки =====
    window.ScreenGui = gui
    window.Holder = holder
    window.MainFrame = main
    window.Scale = uiScale
    window.Glows = glows
    window.TabList = tabList
    window.Pages = pages
    window.PageTitle = pageTitle
    window.SearchInput = searchInput
    window.TitleLabel = titleLabel
    window.Grip = grip
    window.SearchBox = searchBox
    window.Brand = brand
    window.Footer = footer
    window.ContactsFrame = contactsFrame
    window.MoreButton = moreBtn
    window.Topbar = topbar
    window.CloseButton = closeBtn
    window.MinButton = minBtn
    window.EyeButton = eyeBtn
    window._borderGradient = borderGradient
    window._logoGradient = logoGradient
    window._shadowEnabled = true

    -- ===== Тема =====
    window:_themed(function(a)
        local seq = accentSeq(a)
        borderGradient.Color = seq
        logoGradient.Color = seq
        logoText.TextColor3 = contrastOn(a)
        for _, g in ipairs(glows) do g.gradient.Color = seq end
    end)

    -- ===== Централизованный ввод =====
    local function track(conn)
        table.insert(window.Connections, conn)
        return conn
    end

    track(UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            window._lastMouse = input.Position
            if window.Tip and window.Tip.Visible then window:_moveTip(input.Position) end
        end
        if window.DragState and isMove(input) then
            window.DragState.Update(input)
        end
    end))

    track(UserInputService.InputEnded:Connect(function(input)
        if isPress(input) then
            local state = window.DragState
            window.DragState = nil
            if state and state.Release then safeCall(state.Release) end
        end
    end))

    track(UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

        if window.ListeningKeybind then
            if input.KeyCode == Enum.KeyCode.Escape then
                window.ListeningKeybind.Cancel()
            else
                window.ListeningKeybind.Bind(input.KeyCode)
            end
            window.ListeningKeybind = nil
            return
        end

        if gameProcessed then return end

        local bucket = window.KeybindMap[input.KeyCode]
        if bucket then
            for _, callback in ipairs(bucket) do
                safeCall(callback, input.KeyCode)
            end
        end
    end))

    -- Перетаскивание окна за верхнюю панель и бренд
    local function startDrag(input)
        if not isPress(input) then return end
        local startMouse = input.Position
        local startPos = holder.Position
        window.DragState = {
            Update = function(inp)
                local delta = inp.Position - startMouse
                holder.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
            end,
        }
    end
    topbar.InputBegan:Connect(startDrag)
    brand.InputBegan:Connect(startDrag)

    -- Ресайз
    grip.InputBegan:Connect(function(input)
        if not isPress(input) or window._minimized or not window._allowResize then return end
        local startMouse = input.Position
        local startSize = window._size
        local startPos = holder.Position
        local scale = window._scale
        window.DragState = {
            Update = function(inp)
                local delta = inp.Position - startMouse
                local newW = math.max(480, startSize.X + delta.X / scale)
                local newH = math.max(320, startSize.Y + delta.Y / scale)
                window._size = Vector2.new(newW, newH)
                holder.Size = UDim2.new(0, newW, 0, newH)
                -- Holder привязан к верхнему центру: сдвигаем по X на половину
                -- прироста, чтобы правый нижний угол следовал за курсором.
                holder.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + (newW - startSize.X) * scale / 2,
                    startPos.Y.Scale, startPos.Y.Offset
                )
            end,
        }
    end)
    grip.Visible = window._allowResize

    -- Поиск
    searchInput:GetPropertyChangedSignal("Text"):Connect(function()
        window.SearchQuery = lowerU(searchInput.Text or "")
        for _, t in ipairs(window.Tabs) do
            t.Tab:_applySearch()
        end
    end)

    -- Кнопки
    closeBtn.MouseButton1Click:Connect(function()
        if #originNew.Windows <= 1 then
            originNew:Unload()
        else
            window:Unload()
        end
    end)
    minBtn.MouseButton1Click:Connect(function() window:SetMinimized(not window._minimized) end)
    eyeBtn.MouseButton1Click:Connect(function()
        window:SetOpen(false)
        local keyName = "RightControl"
        pcall(function()
            if window._menuKeybind then keyName = window._menuKeybind.GetKey().Name end
        end)
        originNew:Notify({
            Title = "Menu hidden",
            Content = "Press " .. keyName .. " to show it again.",
            Type = "info",
            Duration = 3,
        })
    end)

    -- Подсказка с описанием функции (показывается при наведении)
    local tip = create("Frame", {
        Name = "Tip", Visible = false, ZIndex = 60,
        Size = UDim2.new(0, 230, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = C.Card, BorderSizePixel = 0,
    }, holder)
    corner(tip, 8)
    stroke(tip, C.StrokeHi, 1, 0)
    padding(tip, 10, 7, 10, 8)
    local tipLabel = text(tip, "", 11, C.SubText, Enum.Font.Gotham)
    tipLabel.ZIndex = 61
    tipLabel.Size = UDim2.new(1, 0, 0, 0)
    tipLabel.AutomaticSize = Enum.AutomaticSize.Y
    tipLabel.TextWrapped = true
    tipLabel.TextYAlignment = Enum.TextYAlignment.Top
    window.Tip = tip
    window.TipLabel = tipLabel

    -- Меню more: блокер (клик мимо закрывает) + всплывающее окно с действиями
    local blocker = create("TextButton", {
        Name = "MoreBlocker", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
        Text = "", AutoButtonColor = false, Visible = false, ZIndex = 40,
    }, holder)
    local popup = create("CanvasGroup", {
        Name = "MorePopup", AnchorPoint = Vector2.new(0, 1), Visible = false, ZIndex = 41,
        Position = UDim2.new(0, 12, 1, -68), Size = UDim2.new(0, 164, 0, 40),
        BackgroundColor3 = C.Card, BorderSizePixel = 0, GroupTransparency = 1,
    }, holder)
    corner(popup, 10)
    stroke(popup, C.StrokeHi, 1, 0)
    padding(popup, 6, 6, 6, 6)
    create("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }, popup)
    window.MoreBlocker = blocker
    window.MorePopup = popup
    window._moreOpen = false
    blocker.MouseButton1Click:Connect(function() window:_setMoreOpen(false) end)
    moreBtn.MouseButton1Click:Connect(function() window:_setMoreOpen(not window._moreOpen) end)

    -- Иконки, контакты, настройки
    if options.Preset ~= nil then originNew:SetPreset(options.Preset) end
    if options.Icon then window:SetIcon(options.Icon) end
    if options.HideIcon then window:SetHideIcon(options.HideIcon) end
    window:_collectContacts(options)

    if not options.DisableSettings and not options.disablesettings then
        window:BuildSettingsTab()
    end

    window:SetOpen(true)
    return window
end

-- ==========================================
-- МЕТОДЫ ОКНА
-- ==========================================
function Window:_themed(fn)
    table.insert(self._themeFns, fn)
    fn(self.Theme.Accent, self.Theme.Accent2, self.Theme.AccentText)
end

function Window:SetAccent(color)
    self.Theme.Accent = color
    self.Theme.Accent2 = accent2Of(color)
    self.Theme.AccentText = readableAccent(color)
    for _, fn in ipairs(self._themeFns) do
        safeCall(fn, self.Theme.Accent, self.Theme.Accent2, self.Theme.AccentText)
    end
    if (self.SearchQuery or "") ~= "" then
        for _, t in ipairs(self.Tabs) do t.Tab:_applySearch() end
    end
end

-- Совместимость с originLIB: UpdateThemeColor("Accent" | "Background", color)
function Window:UpdateThemeColor(category, color)
    if category == "Accent" then
        self:SetAccent(color)
    elseif category == "Background" then
        tween(self.MainFrame, { BackgroundColor3 = color }, 0.2)
    end
end

function Window:SetTitle(str)
    self.TitleLabel.Text = tostring(str)
end

function Window:SetScale(scale)
    self._scale = math.clamp(scale, 0.6, 1.5)
    if self._open then
        tween(self.Scale, { Scale = self._scale }, 0.2)
    end
end

-- Прозрачность фона окна: 0 (непрозрачное) .. 1.
function Window:SetOpacity(transparency)
    self._opacity = math.clamp(transparency, 0, 0.9)
    self:_applyBackground()
end

-- Фон окна: при стекле он наполовину прозрачный, иначе берётся из слайдера.
function Window:_applyBackground()
    local main = self._opacity
    local panel = 0
    if self.GlassEnabled then
        main = math.max(self._opacity, 0.5)
        panel = 0.5
    end
    tween(self.MainFrame, { BackgroundTransparency = main }, 0.2)
    tween(self.Sidebar, { BackgroundTransparency = panel }, 0.2)
end

function Window:SetAllowResize(state)
    self._allowResize = state and true or false
    self.Grip.Visible = self._allowResize and not self._minimized
end

-- Свёрнутое окно показывает только название вкладки и игрока.
-- Название хаба, список вкладок, контакты, поиск и страницы скрываются.
function Window:SetMinimized(state)
    state = state and true or false
    if state == self._minimized then return end
    self._minimized = state
    self:_hideTip()
    self:_setMoreOpen(false)
    local h = state and 52 or self._size.Y
    tween(self.Holder, { Size = UDim2.new(0, self._size.X, 0, h) }, 0.3)
    self.Grip.Visible = self._allowResize and not state
    self.Brand.Visible = not state
    self.TabList.Visible = not state
    self.SearchBox.Visible = not state
    self.Pages.Visible = not state
    self.Footer.Position = state and UDim2.new(0, 0, 0, -5) or UDim2.new(0, 0, 1, -62)
    self:_layoutSidebar()
    self:_rebuildMore()
end

-- Иконка в заголовке (вместо буквы O): ассет, ссылка или файл в workspace.
function Window:SetIcon(spec)
    resolveIcon(spec, function(asset)
        if not self._logoImage or not self._logoImage.Parent then return end
        self._logoImage.Image = asset
        self._logoImage.Visible = true
        self._logoText.Visible = false
    end)
end

-- Своя иконка для кнопки "скрыть меню" (по умолчанию рисуется глаз).
function Window:SetHideIcon(spec, tint)
    resolveIcon(spec, function(asset)
        if not self._eyeImage or not self._eyeImage.Parent then return end
        self._eyeImage.Image = asset
        self._eyeImage.ImageColor3 = tint or Color3.fromRGB(255, 255, 255)
        self._eyeImage.Visible = true
        self._eyeDraw.Visible = false
    end)
end

function Window:SetLanguage(code)
    self.Language = tostring(code or "en"):lower()
    if self.Tip and self.Tip.Visible and self._tipDesc then
        self.TipLabel.Text = descFor(self._tipDesc, self.Language) or ""
    end
end

-- ===== Описания при наведении =====
function Window:_showTip(owner, desc)
    if self._minimized then return end
    local str = descFor(desc, self.Language)
    if not str or str == "" then return end
    self._tipOwner = owner
    self._tipDesc = desc
    self.TipLabel.Text = str
    self.Tip.Visible = true
    self:_moveTip(self._lastMouse)
end

function Window:_hideTip(owner)
    if owner ~= nil and self._tipOwner ~= owner then return end
    self._tipOwner = nil
    self._tipDesc = nil
    if self.Tip then self.Tip.Visible = false end
end

function Window:_moveTip(pos)
    if not pos or not self.Tip then return end
    local hp = self.Holder.AbsolutePosition
    local scale = math.max(self._scale, 0.1)
    local x = (pos.X - hp.X) / scale + 16
    local y = (pos.Y - hp.Y) / scale + 20
    x = math.clamp(x, 8, math.max(8, self._size.X - 238))
    y = math.clamp(y, 8, math.max(8, self._size.Y - 50))
    self.Tip.Position = UDim2.new(0, x, 0, y)
end

-- ===== Контакты над разделителем футера =====
local CONTACT_LABELS = { dsc = "Discord", discord = "Discord", tg = "Telegram", telegram = "Telegram", custom = "Link" }
local CONTACT_ORDER = { dsc = 1, discord = 1, tg = 2, telegram = 2, custom = 3 }

function Window:_layoutSidebar()
    local n = #self.Contacts
    local height = (n > 0) and 40 or 0
    self.ContactsFrame.Visible = n > 0 and not self._minimized
    self.ContactsFrame.Position = UDim2.new(0, 0, 1, -62 - height)
    self.ContactsFrame.Size = UDim2.new(1, 0, 0, height)
    self.TabList.Size = UDim2.new(1, 0, 1, -66 - 62 - height)
    local gap = 6
    local w = math.floor((176 - 24 - (n - 1) * gap) / math.max(n, 1))
    for i, contact in ipairs(self.Contacts) do
        contact.btn.Size = UDim2.new(0, w, 0, 28)
        contact.btn.Position = UDim2.new(0, 12 + (i - 1) * (w + gap), 0, 6)
    end
end

-- window:Contact("dsc" | "tg" | "custom" | любое имя, url, подпись, иконка)
function Window:Contact(kind, url, label, icon)
    if type(url) ~= "string" or url == "" then return end
    kind = (tostring(kind or "custom"):lower():gsub("^cont", ""))
    local host = url:match("^%a+://([^/]+)")
    if host then host = host:gsub("^www%.", "") end
    label = label or CONTACT_LABELS[kind] or host or kind

    local btn = create("TextButton", {
        BackgroundColor3 = C.Field, BorderSizePixel = 0, Text = "", AutoButtonColor = false,
        Size = UDim2.new(0, 60, 0, 28),
    }, self.ContactsFrame)
    corner(btn, 8)
    local st = stroke(btn, C.Stroke, 1, 0)
    local caption = text(btn, tostring(label), 11, C.SubText, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
    caption.Size = UDim2.new(1, 0, 1, 0)
    caption.TextTruncate = Enum.TextTruncate.AtEnd
    if icon then
        local img = iconImage(btn, icon, 14, C.SubText)
        img.AnchorPoint = Vector2.new(0, 0.5)
        img.Position = UDim2.new(0, 8, 0.5, 0)
        caption.Position = UDim2.new(0, 14, 0, 0)
        caption.Size = UDim2.new(1, -14, 1, 0)
    end
    btn.MouseEnter:Connect(function()
        tween(st, { Color = self.Theme.Accent }, 0.15)
        tween(caption, { TextColor3 = C.Text }, 0.15)
    end)
    btn.MouseLeave:Connect(function()
        tween(st, { Color = C.Stroke }, 0.15)
        tween(caption, { TextColor3 = C.SubText }, 0.15)
    end)
    btn.MouseButton1Click:Connect(function()
        local copied = false
        pcall(function()
            if setclipboard then
                setclipboard(url)
                copied = true
            end
        end)
        originNew:Notify({
            Title = tostring(label),
            Content = copied and ("Link copied: " .. url) or url,
            Type = "info",
            Duration = 4,
        })
    end)

    table.insert(self.Contacts, { kind = kind, url = url, btn = btn, order = CONTACT_ORDER[kind] or 4 })
    table.sort(self.Contacts, function(a, b)
        if a.order ~= b.order then return a.order < b.order end
        return false
    end)
    self:_layoutSidebar()
end

-- Читает contdsc / conttg / contcustom и список Contacts из параметров окна.
function Window:_collectContacts(options)
    local found = {}
    for key, value in pairs(options) do
        if type(key) == "string" and type(value) == "string" and key:lower():match("^cont%a+$") then
            table.insert(found, { kind = key:lower(), url = value })
        end
    end
    table.sort(found, function(a, b)
        local oa, ob = CONTACT_ORDER[a.kind:gsub("^cont", "")] or 4, CONTACT_ORDER[b.kind:gsub("^cont", "")] or 4
        if oa ~= ob then return oa < ob end
        return a.kind < b.kind
    end)
    for _, c in ipairs(found) do self:Contact(c.kind, c.url) end

    if type(options.Contacts) == "table" then
        for _, c in ipairs(options.Contacts) do
            if type(c) == "string" then
                local kind, url = c:match("^(cont%a+):(.+)$")
                if kind then self:Contact(kind, url) end
            elseif type(c) == "table" then
                self:Contact(c.Kind or c.kind, c.Url or c.url, c.Text or c.text, c.Icon or c.icon)
            end
        end
    end
end

-- ===== More: контекстное меню справа от имени игрока =====
-- window:More("Название", function() ... end, иконка)
-- window:More({ { Name = "A", Callback = fn }, { Name = "B", Callback = fn2 } })
function Window:More(first, callback, icon)
    if type(first) == "table" then
        for _, entry in ipairs(first) do
            self:More(entry.Name or entry.Text or entry[1], entry.Callback or entry.Function or entry[2], entry.Icon)
        end
        return
    end
    if type(first) ~= "string" or type(callback) ~= "function" then return end
    table.insert(self.MoreItems, { name = first, fn = callback, icon = icon })
    self:_rebuildMore()
end

function Window:_rebuildMore()
    local popup = self.MorePopup
    for _, child in ipairs(popup:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    for i, item in ipairs(self.MoreItems) do
        local row = create("TextButton", {
            Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = C.Field, BackgroundTransparency = 1,
            BorderSizePixel = 0, Text = "", AutoButtonColor = false, LayoutOrder = i, ZIndex = 42,
        }, popup)
        corner(row, 7)
        local label = text(row, item.name, 12, C.SubText, Enum.Font.GothamMedium)
        label.ZIndex = 43
        label.Position = UDim2.new(0, 10, 0, 0)
        label.Size = UDim2.new(1, -16, 1, 0)
        label.TextTruncate = Enum.TextTruncate.AtEnd
        if item.icon then
            local img = iconImage(row, item.icon, 14, C.SubText)
            img.ZIndex = 43
            img.AnchorPoint = Vector2.new(0, 0.5)
            img.Position = UDim2.new(0, 8, 0.5, 0)
            label.Position = UDim2.new(0, 28, 0, 0)
            label.Size = UDim2.new(1, -34, 1, 0)
        end
        row.MouseEnter:Connect(function()
            tween(row, { BackgroundTransparency = 0 }, 0.12)
            tween(label, { TextColor3 = C.Text }, 0.12)
        end)
        row.MouseLeave:Connect(function()
            tween(row, { BackgroundTransparency = 1 }, 0.12)
            tween(label, { TextColor3 = C.SubText }, 0.12)
        end)
        row.MouseButton1Click:Connect(function()
            self:_setMoreOpen(false)
            safeCall(item.fn)
        end)
    end
    local count = #self.MoreItems
    popup.Size = UDim2.new(0, 164, 0, 12 + count * 30 + math.max(count - 1, 0) * 3)
    self.MoreButton.Visible = count > 0 and not self._minimized
end

function Window:_setMoreOpen(open)
    open = open and #self.MoreItems > 0 and not self._minimized
    if open == self._moreOpen then return end
    self._moreOpen = open and true or false
    local popup = self.MorePopup
    self._moreToken = (self._moreToken or 0) + 1
    local token = self._moreToken
    if open then
        self.MoreBlocker.Visible = true
        popup.Visible = true
        popup.Position = UDim2.new(0, 12, 1, -60)
        popup.GroupTransparency = 1
        tween(popup, { GroupTransparency = 0, Position = UDim2.new(0, 12, 1, -68) }, 0.22, Enum.EasingStyle.Quint)
    else
        self.MoreBlocker.Visible = false
        tween(popup, { GroupTransparency = 1 }, 0.15)
        task.delay(0.17, function()
            if self._moreToken == token and popup.Parent then popup.Visible = false end
        end)
    end
end

-- ===== Стеклянный блюр: парт-стекло под окном + DepthOfField =====
function originNew:_acquireGlassDOF()
    self._glassUsers = self._glassUsers + 1
    if not self._glassDOF then
        local dof = Instance.new("DepthOfFieldEffect")
        dof.Name = "originNEW_GlassDOF"
        dof.FarIntensity = 0
        dof.FocusDistance = 0.05
        dof.InFocusRadius = 0.1
        dof.NearIntensity = 1
        dof.Parent = Lighting
        self._glassDOF = dof
    end
    self._glassDOF.Enabled = true
end

function originNew:_releaseGlassDOF()
    self._glassUsers = math.max(0, self._glassUsers - 1)
    if self._glassUsers == 0 and self._glassDOF then
        self._glassDOF.Enabled = false
    end
end

local GLASS_PART_TRANSPARENCY = 0.3
local GLASS_CLEAR_TRANSPARENCY = 0.98
local GLASS_DISTANCE = 0.001

-- Положение парта считается из UDim2 Position/Size окна и области ScreenGui,
-- а не из AbsolutePosition (он бывает сдвинут на размер верхней панели).
function Window:_updateGlass()
    local part = self.GlassPart
    local cam = Workspace.CurrentCamera
    if not part or not cam or not self.Holder then return end
    if part.Parent ~= cam then part.Parent = cam end

    local guiPos = { X = 0, Y = 0 }
    local guiSize = cam.ViewportSize
    local gui = self.ScreenGui
    if gui then
        local gs, gp = gui.AbsoluteSize, gui.AbsolutePosition
        if gs.X > 0 and gs.Y > 0 then guiSize, guiPos = gs, gp end
    end

    local p, s = self.Holder.Position, self.Holder.Size
    local scale = self.Scale.Scale
    local sizeX = (s.X.Scale * guiSize.X + s.X.Offset) * scale
    local sizeY = (s.Y.Scale * guiSize.Y + s.Y.Offset) * scale
    local centerX = guiPos.X + p.X.Scale * guiSize.X + p.X.Offset
    local posX = centerX - sizeX / 2
    local posY = guiPos.Y + p.Y.Scale * guiSize.Y + p.Y.Offset + self.GlassOffsetY

    local function pointAt(x, y)
        local ray = cam:ViewportPointToRay(x, y, 0)
        return ray.Origin + ray.Direction * GLASS_DISTANCE
    end
    local topLeft = pointAt(posX, posY)
    local topRight = pointAt(posX + sizeX, posY)
    local bottomLeft = pointAt(posX, posY + sizeY)
    local center = (topRight + bottomLeft) / 2
    local width = math.max((topRight - topLeft).Magnitude, 0.001)
    local height = math.max((bottomLeft - topLeft).Magnitude, 0.001)

    part.Size = Vector3.new(width, height, 0.001)
    part.CFrame = CFrame.lookAt(center, center + cam.CFrame.LookVector)
end

function Window:_setGlassActive(active)
    active = active and true or false
    if active == self._glassActive then return end
    self._glassActive = active
    local bindName = "originNEW_Glass_" .. tostring(self._id)

    if active then
        local part = Instance.new("Part")
        part.Name = "originNEW_Glass"
        part.Material = Enum.Material.Glass
        part.Color = C.Bg
        part.Transparency = self.GlassDark and GLASS_PART_TRANSPARENCY or GLASS_CLEAR_TRANSPARENCY
        part.Anchored = true
        part.CanCollide = false
        part.CanTouch = false
        part.CanQuery = false
        part.CastShadow = false
        part.Locked = true
        part.Size = Vector3.new(1, 1, 0.001)
        part.Parent = Workspace.CurrentCamera
        self.GlassPart = part
        originNew:_acquireGlassDOF()
        RunService:BindToRenderStep(bindName, Enum.RenderPriority.Camera.Value + 1, function()
            self:_updateGlass()
        end)
        self:_updateGlass()
    else
        RunService:UnbindFromRenderStep(bindName)
        if self.GlassPart then
            self.GlassPart:Destroy()
            self.GlassPart = nil
        end
        originNew:_releaseGlassDOF()
    end
end

-- Парт нужен, только пока включён режим И окно открыто.
function Window:_refreshGlass()
    self:_setGlassActive(self.GlassEnabled and self._open and not self._unloaded)
end

function Window:SetGlassEnabled(state)
    self.GlassEnabled = state and true or false
    self:_applyBackground()
    self:_refreshGlass()
end

function Window:SetGlassDark(state)
    self.GlassDark = state and true or false
    if self.GlassPart then
        tween(self.GlassPart, {
            Transparency = self.GlassDark and GLASS_PART_TRANSPARENCY or GLASS_CLEAR_TRANSPARENCY,
        }, 0.2)
    end
end

-- Ручная подстройка по вертикали, если на вашем мониторе стекло сдвинуто.
function Window:SetGlassOffsetY(px)
    self.GlassOffsetY = tonumber(px) or 0
end

-- Свечение вокруг окна (замена "Window Shadow" из originLIB).
function Window:SetShadowEnabled(state)
    self._shadowEnabled = state and true or false
    for _, g in ipairs(self.Glows) do
        local target = (self._open and self._shadowEnabled) and g.base or 1
        tween(g.frame, { BackgroundTransparency = target }, 0.25)
    end
end

function Window:_startAnim()
    if self._animConn then return end
    self._animConn = RunService.RenderStepped:Connect(function()
        local r = (os.clock() * 36) % 360
        self._borderGradient.Rotation = r
        self._logoGradient.Rotation = 45 + math.sin(os.clock() * 1.5) * 25
    end)
end

function Window:_stopAnim()
    if self._animConn then
        self._animConn:Disconnect()
        self._animConn = nil
    end
end

function Window:IsOpen()
    return self._open
end

function Window:SetOpen(open)
    open = open and true or false
    if open == self._open or self._unloaded then return end
    self._open = open
    self._animToken = self._animToken + 1
    local token = self._animToken

    if open then
        self.Holder.Visible = true
        self.MainFrame.GroupTransparency = 1
        self.Scale.Scale = self._scale * 0.9
        tween(self.MainFrame, { GroupTransparency = 0 }, 0.3)
        tween(self.Scale, { Scale = self._scale }, 0.45, Enum.EasingStyle.Back)
        for _, g in ipairs(self.Glows) do
            tween(g.frame, { BackgroundTransparency = self._shadowEnabled and g.base or 1 }, 0.4)
        end
        self:_startAnim()
    else
        tween(self.MainFrame, { GroupTransparency = 1 }, 0.2)
        tween(self.Scale, { Scale = self._scale * 0.94 }, 0.2)
        for _, g in ipairs(self.Glows) do
            tween(g.frame, { BackgroundTransparency = 1 }, 0.2)
        end
        self:_stopAnim()
        for _, d in ipairs(self.Dropdowns) do d.Close() end
        task.delay(0.22, function()
            if self._animToken == token and not self._open and self.Holder and self.Holder.Parent then
                self.Holder.Visible = false
            end
        end)
    end

    originNew:_adjustMouseCapture(open and 1 or -1)
    if not open then
        self:_hideTip()
        self:_setMoreOpen(false)
    end
    self:_refreshGlass()
end

function Window:Toggle()
    self:SetOpen(not self._open)
end

function Window:OnUnload(taskFunc)
    if type(taskFunc) == "function" then
        table.insert(self.UnloadTasks, taskFunc)
    end
end

function Window:Unload()
    if self._unloaded then return end

    for _, toggleData in ipairs(self.Toggles) do
        if toggleData.IsOn() then
            toggleData.SetState(false)
        end
    end

    for _, taskFunc in ipairs(self.UnloadTasks) do
        safeCall(taskFunc)
    end

    for _, conn in ipairs(self.Connections) do
        if conn.Connected then conn:Disconnect() end
    end
    self:_stopAnim()

    if self._open then
        self._open = false
        originNew:_adjustMouseCapture(-1)
    end
    self._unloaded = true
    self:_setGlassActive(false)

    if self.ScreenGui then self.ScreenGui:Destroy() end

    for i, w in ipairs(originNew.Windows) do
        if w == self then
            table.remove(originNew.Windows, i)
            break
        end
    end
end

-- Закрывает все раскрытые списки, кроме `except`.
function Window:CloseOtherDropdowns(except)
    for _, d in ipairs(self.Dropdowns) do
        if d ~= except then d.Close() end
    end
end

-- ==========================================
-- ВКЛАДКИ
-- ==========================================
-- window:Tab("Name", порядок, иконка) или window:Tab({ Name = "Name", Icon = "...", Order = 2 })
function Window:Tab(name, layoutOrder, icon)
    if type(name) == "table" then
        layoutOrder = name.Order or name.LayoutOrder or layoutOrder
        icon = name.Icon or icon
        name = name.Name or name.Title
    end
    local window = self
    local tab = setmetatable({}, Tab)
    tab.Window = self
    tab.Name = tostring(name)
    tab._items = {}

    local btn = create("TextButton", {
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 1,
        Text = "", AutoButtonColor = false, ClipsDescendants = true,
        LayoutOrder = layoutOrder or #self.Tabs,
    }, self.TabList)
    corner(btn, 10)

    local fill = create("Frame", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 1, BorderSizePixel = 0,
    }, btn)
    corner(fill, 10)
    local fillGradient = create("UIGradient", { Color = accentSeq(self.Theme.Accent) }, fill)

    local marker = create("Frame", {
        AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(0, 3, 0, 0), BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0,
    }, btn)
    corner(marker, 2)
    local markerGradient = create("UIGradient", { Color = accentSeq(self.Theme.Accent), Rotation = 90 }, marker)

    local label = text(btn, tab.Name, 13, C.SubText, Enum.Font.GothamMedium)
    label.Position = UDim2.new(0, 16, 0, 0)
    label.Size = UDim2.new(1, -24, 1, 0)
    local tabIcon
    if icon then
        tabIcon = iconImage(btn, icon, 16, C.SubText)
        tabIcon.AnchorPoint = Vector2.new(0, 0.5)
        tabIcon.Position = UDim2.new(0, 16, 0.5, 0)
        label.Position = UDim2.new(0, 40, 0, 0)
        label.Size = UDim2.new(1, -48, 1, 0)
    end

    self:_themed(function(a)
        local seq = accentSeq(a)
        fillGradient.Color = seq
        markerGradient.Color = seq
    end)

    local page = create("ScrollingFrame", {
        Name = tab.Name,
        Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0, 0, 0, 14),
        BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false,
        ScrollBarThickness = 3, ScrollBarImageTransparency = 0.3,
        AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(0, 0, 0, 0),
    }, self.Pages)
    padding(page, 18, 4, 16, 14)
    create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, page)
    self:_themed(function(a) page.ScrollBarImageColor3 = a end)

    tab.Page = page
    tab.TabButton = btn

    local function setActive(active)
        if active then
            tween(fill, { BackgroundTransparency = 0.82 }, 0.25)
            tween(marker, { Size = UDim2.new(0, 3, 0, 18) }, 0.35, Enum.EasingStyle.Back)
            tween(label, { TextColor3 = C.Text }, 0.2)
            if tabIcon then tween(tabIcon, { ImageColor3 = C.Text }, 0.2) end
        else
            tween(fill, { BackgroundTransparency = 1 }, 0.2)
            tween(marker, { Size = UDim2.new(0, 3, 0, 0) }, 0.2)
            tween(label, { TextColor3 = C.SubText }, 0.2)
            if tabIcon then tween(tabIcon, { ImageColor3 = C.SubText }, 0.2) end
        end
    end

    local function activate()
        if window.ActiveTab == tab then return end
        for _, t in ipairs(window.Tabs) do
            if t.Tab ~= tab then
                t.Tab.Page.Visible = false
                t.setActive(false)
            end
        end
        window.ActiveTab = tab
        page.Position = UDim2.new(0, 0, 0, 14)
        page.Visible = true
        tween(page, { Position = UDim2.new(0, 0, 0, 0) }, 0.35)
        setActive(true)
        window.PageTitle.Text = tab.Name
        window:CloseOtherDropdowns(nil)
        window:_hideTip()
        tab:_applySearch()
    end
    tab.Activate = activate

    btn.MouseButton1Click:Connect(activate)
    btn.MouseEnter:Connect(function()
        if window.ActiveTab ~= tab then
            tween(label, { TextColor3 = C.Text }, 0.15)
            if tabIcon then tween(tabIcon, { ImageColor3 = C.Text }, 0.15) end
        end
    end)
    btn.MouseLeave:Connect(function()
        if window.ActiveTab ~= tab then
            tween(label, { TextColor3 = C.SubText }, 0.15)
            if tabIcon then tween(tabIcon, { ImageColor3 = C.SubText }, 0.15) end
        end
    end)

    table.insert(self.Tabs, { Tab = tab, setActive = setActive })

    -- Первая созданная вкладка (кроме Settings) открывается сразу.
    if window.ActiveTab == nil and tab.Name ~= "Settings" then
        activate()
    end

    return tab
end

-- Поиск идёт по названию и по описанию (на любом языке). Совпадение в названии
-- подсвечивается, совпадение только в описании красит название акцентом.
function Tab:_applySearch()
    local window = self.Window
    local q = window.SearchQuery or ""
    local hex = toHex(window.Theme.AccentText)
    for _, item in ipairs(self._items) do
        local label = item.title
        if label and not item.marked then item.plain = label.Text end

        if q == "" then
            item.frame.Visible = true
            if label and item.marked then
                label.RichText = false
                label.Text = item.plain
                label.TextColor3 = item.baseColor
                item.marked = false
            end
        elseif item.kind == "section" or item.kind == "divider" then
            item.frame.Visible = false
        else
            local inTitle = lowerU(item.plain or item.name):find(q, 1, true) ~= nil
            local inDesc = false
            for _, d in ipairs(item.descs) do
                if d:find(q, 1, true) then inDesc = true break end
            end
            item.frame.Visible = inTitle or inDesc
            if label and (inTitle or inDesc) then
                if not item.marked then item.baseColor = label.TextColor3 end
                item.marked = true
                if inTitle then
                    label.RichText = true
                    label.Text = highlight(item.plain, q, hex)
                    label.TextColor3 = item.baseColor
                else
                    label.RichText = false
                    label.Text = item.plain
                    label.TextColor3 = window.Theme.AccentText
                end
            elseif label and item.marked then
                label.RichText = false
                label.Text = item.plain
                label.TextColor3 = item.baseColor
                item.marked = false
            end
        end
    end
end

function Tab:_register(frame, name, kind, titleLabel, spec)
    table.insert(self._items, {
        frame = frame,
        name = lowerU(name),
        plain = tostring(name or ""),
        kind = kind or "element",
        title = titleLabel,
        baseColor = titleLabel and titleLabel.TextColor3 or nil,
        descs = descList(spec and spec.desc),
        marked = false,
    })
end

-- Иконка слева от названия и описание при наведении. `overlay` это невидимая
-- кнопка поверх карточки: на неё тоже вешаем наведение.
function Tab:_decorate(card, title, spec, overlay)
    local window = self.Window
    if spec.icon then
        local shift = 26
        local img = iconImage(card, spec.icon, 18, C.SubText)
        img.AnchorPoint = Vector2.new(0, 0.5)
        if title.Size.Y.Scale >= 1 then
            img.Position = UDim2.new(0, 14, 0.5, 0)
        else
            img.Position = UDim2.new(0, 14, 0, title.Position.Y.Offset + title.Size.Y.Offset / 2)
        end
        title.Position = UDim2.new(title.Position.X.Scale, title.Position.X.Offset + shift, title.Position.Y.Scale, title.Position.Y.Offset)
        title.Size = UDim2.new(title.Size.X.Scale, title.Size.X.Offset - shift, title.Size.Y.Scale, title.Size.Y.Offset)
    end
    if spec.desc then
        local function enter() window:_showTip(card, spec.desc) end
        local function leave() window:_hideTip(card) end
        card.MouseEnter:Connect(enter)
        card.MouseLeave:Connect(leave)
        if overlay then
            overlay.MouseEnter:Connect(enter)
            overlay.MouseLeave:Connect(leave)
        end
    end
end

-- Карточка-контейнер элемента.
function Tab:_card(height, hoverable)
    local card = create("Frame", {
        Size = UDim2.new(1, 0, 0, height),
        BackgroundColor3 = C.Card, BorderSizePixel = 0, ClipsDescendants = true,
    }, self.Page)
    corner(card, 10)
    local st = stroke(card, C.Stroke, 1, 0)
    if hoverable then
        card.MouseEnter:Connect(function()
            tween(card, { BackgroundColor3 = C.CardHover }, 0.15)
            tween(st, { Color = C.StrokeHi }, 0.15)
        end)
        card.MouseLeave:Connect(function()
            tween(card, { BackgroundColor3 = C.Card }, 0.15)
            tween(st, { Color = C.Stroke }, 0.15)
        end)
    end
    return card, st
end

-- ==========================================
-- ЭЛЕМЕНТЫ
-- ==========================================

-- Button(text, callback)
function Tab:Button(label, callback)
    local window = self.Window
    local spec = parseSpec(label)
    label = spec.text
    local card = self:_card(42, true)

    local title = text(card, tostring(label), 13, C.Text, Enum.Font.GothamMedium)
    title.Position = UDim2.new(0, 14, 0, 0)
    title.Size = UDim2.new(1, -50, 1, 0)

    local arrow = text(card, ">", 14, C.Dim, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
    arrow.Position = UDim2.new(1, -36, 0, 0)
    arrow.Size = UDim2.new(0, 22, 1, 0)

    local click = create("TextButton", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
        Text = "", AutoButtonColor = false, ZIndex = 2,
    }, card)
    click.InputBegan:Connect(function(input)
        if isPress(input) then ripple(card, input) end
    end)
    click.MouseButton1Click:Connect(function()
        tween(arrow, { TextColor3 = window.Theme.AccentText }, 0.1)
        task.delay(0.2, function()
            if arrow.Parent then tween(arrow, { TextColor3 = C.Dim }, 0.25) end
        end)
        safeCall(callback)
    end)

    self:_decorate(card, title, spec, click)
    self:_register(card, label, "button", title, spec)
    return {
        SetText = function(value) title.Text = tostring(value) end,
        Click = function() safeCall(callback) end,
    }
end

-- Toggle(text, default, callback)
function Tab:Toggle(label, default, callback)
    local window = self.Window
    local spec = parseSpec(label)
    label = spec.text
    local state = default and true or false
    local card = self:_card(42, true)

    local title = text(card, tostring(label), 13, C.Text, Enum.Font.GothamMedium)
    title.Position = UDim2.new(0, 14, 0, 0)
    title.Size = UDim2.new(1, -80, 1, 0)

    local track = create("Frame", {
        Size = UDim2.new(0, 42, 0, 22), Position = UDim2.new(1, -56, 0.5, -11),
        BackgroundColor3 = C.Off, BorderSizePixel = 0,
    }, card)
    corner(track, 11)

    local fill = create("Frame", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = state and 0 or 1, BorderSizePixel = 0,
    }, track)
    corner(fill, 11)
    local fillGradient = create("UIGradient", { Color = accentSeq(window.Theme.Accent) }, fill)
    window:_themed(function(a) fillGradient.Color = accentSeq(a) end)

    local knob = create("Frame", {
        Size = UDim2.new(0, 16, 0, 16), AnchorPoint = Vector2.new(0, 0.5),
        Position = state and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0, ZIndex = 2,
    }, track)
    corner(knob, 8)

    -- Ручка на светлом акценте получает тёмный цвет, иначе она сливалась бы с заливкой.
    local function knobColor(on)
        if on then return contrastOn(window.Theme.Accent) end
        return Color3.fromRGB(255, 255, 255)
    end
    knob.BackgroundColor3 = knobColor(state)
    window:_themed(function() knob.BackgroundColor3 = knobColor(state) end)

    local click = create("TextButton", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 3,
    }, card)

    local function setState(newState)
        state = newState and true or false
        tween(fill, { BackgroundTransparency = state and 0 or 1 }, 0.22)
        tween(knob, { Position = state and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0) }, 0.3, Enum.EasingStyle.Back)
        tween(knob, { BackgroundColor3 = knobColor(state) }, 0.22)
        safeCall(callback, state)
    end

    click.MouseButton1Click:Connect(function() setState(not state) end)

    -- Тогглы встроенной вкладки настроек не выключаются при Unload: иначе выгрузка
    -- записала бы в конфиг "всё выключено".
    if not self._internal then
        table.insert(window.Toggles, {
            IsOn = function() return state end,
            SetState = setState,
        })
    end

    self:_decorate(card, title, spec, click)
    self:_register(card, label, "toggle", title, spec)
    return { SetState = setState, IsOn = function() return state end }
end

-- Slider(text, min, max, default, callback)
function Tab:Slider(label, min, max, default, callback)
    local window = self.Window
    local spec = parseSpec(label)
    label = spec.text
    min = min or 0
    max = max or 100
    if max == min then max = min + 1 end
    local value = math.clamp(default or min, min, max)

    local card = self:_card(56, true)

    local title = text(card, tostring(label), 13, C.Text, Enum.Font.GothamMedium)
    title.Position = UDim2.new(0, 14, 0, 9)
    title.Size = UDim2.new(0.6, 0, 0, 16)

    local valueLabel = text(card, tostring(value), 12, C.SubText, Enum.Font.GothamBold, Enum.TextXAlignment.Right)
    valueLabel.Position = UDim2.new(1, -74, 0, 9)
    valueLabel.Size = UDim2.new(0, 60, 0, 16)

    local track = create("Frame", {
        Position = UDim2.new(0, 14, 0, 36), Size = UDim2.new(1, -28, 0, 6),
        BackgroundColor3 = C.Off, BorderSizePixel = 0,
    }, card)
    corner(track, 3)

    local frac = (value - min) / (max - min)
    local fill = create("Frame", {
        Size = UDim2.new(frac, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0,
    }, track)
    corner(fill, 3)
    local fillGradient = create("UIGradient", { Color = accentSeq(window.Theme.Accent) }, fill)

    local thumb = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(frac, 0, 0.5, 0),
        Size = UDim2.new(0, 14, 0, 14), BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0, ZIndex = 2,
    }, track)
    corner(thumb, 7)
    local thumbStroke = stroke(thumb, window.Theme.Accent, 2, 0)

    window:_themed(function(a)
        fillGradient.Color = accentSeq(a)
        thumbStroke.Color = a
        thumb.BackgroundColor3 = contrastOn(a)
    end)

    local function applyValue(v, fire)
        v = math.clamp(v, min, max)
        local changed = v ~= value
        value = v
        local f = (v - min) / (max - min)
        -- Значения остаются целыми шагами, но полоска и ручка скользят к ним плавно.
        tween(fill, { Size = UDim2.new(f, 0, 1, 0) }, 0.14)
        tween(thumb, { Position = UDim2.new(f, 0, 0.5, 0) }, 0.14)
        valueLabel.Text = tostring(v)
        if fire and changed then safeCall(callback, v) end
    end

    local function update(input)
        local f = math.clamp((input.Position.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
        applyValue(math.floor(min + (max - min) * f + 0.5), true)
    end

    local function begin(input)
        if not isPress(input) then return end
        update(input)
        tween(thumb, { Size = UDim2.new(0, 18, 0, 18) }, 0.15, Enum.EasingStyle.Back)
        tween(valueLabel, { TextColor3 = window.Theme.AccentText }, 0.15)
        window.DragState = {
            Update = update,
            Release = function()
                tween(thumb, { Size = UDim2.new(0, 14, 0, 14) }, 0.2)
                tween(valueLabel, { TextColor3 = C.SubText }, 0.2)
            end,
        }
    end
    track.InputBegan:Connect(begin)
    thumb.InputBegan:Connect(begin)

    self:_decorate(card, title, spec, nil)
    self:_register(card, label, "slider", title, spec)
    return {
        GetValue = function() return value end,
        SetValue = function(v) applyValue(v, true) end,
    }
end

-- TextBox(text, placeholder, callback)
function Tab:TextBox(label, placeholder, callback)
    local window = self.Window
    local spec = parseSpec(label)
    label = spec.text
    local card = self:_card(42, true)

    local title = text(card, tostring(label), 13, C.Text, Enum.Font.GothamMedium)
    title.Position = UDim2.new(0, 14, 0, 0)
    title.Size = UDim2.new(0.45, 0, 1, 0)

    local field = create("Frame", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.new(0.5, -12, 0, 28), BackgroundColor3 = C.Field, BorderSizePixel = 0,
    }, card)
    corner(field, 8)
    local fieldStroke = stroke(field, C.Stroke, 1, 0)

    local input = create("TextBox", {
        Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(1, -20, 1, 0),
        BackgroundTransparency = 1, Text = "", PlaceholderText = placeholder or "Enter...",
        PlaceholderColor3 = C.Dim, TextColor3 = C.Text, Font = Enum.Font.Gotham, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false,
    }, field)

    input.Focused:Connect(function() tween(fieldStroke, { Color = window.Theme.Accent }, 0.15) end)
    input.FocusLost:Connect(function(enter)
        tween(fieldStroke, { Color = C.Stroke }, 0.15)
        if enter then safeCall(callback, input.Text) end
    end)

    self:_decorate(card, title, spec, nil)
    self:_register(card, label, "textbox", title, spec)
    return {
        Input = input,
        GetText = function() return input.Text end,
        SetText = function(value) input.Text = tostring(value) end,
    }
end

-- Keybind(text, defaultKey, callback)
local PAIRED_KEYS = {
    [Enum.KeyCode.LeftControl] = Enum.KeyCode.RightControl,
    [Enum.KeyCode.RightControl] = Enum.KeyCode.LeftControl,
    [Enum.KeyCode.LeftShift] = Enum.KeyCode.RightShift,
    [Enum.KeyCode.RightShift] = Enum.KeyCode.LeftShift,
    [Enum.KeyCode.LeftAlt] = Enum.KeyCode.RightAlt,
    [Enum.KeyCode.RightAlt] = Enum.KeyCode.LeftAlt,
}
local FRIENDLY_KEYS = {
    [Enum.KeyCode.LeftControl] = "Control", [Enum.KeyCode.RightControl] = "Control",
    [Enum.KeyCode.LeftShift] = "Shift", [Enum.KeyCode.RightShift] = "Shift",
    [Enum.KeyCode.LeftAlt] = "Alt", [Enum.KeyCode.RightAlt] = "Alt",
}

function Tab:Keybind(label, defaultKey, callback, onChange)
    local window = self.Window
    local spec = parseSpec(label)
    label = spec.text
    local currentKey = defaultKey or Enum.KeyCode.RightControl
    local card = self:_card(42, true)

    local title = text(card, tostring(label), 13, C.Text, Enum.Font.GothamMedium)
    title.Position = UDim2.new(0, 14, 0, 0)
    title.Size = UDim2.new(0.6, 0, 1, 0)

    local pill = create("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.new(0, 104, 0, 26), BackgroundColor3 = C.Field, BorderSizePixel = 0,
        Text = "", AutoButtonColor = false,
    }, card)
    corner(pill, 8)
    local pillStroke = stroke(pill, C.Stroke, 1, 0)
    local pillLabel = text(pill, "", 11, window.Theme.AccentText, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
    pillLabel.Size = UDim2.new(1, 0, 1, 0)
    window:_themed(function(_, _, t) pillLabel.TextColor3 = t end)

    local function keyName(key) return FRIENDLY_KEYS[key] or key.Name end
    pillLabel.Text = keyName(currentKey)

    local function register(key)
        window.KeybindMap[key] = window.KeybindMap[key] or {}
        table.insert(window.KeybindMap[key], callback)
        local pair = PAIRED_KEYS[key]
        if pair then
            window.KeybindMap[pair] = window.KeybindMap[pair] or {}
            table.insert(window.KeybindMap[pair], callback)
        end
    end

    local function unregister(key)
        local function removeFrom(k)
            local bucket = window.KeybindMap[k]
            if not bucket then return end
            for i, cb in ipairs(bucket) do
                if cb == callback then
                    table.remove(bucket, i)
                    break
                end
            end
        end
        removeFrom(key)
        local pair = PAIRED_KEYS[key]
        if pair then removeFrom(pair) end
    end

    register(currentKey)

    local function setKey(newKey)
        unregister(currentKey)
        currentKey = newKey
        register(currentKey)
        pillLabel.Text = keyName(currentKey)
        safeCall(onChange, currentKey)
    end

    pill.MouseButton1Click:Connect(function()
        if window.ListeningKeybind then window.ListeningKeybind.Cancel() end
        pillLabel.Text = "Press key..."
        tween(pillStroke, { Color = window.Theme.Accent }, 0.15)
        window.ListeningKeybind = {
            Bind = function(newKey)
                setKey(newKey)
                tween(pillStroke, { Color = C.Stroke }, 0.15)
            end,
            Cancel = function()
                pillLabel.Text = keyName(currentKey)
                tween(pillStroke, { Color = C.Stroke }, 0.15)
            end,
        }
    end)

    self:_decorate(card, title, spec, nil)
    self:_register(card, label, "keybind", title, spec)
    return {
        GetKey = function() return currentKey end,
        SetKey = setKey,
    }
end

-- ColorPicker(text, defaultColor, callback)
function Tab:ColorPicker(label, defaultColor, callback)
    local window = self.Window
    local spec = parseSpec(label)
    label = spec.text
    local currentColor = defaultColor or DEFAULT_ACCENT
    local h, s, v = Color3.toHSV(currentColor)
    local HEAD, OPEN_HEIGHT = 42, 236
    local card = self:_card(HEAD, true)

    local title = text(card, tostring(label), 13, C.Text, Enum.Font.GothamMedium)
    title.Position = UDim2.new(0, 14, 0, 0)
    title.Size = UDim2.new(0.5, 0, 0, HEAD)

    local hexLabel = text(card, toHex(currentColor), 11, C.Dim, Enum.Font.Code, Enum.TextXAlignment.Right)
    hexLabel.AnchorPoint = Vector2.new(1, 0)
    hexLabel.Position = UDim2.new(1, -58, 0, 13)
    hexLabel.Size = UDim2.new(0, 70, 0, 16)

    local swatch = create("Frame", {
        AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 10),
        Size = UDim2.new(0, 36, 0, 22), BackgroundColor3 = currentColor, BorderSizePixel = 0,
    }, card)
    corner(swatch, 7)
    stroke(swatch, Color3.fromRGB(255, 255, 255), 1, 0.75)

    local header = create("TextButton", {
        Size = UDim2.new(1, 0, 0, HEAD), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 2,
    }, card)

    local body = create("Frame", {
        Position = UDim2.new(0, 14, 0, 50), Size = UDim2.new(1, -28, 0, 172), BackgroundTransparency = 1,
    }, card)

    local svBox = create("ImageLabel", {
        Size = UDim2.new(1, 0, 0, 110), BackgroundColor3 = Color3.fromHSV(h, 1, 1),
        Image = "rbxassetid://4155801252", BorderSizePixel = 0,
    }, body)
    corner(svBox, 8)
    local cursor = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(s, 0, 1 - v, 0),
        Size = UDim2.new(0, 12, 0, 12), BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0,
    }, svBox)
    corner(cursor, 6)
    stroke(cursor, Color3.fromRGB(0, 0, 0), 1.5, 0)

    local hueBar = create("Frame", {
        Position = UDim2.new(0, 0, 0, 120), Size = UDim2.new(1, 0, 0, 14),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0,
    }, body)
    corner(hueBar, 7)
    create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
            ColorSequenceKeypoint.new(0.167, Color3.fromRGB(255, 255, 0)),
            ColorSequenceKeypoint.new(0.333, Color3.fromRGB(0, 255, 0)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
            ColorSequenceKeypoint.new(0.667, Color3.fromRGB(0, 0, 255)),
            ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255, 0, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
        }),
    }, hueBar)
    local hueCursor = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(h, 0, 0.5, 0),
        Size = UDim2.new(0, 6, 1, 6), BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0,
    }, hueBar)
    corner(hueCursor, 3)
    stroke(hueCursor, Color3.fromRGB(0, 0, 0), 1, 0.3)

    local hexField = create("Frame", {
        Position = UDim2.new(0, 0, 0, 144), Size = UDim2.new(0.5, 0, 0, 28),
        BackgroundColor3 = C.Field, BorderSizePixel = 0,
    }, body)
    corner(hexField, 8)
    local hexStroke = stroke(hexField, C.Stroke, 1, 0)
    local hexInput = create("TextBox", {
        Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(1, -20, 1, 0), BackgroundTransparency = 1,
        Text = toHex(currentColor), PlaceholderText = "#RRGGBB", PlaceholderColor3 = C.Dim,
        TextColor3 = C.Text, Font = Enum.Font.Code, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false,
    }, hexField)

    local function refresh(fire)
        currentColor = Color3.fromHSV(h, s, v)
        swatch.BackgroundColor3 = currentColor
        hexLabel.Text = toHex(currentColor)
        hexInput.Text = toHex(currentColor)
        svBox.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        cursor.Position = UDim2.new(s, 0, 1 - v, 0)
        hueCursor.Position = UDim2.new(h, 0, 0.5, 0)
        if fire then safeCall(callback, currentColor) end
    end

    local function updateSV(input)
        s = math.clamp((input.Position.X - svBox.AbsolutePosition.X) / math.max(svBox.AbsoluteSize.X, 1), 0, 1)
        v = 1 - math.clamp((input.Position.Y - svBox.AbsolutePosition.Y) / math.max(svBox.AbsoluteSize.Y, 1), 0, 1)
        refresh(true)
    end
    local function updateHue(input)
        h = math.clamp((input.Position.X - hueBar.AbsolutePosition.X) / math.max(hueBar.AbsoluteSize.X, 1), 0, 1)
        refresh(true)
    end
    svBox.InputBegan:Connect(function(input)
        if isPress(input) then
            updateSV(input)
            window.DragState = { Update = updateSV }
        end
    end)
    hueBar.InputBegan:Connect(function(input)
        if isPress(input) then
            updateHue(input)
            window.DragState = { Update = updateHue }
        end
    end)

    hexInput.Focused:Connect(function() tween(hexStroke, { Color = window.Theme.Accent }, 0.15) end)
    hexInput.FocusLost:Connect(function()
        tween(hexStroke, { Color = C.Stroke }, 0.15)
        local parsed = parseHex(hexInput.Text)
        if parsed then
            h, s, v = Color3.toHSV(parsed)
            refresh(true)
        else
            hexInput.Text = toHex(currentColor)
        end
    end)

    local isOpen = false
    header.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        tween(card, { Size = UDim2.new(1, 0, 0, isOpen and OPEN_HEIGHT or HEAD) }, 0.35)
    end)

    self:_decorate(card, title, spec, header)
    self:_register(card, label, "colorpicker", title, spec)
    return {
        GetColor = function() return currentColor end,
        SetColor = function(color)
            h, s, v = Color3.toHSV(color)
            refresh(true)
        end,
    }
end

-- Общая сборка для Dropdown и MultiDropdown
local function buildDropdown(tab, label, options, initial, callback, multi)
    local window = tab.Window
    local spec = parseSpec(label)
    label = spec.text
    options = options or {}
    local HEAD, ROW = 42, 30

    local selected
    local set = {}
    if multi then
        for _, value in ipairs(initial or {}) do set[value] = true end
    else
        selected = initial or options[1]
    end

    local card = tab:_card(HEAD, true)

    local title = text(card, tostring(label), 13, C.Text, Enum.Font.GothamMedium)
    title.Position = UDim2.new(0, 14, 0, 0)
    title.Size = UDim2.new(0.4, 0, 0, HEAD)

    local pill = create("Frame", {
        AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 8),
        Size = UDim2.new(0.5, -12, 0, 26), BackgroundColor3 = C.Field, BorderSizePixel = 0,
    }, card)
    corner(pill, 8)
    stroke(pill, C.Stroke, 1, 0)

    local pillLabel = text(pill, "", 11, window.Theme.AccentText, Enum.Font.GothamBold)
    pillLabel.Position = UDim2.new(0, 10, 0, 0)
    pillLabel.Size = UDim2.new(1, -30, 1, 0)
    pillLabel.TextTruncate = Enum.TextTruncate.AtEnd
    window:_themed(function(_, _, t) pillLabel.TextColor3 = t end)

    local arrow = text(pill, "v", 11, C.SubText, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
    arrow.Position = UDim2.new(1, -22, 0, 0)
    arrow.Size = UDim2.new(0, 16, 1, 0)

    local header = create("TextButton", {
        Size = UDim2.new(1, 0, 0, HEAD), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 2,
    }, card)

    local list = create("ScrollingFrame", {
        Position = UDim2.new(0, 12, 0, HEAD + 2), Size = UDim2.new(1, -24, 1, -(HEAD + 12)),
        BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2,
        AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(0, 0, 0, 0),
    }, card)
    create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, list)

    local function summary()
        if multi then
            local picked = {}
            for _, option in ipairs(options) do
                if set[option] then table.insert(picked, tostring(option)) end
            end
            if #picked == 0 then return "None" end
            if #picked == 1 then return picked[1] end
            return #picked .. " selected"
        end
        return tostring(selected)
    end
    pillLabel.Text = summary()

    local rows = {}
    local function refreshRows()
        for _, row in ipairs(rows) do
            local on
            if multi then on = set[row.option] == true else on = row.option == selected end
            tween(row.mark, { BackgroundTransparency = on and 0 or 1 }, 0.15)
            tween(row.label, { TextColor3 = on and C.Text or C.SubText }, 0.15)
        end
        pillLabel.Text = summary()
    end

    local function buildRows()
      for _, old in ipairs(rows) do old.button:Destroy() end
      rows = {}
      for index, option in ipairs(options) do
        local row = create("TextButton", {
            Size = UDim2.new(1, -4, 0, ROW), BackgroundColor3 = C.Field, BorderSizePixel = 0,
            Text = "", AutoButtonColor = false, LayoutOrder = index,
        }, list)
        corner(row, 8)
        local rowLabel = text(row, tostring(option), 12, C.SubText, Enum.Font.GothamMedium)
        rowLabel.Position = UDim2.new(0, 12, 0, 0)
        rowLabel.Size = UDim2.new(1, -40, 1, 0)

        local box = create("Frame", {
            AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0),
            Size = UDim2.new(0, 12, 0, 12), BackgroundTransparency = 1, BorderSizePixel = 0,
        }, row)
        corner(box, multi and 4 or 6)
        local boxStroke = stroke(box, C.StrokeHi, 1, 0)
        local mark = create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(0, 6, 0, 6), BackgroundColor3 = window.Theme.AccentText,
            BackgroundTransparency = 1, BorderSizePixel = 0,
        }, box)
        corner(mark, multi and 2 or 3)
        window:_themed(function(_, _, t) mark.BackgroundColor3 = t end)

        row.MouseEnter:Connect(function() tween(row, { BackgroundColor3 = C.CardHover }, 0.12) end)
        row.MouseLeave:Connect(function() tween(row, { BackgroundColor3 = C.Field }, 0.12) end)

        table.insert(rows, { option = option, mark = mark, label = rowLabel, button = row })

        row.MouseButton1Click:Connect(function()
            if multi then
                set[option] = (not set[option]) or nil
                refreshRows()
                local picked = {}
                for _, o in ipairs(options) do
                    if set[o] then table.insert(picked, o) end
                end
                safeCall(callback, picked)
            else
                selected = option
                refreshRows()
                safeCall(callback, selected)
                tab.Window:CloseOtherDropdowns(nil)
            end
        end)
      end
      refreshRows()
    end
    buildRows()

    local isOpen = false
    local entry = {}
    local function setOpen(open)
        isOpen = open
        local openHeight = HEAD + 12 + math.min(#options, 5) * (ROW + 4)
        tween(card, { Size = UDim2.new(1, 0, 0, open and openHeight or HEAD) }, 0.35)
        tween(arrow, { Rotation = open and 180 or 0 }, 0.25)
    end
    entry.Close = function() if isOpen then setOpen(false) end end
    table.insert(window.Dropdowns, entry)

    header.MouseButton1Click:Connect(function()
        if not isOpen then window:CloseOtherDropdowns(entry) end
        setOpen(not isOpen)
    end)

    tab:_decorate(card, title, spec, header)
    tab:_register(card, label, multi and "multidropdown" or "dropdown", title, spec)

    -- Меняет список вариантов на лету (нужно, например, для списка конфигов).
    -- Выбранное значение сохраняется, если оно есть в новом списке.
    local function setOptions(newOptions)
        options = newOptions or {}
        if multi then
            local keep = {}
            for _, o in ipairs(options) do
                if set[o] then keep[o] = true end
            end
            set = keep
        else
            local found = false
            for _, o in ipairs(options) do
                if o == selected then found = true end
            end
            if not found then selected = options[1] end
        end
        buildRows()
        if isOpen then setOpen(true) end
    end

    if multi then
        return {
            SetOptions = setOptions,
            GetValues = function()
                local picked = {}
                for _, o in ipairs(options) do
                    if set[o] then table.insert(picked, o) end
                end
                return picked
            end,
        }
    end
    return {
        SetOptions = setOptions,
        GetValue = function() return selected end,
        SetValue = function(value)
            selected = value
            refreshRows()
            safeCall(callback, selected)
        end,
    }
end

function Tab:Dropdown(label, options, default, callback)
    return buildDropdown(self, label, options, default, callback, false)
end

function Tab:MultiDropdown(label, options, defaults, callback)
    return buildDropdown(self, label, options, defaults, callback, true)
end

-- Paragraph(title, content)
function Tab:Paragraph(title, content)
    local card = self:_card(0, false)
    card.Size = UDim2.new(1, 0, 0, 0)
    card.AutomaticSize = Enum.AutomaticSize.Y
    padding(card, 14, 11, 14, 12)
    create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, card)

    local titleLabel = text(card, tostring(title or "Title"), 13, C.Text, Enum.Font.GothamBold)
    titleLabel.Size = UDim2.new(1, 0, 0, 16)
    titleLabel.LayoutOrder = 1

    local body = text(card, tostring(content or ""), 12, C.SubText, Enum.Font.Gotham)
    body.Size = UDim2.new(1, 0, 0, 0)
    body.AutomaticSize = Enum.AutomaticSize.Y
    body.TextWrapped = true
    body.TextYAlignment = Enum.TextYAlignment.Top
    body.LayoutOrder = 2

    self:_register(card, tostring(title) .. " " .. tostring(content), "paragraph")
    return {
        Set = function(newTitle, newContent)
            if newTitle ~= nil then titleLabel.Text = tostring(newTitle) end
            if newContent ~= nil then body.Text = tostring(newContent) end
        end,
    }
end

-- Section(text)
function Tab:Section(label)
    local window = self.Window
    local frame = create("Frame", {
        Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1,
    }, self.Page)

    local title = text(frame, string.upper(tostring(label or "SECTION")), 11, window.Theme.AccentText, Enum.Font.GothamBold)
    title.Position = UDim2.new(0, 2, 0, 4)
    title.Size = UDim2.new(1, 0, 0, 16)
    window:_themed(function(_, _, t) title.TextColor3 = t end)

    create("Frame", {
        Position = UDim2.new(0, 0, 1, -4), Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = C.Stroke, BorderSizePixel = 0,
    }, frame)

    self:_register(frame, label, "section")
end

-- Label(text)
function Tab:Label(label)
    local lbl = text(self.Page, tostring(label or ""), 12, C.SubText, Enum.Font.Gotham)
    lbl.Size = UDim2.new(1, 0, 0, 0)
    lbl.AutomaticSize = Enum.AutomaticSize.Y
    lbl.TextWrapped = true
    self:_register(lbl, label, "label")
    return lbl
end

-- Divider()
function Tab:Divider()
    local frame = create("Frame", {
        Size = UDim2.new(1, 0, 0, 10), BackgroundTransparency = 1,
    }, self.Page)
    create("Frame", {
        Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = C.Stroke, BorderSizePixel = 0,
    }, frame)
    self:_register(frame, "", "divider")
end

-- Notice(text, color)  color: Color3 или "info" | "success" | "warning" | "error"
function Tab:Notice(message, color)
    local window = self.Window
    local function resolve(value)
        if typeof(value) == "Color3" then return value end
        if type(value) == "string" then return NOTIF_COLORS[value:lower()] or window.Theme.Accent end
        return C.Warning
    end
    local tint = resolve(color)

    local card, st = self:_card(0, false)
    card.Size = UDim2.new(1, 0, 0, 0)
    card.AutomaticSize = Enum.AutomaticSize.Y
    st.Color = tint
    st.Transparency = 0.5
    padding(card, 14, 10, 14, 10)

    local body = text(card, tostring(message or ""), 12, tint, Enum.Font.Gotham)
    body.Size = UDim2.new(1, 0, 0, 0)
    body.AutomaticSize = Enum.AutomaticSize.Y
    body.TextWrapped = true
    body.TextYAlignment = Enum.TextYAlignment.Top

    self:_register(card, message, "notice")
    return {
        Label = body,
        Set = function(newText, newColor)
            body.Text = tostring(newText or "")
            if newColor ~= nil then
                local c = resolve(newColor)
                body.TextColor3 = c
                st.Color = c
            end
        end,
    }
end

-- ==========================================
-- ВСТРОЕННАЯ ВКЛАДКА SETTINGS
-- Все значения хранятся в OriginNewGuiSettings.cfg. Если включено
-- "Auto Load / Save Settings" (autoloadme:yes), сохранённые значения
-- применяются при запуске и каждое изменение пишется в файл.
-- ==========================================
function Window:BuildSettingsTab()
    local window = self
    originNew:_initConfig()
    local tab = window:Tab("Settings", 9999)
    tab._internal = true
    window.SettingsTab = tab

    -- Начальное значение: сохранённое (если включена автозагрузка), затем
    -- пресет автора скрипта, затем значение по умолчанию.
    local function saved(key)
        local k = key:lower()
        if originNew._autoSave and originNew._cfg[k] ~= nil then return originNew._cfg[k] end
        return originNew._preset[k]
    end
    local function remember(key, value)
        originNew._cfg[key:lower()] = tostring(value)
    end
    local function persist(key, value)
        originNew:SetConfig(key, value)
    end

    -- Начальные значения: из конфига или по умолчанию.
    local accent = parseHex(saved("accent")) or DEFAULT_ACCENT
    local uiscale = math.clamp(tonumber(saved("uiscale")) or 100, 70, 130)
    local opacity = math.clamp(tonumber(saved("opacity")) or 94, 40, 100)
    local resize = toBool(saved("resize"), true)
    local glow = toBool(saved("glow"), true)
    local language = saved("language") or "en"
    local glass = toBool(saved("glass"), false)
    local glassDark = toBool(saved("glassdark"), true)
    local glassOffset = math.clamp(tonumber(saved("glassoffset")) or 0, -120, 120)
    local unlock = toBool(saved("unlockcur"), true)
    local fsBlur = toBool(saved("fullscreenblur"), false)
    local fsLevel = math.clamp(tonumber(saved("fullblurlevel")) or 12, 2, 40)
    local toggleKey = parseKey(saved("ToggleKey")) or Enum.KeyCode.RightControl

    -- Применяем сразу, до создания элементов.
    window:SetAccent(accent)
    window:SetScale(uiscale / 100)
    window:SetOpacity(1 - opacity / 100)
    window:SetAllowResize(resize)
    window:SetShadowEnabled(glow)
    window:SetLanguage(language)
    window:SetGlassDark(glassDark)
    window:SetGlassOffsetY(glassOffset)
    window:SetGlassEnabled(glass)
    originNew:SetCursorUnlock(unlock)
    originNew:SetBlurSize(fsLevel)
    originNew:SetBlurEnabled(fsBlur)

    remember("accent", toHex(accent))
    remember("ToggleKey", toggleKey.Name)
    remember("uiscale", uiscale)
    remember("opacity", opacity)
    remember("resize", tostring(resize))
    remember("glow", tostring(glow))
    remember("language", language)
    remember("glass", tostring(glass))
    remember("glassdark", tostring(glassDark))
    remember("glassoffset", glassOffset)
    remember("unlockcur", tostring(unlock))
    remember("fullscreenblur", tostring(fsBlur))
    remember("fullblurlevel", fsLevel)
    remember("lib", originNew:GetUILib() or LIB_NAME)
    remember("autoloadme", originNew._autoSave and "yes" or "no")

    -- "Load Settings Now" проходит по этому списку и обновляет элементы.
    local loaders = {}
    local function loader(key, fn) table.insert(loaders, { key = key, fn = fn }) end

    -- ===== Interface =====
    tab:Section("Interface")

    local keyCtl = tab:Keybind(
        { Text = "Menu Toggle Key", Desc = {
            en = "Shows and hides the menu. The eye button hides it too.",
            ru = "Показывает и скрывает меню. Кнопка с глазом тоже его скрывает.",
        } },
        toggleKey,
        function() window:Toggle() end,
        function(key) persist("ToggleKey", key.Name) end
    )
    window._menuKeybind = keyCtl
    loader("ToggleKey", function(raw)
        local key = parseKey(raw)
        if key then keyCtl.SetKey(key) end
    end)

    local accentCtl = tab:ColorPicker(
        { Text = "Accent Color", Desc = {
            en = "Main color of the border, glow, sliders and toggles. Elements on top of it adapt to light colors.",
            ru = "Основной цвет обводки, свечения, ползунков и тогглов. Элементы поверх него подстраиваются под светлые цвета.",
        } },
        accent,
        function(color)
            window:SetAccent(color)
            persist("accent", toHex(color))
        end
    )
    loader("accent", function(raw)
        local color = parseHex(raw)
        if color then accentCtl.SetColor(color) end
    end)

    local scaleCtl = tab:Slider("UI Scale (%)", 70, 130, uiscale, function(value)
        window:SetScale(value / 100)
        persist("uiscale", value)
    end)
    loader("uiscale", function(raw)
        local n = tonumber(raw)
        if n then scaleCtl.SetValue(n) end
    end)

    local opacityCtl = tab:Slider("Window Opacity (%)", 40, 100, opacity, function(value)
        window:SetOpacity(1 - value / 100)
        persist("opacity", value)
    end)
    loader("opacity", function(raw)
        local n = tonumber(raw)
        if n then opacityCtl.SetValue(n) end
    end)

    local resizeCtl = tab:Toggle("Allow Window Resize", resize, function(state)
        window:SetAllowResize(state)
        persist("resize", tostring(state))
    end)
    loader("resize", function(raw) resizeCtl.SetState(toBool(raw, true)) end)

    local glowCtl = tab:Toggle("Window Glow", glow, function(state)
        window:SetShadowEnabled(state)
        persist("glow", tostring(state))
    end)
    loader("glow", function(raw) glowCtl.SetState(toBool(raw, true)) end)

    local languageCtl = tab:Dropdown(
        { Text = "Language", Desc = {
            en = "Language of the function descriptions shown on hover.",
            ru = "Язык описаний функций, которые появляются при наведении.",
        } },
        originNew.Languages,
        language,
        function(code)
            window:SetLanguage(code)
            persist("language", code)
        end
    )
    loader("language", function(raw)
        if raw then languageCtl.SetValue(raw) end
    end)

    -- ===== Glass =====
    tab:Section("Glass")

    local glassCtl = tab:Toggle(
        { Text = "Enable Blur", Desc = {
            en = "Glass mode: the window background turns half transparent and a glass part blurs the scene behind it.",
            ru = "Стеклянный режим: фон окна становится наполовину прозрачным, а парт из стекла размывает сцену за ним.",
        } },
        glass,
        function(state)
            window:SetGlassEnabled(state)
            persist("glass", tostring(state))
        end
    )
    loader("glass", function(raw) glassCtl.SetState(toBool(raw, false)) end)

    local darkCtl = tab:Toggle("Glass Darkness", glassDark, function(state)
        window:SetGlassDark(state)
        persist("glassdark", tostring(state))
    end)
    loader("glassdark", function(raw) darkCtl.SetState(toBool(raw, true)) end)

    local offsetCtl = tab:Slider(
        { Text = "Glass Y Offset", Desc = {
            en = "If the glass sits too high or too low on your screen, move it with this slider.",
            ru = "Если стекло на вашем экране выше или ниже окна, сдвиньте его этим ползунком.",
        } },
        -120, 120, glassOffset,
        function(value)
            window:SetGlassOffsetY(value)
            persist("glassoffset", value)
        end
    )
    loader("glassoffset", function(raw)
        local n = tonumber(raw)
        if n then offsetCtl.SetValue(n) end
    end)

    tab:Notice("Glass needs graphics quality 8 or higher. Below that the blur does not render, use Fullscreen Blur instead.", "warning")

    -- ===== UI lib =====
    tab:Section("UI lib")

    tab:Dropdown("UI lib", UI_LIB_NAMES, originNew:GetUILib() or LIB_NAME, function(selected)
        local ok = originNew:SetUILib(selected)
        if not ok then
            originNew:Notify({
                Title = "UI lib",
                Content = "Could not save the choice. Your executor has no writefile.",
                Type = "error",
                Duration = 5,
            })
        elseif selected ~= LIB_NAME then
            originNew:Notify({
                Title = "UI lib",
                Content = RESTART_MESSAGE,
                Type = "warning",
                Duration = 5,
            })
        end
    end)

    -- ===== Behavior =====
    tab:Section("Behavior")

    local unlockCtl = tab:Toggle("Auto Unlock Cursor", unlock, function(state)
        originNew:SetCursorUnlock(state)
        persist("unlockcur", tostring(state))
    end)
    loader("unlockcur", function(raw) unlockCtl.SetState(toBool(raw, true)) end)

    local blurCtl = tab:Toggle("Fullscreen Blur", fsBlur, function(state)
        originNew:SetBlurEnabled(state)
        persist("fullscreenblur", tostring(state))
    end)
    loader("fullscreenblur", function(raw) blurCtl.SetState(toBool(raw, false)) end)

    local levelCtl = tab:Slider("Fullscreen Blur Intensity", 2, 40, fsLevel, function(value)
        originNew:SetBlurSize(value)
        persist("fullblurlevel", value)
    end)
    loader("fullblurlevel", function(raw)
        local n = tonumber(raw)
        if n then levelCtl.SetValue(n) end
    end)

    -- ===== Config =====
    tab:Section("Config")

    local autoCtl = tab:Toggle(
        { Text = "Auto Load / Save Settings", Desc = {
            en = "On: saved settings load at start and every change is written to the file. Off: use the buttons below.",
            ru = "Включено: сохранённые настройки загружаются при запуске, каждое изменение пишется в файл. Выключено: используйте кнопки ниже.",
        } },
        originNew._autoSave,
        function(state)
            originNew._autoSave = state
            originNew:SetConfig("autoloadme", state and "yes" or "no", true)
        end
    )
    loader("autoloadme", function(raw) autoCtl.SetState(toBool(raw, true)) end)

    tab:Button("Save Settings Now", function()
        if originNew:SaveConfig() then
            originNew:Notify({ Title = "Config", Content = "Saved to " .. CFG_FILE, Type = "success", Duration = 3 })
        else
            originNew:Notify({ Title = "Config", Content = "Could not write the file. Your executor has no writefile.", Type = "error", Duration = 4 })
        end
    end)

    tab:Button("Load Settings Now", function()
        local file = cfgRead()
        local count = 0
        for _, entry in ipairs(loaders) do
            local raw = file[entry.key:lower()]
            if raw ~= nil then
                entry.fn(raw)
                count = count + 1
            end
        end
        originNew:Notify({
            Title = "Config",
            Content = count > 0 and ("Loaded " .. count .. " settings.") or ("No saved settings in " .. CFG_FILE),
            Type = count > 0 and "success" or "warning",
            Duration = 3,
        })
    end)

    tab:Notice("File: " .. CFG_FILE .. " in the executor workspace folder.", "info")

    -- ===== Configs: пресет автора и свои конфиги =====
    tab:Section("Configs")

    local NONE = "(none)"
    local function configOptions()
        local list = {}
        if originNew:HasPreset() then list[#list + 1] = PRESET_NAME end
        for _, n in ipairs(originNew:ListConfigs()) do list[#list + 1] = n end
        if #list == 0 then list[1] = NONE end
        return list
    end
    local function has(list, value)
        for _, v in ipairs(list) do
            if v == value then return true end
        end
        return false
    end

    local options = configOptions()
    local chosen = originNew._cfg.config
    if not chosen or not has(options, chosen) then chosen = options[1] end
    remember("config", chosen)

    local configCtl
    configCtl = tab:Dropdown(
        { Text = "Config", Desc = {
            en = "Pick a config. 'preset by script' holds the settings the script author chose, the others are your own saved configs.",
            ru = "Выберите конфиг. 'preset by script' хранит настройки, которые выбрал автор скрипта, остальные это ваши сохранённые конфиги.",
        } },
        options,
        chosen,
        function(name)
            chosen = name
            persist("config", name)
        end
    )

    local nameBox = tab:TextBox(
        { Text = "Config name", Desc = {
            en = "Name for Save Config. Leave empty to overwrite the selected config.",
            ru = "Имя для Save Config. Оставьте пустым, чтобы перезаписать выбранный конфиг.",
        } },
        "my config",
        function() end
    )

    local function refreshConfigs(select)
        local list = configOptions()
        configCtl.SetOptions(list)
        chosen = has(list, select) and select or list[1]
        configCtl.SetValue(chosen)
    end

    local function applyData(data)
        local count = 0
        for _, entry in ipairs(loaders) do
            local k = entry.key:lower()
            if not CFG_SKIP[k] and data[k] ~= nil then
                entry.fn(data[k])
                count = count + 1
            end
        end
        return count
    end

    local function tell(title, content, kind)
        originNew:Notify({ Title = title, Content = content, Type = kind or "info", Duration = 4 })
    end

    tab:Button("Load Config", function()
        if chosen == NONE then
            tell("Config", "No configs yet. Type a name and press Save Config.", "warning")
        elseif chosen == PRESET_NAME then
            tell("Config", "Preset by script applied (" .. applyData(originNew._preset) .. " settings).", "success")
        else
            local data = originNew:LoadNamedConfig(chosen)
            if not data then
                tell("Config", "Could not read '" .. chosen .. "'.", "error")
            else
                tell("Config", "Loaded '" .. chosen .. "' (" .. applyData(data) .. " settings).", "success")
            end
        end
    end)

    tab:Button("Save Config", function()
        local typed = nameBox.GetText()
        local target = (typed and typed:gsub("%s", "") ~= "") and typed or chosen
        if target == PRESET_NAME or target == NONE then
            tell("Config", "Type a name in Config name first. The preset can not be overwritten.", "warning")
            return
        end
        local name, reason = originNew:SaveNamedConfig(target)
        if name then
            nameBox.SetText("")
            refreshConfigs(name)
            tell("Config", "Saved '" .. name .. "'.", "success")
        else
            tell("Config", "Could not save: " .. tostring(reason) .. ".", "error")
        end
    end)

    tab:Button("Delete Config", function()
        if chosen == PRESET_NAME or chosen == NONE then
            tell("Config", "Select one of your own configs to delete.", "warning")
            return
        end
        local ok, reason = originNew:DeleteNamedConfig(chosen)
        if ok then
            tell("Config", "Deleted '" .. chosen .. "'.", "success")
            refreshConfigs(nil)
        else
            tell("Config", "Could not delete: " .. tostring(reason) .. ".", "error")
        end
    end)

    tab:Button("Refresh Config List", function()
        refreshConfigs(chosen)
    end)

    tab:Notice("Configs are saved in OriginNew/configs. The script author can ship a preset by script.", "info")

    tab:Button("Unload Script", function()
        originNew:Unload()
    end)
end

return originNew
