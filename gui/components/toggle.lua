local component = require("druid.component")
local event = require("event.event")

---@class widget.toggle : druid.widget
---@field is_enabled boolean
local Toggle = {}

local SCHEME = {
    ROOT = "root",
    BUTTON = "button",
    TEXT = "button_text",
}

function Toggle:play_animation(animate)
    local onOff = self.is_enabled and 0 or 1
    gui.play_flipbook(self.node, gui.get_flipbook(self.node), nil,
        { offset = 0, playback_rate = onOff })
end

function Toggle:init(initial_toggle, on_state_change)
    self.druid = self:get_druid()
    self.root = self:get_node(SCHEME.ROOT)
    self.node = self:get_node(SCHEME.BUTTON)
    self.button = self.druid:new_button(SCHEME.BUTTON)
    self.clickable = true
    self.on_state_changed = event.create(on_state_change)
    self.toggle_text = self.druid:new_text(SCHEME.TEXT)
    self:set_state(initial_toggle, false)

    self.button.on_click:subscribe(function()
        self:toggle()
    end)
end

function Toggle:toggle()
    if not self.clickable then return end

    self.is_enabled = not self.is_enabled
    self:play_animation(true)
    self.on_state_changed:trigger(self.is_enabled)

    AudioManager:play_oneshot("toggle_pressed", { gain = 0.8, speed = math.random(80, 110) / 100 })
end

function Toggle:set_state(toggle, animate)
    self.is_enabled = toggle
    self:play_animation(animate)
end

function Toggle:set_clickable(clickable)
    self.clickable = clickable
end

function Toggle:set_text(text)
    self.toggle_text:set_text(text)
end

function Toggle:get_state()
    return self.is_enabled
end

return Toggle
