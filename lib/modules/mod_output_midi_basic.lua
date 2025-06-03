--[[
Bline Output Module
Basic MIDI Output (note + velocity)
]]--

local ControlSpec = require 'controlspec'

local deviceName = "MIDI Basic"
-- Parameter group name
local paramGroupName = ""
-- Parameter ID prefix
local paramIDPrefix = "output_midi_basic_"

local midiOutDevice = nil
local midiOutChannel = nil

-- Non-Accent velocity
local velocityNonAccent = 100
-- Accent velocity
local velocityAccent = 127
-- Octave-shift
local octaveShift = 0

local MIDIOutBasic = {}

-- Make device name accessible
MIDIOutBasic.deviceName = deviceName

-- Debug mode toggle
MIDIOutBasic.debugMode = false

-------------------------------------------------
-- Add Params Function --------------------------
-------------------------------------------------

function MIDIOutBasic.addParams()

	print("Adding params")

	params:add_group(paramGroupName, 5)

	-- Get list of available MIDI devices
	local devices = {}
	for i, device in pairs(midi.vports) do
		devices[i] = device.name
	end

	-- Add MIDI output device param
	params:add {
		type = "option",
		id = paramIDPrefix .. "midi_device",
		name = "Device",
		options = devices,
		default = 2,
		action = function(x)
			midiOutDevice = midi.connect(x)
		end
	}

	-- Add MIDI output channel param
	params:add {
		type = "number",
		id = paramIDPrefix .. "midi_channel",
		name = "Channel",
		min = 1,
		max = 16,
		default = 1,
		action = function(x)
			MIDIOutBasic.allNotesOff()
			midiOutChannel = x
		end
  	}

	-- Add non-accent velocity param
	params:add {
		type = "number",
		id = paramIDPrefix .. "na_velocity",
		name = "Non-Accent Velocity",
		min = 0,
		max = 127,
		default = 100,
		action = function(x)
			velocityNonAccent = x
		end
	}

	-- Add non-accent velocity param
	params:add {
		type = "number",
		id = paramIDPrefix .. "a_velocity",
		name = "Accent Velocity",
		min = 0,
		max = 127,
		default = 127,
		action = function(x)
			velocityAccent = x
		end
	}

	-- Add Panic param
	params:add {
		type = "trigger",
		id = paramIDPrefix .. "PANIC",
		name = "PANIC",
		action = function()
			MIDIOutBasic.allNotesOff()
		end
	}


	-- Hide param group
	params:hide(paramGroupName)

	-- Rebuild params table
	_menu.rebuild_params()

end -- End MIDIOutBasic.addParams()

--------------------------------------------------
-- Send Note-On ----------------------------------
--------------------------------------------------

function MIDIOutBasic.noteOn(note, accent, slide, tie)

	-- Velocity (Accent ON/OFF)
	local velocity = velocityNonAccent
	if accent then
		velocity = velocityAccent
	end

	-- Send note on
	midiOutDevice:note_on(note, velocity, midiOutChannel)

end -- End MIDIOutBasic.noteOn(note, velocity)

--------------------------------------------------
-- Send Note-Off ---------------------------------
--------------------------------------------------

function MIDIOutBasic.noteOff(note)

    -- Send note-off
	midiOutDevice:note_off(note, nil, midiOutChannel)

end -- End MIDIOutBasic.noteOff(note)

--------------------------------------------------
-- All Notes Off ---------------------------------
--------------------------------------------------

function MIDIOutBasic.allNotesOff()

	midiOutDevice:cc(123, 0, midiOutChannel)

end -- End MIDIOutBasic.allNotesOff()

--------------------------------------------------
-- Unload Function -------------------------------
--------------------------------------------------

function MIDIOutBasic.unload()

	print("Unloading Output module '" .. deviceName .. "'")

    -- All notes off

	-- Hide param group from menu
	params:hide(paramGroupName)

	-- Rebuild params table
	_menu.rebuild_params()

	-- All notes off
	MIDIOutBasic.allNotesOff()

end -- End MIDIOutBasic.unload()

--------------------------------------------------
-- Activate --------------------------------------
--------------------------------------------------

function MIDIOutBasic.activate()

	print("Activating Output module '" .. deviceName .. "'")

	-- Unhide param group
	params:show(paramGroupName)

	-- Rebuild params table
	_menu.rebuild_params()

	-- Disable audio output of both builtin synths
	engine.source_select(1)

end -- End MIDIOutBasic.activate()

--------------------------------------------------
-- Init Function ---------------------------------
--------------------------------------------------

function MIDIOutBasic.init(debug)

	print("Initialising Output module '" .. deviceName .. "'")

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
	midiOutDevice = midi.connect(1)
	midiOutDevice.event = function() end

	-- Param group name
	paramGroupName = deviceName .. " Output"

	-- Add params
	MIDIOutBasic.addParams()

	-- Send all-notes-off
	MIDIOutBasic.allNotesOff()

end -- End MIDIOutBasic.init()

-----------------------------------------
-- Return Module Table ------------------
-----------------------------------------

return MIDIOutBasic