local requiredScript = string.lower(RequiredScript)

if requiredScript == "lib/managers/menumanager" then

    function MenuCallbackHandler:save_crimenet_filters()
        managers.savefile:save_setting(true)
        managers.network.matchmake:search_lobby(managers.network.matchmake:search_friends_only())
    end

    function MenuCallbackHandler:load_filters()
        if managers.network.matchmake and managers.network.matchmake.load_user_filters then
            managers.network.matchmake:load_user_filters()
        end
    end
    
    -- function MenuCallbackHandler:choice_state_filter(item)
    --     local state_filter = item:value()
    --     if managers.network.matchmake:get_lobby_filter("state") == state_filter then
    --         return
    --     end
    --     managers.network.matchmake:add_lobby_filter("state", state_filter, "equal")
    --     managers.network.matchmake:search_lobby(managers.network.matchmake:search_friends_only())
    -- end
    
    -- function MenuCallbackHandler:choice_gamemode_filter2(item)
    --     Global.game_settings.gamemode_filter = item:value()
    
    --     managers.user:set_setting("crimenet_gamemode_filter", item:value())
    
    --     local logic = managers.menu:active_menu().logic
    
    --     if logic then
    --         logic:refresh_node_stack()
    --     end
    
    --     managers.network.matchmake:search_lobby(managers.network.matchmake:search_friends_only())
    -- end

    function MenuSTEAMHostBrowser:add_filter(node)
    end

    function MenuCallbackHandler:_find_online_games(friends_only)
		friends_only = friends_only or Global.game_settings.search_friends_only
		if self:is_win32() then
			local function f(info)
				print("info in function")
				print(inspect(info))
				managers.network.matchmake:search_lobby_done()
				managers.menu:active_menu().logic:refresh_node(VHUDPlus.fast_net_node, true, info, friends_only)
			end
			managers.network.matchmake:register_callback("search_lobby", f)
			managers.menu:show_retrieving_servers_dialog()
			managers.network.matchmake:search_lobby(friends_only)
			if SystemInfo:distribution() == Idstring("STEAM") then
                local function usrs_f(success, amount)
                    print("usrs_f", success, amount)
                    if success then
                        local stack = managers.menu:active_menu().renderer._node_gui_stack
                        local node_gui = stack[#stack]
                        local is_FastNet = (managers.menu:active_menu().logic:selected_node():parameters().name == VHUDPlus.fast_net_node)
                        if is_FastNet and node_gui.set_mini_info then
                            node_gui:set_mini_info(managers.localization:text("menu_players_online", {COUNT = amount}))
                        end
                    end
			end
			Steam:sa_handler():concurrent_users_callback(usrs_f)
			Steam:sa_handler():get_concurrent_users()
        end
		end
		if self:is_ps3() or self:is_ps4() then
			if #PSN:get_world_list() == 0 then
				return
			end
			local function f(info_list)
				print("info_list in function")
				print(inspect(info_list))
				managers.network.matchmake:search_lobby_done()
				managers.menu:active_menu().logic:refresh_node("play_online", true, info_list, friends_only)
			end
			managers.network.matchmake:register_callback("search_lobby", f)
			managers.network.matchmake:start_search_lobbys(friends_only)
		end
	end
    
    -- function MenuSTEAMHostBrowser:add_filter(node)
    --     if node:item("server_filter") then
    --         return
    --     end
    
        if managers.network and managers.network.matchmake then
    --         managers.network.matchmake:reset_crash_fix()
            managers.network.matchmake:search_lobby(managers.network.matchmake:search_friends_only())
        end
    
    --     local params = {
    --         name = "gamemode_filter",
    --         text_id = "menu_gamemode",
    --         -- visible_callback = "is_multiplayer is_win32",
    --         callback = "choice_gamemode_filter2",
    --         filter = true
    --     }
        
    --     local data_node = {
    --         type = "MenuItemMultiChoice",
    --         {
    --             _meta = "option",
    --             text_id = "menu_gamemode_heist",
    --             value = "standard"
    --         },
    --         {
    --             _meta = "option",
    --             text_id = "menu_gamemode_spree",
    --             value = "crime_spree"
    --         },
    --         {
    --             _meta = "option",
    --             text_id = "menu_cn_skirmish",
    --             value = "skirmish"
    --         }
    --     }
    --     local new_item = node:create_item(data_node, params)
    --     new_item:set_value(managers.user:get_setting("crimenet_gamemode_filter"))
    --     node:add_item(new_item)
        
    --     local params = {
    --         name = "job_id_filter",
    --         text_id = "menu_job_id_filter",
    --         -- visible_callback = "is_multiplayer is_win32",
    --         callback = "choice_job_id_filter",
    --         filter = true
    --     }
    --     local menu_any = {
    --         value = -1,
    --         text_id = "menu_any",
    --         _meta = "option"	
    --     }
    --     local data_node = {
    --         type = "MenuItemMultiChoice"
    --     }
    --     for index, job_id in ipairs(tweak_data.narrative:get_jobs_index()) do
    --         local job_tweak = tweak_data.narrative.jobs[job_id]
    --         local contact = job_tweak.contact
    --         local contact_tweak = tweak_data.narrative.contacts[contact]
    --         local is_hidden = job_tweak.hidden or contact_tweak and contact_tweak.hidden
    --         local allow = not job_tweak.wrapped_to_job and not is_hidden
    
    --         if allow then
    --             local text_id, color_data = tweak_data.narrative:create_job_name(job_id)
    --             local params = {
    --                 localize = false,
    --                 _meta = "option",
    --                 text_id = text_id,
    --                 value = index
    --             }
    
    --             for count, color in ipairs(color_data) do
    --                 params["color" .. count] = color.color
    --                 params["color_start" .. count] = color.start
    --                 params["color_stop" .. count] = color.stop
    --             end
    
    --             table.insert(data_node, params)
    --         end
    --     end
    --     if VHUDPlus:getSetting({"INVENTORY", "FastNetSortHeistsA"}, false) then
    --     	table.sort(data_node, function (a, b)
    --     		return a.text_id < b.text_id
    --     	end)
    --     end
    --     table.insert(data_node, 1, menu_any)
    --     local new_item = node:create_item(data_node, params)
    --     new_item:set_value(managers.network.matchmake:get_lobby_filter("job_id") or -1)
    --     node:add_item(new_item)
        
    --     local params = {
    --         name = "server_filter",
    --         text_id = "menu_dist_filter",
    --         help_id = "menu_dist_filter_help",
    --         callback = "choice_distance_filter",
    --         filter = true
    --     }
    --     local data_node = {
    --         type = "MenuItemMultiChoice",
    --         {
    --             _meta = "option",
    --             text_id = "menu_dist_filter_close",
    --             value = 1
    --         },
    --         {
    --             _meta = "option",
    --             text_id = "menu_dist_filter_far",
    --             value = 2
    --         },
    --         {
    --             _meta = "option",
    --             text_id = "menu_dist_filter_worldwide",
    --             value = 3
    --         }
    --     }
    --     local new_item = node:create_item(data_node, params)
    --     new_item:set_value(managers.network.matchmake:distance_filter())
    --     node:add_item(new_item)
        
    --     local params = {
    --         name = "difficulty_filter",
    --         text_id = "menu_diff_filter",
    --         help_id = "menu_diff_filter_help",
    --         callback = "choice_difficulty_filter",
    --         filter = true
    --     }
    --     local data_node = {
    --         type = "MenuItemMultiChoice",
    --         {
    --             _meta = "option",
    --             text_id = "menu_all",
    --             value = -1
    --         },
    --         {
    --             _meta = "option",
    --             text_id = "menu_difficulty_normal",
    --             value = 2
    --         },
    --         {
    --             _meta = "option",
    --             text_id = "menu_difficulty_hard",
    --             value = 3
    --         },
    --         {
    --             _meta = "option",
    --             text_id = "menu_difficulty_very_hard",
    --             value = 4
    --         },
    --         {
    --             _meta = "option",
    --             text_id = "menu_difficulty_overkill",
    --             value = 5
    --         },
    --         {
    --             _meta = "option",
    --             text_id = "menu_difficulty_easy_wish",
    --             value = 6
    --         },
    --         {
    --             _meta = "option",
    --             text_id = "menu_difficulty_apocalypse",
    --             value = 7
    --         },
    --         {
    --             _meta = "option",
    --             text_id = "menu_difficulty_sm_wish",
    --             value = 8
    --         }
    --     }
    --     local new_item = node:create_item(data_node, params)
    --     new_item:set_value(managers.network.matchmake:difficulty_filter())
    --     node:add_item(new_item)
        
    --     local params = {
    --         name = "max_lobbies_filter",
    --         text_id = "menu_max_lobbies_filter",
    --         help_id = "menu_servers_filter_help",
    --         callback = "choice_max_lobbies_filter",
    --         filter = true
    --     }
    --     local data_node = {
    --         type = "MenuItemMultiChoice",
    --         {
    --             _meta = "option",
    --             text_id = "30",
    --             value = 30,
    --             localize = false
    --         },
    --         {
    --             _meta = "option",
    --             text_id = "40",
    --             value = 40,
    --             localize = false
    --         },
    --         {
    --             _meta = "option",
    --             text_id = "50",
    --             value = 50,
    --             localize = false
    --         }
    --     }
    --     local new_item = node:create_item(data_node, params)
    --     new_item:set_value(managers.network.matchmake:get_lobby_return_count())
    --     node:add_item(new_item)
        
    --     local params = {
    --         name = "state_filter",
    --         text_id = "menu_state_filter",
    --         help_id = "menu_state_filter_help",
    --         callback = "choice_state_filter",
    --         filter = true
    --     }
    --     local data_node = {
    --         type = "MenuItemMultiChoice",
            
    --         {
    --             _meta = "option",
    --             text_id = "menu_all",
    --             value = -1
    --         },
    --         {
    --             _meta = "option",
    --             text_id = "menu_state_lobby",
    --             value = 1
    --         },
    --         {
    --             _meta = "option",
    --             text_id = "menu_state_loading",
    --             value = 2
    --         },
    --         {
    --             _meta = "option",
    --             text_id = "menu_state_ingame",
    --             value = 3
    --         }
    --     }
    --     local new_item = node:create_item(data_node, params)
    --     new_item:set_value(managers.network.matchmake:get_lobby_filter("state"))
    --     node:add_item(new_item)
        
    --     local params = {
    --         name = "job_plan_filter",
    --         text_id = "menu_preferred_plan",
    --         help_id = "menu_preferred_plan_help",
    --         callback = "choice_job_plan_filter",
    --         filter = true
    --     }
    --     local data_node = {
    --         type = "MenuItemMultiChoice",
    --         {
    --             _meta = "option",
    --             text_id = "menu_any",
    --             value = -1
    --         },
    --         {
    --             _meta = "option",
    --             text_id = "menu_plan_loud",
    --             value = 1
    --         },
    --         {
    --             _meta = "option",
    --             text_id = "menu_plan_stealth",
    --             value = 2
    --         }
    --     }
    --     local new_item = node:create_item(data_node, params)
    --     new_item:set_value(managers.network.matchmake:get_lobby_filter("job_plan"))
    --     node:add_item(new_item)
    
    --     local params = {
    --         callback = "chocie_one_down_filter",
    --         name = "t_one_down_lobby",
    --         text_id = "menu_toggle_one_down_lobbies",
    --         filter = true
    --     }
    --     local data_node = {
    --         {
    --             w = "24",
    --             y = "0",
    --             h = "24",
    --             s_y = "24",
    --             value = "off",
    --             s_w = "24",
    --             s_h = "24",
    --             s_x = "0",
    --             _meta = "option",
    --             icon = "guis/textures/menu_tickbox",
    --             x = "0",
    --             s_icon = "guis/textures/menu_tickbox"
    --         },
    --         {
    --             w = "24",
    --             y = "0",
    --             h = "24",
    --             s_y = "24",
    --             value = "on",
    --             s_w = "24",
    --             s_h = "24",
    --             s_x = "24",
    --             _meta = "option",
    --             icon = "guis/textures/menu_tickbox",
    --             x = "24",
    --             s_icon = "guis/textures/menu_tickbox"
    --         },
    --         type = "CoreMenuItemToggle.ItemToggle"
    --     }
    --     new_item = node:create_item(data_node, params)
    
    --     new_item:set_value(managers.user:set_setting("crimenet_filter_one_down"))
    --     node:add_item(new_item)
    -- end
    
    -- function MenuCallbackHandler:chocie_one_down_filter(item)
    --     local allow_one_down = item:value() == "on" and true or false
    --     Global.game_settings.search_one_down_lobbies = allow_one_down
    
    --     managers.user:set_setting("crimenet_filter_one_down", allow_one_down)
        
    --     managers.network.matchmake:search_lobby(managers.network.matchmake:search_friends_only())
    -- end
    
    function MenuCallbackHandler:setup_join_cs_manager(item, ...)
        local params = item:parameters()
        if params.is_crime_spree then
            managers.crime_spree:join_server(params)
        end
    end

    function MenuSTEAMHostBrowser:refresh_node(node, info, friends_only)

        -- if not VHUDPlus.Version then
            -- managers.network.matchmake:reset_crash_fix()
            -- managers.network.matchmake:search_lobby(managers.network.matchmake:search_friends_only())
        -- end

        local new_node = node
		
		if not info then
			managers.menu:add_back_button(new_node)
			return new_node
		end
		
		local room_list = info.room_list
		local attribute_list = info.attribute_list
		
		local dead_list = {}
		for _, item in ipairs(node:items()) do
			if not item:parameters().back and not item:parameters().filter and not item:parameters().pd2_corner then
				dead_list[item:parameters().room_id] = true
			end
		end
		
		for i, room in ipairs(room_list) do
			if managers.network.matchmake:is_server_ok(friends_only, room, attribute_list[i], nil) then
				local host_name = tostring(room.owner_name)
				local attributes_numbers = attribute_list[i].numbers
				local attributes_mutators = attribute_list[i].mutators
				if attributes_numbers then
                    dead_list[room.room_id] = nil
                    local level_index, job_index = managers.network.matchmake:_split_attribute_number(attributes_numbers[1], 1000)
                    local level_id = tweak_data.levels:get_level_name_from_index(level_index)
                    local name_id = level_id and tweak_data.levels[level_id] and tweak_data.levels[level_id].name_id
                    local level_name = name_id and managers.localization:text(name_id) or "LEVEL NAME ERROR"
                    local job_id = tweak_data.narrative:get_job_name_from_index(math.floor(job_index))
                    local job_name = job_id and tweak_data.narrative.jobs[job_id] and managers.localization:text(tweak_data.narrative.jobs[job_id].name_id) or "CONTRACTLESS"
                    local job_days = job_id and (tweak_data.narrative.jobs[job_id].job_wrapper and  table.maxn(tweak_data.narrative.jobs[tweak_data.narrative.jobs[job_id].job_wrapper[1]].chain) or table.maxn(tweak_data.narrative.jobs[job_id].chain)) or 1
                    local is_pro = job_id and (tweak_data.narrative.jobs[job_id].professional and tweak_data.narrative.jobs[job_id].professional or false) or false
                    local difficulty_num = attributes_numbers[2]
                    local difficulty = tweak_data:index_to_difficulty(difficulty_num) or "error"
                    local is_one_down = (tonumber(attribute_list[i].one_down) or 0) == 1
                    local state_string_id = tweak_data:index_to_server_state(attributes_numbers[4])
                    local state_name = state_string_id and managers.localization:text("menu_lobby_server_state_" .. state_string_id) or "UNKNOWN"
                    local display_job = job_name .. ((job_name ~= level_name and job_name ~= "CONTRACTLESS" and level_name ~= "CONTRACTLESS" and job_days > 1) and " (" .. level_name .. ")" or "") 
                    local state = attributes_numbers[4]
                    local num_plrs = attributes_numbers[5]
                    local kick_option = attributes_numbers[8]
                    local kick_suffix = {[1] = "server", [2] = "vote", [0] = "disabled"}
                    local kick_option_name = "menu_kick_" .. (kick_suffix[kick_option] or "error")
                    local job_plan = attributes_numbers[10]
                    local job_plan_suffix = {"plan_loud", "plan_stealth"}
                    local job_plan_name = "menu_" .. (job_plan_suffix[job_plan] or "any")
                    local attribute_crimespree = attribute_list[i].crime_spree
                    local is_crime_spree = attribute_crimespree and 0 <= attribute_crimespree
                    local crime_spree_mission = attribute_list[i].crime_spree_mission
                    local crime_spree_mission_name = "CONTRACTLESS"
                    local mods = attribute_list[i].mods
                    local is_skirmish = attribute_list[i].skirmish and attribute_list[i].skirmish > 0
                    local skirmish = attribute_list[i].skirmish
                    local skirmish_wave = attribute_list[i].skirmish_wave
                    if crime_spree_mission then
                        local mission_data = managers.crime_spree:get_mission(crime_spree_mission)
                        if mission_data then
                            local tweak = tweak_data.levels[mission_data.level.level_id]
                            crime_spree_mission_name = managers.localization:text(tweak and tweak.name_id or "UNKNOWN")
                        end
                    end
                    local item = new_node:item(room.room_id)
                    if not item and not (state  ~= 1 and not tweak_data.narrative.jobs[job_id]) then
                        print("ADD", name_str)
                        local params = {
                            name = room.room_id,
                            text_id = name_str,
                            room_id = room.room_id,
                            columns = {
                                utf8.to_upper(host_name),
                                utf8.to_upper(is_crime_spree and crime_spree_mission_name or display_job),
                                utf8.to_upper(state_name),
                                tostring(num_plrs) .. "/4 ",
                                (job_plan == 1 and utf8.char(57364) or job_plan == 2 and utf8.char(57363) or "")
                            },
                            pro = is_pro,
                            days = job_days,
                            level_name = job_id,
                            real_level_name = display_job,
                            level_id = level_id,
                            state_name = state_name,
                            difficulty = difficulty,
                            job_plan = job_plan,
                            job_plan_name = job_plan_name,
                            difficulty_num = difficulty_num or 2,
                            is_one_down = is_one_down,
                            host_name = host_name,
                            state = state,
                            num_plrs = num_plrs,
                            kick_option = kick_option,
                            kick_option_name = kick_option_name,
                            friend = is_friend,
                            is_crime_spree = is_crime_spree,
                            crime_spree = attribute_crimespree,
                            crime_spree_mission = crime_spree_mission,
                            crime_spree_mission_name = crime_spree_mission_name,
                            mutators = attributes_mutators,
                            is_skirmish = skirmish and skirmish > 0,
                            skirmish = skirmish,
                            skirmish_wave = skirmish_wave,
                            mods = mods,
                            callback = "setup_join_cs_manager connect_to_lobby",
                            localize = false
                        }
                        local new_item = new_node:create_item({
                            type = "ItemServerColumn"
                        }, params)
                        new_node:add_item(new_item)
                    elseif not (state  ~= 1 and not tweak_data.narrative.jobs[job_id]) then
                        if item:parameters().real_level_name ~= display_job then
                            item:parameters().columns[2] = utf8.to_upper(display_job)
                            item:parameters().level_name = job_id
                            item:parameters().level_id = level_id
                            item:parameters().real_level_name = display_job
                        end
                        if item:parameters().state ~= state then
                            item:parameters().columns[3] = state_name
                            item:parameters().state = state
                            item:parameters().state_name = state_name
                        end
                        if item:parameters().difficulty ~= difficulty then
                            item:parameters().difficulty = difficulty
                        end
                        if item:parameters().room_id ~= room.room_id then
                            item:parameters().room_id = room.room_id
                        end
                        if item:parameters().num_plrs ~= num_plrs then
                            item:parameters().num_plrs = num_plrs
                            item:parameters().columns[4] = tostring(num_plrs) .. "/4 "
                        end
                        if item:parameters().crime_spree ~= attribute_crimespree then
                            item:parameters().is_crime_spree = is_crime_spree
                            item:parameters().crime_spree = attribute_crimespree
                        end
                        if item:parameters().crime_spree_mission ~= crime_spree_mission then
                            item:parameters().crime_spree_mission = crime_spree_mission
                            item:parameters().crime_spree_mission_name = crime_spree_mission_name
                        end
                        if item:parameters().difficulty_num ~= difficulty_num then
                            item:parameters().difficulty_num = difficulty_num
                        end
                        if item:parameters().is_one_down ~= is_one_down then
                            item:parameters().is_one_down = is_one_down
                        end
                        if item:parameters().mutators ~= attributes_mutators then
                            item:parameters().mutators = attributes_mutators
                        end
                        if item:parameters().job_plan ~= job_plan then
                            item:parameters().job_plan = job_plan
                            item:parameters().job_plan_name = job_plan_name
                            item:parameters().columns[5] = (job_plan == 1 and utf8.char(57364) or job_plan == 2 and utf8.char(57363) or "")
                        end
                    elseif item then
                        new_node:delete_item(room.room_id)
                    end
                end
            end
        end
        for name, _ in pairs(dead_list) do
            new_node:delete_item(name)
        end
        managers.menu:add_back_button(new_node)
        return new_node
    end
elseif requiredScript == "lib/network/matchmaking/networkmatchmakingsteam" then
    
    function NetworkMatchMakingSTEAM:reset_crash_fix()
        local usr = managers.user
    
        usr:set_setting("crimenet_gamemode_filter", usr:get_default_setting("crimenet_gamemode_filter"))
        self:load_user_filters()
    end
elseif requiredScript == "lib/managers/menu/nodes/menunodeserverlist" then
    function MenuNodeServerList:_setup_columns()
        self:_add_column({		-- Server Name
            text = string.upper(""),
            proportions = 1.4,
            align = "left"
        })
        self:_add_column({		-- level name
            text = string.upper(""),
            proportions = 1.6,
            align = "right"
        })
        self:_add_column({		-- Difficulty, State name
            text = string.upper(""),
            proportions = 1.4,
            align = "right"
        })
        self:_add_column({		-- Players/Total
            text = string.upper(""),
            proportions = 0.2,
            align = "right"
        })
        self:_add_column({		-- Lobby Plan
            text = string.upper(""),
            proportions = 0.1,
            align = "center"
        })
    end
elseif requiredScript == "lib/managers/menu/renderers/menunodetablegui" then
    function MenuNodeTableGui:_setup_panels(node)
        MenuNodeTableGui.super._setup_panels(self, node)
        local safe_rect_pixels = self:_scaled_size()
        local mini_info = self.safe_rect_panel:panel({
            x = 0,
            y = self._info_bg_rect:h(),
            w = self._info_bg_rect:w(),
            h = self.safe_rect_panel:h() - self._info_bg_rect:h()
        })
        local mini_text = mini_info:text({
            x = self.safe_rect_panel:w() - tweak_data.menu.info_padding * 12,
            y = tweak_data.menu.info_padding,
            w = tweak_data.menu.info_padding * 11,
            h = 35,
            align = "left",
            halign = "top",
            vertical = "top",
            font = tweak_data.menu.pd2_small_font,
            font_size = tweak_data.menu.pd2_small_font_size + 2,
            color = Color.white or PDTH_Menu and Color.yellow,
            layer = self.layers.items,
            text = ""
        })
        mini_info:set_width(self._info_bg_rect:w() - tweak_data.menu.info_padding * 38)
        mini_text:set_width(mini_info:w())
        mini_info:set_height(35)
        mini_text:set_height(35)
        mini_info:set_top(self._info_bg_rect:bottom() + tweak_data.menu.info_padding - 12)
        mini_text:set_top(0)
        mini_info:set_left(tweak_data.menu.info_padding)
        mini_text:set_left(0)
        self._mini_info_text = mini_text
    end
    
    
    function MenuNodeTableGui:set_mini_info(text)
        self._mini_info_text:set_text(text)
    end
    
    function MenuNodeTableGui:completed_job(job_id, difficulty, require_one_down)
        local job_stats = managers.statistics._global.sessions.jobs
        local tweak_jobs = tweak_data.narrative.jobs
        local job_wrapper = nil
    
        if tweak_data.narrative:has_job_wrapper(job_id) then
            job_wrapper = tweak_jobs[job_id].job_wrapper
        elseif tweak_data.narrative:is_wrapped_to_job(job_id) then
            job_wrapper = tweak_jobs[tweak_jobs[job_id].wrapped_to_job].job_wrapper
        end
    
        local function single_job_count(job_id, difficulty, require_one_down)
            local stat_prefix = tostring(job_id) .. "_" .. tostring(difficulty)
            local stat_suffix = "_completed"
            local count = 0
            count = count + (job_stats[stat_prefix .. "_od" .. stat_suffix] or 0)
    
            if not require_one_down then
                count = count + (job_stats[stat_prefix .. stat_suffix] or 0)
            end
    
            return count
        end
    
        local count = 0
    
        if job_wrapper then
            local count = 0
    
            for _, wrapped_job in ipairs(job_wrapper) do
                count = count + single_job_count(wrapped_job, difficulty, require_one_down)
            end
    
            return count
        end
    
        return single_job_count(job_id, difficulty, require_one_down)
    end
    
    function MenuNodeTableGui:_create_menu_item(row_item)
        if row_item.type == "column" then
            local columns = row_item.node:columns()
            local total_proportions = row_item.node:parameters().total_proportions
            row_item.gui_panel = self.item_panel:panel({
                x = self:_right_align(),
                w = self.item_panel:w()
            })
            row_item.gui_columns = {}
            local x = 0
            for i, data in ipairs(columns) do
                local text = row_item.gui_panel:text({
                    font_size = self.font_size,
                    x = row_item.position.x,
                    y = 0,
                    align = data.align,
                    halign = data.align,
                    vertical = "center",
                    font = row_item.font,
                    color = row_item.color,
                    layer = self.layers.items,
                    text = row_item.item:parameters().columns[i]
                })
                row_item.gui_columns[i] = text
                local _, _, w, h = text:text_rect()
                text:set_h(h)
                local w = data.proportions / total_proportions * row_item.gui_panel:w()
                text:set_w(w)
                text:set_x(x)
                x = x + w
            end
            local x, y, w, h = row_item.gui_columns[1]:text_rect()
            row_item.gui_panel:set_height(h)
        elseif row_item.type == "server_column" then
            --row_item.font = tweak_data.menu.pd2_medium_font_id
            local columns = row_item.node:columns()
            local total_proportions = row_item.node:parameters().total_proportions
            local safe_rect = self:_scaled_size()
            local xl_pad = 80
            row_item.gui_panel = self.item_panel:panel({
                x = safe_rect.width / 2 - xl_pad,
                w = safe_rect.width / 2 + xl_pad - tweak_data.menu.info_padding
            })
            row_item.gui_columns = {}
            local x = 0
            for i, data in ipairs(columns) do
                local color = row_item.color
                if i == 1 and row_item.item:parameters().friend then
                    color = tweak_data.screen_colors.friend_color
                elseif i == 2 and row_item.item:parameters().pro then
                    color = tweak_data.screen_colors.pro_color
                elseif row_item.item:parameters().mutators then
                    color = tweak_data.screen_colors.mutators_color
                end
                
                local new_font_size
                if PDTH_Menu then
                    new_font_size = tweak_data.menu.server_list_font_size
                else
                    new_font_size = math.round(row_item.font_size * 0.77)
                end
                local text = row_item.gui_panel:text({
                    x = row_item.position.x,
                    y = 0,
                    align = data.align,
                    halign = data.align,
                    vertical = "center",
                    font = row_item.font,
                    font_size = new_font_size,
                    color = color,
                    layer = self.layers.items,
                    text = row_item.item:parameters().columns[i]
                })
                row_item.gui_columns[i] = text
                local _, _, w, h = text:text_rect()
                text:set_h(h)
                local w = data.proportions / total_proportions * row_item.gui_panel:w()
                text:set_w(w + (i == 2 and 10 or 0))
                text:set_x(x)
                x = x + w
            end
            local x, y, w, h = row_item.gui_columns[1]:text_rect()
            row_item.gui_panel:set_height(h)	
            
            local x = row_item.gui_columns[2]:right()
            local y = 0
            row_item.difficulty_icons = {}
            if row_item.item:parameters().is_crime_spree then
                local spree_level = row_item.gui_panel:text({
                    font_size = tweak_data.menu.server_list_font_size,
                    x = x,
                    y = y,
                    w = 60,
                    h = h,
                    align = "right",
                    halign = "center",
                    vertical = "center",
                    font = row_item.font,
                    font_size = math.round(row_item.font_size * 0.77),
                    color = tweak_data.screen_colors.crime_spree_risk,
                    layer = self.layers.items,
                    text = managers.experience:cash_string(tonumber(row_item.item:parameters().crime_spree), "") .. managers.localization:get_default_macro("BTN_SPREE_TICKET"),
                })
                table.insert(row_item.difficulty_icons, spree_level)
            elseif row_item.item:parameters().is_skirmish then
                local wave = row_item.item:parameters().skirmish_wave
                local text = managers.localization:to_upper_text("menu_skirmish_wave_number", {
                    wave = wave
                })
                local skirmish_wave = row_item.gui_panel:text({
                    font_size = tweak_data.menu.server_list_font_size,
                    x = x,
                    y = y,
                    w = 60,
                    h = h,
                    align = "right",
                    halign = "center",
                    vertical = "center",
                    font = row_item.font,
                    font_size = math.round(row_item.font_size * 0.77),
                    layer = self.layers.items,
                    text = text,
                    color = tweak_data.screen_colors.skirmish_color,
                    font = tweak_data.menu.pd2_small_font,
                    font_size = tweak_data.menu.server_list_font_size
                })
            else
                local difficulty_stars = row_item.item:parameters().difficulty_num
                local start_difficulty = 3
                local num_difficulties = 6
                local spacing = 14
                for i = start_difficulty, difficulty_stars do
                    local difficulty_id = tweak_data:index_to_difficulty(i)
                    local skull_texture = difficulty_id and tweak_data.gui.blackscreen_risk_textures[difficulty_id] or "guis/textures/pd2/risklevel_blackscreen"
                    local skull = row_item.gui_panel:bitmap({
                        texture = skull_texture,
                        x = x,
                        y = y,
                        w = h,
                        h = h,
                        --blend_mode = "add",
                        layer = self.layers.items,
                        color = tweak_data.screen_colors.risk
                    })
                    x = x + (spacing)
                    row_item.difficulty_icons[i] = skull
                    --num_stars = num_stars + 1
                    --skull:set_center_y(row_item.gui_columns[2]:center_y())
                    if row_item.item:parameters().is_one_down then
                        skull:set_color(tweak_data.screen_colors.one_down)
                        -- row_item.one_down_icon = row_item.gui_panel:bitmap({
                        -- 	texture = "guis/textures/pd2/cn_mini_onedown",
                        -- 	x = x,
                        -- 	y = y,
                        -- 	w = h,
                        -- 	h = h,
                        -- 	--blend_mode = "add",
                        -- 	layer = self.layers.items,
                        -- 	color = tweak_data.screen_colors.one_down,
                        -- })
                    end
                end
            end
            
            local level_id = row_item.item:parameters().level_id
            local mutators = row_item.item:parameters().mutators or {}
            local mutators_list = {}
            local mutators_text = ""
            if mutators then
                managers.mutators:set_crimenet_lobby_data(mutators)
                for mutator_id, mutator_data in pairs(mutators) do
                    local mutator = managers.mutators:get_mutator_from_id(mutator_id)
                    if mutator then
                        table.insert(mutators_list, mutator:name()) 
                    end
                end
                managers.mutators:set_crimenet_lobby_data(nil)
                table.sort(mutators_list, function(a, b) 
                    return a < b
                end)
                for i, mutator in ipairs(mutators_list) do
                    mutators_text = string.format("%s%s", mutators_text, (mutator .. (i < #mutators_list and "\n" or "")))
                end
            end
    
            row_item.gui_info_panel = self.safe_rect_panel:panel({
                visible = false,
                layer = self.layers.items,
                x = 0,
                y = 0,
                w = self:_left_align(),
                h = self._item_panel_parent:h()
            })
            row_item.heist_name = row_item.gui_info_panel:text({
                visible = false,
                text = utf8.to_upper(row_item.item:parameters().level_name),
                layer = self.layers.items,
                font = self.font,
                font_size = tweak_data.menu.challenges_font_size,
                color = row_item.color,
                align = "left",
                vertical = "left"
            })
            local briefing_text = level_id and managers.localization:text(tweak_data.levels[level_id].briefing_id) or ""
            row_item.heist_briefing = row_item.gui_info_panel:text({
                visible = true,
                x = 0,
                y = 0,
                align = "left",
                halign = "top",
                vertical = "top",
                font = tweak_data.menu.pd2_small_font,
                font_size = tweak_data.menu.pd2_small_font_size,
                color = Color.white,
                layer = self.layers.items,
                text = briefing_text,
                wrap = true,
                word_wrap = true
            })
            
            local font_size = tweak_data.menu.pd2_small_font_size
            row_item.server_title = row_item.gui_info_panel:text({
                name = "server_title",
                text = utf8.to_upper(managers.localization:text("menu_lobby_server_title")) .. " ",
                font = tweak_data.menu.pd2_small_font,
                font_size = font_size,
                align = "left",
                vertical = "center",
                w = 256,
                h = font_size,
                layer = 1
            })
            row_item.server_text = row_item.gui_info_panel:text({
                name = "server_text",
                text = utf8.to_upper(row_item.item:parameters().host_name),
                font = tweak_data.menu.pd2_small_font,
                color = tweak_data.hud.prime_color,
                font_size = font_size,
                align = "left",
                vertical = "center",
                w = 256,
                h = font_size,
                layer = 1
            })
            row_item.server_info_title = row_item.gui_info_panel:text({
                name = "server_info_title",
                text = utf8.to_upper(managers.localization:text("menu_lobby_server_state_title")) .. " ",
                font = tweak_data.menu.pd2_small_font,
                font_size = font_size,
                align = "left",
                vertical = "center",
                w = 256,
                h = font_size,
                layer = 1
            })
            row_item.server_info_text = row_item.gui_info_panel:text({
                name = "server_info_text",
                text = utf8.to_upper(row_item.item:parameters().state_name) .. " " .. tostring(row_item.item:parameters().num_plrs) .. "/4 ",
                font = tweak_data.menu.pd2_small_font,
                color = tweak_data.hud.prime_color,
                font_size = font_size,
                align = "left",
                vertical = "center",
                w = 256,
                h = font_size,
                layer = 1
            })
            row_item.level_title = row_item.gui_info_panel:text({
                name = "level_title",
                text = utf8.to_upper(managers.localization:text("menu_lobby_campaign_title")) .. " ",
                font = tweak_data.menu.pd2_small_font,
                font_size = font_size,
                align = "left",
                vertical = "center",
                w = 256,
                h = font_size,
                layer = 1
            })
            row_item.level_text = row_item.gui_info_panel:text({
                name = "level_text",
                text = utf8.to_upper(row_item.item:parameters().real_level_name) .. " ",
                font = tweak_data.menu.pd2_small_font,
                color = tweak_data.hud.prime_color,
                font_size = font_size,
                align = "left",
                vertical = "center",
                w = 256,
                h = font_size,
                layer = 1
            })
            
            row_item.level_pro_text = row_item.gui_info_panel:text({
                name = "level_pro_text",
                text = utf8.to_upper(row_item.item:parameters().pro and "PRO JOB" or ""),
                font = tweak_data.menu.pd2_small_font,
                color = tweak_data.screen_colors.pro_color,
                font_size = font_size,
                align = "left",
                vertical = "center",
                w = 256,
                h = font_size,
                layer = 1
            })
            
            row_item.difficulty_title = row_item.gui_info_panel:text({
                name = "difficulty_title",
                text = utf8.to_upper(managers.localization:text("menu_lobby_difficulty_title")) .. " ",
                font = tweak_data.menu.pd2_small_font,
                font_size = font_size,
                align = "left",
                vertical = "center",
                w = 256,
                h = font_size,
                layer = 1
            })
            
            local wave = row_item.item:parameters().skirmish_wave
            local skirm_text = managers.localization:to_upper_text("menu_skirmish_wave_number", {
                wave = wave
            })
            row_item.difficulty_text = row_item.gui_info_panel:text({
                name = "difficulty_text",
                text = row_item.item:parameters().is_crime_spree and (managers.experience:cash_string(tonumber(row_item.item:parameters().crime_spree), "") .. managers.localization:get_default_macro("BTN_SPREE_TICKET")) or row_item.item:parameters().is_skirmish and skirm_text or managers.localization:to_upper_text(tweak_data.difficulty_name_ids[row_item.item:parameters().difficulty]),
                font = tweak_data.menu.pd2_small_font,
                color = tweak_data.hud.prime_color,
                font_size = font_size,
                align = "left",
                vertical = "center",
                w = 256,
                h = font_size,
                layer = 1
            })
            
            row_item.one_down_text = row_item.gui_info_panel:text({
                name = "one_down_text",
                text = managers.localization:to_upper_text("menu_one_down"),
                font = tweak_data.menu.pd2_small_font,
                color = tweak_data.screen_colors.one_down,
                font_size = font_size,
                align = "left",
                vertical = "center",
                w = 256,
                h = font_size,
                layer = 1
            })
            
            row_item.job_plan_title = row_item.gui_info_panel:text({
                name = "job_plan_title",
                text = utf8.to_upper(managers.localization:text("menu_lobby_job_plan_title")) .. " ",
                font = tweak_data.menu.pd2_small_font,
                font_size = font_size,
                align = "left",
                vertical = "center",
                w = 256,
                h = font_size,
                layer = 1
            })
    
            local difficulty_stat = row_item.item:parameters().difficulty_num
            local stat = self:completed_job( row_item.item:parameters().level_name, tweak_data:index_to_difficulty( difficulty_stat ) )
            row_item.stats_title = row_item.gui_info_panel:text({
                name = "stats_title",
                text = managers.localization:to_upper_text("menu_stat_job_new"),
                font = tweak_data.menu.pd2_small_font,
                font_size = font_size,
                align = "left",
                vertical = "left",
                w = 256,
                h = font_size,
                layer = 1
            })
    
            row_item.stats_text = row_item.gui_info_panel:text({
                name = "stats_text",
                text = managers.localization:to_upper_text("menu_stat_job_completed_new", {
                    stat = tostring(stat)
                }) .. " ",
                font = tweak_data.menu.pd2_small_font,
                color = tweak_data.hud.prime_color,
                font_size = font_size,
                align = "left",
                vertical = "center",
                w = 256,
                h = font_size,
                layer = 1
            })
                
    
            row_item.server_mutators_text = row_item.gui_info_panel:text({
                name = "server_mutators_text",
                text = utf8.to_upper(row_item.item:parameters().mutators and "MUTATORS ENABLED" or ""),
                font = tweak_data.menu.pd2_small_font,
                color = tweak_data.screen_colors.mutators_color_text,
                font_size = font_size,
                align = "left",
                vertical = "center",
                w = 256,
                h = font_size,
                layer = 1
            })
            
            row_item.crime_spree_text = row_item.gui_info_panel:text({
                name = "crime_spree_text",
                text = utf8.to_upper(row_item.item:parameters().is_crime_spree and "[CRIME SPREE]" or ""),
                font = tweak_data.menu.pd2_small_font,
                color = tweak_data.screen_colors.crime_spree_risk,
                font_size = font_size,
                align = "left",
                vertical = "center",
                w = 256,
                h = font_size,
                layer = 1
            })
    
            row_item.job_plan_text = row_item.gui_info_panel:text({
                name = "job_plan_text",
                text = utf8.to_upper(managers.localization:text("menu_job_plan_" .. tostring(row_item.item:parameters().job_plan))),
                font = tweak_data.menu.pd2_small_font,
                color = tweak_data.hud.prime_color,
                font_size = font_size,
                align = "left",
                vertical = "center",
                w = 256,
                h = font_size,
                layer = 1
            })
    
            row_item.mutators_title = row_item.gui_info_panel:text({
                name = "mutators_title",
                text = managers.localization:to_upper_text("menu_mutators") .. ":  ",
                font = tweak_data.menu.pd2_small_font,
                font_size = font_size,
                align = "left",
                vertical = "center",
                w = 256,
                h = font_size,
                layer = 1
            })
            row_item.mutators_list = row_item.gui_info_panel:text({
                name = "days_text",
                text = utf8.to_upper(mutators_text),
                font = tweak_data.menu.pd2_small_font,
                color = tweak_data.hud.prime_color,
                font_size = font_size,
                align = "left",
                vertical = "center",
                w = 256,
                h = font_size,
                layer = 1
            })
    
            row_item.days_title = row_item.gui_info_panel:text({
                name = "days_title",
                text = utf8.to_upper(managers.localization:text("menu_lobby_days_title")) .. "  ",
                font = tweak_data.menu.pd2_small_font,
                font_size = font_size,
                align = "left",
                vertical = "center",
                w = 256,
                h = font_size,
                layer = 1
            })
            
            row_item.days_text = row_item.gui_info_panel:text({
                name = "days_text",
                text = utf8.to_upper(math.max(row_item.item:parameters().days, 1)),
                font = tweak_data.menu.pd2_small_font,
                color = tweak_data.hud.prime_color,
                font_size = font_size,
                align = "left",
                vertical = "center",
                w = 256,
                h = font_size,
                layer = 1
            })
            
            self:_align_server_column(row_item)
            local visible = row_item.item:menu_unselected_visible(self, row_item) and not row_item.item:parameters().back
            row_item.menu_unselected = self.item_panel:bitmap({
                visible = visible,
                texture = "guis/textures/menu_unselected",
                x = 0,
                y = 0,
                layer = -1
            })
            row_item.menu_unselected:set_color(row_item.item:parameters().is_expanded and Color(0.5, 0.5, 0.5) or Color.white)
            row_item.menu_unselected:hide()
        else
            MenuNodeTableGui.super._create_menu_item(self, row_item)
        end
    end
    function MenuNodeTableGui:_align_server_column(row_item)
        local safe_rect = self:_scaled_size()
        self:_align_item_gui_info_panel(row_item.gui_info_panel)
        local font_size = tweak_data.menu.pd2_small_font_size
        local offset = 22 * tweak_data.scale.lobby_info_offset_multiplier
        row_item.server_title:set_font_size(font_size)
        row_item.server_text:set_font_size(font_size)
        local x, y, w, h = row_item.server_title:text_rect()
        row_item.server_title:set_x(tweak_data.menu.info_padding)
        row_item.server_title:set_y(tweak_data.menu.info_padding)
        row_item.server_title:set_w(w)
        row_item.server_text:set_lefttop(row_item.server_title:righttop())
        row_item.server_text:set_w(row_item.gui_info_panel:w())
        row_item.server_text:set_position(math.round(row_item.server_text:x()), math.round(row_item.server_text:y()))
        
        
        row_item.server_info_title:set_font_size(font_size)
        row_item.server_info_text:set_font_size(font_size)
        local x, y, w, h = row_item.server_info_title:text_rect()
        row_item.server_info_title:set_x(tweak_data.menu.info_padding)
        row_item.server_info_title:set_y(tweak_data.menu.info_padding + offset)
        row_item.server_info_title:set_w(w)
        row_item.server_info_text:set_lefttop(row_item.server_info_title:righttop())
        row_item.server_info_text:set_w(row_item.gui_info_panel:w())
        row_item.server_info_text:set_position(math.round(row_item.server_info_text:x()), math.round(row_item.server_info_text:y()))
        
        row_item.server_mutators_text:set_lefttop(row_item.server_info_text:righttop())
        row_item.server_mutators_text:set_w(row_item.gui_info_panel:w())
        row_item.server_mutators_text:set_position(math.round(row_item.server_mutators_text:x()), math.round(row_item.server_mutators_text:y()))
        local _, _, w, _ = row_item.server_mutators_text:text_rect()
        row_item.server_mutators_text:set_w(w)
        
        row_item.crime_spree_text:set_lefttop(row_item.server_mutators_text:righttop())
        row_item.crime_spree_text:set_w(row_item.gui_info_panel:w())
        row_item.crime_spree_text:set_position(math.round(row_item.crime_spree_text:x()), math.round(row_item.crime_spree_text:y()))
    
        row_item.level_title:set_font_size(font_size)
        row_item.level_text:set_font_size(font_size)
        row_item.level_pro_text:set_font_size(font_size)
        local x, y, w, h = row_item.level_title:text_rect()
        row_item.level_title:set_x(tweak_data.menu.info_padding)
        row_item.level_title:set_y(tweak_data.menu.info_padding + offset * 2)
        row_item.level_title:set_w(w)
        local x, y, w, h = row_item.level_text:text_rect()
        row_item.level_text:set_lefttop(row_item.level_title:righttop())
        row_item.level_text:set_w(w)
        row_item.level_text:set_position(math.round(row_item.level_text:x()), math.round(row_item.level_text:y()))
        
        row_item.level_pro_text:set_lefttop(row_item.level_text:righttop())
        row_item.level_pro_text:set_w(row_item.gui_info_panel:w())
        row_item.level_pro_text:set_position(math.round(row_item.level_pro_text:x()), math.round(row_item.level_pro_text:y()))
        
        row_item.days_title:set_font_size(font_size)
        row_item.days_text:set_font_size(font_size)
        local x, y, w, h = row_item.days_title:text_rect()
        row_item.days_title:set_x(tweak_data.menu.info_padding)
        row_item.days_title:set_y(tweak_data.menu.info_padding + offset * 3)
        row_item.days_title:set_w(w)
        row_item.days_text:set_lefttop(row_item.days_title:righttop())
        row_item.days_text:set_w(row_item.gui_info_panel:w())
        row_item.days_text:set_position(math.round(row_item.days_text:x()), math.round(row_item.days_text:y()))
        
        row_item.difficulty_title:set_font_size(font_size)
        row_item.difficulty_text:set_font_size(font_size)
        local x, y, w, h = row_item.difficulty_title:text_rect()
        row_item.difficulty_title:set_x(tweak_data.menu.info_padding)
        row_item.difficulty_title:set_y(tweak_data.menu.info_padding + offset * 4)
        row_item.difficulty_title:set_w(w)
        row_item.difficulty_text:set_lefttop(row_item.difficulty_title:righttop())
        local _, _, w, _ = row_item.difficulty_text:text_rect()
        row_item.difficulty_text:set_w(w + 8)
        row_item.difficulty_text:set_position(math.round(row_item.difficulty_text:x()), math.round(row_item.difficulty_text:y()))
        
        row_item.one_down_text:set_lefttop(row_item.difficulty_text:righttop())
        row_item.one_down_text:set_w(row_item.gui_info_panel:w())
        row_item.one_down_text:set_position(math.round(row_item.one_down_text:x()), math.round(row_item.one_down_text:y()))
        row_item.one_down_text:set_visible(row_item.item:parameters().is_one_down or false)
        
        row_item.job_plan_title:set_font_size(font_size)
        row_item.job_plan_text:set_font_size(font_size)
        local x, y, w, h = row_item.job_plan_title:text_rect()
        row_item.job_plan_title:set_x(tweak_data.menu.info_padding)
        row_item.job_plan_title:set_y(tweak_data.menu.info_padding + offset * 5)
        row_item.job_plan_title:set_w(w)
        row_item.job_plan_text:set_lefttop(row_item.job_plan_title:righttop())
        row_item.job_plan_text:set_w(row_item.gui_info_panel:w())
        row_item.job_plan_text:set_position(math.round(row_item.job_plan_text:x()), math.round(row_item.job_plan_text:y()))
    
        local mutators_active = row_item.item:parameters().mutators or false
            
        local _, _, w, h = row_item.mutators_list:text_rect()
        row_item.mutators_list:set_w(row_item.gui_info_panel:w())
        row_item.mutators_list:set_h(h)
        row_item.mutators_list:set_bottom(self._info_bg_rect:h() - 2 * tweak_data.menu.info_padding)
        row_item.mutators_list:set_visible(mutators_active)
        
        local _, _, w, _ = row_item.mutators_title:text_rect()
        row_item.mutators_title:set_x(tweak_data.menu.info_padding)
        row_item.mutators_title:set_w(w)
        row_item.mutators_title:set_visible(mutators_active)
        
        row_item.mutators_title:set_top(row_item.mutators_list:top())
        row_item.mutators_list:set_left(row_item.mutators_title:right())
        
        row_item.mutators_title:set_position(math.round(row_item.mutators_title:x()), math.floor(row_item.mutators_title:y()))
        row_item.mutators_list:set_position(math.round(row_item.mutators_list:x()), math.floor(row_item.mutators_list:y()))
        
        row_item.stats_title:set_font_size(font_size)
        row_item.stats_text:set_font_size(font_size)
        local x, y, w, h = row_item.stats_title:text_rect()
        row_item.stats_title:set_x(tweak_data.menu.info_padding)
        row_item.stats_title:set_y(tweak_data.menu.info_padding + offset * 6)
        row_item.stats_title:set_w(w)
        row_item.stats_text:set_lefttop(row_item.stats_title:righttop())
        row_item.stats_text:set_w(row_item.gui_info_panel:w())
        row_item.stats_text:set_position(math.round(row_item.stats_text:x()), math.round(row_item.stats_text:y()))
        
        local _, _, _, h = row_item.heist_name:text_rect()
        local w = row_item.gui_info_panel:w()
        row_item.heist_name:set_height(h)
        row_item.heist_name:set_w(w)
        row_item.heist_briefing:set_w(w)
        row_item.heist_briefing:set_shape(row_item.heist_briefing:text_rect())
        row_item.heist_briefing:set_x(tweak_data.menu.info_padding)
        row_item.heist_briefing:set_y(tweak_data.menu.info_padding + offset * 7 + tweak_data.menu.info_padding * 2)
        row_item.heist_briefing:set_position(math.round(row_item.heist_briefing:x()), math.round(row_item.heist_briefing:y()))
    end
    
    function MenuNodeTableGui:mouse_pressed(button, x, y)
        --[[if self.item_panel:inside(x, y) and self._item_panel_parent:inside(x, y) and x > self:_mid_align() then
            if button == Idstring("mouse wheel down") then
                return self:wheel_scroll_start(-1)
            elseif button == Idstring("mouse wheel up") then
                return self:wheel_scroll_start(1)
            end
        end]]--
        MenuNodeTableGui.super.mouse_pressed(self, button, x, y)
        if button == Idstring("0") and self._mini_info_text:inside(x, y) then
            managers.network.account:overlay_activate("url", "http://store.steampowered.com/stats")
            return true
        end
    end
    
    function MenuNodeTableGui:mouse_moved(o, x, y)
    
        local inside = self._mini_info_text:inside(x, y)
        --self._mouse_over = inside
        return inside, inside and "link"
    end
end