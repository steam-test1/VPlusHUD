if _G.IS_VR then
	return
end
if VHUDPlus:getSetting({"CustomHUD", "HUDTYPE"}, 2) == 2 then

	if RequiredScript == "lib/managers/hudmanagerpd2" then

		local set_stamina_value_original = HUDManager.set_stamina_value
		local set_max_stamina_original = HUDManager.set_max_stamina
		local teammate_progress_original = HUDManager.teammate_progress
		local feed_heist_time_original = HUDManager.feed_heist_time
		local set_player_condition_original = HUDManager.set_player_condition
		local set_mugshot_custody_original = HUDManager.set_mugshot_custody
		local set_mugshot_normal_original = HUDManager.set_mugshot_normal
		local update_original = HUDManager.update

		function HUDManager:set_stamina_value(value, ...)
			if self._teammate_panels[self.PLAYER_PANEL].set_current_stamina then
				self._teammate_panels[self.PLAYER_PANEL]:set_current_stamina(value)
			end
			return set_stamina_value_original(self, value, ...)
		end

		function HUDManager:set_max_stamina(value, ...)
			if self._teammate_panels[self.PLAYER_PANEL].set_max_stamina then
				self._teammate_panels[self.PLAYER_PANEL]:set_max_stamina(value)
			end
			return set_max_stamina_original(self, value, ...)
		end

		function HUDManager:teammate_progress(peer_id, type_index, enabled, tweak_data_id, timer, success, ...)
			teammate_progress_original(self, peer_id, type_index, enabled, tweak_data_id, timer, success, ...)
			local character_data = managers.criminals:character_data_by_peer_id(peer_id)
			if character_data then
				local teammate_panel = self._teammate_panels[character_data.panel_id]
				local name_label = self:_name_label_by_peer_id(peer_id)
				if name_label then
					teammate_panel:set_interact_text(name_label.panel:child("action"):text())
				end
				teammate_panel:set_interact_visibility(enabled and timer and VHUDPlus:getSetting({"CustomHUD", "TEAMMATE", "INTERACTION", "MIN_DURATION"}, 1) <= timer and not VHUDPlus:getSetting({"CustomHUD", "TEAMMATE", "INTERACTION", "HIDE"}, false) and VHUDPlus:getSetting({"CustomHUD", "TEAMMATE", "INTERACTION", "TEXT"}, true))
			end
		end
		
		function HUDManager:update_armor_timer(...)
			self._teammate_panels[self.PLAYER_PANEL]:update_armor_timer(...)
		end
		
		function HUDManager:update_inspire_timer(...)
			self._teammate_panels[self.PLAYER_PANEL]:update_inspire_timer(...)
		end
		
		function HUDManager:show_underdog()
			if not VHUDPlus:getSetting({"CustomHUD", "PLAYER", "UNDERDOG"}, true) then
				self._teammate_panels[ self.PLAYER_PANEL ]:hide_underdog()
				return
			end

			self._teammate_panels[ self.PLAYER_PANEL ]:show_underdog()

		end

		function HUDManager:hide_underdog()

			self._teammate_panels[ self.PLAYER_PANEL ]:hide_underdog()

		end
		
		function HUDManager:change_health(...)
			self._teammate_panels[self.PLAYER_PANEL]:change_health(...)
		end
		
		function HUDManager:feed_heist_time(t, ...)
			
			feed_heist_time_original(self, t, ...)
			self._teammate_panels[self.PLAYER_PANEL]:change_health(0) -- force refresh hps meter atleast every second.
		end
		
		function HUDManager:_mugshot_id_to_panel_id(id)
			for _, data in pairs(managers.criminals:characters()) do
				if data.data.mugshot_id == id then
					return data.data.panel_id
				end
			end
		end
		
		function HUDManager:set_mugshot_custody(id)
			local panel_id = self:_mugshot_id_to_panel_id(id)
			if panel_id then
				self._teammate_panels[panel_id]:set_player_in_custody(true)
			end
			return set_mugshot_custody_original(self, id)
		end

		function HUDManager:set_mugshot_normal(id)
			local panel_id = self:_mugshot_id_to_panel_id(id)
			if panel_id then
				self._teammate_panels[panel_id]:set_player_in_custody(false)
			end
			return set_mugshot_normal_original(self, id)
		end
		
		function HUDManager:set_player_condition(icon_data, text)
			set_player_condition_original(self, icon_data, text)
			if icon_data == "mugshot_in_custody" then
				self._teammate_panels[self.PLAYER_PANEL]:set_player_in_custody(true)
			elseif icon_data == "mugshot_normal" then
				self._teammate_panels[self.PLAYER_PANEL]:set_player_in_custody(false)
			end
		end
		
		function HUDManager:set_mugshot_voice(id, active)
			local panel_id = self:_mugshot_id_to_panel_id(id)
			if panel_id and panel_id ~= self.PLAYER_PANEL then
				self._teammate_panels[panel_id]:set_voice_com(active)
			end
		end

		function HUDManager:set_bulletstorm( state )
			self._teammate_panels[ self.PLAYER_PANEL ]:_set_bulletstorm( state )
		end

		function HUDManager:update(...)
			for i, panel in ipairs(self._teammate_panels) do
				panel:update(...)
			end

			return update_original(self, ...)
		end

		function HUDManager:_update_temporary_upgrades()
			local underactivated = managers.player:has_activate_temporary_upgrade("temporary", "dmg_dampener_outnumbered")
			if underactivated == true then
				managers.hud:show_underdog()
			else
				managers.hud:hide_underdog()
			end
			
			if not underactivated then
				self:remove_updator("_update_temporary_upgrades")
				self._temp_upgrades_updator_active = false
			end
		end

		function HUDManager:activate_temp_upgrades_updator()
			if not self._temp_upgrades_updator_active then
				self._temp_upgrades_updator_active = true
				self:add_updator("_update_temporary_upgrades", callback(self, self, "_update_temporary_upgrades"))
			end
		end

	elseif RequiredScript == "lib/managers/hud/hudteammate" then

		local init_original = HUDTeammate.init
		local set_name_original = HUDTeammate.set_name
		local set_condition_original = HUDTeammate.set_condition
		local teammate_progress_original = HUDTeammate.teammate_progress

		function HUDTeammate:init(...)
			init_original(self, ...)

			self._setting_prefix = self._main_player and "PLAYER" or "TEAMMATE"
			self._max_name_panel_width = self._panel:w()

			self._next_latency_update_t = 0

			self._condition_icon = self._panel:child("condition_icon")
			self._condition_icon:set_color(VHUDPlus:getColorSetting({"CustomHUD", self._setting_prefix, "CONDITION_ICON_COLOR"}, "white"))

			if self._main_player then
				self:_create_stamina_circle()
				self:_init_armor_timer()
				self:_init_inspire_timer()
				self:_init_hps_meter()
				self:inject_health_glow()
				self:inject_ammo_glow()
				-- self:_init_hp_ap_num()
			else
				-- self:_init_hp_ap_num()
				self:_init_interact_info()
				self:_create_ping_info()
			end

			self._panel:child("name_bg"):set_visible(false)
			self._cable_ties_panel:child("bg"):set_visible(false)
			self._deployable_equipment_panel:child("bg"):set_visible(false)
			self._grenades_panel:child("bg"):set_visible(false)
			self._player_panel:child("weapons_panel"):child("primary_weapon_panel"):child("bg"):set_visible(false)
			self._player_panel:child("weapons_panel"):child("secondary_weapon_panel"):child("bg"):set_visible(false)
		end

		function HUDTeammate:set_name(name, ...)
			if not self._ai then
				if VHUDPlus:getSetting({"CustomHUD", self._setting_prefix, "TRUNCATE_TAGS"}, true) then
					name = VHUDPlus:truncateNameTag(name)
				end
				if VHUDPlus:getSetting({"CustomHUD", self._setting_prefix, "RANK"}, true) then
					local peer = self:peer_id() and managers.network:session():peer(self:peer_id())
					local infamy, level = peer and peer:rank() or managers.experience:current_rank(), peer and peer:level() or managers.experience:current_level()
					local level_str = string.format("%s%s ",
						(infamy or 0) > 0 and string.format("%s-", managers.experience:rank_string(infamy)) or "",
						tostring(level)
					)
					name = level_str .. name
					self._color_pos = level_str:len()
				end
			end
			set_name_original(self, name,...)
			self:_truncate_name()
		end

		function HUDTeammate:_truncate_name()
			local name_panel = self._panel:child("name")
			local name_bg_panel = self._panel:child("name_bg")
			local teammate_name = name_panel:text()
			name_panel:set_vertical("center")
			name_panel:set_font_size(tweak_data.hud_players.name_size)
			if not VHUDPlus:getSetting({"CustomHUD", self._setting_prefix, "KILLCOUNTER", "HIDE"}, false) or not self._ai then
			name_panel:set_w(self._panel:w() - name_panel:x())
			end
			local _,_,w,h = name_panel:text_rect()
			while (name_panel:x() + w) > self._max_name_panel_width do
				if name_panel:font_size() > 15.1 then
					name_panel:set_font_size(name_panel:font_size() - 0.1)
				else
					name_panel:set_text(teammate_name:sub(1, teammate_name:len() - 1))
				end
				teammate_name = name_panel:text()
				_,_,w,h = name_panel:text_rect()
			end
			if not self._ai then
				name_panel:set_range_color((self._color_pos or 0) + 1, name_panel:text():len() + 1, self._panel:child("callsign"):color():with_alpha(1))
			else
				name_panel:set_color(VHUDPlus:getSetting({"CustomHUD", "TEAMMATE", "AI_COLOR", "USE"}, false) and VHUDPlus:getColorSetting({"CustomHUD", "TEAMMATE", "AI_COLOR", "COLOR"}, "white") or tweak_data.chat_colors[5])
			end
			name_bg_panel:set_w(w + 4)
			name_bg_panel:set_h(h + 2)
			name_bg_panel:set_y(name_panel:y() + name_panel:h() / 2 - h / 2 - 1)
		end

		function HUDTeammate:_create_stamina_circle()
			local radial_health_panel = self._panel:child("player"):child("radial_health_panel")
			self._stamina_bar = radial_health_panel:bitmap({
				name = "radial_stamina",
				texture = "guis/textures/pd2/hud_radial_rim",
				render_template = "VertexColorTexturedRadial",
				blend_mode = "add",
				alpha = 1,
				w = radial_health_panel:w() * 0.37,--53,
				h = radial_health_panel:h() * 0.37,--53,
				layer = 2,
				visible = VHUDPlus:getSetting({"CustomHUD", "PLAYER", "STAMINA"}, true)
			})
			self._stamina_bar:set_color(Color(1, 1, 0, 0))
			self._stamina_bar:set_center(radial_health_panel:child("radial_health"):center())

			self._stamina_line = radial_health_panel:rect({
				color = Color.red:with_alpha(0.4),
				w = radial_health_panel:w() * 0.05,
				h = 2,
				layer = 10,
				visible = VHUDPlus:getSetting({"CustomHUD", "PLAYER", "STAMINA"}, true)
			})
			self._stamina_line:set_center(radial_health_panel:child("radial_health"):center())
		end

		function HUDTeammate:set_max_stamina(value)
			if not self._max_stamina or self._max_stamina ~= value then
				self._max_stamina = value
				local w = self._stamina_bar:w()
				local threshold = tweak_data.player.movement_state.stamina.MIN_STAMINA_THRESHOLD
				local angle = 360 * (threshold/self._max_stamina) - 90
				local x = 0.48 * w * math.cos(angle) + w * 0.5 + self._stamina_bar:x()
				local y = 0.48 * w * math.sin(angle) + w * 0.5 + self._stamina_bar:y()
				self._stamina_line:set_x(x)
				self._stamina_line:set_y(y)
				self._stamina_line:set_rotation(angle)
			end
		end

		function HUDTeammate:set_current_stamina(value)
			self._stamina_bar:set_color(Color(1, value/self._max_stamina, 0, 0))
			self:set_stamina_meter_visibility(VHUDPlus:getSetting({"CustomHUD", "PLAYER", "STAMINA"}, true) and not self._condition_icon:visible())
		end

		function HUDTeammate:set_stamina_meter_visibility(value)
			if self._stamina_bar and self._stamina_bar:visible() ~= value then
				self._stamina_bar:set_visible(value)
				self._stamina_line:set_visible(value)
			end
		end

		function HUDTeammate:_init_interact_info()
			self._interact_info_panel = self._panel:panel({
				name = "interact_info_panel",
				x = 0,
				y = 0,
				visible = false
			})
			self._interact_info = self._interact_info_panel:text({
				name = "interact_info",
				text = "|",
				layer = 3,
				color = Color.white,
				x = 0,
				y = 1,
				align = "right",
				vertical = "top",
				font_size = tweak_data.hud_players.name_size,
				font = tweak_data.hud_players.name_font
			})
			local _, _, text_w, text_h = self._interact_info:text_rect()
			self._interact_info:set_right(self._interact_info_panel:w() - 4)
			self._interact_info_bg = self._interact_info_panel:bitmap({
				name = "interact_info_bg",
				texture = "guis/textures/pd2/hud_tabs",
				texture_rect = {
					84,
					0,
					44,
					32
				},
				layer = 2,
				color = Color.white / 3,
				x = 0,
				y = 0,
				align = "left",
				vertical = "bottom",
				w = text_w + 4,
				h = text_h
			})
		end

		function HUDTeammate:set_interact_text(text)
			if alive(self._interact_info) then
				self._interact_info:set_text(text)
				local _, _, w, _ = self._interact_info:text_rect()
				self._interact_info_bg:set_w(w + 8)
				self._interact_info_bg:set_right(self._interact_info:right() + 4)
			end
		end

		function HUDTeammate:set_interact_visibility(visible)
			if self._interact_info_panel then
				self._interact_info_panel:set_visible(visible)
			end
		end

		function HUDTeammate:teammate_progress(enabled, tweak_data_id, timer, success, ...)
			local show = timer and VHUDPlus:getSetting({"CustomHUD", "TEAMMATE", "INTERACTION", "MIN_DURATION"}, 1) <= timer and not VHUDPlus:getSetting({"CustomHUD", "TEAMMATE", "INTERACTION", "HIDE"}, false)
			teammate_progress_original(self, enabled and show, tweak_data_id, timer, success and show, ...)
			if enabled and show and VHUDPlus:getSetting({"CustomHUD", "TEAMMATE", "INTERACTION", "NUMBER"}, true) then
				self:_start_interact_timer(timer)
			else
				self:_stop_interact_timer()
			end
		end

		function HUDTeammate:_start_interact_timer(interaction_time)
			local condition_timer = self._panel:child("condition_timer")
			condition_timer:stop()
			condition_timer:animate(callback(self, self, "_animate_interact_timer"), interaction_time)
		end

		function HUDTeammate:_animate_interact_timer(condition_timer, total_time)
			condition_timer:set_font_size(tweak_data.hud_players.timer_size)
			condition_timer:set_color(Color.white)
			condition_timer:set_visible(true)

			local t = total_time
			while t >= 0 do
				t = t - coroutine.yield()
				condition_timer:set_text(string.format("%.1fs", t))
				condition_timer:set_color(math.lerp(Color('00FF00'), Color.white, t / total_time))
			end
			condition_timer:set_text(string.format("%.1fs", 0))
			condition_timer:set_color(Color('00FF00'))
		end

		function HUDTeammate:_stop_interact_timer()
			if alive(self._panel) then
				local condition_timer = self._panel:child("condition_timer")
				condition_timer:stop()
				condition_timer:set_visible(false)
			end
		end

		function HUDTeammate:set_condition(icon_data, ...)
			local visible = icon_data ~= "mugshot_normal"
			local vis_down = visible or not VHUDPlus:getSetting({"CustomHUD", self._setting_prefix, "DOWNCOUNTER"}, true) or self._ai
			local vis_detect = visible or not VHUDPlus:getSetting({"CustomHUD", self._setting_prefix, "DETECTIONCOUNTER"}, true) or self._ai
			self:set_stamina_meter_visibility(not visible and VHUDPlus:getSetting({"CustomHUD", "PLAYER", "STAMINA"}, true))
			self:set_armor_timer_visibility(not visible and VHUDPlus:getSetting({"CustomHUD", "PLAYER", "ARMOR"}, true))
			self:set_inspire_timer_visibility(not visible and VHUDPlus:getSetting({"CustomHUD", "PLAYER", "INSPIRE"}, true))
			
			if HUDManager.DOWNS_COUNTER_PLUGIN and self._downs_counter then
				self._downs_counter:set_visible(not vis_down and not managers.groupai:state():whisper_mode())
			end

			if HUDManager.DETECT_COUNTER_PLUGIN and self._detection_counter then
				self._detection_counter:set_visible(not vis_detect and not self._downs_counter:visible())
			end
			set_condition_original(self, icon_data, ...)
		end
		
		function HUDTeammate:set_player_in_custody(incustody)
			self._is_in_custody = incustody
			
			if incustody then
				self:set_underdog_glow_visibility(false)
			end
		end
		
		function HUDTeammate:_init_armor_timer()
			self._armor_timer = OutlinedText:new(self._player_panel, {
				name = "armor_regen",
				text = "",
				color = Color.white,
				visible = false,
				align = "left",
				vertical = "bottom",
				font = tweak_data.hud_players.name_font,
				font_size = 20,
				layer = 4
			})
			--self._armor_timer:set_outlines_visible(true)
		end
		
		local hide_time_state = {
			["bleed_out"] = true,
			["fatal"] = true,
			["incapacitated"] = true
		}
		
		function HUDTeammate:update_armor_timer(t)
			if t and t > 0 and self._armor_timer and not hide_time_state[managers.player:current_state()] and not managers.player:player_unit():character_damage().swansong then
				t = string.format("%.1f", t) .. "s"
				self._armor_timer:set_text(t)
				self:set_armor_timer_visibility(VHUDPlus:getSetting({"CustomHUD", "PLAYER", "ARMOR"}, true))
			elseif self._armor_timer and self._armor_timer:visible() then
				self:set_armor_timer_visibility(false)
			end
		end
		
		function HUDTeammate:set_armor_timer_visibility(visible)
			if self._armor_timer then
				self._armor_timer:set_visible(visible)
			end
		end

		function HUDTeammate:set_inf_ammo_visibility(visible)
			if self._primary_ammo then
				self._primary_ammo:set_visible(visible)
			end
			if self._secondary_ammo then
				self._secondary_ammo:set_visible(visible)
			end
		end
		
		function HUDTeammate:_init_inspire_timer()
			self._inspire_timer = self._player_panel:text({
				name = "inspire_timer",
				text = "",
				color = Color.white,
				visible = false,
				align = "right",
				vertical = "bottom",
				font = tweak_data.hud_players.name_font,
				font_size = 20,
				layer = 4
			})
			self._inspire_timer:set_right(self._player_panel:child("radial_health_panel"):right() + 5)
			self._inspire_timer_bg = VHUDPlus:OutlineText(self._player_panel, {
				text = "",
				color = Color.black:with_alpha(0.5),
				visible = false,
				align = "right",
				vertical = "bottom",
				font = tweak_data.hud_players.name_font,
				font_size = 20,
				layer = 3
			}, self._inspire_timer)
		end
		
		function HUDTeammate:update_inspire_timer(t)
			if t and t > 0 and self._inspire_timer then
				t = string.format("%.1f", t) .. "s"
				self._inspire_timer:set_text(t)
				for _, bg in ipairs(self._inspire_timer_bg) do
					bg:set_text(t)
				end
				self:set_inspire_timer_visibility(VHUDPlus:getSetting({"CustomHUD", "PLAYER", "INSPIRE"}, true))
			elseif self._inspire_timer and self._inspire_timer:visible() then
				self:set_inspire_timer_visibility(false)
			end
		end
		
		function HUDTeammate:set_inspire_timer_visibility(visible)
			if self._inspire_timer then
				self._inspire_timer:set_visible(visible)
				for _, bg in ipairs(self._inspire_timer_bg) do
					bg:set_visible(visible)
				end
			end
		end
		
		function HUDTeammate:inject_health_glow()
			local radial_health_panel = self._player_panel:child( "radial_health_panel" )
			local underdog_glow = radial_health_panel:bitmap({
				valign 			= "center",
				halign 			= "center",
				w 				= 70,
				h 				= 70,
				--w 				= 50,
				--h 				= 50,				
				name 			= "underdog_glow",
				visible 		= false,
				texture 		= "guis/textures/pd2/hot_cold_glow",
				--texture 		= "guis/textures/pd2/crimenet_marker_glow",
				--texture_rect 	= {
				--					0,
				--					0,
				--					64,
				--					64
				--				},				
				color 			= Color.yellow,
				layer 			= 2,
				blend_mode 		= "add"
			})

			underdog_glow:set_center( radial_health_panel:w() / 2 , radial_health_panel:h() / 2 )
		end


		function HUDTeammate:show_underdog()

			local teammate_panel = self._panel:child( "player" )
			local radial_health_panel = teammate_panel:child( "radial_health_panel" )
			local underdog_glow = radial_health_panel:child( "underdog_glow" )

			if not self._underdog_animation then
				underdog_glow:set_visible( true )
				underdog_glow:animate( callback( self , self , "_animate_glow" ) )

				self._underdog_animation = true
			end

		end

		function HUDTeammate:hide_underdog()

			local teammate_panel = self._panel:child( "player" )
			local radial_health_panel = teammate_panel:child( "radial_health_panel" )
			local underdog_glow = radial_health_panel:child( "underdog_glow" )

			if self._underdog_animation then
				underdog_glow:set_alpha( 0 )
				underdog_glow:set_visible( false )
				underdog_glow:stop()

				self._underdog_animation = nil
			end

		end

		function HUDTeammate:_animate_glow( glow )

			local t = 0

			while true do

				t = t + coroutine.yield()
				glow:set_alpha( ( math.abs( math.sin( ( 4 + t ) * 360 * 4 / 4 ) ) ) )

			end

		end
		
		function HUDTeammate:_init_hps_meter()
			self._hps_meter_panel = self._panel:panel({
				name = "hps_meter_panel",
				x = 0,
				y = 0,
				visible = true
			})
			self._hps_meter = self._hps_meter_panel:text({
				name = "hps_meter",
				text = "|",
				color = Color.white,
				x = 4,
				y = 1,
				visible = false,
				align = "left",
				vertical = "top",
				font = tweak_data.hud_players.name_font,
				font_size = tweak_data.hud_players.name_size,
				layer = 4
			})
			local _, _, text_w, text_h = self._hps_meter:text_rect()
			self._hps_meter_bg = self._hps_meter_panel:bitmap({
				name = "hps_meter_bg",
				texture = "guis/textures/pd2/hud_tabs",
				texture_rect = {
					84,
					0,
					44,
					32
				},
				layer = 2,
				color = Color.white / 3,
				x = 0,
				y = 0,
				align = "left",
				vertical = "bottom",
				w = text_w + 8,
				h = text_h + 2
			})
		end
		
		function HUDTeammate:update_hps_meter(current_hps, total_hps)
			if self._hps_meter then
				if VHUDPlus:getSetting({"CustomHUD", "PLAYER", "HPS_METER"}, true)
						and ((VHUDPlus:getSetting({"CustomHUD", "PLAYER", "SHOW_HPS_CURRENT"}, true) and current_hps and current_hps > 0)
						or (VHUDPlus:getSetting({"CustomHUD", "PLAYER", "SHOW_HPS_TOTAL"}, true) and total_hps and total_hps > 0)) then
					local hps_string = nil
					if VHUDPlus:getSetting({"CustomHUD", "PLAYER", "SHOW_HPS_CURRENT"}, true) then
						hps_string = "hps: " .. (current_hps and current_hps > 0 and string.format("%.2f", current_hps) or "-")
					end
					if VHUDPlus:getSetting({"CustomHUD", "PLAYER", "SHOW_HPS_TOTAL"}, true) then
						hps_string = (hps_string and hps_string .. " / " or "hps: ") .. string.format("%.2f", total_hps or 0)
					end
					self._hps_meter:set_text(hps_string)
					self._hps_meter:set_visible(true)
					self._hps_meter_bg:set_visible(true)
					local _, _, text_w, _ = self._hps_meter:text_rect()
					self._hps_meter_bg:set_w(text_w + 8)
				else
					self._hps_meter:set_visible(false)
					self._hps_meter_bg:set_visible(false)
				end
			end
		end
		
		function HUDTeammate:change_health(change_of_health)
			if managers.player then
				change_of_health = change_of_health or 0
				local time_current = managers.player:player_timer():time()
				local passed_time = time_current - (self._last_time or time_current)
				self._total_hps_time = (self._total_hps_time or 0) + passed_time
				self._total_hps_heal = (self._total_hps_heal or 0) + change_of_health
				self._total_hps = self._total_hps_heal / self._total_hps_time
				if time_current > (self._last_heal_happened or 0) + (VHUDPlus:getSetting({"CustomHUD", "PLAYER", "CURRENT_HPS_TIMEOUT"}, 5) or 5) then
					self._current_hps_heal = nil
					self._current_hps_time = nil
				end
				self._current_hps_time = (self._current_hps_time or 0) + passed_time
				self._current_hps_heal = (self._current_hps_heal or 0) + change_of_health
				self._current_hps = self._current_hps_heal / self._current_hps_time
				self._last_time = time_current
				if change_of_health > 0 then
					self._last_heal_happened = time_current
				end
				if time_current > (self._last_hps_shown or 0) + (VHUDPlus:getSetting({"CustomHUD", "PLAYER", "HPS_REFRESH_RATE"}, 1) or 1) then
					self._last_hps_shown = time_current
					self:update_hps_meter(self._current_hps, self._total_hps)
				end
			end
		end
		
		function HUDTeammate:set_underdog_glow_visibility(visible)
			local teammate_panel = self._panel:child( "player" )
			local radial_health_panel = teammate_panel:child( "radial_health_panel" )
			local underdog_glow = radial_health_panel:child( "underdog_glow" )
			
			if underdog_glow then
				underdog_glow:set_visible(visible and not self._is_in_custody)
			end
		end
		
		function HUDTeammate:set_voice_com(status)
			local texture = status and "guis/textures/pd2/jukebox_playing" or "guis/textures/pd2/hud_tabs"
			local texture_rect = status and { 0, 0, 16, 16 } or { 84, 34, 19, 19 }
			local callsign = self._panel:child("callsign")
			callsign:set_image(texture, unpack(texture_rect))
		end

		function HUDTeammate:inject_ammo_glow()
			self._primary_ammo = self._player_panel:child("weapons_panel"):child("primary_weapon_panel"):bitmap({
				align           = "center",
				w 				= 50,
				h 				= 45,
				name 			= "primary_ammo",
				visible 		= false,
				texture 		= "guis/textures/pd2/crimenet_marker_glow",
				color 			= Color("00AAFF"),
				layer 			= 2,
				blend_mode 		= "add"
			})
			self._secondary_ammo = self._player_panel:child("weapons_panel"):child("secondary_weapon_panel"):bitmap({
				align           = "center",
				w 				= 50,
				h 				= 45,
				name 			= "secondary_ammo",
				visible 		= false,
				texture 		= "guis/textures/pd2/crimenet_marker_glow",
				color 			= Color("00AAFF"),
				layer 			= 2,
				blend_mode 		= "add"
			})
			self._primary_ammo:set_center_y(self._player_panel:child("weapons_panel"):child("primary_weapon_panel"):child("ammo_clip"):y() + self._player_panel:child("weapons_panel"):child("primary_weapon_panel"):child("ammo_clip"):h() / 2 - 2)
			self._secondary_ammo:set_center_y(self._player_panel:child("weapons_panel"):child("secondary_weapon_panel"):child("ammo_clip"):y() + self._player_panel:child("weapons_panel"):child("secondary_weapon_panel"):child("ammo_clip"):h() / 2 - 2)
			self._primary_ammo:set_center_x(self._player_panel:child("weapons_panel"):child("primary_weapon_panel"):child("ammo_clip"):x() + self._player_panel:child("weapons_panel"):child("primary_weapon_panel"):child("ammo_clip"):w() / 2)
			self._secondary_ammo:set_center_x(self._player_panel:child("weapons_panel"):child("secondary_weapon_panel"):child("ammo_clip"):x() + self._player_panel:child("weapons_panel"):child("secondary_weapon_panel"):child("ammo_clip"):w() / 2)
		end
	
		
		Hooks:PostHook( HUDTeammate , "set_ammo_amount_by_type" , "infinite_ammo" , function( self , type, max_clip, current_clip, current_left, max, weapon_panel, ... )

		local weapon_panel = self._player_panel:child( "weapons_panel" ):child( type .. "_weapon_panel" )
		local ammo_clip = weapon_panel:child( "ammo_clip" )

		if self._main_player and self._bullet_storm then
			ammo_clip:set_color(Color.white)
			ammo_clip:set_text( "8" )
			ammo_clip:set_rotation( 90 )
		else
			ammo_clip:set_rotation( 0 )
		end

		if self._main_player then
			local ratio = current_clip / max_clip

			local green = 0.7 * math.clamp((ratio - 0.25) / 0.25, 0, 1) + 0.3
			local blue = 0.7 * math.clamp(ratio/0.25, 0, 1) + 0.3
			local color = ratio >= 1 and Color('C2FC97') or Color(1, 1, blue, green)
			ammo_clip:set_text(string.format("%03.0f", current_clip))
			ammo_clip:set_color(color)

			local range = current_clip < 10 and 2 or current_clip < 100 and 1 or 0
			if range > 0 then
				ammo_clip:set_range_color(0, range, color:with_alpha(0.5))
			end
		end

		end )

		function HUDTeammate:_set_bulletstorm( state )
		if not VHUDPlus:getSetting({"CustomHUD", "PLAYER", "BULLETSTORM"}, true) then return end
		self._bullet_storm = state	
		
		if state then
			
			local pweapon_panel = self._player_panel:child( "weapons_panel" ):child( "primary_weapon_panel" )
			local pammo_clip = pweapon_panel:child( "ammo_clip" )
			local sweapon_panel = self._player_panel:child( "weapons_panel" ):child( "secondary_weapon_panel" )
			local sammo_clip = sweapon_panel:child( "ammo_clip" )
			
			self._primary_ammo:set_visible(true)
			self._secondary_ammo:set_visible(true)
			self._secondary_ammo:animate( callback( self, self, "_animate_glow" ) )
			self._primary_ammo:animate( callback( self , self , "_animate_glow" ) )
			
			pammo_clip:set_color(Color.white)
			pammo_clip:set_text( "8" )
			pammo_clip:set_rotation( 90 )
			
			sammo_clip:set_color(Color.white)
			sammo_clip:set_text( "8" )
			sammo_clip:set_rotation( 90 )	
			else
			self._primary_ammo:set_visible(false)
			self._secondary_ammo:set_visible(false)		
			end
		end
		
		function HUDTeammate:update(t,dt)
			self:update_latency(t,dt)
		end

		function HUDTeammate:update_latency(t,dt)
			local ping_panel = self._panel:child("latency")
			if ping_panel and self:peer_id() and t > self._next_latency_update_t then
				local net_session = managers.network:session()
				local peer = net_session and net_session:peer(self:peer_id())
				local latency = peer and Network:qos(peer:rpc()).ping or "n/a"

				if type(latency) == "number" then
					ping_panel:set_text(string.format("%.0fms", latency))
					ping_panel:set_color(latency < 75 and Color('C2FC97') or latency < 150 and Color('CEA168') or Color('E24E4E'))
				else
					ping_panel:set_text(latency)
					ping_panel:set_color(Color('E24E4E'))
				end

				self._next_latency_update_t = t + 1
			elseif not self:peer_id() and ping_panel then
				ping_panel:set_text("")
			end
		end

		function HUDTeammate:_create_ping_info()
			local name_panel = self._panel:child("name")
			local ping_info = self._panel:text({
				name = "latency",
				visible = VHUDPlus:getSetting({"CustomHUD","TEAMMATE","LATENCY"}, true),
				vertical = "right",
				font_size = tweak_data.hud.small_font_size,
				align = "right",
				halign = "right",
				text = "",
				font = "fonts/font_small_mf",
				layer = 1,
				visible = true,
				color = Color.white,
				x = -12,
				y = name_panel:y() - tweak_data.hud.small_font_size,
				h = 50
			})
		end

		-- function HUDTeammate:_init_hp_ap_num()
		-- 	local teammate_panel = self._panel:child("player")
		-- 	local radial_health_panel = teammate_panel:child("radial_health_panel")
		-- 	self.HealthNum = radial_health_panel:text({
		-- 		name = "HealthNum",
		-- 		visible = VHUDPlus:getSetting({"CustomHUD", self._setting_prefix, "SHOW_HP_AP_NUM"}, false),
		-- 		text = "",
		-- 		color = HealthNum_color,
		-- 		blend_mode = "normal",
		-- 		layer = 3,
		-- 		w = radial_health_panel:w(),
		-- 		h = radial_health_panel:h(),
		-- 		vertical = "top",
		-- 		align = "center",
		-- 		font_size = main_player and 22 or 18,
		-- 		font = "fonts/font_large_mf"
		-- 	})
		-- 	self.Armorsize = radial_health_panel:text({
		-- 		name = "ArmorNum",
		-- 		visible = VHUDPlus:getSetting({"CustomHUD", self._setting_prefix, "SHOW_HP_AP_NUM"}, false),
		-- 		text = "",
		-- 		color = ArmorNum_color,
		-- 		blend_mode = "normal",
		-- 		layer = 3,
		-- 		w = radial_health_panel:w(),
		-- 		h = radial_health_panel:h(),
		-- 		vertical = "bottom",
		-- 		align = "center",
		-- 		font_size = main_player and 22 or 18,
		-- 		font = "fonts/font_large_mf"
		-- 	})
		-- end

		-- Hooks:PostHook( HUDTeammate , "set_health" , "HealthAsNumber" , function( self , data )
		-- 	local teammate_panel = self._panel:child("player")
		-- 	local radial_health_panel = teammate_panel:child("radial_health_panel")
		-- 	local HealthNum2 = radial_health_panel:child("HealthNum")
		-- 	local radial_health = radial_health_panel:child("radial_health")
		-- 	local radial_bg = radial_health_panel:child("radial_bg")
		-- 	local radial_rip = radial_health_panel:child("radial_rip")
		-- 	local radial_rip_bg = radial_health_panel:child("radial_rip_bg")
			
		-- 	local red = data.current / data.total
		-- 	local Value = math.clamp(data.current / data.total, 0, 1)
		-- 	local real_value = math.round((data.total * 10) * Value)

		-- 	radial_health:set_visible( not VHUDPlus:getSetting({"CustomHUD", self._setting_prefix, "HIDEHPAP"}, false))
		-- 	radial_bg:set_visible( not VHUDPlus:getSetting({"CustomHUD", self._setting_prefix, "HIDEHPAP"}, false))
		-- 	HealthNum2:animate(callback(self, self, "_animate_hp"))
		-- 	HealthNum2:set_text(real_value)
		-- 	if real_value > 35 then
		-- 	  HealthNum2:set_color(Color.white)
		-- 	elseif real_value < 35 then
		-- 	  HealthNum2:set_color(Color.red)
		-- 	end
		-- end)

		-- Hooks:PostHook( HUDTeammate , "set_armor" , "ArmorAsNumber" , function( self , data )
		-- 	local teammate_panel = self._panel:child("player")
		-- 	local radial_health_panel = teammate_panel:child("radial_health_panel")
		-- 	local ArmorNum2 = radial_health_panel:child("ArmorNum")
		-- 	local radial_health = radial_health_panel:child("radial_health")
		-- 	local radial_shield = radial_health_panel:child("radial_shield")
		-- 	local radial_bg = radial_health_panel:child("radial_bg")
		
		-- 	local ratio = data.total ~= 0 and data.current / data.total or 0
		-- 	local Value = math.clamp(data.current / data.total, 0, 1)
		-- 	local real_value = math.round((data.total * 10) * Value)
		
		-- 	ArmorNum2:animate(callback(self, self, "_animate_ap"))
		-- 	ArmorNum2:set_text(real_value)
		-- 	if real_value > 35 then
		-- 		ArmorNum2:set_color(Color.white)
		-- 	elseif real_value < 35 then
		-- 		ArmorNum2:set_color(Color.red)
		-- 	end
		-- end)
		
		-- function HUDTeammate:_animate_hp()
		-- 	local t = 0
		-- 	local Healthsize = 25
		-- 	local teammate_panel = self._panel:child("player")
		-- 	local radial_health_panel = teammate_panel:child("radial_health_panel")
		-- 	local HealthNum2 = radial_health_panel:child("HealthNum")
		-- 	while t < 0.5 do
		-- 		t = t + coroutine.yield()
		-- 		local n = 1 - math.sin(t * 180)
		-- 		HealthNum2:set_font_size(math.lerp(Healthsize + 1, Healthsize + 1, n))
		-- 	end
		-- 	HealthNum2:set_font_size(Healthsize)
		-- end
		
		-- function HUDTeammate:_animate_ap()
		-- 	local t = 0
		-- 	local Armorsize = 25
		-- 	local teammate_panel = self._panel:child("player")
		-- 	local radial_health_panel = teammate_panel:child("radial_health_panel")
		-- 	local ArmorNum2 = radial_health_panel:child("ArmorNum")
		-- 	while t < 0.5 do
		-- 		t = t + coroutine.yield()
		-- 		local n = 1 - math.sin(t * 180)
		-- 		ArmorNum2:set_font_size(math.lerp(Armorsize + 1, Armorsize + 1, n))
		-- 	end
		-- 	ArmorNum2:set_font_size(Armorsize)
		-- end
		
	elseif RequiredScript == "lib/units/beings/player/playerdamage" then
		
		local update_original = PlayerDamage.update
		local change_health_original = PlayerDamage.change_health
		
		function PlayerDamage:update(...)
			update_original(self, ...)
			managers.hud:update_armor_timer(self._regenerate_timer or 0)
		end
		
		function PlayerDamage:change_health(change_of_health)
			managers.hud:change_health(math.max(0, change_of_health or 0))
			return change_health_original(self, change_of_health)
		end
		
	elseif RequiredScript == "lib/units/beings/player/states/playerstandard" then
		
		local update_original = PlayerStandard.update
		
		function PlayerStandard:update(t, ...)
			managers.hud:update_inspire_timer(self._ext_movement:morale_boost() and managers.enemy:get_delayed_clbk_expire_t(self._ext_movement:morale_boost().expire_clbk_id) - t or -1)
			update_original(self, t, ...)
		end

	elseif RequiredScript == "lib/managers/enemymanager" then
		
		function EnemyManager:get_delayed_clbk_expire_t(clbk_id)	
			for _, clbk in ipairs(self._delayed_clbks) do	
				if clbk[1] == clbk_id then	
					return clbk[2]	
				end	
			end	
		end 

	elseif RequiredScript == "lib/units/beings/player/playermovement" then
		
		Hooks:PostHook( PlayerMovement , "_upd_underdog_skill" , "uHUDPostPlayerMovementUpdUnderdogSkill" , function( self , t )

			if not self._underdog_skill_data.has_dmg_dampener then return end

			if not self._attackers or self:downed() then
				managers.hud:hide_underdog()
				return
			end

			local my_pos = self._m_pos
			local nr_guys = 0
			local activated
			for u_key, attacker_unit in pairs(self._attackers) do
				if not alive(attacker_unit) then
					self._attackers[u_key] = nil
					managers.hud:hide_underdog()
					return
				end
				local attacker_pos = attacker_unit:movement():m_pos()
				local dis_sq = mvector3.distance_sq(attacker_pos, my_pos)
				if dis_sq < self._underdog_skill_data.max_dis_sq and math.abs(attacker_pos.z - my_pos.z) < 250 then
					nr_guys = nr_guys + 1
					if nr_guys >= self._underdog_skill_data.nr_enemies then
						activated = true
						managers.hud:show_underdog()
					end
				else
				return
				end
			end

		end )

	elseif RequiredScript == "lib/managers/playermanager" then


		local _update_temporary_upgrades_orig2 = PlayerManager.activate_temporary_upgrade
		function PlayerManager:activate_temporary_upgrade(...)
			_update_temporary_upgrades_orig2(self, ...)
			managers.hud:activate_temp_upgrades_updator()
		end

		function PlayerManager:_clbk_bulletstorm_expire()

			self._bullet_storm_clbk = nil
			managers.hud:set_bulletstorm( false )
			
			if managers.player and managers.player:player_unit() and managers.player:player_unit():inventory() then
				for id , weapon in pairs( managers.player:player_unit():inventory():available_selections() ) do
					managers.hud:set_ammo_amount( id , weapon.unit:base():ammo_info() )
				end
			end
		
		end
		
		Hooks:PostHook( PlayerManager , "add_to_temporary_property" , "infinite_ammo" , function( self , name , time )
		
			if name == "bullet_storm" and time then
			
				if not self._bullet_storm_clbk then
					self._bullet_storm_clbk = "Infinite"
					managers.hud:set_bulletstorm( true )
					managers.enemy:add_delayed_clbk( self._bullet_storm_clbk , callback( self , self , "_clbk_bulletstorm_expire" ) , TimerManager:game():time() + time )
				end
				
			end
		
		end )

	elseif RequiredScript == "lib/managers/hud/hudplayercustody" then

		local set_negotiating_visible_orig  = HUDPlayerCustody.set_negotiating_visible
		local set_can_be_trade_visible_orig = HUDPlayerCustody.set_can_be_trade_visible

		function HUDPlayerCustody:set_negotiating_visible(...)
		set_negotiating_visible_orig(self, ...)
			local trade_text = self._hud.trade_text2

			if VHUDPlus:getSetting({"CustomHUD", "HUD_SCALE"}, 1) < 0.55 then
				offset = 720
			elseif VHUDPlus:getSetting({"CustomHUD", "HUD_SCALE"}, 1) < 0.60 then
				offset = 660
			elseif VHUDPlus:getSetting({"CustomHUD", "HUD_SCALE"}, 1) < 0.65 then
				offset = 595
			elseif VHUDPlus:getSetting({"CustomHUD", "HUD_SCALE"}, 1) < 0.70 then
				offset = 530
			elseif VHUDPlus:getSetting({"CustomHUD", "HUD_SCALE"}, 1) < 0.75 then
				offset = 465
			elseif VHUDPlus:getSetting({"CustomHUD", "HUD_SCALE"}, 1) < 0.80 then
				offset = 400
			elseif VHUDPlus:getSetting({"CustomHUD", "HUD_SCALE"}, 1) < 0.85 then
				offset = 335
			elseif VHUDPlus:getSetting({"CustomHUD", "HUD_SCALE"}, 1) < 0.90 then
				offset = 275
			elseif VHUDPlus:getSetting({"CustomHUD", "HUD_SCALE"}, 1) < 0.95 then
				offset = 210
			elseif VHUDPlus:getSetting({"CustomHUD", "HUD_SCALE"}, 1) < 1 then
				offset = 145
			else
				offset = 80 
			end

			trade_text:set_right(self._hud.trade_text2:w() + offset )
		end

		function HUDPlayerCustody:set_can_be_trade_visible(...)
		set_can_be_trade_visible_orig(self, ...)
			local trade_text = self._hud.trade_text1
			
			if VHUDPlus:getSetting({"CustomHUD", "HUD_SCALE"}, 1) < 0.55 then
				offset = 720
			elseif VHUDPlus:getSetting({"CustomHUD", "HUD_SCALE"}, 1) < 0.60 then
				offset = 660
			elseif VHUDPlus:getSetting({"CustomHUD", "HUD_SCALE"}, 1) < 0.65 then
				offset = 595
			elseif VHUDPlus:getSetting({"CustomHUD", "HUD_SCALE"}, 1) < 0.70 then
				offset = 530
			elseif VHUDPlus:getSetting({"CustomHUD", "HUD_SCALE"}, 1) < 0.75 then
				offset = 465
			elseif VHUDPlus:getSetting({"CustomHUD", "HUD_SCALE"}, 1) < 0.80 then
				offset = 400
			elseif VHUDPlus:getSetting({"CustomHUD", "HUD_SCALE"}, 1) < 0.85 then
				offset = 335
			elseif VHUDPlus:getSetting({"CustomHUD", "HUD_SCALE"}, 1) < 0.90 then
				offset = 275
			elseif VHUDPlus:getSetting({"CustomHUD", "HUD_SCALE"}, 1) < 0.95 then
				offset = 210
			elseif VHUDPlus:getSetting({"CustomHUD", "HUD_SCALE"}, 1) < 1 then
				offset = 145
			else
				offset = 80 
			end
			
			trade_text:set_right(self._hud.trade_text1:w() + offset )
		end
	end
end