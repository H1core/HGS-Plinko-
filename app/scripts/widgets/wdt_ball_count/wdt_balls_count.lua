local service_consumables = require("app.scripts.consumables.service_consumables")

---@class widget.wdt_balls_count: druid.widget
local M = {}


function M:init(...)
	self.consumable = service_consumables.get("balls")
	self.root = self:get_node("root")
	self:build_cd()
	self:build_cnt()
end

function M:build_cd()
	self.cd_txt = self.druid:new_text(
		self:get_node("shoot_cd_text/text")
		, ""
		, "no_adjust"
	)
	self.cd_txt_shadow = self:get_node("shoot_cd_text/text_shadow")
	self.cd_inner = self:get_node("shoot_cd")

	self.cd_txt.on_set_text:subscribe(function (_, text)
		gui.set_text(self.cd_txt_shadow, text)
	end, nil)
	self.func_update_cd_view = function ()
		gui.set_enabled(self.cd_inner , not self.consumable:is_limit())
		local _tmp_text = string.format(
			"+%d in %ds",
			self.consumable.cfg.recovery_amount,
			self.consumable:time_to_recovery()
		)

		self.cd_txt:set_text(_tmp_text)
	end
	timer.delay(0.5, true,self.func_update_cd_view)
	self.func_update_cd_view()

	self.druid
		:new_text_size_follower(self.cd_txt)
		:add_follower(self.cd_inner)
		:use_scaled_size_set()
		:set_size_bias(vmath.vector3(-6,0,0))
		:update_view()
end

function M:build_cnt()
	self.txt_cnt =  self.druid:new_text(
		self:get_node("text_cnt/text"),
		self.consumable:count(),
		"no_adjust"
	)
	self.txt_cnt_shadow = self:get_node("text_cnt/text_shadow")
	self.txt_cnt.on_set_text:subscribe(function (_, text)
		gui.set_text(self.txt_cnt_shadow, text)
	end, nil)

	self.txt_inner = self:get_node("shoots_inner")
	self.func_consumable_changed = function (cnt)
		self.txt_cnt:set_text(cnt)
		self.func_update_cd_view()
	end
	self.consumable.event_changed:subscribe(self.func_consumable_changed)

	self.txt_cnt:set_text(self.consumable:count())
	self.druid
		:new_text_size_follower(self.txt_cnt)
		:add_follower(self.txt_inner)
		:set_size_bias(vmath.vector3(64,0,0))
		:update_view()
end

function M:on_remove()
	self.consumable.event_changed:unsubscribe(self.func_consumable_changed)
end

return M
