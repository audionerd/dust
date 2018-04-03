-- @name 3oscs
-- @version 0.1.0
-- @author jah
-- @txt test r

ControlSpec = require 'lua/jah/_controlspec'
Param = require 'lua/jah/_param'
Scroll = require 'lua/jah/_scroll'
Helper = require 'lua/jah/_helper'

engine = 'R'

local percent_spec = ControlSpec.new(0, 1, 'lin', 0, 0, "")
local widefreq_spec = ControlSpec.new(0.1, 20000, 'exp', 0, 440, "Hz")
local index_spec = ControlSpec.new(0, 24, 'lin', 0, 3, "")
local lofreq_spec = ControlSpec.new(0.1, 100, 'exp', 0, 6, "Hz")
local db_spec = ControlSpec.new(-60, 0, 'lin', 0, -60, "dB")
local delay_time_spec = ControlSpec.new(0.0001, 3, ControlSpec.WARP_EXP, 0, 0.3, "secs")

local osc1_freq = Param.new("osc1 freq", widefreq_spec)
local osc1_index = Param.new("osc1 index", index_spec)
local osc1_osc1_patch = Param.new("osc1 > osc1", db_spec) -- TODO: i dunno about feedback
local osc1_osc2_patch = Param.new("osc1 > osc2", db_spec)
local osc1_osc3_patch = Param.new("osc1 > osc3", db_spec)
local osc1_filter_patch = Param.new("osc1 > filter", db_spec)
local osc2_freq = Param.new("osc2 freq", widefreq_spec)
local osc2_index = Param.new("osc2 index", index_spec)
local osc2_osc1_patch = Param.new("osc2 > osc1", db_spec) -- TODO: i dunno about feedback
local osc2_osc2_patch = Param.new("osc2 > osc2", db_spec) -- TODO: i dunno about feedback
local osc2_osc3_patch = Param.new("osc2 > osc3", db_spec)
local osc2_filter_patch = Param.new("osc2 > filter", db_spec)
local osc3_freq = Param.new("osc3 freq", widefreq_spec)
local osc3_index = Param.new("osc3 index", index_spec)
local osc3_osc1_patch = Param.new("osc3 > osc1", db_spec) -- TODO: i dunno about feedback
local osc3_osc2_patch = Param.new("osc3 > osc2", db_spec) -- TODO: i dunno about feedback
local osc3_osc3_patch = Param.new("osc3 > osc3", db_spec) -- TODO: i dunno about feedback
local osc3_filter_patch = Param.new("osc3 > filter", db_spec)
local delay_send = Param.new("delay send level", db_spec)
local delayl_delaytime = Param.new("delayl delaytime", delay_time_spec)
local delayr_delaytime = Param.new("delayr delaytime", delay_time_spec)
local delay_feedback = Param.new("delay feedback", db_spec)
local output_level = Param.new("output level", db_spec)
local filter_freq = Param.new("filter freq", percent_spec)
local filter_res = Param.new("filter res", percent_spec)
local filter_lforate = Param.new("filter lforate", lofreq_spec)
local filter_lfodepth = Param.new("filter lfodepth", percent_spec)

local function to_hz(note)
  local exp = (note - 21) / 12
  return 27.5 * 2^exp
end

local function update_delay_send()
  e.patch('filter', 'delayl', delay_send:mapped_value())
  e.patch('filter', 'delayr', delay_send:mapped_value())
end

local function update_delay_feedback()
  e.patch('delayl', 'delayr', delay_feedback:mapped_value())
  e.patch('delayr', 'delayl', delay_feedback:mapped_value())
end

local function update_output_level()
  e.patch('delayl', 'outl', output_level:mapped_value())
  e.patch('delayr', 'outr', output_level:mapped_value())
  e.patch('filter', 'outl', output_level:mapped_value())
  e.patch('filter', 'outr', output_level:mapped_value())
end

local function split_param_name(param)
  words = {}
  for word in param.title:gmatch("[a-zA-Z0-9>]+") do table.insert(words, word) end
  return words
end

local function is_patch_param(param)
  return split_param_name(param)[2] == '>'
end

local function send_param_value_to_engine(param)
  print("send_param_value_to_engine: "..param.title)
  if param == delay_send then
    update_delay_send()
  elseif param == delay_feedback then
    update_delay_feedback()
  elseif param == output_level then
    update_output_level()
  elseif is_patch_param(param) then
    module_gt_module = split_param_name(param)
    e.patch(module_gt_module[1], module_gt_module[3], param:mapped_value())
  else
    module_param = split_param_name(param)
    e.param(module_param[1], module_param[2], param:mapped_value())
  end
end

local function send_param_values_to_engine(params)
  for i, param in ipairs(params) do
    send_param_value_to_engine(param)
  end
end

local function init_osc1()
  osc1_freq:set_mapped_value(to_hz(69+12))
  osc1_index:revert_to_default()
  osc1_filter_patch:set(0)
  osc1_osc1_patch:set(0)
  osc1_osc2_patch:set(db_spec:unmap(-20))
  osc1_osc3_patch:set(db_spec:unmap(-20))
  send_param_values_to_engine({osc1_freq, osc1_index, osc1_osc1_patch, osc1_osc2_patch, osc1_osc3_patch, osc1_filter_patch})
end

local function init_osc2()
  osc2_freq:set_mapped_value(to_hz(69-12))
  osc2_index:set_mapped_value(9)
  osc2_filter_patch:set_mapped_value(-20)
  osc2_osc1_patch:set(0)
  osc2_osc2_patch:set(0)
  osc2_osc3_patch:set(0)
  send_param_values_to_engine({osc2_freq, osc2_index, osc2_osc1_patch, osc2_osc2_patch, osc2_osc3_patch, osc2_filter_patch})
end

local function init_osc3()
  osc3_freq:set_mapped_value(to_hz(69))
  osc3_index:revert_to_default()
  osc3_filter_patch:set_mapped_value(-20)
  osc3_osc1_patch:set(0)
  osc3_osc2_patch:set(0)
  osc3_osc3_patch:set(0)
  send_param_values_to_engine({osc3_freq, osc3_index, osc3_osc1_patch, osc3_osc2_patch, osc3_osc3_patch, osc3_filter_patch})
end

local function init_filter()
  filter_freq:set(0.4)
  filter_res:set(0.1)
  filter_lforate:set_mapped_value(0.1)
  filter_lfodepth:set(0.1)
  send_param_values_to_engine({filter_freq, filter_res, filter_lforate, filter_lfodepth})
end

local function init_delay()
  delay_send:set_mapped_value(-30)
  update_delay_send()
  delayl_delaytime:set_mapped_value(0.23)
  delayr_delaytime:set_mapped_value(0.45)
  send_param_values_to_engine({delayl_delaytime, delayr_delaytime})

  delay_feedback:set_mapped_value(-20)
  update_delay_feedback()
end

local function init_output()
  e.param('outr', 'config', 1) -- sets outr to output on right channel
  output_level:set_mapped_value(-40)
  update_output_level()
end

local function note_on(note, velocity)
  print("note_on: "..note..", velocity: "..velocity) -- TODO: replace this with on-screen notification
  osc1_ratio = osc1_freq:mapped_value() / osc3_freq:mapped_value()
  osc2_ratio = osc2_freq:mapped_value() / osc3_freq:mapped_value()
  local freq = to_hz(note)
  osc1_freq:set_mapped_value(freq*osc1_ratio)
  osc2_freq:set_mapped_value(freq*osc2_ratio)
  osc3_freq:set_mapped_value(freq)
  send_param_values_to_engine({osc1_freq, osc2_freq, osc3_freq})
  redraw()
end

local function note_off(note)
  print("note_off: "..note)
end

local function cc(control, value)
  print("control: "..control..", value: "..value) -- TODO: replace this with on-screen notification
  if control == 1 then
    print("osc3_index:set: "..value/127)
    osc3_index:set(value/127)
    send_param_value_to_engine(osc3_index)
    redraw()
  elseif control == 2 then
    print("osc2_index:set: "..value/127)
    osc2_index:set(value/127)
    send_param_value_to_engine(osc2_index)
    redraw()
  elseif control == 3 then
    print("filter_freq:set: "..value/127)
    filter_freq:set(value/127)
    send_param_value_to_engine(filter_freq)
    redraw()
  elseif control == 4 then
    print("filter_res:set: "..value/127)
    filter_res:set(value/127)
    send_param_value_to_engine(filter_res)
    redraw()
  end
end

init = function()
  s.aa(1)
  s.line_width(1.0)

  e.capacity(8)
  e.module('osc1', 'oscil')
  e.module('osc2', 'oscil')
  e.module('osc3', 'oscil')
  e.module('filter', 'pole')
  e.module('delayl', 'delay')
  e.module('delayr', 'delay')
  e.module('outl', 'output')
  e.module('outr', 'output')

  init_osc1()
  init_osc2()
  init_osc3()
  init_filter()
  init_delay()
  init_output()

  scroll = Scroll.new()
  scroll:push("this is a test of r.")
  scroll:push("three oscillators")
  scroll:push("a modulating filter")
  scroll:push("and a stereo delay")
  scroll:push("")
  scroll:push("scroll ui with middle enc.")
  scroll:push("adjust values with rightmost")
  scroll:push("enc - hold middle key to")
  scroll:push("fine adjust. rightmost key")
  scroll:push("will revert value to default.")
  scroll:push("")
  scroll:push(osc1_freq)
  scroll:push(osc1_index)
  scroll:push(osc1_filter_patch)
  scroll:push(osc1_osc1_patch)
  scroll:push(osc1_osc2_patch)
  scroll:push(osc1_osc3_patch)
  scroll:push("")
  scroll:push(osc2_freq)
  scroll:push(osc2_index)
  scroll:push(osc2_filter_patch)
  scroll:push(osc2_osc1_patch)
  scroll:push(osc2_osc2_patch)
  scroll:push(osc2_osc3_patch)
  scroll:push("")
  scroll:push(osc3_freq)
  scroll:push(osc3_index)
  scroll:push(osc3_filter_patch)
  scroll:push(osc3_osc1_patch)
  scroll:push(osc3_osc2_patch)
  scroll:push(osc3_osc3_patch)
  scroll:push("")
  scroll:push(filter_freq)
  scroll:push(filter_res)
  scroll:push(filter_lforate)
  scroll:push(filter_lfodepth)
  scroll:push("")
  scroll:push(delay_send)
  scroll:push(delayl_delaytime)
  scroll:push(delayr_delaytime)
  scroll:push(delay_feedback)
  scroll:push("")
  scroll:push(output_level)
  scroll:push("")
  scroll:push("midi support:")
  scroll:push("note ons will change")
  scroll:push("osc3 freq, and osc1")
  scroll:push("and osc2 freqs relative")
  scroll:push("to osc1.")
  scroll:push("")
  scroll:push("op-1 (midi ctrl mode):")
  scroll:push("knobs will change osc3 index,")
  scroll:push("osc2 index, filter freq,")
  scroll:push("filter res")
  scroll:push("")
  scroll:push("...fin")
  redraw()
end

redraw = function()
  if scroll then
    scroll:redraw()
  end
  s.update()
end

enc = function(n, delta)
  if n == 1 then
    Helper.adjust_audio_output_level(delta)
    return
  end

  local d
  if key2_down then
    d = delta/2500
  else
    d = delta/100
  end
  if n == 2 then
    scroll:navigate(delta)
    redraw()
  elseif n == 3 then
    if scroll.selected_param then
      local param = scroll.selected_param
      param:adjust(d)
      send_param_value_to_engine(param)
      redraw()
    end
  end
end

key = function(n, z)
  if z == 1 then
    if n == 2 then
      key2_down = true
    elseif n == 3 then
      if scroll.selected_param then
        local param = scroll.selected_param
        param:revert_to_default()
        send_param_value_to_engine(param)
        redraw()
      end
    end
  end
  if z == 0 then
    if n == 2 then
      key2_down = false
    elseif n == 3 then
    end
  end
end

cleanup = function()
  norns.midi.event = nil
end

norns.midi.event = function(id, status, data1, data2)
  print(id, status, data1, data2)
  if status == 144 then
    --[[
    if data1 == 0 then
      return -- TODO: filter OP-1 bpm link oddity, is this an op-1 or norns issue?
    end
    ]]
    note_on(data1, data2)
  elseif status == 128 then
    --[[
    if data1 == 0 then
      return -- TODO: filter OP-1 bpm link oddity, is this an op-1 or norns issue?
    end
    ]]
    note_off(data1)
  elseif status == 176 then
    cc(data1, data2)
  elseif status == 224 then
    bend(data1, data2)
  end
end