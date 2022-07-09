--[[
Bline Pattern Generator Module
]]--

--------------------------------------------------
-- Includes --------------------------------------
--------------------------------------------------

local ControlSpec = require "controlspec"
local NornsUtils = require "lib.util"
local TabUtil = require "lib.tabutil"

-- Include quantiser
local quantiser = include("lib/modules/mod_quantiser")

-- Include channel "class"
local channel = include("lib/classes/class_channel")

-- Include note-player
local output = include("lib/modules/mod_output")

-- Require bline utils module
local bline_utils = include("lib/modules/mod_bline_utils")
--local bline_utils = require(_path.code .. "bline/lib/modules/mod_bline_utils")

-- Require Clockcut module
local delay = include("lib/modules/mod_fx_delay")

--------------------------------------------------
-- Local Variables -------------------------------
--------------------------------------------------

-- Master clock reset counts
local reset_counts = {}
reset_counts[1] = 8
reset_counts[2] = 16
reset_counts[3] = 32
reset_counts[4] = 64
reset_counts[5] = 128
reset_counts[6] = 256

-- Reset-count names
local reset_names = {}
reset_names[1] = "1/2 Bar"
reset_names[2] = "1 Bar"
reset_names[3] = "2 Bars"
reset_names[4] = "4 Bars"
reset_names[5] = "8 Bars"
reset_names[6] = "16 Bars"

-- Key 3 functions table
local k3_functions = {}
k3_functions[1] = {
    -- Do nothing
    label = "none",
    keydown = function() print("Key 3 unassigned"); end,
    keyup = function() print("Key 3 unassigned"); end
}
k3_functions[2] = {
    -- Reset sequencer position
    label = "Reset",
    keydown = function() RESET = true; end,
    keyup = function() end
}
k3_functions[3] = {
    -- Toggle sequencer start/stop
    label = "Start/Stop",
    keydown = function()
        -- Negate RUNNING flag (ie toggle true/false)
        RUNNING = (not RUNNING)
    end,
    keyup = function() end
}

--------------------------------------------------
-- Init Module Table -----------------------------
--------------------------------------------------

local PatternGenerator = {}

--------------------------------------------------
-- Table Variables -------------------------------
--------------------------------------------------

-- Node matrix position
PatternGenerator.posX = 0
PatternGenerator.posY = 0
PatternGenerator.jitterScale = 0
PatternGenerator.jitterVals = {} -- Jitter values array

-- Table of channel instances
PatternGenerator.channels = {
    notes = {},
    octaves = {},
    accents = {},
    slides = {},
    rests = {}
}

-- Table of all channel patterns (to pass on to UI function for display)
PatternGenerator.patterns = {
    note = {},
    octave = {},
    accent = {},
    slide = {},
    rest = {}
}

-- Stores table of data for current step
PatternGenerator.currentStepState = nil
--PatternGenerator.previous_step = {} -- NOT YET IMPLEMENTED

-- Master step-counter
PatternGenerator.masterStepCounter = 1
-- Bar-counter
PatternGenerator.barCounter = 1
-- Loop-length
PatternGenerator.loopLength = 16
-- Channel data offset
PatternGenerator.channelDataOffset = 0
-- Debug mode toggle
PatternGenerator.debugMode = false
-- Norns Key 3 Assignment index
PatternGenerator.k3Assign = 1

--------------------------------------------------
-- Add Params ------------------------------------
--------------------------------------------------

function PatternGenerator.addParams()

    print("Adding Pattern-Generator parameters")

    -- Add param group
    params:add_group("Bline Global", 8)

    -- Add Position X param
    params:add_control(
        "pgen_x",
        "Position X",
        ControlSpec.new(0, 4, 'lin', 0.01, 0)
    )
    params:set_action(
        "pgen_x",
        function(x)
            PatternGenerator.posX = x
            PatternGenerator.updatePatterns()
            SCREEN_DIRTY = true
        end
    )

    -- Add Position X param
    params:add_control(
        "pgen_y",
        "Position Y",
        ControlSpec.new(0, 4, 'lin', 0.01, 0)
    )
    params:set_action(
        "pgen_y",
        function(x)
            PatternGenerator.posY = x;
            PatternGenerator.updatePatterns()
            SCREEN_DIRTY = true;
        end
    )

    -- Add Position Jitter control
    params:add_control(
        "pgen_pos_jitter",
        "XY Jitter",
        ControlSpec.new(0, 1, 'lin', 0.1, 0)
    )
    params:set_action(
        "pgen_pos_jitter",
        function(x)
            PatternGenerator.jitterScale = x;
            PatternGenerator.updatePatterns()
            SCREEN_DIRTY = true;
        end
    )

    -- Swap channels
    params:add_number(
        "pgen_swap_channels",
        "Swap Channels",
        0,
        5,
        0
    )
    params:set_action(
        "pgen_swap_channels",
        function(x)
            PatternGenerator.channelDataOffset = x
            PatternGenerator.swapChannels(x)
            SCREEN_DIRTY = true
        end
    )

    -- Add Gate-Length param
    params:add_control(
        "pgen_gate_length",
        "Gate Length",
        ControlSpec.new(0.1, 0.9, 'lin', 0.1, 0.5)
    )

    -- Add Master Reset (Loop-Length) param
    params:add_option(
        "pgen_loop_length",
        "Loop Length",
        reset_names,
        3
    )
    params:set_action(
        "pgen_loop_length",
        function(x)
            PatternGenerator.loopLength = reset_counts[x]
        end
    )

    -- Add Master Offset param
    params:add_number(
        "pgen_master_offset",
        "Master Offset",
        0,
        15,
        0
    )
    params:set_action(
        "pgen_master_offset",
        function(x)
            PatternGenerator.masterOffset = x
            PatternGenerator.updateMasterOffset(PatternGenerator.masterOffset)
            SCREEN_DIRTY = true
        end
    )

    -- Add Clock Swing param
    params:add_control(
        "pgen_clock_swing",
        "Clock Swing",
        controlspec.new(0, 100, 'lin', 1, 0, '%')
    )

    -- Rebuild params table
    _menu.rebuild_params()

end -- End PatternGenerator.addParams()

--------------------------------------------------
-- Add Config Params -----------------------------
--------------------------------------------------

function PatternGenerator.addConfigParams()

    print("Adding Bline config parameters")

    -- Add param group
    params:add_group("Bline Configuration", 6)

	params:add_separator("UI Options")

    params:add_option(
        "config_k3_assign",
        "K3 Function",
        bline_utils.getKeyVals(k3_functions, "label"),
        1
    )
    params:set_action(
        "config_k3_assign",
        function(x)
            PatternGenerator.k3Assign = x
        end
    )

	params:add_separator("Mapping Utilities")

	-- Clear MIDI device mapping
	params:add {
		type = "binary",
		name = "Clear MIDI Map",
		id = "config_clear_pmap",
		behavior='trigger',
		action = function()
			os.execute("rm -f /home/we/dust/data/bline/bline.pmap")
			os.execute("touch /home/we/dust/data/bline/bline.pmap")
			params:set("config_message","> please reload script!")
			params:show("config_message")
			_menu.rebuild_params()
		end
	}

	params:add {
		type = "binary",
		name = "Restore MIDI Map",
		id = "config_restore_pmap",
		behavior='trigger',
		action = function()
			os.execute("rm -f /home/we/dust/data/bline/bline.pmap")
			PatternGenerator.copyPMAP()
			params:set("config_message","> please reload script!")
			params:show("config_message")
			_menu.rebuild_params()
		end
	}

	params:add_text("config_message", "")

	params:hide("config_message")

    -- Rebuild params table
    _menu.rebuild_params()

end -- End PatternGenerator.addParams()

--------------------------------------------------
-- Update Step-Counters --------------------------
--------------------------------------------------

function PatternGenerator.updateCounters()

    -- Update bar-counter (counts 16 steps)
    -- Bar-counter always counts 1-16 over 1 bar, irrespective of step-counter wrap/offset etc.
    PatternGenerator.barCounter = NornsUtils.wrap(PatternGenerator.barCounter + 1, 1, 16)

    -- Update patterns on last step of loop
    -- (allows for position jitter to be recalculated every loop)
    -- Only update patterns if master jitter scale > 0
    if (PatternGenerator.jitterScale > 0) then
        if (PatternGenerator.barCounter == 16) then
            -- Update jitter values, send to channels
            PatternGenerator.updateJitterVals()
            -- Update patterns
            PatternGenerator.updatePatterns()
        elseif (PatternGenerator.barCounter == NornsUtils.clamp(PatternGenerator.loopLength, 1, 16)) then
            PatternGenerator.updateJitterVals()
            PatternGenerator.updatePatterns()
        end
    end

    -- Upate master counter, resetting
    PatternGenerator.masterStepCounter = NornsUtils.wrap(
        PatternGenerator.masterStepCounter + 1,
        1,
        PatternGenerator.loopLength
    )
    --print(PatternGenerator.masterStepCounter)

end -- End Pattern_Generator:update_counters()

--------------------------------------------------
-- Swap Channel Indices --------------------------
--------------------------------------------------

-- Send signal to channels to rotate node channel indices
function PatternGenerator.swapChannels()

    -- Update all channel indices
    for _, c in pairs(PatternGenerator.channels) do
        c:updateChannelIndex(PatternGenerator.channelDataOffset)
    end

end -- End PatternGenerator.swapChannels

--------------------------------------------------
-- Update Channel Master Offset ------------------
--------------------------------------------------

function PatternGenerator.updateMasterOffset(offset)

    -- Update all channel master offset values
    for _, c in pairs(PatternGenerator.channels) do
        c:updateMasterOffset(offset)
    end

end

--------------------------------------------------
-- Update Channel Patterns -----------------------
--------------------------------------------------

-- Send signal to channels to update their patterns
function PatternGenerator.updatePatterns()

    --print("updating patterns")

    -- Update all channel patterns
    for _, c in pairs(PatternGenerator.channels) do
        c:calculatePattern(PatternGenerator.jitterVals)
    end

end -- End PatternGenerator.updatePatterns()

--------------------------------------------------
-- Position Jitter -------------------------------
--------------------------------------------------

function PatternGenerator.updateJitterVals()

    local j_amt = PatternGenerator.jitterScale--^1.5
    local vals = {}

    for i = 1, 16, 1 do
        vals[i] = {
            x = ((math.random() * 5) - 2.5) * j_amt,
            y = ((math.random() * 5) - 2.5) * j_amt
        }
    end

    PatternGenerator.jitterVals = vals

    -- Send updated vals to channels
    for _, c in pairs(PatternGenerator.channels) do
        c:updateJitterVals(PatternGenerator.jitterVals)
    end

end -- End PatternGenerator.updateJitterXY()


--------------------------------------------------
-- Get All Patterns ------------------------------
--------------------------------------------------

-- Get pattern data all channels for UI
function PatternGenerator.getChannelStates()

    -- Collate pattern data from channels
    PatternGenerator.patterns = {
        notes = PatternGenerator.channels["notes"]:getState(),
        octaves = PatternGenerator.channels["octaves"]:getState(),
        accents = PatternGenerator.channels["accents"]:getState(),
        slides = PatternGenerator.channels["slides"]:getState(),
        rests = PatternGenerator.channels["rests"]:getState()
    }
    -- Return pattern state table
    return PatternGenerator.patterns

end -- End PatternGenerator.getPatternState()

--------------------------------------------------
-- Get Current Step State ------------------------
--------------------------------------------------

function PatternGenerator.getStepState()

    return PatternGenerator.currentStepState

end -- End atternGenerator:getStepState()

--------------------------------------------------
-- Create Note Current Step ----------------------
--------------------------------------------------

-- "tick" pattern channels and collate step values into current_note table
function PatternGenerator.calculateStepNote()

    -- Get quantised note index and Quantiser state for current step
    local final_note, quantiser_state = quantiser.applyScale(
        PatternGenerator.channels["notes"]:tick(PatternGenerator.masterStepCounter),
        PatternGenerator.channels["octaves"]:tick(PatternGenerator.masterStepCounter)
    )

    -- Update note-data
    PatternGenerator.currentStepState = {
        note = final_note,
        accent = PatternGenerator.channels["accents"]:tick(PatternGenerator.masterStepCounter),
        slide = PatternGenerator.channels["slides"]:tick(PatternGenerator.masterStepCounter),
        rest = PatternGenerator.channels["rests"]:tick(PatternGenerator.masterStepCounter),
        scale_name = quantiser_state["scale_name"],
        last_note_name = quantiser_state["last_note_name"],
        last_note_index = quantiser_state["last_note_index"],
        last_octave_index = quantiser_state["last_octave_index"],
        last_octave_indicator = quantiser_state["last_octave_indicator"]
    }

end -- End PatternGenerator.calculateStepNote()

--------------------------------------------------
-- Step Function / Note-On -----------------------
--------------------------------------------------

function PatternGenerator.doStep(step_length)

    -- Get current note data
    PatternGenerator.calculateStepNote()

    -- Send note-on to output module
    output.playNote(
        PatternGenerator.currentStepState["note"],
        PatternGenerator.currentStepState["accent"],
        PatternGenerator.currentStepState["slide"],
        PatternGenerator.currentStepState["rest"],
        step_length
    )

    -- Update master step-counter
    PatternGenerator.updateCounters()

end -- End atternGenerator.doStep()

--------------------------------------------------
-- Sequencer Tick --------------------------------
--------------------------------------------------

function PatternGenerator.tick()

    -- Unswung step-length (8th note)
    -- Plays odd-numbered steps, 1, 3, 5 etc.
    local step_length = clock.get_beat_sec() / 4

    -- Scaled swing amount 0-0.5
    local swing_amt = params:get("pgen_clock_swing") / 200

    -- Length of 1st step
    -- Also sleep period for 2nd step scheduler
    local len1 = step_length * (1 + swing_amt)

    -- Length of 2nd (swung) step
    local len2 = step_length * (1 - swing_amt)

    -- Do step note
    -- Send 1st step length as arg
    PatternGenerator.doStep(len1)

    -- Force screen-redraw every step
    -- (required to update pattern playhead position display in UI)
    SCREEN_DIRTY = true

    -- Schedule swung step
    -- Plays even-numbered steps, 2, 4, 6 etc.
    clock.run(
        function()
            -- I don't know if it's good practice to exploit this
            -- but callback seems able to access locals declared above
            clock.sleep(len1)
            -- Do step, sending 2nd (swung) step length as arg
            PatternGenerator.doStep(len2)
            -- Force UI update on 2nd step, too
            SCREEN_DIRTY = true
        end
    )

end -- End PatternGenerator.doStep()

--------------------------------------------------
-- Reset Master Counter --------------------------
--------------------------------------------------

function PatternGenerator.resetCounters()

    PatternGenerator.barCounter = 1
    PatternGenerator.masterStepCounter = 1

end -- End PatternGenerator.resetCounters()

--------------------------------------------------
-- Send All-Notes Off ----------------------------
--------------------------------------------------

function PatternGenerator.allNotesOff()

    -- Send all-notes-off to output device
    output.allNotesOff()

end -- End PatternGenerator.allNotesOff()

function PatternGenerator.handleK3Button(direction)

    -- Check key up/down
    if (direction == 1) then
        k3_functions[PatternGenerator.k3Assign]:keydown()
    elseif (direction == 2) then
        k3_functions[PatternGenerator.k3Assign]:keyup()
    end -- End key up/down check

end -- PatternGenerator.handleK3Button(direction)

--------------------------------------------------
-- Copy PMAP File --------------------------------
--------------------------------------------------

function PatternGenerator.copyPMAP()

    -- Copy named PMAP file to ..data/bline/bline.pmap
    if not util.file_exists("/home/we/dust/data/bline/bline.pmap") then
		os.execute("cp -f /home/we/dust/code/bline/data/controllers/Launch_Control_XL.pmap ".."/home/we/dust/data/bline/bline.pmap")
		print("Copied pmap file")
	end

end -- End PatternGenerator.copyPMAP()

--------------------------------------------------
-- Pattern-Generator Init ------------------------
--------------------------------------------------

function PatternGenerator.init(debug)

    print("Initialising Pattern-Generator module")

    if (debug) then
        PatternGenerator.debugMode = true
        print("Setting debug mode ON")
    end -- End set debug

    -- Add Pattern-Generator params
    PatternGenerator.addParams()

    -- Instantiate and initialise channels -------

    PatternGenerator.channels["notes"] = channel:new(nil)
    PatternGenerator.channels["notes"]:init(
        1, -- Pattern node channel
        "Note", -- Channel name/id
        nil, -- Param 1 name/label
        1.0, -- Param 1 response curve
        "num", -- Channel type
        1.0, -- Forced value for first step in bar
        11, -- Output scale
        1, -- Output offset
        false -- Debug mode true/false
    )

    PatternGenerator.channels["octaves"] = channel:new(nil)
    PatternGenerator.channels["octaves"]:init(
        2,
        "Octave",
        nil,
        1.0,
        "num",
        1.0,
        3,
        1,
        false
    )

    PatternGenerator.channels["accents"] = channel:new(nil)
    PatternGenerator.channels["accents"]:init(
        3,
        "Accent",
        "Density",
        1.5,
        "bool",
        true,
        1,
        0,
        false
    )

    PatternGenerator.channels["slides"] = channel:new(nil)
    PatternGenerator.channels["slides"]:init(
        4,
        "Slide",
        "Density",
        1.5,
        "bool",
        false,
        1,
        0,
        false
    )

    PatternGenerator.channels["rests"] = channel:new(nil)
    PatternGenerator.channels["rests"]:init(
        5,
        "Rest",
        "Density",
        1.5,
        "bool",
        false,
        1,
        0,
        false
    )

    -- Create Jitter values ----------------------

    PatternGenerator.updateJitterVals()

    -- Update patterns ---------------------------

    PatternGenerator.updatePatterns()

    -- Initialise Quantiser module ---------------

    quantiser.init(false)

    -- Initialise Output module ------------------

    output.init(false)

	-- Initialise SoftCut delay -----------------

	delay.init()

	-- Add Config params -------------------------

    PatternGenerator.addConfigParams()

    -- Copy PMAP file
	PatternGenerator.copyPMAP()


end -- End PatternGenerator.init()

-----------------------------------------
-- Return Module Table ------------------
-----------------------------------------

return PatternGenerator
