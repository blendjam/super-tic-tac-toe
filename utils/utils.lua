---@alias UserProfile { clientId: string | nil; type: string; name: string; picture: string; country: string; email: string; allowBeta: boolean }
---@alias UserCurrencies { rubies: number, chips_single: number, chips_multi: number, life: number };
---@alias UserItem {id: number, equipped: boolean, quantity: number, preview: {parent_id: number, texture_url: string, lvl: number}, equipGroup: number, category: number}
---@alias State  {statePatchNumber: number,typeId: string; serverSequenceNumber: number; deviceSequenceNumber: number; instanceId: string; currencies: UserCurrencies; profile: UserProfile; items: UserItem[] }
---@alias ServerAction {instanceId: string; serverSequenceNumber: number; deviceSequenceNumber: number; serializedAction: table}
local DISPLAY_WIDTH = sys.get_config_int("display.width")
local DISPLAY_HEIGHT = sys.get_config_int("display.height")

local M = {
    center = vmath.vector3(720 / 2, 1440 / 2, 0.5),
    render_state = {},
    worldSize = {
        y = 1440,
        x = 720
    },
    coords = {
        top = 1440,
        right = 720,
        bottom = 0,
        left = 0
    }
}

M.PlayerType = {
    CROSS = "CROSS",
    CIRCLE = "CIRCLE"
}

M.WinnerType = {
    CROSS = M.PlayerType.CROSS,
    CIRCLE = M.PlayerType.CIRCLE,
    NONE = "NONE",
    TIE = "TIE"
}

M.PlayState = {
    PLAY = "PLAY",
    END = "END",
    ZOOMIN = "ZOOMIN",
    ZOOMOUT = "ZOOMOUT",
    FULLVIEW = "FULLVIEW",
}


M.RoomType = {
    Single = 1,
    Multi = 2,
    Hotspot = 3,
    Passnplay = 4,
    Tournament = 5,
    Tutorial = 6,
    [1] = "single",
    [2] = "multiplayer",
    [3] = "hotspot",
    [4] = "passnplay",
    [5] = "tournament",
    [6] = "tutorial"
}

M.Rarity = {
    [1] = "standard",
    [2] = "rare",
    [3] = "legendary",
    standard = 1,
    rare = 2,
    legendary = 3
}

M.ItemType = {
    [1] = "striker",
    [2] = "puck",
    [3] = "board",
    [4] = "frame",
    striker = 1,
    puck = 2,
    board = 3,
    frame = 4
}

M.CurrencyId = {
    [1] = "rubies",
    [2] = "chips_single",
    [3] = "chips_multi",
    [4] = "life",
    [5] = "standard_token",
    [6] = "rare_token",
    [7] = "legendary_token",
    rubies = 1,
    chips_single = 2,
    chips_multi = 3,
    life = 4,
    standard_token = 5,
    rare_token = 6,
    legendary_token = 7
}

M.CurrencySources = {
    AdReward = 1,
    RubyExchange = 2,
    LoginReward = 3,
    Milestone = 4,
    LeaderboardReward = 5
}

M.stats = {
    total_games_single = 617,
    total_wins_single = 618,
    total_games_multi = 620,
    total_wins_multi = 621,
    total_coins_won_multi = 622,
    mmr_multi = 626,
    total_games_pnp = 627,
    total_xp = 631
}

function M.str_split(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t = {}
    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
        table.insert(t, str)
    end
    return t
end

function M.open_feedback_mail(clientId)
    local title = "Carrom Feedback (v" .. sys.get_config_string("project.version") .. "-" .. clientId .. ")"
    local mail_body = "Sent via (" .. sys.get_sys_info().device_model .. " " .. sys.get_sys_info().system_name .. " " ..
        sys.get_sys_info().system_version .. ")" .. " Please do not erase this part" ..
        "\n\nYour Feedback: "

    sys.open_url("mailto:support@bhoos.com?subject=" .. title .. "&body=" .. mail_body)
end

function M.version_compare(old_version, new_version)
    local old = M.str_split(old_version, ".")
    local new = M.str_split(new_version, ".")
    for index, value in ipairs(old) do
        if tonumber(value) < tonumber(new[index]) then
            return true;
        end
    end
    return false;
end

function M.hex_to_rgb(hex)
    hex = hex:gsub("#", "")
    return vmath.vector3(tonumber("0x" .. hex:sub(1, 2)) / 255, tonumber("0x" .. hex:sub(3, 4)) / 255,
        tonumber("0x" .. hex:sub(5, 6)) / 255, 1)
end

function M.is_inside(touch_pos, target_pos, puck_size)
    local dist = vmath.length(touch_pos - target_pos)
    return dist < puck_size
end

function M.lerp(a, b, t)
    return a + (b - a) * t
end

function M.set_render_state(state)
    M.render_state = state
end

function M.get_table_size(table)
    local count = 0
    for _ in pairs(table) do
        count = count + 1
    end
    return count
end

function M.firstUpper(str)
    return string.gsub(" " .. str, "%W%l", string.upper):sub(2)
end

function M.condense_number(number)
    if number >= 1000000000 then
        return math.floor(number / 1000000000) .. "." .. math.floor((number % 1000000000) / 10000000) .. "B"
    elseif number >= 1000000 then
        return math.floor(number / 1000000) .. "." .. math.floor((number % 1000000) / 10000) .. "M"
    elseif number >= 1000 then
        return math.floor(number / 1000) .. "." .. math.floor((number % 1000) / 10) .. "K"
    else
        return tostring(number)
    end
end

function M.vector_to_table(vector3)
    return {
        x = vector3.x,
        y = vector3.y,
        z = vector3.z
    }
end

function M.table_to_vector(table)
    return vmath.vector3(table.x, table.y, table.z)
end

function M.map_range(var, in_min, in_max, out_min, out_max)
    return (var - in_min) * (out_max - out_min) / (in_max - in_min) + out_min
end

function M.normalize(value, min, max)
    return (value - min) / (max - min)
end

function M.clamp(var, min, max)
    if min > max then
        local temp = min;
        min = max;
        max = temp;
    end
    if var < min then
        return min
    elseif var > max then
        return max
    else
        return var
    end
end

---comment
---@param url string | hash | url
---@param duration number
---@param value vector3
---@param _cb fun() | nil
---@param _delay number | nil
function M.animatePositionLinearEase(url, duration, value, _cb, _delay)
    local delay = _delay == nil and 0 or _delay
    local cb = _cb == nil and function()
    end or _cb
    go.animate(url, "position", go.PLAYBACK_ONCE_FORWARD, value, go.EASING_LINEAR, duration, delay, cb)
end

function M.screen_to_world_defold(x, y, z, projection, view)
    local w, h = window.get_size()
    -- The window.get_size() function will return the scaled window size,
    -- ie taking into account display scaling (Retina screens on macOS for
    -- instance). We need to adjust for display scaling in our calculation.
    w = w / (w / DISPLAY_WIDTH)
    h = h / (h / DISPLAY_HEIGHT)

    -- https://defold.com/manuals/camera/#converting-mouse-to-world-coordinates
    local inv = vmath.inv(projection * view)
    x = (2 * x / w) - 1
    y = (2 * y / h) - 1
    z = (2 * z) - 1
    local x1 = x * inv.m00 + y * inv.m01 + z * inv.m02 + inv.m03
    local y1 = x * inv.m10 + y * inv.m11 + z * inv.m12 + inv.m13
    local z1 = x * inv.m20 + y * inv.m21 + z * inv.m22 + inv.m23
    return vmath.vector3(x1, y1, z1)
end

function M.screen_to_world(vector)
    return M.screen_to_world_defold(vector.x, vector.y, vector.z, M.render_state.main_camera.proj,
        M.render_state.main_camera.view)
end

---comment
---@param statsTable table<number, table<number,number>>
---@param id number
---@return number
function M.AggregateStats(statsTable, id)
    local val = 0;
    for _, value in pairs(statsTable) do
        if value["0"] == id then
            val = val + value["2"]
        end
    end
    return val
end

function M.get_total_trophy(statsTable)
    return M.AggregateStats(statsTable, M.stats.mmr_multi)
end

function M.randomString(n)
    local chars = { "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T",
        "U", "V", "W", "X", "Y", "Z", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n",
        "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "0", "1", "2", "3", "4", "5", "6", "7",
        "8", "9" }
    local ret = ""
    while n > 0 do
        ret = ret .. chars[rnd.range(1, #chars)];
        n = n - 1;
    end
    return ret
end

function M.table_copy(table, isarray)
    local loopingfunc = pairs
    if isarray then
        loopingfunc = ipairs
    end
    local c = {}
    for key, value in loopingfunc(table) do
        c[key] = value;
    end
    return c;
end

---@param fn fun() -- function to retry until donefn returns true
---@param retryInterval number -- in seconds
---@param donefn fun(): boolean -- function that tells if we no longer need to retry
function M.retryUntil(fn, retryInterval, donefn)
    if donefn() then
        return;
    end
    fn()
    if donefn() then
        return;
    end
    timer.delay(retryInterval, false, function(self, handle, time_elapsed)
        M.retryUntil(fn, retryInterval, donefn)
    end);
end

---comment
---@param str string
---@param max_length number
---@param min_length number
---@param fill string
function M.stringFit(str, max_length, min_length, fill)
    local ret = ""
    if string.len(str) <= max_length then
        return str;
    end

    ret = string.sub(str, 1, min_length)
    for i = 1, (max_length - min_length) do
        ret = ret .. fill;
    end
    return ret;
end

---comment
---@param t table
---@param cb fun(k: string | number, value: any): boolean
---@return any | nil
function M.table_find(t, cb, isarray)
    local loopingfunc = pairs
    if isarray then
        loopingfunc = ipairs
    end
    for key, value in loopingfunc(t) do
        if cb(key, value) then
            return value;
        end
    end
    return nil
end

---comment
---@param t table
---@param cb fun(k: string | number, value: any): boolean
---@return number
function M.table_find_index(t, cb, isarray)
    local loopingfunc = pairs
    if isarray then
        loopingfunc = ipairs
    end
    for key, value in loopingfunc(t) do
        if cb(key, value) then
            return key;
        end
    end
    return -1
end

function M.safeExec(fn, onSuccess, onFail)
    if not onSuccess then
        onSuccess = function()
        end
    end

    if not onFail then
        onFail = function()
        end
    end
    local success, res = pcall(function()
        fn();
    end)
    if not success then
        pprint("success handler failed for api", res);
    end
    return res;
end

---@param t table
---@param cb fun(k: string | number, value: any): boolean
---@return table<number, any>;
function M.table_find_multi(t, cb, isarray)
    local ret = {}
    local loopingfunc = pairs
    if isarray then
        loopingfunc = ipairs
    end
    for key, value in loopingfunc(t) do
        if cb(key, value) then
            table.insert(ret, #ret + 1, value);
        end
    end
    return ret;
end

function M.table_contains(t, value)
    for _, v in pairs(t) do
        if v == value then
            return true;
        end
    end
    return false;
end

function M.unix_to_date(unix_time)
    local seconds_in_a_day = 86400

    local timestamp = unix_time * seconds_in_a_day

    return os.date("%Y-%m-%d", timestamp)
end

function M.unix_to_time_remaining(unix_time)
    local seconds_in_a_day = 86400

    local target_timestamp = unix_time * seconds_in_a_day

    local current_timestamp = os.time(os.date("!*t")) -- UTC time

    local remaining = target_timestamp - current_timestamp

    local days = math.floor(remaining / seconds_in_a_day)
    local hours = math.floor((remaining % seconds_in_a_day) / 3600)
    local minutes = math.floor((remaining % 3600) / 60)
    return string.format("%dd:%02dh:%02dm", days, hours, minutes)
end

function M.table_map(t, cb, isarray)
    local loopingfunc = pairs
    if isarray then
        loopingfunc = ipairs
    end
    local ret = {}
    for key, value in loopingfunc(t) do
        table.insert(ret, cb(key, value))
    end
    return ret;
end

function M.is_touch(action_id)
    if action_id == hash("touch") or action_id == hash("touch_multi") then
        return true
    end
end

function M.load_image_to_atlas(image_path, image_name, callback)
    local data = sys.load_resource(image_path)
    imageloader.load({
        data = data,
        listener = function(self, res)
            local params = {
                width = res.header.width,
                height = res.header.height,
                type = graphics.TEXTURE_TYPE_2D,
                format = graphics.TEXTURE_FORMAT_RGBA
            }
            local texture_name = image_name .. ".texturec"

            local success, result = pcall(resource.get_texture_info, texture_name)
            if not success then
                local texture_id = resource.create_texture(texture_name, params, res.buffer)
            else
                pprint("Texture Already Created")
            end
            local aparams = {
                texture = texture_name,
                animations = { {
                    id = image_name,
                    width = res.header.width,
                    height = res.header.height,
                    frame_start = 1,
                    frame_end = 2,
                    playback = go.PLAYBACK_NONE
                } },
                geometries = { {
                    id = image_name,
                    width = res.header.width,
                    height = res.header.height,
                    pivot_x = 0.5,
                    pivot_y = 0.5,
                    vertices = { 0, 0, 0, res.header.height, res.header.width, res.header.height, res.header.width, 0 },
                    uvs = { 0, 0, 0, res.header.height, res.header.width, res.header.height, res.header.width, 0 },
                    indices = { 0, 1, 2, 0, 2, 3 }
                } }
            }
            local atlas_id = nil
            local atlas_path = image_name .. ".texturesetc"
            local success, result = pcall(resource.get_atlas, atlas_path)
            if not success then
                atlas_id = resource.create_atlas(atlas_path, aparams)
            else
                atlas_id = hash(atlas_path)
                pprint("Atlas Already Created")
            end
            pcall(callback, atlas_id)
        end
    })
end

-- function M.load_puck_atlas(puck, callback)
--   local atlas_id = nil
--   local data = sys.load_resource("/assets/runtime_resources/pucks/" .. puck .. ".png")
--   local puck_texture_width = 72
--   imageloader.load({
--     data = data,
--     listener = function(self, res)
--       local params = {
--         width = res.header.width,
--         height = res.header.height,
--         type = graphics.TEXTURE_TYPE_2D,
--         format = graphics.TEXTURE_FORMAT_RGBA
--       }
--       local texture_name = "/" .. puck .. ".texturec"
--       local texture_id = resource.create_texture(texture_name, params, res.buffer)
--       local aparams = {
--         texture = texture_name,
--         animations = {
--           {
--             id          = "Black",
--             width       = res.header.width,
--             height      = res.header.height,
--             frame_start = 1,
--             frame_end   = 2,
--             playback    = go.PLAYBACK_NONE
--           },
--           {
--             id          = "White",
--             width       = res.header.width,
--             height      = res.header.height,
--             frame_start = 2,
--             frame_end   = 3,
--             playback    = go.PLAYBACK_NONE
--           },
--           {
--             id          = "Queen",
--             width       = res.header.width,
--             height      = res.header.height,
--             frame_start = 3,
--             frame_end   = 4,
--             playback    = go.PLAYBACK_NONE
--           },
--         },
--         geometries = {
--           {
--             id       = 'Black',
--             width    = puck_texture_width,
--             height   = res.header.height,
--             pivot_x  = 0.5,
--             pivot_y  = 0.5,
--             vertices = {
--               0, 0,
--               0, res.header.height,
--               puck_texture_width, res.header.height,
--               puck_texture_width, 0
--             },
--             uvs      = {
--               0, 0,
--               0, res.header.height,
--               puck_texture_width, res.header.height,
--               puck_texture_width, 0
--             },
--             indices  = { 0, 1, 2, 0, 2, 3 }
--           },
--           {
--             id       = "White",
--             width    = puck_texture_width,
--             height   = res.header.height,
--             pivot_x  = 0.5,
--             pivot_y  = 0.5,
--             vertices = {
--               puck_texture_width, 0,
--               puck_texture_width, res.header.height,
--               puck_texture_width * 2, res.header.height,
--               puck_texture_width * 2, 0
--             },
--             uvs      = {
--               puck_texture_width, 0,
--               puck_texture_width, res.header.height,
--               puck_texture_width * 2, res.header.height,
--               puck_texture_width * 2, 0
--             },
--             indices  = { 0, 1, 2, 0, 2, 3 }
--           },
--           {
--             id       = "Queen",
--             width    = puck_texture_width,
--             height   = res.header.height,
--             pivot_x  = 0.5,
--             pivot_y  = 0.5,
--             vertices = {
--               puck_texture_width * 2, 0,
--               puck_texture_width * 2, res.header.height,
--               puck_texture_width * 3, res.header.height,
--               puck_texture_width * 3, 0
--             },
--             uvs      = {
--               puck_texture_width * 2, 0,
--               puck_texture_width * 2, res.header.height,
--               res.header.width, res.header.height,
--               res.header.width, 0
--             },
--             indices  = { 0, 1, 2, 0, 2, 3 }
--           }
--         }
--       }
--       atlas_id = resource.create_atlas("/" .. puck .. ".texturesetc", aparams)
--       callback(atlas_id)
--     end
--   })
-- end

return M;
