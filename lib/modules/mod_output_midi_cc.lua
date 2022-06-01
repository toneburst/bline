--[[
Bline Output Module
MIDI Output with CCs
]]--

local ControlSpec = require 'controlspec'

local MIDIOutCC = {}

MIDIOutCC.deviceName = "MIDI + CC"
-- Parameter group name
MIDIOutCC.paramGroupName = ""
-- Parameter ID prefix
MIDIOutCC.paramIDPrefix = "output_midi_cc_"

MIDIOutCC.midi_out_device = nil
MIDIOutCC.midi_out_channel = nil

-- Non-Accent velocity
MIDIOutCC.velocityNonAccent = 100
-- Accent velocity
MIDIOutCC.velocityAccent = 127
-- Octave-shift
MIDIOutCC.octaveShift = 0

-- Default CC numbers (General MIDI)
MIDIOutCC.CCCutoff = nil
MIDIOutCC.CCFilterDecay = nil
MIDIOutCC.CCFilterModAmt = nil
MIDIOutCC.CCSlideTime = nil

-- Debug mode toggle
MIDIOutCC.debugMode = false

-------------------------------------------------
-- Add Params Function --------------------------
-------------------------------------------------

function MIDIOutCC.addParams()

	print("Adding params")

	params:add_group(MIDIOutCC.paramGroupName, 5)

	-- Get list of available MIDI devices
	local devices = {}
	for id, device in pairs(midi.vports) do
		devices[id] = device.name
	end

	-- Add MIDI output device param
	params:add {
		type = "option",
		id = MIDIOutCC.paramIDPrefix .. "midi_device",
		name = "MIDI Device",
		options = devices,
		default = 2,
		action = function(x)
			MIDIOutCC.midi_out_device = midi.connect(x)
		end
	}

	-- Add MIDI output channel param
	params:add {
		type = "number",
		id = MIDIOutCC.paramIDPrefix .. "midi_channel",
		name = "MIDI Channel",
		min = 1,
		max = 16,
		default = 1,
		action = function(x)
			MIDIOutCC.allNotesOff()
			MIDIOutCC.midi_out_channel = x
		end
  	}

	-- Add non-accent velocity param
	params:add {
		type = "number",
		id = MIDIOutCC.paramIDPrefix .. "na_velocity",
		name = "Non-Accent Velocity",
		min = 0,
		max = 127,
		default = MIDIOutCC.velocityNonAccent,
		action = function(x)
			MIDIOutCC.velocityNonAccent = x
		end
	}

	-- Add non-accent velocity param
	params:add {
		type = "number",
		id = MIDIOutCC.paramIDPrefix .. "a_velocity",
		name = "Accent Velocity",
		min = 0,
		max = 127,
		default = MIDIOutCC.velocityAccent,
		action = function(x)
			MIDIOutCC.velocityAccent = x
		end
	}

	-- Add Panic param
	params:add {
		type = "trigger",
		id = MIDIOutCC.paramIDPrefix .. "PANIC",
		name = "PANIC",
		action = function()
			MIDIOutCC.allNotesOff()
		end
	}

	-- Hide param group
	params:hide(MIDIOutCC.paramGroupName)

	-- Rebuild params table
	_menu.rebuild_params()

end -- End MIDIOutCC.addParams()

--------------------------------------------------
-- Send Note-On ----------------------------------
--------------------------------------------------

function MIDIOutCC.noteOn(note, accent, slide, tie)

	local n = note + (12 * MIDIOutCC.octaveShift)

	-- Velocity (Accent ON/OFF)
	local velocity = MIDIOutCC.velocityNonAccent
	if accent then
		velocity = MIDIOutCC.velocityAccent
	end

	-- Send note on
	MIDIOutCC.midi_out_device:note_on(note, velocity, MIDIOutCC.midi_out_channel)

end -- End MIDIOutCC.noteOn(note, velocity)

--------------------------------------------------
-- Send Note-Off ---------------------------------
--------------------------------------------------

function MIDIOutCC.noteOff(note)

    -- Send note-off
	MIDIOutCC.midi_out_device:note_off(note, nil, MIDIOutCC.midi_out_channel)

end -- End MIDIOutCC.noteOff(note)

--------------------------------------------------
-- All Notes Off ---------------------------------
--------------------------------------------------

function MIDIOutCC.allNotesOff()

	MIDIOutCC.midi_out_device:cc(123, 0, MIDIOutCC.midi_out_channel)

end -- End MIDIOutCC.allNotesOff()

--------------------------------------------------
-- Unload Function -------------------------------
--------------------------------------------------

function MIDIOutCC.unload()

	print("Unloading Output module '" .. MIDIOutCC.deviceName .. "'")

    -- All notes off

	-- Hide param group from menu
	params:hide(MIDIOutCC.paramGroupName)

	-- Rebuild params table
	_menu.rebuild_params()

	-- All notes off
	MIDIOutCC.allNotesOff()

end -- End MIDIOutCC.unload()

--------------------------------------------------
-- Activate --------------------------------------
--------------------------------------------------

function MIDIOutCC.activate()

	print("Activating Output module '" .. MIDIOutCC.deviceName .. "'")

	-- Unhide param group
	params:show(MIDIOutCC.paramGroupName)

	-- Rebuild params table
	_menu.rebuild_params()

end -- End MIDIOutCC.activate()

--------------------------------------------------
-- Init Function ---------------------------------
--------------------------------------------------

function MIDIOutCC.init(debug)

	print("Initialising Output module '" .. MIDIOutCC.deviceName .. "'")

	if (debug == true) then
		MIDIOutCC.debugMode = true
		print("Setting debug mode ON")
	end -- End set debug

	MIDIOutCC.midi_out_device = midi.connect(1)
	MIDIOutCC.midi_out_device.event = function() end

	-- Param group name
	MIDIOutCC.paramGroupName = MIDIOutCC.deviceName .. " Output"

	-- Add params
    MIDIOutCC.addParams()

	-- Send all-notes-off
	MIDIOutCC.allNotesOff()

	-- Turn on Mono Legato mode
	MIDIOutCC.midi_out_device:cc(68, 127, MIDIOutCC.midi_out_channel)

end -- End MIDIOutCC.init()

-----------------------------------------
-- Return Module Table ------------------
-----------------------------------------

return MIDIOutCC
