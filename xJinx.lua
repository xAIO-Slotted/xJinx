-- xJinx by Jay and a bit of ampx.

-- TODO
-- improve the dash detection logic using db
-- AutoKS
-- -- w reimplement 

-- damage visualizer 
-- -- fix bar size
-- -- add crit chance to damage calc

-- Farming 
-- -- add clear and fast clear logic
-- Combo
-- -- investigte more options

-- -=--==-=-=-=-=-
-- Features
	-- Combo Q swap
  -- Combo W 

  -- harass 
  -- -- harass Q swap
  -- -- -- optional Extend AutoAttack range with minion splash radius
  -- -- harass W

  -- Auto Chain CC/immobile/channel/Dash traps (prediction / timing based)
  -- Auto Chain CC/immobile/channel/Dash laser (prediction / timing based)

  -- semiAutoR (while holding U)
  -- SemiAutoW (Full combo)

  -- Auto KS with R

  -- Damage visualizer
  -- -- HP bar shows damage of 3 autos + W and R if available or 4 autos if attack speed is above 1.5
  -- -- "Combo Kill" text shows if hp below W+R
  -- -- "W Kill" text shows if hp below W
  -- -- "AA Kill" shows if hp below AA damage 

  -- Harass visualizer
  -- Draws circle around target who could be safely hit by attacking a minion when otherwise impossible to reach

  -- Debug toggle [Shows all debug message on screen]


local core = require("xCore")

local Combo_key = 1
local Clear_key = 3
local Harass_key = 4
local Flee_key = 5

-- Should be way better than current Jinx. Any more suggestions? DM me on Discord: dizzy#6092 :).
local name = "xAIO - Jinx"

local add_nav = menu.get_main_window():push_navigation(name, 10000)
local navigation = menu.get_main_window():find_navigation(name)

-- Sections
local combo_sect = navigation:add_section("combo")
local harass_sect = navigation:add_section("harass")
local clear_sect = navigation:add_section("clear")
local agc_sect = navigation:add_section("gap close")
local auto_sect = navigation:add_section("auto")
local msc_sect = navigation:add_section("misc")
local draw_sect = navigation:add_section("drawings")

-- Config
local q_combo_aoe_count_cfg = g_config:add_int(3, "q_aoe_count")
local q_clear_aoe_count_cfg = g_config:add_int(3, "q_aoe_count")

-- Combo
local q_combo = combo_sect:checkbox("use Q", g_config:add_bool(true, "q_combo"))
local q_combo_aoe = combo_sect:checkbox("^ try AOE", g_config:add_bool(true, "q_combo_aoe"))
local q_combo_aoe_count = combo_sect:slider_int("^ if x enemies", q_combo_aoe_count_cfg, 0, 5, 1)

local w_combo = combo_sect:checkbox("use W", g_config:add_bool(true, "w_combo"))
local w_combo_not_in_range = combo_sect:checkbox("^ if outside of aa range", g_config:add_bool(true, "w_combo_in_range"))
local w_combo_hitchance = combo_sect:select("W hitchance", g_config:add_int(3, "w_combo_hitchance"),
{ "low", "medium", "high", "very_high", "immobile" })


local e_combo = combo_sect:checkbox("use E", g_config:add_bool(true, "e_combo"))
local e_combo_mode = combo_sect:select("E Logic:", g_config:add_int(1, "e_combo_mode"),
{ "always", "advanced", "undodgable" })

local r_combo = combo_sect:checkbox("use R", g_config:add_bool(true, "r_combo"))
local r_combo_hitchance = combo_sect:select("R hitchance", g_config:add_int(3, "r_combo_hitchance"),
{ "low", "medium", "high", "very_high", "immobile" })

-- Clear
local q_clear = clear_sect:checkbox("use Q", g_config:add_bool(true, "q_clear"))
local q_clear_aoe = clear_sect:checkbox("^ try AOE", g_config:add_bool(true, "q_clear_aoe"))
local q_clear_aoe_count = clear_sect:slider_int("^ if x enemies", q_clear_aoe_count_cfg, 0, 5, 1)

-- Harass
local checkboxJinxSplashHarass = harass_sect:checkbox("extend aa range with Q splash",
g_config:add_bool(true, "splash_harass"))

-- Auto
local q_auto = auto_sect:checkbox("auto Q swapping", g_config:add_bool(true, "q_auto"))
local extend_q_auto = auto_sect:checkbox("auto Q harass", g_config:add_bool(true, "auto q splash harass"))

local w_auto = auto_sect:checkbox("auto W", g_config:add_bool(true, "w_auto"))
-- local w_auto_cc = auto_sect:checkbox("^ on cc", g_config:add_bool(true, "w_auto_cc"))
-- local w_auto_channel = auto_sect:checkbox("^ on channel", g_config:add_bool(true, "w_auto_channel"))
-- local w_auto_special = auto_sect:checkbox("^ on special", g_config:add_bool(true, "w_auto_special"))

local e_auto = auto_sect:checkbox("auto E", g_config:add_bool(true, "e_auto"))
-- local e_auto_cc = auto_sect:checkbox("^ on cc", g_config:add_bool(true, "e_auto_cc"))
-- local e_auto_channel = auto_sect:checkbox("^ on channel", g_config:add_bool(true, "e_auto_channel"))
-- local e_auto_special = auto_sect:checkbox("^ on special", g_config:add_bool(true, "e_auto_special"))

local r_auto = auto_sect:checkbox("auto R", g_config:add_bool(true, "r_auto"))
local r_auto_dashless = auto_sect:checkbox("^ if no dash", g_config:add_bool(true, "r_auto_dashless"))

local w_agc = agc_sect:checkbox("W on dash", g_config:add_bool(true, "W on dash"))
local e_agc = agc_sect:checkbox("E on dash", g_config:add_bool(true, "E on dash"))

-- add a multi select
local Dash_list = {}
local Dash_list_cfg = {}

-- 0 = nothing
-- 1 = default
-- 2 = lots
-- 3 = trace
Debug_level = 2
Res = g_render:get_screensize()
Font = 'roboto-regular'
White = color:new(255, 255, 255)
Red = color:new(255, 0, 0)
Green = color:new(0, 255, 0)
Blue = color:new(0, 0, 200)
local colors = {
  solid = {
      white = color:new(255, 255, 255),
      red = color:new(255, 0, 0),
      orange = color:new(255, 127, 0),
      yellow = color:new(255, 255, 0),
      green = color:new(0, 255, 0),
      cyan = color:new(0, 255, 255),
      blue = color:new(0, 0, 255),
      purple = color:new(143, 0, 255)
  },
  transparent = {
      white = color:new(255, 255, 255, 130),
      red = color:new(255, 0, 0, 130),
      orange = color:new(255, 127, 0, 130),
      yellow = color:new(255, 255, 0, 130),
      green = color:new(0, 255, 0, 130),
      cyan = color:new(0, 255, 255, 130),
      blue = color:new(0, 0, 255, 130),
      purple = color:new(143, 0, 255, 200)
  }
}

COLOR = White
LastMsg = "init"
MinionInRange = {}
MinionToHarass = {}
SplashableTargetIndex = nil
SplashableMinionIndex = nil
MinionTable = {}
Last_cast_time = g_time

function Prints(str, level)
  level = level or 1
  str = tostring(str)
  if level <= Debug_level then
    print("log: " .. " " .. str)
    if str ~= LastMsg then LastMsg = str end
  end
end


local dash_blacklist = auto_sect:multi_select("^ dash blacklist", Dash_list, Dash_list_cfg)

-- misc
local checkboxManR = msc_sect:checkbox("Manual Ult on U", g_config:add_bool(true, "Semi Auto Cast R"))


-- Lasthit

-- Mana

-- AntiGapClose

-- Flee

-- Permashow

-- Draw
local checkboxDBG = draw_sect:checkbox("debug messages", g_config:add_bool(true, "debug messages"))
local checkboxVisualDmg = draw_sect:checkbox("damage visual", g_config:add_bool(true, "visualize damage"))
local checkboxDrawQ = draw_sect:checkbox("Draw alternate Q range", g_config:add_bool(true, "Draw alternate Q range"))
local checkboxDrawW = draw_sect:checkbox("Draw W off cooldown", g_config:add_bool(true, "Draw W off cooldown"))



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

function Data:Get_jinx_multiplier(index)
  local target = features.entity_list:get_by_index(index)
  local distance = g_local.position:dist_to(target.position)

  -- Calculate the damage scaling based on distance traveled (10% to 100%) (using W range as max R on)

  if g_local.position:dist_to(target.position) >= 1500 then
      return 1
  elseif g_local.position:dist_to(target.position) <= 100 then
      return 0.1
  else
      return 0.1 + 0.9 * (distance / self['W'].Range)
  end
end


function Data:refresh_data()
  Prints("refreshing", 3)
  self['AA'].Damage = g_local:get_attack_damage()
  self['AA'].rocket_launcher = self:has_rocket_launcher()
  local range = g_local.attack_range + g_local:get_bounding_radius()
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
  self['AA'].enemy_close = self:is_enemy_near(range)
  self['AA'].enemy_far = self:is_enemy_near(long_range)

  self['Q'].Level = g_local:get_spell_book():get_spell_slot(e_spell_slot.q).level
  self['Q'].spell = g_local:get_spell_book():get_spell_slot(e_spell_slot.q)
  self['Q'].spellSlot = e_spell_slot.q

  self['W'].Level = g_local:get_spell_book():get_spell_slot(e_spell_slot.w).level
  self['W'].spell = g_local:get_spell_book():get_spell_slot(e_spell_slot.w)
  self['W'].castTime = math.max(0.6 - 0.02 * math.floor(g_local.bonus_attack_speed / 0.25), 0.4)
  
  self['E'].Level = g_local:get_spell_book():get_spell_slot(e_spell_slot.e).level
  self['E'].spell = g_local:get_spell_book():get_spell_slot(e_spell_slot.e)
  self['E'].spellSlot = e_spell_slot.e
  
  self['R'].Level = g_local:get_spell_book():get_spell_slot(e_spell_slot.r).level
  self['R'].spell = g_local:get_spell_book():get_spell_slot(e_spell_slot.r)
  self['R'].spellSlot = e_spell_slot.r
  
  Prints("refreshed", 3)
end

function Data:is_ready(spell)
  if self[spell].spell:is_ready() then
    return true
  end
  return false
end

function Data:has_enough_mana(spell)
  local costs = self[spell].manaCost
  local level = self[spell].Level
  local cost = costs[level]

  if g_local and spell and cost then
    --Prints("Cost of  " .. spell .. " at " .. level .. " level is " .. cost, 3)
    if g_local.mana >= cost then
      return true
    else
      return false
    end
  end
end

function Data:can_cast(spell)
  if self:is_ready(spell) and self:has_enough_mana(spell) then
    return true
  end
  return false
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

function Data:is_enemy_near(range, override)
  for _, entity in pairs(features.entity_list:get_enemies()) do
    if entity.position:dist_to(g_local.position) <= range then
      return true
    end
  end
  return false
end

function Data:count_enemies(range, position)
  local numAround = 0
  for _, entity in pairs(features.entity_list:get_enemies()) do
    if entity ~= nil and entity.position:dist_to(position) <= range then
      numAround = numAround + 1
    end
  end
  return numAround
end

function Data:calculate_W_damage(index)
  local target = features.entity_list:get_by_index(index)
  local baseDamage = {10, 60, 110, 160, 210}
  local scalingFactor = 1.6
  local AD = g_local:get_attack_damage()

  -- Get the current level of the W ability
  local W_level = self['W'].Level

  -- Calculate the raw damage using the base damage and scaling factor
  local rawDamage = baseDamage[W_level] + (AD * scalingFactor)

  -- Factor in the target's armor
  local finalDamage = helper.calculate_damage(rawDamage, index, true)

  return finalDamage
end

function Data:calculate_R_damage(index)
  if not Data:can_cast('R') then return 0 end
  local target = features.entity_list:get_by_index(index)
  local baseDamage = {300, 450, 600}
  local scalingFactor = 1.5
  local missingHealthScaling = {0.25, 0.30, 0.35}

  -- Get the current level of the R ability
  local R_level = self['R'].Level

  -- Get the bonus attack damage and base attack damage
  local bonusAD = g_local.bonus_attack
  local baseAD = g_local:get_attack_damage()

  -- Calculate the raw damage using the base damage and scaling factor
  local rawDamage = baseDamage[R_level] + (bonusAD * scalingFactor)

  -- Add the missing health percentage damage
  local target_missing_health = target.max_health - target.health
  rawDamage = rawDamage + (target_missing_health * missingHealthScaling[R_level])

  -- Apply the damage scaling to the raw damage (excluding the missing health damage)
  rawDamage = (baseDamage[R_level] + (bonusAD * scalingFactor)) * Data:Get_jinx_multiplier(index) + (target_missing_health * missingHealthScaling[R_level])

  -- Factor in the target's armor
  local finalDamage = helper.calculate_damage(rawDamage, index, true)

  return finalDamage
end



function Data:CalcDamage(index, rawDamage)
  Prints("cdt", 3)
  local target = features.entity_list:get_by_index(index)
  if target == nil then return 0 end

  Prints("Calcing against: " .. target:get_object_name(), 2)
  local armor = target.total_armor
  local calc = (rawDamage * ( 100 / ( 100 + armor )))
  Prints("lc", 3)
  return calc
end

function Data:CalcDamageCalcDamageAP(index, rawDamage)
  local target = features.entity_list:get_by_index(index)
  local mr = target.total_mr
  return (rawDamage * ( 100 / ( 100 + mr )))
end

function Data:calc_dmg(target, rawDamage)
  Prints("dmg to " .. target:get_object_name() .. "before calc is " .. rawDamage, 3)
  local armor = target.total_armor
  return (rawDamage * (100 / (100 + armor)))
end

function Build_dash_list()
  Dash_list = {}
  Dash_list_cfg = {}
  Prints("building dash list", 1)
  for _, enemy in pairs(features.entity_list:get_enemies()) do
      local enemy_champion_name = string.lower(enemy.champion_name.text)
      if core.DB.Dash[enemy_champion_name] then
          Prints("adding ".. enemy_champion_name)
          local dash_data_list = core.DB.Dash[enemy_champion_name]
          for _, dash_data in ipairs(dash_data_list) do
              local details = enemy_champion_name .. tostring(dash_data.menuslot)
              local dash = g_config:add_bool(false, details)
              table.insert(Dash_list, dash_data.menuslot)  -- Store the ability letter
              table.insert(Dash_list_cfg, details)
          end
      end
  end
  Prints("built dash lists", 1)
  -- local local_champion_name = string.lower(g_local.champion_name.text)
  -- if x.DB.Dash[local_champion_name] then
  --     Prints("adding ".. local_champion_name)
  --     local dash_data_list = x.DB.Dash[local_champion_name]
  --     for _, dash_data in ipairs(dash_data_list) do
  --         local details = local_champion_name .. tostring(dash_data.menuslot)
  --         local dash = g_config:add_bool(false, details)
  --         table.insert(Dash_list, dash_data.menuslot)  -- Store the ability letter
  --         table.insert(Dash_list_cfg, details)
  --     end
  -- end
end


function Show_splash_harass()
  Prints("draw harass", 3)
  if SplashabletargetIndex then
    local tgt = features.entity_list:get_by_index(SplashabletargetIndex)
    if tgt then
      Get_harass_minions_near(SplashabletargetIndex, 235)
      -- circle the target
      g_render:circle_3d(tgt.position, Red, 235, 2, 90, 2)
      if MinionTable and #MinionTable > 0 then
        --Prints("splash?", 1)
        for ii, alive in ipairs(MinionTable) do
          local min = features.entity_list:get_by_index(alive.idx)
          if min then
            local hmm = min.position:extend(tgt.position, tgt.position:dist_to(min.position))
            if tgt ~= nil and min ~= nil then g_render:line_3d(min.position, tgt.position, Red, 1) end
          end
        end
      end
    end
  end
  if SplashableMinionIndex then
    local min = features.entity_list:get_by_index(SplashableMinionIndex)
    if min then g_render:circle_3d(min.position, Green, 80, 2, 90, 2) end
  end
end

function IsUnderTurret(pos)
  local range = 850
  for _,unit in pairs(features.entity_list:get_enemy_turrets()) do
    if unit ~= nil and not unit:is_dead() then 
      local away = unit.position:dist_to(pos)
      if away < range then return true end
    end
  end	
  return false
end


function KillSteal()

end

function Visualize_damage()
  if g_time - Last_cast_time <= 0.15 then return end

  for i, enemy in pairs(features.entity_list:get_enemies()) do
    if enemy:is_alive() and enemy:is_visible() and g_local.position:dist_to(enemy.position) < 3000 then
      local approx = 0
      local Killable = false
      local aadmg = helper.get_aa_damage(enemy.index, false)
      local wdmg =  0
      local rdmg =  0
      local nmehp = enemy.health

      approx = 3*aadmg
      if Data:can_cast('W') then
        wdmg = Data:calculate_W_damage(enemy.index)
        approx = approx + wdmg
      end
      if Data:can_cast('R') then
        rdmg = Data:calculate_R_damage(enemy.index)
        approx = approx + rdmg
      end
      if g_local.bonus_attack_speed + g_local.attack_speed > 1.5 then
        approx = approx + aadmg
      end

      local screen = g_render:get_screensize()
      local base_x = 2560
      local base_y = 1080
      local x_ratio = screen.x / base_x
      local y_ratio = screen.y / base_y
      local width_offset = 0.0409
      local height_offset = 0.010 
      local base_x_offset = 0.43
      local base_y_offset = 2.20
      local bar_width = (screen.x  * width_offset)
      local bar_height = (screen.y * height_offset)
      local base_position = enemy:get_hpbar_position()
      base_position.x = base_position.x - bar_width * base_x_offset
      base_position.y = base_position.y - bar_height * base_y_offset
  
      local modifier = enemy.health / enemy.max_health
      local damage_mod = approx / enemy.max_health
  
      local box_start = vec2:new(base_position.x + bar_width * modifier, base_position.y)
      local box_size_x = 0
      if damage_mod * bar_width > box_start.x - base_position.x then
          box_size_x = base_position.x - box_start.x
      else 
          box_size_x = (bar_width * damage_mod) * -1
      end
  
      local box_size = vec2:new(box_size_x , bar_height)
  
      g_render:filled_box(box_start, box_size, colors.transparent.purple)
      if approx >= (enemy.health + 5) then
          Killable = true
          Square_color = color:new(255,0,200,100)
          -- Prints("draw circ", 1)
          if enemy.position:to_screen() ~= nil then
              g_render:circle_3d(enemy.position, Square_color, 65, 1, 90, 2)
              g_render:text(enemy.position:to_screen(), color:new(255,255,255), "KILLABLE", Font, 30) --Hold SHIFT to "..mode_text.." ultimate!
              --g_render:circle(enemy.position:to_screen(), Square_color, 65, 90)
          end
          -- Prints("drew circ", 1)
      end
  --     Prints("draw text", 1)
  --     if enemy.position:to_screen() ~= nil then
  --         Font = 'roboto-regular'
  --         
  --         Prints("drew text", 1)
  --     end
  -- end
      -- Prints("AA will do " .. helper.get_aa_damage(target.index, false)  .. " to " .. target:get_object_name(), 3)
      -- Prints("W will do " ..tostring(Data['W'].Damage) .. " to " .. target:get_object_name(), 3)
      -- Prints("R will do " .. tostring(Data['R'].Damage) .. " to " .. target:get_object_name(), 3)
       
    end
  end
  Prints("tick exit", 3)

  --DrawLethal()ll
  --local dmg_total = get_quick_combo_dmg()
  
  --local hp = target.health = local target = features.target_selector:get_default_target()
end





function Visualize_spell_range()
  Prints("draw ranges", 3)
  if checkboxDrawQ:get_value() then 
    if Data['AA'].rocket_launcher then
      g_render:circle_3d(g_local.position, Blue, Data['AA'].short_range, 2, 50, 1)
    else
      g_render:circle_3d(g_local.position, Blue, Data['AA'].long_range, 2, 50, 1)
    end
  end
  if checkboxDrawW:get_value() and Data:can_cast('W') then
    g_render:circle_3d(g_local.position, Blue, Data['W'].Range, 2, 50, 1)
  end 
end

function Draw()
  Prints("Draws", 3)
  if checkboxJinxSplashHarass:get_value() then
    Show_splash_harass()
  end
  if checkboxVisualDmg:get_value() then
     Visualize_damage()
  end
  if checkboxDrawQ:get_value() or checkboxDrawW:get_value() then
    Visualize_spell_range()
  end

  if checkboxDBG:get_value() then
    local pos = vec2:new((Res.x / 2) - 100, Res.y - 260)
    g_render:text(pos, COLOR, LastMsg, Font, 30)
  end
end

function Get_harass_minions_near(obj_hero_idx, range)
  Prints("get harass", 3)
  local obj_hero = features.entity_list:get_by_index(obj_hero_idx)
  local minions = features.entity_list:get_enemy_minions()
  --Prints("getting harass minions in range of " .. tostring(obj_hero:get_object_name()) .. " x= " .. tostring(range) )
  --Prints("getting harass minions out of " .. tostring(#minions))
  for i, obj_minion in ipairs(minions) do
    if obj_hero and obj_minion and obj_minion:is_alive() and obj_minion:is_visible() and obj_minion:is_minion() and obj_minion:is_targetable() then
      if (obj_minion:get_object_name() == "SRU_ChaosMinionRanged" or obj_minion:get_object_name() == "SRU_ChaosMinionMelee" or obj_minion:get_object_name() == "SRU_ChaosMinionSiege") then
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
            if alive:is_alive() == false then remove = true end
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
  -- Prints("after a full loop ive got... " .. tostring(#MinionTable))

  return true
end

function ValidateSplashMinionAndtarget()
  if SplashabletargetIndex then
    local hero_obj = features.entity_list:get_by_index(SplashabletargetIndex)
    if g_local.position:dist_to(hero_obj.position) < Data['AA'].long_range then
      SplashabletargetIndex = nil
    elseif hero_obj.position:dist_to(hero_obj.position) > Data['AA'].long_range + 260 then
      SplashabletargetIndex = nil
    elseif hero_obj:is_alive() == false then
      SplashabletargetIndex = nil
    elseif hero_obj:is_visible() == false then
      SplashabletargetIndex = nil
    end
    -- if SplashabletargetIndex then Prints("Splashable target valid", 1) else Prints("Splashable target removed", 1) end
    if SplashableMinionIndex then
      local min_obj = features.entity_list:get_by_index(SplashableMinionIndex)
      if g_local.position:dist_to(min_obj.position) > Data['AA'].long_range then
        SplashableMinionIndex = nil
      elseif hero_obj.position:dist_to(min_obj.position) > 235 then
        SplashableMinionIndex = nil
      elseif min_obj:is_alive() == false then
        SplashableMinionIndex = nil
      elseif min_obj:is_visible() == false then
        SplashableMinionIndex = nil
      end
      -- if SplashableMinionIndex then Prints("Splashable Minion valid", 1) else Prints("Splashable Minion removed", 1) end
    end
  end
end

function FindSplashableMinion()
  local target = features.target_selector:get_default_target()
  if target == nil then return false end
  --update the global minion table nearby the target
  --Prints("finding splash minion", 1)
  Get_harass_minions_near(target.index, 250)
  --get all the minions in AA range of me out of this table.
  if MinionTable and #MinionTable > 0 then
    for i, minionIdx in ipairs(MinionTable) do
      if SplashableMinionIndex == nil then
        local minion = features.entity_list:get_by_index(minionIdx.idx)
        if target.position:dist_to(minion.position) < 236 and g_local.position:dist_to(minion.position) < Data['AA'].long_range then
          --Prints("idx is minions is at " .. g_local.position:dist_to(minion.position))
          SplashableMinionIndex = minion.index
        end
      end
    end
  end
end

function Splash_harass()
  
  if checkboxJinxSplashHarass:get_value() == false then return false end
  if features.orbwalker:is_in_attack() or features.evade:is_active() or not Data:can_cast('Q') then return false end
  local target = features.target_selector:get_default_target()
  if target == nil then return false end
  SplashabletargetIndex = target.index
  ValidateSplashMinionAndtarget()

  --is target outside normal Q range?
  if target:is_alive() and target:is_visible() and g_local.position:dist_to(target.position) > Data['AA'].long_range then
    if g_local.position:dist_to(target.position) < Data['AA'].long_range + 260 then
      --Prints("target is inside splash range.", 1)
      -- if we already have a splash minion then why are we still searching
      if SplashableMinionIndex == nil then FindSplashableMinion() end
      -- we may have found a minion so
      if SplashableMinionIndex then
        local min_obj = features.entity_list:get_by_index(SplashableMinionIndex)
        if min_obj then
          if features.orbwalker:get_mode() == Harass_key or extend_q_auto:get_value() then
            local min_pred = features.prediction:predict(SplashableMinionIndex, Data['AA'].long_range, 1500, 0,
            g_local.attack_speed, g_local.position)
            local nme_pred = features.prediction:predict(SplashableMinionIndex, Data['AA'].long_range, 1500, 0,
            g_local.attack_speed, g_local.position)

            if g_local.position:dist_to(min_pred.position) < Data['AA'].long_range then
              if nme_pred.position:dist_to(min_pred.position) < 235 then
                if Data['AA'].rocket_launcher == false then g_input:cast_spell(e_spell_slot.q) end
                if features.orbwalker:can_attack() and not features.orbwalker:is_in_attack() then features.orbwalker
                      :send_attack(min_obj.network_id) end
                return true
              end
            end
          end
        end
      end
    end
  end
end

function SemiAutoR()
  if checkboxManR:get_value() == false then return false end
  if features.orbwalker:is_in_attack() or features.evade:is_active() or not Data:can_cast('R') then return false end
  if g_input:is_key_pressed(85) == true then -- 85 is U key T is 84, Y is 89
    Prints("Auto R.....", 1)
    local target = features.target_selector:get_default_target()
    -- dont do it if: nil or invis or bad target or not attackable or out of range XD
    if target == nil then
      Prints("nil target manual ulti", 1)
      return false
    end
    if features.target_selector:is_bad_target(target.index) then
      Prints("bad target manual ulti", 1)
      return false
    end
    if not features.orbwalker:is_attackable(target.index, 3500, true) then
      Prints("not atkble manual ulti", 1)
      return false
    end
    if not (target:is_alive() and target:is_visible()) then
      Prints("dead or invis tgt manual ulti", 1)
      return false
    end
    if g_local.position:dist_to(target.position) > 3500 then
      Prints("man ult target to far away", 1)
      return false
    end
    local hitchance = features.prediction:predict(target.index, Data['R'].Range, Data['R'].Speed, Data['R'].Width, 0,
    g_local.position)
    if hitchance.valid and hitchance.hitchance >= 0 then g_input:cast_spell(e_spell_slot.r, hitchance.position) end
  end
end

function Time_remaining_for_dash(cai)
  local dx = cai.path_end.x - cai.path_start.x
  local dy = cai.path_end.y - cai.path_start.y
  local dz = cai.path_end.z - cai.path_start.z

  local distance = math.sqrt(dx * dx + dy * dy + dz * dz)
  local time_remaining = distance / cai.dash_speed

  return time_remaining
end

function OnDash(index)
  Prints("enter OnDash", 3)
  local tgt = features.entity_list:get_by_index(index)
  local cai = tgt:get_ai_manager()
  if (e_agc:get_value() or e_agc:get_value()) and cai.is_dashing then
    Prints("checking for dashes", 2)
    if g_local.position:dist_to(cai.path_end) > Data['W'].Range then
      Prints("is dashing out of range of w :(" , 2)
      return
    end
    Prints("is dashing...", 2)
    local time_remaining = Time_remaining_for_dash(cai)
    Prints("Time Remaining: " .. tostring(time_remaining), 2)
    local trapped = false

    if e_agc:get_value() and time_remaining > (Data['E'].castTime - 0.5) and g_local.position:dist_to(cai.path_end) < Data['E'].Range and Data:can_cast('E') then
      Prints("lets e?", 3)
      g_input:cast_spell(e_spell_slot.e, cai.path_end)
      features.orbwalker:set_cast_time(0.25)
      Last_cast_time = g_time
    end

    -- dont w under tower unless already in combo mode
    if (IsUnderTurret(g_local.position) and not features.orbwalker:get_mode() == Combo_key) then return false end

    if w_agc:get_value() and time_remaining > (Data['W'].castTime - 0.5) and Data:can_cast('W') then
      local minion_block = features.prediction:minion_in_line(g_local.position, cai.path_end, 120)
      if not minion_block and g_local.position:dist_to(cai.path_end) > 300 then
        g_input:cast_spell(e_spell_slot.w, cai.path_end)
        Prints("attempted to cast W", 2)
      end
    end

    return true
  end
  Prints("exit OnDash", 3)
end

function On_cc_special_channel(index)
  Prints("cc check", 1)
  -- local cai = tgt:get_ai_manager()
  -- w_auto
  -- w_auto_cc  w_auto_channel w_auto_special 
  local enemy = features.entity_list:get_by_index(index)
  if enemy then
    if enemy:is_alive() and not enemy:is_invisible() then
      Prints("checking if " .. enemy:get_object_name() .. " is ccd or immobile", 2)

      local should_cast_w = false
      local should_cast_e = false

      local is_immobile = false
      local is_ccd = false
      --local is_channeling = false
      
      if features.buff_cache:is_immobile(enemy.index) then is_ccd = true end
      if features.buff_cache:has_hard_cc(enemy.index) then is_immobile = true end

      if is_immobile or is_ccd then 
        Prints("is ccd or immobile looking to cast", 1)

        if w_auto:get_value() and Data:can_cast('W') and Data:in_range('W', enemy)  then 
            should_cast_w = true
        end
        -- please dont laser under enemy tower lol
        if (IsUnderTurret(g_local.position) and not features.orbwalker:get_mode() == Combo_key) then should_cast_w = false
        end

        if e_auto:get_value() and Data:can_cast('E') and Data:in_range('E', enemy) then 
            should_cast_e = true
        end
      end

      if should_cast_e or should_cast_w then
        Prints("lets cast something", 2)

        if e_auto:get_value() and Data:can_cast('E') and Data:in_range('E', enemy) then 
          local eHit = features.prediction:predict(enemy.index, Data['E'].Range, Data['E'].Speed, Data['E'].Width, 0, g_local.position)
          if eHit.valid and eHit.hitchance >= 2 then
            g_input:cast_spell(e_spell_slot.e, eHit.position)
          end
          features.orbwalker:set_cast_time(0.25)
          Last_cast_time = g_time
        end
        Prints("lets cast something 2", 2)
        if w_auto:get_value() and Data:can_cast('W') and Data:in_range('W', enemy) then 
          local wHit = features.prediction:predict(enemy.index, Data['W'].Range, Data['W'].Speed, Data['W'].Width, 0, g_local.position)
          if wHit.valid and wHit.hitchance >= 2 then
            g_input:cast_spell(e_spell_slot.w, wHit.position)
            features.orbwalker:set_cast_time(0.25)
          end
        end
      end
    end
  end
end
      -- local qHit = features.prediction:predict(Target.index, Q_range, Q_speed, Q_width, Q_windup+0.726, g_local.position) 
      -- if (qHit.valid and qHit.hitchance > 1.0) then
      --     g_input:cast_spell(e_spell_slot.q, qHit.position)
      --     features.orbwalker:set_cast_time(features.orbwalker:get_attack_cast_delay())
      --     Prints("auto cc q cast", 1)
      --     return false
      -- end


function OnTick()
  if g_time - Last_cast_time <= 0.05 then return end
  Prints("tick...", 3)
  for i, enemy in pairs(features.entity_list:get_enemies()) do
    if enemy:is_alive() and enemy:is_visible() and g_local.position:dist_to(enemy.position) < 3000 then
      --Prints("check dash", 2)
      if not features.orbwalker:is_in_attack() and not features.evade:is_active() then
        -- if is dashing
        if enemy:get_ai_manager().is_dashing then
          Prints("check dash is dashing", 2)
          OnDash(enemy.index)
        end
        On_cc_special_channel(enemy.index)
      end
    end
  end
  Prints("tick exit", 3)
end
function Refresh() Data:refresh_data() end



cheat.register_module(
  {
    champion_name = "Jinx",
    spell_q = function()
      local mode = features.orbwalker:get_mode()
      local target = features.target_selector:get_default_target()

      if features.orbwalker:is_in_attack() or features.evade:is_active() or not Data:can_cast('Q') then
      end

      if mode == Combo_key and q_combo:get_value() then
        if q_combo_aoe:get_value() and target ~= nil and Data:count_enemies(250, target.position) >= q_combo_aoe_count:get_value() then
          if not Data['AA'].rocket_launcher then
            g_input:cast_spell(e_spell_slot.q)
          end
          -- we need more range...
        else
          if (not Data['AA'].rocket_launcher and Data['AA'].enemy_far and not Data['AA'].enemy_close) then
            g_input:cast_spell(e_spell_slot.q)
          else
            if (Data['AA'].rocket_launcher and Data['AA'].enemy_far and Data['AA'].enemy_close) then
              -- we need more attack speed...
              g_input:cast_spell(e_spell_slot.q)
            end
          end
        end
      end
      if mode == Clear_key and q_auto:get_value() then
        local turrets = features.entity_list:get_enemy_turrets()

        -- spellfarm check
        if Data['AA'].rocket_launcher and (target ~= nil or turrets[target] ~= nil) then
          g_input:cast_spell(e_spell_slot.q)
        end
      end
    end,
    spell_w = function()
      local mode = features.orbwalker:get_mode()
      local target = features.target_selector:get_default_target()

      if features.orbwalker:is_in_attack() or features.evade:is_active() or not Data:can_cast('W') then
        return false
      end
      -- Prints("scoob the mode is " .. mode)
      if w_combo:get_value() then
        Prints("w spell in" , 3)

        if (mode == Combo_key and q_combo:get_value()) or mode == Harass_key then
          if target == nil then return false end
          local skip_cast = false
          
          local hit_chance_setting = w_combo_hitchance:get_value()
          if g_input:is_key_pressed(17) then
            hit_chance_setting = 1
          end

          --dont WW while in aa range if toggled off
          Prints("w in - only combo while in range?" .. tostring(w_combo_not_in_range:get_value()) .. " Full combo: " .. tostring(g_input:is_key_pressed(17)), 2)
          if  w_combo_not_in_range:get_value() and not g_input:is_key_pressed(17)
            then if Data['AA'].enemy_far
              then skip_cast = true
            end
          end
          -- dont W if theyre in range and could kill in less than 4 autos
          if math.ceil(target.health / Data:calc_dmg(target, Data['AA'].Damage)) > 4 and Data['AA'].enemy_far then skip_cast = true end
          Prints("skip w? " .. tostring(skip_cast), 3)

          if not skip_cast then
            if Data:in_range('W', target) then
              local wHit = features.prediction:predict(target.index, Data['W'].Range, Data['W'].Speed, Data['W'].Width,Data['W'].castTime, g_local.position)
              Prints("w pred range: " .. tostring(Data['W'].Range) .. " speed: " .. tostring(Data['W'].Speed) .. " width " .. Data['W'].Width .. " wind up" .. Data['W'].castTime, 2)

              local minion_block = features.prediction:minion_in_line(g_local.position, wHit.position, 120)
              -- Prints("w only combo " .. tostring(w_combo_not_in_range:get_value()) .. " Full combo: " .. tostring(g_input:is_key_pressed(17)) .. " Hitchance: " .. tostring(wHit.hitchance) .. "/" .. tostring(hit_chance_setting), 2)
              if wHit.valid and wHit.hitchance >= hit_chance_setting and not minion_block then
                g_input:cast_spell(e_spell_slot.w, wHit.position)
                return true
              end
            end
          end
        end

      else Prints("dont w in combo") end
      -- Prints(" ")

      -- search for a free W hit.
      -- all dash cases are handled in OnDash()

      -- I dont want to loop entity_list list over and over soo Im going to handle all auto cases in OnTick

      --KS Logic
      -- if ks_with_w:get_value() then
      --   local skip_cast = false
      --   local can_kill = target.health - Data:calc_dmg(target, Data['AA'].Damage) <= 0
      --   if features.orbwalker:is_in_attack() or features.evade:is_active() or not Data:can_cast('R') then skip_cast = true end


      --   end
      -- end
    end,
    spell_e = function()
      local mode = features.orbwalker:get_mode()
      local target = features.target_selector:get_default_target()

      if features.orbwalker:is_in_attack() or features.evade:is_active() or not Data:can_cast('E') then
      end

      if mode == Combo_key and q_combo:get_value() then

        if (e_combo_mode:get_value() == 0) then
          if Data:in_range('E', target) then
            local eHit = features.prediction:predict(target.index, Data['E'].Range, Data['E'].Speed, Data['E'].Width, 0,
            g_local.position)
            if eHit.valid and eHit.hitchance >= 3 then --TODO: set hitchance on 3
              g_input:cast_spell(e_spell_slot.e, eHit.position)
            end
          end
        end
      end
    end,
    spell_r = function()
      local mode = features.orbwalker:get_mode()
      local target = features.target_selector:get_default_target()
      if target == nil then return false end
      local dmg = 5 > math.ceil(target.health / Data:calc_dmg(target, Data['AA'].Damage))
      if features.orbwalker:is_in_attack() or features.evade:is_active() or not Data:can_cast('R') then
      end

      if mode == Combo_key and r_combo:get_value() then
        if Data:in_range('R', target) and dmg and not Data['AA'].enemy_far then
          local hitchance = features.prediction:predict(target.index, Data['R'].Range, Data['R'].Speed, Data['R'].Width,
          0, g_local.position)
          if hitchance.valid and hitchance.hitchance >= 0 then --TODO: set hitchance on 3
            g_input:cast_spell(e_spell_slot.r, hitchance.position)
          end
        end
      end
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
Build_dash_list()
cheat.register_callback("render", Draw)
cheat.register_callback("feature", Refresh)
cheat.register_callback("feature", Splash_harass)
cheat.register_callback("feature", SemiAutoR)
cheat.register_callback("feature", OnTick)