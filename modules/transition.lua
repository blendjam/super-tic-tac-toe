---@class Transition
local M = {}

local function show_circle_transition(self)
	gui.set_enabled(self.root, true)
	for i, circle in ipairs(self.circle.list) do
		local column = i % self.circle.column
		local row    = math.floor((i - column) / self.circle.column)
		local delay  = row * 0.03
		gui.set_enabled(circle, true)
		gui.animate(circle, "scale", vmath.vector3(1), gui.EASING_INOUTSINE, 0.5, delay, function()
			if i == #self.circle.list then
				gui.set_enabled(self.loading_overlay, true)
				self.on_transition_complete()
			end
		end)
	end
end

local function init_circle_list(self)
	for i = 0, self.circle.row do
		for j = 0, self.circle.column do
			local circle = gui.clone(self.circle.prefab)
			local circle_radius = self.circle.size * 0.5
			local x_offset = (-gui.get_width() / 2 - circle_radius) + (j * circle_radius)
			local y_offset = (-gui.get_height() / 2 - circle_radius) + (i * circle_radius)
			gui.set_position(circle, vmath.vector3(x_offset, y_offset, 0))
			gui.set(circle, "size", vmath.vector3(self.circle.size))
			gui.set_scale(circle, vmath.vector3(0, 0, 0))
			table.insert(self.circle.list, circle)
		end
	end
end

local function hide_circle_transition(self)
	gui.set_enabled(self.loading_overlay, false)
	for i, circle in ipairs(self.circle.list) do
		-- gui.set_pivot(circle, gui.PIVOT_NE)
		local column = i % self.circle.column
		local row    = math.floor((i - column) / self.circle.column)
		local delay  = row * 0.03
		gui.animate(circle, "scale", vmath.vector3(0), gui.EASING_INOUTSINE, 0.5, delay, function()
			gui.set_enabled(circle, false)
			if row == self.circle.row then
				gui.set_enabled(self.root, false)
			end
		end)
	end
end


function M:new()
	local o = {}
	setmetatable(o, self)
	self.__index = self
	return o
end

function M:set_templates()
	gui.set_render_order(15)
	self.url = msg.url()
	self.root = gui.get_node("root")

	-- Circle Transition
	self.loading_overlay = gui.get_node("loading_overlay")
	self.circle = {
		prefab = gui.get_node("circle"),
		size = 300,
		row = 0,
		column = 0,
		list = {}
	}
	self.circle.row = math.ceil(gui.get_height() / (self.circle.size * 0.5)) + 1
	self.circle.column = math.ceil(gui.get_width() / (self.circle.size * 0.5)) + 1
	self.is_loading = false

	gui.set(self.circle.prefab, "scale", vmath.vector3(0, 0, 0))
	gui.set_enabled(self.root, false)
	gui.set_enabled(self.loading_overlay, false)
	init_circle_list(self)
end

function M:play(on_complete)
	self.on_transition_complete = on_complete or function()
		pprint("TRANSITION COMPLETE")
	end
	msg.post(self.url, "play_transition")
end

function M:hide()
	msg.post(self.url, "hide_transition")
end

function M:on_message(message_id, message, sender)
	if message_id == hash("play_transition") then
		self.is_loading = true
		msg.post(".", "acquire_input_focus")
		show_circle_transition(self)
	end

	if message_id == hash("hide_transition") then
		hide_circle_transition(self)
		self.is_loading = false
	end
end

function M:on_input(action_id, action)
	if self.is_loading then
		return true
	end
	return false
end

Transition = M:new()
