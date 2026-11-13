PROFILE_WRENCH = {  frames = {
    trade = 0,
    ignore = 1,
    worldban = 2,
    empty = 3,
    view_worn_clothes = 5,
    mute = 6,
    unmute = 7,
    friend_add = 8,
    punish_view = 9,
    pull = 10,
    kick = 11,
    send_msg = 12,
    send_gems = 13,
    trade_disabled = 14,
    report = 15,
    invitetoguild = 16,
    start_surg = 17
  },
  clothing_slots = { 7, 4, 0, 8, 1, 6, 2, 3, 5 },
  clothing_slots_full = { 0, 4, 8, 1, 6, 5, 2, 3, 9 },
  hospital_bed = 1256,
  surgery_recovery_playmod = 87,
  cheat_playmod = 143,
  max_gems = 2100000000,
  pay_max = 2000000000,
  wl_items = { [242] = 1, [1796] = 100, [7188] = 10000 },
  magical_lock = 8470,
  gem_icon = 112,
  msg_cooldown_seconds = 5
}
PROFILE_POPUP = {
  ezio = {
    feet = { item = 10618, button = "feet", image = "interface/large/gui_wrench_pps_transform.rttex" },
    ances = { item = 12634, button = "eq_aura", image = "interface/large/gui_wrench_eq_a.rttex" },
    back = {
      { item = 10424, button = "Rift_Cape", image = "interface/large/gui_wrench_rift_cape.rttex" },
      { item = 11478, button = "Rift_Wings", image = "interface/large/gui_wrench_rift_wings.rttex" },
      { item = 12640, button = "minokawa_wings", image = "interface/large/gui_wrench_mkw.rttex" },
      { item = 10182, button = "piano_wings_edit", image = "interface/large/gui_wrench_musical_wings.rttex" }
    },
    necklace = {
      { items = { 13220, 13196 }, button = "neck", image = "interface/large/gui_wrench_u2_transform.rttex" },
      { items = { 11560, 11554, 11556, 11558 }, button = "neck", image = "interface/large/gui_wrench_u_transform.rttex" },
      { items = { 11748 }, button = "bannerbandolier", image = "interface/large/gui_wrench_banner_bandolier.rttex" },
      { items = { 11818 }, button = "scarf_of_seasons_edit", image = "interface/large/gui_wrench_banner_seasons_item2.rttex" },
      { items = { 12648, 12646, 12650 }, button = "neck", image = "interface/large/gui_wrench_a15.rttex" }
    },
    hand = {
      { items = { 10952, 10954, 10956, 10958, 10960 }, button = "hand", image = "interface/large/gui_wrench_space_animals_transform.rttex" },
      { items = { 12866, 12868 }, button = "hand", image = "interface/large/gui_wrench_st_ani.rttex" },
      { items = { 12014, 12016, 12018, 12020 }, button = "hand", image = "interface/large/gui_wrench_st_transform.rttex" }
    },
    hair = {
      { item = 12958, button = "infinity_crown_edit", image = "interface/large/gui_wrench_icr.rttex" },
      { item = 10674, button = "cernuous_mask_edit", image = "interface/large/gui_wrench_crown_seasons.rttex" },
      { items = { 12872, 12874 }, button = "panda_spirit", image = "interface/large/gui_wrench_rpan.rttex" }
    }
  }
}
GB_DIALOGS = GB_DIALOGS or {}
GB_DIALOGS["profile_online"] = {
  lines = {
    { key = "header", text = [[add_progress_bar|`w{{player_name}}``|big|Level {{level}}|{{xp}}|{{xp_max}}|({{xp}}/{{xp_max}})|-3669761|]] },
    { key = "status", text = [[`oStatus: `2ONLINE``]] },
    { key = "gems", text = [[`oTotal Gems: {{gems}}]] },
    { key = "world_locks", text = [[`oTotal World Locks: {{world_locks}}]] },
    { key = "magical_locks", text = [[`oTotal Magical Gem Locks: {{magical_locks}}]] },
    { key = "bank", text = [[`oWorld Lock Bank: `2{{bank_locks}} WL]] },
    { key = "note", text = [[`5(Statistics refresh every minute in real -<CR>`5time)]]  },
  },
  buttons = {
    { action = "show_bp_{{player_name}}", label = [[`2Show Backpack / Inventory``]] },
    { action = "backto_richleaderboard", label = [[ `oBack``]] },
  },
}
GB_DIALOGS["profile_offline"] = {
  lines = {
    { key = "header", text = [[add_progress_bar|`w{{player_name}}``|big|Level {{level}}|{{xp}}|{{xp_max}}|({{xp}}/{{xp_max}})|-3669761|]] },
    { key = "status", text = [[`oStatus: `4OFFLINE``]] },
    { key = "gems", text = [[`oTotal Gems: {{gems}}]] },
    { key = "world_locks", text = [[`oTotal World Locks: {{world_locks}}]] },
    { key = "magical_locks", text = [[`oTotal Magical Gem Locks: {{magical_locks}}]] },
    { key = "bank", text = [[`oWorld Lock Bank: `2{{bank_locks}} WL]] },
    { key = "note", text = [[`5(Statistics refresh every minute in<CR>`5real-time)]]  },
  },
  buttons = {
    { action = "show_bp_{{player_name}}", label = [[`2Show Backpack / Inventory``]] },
    { action = "backto_richleaderboard", label = [[`oBack``]] },
  },
}
GB_DIALOGS["profile_backpack"] = {
  title = [[`wBackpack of {{player_name}}``]],
  buttons = {
    { action = "userinfo_{{player_name}}", label = [[`oBack to Profile``]] },
    { action = "backto_richleaderboard", label = [[`oBack to Leaderboard``]] },
  },
}
