if string.lower(RequiredScript) == "lib/managers/hud/hudobjectives" then

-- Old

elseif string.lower(RequiredScript) == "lib/managers/hud/hudheisttimer" then

-- Old

elseif string.lower(RequiredScript) == "core/lib/managers/subtitle/coresubtitlepresenter" then
	core:module("CoreSubtitlePresenter")
	function OverlayPresenter:show_text(text, duration)
		self.__font_name = "fonts/font_medium_mf"
		self._text_scale = _G.VHUDPlus:getSetting({"MISCHUD", "SCALE"}, 1)
		local text_shadow = _G.VHUDPlus:getSetting({"MISCHUD", "SUB"}, true)
		local label = self.__subtitle_panel:child("label") or self.__subtitle_panel:text({
			name = "label",
			font = self.__font_name,
			font_size = self.__font_size * self._text_scale,
			color = Color.white,
			align = "center",
			vertical = "bottom",
			layer = 1,
			wrap = true,
			word_wrap = true
		})
		local shadow = self.__subtitle_panel:child("shadow") or self.__subtitle_panel:text({
			name = "shadow",
			x = 1,
			y = 1,
			font = self.__font_name,
			font_size = self.__font_size * self._text_scale,
			color = Color.black:with_alpha(1),
			align = "center",
			vertical = "bottom",
			layer = 0,
			wrap = true,
			word_wrap = true
		})
		label:set_text(text)
		shadow:set_text(text)	
		label:set_font_size(self.__font_size * self._text_scale)
		shadow:set_font_size(self.__font_size * self._text_scale)
		shadow:set_visible(text_shadow)
	end
	
	local _on_resolution_changed_original = OverlayPresenter._on_resolution_changed
	function OverlayPresenter:_on_resolution_changed(...)
		_on_resolution_changed_original(self, ...)
		self:apply_bottom_offset()
	end

	function OverlayPresenter:set_bottom(offset)
		if self._bottom_off ~= offset then
			self._bottom_off = offset
			self:apply_bottom_offset()
		end
	end

	function OverlayPresenter:apply_bottom_offset()
		if self.__subtitle_panel and self._bottom_off then
			self.__subtitle_panel:set_height(self._bottom_off or self.__subtitle_panel:h())
			local label = self.__subtitle_panel:child("label")
			if label then
				label:set_h(self.__subtitle_panel:h())
				label:set_w(self.__subtitle_panel:w())
			end
			local shadow = self.__subtitle_panel:child("shadow")
			if shadow then
				shadow:set_h(self.__subtitle_panel:h())
				shadow:set_w(self.__subtitle_panel:w())
			end
		end
	end
end
