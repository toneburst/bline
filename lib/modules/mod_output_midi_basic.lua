--[[
Bline Output Module
Basic MIDI Output (note + velocity)
]]--

local ControlSpec = require 'controlspec'

local MIDIOutBasic = {}

MIDIOutBasic.deviceName = "MIDI Basic"
-- Parameter group name
MIDIOutBasic.paramGroupName = ""
-- Parameter ID prefix
MIDIOutBasic.paramIDPrefix = "output_midi_basic_"

MIDIOutBasic.midi_out_device = nil
MIDIOutBasic.midi_out_channel = nil

-- Non-Accent velocity
MIDIOutBasic.velocityNonAccent = 100
-- Accent velocity
MIDIOutBasic.velocityAccent = 127
-- Octave-shift
MIDIOutBasic.octaveShift = 0

-- Debug mode toggle
MIDIOutBasic.debugMode = false

-------------------------------------------------
-- Add Params Function --------------------------
-------------------------------------------------

function MIDIOutBasic.addParams()

	print("Adding params")

	params:add_group(MIDIOutBasic.paramGroupName, 5)

	-- Get list of available MIDI devices
	local devices = {}
	for id, device in pairs(midi.vports) do
		devices[id] = device.name
	end

	-- Add MIDI output device param
	params:add {
		type = "option",
		id = MIDIOutBasic.paramIDPrefix .. "midi_device",
		name = "Device",
		options = devices,
		default = 2,
		action = function(x)
			MIDIOutBasic.midi_out_device = midi.connect(x)
		end
	}

	-- Add MIDI output channel param
	params:add {
		type = "number",
		id = MIDIOutBasic.paramIDPrefix .. "midi_channel",
		name = "Channel",
		min = 1,
		max = 16,
		default = 1,
		action = function(x)
			MIDIOutBasic.allNotesOff()
			MIDIOutBasic.midi_out_channel = x
		end
  	}

	-- Add non-accent velocity param
	params:add {
		type = "number",
		id = MIDIOutBasic.paramIDPrefix .. "na_velocity",
		name = "Non-Accent Velocity",
		min = 0,
		max = 127,
		default = 100,
		action = function(x)
			MIDIOutBasic.velocityNonAccent = x
		end
	}

	-- Add non-accent velocity param
	params:add {
		type = "number",
		id = MIDIOutBasic.paramIDPrefix .. "a_velocity",
		name = "Accent Velocity",
		min = 0,
		max = 127,
		default = 127,
		action = function(x)
			MIDIOutBasic.velocityAccent = x
		end
	}

	-- Add Panic param
	params:add {
		type = "trigger",
		id = MIDIOutBasic.paramIDPrefix .. "PANIC",
		name = "PANIC",
		action = function()
			MIDIOutBasic.allNotesOff()
		end
	}


	-- Hide param group
	params:hide(MIDIOutBasic.paramGroupName)

	-- Rebuild params table
	_menu.rebuild_params()

end -- End MIDIOutBasic.addParams()

--------------------------------------------------
-- Send Note-On ----------------------------------
--------------------------------------------------

function MIDIOutBasic.noteOn(note, accent, slide, tie)

	-- Velocity (Accent ON/OFF)
	local velocity = MIDIOutBasic.velocityNonAccent
	if accent then
		velocity = MIDIOutBasic.velocityAccent
	end

	-- Send note on
	MIDIOutBasic.midi_out_device:note_on(note, velocity, MIDIOutBasic.midi_out_channel)

end -- End MIDIOutBasic.noteOn(note, velocity)

--------------------------------------------------
-- Send Note-Off ---------------------------------
--------------------------------------------------

function MIDIOutBasic.noteOff(note)

    -- Send note-off
	MIDIOutBasic.midi_out_device:note_off(note, nil, MIDIOutBasic.midi_out_channel)

end -- End MIDIOutBasic.noteOff(note)

--------------------------------------------------
-- All Notes Off ---------------------------------
--------------------------------------------------

function MIDIOutBasic.allNotesOff()

	MIDIOutBasic.midi_out_device:cc(123, 0, MIDIOutBasic.midi_out_channel)

end -- End MIDIOutBasic.allNotesOff()

--------------------------------------------------
-- Unload Function -------------------------------
--------------------------------------------------

function MIDIOutBasic.unload()

	print("Unloading Output module '" .. MIDIOutBasic.deviceName .. "'")

    -- All notes off

	-- Hide param group from menu
	params:hide(MIDIOutBasic.paramGroupName)

	-- Rebuild params table
	_menu.rebuild_params()

	-- All notes off
	MIDIOutBasic.allNotesOff()

end -- End MIDIOutBasic.unload()

--------------------------------------------------
-- Activate --------------------------------------
--------------------------------------------------

function MIDIOutBasic.activate()

	print("Activating Output module '" .. MIDIOutBasic.deviceName .. "'")

	-- Unhide param group
	params:show(MIDIOutBasic.paramGroupName)

	-- Rebuild params table
	_menu.rebuild_params()

end -- End MIDIOutBasic.activate()

--------------------------------------------------
-- Init Function ---------------------------------
--------------------------------------------------

function MIDIOutBasic.init(debug)

	print("Initialising Output module '" .. MIDIOutBasic.deviceName .. "'")

	if (debug == true) then
		MIDIOutBasic.debugMode = true
		print("Setting debug mode ON")
	end -- End set debug

	-- Show Crow clock output menu items
	params:set("clock_crow_out", 2) -- set 'crow out' to 'on'
	params:show("clock_crow_out") -- hide the 'crow out' param
	params:show("clock_crow_out_div") -- hide the 'crow out div' param
	params:show("clock_crow_in_div") -- hide the 'crow in div' param

	-- Setup MIDI output
	MIDIOutBasic.midi_out_device = midi.connect(1)
	MIDIOutBasic.midi_out_device.event = function() end

	-- Turn on Mono Legato mode
	-- MIDIOutBasic.midi_out_device:cc(68, 127, MIDIOutBasic.midi_out_channel)

	-- Param group name
	MIDIOutBasic.paramGroupName = MIDIOutBasic.deviceName .. " Output"

	-- Add params
    MIDIOutBasic.addParams()

	-- Send all-notes-off
	MIDIOutBasic.allNotesOff()

end -- End MIDIOutBasic.init()

-----------------------------------------
-- Return Module Table ------------------
-----------------------------------------

return MIDIOutBasic
