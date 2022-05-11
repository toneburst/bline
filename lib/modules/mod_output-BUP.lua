--[[
  Bline Note Player Module
]]--

local ControlSpec = require "controlspec"

-- Include
--local deviceBlineSynth = include("lib/modules/mod_output_bline_synth")

local first_run = true

local Output = {}

-- Output function index
Output.outputType = 1

Output.outputFunctions = {}
Output.outputFunctions[1] = include("lib/modules/mod_output_bline_synth")
Output.outputFunctions[2] = include("lib/modules/mod_output_midi_basic")
Output.outputFunctions[3] = include("lib/modules/mod_output_midi_cc")
Output.outputFunctions[4] = include("lib/modules/mod_output_crow_x0x")
Output.outputFunctions[5] = include("lib/modules/mod_output_crow_envs")

-- Current output device table
Output.outputDevice = {}
Output.outputDevice = Output.outputFunctions[1]

-- List of output modes
Output.outputDevices = {}
Output.outputDevices[1] = "Internal Synth"
Output.outputDevices[2] = "MIDI Basic"
-- Output.outputDevices[3] = "MIDI + CCs"
-- Output.outputDevices[4] = "Crow X0X"
-- Output.outputDevices[5] = "Crow Envelopes"

Output.previousNote = nil

-- Debug mode toggle
Output.debugMode = false

------------------------------------------
-- Add Params ----------------------------
------------------------------------------

function Output.addParams()

    params:add_group("Bline Output", 1)

    params:add_option(
		"output_device",
		"Output Device",
		Output.outputDevices,
		1
	)
    params:set_action(
		"output_device",
		function(x)
			Output.changeOutput(x)
		end
	)

end -- End Output.addParams()

------------------------------------------
-- Change Output -------------------------
------------------------------------------

function Output.changeOutput(index)

    print("Output module setting output device to " .. Output.outputDevices[index])

	-- Unload previous device if not first-run
	-- if (first_run == true) then
    	-- Silence current device
    	Output.outputDevice.unload()
	-- 	first_run = false
	-- end

    -- Select new device, initialise
    Output.outputDevice = Output.outputFunctions[index]
    Output.outputDevice.activate()

end -- End Output.changeOutput(index)

------------------------------------------
-- Note On -------------------------------
------------------------------------------

-- Send note-on to active output device
function Output.playNote(note, accent, slide, rest, step_length)

	Output.stepLength = step_length

	-- Tie flag (current note number same as previous note number)
	local tie = (Output.previousNote["note_num"] == note)

	--[[

	NOTE LOGIC TABLE

	=========================================================================================
	| PREV		|	CURRENT		|	NEW NOTE-ON		|	PREV NOTE-OFF	|	NEW NOTE-OFF	|
	=========================================================================================
	| NON-SLIDE	|	NON-SLIDE	|	Y				|	N				|	Y				|
	-----------------------------------------------------------------------------------------
	| NON-SLIDE	|	SLIDE		|	Y				|	N				|	N				|
	-----------------------------------------------------------------------------------------
	| SLIDE		|	SLIDE		|	IF NON-TIE 		|	IF NON-TIE		|	N				|
	-----------------------------------------------------------------------------------------
	| SLIDE		|	NON-SLIDE	|	IF NON-TIE		| 	Y				| 	Y				|
	-----------------------------------------------------------------------------------------

	]]--

	-- Check previous note slide
	if (Output.previousNote["slide"] == true) then -- SLIDE
		-- Check current note slide
		if (slide == true) then -- SLIDE SLIDE
			-- Check for tie
			if (tie == false) then -- SLIDE SLIDE NON-TIE
				--  Do note-on
				Output.sendNoteOn(note, accent)
				-- Schedule previous note-off (with overlap)
				clock.run(Output.schedulePreviousNoteOff, Output.previousNote["note"])
			end
		else -- SLIDE NON-SLIDE
			-- Check tie
			if (tie == false) then -- SLIDE NON-SLIDE NON-TIE
				--  Do note-on
				Output.sendNoteOn(note, accent)
			end
			-- Schedule previous note-off (with overlap)
			clock.run(Output.schedulePreviousNoteOff, Output.previousNote["note"])
			-- Schedule note-off
			clock.run(Output.scheduleCurrentNoteOff, note)
		end -- End check current note slide
	else -- NON-SLIDE
		-- Check current note slide
		if (slide == true) then -- NON-SLIDE SLIDE
			--  Do note-on
			Output.sendNoteOn(note, accent)
		else -- NON-SLIDE NON-SLIDE
			--  Do note-on
			Output.sendNoteOn(note, accent)
			-- Schedule note-off
			clock.run(Output.scheduleCurrentNoteOff, note)
		end
	end -- End check previous note slide

    -- Sent message to engine
    --Output.outputDevice.noteOn(note, accent, slide, rest, step_length)

	-- Set previous note
	Output.previousNote = {
        note = note,
        slide = slide
    }

end -- End Output.playNote(note, accent, slide, rest, step_length)

--------------------------------------------------
-- Send Note-On ----------------------------------
--------------------------------------------------

function Output.sendNoteOn(note, accent)

    -- Velocity (Accent ON/OFF)
    local velocity = 100
    if accent then
        velocity = 127
    end

    -- Send note on
    Output.outputDevice.noteOn(note, accent, slide, rest)

end

--------------------------------------------------
-- Schedule Non-Slide Note Off -------------------
--------------------------------------------------

function Output.scheduleCurrentNoteOff(note)

    -- Calculate 16th note gate-length
    local sleeptime = Output.stepLength * params:get("pgen_gate_length")

    -- Pause clock
    clock.sleep(sleeptime)

    -- Send note-off
    Output.outputDevice.noteOff(note)

end -- End Output.scheduleCurrentNoteOff(note)

--------------------------------------------------
-- Schedule Overlap Note Off ---------------------
--------------------------------------------------

function Output.schedulePreviousNoteOff(previous_note)

    -- Calculate 16th note gate-length
    local sleeptime = Output.stepLength * 0.01

    -- Pause clock
    clock.sleep(sleeptime)

    -- Send note-off
    Output.outputDevice.noteOff(previous_note)

end -- End Output.schedulePreviousNoteOff(previous_note)

------------------------------------------
-- All Notes Off -------------------------
------------------------------------------

function Output.allNotesOff()

	-- Send All Notes Off message to output device
	Output.outputDevice.allNotesOff()

end -- End Output.allNotesOff()

------------------------------------------
-- Init ----------------------------------
------------------------------------------

function Output.init(debug)

    print("Initialising Output module")

    if (debug) then
        Output.debugMode = true
		print("Setting debug mode ON")
    end

    -- set Params
    Output.addParams()

	-- Init all output modules
	for index, output in ipairs(Output.outputFunctions) do
    	output:init(nil)
	end

end -- End Output.init()

-----------------------------------------
-- Return Module Table ------------------
-----------------------------------------

return Output
