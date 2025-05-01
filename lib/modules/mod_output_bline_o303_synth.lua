--[[
Bline Output Module
Singleton module
https://www.tutorialspoint.com/lua/lua_singleton_modules.htm

Internal Open303-based Synth engine
Requires Open303_SuperCollider plugin
https://github.com/toneburst/Open303_SuperCollider
]]--

local ControlSpec = require 'controlspec'

local BlineSynthO303 = {}

BlineSynthO303.deviceName = "Bline Open303 Synth"
-- Parameter group name
BlineSynthO303.deviceName = "Bline Open303 Synth"
-- Parameter ID prefix
BlineSynthO303.paramIDPrefix = "output_bline_open303_synth_"

-- Debug mode toggle
BlineSynthO303.debugMode = false

-------------------------------------------------
-- Add Params Function --------------------------
-------------------------------------------------

function BlineSynthO303.addParams()

	print("Adding params")

    params:add_group(BlineSynthO303.deviceName, 12)

	-- 1
    params:add_control(
		BlineSynthO303.paramIDPrefix .. "waveform",
		"Waveform",
		ControlSpec.def{
			min = 0.0, -- the minimum value
			max = 127.0, -- the maximum value
			warp = 'lin', -- a shaping option for the raw value
			step = 0.1, -- output value quantization
			default = 0.0, -- default value
			quantum = 0.1, -- each delta will change raw value by this much
			wrap = false -- wrap around on overflow (true) or clamp (false)
		}
	)
    params:set_action(
		BlineSynthO303.paramIDPrefix .. "waveform",
		function(x)
			engine.o303_waveform(x)
			--SCREEN_DIRTY = true
		end
	)
	-- 2
	params:add_control(
		BlineSynthO303.paramIDPrefix .. "sub_level",
		"Sub Level",
		ControlSpec.def{
			min = 0.0, -- the minimum value
			max = 127.0, -- the maximum value
			warp = 'lin', -- a shaping option for the raw value
			step = 0.1, -- output value quantization
			default = 0.0, -- default value
			quantum = 0.1, -- each delta will change raw value by this much
			wrap = false -- wrap around on overflow (true) or clamp (false)
		}
	)
	params:set_action(
		BlineSynthO303.paramIDPrefix .. "sub_level",
		function(x)
			engine.o303_sub_level(x)
			--SCREEN_DIRTY = true
		end
	)
	-- 3
    params:add_control(
		BlineSynthO303.paramIDPrefix .. "cutoff",
		"Filter Cutoff",
		ControlSpec.def{
			min = 0.0,
			max = 127.0,
			warp = 'lin',
			step = 0.01,
			default = 30.0,
			quantum = 0.01,
			wrap = false
		}
	)
    params:set_action(
		BlineSynthO303.paramIDPrefix .. "cutoff",
		function(x)
			engine.o303_cutoff(x)
			--SCREEN_DIRTY = true
		end
	)
	-- 4
    params:add_control(
		BlineSynthO303.paramIDPrefix .. "resonance",
		"Filter Resonance",
		ControlSpec.def{
			min = 0.0,
			max = 127.0,
			warp = 'lin',
			step = 0.01,
			default = 64.0,
			quantum = 0.01,
			wrap = false
		}
	)
    params:set_action(
		BlineSynthO303.paramIDPrefix .. "resonance",
		function(x)
			engine.o303_resonance(x)
			--SCREEN_DIRTY = true
		end
	)
	-- 5
	params:add_control(
		BlineSynthO303.paramIDPrefix .. "filter_morph",
		"Filter Morph",
		ControlSpec.def{
			min = 0.0,
			max = 127.0,
			warp = 'lin',
			step = 0.1,
			default = 0.0,
			quantum = 0.1,
			wrap = false
		}
	)
    params:set_action(
		BlineSynthO303.paramIDPrefix .. "filter_morph",
		function(x)
			engine.o303_filter_morph(x)
			--SCREEN_DIRTY = true
		end
	)
	-- 6
    params:add_control(
		BlineSynthO303.paramIDPrefix .. "envelope",
		"Filter Envelope",
		ControlSpec.def{
			min = 0.0,
			max = 127.0,
			warp = 'lin',
			step = 0.1,
			default = 32.00,
			quantum = 0.1,
			wrap = false
		}
	)
    params:set_action(
		BlineSynthO303.paramIDPrefix .. "envelope",
		function(x)
			engine.o303_envelope(x)
			--SCREEN_DIRTY = true
		end
	)
	-- 7
    params:add_control(
		BlineSynthO303.paramIDPrefix .. "decay",
		"Envelope Decay",
		ControlSpec.def{
			min = 0.0,
			max = 127.0,
			warp = 'lin',
			step = 0.1,
			default = 64.0,
			quantum = 0.1,
			wrap = false
		}
	)
    params:set_action(
		BlineSynthO303.paramIDPrefix .. "decay",
		function(x)
			engine.o303_decay(x)
			--SCREEN_DIRTY = true
		end
	)
	-- 8
    params:add_control(
		BlineSynthO303.paramIDPrefix .. "accent",
		"Accent",
		ControlSpec.def{
			min = 0.0,
			max = 127.0,
			warp = 'lin',
			step = 0.0,
			default = 64.0,
			quantum = 0.1,
			wrap = false
		}
	)
    params:set_action(
		BlineSynthO303.paramIDPrefix .. "accent",
		function(x)
			engine.o303_accent(x)
			--SCREEN_DIRTY = true
		end
	)
	-- 9
    params:add_control(
		BlineSynthO303.paramIDPrefix .. "slide_time",
		"Slide Time",
		ControlSpec.def{
			min = 0.0,
			max = 127.0,
			warp = 'lin',
			step = 0.1,
			default = 64.0,
			quantum = 0.1,
			wrap = false
		}
	)
    params:set_action(
		BlineSynthO303.paramIDPrefix .. "slide_time",
		function(x)
			engine.o303_slide_time(x)
			--SCREEN_DIRTY = true
		end
	)
	-- 10
	params:add_control(
		BlineSynthO303.paramIDPrefix .. "distortion",
		"Distortion",
		ControlSpec.def{
			min = 0.0,
			max = 127.0,
			warp = 'lin',
			step = 0.1,
			default = 0.0,
			quantum = 0.1,
			wrap = false
		}
	)
    params:set_action(
		BlineSynthO303.paramIDPrefix .. "distortion",
		function(x)
			engine.o303_distortion(x)
			--SCREEN_DIRTY = true
		end
	)
	-- 11
	params:add_control(
		BlineSynthO303.paramIDPrefix .. "amp",
		"Amp",
		ControlSpec.def{
			min = 0.0,
			max = 127.0,
			warp = 'lin',
			step = 0.1,
			default = 127.0,
			quantum = 0.1,
			wrap = false
		}
	)
    params:set_action(
		BlineSynthO303.paramIDPrefix .. "amp",
		function(x)
			engine.o303_volume(x)
			--SCREEN_DIRTY = true
		end
	)
	-- 12
	params:add_control(
		BlineSynthO303.paramIDPrefix .. "pan",
		"Pan",
		ControlSpec.def{
			min = 0.0,
			max = 127.0,
			warp = 'lin',
			step = 0.1,
			default = 64.0,
			quantum = 0.1,
			wrap = false
		}
	)
    params:set_action(
		BlineSynthO303.paramIDPrefix .. "pan",
		function(x)
			engine.o303_pan(x)
			--SCREEN_DIRTY = true
		end
	)

	-- Hide param group from menu
	params:hide(BlineSynthO303.deviceName)

	-- Rebuild params table
	_menu.rebuild_params()

end -- End BlineSynthO303.addParams()

--------------------------------------------------
-- Send Note-On ----------------------------------
--------------------------------------------------

function BlineSynthO303.noteOn(note, accent, slide, tie)

	-- Velocity (Accent ON/OFF)
    local velocity = 95
    if accent then
        velocity = 127
    end

    -- Send note on
    engine.o303_note_on(note, velocity)

end -- End BlineSynthO303.noteOn(note, velocity)

--------------------------------------------------
-- Schedule Non-Slide Note Off -------------------
--------------------------------------------------

function BlineSynthO303.noteOff(note)

    -- Send note-off
    engine.o303_note_off(note)

end -- End BlineSynthO303.noteOff(note)

--------------------------------------------------
-- All Notes Off ---------------------------------
--------------------------------------------------

function BlineSynthO303.allNotesOff()

	engine.o303_all_notes_off(0)

end -- End BlineSynthO303.allNotesOff()

--------------------------------------------------
-- Activate --------------------------------------
--------------------------------------------------

function BlineSynthO303.activate()

	print("Activating Output module '" .. BlineSynthO303.deviceName .. "'")

	-- Unhide param group
	params:show(BlineSynthO303.deviceName)

	-- Rebuild params table
	_menu.rebuild_params()

end -- End BlineSynthO303.activate()

--------------------------------------------------
-- Init Function ---------------------------------
--------------------------------------------------

function BlineSynthO303.init(debug)

	print("Initialising Output module '" .. BlineSynthO303.deviceName .. "'")

	if (debug == true) then
		BlineSynthO303.debugMode = true
		print("Setting debug mode ON")
	end -- End set debug

	-- Add params
    BlineSynthO303.addParams()

	-- All-notes-off
    BlineSynthO303.allNotesOff()

end -- End BlineSynthO303.init()

--------------------------------------------------
-- Unload Function -------------------------------
--------------------------------------------------

function BlineSynthO303.unload()

	print("Unloading Output module '" .. BlineSynthO303.deviceName .. "'")

    -- Reset Synth
    BlineSynthO303.allNotesOff()

	-- Hide param group from menu
	params:hide(BlineSynthO303.deviceName)

	-- Rebuild params table
	_menu.rebuild_params()

end -- End BlineSynthO303.unload()

-----------------------------------------
-- Return Module Table ------------------
-----------------------------------------

return BlineSynthO303
