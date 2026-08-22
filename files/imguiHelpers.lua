local imguiHelpers = {
	wrappedFocus = nil,
	wrappedBool = false
}
imguiHelpers.visibleLabel = function(label)
	return tostring(label):sub(1, (tostring(label):find("##", nil, true) or 0) - 1)
end
imguiHelpers.tooltip = function(tooltip)
	if imgui.IsItemHovered() and tooltip ~= nil and (type(tooltip) ~= "string" or imguiHelpers.stringLength(tooltip) > 0) then
		local x, y, offset
		if mods["imgui-scale-fix"] and mods["imgui-scale-fix"].enabled then
			x = imgui.GetIO().MousePos.x
			y = imgui.GetIO().MousePos.y
		else
			x = mouse.rx * imgui.canvasScale
			y = mouse.ry * imgui.canvasScale
		end

		offset = 0
		if mouse.rx > 400 then
			offset = 1
		end
		imgui.SetNextWindowPos(imgui.ImVec2_Float(x, y), imgui.ImGuiCond_Appearing, imgui.ImVec2_Float(offset, 0.5))

		imgui.BeginTooltip()

		imgui.PushTextWrapPos(imgui.GetFontSize() * 7 / 13 * 65)
		imgui.TextUnformatted(tostring(tooltip))
		imgui.PopTextWrapPos()

		imgui.EndTooltip()
	end
end
imguiHelpers.stringLength = function(label)
	local length = 0
	for s in label:gmatch("[^\n]+") do
		length = math.max(length, #s)
	end
	return length
end
imguiHelpers.getWidth = function(label)
	if label == nil or imguiHelpers.stringLength(imguiHelpers.visibleLabel(label)) == 0 then
		return -1 ^ -9
	else
		return -imgui.GetFontSize() * 7 / 13 * imguiHelpers.stringLength(imguiHelpers.visibleLabel(label)) - imgui.GetStyle().ItemInnerSpacing.x
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
imguiHelpers.inputText = function(label, current, default, tooltip, flags, size, overrideWidth)
	if current == nil then current = default end
	size = size or (2 ^ 10)
	local v = ffi.new("char[?]", size)
	ffi.copy(v, current, #current)
	if overrideWidth then
		imgui.SetNextItemWidth(overrideWidth)
	else
		imguiHelpers.setWidth(label)
	end
	imgui.InputText(label, v, size, flags or (2 ^ 12))
	imguiHelpers.tooltip(tooltip)
	return ffi.string(v)
end
imguiHelpers.inputMultiline = function(label, current, default, tooltip, flags, size, overrideWidth)
	if current == nil then current = default end
	size = size or (2 ^ 10)

	local lines = 1
	for _ in current:gmatch("\n") do
		lines = lines + 1
	end
	local size2d = imgui.ImVec2_Float(overrideWidth or imguiHelpers.getWidth(label), imgui.GetFontSize() * lines + imgui.GetStyle().FramePadding.y * 2)

	local v = ffi.new("char[?]", size)
	ffi.copy(v, current, #current)
	imgui.InputTextMultiline(label, v, size, size2d, flags)
	imguiHelpers.tooltip(tooltip)
	return ffi.string(v)
end
imguiHelpers.inputWrapped = function(label, current, default, tooltip, flags, size, overrideWidth) -- unfinished
	if current == nil then current = default end
	size = size or (2 ^ 10)
	if imguiHelpers.wrappedBool then
		label = tostring(label) .. "##"
	end
	overrideWidth = overrideWidth or imguiHelpers.getWidth(label)

	local space = overrideWidth < 0 and imgui.GetContentRegionAvail().x + overrideWidth - imgui.GetStyle().ItemInnerSpacing.x or overrideWidth
	local maxAmount = math.max(1, math.floor(space / (imgui.GetFontSize() * 7 / 13)))

	--[[ local temp = ""

	if #current > maxAmount then
		local amount = math.ceil((#current) / maxAmount) - 1
		for j = 1, amount do
			current = current:sub(1, maxAmount * j + j - 1) .. "\n" .. current:sub(1 + maxAmount * j + j - 1)
		end
	end ]]

	local textSize = imgui.ImVec2_Float(0, 0)
	utilitools.try(mod, function()
		textSize = imgui.CalcTextSize(current, current, false, space)
	end)

	local lines = 1
	for _ in current:gmatch("\n") do
		lines = lines + 1
	end
	local size2d = imgui.ImVec2_Float(overrideWidth, imgui.GetFontSize() * lines + imgui.GetStyle().FramePadding.y * 2)

	if imguiHelpers.wrappedFocus ~= nil then
		imgui.SetKeyboardFocusHere()
	end

	local v = ffi.new("char[?]", size)
	ffi.copy(v, current, #current)
	imgui.PushTextWrapPos(imgui.GetFontSize() * 7 / 13 * 10)
	imgui.InputTextMultiline(label, v, size, size2d, flags or imgui.ImGuiInputTextFlags_EnterReturnsTrue)
	imgui.PopTextWrapPos()
	imguiHelpers.tooltip(tooltip .. "\n" .. utilitools.string.concat(imguiHelpers.stringLength(current), textSize.x, textSize.y))

	if imguiHelpers.wrappedBool then
		imguiHelpers.wrappedBool = false
	end
	if imgui.IsItemEdited() and not imgui.IsItemDeactivated() then
		imguiHelpers.wrappedBool = true
		imguiHelpers.wrappedFocus = true
	else
		if imguiHelpers.wrappedFocus then
			imguiHelpers.wrappedFocus = false
		else
			imguiHelpers.wrappedFocus = nil
		end
	end

	utilitools.try(mod, function()
		imguiHelpers.inputTextWrapped(label, current, size, size2d, flags, tooltip)
	end)

	return ffi.string(v):gsub("\n", "")
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
	size = size or (2 ^ 10)
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
		for n in val:gmatch("(%d+)") do
			local s = tonumber(n)
			if s ~= nil and s ~= 0 then
				table.insert(rv[1], s)
			end
		end
	end
	return rv[1], rv[2]
end
imguiHelpers.inputKey = function(label, category, keyId, tooltip, modded)
	if category == "controltable" then return end

	local first2 = true
	local function sameLine(text, padding)
		if not first2 then
			imgui.SameLine()
			local space = imgui.GetContentRegionAvail().x
			space = space - (imgui.GetFontSize() * 7 / 13 * imguiHelpers.stringLength(imguiHelpers.visibleLabel(text)) + (padding and imgui.GetStyle().FramePadding.x * 2 or 0))
			if space < 0 then imgui.NewLine() end
		end
		first2 = false
	end
	for i, v in ipairs(utilitools.keybinds.getKeybinds(category, keyId, modded)) do
		local keyLabel = ""
		if modded then
			local first = true
			for k, _ in pairs(v[1]) do
				keyLabel = keyLabel .. (first and "" or " + ") .. utilitools.keybinds.text.keyLabel(k)
				first = false
			end
			keyLabel = keyLabel .. (first and "" or " + ") .. utilitools.keybinds.text.keyLabel(v[2])
		else
			keyLabel = keyLabel .. utilitools.keybinds.text.keyLabel(v)
		end
		sameLine(keyLabel .. "##" .. label, true)
		if imgui.Button(keyLabel .. "##" .. label) then
			if modded then
				utilitools.keybinds.mod.removeKeybind(category, keyId, v)
			else
				utilitools.keybinds.raw.removeKeybind(category, keyId, v)
			end
		end
		imguiHelpers.tooltip(tooltip)
	end
	sameLine("Add##" .. label, true)
	if imgui.Button("Add##" .. label) then
		utilitools.prompts.key(category, keyId, modded)
	end
	sameLine("Reset##" .. label, true)
	if modded and imgui.Button("Reset##" .. label) then
		modlog(category, utilitools.files[category.id].configOptions[keyId].default)
		utilitools.keybinds.register.newKey(category, keyId, utilitools.files[category.id].configOptions[keyId].default, true)
		utilitools.keybinds.register.finish()
	end
	imguiHelpers.tooltip(tooltip)
	sameLine(label, true)
	imgui.Text(imguiHelpers.visibleLabel(label))
	imguiHelpers.tooltip(tooltip)
end
imguiHelpers.inputBranch = function(mod)
	if utilitools.modLinks[mod.id] == nil then return end

	local data = { utilitools.modUpdater2.getData(mod) } if not data[1] then return end
	local _, branch, fork
	_, _, _, branch, fork = unpack(data)

	local branchPrefix = "Latest commit to "
	local totalItems = {}
	local current
	local function add(data2, fork2)
		local branches = data2.branch
		local default = data2.default
		local itemsSorted = {}
		for branch2, _ in pairs(branches) do
			local isDefault = branch2 == default
			table.insert(itemsSorted, {
				branch = branch2, fork = fork2,
				label = "Latest commit to " .. (fork2 and fork2 .. "'s " or "") .. branch2,
				default = isDefault,
				tooltip = "Use the latest commit on the " .. branch2 .. " branch" .. (fork2 and " of " .. fork2 .. "'s fork" or "") .. (isDefault and "\nThis is the default branch of this " .. (fork2 and "fork" or "repository") or "")
			})
		end
		table.sort(itemsSorted, function(a, b)
			if a.branch == default or b.branch == default and a.branch ~= b.branch then
				return a.branch == default
			end
			return a.branch < b.branch
		end)
		for _, item in ipairs(itemsSorted) do
			if item.branch == branch and item.fork == fork then current = item end
			table.insert(totalItems, item)
		end
	end

	if fork then add(utilitools.modLinks[mod.id].fork[fork], fork) end
	add(utilitools.modLinks[mod.id], nil)
	if utilitools.modLinks[mod.id].fork then
		local forksSorted = utilitools.table.keysToValues(utilitools.modLinks[mod.id].fork)
		table.sort(forksSorted)
		for _, fork2 in ipairs(forksSorted) do
			if fork2 ~= fork then
				add(utilitools.modLinks[mod.id].fork[fork2], fork2)
			end
		end
	end

	if #totalItems > 1 then
		local label = "Branch##" .. mod.id .. "Config_branch"
		local tooltip = "Different ways to get different versions of a mod"
		local flags = utilitools.files.utilitools.configOptions.branches.flags -- currently nil, might change later on, maybe, or never at all

		if flags then imguiHelpers.setWidth(label) end
		local open = imgui.BeginCombo(label, current.label, flags or (2 ^ 4 + 2 ^ 5 + 2 ^ 7))
		imguiHelpers.tooltip(tooltip)
		if open then
			for _, item in ipairs(totalItems) do
				local selected = imgui.Selectable_Bool(item.label, item == current)
				imguiHelpers.tooltip(item.tooltip)
				if selected then
					current = item
				end
			end
			imgui.EndCombo()
		end
	end

	if current.fork ~= fork or current.branch ~= branch then
		mods.utilitools.config.branches[mod.id] = current.branch
		mods.utilitools.config.forks[mod.id] = current.fork
		modlog(mods.utilitools, "set branch", current.branch, "fork", current.fork, "\n", mods.utilitools.config.branches)
	end
end
imguiHelpers.inputSliderInt = function(label, current, default, tooltip, flags, min, max, innerLabel, colored)
	if current == nil then current = default end
	local v = ffi.new("int[1]", { current })
	imguiHelpers.setWidth(label)
	if colored and 0 <= current and current <= 7 then
		local sliderColors = {
			[0] = imgui.ImVec4_Float(1.0, 1.0, 1.0, 1.0),
			[1] = imgui.ImVec4_Float(0.0, 0.0, 0.0, 1.0),
			[2] = imgui.ImVec4_Float(1.0, 0.0, 0.0, 1.0),
			[3] = imgui.ImVec4_Float(0.0, 0.0, 1.0, 1.0),
			[4] = imgui.ImVec4_Float(0.0, 1.0, 0.0, 1.0),
			[5] = imgui.ImVec4_Float(1.0, 1.0, 0.0, 1.0),
			[6] = imgui.ImVec4_Float(1.0, 0.0, 1.0, 1.0),
			[7] = imgui.ImVec4_Float(0.0, 1.0, 1.0, 1.0)
		}
		imgui.PushStyleColor_Vec4(imgui.ImGuiCol_SliderGrab, sliderColors[current])
		imgui.PushStyleColor_Vec4(imgui.ImGuiCol_SliderGrabActive, sliderColors[current])
	end
	imgui.SliderInt(label, v, min, max, innerLabel, flags)
	if colored and 0 <= current and current <= 7 then
		imgui.PopStyleColor(2)
	end
	imguiHelpers.tooltip(tooltip)
	return v[0]
end
imguiHelpers.inputSliderFloat = function(label, current, default, tooltip, flags, min, max, innerLabel)
	if current == nil then current = default end
	local v = ffi.new("float[1]", { current })
	imguiHelpers.setWidth(label)
	imgui.SliderFloat(label, v, min, max, innerLabel, flags)
	imguiHelpers.tooltip(tooltip)
	return v[0]
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

function imguiHelpers.inputTextWrapped(label, current, size, size2d, flags, tooltip) -- unfinished
	local drawList = imgui.GetWindowDrawList()
	local avail = imgui.GetContentRegionAvail()
	local v = ffi.new("char[?]", size)
	ffi.copy(v, current, #current)

	local windowPos = imgui.GetCursorScreenPos()
	local endPos = imgui.ImVec2_Float(windowPos.x + size2d.x + (size2d.x < 0 and avail.x or 0), windowPos.y + size2d.y + (size2d.y < 0 and avail.y or 0))
	local color = imgui.ImGuiCol_FrameBg
	local padding = imgui.GetStyle().FramePadding

	imgui.InvisibleButton(label .. "##", size2d)
	imguiHelpers.tooltip(tooltip)

	if imgui.IsItemHovered() then
		color = imgui.ImGuiCol_FrameBgHovered
		imgui.SetMouseCursor(imgui.ImGuiMouseCursor_TextInput)
	end
	if imgui.IsItemActive() then
		color = imgui.ImGuiCol_FrameBgActive
	end

	drawList:AddRectFilled(windowPos, endPos, imgui.GetColorU32_Col(color), imgui.GetStyle().FrameRounding)
	drawList:AddText_Vec2(imgui.ImVec2_Float(windowPos.x + padding.x, windowPos.y + padding.y), imgui.GetColorU32_Col(imgui.ImGuiCol_Text), v, nil)

	function drawCursor(offset)
		local xPos = windowPos.x + padding.x + offset * imgui.GetFontSize() * 7 / 13
		local yPosMin = windowPos.y + padding.y + 1
		drawList:AddLine(imgui.ImVec2_Float(xPos, yPosMin), imgui.ImVec2_Float(xPos, yPosMin + imgui.GetFontSize() - 2), imgui.GetColorU32_Col(imgui.ImGuiCol_Text), 1)
	end

	imgui.SameLine()
	imgui.AlignTextToFramePadding()
	imgui.Text(imguiHelpers.visibleLabel(label))
	imguiHelpers.tooltip(tooltip)
end
return imguiHelpers
