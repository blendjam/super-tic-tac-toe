---@alias SoundProps { gain:number, speed:number, loop: boolean}
---@class SoundManager
---@field sound_go string
local M = {
    sound_go = "main:/audio_manager#audio_manager",
    current_bg_music = nil,
    current_bg_music_props = nil
}

-- Always have a bg_music to toggle on or of unless someone calls play_music

---@return SoundManager
function M:new()
    local ins = {}
    setmetatable(ins, self);
    self.__index = self;
    return self;
end

function M:init()
    self.is_playing_music = false
end

---@param sound string
---@param soundProps SoundProps | nil
function M:play_oneshot(sound, soundProps)
    msg.post(self.sound_go, "play_oneshot", { sound = sound, props = soundProps })
end

---@param sound string
---@param soundProps SoundProps
function M:play_music(sound, soundProps)
    if self.current_bg_music ~= sound then
        M:fade_out_music(self.current_bg_music, 1)
        msg.post(self.sound_go, "play_music", { sound = sound, props = soundProps })
        self.is_playing_music = true
    end
    self.current_bg_music = sound
    self.current_bg_music_props = soundProps
end

function M:pause_music()
    if self.is_playing_music then
        msg.post(self.sound_go, "fade_out", { sound = self.current_bg_music, duration = 1 / 0.5 })
        self.is_playing_music = false
    end
end

function M:resume_music()
    if not self.is_playing_music and self.current_bg_music ~= nil then
        msg.post(self.sound_go, "play_music", { sound = self.current_bg_music, props = self.current_bg_music_props })
        self.is_playing_music = true
    end
end

function M:fade_out_music(sound, duration)
    if self.is_playing_music and self.current_bg_music == sound then
        msg.post(self.sound_go, "fade_out", { sound = sound, duration = duration })
        self.is_playing_music = false
        self.current_bg_music = nil
    end
end

return M:new()
