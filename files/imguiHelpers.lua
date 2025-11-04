local imguiHelpers = {}
imguiHelpers.visibleLabel = function(label)
	return string.sub(tostring(label), 1, (string.find(tostring(label), "##") or 0) - 1)
end
imguiHelpers.tooltip = function(tooltip)
	if imgui.IsItemHovered() and tooltip ~= nil and (type(tooltip) ~= "string" or string.len(tooltip) > 0) then
		imgui.PushTextWrapPos(imgui.GetFontSize() * 7 / 13 * 65)
		imgui.SetItemTooltip(tostring(tooltip))
		imgui.PopTextWrapPos()
		return
	end
	if imgui.IsItemHovered() then print(tooltip) end
end
imguiHelpers.getWidth = function(label)
	if label == nil or string.len(imguiHelpers.visibleLabel(label)) == 0 then
		return -1 ^ -9
	else
		return -imgui.GetFontSize() * 7 / 13 * string.len(imguiHelpers.visibleLabel(label)) - 4
	end
end
imguiHelpers.setWidth = function(label)
	imgui.SetNextItemWidth(imguiHelpers.getWidth(label))
end
imguiHelpers.inputBool = function(label, current, default, tooltip)
	if current == nil then current = default end
	local v = ffi.new("bool[1]", { current })
	imgui.Checkbox(label, v)
	imguiHelpers.tooltip(tooltip)
	return v[0]
end
imguiHelpers.inputInt = function(label, current, default, tooltip, flags, step, stepFast)
	if current == nil then current = default end
	local v = ffi.new("int[1]", { current })
	imguiHelpers.setWidth(label)
	imgui.InputInt(label, v, step or 0, stepFast, flags or (2 ^ 12))
	imguiHelpers.tooltip(tooltip)
	return v[0]
end
imguiHelpers.inputFloat = function(label, current, default, tooltip, flags, step, stepFast, format)
	if current == nil then current = default end
	local v = ffi.new("float[1]", { current })
	imguiHelpers.setWidth(label)
	imgui.InputFloat(label, v, step or 0, stepFast, format, flags or (2 ^ 12))
	imguiHelpers.tooltip(tooltip)
	return v[0]
end
imguiHelpers.inputText = function(label, current, default, tooltip, flags, size)
	if current == nil then current = default end
	size = size or (2 ^ 16)
	local v = ffi.new("char[?]", size)
	ffi.copy(v, current, #current)
	imguiHelpers.setWidth(label)
	imgui.InputText(label, v, size, flags or (2 ^ 12))
	imguiHelpers.tooltip(tooltip)
	return ffi.string(v)
end
imguiHelpers.inputMultiline = function(label, current, default, tooltip, flags, size)
	if current == nil then current = default end
	size = size or (2 ^ 16)

	local lines = 1
	for _ in string.gmatch(current, "\n") do
		lines = lines + 1
	end
	local size2d = imgui.ImVec2_Float(imguiHelpers.getWidth(label), imgui.GetFontSize() * lines + 6)

	local v = ffi.new("char[?]", size)
	ffi.copy(v, current, #current)
	imgui.InputTextMultiline(label, v, size, size2d, flags)
	imguiHelpers.tooltip(tooltip)
	return ffi.string(v)
end
imguiHelpers.inputCombo = function(label, current, default, tooltip, flags, values, tooltips)
	if current == nil then current = default end
	if flags then imguiHelpers.setWidth(label) end
	local open = imgui.BeginCombo(label, current, flags or (2 ^ 4 + 2 ^ 5 + 2 ^ 7))
	imguiHelpers.tooltip(tooltip)
	local rv = current
	if open then
		for i, v in ipairs(values) do
			local selected = imgui.Selectable_Bool(v, v == current)
			if tooltips then imguiHelpers.tooltip(tooltips[i]) end
			if selected then
				rv = v
			end
		end
		imgui.EndCombo()
	end
	return rv
end
imguiHelpers.inputEase = function(label, current, default, tooltip, flags)
	if current == nil then current = default end
	if flags then imguiHelpers.setWidth(label) end

	local values = utilitools.eases
	local tooltips

	local open = imgui.BeginCombo(label, current, flags or (2 ^ 4 + 2 ^ 5 + 2 ^ 7))
	imguiHelpers.tooltip(tooltip)
	local rv = current
	if open then
		for i, v in ipairs(values) do
			local selected = imgui.Selectable_Bool(v, v == current)
			if tooltips then imguiHelpers.tooltip(tooltips[i]) end
			if selected then
				rv = v
			end
		end
		imgui.EndCombo()
	end
	return rv
end
imguiHelpers.inputColor = function(label, current, default, tooltip, flags)
	if current == nil then current = default end
	local v = ffi.new("float[" .. (current.a and 4 or 3) .. "]",
		current.a and {
			current.r, current.g, current.b, current.a,
		} or {
			current.r, current.g, current.b,
		})
	imgui["ColorEdit" .. (current.a and 4 or 3)](label, v, flags or (2 ^ 5))
	imguiHelpers.tooltip(tooltip)
	return { r = v[0], g = v[1], b = v[2], a = current.a and v[3] or nil }
end
imguiHelpers.inputList = function(label, current, default, tooltip, flags, temp, size)
	if current == nil then current = default end
	local formatted = table.concat(current, ", ")
	size = size or (2 ^ 16)
	local v = ffi.new("char[?]", size)
	ffi.copy(v, formatted, #formatted)
	imguiHelpers.setWidth(label)
	imgui.InputText(label, v, size, flags or (2 ^ 12))
	imguiHelpers.tooltip(tooltip)
	local val = ffi.string(v)
	local rv = { current, temp }
	if formatted ~= val and val ~= temp then
		rv[1] = {}
		rv[2] = val
		for n in string.gmatch(val, "(%d+)") do
			local s = tonumber(n)
			if s ~= nil and s ~= 0 then
				table.insert(rv[1], s)
			end
		end
	end
	return rv[1], rv[2]
end
imguiHelpers.inputKey = function(label, category, key, tooltip)
	for _, v in ipairs(utilitools.keybinds.getKeys(category)[key]) do
		if imgui.Button(string.sub(v, #"key:" + 1)) then
			utilitools.keybinds.forceRemoveKeyValue(category, key, v)
		end
		imguiHelpers.tooltip(tooltip)
		imgui.SameLine()
	end
	if imgui.Button("Add") then
		utilitools.prompts.keyRaw(category, key)
	end
	imguiHelpers.tooltip(tooltip)
	imgui.SameLine()
	imgui.Text(imguiHelpers.visibleLabel(label))
	imguiHelpers.tooltip(tooltip)
end
imguiHelpers.condTreeNode = function(label, name, current, target, same, func, flags)
	local condition = (current == target) == same
	if not condition then
		imgui.BeginDisabled()
		imgui.SetNextItemOpen(false, 2 ^ 0)
	elseif utilitools.config.foldAll then
		imgui.SetNextItemOpen(not not (flags and flags % 2 ^ (5 + 1) >= 2 ^ 5), 2 ^ 0)
	end
	if flags then
		if imgui.TreeNodeEx_Str(label, flags) then
			func()
			imgui.TreePop()
		end
	else
		if imgui.TreeNode_Str(label) then
			func()
			imgui.TreePop()
		end
	end
	if not condition then
		imgui.EndDisabled()
		if imgui.IsItemHovered(2 ^ 10) then
			imgui.PushTextWrapPos(imgui.GetFontSize() * 7 / 13 * 65)
			imgui.SetTooltip(name .. " needs to " .. (same and "" or "not ") .. "be " .. tostring(target))
			imgui.PopTextWrapPos()
		end
	end
end
imguiHelpers.treeNode = function(label, func, flags)
	if utilitools.config.foldAll then imgui.SetNextItemOpen(not not (flags and flags % 2 ^ (5 + 1) >= 2 ^ 5), 2 ^ 0) end
	if flags then
		if imgui.TreeNodeEx_Str(label, flags) then
			func()
			imgui.TreePop()
		end
	else
		if imgui.TreeNode_Str(label) then
			func()
			imgui.TreePop()
		end
	end
end
return imguiHelpers
