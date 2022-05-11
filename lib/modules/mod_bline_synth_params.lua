--[[
  Add Bline Synth Params
]]--

local ControlSpec = require "controlspec"

local BlineSynthParams = {}

------------------------------------------------
-- Screen-Dirty Function -----------------------
------------------------------------------------

function BlineSynthParams.setScreenDirty()
	-- Set global var
	SCREEN_DIRTY = true
end -- End BlineSynthParams.setScreenDirty()

------------------------------------------------
-- Add Params ----------------------------------
------------------------------------------------

function BlineSynthParams.addParams()

    local ControlSpec = require 'controlspec'

    params:add_group("Bline Synth", 10)

    params:add_control("synth_waveform", "waveform", ControlSpec.new(0, 127, 'lin', 0.1, 127))
    params:set_action( "synth_waveform", function(x) engine.waveform(x); BlineSynthParams.setScreenDirty() end)

    params:add_control("synth_cutoff", "cutoff", ControlSpec.new(0, 127, 'lin', 0.01, 64))
    params:set_action( "synth_cutoff", function(x) engine.cutoff(x); BlineSynthParams.setScreenDirty() end)

    params:add_control("synth_resonance", "resonance", ControlSpec.new(0, 127, 'lin', 0.1, 80))
    params:set_action( "synth_resonance", function(x) engine.resonance(x); BlineSynthParams.setScreenDirty() end)

    params:add_control("synth_filter_overdrive", "filter overdrive", ControlSpec.new(0, 127, 'lin', 0.1, 0))
    params:set_action( "synth_filter_overdrive", function(x) engine.filter_overdrive(x); BlineSynthParams.setScreenDirty() end)

    params:add_control("synth_envelope", "envelope", ControlSpec.new(0, 127, 'lin', 0.1, 100))
    params:set_action( "synth_envelope", function(x) engine.envelope(x); BlineSynthParams.setScreenDirty() end)

    params:add_control("synth_decay", "decay", ControlSpec.new(0, 127, 'lin', 0.1, 100))
    params:set_action( "synth_decay", function(x) engine.decay(x); BlineSynthParams.setScreenDirty() end)

    params:add_control("synth_accent", "accent", ControlSpec.new(0, 127, 'lin', 0.1, 100))
    params:set_action( "synth_accent", function(x) engine.accent(x); BlineSynthParams.setScreenDirty() end)

    params:add_control("synth_slide_time", "slide time", ControlSpec.new(0, 1, 'lin', 0.01, 0.15))
    params:set_action( "synth_slide_time", function(x) engine.slide_time(x); BlineSynthParams.setScreenDirty() end)

    params:add_control("synth_volume", "volume", ControlSpec.new(0, 127, 'lin', 0.1, 100))
    params:set_action( "synth_volume", function(x) engine.volume(x); BlineSynthParams.setScreenDirty() end)

    params:add_control("synth_pan", "pan", ControlSpec.new(0, 127, 'lin', 0.1, 64))
    params:set_action( "synth_pan", function(x) engine.volume(x); BlineSynthParams.setScreenDirty() end)

end -- End BlineSynthParams.add_params()

return BlineSynthParams
