--[[
  Bline Note Player Module
  Singleton module
  https://www.tutorialspoint.com/lua/lua_singleton_modules.htm
]]--

local ControlSpec = require "controlspec"

-- First-run flag
local first_run = true

-- Output function index
local outputType = 1

-- Step-length
local stepLength = nil

local outputFunctions = {}
outputFunctions[1] = require(_path.code .. "bline/lib/modules/mod_output_bline_synth")
outputFunctions[2] = require(_path.code .. "bline/lib/modules/mod_output_bline_o303_synth")
outputFunctions[3] = require(_path.code .. "bline/lib/modules/mod_output_midi_basic")
--outputFunctions[4] = require(_path.code .. "bline/lib/modules/mod_output_crow_x0x")
--outputFunctions[5] = irequire(_path.code .. "bline/lib/modules/mod_output_midi_cc")
--outputFunctions[6] = require(_path.code .. "bline/lib/modules/mod_output_crow_envs")

-- List of output modes (populated at init)
local outputDevices = {}

-- Current output device table
local outputDevice = {}

local previousNote = {
	note = 0,
	slide = false
}

local Output = {}

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
		outputDevices,
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

    print("Output module setting output device to " .. outputDevices[index])

	-- Unload previous device if not first-run
	-- Needed because this function gets called when param added to set initial value
	if (first_run == true) then
    	-- Toggle first_run so we can unload devices next time output changes
		first_run = false
	else
		-- Silence current device
    	outputDevice.unload()
	end

    -- Select new device, initialise
    outputDevice = outputFunctions[index]
    outputDevice.activate()

end -- End Output.changeOutput(index)

------------------------------------------
-- Note On -------------------------------
------------------------------------------

-- Send note-on to active output device
function Output.playNote(note, accent, slide, rest, step_length)

	stepLength = step_length

	-- Tie flag (current note number same as previous note number)
	local tie = (previousNote["note_num"] == note)

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

	-- Check if current note is rest
	if (rest) then
		-- If previous note still playing, turn off immediately
		if (previousNote["slide"]) then
			previousNoteOffImmediate(previousNote["note"])
		end
		-- Else do nothing
	elseif (previousNote["slide"] == true) then -- PREVIOUS NOTE SLIDE
		-- Check current note slide
		if (slide == true) then -- SLIDE SLIDE
			-- Check for tie
			if (tie == false) then -- SLIDE SLIDE NON-TIE
				--  Do note-on
				Output.sendNoteOn(note, accent, slide, rest)
				-- Schedule previous note-off (with overlap)
				clock.run(Output.schedulePreviousNoteOff, previousNote["note"])
			end
		else -- SLIDE NON-SLIDE
			-- Check tie
			if (tie == false) then -- SLIDE NON-SLIDE NON-TIE
				--  Do note-on
				Output.sendNoteOn(note, accent, slide, rest)
			end
			-- Schedule previous note-off (with overlap)
			clock.run(Output.schedulePreviousNoteOff, previousNote["note"])
			-- Schedule current note-off
			clock.run(Output.scheduleCurrentNoteOff, note)
		end -- End check current note slide
	else -- PREVIOUS NOTE NON-SLIDE
		-- Check current note slide
		if (slide == true) then -- NON-SLIDE SLIDE
			--  Do note-on
			Output.sendNoteOn(note, accent, slide, rest)
		else -- NON-SLIDE NON-SLIDE
			--  Do note-on
			Output.sendNoteOn(note, accent, slide, rest)
			-- Schedule note-off
			clock.run(Output.scheduleCurrentNoteOff, note)
		end
	end -- End check previous note slide

    -- Sent message to engine
    --outputDevice.noteOn(note, accent, slide, rest, step_length)

	-- Set previous note
	previousNote = {
        note = note,
        slide = slide
    }

end -- End Output.playNote(note, accent, slide, rest, step_length)

--------------------------------------------------
-- Send Note-On ----------------------------------
--------------------------------------------------

function Output.sendNoteOn(note, accent, slide, rest)

    -- Velocity (Accent ON/OFF)
    local velocity = 100
    if accent then
        velocity = 127
    end

    -- Send note on
    outputDevice.noteOn(note, accent, slide, rest)

end

--------------------------------------------------
-- Schedule Non-Slide Note Off -------------------
--------------------------------------------------

function Output.scheduleCurrentNoteOff(note)

    -- Calculate 16th note gate-length
    local sleeptime = stepLength * params:get("pgen_gate_length")

    -- Pause clock
    clock.sleep(sleeptime)

    -- Send note-off
    outputDevice.noteOff(note, false)

end -- End Output.scheduleCurrentNoteOff(note)

--------------------------------------------------
-- Immediate Note Off ----------------------------
--------------------------------------------------

function previousNoteOffImmediate(previous_note)

	-- Send note-off
    outputDevice.noteOff(previous_note, false)

end -- End previousNoteOffImmediate(previous_note)

--------------------------------------------------
-- Schedule Overlap Note Off ---------------------
--------------------------------------------------

function Output.schedulePreviousNoteOff(previous_note)

    -- Calculate 16th note gate-length
    local sleeptime = stepLength * 0.01

    -- Pause clock
    clock.sleep(sleeptime)

    -- Send note-off
    outputDevice.noteOff(previous_note, true)

end -- End Output.schedulePreviousNoteOff(previous_note)

------------------------------------------
-- All Notes Off -------------------------
------------------------------------------

function Output.allNotesOff()

	-- Send All Notes Off message to output device
	outputDevice.allNotesOff()

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

	-- Get device names
	for i, output in ipairs(outputFunctions) do
    	outputDevices[i] = outputFunctions[i].deviceName
	end

    -- set Params
    Output.addParams()

	-- Init all output modules
	for __, output in ipairs(outputFunctions) do
    	output:init(nil)
	end

end -- End Output.init()

-----------------------------------------
-- Return Module Table ------------------
-----------------------------------------

return Output
