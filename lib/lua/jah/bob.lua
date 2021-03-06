local ControlSpec = require 'controlspec'
local Formatters = require 'jah/formatters'
local Bob = {}

-- Autogenerated using Engine_Bob.generateLuaEngineModuleSpecsSection

local specs = {}

specs.cutoff = ControlSpec.FREQ
specs.resonance = ControlSpec.UNIPOLAR

Bob.specs = specs

local function bind(paramname, id, formatter)
  params:add_control(paramname, specs[id], formatter)
  params:set_action(paramname, engine[id])
end

function Bob.add_params()
  bind("cutoff", "cutoff")
  bind("resonance", "resonance", Formatters.percentage)
end

return Bob
