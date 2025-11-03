local prompts = {
	active = false,
	doOpen = false,
	random = 0,
	func = nil,
	title = "",
	message = "",
	isError = false,
	confirm = nil,
	buttons = nil,
	listening = false
}

prompts.randomize = function()
	prompts.close()
	prompts.active = true
	prompts.doOpen = true
	prompts.random = math.random()
end
prompts.close = function()
	if prompts.listening then
		utilitools.keybinds.stopListening()
	end

	prompts.active = false
    prompts.doOpen = false
	prompts.random = 0
	prompts.func = nil
	prompts.title = ""
	prompts.message = ""
	prompts.isError = false
	prompts.confirm = nil
	prompts.buttons = nil
	prompts.listening = nil
end

prompts.error = function(mod, message)
	prompts.randomize()
    prompts.isError = true
	prompts.message = message

	log(mod, message)
end
prompts.confirm = function(message, func)
	prompts.randomize()
    prompts.title = "Are you sure?"
	prompts.message = message
	prompts.confirm = func
end
prompts.buttons = function(message, buttons)
	prompts.randomize()
	prompts.message = message
	prompts.buttons = buttons
end
prompts.key = function(mod, key)
	prompts.randomize()
	prompts.message = "Listening for key..."
    prompts.listening = {
		category = utilitools.keybinds.getModCategory(mod), key = utilitools.keybinds.keyName(mod, key)
	}
end
prompts.keyRaw = function(category, key)
	prompts.randomize()
	prompts.message = "Listening for key..."
    prompts.listening = {
		category = category, key = key
	}
end
prompts.custom = function(t)
	prompts.randomize()
	for k, v in pairs(t) do
		prompts[k] = v
	end
end

prompts.imgui = function()
	if prompts.active then
		if prompts.doOpen then
			if not imgui.IsPopupOpen("utilitoolsPrompt") then imgui.OpenPopup_Str("utilitoolsPrompt") end
            if prompts.isError then
                local errorTexts = {
                    "Error", "Curses!", "Dammit!", "Darn!", "Dang!", "Dangit!", "Task failed successfully.",
                    ":(", "):", ":C", ":c",
                    --[[ k4kadu: ]] "naurr!", "That can't be healthy...",
                    --[[ something4803: ]] "This error sucks:",
                    --[[ irember135: "ypu fked upo the beat blokc you" ]] "you fked up the beat blocked you",
                }
                table.insert(
                    errorTexts, 1, "Error Code " .. tostring(math.floor(prompts.random * (#errorTexts + 1) * 999))
                )
                prompts.title = tostring(errorTexts[math.floor(prompts.random * #errorTexts) + 1])
                prompts.isError = false
            end
			if prompts.listening then
				utilitools.keybinds.forceListen(prompts.listening.category, prompts.listening.key)
			end
			prompts.doOpen = false
		end
        if imgui.BeginPopup("utilitoolsPrompt") then
            imgui.PushTextWrapPos(imgui.GetFontSize() * 35)

            if prompts.title ~= "" then
                imgui.Text(tostring(prompts.title))
                imgui.Separator()
            end

            if prompts.message ~= "" then
                imgui.Text(tostring(prompts.message))
            end

			if prompts.func then
				prompts.func()
			end

			if prompts.confirm then
				local confirmationTexts = { "Confirm", "Accept", "Yes", "Yeah", "Ye", "Sure", "True", "Positive", "Okay",
					"Ok",
					"Do it", "Ready", "Yippee!" }

				if imgui.Button(tostring(confirmationTexts[math.floor(prompts.random * #confirmationTexts) + 1]) .. "##utilitoolsComfirm") then
					local temp = prompts.confirm
					prompts.close()
					imgui.CloseCurrentPopup()
					if temp then temp() end
				end
			end

            if prompts.buttons then
                for i, v in ipairs(prompts.buttons) do
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
		else
			prompts.close()
		end
	end
end

if false then
end

return prompts
