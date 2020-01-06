if string.lower(RequiredScript) == "lib/managers/hud/hudobjectives" then

-- Old

elseif string.lower(RequiredScript) == "lib/managers/hud/hudheisttimer" then

-- Old

elseif string.lower(RequiredScript) == "core/lib/managers/subtitle/coresubtitlepresenter" and VHUDPlus:getSetting({"HUDList", "BUFF_LIST", "show_buffs"}, true) then
	core:module("CoreSubtitlePresenter")
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
