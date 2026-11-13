local function ghost_allowed(p)
  if p:getRoleLevel() > 0 then
    return true
  end
  if p:getRoleFlag("Owner") then
    return true
  end
  if isClist(p:getName()) then
    return true
  end
  if p:getRoleFlag("Staff") then
    return true
  end
  if p:isDeveloper() then
    return true
  end
  if p:isAdministrator() then
    return true
  end
  if p:isModerator() then
    return true
  end
  if p:isVip() then
    return true
  end
  if p:getRoleFlag("Donatur") then
    return true
  end
  if p:getRoleFlag("Streamers") then
    return true
  end
  if p:getRoleFlag("God") then
    return true
  end
  if p:getRoleFlag("Unlimited") then
    return true
  end
  if p:getRoleFlag("Coder") then
    return true
  end
  if p:hasConfigAccess() then
    return true
  end
  if p:getRoleFlag("GhostCommandAccess") then
    return true
  end
  return false
end

local function toggleGhostPlaymod(p, enable)
  -- 1. Sinkronkan flag engine
  if type(p.setGhost) == "function" then
    p:setGhost(enable)
  end
  if type(p.setNoclip) == "function" then
    p:setNoclip(enable)
  end

  -- 2. Pasang / cabut playmod "Ghost in the Shell" persis seperti /noclip agar client langsung normal
  if enable then
    if type(p.addMod) == "function" then
      p:addMod("Ghost in the Shell")
    end
  else
    if type(p.removeMod) == "function" then
      p:removeMod("Ghost in the Shell")
    end
  end
end

registerLuaCommand({
  command = "/ghost",
  description = "Toggle ghost mode",
  roleRequired = 0,
  callback = function(p, args)
    if string.find(p:getWorldName(), "GROWMINES", 1, true) ~= nil then
      return
    end
    if not ghost_allowed(p) then
      if p:getWorldName() == "" then
        p:onConsoleMessage("`4You can only use /ghost in your own world.")
        return
      end
      local w = p:getWorld()
      if w == nil or string.lower(w:getOwner() or "") ~= string.lower(p:getName()) then
        p:onConsoleMessage("`4Only the world owner can use /ghost here.")
        return
      end
    end

    p:sendActionPacket("action|play_sfx\nfile|audio/dialog_confirm.wav\ndelayMS|0")

    local currentlyGhost = false
    if type(p.hasMod) == "function" and p:hasMod("Ghost in the Shell") then
      currentlyGhost = true
    end
    if not currentlyGhost and type(p.getGhost) == "function" and p:getGhost() then
      currentlyGhost = true
    end

    local nextState = not currentlyGhost
    toggleGhostPlaymod(p, nextState)

    if nextState then
      p:onConsoleMessage("`oQuantum tunneling activated! (`$Ghost Mode ON``)")
    else
      p:onConsoleMessage("`oMolecular cohesion restored! (`$Ghost Mode OFF``)")
    end
  end
})

GB.register("cmd-ghost", { version = 1, category = "command" })