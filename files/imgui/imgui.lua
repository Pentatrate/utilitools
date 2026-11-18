local _imgui = {}

_imgui.mouse = _imgui.mouse or {
	sx = 0, sy = 0,
	prevSx = 0, prevSy = 0
}
function _imgui.color(...) return imgui.ColorConvertFloat4ToU32(imgui.ImVec4_Float(...)) end

return _imgui
