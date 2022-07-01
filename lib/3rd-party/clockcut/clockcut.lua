-- clockcut
--
-- Simple clocked looper
--
-- No UI (designed for MIDI mapping)
--
-- Based on
-- https://github.com/catfact/clockcut

local Clockcut = {}

local Sequins = require 'sequins'
local Taper = include 'lib/3rd-party/clockcut/lib/taper'
local Eq = include 'lib/3rd-party/clockcut/lib/eq'
local ControlSpec = require 'controlspec'

------------------------------------------------
---- state

-- start point in the buffer, in seconds
-- TODO: try scrubbing this around!
start_position = 1
-- ^NB: this is 1 second, nothing to do with base-1
-- that is in case negative rates are added, necessitating pre-roll

-- a sequence of clock duration multipliers
-- (scaled by our master multiplier parameter)
-- TODO: make this non-trivial!
local sequence = {1}

local speed_base_ratio=1
local speed_tune_ratio=1

-------------------------------------------------
--- helpers

--- multiplier param display
local muls = {
    {1/4, "1/4"},
    {1/3, "1/3"},
    {2/5, "2/5"},
    {1/2, "1/2"},
    {2/3, "2/3"},
    {3/4, "3/4"},
    {1, "1"},
    {4/3, "4/3"},
    {3/2, "3/2"},
    {2, "2"},
    {2.5, "5/2"},
    {3, "3"},
    {4, "4"},
}

local mul_str = {}
for i = 1, #muls do
    table.insert(mul_str, muls[i][2])
end

--- our clock routine
local clock_loop = function()
    local seq = Sequins(sequence)
    while(true) do
        -- we'll simply tell softcut to jump back to the start on each tick
        softcut.position(1, start_position)
        clock.sync(clock_mul * seq())
    end
end

-- This is used for displaying parameter in the UI.
-- I've removed the UI stuff, so this is no longer needed, but will leave and comment, in case I need to add UI later
--local param_str = {}

--------------------------
-- norns API overwrites

function Clockcut.init()

	params:add_group("Clockcut Delay", 11)

    -- clock multiplier param
    params:add({type='option', id='clock_mul', name='Clock Multiplier',
        options=mul_str, default=7, action=function(index)
        clock_mul = muls[index][1]
        str = muls[index][2]
        --param_str['clock_mul'] = 'mul: '..str
    end})

    -- speed ratio param
    params:add({type='option',id='speed_ratio', name='Speed Ratio',
        options=mul_str, default=7, action=function(index)
        local str = muls[index][2]
        speed_base_ratio =  muls[index][1]
        softcut.rate(1, speed_base_ratio * speed_tune_ratio)
        --param_str['speed_ratio'] = 'ratio: '..str
    end})

    -- speed tuning param
    params:add({type="number", id='speed_tune', name='Speed Tune',
        min=-200, max=200, default=0, action=function(cents)
        speed_base_tune = 2 ^ (cents/1200)
        softcut.rate(1, speed_base_ratio * speed_base_tune)
        --param_str['speed_tune'] = 'tune: '..cents
    end})

    params:add({type='option', id='rec_level', name='Rec Level',
        options=Taper.db_128, default=defaultIndex, action=function(index)
            local amp = Taper.amp_128[index]
            local db = Taper.db_128[index]
            softcut.rec_level(1, amp)
            ----param_str.rec_level = 'rec: '..db
        end
    })

    params:add({type='option', id='pre_level', name='Pre Level',
        options=Taper.db_128, default=defaultIndex, action=function(index)
            local amp = Taper.amp_128[index]
            local db = Taper.db_128[index]
            softcut.pre_level(1, amp)
            --param_str.pre_level = 'pre: '..db
        end
    })

    -- fade time parameter
    params:add({type='number', id='fade_ms', name='Fade Time',
        min=0, max=1000, default=50,  action = function(ms)
        softcut.fade_time(1, ms * 0.001)
        --param_str['fade_ms'] = 'fade_ms: '..ms .. 'ms'
    end})

    -- TODO: more params! if you want

    -- the EQ class is a helper abstraction over the softcut SVF
    eq = Eq.new(1)
    params:add({id='eq_mix', name='EQ Mix', type='control', min=0, max=1, default=1, action=function(x)
        eq:set_mix(x); eq:apply()
        --param_str['eq_mix'] = 'mix: '..x
    end})

    params:add({id='eq_fc', name='EQ FC', type='control',
        controlspec=ControlSpec.new(20, 16000, 'exp', 0, 1200, "hz"), action=function(x)
        eq:set_fc(x); eq:apply()
        --param_str['eq_fc'] = 'fc: '..x
    end, })

    params:add({id='eq_tilt', name='EQ Tilt', type='control',
        controlspec=ControlSpec.new(-1, 1, 'lin', 0, 0, ""), action=function(x)
        eq:set_tilt(x); eq:apply()
        --param_str['eq_tilt'] = 'tilt: '..x
    end})

    params:add({id='eq_select', name='EQ Select', type='control',
        controlspec=ControlSpec.new(-1, 1, 'lin', 0, 0, ""), action=function(x)
        eq:set_select(x); eq:apply()
        --param_str['eq_select'] = 'select: '..x
    end})

    params:add({id='eq_rez', name='EQ Resonance', type='control',
        controlspec=ControlSpec.new(0, 1, 'lin', 0, 0, ""), action=function(x)
        eq:set_rez(x); eq:apply()
        --param_str['eq_rez'] = 'rez: '..x
    end})

    -- other non-default softcut settings
	audio.level_cut(1)
	audio.level_adc_cut(1)
	audio.level_eng_cut(1)

    softcut.level(1,1.0)
	softcut.level_input_cut(1, 1, 1.0)
	softcut.level_input_cut(2, 1, 1.0)
	softcut.pan(1, 0.0)

	softcut.filter_dry(1, 1)
	softcut.filter_lp(1, 0)
	softcut.filter_hp(1, 0)
	softcut.filter_bp(1, 0)
	softcut.filter_br(1, 0)

    softcut.enable(1, 1)
    softcut.play(1, 1)
    softcut.rec(1, 1)

	softcut.loop_start(1, 0)
	softcut.loop_end(1, softcut.BUFFER_SIZE)
	softcut.loop(1, 0)

    -- load params
    params:default()

    -- start the sequencer
    clock.run(clock_loop)
end

return Clockcut
