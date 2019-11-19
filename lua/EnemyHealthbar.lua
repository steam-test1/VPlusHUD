if string.lower(RequiredScript) == "lib/managers/hudmanager" then

local _setup_player_info_hud_pd2_original = HUDManager._setup_player_info_hud_pd2

function HUDManager:_setup_player_info_hud_pd2()
	_setup_player_info_hud_pd2_original(self)
	self._enemy_target = HUDEnemyTarget:new((managers.hud:script(PlayerBase.PLAYER_INFO_HUD_PD2)))
end

function HUDManager:set_enemy_health(data)
	if self._enemy_target then
		self._enemy_target:set_health(data)
	end
end

function HUDManager:set_enemy_health_visible(visible)
	if self._enemy_target then
		self._enemy_target:set_visible(visible)
	end
end

function HUDManager:change_enemyhealthbar_setting(setting, value)
	if self._enemy_target then
		self._enemy_target:update_setting(setting, value)
	end
end

HUDEnemyTarget = HUDEnemyTarget or class()

Color.orange = Color("FF8800")
local enemy_hurt_color = Color.orange
local enemy_kill_color = Color.red
local show_multiplied_enemy_health = true

function HUDEnemyTarget:init(hud)
	self._hud_panel = hud.panel
	self._no_target = true
	
	self._enemyhealthbar_settings = {
		enemy_health_size = VHUDPlus:getSetting({"EnemyHealthbar", "SCALE"}, 75) or 75,
		enemy_health_vertical_offset = VHUDPlus:getSetting({"EnemyHealthbar", "ENEMY_HEALTH_VERTICAL_OFFSET"}, 110) or 110,
		enemy_health_horizontal_offset = VHUDPlus:getSetting({"EnemyHealthbar", "ENEMY_HEALTH_HORIZONTAL_OFFSET"}, 0) or 0,
		enemy_text_size = VHUDPlus:getSetting({"EnemyHealthbar", "ENEMY_TEXT_SIZE"}, 30) or 30
	}
	--self._enemyhealthbar_settings.enemy_health_size or 100
	self._enemy_target_panel = managers.hud:script(PlayerBase.PLAYER_INFO_HUD_PD2).panel:panel({
		name 	= "enemy_target_panel",
		h = self._enemyhealthbar_settings.enemy_health_size + 20,
		y = self._enemyhealthbar_settings.enemy_health_vertical_offset,
		valign = "top",
		layer = 0,
		visible = false
	})
	if self._enemyhealthbar_settings.enemy_health_horizontal_offset then
		self._enemy_target_panel:set_x(self._enemy_target_panel:x() + self._enemyhealthbar_settings.enemy_health_horizontal_offset)
	end

	self._enemy_target_panel:panel({
		name = "radial_health_panel",
		visible = false,
		layer = 1,
		w = self._enemyhealthbar_settings.enemy_health_size,
		h = self._enemyhealthbar_settings.enemy_health_size,
		x = self._enemy_target_panel:center() - self._enemyhealthbar_settings.enemy_health_size / 2
	}):set_bottom(self._enemy_target_panel:h())
	self._radial_health_panel = self._enemy_target_panel:panel({
		name = "radial_health_panel",
		visible = false,
		layer = 1,
		w = self._enemyhealthbar_settings.enemy_health_size,
		h = self._enemyhealthbar_settings.enemy_health_size,
		x = self._enemy_target_panel:center() - self._enemyhealthbar_settings.enemy_health_size / 2
	})
	self._radial_health = self._enemy_target_panel:panel({
		name = "radial_health_panel",
		--visible = false,
		layer = 1,
		w = self._enemyhealthbar_settings.enemy_health_size,
		h = self._enemyhealthbar_settings.enemy_health_size,
		x = self._enemy_target_panel:center() - self._enemyhealthbar_settings.enemy_health_size / 2
	}):bitmap({
		name = "radial_health",
		texture = "guis/textures/pd2/hud_health",
		texture_rect = {
			128,
			0,
			-128,
			128
		},
		render_template = "VertexColorTexturedRadial",
		align = "center",
		blend_mode = "normal",
		alpha = 1,
		w = self._enemy_target_panel:panel({
			name = "radial_health_panel",
			--visible = false,
			layer = 1,
			w = self._enemyhealthbar_settings.enemy_health_size,
			h = self._enemyhealthbar_settings.enemy_health_size,
			x = self._enemy_target_panel:center() - self._enemyhealthbar_settings.enemy_health_size / 2
		}):w(),
		h = self._enemy_target_panel:panel({
			name = "radial_health_panel",
			--visible = false,
			layer = 1,
			w = self._enemyhealthbar_settings.enemy_health_size,
			h = self._enemyhealthbar_settings.enemy_health_size,
			x = self._enemy_target_panel:center() - self._enemyhealthbar_settings.enemy_health_size / 2
		}):h(),
		layer = 2
	})
	self._radial_health:set_color(Color(1, 1, 1, 1))
	self._damage_indicator = self._enemy_target_panel:panel({
		name = "radial_health_panel",
		visible = false,
		layer = 1,
		w = self._enemyhealthbar_settings.enemy_health_size,
		h = self._enemyhealthbar_settings.enemy_health_size,
		x = self._enemy_target_panel:center() - self._enemyhealthbar_settings.enemy_health_size / 2
	}):bitmap({
		name = "damage_indicator",
		texture = "guis/textures/pd2/hud_radial_rim",
		blend_mode = "add",
		alpha = 0,
		w = self._enemy_target_panel:panel({
			name = "radial_health_panel",
			visible = false,
			layer = 1,
			w = self._enemyhealthbar_settings.enemy_health_size,
			h = self._enemyhealthbar_settings.enemy_health_size,
			x = self._enemy_target_panel:center() - self._enemyhealthbar_settings.enemy_health_size / 2
		}):w(),
		h = self._enemy_target_panel:panel({
			name = "radial_health_panel",
			visible = false,
			layer = 1,
			w = self._enemyhealthbar_settings.enemy_health_size,
			h = self._enemyhealthbar_settings.enemy_health_size,
			x = self._enemy_target_panel:center() - self._enemyhealthbar_settings.enemy_health_size / 2
		}):h(),
		layer = 1,
		align = "center"
	})
	self._damage_indicator:set_color(Color(1, 1, 1, 1))
	self._damage_bonus_glow = self._enemy_target_panel:panel({
		name = "radial_health_panel",
		visible = false,
		layer = 1,
		w = self._enemyhealthbar_settings.enemy_health_size,
		h = self._enemyhealthbar_settings.enemy_health_size,
		x = self._enemy_target_panel:center() - self._enemyhealthbar_settings.enemy_health_size / 2
	}):panel({
		visible = false,
		name = "damage_glow_panel",
		h = self._enemy_target_panel:panel({
			name = "radial_health_panel",
			visible = false,
			layer = 1,
			w = self._enemyhealthbar_settings.enemy_health_size,
			h = self._enemyhealthbar_settings.enemy_health_size,
			x = self._enemy_target_panel:center() - self._enemyhealthbar_settings.enemy_health_size / 2
		}):h() - 2,
		w = self._enemy_target_panel:panel({
			name = "radial_health_panel",
			visible = false,
			layer = 1,
			w = self._enemyhealthbar_settings.enemy_health_size,
			h = self._enemyhealthbar_settings.enemy_health_size,
			x = self._enemy_target_panel:center() - self._enemyhealthbar_settings.enemy_health_size / 2
		}):w() - 2,
		layer = 0
	}):bitmap({
		name = "glow",
		texture = "guis/textures/pd2/crimenet_marker_glow",
		texture_rect = {
			1,
			1,
			62,
			62
		},
		h = self._enemy_target_panel:panel({
			name = "radial_health_panel",
			visible = false,
			layer = 1,
			w = self._enemyhealthbar_settings.enemy_health_size,
			h = self._enemyhealthbar_settings.enemy_health_size,
			x = self._enemy_target_panel:center() - self._enemyhealthbar_settings.enemy_health_size / 2
		}):h() - 0,
		w = self._enemy_target_panel:panel({
			name = "radial_health_panel",
			visible = false,
			layer = 1,
			w = self._enemyhealthbar_settings.enemy_health_size,
			h = self._enemyhealthbar_settings.enemy_health_size,
			x = self._enemy_target_panel:center() - self._enemyhealthbar_settings.enemy_health_size / 2
		}):w() - 0,
		color = Color.red,
		blend_mode = "add",
		layer = 2,
		align = "center",
		visible = false,
		rotation = 360
	})
	self._damage_bonus_glow:set_position(0 / 2, 0 / 2)
	self._health_num = self._enemy_target_panel:panel({
		name = "radial_health_panel",
		--visible = false,
		layer = 1,
		w = self._enemyhealthbar_settings.enemy_health_size,
		h = self._enemyhealthbar_settings.enemy_health_size,
		x = self._enemy_target_panel:center() - self._enemyhealthbar_settings.enemy_health_size / 2
	}):text({
		name = "health_num",
		text = "",
		layer = 5,
		alpha = 0.9,
		color = Color.white,
		w = self._enemy_target_panel:panel({
			name = "radial_health_panel",
			--visible = false,
			layer = 1,
			w = self._enemyhealthbar_settings.enemy_health_size,
			h = self._enemyhealthbar_settings.enemy_health_size,
			x = self._enemy_target_panel:center() - self._enemyhealthbar_settings.enemy_health_size / 2
		}):w(),
		x = 0,
		y = 0,
		h = self._enemy_target_panel:panel({
			name = "radial_health_panel",
			--visible = false,
			layer = 1,
			w = self._enemyhealthbar_settings.enemy_health_size,
			h = self._enemyhealthbar_settings.enemy_health_size,
			x = self._enemy_target_panel:center() - self._enemyhealthbar_settings.enemy_health_size / 2
		}):h(),
		vertical = "center",
		align = "center",
		font_size = self._enemyhealthbar_settings.enemy_text_size,
		font = tweak_data.menu.pd2_large_font
	})
	self._health_num_bg1 = self._enemy_target_panel:panel({
		name = "radial_health_panel",
		--visible = false,
		layer = 1,
		w = self._enemyhealthbar_settings.enemy_health_size,
		h = self._enemyhealthbar_settings.enemy_health_size,
		x = self._enemy_target_panel:center() - self._enemyhealthbar_settings.enemy_health_size / 2
	}):text({
		name = "health_num_bg1",
		text = "",
		layer = 4,
		alpha = 0.9,
		color = Color.black,
		w = self._enemy_target_panel:panel({
			name = "radial_health_panel",
			--visible = false,
			layer = 1,
			w = self._enemyhealthbar_settings.enemy_health_size,
			h = self._enemyhealthbar_settings.enemy_health_size,
			x = self._enemy_target_panel:center() - self._enemyhealthbar_settings.enemy_health_size / 2
		}):w(),
		x = 0,
		y = 0,
		h = self._enemy_target_panel:panel({
			name = "radial_health_panel",
			--visible = false,
			layer = 1,
			w = self._enemyhealthbar_settings.enemy_health_size,
			h = self._enemyhealthbar_settings.enemy_health_size,
			x = self._enemy_target_panel:center() - self._enemyhealthbar_settings.enemy_health_size / 2
		}):h(),
		vertical = "center",
		align = "center",
		font_size = self._enemyhealthbar_settings.enemy_text_size,
		font = tweak_data.menu.pd2_large_font
	})
	self._health_num_bg2 = self._enemy_target_panel:panel({
		name = "radial_health_panel",
		--visible = false,
		layer = 1,
		w = self._enemyhealthbar_settings.enemy_health_size,
		h = self._enemyhealthbar_settings.enemy_health_size,
		x = self._enemy_target_panel:center() - self._enemyhealthbar_settings.enemy_health_size / 2
	}):text({
		name = "health_num_bg2",
		text = "",
		layer = 4,
		alpha = 0.9,
		color = Color.black,
		w = self._enemy_target_panel:panel({
			name = "radial_health_panel",
			--visible = false,
			layer = 1,
			w = self._enemyhealthbar_settings.enemy_health_size,
			h = self._enemyhealthbar_settings.enemy_health_size,
			x = self._enemy_target_panel:center() - self._enemyhealthbar_settings.enemy_health_size / 2
		}):w(),
		x = 0,
		y = 0,
		h = self._enemy_target_panel:panel({
			name = "radial_health_panel",
			--visible = false,
			layer = 1,
			w = self._enemyhealthbar_settings.enemy_health_size,
			h = self._enemyhealthbar_settings.enemy_health_size,
			x = self._enemy_target_panel:center() - self._enemyhealthbar_settings.enemy_health_size / 2
		}):h(),
		vertical = "center",
		align = "center",
		font_size = self._enemyhealthbar_settings.enemy_text_size,
		font = tweak_data.menu.pd2_large_font
	})
	self._health_num_bg3 = self._enemy_target_panel:panel({
		name = "radial_health_panel",
		--visible = false,
		layer = 1,
		w = self._enemyhealthbar_settings.enemy_health_size,
		h = self._enemyhealthbar_settings.enemy_health_size,
		x = self._enemy_target_panel:center() - self._enemyhealthbar_settings.enemy_health_size / 2
	}):text({
		name = "health_num_bg3",
		text = "",
		layer = 4,
		alpha = 0.9,
		color = Color.black,
		w = self._enemy_target_panel:panel({
			name = "radial_health_panel",
			--visible = false,
			layer = 1,
			w = self._enemyhealthbar_settings.enemy_health_size,
			h = self._enemyhealthbar_settings.enemy_health_size,
			x = self._enemy_target_panel:center() - self._enemyhealthbar_settings.enemy_health_size / 2
		}):w(),
		x = 0,
		y = 0,
		h = self._enemy_target_panel:panel({
			name = "radial_health_panel",
			--visible = false,
			layer = 1,
			w = self._enemyhealthbar_settings.enemy_health_size,
			h = self._enemyhealthbar_settings.enemy_health_size,
			x = self._enemy_target_panel:center() - self._enemyhealthbar_settings.enemy_health_size / 2
		}):h(),
		vertical = "center",
		align = "center",
		font_size = self._enemyhealthbar_settings.enemy_text_size,
		font = tweak_data.menu.pd2_large_font
	})
	self._health_num_bg4 = self._enemy_target_panel:panel({
		name = "radial_health_panel",
		--visible = false,
		layer = 1,
		w = self._enemyhealthbar_settings.enemy_health_size,
		h = self._enemyhealthbar_settings.enemy_health_size,
		x = self._enemy_target_panel:center() - self._enemyhealthbar_settings.enemy_health_size / 2
	}):text({
		name = "health_num_bg4",
		text = "",
		layer = 4,
		alpha = 0.9,
		color = Color.black,
		w = self._enemy_target_panel:panel({
			name = "radial_health_panel",
			--visible = false,
			layer = 1,
			w = self._enemyhealthbar_settings.enemy_health_size,
			h = self._enemyhealthbar_settings.enemy_health_size,
			x = self._enemy_target_panel:center() - self._enemyhealthbar_settings.enemy_health_size / 2
		}):w(),
		x = 0,
		y = 0,
		h = self._enemy_target_panel:panel({
			name = "radial_health_panel",
			--visible = false,
			layer = 1,
			w = self._enemyhealthbar_settings.enemy_health_size,
			h = self._enemyhealthbar_settings.enemy_health_size,
			x = self._enemy_target_panel:center() - self._enemyhealthbar_settings.enemy_health_size / 2
		}):h(),
		vertical = "center",
		align = "center",
		font_size = self._enemyhealthbar_settings.enemy_text_size,
		font = tweak_data.menu.pd2_large_font
	})
	self._health_num_bg1:set_y(self._health_num_bg1:y() - 1)
	self._health_num_bg1:set_x(self._health_num_bg1:x() - 1)
	self._health_num_bg2:set_y(self._health_num_bg2:y() + 1)
	self._health_num_bg2:set_x(self._health_num_bg2:x() + 1)
	self._health_num_bg3:set_y(self._health_num_bg3:y() + 1)
	self._health_num_bg3:set_x(self._health_num_bg3:x() - 1)
	self._health_num_bg4:set_y(self._health_num_bg4:y() - 1)
	self._health_num_bg4:set_x(self._health_num_bg4:x() + 1)
end

function HUDEnemyTarget:set_health(data)
	if not data or not data.current or not data.total then
		return
	end

	if data.current / data.total < self._radial_health:color().red then
		self._damage_was_fatal = data.current / data.total <= 0 and true or false
		self:_damage_taken()
	end

	self._radial_health:set_color(Color(1, data.current / data.total, 1, 1))
	if not (data.current <= 0) or not "" then
	end

	self._health_num:set_text((string.format(show_multiplied_enemy_health and "%.0f" or "%.1f", data.current)))
	for i = 1, 4 do
		self["_health_num_bg" .. i]:set_text((string.format(show_multiplied_enemy_health and "%.0f" or "%.1f", data.current)))
	end
end

function HUDEnemyTarget:set_visible(visible)
	
	if visible == true and not self._health_circle_visible and VHUDPlus:getSetting({"EnemyHealthbar", "ENABLED"}, true) then
		
		self._health_circle_visible = true
		
		
			self._enemy_target_panel:set_visible( true )

			

	elseif visible == false and self._health_circle_visible then

		self._health_circle_visible = nil
		

			self._enemy_target_panel:set_visible( false )
		
	end
	
end

function HUDEnemyTarget:_animate_hide_decay(radial_health_panel)
	while 1.5 > 0 and self._no_target do
		radial_health_panel:set_alpha((1.5 - coroutine.yield()) / 1.5)
	end

	if self._no_target then
		radial_health_panel:set_visible(false)
	end

	radial_health_panel:set_alpha(1)
end

function HUDEnemyTarget:_damage_taken()
	self._damage_indicator:stop()
	self._damage_indicator:animate(callback(self, self, "_animate_damage_taken"))
end

function HUDEnemyTarget:_animate_damage_taken(data)
	self:__animate_damage_taken(self._damage_was_fatal, data)
end

function HUDEnemyTarget:__animate_damage_taken(data, damage_indicator)
	damage_indicator:set_alpha(1)
	while 1.5 > 0 do
		if not data or not Color(math.clamp(0.5 - coroutine.yield(), 0, 1) / 0.5 + enemy_kill_color.r, math.clamp(0.5 - coroutine.yield(), 0, 1) / 0.5 + enemy_kill_color.g, math.clamp(0.5 - coroutine.yield(), 0, 1) / 0.5 + enemy_kill_color.b) then
		end

		damage_indicator:set_color((Color(math.clamp(0.5 - coroutine.yield(), 0, 1) / 0.5 + enemy_hurt_color.r, math.clamp(0.5 - coroutine.yield(), 0, 1) / 0.5 + enemy_hurt_color.g, math.clamp(0.5 - coroutine.yield(), 0, 1) / 0.5 + enemy_hurt_color.b)))
		damage_indicator:set_alpha((1.5 - coroutine.yield()) / 1.5)
	end

	damage_indicator:set_alpha(0)
end

function HUDEnemyTarget:update_setting(setting, value)
	if self._enemyhealthbar_settings[setting] ~= value then
		self._enemyhealthbar_settings[setting] = value
	end
	if self._enemy_target_panel then
	--	self._stats_panel:clear()
	--	self:_create_stat_list(self._stats_panel)
	end
end

elseif string.lower(RequiredScript) == "lib/units/beings/player/states/playerstandard" then
	local show_multiplied_enemy_health = true
local _update_fwd_ray_ori = PlayerStandard._update_fwd_ray

function PlayerStandard:_update_fwd_ray()
	_update_fwd_ray_ori(self)
	if self._fwd_ray and self._fwd_ray.unit and type(self._fwd_ray.unit) == "userdata" then
			local unit = self._fwd_ray.unit
			if unit:in_slot( 8 ) and alive(unit:parent()) then -- Fix when aiming at shields shield.
				unit = unit:parent()
			end
			
			if VHUDPlus:getSetting({"EnemyHealthbar", "IGNORE_CIVILIAN_HEALTH"}, true) and managers.enemy:is_civilian(unit) then
				return
			end
			if VHUDPlus:getSetting({"EnemyHealthbar", "IGNORE_TEAM_AI_HEALTH"}, true) and unit:in_slot(16) then
				return
			end
			
			local visible, name, name_id, health, max_health, shield
			if alive( unit ) then
				if unit:in_slot( 25 ) and not unit:character_damage():dead() and (table.contains(managers.groupai:state():turrets() or {}, unit) and Network:is_server()) then
					self._last_unit = nil
					visible = true
					if not unit:character_damage():needs_repair() then
						shield = true
						managers.hud:set_enemy_health({
							current = (unit:character_damage()._shield_health or 0) * (show_multiplied_enemy_health and 10 or 1),
							total = (unit:character_damage()._SHIELD_HEALTH_INIT or 0) * (show_multiplied_enemy_health and 10 or 1)
						})
					else
						managers.hud:set_enemy_health({
							current = (unit:character_damage()._health or 0) * (show_multiplied_enemy_health and 10 or 1),
							total = (unit:character_damage()._HEALTH_INIT or 0) * (show_multiplied_enemy_health and 10 or 1)
						})
					end
				elseif alive( unit ) and ( unit:in_slot( 12 ) or ( unit:in_slot( 21 ) or unit:in_slot( 22 ) ) or unit:in_slot( 16 ) and Network:is_server()) and not unit:character_damage():dead() then
					self._last_unit = unit
					visible = true
					managers.hud:set_enemy_health({
							current = (unit:character_damage()._health or 0) * (show_multiplied_enemy_health and 10 or 1),
							total = (unit:character_damage()._HEALTH_INIT or 0) * (show_multiplied_enemy_health and 10 or 1)
					})

				elseif alive( unit ) and unit:in_slot( 39 ) and VHUDPlus:getSetting({"EnemyHealthbar", "SHOW_VEHICLE"}, true) and unit:vehicle_driving() and not self._seat then
					self._last_unit = nil
					visible = true
					managers.hud:set_enemy_health({
							current = (unit:character_damage()._health or 0) * (show_multiplied_enemy_health and 10 or 1),
							total = (unit:character_damage()._HEALTH_INIT or 0) * (show_multiplied_enemy_health and 10 or 1)
					})
				else
					visible = false
				end
			end

			if not visible and self._last_unit and alive( self._last_unit ) and self._last_unit:character_damage() then
				managers.hud:set_enemy_health({
					current = (self._last_unit:character_damage()._health or 0) * (show_multiplied_enemy_health and 10 or 1),
					total = (self._last_unit:character_damage()._HEALTH_INIT or 0) * (show_multiplied_enemy_health and 10 or 1)
				})

				local angle = (self:getUnitRotation(self._last_unit) + 360) % 360
				if self._last_unit:character_damage():dead() or (angle < 350 and angle > 10) then
					visible = false
					self._last_unit = nil
				else
					visible = true
				end
			end

			managers.hud:set_enemy_health_visible( visible, shield )
		else
			managers.hud:set_enemy_health_visible( false )
		end
end
function PlayerStandard:getUnitRotation( unit )

	if not unit or not alive( unit ) then return 360 end

	local unit_position = unit:position()
	local vector = unit_position - self._camera_unit:position()
	local forward = self._camera_unit:rotation():y()
	local rotation = math.floor( vector:to_polar_with_reference( forward , math.UP ).spin )

	return rotation

end
elseif string.lower(RequiredScript) == "lib/states/ingamearrested" then
	Hooks:PostHook( IngameArrestedState , "at_enter" , "WolfHUDPostIngameArrestedAtEnter" , function( self )
		if managers.hud then
			managers.hud:set_enemy_health_visible( false, false )
		end
	end )
end
