_SHARED_TILE_PENDING = _SHARED_TILE_PENDING or {}
local function tile_register(kind, key, fn)
  _SHARED_TILE_PENDING[#_SHARED_TILE_PENDING + 1] = { kind = kind, key = key, fn = fn }
end

local SLOTS_PER_LEVEL = 10

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
  return "set_default_color|" .. t.textColor .. "\nset_bg_color|" .. t.bg .. "|\nset_border_color|" .. t.border .. "|\nadd_quick_exit|\n"
end

GB.showBackpackDialog = function(p)
  local t = getTheme()
  local tc = t.textColor
  local ac = t.accent

  local level = p:getBackpackLevel()
  if level < 1 then
    level = 1
  end
  local slotMax = level * SLOTS_PER_LEVEL

  local rawItems = p:getBackpackItems() or {}
  local items = {}
  for i = 1, #rawItems do
    if rawItems[i].id ~= 0 and rawItems[i].count ~= 0 then
      items[#items + 1] = rawItems[i]
    end
  end

  table.sort(items, function(a, b)
    return a.id < b.id
  end)

  local usedSlots = #items
  local freeSlots = math.max(0, slotMax - usedSlots)
  local listItems = ""

  -- 1. Tampilkan item yang tersimpan (jika ada)
  for i = 1, usedSlots do
    local itemID = items[i].id
    local amount = items[i].count
    listItems = listItems .. "\nadd_button_with_icon|bp_" .. itemID .. "||" .. t.frame .. "|" .. itemID .. "|" .. amount .. "|"
  end

  -- 2. Kotak tombol + (Store Item) langsung di akhir daftar (atau sendirian jika bp masih 0)
  listItems = listItems .. "\nadd_button_with_icon|add_item||" .. t.frame .. "|9412||"

  local upgradeCost = 10 * level
  local slotStatus = (freeSlots == 0)
    and (t.danger .. "FULL (0 Available)")
    or ("`2" .. freeSlots .. " Available")

  local d = themeHeader()
    .. "add_label_with_icon|big|" .. tc .. "Plus Backpack|left|448|\n"
    .. "add_smalltext|" .. tc .. "Level: " .. ac .. level .. tc .. " - Total Slots: " .. ac .. slotMax .. tc .. " - Used: " .. ac .. usedSlots .. "/" .. slotMax .. tc .. " (" .. slotStatus .. tc .. ")|\n"
    .. "text_scaling_string|12345678901234|"
    .. listItems
    .. "\nadd_button_with_icon||END_LIST|noflags|0||\n"
    .. "add_button|upgrade|" .. tc .. "Upgrade Backpack +" .. SLOTS_PER_LEVEL .. " Slots (" .. ac .. upgradeCost .. " BGL" .. tc .. ")|center|\n"

  if p:getBackpackUntradeUnlocked() then
    d = d .. "add_smalltext|`2[UNLOCKED] " .. tc .. "Untradeable item storage is active.|left|\n"
  else
    d = d .. "add_button|unlock_untrade|" .. tc .. "Unlock Untrade Storage (" .. ac .. "10 LGL" .. tc .. ")|center|\n"
  end

  d = d .. "end_dialog|gb_bp_main|Close|"
  p:onDialogRequest(d)
end

local function parseDigits(val)
  if val == nil then
    return 0
  end
  local numStr = tostring(val):match("%d+")
  return tonumber(numStr) or 0
end

local function handleBackpackDialog(w, p, data, raw)
  local name = GB.dialog_name(data, raw)
  local btn = GB.button_clicked(data, raw)

  -- 1. Dialog Utama Plus Backpack
  if name == "gb_bp_main" then
    if btn == "" or btn == "Close" then
      return true
    end

    if btn == "add_item" then
      local t = getTheme()
      local d = themeHeader()
        .. "add_label_with_icon|big|" .. t.textColor .. "Select Item to Store|left|9412|\n"
        .. "add_item_picker|selectItem|Choose Item|Pick from your inventory|\n"
        .. "end_dialog|gb_bp_store|Cancel|"
      p:onDialogRequest(d)
      return true
    end

    if btn == "upgrade" then
      local level = p:getBackpackLevel()
      if level < 1 then
        level = 1
      end
      local cost = 10 * level
      local has = p:getItemAmount(7188)
      if has >= cost then
        p:changeItem(7188, -cost)
        p:setBackpackLevel(level + 1)
        p:onConsoleMessage("`2Backpack upgraded! Level: " .. (level + 1) .. " (Total Slots: " .. ((level + 1) * SLOTS_PER_LEVEL) .. ")")
      else
        p:onConsoleMessage("`4Not enough BGL! Need " .. cost .. " BGL (You have: " .. has .. ").")
      end
      GB.showBackpackDialog(p)
      return true
    end

    if btn == "unlock_untrade" then
      if p:getBackpackUntradeUnlocked() then
        p:onConsoleMessage("`oUntradeable item storage is already unlocked.")
        GB.showBackpackDialog(p)
        return true
      end
      local lglCost = 10
      local hasLgl = p:getItemAmount(8470)
      if hasLgl < lglCost then
        p:onConsoleMessage("`4You need " .. lglCost .. " LGL to unlock untradeable item storage! You have " .. hasLgl .. ".")
        GB.showBackpackDialog(p)
        return true
      end
      p:changeItem(8470, -lglCost)
      p:setBackpackUntradeUnlocked(true)
      p:onConsoleMessage("`2Untradeable item storage unlocked! You can now store untradeable items in your backpack.")
      p:onAddNotification("interface/science_button.rttex", "`2Backpack: Untrade storage unlocked!", "audio/hub_open.wav", 0, 0)
      GB.showBackpackDialog(p)
      return true
    end

    if btn ~= nil and btn:sub(1, 3) == "bp_" then
      local itemID = parseDigits(btn:sub(4))
      local items = p:getBackpackItems() or {}
      local t = getTheme()
      for i = 1, #items do
        if items[i].id == itemID then
          local amount = items[i].count
          local d = themeHeader()
            .. "add_label_with_icon|big|" .. t.textColor .. "Retrieve " .. t.accent .. GB.item_name(itemID) .. "|left|" .. itemID .. "|\n"
            .. "add_smalltext|" .. t.textColor .. "Stored in Backpack: " .. t.accent .. amount .. "|\n"
            .. "add_text_input|count|" .. t.textColor .. "Amount:|" .. amount .. "|4|\n"
            .. "embed_data|retrieve_item|" .. itemID .. "\n"
            .. "end_dialog|gb_bp_retrieve|Cancel|Take"
          p:onDialogRequest(d)
          return true
        end
      end
      return true
    end

    return true
  end

  -- 2. Dialog Pilih Item dari Inventory
  if name == "gb_bp_store" then
    if btn == "Cancel" then
      GB.showBackpackDialog(p)
      return true
    end

    local itemid = parseDigits(data.selectItem or (raw and raw:match("selectItem|(%d+)")))
    if itemid <= 0 or itemid >= getItemCount() then
      GB.showBackpackDialog(p)
      return true
    end

    local item = getItem(itemid)
    if item ~= nil and item:isUntradeable() then
      if not p:getBackpackUntradeUnlocked() then
        p:onConsoleMessage("`4Untradeable items require unlocking first! Use 'Unlock Untrade Storage' (costs 10 LGL).")
        GB.showBackpackDialog(p)
        return true
      end
    end

    local t = getTheme()
    local have = p:getItemAmount(itemid)
    local d = themeHeader()
      .. "add_label_with_icon|big|" .. t.textColor .. "Store " .. t.accent .. GB.item_name(itemid) .. "|left|" .. itemid .. "|\n"
      .. "add_smalltext|" .. t.textColor .. "In Inventory: " .. t.accent .. have .. "|\n"
      .. "add_text_input|count|" .. t.textColor .. "Amount:|" .. have .. "|4|\n"
      .. "embed_data|store_item|" .. itemid .. "\n"
      .. "end_dialog|gb_bp_confirm|Cancel|Store"
    p:onDialogRequest(d)
    return true
  end

  -- 3. Dialog Konfirmasi Store
  if name == "gb_bp_confirm" then
    if btn == "Cancel" or btn == "Close" then
      GB.showBackpackDialog(p)
      return true
    end

    local itemid = parseDigits(data.store_item or GB.embed_value(raw, "store_item") or (raw and raw:match("store_item|(%d+)")))
    local count = parseDigits(data.count or (raw and raw:match("count|(%d+)")))

    if itemid <= 0 or count <= 0 then
      p:onConsoleMessage("`4Invalid item or amount.")
      GB.showBackpackDialog(p)
      return true
    end

    local have = p:getItemAmount(itemid)
    if have < count then
      p:onConsoleMessage("`4Not enough items in inventory (Have: " .. have .. ").")
      GB.showBackpackDialog(p)
      return true
    end

    local level = p:getBackpackLevel()
    if level < 1 then
      level = 1
    end
    local maxSlot = level * SLOTS_PER_LEVEL
    local currentItems = p:getBackpackItems() or {}
    local usedCount = 0
    local alreadyExists = false
    for i = 1, #currentItems do
      if currentItems[i].id ~= 0 and currentItems[i].count ~= 0 then
        usedCount = usedCount + 1
        if currentItems[i].id == itemid then
          alreadyExists = true
        end
      end
    end

    if not alreadyExists and usedCount >= maxSlot then
      p:onConsoleMessage("`4Backpack is full! (" .. usedCount .. "/" .. maxSlot .. " slots)")
      GB.showBackpackDialog(p)
      return true
    end

    if not p:storeBackpackItem(itemid, count) then
      p:onConsoleMessage("`4Failed to store item.")
      GB.showBackpackDialog(p)
      return true
    end

    p:onConsoleMessage("`2Stored " .. count .. " " .. GB.item_name(itemid) .. " in Backpack.")
    GB.showBackpackDialog(p)
    return true
  end

  -- 4. Dialog Retrieve Item
  if name == "gb_bp_retrieve" then
    if btn == "Cancel" or btn == "Close" then
      GB.showBackpackDialog(p)
      return true
    end

    local itemid = parseDigits(data.retrieve_item or GB.embed_value(raw, "retrieve_item") or (raw and raw:match("retrieve_item|(%d+)")))
    local count = parseDigits(data.count or (raw and raw:match("count|(%d+)")))

    if itemid <= 0 or count <= 0 then
      GB.showBackpackDialog(p)
      return true
    end

    local items = p:getBackpackItems() or {}
    local stored = 0
    for i = 1, #items do
      if items[i].id == itemid then
        stored = items[i].count
        break
      end
    end

    if stored <= 0 then
      GB.showBackpackDialog(p)
      return true
    end

    if count > stored then
      count = stored
    end

    if p:retrieveBackpackItem(itemid, count) then
      p:onConsoleMessage("`2Retrieved " .. count .. " " .. GB.item_name(itemid) .. " from Backpack.")
    else
      p:onConsoleMessage("`4Failed to retrieve, inventory full.")
    end

    GB.showBackpackDialog(p)
    return true
  end

  return false
end

onDialog(handleBackpackDialog)

for _, cmdName in ipairs({ "/backpack", "/bp" }) do
  registerLuaCommand({
    command = cmdName,
    description = "Open your backpack storage",
    roleRequired = 0,
    callback = function(p, args)
      GB.showBackpackDialog(p)
    end
  })
end

GB.register("cmd-backpack", {
  version = 1,
  category = "command",
  dialogs = { "gb_bp_main", "gb_bp_store", "gb_bp_confirm", "gb_bp_retrieve" }
})