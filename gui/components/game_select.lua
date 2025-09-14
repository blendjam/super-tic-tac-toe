---@class widget.game_select : druid.widget
---@
local M = {}

function M:init()
    self.druid = self:get_druid()
    self.room_type = nil
    self.overlay = self:get_node("overlay")
    self.root = self:get_node("root")
    self.blocker = self.druid:new_blocker(self.overlay)
    self.blocker:set_enabled(false)
    self.druid:new_button("two_player", function()
        LevelController:load_level(self.room_type, { player_type = "player" },
            true)
    end)
    self.druid:new_button("computer", function()
        LevelController:load_level(self.room_type, { player_type = "computer" },
            true)
    end)
    self.druid:new_button("close_button", function()
        self:hide()
    end)
    gui.set(self.overlay, "color.w", 0)
    gui.set(self.root, "scale", vmath.vector3(0))
end

function M:hide()
    self.blocker:set_enabled(false)
    gui.animate(self.overlay, "color.w", 0, gui.EASING_OUTSINE, 0.3)
    gui.animate(self.root, "scale", vmath.vector3(), gui.EASING_INBACK, 0.3)
end

function M:show(room_type)
    self.blocker:set_enabled(true)
    gui.animate(self.overlay, "color.w", 0.95, gui.EASING_OUTSINE, 0.2)
    gui.animate(self.root, "scale", vmath.vector3(1), gui.EASING_OUTBACK, 0.3)
    self.room_type = room_type
end

return M
