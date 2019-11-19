local _upd_criminal_suspicion_progress_original = GroupAIStateBase._upd_criminal_suspicion_progress
 
function GroupAIStateBase:_upd_criminal_suspicion_progress(...)
	if self._ai_enabled then
		for obs_key, obs_susp_data in pairs(self._suspicion_hud_data or {}) do
			local unit = obs_susp_data.u_observer
			
			if managers.enemy:is_civilian(unit) then
				local waypoint = managers.hud._hud.waypoints["susp1" .. tostring(obs_key)]
				
				if waypoint then
					if unit:anim_data().drop and VHUDPlus:getSetting({"HUDSuspicion", "SHOW_PACIFIED_CIVILIANS"}, true) then
						if not obs_susp_data._subdued_civ then
							obs_susp_data._alerted_civ = nil
							obs_susp_data._subdued_civ = true
							waypoint.bitmap:set_color(Color(0.0, 1.0, 0.0))
							waypoint.arrow:set_color(Color(0.75, 0, 0.3, 0))
						end
					elseif obs_susp_data.alerted then
						if not obs_susp_data._alerted_civ then
							obs_susp_data._subdued_civ = nil
							obs_susp_data._alerted_civ = true
							waypoint.bitmap:set_color(Color.white)
							waypoint.arrow:set_color(tweak_data.hud.detected_color:with_alpha(0.75))
						end
					end
				end
			end
		end
	end
	
	return _upd_criminal_suspicion_progress_original(self, ...)
end
