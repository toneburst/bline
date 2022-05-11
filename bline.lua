--
-- bline
-- Parametric bassline
-- sculptor
-- 1.0.0 @toneburst
-- llllllll.co/t/bline
--
-- Bassline sculptor
--
-- E1 : Change page
-- E2 : Param 1
-- E3 : Param 2
-- K2 : Play/Pause
-- K3 : Toggle param group
--

BLINE_UTILS = include("lib/modules/mod_bline_utils")

-- Include pattern generator
local pattern_generator = include('lib/modules/mod_pattern_generator')
-- include UI
local ui = include('lib/ui/mod_ui')

-- Add shonky 303 engine
engine.name = "Bline_Synth"

-- Screen and pattern dirty flags (global)
SCREEN_DIRTY = true

------------------------------------------
------------------------------------------
-- Init ----------------------------------
------------------------------------------
------------------------------------------

function init()

    -- Initialise pattern-generator ----------

    pattern_generator.init(false)

	-- Initialise UI module ------------------

	ui.init(false)

    -- Read params from disk if file present at 'data/<scriptname>/<scriptname>.pset'
    params:read()
    params:bang()

    -- Setup Clocks --------------------------

    -- Master sequencer step clock
    master_clock_id = clock.run(master_clock) -- create master sequencer clock and note the id

    -- Param auto-save clock
    autosave_clock_id = clock.run(autosave_clock) -- create a "autosave_clock" and note the id

    -- Screen-redraw clock
    screen_redraw_clock_id = clock.run(screen_redraw_clock) -- create a "redraw_clock" and note the id

end -- End init()

------------------------------------------
-- Norns Encoders ------------------------
------------------------------------------

-- enc() is automatically called by norns
function enc(n, delta)
	ui.handleEncoders(n, delta)
	-- Force screen redraw
    SCREEN_DIRTY = true
end -- End enc(n, delta)

------------------------------------------
-- Norns Buttons -------------------------
------------------------------------------

-- key() is automatically called by norns
function key(k, z)
	-- Do nothing when you release a key
    if z == 0 then return end
    ui.handleButtons(k)
	-- Force screen redraw
    SCREEN_DIRTY = true
end -- End key(k, z)

------------------------------------------
-- Configure Clocks ----------------------
------------------------------------------

-- Master Step clock
function master_clock()
    clock.sleep(5)
	-- Infinite loop
    while true do
        -- Sync clock to 1/16 note
		-- Change to 8th note, and implement swing multiplier
        clock.sync(1 / 2)
        -- Execute pattern step
        pattern_generator.tick()
    end
end -- End master_clock()

-- Screen-Redraw clock
function screen_redraw_clock()
    clock.sleep(5)
    while true do
		-- pause for a thirtieth of a second (aka 30fps)
        clock.sleep(1 / 30)
		-- Only redraw if SCREEN_DIRTY has been set true
        if SCREEN_DIRTY then
            -- Call redraw() function
			-- Function must be called "redraw()" in order for Norns to disable redraw while System menus active!!
            redraw()
            -- Reset dirty flag
            SCREEN_DIRTY = false
        end
    end
end -- End screen_redraw_clock()

-- Auto-Save clock
function autosave_clock()
    clock.sleep(10)
    while true do
        clock.sleep(10)
        -- Auto-save params to disk at data/bline/bline-01.pset' every 10 seconds
        params:write()
    end
end -- End autosave_clock()

------------------------------------------
-- Redraw Function -----------------------
------------------------------------------

-- redraw() is automatically called by norns
function redraw()
	-- Update UI, passing pattern, channel and last-note data
	ui.redraw(
		pattern_generator.getChannelStates(),
		pattern_generator.getStepState()
	)
end -- End redraw()

------------------------------------------
-- Script-Reload Function ----------------
------------------------------------------

-- Execute reload() in the repl to quickly rerun this script
function reload()
    cleanup()
	-- https://github.com/monome/norns/blob/main/lua/core/state.lua
    norns.script.load(norns.state.script)
end -- End reload()

------------------------------------------
-- Script-Close Cleanup ------------------
------------------------------------------

-- Cleanup() is automatically called on script close
function cleanup()
	-- Cancel clocks
	clock.cancel(master_clock_id) -- Destoy master clock  via the id we noted
    clock.cancel(screen_redraw_clock_id) -- Destroy redraw clock via the id we noted
    clock.cancel(autosave_clock_id) -- Destroy autosave clock via the id we noted
	-- Silence output devices
	pattern_generator.allNotesOff()
	-- Save params
	params:write()
end -- End cleanup()
