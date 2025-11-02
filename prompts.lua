local prompts = {
	active = false,
	random = 0,
	error = {
		message = ""
	},
	confirm = {
		message = "",
		func = function()
		end
	},
	prompt = {
		message = ""
	}
}

prompts.randomize = function()
	prompts.active = true
	prompts.random = math.random()
end
prompts.close = function()
	prompts.active = false
	prompts.error.doOpen = nil
	prompts.confirm.doOpen = nil
	prompts.prompt.doOpen = nil
	prompts.error.message = ""
	prompts.confirm.message = ""
	prompts.prompt.message = ""
	prompts.confirm.func = function() end
	prompts.prompt.buttons = nil
end

prompts.error.open = function(mod, message)
	prompts.randomize()
	prompts.error.doOpen = true
	prompts.error.message = message
	log(mod, message)
end
prompts.confirm.open = function(message, func)
	prompts.randomize()
	prompts.confirm.doOpen = true
	prompts.confirm.message = message
	prompts.confirm.func = func
end
prompts.prompt.open = function(message, buttons)
	prompts.randomize()
	prompts.prompt.doOpen = true
	prompts.prompt.message = message
	prompts.prompt.buttons = buttons
end

prompts.imgui = function()
    if prompts.active then
        if prompts.error.doOpen then
            if not imgui.IsPopupOpen("utilitoolsError") then imgui.OpenPopup_Str("utilitoolsError") end
            prompts.error.doOpen = nil
        end
        if prompts.confirm.doOpen then
            if not imgui.IsPopupOpen("utilitoolsConfirm") then imgui.OpenPopup_Str("utilitoolsConfirm") end
            prompts.confirm.doOpen = nil
        end
        if prompts.prompt.doOpen then
            if not imgui.IsPopupOpen("utilitoolsPrompt") then imgui.OpenPopup_Str("utilitoolsPrompt") end
            prompts.prompt.doOpen = nil
        end

        local open = false

        if imgui.BeginPopup("utilitoolsError") then
            open = true
            imgui.PushTextWrapPos(imgui.GetFontSize() * 35)
            local errorTexts = { "Error", "Curses!", "Dammit!", "Darn!", "Dang!", "Dangit!", "Task failed successfully.",
                ":(", "):", ":C", ":c", --[[ k4kadu: ]] "naurr!", "That can't be healthy...", --[[ something4803: ]]
                "This error sucks:", --[[ irember135: "ypu fked upo the beat blokc you" ]]
                "you fked up the beat blocked you" }
            table --[[stop wrong injection]].insert(errorTexts, 1,
                "Error Code " .. tostring(math.floor(prompts.random * (#errorTexts + 1) * 999)))

            imgui.Text(tostring(errorTexts[math.floor(prompts.random * #errorTexts) + 1]))
            imgui.Separator()
            imgui.Text(tostring(prompts.error.message))

            imgui.PopTextWrapPos()
            imgui.EndPopup("utilitoolsError")
        elseif prompts.error.message ~= "" then
            prompts.error.message = ""
        end

        if imgui.BeginPopup("utilitoolsConfirm") then
            open = true
            imgui.PushTextWrapPos(imgui.GetFontSize() * 35)
            local confirmationTexts = { "Confirm", "Accept", "Yes", "Yeah", "Ye", "Sure", "True", "Positive", "Okay",
                "Ok",
                "Do it", "Ready", "Yippee!" }

            imgui.Text("Are you sure?")
            imgui.Text(tostring(prompts.confirm.message))

            if imgui.Button(tostring(confirmationTexts[math.floor(prompts.random * #confirmationTexts) + 1]) .. "##utilitoolsComfirm") then
                local tempFunc = prompts.confirm.func
                prompts.close()
                imgui.CloseCurrentPopup()
                if tempFunc then tempFunc() end
            end

            imgui.PopTextWrapPos()
            imgui.EndPopup("utilitoolsConfirm")
        elseif prompts.confirm.message ~= "" then
            prompts.confirm.message = ""
            prompts.confirm.func = function() end
        end

        if imgui.BeginPopup("utilitoolsPrompt") then
            open = true
            imgui.PushTextWrapPos(imgui.GetFontSize() * 35)

            imgui.Text(tostring(prompts.prompt.message))

            if prompts.prompt.buttons then
                for i, v in ipairs(prompts.prompt.buttons) do
                    if i ~= 1 then imgui.SameLine() end
                    if imgui.Button(tostring(v[1])) then
                        prompts.close()
                        imgui.CloseCurrentPopup()
                        if v[2] then v[2]() end
                    end
                end
            end

            imgui.PopTextWrapPos()
            imgui.EndPopup("utilitoolsPrompt")
        elseif prompts.prompt.message ~= "" then
            prompts.prompt.message = ""
            prompts.prompt.buttons = nil
        end

        if not open then
            prompts.close()
        end
    end
end

if false then
end

return prompts
