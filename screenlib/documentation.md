# Документация originLIB v5.6 и originNEW v1.1

Репозиторий содержит две UI-библиотеки для Roblox-скриптов с одинаковым API элементов, окон и очистки ресурсов.

| Файл | Библиотека | Что внутри |
|---|---|---|
| `originlib.lua` | origin lib v5.6 | Классический интерфейс, стеклянный режим, тема из четырёх цветов |
| `OriginNew.lua` | origin new v1.1 | Новый интерфейс: боковая панель, поиск по названию и описанию, иконки, контакты, меню more, стекло, сохранение настроек |
| `OriginLoader.lua` | загрузчик | Запускает ту библиотеку, которую игрок выбрал в настройках |

Код, написанный под одну библиотеку, работает на другой без изменений. Возможности из раздела 8 (иконки, описания, контакты, more, конфиг) есть только в origin new. В origin lib такие параметры игнорируются, а таблица вместо строки в названии элемента не поддерживается, поэтому для общего кода используйте обычные строки.

## Оглавление

1. [Быстрый старт](#1-быстрый-старт)
2. [Выбор библиотеки (UI lib)](#2-выбор-библиотеки-ui-lib)
3. [Методы библиотеки](#3-методы-библиотеки)
4. [Уведомления](#4-уведомления)
5. [Очистка ресурсов и Unload](#5-очистка-ресурсов-и-unload)
6. [Окна и вкладки](#6-окна-и-вкладки)
7. [Элементы](#7-элементы)
8. [Возможности origin new](#8-возможности-origin-new)
9. [Вкладка настроек origin lib](#9-вкладка-настроек-origin-lib)
10. [Вкладка настроек origin new](#10-вкладка-настроек-origin-new)
11. [Устройство и производительность](#11-устройство-и-производительность)
12. [История изменений](#12-история-изменений)

---

## 1. Быстрый старт

С загрузчиком (подхватит выбор игрока):

```lua
local lib = loadstring(game:HttpGet("URL_К_OriginLoader.lua"))()
local window = lib:Window({ Title = "My Hub" })
local tab = window:Tab("Main")
tab:Toggle("Auto Farm", false, function(state) print(state) end)
```

Напрямую, без выбора:

```lua
local lib = loadstring(game:HttpGet("URL_К_originlib.lua"))()   -- или OriginNew.lua
```

Библиотека ничего не рисует, пока вы не вызовете `lib:Window(...)`.

---

## 2. Выбор библиотеки (UI lib)

В настройках обеих библиотек есть выпадающий список `UI lib` со значениями `origin lib` и `origin new`. После выбора другой библиотеки приходит уведомление `Restart the script to enable other ui lib`. Текущий интерфейс остаётся открытым, новый включится при следующем запуске скрипта.

Выбор хранится в строке `lib:origin new` или `lib:origin lib` файла `OriginNewGuiSettings.cfg` (раздел 8.7). Эту строку пишут обе библиотеки, остальные строки файла они не трогают. Для совместимости запись дублируется в `originLIB_uilib.txt` и в `getgenv().originLIB_UILib`.

Если сохранить не удалось, вместо уведомления о перезапуске приходит уведомление об ошибке.

Загрузчик ищет выбор в таком порядке: строка `lib` в cfg, файл `originLIB_uilib.txt`, `getgenv().originLIB_UILib`, затем origin lib по умолчанию. При каждом запуске он пишет в консоль, какую библиотеку и откуда он грузит. Если ссылка для одной библиотеки вернула другую, он предупреждает об этом, это значит, что ссылки в `SOURCES` перепутаны.

Откройте `OriginLoader.lua`. Откройте его и замените `OWNER/REPO` в таблице `SOURCES` на свой репозиторий. Ссылки можно задать и снаружи, до загрузки:

```lua
getgenv().originLIB_Sources = {
    ["origin lib"] = "https://raw.githubusercontent.com/me/hub/main/originlib.lua",
    ["origin new"] = "https://raw.githubusercontent.com/me/hub/main/OriginNew.lua",
}
```

Если выбранная библиотека не скачалась, загрузчик пишет предупреждение и запускает origin lib. Если не скачалась и она, он выдаёт ошибку.

Обе библиотеки также умеют читать и писать выбор сами:

| Метод | Описание |
|---|---|
| `lib:GetUILib()` | Возвращает `"origin lib"`, `"origin new"` или `nil`, если выбора ещё не было |
| `lib:SetUILib(name)` | Сохраняет выбор. Возвращает `true`, если запись удалась, и `false` для неизвестного имени |

---

## 3. Методы библиотеки

### `lib:ShowIntro(text, duration)`

Показывает плашку при запуске.

| Параметр | Тип | Описание |
|---|---|---|
| `text` | `string` | Заголовок плашки |
| `duration` | `number` | Время показа в секундах |

### Курсор и размытие

```lua
lib:SetCursorUnlock(true)   -- Auto Unlock Cursor
lib:SetBlurEnabled(true)    -- Fullscreen Blur
lib:SetBlurSize(18)         -- сила Fullscreen Blur
```

Пока окно открыто, курсор свободен. Если он уже свободен, библиотека его не трогает. Если игра залочила его (шифтлок, первое лицо), библиотека снимает лок один раз и держит его снятым. При закрытии окна исходное состояние возвращается, но только если его меняла библиотека.

---

## 4. Уведомления

Уведомления общие для всех окон и выезжают в правом нижнем углу.

```lua
lib:Notify({
    Title = "Готово",
    Content = "Действие выполнено.",
    Duration = 4,
    Color = Color3.fromRGB(140, 100, 255),
})
```

| Параметр | Тип | Описание | По умолчанию |
|---|---|---|---|
| `Title` | `string` | Заголовок | `"Notification"` |
| `Content` | `string` | Текст | `""` |
| `Duration` | `number` | Время показа в секундах | `3` |
| `Color` | `Color3` | Цвет акцентной полосы | фиолетовый |
| `Type` | `string` | Только origin new: `info`, `success`, `warning`, `error`. Задаёт цвет, если `Color` не указан | `info` |

В origin new высота карточки зависит от длины текста.

---

## 5. Очистка ресурсов и Unload

Есть два уровня очистки. Глобальная выгружает скрипт целиком, локальная только одно окно.

### Глобальная

`lib:OnUnload(fn)` регистрирует функцию очистки, не привязанную к окну (отключить `RenderStepped`, остановить цикл, убрать ESP). Она выполнится при `lib:Unload()`.

```lua
lib:OnUnload(function()
    if myConnection then myConnection:Disconnect() end
end)
```

`lib:Unload()` выполняет по порядку:

1. Выключает все включённые `Toggle` во всех окнах (каждый получает `callback(false)`).
2. Запускает все `OnUnload`-функции окон и библиотеки.
3. Отключает подключения библиотеки.
4. Удаляет все `ScreenGui`, уведомления и эффекты (размытие, стекло).
5. Возвращает курсор в исходное состояние, если его меняла библиотека.

`lib:UnloadAll()` делает то же самое. Используйте его, если хотите, чтобы в коде было видно, что закрываются все окна.

### Одно окно

`window:OnUnload(fn)` регистрирует функцию для этого окна. `window:Unload()` выгружает только его: выключает его тогглы, запускает его функции, отключает его подключения и удаляет его `ScreenGui`. Уведомления и остальные окна продолжают работать.

```lua
local second = lib:Window({ Title = "Второе окно" })
second:OnUnload(function() print("Закрылось второе окно") end)
second:Unload()
```

---

## 6. Окна и вкладки

```lua
local window = lib:Window({
    Title = "Main UI",
    DisableSettings = false,
})
```

| Параметр | Тип | Описание |
|---|---|---|
| `Title` | `string` | Заголовок окна |
| `DisableSettings` | `boolean` | `true` отключает встроенную вкладку настроек |

Каждое окно независимо: у него своя тема, свои вкладки, свои тогглы и свой `Unload`. Все живые окна лежат в `lib.Windows`.

### Методы окна

| Метод | Описание | origin lib | origin new |
|---|---|---|---|
| `window:Toggle()` | Показать или скрыть окно | да | да |
| `window:Tab(name, order)` | Новая вкладка | да | да |
| `window:OnUnload(fn)` | Очистка этого окна | да | да |
| `window:Unload()` | Выгрузка этого окна | да | да |
| `window:SetShadowEnabled(bool)` | Тень (origin new: свечение) | да | да |
| `window:SetGlassEnabled(bool)` | Стеклянный режим | да | да |
| `window:SetGlassDark(bool)` | Тёмный оттенок стекла | да | да |
| `window:SetGlassOffsetY(px)` | Сдвиг стекла по вертикали | да | да |
| `window:SetAccent(color)` | Акцентный цвет | нет | да |
| `window:SetTitle(text)` | Заголовок | нет | да |
| `window:SetScale(n)` | Масштаб, 0.6 до 1.5 | нет | да |
| `window:SetOpacity(t)` | Прозрачность фона, 0 до 0.9 | нет | да |
| `window:SetAllowResize(bool)` | Разрешить ресайз | нет | да |
| `window:SetMinimized(bool)` | Свернуть до шапки | нет | да |
| `window:SetOpen(bool)` | Открыть или закрыть | нет | да |
| `window:IsOpen()` | Открыто ли окно | нет | да |
| `window:SetIcon(icon)` | Иконка вместо буквы в заголовке | нет | да |
| `window:SetHideIcon(icon, tint)` | Своя иконка кнопки "скрыть" | нет | да |
| `window:SetLanguage(code)` | Язык описаний при наведении | нет | да |
| `window:Contact(kind, url, text, icon)` | Добавить контакт | нет | да |
| `window:More(name, fn, icon)` | Добавить пункт меню more | нет | да |

В origin lib окно двигается за шапку, размер меняется за правый нижний угол. В origin new окно двигается за верхнюю панель, а размер меняется за три точки в правом нижнем углу.

---

## 7. Элементы

Элементы добавляются к вкладке, которую вернул `window:Tab(...)`.

```lua
local mainTab = window:Tab("Main")
```

`Tab:Section(text)` рисует заголовок раздела с линией.

`Tab:Paragraph(title, content)` рисует карточку с заголовком и текстом. В origin new возвращает `{ Set(title, content) }`.

`Tab:Label(text)` рисует строку текста без карточки.

`Tab:Divider()` рисует тонкую линию.

`Tab:Notice(text, color)` рисует карточку-предупреждение с цветной обводкой и возвращает `{ Label, Set(text, color) }`. Цвет задаётся через `Color3`. В origin new можно передать и строку `"info"`, `"success"`, `"warning"` или `"error"`.

```lua
local notice = mainTab:Notice("Внимание", Color3.fromRGB(255, 190, 80))
notice.Set("Всё в порядке", Color3.fromRGB(110, 210, 140))
```

`Tab:Button(text, callback)` рисует кнопку. В origin new при нажатии появляется круговая волна.

```lua
mainTab:Button("Телепорт на спавн", function() print("Телепорт") end)
```

`Tab:Toggle(text, default, callback)` рисует переключатель. Он выключается сам при `Unload`. Возвращает `SetState(bool)` и `IsOn()`.

```lua
local farm = mainTab:Toggle("Авто-фарм", false, function(state) print(state) end)
farm.SetState(true)   -- включить из кода, callback вызовется
```

`Tab:Slider(text, min, max, default, callback)` рисует ползунок с целыми значениями. Возвращает `GetValue()` и `SetValue(v)`.

```lua
mainTab:Slider("Скорость", 16, 120, 16, function(value)
    game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = value
end)
```

`Tab:Dropdown(text, options, default, callback)` рисует список с выбором одного значения. Одновременно открыт только один список в окне. В origin new возвращает `GetValue()` и `SetValue(v)`, в origin lib только `GetValue()`.

```lua
mainTab:Dropdown("Оружие", {"Sword", "Bow", "Staff"}, "Sword", function(selected)
    print(selected)
end)
```

`Tab:MultiDropdown(text, options, defaults, callback)` работает так же, но выбирает несколько значений. Callback получает массив выбранных строк.

`Tab:TextBox(text, placeholder, callback)` рисует поле ввода. Callback срабатывает по Enter.

`Tab:Keybind(text, defaultKey, callback)` привязывает клавишу. Нажмите на кнопку, затем на нужную клавишу. Escape отменяет выбор. Левые и правые Ctrl, Shift и Alt считаются одной клавишей.

```lua
mainTab:Keybind("Скрыть меню", Enum.KeyCode.RightControl, function() window:Toggle() end)
```

`Tab:ColorPicker(text, defaultColor, callback)` рисует выбор цвета: квадрат насыщенности и яркости, полосу оттенка и поле HEX. В origin new возвращает `GetColor()` и `SetColor(c)`.

```lua
mainTab:ColorPicker("Цвет", Color3.fromRGB(140, 100, 255), function(color) print(color) end)
```

---

## 8. Возможности origin new

### 8.1. Акцент и контраст

Акцент по умолчанию Ember Night, `#394F95`. Цвет меняется в настройках или через `window:SetAccent(Color3)`. Элементы подстраиваются под выбранный цвет:

- Буква логотипа, ручка включённого тоггла и ручка слайдера становятся тёмными на светлом акценте (например, белом), чтобы не сливаться с заливкой.
- Второй цвет градиента темнее первого для светлых акцентов и светлее для очень тёмных.
- Текст акцентного цвета (названия разделов, значения в списках) осветляется на тёмных акцентах до читаемой яркости.

### 8.2. Иконки

Иконку можно задать в заголовке, у вкладки, у элемента, у контакта и у пункта more. Принимаются три вида значений:

| Значение | Пример | Что нужно |
|---|---|---|
| Ассет Roblox | `"rbxassetid://123"` или `123` | ничего |
| Ссылка | `"https://example.com/icon.png"` | `getcustomasset`, `writefile`, `HttpGet` или `request` |
| Файл | `"icons/fly.png"` (путь в папке workspace) | `getcustomasset`, `isfile` |

Ссылки скачиваются один раз в `OriginNew/icons` и дальше берутся с диска. Форматы png и jpg. Загрузка идёт в фоне, иконка появляется, когда скачается.

```lua
local window = lib:Window({ Title = "Hub", Icon = "https://example.com/logo.png" })
local tab = window:Tab("Combat", 1, "rbxassetid://123")        -- или window:Tab({ Name = "Combat", Icon = "...", Order = 1 })
tab:Button({ Text = "Fly", Icon = "icons/fly.png" }, function() end)
```

Кнопка скрытия меню по умолчанию рисуется глазом. Свою иконку задайте параметром `HideIcon` окна или методом `window:SetHideIcon("https://.../eye.png", Color3.fromRGB(255, 255, 255))`. Второй аргумент задаёт цвет иконки, по умолчанию она остаётся как есть.

### 8.3. Описания и поиск

В origin new название элемента можно передать таблицей:

```lua
tab:Toggle({
    Text = "Fly",
    Icon = "rbxassetid://123",
    Desc = { en = "Lets you fly", ru = "Позволяет летать" },
}, false, function(state) end)
```

`Desc` это строка или таблица `код языка -> текст`. Описание появляется рядом с курсором при наведении на элемент. Язык выбирается в настройках (список Language) или методом `window:SetLanguage("ru")`. Если нужного языка нет, берётся `en`, затем любой другой.

Поиск в верхней панели ищет по названию и по описаниям на всех языках. Регистр не важен, кириллица тоже. Найденный фрагмент в названии выделяется цветом и жирным шрифтом, результат обновляется с каждой буквой. Если запрос совпал только с описанием, название целиком красится акцентом. Заголовки разделов и разделители при поиске скрываются.

Таблицу вместо строки принимают `Button`, `Toggle`, `Slider`, `TextBox`, `Keybind`, `ColorPicker`, `Dropdown` и `MultiDropdown`.

### 8.4. Кнопки окна и свёрнутый режим

| Кнопка | Действие |
|---|---|
| Крестик | Выгружает меню. Если это последнее окно, выгружается весь скрипт (`lib:Unload()`), иначе только это окно (`window:Unload()`) |
| Минус | Сворачивает окно |
| Глаз | Скрывает окно. Откроется по клавише из настроек, об этом приходит уведомление |

В свёрнутом виде остаются название текущей вкладки и аватар с ником игрока, кнопки управления остаются справа. Название хаба, список вкладок, контакты, поиск и страницы скрываются.

### 8.5. Контакты

Контакты показываются кнопками над разделителем перед аватаром. Клик копирует ссылку в буфер обмена (`setclipboard`) и показывает уведомление. Если буфера нет, уведомление показывает саму ссылку.

```lua
local window = lib:Window({
    Title = "Hub",
    contdsc = "https://discord.gg/yourcommunity",
    conttg = "https://t.me/crow",
    contcustom = "https://example.com/community",
})
```

Порядок кнопок: Discord, Telegram, остальные. Для своих кнопок используйте список `Contacts` или метод:

```lua
lib:Window({ Contacts = {
    "contdsc:https://discord.gg/abc",
    { Kind = "custom", Url = "https://example.com", Text = "Site", Icon = "rbxassetid://123" },
} })
window:Contact("custom", "https://example.com", "Site")
```

### 8.6. Меню more

Справа от ника игрока появляются три вертикальные точки, как только вы добавите хотя бы один пункт. Клик открывает контекстное меню, клик мимо закрывает его.

```lua
window:More("Copy user id", function() setclipboard(tostring(game.Players.LocalPlayer.UserId)) end)
window:More("Rejoin", function() game:GetService("TeleportService"):Teleport(game.PlaceId) end, "rbxassetid://123")

window:More({
    { Name = "Reset character", Callback = function() game.Players.LocalPlayer.Character:BreakJoints() end },
    { Name = "Print hello", Callback = function() print("hello") end },
})
```

### 8.7. Конфиг OriginNewGuiSettings.cfg

Файл лежит в папке workspace executor-а. Каждая строка имеет вид `ключ:значение`. Пример:

```
autoloadme:yes
accent:#394F95
ToggleKey:RightControl
uiscale:122
opacity:78
resize:true
glow:true
lib:origin new
unlockcur:true
fullscreenblur:false
fullblurlevel:40
language:en
glass:false
glassdark:true
glassoffset:0
```

| Ключ | Значение |
|---|---|
| `autoloadme` | `yes`: сохранённые настройки применяются при запуске и каждое изменение пишется в файл. `no`: ни загрузки, ни записи, только кнопки Save Settings Now и Load Settings Now |
| `accent` | hex-цвет |
| `ToggleKey` | имя клавиши (`RightControl`, `F`) или её числовой код (`#305`) |
| `uiscale` | 70 до 130 |
| `opacity` | 40 до 100, непрозрачность окна в процентах |
| `resize`, `glow`, `unlockcur`, `fullscreenblur`, `glass`, `glassdark` | `true` или `false` |
| `fullblurlevel` | 2 до 40 |
| `language` | код языка описаний |
| `glassoffset` | −120 до 120 |
| `config` | имя выбранного в списке Config конфига |
| `lib` | `origin lib` или `origin new`, читает загрузчик. Записывается сразу при выборе, даже при `autoloadme:no` |

Комментарий в скобках после значения (`ToggleKey:RightControl (control)`) игнорируется. Неизвестные строки остаются в файле. Запись идёт с задержкой 0.6 секунды, поэтому перетаскивание слайдера не нагружает диск. Методы: `lib:GetConfig(key)`, `lib:SetConfig(key, value)`, `lib:SaveConfig()`, `lib:LoadConfig()`.

### 8.8. Стеклянный блюр

Режим `Enable Blur` работает так же, как в origin lib. Фон окна становится наполовину прозрачным, под окном появляется парт из стекла в `Workspace.CurrentCamera` (без коллизии), а общий `DepthOfFieldEffect` размывает сцену за ним. Парт следует за окном, его размером и масштабом, и пропадает при скрытии окна. Если стекло сдвинуто относительно окна на вашем мониторе, подправьте `Glass Y Offset`. Режим требует качества графики 8 и выше.

### 8.9. Пресет автора и именованные конфиги

Автор скрипта может задать свои настройки по умолчанию. Они называются пресетом и выбираются в списке Config под именем `preset by script`. Ключи те же, что в cfg. Значения могут быть строками, числами, булевыми, `Color3` и `KeyCode`.

```lua
local window = lib:Window({
    Title = "Hub",
    Preset = {
        accent = Color3.fromRGB(180, 60, 60),
        uiscale = 95,
        language = "ru",
        glow = false,
        ToggleKey = Enum.KeyCode.RightShift,
    },
})
-- или до создания окна: lib:SetPreset({ accent = "#B43C3C" })
```

Порядок значений при запуске такой: сохранённый конфиг (если включён `autoloadme`), затем пресет, затем значения библиотеки. То есть при первом запуске игрок видит настройки автора, а потом свои. Чтобы вернуться к настройкам автора, выберите `preset by script` в списке Config и нажмите Load Config. Ключи `lib`, `autoloadme` и `config` в пресет и в конфиги не входят.

Свои конфиги игрок сохраняет в `OriginNew/configs/<имя>.cfg` в том же формате. Раздел Configs во вкладке настроек:

| Элемент | Действие |
|---|---|
| Config | Список: `preset by script` (если автор его задал) и сохранённые конфиги |
| Config name | Имя для нового конфига. Пустое поле значит перезапись выбранного |
| Load Config | Применяет выбранный конфиг или пресет к элементам |
| Save Config | Сохраняет текущие настройки под именем |
| Delete Config | Удаляет выбранный конфиг (нужен `delfile`) |
| Refresh Config List | Перечитывает папку |

Список строится по `listfiles`. Если у executor-а его нет, имена берутся из `OriginNew/configs/index.txt`, который ведёт библиотека. В имени остаются буквы, цифры, пробел, дефис, точка и подчёркивание, не больше 32 символов.

Автор может добавить в эту вкладку и свои элементы: `window.SettingsTab` это обычная вкладка, например `window.SettingsTab:Toggle("My option", false, cb)`. Они появятся после встроенных.

Методы: `lib:SetPreset(table)`, `lib:GetPreset()`, `lib:HasPreset()`, `lib:ListConfigs()`, `lib:SaveNamedConfig(name, data)`, `lib:LoadNamedConfig(name)`, `lib:DeleteNamedConfig(name)`.

---

## 9. Вкладка настроек origin lib

Вкладка `GUI Settings` создаётся в конце списка, если `DisableSettings` не равен `true`. В ней есть:

- `Menu Toggle Key` меняет клавишу показа и скрытия окна.
- `Allow Window Resize` включает ресайз за правый нижний угол.
- `Accent Color`, `Background Color`, `TopBar Color`, `Element Background` меняют цвета темы на лету.
- `Corner Radius` задаёт радиус скругления от 0 до 12 px.
- `UI lib` переключает библиотеку (раздел 2).
- `Auto Unlock Cursor` включён по умолчанию (раздел 3).
- Предупреждение о графике. При качестве 8 и выше пишет `it's okay`. Ниже 8 пишет, что фоновое размытие не работает и нужно использовать Fullscreen Blur. Шкала 1 до 10 берётся из настроек Roblox и обновляется при смене графики. Если прочитать её не удалось, показывается `unknown`.
- `Enable Blur` включает стеклянный режим. Фон окна становится прозрачным на 50%, а под окном появляется `Part` из стекла (`Transparency = 0.3`, без коллизии) по размеру окна. Парт лежит в `Workspace.CurrentCamera`, двигается и масштабируется вместе с окном и следует за камерой. Размытие строится на `DepthOfFieldEffect`, один на все окна.
- `Window Shadow` включает обычную тень. Её положение берётся из `Position` и `Size` окна, поэтому она не съезжает при разных инсетах.
- `Glass Darkness` включает тёмный оттенок стекла (`0.3`). Выключенное стекло почти прозрачное (`0.98`), размытие остаётся.
- `Glass Y Offset` сдвигает стекло по вертикали от −120 до 120 px. Он нужен, если на вашем мониторе стекло уехало вверх или вниз.
- Notice про баги после обновлений и про подстройку `Glass Y Offset`.
- `Fullscreen Blur` и `Fullscreen Blur Intensity` размывают весь экран через `Lighting.BlurEffect`.

Configs

- Список `Config`, поле `Config name` и кнопки Load Config, Save Config, Delete Config, Refresh Config List (раздел 8.9).
- `Unload Script` вызывает `lib:Unload()`.

Методы для тех же настроек:

```lua
window:SetGlassEnabled(true)
window:SetShadowEnabled(false)
window:SetGlassDark(false)
window:SetGlassOffsetY(10)
```

Константы стекла (`GLASS_PART_TRANSPARENCY`, `GLASS_WINDOW_TRANSPARENCY`, `GLASS_DISTANCE`) лежат в начале `originlib.lua`.

Геометрию парта (размер, позицию, отсутствие коллизии) я проверил на эмуляторе API. Как стекло и размытие выглядят в самом Roblox, зависит от версии рендера и графики клиента, и я это в игре не проверял.

---

## 10. Вкладка настроек origin new

Вкладка `Settings` стоит последней в боковой панели. Тогглы этой вкладки не выключаются при выгрузке скрипта, а значения всех элементов сохраняются в конфиг (раздел 8.7). Разделы:

Interface

- `Menu Toggle Key` (по умолчанию RightControl).
- `Accent Color` меняет цвет обводки, свечения, тогглов, ползунков и активной вкладки.
- `UI Scale (%)` от 70 до 130.
- `Window Opacity (%)` от 40 до 100.
- `Allow Window Resize`.
- `Window Glow` включает и выключает свечение вокруг окна.
- `Language` задаёт язык описаний при наведении.

Glass

- `Enable Blur` включает стеклянный режим.
- `Glass Darkness` включает тёмный оттенок стекла.
- `Glass Y Offset` сдвигает стекло по вертикали.
- Предупреждение о том, что стеклу нужна графика 8 и выше.

UI lib

- `UI lib` переключает библиотеку (раздел 2).

Behavior

- `Auto Unlock Cursor`.
- `Fullscreen Blur` и `Fullscreen Blur Intensity` (от 2 до 40).

Config

- `Auto Load / Save Settings` (ключ `autoloadme`).
- `Save Settings Now` пишет текущие значения в файл.
- `Load Settings Now` читает файл и применяет значения к элементам.
- `Unload Script` вызывает `lib:Unload()`.

---

## 11. Устройство и производительность

- Окно держит три подключения к `UserInputService` (`InputChanged`, `InputEnded`, `InputBegan`) и само раздаёт события слайдерам, цветовым пикерам и кейбиндам. Новые элементы подключений к сервису не добавляют.
- Кейбинды лежат в таблице `[KeyCode] -> {callback, ...}`, поэтому нажатие клавиши обрабатывается за одну выборку.
- Все подключения, которые пережили бы свой `Instance`, окно запоминает и отключает при `Unload`.
- Каждый пользовательский callback вызывается через `pcall`. Ошибка в одном не прерывает очистку.
- Проверка курсора на `RenderStepped` существует только пока открыто хотя бы одно окно.
- В шрифте Gotham нет многих символов Юникода, поэтому в интерфейсе только ASCII. Иконки origin new нарисованы рамками.

---

## 12. История изменений

### origin new v1.1

- Исправлена ошибка `attempt to call a Instance value` при создании окна: поле `tab.Button` перекрывало метод `Tab:Button`, и вкладка настроек не достраивалась. Поле теперь называется `tab.TabButton`.
- Тогглы настроек не выключаются при `Unload` и не затирают конфиг.
- Конфиг `OriginNewGuiSettings.cfg`, строка `lib` в нём выбирает библиотеку для загрузчика.
- Акцент по умолчанию `#394F95`, подстройка логотипа, ручек и текста под любой акцент.
- Иконки (ассет, ссылка, файл), описания на нескольких языках, поиск по описанию с подсветкой.
- Контакты, меню more, кнопки "глаз", "минус", "крестик", свёрнутый режим.
- Стеклянный блюр, плавные слайдеры.
- Пресет автора скрипта (`Preset` в параметрах окна, `lib:SetPreset`), список конфигов в настройках: `preset by script` и свои конфиги в `OriginNew/configs`.
- Выпадающие списки умеют менять варианты на лету (`SetOptions`), у кнопок есть `Click()`, у окна есть `window.SettingsTab`.

### origin lib v5.6

- Выпадающий список `UI lib` в настройках, сообщение `Restart the script to enable other ui lib`, методы `GetUILib` и `SetUILib`.

### origin new v1.0

- Первая версия. Боковая панель вкладок, строка поиска, анимированная градиентная обводка, двухслойное свечение, аватар игрока в нижней части панели.
- Элементы совместимы по API с origin lib. Notify получил поле `Type`, Notice принимает строку типа.
- Круговая волна на кнопках, ползунок увеличивает ручку при перетаскивании.
- Стеклянного режима нет, методы стекла пустые.

### origin lib v5.5

- Тень съезжала вверх примерно на 58 px. Теперь она повторяет `Position` и `Size` окна.
- Положение стекла считается из `Position`, `Size` и области `ScreenGui`.
- Тоггл `Window Shadow` и метод `window:SetShadowEnabled`. Тень больше не скрывается при включённом стекле.
- Второй Notice в настройках.

### origin lib v5.4

- Тоггл `Glass Darkness`, слайдер `Glass Y Offset`.
- Предупреждение о качестве графики с порогом 8.
- Элемент `Tab:Notice`.

### origin lib v5.3

- Логика курсора переписана: свободный курсор не трогается, лок снимается только когда курсор закрыт, исходное состояние возвращается только если его меняла библиотека.
- Тоггл `Auto Unlock Cursor`, метод `SetCursorUnlock`.
- Тоггл `Enable Blur` и метод `window:SetGlassEnabled`.
- `Background Blur` и `Blur Intensity` переименованы в `Fullscreen Blur` и `Fullscreen Blur Intensity`.
- `ScreenGui` окна использует `IgnoreGuiInset = true`.

### origin lib v5.2

- Размытие всего экрана через `Lighting.BlurEffect` с настройкой силы.

### origin lib v5.1

- Новый стиль: тень и свечение, градиент шапки, круглые кнопки окна, индикатор активной вкладки, переключатель в форме таблетки, ползунок с круглой ручкой, HEX в пикере, анимированные списки.
- Тень скрывается вместе с окном. Юникод-символы заменены на ASCII, потому что в Gotham они отображались квадратами.
- Левый и правый Ctrl, Shift и Alt работают как одна клавиша. Пока окно открыто, курсор свободен.

### origin lib v5.0

- Несколько независимых окон, `window:OnUnload`, `window:Unload`, `lib:UnloadAll`.
- Элементы `Label`, `Divider`, `MultiDropdown`.
- Один набор подключений к `UserInputService` на окно, кейбинды через таблицу.
- Исправлены состояние `Toggle` при `Unload`, область нажатия `Slider`, отмена захвата в `Keybind`.
- Callback-и и `OnUnload`-функции обёрнуты в `pcall`. Демо-интерфейс больше не появляется при `loadstring`.

### origin lib v4.0

- Первая версия: базовые элементы, уведомления, вступительная плашка, вкладка настроек.
