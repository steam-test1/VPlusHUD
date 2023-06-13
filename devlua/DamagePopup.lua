
if RequiredScript == "lib/units/enemies/cop/copdamage" and not VHUDPlus.dmg_pop then
	VHUDPlus.dmg_pop = true
	local init_original = CopDamage.init
	function CopDamage.init(self, ...)
		self._head_body_name = self._head_body_name
		init_original(self, ...)
		self._hud = HoxPopUp:new(self._unit)
	end

	-- if blt.blt_info().platform == "mswindows" then
		HoxPopUp = HoxPopUp or class()
	-- end

	local _update_debug_ws_original = CopDamage._update_debug_ws
		
	function CopDamage:_update_debug_ws(damage_info, ...)
		self:popup_kill(damage_info)
		-- self:_process_popup_damage(damage_info)
		self._sync_ibody_popup = nil
		return _update_debug_ws_original(self, damage_info, ...)
	end

	function CopDamage:popup_kill(damage_info)
		-- if not blt.blt_info().platform == "mswindows" then return end

		local damage = damage_info and tonumber(damage_info.damage) or 0

		local attacker = damage_info and alive(damage_info.attacker_unit) and damage_info.attacker_unit
		local killer
		
		if alive( attacker ) and attacker:base() and attacker:base().thrower_unit then
			attacker = attacker:base():thrower_unit()
		end

		local damage_check = false

		if attacker and damage >= 0.1 and not damage_check then
			local body = damage_info and damage_info.col_ray and damage_info.col_ray.body
			local headshot = body and damage_info.headshot
			if damage_info and damage_info.variant == "bullet" and attacker:in_slot(2) then
				killer = attacker
				self._hud:show_damage(damage, self._dead, headshot)
			elseif damage_info and damage_info.variant == "melee" and attacker:in_slot(2) then
				killer = attacker
				self._hud:show_damage(damage, self._dead, headshot)
			elseif damage_info and damage_info.variant == "explosion" and attacker:in_slot(2) then
				killer = attacker
				self._hud:show_damage(damage, self._dead, false)
			elseif damage_info and damage_info.variant == "fire" and attacker:in_slot(2) then
				killer = attacker
				self._hud:show_damage(damage, self._dead, false)
			elseif attacker:in_slot(2) then
				killer = attacker
				self._hud:show_damage(damage, self._dead, headshot)
			end
			damage_check = true
		end
	end

elseif RequiredScript == "lib/units/civilians/civiliandamage" then
	--Not Needed
end
