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

local Lattice = require 'lattice'
local Util = require 'util'
local ControlSpec = require "controlspec"

------------------------------------------
-- Setup ---------------------------------
------------------------------------------

local time_length_options = {1, 1.5, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16}
local delay_times = {4, 6}
local directions = {1, 1}

local Delay = {}

------------------------------------------
-- Lattice Setup -------------------------
------------------------------------------

-- Create lattice
local Lattice1 = Lattice:new({
    auto = true,
    meter = 4, -- use params default
    ppqn = 96
})

-- Create lattice patterns
local patterns = {
	-- Left pattern
    Lattice1:new_pattern{
        division = 1 / 2,
        action = function(t)
			Delay.reset_loop(1)
		end,
        enabled = true
    },
	-- Right pattern
    Lattice1:new_pattern{
		division = 1 / 3,
        action = function(t)
			Delay.reset_loop(2)
		end,
        enabled = true
    }
}

------------------------------------------
-- Rest Loop -----------------------------
------------------------------------------

function Delay.reset_loop(v)
	softcut.position(v, 0.5)
end

------------------------------------------
-- Setup Clocks --------------------------
------------------------------------------

function Delay.setup_clocks()
    Lattice1:start()
end

------------------------------------------
-- Change Voice Direction ----------------
------------------------------------------

-- function Delay.toggle_direction(v)
--
-- 	local direction = params:get("delay_" .. v .. "_direction")
--
-- 	-- Reset voice loop before changing pattern length
-- 	Delay.reset_loop(v)
--
-- 	if (direction == 0) then
-- 		directions[v] = 1
-- 	else
-- 		directions[v] = -1
-- 	end
--
-- 	softcut.rate(v, directions[v])
--
--
-- end -- End change_direction(v)

------------------------------------------
-- Change Pattern Division ---------------
------------------------------------------

function Delay.apply_pattern_division()

	softcut.buffer_clear()

	for i = 1, 2 do
	    local divisor = delay_times[i]
	    divisor = 360 / (divisor * 8)
	    patterns[i].division = 1 / divisor
	end
end

------------------------------------------
-- Setup Softcut -------------------------
------------------------------------------

function Delay.setup_softcut()
    local rate = 1.0
    local rec = 1.0
    local pre = 0.5
	local cutoff = 50

    -- Send audio input and engine to softcut input
    audio.level_adc_cut(1)
    audio.level_eng_cut(1)
    audio.level_tape_cut(0)

	-- Loop through creating buffers
	for i = 1, 2 do
		softcut.enable(i, 1)
	    softcut.buffer(i, i)
	    softcut.level(i, 1.0)
	    softcut.loop(i, 1)
	    softcut.loop_start(i, 0)
	    softcut.loop_end(i, 120)
	    softcut.position(i, 0)
	    softcut.play(i, 1)
	    softcut.rec(i, 1)
	    softcut.pre_level(i, 0)
	    softcut.level_input_cut(i, 1, 1.0)
	    softcut.rec_level(i, rec)
		softcut.fade_time(i, 0.05)
		-- set voice dry level to 0.0
		softcut.pre_filter_dry(i, 0.0)
		-- set voice band pass level to 1.0 (full wet)
		softcut.pre_filter_hp(i, 1.0)
		softcut.pre_filter_lp(i, 0)
		softcut.pre_filter_bp(i, 0)
		softcut.pre_filter_br(i, 0)
		-- set voice filter cutoff
		softcut.pre_filter_fc(i, cutoff)
	end

	-- Set voice-specific params
	softcut.pan(1, -1)
	softcut.pan(2, 1)

	softcut.level_cut_cut(1, 2, pre)
	softcut.level_cut_cut(2, 1, pre)

    softcut.voice_sync(1, 2, 0)

    softcut.buffer_clear()

end -- End setup_softcut = function()

------------------------------------------
-- Add Params ----------------------------
------------------------------------------

function Delay.add_params()

	params:add_group("Bline FX", 4)

	params:add_control(
		"delay_level_adc",
		"Delay Level ADC",
		ControlSpec.new(0, 1, 'lin', 0.01, 1.0)
	)

	params:set_action(
		"delay_level_adc",
		function(x)
			audio.level_adc_cut(x)
		end
	)

	params:add_control(
		"delay_level_eng",
		"Delay Level Engine",
		ControlSpec.new(0, 1, 'lin', 0.01, 1.0)
	)

	params:set_action(
		"delay_level_eng",
		function(x)
			audio.level_eng_cut(x)
		end
	)

	params:add_option(
		"delay_time",
		"Delay Time",
		time_length_options,
		5
	)

	params:set_action(
		"delay_time",
		function(x)
			delay_times[1] = time_length_options[params:get("delay_time")]
			delay_times[2] = 1.5 * delay_times[1]
			Delay.apply_pattern_division()
		end
	)

	params:add_control(
		"delay_feedback",
		"Delay Feedback",
		ControlSpec.new(0, 0.8, 'lin', 0.01, 0.25)
	)

	params:set_action(
		"delay_feedback",
		function(x)
			softcut.level_cut_cut(1, 2, x)
			softcut.level_cut_cut(2, 1, x)
		end
	)

	-- params:add_binary(
	-- 	"delay_1_direction",
	-- 	"Delay Left Reverse",
	-- 	"toggle"
	-- )
	--
    -- params:set_action(
	-- 	"delay_1_direction",
	-- 	function(x)
	-- 		Delay.toggle_direction(1)
	-- 	end
	-- )
	--
	-- params:add_binary(
	-- 	"delay_2_direction",
	-- 	"Delay Right Reverse",
	-- 	"toggle"
	-- )
	--
    -- params:set_action(
	-- 	"delay_2_direction",
	-- 	function(x)
	-- 		Delay.toggle_direction(2)
	-- 	end
	-- )

end -- End Delay.Delay.apply_pattern_division()

------------------------------------------
-- Init ----------------------------------
------------------------------------------

function Delay.init()

	Delay.add_params()

    Delay.setup_softcut()
    Delay.setup_clocks()

    Delay.apply_pattern_division()

end -- End Delay.init()

return Delay
