if string.lower(RequiredScript) == "lib/managers/hud/hudassaultcorner" then
	local init_original = HUDAssaultCorner.init
	local _start_assault_original = HUDAssaultCorner._start_assault
	local _set_hostage_offseted_original = HUDAssaultCorner._set_hostage_offseted
	local set_buff_enabled_original = HUDAssaultCorner.set_buff_enabled
	local show_point_of_no_return_timer_original = HUDAssaultCorner.show_point_of_no_return_timer
	local hide_point_of_no_return_timer_original = HUDAssaultCorner.hide_point_of_no_return_timer
	local show_casing_original = HUDAssaultCorner.show_casing
	local hide_casing_original = HUDAssaultCorner.hide_casing
	local set_assault_wave_number_original = HUDAssaultCorner.set_assault_wave_number
	local _animate_wave_started_original = HUDAssaultCorner._animate_wave_started
	local _animate_wave_completed_original = HUDAssaultCorner._animate_wave_completed

	local enhanced_obj = VHUDPlus:getSetting({"CustomHUD", "ENABLED_ENHANCED_OBJECTIVE"}, false)
	local center_assault = VHUDPlus:getSetting({"AssaultBanner", "USE_CENTER_ASSAULT"}, true)
	local HIDE_CASING_MODE_PANEL = VHUDPlus:getSetting({"AssaultBanner", "HIDE_CASING_MODE_PANEL"}, false)

	function HUDAssaultCorner:init(tweak_hud, ...)
		init_original(self, tweak_hud, ...)

		if center_assault then
			if alive(self._hud_panel:child("assault_panel")) or alive(self._hud_panel:child("casing_panel")) or alive(self._hud_panel:child("point_of_no_return_panel")) or alive(self._hud_panel:child("buffs_panel")) or alive(self._hud_panel:child("_vip_bg_box")) then
				self._hud_panel:child("assault_panel"):set_right(self._hud_panel:w() / 2 + 150)
				-- self._hud_panel:child("assault_panel"):child("icon_assaultbox"):set_visible(false)
				self._hud_panel:child("casing_panel"):set_right(self._hud_panel:w() / 2 + 150)
				self._hud_panel:child("casing_panel"):child("icon_casingbox"):set_visible(HIDE_CASING_MODE_PANEL)
				self._hud_panel:child("point_of_no_return_panel"):set_right(self._hud_panel:w() / 2 + 150)
				-- self._hud_panel:child("point_of_no_return_panel"):child("icon_noreturnbox"):set_visible(false)
				self._hud_panel:child("buffs_panel"):set_x(self._hud_panel:child("assault_panel"):right())
				self._vip_bg_box:set_x(0) -- left align this "buff"
			end
			if not enhanced_obj then
				self._last_assault_timer_size = 0
				self._assault_timer = HUDHeistTimer:new({
					panel = self._bg_box:panel({
						name = "assault_timer_panel",
						x = 4
					})
				}, tweak_hud)
				self._assault_timer._timer_text:set_font_size(tweak_data.hud_corner.assault_size)
				self._assault_timer._timer_text:set_font(Idstring(tweak_data.hud_corner.assault_font))
				self._assault_timer._timer_text:set_align("left")
				self._assault_timer._timer_text:set_vertical("center")
				self._assault_timer._timer_text:set_color(Color.white:with_alpha(0.9))
			
				self._last_casing_timer_size = 0
				self._casing_timer = HUDHeistTimer:new({
					panel = self._casing_bg_box:panel({
						name = "casing_timer_panel",
						x = 4
					})
				}, tweak_hud)
				self._casing_timer._timer_text:set_font_size(tweak_data.hud_corner.assault_size)
				self._casing_timer._timer_text:set_font(Idstring(tweak_data.hud_corner.assault_font))
				self._casing_timer._timer_text:set_align("left")
				self._casing_timer._timer_text:set_vertical("center")
				self._casing_timer._timer_text:set_color(Color.white:with_alpha(0.9))
			end
		end
		
		-- Waves completed are visible in Objective and overlapping with HUDList.
		if self:should_display_waves() and VHUDPlus:getSetting({"AssaultBanner", "WAVE_COUNTER"}, true) then
			local wave_panel = self._hud_panel:child("wave_panel")
			if alive(wave_panel) then
				wave_panel:set_alpha(0)
			end
			local assault_panel = self._hud_panel:child("assault_panel")
			if alive(assault_panel) then
				self._wave_text = assault_panel:text({
					name = "num_waves",
					text = self:get_completed_waves_string(),
					valign = "center",
					vertical = "center",
					align = "center",
					halign = "right",
					w = self._bg_box and self._bg_box:w() - 5 or 100,
					h = 14,
					layer = 1,
					x = 0,
					y = 0,
					color = Color.white,
					alpha = 0.8,
					font = "fonts/font_medium_shadow_mf",
					font_size = tweak_data.hud.active_objective_title_font_size * 0.9,
				})
				self._wave_text:set_top(self._bg_box and self._bg_box:bottom() or 40)
				self._wave_text:set_right(self._bg_box and self._bg_box:right() or 575)
			end
		end
	end

	function HUDAssaultCorner:feed_heist_time(t, ...)
		local time = "00:00"

		if t >= 60 then
			local m = tonumber(string.format("%d", t/60))
			local s = t - m*60

			if m >= 60 then
				local h = tonumber(string.format("%d", m/60))
					m = m - h*60
				time = string.format("%02d:%02d:%02d", h, m, s)
			else
				time = string.format("%02d:%02d", m, s)
			end

		else
			r = string.format("00:%02d", t)
		end

		VHUDPlus._heist_time = time
		
		if self._assault_timer and not enhanced_obj then
			self._assault_timer:set_time(t)
			local _, _, cw, _ = self._assault_timer._timer_text:text_rect()
			if alive(self._bg_box:child("text_panel")) and self._bg_box:w() >= 242 and cw ~= self._last_assault_timer_size then
				self._last_assault_timer_size = cw
				self._bg_box:child("text_panel"):set_w(self._bg_box:w() - (cw + 8))
				self._bg_box:child("text_panel"):set_x(cw + 8)
			end
		end
		if self._casing_timer and not enhanced_obj then
			self._casing_timer:set_time(t)
			local _, _, aw, _ = self._casing_timer._timer_text:text_rect()
			if alive(self._casing_bg_box:child("text_panel")) and self._casing_bg_box:w() >= 242 and aw ~= self._last_casing_timer_size then
				self._last_casing_timer_size = aw
				self._casing_bg_box:child("text_panel"):set_w(self._casing_bg_box:w() - (aw + 8))
				self._casing_bg_box:child("text_panel"):set_x(aw + 8)
			end
		end
	end

	function HUDAssaultCorner:_start_assault(text_list, ...)
		for i, string_id in ipairs(text_list) do
			if string_id == "hud_assault_assault" or string_id == "hud_assault_alpha" or string_id == "NepgearsyHUDReborn/HUD/AssaultCorner/Coming" then
				text_list[i] = "hud_adv_assault"
			end
		end
		return _start_assault_original(self, text_list, ...)
	end
	

	function HUDAssaultCorner:_animate_wave_started(...)
		if alive(self._wave_text) then
			self._wave_text:set_text(self:get_completed_waves_string())
		end

		return _animate_wave_started_original(self, ...)
	end
	function HUDAssaultCorner:_animate_wave_completed(...)
		if alive(self._wave_text) then
			self._wave_text:set_text(self:get_completed_waves_string())
		end

		return _animate_wave_completed_original(self, ...)
	end

	function HUDAssaultCorner:set_assault_wave_number(...)
		if alive(self._wave_text) then
			self._wave_text:set_text(self:get_completed_waves_string())
			self._wave_text:animate(callback(self, self, "_animate_wave_text"))
		end

		return set_assault_wave_number_original(self, ...)
	end

	function HUDAssaultCorner:_animate_wave_text(object)
		local TOTAL_T = 2
		local t = TOTAL_T
		object:set_alpha(0.8)
		while t > 0 do
			local dt = coroutine.yield()
			t = t - dt
			object:set_alpha(0.5 + 0.5 * (0.5 * math.sin(t * 360 * 2) + 0.5))
		end
		object:set_alpha(0.8)
	end

	function HUDAssaultCorner:locked_assault(status)
		local assault_panel = self._hud_panel:child("assault_panel")
		local icon_assaultbox = assault_panel and assault_panel:child("icon_assaultbox")
		local image
		if status then
			image = "guis/textures/pd2/hud_icon_padlockbox"
		else
			image = "guis/textures/pd2/hud_icon_assaultbox"
		end
		if icon_assaultbox and image then
			icon_assaultbox:set_image(image)
		end
	end

	if HIDE_CASING_MODE_PANEL then
		function HUDAssaultCorner:show_casing() return end
		function HUDAssaultCorner:hide_casing() return end
	end
elseif string.lower(RequiredScript) == "lib/managers/hudmanagerpd2" then
	local feed_heist_time_original = HUDManager.feed_heist_time
	local show_casing_original = HUDManager.show_casing
	local hide_casing_original = HUDManager.hide_casing
	local sync_start_assault_original = HUDManager.sync_start_assault
	local sync_end_assault_original = HUDManager.sync_end_assault
	local show_point_of_no_return_timer_original = HUDManager.show_point_of_no_return_timer
	local hide_point_of_no_return_timer_original = HUDManager.hide_point_of_no_return_timer
	local _create_downed_hud_original = HUDManager._create_downed_hud
	local _create_custody_hud_original = HUDManager._create_custody_hud
	
	local mui_fix = VHUDPlus:getSetting({"AssaultBanner", "MUI_ASSAULT_FIX"}, false)
	local enhanced_obj = VHUDPlus:getSetting({"CustomHUD", "ENABLED_ENHANCED_OBJECTIVE"}, false)
	local center_assault = VHUDPlus:getSetting({"AssaultBanner", "USE_CENTER_ASSAULT"}, true)
	
	function HUDManager:_locked_assault(status)
		status = Network:is_server() and (managers.groupai:state():get_hunt_mode() or false) or status
		self._assault_locked = self._assault_locked or false
		if self._assault_locked ~= status then
			if self._hud_assault_corner then
				self._hud_assault_corner:locked_assault(status)
			end
			self._assault_locked = status
		end
		return self._assault_locked
	end
	
	function HUDManager:show_casing(...)
		if enhanced_obj and not mui_fix then
			self._hud_heist_timer._heist_timer_panel:set_visible(true)
		elseif not center_assault and not mui_fix then
			self._hud_heist_timer._heist_timer_panel:set_visible(true)
		elseif not enhanced_obj and not mui_fix then
			self._hud_heist_timer._heist_timer_panel:set_visible(false)
		end
		if self:alive("guis/mask_off_hud") and center_assault then
			self:script("guis/mask_off_hud").mask_on_text:set_y(50)
		end
		show_casing_original(self, ...)
	end

	function HUDManager:hide_casing(...)
		hide_casing_original(self, ...)
		if not mui_fix and not enhanced_obj then
			self._hud_heist_timer._heist_timer_panel:set_visible(true)
		end
	end
	
	function HUDManager:sync_start_assault(...)
		if enhanced_obj and not mui_fix then
			self._hud_heist_timer._heist_timer_panel:set_visible(true)
		elseif not center_assault and not mui_fix then
			self._hud_heist_timer._heist_timer_panel:set_visible(true)
		elseif not enhanced_obj and not mui_fix then
			self._hud_heist_timer._heist_timer_panel:set_visible(false)
		end
		managers.groupai:state()._wave_counter = (managers.groupai:state()._wave_counter or 0) + 1
		sync_start_assault_original(self, ...)
	end

	function HUDManager:sync_end_assault(...)
		sync_end_assault_original(self, ...)
		if not mui_fix then
			self._hud_heist_timer._heist_timer_panel:set_visible(true)
		end
	end

	function HUDManager:show_point_of_no_return_timer(...)
		if enhanced_obj and not mui_fix then
			self._hud_heist_timer._heist_timer_panel:set_visible(true)
		elseif not center_assault and not mui_fix then
			self._hud_heist_timer._heist_timer_panel:set_visible(true)
		elseif not enhanced_obj and not mui_fix then
			self._hud_heist_timer._heist_timer_panel:set_visible(false)
		end
		show_point_of_no_return_timer_original(self, ...)
	end

	function HUDManager:hide_point_of_no_return_timer(...)
		hide_point_of_no_return_timer_original(self, ...)
		if not mui_fix then
			self._hud_heist_timer._heist_timer_panel:set_visible(false )
		end
	end

	function HUDManager:feed_heist_time(t, ...)

		if self._hud_assault_corner then
			self._hud_assault_corner:feed_heist_time(t)
		end
		feed_heist_time_original(self, t, ...)
	end
	
	function HUDManager:_create_downed_hud(...)
		_create_downed_hud_original(self, ...)
		if VHUDPlus:getSetting({"AssaultBanner", "USE_CENTER_ASSAULT"}, true) and self._hud_player_downed then
			local downed_panel = self._hud_player_downed._hud_panel
			local downed_hud = self._hud_player_downed._hud
			local timer_msg = downed_panel and downed_panel:child("downed_panel"):child("timer_msg")
			local timer = downed_hud and downed_hud.timer
			if timer_msg and timer then
				timer_msg:set_y(65)
				timer:set_y(math.round(timer_msg:bottom() - 6))
			end
		end
	end
	
	function HUDManager:_create_custody_hud(...)
		_create_custody_hud_original(self, ...)
		if VHUDPlus:getSetting({"AssaultBanner", "USE_CENTER_ASSAULT"}, true) and self._hud_player_custody then
			local custody_panel = self._hud_player_custody._hud_panel
			local timer_msg = custody_panel and custody_panel:child("custody_panel") and custody_panel:child("custody_panel"):child("timer_msg")
			local timer = self._hud_player_custody._timer
			if timer_msg and timer then
				timer_msg:set_y(65)
				timer:set_y(math.round(timer_msg:bottom() - 6))
			end
		end
	end
elseif string.lower(RequiredScript) == "lib/managers/localizationmanager" then
	local text_original = LocalizationManager.text

	function LocalizationManager:text(string_id, ...)
		if string_id == "hud_adv_assault" or string_id == "hud_assault_alpha" or string_id == "NepgearsyHUDReborn/HUD/AssaultCorner/Coming" then
			return self:hud_adv_assault()
		end
		return text_original(self, string_id, ...)
	end

	function LocalizationManager:hud_adv_assault()
		
		if VHUDPlus:getSetting({"AssaultBanner", "USE_ADV_ASSAULT"}, true) then
			if managers.hud and managers.hud:_locked_assault() then
				return self:text("wolfhud_locked_assault")
			else
				local tweak = tweak_data.group_ai.besiege.assault
				local gai_state = managers.groupai:state()
				local assault_data = Network:is_server() and gai_state and gai_state._task_data.assault
				if tweak and gai_state and assault_data and assault_data.active then
					local get_value = gai_state._get_difficulty_dependent_value or function() return 0 end
					local get_mult = gai_state._get_balancing_multiplier or function() return 0 end
					local phase = self:text("wolfhud_advassault_phase_title") .. "  " .. self:text("wolfhud_advassault_phase_" .. assault_data.phase)

					local spawns = get_value(gai_state, tweak.force_pool) * get_mult(gai_state, tweak.force_pool_balance_mul)
					local spawns_left = self:text("wolfhud_advassault_spawns_title") .. "  " .. math.round(math.max(spawns - assault_data.force_spawned, 0))

					local time_left = assault_data.phase_end_t - gai_state._t --+ 350
					if assault_data.phase == "build" then
						local sustain_duration = math.lerp(get_value(gai_state, tweak.sustain_duration_min), get_value(gai_state, tweak.sustain_duration_max), 0.5) * get_mult(gai_state, tweak.sustain_duration_balance_mul)
						time_left = time_left + sustain_duration + tweak.fade_duration
					elseif assault_data.phase == "sustain" then
						time_left = time_left + tweak.fade_duration
					end
					--if gai_state:_count_police_force("assault") > 7 then -- 350 = additional duration, if more than 7 assault groups are active (hardcoded values in gai_state).
					--	time_left = time_left + 350
					--end
					if time_left < 0 then
						time_left = self:text("wolfhud_advassault_time_overdue")
					else
						time_left = self:text("wolfhud_advassault_time_title") .. "  " .. string.format("%.2f", time_left)
					end

					local spacer = string.rep(" ", 10)
					local sep = string.format("%s%s%s", spacer, self:text("hud_assault_end_line"), spacer)
					return string.format("%s%s%s%s%s", phase, sep, spawns_left, sep, time_left)
				end
			end
		end
		return self:text("hud_assault_assault")
	end
end
