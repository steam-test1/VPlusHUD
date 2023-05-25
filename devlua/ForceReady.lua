if string.lower(RequiredScript) == "lib/managers/hudmanagerpd2" then

-- Host-controlled force start
-- Need to click the "Ready" button in lobby multiple times for a menu to appear
local FORCE_READY_CLICKS = 3
local FORCE_READY_TIME = 2
local FORCE_READY_ACTIVE_T = 90

local force_ready_start_t = 0
local force_ready_clicked = 0

local set_slot_ready_orig = HUDManager.set_slot_ready
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
									local gsm = game_state_machine
									local gsm_state = gsm and gsm:current_state()
									-- Fix crash where Force Start menu remains open
									-- into the loading screen (between lobby and in-game state)
									-- @TODO: Automatically close the menu when the game starts?
									if gsm_state and gsm_state.start_game_intro then
										managers.chat:send_message(ChatManager.GAME, local_peer,
											managers.localization:text("wolfhud_dialog_force_start_msg"))

										gsm_state:start_game_intro()
									else
										-- 'ingame_mask_off' state is the black loading screen
										log(string.format("VHUDPlus: Cannot force start in current game state '%s' (%s)",
											gsm.current_state_name and gsm:current_state_name() or "",
											tostring(gsm_state)
										))
									end
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

end
