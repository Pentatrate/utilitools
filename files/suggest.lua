local suggest = {
	list = {},
	index = 1,
	last = "",
	radius = 64,
	lineThickness = 2,
	dials = { }
}

suggest.suggest = function(current, list)
	if imgui.IsItemActive() then
		if imgui.IsItemEdited() or imgui.IsItemActivated() then
			suggest.index = 1
			suggest.list = {}
			if #current > 0 then
				for _, v in ipairs(list) do
					local find = v:lower():find(current:lower(), nil, true)
					if find then
						table.insert(suggest.list, { v, find == 1 })
					end
				end
			end
			table.sort(suggest.list, function(a, b)
				if a[2] ~= b[2] then return a[2] end
				return a[1] < b[1]
			end)
		end
		if #suggest.list > 0 then
			if imgui.BeginTooltip() then
				imgui.SeparatorText("Suggestions")
				for i, v in ipairs(suggest.list) do
					imgui.Selectable_Bool(v[1], i == suggest.index)
				end
				imgui.EndTooltip()
			end
		end
		if imgui.IsKeyPressed(imgui.ImGuiKey_UpArrow, false) or imgui.IsKeyPressed(imgui.ImGuiKey_Keypad8, false) then -- up
			suggest.index = suggest.index - 1
			if suggest.index < 1 then
				suggest.index = suggest.index + #suggest.list
			end
		end
		if imgui.IsKeyPressed(imgui.ImGuiKey_DownArrow, false) or imgui.IsKeyPressed(imgui.ImGuiKey_Keypad2, false) then -- down
			suggest.index = (suggest.index % #suggest.list) + 1
		end
		if imgui.IsKeyPressed(imgui.ImGuiKey_Tab, false) and #suggest.list > 0 then -- tab
			suggest.last = suggest.list[suggest.index][1]
			return suggest.list[suggest.index][1]
		end
	elseif imgui.IsItemDeactivated() and suggest.last ~= "" then
		local temp = suggest.last
		suggest.last = ""
		return temp
	end
	return current
end

suggest.dial = function(current, id, snap)
	if imgui.Button("Dial##utilitoolsDial_" .. id) then
		local drawList
		local windowPos
		local rotations = 0
		local prevangle
		local function coords(x, y)
			return imgui.ImVec2_Float(windowPos.x + suggest.radius + x, windowPos.y + suggest.radius + y)
		end
		utilitools.prompts.custom({
			func = function()
				drawList = drawList or imgui.GetWindowDrawList()
				windowPos = imgui.GetCursorScreenPos()

				local hovered = math.sqrt((windowPos.x + suggest.radius - imgui.GetMousePos().x) ^ 2 + (windowPos.y + suggest.radius - imgui.GetMousePos().y) ^ 2) <= suggest.radius
				local pressed = false

				local angle = -math.atan2(windowPos.x + suggest.radius - imgui.GetMousePos().x, windowPos.y + suggest.radius - imgui.GetMousePos().y) % (math.pi * 2)
				angle = angle - (angle + math.pi / snap) % (math.pi * 2 / snap) + math.pi / snap
				local drawangle = angle - math.pi / 2
				if prevangle and math.abs(angle - prevangle) > math.pi then rotations = rotations + (angle > prevangle and -1 or 1) end
				prevangle = angle
				angle = helpers.round(((angle) / math.pi * 180 + 360 * rotations) * 1e3) / 1e3
				if angle == 0 then angle = math.abs(angle) end

				imgui.Dummy(imgui.ImVec2_Float(suggest.radius * 2, suggest.radius * 2))
				if hovered then
					utilitools.imguiHelpers.tooltip("Click or press enter to save")
					pressed = imgui.IsItemClicked(imgui.ImGuiMouseButton_Left)
				end
				drawList:AddCircleFilled(
					coords(0, 0),
					suggest.radius,
					hovered and imgui.GetColorU32_Col(imgui.ImGuiCol_ButtonHovered) or imgui.GetColorU32_Col(imgui.ImGuiCol_Button)
				);
				for i = 0, snap - 1 do
					drawList:AddLine(coords(math.cos(math.pi * 2 / snap * i - math.pi / 2) * suggest.radius * 0.75, math.sin(math.pi * 2 / snap * i - math.pi / 2) * suggest.radius * 0.75), coords(math.cos(math.pi * 2 / snap * i - math.pi / 2) * suggest.radius, math.sin(math.pi * 2 / snap * i - math.pi / 2) * suggest.radius), imgui.GetColorU32_Col(imgui.ImGuiCol_Separator), suggest.lineThickness)
				end
				local overRotations = math.min(math.abs(rotations + 0.5) - 0.5, math.floor(suggest.radius / 4 / suggest.lineThickness))
				if overRotations > 0 then
					drawList:AddCircle(
						coords(0, 0),
						suggest.radius - overRotations * suggest.lineThickness / 2,
						imgui.GetColorU32_Col(imgui.ImGuiCol_Separator),
						nil, suggest.lineThickness * overRotations
					);
				end
				if overRotations ~= math.floor(suggest.radius / 4 / suggest.lineThickness) then
					drawList:PathClear()
					if rotations >= 0 then
						drawList:PathArcTo(coords(0, 0), suggest.radius - suggest.lineThickness / 2 - overRotations * suggest.lineThickness, -math.pi / 2, drawangle)
					else
						drawList:PathArcTo(coords(0, 0), suggest.radius - suggest.lineThickness / 2 - overRotations * suggest.lineThickness, drawangle, math.pi * 1.5)
					end
					drawList:PathStroke(imgui.GetColorU32_Col(imgui.ImGuiCol_Text), nil, suggest.lineThickness)
				end
				drawList:AddLine(
					coords(math.cos(drawangle) * suggest.radius / 2, math.sin(drawangle) * suggest.radius / 2),
					coords(math.cos(drawangle) * (suggest.radius - suggest.lineThickness / 2 - overRotations * suggest.lineThickness), math.sin(drawangle) * (suggest.radius - suggest.lineThickness / 2 - overRotations * suggest.lineThickness)),
					imgui.GetColorU32_Col(imgui.ImGuiCol_Text), 2
				)
				imgui.SetCursorPos(imgui.ImVec2_Float(suggest.radius + 7 - #tostring(angle) * 3.5, suggest.radius))
				imgui.Text(tostring(angle))

				if pressed or imgui.IsKeyPressed(imgui.ImGuiKey_Enter, false) then
					suggest.dials[id] = angle
					imgui.CloseCurrentPopup()
				end
			end
		})
	end
	if suggest.dials[id] then
		current = suggest.dials[id]
		suggest.dials[id] = nil
	end
	return current
end

return suggest
