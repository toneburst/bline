--[[
Bline Output Module
Internal Open303-based Synth engine
Requires Open303_SuperCollider plugin
https://github.com/toneburst/Open303_SuperCollider
]]--

local ControlSpec = require 'controlspec'

local deviceName = "Bline Open303 Synth"
-- Parameter group name
local paramGroupName = "Bline Open303 Synth"
-- Parameter ID prefix
paramIDPrefix = "output_bline_open303_synth_"

local BlineSynthO303 = {}

-- Debug mode toggle
BlineSynthO303.debugMode = false

-------------------------------------------------
-- Add Params Function --------------------------
-------------------------------------------------

function BlineSynthO303.addParams()

	print("Adding params")

    params:add_group(paramGroupName, 12)

    params:add_control(
		paramIDPrefix .. "waveform",
		"Waveform",
		ControlSpec.new(0, 127, 'lin', 0, 127)
	)
    params:set_action(
		paramIDPrefix .. "waveform",
		function(x)
			engine.o303_waveform(x)
			--SCREEN_DIRTY = true
		end
	)

	-- params:add_control(
	-- 	paramIDPrefix .. "sub_level",
	-- 	"Sub Level",
	-- 	ControlSpec.new(0, 127, 'lin', 0, 127)
	-- )
	-- params:set_action(
	-- 	paramIDPrefix .. "sub_level",
	-- 	function(x)
	-- 		engine.o303_sub_level(x)
	-- 		--SCREEN_DIRTY = true
	-- 	end
	-- )

    params:add_control(
		paramIDPrefix .. "cutoff",
		"Filter Cutoff",
		ControlSpec.new(0, 127, 'lin', 0, 127)
	)
    params:set_action(
		paramIDPrefix .. "cutoff",
		function(x)
			engine.o303_cutoff(x)
			--SCREEN_DIRTY = true
		end
	)

    params:add_control(
		paramIDPrefix .. "resonance",
		"Filter Resonance",
		ControlSpec.new(0, 127, 'lin', 0, 127)
	)
    params:set_action(
		paramIDPrefix .. "resonance",
		function(x)
			engine.o303_resonance(x)
			--SCREEN_DIRTY = true
		end
	)

	params:add_control(
		paramIDPrefix .. "filter_morph",
		"Filter Morph",
		ControlSpec.new(0, 127, 'lin', 0, 127)
	)
    params:set_action(
		paramIDPrefix .. "filter_morph",
		function(x)
			engine.o303_filter_morph(x)
			--SCREEN_DIRTY = true
		end
	)

    -- params:add_control(
	-- 	paramIDPrefix .. "filter_overdrive",
	-- 	"Filter Overdrive",
	-- 	ControlSpec.new(0, 127, 'lin', 0, 127)
	-- )
    -- params:set_action(
	-- 	paramIDPrefix .. "filter_overdrive",
	-- 	function(x)
	-- 		engine.o303_filter_overdrive(x)
	-- 		--SCREEN_DIRTY = true
	-- 	end
	-- )

    params:add_control(
		paramIDPrefix .. "envelope",
		"Filter Envelope",
		ControlSpec.new(0, 127, 'lin', 0, 127)
	)
    params:set_action(
		paramIDPrefix .. "envelope",
		function(x)
			engine.o303_envelope(x)
			--SCREEN_DIRTY = true
		end
	)

    params:add_control(
		paramIDPrefix .. "decay",
		"Envelope Decay",
		ControlSpec.new(0, 127, 'lin', 0, 127)
	)
    params:set_action(
		paramIDPrefix .. "decay",
		function(x)
			engine.o303_decay(x)
			--SCREEN_DIRTY = true
		end
	)

    params:add_control(
		paramIDPrefix .. "accent",
		"Accent",
		ControlSpec.new(0, 127, 'lin', 0, 127)
	)
    params:set_action(
		paramIDPrefix .. "accent",
		function(x)
			engine.o303_accent(x)
			--SCREEN_DIRTY = true
		end
	)

    params:add_control(
		paramIDPrefix .. "slide_time",
		"Slide Time",
		ControlSpec.new(0, 127, 'lin', 0, 127)
	)
    params:set_action(
		paramIDPrefix .. "slide_time",
		function(x)
			engine.o303_slide_time(x)
			--SCREEN_DIRTY = true
		end
	)

	params:add_control(
		paramIDPrefix .. "distortion",
		"Distortion",
		ControlSpec.new(0, 127, 'lin', 0, 127)
	)
    params:set_action(
		paramIDPrefix .. "distortion",
		function(x)
			engine.o303_distortion(x)
			--SCREEN_DIRTY = true
		end
	)

	params:add_control(
		paramIDPrefix .. "amp",
		"Amp",
		ControlSpec.new(0, 127, 'lin', 0, 127)
	)
    params:set_action(
		paramIDPrefix .. "amp",
		function(x)
			engine.o303_volume(x)
			--SCREEN_DIRTY = true
		end
	)

	params:add_control(
		paramIDPrefix .. "pan",
		"Pan",
		ControlSpec.new(0, 127, 'lin', 0, 127)
	)
    params:set_action(
		paramIDPrefix .. "pan",
		function(x)
			engine.o303_pan(x)
			--SCREEN_DIRTY = true
		end
	)

	-- Hide param group from menu
	params:hide(paramGroupName)

	-- Rebuild params table
	_menu.rebuild_params()

end -- End BlineSynthO303.addParams()

--------------------------------------------------
-- Send Note-On ----------------------------------
--------------------------------------------------

function BlineSynthO303.noteOn(note, accent, slide, tie)

	-- Velocity (Accent ON/OFF)
    local velocity = 99
    if accent then
        velocity = 127
    end

    -- Send note on
    engine.note_on(note, velocity)

end -- End BlineSynthO303.noteOn(note, velocity)

--------------------------------------------------
-- Schedule Non-Slide Note Off -------------------
--------------------------------------------------

function BlineSynthO303.noteOff(note)

    -- Send note-off
    engine.note_off(note)

end -- End BlineSynthO303.noteOff(note)

--------------------------------------------------
-- All Notes Off ---------------------------------
--------------------------------------------------

function BlineSynthO303.allNotesOff()

	engine.all_notes_off(0)

end -- End BlineSynthO303.allNotesOff()

--------------------------------------------------
-- Unload Function -------------------------------
--------------------------------------------------

function BlineSynthO303.unload()

	print("Unloading Output module '" .. deviceName .. "'")

    -- Reset Synth
    BlineSynthO303.allNotesOff()

	-- Hide param group from menu
	params:hide(paramGroupName)

	-- Rebuild params table
	_menu.rebuild_params()

end -- End BlineSynthO303.unload()

--------------------------------------------------
-- Activate --------------------------------------
--------------------------------------------------

function BlineSynthO303.activate()

	print("Activating Output module '" .. deviceName .. "'")

	-- Unhide param group
	params:show(paramGroupName)

	-- Rebuild params table
	_menu.rebuild_params()

end -- End BlineSynthO303.activate()

--------------------------------------------------
-- Init Function ---------------------------------
--------------------------------------------------

function BlineSynthO303.init(debug)

	print("Initialising Output module '" .. deviceName .. "'")

	if (debug == true) then
		BlineSynthO303.debugMode = true
		print("Setting debug mode ON")
	end -- End set debug

	-- Add params
    BlineSynthO303.addParams()

	-- All-notes-off
    BlineSynthO303.allNotesOff()

end -- End BlineSynthO303.init()

-----------------------------------------
-- Return Module Table ------------------
-----------------------------------------

return BlineSynthO303
