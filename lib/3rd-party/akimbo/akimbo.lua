-- Based on
-- https://github.com/dansimco/akimbo

-- Akimbo.
-- a synced, looping delay.
--
--
-- Two delay buffers, left and right.
-- Quantised buffer length, controlled by arcs 1 and 4
-- feedback controllerd by 2 and 3
-- based on the 4ms Dual Looping Delay

local lattice = require 'lattice'
local util = require 'util'
local tabutil = require 'tabutil'
local tau = math.pi * 2

----------------------------
--
--  Setup
--
----------------------------

local buffers = {"A", "B"}
local time_length_options = {1, 1.5, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16}
local time_scale_options = {"1/8", "1", "+16"}

local akimbo = {}

function Akimbo.init()

	add_params()

    setup_softcut()
    setup_clocks()

    apply_pattern_division(1)
    apply_pattern_division(2)

end -- End Akimbo.init()

-- Add Params

local add_params = function()

	params:add_group("Akimbo Looping Delay", 11)

	params:add_option("akimbo_reset_on_time_change", "reset on time change", {"no", "yes"}, 2)

	for i = 1, 2 do
	    --params:add_separator("Buffer " .. buffers[i])

		params:add_option("akimbo_"..i.."time", "Buffer "..buffers[i].." time (beats)", time_length_options, 7)
		params:add_action(
			"akimbo_"..i.."time",
			function(x)

			end
		)

		params:add_option("akimbo_"..i.."time_scale", "Buffer "..buffers[i].." time mod", time_scale_options, 1)


		params:add_number("akimbo_"..i.."feedback", "Buffer "..buffers[i].." feedback", 0, 100, 75)


		params:add_number("akimbo_"..i.."send_amount", "Buffer "..buffers[i].." send amount", 0, 100, 0)


	end

end -- End Aadd_params()

----------------------------
--
--  Clocks
--
----------------------------

local args = {
    auto = true,
    meter = 4, -- use params default
    ppqn = 96
}

local lattice1 = lattice:new(args)

local patterns = {
    lattice1:new_pattern{
        action = function(t) reset_loop(1) end,
        division = 1 / 2,
        enabled = true
    },
    lattice1:new_pattern{
        action = function(t) reset_loop(2) end,
        division = 1 / 2,
        enabled = true
    }
}

local setup_clocks = function()
    lattice1:start()
end

local apply_pattern_division = function(p)
    local divisor = time_length_options[params:get(p .. "time")]

    divisor = 360 / (divisor * 8)
    patterns[p].division = 1 / divisor
end

local reset_loop = function(voice)
    softcut.position(voice, 0.5)
end

----------------------------
--
--  Softcut
--
----------------------------

local setup_softcut = function()
    rate = 1.0
    rec = 1.0
    pre = 0.5

    -- send audio input to softcut input
    audio.level_adc_cut(1)
    audio.level_eng_cut(0)
    audio.level_tape_cut(0)

    softcut.enable(1, 1)
    softcut.buffer(1, 1)
    softcut.level(1, 1.0)
    softcut.loop(1, 1)
    softcut.loop_start(1, 0)
    softcut.loop_end(1, 120)
    softcut.position(1, 0)
    softcut.play(1, 1)
    softcut.pan(1, - 1)
    softcut.rec(1, 1)
    softcut.pre_level(1, pre)
    softcut.level_input_cut(1, 1, 1.0)
    softcut.rec_level(1, rec)

    softcut.enable(2, 1)
    softcut.buffer(2, 2)
    softcut.level(2, 1.0)
    softcut.loop(2, 1)
    softcut.loop_start(2, 0)
    softcut.loop_end(2, 120)
    softcut.position(2, 0)
    softcut.play(2, 1)
    softcut.pan(2, 1)
    softcut.rec(2, 1)
    softcut.pre_level(2, pre)
    softcut.level_input_cut(2, 2, 1.0)
    softcut.rec_level(2, rec)

    softcut.voice_sync(1, 2, 0)

    softcut.buffer_clear()

end

-- function update_positions(voice,position)
--   print(voice,position)
-- end

-- softcut.phase_quant(1,0.1)
-- -- softcut.phase_quant(2,0.1)
-- softcut.event_phase(update_positions)
-- softcut.poll_start_phase()

----------------------------
--
--  Norns Inputs
--
----------------------------
local directions = {1, 1}

function enc(n, d)
    if n == 2 or n == 3 then
        softcut.level_input_cut(n - 1, n - 1, util.clamp())
    end
end

function key(n, z)
    if n == 2 and z == 1 then
        directions[1] = directions[1] * - 1
        softcut.rate(1, directions[1])
    end

    if n == 3 and z == 1 then
        directions[2] = directions[2] * - 1
        softcut.rate(2, directions[2])
    end

end

----------------------------
--
--  ARC Inputs
--
----------------------------

local cursor_max = 360
local time_cursors = {180, 180} -- @todo this needs to match params

local apply_time_cursor = function(n, d)
    time_cursors[n] = util.clamp(time_cursors[n] + d / 3, 1, cursor_max)
    local time_index = math.ceil((#time_length_options / cursor_max) * time_cursors[n])
    params:set(n .. "time", time_index)
end

-- Arc delta functions

function a.delta(n, d)
    if (n == 2) then
        params:delta("1feedback", d / 11)
        softcut.pre_level(1, params:get("1feedback") / 100)
    end

    if (n == 3) then
        params:delta("2feedback", d / 11)
        softcut.pre_level(2, params:get("2feedback") / 100)
    end

    if (n == 1) then
        -- Channel 1 Time
        apply_time_cursor(1, d)
        apply_pattern_division(1)
        if params:get("reset_on_time_change") == 2 then
            reset_loop(1)
        end
    end

    if (n == 4) then
        apply_time_cursor(2, d)
        apply_pattern_division(2)
        if params:get("reset_on_time_change") == 2 then
            reset_loop(1)
        end
    end

end

return Akimbo
