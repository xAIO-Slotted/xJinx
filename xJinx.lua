-- xJinx by Jay and a bit of ampx.

local Jinx_VERSION = "1.1.7"
local Jinx_LUA_NAME = "xJinx.lua"
local Jinx_REPO_BASE_URL = "https://raw.githubusercontent.com/xAIO-Slotted/xJinx/main/"
local Jinx_REPO_SCRIPT_PATH = Jinx_REPO_BASE_URL .. Jinx_LUA_NAME
REQUIRE_SLOTTED_RESTART = false

local name = "xAIO - Jinx"

local std_math = math

local Idle_key = 0
local Combo_key = 1
local Lasthit = 2
local Clear_key = 3
local Harass_key = 4
local Flee = 5
local Recalling = 6
local Freeze = 7


Res = g_render:get_screensize()
Font = 'roboto-regular'

MinionInRange = {}
MinionToHarass = {}
SplashableTargetIndex = nil
SplashableMinionIndex = nil
MinionTable = {}
Last_Q_swap_time = g_time
Last_cast_time = g_time
Last_dbg_msg_time = g_time

local chanceStrings = {
  [0] = "low",
  [1] = "medium",
  [2] = "high",
  [3] = "very_high",
  [4] = "immobile"
}

local function add_jmenus()
  local jmenu = {}
  local navigation = menu.get_main_window():push_navigation(name, 10000)

  -- Sections
  local sections = {
    combo = navigation:add_section("combo"),
    harass = navigation:add_section("harass"),
    clear = navigation:add_section("farm"),
    agc = navigation:add_section("gap close"),
    auto = navigation:add_section("auto"),
    misc = navigation:add_section("misc"),
    draw = navigation:add_section("drawings"),
  }

  -- Combo
  jmenu.q_combo = sections.combo:checkbox("use Q", g_config:add_bool(true, "q_combo"))
  jmenu.q_combo_aoe = sections.combo:checkbox("^ try AOE", g_config:add_bool(true, "q_combo_aoe"))
  jmenu.q_combo_aoe_count = sections.combo:slider_int("^ if x enemies", g_config:add_int(3, "q_aoe_count"), 0, 5, 1)

  jmenu.w_combo = sections.combo:checkbox("use W", g_config:add_bool(true, "w_combo"))
  jmenu.w_combo_not_in_range = sections.combo:checkbox("^ if outside of aa range",
    g_config:add_bool(true, "w_combo_in_range"))
  jmenu.w_combo_hitchance = sections.combo:select("W hitchance", g_config:add_int(3, "w_combo_hitchance"),
    { "low", "medium", "high", "very_high", "immobile" })

  jmenu.e_combo = sections.combo:checkbox("use E", g_config:add_bool(true, "e_combo"))
  jmenu.e_combo_mode = sections.combo:select("E Logic:", g_config:add_int(1, "e_combo_mode"),
    { "always", "advanced", "undodgable" })

  -- Clear
  jmenu.q_clear = sections.clear:checkbox("use Q (minion of range)", g_config:add_bool(true, "q_clear"))
  jmenu.q_clear_aoe = sections.clear:checkbox("Q AOE (fast Lane Clear mode)", g_config:add_bool(true, "q_clear_aoe"))
  jmenu.q_clear_aoe_count = sections.clear:slider_int("^ if x enemies", g_config:add_int(3, "q_aoe_count"), 0, 5, 1)

  -- Harass
  jmenu.q_harass = sections.harass:checkbox("use Q", g_config:add_bool(true, "q_auto"))
  jmenu.checkboxJinxSplashHarass = sections.harass:checkbox("extend aa range with Q splash",
    g_config:add_bool(true, "splash_harass"))

  jmenu.w_harass = sections.harass:checkbox("use W", g_config:add_bool(true, "w_harass"))
  jmenu.w_harass_not_in_range = sections.harass:checkbox("^ if outside of aa range",
    g_config:add_bool(true, "w_combo_in_range"))
  jmenu.w_harass_hitchance = sections.harass:select("W hitchance", g_config:add_int(3, "w_combo_hitchance"),
    { "low", "medium", "high", "very_high", "immobile" })

  jmenu.e_harass = sections.harass:checkbox("use E", g_config:add_bool(true, "e_combo"))

  -- Auto
  jmenu.extend_q_auto = sections.auto:checkbox("Autonomous auto Q  minion splash harass",
    g_config:add_bool(true, "auto q splash harass"))

  jmenu.w_auto = sections.auto:checkbox("auto W Stasis/cc/immobile", g_config:add_bool(true, "w_auto"))
  jmenu.e_auto = sections.auto:checkbox("auto E Stasis/cc/immobile", g_config:add_bool(true, "e_auto"))

  jmenu.w_KS = sections.auto:checkbox("W KS", g_config:add_bool(true, "w_ks"))

  jmenu.r_KS = sections.auto:checkbox("R KS", g_config:add_bool(true, "r_ks"))
  jmenu.r_auto_base_ult_vision = sections.auto:checkbox("Base Ult in vision", g_config:add_bool(true, "r_auto_base_ult_vision"))

  jmenu.r_combo_multihit = sections.combo:checkbox("R Multihit combo", g_config:add_bool(true, "r_combo_multihit"))
  jmenu.r_KS_hitchance = sections.combo:select("R hitchance", g_config:add_int(3, "r_combo_hitchance"),
    { "low", "medium", "high", "very_high", "immobile" })
  jmenu.r_KS_dashless = sections.auto:checkbox("^ if no dash", g_config:add_bool(true, "r_auto_dashless"))


  -- AntiGapClose
  jmenu.w_agc = sections.agc:checkbox("W on AntiGapClose", g_config:add_bool(true, "W on dash"))
  jmenu.e_agc = sections.agc:checkbox("E on AntiGapClose", g_config:add_bool(true, "E on dash"))

  -- Dash blacklist
  jmenu.Dash_list = {}
  jmenu.Dash_list_cfg = {}
  jmenu.dash_blacklist = sections.auto:multi_select("^ dash blacklist", jmenu.Dash_list, jmenu.Dash_list_cfg)

  -- Misc
  jmenu.checkboxManR = sections.misc:checkbox("Manual Ult on U", g_config:add_bool(true, "Semi Auto Cast R"))
  jmenu.checkboxLanePressure = sections.misc:checkbox("draw Lane pressure", g_config:add_bool(true, "LANE"))
  -- Draw
  jmenu.checkboxDrawQ = sections.draw:checkbox("Draw alternate Q range",
    g_config:add_bool(true, "Draw alternate Q range"))
  jmenu.checkboxDrawW = sections.draw:checkbox("Draw W off cooldown", g_config:add_bool(true, "Draw W off cooldown"))

  return jmenu
end
local jmenu = add_jmenus()


function Prints(str, level)
  core.debug:Print(str, level)
end

local function fetch_remote_version_number()
  local command = "curl -s -H 'Cache-Control: no-cache, no-store, must-revalidate' " .. Jinx_REPO_SCRIPT_PATH
  local handle = io.popen(command)
  if not handle then
    print("Failed to fetch the remote version number.")
    return nil
  end
  local content = handle:read("*a")
  handle:close()

  if content == "" then
    print("Failed to fetch the remote version number.")
    return nil
  end

  local remote_version = content:match("VERSION%s*=%s*\"(%d+%.%d+%.%d+)\"")

  return remote_version
end

local function replace_current_file_with_latest_version(latest_version_script)
  local resources_path = cheat:get_resource_path()
  local current_file_path = resources_path:gsub("resources$", "lua/" .. Jinx_LUA_NAME)

  local file, errorMessage = io.open(current_file_path, "w")

  if not file then
    print("Failed to open the current file for writing. Error: ", errorMessage)
    return false
  end

  file:write(latest_version_script)
  file:close()

  return true
end

local function file_exists(path)
  local file = io.open(path, "r")
  if file then
    file:close()
    return true
  end
  return false
end

local function download_file(url, path)
  local command = "curl -s -L --create-dirs -o \"" .. path .. "\" " .. url
  -- local command = "curl -s -o \"" .. path .. "\" " .. url
  local handle = io.popen(command)
  if not handle then
    print("Failed to download the file.")
    return
  end
  handle:close()
end

local function check_for_prereqs()
  local resources_path = cheat:get_resource_path()
  local fonts_path = resources_path:gsub("resources$", "fonts")
  local corbel_path = fonts_path .. "/Corbel.ttf"
  local roboto_path = fonts_path .. "/Roboto-Regular.ttf"

  if not file_exists(corbel_path) then
    print("Corbel.ttf not found. Downloading...")
    REQUIRE_SLOTTED_RESTART = true
    download_file("https://github.com/xAIO-Slotted/xCore/raw/main/Corbel.ttf", corbel_path)
  else
    print("Corbel.ttf found.")
  end

  if not file_exists(roboto_path) then
    print("Roboto-Regular.ttf not found. Downloading...")
    REQUIRE_SLOTTED_RESTART = true
    download_file("https://github.com/xAIO-Slotted/xJinx/raw/main/Roboto-Regular.ttf", roboto_path)
  else
    print("Roboto-Regular.ttf found.")
  end

  local xcore_path = resources_path:gsub("resources$", "lua\\lib\\xCore.lua")
  if not file_exists(xcore_path) then
    print("xCore.lua not found. Downloading...")
    download_file("https://raw.githubusercontent.com/xAIO-Slotted/xCore/main/xCore.lua", xcore_path)
  else
    print("xCore.lua found.")
  end
  if REQUIRE_SLOTTED_RESTART then
    print("You did not have the fonts you will have to restart slotted, it will work next time though :D")
    print("You did not have the fonts you will have to restart slotted, it will work next time though :D")
    print("You did not have the fonts you will have to restart slotted, it will work next time though :D")
    print("You did not have the fonts you will have to restart slotted, it will work next time though :D")
    print("You did not have the fonts you will have to restart slotted, it will work next time though :D")
    print("You did not have the fonts you will have to restart slotted, it will work next time though :D")
    print("You did not have the fonts you will have to restart slotted, it will work next time though :D")
    print("You did not have the fonts you will have to restart slotted, it will work next time though :D")
    print("You did not have the fonts you will have to restart slotted, it will work next time though :D")
  end
end
local function check_for_update()
  local remote_version = fetch_remote_version_number()
  Prints("local version: " .. Jinx_VERSION .. " remote version: " .. remote_version, 0)
  if remote_version and remote_version > Jinx_VERSION then
    local command = "curl -s " .. Jinx_REPO_SCRIPT_PATH
    local handle = io.popen(command)
    if not handle then
      Prints("Failed to fetch the remote script.", 0)
      return
    end
    local latest_version_script = handle:read("*a")
    handle:close()


    if latest_version_script then
      if replace_current_file_with_latest_version(latest_version_script) then
        Prints("Please click reload lua ", 0)
        Prints("Successfully updated " .. Jinx_LUA_NAME .. " to version " .. remote_version .. ".", 0)
        Prints("Please click reload lua  ", 0)
        -- You may need to restart the program to use the updated script
      else
        Prints("Failed to update " .. Jinx_LUA_NAME .. ".", 0)
      end
    end
  else
    Prints("You are running the latest version of " .. Jinx_LUA_NAME .. ".", 0)
  end
end

local Data = {
  Q = {
    manaCost = { 20, 20, 20, 20, 20 },
    spell = g_local:get_spell_book():get_spell_slot(e_spell_slot.q),
    spellSlot = e_spell_slot.q,
    Range = { 80, 110, 140, 170, 200 },
    Level = 0,
  },
  W = {
    manaCost = { 40, 45, 50, 55, 60 },
    spell = g_local:get_spell_book():get_spell_slot(e_spell_slot.w),
    spellSlot = e_spell_slot.w,
    Range = 1450,
    Width = 120 / 2,
    castTime = 0.4,
    Damage = 0,
    Speed = 3300,
    Level = 0,
  },
  E = {
    manaCost = { 90, 90, 90, 90, 90 },
    spell = g_local:get_spell_book():get_spell_slot(e_spell_slot.e),
    spellSlot = e_spell_slot.e,
    Range = 925,
    Damage = g_local:get_attack_damage(),
    castTime = 0.9,
    Width = 100 / 2,
    Speed = 1700,
    Level = 0,
  },
  R = {
    manaCost = { 100, 100, 100, 100, 100 },
    spell = g_local:get_spell_book():get_spell_slot(e_spell_slot.r),
    spellSlot = e_spell_slot.r,
    Range = 3000,
    Width = 280 / 2,
    castTime = 0.6,
    Damage = 0,
    Speed = 1700,
    Level = 0,
  },
  AA = {
    Damage = g_local:get_attack_damage(),
    short_range = 0,
    long_range = 0,
    rocket_launcher = false,
    enemy_close = false,
    enemy_far = false,
  },
}

function Data:refresh_data()
  Prints("refreshing", 3)
  self['AA'].Damage = g_local:get_attack_damage()
  self['AA'].rocket_launcher = self:has_rocket_launcher()
  local range = g_local.attack_range + core.objects:get_bounding_radius(g_local)
  -- Prints("aa: " .. g_local.attack_range, 3)
  -- Prints("bound: " .. g_local:get_bounding_radius() + 15, 3)
  -- Prints("Q_level: " .. Data['Q'].Level,3)
  -- Prints("Long range:" .. range + (50 + (30 * Data['Q'].Level)),3)
  local long_range = range
  if Data['AA'].rocket_launcher then
    range = range - (50 + 30 * Data['Q'].Level)
  else
    long_range = range + (50 + 30 * Data['Q'].Level)
    -- 80 / 110 / 140 / 170 / 200
  end

  self['AA'].short_range = range

  self['AA'].long_range = long_range
  self['AA'].enemy_close = core.objects:is_enemy_near(range)
  self['AA'].enemy_far = core.objects:is_enemy_near(long_range)

  self['Q'].Level = g_local:get_spell_book():get_spell_slot(e_spell_slot.q).level
  self['Q'].spell = g_local:get_spell_book():get_spell_slot(e_spell_slot.q)
  self['Q'].spellSlot = e_spell_slot.q

  self['W'].Level = g_local:get_spell_book():get_spell_slot(e_spell_slot.w).level
  self['W'].spell = g_local:get_spell_book():get_spell_slot(e_spell_slot.w)
  self['W'].castTime = std_math.max(0.6 - 0.02 * std_math.floor(g_local.bonus_attack_speed / 0.25), 0.4)

  self['E'].Level = g_local:get_spell_book():get_spell_slot(e_spell_slot.e).level
  self['E'].spell = g_local:get_spell_book():get_spell_slot(e_spell_slot.e)
  self['E'].spellSlot = e_spell_slot.e

  self['R'].Level = g_local:get_spell_book():get_spell_slot(e_spell_slot.r).level
  self['R'].spell = g_local:get_spell_book():get_spell_slot(e_spell_slot.r)
  self['R'].spellSlot = e_spell_slot.r

  Prints("refreshed", 3)
end

function Data:has_rocket_launcher()
  local buffs = features.buff_cache:get_all_buffs(g_local.index)
  for _, buff in pairs(buffs) do
    if (buff.name == "JinxQ") then
      return true
    end
  end
  return false
end

function Data:in_range(spell, target)
  if target ~= nil and target.position:dist_to(g_local.position) <= self[spell].Range then
    return true
  else
    return false
  end
end

local function IsUnderTurret(pos)
  local range = 850
  for _, unit in pairs(features.entity_list:get_enemy_turrets()) do
    if unit ~= nil and not unit:is_dead() then
      local away = unit.position:dist_to(pos)
      if away < range then return true end
    end
  end
  return false
end

local function get_sorted_targets(enemies, damage_function, spell_data, delay)
  local targets = {}
  if #enemies == 0 then return targets end
  for i, enemy in pairs(enemies) do
    if enemy and core.helper:is_alive(enemy) then
      local delay = core.objects:get_aa_travel_time(enemy, g_local, 1700) + 0.35
      local hpPred = features.prediction:predict_health(enemy, delay, true)
      local dmg = damage_function(enemy)
      local hit = features.prediction:predict(enemy.index, spell_data.Range, spell_data.Speed, spell_data.Width, 0,
        g_local.position)

      table.insert(targets, { target = enemy, hp = hpPred, hitchance = hit.hitchance, damage = dmg })
    end
  end

  table.sort(targets, function(a, b)
    if a.hp == b.hp then
      return a.hitchance > b.hitchance
    else
      return a.hp < b.hp
    end
  end)

  return targets
end


local function get_sorted_w_targets(enemies)
  return get_sorted_targets(enemies, function(enemy)
    return core.damagelib:calc_spell_dmg("W", g_local, enemy, 1, Data['W'].Level)
  end, Data['W'], 0.4)
end

local function get_sorted_r_targets(enemies, delay)
  return get_sorted_targets(enemies, function(enemy)
    return core.damagelib:calc_spell_dmg("R", g_local, enemy, 1, Data['R'].Level)
  end, Data['R'], 0.55)
end

local function Get_target()
  -- if core.target_selector:GET_STATUS() then print("ts: true") else print("ts: false") end
  local target = core.target_selector:get_main_target()

  -- if we are on core ts return core ts else return get_default_target
  if core.target_selector:GET_STATUS() then
    target = core.target_selector:get_main_target()
    -- try even harder to find a target
    if target == nil or (target and g_local.position:dist_to(target.position) > 2000) then
      if core.objects:count_enemy_champs(2000) > 0 then
        print("get second try")
        target = core.target_selector:get_second_target(2000)
        print("get thirds try")
        
        if target == nil or (target and g_local.position:dist_to(target.position) > 2000) then
          local enemies = core.objects:get_enemy_champs(2000)
          local sorted = get_sorted_w_targets(enemies)
          if sorted and #sorted > 0 then
            if sorted[1] and sorted[1].position then
              target = sorted[1]
            end
          end
        end
      end
    end
  else
    target = features.target_selector:get_default_target()
  end

  if target == nil then
    -- Prints("no target", 1)
  end
  return target
end


-- <3 nenny
function Vec3_Rotate(c, p, angle)  -- Center, Point, Angle
  angle = angle * (math.pi / 180)
  local rotatedX = math.cos(angle) * (p.x - c.x) - math.sin(angle) * (p.z - c.z) + c.x
  local rotatedZ = math.sin(angle) * (p.x - c.x) + math.cos(angle) * (p.z - c.z) + c.z
  return vec3:new(rotatedX, p.y, rotatedZ)
end

local function get_e_vecs(start)
  local left = nil
  local right = nil
  if start then
    local offset = 180

    local dist = g_local.position:dist_to(start) + offset
    local rotater = g_local.position:extend(start, dist)

    --then we can rotate around the cursor pos
    left = Vec3_Rotate(start, rotater, 90)
    right = Vec3_Rotate(start, rotater, -90)
  end
  return left, start, right
end

local function count_hit_by_traps(center, enemies)
  local hit_count = 0
  local left, _, right = get_e_vecs(center)

  for i, enemy in pairs(enemies) do
    if enemy and core.helper:is_alive(enemy) then
      local e_hit = features.prediction:predict(enemy.index, Data['E'].Range, Data['E'].Speed, Data['E'].Width, 0,
        g_local.position)
      if e_hit.position:dist_to(center) < Data['E'].Width or e_hit.position:dist_to(left) < Data['E'].Width or e_hit.position:dist_to(right) < Data['E'].Width then
        hit_count = hit_count + 1
      end
    end
  end

  return hit_count
end


local function Visualize_spell_range()
  Prints("draw ranges", 3)
  if jmenu.checkboxDrawQ:get_value() then
    if Data['AA'].rocket_launcher then
      g_render:circle_3d(g_local.position, Colors.solid.blue, Data['AA'].short_range, 2, 50, 1)
    else
      g_render:circle_3d(g_local.position, Colors.solid.blue, Data['AA'].long_range, 2, 50, 1)
    end
  end
  if jmenu.checkboxDrawW:get_value() and core.objects:can_cast(e_spell_slot.w) then
    g_render:circle_3d(g_local.position, Colors.solid.blue, Data['W'].Range, 2, 50, 1)
  end
end

local function get_harass_minions_near(obj_hero_idx, range)
  Prints("get harass min near enter", 3)
  local obj_hero = features.entity_list:get_by_index(obj_hero_idx)
  local minions = features.entity_list:get_enemy_minions()
  --Prints("getting harass minions in range of " .. tostring(obj_hero:get_object_name()) .. " x= " .. tostring(range) )
  --Prints("getting harass minions out of " .. tostring(#minions))
  for i, obj_minion in ipairs(minions) do
    if obj_hero and obj_minion then
      if obj_hero and obj_minion and core.helper:is_alive(obj_minion) and obj_minion:is_visible() and obj_minion:is_minion() and obj_minion:is_targetable() then
        if true then -- (obj_minion:get_object_name() == "SRU_ChaosMinionRanged" or obj_minion:get_object_name() == "SRU_ChaosMinionMelee" or obj_minion:get_object_name() == "SRU_ChaosMinionSiege")
          local exists = 0
          --Prints(" i can see and is alive: " .. tostring(obj_minion:get_object_name()))
          if obj_hero.position:dist_to(obj_minion.position) < range then
            --Prints("i see one " .. tostring(obj_hero.position:dist_to(obj_minion.position)))
            if MinionTable and #MinionTable > 0 then
              -- Prints("checking if our list already has " .. obj_minion.index)
              for ii, alive in ipairs(MinionTable) do
                --Prints("have: " .. alive.idx .. " check: " .. obj_minion.index)
                if alive.idx == obj_minion.index then
                  --Prints("we do!", 1)
                  exists = 1
                end
              end
            end
          end
          if exists == 0 then
            table.insert(MinionTable, { idx = obj_minion.index })
          end
        end
        if MinionTable and #MinionTable > 0 then
          for ii, alive_idx in ipairs(MinionTable) do
            local remove = false
            local alive = features.entity_list:get_by_index(alive_idx.idx)
            if alive then
              if obj_hero.position:dist_to(alive.position) > range then remove = true end
              if core.helper:is_alive(alive) == false then remove = true end
              if alive:is_visible() == false then remove = true end
            else
              remove = true
            end
            if remove then
              table.remove(MinionTable, ii)
            end
          end
        end
      end
    end
  end
  -- Prints("after a full loop ive got... " .. tostring(#MinionTable))

  return true
end

local function show_splash_harass()
  if SplashabletargetIndex then
    Prints("draw harass", 3)
    local tgt = features.entity_list:get_by_index(SplashabletargetIndex)
    if tgt then

      get_harass_minions_near(SplashabletargetIndex, 235)
      -- circle the target
      g_render:circle_3d(tgt.position, Colors.solid.red, 235, 2, 90, 2)
      if MinionTable and #MinionTable > 0 then
        --Prints("splash?", 2)
        for ii, alive in ipairs(MinionTable) do
          local min = features.entity_list:get_by_index(alive.idx)
          if min then
            local hmm = min.position:extend(tgt.position, tgt.position:dist_to(min.position))
            -- print distance from tgt to min
            if tgt ~= nil and min ~= nil and tgt.position:dist_to(min.position) < 260 then g_render:line_3d(min.position,
                tgt.position, Colors.solid.red, 1) end
          end
        end
      end
    end
  end
  if SplashableMinionIndex then
    Prints("draw harass 2", 3)

    local min = features.entity_list:get_by_index(SplashableMinionIndex)
    if min then g_render:circle_3d(min.position, Colors.solid.green, 80, 2, 90, 2) end
  else
    Prints("no splashable minion to draw lines too ", 3)
  end
end

local function Draw()
  Prints("Draws", 3)
  if jmenu.checkboxJinxSplashHarass:get_value() then
    Prints("draw harass", 3)
    show_splash_harass()
  end
  if jmenu.checkboxDrawQ:get_value() or jmenu.checkboxDrawW:get_value() then
    Prints("draw Q", 3)
    Visualize_spell_range()
  end
end


local function ValidateSplashMinionAndtarget()
  if SplashabletargetIndex then
    local hero_obj = features.entity_list:get_by_index(SplashabletargetIndex)
    if g_local.position:dist_to(hero_obj.position) < Data['AA'].long_range + core.objects:get_bounding_radius(hero_obj) then
      SplashabletargetIndex = nil
    elseif hero_obj.position:dist_to(hero_obj.position) > Data['AA'].long_range + 260 + core.objects:get_bounding_radius(hero_obj) then
      SplashabletargetIndex = nil
    elseif core.helper:is_alive(hero_obj) == false then
      SplashabletargetIndex = nil
    elseif hero_obj:is_visible() == false then
      SplashabletargetIndex = nil
    end
    -- if SplashabletargetIndex then Prints("Splashable target valid", 1) else Prints("Splashable target removed", 1) end
    if SplashableMinionIndex then
      local min_obj = features.entity_list:get_by_index(SplashableMinionIndex)
      if g_local.position:dist_to(min_obj.position) > Data['AA'].long_range + core.objects:get_bounding_radius(min_obj) then
        SplashableMinionIndex = nil
      elseif hero_obj.position:dist_to(min_obj.position) > 235 then
        SplashableMinionIndex = nil
      elseif core.helper:is_alive(min_obj) == false then
        SplashableMinionIndex = nil
      elseif min_obj:is_visible() == false then
        SplashableMinionIndex = nil
      elseif min_obj:is_minion() == false then
        SplashableMinionIndex = nil
      elseif min_obj:is_targetable() == false then
        SplashableMinionIndex = nil
      end
      -- if SplashableMinionIndex then Prints("Splashable Minion valid", 1) else Prints("Splashable Minion removed", 1) end
    end
  end
end

local function FindSplashableMinion()
  local target = Get_target()
  if target == nil then return false end
  --update the global minion table nearby the target
  --Prints("finding splash minion", 1)
  get_harass_minions_near(target.index, 250)
  --get all the minions in AA range of me out of this table.
  if MinionTable and #MinionTable > 0 then
    for i, minionIdx in ipairs(MinionTable) do
      if SplashableMinionIndex == nil then
        local minion = features.entity_list:get_by_index(minionIdx.idx)
        if target.position:dist_to(minion.position) < 236 and g_local.position:dist_to(minion.position) < Data['AA'].long_range + core.objects:get_bounding_radius(minion) then
          --Prints("idx is minions is at " .. g_local.position:dist_to(minion.position))
          SplashableMinionIndex = minion.index
        end
      end
    end
  end
end

local function Get_minions(range)
  local minions_in_range = {}
  local all_enemy_minions = features.entity_list:get_enemy_minions()

  for _, minion in ipairs(all_enemy_minions) do
    if minion ~= nil and core.helper:is_alive(minion) and minion:is_visible() and minion:is_minion() and minion:is_targetable() then
      if g_local.position:dist_to(minion.position) <= range then
        table.insert(minions_in_range, minion)
      end
    end
  end

  return minions_in_range
end

local function Splash_harass()
  if jmenu.checkboxJinxSplashHarass:get_value() == false then return false end
  if features.orbwalker:is_in_attack() or features.evade:is_active() or not core.objects:can_cast(e_spell_slot.q) then return false end
  local target = Get_target()
  if target == nil then return false end
  SplashabletargetIndex = target.index
  ValidateSplashMinionAndtarget()

  --is target outside normal Q range?
  if core.helper:is_alive(target) and target:is_visible() and g_local.position:dist_to(target.position) > Data['AA'].long_range + core.objects:get_bounding_radius(target) then
    if g_local.position:dist_to(target.position) < Data['AA'].long_range + 260 + core.objects:get_bounding_radius(target) then
      Prints("target is inside splash range.", 3)
      -- if we already have a splash minion then why are we still searching
      if SplashableMinionIndex == nil then FindSplashableMinion() end
      -- we may have found a minion so
      if SplashableMinionIndex then
        Prints("splash minion found", 3)
        local min_obj = features.entity_list:get_by_index(SplashableMinionIndex)
        if min_obj then
          if features.orbwalker:get_mode() == Harass_key or jmenu.extend_q_auto:get_value() then
            local min_pred = features.prediction:predict(SplashableMinionIndex, Data['AA'].long_range + core.objects:get_bounding_radius(min_obj), 1500, 0,g_local.attack_speed, g_local.position)
            local nme_pred = features.prediction:predict(target.index, Data['AA'].long_range + core.objects:get_bounding_radius(target) , 1500, 0,
              g_local.attack_speed, g_local.position)
            
            if g_local.position:dist_to(min_pred.position) < Data['AA'].long_range + core.objects:get_bounding_radius(min_obj) then
              if nme_pred.position:dist_to(min_pred.position) < 235 then
                Prints("sending extendo attack to " .. min_obj:get_object_name(), 2)
                if Data['AA'].rocket_launcher == false then 
                  g_input:cast_spell(e_spell_slot.q) 
                  features.orbwalker:set_cast_time(0.25)
                end
                print("go")
                if features.orbwalker:can_attack() and not features.orbwalker:is_in_attack() then
                  g_input:issue_order_attack(min_obj.network_id)
                  -- features.orbwalker:send_attack(min_obj.network_id)
                end
                return true
              end
            end
          end
        end
      end
    end
  end
end

local function IsBadTarget(target_index)
  return features.target_selector:is_bad_target(target_index)
end
local function enemy_buff_name() --- prints all ally buffs names
  for i, ally in pairs(features.entity_list:get_enemies()) do
    for j, buff in pairs(features.buff_cache:get_all_buffs(ally.index)) do
      Prints(ally.champion_name.text .. " buff: " .. buff.name)
      print("active: " .. tostring(buff.active))
      print("hard_cc: " .. tostring(buff.hard_cc))
      print("disabling: " .. tostring(buff.disabling))
      print("knock_up: " .. tostring(buff.knock_up))
      print("silence: " .. tostring(buff.silence))
      print("cripple: " .. tostring(buff.cripple))
      print("invincible: " .. tostring(buff.invincible))
      print("slow: " .. tostring(buff.slow))
      print("type: " .. tostring(buff.type))
      print("start_time: " .. tostring(buff.start_time))
      print("end_time: " .. tostring(buff.end_time))
      print("alt_amount: " .. tostring(buff.alt_amount))
      print("name: " .. tostring(buff.name))
      print("amount: " .. tostring(buff.amount))
    end
  end
end
local function PrintBuffs()
  if g_input:is_key_pressed(85) == true then
    if g_input:is_key_pressed(85) == true then
      enemy_buff_name() -- prints all enemy buffs names
    end
  end
end
local function Time_remaining_for_dash(cai)
  local dx = cai.path_end.x - cai.path_start.x
  local dy = cai.path_end.y - cai.path_start.y
  local dz = cai.path_end.z - cai.path_start.z

  local distance = std_math.sqrt(dx * dx + dy * dy + dz * dz)
  local time_remaining = distance / cai.dash_speed

  return time_remaining
end


local function OnDash(index)
  local tgt = features.entity_list:get_by_index(index)
  local champion_name = string.lower(tgt.champion_name.text)
  local cai = tgt:get_ai_manager()
  local spell_book = tgt:get_spell_book()
  local cast_info = spell_book:get_spell_cast_info()

  if (jmenu.e_agc:get_value() or jmenu.e_agc:get_value()) then
    -- 	local has_dash = core.database:has_dash(tgt)

    --     if cast_info ~= nil and has_dash then
    --       Prints(champion_name .. ": enter cast check" .. tostring(cast_info.slot), 2)
    --       local casted_slot = cast_info.slot
    --       if casted_slot >= 0 and casted_slot <= 50  then
    --         Prints("looking at " .. string.lower(tgt.champion_name.text), 1)
    -- 		Prints("casted slot: " .. tostring(cast_info.name), 1)
    --         Prints("casted slot: " .. tostring(cast_info.slot), 1)

    --         -- Check if the local champion is in the dash_list_cfg
    --         local is_dash = false

    -- 		local champion_dash_list = core.database.DASH_LIST[champion_name]
    -- 		if champion_dash_list ~= nil then
    -- 		  for _, ability_slot in ipairs(champion_dash_list) do
    -- 			if casted_slot == ability_slot then
    -- 			  is_dash = true
    -- 			  break
    -- 			end
    -- 		  end
    -- 		end

    --         if is_dash then Prints(tostring(casted_slot) .. " is a dash!!!") else Prints(tostring(casted_slot) .. " is not a dash") end
    --       else Prints(champion_name .. ": slot came back -1", 3) end
    --     else Prints(champion_name .. ": no cast info", 3) end
  end


  if (jmenu.e_agc:get_value() or jmenu.e_agc:get_value()) and cai.is_dashing then
    Prints("checking for dashes", 2)
    if g_local.position:dist_to(cai.path_end) > Data['W'].Range then
      Prints("is dashing out of range of w :(", 2)
      return false
    end
    Prints("is dashing...", 2)
    local time_remaining = Time_remaining_for_dash(cai)
    Prints("Time Remaining: " .. tostring(time_remaining), 2)
    local trapped = false

    if jmenu.e_agc:get_value() and time_remaining > (Data['E'].castTime - 0.5) and g_local.position:dist_to(cai.path_end) < Data['E'].Range and core.objects:can_cast(e_spell_slot.e) then
      g_input:cast_spell(e_spell_slot.e, cai.path_end)
      features.orbwalker:set_cast_time(0.25)
      Last_cast_time = g_time
      return true
    end

    -- dont w under tower unless already in combo mode
    if (IsUnderTurret(g_local.position) and not features.orbwalker:get_mode() == Combo_key) then return false end

    if jmenu.w_agc:get_value() and time_remaining > (Data['W'].castTime - 0.5) and core.objects:can_cast(e_spell_slot.w) then
      local minion_block = features.prediction:minion_in_line(g_local.position, cai.path_end, 120)
      if not minion_block and g_local.position:dist_to(cai.path_end) > 300 then
        g_input:cast_spell(e_spell_slot.w, cai.path_end)
        Prints("attempted to cast W", 2)
        return true
      end
    end

    return false
  end
  Prints("exit OnDash", 3)
end

local function Has_stasis(enemy)
  local stasis_end_time = 0
  local has_stasis = false

  for _, buff in ipairs(features.buff_cache:get_all_buffs(enemy.index)) do
    if buff.name == "ChronoRevive" or buff.name == "ZhonyasRingShield" then
      stasis_end_time = buff.end_time
      Prints(
      "found stasis of type" ..
      buff.name .. " ending at " .. tostring(stasis_end_time) .. " on " .. enemy.champion_name.text, 3)
      has_stasis = true
    end
  end

  return has_stasis, stasis_end_time
end

local function On_stasis_special_channel(index)
  local enemy = features.entity_list:get_by_index(index)
  if enemy then
    local has_stasis_buff, stasis_end_time = Has_stasis(enemy)
    if has_stasis_buff then
      local should_cast_w = false
      local should_cast_e = false

      if jmenu.w_auto:get_value() and core.objects:can_cast(e_spell_slot.w) and Data:in_range('W', enemy) then
        should_cast_w = true
      end

      if jmenu.e_auto:get_value() and core.objects:can_cast(e_spell_slot.e) and Data:in_range('E', enemy) then
        should_cast_e = true
      end
      if should_cast_e == false and should_cast_w == false then return end
      local remaining_stasis_time = stasis_end_time - g_time

      if should_cast_e or should_cast_w then
        Prints("okay lets try hand stasis", 3)
        if should_cast_e then
          local time_to_cast_e = 0.9
          Prints("E stasis cast: " .. tostring(remaining_stasis_time), 2)
          if remaining_stasis_time <= time_to_cast_e then
            local eHit = features.prediction:predict(enemy.index, Data['E'].Range, Data['E'].Speed, Data['E'].Width, 0,
              g_local.position)
            if eHit.valid and eHit.hitchance >= 2 then
              g_input:cast_spell(e_spell_slot.e, eHit.position)
              features.orbwalker:set_cast_time(0.25)
              Last_cast_time = g_time
              return true
            end
          end
        end

        if should_cast_w then
          Prints("okay lets try hand w stasis", 2)

          local time_to_cast_w = g_time + remaining_stasis_time - Data['W'].castTime
          Prints("we want to cast at: " .. tostring(time_to_cast_w) .. "now it's: " .. tostring(g_time), 2)

          if g_time >= time_to_cast_w and g_time <= time_to_cast_w + 0.25 then
            Prints("Stasis: casting w for stasis g_time:" .. tostring(g_time), 2)
            local wHit = features.prediction:predict(enemy.index, Data['W'].Range, Data['W'].Speed, Data['W'].Width, 0,
              g_local.position)
            local minion_block = features.prediction:minion_in_line(g_local.position, wHit.position, 120)

            if wHit.valid and wHit.hitchance >= 2 and not minion_block then
              Prints("stasis: casting w hitchance is " .. chanceStrings[wHit.hitchance], 2)
              g_input:cast_spell(e_spell_slot.w, wHit.position)
              features.orbwalker:set_cast_time(0.25)
              Last_cast_time = g_time
              return true
            end
          end
        end
      end
    end
  end
end
local function On_cc_special_channel(index)
  if g_local:is_recalling() then return false end
  Prints("cc check", 3)
  local enemy = features.entity_list:get_by_index(index)
  if enemy then
    local cai = enemy:get_ai_manager()
    -- w_auto
    -- w_auto_cc  w_auto_channel w_auto_special
    if core.helper:is_alive(enemy) and not enemy:is_invisible() then
      Prints("checking if " .. enemy:get_object_name() .. " is ccd or immobile or stasis", 3)
      local should_cast_w = false
      local should_cast_e = false

      local is_immobile = false
      local is_ccd = false
      --local is_channeling = false

      if features.buff_cache:is_immobile(enemy.index) then is_ccd = true end
      if features.buff_cache:has_hard_cc(enemy.index) then is_immobile = true end
      if Has_stasis(enemy) then return On_stasis_special_channel(index) end

      if is_immobile or is_ccd then
        Prints("is ccd or immobile looking to cast", 2)

        if jmenu.w_auto:get_value() and core.objects:can_cast(e_spell_slot.w) and Data:in_range('W', enemy) then
          should_cast_w = true
        end
        -- please dont laser under enemy tower lol
        if (IsUnderTurret(g_local.position) and not features.orbwalker:get_mode() == Combo_key) then
          should_cast_w = false
        end

        if jmenu.e_auto:get_value() and core.objects:can_cast(e_spell_slot.e) and Data:in_range('E', enemy) then
          should_cast_e = true
        end
      end
      if should_cast_e or should_cast_w then
        Prints("lets cast something", 2)
        
        if jmenu.e_auto:get_value() and core.objects:can_cast(e_spell_slot.e) and Data:in_range('E', enemy) then
          local eHit = features.prediction:predict(enemy.index, Data['E'].Range, Data['E'].Speed,
            Data['E'].Width, 0,
            g_local.position)
          if eHit.valid and eHit.hitchance >= 2 then
            g_input:cast_spell(e_spell_slot.e, eHit.position)
          end
          features.orbwalker:set_cast_time(0.25)
          Last_cast_time = g_time
        end
        Prints("lets cast something 2", 2)
        if jmenu.w_auto:get_value() and core.objects:can_cast(e_spell_slot.w) and Data:in_range('W', enemy) then
          local wHit = features.prediction:predict(enemy.index, Data['W'].Range, Data['W'].Speed,
            Data['W'].Width, 0,
            g_local.position)
          local minion_block = features.prediction:minion_in_line(g_local.position, wHit.position, 120)
          if wHit.valid and wHit.hitchance >= 2 and not minion_block then
            Prints("casting w hitchance is " .. chanceStrings[wHit.hitchance], 2)
            g_input:cast_spell(e_spell_slot.w, wHit.position)
            features.orbwalker:set_cast_time(0.25)
            Last_cast_time = g_time
          end
        end
      end
    end
  end
end

Recalling = {}
local function ProcessRecall()
  for i, recall in ipairs(Recalling) do
    local obj = features.entity_list:get_by_index(recall.champ)
    if g_time > recall.end_time or (obj:is_visible() and not obj:is_recalling()) then
      print("removing recall: " .. obj:get_object_name())
      table.remove(Recalling, i)
    end
  end
  
  local hero_Table = features.entity_list:get_enemies()
  for i, obj_hero in ipairs(hero_Table) do
    if obj_hero and core.helper:is_alive(obj_hero) and not obj_hero:is_invisible() then
      local spell_book = obj_hero:get_spell_book()
      local cast_info = spell_book:get_spell_cast_info()
      if obj_hero:is_recalling() then
        local recallIndex = nil
        for ii, recall in pairs(Recalling) do
          if recall.champ == obj_hero.index then
            recallIndex = ii
            break
          end
        end
        if cast_info and cast_info.slot and cast_info.slot == 13 then
          local end_time = cast_info.end_time -- calculate recall end time
          local recallData = { champ = obj_hero.index, position = obj_hero.position, start = g_time, end_time = end_time }
          if recallIndex then
            -- Update existing recall
            Recalling[recallIndex] = recallData
          else
            -- Add new recall
            table.insert(Recalling, recallData)
          end
        end
      end
    end
  end
end


local function Refresh() Data:refresh_data() end

local function calculate_projectile_travel_time(distance)
  local r_speed_1 = 1700  -- Initial speed
  local r_speed_2 = 2200  -- Speed after 1350 units
  local r_acceleration_distance = 1350  -- Distance at which speed changes

  local time = 0
  
  if distance <= r_acceleration_distance then
    -- If distance is less than or equal to 1350, use the first speed
    time = distance / r_speed_1
  else
    -- If distance is more than 1350, calculate the time for the first 1350 units, then add the time for the remaining distance with the second speed
    local time_1 = r_acceleration_distance / r_speed_1
    local time_2 = (distance - r_acceleration_distance) / r_speed_2
    time = time_1 + time_2
  end

  return time
end
local function baseult()
  local should_baseUlt = jmenu.r_auto_base_ult_vision:get_value() and
      not core.objects:is_enemy_near(Data['AA'].short_range) and not g_input:is_key_pressed(17) and
      core.objects:can_cast(e_spell_slot.r)
  if not should_baseUlt then return end
  ProcessRecall()
  if #Recalling == 0 then return end

  local delay = 0.015

  for i, recall in pairs(Recalling) do
    local enemy = features.entity_list:get_by_index(recall.champ)
    if not enemy then return end
    local rdmg = core.damagelib:calc_spell_dmg("R", g_local, enemy, 1, core.objects:get_spell_level(e_spell_slot.r))

    if enemy.health + 30 > rdmg then
      return false
    end

    local remainingTime = (recall.end_time - g_time)

    local enemy_dist = g_local.position:dist_to(recall.position)

    local enemy_base_position = core.objects:get_baseult_pos(enemy)
    local base_dist = g_local.position:dist_to(enemy_base_position)

    local time_To_hit_enemy = 0.692 + calculate_projectile_travel_time(enemy_dist) + delay
    local time_To_hit_base = 0.5 + calculate_projectile_travel_time(base_dist) + delay

    if (remainingTime >= time_To_hit_enemy) or (remainingTime >= time_To_hit_base) then
      print("looking for a recall ult... " .. tostring(remainingTime),3)
      -- start with try to hit enemy
      if not core.vec3_util:is_colliding(g_local.position, recall.position, enemy, Data['R'].Width) then
        Prints("trying to hit enemy with recall ulti hold control to cancel .. " .. time_To_hit_enemy, 2)
        if remainingTime >= time_To_hit_enemy and remainingTime <= 6 then

          Prints("-=--==-=--= RECALL ULT =--=-==-=--=", 2)
          g_input:cast_spell(e_spell_slot.r, recall.position)
          features.orbwalker:set_cast_time(0.25)
          return true
        end
      end if not core.vec3_util:is_colliding(g_local.position, enemy_base_position, enemy, Data['R'].Width) then
        Prints("trying to hit base with recall ulti hold control to cancel .. " .. tostring(time_To_hit_base), 2)
        if math.abs(remainingTime - time_To_hit_base) <= 0.05 then

          print("-=--==-=--= BASE ULT =--=-==-=--=", 2)
          g_input:cast_spell(e_spell_slot.r, enemy_base_position)
          features.orbwalker:set_cast_time(0.25)
          return true
        end
      end
    end
  end
end

local function OnTick()
  if core.objects:can_cast(e_spell_slot.r) and jmenu.r_auto_base_ult_vision:get_value() then
    baseult() 
  end
  
  if g_time - Last_cast_time <= 0.05 then return end
  if g_local:is_recalling() then return false end
  Prints("tick...", 3)
  for i, enemy in pairs(features.entity_list:get_enemies()) do
    if core.helper:is_alive(enemy) and enemy:is_visible() and g_local.position:dist_to(enemy.position) < 3000 then
      --Prints("check dash", 2)
      if not features.orbwalker:is_in_attack() and not features.evade:is_active() and not core.helper:is_invincible(enemy) then
        -- if is dashing
        Prints("check dash is dashing", 3)
        OnDash(enemy.index)
        if enemy:get_ai_manager().is_dashing then
        end
        --chain cc
        On_cc_special_channel(enemy.index)
      end
    end
  end
  Prints("tick exit", 3)
end

local function fakeorbwalk()
-- if mode clear and orbwalker 




end


local function exit_rocket_logic()
  local mode = features.orbwalker:get_mode()
  if Data['AA'].rocket_launcher and not features.orbwalker:is_in_attack() and mode ~= Combo_key and mode ~= Idle_key and jmenu.q_clear:get_value() then
    if mode == Harass_key and Data['AA'].enemy_far then
      return false
    end
    if g_time - Last_Q_swap_time > 3.5 then
      Prints("exit rocket mode, bored", 2)
      g_input:cast_spell(e_spell_slot.q)
      Last_Q_swap_time = g_time
      return true
    end
  end
  return false
end
local function save_minion_with_q()
  if not Data['AA'].rocket_launcher and features.orbwalker:can_attack() then
    Prints("getting mins in long range", 3)

    local minions_in_range = Get_minions((Data['AA'].long_range + 35))
    for _, minion in ipairs(minions_in_range) do
      if g_local.position:dist_to(minion.position) > Data['AA'].short_range + 35 then
        local delay = core.objects:get_aa_travel_time(minion, g_local, 1700) + 0.35
        local hpPred = features.prediction:predict_health(minion, delay, true)
        if hpPred ~= minion.health then
          local aa_dmg = core.damagelib:calc_aa_dmg(g_local, minion)

          if hpPred < aa_dmg * 1.1 and hpPred > 5 then
            Prints("Forcing target for q clear save", 2)
            g_input:cast_spell(e_spell_slot.q)
            Last_Q_swap_time = g_time
            g_input:issue_order_attack(minion.network_id)
            return true
          end
        end
      end
    end
  end
end
local function combo_harass_q()
  local target = Get_target()
 
  -- aoe splash logic
  if jmenu.q_combo_aoe:get_value() and target and core.objects:count_enemy_champs(250, target.position) >= jmenu.q_combo_aoe_count:get_value() then
    if not Data['AA'].rocket_launcher then
      g_input:cast_spell(e_spell_slot.q)
      Last_Q_swap_time = g_time
      return true
    end
    -- we need more range...
  else 
    if (not Data['AA'].rocket_launcher and Data['AA'].enemy_far and not Data['AA'].enemy_close) then
      g_input:cast_spell(e_spell_slot.q)
      Last_Q_swap_time = g_time
    else
      if (Data['AA'].rocket_launcher and Data['AA'].enemy_far and Data['AA'].enemy_close) then
        -- we need more attack speed...
        g_input:cast_spell(e_spell_slot.q)
        Last_Q_swap_time = g_time
        return true
      end
    end
  end
end
local function fast_clear_aoe_Logic()
  return false
end
local function should_skip_w_cast()
  local target = Get_target()
  local in_Q_range = target.position:dist_to(g_local.position) <= Data['AA'].long_range + 15
  if not in_Q_range then return false end

  local mode = features.orbwalker:get_mode()
  local full_combo = g_input:is_key_pressed(17)
  local should_w_in_aa_range = jmenu.w_combo_not_in_range:get_value()
  if mode == Harass_key then should_w_in_aa_range = jmenu.w_harass_not_in_range:get_value() end
  local aadmg = core.damagelib:calc_aa_dmg(g_local, target)
  local aa_to_kill = std_math.ceil(target.health / aadmg)
  local near_death = aa_to_kill <= 2
  local can_weave = features.orbwalker:should_reset_aa()
  if full_combo and mode == Combo_key then should_w_in_aa_range = true end


  if in_Q_range then
    if not can_weave or not should_w_in_aa_range or near_death then
      return true
    end
  end

  return false
end

local function get_w_hitchance_setting()
  local mode = features.orbwalker:get_mode()
  local chance = jmenu.w_combo_hitchance:get_value()
  -- if we're in harass mode, use the harass hitchance setting
  if mode == Harass_key then
    chance = jmenu.w_harass_hitchance:get_value()
    -- if we're in combo mode and we're holding control key, force w to go off
  elseif g_input:is_key_pressed(17) then
    chance = 0
  end
  return chance
end

local function w_combo_harass_logic()
  local target = Get_target()
  if target == nil then return false end

  if should_skip_w_cast() then return false end

  local wHit = features.prediction:predict(target.index, Data['W'].Range, Data['W'].Speed, Data['W'].Width,
    Data['W'].castTime, g_local.position)

  local minion_block = features.prediction:minion_in_line(g_local.position, wHit.position, 120)

  if wHit.valid and (wHit.hitchance >= get_w_hitchance_setting()) and not minion_block then
    Prints("combo: casting w hitchance is " .. chanceStrings[wHit.hitchance], 2)
    g_input:cast_spell(e_spell_slot.w, wHit.position)
    return true
  end


  return false
end





local function get_semi_auto_r_target(sorted_targets)
  if #sorted_targets > 0 then
    return sorted_targets[1].target
  else
    return nil
  end
end

local function w_ks_logic()
  local enemies = core.objects:get_enemy_champs(Data['W'].Range)
  local sorted_targets = get_sorted_w_targets(enemies)     -- adjust delay as needed
  local ks_w_hitchance = 3

  for _, target_info in ipairs(sorted_targets) do
    if target_info.damage > target_info.hp + 15 and target_info.hp > 1 and target_info.hitchance > ks_w_hitchance then
      local wHit = features.prediction:predict(target_info.target.index, Data['W'].Range, Data['W'].Speed,
        Data['W'].Width, 0, g_local.position)
      local minion_block = features.prediction:minion_in_line(g_local.position, wHit.position, 120)
      if wHit.valid and wHit.hitchance >= ks_w_hitchance and not minion_block then
        Prints("KS: casting w hitchance is " .. chanceStrings[wHit.hitchance], 2)
        g_input:cast_spell(e_spell_slot.w, wHit.position)
        features.orbwalker:set_cast_time(0.25)
        Last_cast_time = g_time
        return true
      end
    end
  end
end

local function should_r_ks(sorted_targets)
  for _, target_info in ipairs(sorted_targets) do
    if target_info.damage > target_info.hp + 15 and target_info.hp > 1 and target_info.hitchance > jmenu.r_KS_hitchance:get_value() then
      local rHit = features.prediction:predict(target_info.target.index, Data['R'].Range, Data['R'].Speed,
        Data['R'].Width, 0, g_local.position)
      if rHit.valid and rHit.hitchance >= jmenu.r_KS_hitchance:get_value() then
        Prints("KS: casting r hitchance is " .. chanceStrings[rHit.hitchance], 2)
        g_input:cast_spell(e_spell_slot.r, rHit.position)
        features.orbwalker:set_cast_time(0.25)
        Last_cast_time = g_time
        return true
      end
    end
  end
  return false
end

local function try_semi_auto_r(sorted_targets)
  local semi_auto_r_target = get_semi_auto_r_target(sorted_targets)
  if semi_auto_r_target then
    local rHit = features.prediction:predict(semi_auto_r_target.index, Data['R'].Range, Data['R'].Speed, Data['R'].Width,
      0, g_local.position)
    if rHit.valid then
      g_input:cast_spell(e_spell_slot.r, rHit.position)
      features.orbwalker:set_cast_time(0.25)
      Last_cast_time = g_time
      return true
    end
  end
  return false
end
local function should_e_multihit()
  local enemies = core.objects:get_enemy_champs(Data['E'].Range - 50)

  for _, enemy in ipairs(enemies) do
    if enemy and core.helper:is_alive(enemy) then
      local e_hit = features.prediction:predict(enemy.index, Data['E'].Range, Data['E'].Speed, Data['E'].Width, 0,
        g_local.position)
      if e_hit.valid and e_hit.hitchance >= 2 then
        local hit_count = count_hit_by_traps(e_hit.position, enemies)
        if hit_count > 1 then
          Prints("Casting E to hit " .. hit_count .. " enemies", 2)
          g_input:cast_spell(e_spell_slot.e, e_hit.position)
          features.orbwalker:set_cast_time(0.25)
          Last_cast_time = g_time
          return true
        end
      end
    end
  end

  return false
end


local function should_e_slowed()
  local target = Get_target()
  if target and core.helper:is_alive(target) then
    local e_hit = features.prediction:predict(target.index, Data['E'].Range, Data['E'].Speed, Data['E'].Width, 0,
      g_local.position)
    if e_hit.valid and e_hit.hitchance >= 2 and features.buff_cache:has_buff_of_type(target.index, e_buff_type.slow) then
      g_input:cast_spell(e_spell_slot.e, e_hit.position)
      Prints("Casting E on slowed target", 2)
      features.orbwalker:set_cast_time(0.25)
      Last_cast_time = g_time
      return true
    end
  end
  return false
end

local function try_r_multihit(sorted_targets)
  if not core.objects:can_cast(e_spell_slot.r) then
    return false
  end

  for i, enemy in pairs(sorted_targets) do
    local rHit = features.prediction:predict(enemy.target.index, Data['R'].Range, Data['R'].Speed, Data['R'].Width, 0, g_local.position)
    local bad_hit =  core.vec3_util:is_colliding(g_local.position, enemy.target.position, enemy.target, Data['R'].Width)

    local allies_to_follow = #core.objects:get_ally_champs(800, enemy.target.position) or 0
    local splashable_targets = core.objects:get_enemy_champs(400, enemy.target.position)
    local good_splashables = 0

    for _, splash_target in pairs(splashable_targets) do
      if core.helper:get_percent_hp(splash_target) <= 65 then 
        good_splashables = good_splashables + 1
      end
    end

    local do_multihit = allies_to_follow >= 2 and good_splashables >= 2 and core.helper:get_percent_hp(enemy.target) <= 65 and not bad_hit and rhit.valid and rHit.hitchance >= jmenu.r_KS_hitchance:get_value()
    if do_multihit then
      Prints("Casting R to multihit with " .. allies_to_follow .. " allies and " .. good_splashables .. " enemies < 65%", 2)
      g_input:cast_spell(e_spell_slot.r, rHit.position)
      features.orbwalker:set_cast_time(0.25)

      return true
    end
  end

  return false
end

---@diagnostic disable-next-line: missing-parameter
cheat.register_module(
  {
    champion_name = "Jinx",
    spell_q = function(data)
      Prints("q spell in", 3)
      local mode = features.orbwalker:get_mode()

      -- Combo logic
      if mode == Combo_key and jmenu.q_combo:get_value() and combo_harass_q() then return true end

      -- Harass logic
      if mode == Harass_key and jmenu.q_harass:get_value() and combo_harass_q() then return true end

      -- Farm logic -- extends auto range to hit dying minions if in minigun form
      if (mode == Clear_key or mode == Harass_key or mode == Lasthit) and jmenu.q_clear:get_value() and save_minion_with_q() then return true end

      -- Clear logic -- AoE minions
      if (mode == Clear_key or mode == Harass_key) and jmenu.q_clear_aoe:get_value() and fast_clear_aoe_Logic() then return true end

      -- Exit rocket logic
      if Data['AA'].rocket_launcher and not features.orbwalker:is_in_attack() and mode ~= Combo_key and mode ~= Idle_key and jmenu.q_clear:get_value() and g_time - Last_Q_swap_time > 0.5 and exit_rocket_logic() then return true end

      return false
    end,
    spell_w = function(data)
      local target = Get_target()
      local mode = features.orbwalker:get_mode()
      -- no w in evade or no target or out of range

      if features.evade:is_active() or target == nil or g_local.position:dist_to(target.position) > Data['W'].Range then
        return false
      end

      local should_w_combo = (mode == Combo_key and jmenu.w_combo:get_value())
      local should_w_harass = (mode == Harass_key and jmenu.w_harass:get_value())
      local should_w_ks = (jmenu.w_KS:get_value())

      -- w Combo / harss logic
      if (should_w_combo or should_w_harass) and w_combo_harass_logic() then
        return true
      end
      --W KS logic
      if should_w_ks and w_ks_logic() then return true end


      return false
    end,
    spell_e = function(data)
      local mode = features.orbwalker:get_mode()
      local should_e_combo = (mode == Combo_key and jmenu.e_combo:get_value())

      if should_e_combo and should_e_multihit() then
        return true
      end
      if should_e_combo and should_e_slowed() then
        return true
      end

      return false
    end,
    spell_r = function(data)
      if features.evade:is_active() or features.orbwalker:is_in_attack() or g_local:is_recalling() then return false end

      local enemies = core.objects:get_enemy_champs(3000)
      local sorted_targets = get_sorted_r_targets(enemies)
      if #sorted_targets == 0 then return false end
      local should_SemiManualR = jmenu.checkboxManR:get_value() and g_input:is_key_pressed(85)
      local should_r_multihit = features.orbwalker:get_mode() == Combo_key and jmenu.r_combo_multihit:get_value()

      -- r ks logic
      if jmenu.r_KS:get_value() and should_r_ks(sorted_targets) then return true end

      -- semi auto r logic
      if should_SemiManualR and try_semi_auto_r(sorted_targets) then return true end

      if should_r_multihit and try_r_multihit(sorted_targets) then return true end

      return false
    end,
    get_priorities = function()
      return {
        "spell_q",
        "spell_w",
        "spell_e",
        "spell_r",
      }
    end
  })


check_for_prereqs()
if REQUIRE_SLOTTED_RESTART then return end
core = require("xCore")
core:init()
Colors = core.debug.Colors

check_for_update()

core.permashow:set_title(name)
-- Clear
core.permashow:register("farm", "farm", "A", true, jmenu.q_clear_aoe_cgf)
core.permashow:register("Fast W", "Fast W", "control")
core.permashow:register("Semi-Auto Ult", "Semi-Auto Ult", "U")
core.permashow:register("Extend AA To Harass", "Extend AA To Harass", "I", true, jmenu.splash_harass_cfg)


cheat.register_callback("render", Draw)
cheat.register_callback("feature", Refresh)
cheat.register_callback("feature", Splash_harass)
cheat.register_callback("feature", OnTick)
