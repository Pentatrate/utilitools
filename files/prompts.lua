local prompts = {
	active = false,
	doOpen = false,
	random = 0,
	func = nil,
	title = "",
	message = "",
	isError = false,
	confirmFunc = nil,
	buttonsTable = nil,
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
		utilitools.keybinds.listening.stop()
	end

	prompts.active = false
    prompts.doOpen = false
	prompts.random = 0
	prompts.func = nil
	prompts.title = ""
	prompts.message = ""
	prompts.isError = false
	prompts.confirmFunc = nil
	prompts.buttonsTable = nil
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
	prompts.confirmFunc = func
end
prompts.buttons = function(message, buttons)
	prompts.randomize()
	prompts.message = message
	prompts.buttonsTable = buttons
end
prompts.key = function(category, keyId, modded)
	prompts.randomize()
	prompts.func = function()
		local pressed = false
		if modded then for k, _ in pairs(utilitools.keybinds.listening.keysPressed) do pressed = true break end end
		if pressed then
			local temp = ""
			local first = true
			for k, _ in pairs(utilitools.keybinds.listening.keysPressed) do
				temp = temp .. (first and "" or " + ") .. k:sub(#"key:" + 1)
				first = false
			end
			imgui.Text(temp)
		else
			imgui.Text("Listening for key...")
		end
	end
    prompts.listening = {
		category = category, keyId = keyId, modded = modded
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
                    --[[ k4kadu: "I present this crashlog to thee, for thou hast met an unfortunate end to thine Beatblock session." ]] "naurr!", "That can't be healthy...", "I present this message to thee, for thou hast met an unfortunate end to thine fun.", "Now go forth and give Penatwate the necessary ingredients to perpend his next Beattools update.", "Be not too expedient to inherit the belief in this testy way of play. Despite **this message being sponsored by Beattools**, thou must still predict a sudden retirement of thine young charting progress.",
                    --[[ something4803: ]] "This error sucks:",
                    --[[ irember135: "ypu fked upo the beat blokc you" ]] "You fked up the beat blocked you",
					--[[ thatguytheman: ]] "Seriously?", "Damn it", "3:", "@penatwate Mod broke", "@penatwate Where were you when beatblock die",
                }
                table.insert(
                    errorTexts, 1, "Error Code " .. tostring(math.floor(prompts.random * (#errorTexts + 1) * 999))
                )
                prompts.title = tostring(errorTexts[math.floor(prompts.random * #errorTexts) + 1])
                prompts.isError = false
            end
			if prompts.listening then
				utilitools.keybinds.listening.listen(prompts.listening.category, prompts.listening.keyId, prompts.listening.modded)
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

			if prompts.confirmFunc then
				local confirmationTexts = { "Confirm", "Accept", "Yes", "Yeah", "Ye", "Sure", "True", "Positive", "Okay",
					"Ok",
					"Do it", "Ready", "Yippee!" }

				if imgui.Button(tostring(confirmationTexts[math.floor(prompts.random * #confirmationTexts) + 1]) .. "##utilitoolsComfirm") then
					local temp = prompts.confirmFunc
					prompts.close()
					imgui.CloseCurrentPopup()
					if temp then temp() end
				end
			end

            if prompts.buttonsTable then
                for i, v in ipairs(prompts.buttonsTable) do
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

return prompts
