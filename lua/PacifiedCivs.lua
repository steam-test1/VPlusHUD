
-- local _upd_criminal_suspicion_progress_original = GroupAIStateBase._upd_criminal_suspicion_progress
-- function GroupAIStateBase:_upd_criminal_suspicion_progress(...)
-- 	if self._ai_enabled then
-- 		for obs_key, obs_susp_data in pairs(self._suspicion_hud_data or {}) do
-- 			local unit = obs_susp_data.u_observer
-- 			if managers.enemy:is_civilian(unit) then
-- 				local waypoint_id = "susp1" .. tostring(obs_key)
-- 				local waypoint = managers.hud and managers.hud._hud.waypoints[waypoint_id]
-- 				if waypoint then
-- 					local color, arrow_color
-- 					if unit:anim_data().drop and VHUDPlus:getSetting({"HUDSuspicion", "SHOW_PACIFIED_CIVILIANS"}, true) then
-- 						if not obs_susp_data._subdued_civ then
-- 							obs_susp_data._alerted_civ = nil
-- 							obs_susp_data._subdued_civ = true
-- 						if VHUDPlus:getSetting({"HUDSuspicion", "SHOW_PACIFIED_CIVILIANS_ALT_ICON"}, true) then	
-- 							waypoint.bitmap:set_color(Color(0.0, 1.0, 0.0))
-- 							waypoint.arrow:set_color(Color(0.75, 0, 0.3, 0))
-- 						else
-- 							color = Color(0, 0.71, 1)
-- 							arrow_color = Color(0, 0.35, 0.5)
-- 							waypoint.bitmap:set_image("guis/textures/menu_singletick")
-- 					        end
-- 						end
-- 					elseif obs_susp_data.alerted then
-- 						if not obs_susp_data._alerted_civ then
-- 							obs_susp_data._subdued_civ = nil
-- 							obs_susp_data._alerted_civ = true
-- 							color = Color.white
-- 							arrow_color = tweak_data.hud.detected_color
-- 							waypoint.bitmap:set_image("guis/textures/hud_icons")
-- 							waypoint.bitmap:set_texture_rect(479, 433, 32, 32)
-- 						end
-- 					end
-- 					if color and arrow_color then
-- 						waypoint.bitmap:set_color(color)
-- 						waypoint.arrow:set_color(arrow_color:with_alpha(0.75))
-- 					end
-- 				end
-- 			end
-- 		end
-- 	end
-- 	return _upd_criminal_suspicion_progress_original(self, ...)
-- end
-- CONFIG **********************************************************************
local config = {}

config.icons = {}

config.icons.civilian_alerted = "assets/guis/textures/civilian_alerted"
config.icons.civilian_curious = "assets/guis/textures/civilian_curious"

if VHUDPlus:getSetting({"HUDSuspicion", "SHOW_PACIFIED_CIVILIANS_WOLFDEFAULT"}, true) then
	config.icons.civilian_subdued = "guis/textures/menu_singletick"
else
	config.icons.civilian_subdued = "assets/guis/textures/civilian_subdued"
end

config.icons.guard_alerted = "assets/guis/textures/guard_alerted"
config.icons.guard_curious = "assets/guis/textures/guard_curious"

config.icons.camera_alerted = "assets/guis/textures/camera_alerted"
config.icons.camera_curious = "assets/guis/textures/camera_curious"

config.colors = {}

config.colors.called  = Color(1,0,0)
config.colors.calling = Color(1,0,0)

if VHUDPlus:getSetting({"HUDSuspicion", "SHOW_PACIFIED_CIVILIANS_WOLFDEFAULT"}, true) then
	config.colors.subdued = Color(0,0.65,1)
else
	config.colors.subdued = Color('008000')
end

config.colors.alerted = Color(1,0.2,0)
config.colors.curious = Color(0,0.65,1)

-- OVERRIDES *******************************************************************
local _upd_criminal_suspicion_progress_orig = GroupAIStateBase._upd_criminal_suspicion_progress
function GroupAIStateBase:_upd_criminal_suspicion_progress(...)
    if self._ai_enabled and not VHUDPlus:getSetting({"HUDSuspicion", "SHOW_PACIFIED_CIVILIANS_ALT_ICON"}, true) then
 		for obs_key, obs_susp_data in pairs(self._suspicion_hud_data or {}) do
			local unit = obs_susp_data.u_observer
			if managers.enemy:is_civilian(unit) then
				local waypoint_id = "susp1" .. tostring(obs_key)
				local waypoint = managers.hud and managers.hud._hud.waypoints[waypoint_id]
			    if waypoint then
					local color, arrow_color
				    if unit:anim_data().drop and VHUDPlus:getSetting({"HUDSuspicion", "SHOW_PACIFIED_CIVILIANS"}, true) then
 					    if not obs_susp_data._subdued_civ then
 						    obs_susp_data._alerted_civ = nil
 						    obs_susp_data._subdued_civ = true
						
						    if VHUDPlus:getSetting({"HUDSuspicion", "SHOW_PACIFIED_CIVILIANS_WOLFDEFAULT"}, true) then	
 							    color = Color(0, 0.71, 1)
							    arrow_color = Color(0, 0.35, 0.5)
 							    waypoint.bitmap:set_image("guis/textures/menu_singletick")
						    else
							    waypoint.bitmap:set_color(Color(0.0, 1.0, 0.0))
 							    waypoint.arrow:set_color(Color(0.75, 0, 0.3, 0))
 					        end
 					    end
 			        elseif obs_susp_data.alerted then
 					    if not obs_susp_data._alerted_civ then
 					        obs_susp_data._subdued_civ = nil
 						    obs_susp_data._alerted_civ = true
 						    color = Color.white
 						    arrow_color = tweak_data.hud.detected_color
 						    waypoint.bitmap:set_image("guis/textures/hud_icons")
 						    waypoint.bitmap:set_texture_rect(479, 433, 32, 32)
					    end
 				    end
				
				    if color and arrow_color then
 					    waypoint.bitmap:set_color(color)
					    waypoint.arrow:set_color(arrow_color:with_alpha(0.75))
				    end
			    end
 		    end
 	    end
	elseif self._ai_enabled and VHUDPlus:getSetting({"HUDSuspicion", "SHOW_PACIFIED_CIVILIANS_ALT_ICON"}, true) and VHUDPlus:getSetting({"HUDSuspicion", "SHOW_PACIFIED_CIVILIANS"}, true) then
		for obs_key, obs_susp_data in pairs(self._suspicion_hud_data or {}) do
			local waypoint = managers.hud._hud.waypoints["susp1" .. tostring(obs_key)]

			if waypoint then
				local waypoint_data = buildWaypointData(obs_susp_data)
				setWaypointIcon(waypoint, decideWaypointIcon(waypoint_data))
				setWaypointColor(waypoint, decideWaypointColor(waypoint_data))
			end
		end
	end

	return _upd_criminal_suspicion_progress_orig(self, ...)
end

-- FUNCTION LIB ****************************************************************
function buildWaypointData(obs_susp_data)
	local unit = obs_susp_data.u_observer
	local data = {}

	--type
	if managers.enemy:is_civilian(unit) then
		data.type = "civilian"
	elseif unit:character_damage() then
		data.type = "guard"
	else
		data.type = "camera"
	end

	--state
	if (type(obs_susp_data.status) == 'string' and obs_susp_data.status == 'called') then
		data.state = "called"
	elseif (type(obs_susp_data.status) == 'string' and obs_susp_data.status == 'calling') then
		data.state = "calling"
	elseif (unit:anim_data() and unit:anim_data().drop) then
		data.state = "subdued"
	elseif (obs_susp_data.alerted) then
		data.state = "alerted"
	else
		data.state = "curious"
	end

	return data
end

function decideWaypointIcon(waypoint_data)
	local icon

	if waypoint_data.type == "camera" then
		if waypoint_data.state == "alerted" then
			icon = config.icons.camera_alerted
		else
			icon = config.icons.camera_curious
		end
	elseif waypoint_data.type == "civilian" then
		if waypoint_data.state == "subdued" then
			icon = config.icons.civilian_subdued
		elseif waypoint_data.state == "alerted" then
			icon = config.icons.civilian_alerted
		else
			icon = config.icons.civilian_curious
		end
	elseif waypoint_data.type == "guard" then
		if waypoint_data.state == "alerted" then
			icon = config.icons.guard_alerted
		else
			icon = config.icons.guard_curious
		end
	end

	--disable icon change for calling/called status (use built-in icons)
	if waypoint_data.state == "calling" or waypoint_data.state == "called" then
		icon = false
	end

	return icon
end

function decideWaypointColor(waypoint_data)
	local color

	if waypoint_data.state == "called" then
		color = config.colors.called
	elseif waypoint_data.state == "calling" then
		color = config.colors.calling
	elseif waypoint_data.state == "subdued" then
		color = config.colors.subdued
	elseif waypoint_data.state == "alerted" then
		color = config.colors.alerted
	elseif waypoint_data.state == "curious" then
		color = config.colors.curious
	end

	return color
end

function setWaypointIcon(waypoint, icon)
	if icon then
		waypoint.bitmap:set_image(icon)
	end
end

function setWaypointColor(waypoint, color)
	if color then
		waypoint.bitmap:set_color(color)
		waypoint.arrow:set_color(color:with_alpha(0.75))
	end
end
