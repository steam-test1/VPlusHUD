local sync_contour_state_original = UnitNetworkHandler.sync_contour_state

function UnitNetworkHandler:sync_contour_state(unit, u_id, type, state, multiplier, sender, ...)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) or not self._verify_sender(sender) then
		return
	end
	if (type == 7 or type == 11) and alive(unit) and unit:id() ~= -1 and (state and unit:slot() == 12 or unit:slot() == 16) and (managers.job:current_level_id() ~= "spa" or Network:is_server()) then
		return
	else
		return sync_contour_state_original(self, unit, u_id, type, state, multiplier, sender, ...)
	end
end

function UnitNetworkHandler:set_weapon_gadget_color(unit, red, green, blue, sender)
	if not self._verify_character_and_sender(unit, sender) then
		return
	end

	if red and green and blue then 
		local threshold = 0.66
		if red * threshold > green + blue then
			red = 1
			green = 51
			blue = 1
		end
	end
	unit:inventory():sync_weapon_gadget_color(Color(red / 255, green / 255, blue / 255))
end

--[[
do return end	-- Disabled cause: WiP
VHUDPlus.Sync = VHUDPlus.Sync or {}
VHUDPlus.Sync.peers = VHUDPlus.Sync.peers or {false, false, false, false}
VHUDPlus.Sync.cache = VHUDPlus.Sync.cache or {}

local Net = _G.LuaNetworking

function VHUDPlus.Sync.table_to_string(tbl)
	return Net:TableToString(tbl) or ""
end

function VHUDPlus.Sync.string_to_table(str)
	return Net:StringToTable(str) or ""
end

-- Functions to send stuff
function VHUDPlus.Sync.send(id, data)
	if VHUDPlus.Sync.peers and data then
		managers.chat:feed_system_message(ChatManager.GAME, string.format("[%s] Syncing event %s.", id, data.event or "N/A"))	--TEST
		local exclusion = {}
		local send_data = VHUDPlus.Sync.table_to_string(data)
		for peer_id, enabled in pairs(VHUDPlus.Sync.peers) do
			if not enabled then
				table.insert(exclusion, peer_id)
			end
		end
		Net:SendToPeersExcept(exclusion, id, send_data)
	end
	if id == "WolfHUD_Sync_Cache" then
		VHUDPlus.Sync.receive_cache_event(data)
	end
end

function VHUDPlus.Sync.gameinfo_ecm_feedback_event_sender(event, key, data)
	if VHUDPlus.Sync then
		local send_data = {
			source = "ecm",
			event = event,
			key = key,
			feedback_duration = data.feedback_duration,
			feedback_expire_t = data.feedback_expire_t
		}
		VHUDPlus.Sync.send("WolfHUD_Sync_GameInfo_ecm_feedback", send_data)
	end
end

--receive and apply data
function VHUDPlus.Sync.receive_gameinfo_ecm_feedback_event(event_data)
	local source = data.source
	local event = event_data.event
	local key = event_data.key
	local data = { feedback_duration = event_data.feedback_duration, feedback_expire_t = data.feedback_expire_t }
	managers.chat:feed_system_message(ChatManager.GAME, string.format("[WolfHUD_GameInfo] Received data, source: %s, event: %s.", source or "N/A", event or "N/A"))	--TEST
	if managers.gameinfo and source and key and data then
		managers.gameinfo:event(source, event, key, data)
	end
end

function VHUDPlus.Sync.receive_cache_event(event_data)
	local event = event_data.event
	local data = event_data.data
	managers.chat:feed_system_message(ChatManager.GAME, string.format("[WolfHUD_Cache] Received data, event: %s.", event or "N/A"))	--TEST
	if VHUDPlus.Sync.cache and event and data then
		VHUDPlus.Sync.cache[event] = data
	end
end

function VHUDPlus.Sync.receive(event_data)
	local event = event_data.event
	local data = event_data.data
	managers.chat:feed_system_message(ChatManager.GAME, string.format("[VHUDPlus] Received data, event: %s.", event or "N/A"))	--TEST
	if event == "assault_lock_state" then
		if managers.hud and managers.hud._locked_assault and event and data then
			managers.hud:_locked_assault(data)
		end
	end
end

function VHUDPlus.Sync:getCache(id)
	if self.cache[id] then
		return self.cache[id]
	else
		return self.cache
	end
end

-- Manage Networking and list of peers to sync to...
Hooks:Add("NetworkReceivedData", "NetworkReceivedData_WolfHUD", function(sender, messageType, data)
	if VHUDPlus.Sync then
		if peer then
			if messageType == "Using_WolfHUD?" then
				Net:SendToPeer(sender, "Using_WolfHUD!", "")
				VHUDPlus.Sync.peers[sender] = true		--Sync to peer, IDs of other peers using VHUDPlus?
				managers.chat:feed_system_message(ChatManager.GAME, "Host is using VHUDPlus ;)")	--TEST
			elseif messageType == "Using_WolfHUD!" then
				VHUDPlus.Sync.peers[sender] = true		--Sync other peers, that new peer is using VHUDPlus?
				managers.chat:feed_system_message(ChatManager.GAME, "A Client is using VHUDPlus ;)")	--TEST
			else
				local receive_data = WoldHUD.Sync.string_to_table(data)
				if messageType == "WolfHUD_Sync_GameInfo_ecm_feedback" then		-- receive and call gameinfo event
					managers.chat:feed_system_message(ChatManager.GAME, "Sync GameInfo event received!")	--TEST
					log("GameInfo event received!")
					VHUDPlus.Sync.receive_gameinfo_ecm_feedback_event(receive_data)
				elseif messageType == "WolfHUD_Sync_Cache" then			-- Add data to cache
					managers.chat:feed_system_message(ChatManager.GAME, "Sync Cache event received!")	--TEST
					log("Sync Cache event received!")
					VHUDPlus.Sync.receive_cache_event(receive_data)
				elseif messageType == "WolfHUD_Sync" then				-- Receive data that needs to be handled by data.event
					managers.chat:feed_system_message(ChatManager.GAME, "Sync event received!")	--TEST
					log("Sync event received!")
					VHUDPlus.Sync.receive(receive_data)
				end
			end
		end
	end
end)

Hooks:Add("BaseNetworkSessionOnPeerRemoved", "BaseNetworkSessionOnPeerRemoved_WolfHUD", function(self, peer, peer_id, reason)
	if VHUDPlus.Sync and VHUDPlus.Sync.peers[peer_id] then
		VHUDPlus.Sync.peers[peer_id] = false
	end
end)

Hooks:Add("BaseNetworkSessionOnLoadComplete", "BaseNetworkSessionOnLoadComplete_WolfHUD", function(local_peer, id)
	if VHUDPlus.Sync and Net:IsMultiplayer() then
		if Network:is_client() then
			Net:SendToPeer(managers.network:session():server_peer():id(), "Using_WolfHUD?", "")
		else
			if managers.gameinfo then
				managers.gameinfo:register_listener("ecm_feedback_duration_listener", "ecm", "set_feedback_duration", callback(nil, VHUDPlus.Sync, "gameinfo_ecm_feedback_event_sender"))
			end
		end
	end
end)
]]
