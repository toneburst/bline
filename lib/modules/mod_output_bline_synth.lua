--[[
Bline Output Module
Internal Synth engine
]]--

local ControlSpec = require 'controlspec'

local deviceName = "Bline Synth"
-- Parameter group name
local paramGroupName = "Bline Synth"
-- Parameter ID prefix
paramIDPrefix = "output_bline_synth_"

local BlineSynth = {}

-- Debug mode toggle
BlineSynth.debugMode = false

-------------------------------------------------
-- Add Params Function --------------------------
-------------------------------------------------

function BlineSynth.addParams()

	print("Adding params")

    params:add_group(paramGroupName, 10)

    params:add_control(
		paramIDPrefix .. "waveform",
		"Waveform",
		ControlSpec.new(0, 127, 'lin', 0.1, 127)
	)
    params:set_action(
		paramIDPrefix .. "waveform",
		function(x)
			engine.waveform(x)
			SCREEN_DIRTY = true
		end
	)

    params:add_control(
		paramIDPrefix .. "cutoff",
		"Filter Cutoff",
		ControlSpec.new(0, 127, 'lin', 0.01, 64)
	)
    params:set_action(
		paramIDPrefix .. "cutoff",
		function(x)
			engine.cutoff(x)
			SCREEN_DIRTY = true
		end
	)

    params:add_control(
		paramIDPrefix .. "resonance",
		"Filter Resonance",
		ControlSpec.new(0, 127, 'lin', 0.1, 80)
	)
    params:set_action(
		paramIDPrefix .. "resonance",
		function(x)
			engine.resonance(x)
			SCREEN_DIRTY = true
		end
	)

    params:add_control(
		paramIDPrefix .. "filter_overdrive",
		"Filter Overdrive",
		ControlSpec.new(0, 127, 'lin', 0.1, 0)
	)
    params:set_action(
		paramIDPrefix .. "filter_overdrive",
		function(x)
			engine.filter_overdrive(x)
			SCREEN_DIRTY = true
		end
	)

    params:add_control(
		paramIDPrefix .. "envelope",
		"Filter Envelope",
		ControlSpec.new(0, 127, 'lin', 0.1, 100)
	)
    params:set_action(
		paramIDPrefix .. "envelope",
		function(x)
			engine.envelope(x)
			SCREEN_DIRTY = true
		end
	)

    params:add_control(
		paramIDPrefix .. "decay",
		"Envelope Decay",
		ControlSpec.new(0, 127, 'lin', 0.1, 100)
	)
    params:set_action(
		paramIDPrefix .. "decay",
		function(x)
			engine.decay(x)
			SCREEN_DIRTY = true
		end
	)

    params:add_control(
		paramIDPrefix .. "accent",
		"Accent",
		ControlSpec.new(0, 127, 'lin', 0.1, 100)
	)
    params:set_action(
		paramIDPrefix .. "accent",
		function(x)
			engine.accent(x)
			SCREEN_DIRTY = true
		end
	)

    params:add_control(
		paramIDPrefix .. "slide_time",
		"Slide Time",
		ControlSpec.new(0, 1, 'lin', 0.01, 0.15)
	)
    params:set_action(
		paramIDPrefix .. "slide_time",
		function(x)
			engine.slide_time(x)
			SCREEN_DIRTY = true
		end
	)

    params:add_control(
		paramIDPrefix .. "volume",
		"Volume",
		ControlSpec.new(0, 127, 'lin', 0.1, 100)
	)
    params:set_action(
		paramIDPrefix .. "volume",
		function(x)
			engine.volume(x)
			SCREEN_DIRTY = true
		end
	)

    params:add_control(
		paramIDPrefix .. "pan",
		"Pan",
		ControlSpec.new(0, 127, 'lin', 0.1, 64)
	)
    params:set_action(
		paramIDPrefix .. "pan",
		function(x)
			engine.volume(x)
			SCREEN_DIRTY = true
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
-- Unload Function -------------------------------
--------------------------------------------------

function BlineSynth.unload()

	print("Unloading Output module '" .. deviceName .. "'")

    -- Reset Synth
    BlineSynth.allNotesOff()

	-- Hide param group from menu
	params:hide(paramGroupName)

	-- Rebuild params table
	_menu.rebuild_params()

end -- End BlineSynth.unload()

--------------------------------------------------
-- Activate --------------------------------------
--------------------------------------------------

function BlineSynth.activate()

	print("Activating Output module '" .. deviceName .. "'")

	-- Unhide param group
	params:show(paramGroupName)

	-- Rebuild params table
	_menu.rebuild_params()

end -- End BlineSynth.activate()

--------------------------------------------------
-- Init Function ---------------------------------
--------------------------------------------------

function BlineSynth.init(debug)

	print("Initialising Output module '" .. deviceName .. "'")

	if (debug == true) then
		BlineSynth.debugMode = true
		print("Setting debug mode ON")
	end -- End set debug

	-- Add params
    BlineSynth.addParams()

	-- All-notes-off
    BlineSynth.allNotesOff()

end -- End BlineSynth.init()

-----------------------------------------
-- Return Module Table ------------------
-----------------------------------------

return BlineSynth
