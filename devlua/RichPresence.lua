if RequiredScript == "lib/managers/platformmanager" and not RichPresenceUltimate then
	core:module("PlatformManager")

	local set_rich_presence_original = WinPlatformManager.set_rich_presence
	function WinPlatformManager:set_rich_presence(name, ...)
		set_rich_presence_original(self, name or self._current_rich_presence, ...)

		if SystemInfo:distribution() == Idstring("STEAM") then
			-- Default config
			local display = "#raw_status" --"#DisplayMe"
			local group_key = ""
			local group_count = ""

			local game_state = "menu"
			local game_mode = ""
			local game_heist = ""
			local game_heistday = ""
			local game_difficulty = ""

			if self._current_rich_presence ~= "Idle" then
				if Global.game_settings.permission == "private" and not Global.game_settings.single_player then
					game_state = "private"
				else
					-- Handle Steam RP Grouping
					if not Global.game_settings.single_player then
						if managers.network.matchmake and managers.network.matchmake.lobby_handler then
							group_key = managers.network.matchmake.lobby_handler:id()
						end

						local session = managers.network:session()
						group_count = tostring(session and #session:all_peers() or 1)
					end

					-- Determine game state
					if _G.game_state_machine and (_G.game_state_machine:current_state_name() == "menu_main" or _G.game_state_machine:current_state_name() == "ingame_lobby_menu") then
						game_state = "lobby"
					elseif self._current_rich_presence == "SPEnd" or self._current_rich_presence == "MPEnd" then
						game_state = "payday"
					else
						game_state = "playing"
					end

					local job_data = managers.job:current_job_data()
					local job_name = job_data and managers.localization:text(job_data.name_id)
					
					-- Popululate gamemode, heist and difficulty
					if managers.crime_spree and managers.crime_spree:is_active() then		-- Crime Spree
						local level_id = Global.game_settings.level_id
						local name_id = level_id and _G.tweak_data.levels[level_id] and _G.tweak_data.levels[level_id].name_id

						if name_id then
							job_name = managers.localization:text(name_id) or job_name
						end
						game_mode = "crime_spree"
						game_heist = job_name
						local spree_lvl = managers.crime_spree:server_spree_level()
						game_difficulty = spree_lvl and managers.money:add_decimal_marks_to_string(tostring(spree_lvl)) or "(N/A)"
					elseif managers.skirmish and managers.skirmish:is_skirmish() then		-- Holdout
						game_mode = "skirmish"
						game_heist = job_name
						game_difficulty = string.format("%i/%i", managers.skirmish:current_wave_number() or 1, tweak_data and #tweak_data.skirmish.ransom_amounts or 9)
					elseif managers.job:has_active_job() then
						game_heist = job_name

						if #(managers.job:current_job_chain_data() or {}) > 1 then
							game_mode = "heist_chain"
							game_heistday = tostring(managers.job:current_stage() or "")
						else
							game_mode = "heist"
						end

						game_difficulty = tweak_data and tweak_data:index_to_difficulty(managers.job:current_difficulty_stars() + 2) or Global.game_settings.difficulty or "easy"
					else
						-- Overwrite game state if nothing is selected
						game_state = "lobby_no_job"
					end
				end
			end

			-- Send our data to Steam
			Steam:set_rich_presence("steam_display", display)		-- Currently not usable, only Overkill can setup required localized strings here...
			Steam:set_rich_presence("steam_player_group", group_key)
			Steam:set_rich_presence("steam_player_group_size", group_count)

			Steam:set_rich_presence("game:state", game_state)
			Steam:set_rich_presence("game:mode", game_mode)
			Steam:set_rich_presence("game:heist", game_heist)
			Steam:set_rich_presence("game:heist_day", game_heistday)
			Steam:set_rich_presence("game:difficulty", game_difficulty)

			Steam:set_rich_presence("status", self:build_status_string(display, game_state, game_mode, game_heist, game_heistday, game_difficulty))
		end
	end

	local suffixList = {
		"_prof$",
		"_day$",
		"_night$",
		"_wrapper$",
		"^skm_"
	}
	local ignoreSuffix = {
		["election_day"] = true
	}

	function WinPlatformManager:get_current_job_id()
		local job_id = managers.job:current_job_id()
		local job_name = job_id and managers.localization:text(job_id.name_id)
		-- if job_id and not ignoreSuffix[job_id] then
		-- 	for _, suffix in ipairs(suffixList) do
		-- 		job_id = job_name:gsub(suffix, "")
		-- 	end
		-- end

		return #job_name or "UNKNOWN"
	end

	function WinPlatformManager:get_current_level_id()
		local level_id = Global.game_settings.level_id

		if level_id and not ignoreSuffix[level_id] then
			for _, suffix in ipairs(suffixList) do
				level_id = level_id:gsub(suffix, "")
			end
		end

		return level_id or self:get_current_job_id()
	end

	function WinPlatformManager:build_status_string(display, state, mode, heist, day, difficulty)
		local tokens = {
			["#raw_status"] =				"{#State_%game:state%}",

			-- Game states
			["#State_menu"] =				"At the main menu",
			["#State_private"] =			"In a private lobby",
			["#State_lobby_no_job"] =		"In a lobby",
			["#State_lobby"] =				"Lobby: {#Mode_%game:mode%}",
			["#State_playing"] =			"Playing: {#Mode_%game:mode%}",
			["#State_payday"] =				"Payday: {#Mode_%game:mode%}",

			-- Game modes
			["#Mode_crime_spree"] =			"[CS] {%game:heist%} (Lvl. %game:difficulty%)",
			["#Mode_skirmish"] =			"[HO] {%game:heist%} (Wave %game:difficulty%)",
			["#Mode_heist"] =				"{%game:heist%} ({#Difficulty_%game:difficulty%})",
			["#Mode_heist_chain"] =			"{%game:heist%}, Day %game:heist_day% ({#Difficulty_%game:difficulty%})",

			-- Difficulties
			["#Difficulty_easy"] =			"EASY",
			["#Difficulty_normal"] =		"NORMAL",
			["#Difficulty_hard"] =			"HARD",
			["#Difficulty_overkill"] =		"VERY HARD",
			["#Difficulty_overkill_145"] =	"OVERKILL",
			["#Difficulty_easy_wish"] =		"MAYHEM",
			["#Difficulty_overkill_290"] =	"DEATHWISH",
			["#Difficulty_sm_wish"] =		"DEATH SENTENCE"
		}

		local data = {
			["game:state"] = state,
			["game:mode"] = mode,
			["game:heist"] = heist,
			["game:heist_day"] = day,
			["game:difficulty"] = difficulty,
		}

		local s = string.format("{%s}", display or "#raw_status")

		local function populate_data(s, tokens, data, count)
			count = count or 1
			if count > 100 then
				log("Infinite loop in RP update!", "error")
				return s
			end

			if s:gmatch("%%(.+)%%") then
				for k, v in pairs(data or {}) do
					s = s:gsub("%%" .. k .. "%%", v)
				end
			end

			if s:gmatch("{(.+)}") then
				for k, v in pairs(tokens or {}) do
					local key = string.format("{%s}", k)
					if s:find(key) then
						s = s:gsub(key, populate_data(v, tokens, data, count + 1))
					end
				end
			end

			return s
		end

		s = populate_data(s, tokens, data)
		log(string.format("Steam RP updated: %s", s))
		return s
	end
elseif RequiredScript == "lib/managers/skirmishmanager" and not RichPresenceUltimate then
	local update_matchmake_attributes_original = SkirmishManager.update_matchmake_attributes
	function SkirmishManager:update_matchmake_attributes(...)
		update_matchmake_attributes_original(self, ...)

		if Global.game_settings.permission ~= "private" then
			--local game_difficulty = string.format("%i/%i", self:current_wave_number() or 1, tweak_data and #tweak_data.skirmish.ransom_amounts or 9)
			--Steam:set_rich_presence("game:difficulty", game_difficulty)
			if managers.platform then
				managers.platform:set_rich_presence()
			end
		end
	end
end

if Hooks and not RichPresenceUltimate then	-- Basegame doesn't update RP on peer count changes...
	Hooks:Add("BaseNetworkSessionOnPeerEnteredLobby", "BaseNetworkSessionOnPeerEnteredLobby_WolfHUD_RP", function(session, peer, peer_id)
		local session = managers.network:session()
		if session and Global.game_settings.permission ~= "private" then
			local group_count = tostring(session and #session:all_peers() or 1)
			Steam:set_rich_presence("steam_player_group_size", group_count)
		end
	end)

	Hooks:Add("BaseNetworkSessionOnPeerRemoved", "BaseNetworkSessionOnPeerRemoved_WolfHUD_RP", function(session, peer, peer_id, reason)
		local session = managers.network:session()
		if session and Global.game_settings.permission ~= "private" then
			local group_count = tostring(session and #session:all_peers() or 1)
			Steam:set_rich_presence("steam_player_group_size", group_count)
		end
	end)
end
