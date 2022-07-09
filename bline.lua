--
-- bline
-- Parametric Acid
-- Bassline Sculptor
--
-- 1.0.0 @toneburst
--
-- E1 : Change parameter page
-- E2 : Param 1
-- E3 : Param 2
-- K2 : Toggle param group
-- K3 : Assignable
--
-- Not all parameters exposed
-- in the UI. Mapping Params
-- to MIDI controller
-- recommended!
--
--

BLINE_UTILS = include("lib/modules/mod_bline_utils")

-- Require Audio module
local audio = require "audio"

-- Include pattern generator
local pattern_generator = include('lib/modules/mod_pattern_generator')

-- include UI
local ui = include('lib/ui/mod_ui')

-- Add shonky 303 engine
engine.name = "Bline_Synth"

------------------------------------------
-- GLOBAL VARS ---------------------------
------------------------------------------

-- Sequencer running flag
RUNNING = true

-- Sequencer eset flag
RESET = false

-- Screen and pattern dirty flags (global)
SCREEN_DIRTY = true

-- Version
VERSION = "1.0.0"

------------------------------------------
-- Init ----------------------------------
------------------------------------------

function init()

    -- Initialise pattern-generator ----------

    pattern_generator.init(false)

	-- Disable pitch-analysis (save CPU) -----

	audio.pitch_off()

    -- Initialise UI module ------------------

    ui.init(false)

    -- Read params from disk if file present at 'data/<scriptname>/<scriptname>.pset'
    params:read()
    params:bang()

    -- Setup Clocks --------------------------

    -- Master sequencer step clock
    sequencer_clock_id = clock.run(sequencer_clock) -- create master sequencer clock and note the id

    -- Param auto-save clock
    autosave_clock_id = clock.run(autosave_clock) -- create a "autosave_clock" and note the id

    -- Screen-redraw clock
    screen_redraw_clock_id = clock.run(screen_redraw_clock) -- create a "redraw_clock" and note the id

end -- End init()

------------------------------------------
-- Norns Encoders ------------------------
------------------------------------------

function enc(n, delta)
	-- Pass encoder changes to UI module
	ui.handleEncoders(n, delta)
	-- Set flag to update UI display
	SCREEN_DIRTY = true
end

------------------------------------------
-- Norns Buttons -------------------------
------------------------------------------

function key(k, z)
	-- Ignore key-up
	if (z == 0) then
		-- We will pass on Key 3 key-up to the pgen rather than the UI module
		if (k == 3) then
			-- 2 for direction argument = key-up
			pattern_generator.handleK3Button(2)
		end
		-- Need to return here or we get a key-down event firing after every key-up (dunno why...)
		return
	end
	-- Process key-down (ignore Key 1)
	if (k == 2) then
		-- Key 2 key-down. Pass on to UI module
		ui.handleButtons(k)
	elseif (k == 3) then
		-- Pass on Key 3 key-down to pgen module
		-- 1 for direction argument = key-down
		pattern_generator.handleK3Button(1)
		return
	end
	-- Set flag to update UI display
	SCREEN_DIRTY = true
end

------------------------------------------
-- Configure Clocks ----------------------
------------------------------------------

-- Master Step clock ---------------------

function sequencer_clock()
	-- Sleep while loading animation plays
	clock.sleep(5)
	-- Start sequencer loop
    while true do
        -- Sync clock to 1/8th note
        clock.sync(1 / 2)
		-- Send reset signal to pattern-generator if 'RESET' flag set
		if (RESET == true) then
			pattern_generator.resetCounters()
			-- RESET 'RESET' flag (ha!)
			RESET = false
		end
        -- Check 'RUNNING' flag
		if (RUNNING == false) then
			-- Send reset signal to pattern-generator if 'RUNNING' flag set false
        	-- pattern_generator.resetCounters()
			pattern_generator.allNotesOff()
		else
			-- Else send signal to pattern-generator to execute step
			pattern_generator.tick()
		end
    end
end

-- Screen-Redraw clock -------------------

function screen_redraw_clock()
    while true do
		-- Pause for a thirtieth of a second (aka 30fps)
        clock.sleep(1 / 30)
        if SCREEN_DIRTY then ---- only if something changed
            -- Call redraw() function
            -- Function must be called "redraw()" in order for Norns to disable redraw while System menus active!!
            redraw()
            -- RESET dirty flag
            SCREEN_DIRTY = false
        end
    end
end

-- Auto-Save clock -----------------------

function autosave_clock()
    clock.sleep(10)
    while true do
        clock.sleep(10)
        -- Auto-save params to disk at
        --'data/bline/bline-01.pset' every 10 seconds
        params:write()
    end
end

------------------------------------------
-- Transport Functions -------------------
------------------------------------------

-- Transport-start callback
function clock.transport.start()
	print("clock.transport.start received")
	RUNNING = true
end

-- Transport-stop callback
function clock.transport.stop()
	print("clock.transport.stop received")
	pattern_generator.resetCounters()
    RUNNING = false
end

-- Transport-reset callback
function clock.transport.reset()
	print("clock.transport.reset received")
    RESET = true
end

------------------------------------------
-- Redraw Function -----------------------
------------------------------------------

function redraw()
    -- Update UI, passing pattern, channel and last-note data
    ui.redraw(
        pattern_generator.getChannelStates(),
        pattern_generator.getStepState()
    )
end -- End redraw()

------------------------------------------
-- Script-Reload Functions ---------------
------------------------------------------

function r()
    cleanup()
	-- https://github.com/monome/norns/blob/main/lua/core/state.lua
    norns.script.load(norns.state.script)
end

------------------------------------------
-- Script Close Cleanup ------------------
------------------------------------------

function cleanup()
    -- Cancel clocks
    clock.cancel(sequencer_clock_id) -- Destoy master clock  via the id we noted
    clock.cancel(screen_redraw_clock_id)
    clock.cancel(autosave_clock_id)
    -- Silence output devices
    pattern_generator.allNotesOff()
    -- Save params
    params:write()
end
