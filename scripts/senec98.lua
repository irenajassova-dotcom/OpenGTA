-- ==========================================================================
--  SENEC '98 : ZVUK ULICE
--  A fan-made mission pack for OpenGTA, set in Senec (Slovakia) during the
--  birth of Slovak hip hop (1993 - 2001).
--
--  Usage:  ./viewer -s scripts/senec98.lua
--          (requires a build WITH_LUA, see doc/senec98.txt)
--
--  The GTA1 maps are not Senec, so every waypoint is an OFFSET (in blocks)
--  from where the player stands when the script starts. Walk / drive to the
--  pulsing objective shown on the HUD (distance + compass direction).
--
--  Historical notes (fictionalised, written as a tribute):
--   * Dávid zo Senca rapped in Slovak from 1989 and is called the
--     "praotec" (forefather) of Slovak hip hop. Geto Gang x3 - "Politik" (1993).
--   * His compilation project "Zvuk ulice" gathered young MCs from all
--     over Slovakia in the 90s.
--   * Rytmus first appeared on Zvuk ulice as "Pa3k Metamorfolord", later
--     co-founded Kontrafakt (2001) with Ego and DJ Anys.
--  This is not affiliated with or endorsed by any of the artists.
-- ==========================================================================

pos = { x = 214, y = 15, z = 51 }
city_view:setCamPosition(pos.x, pos.y, pos.z)
city_view:setTopDownView(true)

local TICK_SECONDS = 0.1   -- game_tick() is called every 100 ms
local REACH_RADIUS = 2.5   -- blocks

local origin = nil
local stage  = 1
local step   = 1
local timer  = nil
local hold   = 0
local finished = false

-- -------------------------------------------------------------------------
-- Mission data. dx / dz are block offsets from the start position.
-- 'hold' = seconds the player has to stay on the spot (recording, tagging).
-- 'time' = optional time limit in seconds for the whole mission.
-- -------------------------------------------------------------------------
missions = {
  {
    title  = "1/5 POLITIK '93",
    intro  = "DAVID ZO SENCA: Mlady, rap po slovensky? To ide. Prines kazetu.",
    reward = 500,
    steps  = {
      { text = "Kup prazdnu TDK kazetu na trhovisku", dx = 6,  dz = -4 },
      { text = "Dones kazetu do pivnicneho studia",   dx = -5, dz = 8 },
      { text = "Nahravaj verse - stoj na mieste",     dx = -5, dz = 8, hold = 6 },
    },
  },
  {
    title  = "2/5 ZVUK ULICE",
    intro  = "DAVID: Kompilacia ide do lisovne. Rozvez demaky po meste!",
    reward = 1500,
    time   = 150,
    steps  = {
      { text = "Demo k zeleznicnej stanici",    dx = 14,  dz = 3 },
      { text = "Demo na Namestie pri Tureckom dome", dx = 2, dz = -12 },
      { text = "Demo do bufetu pri Slnecnych jazerach", dx = -16, dz = -6 },
      { text = "Vrat sa do studia",             dx = -5, dz = 8 },
    },
  },
  {
    title  = "3/5 METAMORFOLORD",
    intro  = "PAGER: MC z Piestan vystupi z vlaku o 19:00. Vyzdvihni ho.",
    reward = 2000,
    time   = 120,
    steps  = {
      { text = "Chod na stanicu po Pa3ka Metamorfolorda", dx = 14, dz = 3 },
      { text = "Odvez ho do studia, session zacina!",     dx = -5, dz = 8 },
      { text = "Pa3k nahrava sloku pre Zvuk ulice",       dx = -5, dz = 8, hold = 5 },
    },
  },
  {
    title  = "4/5 STENY NA JAZERACH",
    intro  = "Mesto potrebuje vediet, ze kompilacia vychadza. Sprej v ruke.",
    reward = 1200,
    wanted = 2,
    steps  = {
      { text = "Tag: garaze na sidlisku",      dx = 9,   dz = 10, hold = 3 },
      { text = "Tag: podchod pod tratou",      dx = 15,  dz = -2, hold = 3 },
      { text = "Tag: mola na Slnecnych jazerach", dx = -18, dz = -9, hold = 3 },
      { text = "Strat policiu - zmizni do studia", dx = -5, dz = 8 },
    },
  },
  {
    title  = "5/5 KRST KOMPILACIE",
    intro  = "DAVID: Dnes vecer krst na jazerach. Cela scena pride.",
    reward = 5000,
    time   = 90,
    steps  = {
      { text = "Vyzdvihni krabicu kaziet v lisovni", dx = 20, dz = 14 },
      { text = "Dones kazety na podium pri jazere",  dx = -20, dz = -10 },
      { text = "Vystup! Drz mikrofon",              dx = -20, dz = -10, hold = 8 },
    },
  },
}

-- -------------------------------------------------------------------------
local function count(t) return table.getn(t) end

local function compass(dx, dz)
  local ns, ew = "", ""
  if dz < -1 then ns = "S" elseif dz > 1 then ns = "J" end   -- sever / juh
  if dx > 1 then ew = "V" elseif dx < -1 then ew = "Z" end   -- vychod / zapad
  local c = ns .. ew
  if c == "" then c = "TU" end
  return c
end

local function start_mission(i)
  local m = missions[i]
  stage, step, hold = i, 1, 0
  if m.time then timer = m.time else timer = nil end
  hud.setTitle(m.title)
  hud.pager(m.intro, 6)
  if m.wanted then player.setWanted(m.wanted) end
end

local function fail(reason)
  hud.pager("MISIA ZLYHALA: " .. reason, 5)
  start_mission(stage)
end

local function complete_mission()
  local m = missions[stage]
  player.addCash(m.reward)
  player.setWanted(0)
  hud.pager("RESPECT +" .. m.reward .. " Sk", 5)
  if stage < count(missions) then
    start_mission(stage + 1)
  else
    finished = true
    hud.setTitle("SENEC '98 - HOTOVO")
    hud.setObjective("Kompilacia vysla. Zvuk ulice zije. Respekt, Senec!")
  end
end

function game_tick()
  if finished then return end

  local x, y, z = player.getPos()
  if x == nil then return end   -- player not spawned yet

  if origin == nil then
    origin = { x = x, z = z }
    start_mission(1)
  end

  local m = missions[stage]
  local s = m.steps[step]
  local tx, tz = origin.x + s.dx, origin.z + s.dz
  local dx, dz = tx - x, tz - z
  local dist = math.sqrt(dx * dx + dz * dz)

  local line = s.text .. "  [" .. math.floor(dist) .. " " .. compass(dx, dz) .. "]"
  if timer then
    timer = timer - TICK_SECONDS
    line = line .. "  CAS " .. math.floor(timer)
    if timer <= 0 then
      fail("nestihol si to")
      return
    end
  end

  if dist <= REACH_RADIUS then
    if s.hold then
      hold = hold + TICK_SECONDS
      line = s.text .. "  " .. math.floor(hold) .. "/" .. s.hold
      if hold < s.hold then
        hud.setObjective(line)
        return
      end
    end
    hold = 0
    if step < count(m.steps) then
      step = step + 1
    else
      complete_mission()
      return
    end
  else
    hold = 0
  end

  hud.setObjective(line)
end
