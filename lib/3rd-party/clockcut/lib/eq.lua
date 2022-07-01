
----
-- an 'EQ pedal' abstraction over the softcut SVF, 
-- with friendlier parameter mappings

Eq = {}
Eq.__index = Eq

Eq.SELECT_GAIN = 2
Eq.SELECT_GAIN_INV = 1 - (1/Eq.SELECT_GAIN)

Eq.commands = {
    'dry',
    'lp',
    'hp',
    'bp',
    'br',
    'fc',
    'rq',
}

local function tilt_fade(x)
    local b = x * 0.5
    local c = x*x* -0.20554863
    local l = 0.70554862 + b + c
    local r = 0.70554862 - b + c
    return l, r
end

-- symmetric boost/cut by 12db
local function select_fade(x)
    -- TODO: needs some work...
    local l = x * Eq.SELECT_GAIN
    local r = 1 - (x * Eq.SELECT_GAIN_INV)
    return l, r
end

function Eq.new(voice, post)
    local x = setmetatable({}, Eq)
    -- parameter mapping values
    x.params = {
        -- our interface:
        tilt=0, select=0, rez=0, mix=0,
        -- tmp:
        wet=0, shelf=0,
        -- softcut API:
        dry=0, lp=0, hp=0, bp=0, br=0, fc=100, rq=1
    }
    -- softcut helpers    
    x.commands = {}
    x.voice = voice and voice or 1
    x.post = post and post or true
    x:set_voice(x.voice)
    x:set_post(x.post)
    return x
end

------------------------
--- these functions define the public API
--- all accept generic parameter ranges in [0, 1] or [-1, 1]
--- (except cutoff frequency, which is still Hz)

-- tilt:
-- affects highpass/lowpass balance.
-- at -1, all lowpass
-- at +1, all highpass
-- at zero, equal-power mix
function Eq:set_tilt(pos)
    self.params.tilt = pos
    local hp, lp = tilt_fade(pos)
    self.params.lp = lp
    self.params.hp = hp
end

-- boost or cut around the center frequency
function Eq:set_select(amt)
    local peak, shelf
    self.params.select = amt
    if amt > 0 then
        peak, shelf = select_fade(amt)
        self.params.bp = peak
        self.params.br = 0
        self.params.shelf = shelf
    else
        peak, shelf = select_fade(amt * -1)
        self.params.bp = 0
        self.params.br = peak
        self.params.shelf = shelf
    end
end

function Eq:set_rez(val)
    self.params.rez = val
    -- TODO: work out something that feels really good.
    -- this is a first attempt
    x = 1-val
    self.params.rq = 2.15821131e-01 + (x*2.29231176e-09) + (x*x*3.41072934)
end

-- set the mix amount
function Eq:set_mix(amt)    
    self.params.mix = amt
    local w, d = amt, 1-amt
    self.params.dry = d
    self.params.wet = w 
end


function Eq:set_fc(hz)    
    -- this one just passes through
    self.params.fc = hz
end

-- update softcut with the object's param state
function Eq:apply()
    --tab.print(self.params)
    local wetshelf = self.params.wet * self.params.shelf
    softcut[self.commands.dry](self.voice, self.params.dry)
    softcut[self.commands.lp](self.voice, self.params.lp * wetshelf)
    softcut[self.commands.hp](self.voice, self.params.hp * wetshelf)
    softcut[self.commands.bp](self.voice, self.params.bp * self.params.wet)
    softcut[self.commands.br](self.voice, self.params.br * self.params.wet)
    softcut[self.commands.rq](self.voice, self.params.rq)
    softcut[self.commands.fc](self.voice, self.params.fc)
end

-- set which softcut voice this EQ object controls
function Eq:set_voice(idx)
    self.voice = idx;
end

-- set whether this EQ object controls pre- or post-filter
function Eq:set_post(post)
    self.post = post;
    local prefix = post and 'post_filter_' or 'pre_filter_'
    for _,k in pairs(Eq.commands) do
        self.commands[k] = prefix..k
    end
end

return Eq