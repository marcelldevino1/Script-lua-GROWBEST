local ROLES_PATH = ROLES_DATA.roles_path
local PLAYERS_DIR = ROLES_DATA.players_dir

local function getTheme()
  return GB_THEME or {
    bg = "72,28,38,235",
    border = "178,112,126,255",
    frame = "staticYellowFrame",
    textColor = "`w",
    accent = "`c",
    danger = "`4"
  }
end

local function themeHeader()
  local t = getTheme()
  return "set_default_color|" .. t.textColor
    .. "\nset_bg_color|" .. t.bg .. "|\n"
    .. "set_border_color|" .. t.border .. "|\n"
    .. "set_custom_spacing|x:6;y:4|\n"
    .. "add_quick_exit|\n"
end

local function readFile(path)
  local f = io.open(path, "r")
  if not f then
    return nil
  end
  local data = f:read("*a")
  f:close()
  return data
end

local function writeFileAtomic(path, data)
  local tmp = path .. ".tmp"
  local f = io.open(tmp, "w")
  if not f then
    return false
  end
  f:write(data)
  f:close()
  local ok = os.rename(tmp, path)
  if not ok then
    os.remove(path)
    ok = os.rename(tmp, path)
  end
  return ok == true or ok ~= nil
end

local function jsonDecode(text)
  local pos = 1
  local len = string.len(text)
  local function skipWs()
    while pos <= len do
      local c = string.sub(text, pos, pos)
      if c == " " or c == "\t" or c == "\n" or c == "\r" then
        pos = pos + 1
      else
        break
      end
    end
  end
  local parseValue
  local function parseString()
    pos = pos + 1
    local out = {}
    while pos <= len do
      local c = string.sub(text, pos, pos)
      if c == '"' then
        pos = pos + 1
        return table.concat(out)
      end
      if c == "\\" then
        pos = pos + 1
        local e = string.sub(text, pos, pos)
        if e == "n" then
          table.insert(out, "\n")
        elseif e == "t" then
          table.insert(out, "\t")
        elseif e == "r" then
          table.insert(out, "\r")
        elseif e == "b" then
          table.insert(out, "\b")
        elseif e == "f" then
          table.insert(out, "\f")
        elseif e == "u" then
          local hex = string.sub(text, pos + 1, pos + 4)
          local code = tonumber(hex, 16) or 63
          if code < 128 then
            table.insert(out, string.char(code))
          elseif code < 2048 then
            table.insert(out, string.char(192 + math.floor(code / 64), 128 + (code % 64)))
          else
            table.insert(out, string.char(224 + math.floor(code / 4096), 128 + (math.floor(code / 64) % 64), 128 + (code % 64)))
          end
          pos = pos + 4
        else
          table.insert(out, e)
        end
        pos = pos + 1
      else
        table.insert(out, c)
        pos = pos + 1
      end
    end
    error("unterminated string")
  end
  local function parseNumber()
    local start = pos
    while pos <= len do
      local c = string.sub(text, pos, pos)
      if string.find("0123456789+-.eE", c, 1, true) then
        pos = pos + 1
      else
        break
      end
    end
    local num = tonumber(string.sub(text, start, pos - 1))
    if num == nil then
      error("bad number")
    end
    return num
  end
  local function parseArray()
    pos = pos + 1
    local arr = {}
    skipWs()
    if string.sub(text, pos, pos) == "]" then
      pos = pos + 1
      return arr
    end
    while true do
      local v = parseValue()
      table.insert(arr, v)
      skipWs()
      local c = string.sub(text, pos, pos)
      if c == "," then
        pos = pos + 1
      elseif c == "]" then
        pos = pos + 1
        return arr
      else
        error("bad array")
      end
    end
  end
  local function parseObject()
    pos = pos + 1
    local obj = {}
    skipWs()
    if string.sub(text, pos, pos) == "}" then
      pos = pos + 1
      return obj
    end
    while true do
      skipWs()
      local k = parseString()
      skipWs()
      if string.sub(text, pos, pos) ~= ":" then
        error("bad object")
      end
      pos = pos + 1
      local v = parseValue()
      obj[k] = v
      skipWs()
      local c = string.sub(text, pos, pos)
      if c == "," then
        pos = pos + 1
      elseif c == "}" then
        pos = pos + 1
        return obj
      else
        error("bad object")
      end
    end
  end
  parseValue = function()
    skipWs()
    local c = string.sub(text, pos, pos)
    if c == "{" then
      return parseObject()
    end
    if c == "[" then
      return parseArray()
    end
    if c == '"' then
      return parseString()
    end
    if c == "t" and string.sub(text, pos, pos + 3) == "true" then
      pos = pos + 4
      return true
    end
    if c == "f" and string.sub(text, pos, pos + 4) == "false" then
      pos = pos + 5
      return false
    end
    if c == "n" and string.sub(text, pos, pos + 3) == "null" then
      pos = pos + 4
      return nil
    end
    return parseNumber()
  end
  local value = parseValue()
  skipWs()
  return value
end

local function jsonEscape(s)
  s = string.gsub(s, "\\", "\\\\")
  s = string.gsub(s, '"', '\\"')
  s = string.gsub(s, "\n", "\\n")
  s = string.gsub(s, "\r", "\\r")
  s = string.gsub(s, "\t", "\\t")
  return s
end

local function isArray(t)
  local n = 0
  for k in pairs(t) do
    if type(k) ~= "number" then
      return false
    end
    n = n + 1
  end
  for i = 1, n do
    if t[i] == nil then
      return false
    end
  end
  return true
end

local function jsonEncode(v)
  local tv = type(v)
  if tv == "nil" then
    return "null"
  end
  if tv == "boolean" then
    if v then
      return "true"
    end
    return "false"
  end
  if tv == "number" then
    return tostring(v)
  end
  if tv == "string" then
    return '"' .. jsonEscape(v) .. '"'
  end
  if tv == "table" then
    if isArray(v) then
      local parts = {}
      for i = 1, #v do
        table.insert(parts, jsonEncode(v[i]))
      end
      return "[" .. table.concat(parts, ",") .. "]"
    end
    local parts = {}
    local keys = {}
    for k in pairs(v) do
      table.insert(keys, k)
    end
    table.sort(keys)
    for i = 1, #keys do
      local k = keys[i]
      table.insert(parts, '"' .. jsonEscape(tostring(k)) .. '":' .. jsonEncode(v[k]))
    end
    return "{" .. table.concat(parts, ",") .. "}"
  end
  return "null"
end

local function readJson(path)
  local raw = readFile(path)
  if not raw or raw == "" then
    return nil
  end
  return jsonDecode(raw)
end

local function queueEngineCommand(cmd, player)
  local fn = _G.queueEngineCommand
  if fn == nil then
    return false
  end
  if player ~= nil and player ~= "" then
    return fn(cmd, player) == true
  end
  return fn(cmd) == true
end

local function lower(s)
  return string.lower(s or "")
end

local function findPlayerFile(name)
  local exact = PLAYERS_DIR .. "/" .. name .. "_.json"
  local f = io.open(exact, "r")
  if f then
    f:close()
    return exact, name
  end
  local handle = io.popen('ls "' .. PLAYERS_DIR .. '" 2>/dev/null')
  if handle then
    for line in handle:lines() do
      local base = string.match(line, "^(.*)_.json$")
      if base and lower(base) == lower(name) then
        handle:close()
        return PLAYERS_DIR .. "/" .. line, base
      end
    end
    handle:close()
  end
  return nil, nil
end

local function loadRoles()
  local doc = readJson(ROLES_PATH)
  if type(doc) ~= "table" or type(doc.roles) ~= "table" then
    return nil
  end
  return doc
end

local function findRole(doc, roleId)
  for i = 1, #doc.roles do
    local r = doc.roles[i]
    if type(r) == "table" and tostring(r.id) == tostring(roleId) then
      return r
    end
  end
  return nil
end

local function getPlayerCurrentRoleId(doc, canonical)
  for i = 1, #doc.roles do
    local r = doc.roles[i]
    if type(r) == "table" and type(r.growids) == "table" then
      for j = 1, #r.growids do
        if lower(r.growids[j]) == lower(canonical) then
          return tostring(r.id)
        end
      end
    end
  end
  return "0"
end

local function grantTitleToOnlinePlayer(target, title)
  if not target or title == nil or title == "" then
    return false
  end
  local titles = target:getActiveTitles()
  for i = 1, #titles do
    if titles[i] == title then
      return false
    end
  end
  target:addTitle(title)
  return true
end

local function grantTitleToOfflinePlayer(path, title)
  if title == nil or title == "" then
    return false
  end
  local doc = readJson(path)
  if type(doc) ~= "table" then
    return false
  end
  if type(doc.custom_titles) ~= "table" then
    doc.custom_titles = {}
  end
  for i = 1, #doc.custom_titles do
    if doc.custom_titles[i] == title then
      return false
    end
  end
  table.insert(doc.custom_titles, title)
  return writeFileAtomic(path, jsonEncode(doc))
end

local function applyRoleTitles(target, doc, growid)
  local granted = {}
  for i = 1, #doc.roles do
    local r = doc.roles[i]
    if type(r) == "table" and type(r.growids) == "table" and type(r.title) == "string" and r.title ~= "" then
      for j = 1, #r.growids do
        if lower(r.growids[j]) == lower(growid) then
          if grantTitleToOnlinePlayer(target, r.title) then
            table.insert(granted, r.title)
          end
          break
        end
      end
    end
  end
  return granted
end

local function assignPlayerRole(adminPlayer, canonical, path, targetRoleId)
  local doc = loadRoles()
  if not doc then
    adminPlayer:onConsoleMessage("`4Role data not found: database/json/roles.json")
    return false
  end

  local role = nil
  if targetRoleId ~= "0" and targetRoleId ~= "none" then
    role = findRole(doc, targetRoleId)
    if not role then
      adminPlayer:onConsoleMessage("`4Role '" .. tostring(targetRoleId) .. "' does not exist in database/json/roles.json")
      return false
    end
  end

  for i = 1, #doc.roles do
    local r = doc.roles[i]
    if type(r) == "table" and type(r.growids) == "table" then
      local kept = {}
      for j = 1, #r.growids do
        if lower(r.growids[j]) ~= lower(canonical) then
          table.insert(kept, r.growids[j])
        end
      end
      r.growids = kept
    end
  end

  if role ~= nil then
    if type(role.growids) ~= "table" then
      role.growids = {}
    end
    table.insert(role.growids, canonical)
  end

  if not writeFileAtomic(ROLES_PATH, jsonEncode(doc)) then
    adminPlayer:onConsoleMessage("`4Failed to write database/json/roles.json")
    return false
  end

  local target = nil
  if getPlayerByName then
    target = getPlayerByName(canonical)
  end

  if role ~= nil and type(role.title) == "string" and role.title ~= "" then
    if target then
      grantTitleToOnlinePlayer(target, role.title)
    else
      grantTitleToOfflinePlayer(path, role.title)
    end
  end

  queueEngineCommand("reload_roles")
  queueEngineCommand("update_role", canonical)

  if role ~= nil then
    local msg = "`2Role '" .. tostring(role.name or role.id) .. "' (" .. tostring(role.id) .. ") assigned to " .. canonical
    if type(role.title) == "string" and role.title ~= "" then
      msg = msg .. " with title '" .. role.title .. "'"
    end
    adminPlayer:onConsoleMessage(msg)
  else
    adminPlayer:onConsoleMessage("`2Custom role cleared on " .. canonical .. " (set to Default).")
  end

  return true
end

local function showSetRoleSearchDialog(p)
  local t = getTheme()
  local tc = t.textColor

  local d = themeHeader()
    .. "add_label_with_icon|big|" .. tc .. "Give / Remove Role|left|1092|\n"
    .. "add_smalltext|" .. tc .. "Enter target player GrowID to view and manage their server role.|left|\n"
    .. "add_spacer|small|\n"
    .. "add_text_input|target_growid|" .. tc .. "Player GrowID:|" .. p:getName() .. "|24|\n"
    .. "add_spacer|small|\n"
    .. "end_dialog|gb_setrole_search|Cancel|Open Role Manager"
  p:onDialogRequest(d)
end

local function showSetRoleMainDialog(p, canonical)
  local doc = loadRoles()
  if not doc then
    p:onConsoleMessage("`4Role data not found: database/json/roles.json")
    return
  end

  local t = getTheme()
  local tc = t.textColor
  local ac = t.accent

  local currentRoleId = getPlayerCurrentRoleId(doc, canonical)
  local onlineTarget = nil
  if getPlayerByName then
    onlineTarget = getPlayerByName(canonical)
  end
  local statusText = "`9OFFLINE"
  if onlineTarget then
    statusText = "`2ONLINE"
  end

  local sortedRoles = {}
  for i = 1, #doc.roles do
    local r = doc.roles[i]
    if type(r) == "table" and tostring(r.id) ~= "0" then
      table.insert(sortedRoles, r)
    end
  end
  table.sort(sortedRoles, function(a, b)
    return (tonumber(a.level) or 0) > (tonumber(b.level) or 0)
  end)

  local d = themeHeader()
    .. "text_scaling_string|WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW|\n"
    .. "add_label_with_icon|big|" .. tc .. "Give / Remove - Role (" .. ac .. canonical .. tc .. ")|left|1092|\n"
    .. "add_smalltext|" .. tc .. "Target Player: " .. ac .. canonical .. tc .. "  -  Status: " .. statusText .. tc .. "  -  Active Role ID: " .. ac .. currentRoleId .. "|\n"
    .. "add_spacer|small|\n"
    .. "add_label|medium|" .. ac .. "- Role Info -|left|\n"

  if #sortedRoles == 0 then
    d = d .. "add_smalltext|" .. tc .. "- No custom roles configured in dashboard yet.|\n"
  end

  for i = 1, #sortedRoles do
    local r = sortedRoles[i]
    local rId = tostring(r.id)
    local rName = tostring(r.name or rId)
    local rLvl = tostring(r.level or 0)
    local badge = tc .. "[`4NO" .. tc .. "]"
    if rId == currentRoleId then
      badge = tc .. "[`2YES" .. tc .. "]"
    end
    d = d .. "add_smalltext|" .. tc .. "- " .. rName .. " (ID: " .. ac .. rId .. tc .. ", Lv." .. rLvl .. "): " .. badge .. "|\n"
  end

  d = d .. "add_spacer|small|\n"
    .. "add_label|medium|" .. ac .. "Select Role (Single Active Role):|left|\n"

  for i = 1, #sortedRoles do
    local r = sortedRoles[i]
    local rId = tostring(r.id)
    local rName = tostring(r.name or rId)
    local rLvl = tostring(r.level or 0)
    local checked = "0"
    if rId == currentRoleId then
      checked = "1"
    end
    local prefixTag = ""
    if type(r.prefix) == "string" and r.prefix ~= "" then
      prefixTag = " " .. tc .. "(" .. r.prefix .. tc .. ")"
    end
    d = d .. "add_checkbox|role_chk_" .. rId .. "|" .. tc .. rName .. prefixTag .. " `9[ID: " .. rId .. " - Lv." .. rLvl .. "]|" .. checked .. "|\n"
  end

  local isDefault = "0"
  if currentRoleId == "0" then
    isDefault = "1"
  end

  d = d .. "add_checkbox|role_chk_0|`4[None / Clear to Default Role]|" .. isDefault .. "|\n"
    .. "add_spacer|small|\n"
    .. "embed_data|target_canonical|" .. canonical .. "\n"
    .. "end_dialog|gb_setrole_main|Nevermind|Apply Changes"

  p:onDialogRequest(d)
end

local function handleSetRoleDialog(w, p, data, raw)
  local name = GB.dialog_name(data, raw)
  local btn = GB.button_clicked(data, raw)

  if name == "gb_setrole_search" then
    if btn == "Cancel" or btn == "Close" or btn == "" then
      return true
    end

    if p:getRoleLevel() < 4 then
      p:onConsoleMessage("`4You don't have permission to use /setrole.")
      return true
    end

    local growid = tostring(data.target_growid or ""):match("^%s*(%S+)%s*$")
    if not growid or growid == "" then
      p:onConsoleMessage("`4Please enter a valid player GrowID.")
      return true
    end

    local path, canonical = findPlayerFile(growid)
    if not path then
      p:onConsoleMessage("`4Player '" .. growid .. "' not found in database/players.")
      return true
    end

    showSetRoleMainDialog(p, canonical)
    return true
  end

  if name == "gb_setrole_main" then
    if btn == "Nevermind" or btn == "Close" or btn == "" then
      return true
    end

    if p:getRoleLevel() < 4 then
      p:onConsoleMessage("`4You don't have permission to use /setrole.")
      return true
    end

    local canonical = tostring(data.target_canonical or GB.embed_value(raw, "target_canonical") or ""):match("^%s*(%S+)%s*$")
    if not canonical or canonical == "" then
      return true
    end

    local path, resolvedCanonical = findPlayerFile(canonical)
    if not path then
      p:onConsoleMessage("`4Player '" .. canonical .. "' not found in database/players.")
      return true
    end

    local doc = loadRoles()
    if not doc then
      p:onConsoleMessage("`4Role data not found: database/json/roles.json")
      return true
    end

    local currentRoleId = getPlayerCurrentRoleId(doc, resolvedCanonical)
    local selectedRoleId = nil

    if tostring(data["role_chk_0"] or "") == "1" and currentRoleId ~= "0" then
      selectedRoleId = "0"
    end

    if selectedRoleId == nil then
      for i = 1, #doc.roles do
        local r = doc.roles[i]
        if type(r) == "table" and tostring(r.id) ~= "0" then
          local rId = tostring(r.id)
          if tostring(data["role_chk_" .. rId] or "") == "1" and rId ~= currentRoleId then
            selectedRoleId = rId
            break
          end
        end
      end
    end

    if selectedRoleId == nil then
      if currentRoleId ~= "0" and tostring(data["role_chk_" .. currentRoleId] or "") == "1" then
        selectedRoleId = currentRoleId
      else
        selectedRoleId = "0"
      end
    end

    assignPlayerRole(p, resolvedCanonical, path, selectedRoleId)
    showSetRoleMainDialog(p, resolvedCanonical)
    return true
  end

  return false
end

onDialog(handleSetRoleDialog)

registerLuaCommand({
  command = "/setrole",
  description = "Open role manager UI or assign a dashboard role to a player",
  roleRequired = 4,
  callback = function(p, args)
    local cleanArgs = (args or ""):match("^%s*(.-)%s*$")

    if cleanArgs == "" then
      showSetRoleSearchDialog(p)
      return
    end

    local onlyGrowid = cleanArgs:match("^(%S+)$")
    if onlyGrowid then
      local path, canonical = findPlayerFile(onlyGrowid)
      if not path then
        p:onConsoleMessage("`4Player '" .. onlyGrowid .. "' not found in database/players.")
        return
      end
      showSetRoleMainDialog(p, canonical)
      return
    end

    local growid, roleId = string.match(cleanArgs, "^(%S+)%s+(%S+)$")
    if not growid or not roleId then
      p:onConsoleMessage("Usage: /setrole <growid> [roleId]")
      return
    end

    local path, canonical = findPlayerFile(growid)
    if not path then
      p:onConsoleMessage("`4Player '" .. growid .. "' not found in database/players.")
      return
    end

    assignPlayerRole(p, canonical, path, roleId)
  end
})

onPlayerLoginCallback(function(p)
  local doc = loadRoles()
  if not doc then
    return
  end
  applyRoleTitles(p, doc, p:getName())
end)

GB.register("cmd-setrole", {
  version = 2,
  category = "roles",
  dialogs = { "gb_setrole_search", "gb_setrole_main" }
})