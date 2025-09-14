---@class widget.game_card : druid.widget
local M = {}

local card_type = {
    { name = "Normal Mode", image = "Normal_Mode", level_name = hash("normal_mode") },
    { name = "Super Mode",  image = "Super_Mode",  level_name = hash("super_mode") },
    { name = "Grid Mode",   image = "Grid_Mode",   level_name = hash("grid_mode") }
}

function M:init(card_id)
    self.root = self:get_node("root")
    self.card_bg = self:get_node("card_bg")
    self.text = self:get_node("game_name")
    self.card_id = card_id
    gui.play_flipbook(self.card_bg, card_type[self.card_id].image)
    gui.set_text(self.text, card_type[self.card_id].name)
    self.button = self.druid:new_button(self.card_bg, function()
        msg.post("main_menu:/main_menu", "show_game_select", { room_type = card_type[self.card_id].level_name })
    end)
end

return M
