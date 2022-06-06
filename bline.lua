--
-- bLine
-- Parametric Acid
-- Bassline Sculptor
--
-- 1.0.0 @toneburst
--
-- E1 : Change page
-- E2 : Param 1
-- E3 : Param 2
-- K2 : Toggle param group
-- K3 : Unassigned
--
-- Not all parameters exposed
-- in the UI. Mapping Params
-- to MIDI controller
-- recommended!
--
--
--                      H
--                      |
--                H  H  C--H
--                 `.|,'|
--                   C  H  H
--                   |     |
--              O    N  H  C
--              \\ ,' `.|,'|`.
--                C     C  H  H
--                |     |
--             H--C     H
--              ,' `.
--       H  H--C  H--C--H
--       |     ||    |
-- H     C     C     N  H  H
--  `. ,' `. ,' `. ,' `.|,'
--    C  _  C  H  C     C
--    | (_) |   `.|     |
--    C     C     C     H
--  ,' `. ,' `. ,' `.
-- H     C     C     H
--       |    ||
--       N-----C
--       |     |
--       H     H
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

-- Sequencer running flag
running = true

-- Sequencer eset flag
reset = false

-- Screen and pattern dirty flags (global)
SCREEN_DIRTY = true

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

-------------------------------------------
-- Norns Buttons -------------------------
------------------------------------------

function key(k, z)
	-- Ignore key-up
	if (z == 0) then
		return
	end
	-- Process key-down (ignore Key 1)
	if (k == 2) then
		-- Key 2 key-down. Pass on to UI module
		ui.handleButtons(k)
	elseif (k == 3) then
		-- We will deal with Key 3 here, rather than passing to the UI module
		-- Toggle transport on/off (this is a neat one-liner for toggling a boolean!)
		--running = (not running)
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
		-- Send reset signal to pattern-generator if 'reset' flag set
		if (reset == true) then
			pattern_generator.resetCounters()
			-- Reset 'reset' flag (ha!)
			reset = false
		end
        -- Check 'running' flag
		if (running == false) then
			-- Send reset signal to pattern-generator if 'running' flag set false
        	pattern_generator.resetCounters()
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
            -- Reset dirty flag
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
-- Transport functions -------------------
------------------------------------------

function clock_start()
	running = true
end

function clock_stop()
	running = false
end

function clock_reset()
	reset = true
end

-- Transport-start callback
function clock.transport.start()
	print("clock.transport.start received")
	clock_start()
end

-- Transport-stop callback
function clock.transport.stop()
	print("clock.transport.stop received")
    clock_stop()
end

-- Transport-reset callback
function clock.transport.reset()
	print("clock.transport.reset received")
    clock_reset()
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
    clock.cancel(screen_redraw_clock_id) -- Destroy redraw clock via the id we noted
    clock.cancel(autosave_clock_id) -- Destroy autosave clock via the id we noted
    -- Silence output devices
    pattern_generator.allNotesOff()
    -- Save params
    params:write()
end
