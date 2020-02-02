if string.lower(RequiredScript) == "lib/managers/hudmanagerpd2" then
	local set_teammate_ammo_amount_orig = HUDManager.set_teammate_ammo_amount
	local set_slot_ready_orig = HUDManager.set_slot_ready

	function HUDManager:set_teammate_ammo_amount(id, selection_index, max_clip, current_clip, current_left, max, ...)
		if VHUDPlus:getSetting({"CustomHUD", "USE_REAL_AMMO"}, true) then
			local total_left = current_left - current_clip
			if total_left >= 0 then
				current_left = total_left
				max = max - current_clip
			end
		end
		return set_teammate_ammo_amount_orig(self, id, selection_index, max_clip, current_clip, current_left, max, ...)
	end

	local FORCE_READY_CLICKS = 3
	local FORCE_READY_TIME = 2
	local FORCE_READY_ACTIVE_T = 90

	local force_ready_start_t = 0
	local force_ready_clicked = 0

	function HUDManager:set_slot_ready(peer, peer_id, ...)
		set_slot_ready_orig(self, peer, peer_id, ...)

		if Network:is_server() and not Global.game_settings.single_player then
			local session = managers.network and managers.network:session()
			local local_peer = session and session:local_peer()
			local time_elapsed = managers.game_play_central and managers.game_play_central:get_heist_timer() or 0
			if local_peer and local_peer:id() == peer_id then
				local t = Application:time()
				if (force_ready_start_t + FORCE_READY_TIME) > t then
					force_ready_clicked = force_ready_clicked + 1
					if force_ready_clicked >= FORCE_READY_CLICKS then
						local enough_wait_time = (time_elapsed > FORCE_READY_ACTIVE_T)
						local friends_list = not enough_wait_time and Steam:logged_on() and Steam:friends() or {}
						local abort = false
						for _, peer in ipairs(session:peers()) do
							local is_friend = false
							for _, friend in ipairs(friends_list) do
								if friend:id() == peer:user_id() then
									is_friend = true
									break
								end
							end
							if not (enough_wait_time or is_friend) or not (peer:synced() or peer:id() == local_peer:id()) then
								abort = true
								break
							end
						end
						if game_state_machine and not abort then
							local menu_options = {
								[1] = {
									text = managers.localization:text("dialog_yes"),
									callback = function(self, item)
										managers.chat:send_message(ChatManager.GAME, local_peer, "The Game was forced to start.")
										game_state_machine:current_state():start_game_intro()
									end,
								},
								[2] = {
									text = managers.localization:text("dialog_no"),
									is_cancel_button = true,
								}
							}
							QuickMenu:new( managers.localization:text("wolfhud_dialog_force_start_title"), managers.localization:text("wolfhud_dialog_force_start_desc"), menu_options, true )
						end
					end
				else
					force_ready_clicked = 1
					force_ready_start_t = t
				end
			end
		end
	end

	local previous_value = 0

	Hooks:PostHook( HUDManager , "update" , "HUDManagerUpdateBangFix" , function( self, t, dt, ... )
		if VHUDPlus:getSetting({"CustomHUD", "ENABLE_IFBG"}, true) then
			local managers = _G.managers
			if managers.environment_controller == nil then
				return
			end

			local alive = _G.alive
			local math = _G.math
			local max = math.max
			local alpha = managers.environment_controller._current_flashbang
			if alpha == 0 and alpha == previous_value then
				-- Optimization: Don't execute the following code when no flashbang is active (previous_value allows the code to be
				-- executed at least once when alpha is 0, otherwise it would never be run)
				return
			end
			previous_value = alpha
			alpha = 1 - math.clamp(alpha, 0, 1)
			-- 	-- Waypoints
			for id, data in pairs(self._hud.waypoints) do
				if alive(data.bitmap) then
					-- Critical state waypoint textures have thin black borders around them that make them somewhat visible with
					-- normal flashbang glare, simulate this by clamping the minimum alpha to 0.1 so it remains visible
					if data.init_data.icon == "wp_revive" or data.init_data.icon == "wp_rescue" then
						data.bitmap:set_alpha(max(0.1, alpha))
					else
						data.bitmap:set_alpha(alpha)
					end
				end
				if alive(data.arrow) then
					-- There is no need to worry about HUDManager:add_waypoint() using a default color of Color.white:with_alpha(0.75)
					-- since setting the bitmap's alpha will cause it to scale the color's alpha value accordingly (i.e. when the
					-- bitmap's alpha is set to 1, the color's alpha will correctly return to 0.75)
					data.arrow:set_alpha(alpha)
				end
				if alive(data.distance) then
					data.distance:set_alpha(alpha)
				end
				if alive(data.text) then
					data.text:set_alpha(alpha)
				end
				if alive(data.timer_gui) then
					data.timer_gui:set_alpha(alpha)
				end
			end

			-- Interaction hints
			local hud_interaction = self._hud_interaction
			if hud_interaction ~= nil then
				local hud_panel = hud_interaction._hud_panel
				if alive(hud_panel) then
					if hud_interaction._child_name_text then
						local panel = hud_panel:child(hud_interaction._child_name_text)
						if alive(panel) then
							panel:set_alpha(alpha)
						end
					end
					if hud_interaction._child_ivalid_name_text then
						local panel = hud_panel:child(hud_interaction._child_ivalid_name_text)
						if alive(panel) then
							panel:set_alpha(alpha)
						end
					end
				end
				if hud_interaction._interact_circle ~= nil and hud_interaction._interact_circle.set_alpha ~= nil then
					hud_interaction._interact_circle:set_alpha(max(0.1, alpha))
				end
			end
		end
	end)
elseif string.lower(RequiredScript) == "core/lib/managers/coreenvironmentcontrollermanager" then
	local ids_dof_settings = Idstring("settings")
	local ids_radial_offset = Idstring("radial_offset")
	local ids_hdr_post_processor = Idstring("hdr_post_processor")
	local ids_hdr_post_composite = Idstring("post_DOF")
	local mvec1 = Vector3()
	local ids_LUT_post = Idstring("color_grading_post")
	local ids_LUT_settings = Idstring("lut_settings")
	local ids_LUT_settings_a = Idstring("LUT_settings_a")
	local ids_LUT_settings_b = Idstring("LUT_settings_b")
	local ids_LUT_contrast = Idstring("contrast")

	local set_post_composite_actual = CoreEnvironmentControllerManager.set_post_composite
	function CoreEnvironmentControllerManager:set_post_composite(t, dt)
		if VHUDPlus:getSetting({"CustomHUD", "ENABLE_IFBG"}, true) then
			local vp = managers.viewport:first_active_viewport()
			if not vp then
				return
			end
			if self._occ_dirty then
				self._occ_dirty = false
				self:_refresh_occ_params(vp)
			end
			if self._fov_ratio_dirty then
				self:_refresh_fov_ratio_params(vp)
				self._fov_ratio_dirty = false
			end
			if self._vp ~= vp then
				local hdr_post_processor = vp:vp():get_post_processor_effect("World", ids_hdr_post_processor)
				if hdr_post_processor then
					local post_composite = hdr_post_processor:modifier(ids_hdr_post_composite)
					if not post_composite then
						return
					end
					self._material = post_composite:material()
					if not self._material then
						return
					end
					self._vp = vp
					self:_update_post_effects()
				end
			end
			local camera = vp:camera()
			local color_tweak = mvec1
			if camera then
			end
			if self._old_vp ~= vp then
				self._occ_dirty = true
				self._fov_ratio_dirty = true
				self:refresh_render_settings()
				self._old_vp = vp
			end
			local blur_zone_val = 0
			blur_zone_val = self:_blurzones_update(t, dt, camera:position())
			if 0 < self._hit_some then
				local hit_fade = dt * 1.5
				self._hit_some = math.max(self._hit_some - hit_fade, 0)
				self._hit_right = math.max(self._hit_right - hit_fade, 0)
				self._hit_left = math.max(self._hit_left - hit_fade, 0)
				self._hit_up = math.max(self._hit_up - hit_fade, 0)
				self._hit_down = math.max(self._hit_down - hit_fade, 0)
				self._hit_front = math.max(self._hit_front - hit_fade, 0)
				self._hit_back = math.max(self._hit_back - hit_fade, 0)
			end
			local flashbang = 0
			local flashbang_flash = 0
			
			if 0 < self._current_flashbang then
				local flsh = self._current_flashbang
				self._current_flashbang = math.max(self._current_flashbang - dt * 0.08 * self._flashbang_multiplier * self._flashbang_duration, 0)
				flashbang = math.min(self._current_flashbang, 1)
				self._current_flashbang_flash = math.max(self._current_flashbang_flash - dt * 0.9, 0)
				flashbang_flash = math.min(self._current_flashbang_flash, 1)
			end
			local hit_some_mod = 1 - self._hit_some
			hit_some_mod = hit_some_mod * hit_some_mod * hit_some_mod
			hit_some_mod = 1 - hit_some_mod
			local downed_value = self._downed_value / 100
			local death_mod = math.max(1 - self._health_effect_value - 0.5, 0) * 2
			local blur_zone_flashbang = blur_zone_val + flashbang
			local flash_1 = math.pow(flashbang, 0.4)
			local flash_2 = math.pow(flashbang, 16) + flashbang_flash
			if self._custom_dof_settings then
				self._material:set_variable(ids_dof_settings, self._custom_dof_settings)
			elseif flash_1 > 0 then
				self._material:set_variable(ids_dof_settings, Vector3(math.min(self._hit_some * 10, 1) + blur_zone_flashbang * 0.4, math.min(blur_zone_val + downed_value * 2 + flash_1, 1), 10 + math.abs(math.sin(t * 10) * 40) + downed_value * 3))
			else
				self._material:set_variable(ids_dof_settings, Vector3(math.min(self._hit_some * 10, 1) + blur_zone_flashbang * 0.4, math.min(blur_zone_val + downed_value * 2, 1), 1 + downed_value * 3))
			end
			self._material:set_variable(ids_radial_offset, Vector3((self._hit_left - self._hit_right) * 0.2, (self._hit_up - self._hit_down) * 0.2, self._hit_front - self._hit_back + blur_zone_flashbang * 0.1))
			self._material:set_variable(Idstring("contrast"), self._base_contrast + self._hit_some * 0.25)
			self._material:set_variable(Idstring("chromatic_amount"), self._base_chromatic_amount + blur_zone_val * 0.3 + flash_1 * 0.5)
			self:_update_dof(t, dt)
			local lut_post = vp:vp():get_post_processor_effect("World", ids_LUT_post)
			if lut_post then
				local lut_modifier = lut_post:modifier(ids_LUT_settings)
				if lut_modifier then
				else
					return
				end
				self._lut_modifier_material = lut_modifier:material()
				if not self._lut_modifier_material then
					return
				end
			end
			local hurt_mod = 1 - self._health_effect_value
			local health_diff = math.clamp((self._old_health_effect_value - self._health_effect_value) * 4, 0, 1)
			self._old_health_effect_value = self._health_effect_value
			if health_diff > self._health_effect_value_diff then
				self._health_effect_value_diff = health_diff
			end
			self._health_effect_value_diff = math.max(self._health_effect_value_diff - dt * 0.5, 0)
			self._lut_modifier_material:set_variable(ids_LUT_settings_a, Vector3(math.clamp(self._health_effect_value_diff * 1.3 * (1 + hurt_mod * 1.3), 0, 1.2), 0, math.min(blur_zone_val + self._HE_blinding, 1)))
			local last_life = 0
			if self._last_life then
				last_life = math.clamp((hurt_mod - 0.5) * 2, 0, 1)
			end
			-- BEGIN MOD --
			local result = flash_2 + math.clamp(hit_some_mod * 2, 0, 1) * 0.25 + blur_zone_val * 0.15 - 0.22
			if result < 0 then
				result = 0
			end
			self._lut_modifier_material:set_variable(ids_LUT_settings_b, Vector3(last_life, result * -1, 0))
			-- END MOD --
			self._lut_modifier_material:set_variable(ids_LUT_contrast, flashbang * 0.5)
		else
			return set_post_composite_actual(self, t, dt)
		end
	end
elseif string.lower(RequiredScript) == "lib/managers/hud/hudhitconfirm" then
	local old_init = HUDHitConfirm.init
	function HUDHitConfirm:init(...)
		old_init(self, ...)
		local size = 24
		local red = (80)/100
		local green = (20)/100
		local blue = (20)/100
		local new_color = Color(red, green, blue)
		if self._hud_panel:child("headshot_confirm") then
			self._hud_panel:remove(self._hud_panel:child("headshot_confirm"))
		end
		self._headshot_confirm = self._hud_panel:bitmap({
			valign = "center",
			halign = "center",
			visible = false,
			name = "headshot_confirm",
			texture = "guis/textures/pd2/hud_progress_active",
			color = new_color,
			layer = 1,
			h = size,
			w = size,
			blend_mode = "normal"
		})
		self._headshot_confirm:set_center(self._hud_panel:w() / 2, self._hud_panel:h() / 2)
	end
	function HUDHitConfirm:on_headshot_confirmed()
	if VHUDPlus:getSetting({"CustomHUD", "HEADSHOT"}, true) then
		self._headshot_confirm:stop()
		self._headshot_confirm:animate(callback(self, self, "_animate_show"), callback(self, self, "show_done"), 0.25)
	end
	end
	
elseif string.lower(RequiredScript) == "lib/managers/playermanager" then
	local old_ohd = PlayerManager.on_headshot_dealt
	function PlayerManager:on_headshot_dealt(...)
		managers.hud:on_headshot_confirmed()
		return old_ohd(self, ...)
	end
elseif string.lower(RequiredScript) == "lib/tweak_data/timespeedeffecttweakdata" then
	local init_original = TimeSpeedEffectTweakData.init
	local FORCE_ENABLE = {
		mission_effects = true,
	}
	function TimeSpeedEffectTweakData:init(...)
		init_original(self, ...)
		if VHUDPlus:getSetting({"SkipIt", "NO_SLOWMOTION"}, true) then
			local function disable_effect(table)
				for name, data in pairs(table) do
					if not FORCE_ENABLE[name] then
						if data.speed and data.sustain then
							data.speed = 1
							data.fade_in_delay = 0
							data.fade_in = 0
							data.sustain = 0
							data.fade_out = 0
						elseif type(data) == "table" then
							disable_effect(data)
						end
					end
				end
			end

			disable_effect(self)
		end
	end
elseif string.lower(RequiredScript) == "lib/managers/experiencemanager" then
	local cash_string_original = ExperienceManager.cash_string

	function ExperienceManager:cash_string(...)
		local val = cash_string_original(self, ...)
		if self._cash_sign ~= "$" and val:find(self._cash_sign) then
			val = val:gsub(self._cash_sign, "") .. self._cash_sign
		end
		return val
	end
elseif string.lower(RequiredScript) == "lib/managers/moneymanager" then
	function MoneyManager:total_string()
		local total = math.round(self:total())
		return managers.experience:cash_string(total)
	end
	function MoneyManager:total_collected_string()
		local total = math.round(self:total_collected())
		return managers.experience:cash_string(total)
	end
elseif string.lower(RequiredScript) == "lib/units/weapons/raycastweaponbase" then

    local init_original = RaycastWeaponBase.init
    local setup_original = RaycastWeaponBase.setup

    function RaycastWeaponBase:init(...)
	    init_original(self, ...)
	    self._bullet_slotmask = self._bullet_slotmask - World:make_slot_mask(16)
    end

    function RaycastWeaponBase:setup(...)
	    setup_original(self, ...)
	    self._bullet_slotmask = self._bullet_slotmask - World:make_slot_mask(16)
    end
elseif string.lower(RequiredScript) == "lib/units/contourext" then
	local add_original = ContourExt.add
    if VHUDPlus:getSetting({"CustomHUD", "JOKER_CONTOUR"}, true) then
	    function ContourExt:add(type, ...)
		    local result = add_original(self, type, ...)
		    local default_friendly_color = ContourExt._types.friendly.color
		    ContourExt._types.friendly.color = nil
		
		    if result and type == "friendly" then
			    self:change_color("friendly", default_friendly_color)
		    end
		
		    local function joker_event(event, key, data)
			    if data.owner then
				    managers.gameinfo:add_scheduled_callback(key .. "_joker_contour", 0.01, function()
					    if alive(data.unit) and data.unit:contour() then
						    data.unit:contour():change_color("friendly", tweak_data.chat_colors[data.owner] or default_friendly_color)
					    end
				    end)
			    end
		    end
		    managers.gameinfo:register_listener("joker_contour_listener", "minion", "set_owner", joker_event)
		    return result
	    end
	end
elseif string.lower(RequiredScript) == "lib/units/contourext" then
	local add_original = ContourExt.add

	function ContourExt:add(type, ...)
		local result = add_original(self, type, ...)
		local default_friendly_color = ContourExt._types.friendly.color
		ContourExt._types.friendly.color = nil
		
		if result and type == "friendly" then
			self:change_color("friendly", default_friendly_color)
		end
		
		local function joker_event(event, key, data)
			if data.owner then
				managers.gameinfo:add_scheduled_callback(key .. "_joker_contour", 0.01, function()
					if alive(data.unit) and data.unit:contour() then
						data.unit:contour():change_color("friendly", tweak_data.chat_colors[data.owner] or default_friendly_color)
					end
				end)
			end
		end
		managers.gameinfo:register_listener("joker_contour_listener", "minion", "set_owner", joker_event)
		return result
	end	
elseif string.lower(RequiredScript) == "lib/managers/objectinteractionmanager" then
	local init_original = ObjectInteractionManager.init

	function ObjectInteractionManager:init(...)
		init_original(self, ...)
		if managers.gameinfo and VHUDPlus:getSetting({"HUDSuspicion", "REMOVE_ANSWERED_PAGER_CONTOUR"}, true) then
			managers.gameinfo:register_listener("pager_contour_remover", "pager", "set_answered", callback(nil, _G, "pager_answered_clbk"))
		end
	end

	function pager_answered_clbk(event, key, data)
		managers.enemy:add_delayed_clbk("contour_remove_" .. key, callback(nil, _G, "remove_answered_pager_contour_clbk", data.unit), Application:time() + 0.01)
	end

	function remove_answered_pager_contour_clbk(unit)
		if alive(unit) then
			unit:contour():remove(tweak_data.interaction.corpse_alarm_pager.contour_preset)
		end
	end

elseif string.lower(RequiredScript) == "lib/managers/hud/hudassaultcorner" then
	local HUDAssaultCorner_init = HUDAssaultCorner.init
	function HUDAssaultCorner:init(...)
		HUDAssaultCorner_init(self, ...)
		local hostages_panel = self._hud_panel:child("hostages_panel")
		if alive(hostages_panel) and VHUDPlus:getSetting({"HUDList", "ENABLED"}, true) then
			hostages_panel:set_alpha(0)
		end
	end
end
