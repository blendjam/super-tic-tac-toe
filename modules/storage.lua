local utils = require("utils.utils");

local CACHE_FILENAME = "cache_file"
local APPLICATION_NAME = "SUPERTTT"

local preferences_save_file = sys.get_save_file(APPLICATION_NAME, "app_preferences");
local cache_save_file = sys.get_save_file(APPLICATION_NAME, CACHE_FILENAME);

local DEFAULT_CACHE_SETTING = { max_length = 21, queue = {}, data = {} }
local DEFAULT_PREFERENCES = {
    settings = {sound = true, music = true},
    games_played = {}
}

--Meta class
---@class Storage
local Storage = {
    listeners = {},
    cache = DEFAULT_CACHE_SETTING
}

---@return Storage
function Storage:new()
    local ins = {}
    setmetatable(ins, self);
    self.__index = self;
    self:init();
    self:broadcastChange();
    return self
end

function Storage:init()
    self.cache = sys.load(cache_save_file)
    if self.cache.max_length == nil then
        self.cache = DEFAULT_CACHE_SETTING
    end

    self.preferences = sys.load(preferences_save_file);
    if self.preferences == nil then
        self.preferences = DEFAULT_PREFERENCES
    end
end

function Storage:clear()
    sys.save(preferences_save_file, {})
    self.listeners = {};
    self.state = {}
    self:init();
    timer.delay(0.2, false, function(self, handle, time_elapsed)
        msg.post("starter:/starter", "restart");
    end)
    self:save();
end

function Storage:getPreferences(key)
    return self.preferences[key];
end

function Storage:getUserSettings()
    return self.preferences["settings"];
end

function Storage:setPreferences(key, value)
    self.preferences[key] = value;
    sys.save(preferences_save_file, self.preferences);
    if self.listeners["settings"] == nil then return end
    for _, cb in pairs(self.listeners["settings"]) do
        cb(self.preferences);
    end
end

---@param key string
---@param val any
function Storage:updateSyncedState(key, val)
    self.syncedState[key] = val;

    sys.save(synced_save_file, self.syncedState);
end

function Storage:save()
    sys.save(preferences_save_file, self.preferences);
    self:broadcastChange();
end

function Storage:broadcastChange()
    self.unsyncedState = self.state.unsyncedState
    for k, listeners in pairs(self.listeners) do
        for _, listener in pairs(listeners) do
            if k == "settings" then
                utils.safeExec(function()
                    listener(self.preferences);
                end, nil, function()
                    pprint("broadcasting failed", k);
                end)
            else
                utils.safeExec(function()
                    listener(self.unsyncedState[k]);
                end, nil, function()
                    pprint("broadcasting failed", k, self.unsyncedState[k]);
                end)
            end
        end
    end
end

---@param key string
---@param val any
function Storage:broadcastKeyChange(key, val)
    pprint("BORDCAst", self.listeners)
    if self.listeners[key] ~= nil then
        for _, listener in pairs(self.listeners[key]) do
            utils.safeExec(function()
                listener(val);
            end, nil, function()
                pprint("broadcasting failed", key, val);
            end)
        end
    end
end

---@param key string
---@param listener fun(val: table)
---@return string
function Storage:setListener(key, listener)
    if self.listeners[key] == nil then
        self.listeners[key] = {};
    end
    local unique = utils.randomString(15)
    while self.listeners[key][unique] ~= nil do
        unique = utils.randomString(15)
    end
    self.listeners[key][unique] = listener
    utils.safeExec(function()
        if key == "settings" then
            listener(self.preferences)
        else
            listener(self.unsyncedState[key])
        end
    end, nil, function()
        pprint("broadcasting failed", key);
    end)
    return unique
end

---@param key string
---@param handle string
function Storage:removeListener(key, handle)
    if self.listeners[key] ~= nil then
        self.listeners[key][handle] = nil;
    end
end

---@param key string
---@param val any
function Storage:updateUnsyncedState(key, val)
    self.state.unsyncedState[key] = val;
    sys.save(unsynced_save_file, self.state);
    self.unsyncedState = self.state.unsyncedState;
    self:broadcastKeyChange(key, self.unsyncedState[key]);
end

function Storage:updateUnsyncedActions(actions)
    if actions == nil then
        actions = self.unsyncedActions;
    end
    self.unsyncedActions = actions
    sys.save(unsynced_actions_file, self.unsyncedActions);
end

local function find_index(queue, item)
    for key, value in ipairs(queue) do
        if value == item then return key end
    end
    return nil
end

function Storage:clearCache()
    self.cache = DEFAULT_CACHE_SETTING
    sys.save(cache_save_file, self.cache)
end

function Storage:saveCacheFile(key, value)
    self.cache.data[key] = value
    local index = find_index(self.cache.queue, key)
    if index then
        self.cache.data[self.cache.queue[index]] = nil
        table.remove(self.cache.queue, index)
    end
    self.cache.data[key] = value
    table.insert(self.cache.queue, 1, key)
    if #self.cache.queue > self.cache.max_length then
        local last_index = #self.cache.queue
        self.cache.data[self.cache.queue[last_index]] = nil
        table.remove(self.cache.queue, last_index)
    end
    sys.save(cache_save_file, self.cache)
end

function Storage:getCacheFile(key)
    local index = find_index(self.cache.queue, key)
    if index then
        table.remove(self.cache.queue, index)
        table.insert(self.cache.queue, 1, key)
    end
    if #self.cache.queue > self.cache.max_length then
        table.remove(self.cache.queue, #self.cache.queue)
    end

    return self.cache.data[key]
end

return Storage:new();
