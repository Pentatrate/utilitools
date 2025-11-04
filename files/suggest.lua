local suggest = {
	list = {},
    index = 1,
	last = ""
}

suggest.run = function(current, list)
    if imgui.IsItemActive() then
        if imgui.IsItemEdited() or imgui.IsItemActivated() then
            suggest.index = 1
            suggest.list = {}
            if #current > 0 then
                for _, v in ipairs(list) do
                    local find = string.find(string.lower(v), string.lower(current), nil, true)
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
        if imgui.IsKeyPressed(515, false) or imgui.IsKeyPressed(620, false) then -- up
            suggest.index = suggest.index - 1
            if suggest.index < 1 then
                suggest.index = suggest.index + #suggest.list
            end
        end
        if imgui.IsKeyPressed(516, false) or imgui.IsKeyPressed(614, false) then -- down
            suggest.index = (suggest.index % #suggest.list) + 1
        end
        if imgui.IsKeyPressed(512, false) then -- tab
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

return suggest
