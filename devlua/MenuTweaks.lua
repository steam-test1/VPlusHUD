if string.lower(RequiredScript) == "lib/managers/menumanager" then
	function MenuCallbackHandler:get_latest_dlc_locked(...) return false end		--Hide DLC ad in the main menu
	
	-- Offline chat.
	function MenuManager:toggle_chatinput()
	    if Application:editor() or SystemInfo:platform() ~= Idstring("WIN32") or self:active_menu() or not managers.network:session() then
		    return
	    end
	    if managers.hud then
		    managers.hud:toggle_chatinput()
		    return true
	    end
    end	

	function MenuCallbackHandler:save_lobby_settings(setting, value)
		--Save lobby settings
		if setting then
			if value == nil then
				value = Global.game_settings[setting]
			end
			VHUDPlus:setSetting({"LOBBY_SETTINGS", setting}, value)
		else
			local lobby_settings = VHUDPlus:getSetting({"LOBBY_SETTINGS"}, {})
			for id, value in pairs(lobby_settings) do
				if Global.game_settings[id] ~= nil then
					lobby_settings[id] = Global.game_settings[id]
				end
			end
			VHUDPlus:setSetting({"LOBBY_SETTINGS"}, lobby_settings)
		end
		VHUDPlus:Save()
	end

	Hooks:PostHook( MenuCallbackHandler , "choice_crimenet_lobby_job_plan" , "MenuCallbackHandlerPostSaveJobPlan_WolfHUD" , function( self, ... )
		self:save_lobby_settings("job_plan")
	end)
	Hooks:PostHook( MenuCallbackHandler , "choice_kicking_option" , "MenuCallbackHandlerPostSaveKickOption_WolfHUD" , function( self, ... )
		self:save_lobby_settings("kick_option")
	end)
	Hooks:PostHook( MenuCallbackHandler , "choice_crimenet_drop_in" , "MenuCallbackHandlerPostSaveDropInOption_WolfHUD" , function( self, ... )
		self:save_lobby_settings("drop_in_option")
	end)
	if not LobbySettings then
	    Hooks:PostHook( MenuCallbackHandler , "choice_crimenet_team_ai" , "MenuCallbackHandlerPostSaveTeamAIOption_WolfHUD" , function( self, ... )
		    self:save_lobby_settings("team_ai")
		    self:save_lobby_settings("team_ai_option")
	    end)
	    Hooks:PostHook( MenuCallbackHandler , "choice_crimenet_lobby_reputation_permission" , "MenuCallbackHandlerPostSaveReputationPermission_WolfHUD" , function( self, ... )
		    self:save_lobby_settings("reputation_permission")
	    end)
	    Hooks:PostHook( MenuCallbackHandler , "choice_crimenet_lobby_permission" , "MenuCallbackHandlerPostSavePermission_WolfHUD" , function( self, ... )
		    self:save_lobby_settings("permission")
	    end)
	    Hooks:PostHook( MenuCallbackHandler , "change_contract_difficulty" , "MenuCallbackHandlerPostSaveDifficulty_WolfHUD" , function( self, item, ... )
		    self:save_lobby_settings("difficulty", tweak_data:index_to_difficulty(item:value()))
	    end)
	    Hooks:PostHook( MenuCallbackHandler , "choice_crimenet_one_down" , "MenuCallbackHandlerPostSaveOneDownMod_WolfHUD" , function( self, item, ... )
		    self:save_lobby_settings("one_down", item:value() == "on")
	    end)		
	end
	Hooks:PostHook( MenuCallbackHandler , "choice_crimenet_auto_kick" , "MenuCallbackHandlerPostSaveAutoKick_WolfHUD" , function( self, ... )
		self:save_lobby_settings("auto_kick")
	end)

	Hooks:PostHook( MenuCallbackHandler , "update_matchmake_attributes" , "MenuCallbackHandlerPostUpdateMatchmakeAttributes_WolfHUD" , function( self, item, ... )
		self:save_lobby_settings()
	end)

	local WOLFHUD_LOBBY_SETTINGS_LOADED = false
	local MenuCrimeNetContractInitiator_modify_node_orig = MenuCrimeNetContractInitiator.modify_node
	function MenuCrimeNetContractInitiator:modify_node(original_node, data, ...)
		
		if not VHUDPlus:getSetting({"INVENTORY", "SAVE_FILTERS"}, true) then
			return MenuCrimeNetContractInitiator_modify_node_orig(self, original_node, data, ...)
		end
		
		if not WOLFHUD_LOBBY_SETTINGS_LOADED then
			local lobby_settings = VHUDPlus:getSetting({"LOBBY_SETTINGS"}, {})
			for id, value in pairs(lobby_settings) do
				if Global.game_settings[id] ~= nil then
					Global.game_settings[id] = value
				end
			end
			WOLFHUD_LOBBY_SETTINGS_LOADED = true
		end

		if data.customize_contract then
			data.difficulty = VHUDPlus:getSetting({"LOBBY_SETTINGS", "difficulty"}, "normal")
			data.difficulty_id = tweak_data:difficulty_to_index(data.difficulty)
			data.one_down = VHUDPlus:getSetting({"LOBBY_SETTINGS", "one_down"}, false)
		end

		local results = { MenuCrimeNetContractInitiator_modify_node_orig(self, original_node, data, ...) }
		local node = table.remove(results, 1)
		
		if data.customize_contract then
			local diff_item = node:item("difficulty")
			if diff_item then
				diff_item:set_value(data.difficulty_id)
			end

			local od_item = node:item("toggle_one_down")
			if od_item then
				od_item:set_value(data.one_down and "on" or "off")
			end
		end
		
		return node, unpack(results or {})
	end
	
	Hooks:Add("MenuManagerBuildCustomMenus", "CreateEmptyLobby_MenuManagerBuildCustomMenus", function(menu_manager, nodes)
	local mainmenu = nodes.main
	    if mainmenu == nil then
		    return
	    end
	
	local data = {
		type = "CoreMenuItem.Item",
	}
	local params = {
		name = "wolfhud_create_empty_lobby_btn",
		text_id = "wolfhud_create_empty_lobby_title",
		help_id = "wolfhud_create_empty_lobby_desc",
		callback = "create_empty_lobby",
		visible_callback = "show_empty_lobby"
	}
	local new_item = mainmenu:create_item(data, params)
	new_item.dirty_callback = callback(mainmenu, mainmenu, "item_dirty")
	    if mainmenu.callback_handler then
		    new_item:set_callback_handler(mainmenu.callback_handler)
	    end

	local position = 2
	    for index, item in pairs(mainmenu._items) do
		    if item:name() == "crimenet" then
			    position = index
			    break
		    end
	    end
	    table.insert(mainmenu._items, position, new_item)
    end)

	function MenuCallbackHandler:show_empty_lobby()
		if VHUDPlus:getSetting({"INVENTORY", "SHOW_EMPTY_LOBBY"}, false) then
			return false
		end
		return true
	end

    function MenuCallbackHandler:create_empty_lobby()
	    if not self:is_online() then
		    managers.menu:show_err_not_signed_in_dialog()
		    return
	    end

	    Global.game_settings.permission = "friends_only"
	    Global.game_settings.level_id = "family"
	    managers.job:deactivate_current_job()
	    managers.gage_assignment:deactivate_assignments()
	    Global.load_level = false
	    Global.level_data.level = nil
	    Global.level_data.mission = nil
	    Global.level_data.world_setting = nil
	    Global.level_data.level_class_name = nil
	    Global.level_data.level_id = nil

	    self:create_lobby()
    end	
elseif string.lower(RequiredScript) == "lib/managers/menu/blackmarketgui" then
	--Always enable mod mini icons, put ghost icon behind silent weapon names
	local populate_weapon_category_new_original = BlackMarketGui.populate_weapon_category_new
	function BlackMarketGui:populate_weapon_category_new(data, ...)
		local value = populate_weapon_category_new_original(self, data, ...)
		local show_icons = not VHUDPlus:getSetting({"INVENTORY", "SHOW_WEAPON_MINI_ICONS"}, true)
		for id, w_data in ipairs(data) do
			if tweak_data.weapon[w_data.name] then	--Filter out locked or empty slots
				local categories = tweak_data.weapon[w_data.name].categories
				local is_saw = table.contains(categories, "saw")
				local has_silencer = table.contains(categories, "bow") or table.contains(categories, "crossbow")
				local has_explosive = false
				for id, i_data in pairs(w_data.mini_icons) do	--Needs to handle silent motor saw
					if i_data.alpha == 1 then		--Icon enabled
						if i_data.texture == "guis/textures/pd2/blackmarket/inv_mod_silencer" then
							has_silencer = true
						elseif i_data.texture == "guis/textures/pd2/blackmarket/inv_mod_ammo_explosive" then
							has_explosive = true
						end
					end
				end
				local silent = has_silencer and not has_explosive
				if VHUDPlus:getSetting({"INVENTORY", "SHOW_SILENT_WEAPONS"}, true) then
					w_data.name_localized = tostring(w_data.name_localized) .. (not is_saw and (" " .. (silent and utf8.char(57363) or "")) or "")
				else
					w_data.name_localized = tostring(w_data.name_localized)
				end
				w_data.hide_unselected_mini_icons = show_icons
			end
		end
		return value
	end

	-- Remove free Buckshot ammo, if you own Gage Shotty DLC
	local populate_mods_original = BlackMarketGui.populate_mods
	function BlackMarketGui:populate_mods(data, ...)
		if managers.dlc:has_dlc("gage_pack_shotgun") and not InFmenu then
			for index, mod_t in ipairs(data.on_create_data or {}) do
				if mod_t[1] == "wpn_fps_upg_a_custom_free"  then
					table.remove(data.on_create_data, index)
					break
				end
			end
		end

		return populate_mods_original(self, data, ...)
	end

	local function getEquipmentAmount(name_id)
		local data = tweak_data.equipments[name_id]
		if data and data.quantity then
			if type(data.quantity) == "table" then
				local amounts = data.quantity
				local amount_str = ""
				for i = 1, #amounts do
					local equipment_name = name_id
					if data.upgrade_name then
						equipment_name = data.upgrade_name[i]
					end
					amount_str = amount_str .. (i > 1 and "/x" or "x") .. tostring((amounts[i] or 0) + managers.player:equiptment_upgrade_value(equipment_name, "quantity"))
				end
				return " (" .. amount_str .. ")"
			else
				return " (x" .. tostring(data.quantity) .. ")"
			end
		end
		return ""
	end

	local populate_deployables_original = BlackMarketGui.populate_deployables
	function BlackMarketGui:populate_deployables(data, ...)
		populate_deployables_original(self, data, ...)
		for i, equipment in ipairs(data) do
			equipment.name_localized = equipment.name_localized .. (equipment.unlocked and getEquipmentAmount(equipment.name) or "")
		end
	end

	local populate_grenades_original = BlackMarketGui.populate_grenades
	function BlackMarketGui:populate_grenades(data, ...)
		populate_grenades_original(self, data, ...)
		local t_data = tweak_data.blackmarket.projectiles
		for i, throwable in ipairs(data) do
			local has_amount = throwable.unlocked and t_data[throwable.name] or false
			throwable.name_localized = throwable.name_localized .. (has_amount and " (x" .. t_data[throwable.name].max_amount .. ")" or "")
		end
	end

	-- Show all Names in Inventory Boxxes
	local orig_blackmarket_gui_slot_item_init = BlackMarketGuiSlotItem.init
	function BlackMarketGuiSlotItem:init(main_panel, data, ...)
		if VHUDPlus:getSetting({"INVENTORY", "SHOW_WEAPON_NAMES"}, true) then
			data.custom_name_text = data.custom_name_text or not data.empty_slot and data.name_localized
		end
		return orig_blackmarket_gui_slot_item_init(self, main_panel, data, ...)
	end

	local orig_blackmarket_gui_slot_item_select = BlackMarketGuiItem.select
	function BlackMarketGuiItem:select(instant, ...)
		self._is_selected = true
		self:set_highlight(true, instant)

		return orig_blackmarket_gui_slot_item_select(self, instant, ...)
	end

	local orig_blackmarket_gui_slot_item_deselect = BlackMarketGuiItem.deselect
	function BlackMarketGuiItem:deselect(instant, ...)
		self._is_selected = false
		self:set_highlight(false, instant)

		return orig_blackmarket_gui_slot_item_deselect(self, instant, ...)
	end

	local orig_blackmarket_gui_slot_item_set_highlight = BlackMarketGuiSlotItem.set_highlight
	function BlackMarketGuiSlotItem:set_highlight(highlight, ...)
		if highlight or self._is_selected or self._data.equipped then
			local name_text = self._panel:child("custom_name_text")
			if name_text then
				name_text:set_alpha(1)
			end
			if self._mini_panel then
				self._mini_panel:set_alpha(1)
			end
		else
			local name_text = self._panel:child("custom_name_text")
			if name_text then
				name_text:set_alpha(0.5)
			end
			if self._mini_panel then
				self._mini_panel:set_alpha(0.4)
			end
		end

		return orig_blackmarket_gui_slot_item_set_highlight(self, highlight, ...)
	end

	local orig_blackmarket_gui_set_selected_tab = BlackMarketGui.set_selected_tab
	function BlackMarketGui:set_selected_tab(...)
		local value = orig_blackmarket_gui_set_selected_tab(self, ...)

		local current_tab = self._tabs[self._selected]
		local selected_slot = current_tab and current_tab._slots[current_tab._slot_selected]
		local highlighted_slot 	= current_tab and current_tab._slots[current_tab._slot_highlighted]

		if selected_slot then
			selected_slot:select(true, true)
			if highlighted_slot and selected_slot ~= highlighted_slot then
				selected_slot:set_highlight(false, true)
				highlighted_slot:set_highlight(true, false)
			end
		end

		return value
	end

	if VHUDPlus:getSetting({"INVENTORY", "SHOW_CUSTOM_INVENTORY_PAGES_NAMES"}, true) then

		--Replace Tab Names with custom ones...
		BlackMarketGui._SUB_TABLE = {
			["<SKULL>"] = utf8.char(57364),	--Skull icon
			["<GHOST>"] = utf8.char(57363),	--Ghost icon
		}

		local BlackMarketGui__setup_original = BlackMarketGui._setup
		function BlackMarketGui:_setup(is_start_page, component_data)
			self._renameable_tabs = false
			component_data = component_data or self:_start_page_data()
			local inv_name_tweak = VHUDPlus:getSetting({"INVENTORY", "CUSTOM_TAB_NAMES"}, {})
			if inv_name_tweak then
				for i, tab_data in ipairs(component_data) do
					if not tab_data.prev_node_data then
						local category_tab_names = inv_name_tweak[tab_data.category]
						local custom_tab_name = category_tab_names and category_tab_names[i] or ""
						for key, subst in pairs(BlackMarketGui._SUB_TABLE) do
							custom_tab_name = custom_tab_name:upper():gsub(key, subst)
						end
						if string.len(custom_tab_name or "") > 0 then
							tab_data.name_localized = custom_tab_name or tab_data.name_localized
						end
						self._renameable_tabs = self._renameable_tabs or category_tab_names and true or false
					end
				end
			end

			BlackMarketGui__setup_original(self, is_start_page, component_data)

			if self._renameable_tabs and self._tabs[1] then
				local first_tab_name = self._tabs[1]._tab_panel and self._tabs[1]._tab_panel:child("tab_text")
				self._renameable_tabs = first_tab_name:visible()
			end

			if self._renameable_tabs and not component_data.is_loadout  and alive(self._panel) then
				-- create rename tab info text
				local legends_panel = self._panel:panel({
					name = "LegendsPanel",
					w = self._panel:w() * 0.75,
					h = tweak_data.menu.pd2_medium_font_size
				})
				legends_panel:set_righttop(self._panel:w(), 0)
				legends_panel:text({
					name = "LegendText",
					text = managers.localization:text("wolfhud_inv_tab_rename_hint"),
					font = tweak_data.menu.pd2_small_font,
					font_size = tweak_data.menu.pd2_small_font_size,
					color = tweak_data.screen_colors.text,
					alpha = 0.8,
					blend_mode = "add",
					align = "right",
					vertical = "top"
				})
			end
		end

		-- Input Dialog on double click selected tab
		local BlackMarketGui_mouse_clicked_original = BlackMarketGui.mouse_clicked
		function BlackMarketGui:mouse_clicked(...)
			BlackMarketGui_mouse_clicked_original(self, ...)

			if not self._enabled or not self._mouse_click or not self._mouse_click[0] or not self._mouse_click[1] then
				return
			end
			
			self._mouse_click[self._mouse_click_index].selected_tab = self._selected
		end

		local BlackMarketGui_mouse_double_click_original = BlackMarketGui.mouse_double_click
		function BlackMarketGui:mouse_double_click(o, button, x, y)
			if self._enabled and not self._data.is_loadout and self._renameable_tabs then
				if self._mouse_click and self._mouse_click[0] and self._mouse_click[1] then
					if self._tabs and self._mouse_click[0].selected_tab == self._mouse_click[1].selected_tab then
						local current_tab = self._tabs[self._selected]
						if current_tab and button == Idstring("0") then
							if self._tab_scroll_panel:inside(x, y) and current_tab:inside(x, y) ~= 1 then
								self:rename_tab_clbk(current_tab, self._selected)
								return
							end
						end
					end
				end
			end

			BlackMarketGui_mouse_double_click_original(self, o, button, x, y)
		end

		function BlackMarketGui:rename_tab_clbk(tab, tab_id)
			local current_tab = tab or self._tabs[self._selected]
			local tab_data = self._data[self._selected]
			local inv_name_tweak = VHUDPlus:getSetting({"INVENTORY", "CUSTOM_TAB_NAMES"}, nil)
			if current_tab and tab_data and inv_name_tweak and not self:in_setup()then
				local prev_name = inv_name_tweak[tab_data.category] and inv_name_tweak[tab_data.category][tab_id or self._selected] or current_tab._tab_text_string
				local menu_options = {
					[1] = {
						text = managers.localization:text("wolfhud_dialog_save"),
						callback = function(cb_data, button_id, button, text)
							if self._data and text and text ~= "" then
								if tab_data and inv_name_tweak then
									inv_name_tweak[tab_data.category] = inv_name_tweak[tab_data.category] or {}
									inv_name_tweak[tab_data.category][tab_id or self._selected] = text
									VHUDPlus:Save()

									for key, subst in pairs(BlackMarketGui._SUB_TABLE) do
										text = text:upper():gsub(key, subst)
									end

									current_tab._tab_text_string = text
									local name = current_tab._tab_panel:child("tab_text")
									if alive(name) then
										name:set_text(text)
									end
									self:rearrange_tab_width(true)
									self:_round_everything()
								end
							end
						end,
					},
					[2] = {
						text = managers.localization:text("dialog_cancel"),
						is_cancel_button = true,
					}
				}
				QuickInputMenu:new(managers.localization:text("wolfhud_dialog_rename_inv_tab"), managers.localization:text("wolfhud_dialog_rename_inv_tab_desc"), prev_name, menu_options, true, {w = 420, to_upper = true, max_len = 15})

				return
			end
		end

		function BlackMarketGui:rearrange_tab_width(start_with_selected)
			local current = start_with_selected and self._selected or 1
			local start = current + 1
			local stop = #self._tabs

			local current_tab = self._tabs[current]
			if current_tab then
				local current_panel = current_tab._tab_panel
				local current_text = current_panel and current_panel:child("tab_text")
				local current_selection = current_panel and current_panel:child("tab_select_rect")
				if alive(current_panel) and alive(current_text) and alive(current_selection) then
					local _, _, w, _ = current_text:text_rect()
					current_panel:set_w(w + 15)
					current_selection:set_w(w + 15)
					current_text:set_w(w + 15)
					current_text:set_center_x(current_panel:w() / 2)
				end
			end

			local offset = alive(self._tabs[current]._tab_panel) and self._tabs[current]._tab_panel:right() or 0
			for i = start, stop do
				local tab = self._tabs[i]
				local tab_panel = tab._tab_panel
				if alive(tab._tab_panel) then
					offset = tab:set_tab_position(offset)
				end

			end
		end
	end
elseif string.lower(RequiredScript) == "lib/managers/menu/skilltreeguinew" then
	local orig_newskilltreeskillitem_refresh = NewSkillTreeSkillItem.refresh
	function NewSkillTreeSkillItem:refresh(...)
		local value = orig_newskilltreeskillitem_refresh(self, ...)

		--Always show Skill names
		if alive(self._skill_panel) and VHUDPlus:getSetting({"INVENTORY", "SHOW_SKILL_NAMES"}, true) then
			local skill_name = self._skill_panel:child("SkillName")
			if skill_name then
				local unlocked = self._skill_id and self._tree and managers.skilltree and managers.skilltree:skill_unlocked(self._tree, self._skill_id) or false
				local step = (self._skilltree:next_skill_step(self._skill_id) or 0)
				local skilled = unlocked and step > 0
				skill_name:set_visible(true)
				skill_name:set_alpha(self._selected and 1 or skilled and 0.6 or 0.4)
			end
		end

		return value
	end

	--Fix mouse pointer for locked skills
	local orig_newskilltreeskillitem_is_active = NewSkillTreeSkillItem.is_active
	function NewSkillTreeSkillItem:is_active(...)
		local unlocked = self._skill_id and self._tree and managers.skilltree and managers.skilltree:skill_unlocked(self._tree, self._skill_id) or false
		return orig_newskilltreeskillitem_is_active(self, ...) or not unlocked
	end

	--Resize and move total points label
	local orig_newskilltreetieritem_init = NewSkillTreeTierItem.init
	local orig_newskilltreetieritem_refresh_points = NewSkillTreeTierItem.refresh_points
	local orig_newskilltreetieritem_refresh_tier_text = NewSkillTreeTierItem._refresh_tier_text
	function NewSkillTreeTierItem:init(...)
		local val = orig_newskilltreetieritem_init(self, ...)
			if self._tier_points_total and self._tier_points_total_zero and self._tier_points_total_curr then
				local font_size = tweak_data.menu.pd2_small_font_size * 0.75
				self._tier_points_total:set_font_size(font_size)
				local _, _, w, h = self._tier_points_total:text_rect()
				self._tier_points_total:set_size(w, h)
				self._tier_points_total_zero:set_font_size(font_size)
				self._tier_points_total_curr:set_font_size(font_size)
				self._tier_points_total:set_alpha(0.9)
				self._tier_points_total_curr:set_alpha(0.9)
				self._tier_points_total_zero:set_alpha(0.6)
			end
		return val
	end
	function NewSkillTreeTierItem:refresh_points(selected, ...)
		orig_newskilltreetieritem_refresh_points(self, selected, ...)
			if alive(self._tier_points_total) and alive(self._tier_points_total_zero) and alive(self._tier_points_total_curr) then
				self._tier_points_total:set_y(self._text_space or 10)
				self._tier_points_total_zero:set_y(self._text_space or 10)
				self._tier_points_total_curr:set_y(self._text_space or 10)
			end
			if alive(self._tier_points_0) and alive(self._tier_points) then
				self._tier_points:set_visible(not self._tier_points_needed:visible())
				self._tier_points_0:set_visible(not self._tier_points_needed:visible())
			end
	end
	function NewSkillTreeTierItem:_refresh_tier_text(selected, ...)
		orig_newskilltreetieritem_refresh_tier_text(self, selected, ...)
			if selected and alive(self._tier_points_needed) and alive(self._tier_points_needed_curr) and alive(self._tier_points_needed_zero) then
				self._tier_points_needed_zero:set_left(self._tier_points_0:left())
				self._tier_points_needed_curr:set_left(self._tier_points_needed_zero:right())
				self._tier_points_needed:set_left(self._tier_points_needed_curr:right() + self._text_space)
			end
			if alive(self._tier_points_0) and alive(self._tier_points) then
				self._tier_points:set_visible(not self._tier_points_needed:visible())
				self._tier_points_0:set_visible(not self._tier_points_needed:visible())
			end
	end
elseif string.lower(RequiredScript) == "lib/tweak_data/tweakdata" then
	if tweak_data then
		-- Give Sound sliders a step size of 1%.
		tweak_data.menu = tweak_data.menu or {}
		tweak_data.menu.MUSIC_CHANGE = 1
		tweak_data.menu.SFX_CHANGE = 1
		tweak_data.menu.VOICE_CHANGE = 0.01

		if Network:is_server() and VHUDPlus:getSetting({"SkipIt", "INSTANT_RESTART"}, false) then
			tweak_data.vote = tweak_data.vote or {}
			tweak_data.voting.restart_delay = 0
		end
	end
elseif string.lower(RequiredScript) == "lib/tweak_data/guitweakdata" then
	local GuiTweakData_init_orig = GuiTweakData.init
	function GuiTweakData:init(...)
		GuiTweakData_init_orig(self, ...)
		self.rename_max_letters = VHUDPlus:getTweakEntry("MAX_WEAPON_NAME_LENGTH", "number", 30)
		self.rename_skill_set_max_letters = VHUDPlus:getTweakEntry("MAX_SKILLSET_NAME_LENGTH", "number", 25)

		if false then
			table.insert(self.crime_net.special_contracts, {
				id = "random_contract",
				name_id = "menu_cn_random_contract",
				desc_id = "menu_cn_random_contract_desc",
				menu_node = nil,
				x = 550,
				y = 640,
				icon = "guis/textures/pd2/crimenet_challenge"
			})
		end
	end
elseif string.lower(RequiredScript) == "lib/managers/crimenetmanager" then
	local check_job_pressed = CrimeNetGui.check_job_pressed
	function CrimeNetGui:check_job_pressed(...)
		if self._jobs["random_contract"] and self._jobs["random_contract"].mouse_over == 1 then
			local job_id = tweak_data.narrative._jobs_index[math.random(#tweak_data.narrative._jobs_index)]
			local job_tweak = tweak_data.narrative:job_data(job_id)
			local data = {
				job_id = job_id,
				difficulty = "normal",
				difficulty_id = 2,
				professional = job_tweak.professional or false,
				competitive = job_tweak.competitive or false,
				customize_contract = true,
				contract_visuals = job_tweak.contract_visuals,
				server = false,
				special_node = Global.game_settings.single_player and "crimenet_contract_singleplayer" or "crimenet_contract_host",
			}
			for k, v in pairs(data) do
				self._jobs["random_contract"][k] = v
			end
		end

		return check_job_pressed(self, ...)
	end
	CrimeNetGui.DIFF_COLORS = {
		Color(0/6, 6/6, 0),	-- normal
		Color(1/6, 5/6, 0),	-- hard
		Color(2/6, 4/6, 0),	-- very hard
		Color(3/6, 3/6, 0),	-- overkill
		Color(4/6, 2/6, 0),	-- mayhem
		Color(5/6, 1/6, 0),	-- death wish
		Color(6/6, 0/6, 0),	-- death sentence
	}

	local _create_locations_original = CrimeNetGui._create_locations
	local _get_job_location_original = CrimeNetGui._get_job_location
	local _create_job_gui_original = CrimeNetGui._create_job_gui
	local colorizeCrNt = VHUDPlus:getSetting({"INVENTORY", "crnt_colorize"}, true)

	function CrimeNetGui:_create_locations()
		_create_locations_original(self)
		if VHUDPlus:getSetting({"INVENTORY", "crnt_align"}, true) then
			local newDots = {}
			local xx,yy = 12,10
			for i=1,xx do -- 224~1666 1442
				for j=1,yy do -- 165~945 780
					--local newX = 150+ 1642*i/xx
					--local newY = 150+ 680*(i % 2 == 0 and j or j - 0.5)/yy
					local newX = 180+ 1642*i/xx
					local newY = 180+ 680*(i % 2 == 0 and j or j - 0.5)/yy
					if  (i >= 3) or ( j < 7 ) then
						-- avoiding fixed points
						table.insert(newDots,{ newX, newY })
					end
				end
			end
			self._locations[1][1].dots = newDots
		end
	end

	function CrimeNetGui:_create_job_gui(data, type, fixed_x, fixed_y, fixed_location, ...)
		local sizeMulCrNt = VHUDPlus:getSetting({"INVENTORY", "crnt_size"}, 0.7)

		local x = fixed_x
		local y = fixed_y
		local size = tweak_data.menu.pd2_small_font_size
		tweak_data.menu.pd2_small_font_size = size * sizeMulCrNt
		local result = _create_job_gui_original(self, data, type, fixed_x, fixed_y, fixed_location, ...)
		tweak_data.menu.pd2_small_font_size = size
		if colorizeCrNt and result and result.side_panel and result.side_panel:child('job_name') and not data.mutators and not data.is_skirmish and not data.is_crime_spree and type ~= "crime_spree" then
			result.side_panel:child('job_name'):set_color(CrimeNetGui.DIFF_COLORS[(data.difficulty_id or 2) - 1] or Color.white)
		end
		if colorizeCrNt then
			local map = self._map_panel:child("map")
			map:set_color(Color( 171 / 255, 181 / 255, 130 / 255 ))
		end
		if colorizeCrNt and result and result.heat_glow then
			result.heat_glow:set_alpha(result.heat_glow:alpha()*0.5)
		end
		return result
	end

	local _create_polylines_original = CrimeNetGui._create_polylines
	local HoloCrashFix = Holo and Holo.Options:GetValue("ColoredBackground")
	function CrimeNetGui:_create_polylines()
		if colorizeCrNt and not HoloCrashFix then
			self._region_locations = {} -- used by _set_zoom()
		else
			_create_polylines_original(self)
		end
	end

	function CrimeNetGui:_get_job_location(data)
		if VHUDPlus:getSetting({"INVENTORY", "crnt_align"}, true) or VHUDPlus:getSetting({"INVENTORY", "crnt_sort"}, true) then
			_get_job_location_original(self, data)
			local diff = (data and data.difficulty_id or 2) - 2
			local diffX = 236 + ( 1700 / 7 ) * diff
			local locations = self:_get_contact_locations()
			local sorted = {}
				for k,dot in pairs(locations[1].dots) do
				if not dot[3] then
					table.insert(sorted,dot)
				end
			end
			if #sorted > 0 then
				local abs = math.abs
				table.sort(sorted,function(a,b)
					return abs(diffX-a[1]) < abs(diffX-b[1])
				end)
				local dot = sorted[1]
				local x,y = dot[1],dot[2]
				local tw = math.max(self._map_panel:child("map"):texture_width(), 1)
				local th = math.max(self._map_panel:child("map"):texture_height(), 1)
				x = math.round(x / tw * self._map_size_w)
				y = math.round(y / th * self._map_size_h)

				return x,y,dot
			end
		else
			return _get_job_location_original(self, data)
		end
	end
	
	local update_server_job_original = CrimeNetGui.update_server_job
	function CrimeNetGui:update_server_job(data, i, ...)
		update_server_job_original(self, data, i, ...)

		-- get job data
		local job_index = data.id or i
		local job = self._jobs[job_index]

		-- colorize by difficulty
		if job.side_panel and colorizeCrNt and not data.mutators and not data.is_crime_spree then
			job.side_panel:child("job_name"):set_color(CrimeNetGui.DIFF_COLORS[(data.difficulty_id or 2) - 1] or Color.white)
		end
	end

	-- Fix Crime.net refresh performance
	local find_online_games_original = CrimeNetManager._find_online_games_win32
	function CrimeNetManager:_find_online_games_win32(friends_only)
		local function f(info)
			managers.network.matchmake:search_lobby_done()

			local room_list = info.room_list
			local attribute_list = info.attribute_list
			local dead_list = {}

			for id, _ in pairs(self._active_server_jobs) do
				dead_list[id] = true
			end

			local friends_cache = {}
			local steam_friends = Steam:logged_on() and Steam:friends()
			if steam_friends then
				for _, friend in ipairs(steam_friends) do
					friends_cache[friend:id()] = true
				end
			end

			for i, room in ipairs(room_list) do
				local name_str = tostring(room.owner_name)
				local attributes_numbers = attribute_list[i].numbers
				local attributes_mutators = attribute_list[i].mutators

				if managers.network.matchmake:is_server_ok(friends_only, room.owner_id, attribute_list[i], nil) then
					dead_list[room.room_id] = nil
					local host_name = name_str
					local level_id = tweak_data.levels:get_level_name_from_index(attributes_numbers[1] % 1000)
					local name_id = level_id and tweak_data.levels[level_id] and tweak_data.levels[level_id].name_id
					local level_name = name_id and managers.localization:text(name_id) or "LEVEL NAME ERROR"
					local difficulty_id = attributes_numbers[2]
					local difficulty = tweak_data:index_to_difficulty(difficulty_id)
					local job_id = tweak_data.narrative:get_job_name_from_index(math.floor(attributes_numbers[1] / 1000))
					local kick_option = attributes_numbers[8]
					local job_plan = attributes_numbers[10]
					local drop = attributes_numbers[6]
					local permission = attributes_numbers[3]
					local min_level = attributes_numbers[7]
					local state_string_id = tweak_data:index_to_server_state(attributes_numbers[4])
					local state_name = state_string_id and managers.localization:text("menu_lobby_server_state_" .. state_string_id) or
						"UNKNOWN"
					local state = attributes_numbers[4]
					local num_plrs = attributes_numbers[5]
					local is_friend = friends_cache[room.room_id] == true

					if name_id then
						if not self._active_server_jobs[room.room_id] then
							if table.size(self._active_jobs) + table.size(self._active_server_jobs) <
								tweak_data.gui.crime_net.job_vars.total_active_jobs and
								table.size(self._active_server_jobs) < self._max_active_server_jobs then
								self._active_server_jobs[room.room_id] = {
									added = false,
									alive_time = 0
								}

								managers.menu_component:add_crimenet_server_job({
									room_id = room.room_id,
									host_id = room.owner_id,
									id = room.room_id,
									level_id = level_id,
									difficulty = difficulty,
									difficulty_id = difficulty_id,
									num_plrs = num_plrs,
									host_name = host_name,
									state_name = state_name,
									state = state,
									level_name = level_name,
									job_id = job_id,
									is_friend = is_friend,
									kick_option = kick_option,
									job_plan = job_plan,
									mutators = attribute_list[i].mutators,
									is_crime_spree = attribute_list[i].crime_spree and attribute_list[i].crime_spree >= 0,
									crime_spree = attribute_list[i].crime_spree,
									crime_spree_mission = attribute_list[i].crime_spree_mission,
									drop = drop,
									permission = permission,
									min_level = min_level,
									mods = attribute_list[i].mods,
									one_down = attribute_list[i].one_down,
									is_skirmish = attribute_list[i].skirmish and attribute_list[i].skirmish > 0,
									skirmish = attribute_list[i].skirmish,
									skirmish_wave = attribute_list[i].skirmish_wave,
									skirmish_weekly_modifiers = attribute_list[i].skirmish_weekly_modifiers
								})
							end
						else
							managers.menu_component:update_crimenet_server_job({
								room_id = room.room_id,
								host_id = room.owner_id,
								id = room.room_id,
								level_id = level_id,
								difficulty = difficulty,
								difficulty_id = difficulty_id,
								num_plrs = num_plrs,
								host_name = host_name,
								state_name = state_name,
								state = state,
								level_name = level_name,
								job_id = job_id,
								is_friend = is_friend,
								kick_option = kick_option,
								job_plan = job_plan,
								mutators = attribute_list[i].mutators,
								is_crime_spree = attribute_list[i].crime_spree and attribute_list[i].crime_spree >= 0,
								crime_spree = attribute_list[i].crime_spree,
								crime_spree_mission = attribute_list[i].crime_spree_mission,
								drop = drop,
								permission = permission,
								min_level = min_level,
								mods = attribute_list[i].mods,
								one_down = attribute_list[i].one_down,
								is_skirmish = attribute_list[i].skirmish and attribute_list[i].skirmish > 0,
								skirmish = attribute_list[i].skirmish,
								skirmish_wave = attribute_list[i].skirmish_wave,
								skirmish_weekly_modifiers = attribute_list[i].skirmish_weekly_modifiers
							})
						end
					end
				end
			end

			for id, _ in pairs(dead_list) do
				self._active_server_jobs[id] = nil

				managers.menu_component:remove_crimenet_gui_job(id)
			end
		end

		managers.network.matchmake:register_callback("search_lobby", f)
		managers.network.matchmake:search_lobby(friends_only)

		local function usrs_f(success, amount)
			if success then
				managers.menu_component:set_crimenet_players_online(amount)
			end
		end

		Steam:sa_handler():concurrent_users_callback(usrs_f)
		Steam:sa_handler():get_concurrent_users()
	end

elseif string.lower(RequiredScript) == "core/lib/managers/menu/items/coremenuitemslider" then
	core:module("CoreMenuItemSlider")
	--core:import("CoreMenuItem")
	local init_actual = ItemSlider.init
	local highlight_row_item_actual = ItemSlider.highlight_row_item
	local set_value_original = ItemSlider.set_value
	local set_enabled_original = ItemSlider.set_enabled
	local reload_original = ItemSlider.reload
	function ItemSlider:init(...)
		init_actual(self, ...)
		self._show_slider_text = true
	end

	function ItemSlider:highlight_row_item(node, row_item, mouse_over, ...)
		local val = highlight_row_item_actual(self, node, row_item, mose_over, ...)
		row_item.gui_slider_gfx:set_gradient_points({
			0, self:slider_highlighted_color():with_alpha(0.6),
			1, self:slider_highlighted_color():with_alpha(0.6)
		})
		return val
	end

	-- function ItemSlider:set_value(value, ...)
	-- 	local times = math.round((value - self._min) / self._step)
	-- 	value = self._min + self._step * times

	-- 	set_value_original(self, value, ...)
	-- end

	function ItemSlider:set_enabled(...)
		set_enabled_original(self, ...)
		if self._enabled then
			self:set_slider_color(_G.tweak_data.screen_colors.button_stage_3)
			self:set_slider_highlighted_color(_G.tweak_data.screen_colors.button_stage_2)
		else
			self:set_slider_color(Color(0.4, 0.4, 0.4, 0.4))
			self:set_slider_highlighted_color(Color(0.2, 0.4, 0.4, 0.4))
		end
	end

	function ItemSlider:reload(row_item, ...)
		local val = reload_original(self, row_item, ...)

		if row_item and row_item.color then
			row_item.gui_text:set_color(row_item.color)
			row_item.gui_slider_text:set_color(row_item.color)
		end

		return val
	end
elseif string.lower(RequiredScript) == "lib/states/ingamewaitingforplayers" then
	local SKIP_BLACKSCREEN = VHUDPlus:getSetting({"SkipIt", "SKIP_BLACKSCREEN"}, true)
	local update_original = IngameWaitingForPlayersState.update
	function IngameWaitingForPlayersState:update(...)
		update_original(self, ...)

		if self._skip_promt_shown and SKIP_BLACKSCREEN and not IntroCinematics then
			self:_skip()
		end
	end
elseif string.lower(RequiredScript) == "lib/managers/menu/stageendscreengui" then
	local init_original = StageEndScreenGui.init
	local update_original = StageEndScreenGui.update
	local special_btn_pressed_original = StageEndScreenGui.special_btn_pressed
	local special_btn_released_original = StageEndScreenGui.special_btn_released
	TheFixesPreventer = TheFixesPreventer or {}
	TheFixesPreventer.end_screen_continue_button = true
	function StageEndScreenGui:init(...)
		init_original(self, ...)

		if self._enabled and VHUDPlus:getSetting({"SkipIt", "STAT_SCREEN_SPEEDUP"}, false) and managers.hud then
			managers.hud:set_speed_up_endscreen_hud(5)
		end
	end

	local SKIP_STAT_SCREEN_DELAY = VHUDPlus:getSetting({"SkipIt", "STAT_SCREEN_DELAY"}, 5)
	function StageEndScreenGui:update(t, ...)
		update_original(self, t, ...)
		if not self._button_not_clickable and SKIP_STAT_SCREEN_DELAY > 0 then
			self._auto_continue_t = self._auto_continue_t or (t + SKIP_STAT_SCREEN_DELAY)
			local gsm = game_state_machine:current_state()
			if gsm and gsm._continue_cb and not (gsm._continue_blocked and gsm:_continue_blocked()) and t >= self._auto_continue_t then
				managers.menu_component:post_event("menu_enter")
				gsm._continue_cb()
			end
		end
	end

	function StageEndScreenGui:special_btn_pressed(...)
		if not VHUDPlus:getSetting({"SkipIt", "STAT_SCREEN_SPEEDUP"}, false) then
			special_btn_pressed_original(self, ...)
		end
	end

	function StageEndScreenGui:special_btn_released(...)
		if not VHUDPlus:getSetting({"SkipIt", "STAT_SCREEN_SPEEDUP"}, false) then
			special_btn_released_original(self, ...)
		end
	end
elseif string.lower(RequiredScript) == "lib/managers/menu/lootdropscreengui" then
	local SKIP_LOOT_SCREEN_DELAY = VHUDPlus:getSetting({"SkipIt", "LOOT_SCREEN_DELAY"}, 3)
	local AUTO_PICK_CARD = VHUDPlus:getSetting({"SkipIt", "AUTOPICK_CARD"}, true)
	local AUTO_PICK_SPECIFIC_CARD = VHUDPlus:getSetting({"SkipIt", "AUTOPICK_CARD_SPECIFIC"}, 1)
	local update_original = LootDropScreenGui.update
	function LootDropScreenGui:update(t, ...)
		update_original(self, t, ...)

		if not self._card_chosen and AUTO_PICK_CARD then
			local autopicked_card = AUTO_PICK_SPECIFIC_CARD
			if autopicked_card == 4 then
				autopicked_card = math.random(3)
			end
			self:_set_selected_and_sync(autopicked_card)
			self:confirm_pressed()
		end

		if not self._button_not_clickable and SKIP_LOOT_SCREEN_DELAY > 0 then
			self._auto_continue_t = self._auto_continue_t or (t + SKIP_LOOT_SCREEN_DELAY)
			local gsm = game_state_machine:current_state()
			if gsm and not (gsm._continue_blocked and gsm:_continue_blocked()) and t >= self._auto_continue_t then
				self:continue_to_lobby()
			end
		end
	end
elseif string.lower(RequiredScript) == "lib/managers/menu/contractboxgui" then
	local create_character_text_original = ContractBoxGui.create_character_text

	function ContractBoxGui:create_character_text(peer_id, ...)
		create_character_text_original(self, peer_id, ...)

		if managers.network:session() and VHUDPlus:getSetting({"CrewLoadout", "ENABLE_PEER_PING"}, true) then
			if managers.network:session():local_peer():id() ~= peer_id then
				local peer_label = self._peers[peer_id]
				if alive(peer_label) then
					local peer = managers.network:session():peer(peer_id)
					local latency = peer and Network:qos(peer:rpc()).ping or 0
					local x, y = peer_label:center_x(), peer_label:top()
					local LPI_offset = LobbyPlayerInfo and (LobbyPlayerInfo.settings.show_play_time_mode or 0) > 1 and LobbyPlayerInfo:GetFontSizeForPlayTime() or 0

					self._peer_latency = self._peer_latency or {}
					self._peer_latency[peer_id] = self._peer_latency[peer_id] or self._panel:text({
						name = tostring(peer_id) .. "_latency",
						text = "",
						align = "center",
						vertical = "center",
						font = tweak_data.menu.pd2_medium_font,
						font_size = tweak_data.menu.pd2_medium_font_size * 0.8,
						layer = 0,
						color = tweak_data.chat_colors[peer_id] or Color.white,
						alpha = 0.8,
						blend_mode = "add"
					})
					self._peer_latency[peer_id]:set_text( latency > 0 and string.format("%.0fms", latency) or "" )
					self._peer_latency[peer_id]:set_visible(self._enabled)
					local _, _, w, h = self._peer_latency[peer_id]:text_rect()
					self._peer_latency[peer_id]:set_size(w, h)
					self._peer_latency[peer_id]:set_center_x(x)
					self._peer_latency[peer_id]:set_bottom(y - LPI_offset)
				end
			end
		end
		
		local peer_label = self._peers[peer_id]
		local x, y = peer_label:center_x(), peer_label:top()
        local voice_icon, voice_texture_rect = tweak_data.hud_icons:get_icon_data('wp_talk')
		local talking, latency_offset
					
		if is_local_peer and not managers.network.voice_chat._push_to_talk then
		    talking = managers.network.voice_chat._enabled
	    else
		    talking = managers.network.voice_chat._users_talking[peer_id] and managers.network.voice_chat._users_talking[peer_id].active
	    end
		
		local LPI_HOUR = LobbyPlayerInfo and (LobbyPlayerInfo.settings.show_play_time_mode or 0) > 1 and LobbyPlayerInfo:GetFontSizeForPlayTime() or 0
		local LPI_offset = 15 + LPI_HOUR
		
		if VHUDPlus:getSetting({"CrewLoadout", "ENABLE_PEER_PING"}, true) and LobbyPlayerInfo then
		    latency_offset = LPI_offset
		elseif not VHUDPlus:getSetting({"CrewLoadout", "ENABLE_PEER_PING"}, true) and LobbyPlayerInfo then
		    latency_offset = LPI_HOUR
		elseif VHUDPlus:getSetting({"CrewLoadout", "ENABLE_PEER_PING"}, true) and not LobbyPlayerInfo then
		    latency_offset = 20
		else
		    latency_offset = 0
		end
					
		self._peers_talking = self._peers_talking or {}
	    self._peers_talking[peer_id] = self._peers_talking[peer_id] or self._panel:bitmap({
		    texture = voice_icon,
		    layer = 0,
	        texture_rect = voice_texture_rect,
		    w = voice_texture_rect[3],
		    h = voice_texture_rect[4],
		    color = color,
		    blend_mode = 'add',
		    alpha = 1
	    })
	    self._peers_talking[peer_id]:set_center_x(x)
	    self._peers_talking[peer_id]:set_bottom(y - latency_offset)
	    self._peers_talking[peer_id]:set_visible(talking)		
	end
elseif string.lower(RequiredScript) == "lib/managers/menu/renderers/menunodeskillswitchgui" then
	local _create_menu_item=MenuNodeSkillSwitchGui._create_menu_item
	function MenuNodeSkillSwitchGui:_create_menu_item(row_item, ...)
		_create_menu_item(self, row_item, ...)
		if row_item.type~="divider" and row_item.name~="back" then
			local gd=Global.skilltree_manager.skill_switches[row_item.name]
			row_item.status_gui:set_text( managers.localization:to_upper_text( ("menu_st_spec_%d"):format( managers.skilltree:digest_value(gd.specialization, false, 1) or 1 ) ) )
			if row_item.skill_points_gui:text() == managers.localization:to_upper_text("menu_st_points_all_spent_skill_switch") then
				local pts, pt, pp, st, sp=0, 1, 0, 2, 0
				for i=1, #gd.trees do
					pts=Application:digest_value(gd.trees[i].points_spent, false)
					if pts>pp then
						sp, st, pp, pt=pp, pt, pts, i
					elseif pts>sp then
						sp, st=pts, i
					end
				end
				row_item.skill_points_gui:set_text(	managers.localization:to_upper_text( tweak_data.skilltree.trees[pt].name_id	) .." / "..	managers.localization:to_upper_text( tweak_data.skilltree.trees[st].name_id	) )
			end
		elseif row_item.type == "divider" and row_item.name == "divider_title" then
			if alive(row_item.status_gui) then
				row_item.status_gui:set_text(managers.localization:to_upper_text("menu_specialization", {}) .. ":")
			end
		end
	end
elseif string.lower(RequiredScript) == "lib/managers/chatmanager" then
	if not VHUDPlus:getSetting({"HUDChat", "SPAM_FILTER"}, true) then return end
	ChatManager._SUB_TABLE = {
		[utf8.char(57364)] = "<SKULL>",	--Skull icon
		[utf8.char(57363)] = "<GHOST>",	--Ghost icon
		[utf8.char(139)] = "<LC>",		--broken bar
		[utf8.char(155)] = "<RC>",
		[utf8.char(1035)] = "<DRC>",
		[utf8.char(1014)] = "<DIV>",	--PocoHuds bar
		[utf8.char(57344)] = "<A>",		--Controller A
		[utf8.char(57345)] = "<B>",		--Controller B
		[utf8.char(57346)] = "<X>",		--Controller X
		[utf8.char(57347)] = "<Y>",		--Controller Y
		[utf8.char(57348)] = "<BACK>",	--Controller BACK
		[utf8.char(57349)] = "<START>",	--Controller START
		[utf8.char(1031)] = "<DOT>",
		[utf8.char(1015)] = "<CHAPTER>",
		[utf8.char(1012)] = "<BIGDOT>",
		[utf8.char(215)] = "<TIMES>",	--Mult
		[utf8.char(247)] = "<DIVIDED>",	--Divided
		[utf8.char(1024)] = "<DEG>",	--Degree
		[utf8.char(1030)] = "<PM>",		--PM Sign
		[utf8.char(1033)] = "<NO>"		--Number

	}

	ChatManager._BLOCK_PATTERNS = {
		".-%[NGBT%w+%].+",
		--NGBTO info blocker Should work since its mass spam.
		"[%d:]+%d:%d%d.-<DIV>.+",
		--Blocks anything, that starts with numbers and ':' and then has a divider (Might block other mods, not only Poco...)
		"Replenished: .+",
	}

	local _receive_message_original = ChatManager._receive_message

	function ChatManager:_receive_message(channel_id, name, message, ...)
		local message2 = message or ""
		for key, subst in pairs(ChatManager._SUB_TABLE) do
			message2 = message2:gsub(key, subst)
		end
		for _, pattern in ipairs(ChatManager._BLOCK_PATTERNS) do
			if message2:match("^" .. pattern .. "$") then
				return VHUDPlus.DEBUG_MODE and _receive_message_original(self, channel_id, name, "Pattern found: " .. pattern, ...)
			end
		end
		return _receive_message_original(self, channel_id, name, message, ...)
	end
elseif string.lower(RequiredScript) == "lib/managers/menumanagerdialogs" then
	if VHUDPlus:getSetting({"INVENTORY", "CONFIRM_DIALOGS"}, false) then
		local function expect_yes(self, params) params.yes_func() end
		MenuManager.show_confirm_buy_premium_contract = expect_yes
		MenuManager.show_confirm_blackmarket_buy_mask_slot = expect_yes
		MenuManager.show_confirm_blackmarket_buy_weapon_slot = expect_yes
		MenuManager.show_confirm_mission_asset_buy = expect_yes
		MenuManager.show_confirm_pay_casino_fee = expect_yes
		MenuManager.show_confirm_mission_asset_buy_all = expect_yes
	end

	local show_person_joining_original = MenuManager.show_person_joining
	local update_person_joining_original = MenuManager.update_person_joining
	local close_person_joining_original = MenuManager.close_person_joining
	function MenuManager:show_person_joining( id, nick, ... )
		self.peer_join_start_t = self.peer_join_start_t or {}
		self.peer_join_start_t[id] = os.clock()
		local peer = managers.network:session():peer(id)
		if peer then
			if peer:rank() > 0 then
				managers.hud:post_event("infamous_player_join_stinger")
			end
			nick = "(" .. (peer:rank() > 0 and managers.experience:rank_string(peer:rank()) .. "-" or "") .. peer:level() .. ") " .. nick
		end
		return show_person_joining_original(self, id, nick, ...)
	end

	function MenuManager:update_person_joining( id, progress_percentage, ... )
		if self.peer_join_start_t and self.peer_join_start_t[id] then
			local t = os.clock() - self.peer_join_start_t[id]
			local result = update_person_joining_original(self, id, progress_percentage, ...)
			local time_left = (t / progress_percentage) * (100 - progress_percentage)
			local dialog = managers.system_menu:get_dialog("user_dropin" .. id)
			if dialog and time_left and VHUDPlus:getSetting({"MISCHUD", "ENABLE_TIME_LEFT"}, true) then
				dialog:set_text(managers.localization:text("dialog_wait") .. string.format(" %d%% (%0.2fs)", progress_percentage, time_left))
			end
		end
	end

	function MenuManager:close_person_joining(id, ...)
		if self.peer_join_start_t then
			self.peer_join_start_t[id] = nil
		end
		--[[
				if managers.chat and managers.system_menu:is_active_by_id("user_dropin" .. id) then
					local peer = managers.network:session() and managers.network:session():peer(id)
					local text = ""
					if peer then
						local name = peer:name()
						local level = (peer:rank() > 0 and managers.experience:rank_string(peer:rank()) .. "-" or "") .. (peer:level() or "")
						local outfit_skills = (peer:blackmarket_outfit() or {}).skills
						local perk = "[Unknown Perkdeck]"
						local skill_str = "[No Skilldata available]"

						if outfit_skills then
							if outfit_skills.specializations then
								local deck_index, deck_level = unpack(outfit_skills.specializations or {})
								local data = tweak_data.skilltree.specializations[tonumber(deck_index)]
								local name_id = data and data.name_id
								if name_id then
									perk = string.format("%s%s", managers.localization:text(name_id), tonumber(deck_level) < 9 and string.format(" (%d/9)", deck_level) or "")
								end
							end

							local skill_data = outfit_skills.skills
							if skill_data then
								local tree_names = {}
								for i, tree in ipairs(tweak_data.skilltree.skill_pages_order) do
									local tree = tweak_data.skilltree.skilltree[tree]
									if tree then
										table.insert(tree_names, tree.name_id and utf8.sub(managers.localization:text(tree.name_id), 1, 1) or "?")
									end
								end

								local subtree_amt = math.floor(#skill_data / #tree_names)
								skill_str = ""

								for tree = 1, #tree_names, 1 do
									local tree_has_points = false
									local tree_sum = 0

									for sub_tree = 1, subtree_amt, 1 do
										local skills = skill_data[(tree-1) * subtree_amt + sub_tree] or 0
										tree_sum = tree_sum + skills
									end
									skill_str = string.format("%s%s:%02d ", skill_str, tree_names[tree] or "?", tree_sum)
								end
							end

							text = string.format("%s, %s", skill_str, perk)
						else
							text = "[invalid outfit]"
						end

						managers.chat:feed_system_message(ChatManager.GAME, string.format("(%s) %s: %s", level, name, text))
					end
				end
		]]
		close_person_joining_original(self, id, ...)
	end
elseif string.lower(RequiredScript) == "lib/network/base/hostnetworksession" then	
    local chk_server_joinable_state_actual = HostNetworkSession.chk_server_joinable_state
    function HostNetworkSession:chk_server_joinable_state(...)
	    chk_server_joinable_state_actual(self, ...)
	    if Global.load_start_menu_lobby and MenuCallbackHandler ~= nil then
		    MenuCallbackHandler:update_matchmake_attributes()
		    MenuCallbackHandler:_on_host_setting_updated()
	    end
    end	
elseif string.lower(RequiredScript) == "lib/managers/menu/items/contractbrokerheistitem" then
	local init_original = ContractBrokerHeistItem.init
	function ContractBrokerHeistItem:init(...) -- parent_panel, job_data, idx

		init_original(self, ...)

		local heat_text, heat_color = self:get_job_heat_text(self._job_data.job_id)

		local heat = self._panel:text({
			alpha = 1,
			vertical = "top",
			layer = 1,
			align = "right",
			halign = "right",
			valign = "top",
			text = heat_text,
			font = tweak_data.menu.pd2_large_font,
			font_size = tweak_data.menu.pd2_medium_font_size * 1,
			color = heat_color
		})
		self:make_fine_text(heat)
		heat:set_right(self._panel:right() - 10)
		heat:set_top(10)
	end

	function ContractBrokerHeistItem:make_fine_text(text)
		local x, y, w, h = text:text_rect()

		text:set_size(w, h)
		text:set_position(math.round(text:x()), math.round(text:y()))
	end

	function ContractBrokerHeistItem:get_job_heat_text(job_id)
		local heat_text = ""
		local heat_color = Color(1,0,1)
		local exp_multiplier  = managers.job:heat_to_experience_multiplier(managers.job:get_job_heat(job_id) or 0)
		local exp_percent     = ((1 - exp_multiplier)*-1)*100
		local job_tweak = tweak_data.narrative:job_data(self._job_data.job_id)

		if exp_percent ~= 0 and job_tweak and job_tweak.contact ~= "skirmish" then
			heat_text = (VHUDPlus:getSetting({"INVENTORY", "SHOW_HEAT"}, true) and exp_percent>0 and ("+" .. exp_percent .."%") or VHUDPlus:getSetting({"INVENTORY", "SHOW_REDUCTION"}, true) and ("-" .. exp_percent .."%"))
			heat_color = (exp_percent > 0 and Color.yellow) or Color('E55858')
		end

		return heat_text, heat_color
	end 
end
