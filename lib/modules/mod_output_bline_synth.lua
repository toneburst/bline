--[[
Bline Output Module
Singleton module
https://www.tutorialspoint.com/lua/lua_singleton_modules.htm

Original internal Synth engine
]]--

local ControlSpec = require 'controlspec'

-- Parameter group name
local paramGroupName = "Bline Synth"
-- Parameter ID prefix
local paramIDPrefix = "output_bline_synth_"

local BlineSynth = {}

BlineSynth.deviceName = "Bline Synth"

-- Debug mode toggle
BlineSynth.debugMode = false

-------------------------------------------------
-- Add Params Function --------------------------
-------------------------------------------------

function BlineSynth.addParams()

	-- Parameter resolution (number of steps between integer values)
	local paramResolution = 5

	print("Adding params")

    params:add_group(paramGroupName, 12)

	-- 1
    params:add_control(
		paramIDPrefix .. "waveform",
		"Waveform",
		ControlSpec.def{
			min = 0.0, -- the minimum value
			max = 127.0, -- the maximum value
			warp = 'lin', -- a shaping option for the raw value
			step = 0.2, -- output value quantization
			default = 0.0, -- default value
			quantum = 1.0 / (127 * paramResolution), -- each delta will change raw value by this much
			wrap = false -- wrap around on overflow (true) or clamp (false)
		}
	)
    params:set_action(
		paramIDPrefix .. "waveform",
		function(x)
			engine.waveform(x)
			--SCREEN_DIRTY = true
		end
	)
	-- 2
	params:add_control(
		paramIDPrefix .. "sub_level",
		"Sub Level",
		ControlSpec.def{
			min = 0.0,
			max = 127.0,
			warp = 'lin',
			step = 0.2,
			default = 0.0,
			quantum = 1.0 / (127 * paramResolution),
			wrap = false
		}
	)
	params:set_action(
		paramIDPrefix .. "sub_level",
		function(x)
			engine.sub_level(x)
			--SCREEN_DIRTY = true
		end
	)
	-- 3
    params:add_control(
		paramIDPrefix .. "cutoff",
		"Filter Cutoff",
		ControlSpec.def{
			min = 0.0,
			max = 127.0,
			warp = 'lin',
			step = 0.2,
			default = 0.0,
			quantum = 1.0 / (127 * paramResolution),
			wrap = false
		}
	)
    params:set_action(
		paramIDPrefix .. "cutoff",
		function(x)
			engine.cutoff(x)
			--SCREEN_DIRTY = true
		end
	)
	-- 4
    params:add_control(
		paramIDPrefix .. "resonance",
		"Filter Resonance",
		ControlSpec.def{
			min = 0.0,
			max = 127.0,
			warp = 'lin',
			step = 0.2,
			default = 0.0,
			quantum = 1.0 / (127 * paramResolution),
			wrap = false
		}
	)
    params:set_action(
		paramIDPrefix .. "resonance",
		function(x)
			engine.resonance(x)
			--SCREEN_DIRTY = true
		end
	)
	-- 5
    params:add_control(
		paramIDPrefix .. "filter_overdrive",
		"Filter Overdrive",
		ControlSpec.def{
			min = 0.0,
			max = 127.0,
			warp = 'lin',
			step = 0.2,
			default = 0.0,
			quantum = 1.0 / (127 * paramResolution),
			wrap = false
		}
	)
    params:set_action(
		paramIDPrefix .. "filter_overdrive",
		function(x)
			engine.filter_overdrive(x)
			--SCREEN_DIRTY = true
		end
	)
	-- 6
    params:add_control(
		paramIDPrefix .. "envelope",
		"Filter Envelope",
		ControlSpec.def{
			min = 0.0,
			max = 127.0,
			warp = 'lin',
			step = 0.2,
			default = 0.0,
			quantum = 1.0 / (127 * paramResolution),
			wrap = false
		}
	)
    params:set_action(
		paramIDPrefix .. "envelope",
		function(x)
			engine.envelope(x)
			--SCREEN_DIRTY = true
		end
	)
	-- 7
    params:add_control(
		paramIDPrefix .. "decay",
		"Envelope Decay",
		ControlSpec.def{
			min = 0.0,
			max = 127.0,
			warp = 'lin',
			step = 0.2,
			default = 0.0,
			quantum = 1.0 / (127 * paramResolution),
			wrap = false
		}
	)
    params:set_action(
		paramIDPrefix .. "decay",
		function(x)
			engine.decay(x)
			--SCREEN_DIRTY = true
		end
	)
	-- 8
    params:add_control(
		paramIDPrefix .. "accent",
		"Accent",
		ControlSpec.def{
			min = 0.0,
			max = 127.0,
			warp = 'lin',
			step = 0.2,
			default = 0.0,
			quantum = 1.0 / (127 * paramResolution),
			wrap = false
		}
	)
    params:set_action(
		paramIDPrefix .. "accent",
		function(x)
			engine.accent(x)
			--SCREEN_DIRTY = true
		end
	)
	-- 9
    params:add_control(
		paramIDPrefix .. "slide_time",
		"Slide Time",
		ControlSpec.def{
			min = 0.0,
			max = 127.0,
			warp = 'lin',
			step = 0.2,
			default = 0.0,
			quantum = 1.0 / (127 * paramResolution),
			wrap = false
		}
	)
    params:set_action(
		paramIDPrefix .. "slide_time",
		function(x)
			engine.slide_time(x)
			--SCREEN_DIRTY = true
		end
	)
	-- 10
	params:add_control(
		paramIDPrefix .. "distortion",
		"Distortion",
		ControlSpec.def{
			min = 0.0,
			max = 127.0,
			warp = 'lin',
			step = 0.2,
			default = 0.0,
			quantum = 1.0 / (127 * paramResolution),
			wrap = false
		}
	)
    params:set_action(
		paramIDPrefix .. "distortion",
		function(x)
			engine.distortion(x)
			--SCREEN_DIRTY = true
		end
	)
	-- 11
	params:add_control(
		paramIDPrefix .. "amp",
		"Amp",
		ControlSpec.def{
			min = 0.0,
			max = 127.0,
			warp = 'lin',
			step = 0.2,
			default = 0.0,
			quantum = 1.0 / (127 * paramResolution),
			wrap = false
		}
	)
    params:set_action(
		paramIDPrefix .. "amp",
		function(x)
			engine.volume(x)
			--SCREEN_DIRTY = true
		end
	)
	-- 12
	params:add_control(
		paramIDPrefix .. "pan",
		"Pan",
		ControlSpec.def{
			min = 0.0,
			max = 127.0,
			warp = 'lin',
			step = 0.2,
			default = 64.0,
			quantum = 1.0 / (127 * paramResolution),
			wrap = false
		}
	)
    params:set_action(
		paramIDPrefix .. "pan",
		function(x)
			engine.pan(x)
			--SCREEN_DIRTY = true
		end
	)

	-- Hide param group from menu
	params:hide(paramGroupName)

	-- Rebuild params table
	_menu.rebuild_params()

end -- End BlineSynth.addParams()

--------------------------------------------------
-- Send Note-On ----------------------------------
--------------------------------------------------

function BlineSynth.noteOn(note, accent, slide, tie)

	-- Velocity (Accent ON/OFF)
    local velocity = 100
    if accent then
        velocity = 127
    end

    -- Send note on
    engine.note_on(note, velocity)

end -- End BlineSynth.noteOn(note, velocity)

--------------------------------------------------
-- Schedule Non-Slide Note Off -------------------
--------------------------------------------------

function BlineSynth.noteOff(note)

    -- Send note-off
    engine.note_off(note)

end -- End BlineSynth.noteOff(note)

--------------------------------------------------
-- All Notes Off ---------------------------------
--------------------------------------------------

function BlineSynth.allNotesOff()

	engine.all_notes_off(0)

end -- End BlineSynth.allNotesOff()

--------------------------------------------------
-- Activate --------------------------------------
--------------------------------------------------

function BlineSynth.activate()

	print("Activating Output module '" .. BlineSynth.deviceName .. "'")

	-- Unhide param group
	params:show(paramGroupName)

	-- Rebuild params table
	_menu.rebuild_params()

	BlineSynth.allNotesOff()

	-- Enable audio output of Bline synth
	engine.source_select(2)

end -- End BlineSynth.activate()

--------------------------------------------------
-- Init Function ---------------------------------
--------------------------------------------------

function BlineSynth.init(debug)

	print("Initialising Output module '" .. BlineSynth.deviceName .. "'")

	if (debug == true) then
		BlineSynth.debugMode = true
		print("Setting debug mode ON")
	end -- End set debug

	-- Add params
    BlineSynth.addParams()

	-- All-notes-off
    BlineSynth.allNotesOff()

end -- End BlineSynth.init()

--------------------------------------------------
-- Unload Function -------------------------------
--------------------------------------------------

function BlineSynth.unload()

	print("Unloading Output module '" .. BlineSynth.deviceName .. "'")

    -- Reset Synth
    BlineSynth.allNotesOff()

	-- Hide param group from menu
	params:hide(paramGroupName)

	-- Rebuild params table
	_menu.rebuild_params()

end -- End BlineSynth.unload()

-----------------------------------------
-- Return Module Table ------------------
-----------------------------------------

return BlineSynth
