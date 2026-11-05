--[[
  OriginLoader
  Загружает ту библиотеку интерфейса, которую игрок выбрал в настройках
  ("UI lib" в GUI Settings). Выбор хранится в файле originLIB_uilib.txt,
  а если writefile недоступен, то в getgenv().originLIB_UILib.

  Использование
    local lib = loadstring(game:HttpGet("URL_К_OriginLoader.lua"))()
    local window = lib:Window({ Title = "My Hub" })

  Замените ссылки ниже на свои (raw-адреса файлов в репозитории) или
  задайте их до загрузки через getgenv().originLIB_Sources.
]]

local SOURCES = {
    ["origin lib"] = "https://raw.githubusercontent.com/OWNER/REPO/main/originlib.lua",
    ["origin new"] = "https://raw.githubusercontent.com/OWNER/REPO/main/OriginNew.lua",
}

local DEFAULT = "origin lib"
local PREF_FILE = "originLIB_uilib.txt"

pcall(function()
    local custom = getgenv().originLIB_Sources
    if type(custom) == "table" then
        for name, url in pairs(custom) do SOURCES[name] = url end
    end
end)

local function normalize(value)
    if type(value) ~= "string" then return nil end
    value = value:lower():gsub("^%s+", ""):gsub("%s+$", "")
    return SOURCES[value] and value or nil
end

local choice
pcall(function()
    if readfile and isfile and isfile(PREF_FILE) then
        choice = normalize(readfile(PREF_FILE))
    end
end)
if not choice then
    pcall(function() choice = normalize(getgenv().originLIB_UILib) end)
end
choice = choice or DEFAULT

local ok, lib = pcall(function()
    return loadstring(game:HttpGet(SOURCES[choice]))()
end)

if not ok or type(lib) ~= "table" then
    warn("[OriginLoader] Could not load '" .. choice .. "': " .. tostring(lib))
    if choice ~= DEFAULT then
        warn("[OriginLoader] Falling back to '" .. DEFAULT .. "'.")
        lib = loadstring(game:HttpGet(SOURCES[DEFAULT]))()
    else
        error("[OriginLoader] Library failed to load.")
    end
end

return lib
