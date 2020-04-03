if RequiredScript == "lib/units/enemies/cop/copdamage" then
	local _on_damage_received_original = CopDamage._on_damage_received
	--Workaround for Teammate Headshots, since col_ray doesn't get forwarded...  (self._sync_ibody_popup)
	local sync_damage_bullet_original = CopDamage.sync_damage_bullet
	local sync_damage_melee_original = CopDamage.sync_damage_melee

	function CopDamage:_on_damage_received(data, ...)
		self:_process_popup_damage(data)
		self._sync_ibody_popup = nil
		return _on_damage_received_original(self, data, ...)
	end

	function CopDamage:sync_damage_bullet(attacker_unit, damage_percent, i_body, ...)
		if i_body then
			self._sync_ibody_popup = i_body
		end

		return sync_damage_bullet_original(self, attacker_unit, damage_percent, i_body, ...)
	end

	function CopDamage:sync_damage_melee(attacker_unit, damage_percent, damage_effect_percent, i_body, ...)
		if i_body then
			self._sync_ibody_popup = i_body
		end

		return sync_damage_melee_original(self, attacker_unit, damage_percent, damage_effect_percent, i_body, ...)

	end
	
	Hooks:PreHook( CopDamage , "_on_damage_received" , "DmgPop_PreCopDamageOnDamageReceived" , function( self , damage_info )
		
	if self._uws and alive( self._uws ) then
		self._uws:panel():stop()
		World:newgui():destroy_workspace( self._uws )
		self._uws = nil
	end
	
	self._uws = World:newgui():create_world_workspace( 165 , 100 , self._unit:movement():m_head_pos() + Vector3( 0 , 0 , 70 ) , Vector3( 50 , 0 , 0 ) , Vector3( 0 , 0 , -50 ) )
	self._uws:set_billboard( self._uws.BILLBOARD_BOTH )
	
	local panel = self._uws:panel():panel({
		visible =  VHUDPlus:getSetting({"DamagePopup", "SHOW_DAMAGE_POPUP_ALT"}, true) and damage_info.damage * 10 > 0.99,
		name 	= "damage_panel",
		layer = 0,
		alpha = 0
	})

	if damage_info.damage * 10 > 999 then
	    glow_w = 375
	elseif damage_info.damage * 10 > 99 then
	    glow_w = 330
	else
	    glow_w = 300
	end	
	
	local glow_panel = panel:bitmap({
		name = "glow_panel",
		texture = "guis/textures/pd2/crimenet_marker_glow",
		visible = damage_info.result.type == "death" and headshot,
		w = 192,
		h = 192,
		blend_mode = "add",
		alpha = 0.55,
		color = VHUDPlus:getColorSetting({"DamagePopup", "GLOW_COLOR"}, "red"),
		--color = DmgPopUp.colors[(DmgPopUp.options.damage_popup_headshot_flash_color)],
		x = -100,
		y = -35,
		h = 200,
		w = glow_w,
		rotation = 360,
		align = "left",
		layer = 1
	})
	
	local text = panel:text({
		text 		= string.format( damage_info.damage * 10 >= 10 and "%d" or "%.1f" , damage_info.damage * 10 ),
		layer 		= 1,
		align 		= "left",
		vertical 	= "bottom",
		font 		= tweak_data.menu.pd2_medium_font,
		font_size 	= 60,
		color 		= VHUDPlus:getColorSetting({"DamagePopup", "COLOR"}, "yellow")
	})
	
	-- local attacker_unit = damage_info and damage_info.attacker_unit
	
	-- if alive( attacker_unit ) and attacker_unit:base() and attacker_unit:base().thrower_unit then
	-- 	attacker_unit = attacker_unit:base():thrower_unit()
	-- end
	
	-- if attacker_unit and managers.network:session() and managers.network:session():peer_by_unit( attacker_unit ) then
	-- 	local peer_id = managers.network:session():peer_by_unit( attacker_unit ):id()
	-- 	local c = tweak_data.chat_colors[ peer_id ]
	-- 	text:set_color( c )
	-- end
	
	local body = damage_info.col_ray and damage_info.col_ray.body or self._sync_ibody_popup and self._unit:body(self._sync_ibody_popup)
	local headshot = body and self.is_head and self:is_head(body) or false
	if damage_info.result.type == "death" then
		text:set_text( managers.localization:get_default_macro( "BTN_SKULL" ) .. text:text() )
		text:set_range_color( 0 , 1 , VHUDPlus:getColorSetting({"DamagePopup", headshot and "HEADSHOT_COLOR" or "COLOR"}, "yellow") )
	end
	
	panel:animate( function( p )
		over( VHUDPlus:getSetting({"DamagePopup", "DURATION_ALT"}, 2.2) , function( o )
			self._uws:set_world( 165 , 100 , self._unit:movement():m_head_pos() + Vector3( 0 , 0 , 70 ) + Vector3( 0 , 0 , math.lerp( 0 , 50 , o ) ) , Vector3( 50 , 0 , 0 ) , Vector3( 0 , 0 , -50 ) )
			text:set_color( text:color():with_alpha( 0.5 + ( math.sin( o * 750 ) + 0.5 ) / 4 ) )
			panel:set_alpha( math.lerp( 1 , 0 , o ) )
		end )
		panel:remove( text )
		World:newgui():destroy_workspace( self._uws )
	end )
	
	local anim_pulse_glow = function(o)
				local t = 0
	
	while true do
	
		t = t + coroutine.yield()
		panel:set_alpha( ( math.abs( math.sin( ( 4 + t ) * 360 * 4 / 4 ) ) ) )
	end
				panel:remove( text )
				World:newgui():destroy_workspace( self._uws )
			end
			--glow:set_center(cost_text:center())
			if damage_info.result.type == "death" and headshot then
			panel:animate(anim_pulse_glow)
			end

end )

Hooks:PostHook( CopDamage , "destroy" , "DmgPop_PostCopDamageDestroy" , function( self , ... )

	if self._uws and alive( self._uws ) then
		World:newgui():destroy_workspace( self._uws )
		self._uws = nil
	end

end )

	function CopDamage:_process_popup_damage(data)
		CopDamage.DMG_POPUP_SETTING = VHUDPlus:getSetting({"DamagePopup", "DISPLAY_MODE"}, 2)

		local attacker = alive(data.attacker_unit) and data.attacker_unit
		local damage = tonumber(data.damage) or 0

		if attacker and damage >= 0.1 and CopDamage.DMG_POPUP_SETTING > 1 then
			local killer

			if attacker:in_slot(3) or attacker:in_slot(5) then
				--Human team mate
				killer = attacker
			elseif attacker:in_slot(2) then
				--Player
				killer = attacker
			elseif attacker:in_slot(16) then
				--Bot/joker
				local key = tostring(attacker:key())
				local minion_data = managers.gameinfo and managers.gameinfo:get_minions(key)
				if minion_data then
					-- Joker
					killer = minion_data.owner and managers.criminals:character_unit_by_peer_id(minion_data.owner)
				else
					-- Bot
					killer = attacker
				end
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

			if alive(killer) and alive(self._unit) then
				local body = data.col_ray and data.col_ray.body or self._sync_ibody_popup and self._unit:body(self._sync_ibody_popup)
				local headshot = body and self.is_head and self:is_head(body) or false
				if CopDamage.DMG_POPUP_SETTING == 2 then
					if killer:in_slot(2) then
						self:show_popup(damage, self._dead, headshot, data.critical_hit)
					end
				else
					local color_id = managers.criminals:character_color_id_by_unit(killer)
					if color_id then
						self:show_popup(damage, self._dead, headshot, false, color_id)
					end
				end
			end
		end
	end

	function CopDamage:show_popup(damage, dead, headshot, critical, color_id)
		if managers.waypoints then
			local id = "damage_wp_" .. tostring(self._unit:key())
			local waypoint = managers.waypoints:get_waypoint(id)
			local waypoint_color = color_id and ((color_id == 5 and VHUDPlus:getSetting({"CustomHUD", "TEAMMATE", "AI_COLOR", "USE"}, false)) and VHUDPlus:getColorSetting({"CustomHUD", "TEAMMATE", "AI_COLOR", "COLOR"}, Color.white) or tweak_data.chat_colors[color_id]) or VHUDPlus:getColorSetting({"DamagePopup", critical and "CRITICAL_COLOR" or headshot and "HEADSHOT_COLOR" or "COLOR"}, "yellow")
			waypoint_color = waypoint_color:with_alpha(VHUDPlus:getSetting({"DamagePopup", "ALPHA"}, 1))
			local waypoint_duration = VHUDPlus:getSetting({"DamagePopup", "DURATION"}, 3)
			if waypoint and not waypoint:is_deleted() then
				managers.waypoints:set_waypoint_duration(id, "duration", waypoint_duration)
				managers.waypoints:set_waypoint_label(id, "label", self:build_popup_text(damage, headshot))
				managers.waypoints:set_waypoint_setting(id, "color", waypoint_color)
				managers.waypoints:set_waypoint_component_setting(id, "icon", "show", dead)
			else
				local params = {
					unit = self._unit,
					offset = Vector3(10, 10, VHUDPlus:getSetting({"DamagePopup", "HEIGHT"}, 20)),
					scale = 2 * VHUDPlus:getSetting({"DamagePopup", "SCALE"}, 1),
					color = waypoint_color,
					visible_distance = {
						min = 30,
						max = 10000
					},
					rescale_distance = {
						start_distance = 500,
						end_distance = 3000,
						final_scale = 0.5
					},
					fade_duration = {
						start = 0.5,
						stop = 1,
						alpha = true,
					},
					icon = {
						type = "icon",
						show = dead,
						scale = VHUDPlus:getSetting({"DamagePopup", "SKULL_SCALE"}, 1.2),
						texture = "guis/textures/pd2/risklevel_blackscreen",
						texture_rect = {0, 0, 64, 64},
						blend_mode = "normal",
						on_minimap = false
					},
					label = {
						type = "label",
						show = true,
						text = self:build_popup_text(damage, headshot, true)
					},
					duration = {
						type = "duration",
						show = false,
						initial_value = waypoint_duration,
						fade_duration = {
							start = 0,
							stop = 1,
							position = Vector3(0, 0, 30),
						},
					},
					component_order = { VHUDPlus:getSetting({"DamagePopup", "SKULL_ALIGN"}, 1) == 1 and { "icon", "label" } or { "label", "icon" } , { "duration" } }
				}
				managers.waypoints:add_waypoint(id, "CustomWaypoint", params)
			end
		end
	end

	function CopDamage:build_popup_text(damage, headshot, is_new)
		self._dmg_value = (not is_new and self._dmg_value or 0) + (damage * 10)
		return math.floor(self._dmg_value) .. ((CopDamage.DMG_POPUP_SETTING == 3 and headshot) and "!" or "")
	end

elseif RequiredScript == "lib/units/civilians/civiliandamage" then
	local _on_damage_received_original = CivilianDamage._on_damage_received
	function CivilianDamage:_on_damage_received(data, ...)
		CivilianDamage.super._process_popup_damage(self, data)
		return _on_damage_received_original(self, data, ...)
	end
	
	Hooks:PreHook( CivilianDamage , "_on_damage_received" , "DmgPopPreCopDamageOnDamageReceived" , function( self , damage_info )
		
	if self._uws and alive( self._uws ) then
		self._uws:panel():stop()
		World:newgui():destroy_workspace( self._uws )
		self._uws = nil
	end
	
	self._uws = World:newgui():create_world_workspace( 165 , 100 , self._unit:movement():m_head_pos() + Vector3( 0 , 0 , 70 ) , Vector3( 50 , 0 , 0 ) , Vector3( 0 , 0 , -50 ) )
	self._uws:set_billboard( self._uws.BILLBOARD_BOTH )
	
	local panel = self._uws:panel():panel({
		visible = VHUDPlus:getSetting({"DamagePopup", "SHOW_DAMAGE_POPUP_ALT"}, true) and VHUDPlus:getSetting({"DamagePopup", "SHOW_DAMAGE_POPUP_ALT_CIV"}, true),
		name 	= "damage_panel",
		layer = 0,
		alpha = 0
	})
	
	local text = panel:text({
		text 		= string.format( damage_info.damage * 10 >= 10 and "%d" or "%.1f" , damage_info.damage * 10 ),
		layer 		= 1,
		align 		= "left",
		vertical 	= "bottom",
		font 		= tweak_data.menu.pd2_medium_font,
		font_size 	= 60,
		color 		= VHUDPlus:getColorSetting({"DamagePopup", "COLOR"}, "yellow")
	})
	
	-- local attacker_unit = damage_info and damage_info.attacker_unit
	
	-- if alive( attacker_unit ) and attacker_unit:base() and attacker_unit:base().thrower_unit then
	-- 	attacker_unit = attacker_unit:base():thrower_unit()
	-- end
	
	-- if attacker_unit and managers.network:session() and managers.network:session():peer_by_unit( attacker_unit ) then
	-- 	local peer_id = managers.network:session():peer_by_unit( attacker_unit ):id()
	-- 	local c = tweak_data.chat_colors[ peer_id ]
	-- 	text:set_color( c )
	-- end
	
	if damage_info.result.type == "death" then
		text:set_text( managers.localization:get_default_macro( "BTN_SKULL" ) .. text:text() )
		text:set_range_color( 0 , 1 , VHUDPlus:getColorSetting({"DamagePopup", "COLOR"}, "yellow") )
	end
	
	panel:animate( function( p )
		over( VHUDPlus:getSetting({"DamagePopup", "DURATION_ALT"}, 2.2) , function( o )
			self._uws:set_world( 165 , 100 , self._unit:movement():m_head_pos() + Vector3( 0 , 0 , 70 ) + Vector3( 0 , 0 , math.lerp( 0 , 50 , o ) ) , Vector3( 50 , 0 , 0 ) , Vector3( 0 , 0 , -50 ) )
			text:set_color( text:color():with_alpha( 0.5 + ( math.sin( o * 750 ) + 0.5 ) / 4 ) )
			panel:set_alpha( math.lerp( 1 , 0 , o ) )
		end )
		panel:remove( text )
		World:newgui():destroy_workspace( self._uws )
	end )

	end )

	Hooks:PostHook( CivilianDamage , "destroy" , "DmgPopPostCopDamageDestroy" , function( self , ... )

		if self._uws and alive( self._uws ) then
			World:newgui():destroy_workspace( self._uws )
			self._uws = nil
		end

	end )
end
