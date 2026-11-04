--[[ ==========================================================================
                                 originNEW v1.0
              Новая UI-библиотека для Roblox с тем же API, что у originLIB
     ==========================================================================

  ЧТО ВНУТРИ
    * Те же методы, что у originLIB: Window, Tab, Button, Toggle, Slider,
      TextBox, Keybind, ColorPicker, Dropdown, MultiDropdown, Paragraph,
      Section, Label, Divider, Notice, Notify, ShowIntro, OnUnload, Unload.
      Скрипт, написанный под originLIB, работает и тут без правок.
    * Стиль: анимированная градиентная обводка и свечение окна, плавное
      появление/скрытие, боковая панель с аватаром, поиск по элементам
      текущей вкладки, ripple-эффект на кнопках, переключатели с подсветкой,
      слайдеры с всплывающим значением, HEX-ввод в ColorPicker,
      уведомления с типами (info / success / warning / error).
    * Настройки (вкладка "Settings"): клавиша меню, цвет акцента, масштаб,
      прозрачность, ресайз, выбор UI lib, курсор, размытие экрана, Unload.
    * Выбор библиотеки ("UI lib"): сохраняется в файл originLIB_uilib.txt
      (или в getgenv, если файлы недоступны). Применяется после перезапуска
      скрипта через OriginLoader.lua.

  БЫСТРЫЙ СТАРТ
    local originNew = loadstring(game:HttpGet("URL"))()
    local window = originNew:Window({ Title = "My Hub" })
    local tab = window:Tab("Main")
    tab:Toggle("Auto Farm", false, function(state) print(state) end)

  ОТЛИЧИЯ ОТ originLIB
    * Нет стеклянного парта ("Enable Blur"/"Glass *"): методы
      window:SetGlassEnabled / SetGlassDark / SetGlassOffsetY существуют,
      но ничего не делают. Окно и так полупрозрачное и со свечением.
      window:SetShadowEnabled(bool) включает/выключает свечение.
    * Окно можно масштабировать (window:SetScale) и менять цвет акцента на
      лету (window:SetAccent). Прозрачность: window:SetOpacity(0..1).
    * Поддержка касаний (touch): перетаскивание и слайдеры.

  ИСТОРИЯ ИЗМЕНЕНИЙ
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
    Version = "1.0",
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
local DEFAULT_ACCENT = Color3.fromRGB(128, 92, 255)

local NOTIF_COLORS = {
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

local function accent2Of(c)
    local h, s, v = Color3.toHSV(c)
    return Color3.fromHSV((h + 0.09) % 1, math.clamp(s * 0.85, 0, 1), math.clamp(v * 1.08 + 0.02, 0, 1))
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
    local choice
    pcall(function()
        if readfile and isfile and isfile(UI_LIB_FILE) then
            choice = normalizeChoice(readfile(UI_LIB_FILE))
        end
    end)
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
    pcall(function()
        if writefile then
            writefile(UI_LIB_FILE, name)
            saved = true
        end
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
    self._blurSize = math.clamp(size, 0, 24)
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
    window.Theme = { Accent = DEFAULT_ACCENT, Accent2 = accent2Of(DEFAULT_ACCENT) }

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

    -- Футер: аватар + имя
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
    nameLabel.Size = UDim2.new(1, -68, 0, 16)
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    local tagLabel = text(footer, lp and ("@" .. lp.Name) or "@player", 10, C.Dim, Enum.Font.Gotham)
    tagLabel.Position = UDim2.new(0, 60, 0, 32)
    tagLabel.Size = UDim2.new(1, -68, 0, 14)
    tagLabel.TextTruncate = Enum.TextTruncate.AtEnd
    task.spawn(function()
        pcall(function()
            if lp then
                local img = Players:GetUserThumbnailAsync(lp.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
                if avatar and avatar.Parent then avatar.Image = img end
            end
        end)
    end)

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

    -- Поиск
    local searchBox = create("Frame", {
        Size = UDim2.new(0, 160, 0, 30), Position = UDim2.new(1, -74 - 8 - 160 - 4, 0.5, -15),
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
    window._borderGradient = borderGradient
    window._logoGradient = logoGradient
    window._shadowEnabled = true

    -- ===== Тема =====
    window:_themed(function(a)
        local seq = accentSeq(a)
        borderGradient.Color = seq
        logoGradient.Color = seq
        for _, g in ipairs(glows) do g.gradient.Color = seq end
    end)

    -- ===== Централизованный ввод =====
    local function track(conn)
        table.insert(window.Connections, conn)
        return conn
    end

    track(UserInputService.InputChanged:Connect(function(input)
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
        window.SearchQuery = string.lower(searchInput.Text or "")
        for _, t in ipairs(window.Tabs) do
            t.Tab:_applySearch()
        end
    end)

    -- Кнопки
    closeBtn.MouseButton1Click:Connect(function() window:SetOpen(false) end)
    minBtn.MouseButton1Click:Connect(function() window:SetMinimized(not window._minimized) end)

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
    fn(self.Theme.Accent, self.Theme.Accent2)
end

function Window:SetAccent(color)
    self.Theme.Accent = color
    self.Theme.Accent2 = accent2Of(color)
    for _, fn in ipairs(self._themeFns) do
        safeCall(fn, self.Theme.Accent, self.Theme.Accent2)
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
    tween(self.MainFrame, { BackgroundTransparency = self._opacity }, 0.2)
end

function Window:SetAllowResize(state)
    self._allowResize = state and true or false
    self.Grip.Visible = self._allowResize and not self._minimized
end

function Window:SetMinimized(state)
    state = state and true or false
    if state == self._minimized then return end
    self._minimized = state
    local h = state and 52 or self._size.Y
    tween(self.Holder, { Size = UDim2.new(0, self._size.X, 0, h) }, 0.3)
    self.Grip.Visible = self._allowResize and not state
end

-- Свечение вокруг окна (замена "Window Shadow" из originLIB).
function Window:SetShadowEnabled(state)
    self._shadowEnabled = state and true or false
    for _, g in ipairs(self.Glows) do
        local target = (self._open and self._shadowEnabled) and g.base or 1
        tween(g.frame, { BackgroundTransparency = target }, 0.25)
    end
end

-- Заглушки совместимости со стеклянным парт-режимом originLIB.
function Window:SetGlassEnabled() end
function Window:SetGlassDark() end
function Window:SetGlassOffsetY() end

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
function Window:Tab(name, layoutOrder)
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
    tab.Button = btn

    local function setActive(active)
        if active then
            tween(fill, { BackgroundTransparency = 0.82 }, 0.25)
            tween(marker, { Size = UDim2.new(0, 3, 0, 18) }, 0.35, Enum.EasingStyle.Back)
            tween(label, { TextColor3 = C.Text }, 0.2)
        else
            tween(fill, { BackgroundTransparency = 1 }, 0.2)
            tween(marker, { Size = UDim2.new(0, 3, 0, 0) }, 0.2)
            tween(label, { TextColor3 = C.SubText }, 0.2)
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
        tab:_applySearch()
    end
    tab.Activate = activate

    btn.MouseButton1Click:Connect(activate)
    btn.MouseEnter:Connect(function()
        if window.ActiveTab ~= tab then tween(label, { TextColor3 = C.Text }, 0.15) end
    end)
    btn.MouseLeave:Connect(function()
        if window.ActiveTab ~= tab then tween(label, { TextColor3 = C.SubText }, 0.15) end
    end)

    table.insert(self.Tabs, { Tab = tab, setActive = setActive })

    -- Первая созданная вкладка (кроме Settings) открывается сразу.
    if window.ActiveTab == nil and tab.Name ~= "Settings" then
        activate()
    end

    return tab
end

-- Фильтр по строке поиска: прячет элементы, не подходящие под запрос.
function Tab:_applySearch()
    local q = self.Window.SearchQuery or ""
    for _, item in ipairs(self._items) do
        if q == "" then
            item.frame.Visible = true
        elseif item.kind == "section" or item.kind == "divider" then
            item.frame.Visible = false
        else
            item.frame.Visible = item.name:find(q, 1, true) ~= nil
        end
    end
end

function Tab:_register(frame, name, kind)
    table.insert(self._items, { frame = frame, name = string.lower(tostring(name or "")), kind = kind or "element" })
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
        tween(arrow, { TextColor3 = window.Theme.Accent }, 0.1)
        task.delay(0.2, function()
            if arrow.Parent then tween(arrow, { TextColor3 = C.Dim }, 0.25) end
        end)
        safeCall(callback)
    end)

    self:_register(card, label, "button")
    return { SetText = function(value) title.Text = tostring(value) end }
end

-- Toggle(text, default, callback)
function Tab:Toggle(label, default, callback)
    local window = self.Window
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

    local click = create("TextButton", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 3,
    }, card)

    local function setState(newState)
        state = newState and true or false
        tween(fill, { BackgroundTransparency = state and 0 or 1 }, 0.22)
        tween(knob, { Position = state and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0) }, 0.3, Enum.EasingStyle.Back)
        safeCall(callback, state)
    end

    click.MouseButton1Click:Connect(function() setState(not state) end)

    table.insert(window.Toggles, {
        IsOn = function() return state end,
        SetState = setState,
    })

    self:_register(card, label, "toggle")
    return { SetState = setState, IsOn = function() return state end }
end

-- Slider(text, min, max, default, callback)
function Tab:Slider(label, min, max, default, callback)
    local window = self.Window
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
    end)

    local function applyValue(v, fire)
        v = math.clamp(v, min, max)
        local changed = v ~= value
        value = v
        local f = (v - min) / (max - min)
        fill.Size = UDim2.new(f, 0, 1, 0)
        thumb.Position = UDim2.new(f, 0, 0.5, 0)
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
        tween(valueLabel, { TextColor3 = window.Theme.Accent }, 0.15)
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

    self:_register(card, label, "slider")
    return {
        GetValue = function() return value end,
        SetValue = function(v) applyValue(v, true) end,
    }
end

-- TextBox(text, placeholder, callback)
function Tab:TextBox(label, placeholder, callback)
    local window = self.Window
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

    self:_register(card, label, "textbox")
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

function Tab:Keybind(label, defaultKey, callback)
    local window = self.Window
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
    local pillLabel = text(pill, "", 11, window.Theme.Accent, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
    pillLabel.Size = UDim2.new(1, 0, 1, 0)
    window:_themed(function(a) pillLabel.TextColor3 = a end)

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

    self:_register(card, label, "keybind")
    return {
        GetKey = function() return currentKey end,
        SetKey = setKey,
    }
end

-- ColorPicker(text, defaultColor, callback)
function Tab:ColorPicker(label, defaultColor, callback)
    local window = self.Window
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

    self:_register(card, label, "colorpicker")
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

    local pillLabel = text(pill, "", 11, window.Theme.Accent, Enum.Font.GothamBold)
    pillLabel.Position = UDim2.new(0, 10, 0, 0)
    pillLabel.Size = UDim2.new(1, -30, 1, 0)
    pillLabel.TextTruncate = Enum.TextTruncate.AtEnd
    window:_themed(function(a) pillLabel.TextColor3 = a end)

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
            Size = UDim2.new(0, 6, 0, 6), BackgroundColor3 = window.Theme.Accent,
            BackgroundTransparency = 1, BorderSizePixel = 0,
        }, box)
        corner(mark, multi and 2 or 3)
        window:_themed(function(a) mark.BackgroundColor3 = a end)

        row.MouseEnter:Connect(function() tween(row, { BackgroundColor3 = C.CardHover }, 0.12) end)
        row.MouseLeave:Connect(function() tween(row, { BackgroundColor3 = C.Field }, 0.12) end)

        table.insert(rows, { option = option, mark = mark, label = rowLabel })

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

    tab:_register(card, label, multi and "multidropdown" or "dropdown")

    if multi then
        return {
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

    local title = text(frame, string.upper(tostring(label or "SECTION")), 11, window.Theme.Accent, Enum.Font.GothamBold)
    title.Position = UDim2.new(0, 2, 0, 4)
    title.Size = UDim2.new(1, 0, 0, 16)
    window:_themed(function(a) title.TextColor3 = a end)

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
-- ==========================================
function Window:BuildSettingsTab()
    local window = self
    local tab = window:Tab("Settings", 9999)

    tab:Section("Interface")

    tab:Keybind("Menu Toggle Key", Enum.KeyCode.RightControl, function()
        window:Toggle()
    end)

    tab:ColorPicker("Accent Color", window.Theme.Accent, function(color)
        window:SetAccent(color)
    end)

    tab:Slider("UI Scale (%)", 70, 130, 100, function(value)
        window:SetScale(value / 100)
    end)

    tab:Slider("Window Opacity (%)", 40, 100, 94, function(value)
        window:SetOpacity(1 - value / 100)
    end)

    tab:Toggle("Allow Window Resize", true, function(state)
        window:SetAllowResize(state)
    end)

    tab:Toggle("Window Glow", true, function(state)
        window:SetShadowEnabled(state)
    end)

    tab:Section("UI lib")

    tab:Dropdown("UI lib", UI_LIB_NAMES, originNew:GetUILib() or LIB_NAME, function(selected)
        local saved = originNew:SetUILib(selected)
        if not saved then
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

    tab:Section("Behavior")

    tab:Toggle("Auto Unlock Cursor", originNew._cursorUnlockEnabled, function(state)
        originNew:SetCursorUnlock(state)
    end)

    tab:Toggle("Fullscreen Blur", originNew._blurEnabled, function(state)
        originNew:SetBlurEnabled(state)
    end)

    tab:Slider("Fullscreen Blur Intensity", 2, 40, originNew._blurSize, function(value)
        originNew:SetBlurSize(value)
    end)

    tab:Notice("The glass part is not available in origin new. Use Fullscreen Blur, or switch to origin lib for the glass effect.", "info")

    tab:Button("Unload Script", function()
        originNew:Unload()
    end)
end

return originNew
