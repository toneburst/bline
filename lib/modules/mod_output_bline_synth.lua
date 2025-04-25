--[[
Bline Output Module
Singleton module
https://www.tutorialspoint.com/lua/lua_singleton_modules.htm

Original internal Synth engine
]]--

local ControlSpec = require 'controlspec'

local BlineSynth = {}

BlineSynth.deviceName = "Bline Synth"
-- Parameter group name
BlineSynth.paramGroupName = "Bline Synth"
-- Parameter ID prefix
BlineSynth.paramIDPrefix = "output_bline_synth_"

-- Debug mode toggle
BlineSynth.debugMode = false

-------------------------------------------------
-- Add Params Function --------------------------
-------------------------------------------------

function BlineSynth.addParams()

	print("Adding params")

    params:add_group(BlineSynth.paramGroupName, 13)

	-- 1
    params:add_control(
		BlineSynth.paramIDPrefix .. "waveform",
		"Waveform",
		ControlSpec.new(0, 127, 'lin', 0, 127)
	)
    params:set_action(
		BlineSynth.paramIDPrefix .. "waveform",
		function(x)
			engine.waveform(x)
			--SCREEN_DIRTY = true
		end
	)
	-- 2
	params:add_control(
		BlineSynth.paramIDPrefix .. "sub_level",
		"Sub Level",
		ControlSpec.new(0, 127, 'lin', 0, 127)
	)
	params:set_action(
		BlineSynth.paramIDPrefix .. "sub_level",
		function(x)
			engine.sub_level(x)
			--SCREEN_DIRTY = true
		end
	)
	-- 3
    params:add_control(
		BlineSynth.paramIDPrefix .. "cutoff",
		"Filter Cutoff",
		ControlSpec.new(0, 127, 'lin', 0, 127)
	)
    params:set_action(
		BlineSynth.paramIDPrefix .. "cutoff",
		function(x)
			engine.cutoff(x)
			--SCREEN_DIRTY = true
		end
	)
	-- 4
    params:add_control(
		BlineSynth.paramIDPrefix .. "resonance",
		"Filter Resonance",
		ControlSpec.new(0, 127, 'lin', 0, 127)
	)
    params:set_action(
		BlineSynth.paramIDPrefix .. "resonance",
		function(x)
			engine.resonance(x)
			--SCREEN_DIRTY = true
		end
	)
	-- 5
    params:add_control(
		BlineSynth.paramIDPrefix .. "filter_overdrive",
		"Filter Overdrive",
		ControlSpec.new(0, 127, 'lin', 0, 127)
	)
    params:set_action(
		BlineSynth.paramIDPrefix .. "filter_overdrive",
		function(x)
			engine.filter_overdrive(x)
			--SCREEN_DIRTY = true
		end
	)
	-- 6
    params:add_control(
		BlineSynth.paramIDPrefix .. "envelope",
		"Filter Envelope",
		ControlSpec.new(0, 127, 'lin', 0, 127)
	)
    params:set_action(
		BlineSynth.paramIDPrefix .. "envelope",
		function(x)
			engine.envelope(x)
			--SCREEN_DIRTY = true
		end
	)
	-- 7
    params:add_control(
		BlineSynth.paramIDPrefix .. "decay",
		"Envelope Decay",
		ControlSpec.new(0, 127, 'lin', 0, 127)
	)
    params:set_action(
		BlineSynth.paramIDPrefix .. "decay",
		function(x)
			engine.decay(x)
			--SCREEN_DIRTY = true
		end
	)
	-- 8
    params:add_control(
		BlineSynth.paramIDPrefix .. "accent",
		"Accent",
		ControlSpec.new(0, 127, 'lin', 0, 127)
	)
    params:set_action(
		BlineSynth.paramIDPrefix .. "accent",
		function(x)
			engine.accent(x)
			--SCREEN_DIRTY = true
		end
	)
	-- 9
    params:add_control(
		BlineSynth.paramIDPrefix .. "slide_time",
		"Slide Time",
		ControlSpec.new(0, 127, 'lin', 0, 127)
	)
    params:set_action(
		BlineSynth.paramIDPrefix .. "slide_time",
		function(x)
			engine.slide_time(x)
			--SCREEN_DIRTY = true
		end
	)
	-- 10
	params:add_control(
		BlineSynth.paramIDPrefix .. "delay",
		"Delay",
		ControlSpec.new(0, 127, 'lin', 0, 127)
	)
	params:set_action(
		BlineSynth.paramIDPrefix .. "delay",
		function(x)
			engine.delay(x)
			--SCREEN_DIRTY = true
		end
	)
	-- 11
	params:add_control(
		BlineSynth.paramIDPrefix .. "distortion",
		"Distortion",
		ControlSpec.new(0, 127, 'lin', 0, 127)
	)
    params:set_action(
		BlineSynth.paramIDPrefix .. "distortion",
		function(x)
			engine.distortion(x)
			--SCREEN_DIRTY = true
		end
	)
	-- 12
	params:add_control(
		BlineSynth.paramIDPrefix .. "amp",
		"Amp",
		ControlSpec.new(0, 127, 'lin', 0, 127)
	)
    params:set_action(
		BlineSynth.paramIDPrefix .. "amp",
		function(x)
			engine.volume(x)
			--SCREEN_DIRTY = true
		end
	)
	-- 13
	params:add_control(
		BlineSynth.paramIDPrefix .. "pan",
		"Pan",
		ControlSpec.new(0, 127, 'lin', 0, 127)
	)
    params:set_action(
		BlineSynth.paramIDPrefix .. "pan",
		function(x)
			engine.pan(x)
			--SCREEN_DIRTY = true
		end
	)

	-- Hide param group from menu
	params:hide(BlineSynth.paramGroupName)

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
	params:show(BlineSynth.paramGroupName)

	-- Rebuild params table
	_menu.rebuild_params()

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
	params:hide(BlineSynth.paramGroupName)

	-- Rebuild params table
	_menu.rebuild_params()

end -- End BlineSynth.unload()

-----------------------------------------
-- Return Module Table ------------------
-----------------------------------------

return BlineSynth
