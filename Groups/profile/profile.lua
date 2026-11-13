PROFILE_LAST = {}
PROFILE_PENDING = {}
PROFILE_MSG_COOLDOWN = {}

local function profile_theme(p)
  local t = GB_THEME or {
    bg = "72,28,38,235",
    border = "178,112,126,255",
    textColor = "`w"
  }
  return "set_default_color|" .. (t.textColor or "`w") .. "\n"
    .. "set_bg_color|" .. (t.bg or "72,28,38,235") .. "|\n"
    .. "set_border_color|" .. (t.border or "178,112,126,255") .. "|\n"
end

local function fmt(n)
  n = math.floor(tonumber(n) or 0)
  local neg = false
  if n < 0 then
    neg = true
    n = -n
  end
  local s = tostring(n)
  local out = ""
  while #s > 3 do
    out = "." .. string.sub(s, -3) .. out
    s = string.sub(s, 1, -4)
  end
  out = s .. out
  if neg then
    out = "-" .. out
  end
  return out
end

local function lower(s)
  return string.lower(s or "")
end

local function in_list(list, name)
  if list == nil then
    return false
  end
  for i = 1, #list do
    if lower(list[i]) == lower(name) then
      return true
    end
  end
  return false
end

local function item_ori_name(id)
  local it = getItem(id)
  if it == nil then
    return ""
  end
  return it:getOriName()
end

local function item_name(id)
  local it = getItem(id)
  if it == nil then
    return ""
  end
  return it:getName()
end

local function playtime_str(total_seconds)
  local total_minutes = math.floor((total_seconds or 0) / 60)
  local days = math.floor(total_minutes / 1440)
  local hours = math.floor((total_minutes % 1440) / 60)
  local minutes = total_minutes % 60
  if days > 0 then
    return days .. " Days, " .. hours .. " Hours, " .. minutes .. " Minutes"
  end
  if hours > 0 then
    return hours .. " Hours, " .. minutes .. " Minutes"
  end
  return minutes .. " Minutes"
end

local function has_playmod(t, id)
  local pms = t:getPlaymods()
  if pms == nil then
    return false
  end
  for i = 1, #pms do
    if pms[i].id == id then
      return true
    end
  end
  return false
end

local function on_hospital_bed(t, w)
  if w == nil then
    return false
  end
  local tile = w:getTile(t:getBlockPosX(), t:getBlockPosY())
  if tile == nil then
    return false
  end
  return tile:getBlockID() == PROFILE_WRENCH.hospital_bed
end

local function role_label(t)
  if isClist(t:getName()) then
    return "`2@Creator List"
  end
  local lvl = t:getRoleLevel()
  if lvl >= 11 then
    return "`c@Owner Server"
  end
  if lvl >= 8 then
    return "`8@Unlimited"
  end
  if lvl >= 7 then
    return "`9@God"
  end
  if lvl >= 5 then
    return "`6@Developer"
  end
  if lvl >= 4 then
    return "`e@Administrator"
  end
  if lvl >= 3 then
    return "`#@Moderator"
  end
  if lvl >= 2 then
    return "`1VIP"
  end
  return "`wNoobs!"
end

local function level_display(t)
  local lvl = tostring(t:getLevel())
  if t:isAdministrator() then
    if t:isModerator() then
      return lvl
    end
    local q = ""
    for i = 1, #lvl do
      q = q .. "?"
    end
    return q
  end
  return lvl
end

local function wl_total(t)
  local total = 0
  for id, mult in pairs(PROFILE_WRENCH.wl_items) do
    total = total + t:getItemAmount(id) * mult
  end
  return total
end

local function friend_state(p, t)
  local friends = p:getFriendsDetailed()
  if friends == nil then
    return false, false
  end
  for i = 1, #friends do
    if lower(friends[i].name) == lower(t:getName()) then
      return true, friends[i].mute == true
    end
  end
  return false, false
end

local function get_target(p)
  local last = PROFILE_LAST[p:getID()]
  if last == nil then
    return nil
  end
  local t = nil
  if getPlayerByName ~= nil then
    t = getPlayerByName(last.name)
  end
  if t == nil and getPlayer ~= nil then
    t = getPlayer(last.netID)
  end
  return t
end

local function remember_target(p, t)
  PROFILE_LAST[p:getID()] = { name = t:getName(), netID = t:getNetID() }
end

local function clothes_lines(t, ori)
  local out = ""
  for i = 1, #PROFILE_WRENCH.clothing_slots do
    local id = t:getClothingItemID(PROFILE_WRENCH.clothing_slots[i])
    if id ~= nil and id ~= 0 then
      local nm = ori and item_ori_name(id) or item_name(id)
      out = out .. "\nadd_label_with_icon|small|" .. nm .. "|left|" .. id .. "|"
    end
  end
  return out
end

local function clothes_lines_full(t)
  local out = ""
  for i = 1, #PROFILE_WRENCH.clothing_slots_full do
    local id = t:getClothingItemID(PROFILE_WRENCH.clothing_slots_full[i])
    if id ~= nil and id ~= 0 then
      out = out .. "\nadd_label_with_icon|small|`o" .. item_name(id) .. "|left|" .. id .. "|"
    end
  end
  return out
end

local function event_str(seconds)
  seconds = math.floor(seconds or 0)
  if seconds <= 0 then
    return "Removing now "
  end
  local day = math.floor(seconds / 86400)
  seconds = seconds - day * 86400
  local hour = math.floor(seconds / 3600)
  local minute = math.floor((seconds % 3600) / 60)
  local second = seconds % 60
  local parts = {}
  if day ~= 0 then
    parts[#parts + 1] = day .. "d"
  end
  if hour ~= 0 then
    parts[#parts + 1] = hour .. "h"
  end
  if minute ~= 0 then
    parts[#parts + 1] = minute .. "m"
  end
  if second ~= 0 then
    parts[#parts + 1] = second .. "s"
  end
  return table.concat(parts, ", ")
end

local function xp_max(level)
  return 50 * ((level * level) + 2)
end

local function userinfo_text(p, t)
  local level = t:getLevel()
  local max = xp_max(level)
  local cur = t:getXP()
  if level == 1000 then
    cur = max
  end
  local range = "(" .. cur .. "/" .. max .. ")"
  if level > 999 then
    range = "(MAX)"
  end
  local s = profile_theme(p) .. "\n\nadd_progress_bar|`w" .. t:getNick() .. "``|big|Level " .. level .. "|" .. cur .. "|" .. max .. "|" .. range .. "|-3669761|\nadd_spacer|small|"
  s = s .. "\nadd_spacer|small|\nadd_textbox|`oStatus: `2ONLINE``|left|\nadd_spacer|small|"
  s = s .. "\nadd_label_with_icon|small|`oTotal Gems: " .. fmt(t:getGems()) .. "|left|112|\nadd_spacer|small|"
  s = s .. "\nadd_label_with_icon|small|`oTotal World Locks: " .. fmt(wl_total(t)) .. "|left|242|"
  s = s .. "\nadd_label_with_icon|small|`oTotal Magical Gem Locks: " .. fmt(t:getItemAmount(PROFILE_WRENCH.magical_lock)) .. "|left|8470|\nadd_spacer|small|"
  s = s .. "\nadd_label_with_icon|small|`oWorld Lock Bank: `2" .. fmt(t:getBankLock()) .. " WL|left|242|\nadd_spacer|small|"
  s = s .. "\nadd_button|show_bp_" .. t:getName() .. "|`2Show Backpack / Inventory``|0|0|\nadd_spacer|small|"
  s = s .. "\nadd_small_font_button||`oClothing/Set(press to copy)|0|0|" .. clothes_lines(t, true) .. "|"
  s = s .. "\nadd_spacer|small|\nadd_smalltext|`5(Statistics refresh every minute in real - time)|left|"
  s = s .. "\nadd_button|backto_richleaderboard| `oBack``|0|0|\n\nadd_quick_exit|end_dialog|Richest_Event||X|"
  return s
end

local function userbp_text(p, t)
  local items = ""
  local inv = t:getInventoryItems()
  if inv ~= nil then
    for i = 1, #inv do
      if inv[i].id ~= 0 and inv[i].count > 0 then
        items = items .. "\nadd_label_with_icon|small|`o" .. item_ori_name(inv[i].id) .. " : `2x" .. fmt(inv[i].count) .. "|left|" .. inv[i].id .. "|"
      end
    end
  end
  if items == "" then
    items = "\nadd_textbox|`4This player has no items in backpack.``|left|"
  end
  local s = profile_theme(p) .. "\n\nadd_label_with_icon|big|`wBackpack of " .. t:getNick() .. "``|left|6016|\nadd_spacer|small|"
  s = s .. items .. "\nadd_spacer|small|"
  s = s .. "\nadd_button|userinfo_" .. t:getName() .. "|`oBack to Profile``|0|0|"
  s = s .. "\nadd_button|backto_richleaderboard|`oBack to Leaderboard``|0|0|\n\nadd_quick_exit|end_dialog|Richest_Event||X|"
  return s
end

function ProfileShowUserInfo(p, username)
  local t = nil
  if getPlayerByName ~= nil then
    t = getPlayerByName(username)
  end
  if t == nil then
    return false
  end
  p:onDialogRequest(userinfo_text(p, t))
  return true
end

function ProfileShowUserBp(p, username)
  local t = nil
  if getPlayerByName ~= nil then
    t = getPlayerByName(username)
  end
  if t == nil then
    return false
  end
  p:onDialogRequest(userbp_text(p, t))
  return true
end

local function wrench_button(action, frame)
  return "\nadd_custom_button|" .. action .. "|image:interface/large/player_wrench.rttex;image_size:227,57;frame:0," .. frame .. ";width:0.27;min_width:60;|\nadd_custom_break|"
end

local function popup_button(action, image, size)
  size = size or "image_size:400,260;width:0.19;"
  return "\nadd_custom_button|" .. action .. "|image:" .. image .. ";" .. size .. "|"
end

function ProfileShowOther(p, t, w)
  local already, muted = friend_state(p, t)
  local surgery = ""
  if on_hospital_bed(t, w) then
    if has_playmod(t, PROFILE_WRENCH.surgery_recovery_playmod) then
      surgery = "\nadd_spacer|small|\nadd_textbox|Recovering from surgery...|left|"
    else
      surgery = "\nadd_spacer|small|" .. wrench_button("start_surg", PROFILE_WRENCH.frames.start_surg) .. "\nadd_smalltext|Surgeon Skill: " .. p:getSurgerySkill() .. "|left|"
    end
  end
  local playtime = playtime_str(os.time() - t:getPlaytime())
  local can_mod = false
  if w ~= nil then
    local owner = w:getOwner()
    if owner ~= nil and lower(owner) == lower(p:getName()) then
      can_mod = true
    end
    if not can_mod then
      local admins = w:getAdmins()
      if in_list(admins, p:getName()) then
        can_mod = true
      end
    end
  end
  if p:isAdministrator() or p:isModerator() then
    can_mod = true
  end
  local s = profile_theme(p) .. "embed_data|mynetID|" .. p:getNetID() .. "\n\n\nadd_label_with_icon|big|" .. t:getNick() .. " `w(UID: " .. t:getID() .. ")`w```` `0(```2" .. level_display(t) .. "```0)``|left|18|" .. surgery
  s = s .. "\nembed_data|othernetID|" .. t:getNetID() .. "\nadd_spacer|small|\nadd_textbox|`4[PLAYER DOSSIER]``|left|"
  s = s .. "\nadd_textbox|`oPlayer Role: " .. role_label(t) .. "``|left|"
  s = s .. "\nadd_textbox|`oTotal Playtime: `w" .. playtime .. "``|left|\nadd_spacer|small|"
  s = s .. wrench_button("trade", PROFILE_WRENCH.frames.trade)
  s = s .. wrench_button("send_gems", PROFILE_WRENCH.frames.send_gems)
  s = s .. wrench_button("send_msg", PROFILE_WRENCH.frames.send_msg)
  s = s .. "\nadd_textbox|(No Battle Leash equipped)|left|\nadd_textbox|Your opponent needs a valid license to battle!|left|"
  if can_mod then
    s = s .. wrench_button("kick", PROFILE_WRENCH.frames.kick)
    s = s .. wrench_button("pull", PROFILE_WRENCH.frames.pull)
    s = s .. wrench_button("worldban", PROFILE_WRENCH.frames.worldban)
  end
  if p:getRoleLevel() >= 9 then
    s = s .. wrench_button("punish_view", PROFILE_WRENCH.frames.punish_view)
  end
  if not already then
    s = s .. wrench_button("friend_add", PROFILE_WRENCH.frames.friend_add)
  end
  if already then
    s = s .. wrench_button("mute_player", PROFILE_WRENCH.frames.mute)
  end
  s = s .. "|\nadd_custom_button|view_worn_clothes|image:interface/large/player_wrench.rttex;image_size:227,57;frame:0,5;width:0.27;min_width:60;|\nadd_custom_break|"
  s = s .. wrench_button("ignore_player", PROFILE_WRENCH.frames.ignore)
  s = s .. wrench_button("report_player", PROFILE_WRENCH.frames.report)
  s = s .. "\nadd_spacer|small|"
  s = s .. "\nadd_custom_button||image:interface/large/player_wrench.rttex;image_size:227,57;frame:0,3;width:0.27;min_width:60;|\nadd_custom_break|"
  s = s .. "\n\nadd_quick_exit|end_dialog|Aparece_Otro|||"
  p:onDialogRequest(s)
  return true
end

local function ezio_buttons(p)
  local out = ""
  local feet = p:getClothingItemID(3)
  if feet == PROFILE_POPUP.ezio.feet.item then
    out = out .. popup_button(PROFILE_POPUP.ezio.feet.button, PROFILE_POPUP.ezio.feet.image)
  end
  local ances = p:getClothingItemID(9)
  if ances == PROFILE_POPUP.ezio.ances.item then
    out = out .. popup_button(PROFILE_POPUP.ezio.ances.button, PROFILE_POPUP.ezio.ances.image)
  end
  local back = p:getClothingItemID(6)
  for i = 1, #PROFILE_POPUP.ezio.back do
    if back == PROFILE_POPUP.ezio.back[i].item then
      out = out .. popup_button(PROFILE_POPUP.ezio.back[i].button, PROFILE_POPUP.ezio.back[i].image)
      break
    end
  end
  local neck = p:getClothingItemID(8)
  for i = 1, #PROFILE_POPUP.ezio.necklace do
    local hit = false
    for j = 1, #PROFILE_POPUP.ezio.necklace[i].items do
      if neck == PROFILE_POPUP.ezio.necklace[i].items[j] then
        hit = true
        break
      end
    end
    if hit then
      out = out .. popup_button(PROFILE_POPUP.ezio.necklace[i].button, PROFILE_POPUP.ezio.necklace[i].image)
      break
    end
  end
  local hand = p:getClothingItemID(5)
  for i = 1, #PROFILE_POPUP.ezio.hand do
    local hit = false
    for j = 1, #PROFILE_POPUP.ezio.hand[i].items do
      if hand == PROFILE_POPUP.ezio.hand[i].items[j] then
        hit = true
        break
      end
    end
    if hit then
      out = out .. popup_button(PROFILE_POPUP.ezio.hand[i].button, PROFILE_POPUP.ezio.hand[i].image)
      break
    end
  end
  local hair = p:getClothingItemID(0)
  for i = 1, #PROFILE_POPUP.ezio.hair do
    local rule = PROFILE_POPUP.ezio.hair[i]
    if rule.item ~= nil and hair == rule.item then
      out = out .. popup_button(rule.button, rule.image)
      break
    end
    if rule.items ~= nil then
      local hit = false
      for j = 1, #rule.items do
        if hair == rule.items[j] then
          hit = true
          break
        end
      end
      if hit then
        out = out .. popup_button(rule.button, rule.image)
        break
      end
    end
  end
  return out
end

function ProfileShowSelf(p)
  local level = p:getLevel()
  local max = xp_max(level)
  local vip = ""
  local used = p:getUsedVipDoor()
  if used ~= nil and #used > 0 and used[1].world ~= nil then
    vip = "\nadd_custom_textbox|`$You have Pay VIP Access in World '" .. used[1].world .. "' Time Remaining: (" .. event_str((used[1]["until"] or 0) - os.time()) .. ")|size:small;icon:14594;|"
  end
  local w = p:getWorld()
  local world_count = 0
  if w ~= nil then
    world_count = w:getPlayersCount()
  end
  local role_prefix = ""
  if w ~= nil then
    role_prefix = p:getRolePrefix(w)
  end
  local status = "\nadd_custom_button|online_status|image:interface/large/gui_wrench_online_status_1green.rttex;image_size:400,260;width:0.19;|"
  local cheats = ""
  if has_playmod(p, PROFILE_WRENCH.cheat_playmod) then
    cheats = "\nadd_custom_button|cheats_menu|image:interface/large/gui_wrench_cheatmenu.rttex;image_size:400,260;width:0.19;||"
  end
  local s = profile_theme(p) .. "\n\nadd_progress_bar|`w" .. role_prefix .. p:getName() .. " `w(UID: " .. p:getID() .. ")`w``|big|Level " .. level .. "|" .. p:getXP() .. "|" .. max .. "|(" .. p:getXP() .. "/" .. max .. ")|-3669761|\n"
  s = s .. vip .. "||\nadd_spacer|small||\nadd_spacer|small|"
  s = s .. "\nset_custom_spacing|x:5;y:10|" .. status
  s = s .. popup_button("notebook_edit", "interface/large/gui_wrench_notebook.rttex")
  s = s .. popup_button("seed_diary", "interface/large/gui_wrench_seed_diary.rttex")
  s = s .. popup_button("goals", "interface/large/gui_wrench_goals_quests.rttex")
  s = s .. popup_button("bonus", "interface/large/gui_wrench_daily_bonus_active.rttex")
  s = s .. popup_button("my_worlds", "interface/large/gui_wrench_my_worlds.rttex")
  s = s .. popup_button("growmoji", "interface/large/gui_wrench_growmojis.rttex")
  s = s .. popup_button("marvelous_missions", "interface/large/gui_wrench_marvelous_missions.rttex")
  s = s .. popup_button("title_edit", "interface/large/gui_wrench_title.rttex")
  s = s .. cheats .. "||\nadd_custom_break|" .. ezio_buttons(p) .. "|\nadd_custom_break|\nadd_spacer|small|\nadd_spacer|small|\nadd_custom_break|"
  s = s .. popup_button("trade_scan", "interface/large/gui_wrench_trades.rttex")
  s = s .. popup_button("wrench_edit", "interface/large/gui_wrench_customization.rttex")
  s = s .. "\nadd_custom_break|\nadd_spacer|small|\nset_custom_spacing|x:0;y:0||"
  s = s .. "\nadd_textbox|`4[PROFILE DOSSIER]``|left|"
  s = s .. "\nadd_textbox|`oTotal Playtime: `w" .. playtime_str(os.time() - p:getPlaytime()) .. " ``(`w" .. string.format("%.2f", (os.time() - p:getPlaytime()) / 3600) .. " hours``)``|left|"
  s = s .. "\nadd_textbox|`oBackpack Capacity: `w" .. (p:getInventorySize() - 1) .. " Slots``|left|"
  s = s .. "\nadd_textbox|`oLocation: `w" .. p:getWorldName() .. " ``(`w" .. math.floor(p:getPosX() / 32) .. "``, `w" .. math.floor(p:getPosY() / 32) .. "``) - `w" .. world_count .. "`` active players``|left|"
  s = s .. "\nadd_spacer|small|"
  s = s .. "\nadd_button|playing_music|`wPlaying Music|noflags|0|0|"
  s = s .. "\nadd_button|open_worldlock_storage|`wBank|noflags|0|0|"
  s = s .. "\nadd_button|game_menu|`wGame Menu|noflags|0|0|"
  s = s .. "\nadd_button|account_security|`wAccount|noflags|0|0|"
  s = s .. "\nadd_spacer|small|"
  s = s .. "\nadd_button|Logout_MyAcc|`4Logout from this Account|noflags|0|0|"
  s = s .. "\nadd_spacer|small|\nadd_quick_exit|end_dialog|popup|||"
  p:onDialogRequest(s)
  return true
end

function ProfileShowSkillAssets(p)
  local s = profile_theme(p) .. "\n\nadd_label_with_icon|big|My Assets & Skills|left|12436|"
  s = s .. "\nadd_spacer|small|"
  s = s .. "\nadd_smalltext|`oAll of your assets & life-skills will be displayed here below! Life skills are defined as a group of psychosocial competencies and interpersonal skills that help people make informed decisions, solve problems, think critically and creatively, communicate effectively.``|left|"
  s = s .. "\nadd_spacer|small|"
  s = s .. "\nadd_textbox|- Gems -|left|\nadd_label_with_icon|small|`w" .. fmt(p:getGems()) .. "|left|14590|"
  if p.getGemsStorage ~= nil then
    s = s .. "\nadd_spacer|small|\nadd_textbox|- Gems Storage -|left|\nadd_label_with_icon|small|`w" .. fmt(p:getGemsStorage()) .. "|left|14592|"
  end
  s = s .. "\nadd_spacer|small|\nadd_textbox|- Level -|left|\nadd_label_with_icon|small|`w" .. fmt(p:getLevel()) .. "|left|1488|"
  if p.getOPC ~= nil then
    s = s .. "\nadd_spacer|small|\nadd_textbox|- Online Point Currency -|left|\nadd_label_with_icon|small|`w" .. fmt(p:getOPC()) .. "|left|10668|"
  end
  s = s .. "\nadd_textbox|- " .. "GrowBest" .. " Coins -|left|\nadd_label_with_icon|small|`w" .. fmt(p:getGtwl()) .. "|left|244|"
  s = s .. "\nadd_textbox|- Bank Locks -|left|"
  s = s .. "\nadd_label_with_icon|small|World Lock Bank: `2" .. fmt(p:getBankLock()) .. " WL|left|242|"
  s = s .. "\nadd_spacer|small|\nadd_textbox|- Awesomeness -|left|\nadd_label_with_icon|small|" .. p:getAwesomeness() .. "%|left||"
  if p.getPunchCount ~= nil then
    s = s .. "\nadd_spacer|small|\nadd_textbox|- You've Punched -|left|\nadd_label_with_icon|small|" .. p:getPunchCount() .. " times|left|18|"
  end
  s = s .. "\nadd_spacer|small|\nadd_textbox|- Fires Put Out -|left|\nadd_label_with_icon|small|" .. p:getFires() .. "|left|3062|"
  if p.getCarnivalGamesWon ~= nil then
    s = s .. "\nadd_spacer|small|\nadd_textbox|- Carnival Games Won -|left|\nadd_label_with_icon|small|" .. p:getCarnivalGamesWon() .. "|left|1882|"
  end
  if p.getSurgeryCompleted ~= nil then
    local sc = p:getSurgeryCompleted()
    s = s .. "\nadd_spacer|small|\nadd_textbox|- Surgeries Completed (using Bling set) -|left|"
    s = s .. "\nadd_label_with_icon|small|" .. sc .. " (2000 more until Angel of Mercy's Wings)|left|1270|"
    s = s .. "\nadd_label_with_icon|small|" .. sc .. " (3000 more until `4Dr.`` Title)|left|1270|"
  end
  s = s .. "\nadd_spacer|small|\nadd_custom_button|backto_wrench|textLabel:`w`wBack;middle_colour:500;border_colour:500;|\nadd_spacer|small|\nadd_custom_break|\n\nadd_quick_exit|end_dialog|popup|||"
  p:onDialogRequest(s)
  return true
end

function ProfileShowOnlineStatus(p)
  local st = 0
  if p.getPStatus ~= nil then
    st = p:getPStatus() or 0
  end
  local s = profile_theme(p) .. "\n\nadd_label_with_icon|big|`wOnline Status``|left|1366|\nadd_spacer|small|\nmax_checks|1|"
  s = s .. "\nadd_checkbox|checkbox_status_online|`wOnline``|" .. (st == 0 and "1" or "0")
  s = s .. "\nadd_checkbox|checkbox_status_busy|`wBusy``|" .. (st == 1 and "1" or "0")
  s = s .. "\nadd_checkbox|checkbox_status_away|`wAway``|" .. (st == 2 and "1" or "0")
  s = s .. "\nadd_spacer|small|\nadd_custom_button|online_status|textLabel:`wOk;middle_colour:500;border_colour:500;|\nadd_spacer|small|\nadd_custom_break|\n\nadd_quick_exit|end_dialog|online_status|||"
  p:onDialogRequest(s)
  return true
end

function ProfileShowNotebook(p)
  if p.getNote == nil then
    return false
  end
  local note = p:getNote() or ""
  local s = profile_theme(p) .. "\n\nadd_label|big|Notebook|left|0|\nadd_text_box_input|personal_note||" .. note .. "|128|5|\nadd_spacer|small|"
  s = s .. "\nadd_custom_button|save|textLabel:`wSave;middle_colour:500;border_colour:500;|\nadd_spacer|small|\nadd_custom_break|"
  s = s .. "\nadd_spacer|small|\nadd_custom_button|clear|textLabel:`wClear;middle_colour:500;border_colour:500;|\nadd_spacer|small|\nadd_custom_break|"
  s = s .. "\nadd_spacer|small|\nadd_custom_button|cancel|textLabel:`wCancel;middle_colour:500;border_colour:500;margin:0,30;|\nadd_spacer|small|\nadd_custom_break|\n\nadd_quick_exit|end_dialog|notebook_edit||"
  p:onDialogRequest(s)
  return true
end

local function is_mod(p)
  return p:isModerator() or p:isAdministrator() or p:isDeveloper()
end

local function mod_note(sender, target)
  local note = (not sender:isModerator() and target:isModerator()) or (not sender:isAdministrator() and target:isAdministrator()) or (not sender:isDeveloper() and target:isDeveloper())
  if note then
    return "`6>> (Sent to `$" .. target:getName() .. "`6) `o(`4Note: ``Message a mod `4ONLY ONCE `oabout an issue. Mods dont fix scams or replace gems, they punish players who break the `5/rules`o. For issues related to account recovery or purchasing, send message to creators on discord.)"
  end
  return "`6>> (Sent to `$" .. target:getName() .. "`6)"
end

local function jammed_world(sender)
  local w = sender:getWorld()
  if sender:getMH() == 1 then
    return "`4JAMMED!``"
  end
  if w ~= nil and w:hasJammer(226) then
    return "`4JAMMED!``"
  end
  return sender:getWorldName()
end

local function do_send_msg(p, msg)
  local last = PROFILE_LAST[p:getID()]
  if last == nil then
    return true
  end
  if has_playmod(p, 11) then
    p:onConsoleMessage("`6>> That's sort of hard to do while duct-taped.``")
    return true
  end
  if msg == nil or msg == "" then
    p:onConsoleMessage("Usage: /msg <`$full or first part of a name``> <`$your message``> - This will send a private message to someone anywhere in the universe.  If you don't include a message, you can just see if he/she is online or not.")
    return true
  end
  local now = os.time()
  local last_t = PROFILE_MSG_COOLDOWN[p:getID()] or 0
  if now - last_t < PROFILE_WRENCH.msg_cooldown_seconds then
    p:onTalkBubble(p:getNetID(), "Slow Down!", 0)
    return true
  end
  PROFILE_MSG_COOLDOWN[p:getID()] = now
  local t = get_target(p)
  if t == nil or t:getMH() == 1 or t:getOnlineStatus() == 0 then
    p:onConsoleMessage("`6>> No one online who has a name starting with " .. last.name .. "`8.")
    return true
  end
  if in_list(t:getIgnored(), p:getName()) then
    p:onConsoleMessage("`6>> `4SYSTEM``: That user is ignoring you.")
    return true
  end
  local sdg = false
  local msg_mute = false
  local my_friends = p:getFriendsDetailed()
  if my_friends ~= nil then
    for i = 1, #my_friends do
      if lower(my_friends[i].name) == lower(t:getName()) and my_friends[i].mute then
        sdg = true
      end
    end
  end
  local their_friends = t:getFriendsDetailed()
  if their_friends ~= nil then
    for i = 1, #their_friends do
      if lower(their_friends[i].name) == lower(p:getName()) and their_friends[i].mute then
        msg_mute = true
      end
    end
  end
  if sdg then
    p:onConsoleMessage("(`4Note: `6: That user is muted you)")
    return true
  end
  if msg_mute then
    p:onConsoleMessage("(`4Note: ```6You can't send messages to people you muted)")
    return true
  end
  t:setLastMsg(p:getName())
  t:setLastMsgWorld(p:getWorldName())
  p:onConsoleMessage(mod_note(p, t))
  t:onConsoleMessage("CP:0_PL:0_OID:_CT:[MSG]_>> `c>> from (``" .. p:getNick() .. "`c) in [`$" .. jammed_world(p) .. "``] > ```$" .. msg .. "``")
  t:sendActionPacket("action|play_sfx\nfile|audio/pay_time.wav\ndelayMS|0")
  return true
end

local function answer_pay(p, data)
  local count = data.CountGems
  if count == nil or count == "" then
    return true
  end
  if string.find(count, "[^0-9]") ~= nil then
    return true
  end
  local n = tonumber(count)
  if n == nil or n < 1 then
    return true
  end
  if n > p:getGems() then
    p:onTalkBubble(p:getNetID(), "`wYou don't have enough gems to pay", 0)
    return true
  end
  if n > PROFILE_WRENCH.pay_max then
    p:onTalkBubble(p:getNetID(), "`wMaximum money amount is 2.000.000.000", 0)
    return true
  end
  local t = get_target(p)
  if t == nil then
    return true
  end
  if t:getGems() >= PROFILE_WRENCH.max_gems then
    p:onTalkBubble(p:getNetID(), "Warning! " .. t:getName() .. " gems have reached the maximum limit", 0)
    return true
  end
  p:removeGems(n)
  t:addGems(n)
  t:notify("`wYou received `2" .. count .. " `wGems from " .. (p:getNameColor() or "") .. p:getName(), "interface/cash_icon_overlay.rttex", "audio/hub_open.wav")
  t:onConsoleMessage("You received `2" .. count .. "`o Gems from " .. (p:getNameColor() or "") .. p:getName())
  p:onConsoleMessage("`oSuccesfully send " .. count .. " Gems to " .. t:getName() .. ".")
  return true
end

local function answer_ignore(p, t)
  local name = t:getName()
  if lower(p:getName()) == lower(name) then
    p:onConsoleMessage("Don't look now, but that person is `5IN YOUR HOUSE``!")
    return true
  end
  local ignored = p:getIgnored() or {}
  if in_list(ignored, name) then
    p:onConsoleMessage("That jerk `5" .. name .. "`` is already being ignored!")
    return true
  end
  local all = nil
  if getAllPlayers ~= nil then
    all = getAllPlayers()
  end
  if all ~= nil then
    for i = 1, #all do
      local cp = all[i]
      if cp ~= nil and (lower(string.sub(cp:getName(), 1, 3)) == lower(string.sub(name, 1, 3)) or name == lower(cp:getName())) then
        if in_list(ignored, cp:getName()) then
          p:onConsoleMessage("You removed `5" .. cp:getName() .. "`` from ignore list!")
          p:removeIgnored(lower(cp:getName()))
          return true
        end
        p:addIgnored(lower(cp:getName()))
        return true
      end
    end
  end
  local w = p:getWorld()
  if w ~= nil then
    local players = w:getPlayers()
    if players ~= nil then
      for i = 1, #players do
        local cp = players[i]
        if cp ~= nil and (lower(string.sub(cp:getName(), 1, 3)) == lower(string.sub(name, 1, 3)) or name == lower(cp:getName())) then
          if in_list(ignored, cp:getName()) then
            p:onConsoleMessage("You removed `5" .. cp:getName() .. "`` from ignore list!")
            p:removeIgnored(lower(cp:getName()))
            return true
          end
          p:addIgnored(lower(cp:getName()))
          return true
        end
      end
    end
  end
  p:onConsoleMessage("Hmm, nobody is currently online with a name starting with `5" .. name .. "``.")
  return true
end

local function answer_friend_add(p, t)
  if lower(p:getName()) == lower(t:getName()) then
    p:onConsoleMessage("`oDon't look now, but that person is `5IN YOUR HOUSE``!")
    return true
  end
  local their_pending = PROFILE_PENDING[t:getID()]
  if their_pending ~= nil and their_pending[lower(p:getName())] then
    p:sendActionPacket("action|play_sfx\nfile|audio/love_in.wav\ndelayMS|0")
    p:addFriend(t:getName())
    p:onConsoleMessage("`3FRIEND ADDED:`` You're now friends with " .. t:getNick() .. "!")
    t:sendActionPacket("action|play_sfx\nfile|audio/love_in.wav\ndelayMS|0")
    t:addFriend(p:getName())
    t:onConsoleMessage("`3FRIEND ADDED:`` You're now friends with " .. p:getNick() .. "!")
    their_pending[lower(p:getName())] = nil
    return true
  end
  local already, _ = friend_state(p, t)
  if already then
    p:onTalkBubble(p:getNetID(), "That's already my friend!", 0)
    return true
  end
  if math.abs(p:getBlockPosX() - t:getBlockPosX()) >= 3 then
    p:onTalkBubble(p:getNetID(), "`5[```4Too far away`` `0- Stand closer to`` " .. t:getNick() .. "`0 first!```5]``", 0)
    return true
  end
  local my_pending = PROFILE_PENDING[p:getID()]
  if my_pending == nil then
    my_pending = {}
    PROFILE_PENDING[p:getID()] = my_pending
  end
  my_pending[lower(t:getName())] = true
  p:onTalkBubble(p:getNetID(), "`5[``Friend request sent to " .. t:getNick() .. "`5]``", 0)
  t:sendActionPacket("action|play_sfx\nfile|audio/tip_start.wav\ndelayMS|0")
  t:onConsoleMessage("`3FRIEND REQUEST:`` You've received a `wfriend request`` from " .. p:getNick() .. "! To accept, press the `wwrench by his/her name`` and then choose `wAdd as friend``.")
  return true
end

local function show_worn_clothes(p, t)
  local dn = t:getDisplayName()
  local title = dn
  if dn == nil or dn == "" then
    title = (t:getNameColor() or "") .. t:getName()
  end
  local s = profile_theme(p) .. "\nadd_label_with_icon|big|`w" .. title .. "`o's Clothes List|left|1420|\nadd_spacer|small|" .. clothes_lines_full(t) .. "\n\nadd_quick_exit|end_dialog||Close||"
  p:onDialogRequest(s)
  return true
end

local function show_playerreport(p)
  local s = profile_theme(p) .. "\n\nadd_label_with_icon|big|`wReport this player|left|1432|\nadd_text_input|reason|`oReason:||33|\nadd_label|small|`1If you really want to report this player, click Report below!|left|\n\nadd_quick_exit|end_dialog|playerreport|Cancel|`wReport|"
  p:onDialogRequest(s)
  return true
end

local function show_send_message(p, t)
  local s = profile_theme(p) .. "\nadd_label_with_icon|big|`5Message To `o" .. t:getName() .. "|left|660|\nadd_text_input|message|||200|\nadd_button|send_message|`5Send|0|0|\nadd_button|backtoplayerwrench|`oBack|\n\nadd_quick_exit|end_dialog|Send_Message|||"
  p:onDialogRequest(s)
  return true
end

local function show_pay(p, t)
  local s = profile_theme(p) .. "\nadd_label_with_icon|big|`5Send Gems To `o(" .. t:getName() .. ")|left|112|\nadd_textbox|`$Your currently gems: `9" .. p:getGems() .. "|left|\nadd_textbox|`$How much do you want to pay " .. t:getName() .. "?|left|\nadd_text_input|CountGems|`$Count Gems:||10|\n\nadd_quick_exit|end_dialog|PayDialog|Cancel|Send|"
  p:onDialogRequest(s)
  return true
end

local function punish_role_line(roles)
  local r = roles or {}
  local s = "`oRole: ["
  s = s .. (r.vip and "`2VIP``/" or "`4NO_VIP``/")
  s = s .. (r.moderator and "`2MOD``/" or "`4NO_MOD``/")
  s = s .. (r.administrator and "`2ADMIN``/" or "`4NO_ADMIN``/")
  s = s .. (r.developer and "`2DEVELOPER``/" or "`4NO_DEVELOPER``/")
  s = s .. (r.god and "`2RESELLER``/" or "`4NO_RESELLER``/")
  s = s .. (r.unlimited and "`2UNLIMITED``/" or "`4NO_UNLIMITED``/")
  s = s .. (r.owner and "`2OWNER``/" or "`4NO_OWNER``/")
  s = s .. (r.cheats and "`2CHEATER``" or "`4NO_CHEATER``")
  return s .. "]|left|"
end

local function punish_list_lines(list, empty_text)
  local out = ""
  if list == nil or #list == 0 then
    return "\nadd_textbox|`o" .. empty_text .. "|left|"
  end
  for i = 1, #list do
    out = out .. "\nadd_textbox|`o" .. list[i] .. ", |left|\n"
  end
  return out
end

local function show_punish_view(p, info)
  local online = info.online == true
  local status = online and "`2ONLINE``" or "`4OFFLINE``"
  local s = profile_theme(p) .. "\n\nadd_label_with_icon|big|`wPlayer Information: " .. status .. "|left|658|\nadd_spacer|small|\nadd_textbox|`oEditing: `w" .. (info.name or "") .. " `o(" .. (info.requested_name or "") .. ") `o| #`w" .. tostring(info.id or 0)
  if info.banned then
    s = s .. " (`4BANNED``)"
  end
  s = s .. "``|left|\nadd_textbox|`oPlaytime: `w" .. string.format("%.2f", tonumber(info.playtime_hours) or 0) .. " hours``   `oIP Address: `w" .. (info.ip or "") .. "``|left|\n"
  if not online and info.last_online ~= nil and info.last_online ~= "" then
    s = s .. "add_smalltext|Last online: `5" .. info.last_online .. "``|left|\n"
  end
  s = s .. "add_spacer|small|\nadd_textbox|`5--- Quick Actions ------------------------------------------|left|\n"
  if online then
    s = s .. "add_custom_button|warp_to_" .. (info.world or "") .. "|textLabel:`oWarp to Player (in `5" .. (info.world or "") .. "``);middle_colour:500;border_colour:500;|\nadd_custom_break|\n"
  else
    s = s .. "add_button||`oWarp to User (in `4EXIT``)|off|0|0|\nadd_custom_break|\n"
  end
  s = s .. "add_custom_button|SkillAssets_Info|textLabel:`oAssets Info / Edit Role;middle_colour:500;border_colour:500;|\nadd_custom_break|\nadd_custom_button|view_inventory|textLabel:`oView Inventory;middle_colour:500;border_colour:500;|\nadd_custom_break|\n"
  if not online and isClist ~= nil and isClist(p:getName()) then
    s = s .. "add_custom_button|login_as|textLabel:`5Login as`` `2" .. (info.name or "") .. "```5...``;middle_colour:500;border_colour:500;|\n"
  end
  if info.banned then
    s = s .. "add_textbox|`5--- Ban Info ------------------------------------------------|left|"
    s = s .. "\nadd_smalltext|Banned by: `5" .. (info.banned_by or "") .. "``|left|\nadd_smalltext|Ban reason: `5" .. (info.ban_reason or "") .. "``|left|\nadd_spacer|small|\nadd_custom_button|ban_0|textLabel:`w`4Unban``;middle_colour:500;border_colour:500;|\nadd_spacer|small|\nadd_custom_break|\n"
  end
  s = s .. "add_spacer|small|\nadd_textbox|`5--- Account Role & Assets ----------------------------------|left|\nadd_smalltext|" .. punish_role_line(info.roles) .. "\n"
  s = s .. "add_smalltext|`oLevel: `w" .. tostring(info.level or 0) .. "`` | Gems: `2" .. GB.fmt_count(info.gems or 0) .. "`` | OPC: `e" .. GB.fmt_count(info.opc or 0) .. "`` | XP: `9" .. GB.fmt_count(info.xp or 0) .. "``|left|\nadd_spacer|small|\n"
  s = s .. "add_textbox|`5--- Records ------------------------------------------------|left|\nadd_textbox|`oAccount Warnings:``" .. punish_list_lines(info.warnings, "This player has clear records / no warnings.") .. "|\n"
  s = s .. "add_textbox|`oAccount Bans:``" .. punish_list_lines(info.bans, "This player has clear records / no bans.") .. "|\n"
  s = s .. "add_textbox|`oAccount Notes:``" .. punish_list_lines(info.notes, "There's no account notes for this user yet.") .. "|\n"
  s = s .. "add_spacer|small|\nadd_textbox|`5--- Moderation Controls ------------------------------------|left|\nadd_smalltext|`oYou must have strong evidence (Hacks, Spammer, Scammer, etc.) and proof must be sent to Discord #Ban-Proof. Banning without solid evidence will result in demotion. Read /modrules before acting.|left|\n"
  if p.isAdministrator ~= nil and p:isAdministrator() then
    s = s .. "add_label_with_icon_button|small|`4Blacklist from Server|left|278|blacklist_|"
  end
  s = s .. "add_label_with_icon_button|small|`4Ban IP Address|left|278|ban_ip|"
  s = s .. "add_label_with_icon_button|small|`4Ban: 1 Week (DGH)|left|732|ban_604800|"
  s = s .. "add_label_with_icon_button|small|`4Ban: 4 Weeks (DGH)|left|732|ban_31|"
  s = s .. "add_label_with_icon_button|small|`4Ban: Permanent (DGH)|left|732|ban_729|"
  s = s .. "add_label_with_icon_button|small|`6Fake Auto-Ban (Online Troll)|left|1908|fake_ban|\n"
  s = s .. "add_spacer|small|\n\nadd_quick_exit|end_dialog|punish_view|Close||"
  p:onDialogRequest(s)
  return true
end

local function show_card_battle(p)
  local gems = p:getGems()
  if gems > 1499 then
    local s = profile_theme(p) .. "\n\nadd_label_with_icon|big|`oCard Battle License|left|112|\nadd_spacer|small|\nadd_label_with_icon|small|`oYou currently have: " .. GB.fmt_count(gems) .. " Gems|left|112|\nadd_button|Get_License_Confirm|`oGet License for 1.500 Gems|0|0|\nadd_spacer|small|\nadd_button|backto_wrench|`wBack|0|0|\n\nadd_quick_exit|end_dialog|popup|||"
    p:onDialogRequest(s)
    return true
  end
  local s = profile_theme(p) .. "\n\nadd_label_with_icon|big|`oCard Battle License|left|112|\nadd_spacer|small|\nadd_textbox|`oOops! Looks like you can't afford a new Card Battle License of the moment! Try again later.|left|\nadd_textbox|`oA new license Will cost you 1,500 Gems.|left|\nadd_label_with_icon|small|`oYou currently have: " .. GB.fmt_count(gems) .. " Gems|left|112|\nadd_spacer|small|\nadd_button|backto_wrench|`wBack|0|0|\n\nadd_quick_exit|end_dialog|popup|||"
  p:onDialogRequest(s)
  return true
end

local function show_fav_items(p)
  if p.getFavoriteItemIds == nil then
    return false
  end
  local ids = p:getFavoriteItemIds() or {}
  if #ids == 0 then
    local s = profile_theme(p) .. "\n\nadd_label_with_icon|big|`wFavorite Items|left|13814|\nadd_spacer|small|\nadd_textbox|`oYou have not favorited any item yet.|left|\nadd_spacer|small|\nadd_button|backto_wrench|`wBack|0|0|\n\nadd_quick_exit|end_dialog|popup|||"
    p:onDialogRequest(s)
    return true
  end
  local item_list = ""
  for i = 1, #ids do
    local it = getItem(ids[i])
    if it ~= nil then
      item_list = item_list .. "\nadd_label_with_icon|small|`w" .. it:getName() .. "|left|" .. ids[i] .. "|"
    end
  end
  local s = profile_theme(p) .. "\n\nadd_label_with_icon|big|`wFavorite Items|left|13814|\nadd_spacer|small|\nadd_textbox|`oAll favorited items are currently in your inventory. They can be unfavorited by tapping on the UNFAV button while having the item selected in your inventory.|left|\nadd_spacer|small|" .. item_list .. "|\nadd_spacer|small|\nadd_button|backto_wrench|`wBack|0|0|\n\nadd_quick_exit|end_dialog|popup|||"
  p:onDialogRequest(s)
  return true
end

local GROWEMOJI_SPECIAL = {
  oops = true, sleep = true, punch = true, bheart = true, cry = true,
  bunny = true, cactus = true, pine = true, peace = true, terror = true,
  troll = true, fireworks = true, party = true, song = true, ghost = true,
  nuke = true, halo = true, lucky = true, weary = true, moyai = true,
  plead = true, wl = true, grow = true, gems = true, gtoken = true,
  vend = true, football = true
}

local function growmoji_owned_line(name)
  return "\nadd_smalltext_forced| (" .. name .. ") |left|"
end

local function growmoji_locked_line(name)
  return "\nadd_smalltext_forced_alpha| (" .. name .. ") |0.5|left|"
end

local function show_growmoji(p)
  local level = p:getLevel()
  local supp = 0
  if p.getSupp ~= nil then
    supp = p:getSupp() or 0
  end
  local friends = 0
  if p.getFriendsDetailed ~= nil then
    local list = p:getFriendsDetailed()
    if list ~= nil then
      friends = #list
    end
  end
  local first_emoji = "\nadd_spacer|small|"
  if level >= 5 then
    first_emoji = first_emoji .. growmoji_owned_line("sigh") .. growmoji_owned_line("mad") .. growmoji_owned_line("smile") .. growmoji_owned_line("tongue") .. growmoji_owned_line("wow")
  end
  if supp >= 1 then
    first_emoji = first_emoji .. growmoji_owned_line("no") .. growmoji_owned_line("shy") .. growmoji_owned_line("wink") .. growmoji_owned_line("music") .. growmoji_owned_line("lol")
  end
  if supp >= 2 then
    first_emoji = first_emoji .. growmoji_owned_line("yes") .. growmoji_owned_line("love") .. growmoji_owned_line("megaphone") .. growmoji_owned_line("heart") .. growmoji_owned_line("cool")
  end
  if friends >= 10 then
    first_emoji = first_emoji .. growmoji_owned_line("kiss")
  end
  if friends >= 20 then
    first_emoji = first_emoji .. growmoji_owned_line("agree")
  end
  if friends >= 30 then
    first_emoji = first_emoji .. growmoji_owned_line("see-no-evil")
  end
  if friends >= 40 then
    first_emoji = first_emoji .. growmoji_owned_line("dance")
  end
  if friends >= 50 then
    first_emoji = first_emoji .. growmoji_owned_line("build")
  end
  local emoji = ""
  local chest_title = ""
  local chest_have = ""
  local chest_dont_have = ""
  local gm = ""
  if p.getGrowmoji ~= nil then
    gm = p:getGrowmoji() or ""
  end
  for name, num in string.gmatch(gm, "%(([^%)]+)%)(%d*)") do
    local id = tonumber(num) or 0
    if GROWEMOJI_SPECIAL[name] then
      if id ~= 0 then
        first_emoji = first_emoji .. growmoji_owned_line(name)
      else
        emoji = emoji .. "\nadd_smalltext|`9This Growmoji can be found in a secret event.``|left|" .. growmoji_locked_line(name) .. "\nadd_spacer|small|"
      end
    elseif name == "trophy" then
      if id ~= 0 then
        first_emoji = first_emoji .. growmoji_owned_line(name)
      else
        emoji = emoji .. "\nadd_smalltext|`9This Growmoji can be obtained from a guild thats level 6.``|left|" .. growmoji_locked_line(name) .. "\nadd_spacer|small|"
      end
    else
      if id ~= 0 then
        chest_have = chest_have .. growmoji_owned_line(name)
      else
        chest_title = "\nadd_spacer|small|\nadd_smalltext|`9These Growmojis can be found in the Growmoji Chest sold by Locke the Traveling Salesman.``|left|"
        chest_dont_have = chest_dont_have .. growmoji_locked_line(name)
      end
    end
  end
  local s = profile_theme(p) .. "\n\nadd_label_with_icon|big|Growmojis|left|1366|" .. first_emoji .. chest_have
  if level < 5 then
    s = s .. "\nadd_spacer|small|\nadd_smalltext|`9You need to be Level 5 to get these Growmojis.``|left|" .. growmoji_locked_line("sigh") .. growmoji_locked_line("mad") .. growmoji_locked_line("smile") .. growmoji_locked_line("tongue") .. growmoji_locked_line("wow")
  end
  if supp < 1 then
    s = s .. "\nadd_spacer|small|\nadd_smalltext|`9You need to be a Supporter to get these Growmojis.``|left|" .. growmoji_locked_line("no") .. growmoji_locked_line("shy") .. growmoji_locked_line("wink") .. growmoji_locked_line("music") .. growmoji_locked_line("lol")
  end
  if supp < 2 then
    s = s .. "\nadd_spacer|small|\nadd_smalltext|`9You need to be a Super Supporter to get these Growmojis.``|left|" .. growmoji_locked_line("yes") .. growmoji_locked_line("love") .. growmoji_locked_line("megaphone") .. growmoji_locked_line("heart") .. growmoji_locked_line("cool")
  end
  if friends < 10 then
    s = s .. "\nadd_spacer|small|\nadd_smalltext|`9You need 10 friends to get this Growmoji.``|left|" .. growmoji_locked_line("kiss")
  end
  if friends < 20 then
    s = s .. "\nadd_spacer|small|\nadd_smalltext|`9You need 20 friends to get this Growmoji.``|left|" .. growmoji_locked_line("agree")
  end
  if friends < 30 then
    s = s .. "\nadd_spacer|small|\nadd_smalltext|`9You need 30 friends to get this Growmoji.``|left|" .. growmoji_locked_line("see-no-evil")
  end
  if friends < 40 then
    s = s .. "\nadd_spacer|small|\nadd_smalltext|`9You need 40 friends to get this Growmoji.``|left|" .. growmoji_locked_line("dance")
  end
  if friends < 50 then
    s = s .. "\nadd_spacer|small|\nadd_smalltext|`9You need 50 friends to get this Growmoji.``|left|" .. growmoji_locked_line("build")
  end
  s = s .. emoji .. chest_title .. chest_dont_have .. "\nadd_spacer|small|\n\nadd_quick_exit|end_dialog|worlds_list||Back|\n"
  p:onDialogRequest(s)
  return true
end

local function on_wrench(w, p, t)
  remember_target(p, t)
  return ProfileShowOther(p, t, w)
end

local function on_dialog(w, p, data, raw)
  local button = data.buttonClicked or ""
  if string.sub(button, 1, 9) == "userinfo_" then
    return ProfileShowUserInfo(p, string.sub(button, 10))
  end
  if string.sub(button, 1, 8) == "show_bp_" then
    return ProfileShowUserBp(p, string.sub(button, 9))
  end
  local name = GB.dialog_name(data, raw)
  if name == "Aparece_Otro" then
    local t = get_target(p)
    if button == "report_player" then
      return show_playerreport(p)
    end
    if t == nil then
      return false
    end
    if button == "trade" then
      if Shared.trade ~= nil and Shared.trade.startTrade ~= nil then
        if Shared.trade.startTrade(p, t) then
          return true
        end
      end
      return false
    end
    if button == "mute_player" or button == "unmute_player" then
      if p.setFriendMute ~= nil then
        p:setFriendMute(t:getName(), button == "mute_player")
        return true
      end
      return false
    end
    if button == "worldban" then
      if p.worldBanPlayer ~= nil then
        p:worldBanPlayer(t:getName())
        return true
      end
      return false
    end
    if button == "pull" then
      if p.pullPlayer ~= nil then
        p:pullPlayer(t:getName())
        return true
      end
      return false
    end
    if button == "kick" then
      if p.kickPlayer ~= nil then
        p:kickPlayer(t:getName())
        return true
      end
      return false
    end
    if button == "punish_view" then
      if p.getPlayerPunishInfo == nil then
        return false
      end
      local tname = ""
      if t ~= nil then
        tname = t:getName()
      end
      if (tname == nil or tname == "") and p.getLastWrenched ~= nil then
        tname = p:getLastWrenched() or ""
      end
      if tname == "" then
        return false
      end
      local info = p:getPlayerPunishInfo(tname)
      if info == nil or info == false then
        return true
      end
      if info.found ~= true then
        p:onTalkBubble(p:getNetID(), "Players not found!", 0)
        return true
      end
      return show_punish_view(p, info)
    end
    if button == "visit_home_world" then
      if p.getLastHomeWorld ~= nil then
        local home = p:getLastHomeWorld()
        if home ~= nil and home ~= "" then
          p:enterWorld(home)
          return true
        end
      end
      return false
    end
    if button == "view_worn_clothes" then
      return show_worn_clothes(p, t)
    end
    if button == "ignore_player" then
      return answer_ignore(p, t)
    end
    if button == "send_msg" then
      return show_send_message(p, t)
    end
    if button == "send_gems" then
      return show_pay(p, t)
    end
    if button == "start_surg" then
      if p.startSurgeryOn ~= nil then
        p:startSurgeryOn(t)
        return true
      end
      return false
    end
    if button == "invitetoguild" then
      if lower(p:getName()) == lower(t:getName()) then
        p:onConsoleMessage("Don't look now, but that person is `5IN YOUR HOUSE``!")
        return true
      end
      if p:getWorldName() ~= t:getWorldName() then
        p:onTalkBubble(p:getNetID(), "Hmm, that person left.", 0)
        return true
      end
      if p.inviteToGuild ~= nil then
        p:inviteToGuild(t:getName())
        return true
      end
      return false
    end
    if button == "friend_add" then
      return answer_friend_add(p, t)
    end
    return false
  end
  if name == "Send_Message" then
    if button == "send_message" then
      return do_send_msg(p, data.message or "")
    end
    if button == "backtoplayerwrench" then
      local t = get_target(p)
      if t ~= nil then
        return ProfileShowOther(p, t, p:getWorld())
      end
      return false
    end
    return false
  end
  if name == "PayDialog" then
    return answer_pay(p, data)
  end
  if name == "playerreport" or name == "worldreport" then
    return false
  end
  if name == "popup" then
    if button == "backto_wrench" or button == "info" then
      return ProfileShowSelf(p)
    end
    if button == "skill_and_assets" or button == "skills" then
      return ProfileShowSkillAssets(p)
    end
    if button == "road_to_glory" then
      if p.showWrenchTab == nil then
        return false
      end
      if p:showWrenchTab("road_to_glory") then
        return true
      end
      return false
    end
    if button == "kit_pass" or button == "kitz" then
      if p.showWrenchTab == nil then
        return false
      end
      if p:showWrenchTab("kit_pass") then
        return true
      end
      return false
    end
    if button == "level_rwds" or button == "levelup" then
      if p.showWrenchTab == nil then
        return false
      end
      if p:showWrenchTab("level_rwds") then
        return true
      end
      return false
    end
    if button == "game_menu" then
      if p.openGameMenu == nil then
        return false
      end
      if p:openGameMenu() then
        return true
      end
      return false
    end
    if button == "royal_winter_wonder" then
      if p.openRoyalWinter == nil then
        return false
      end
      p:openRoyalWinter()
      return true
    end
    if button == "get_card_battle" then
      return show_card_battle(p)
    end
    if button == "Get_License_Confirm" then
      if p.buyCardBattleLicense == nil then
        return false
      end
      local res = p:buyCardBattleLicense()
      if res == "already" then
        p:onTalkBubble(p:getNetID(), "You already have a Card Battle License!", 0)
      elseif res == "notenough" then
        p:onTalkBubble(p:getNetID(), "Don't have enough gems!", 0)
      end
      return true
    end
    if button == "fav_items" then
      return show_fav_items(p)
    end
    if button == "wrench_edit" then
      if p.openWrenchCustoms == nil then
        return false
      end
      if p:openWrenchCustoms() then
        return true
      end
      return false
    end
    if button == "guild_notebook_edit" then
      if p.guildAction == nil then
        return false
      end
      local d = p:guildAction("changeguildnotebook", "")
      if d ~= nil and d ~= "" then
        p:onDialogRequest(d)
      end
      return true
    end
    if button == "marvelous_missions" then
      if p.openMarvelousMissions == nil then
        return false
      end
      if p:openMarvelousMissions() then
        return true
      end
      return false
    end
    if button == "title_edit" then
      if Shared.title ~= nil and Shared.title.showTitleEdit ~= nil then
        return Shared.title.showTitleEdit(p)
      end
      return false
    end
    if button == "neck" or button == "feet" or button == "hand" then
      if p.toggleFlagmay == nil then
        return false
      end
      if p:toggleFlagmay(button) then
        return true
      end
      return false
    end
    if button == "Rift_Cape" then
      if p.openRiftCape == nil then
        return false
      end
      if p:openRiftCape() then
        return true
      end
      return false
    end
    if button == "Rift_Wings" then
      if p.openRiftWings == nil then
        return false
      end
      if p:openRiftWings() then
        return true
      end
      return false
    end
    if button == "panda_spirit" then
      if p.togglePandaSpirit == nil then
        return false
      end
      if p:togglePandaSpirit() then
        return true
      end
      return false
    end
    if button == "infinity_crown_edit" then
      if p.openInfinityCrown == nil then
        return false
      end
      if p:openInfinityCrown() then
        return true
      end
      return false
    end
    if button == "cernuous_mask_edit" then
      if p.openCernuousMask == nil then
        return false
      end
      if p:openCernuousMask() then
        return true
      end
      return false
    end
    if button == "bannerbandolier" then
      if p.openBannerBandolier == nil then
        return false
      end
      if p:openBannerBandolier() then
        return true
      end
      return false
    end
    if button == "acceptguild" then
      if p.acceptGuildInvite == nil then
        return false
      end
      p:acceptGuildInvite()
      return true
    end
    if button == "growmoji" then
      return show_growmoji(p)
    end
    if button == "online_status" then
      return ProfileShowOnlineStatus(p)
    end
    if button == "notebook_edit" then
      return ProfileShowNotebook(p)
    end
    if button == "seed_diary" then
      if p.openSeedDiary ~= nil then
        p:openSeedDiary()
        return true
      end
      return false
    end
    if button == "goals" then
      if GB.showDailyQuestInfoDialog ~= nil then
        GB.showDailyQuestInfoDialog(p)
        return true
      end
      return false
    end
    if button == "bonus" then
      if GB.showGrowPassDialog ~= nil then
        GB.showGrowPassDialog(p, "Tasks")
        return true
      end
      return false
    end
    if button == "my_worlds" then
      if Shared["worlds-nav"] ~= nil and Shared["worlds-nav"].show ~= nil then
        Shared["worlds-nav"].show(p)
        return true
      end
      return false
    end
    if button == "playing_music" then
      if GB.showSpotifyMenu ~= nil then
        GB.showSpotifyMenu(p, "custom", "1")
        return true
      end
      return false
    end
    if button == "open_worldlock_storage" or button == "Bank_Central" then
      if p.openBank ~= nil then
        p:openBank()
        return true
      end
      return false
    end
    if button == "wardrobe_customization" then
      if p.openWardrobe ~= nil then
        p:openWardrobe()
        return true
      end
      return false
    end
    if button == "trade_scan" then
      if Shared.tradescan ~= nil and Shared.tradescan.show ~= nil then
        Shared.tradescan.show(p)
        return true
      end
      return false
    end
    if button == "account_security" then
      if Shared.secureaccount ~= nil and Shared.secureaccount.show ~= nil then
        Shared.secureaccount.show(p, "my_account")
        return true
      end
      return false
    end
    if button == "Logout_MyAcc" then
      if p.disconnect ~= nil then
        p:disconnect()
        return true
      end
      return false
    end
    return false
  end
  if name == "online_status" then
    if p.setPStatus ~= nil then
      if data.checkbox_status_online == "1" then
        p:setPStatus(0)
      elseif data.checkbox_status_busy == "1" then
        p:setPStatus(1)
      elseif data.checkbox_status_away == "1" then
        p:setPStatus(2)
      end
      return ProfileShowSelf(p)
    end
    return false
  end
  if name == "notebook_edit" then
    if button == "cancel" then
      return ProfileShowSelf(p)
    end
    if button == "clear" then
      if p.setNote ~= nil then
        p:setNote("")
        return ProfileShowSelf(p)
      end
      return false
    end
    if button == "save" then
      if p.setNote ~= nil then
        local note = data.personal_note or ""
        if #note > 128 then
          return true
        end
        p:setNote(note)
        return ProfileShowSelf(p)
      end
      return false
    end
    return false
  end
  if name == "title_edit" then
    if Shared.title ~= nil and Shared.title.onDialog ~= nil then
      return Shared.title.onDialog(w, p, data, raw)
    end
    return false
  end
  return false
end

onWrench(on_wrench)
onDialog(on_dialog)
GB.register("profile", { version = 2, category = "system" })
Shared.profile.showOther = ProfileShowOther
Shared.profile.showSelf = ProfileShowSelf
Shared.profile.showUserInfo = ProfileShowUserInfo
Shared.profile.showUserBp = ProfileShowUserBp
Shared.profile.showSkillAssets = ProfileShowSkillAssets
Shared.profile.showOnlineStatus = ProfileShowOnlineStatus
Shared.profile.showNotebook = ProfileShowNotebook
print("[Lua] profile loaded")

function ProfileSendTo(p, name, msg)
  PROFILE_LAST[p:getID()] = { name = name, netID = 0 }
  return do_send_msg(p, msg)
end
Shared.profile.sendTo = ProfileSendTo