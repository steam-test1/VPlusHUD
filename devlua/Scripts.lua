if string.lower(RequiredScript) == "lib/managers/hudmanagerpd2" then
	local set_teammate_ammo_amount_orig = HUDManager.set_teammate_ammo_amount

	function HUDManager:set_teammate_ammo_amount(id, selection_index, max_clip, current_clip, current_left, max, ...)
		if VHUDPlus:getSetting({"CustomHUD", "USE_REAL_AMMO"}, true) and VHUDPlus:getSetting({"CustomHUD", "HUDTYPE"}, 2) == 3 then
			local total_left = current_left - current_clip
			if total_left >= 0 then
				current_left = total_left
				max = max - current_clip
			end
		end
		return set_teammate_ammo_amount_orig(self, id, selection_index, max_clip, current_clip, current_left, max, ...)
	end


    local ability_radial = HUDManager.set_teammate_ability_radial
    function HUDManager:set_teammate_ability_radial(i, data)
	    local hud = managers.hud:script( PlayerBase.PLAYER_INFO_HUD_FULLSCREEN_PD2)
	    if not hud.panel:child("chico_injector_left") then
		    local chico_injector_left = hud.panel:bitmap({
			    name = "chico_injector_left",
			    visible = false,
			    texture = "assets/guis/textures/custom_effect",
			    layer = 0,
			    color = Color(1, 0.6, 0),
			    blend_mode = "add",
			    w = hud.panel:w(),
			    h = hud.panel:h(),
			    x = 0,
			    y = 0
		    })
	    end
	    local chico_injector_left = hud.panel:child("chico_injector_left")
	    if i == 4 and data.current < data.total and data.current > 0 and chico_injector_left then
		    chico_injector_left:set_visible(VHUDPlus:getSetting({"MISCHUD", "KINGPIN_EFFECT"}, true))
		    local hudinfo = managers.hud:script(PlayerBase.PLAYER_INFO_HUD_PD2)
		    chico_injector_left:animate(hudinfo.flash_icon, 4000000000)
	    elseif hud.panel:child("chico_injector_left") then
		    chico_injector_left:stop()
		    chico_injector_left:set_visible(false)
	    end
	    if chico_injector_left and data.current == 0 then
		    chico_injector_left:set_visible(false)
	    end
	    return ability_radial(self, i, data)
    end

local custom_radial = HUDManager.set_teammate_custom_radial
    function HUDManager:set_teammate_custom_radial(i, data)
	    local hud = managers.hud:script( PlayerBase.PLAYER_INFO_HUD_FULLSCREEN_PD2)
	    if not hud.panel:child("swan_song_left") then
		    local swan_song_left = hud.panel:bitmap({
			    name = "swan_song_left",
			    visible = false,
			    texture = "assets/guis/textures/custom_effect",
			    layer = 0,
			    color = Color(0, 0.7, 1),
			    blend_mode = "add",
			    w = hud.panel:w(),
			    h = hud.panel:h(),
			    x = 0,
			    y = 0
		    })
	    end
	    local swan_song_left = hud.panel:child("swan_song_left")
	    if i == 4 and data.current < data.total and data.current > 0 and swan_song_left then
		    swan_song_left:set_visible(VHUDPlus:getSetting({"MISCHUD", "SWAN_SONG_EFFECT"}, true))
		    local hudinfo = managers.hud:script(PlayerBase.PLAYER_INFO_HUD_PD2)
		    swan_song_left:animate(hudinfo.flash_icon, 4000000000)
	    elseif hud.panel:child("swan_song_left") then
		    swan_song_left:stop()
		    swan_song_left:set_visible(false)
	    end
	    if swan_song_left and data.current == 0 then
		    swan_song_left:set_visible(false)
	    end
	    return custom_radial(self, i, data)
    end

	Hooks:PreHook(HUDManager, "_setup_player_info_hud_pd2", "wolfhud_scaling", function(self)
		if HSAS or NepgearsyHUDReborn then return end
		managers.gui_data:layout_scaled_fullscreen_workspace(managers.hud._saferect)
	end)

	function HUDManager:recreate_player_info_hud_pd2()
		if HSAS or NepgearsyHUDReborn then return end
		if not self:alive(PlayerBase.PLAYER_INFO_HUD_PD2) then return end
		local hud = managers.hud:script(PlayerBase.PLAYER_INFO_HUD_PD2)
		self:_create_teammates_panel(hud)
		self:_create_present_panel(hud)
		self:_create_interaction(hud)
		self:_create_progress_timer(hud)
		self:_create_objectives(hud)
		self:_create_hint(hud)
		self:_create_heist_timer(hud)
		self:_create_temp_hud(hud)
		self:_create_suspicion(hud)
		self:_create_hit_confirm(hud)
		self:_create_hit_direction(hud)
		self:_create_downed_hud()
		self:_create_custody_hud()
		self:_create_hud_chat()
		self:_create_assault_corner()
		self:_create_waiting_legend(hud)
		self:_create_accessibility(hud)
	end

	core:module("CoreGuiDataManager")
	function GuiDataManager:layout_scaled_fullscreen_workspace(ws)
		if HSAS or NepgearsyHUDReborn then return end
		local base_res = {x = 1280, y = 720}
		local res = RenderSettings.resolution
		local sc = (2 - _G.VHUDPlus:getSetting({"CustomHUD", "HUD_SCALE"}, 1))
		local aspect_width = base_res.x / self:_aspect_ratio()
		local h = math.round(sc * math.max(base_res.y, aspect_width))
		local w = math.round(sc * math.max(base_res.x, aspect_width / h))

		local safe_w = math.round(0.95 * res.x)
		local safe_h = math.round(0.95 * res.y)
		local sh = math.min(safe_h, safe_w / (w / h))
		local sw = math.min(safe_w, safe_h * (w / h))
		local x = res.x / 2 - sh * (w / h) / 2
		local y = res.y / 2 - sw / (w / h) / 2
		ws:set_screen(w, h, x, y, math.min(sw, sh * (w / h)))
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
		if not VHUDPlus:getSetting({"MISCHUD", "SHOOT_THROUGH_BOTS"}, true) then
			return init_original(self, ...)
		end
		init_original(self, ...)
	    self._bullet_slotmask = self._bullet_slotmask - World:make_slot_mask(16)
    end

    function RaycastWeaponBase:setup(...)
		if not VHUDPlus:getSetting({"MISCHUD", "SHOOT_THROUGH_BOTS"}, true) then
			return setup_original(self, ...)
		end
		setup_original(self, ...)
	    self._bullet_slotmask = self._bullet_slotmask - World:make_slot_mask(16)
    end
elseif string.lower(RequiredScript) == "lib/units/contourext" then
	local add_original = ContourExt.add
    if VHUDPlus:getSetting({"MISCHUD", "JOKER_CONTOUR_NEW"}, true) and not FadingContour then
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
elseif string.lower(RequiredScript) == "lib/tweak_data/weapontweakdata" then
    local init_original = WeaponTweakData.init

    function WeaponTweakData:init(tweak_data)
        init_original(self, tweak_data)
        self.basset_crew.rays = 6
        self.x_basset_crew.rays = 6
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
		if alive(hostages_panel) and VHUDPlus:getSetting({"HUDList", "ENABLED"}, true) and not VHUDPlus:getSetting({"HUDList", "ORIGNIAL_HOSTAGE_BOX"}, false) then
			hostages_panel:set_alpha(0)
		end
	end
elseif string.lower(RequiredScript) == "lib/tweak_data/levelstweakdata" then
    local _get_music_event_orig = LevelsTweakData.get_music_event
    function LevelsTweakData:get_music_event(stage)
        local result = _get_music_event_orig(self, stage)
        if result and VHUDPlus:getSetting({"MISCHUD", "SHUFFLE_MUSIC"}, true) and stage == "control" then
            if self.can_change_music then
                managers.music:check_music_switch()
            else
                self.can_change_music = true
            end
        end
        return result
    end
elseif string.lower(RequiredScript) == "lib/managers/hud/hudteammate" then
	local set_ammo_amount_by_type_orig = HUDTeammate.set_ammo_amount_by_type
	function HUDTeammate:set_ammo_amount_by_type(type, max_clip, current_clip, current_left, max, weapon_panel, ...)
		if VHUDPlus:getSetting({"CustomHUD", "USE_REAL_AMMO"}, true) then
			if current_left - current_clip >= 0 then
				current_left = current_left - current_clip
			end
		end

		return set_ammo_amount_by_type_orig(self, type, max_clip, current_clip, current_left, max, weapon_panel, ...)
	end
elseif string.lower(RequiredScript) == "lib/managers/hud/hudpresenter" then
	local _present_done_orig = HUDPresenter._present_done
	function HUDPresenter:_present_done()
		_present_done_orig(self)
		local present_panel = managers.hud._hud_presenter._hud_panel:child("present_panel")
		present_panel:set_visible(false)
		managers.hud._hud_presenter:_present_done()
	end
elseif string.lower(RequiredScript) == "core/lib/managers/menu/reference_input/coremenuinput" then
	core:module("CoreMenuInput")
	core:import("CoreDebug")
	core:import("CoreMenuItem")
	core:import("CoreMenuItemSlider")
	core:import("CoreMenuItemToggle")

	function MenuInput:update(t, dt)
		self:_check_releases()
		self:any_keyboard_used()

		local axis_timer = self:axis_timer()

		if axis_timer.y > 0 then
			self:set_axis_y_timer(axis_timer.y - dt)
		end

		if axis_timer.x > 0 then
			self:set_axis_x_timer(axis_timer.x - dt)
		end

		if self:_input_hijacked() then
			local item = self._logic:selected_item()

			if item and item.INPUT_ON_HIJACK then
				self._item_input_action_map[item.TYPE](item, self._controller)
			end

			return false
		end

		if self._accept_input and self._controller then
			if axis_timer.y <= 0 then
				if self:menu_up_input_bool() then
					self:prev_item()
					self:set_axis_y_timer(0.12)

					if self:menu_up_pressed() then
						self:set_axis_y_timer(0.3)
					end
				elseif self:menu_down_input_bool() then
					self:next_item()
					self:set_axis_y_timer(0.12)

					if self:menu_down_pressed() then
						self:set_axis_y_timer(0.3)
					end
				end
			end

			if axis_timer.x <= 0 then
				local item = self._logic:selected_item()

				if item then
					self._item_input_action_map[item.TYPE](item, self._controller)
				end
			end

			if self._controller:get_input_pressed("menu_toggle_legends") then
				print("update something")
				self._logic:update_node()
			end

			if self._controller:get_input_pressed("menu_update") then
				managers.menu:open_node("crimenet_filters", {})
				-- managers.menu_component:disable_crimenet()
				self._logic:update_node()
				-- managers.network.matchmake:load_user_filters()
				managers.network.matchmake:search_lobby(managers.network.matchmake:search_friends_only())
			end
		end

		return true
	end
elseif string.lower(RequiredScript) == "lib/managers/statisticsmanager" then

	local shot_fired_original = StatisticsManager.shot_fired
	local session_enemy_killed_by_type_original = StatisticsManager.session_enemy_killed_by_type

	function StatisticsManager:shot_fired(data, ...)
		local value = shot_fired_original(self, data, ...)
		if managers.hud and managers.hud.update_stats_screen then
			managers.hud:update_stats_screen("accuracy")
		end
		return value
	end

	function StatisticsManager:session_enemy_killed_by_type(enemy, type)
		if enemy == "non_special" then	--added new "enemy"
			return self:session_enemy_killed_by_type("total", type)
					- self:session_total_specials_kills()
		end
		return session_enemy_killed_by_type_original(self, enemy, type)
	end

	--New Functions
	function StatisticsManager:enemy_killed_by_type(enemy, type)
		if enemy == "non_special" then	--added new "enemy"
			return self:enemy_killed_by_type("total", type)
					- self:total_specials_kills()
		end
		return self._global.killed and self._global.killed[enemy] and self._global.killed[enemy][type] or 0
	end

	function StatisticsManager:total_specials_kills()
		local count = 0
		for _, id in ipairs(self.special_unit_ids) do
			count = count + self:enemy_killed_by_type(id, "count")
		end
		return count
	end

	local TANK_IDs = { "tank", "tank_green", "tank_black", "tank_skull", "tank_medic", "tank_mini", "tank_hw" }

	function StatisticsManager:session_total_tanks_killed()
		local count = 0
		for _, unit_id in ipairs(TANK_IDs) do
			count = count + self:session_enemy_killed_by_type(unit_id, "count")
		end
		return count
	end

	function StatisticsManager:total_tanks_killed()
		local count = 0
		for _, unit_id in ipairs(TANK_IDs) do
			count = count + self:enemy_killed_by_type(unit_id, "count")
		end
		return count
	end

	function StatisticsManager:total_downed_alltime()
		return self._global.downed.bleed_out + self._global.downed.incapacitated
	end

	function StatisticsManager:session_total_revives()
		return {self._global.session.revives.player_count , self._global.session.revives.npc_count}
	end

	function StatisticsManager:total_revives()
		return {self._global.revives.player_count , self._global.revives.npc_count}
	end

	function StatisticsManager:session_damage(peer_id)
		local peer = peer_id and managers.network:session():peer(peer_id)
		local peer_uid = peer and peer:user_id() or Steam:userid()
		self._session_damage = self._session_damage or {}
		return math.round(self._session_damage[peer_uid] or 0)
	end

	function StatisticsManager:session_damage_string(peer_id)
		local damage = self:session_damage(peer_id)
		return managers.money:add_decimal_marks_to_string(tostring(damage))
	end

	function StatisticsManager:add_session_damage(damage, peer_id)
		local peer = peer_id and managers.network:session():peer(peer_id)
		local peer_uid = peer and peer:user_id() or Steam:userid()
		self._session_damage = self._session_damage or {}
		self._session_damage[peer_uid] = (self._session_damage[peer_uid] or 0 ) + (damage * 10)
	end

	function StatisticsManager:reset_session_damage(peer_id)
		local peer = peer_id and managers.network:session():peer(peer_id)
		local peer_uid = peer and peer:user_id() or Steam:userid()
		self._session_damage = self._session_damage or {}
		self._session_damage[peer_uid] = 0
	end

	function StatisticsManager:most_session_damage()
		local user_id, max_damage = nil, 0
		for peer_uid, damage in pairs(self._session_damage or {}) do
			damage = math.round(damage)
			if damage > max_damage then
				max_damage = damage
				user_id = peer_uid
			end
		end

		local peer_name = user_id and Steam:username(user_id) or managers.localization:text("debug_undecided")
		return string.format("%s (%s)", peer_name, managers.money:add_decimal_marks_to_string(tostring(max_damage)))
	end
elseif string.lower(RequiredScript) == "lib/units/enemies/cop/copdamage" and not VHUDPlus.tabstat_fix then
	VHUDPlus.tabstat_fix = true

	local _update_debug_ws_original = CopDamage._update_debug_ws

	function CopDamage:_update_debug_ws(damage_info, ...)
		if damage_info and type(damage_info) == "table" then
			CopDamage:_process_damage(damage_info)
		end
		return _update_debug_ws_original(self, damage_info, ...)
	end

	function CopDamage:_process_damage(damage_info)
		local attacker = alive(damage_info.attacker_unit) and damage_info.attacker_unit
		local damage = tonumber(damage_info.damage) or 0

		if attacker and damage >= 0.1 then
			local killer

			if attacker:in_slot(3) or attacker:in_slot(5) then
				--Human team mate
				killer = attacker
			elseif attacker:in_slot(2) then
				--Player
				killer = attacker
			elseif attacker:in_slot(16) then
				--Bot/joker
				killer = attacker
			elseif attacker:in_slot(12) then
				--Enemy
			elseif attacker:in_slot(25)	then
				--Turret
				local owner = attacker:base():get_owner_id()
				if owner then
					killer =  managers.criminals:character_unit_by_peer_id(owner)
				end
			elseif attacker:base().thrower_unit then
				killer = attacker:base():thrower_unit()
			end

			if alive(killer) then
				if killer:in_slot(2) then
					if managers.statistics then
						managers.statistics:add_session_damage(damage)
					end

					if managers.hud and managers.hud.update_stats_screen then
						managers.hud:update_stats_screen()
					end
				else
					local peer_id = managers.criminals:character_peer_id_by_unit(killer)
					if peer_id then
						managers.statistics:add_session_damage(damage, peer_id)
					end
				end
			end
		end
	end
elseif RequiredScript == "lib/units/civilians/civiliandamage" then

	local _on_damage_received_original = CivilianDamage._on_damage_received
	function CivilianDamage:_on_damage_received(damage_info, ...)
		if damage_info and type(damage_info) == "table" then
			CivilianDamage.super._process_damage(self, damage_info)
		end
		return _on_damage_received_original(self, damage_info, ...)
	end
elseif string.lower(RequiredScript) == "lib/managers/menu/stageendscreengui" then

	local set_stats_original = StatsTabItem.set_stats
	local feed_statistics_original = StageEndScreenGui.feed_statistics
	local feed_item_statistics_original = StatsTabItem.feed_statistics

	function StatsTabItem:set_stats(stats_data, ...)
		if table.contains(stats_data, "best_killer") then
			table.insert(stats_data, 6, "most_damage")
		elseif table.contains(stats_data, "favourite_weapon") then
			local total_objectives = managers.objectives:total_objectives(Global.level_data and Global.level_data.level_id)
			if total_objectives > 0 then
				table.insert(stats_data, 1, "completed_objectives")
			end
			table.insert(stats_data, 6, "session_damage")
		end

		set_stats_original(self, stats_data, ...)
	end

	function StageEndScreenGui:feed_statistics(data, ...)
		local new_data = clone(data) or {}
		new_data.most_damage = tostring(managers.statistics:most_session_damage())
		new_data.session_damage = tostring(managers.statistics:session_damage_string())

		feed_statistics_original(self, new_data, ...)
	end

	-- Make broken objective counter look less weird...
	function StatsTabItem:feed_statistics(stats_data, ...)
		local new_stats_data = clone(stats_data) or {}
		if managers.statistics:started_session_from_beginning() then
			new_stats_data.completed_objectives = managers.localization:text("menu_completed_objectives_of", {
				COMPLETED = stats_data.total_objectives,
				TOTAL = stats_data.total_objectives,
				PERCENT = stats_data.completed_ratio
			})
		end

		feed_item_statistics_original(self, new_stats_data, ...)
	end
end
