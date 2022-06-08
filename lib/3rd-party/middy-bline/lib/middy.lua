-- A small library to do extend midi mapping functionality
-- This is a simplified version of @infinitedigits original "Middly" add-on
-- https://norns.community/authors/infinitedigits/middy
-- I've removed the MIDI recording functionality and changed the paths for mapping files

local json = include("lib/3rd-party/middy-bline/lib/json")

Middy = {
    is_initialized = false,
    file_loaded = false,
    path_maps = _path.code.."bline/lib/3rd-party/middy-bline/maps/",
    path_midi = _path.code.."bline/lib/3rd-party/middy-bline/midi/",
}

local m = nil

function Middy:init(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    if o.filename ~= nil then
        self:init_map(o.filename)
    end

	self:add_params()

    return o
end -- End Middy:init(o)

function Middy:add_params()
	params:add_group("CONTROLLER MAPPING", 4)
	params:add_control("middy_device", "midi device", controlspec.new(1, 4, 'lin', 1, 1, '', 1 / 4))
	params:add_text('middy_message', ">", "need to initialize.")
	params:add {
		type = 'binary',
		name = 'Initialize MIDI',
		id = 'middy_init',
		behavior = 'trigger',
		action = function(v)
			self:init_midi()
		end
	}
	params:add_file("middy_load_mapping", "Load MIDI Mapping", self.path_maps)
	params:set_action(
		"middy_load_mapping",
		function(x)
			print(x)
			if x == self.path_maps or not self.is_initialized then
				do return end
			end
			self:init_map(x)
			params:set("middy_message", "loaded map.")
			print("loaded map.")
		end
	)
end  -- End Middy:add_params()

function Middy:init_midi()
    self.is_initialized = true
    print("connecting to midi device "..params:get("middy_device"))
    m = midi.connect(params:get("middy_device"))
    m.event = function(data)
        self:process(data)
    end
    params:set("middy_message", "initialized.")
    if params:get("middy_load_mapping") ~= self.path_maps then
        self:init_map(params:get("middy_load_mapping"))
        params:set("middy_message", "loaded map.")
    end
end  -- End Middy:init_midi()

function Middy:init_map(filename)
    -- load file
    self.filename = filename
    local f = assert(io.open(self.filename, "rb"))
    local content = f:read("*all")
    f:close()
    self.events = json.decode(content)

    -- explode the settings (in cases of multiple)
    events = {}
    for i, e in pairs(self.events) do
        event = e
        if e.count == nil then
            table.insert(events, e)
        else
            for j = 1, e.count do
                e2 = {comment = e.comment..j, cc = e.cc + (j - 1) * e.add, commands = {}}
                e2.comment = e2.comment:gsub("X", j)
                if e.button ~= nil then
                    e2.button = true
                end
                for k, o in pairs(e.commands) do
                    o2 = Middy.deepcopy(o)
                    o2.msg = o2.msg:gsub("X", j)
                    table.insert(e2.commands, o2)
                end
                table.insert(events, e2)
            end
        end
    end

    -- initialize the settings
    for i, e in pairs(events) do
        events[i].state = {}
        for j, _ in pairs(e.commands) do
            events[i].state[j] = {last_val = 0, mem = 1}
        end
        events[i].last_msg_time = Middy.current_time()
    end
    self.events = events
    self.file_loaded = true
end -- End Middy:init_map(filename)

function Middy:process(data)
    local d = midi.to_msg(data)
    if d.type == "note_on" or d.type == "note_off" then
        return self:process_note(d)
    end

    --print('Middy', d.type, d.cc, d.val)
    if not self.file_loaded then
        do return end
    end
    current_time = Middy.current_time()
    for i, e in pairs(self.events) do
        -- check if the midi is equal to the cc value
        if e.cc == d.cc then
            --print("Middy", e.comment)
            -- buttons only toggle when hitting 127
            if e.button ~= nil and d.val ~= 127 then
                return
            end

            -- a small debouncer
            if current_time - e.last_msg_time < 0.05 then
                return
            end

            -- loop through each osc message for this event
            for j, o in pairs(e.commands) do
                send_val = nil
                if o.bounds ~= nil then
                    -- bounds are continuous
                    send_val = d.val / 127.0 * (o.bounds[2] - o.bounds[1])
                    send_val = send_val + o.bounds[1]
                elseif o.datas ~= nil then
                    -- loop through multiple discrete data
                    if e.button ~= nil and e.button then
                        -- button toggles to next data
                        if (self.events[i].state[j].mem == nil) then
                            self.events[i].state[j].mem = 1
                        end
                        self.events[i].state[j].mem = self.events[i].state[j].mem + 1
                        if self.events[i].state[j].mem > #o.datas then
                            self.events[i].state[j].mem = 1
                        end
                        send_val = o.datas[self.events[i].state[j].mem]
                    else
                        -- slider/toggle selects closest value in discrete set
                        send_val = o.datas[math.floor(d.val / 127.0 * (#o.datas - 1.0) + 1.0)]
                    end
                elseif o.data ~= nil then
                    -- single data is defined
                    send_val = o.data
                end
                if send_val ~= nil and send_val ~= self.events[i].state[j].last_val then
                    --print("Middy", e.comment, o.msg, send_val)
                    osc.send({"localhost", 10111}, o.msg, {send_val})
                    self.events[i].last_msg_time = current_time
                    self.events[i].state[j].last_val = send_val
                end
            end
            break
        end
    end
end -- End Middy:process(data)

Middy.current_time = function()
	return clock.get_beats()*clock.get_beat_sec()
end

Middy.deepcopy = function(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[Middy.deepcopy(orig_key)] = Middy.deepcopy(orig_value)
        end
        setmetatable(copy, Middy.deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

-- http://phrogz.net/round-to-nearest-via-modulus-division
Middy.round_to_nearest = function(i, n)
    local m = n / 2
    return i + m - (i + m)%n
end

Middy.table_empty = function(t)
    for _, _ in pairs(t) do
        return false
    end
    return true
end

return Middy
