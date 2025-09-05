-- local Utils = require("_core.utils.utils")
-- local Storage = require("_core.networking.appcore.Storage")

local Levels = {
    game = hash("game"),
    main_menu = hash("main_menu"),

}

local broadcastUrls = {
    [Levels.game] = "game:/game_controller",
    [Levels.main_menu] = nil, -- nil means there is nothing to broadcast when this level is loaded
}

---@class LevelController
---@field current_level url
local M = {
    Levels = Levels,
    broadcastUrls = broadcastUrls,
}


function M:new()
    local ins = {}
    setmetatable(ins, self);
    self.__index = self;
    return self
end

function M:init()
    self.url = msg.url();
    window.set_dim_mode(window.DIMMING_OFF);
    msg.post(".", "acquire_input_focus")
    self.current_level = nil
    self.previous_level = nil
    for key, value in pairs(self.Levels) do
        self.Levels[value] = key; -- two way lookup
    end
    self:load_level(Levels.main_menu)
end

---@param level hash
---@param broadcastMessage table | nil
function M:load_level(level, broadcastMessage, transition)
    if self.current_level == level then return end
    msg.post(self.url, "load_level", { level = level, broadcastMessage = broadcastMessage, transition = transition })
end

local function unload_scene(scene)
    msg.post(scene, "disable")
    msg.post(scene, "final")
    msg.post(scene, "unload")
end

function M:get_current_level()
    if self.current_level then
        return hash(self.Levels[self.current_level.fragment])
    end
end

function M:create_match(matchInfo)
    msg.post(self.url, "create_match", { matchInfo = matchInfo });
end

function M:go_back()
    if self.previous_level == nil then
        self.previous_level = Levels.main_menu
    end
    self:load_level(self.previous_level.fragment)
end

local function delete_current_scene(self)
    if self.current_level then
        self.previous_level = self.current_level
        unload_scene(self.current_level)
        self.current_level = nil
    end
end


local function on_level_load(self, sender)
    self.loaded_proxy = nil
    delete_current_scene(self)
    self.current_level = sender
    msg.post(sender, "init")
    msg.post(sender, "enable")
    local broadcastUrl = self.broadcastUrls[sender.fragment];
    if broadcastUrl then
        msg.post(msg.url(broadcastUrl), "level_loaded", self.broadcastMessage);
    end
    --- RESET SOME VALUES
    msg.post("@render:", "use_fixed_fit_projection", { near = -10, far = 10 })
    Transition:hide()
    self.transition_complete = false
    ---
    if self.match ~= nil then
        print("have self.match so sending the matchinfo to the game");
        msg.post(msg.url("game:/game_controller#game_controller"), "matchInfo", self.match.matchInfo)
        self.match = nil;
    end
end

local function async_load_level(self, message)
    local level_url = (msg.url(nil, nil, message.level))
    if self.broadcastUrls[message.level] then
        self.broadcastMessage = message.broadcastMessage
    end
    msg.post(level_url, "async_load")
end

function M:on_message(message_id, message, sender)
    if message_id == hash("create_match") then
        --- level controller has to be the one to create the match
        --- since match needs to persist (websocket issue).
        local match_obj = factory.create("#match_factory", nil, nil, {});
        pprint("MATCH INFO GOT in LC", message.matchInfo)
        msg.post(match_obj, "matchInfo", message.matchInfo);
        Match:new(message.matchInfo, match_obj);
    end

    if message_id == hash("load_level") then
        async_load_level(self, message)
        self.transition_complete = true
        if message.transition then
            self.transition_complete = false
            Transition:play(function()
                self.transition_complete = true
                if self.loaded_proxy then
                    on_level_load(self, self.loaded_proxy)
                end
            end)
        end
    end

    if message_id == hash("proxy_loaded") then
        self.loaded_proxy = sender
        if self.transition_complete then
            on_level_load(self, sender)
        end
    end

    if message_id == hash("restart") then
        if message.transition then
            Transition:play(function()
                self:load_level(message.level, message.broadcastMessage, message.transition)
                delete_current_scene(self)
            end)
        else
            self:load_level(message.level, message.broadcastMessage, message.transition)
            delete_current_scene(self)
        end
    end
end

function M:restart_level(level, broadcastMessage, transition)
    msg.post(self.url, "restart", { level = level, broadcastMessage = broadcastMessage, transition = transition })
end

function M:final()
end

return M:new()
