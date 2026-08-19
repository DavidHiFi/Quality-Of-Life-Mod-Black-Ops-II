-- ============================================================================
--  zm_qol v1.99.87 - RESTART GAME's popup. Queue item 27.
--
--  🌟 THIS IS STOCK'S OWN POPUP, NOT A NEW ONE. The file is Treyarch's
--  ui_mp\t6\zombie\restartgamepopupzombie.lua out of patch_zm.ff, decompiled,
--  with exactly TWO lines changed - both marked below. Everything else,
--  including the demo-upload path, is theirs untouched.
--
--  🛑 WHY IT HAD TO BE OVERRIDDEN AT ALL. Stock gates the actual restart on the
--  session being SYSTEMLINK or OFFLINE:
--        if SessionModeIsMode(SYSTEMLINK) or SessionModeIsMode(OFFLINE) then
--            Engine.Exec( controller, "fast_restart" )
--        else
--            Engine.SendMenuResponse( controller, "restartgamepopup", "restart_level_zm" )
--  and YesButtonPressed only calls RestartLevel inside that same test. Under
--  Plutonium every game reports as an online private match - neither mode is
--  ever true ([[t6-plutonium-session-mode-solo]]) - so pressing YES would have
--  skipped the restart entirely and dropped the player on the "uploading movie"
--  spinner that the rest of YesButtonPressed builds. That is the half-working
--  row this mod does not ship, so the branch is forced instead.
--
--  🌟 THE RESTART COMMAND IS TREYARCH'S, NOT A GUESS. `fast_restart` is what
--  stock's own RESTART GAME runs, and the string is present in t6zm.exe. This
--  changes WHICH BRANCH runs, never what the restart does.
--
--  🛑 Residual risk, stated honestly: whether Plutonium honours `fast_restart`
--  in a zombies match has not been verified in game. If it does not, YES closes
--  the popup and nothing happens - it cannot crash or corrupt a match, because
--  every other line here is stock's.
-- ============================================================================
require("T6.HUD.InGameMenus")
CoD.RestartGamePopup = {}
CoD.RestartGamePopup.AddButton = function (f1_arg0, f1_arg1, f1_arg2, f1_arg3)
	local f1_local0 = f1_arg0.buttonList:addButton(f1_arg1)
	f1_local0:setActionEventName(f1_arg2)
	if f1_arg3 == true then
		f1_local0:disable()
	end
	return f1_local0
end

CoD.RestartGamePopup.Close = function (f2_arg0, f2_arg1)
	Engine.BlurWorld(f2_arg0:getOwner(), 0)
	Engine.LockInput(f2_arg0:getOwner(), false)
	Engine.SetUIActive(f2_arg0:getOwner(), false)
	f2_arg0:processEvent({
		name = "close_all_ingame_menus",
		controller = f2_arg0.controller
	})
end

CoD.RestartGamePopup.CancelUpload = function (f3_arg0, f3_arg1)
	f3_arg1.controller = f3_arg0.controller
	CoD.EndGamePopup.YesButtonPressed(f3_arg0, f3_arg1)
end

CoD.RestartGamePopup.WaitForDemostream = function (f4_arg0, f4_arg1)
	f4_arg0.streamTimeOut = f4_arg0.streamTimeOut + 2000
	if Engine.IsDemoStreamingFinished() and f4_arg0.streamTimeOut < 60000 then
		if f4_arg0.streamTimeOut >= 5000 and f4_arg0.promptLobby == nil then
			f4_arg0.promptLobby = false
			f4_arg0.subTitle:setText(Engine.Localize("ZMUI_CANCEL_WARNING"))
			f4_arg0.subTitle:animateToState("fade_in", 1000)
			f4_arg0:addSelectButton()
			f4_arg0.spinner:animateToState("down", 200)
			f4_arg0.buttonList:setTopBottom(false, true, -CoD.ButtonPrompt.Height - CoD.CoD9Button.Height * 2 + 10, 0)
			local f4_local0 = CoD.RestartGamePopup.AddButton(f4_arg0, Engine.Localize("MENU_OK"), "cancelUpload")
			f4_local0:processEvent({
				name = "gain_focus"
			})
		end
		return 
	else
		f4_arg0.demoStreamTimer:close()
		CoD.RestartGamePopup.RestartLevel(f4_arg0, f4_arg1)
	end
end

CoD.RestartGamePopup.RestartLevel = function (f5_arg0, f5_arg1)
	CoD.RestartGamePopup.Close(f5_arg0, f5_arg1)
	Engine.SetDvar("cl_paused", 0)
	Dvar.ui_busyBlockIngameMenu:set(1)
	Engine.Exec(f5_arg0.controller, "stopControllerRumble")
	Engine.Exec(f5_arg0.controller, "fade 0 0 0 255 0 0 1")
	Engine.Exec(f5_arg0.controller, "silence")
	-- zm_qol CHANGE 1 of 2: stock tested for SYSTEMLINK or OFFLINE here and sent
	-- a menu response to the server otherwise. Plutonium reports neither mode,
	-- so the server-response branch is the one that would always run, and it
	-- does not restart anything locally. fast_restart is stock's own restart.
	Engine.Exec(f5_arg1.controller, "fast_restart")
end

CoD.RestartGamePopup.YesButtonPressed = function (f6_arg0, f6_arg1)
	Engine.ExecNow(f6_arg1.controller, "demo_stop")
	f6_arg0.controller = f6_arg1.controller
	-- zm_qol CHANGE 2 of 2: same test, same reason. Without this, YES fell
	-- through to the "uploading movie" spinner below and never restarted.
	-- RestartLevel closes the popup, so the spinner code stock runs after this
	-- point builds onto a closed menu and is inert - exactly as it is for
	-- Treyarch in the offline case, which also calls RestartLevel here first.
	CoD.RestartGamePopup.RestartLevel(f6_arg0, f6_arg1)
	return
end

CoD.RestartGamePopup.YesButtonPressedUploadPath = function (f6_arg0, f6_arg1)
	local f6_local0 = 5
	f6_arg0.title:setText(Engine.Localize("ZMUI_UPLOAD_MOVIE"))
	f6_arg0.title:setTopBottom(true, false, f6_local0, f6_local0 + CoD.textSize.Condensed)
	f6_arg0.subTitle:setText("")
	f6_arg0.subTitle:setAlpha(0)
	f6_arg0.buttonList:removeAllButtons()
	f6_arg0:removeBackButton()
	f6_arg0:removeSelectButton()
	local f6_local1 = 64
	local f6_local2 = 64
	f6_arg0.spinner = LUI.UIImage.new({
		shaderVector0 = {
			0,
			0,
			0,
			0
		}
	})
	f6_arg0.spinner:setLeftRight(true, true, CoD.Menu.SmallPopupWidth / 2 - f6_local2 / 2, -(CoD.Menu.SmallPopupWidth / 2 - f6_local2 / 2))
	f6_arg0.spinner:setTopBottom(true, true, CoD.Menu.SmallPopupHeight / 2 - f6_local1 / 2, -(CoD.Menu.SmallPopupHeight / 2 - f6_local1 / 2))
	f6_arg0.spinner:registerAnimationState("down", {
		topAnchor = true,
		bottomAnchor = true,
		top = CoD.Menu.SmallPopupHeight / 2 - f6_local1 / 2 + CoD.textSize.Condensed / 2,
		bottom = -(CoD.Menu.SmallPopupHeight / 2 - f6_local1 / 2) + CoD.textSize.Condensed / 2
	})
	f6_arg0.spinner:setImage(RegisterMaterial("lui_loader"))
	f6_arg0:addElement(f6_arg0.spinner)
	f6_arg0.demoStreamTimer = LUI.UITimer.new(2000, "waitForDemoStream", false)
	f6_arg0:addElement(f6_arg0.demoStreamTimer)
	f6_arg0.streamTimeOut = 0
end

CoD.RestartGamePopup.NoButtonPressed = function (f7_arg0, f7_arg1)
	f7_arg0:goBack(f7_arg1.controller)
end

LUI.createMenu.RestartGamePopup = function (f8_arg0)
	local f8_local0 = CoD.Menu.NewSmallPopup("RestartGamePopup")
	f8_local0:setOwner(f8_arg0)
	f8_local0:registerEventHandler("close_all_ingame_menus", CoD.InGameMenu.CloseAllInGameMenus)
	f8_local0:registerEventHandler("restartGamePopup_YesButtonPressed", CoD.RestartGamePopup.YesButtonPressed)
	f8_local0:registerEventHandler("restartGamePopup_NoButtonPressed", CoD.RestartGamePopup.NoButtonPressed)
	f8_local0:registerEventHandler("waitForDemoStream", CoD.RestartGamePopup.WaitForDemostream)
	f8_local0:registerEventHandler("cancelUpload", CoD.RestartGamePopup.CancelUpload)
	f8_local0:addSelectButton()
	f8_local0:addBackButton()
	local f8_local1 = 5
	local f8_local2 = LUI.UIText.new()
	f8_local2:setLeftRight(true, true, 0, 0)
	f8_local2:setTopBottom(true, false, f8_local1, f8_local1 + CoD.textSize.Condensed)
	f8_local2:setFont(CoD.fonts.Condensed)
	f8_local2:setAlignment(LUI.Alignment.Left)
	f8_local2:setText(Engine.Localize("MENU_CONTINUE_RESTART"))
	f8_local0.title = f8_local2
	f8_local0:addElement(f8_local2)
	f8_local1 = f8_local1 + CoD.textSize.Condensed + 10
	local f8_local3 = LUI.UIText.new()
	f8_local3:setLeftRight(true, true, 0, 0)
	f8_local3:setTopBottom(true, false, f8_local1, f8_local1 + CoD.textSize.Condensed)
	f8_local3:setFont(CoD.fonts.Condensed)
	f8_local3:setAlignment(LUI.Alignment.Left)
	f8_local3:setText(Engine.Localize("MENU_RESTART_LEVEL_TEXT"))
	f8_local3:registerAnimationState("fade_in", {
		alpha = 1
	})
	f8_local0.subTitle = f8_local3
	f8_local0:addElement(f8_local3)
	f8_local0.buttonList = CoD.ButtonList.new({
		leftAnchor = true,
		rightAnchor = true,
		left = 0,
		right = 0,
		topAnchor = false,
		bottomAnchor = true,
		top = -CoD.ButtonPrompt.Height - CoD.CoD9Button.Height * 3 + 10,
		bottom = 0
	})
	f8_local0:addElement(f8_local0.buttonList)
	local f8_local4 = CoD.RestartGamePopup.AddButton(f8_local0, Engine.Localize("MENU_YES"), "restartGamePopup_YesButtonPressed")
	local f8_local5 = CoD.RestartGamePopup.AddButton(f8_local0, Engine.Localize("MENU_NO"), "restartGamePopup_NoButtonPressed")
	f8_local5:processEvent({
		name = "gain_focus"
	})
	return f8_local0
end

