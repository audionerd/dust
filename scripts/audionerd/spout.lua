-- spout.
-- 
-- key2 = sample A
-- key3 = sample B
-- enc2 = tempo
-- enc3 = rate selection
-- 

engine.name = 'Ack'

local ControlSpec = require 'controlspec'

local Ack = require 'jah/ack'

local tempo_spec = ControlSpec.new(20, 300, ControlSpec.WARP_LIN, 0, 130, "BPM")

local rates = {4, 3, 2, 1, 5/8, 1/2, 1/3, 1/4, 1/8, 1/16, 1/24, 1/32, 1/64, 1/128, 1/256}
local curr_rate_spec = ControlSpec.new(1, 15, 'lin', 1, 0, "")

local timer

local ppqn = 24
local ticks

local ts = {1, 0}

local function tick()
  ticks = (ticks or -1) + 1
  -- lol
  if ticks % ((ppqn * 4) * rates[params:get("curr_rate")]) == 0 then
    engine.multiTrig(ts[1], ts[2], 0, 0, 0, 0, 0, 0)
  end
  redraw()
end

local function update_metro_time()
  timer.time = 60/params:get("tempo")/ppqn
end

function init()
  print("spout init")
  norns.log.post("spout init")

  timer = metro.alloc()
  timer.callback = tick

  params:add_control("tempo", tempo_spec)
  params:set_action("tempo", function(bpm) update_metro_time() end)

  params:add_control("curr_rate", curr_rate_spec)

  update_metro_time()

  Ack.add_params()
  params:bang()

  -- params:read("spout.pset")

  params:read("step.pset")

  timer:start()
end

function redraw()
  screen.font_size(8)
  screen.clear()
  screen.level(15)

  screen.move(0, 8)
  screen.text("tempo "..params:string("tempo"))

  screen.move(84, 8)
  screen.text("rate "..params:string("curr_rate"))

  screen.update()
end

function enc(n, delta)
  if n == 1 then
    mix:delta("output", delta)
  elseif n == 2 then
    params:delta("tempo", delta)
  elseif n == 3 then
    params:delta("curr_rate", delta)
  end
end

function key(n, z)
  if n == 2 then
    ts = {1, 0}
  end
  if n == 3 then
    ts = {0, 1}
  end
end