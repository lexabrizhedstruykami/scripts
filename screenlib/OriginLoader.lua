--[[
  OriginLoader
  Загружает ту библиотеку интерфейса, которую игрок выбрал в настройках
  ("UI lib" в настройках обеих библиотек).

  Откуда берётся выбор, по порядку
    1. строка "lib:origin lib" или "lib:origin new" в OriginNewGuiSettings.cfg
    2. файл originLIB_uilib.txt (старый формат)
    3. getgenv().originLIB_UILib
    4. origin lib по умолчанию

  Использование
    local lib = loadstring(game:HttpGet("URL_К_OriginLoader.lua"))()
    local window = lib:Window({ Title = "My Hub" })

  Замените OWNER/REPO ниже на свои (raw-адреса файлов в репозитории) или
  задайте ссылки до загрузки через getgenv().originLIB_Sources.
  Загрузчик пишет в консоль, какую библиотеку и откуда он грузит.
]]

local SOURCES = {
    ["origin lib"] = "https://raw.githubusercontent.com/lexabrizhedstruykami/scripts/refs/heads/main/screenlib/originlib.lua",
    ["origin new"] = "https://raw.githubusercontent.com/lexabrizhedstruykami/scripts/refs/heads/main/screenlib/OriginNew.lua",
}

local DEFAULT = "origin lib"
local CFG_FILE = "OriginNewGuiSettings.cfg"
local LEGACY_FILE = "originLIB_uilib.txt"

pcall(function()
    local custom = getgenv().originLIB_Sources
    if type(custom) == "table" then
        for name, url in pairs(custom) do SOURCES[name] = url end
    end
end)

local function normalize(value)
    if type(value) ~= "string" then return nil end
    value = value:gsub("^%s+", ""):gsub("%s+$", ""):lower()
    return SOURCES[value] and value or nil
end

local choice, origin
pcall(function()
    if readfile and isfile and isfile(CFG_FILE) then
        for line in (readfile(CFG_FILE) .. "\n"):gmatch("(.-)\r?\n") do
            local key, value = line:match("^%s*([%w_]+)%s*:%s*(.-)%s*$")
            if key and key:lower() == "lib" then
                choice = normalize(value) or choice
                if choice then origin = CFG_FILE end
            end
        end
    end
end)
if not choice then
    pcall(function()
        if readfile and isfile and isfile(LEGACY_FILE) then
            choice = normalize(readfile(LEGACY_FILE))
            if choice then origin = LEGACY_FILE end
        end
    end)
end
if not choice then
    pcall(function()
        choice = normalize(getgenv().originLIB_UILib)
        if choice then origin = "getgenv" end
    end)
end
if not choice then
    choice = DEFAULT
    origin = "default"
end

local function fetchLib(name)
    print("[OriginLoader] " .. name .. " (from " .. tostring(origin) .. ") <- " .. tostring(SOURCES[name]))
    local ok, lib = pcall(function()
        return loadstring(game:HttpGet(SOURCES[name]))()
    end)
    if not ok or type(lib) ~= "table" then
        warn("[OriginLoader] Could not load '" .. name .. "': " .. tostring(lib))
        return nil
    end
    if lib.Name and lib.Name ~= name then
        warn("[OriginLoader] The link for '" .. name .. "' returned '" .. tostring(lib.Name)
            .. "'. Check the SOURCES table.")
    end
    return lib
end

local lib = fetchLib(choice)
if not lib and choice ~= DEFAULT then
    warn("[OriginLoader] Falling back to '" .. DEFAULT .. "'.")
    origin = "fallback"
    lib = fetchLib(DEFAULT)
end
if not lib then
    error("[OriginLoader] Library failed to load. Check the links in SOURCES.")
end

return lib
