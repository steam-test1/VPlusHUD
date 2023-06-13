if _G.IS_VR then
	return
end
if VHUDPlus:getSetting({"CustomHUD", "HUDTYPE"}, 2) == 2 or VHUDPlus:getSetting({"CustomHUD", "HUDTYPE"}, 2) == 3 then

	if string.lower(RequiredScript) == "lib/units/beings/player/huskplayermovement" then

		-- local _perform_movement_action_enter_bleedout_original = HuskPlayerMovement._perform_movement_action_enter_bleedout

		-- function HuskPlayerMovement:_perform_movement_action_enter_bleedout(...)
		-- 	if not self._bleedout then
		-- 		local crim_data = managers.criminals:character_data_by_unit(self._unit)
		-- 		if crim_data and crim_data.panel_id then
		-- 			managers.hud:increment_teammate_downs(crim_data.panel_id)
		-- 		end
		-- 	end

		-- 	return _perform_movement_action_enter_bleedout_original(self, ...)
		-- end
	elseif string.lower(RequiredScript) == "lib/managers/group_ai_states/groupaistatebase" then

		-- local set_whisper_mode_original = GroupAIStateBase.set_whisper_mode
		-- function GroupAIStateBase:set_whisper_mode(enabled, ...)
		-- 	set_whisper_mode_original(self, enabled, ...)
		-- 	if (enabled) then
		-- 		managers.hud:set_hud_mode("stealth")
		-- 	else
		-- 		managers.hud:set_hud_mode("loud")
		-- 	end
		-- 	self:_call_listeners("whisper_mode", enabled)
		-- end
	elseif string.lower(RequiredScript) == "lib/managers/hudmanagerpd2" then

		HUDManager.DOWNS_COUNTER_PLUGIN = true
		HUDManager.DETECT_COUNTER_PLUGIN = true

		-- local set_player_health_original = HUDManager.set_player_health
		-- local set_mugshot_custody_original = HUDManager.set_mugshot_custody

		-- function HUDManager:set_player_health(data, ...)
		-- 	if data.revives then
		-- 		self:set_player_revives(HUDManager.PLAYER_PANEL, data.revives - 1)
		-- 	end
		-- 	return set_player_health_original(self, data, ...)
		-- end

		-- function HUDManager:set_mugshot_custody(id, ...)
		-- 	local data = self:_get_mugshot_data(id)
		-- 	if data then
		-- 		local i = managers.criminals:character_data_by_name(data.character_name_id).panel_id
		-- 		managers.hud:reset_teammate_downs(i)
		-- 	end

		-- 	return set_mugshot_custody_original(self, id, ...)
		-- end

		function HUDManager:set_hud_mode(mode)
			for _, panel in pairs(self._teammate_panels or {}) do
				panel:set_hud_mode(mode)
			end
		end

		HUDManager.set_player_revives = HUDManager.set_player_revives or function(self, i, revive_amount)
			self._teammate_panels[i]:set_revives_amount(revive_amount)
		end

		-- HUDManager.increment_teammate_downs = HUDManager.increment_teammate_downs or function(self, i)
		-- 	self._teammate_panels[i]:increment_downs()
		-- end

		-- HUDManager.reset_teammate_downs = HUDManager.reset_teammate_downs or function(self, i)
		-- 	self._teammate_panels[i]:reset_downs()
		-- end

	elseif string.lower(RequiredScript) == "lib/managers/hud/hudteammate" and not HUDManager.CUSTOM_TEAMMATE_PANELS then

		Hooks:PostHook( HUDTeammate, "init", "WolfHUD_DownCounter_HUDTeammate_init", function(self, ...)
			self._health_panel = self._health_panel or self._player_panel:child("radial_health_panel")
			self._condition_icon = self._condition_icon or self._panel:child("condition_icon")
			self._setting_prefix = self._main_player and "PLAYER" or "TEAMMATE"
			self._down_counter = HUDManager.DOWNS_COUNTER_PLUGIN and VHUDPlus:getSetting({"CustomHUD", self._setting_prefix, "DOWNCOUNTER"}, true)
			self._detection_risk = HUDManager.DETECT_COUNTER_PLUGIN and VHUDPlus:getSetting({"CustomHUD", self._setting_prefix, "DETECTIONCOUNTER"}, true)
			self.vis_down = self._condition_icon and self._condition_icon:visible() or not (HUDManager.DOWNS_COUNTER_PLUGIN and VHUDPlus:getSetting({"CustomHUD", self._setting_prefix, "DOWNCOUNTER"}, true)) or self._ai
			self.vis_detect = self._condition_icon and self._condition_icon:visible() or not (HUDManager.DETECT_COUNTER_PLUGIN and VHUDPlus:getSetting({"CustomHUD", self._setting_prefix, "DETECTIONCOUNTER"}, true)) or self._ai

			self._health_panel:bitmap({
				name = "risk_indicator_bg",
				texture = "guis/textures/pd2/hot_cold_glow",
				texture_rect = { 0, 0, 64, 64 },
				blend_mode = "normal",
				color = Color.black,
				alpha = 0.6,
				w = self._health_panel:w(),
				h = self._health_panel:h(),
				layer = 1
			})

			self._downs_counter = self._health_panel:text({
				name = "downs",
				color = Color.white,
				align = "center",
				vertical = "center",
				w = self._health_panel:w(),
				h = self._health_panel:h(),
				font_size = self._main_player and 16 or 13,
				font = tweak_data.menu.pd2_medium_font,
				layer = 2,
				visible = HUDManager.DOWNS_COUNTER_PLUGIN and VHUDPlus:getSetting({"CustomHUD", self._setting_prefix, "DOWNCOUNTER"}, true) and not self._ai or false
			})

			self._detection_counter = self._health_panel:text({
				name = "detection",
				color = Color.red,
				align = "center",
				vertical = "center",
				w = self._health_panel:w(),
				h = self._health_panel:h(),
				font_size = self._main_player and 16 or 13,
				font = tweak_data.menu.pd2_medium_font,
				layer = 2,
				visible = HUDManager.DETECT_COUNTER_PLUGIN and VHUDPlus:getSetting({"CustomHUD", self._setting_prefix, "DETECTIONCOUNTER"}, true) and not self._ai or false
			})

			self:set_detection()

			if managers.gameinfo then
				managers.gameinfo:register_listener("HealthRadial_whisper_mode_listener" .. tostring(self._id), "whisper_mode", "change", callback(self, self, "_whisper_mode_change"), nil, true)
			end

			if self._panel:child("player"):child("revive_panel") then
				self._panel:child("player"):child("revive_panel"):set_visible(VHUDPlus:getSetting({"CustomHUD", self._setting_prefix, "NEWDOWNCOUNTER"}, false))
			end
		end)

		Hooks:PostHook( HUDTeammate, "remove_panel", "WolfHUD_DownCounter_HUDTeammate_remove_panel", function(self, ...)
			managers.gameinfo:unregister_listener("HealthRadial_whisper_mode_listener" .. tostring(self._id), "whisper_mode", "change")
		end)

		Hooks:PostHook( HUDTeammate, "set_peer_id", "WolfHUD_DownCounter_HUDTeammate_set_peer_id", function(self, ...)
			self:set_detection()
		end)

		Hooks:PostHook( HUDTeammate, "set_callsign", "WolfHUD_DownCounter_HUDTeammate_set_callsign", function(self, ...)
			if self._main_player then
				self:set_detection()
			end
		end)

		local set_revives_amount_ori = HUDTeammate.set_revives_amount
		function HUDTeammate:set_revives_amount(revive_amount)
			set_revives_amount_ori(self, revive_amount)
			self._health_panel = self._health_panel or self._player_panel:child("radial_health_panel")
			self._downs_counter = self._health_panel:child("downs")
				
			if self._downs_counter then
				self._downs_counter:set_text(tostring(math.max(revive_amount - 1, 0)))
			end
		end

		function HUDTeammate:_whisper_mode_change(status)
			self._downs_counter:set_visible(not self.vis_down and not status)
			self._detection_counter:set_visible(not self.vis_detect and managers.groupai:state():whisper_mode())
		end

		HUDTeammate.set_downs = HUDTeammate.set_downs or function(self, amount)
			self._downs_counter:set_visible(not self.vis_down and not managers.groupai:state():whisper_mode())
			self._detection_counter:set_visible(not self.vis_detect and managers.groupai:state():whisper_mode())
		end

		HUDTeammate.set_detection = HUDTeammate.set_detection or function(self, risk)
			if not risk then
				if self._main_player then
					risk = tonumber(string.format("%.0f", managers.blackmarket:get_suspicion_offset_of_local(tweak_data.player.SUSPICION_OFFSET_LERP or 0.75) * 100))
				elseif self:peer_id() then
					risk = tonumber(string.format("%.0f", managers.blackmarket:get_suspicion_offset_of_peer(managers.network:session():peer(self:peer_id()), tweak_data.player.SUSPICION_OFFSET_LERP or 0.75) * 100))
				end
			end
			if not self._risk or risk and risk ~= self._risk then
				self._risk = risk
				if self._risk then
					local color = self._risk < 50 and Color(1, 0, 0.8, 1) or Color(1, 1, 0.2, 0)
					self._detection_counter:set_text(tostring(self._risk))
					self._detection_counter:set_color(color)
				end

				if self._downs_counter then
					self._downs_counter:set_visible(not self.vis_down and not managers.groupai:state():whisper_mode())
				end
				if self._detection_counter then
					self._detection_counter:set_visible(not self.vis_detect and managers.groupai:state():whisper_mode())
				end
			end
		end
	end
end
