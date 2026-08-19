-- ============================================================================
--  zm_qol v1.99.85 - THE ZOMBIES PAUSE MENU, +2 ROWS. Queue items 28 and 29.
--
--  User, 2026-08-19, from a friend's screen-share:
--    28  INSTANT EXIT   - under the existing END GAME, straight to the lobby
--                         with no game-over music and no scoreboard. Same effect
--                         as the `disconnect` console command they already have
--                         bound and have confirmed works.
--    29  QUIT TO DESKTOP - runs `quit`, closes the game instantly.
--  🛑 END GAME IS NOT TOUCHED. The user was explicit about that; these are
--  additions beside it.
--
--  🛑 ITEM 27, "RESTART GAME", IS DELIBERATELY NOT HERE. See QUEUE.md. Short
--  version: stock builds that button, but PLUTONIUM'S OWN class.lua - this
--  file's base - has removed the whole branch, handler included, so it is not a
--  matter of relaxing a condition. Re-adding the button means also supplying the
--  restart itself, and the only stock mechanism is the GSC builtin
--  map_restart(1) (_zm_gametype.gsc:1197, _globallogic.gsc:960), which stock
--  uses to restart a GRIEF ROUND with the game state deliberately preserved.
--  Whether that yields a clean round-1 Survival match under Plutonium cannot be
--  settled from the files, and a "restart" that hands the player back their
--  perks and round number is exactly the half-working row this project does not
--  ship. It needs one boot to decide, and it is written up rather than guessed.
--
--  ── WHY THIS FILE CAN BE OVERRIDDEN AT ALL, measured ────────────────────────
--  `class.lua` is loaded at BOOT, before any mod is on the search path
--  (console_zm.log line 512, loadmod at 682) - so a naive reading says a mod can
--  never win it. But it is loaded a SECOND time after a mod loads: in the
--  2026-08-19 session log it appears at line 524 and again at 861, with
--  `loadmod: loaded mods/zm_qol` at 701 and `Loading fastfile mod` at 730 in
--  between. At that point the search path has
--  `storage\t6\mods\zm_qol\mod.iwd` at RANK 1, above `storage\t6\raw` at rank 3
--  (both orderings are printed verbatim in the log). So this copy wins while the
--  mod is loaded, and it wins for someone who merely downloaded the release -
--  unlike optionssettings.lua and the other two frontend files, which are menu
--  time only and therefore have to be synced into Plutonium's raw\ folder by
--  build.bat.
--
--  🛑 THE BASE IS PLUTONIUM'S FILE, NOT TREYARCH'S. It is a copy of
--  storage\t6\raw\ui_mp\t6\hud\class.lua with only the marked additions. Their
--  version already differs from stock (the RESTART GAME branch is gone). If
--  Plutonium ships a new class.lua, this copy shadows it while the mod is
--  loaded - re-copy and re-apply the two marked blocks when that happens.
-- ============================================================================
require("T6.HUD.InGameMenus")
require("T6.UnifiedFriends")
if CoD.isMultiplayer and not CoD.isZombie then
	require("T6.XPBar")
end
CoD.Class = {}

CoD.Class.DisableChooseTeam = function ()
	if CoD.Class.GametypeSettings.allowInGameTeamChange == 1 then
		return false
	end
	if CoD.Class.GametypeSettings.allowSpectating == 1 then
		return false
	end
	return true
end

CoD.Class.DisableChooseClass = function ()
	return CoD.Class.GametypeSettings.disableClassSelection == 1
end

CoD.Class.IsChooseTeamAvailable = function ()
	if CoD.isZombie and CoD.Class.GametypeSettings.teamCount < 2 then
		return false
	end
	if CoD.Class.GametypeSettings.allowInGameTeamChange == 0 and CoD.Class.GametypeSettings.allowSpectating == 0 then
		return false
	end
	return true
end

CoD.Class.AddButton = function (IngameMenuWidget, ButtonName, MenuName, f3_arg3)
	local NewButton = IngameMenuWidget.buttonList:addButton(ButtonName)
	NewButton:setActionEventName(MenuName)
	if f3_arg3 == true then
		NewButton:disable()
	end
	return NewButton
end

CoD.Class.ChooseClassButtonPressed = function (IngameMenuWidget, ClientInstance)
	IngameMenuWidget:saveState()
	IngameMenuWidget:openMenu("changeclass", ClientInstance.controller)
	IngameMenuWidget:close()
end

CoD.Class.OptionsButtonPressed = function (IngameMenuWidget, ClientInstance)
	IngameMenuWidget:saveState()
	IngameMenuWidget:openMenu("OptionsMenu", ClientInstance.controller)
	IngameMenuWidget:close()
end

CoD.Class.EndGameButtonPressed = function (IngameMenuWidget, ClientInstance)
	IngameMenuWidget:openPopup("EndGamePopup", ClientInstance.controller)
end

-- zm_qol ADDITION 1 of 2 - the two handlers. Engine.Exec( controller, cmd ) is
-- the shipped route for running a console command from LUI: Plutonium's own
-- mainlobby.lua uses it for xsigninlive, and this mod's optionssettings.lua
-- already uses it for vid_restart and snd_restart. Both command names were
-- confirmed present in t6zm.exe's string table.
CoD.Class.ZmQolInstantExitPressed = function (IngameMenuWidget, ClientInstance)
	Engine.Exec(ClientInstance.controller, "disconnect")
end

CoD.Class.ZmQolQuitToDesktopPressed = function (IngameMenuWidget, ClientInstance)
	Engine.Exec(ClientInstance.controller, "quit")
end

CoD.Class.ResumeGameButtonPressed = function (IngameMenuWidget, ClientInstance)
	IngameMenuWidget:processEvent({
		name = "button_prompt_back",
		controller = ClientInstance.controller
	})
end

CoD.Class.ChooseTeamButtonPressed = function (IngameMenuWidget, ClientInstance)
	IngameMenuWidget:saveState()
	IngameMenuWidget:openMenu("team_marinesopfor", ClientInstance.controller)
	IngameMenuWidget:close()
end

CoD.Class.ButtonPromptFriendsMenu = function (IngameMenuWidget, ClientInstance)
	IngameMenuWidget:saveState()
	local f11_local0 = IngameMenuWidget:openMenu("FriendsList", ClientInstance.controller)
	f11_local0:setPreviousMenu("class")
	IngameMenuWidget:close()
end

CoD.Class.PrepareClassButtonList = function (LocalClientIndex, IngameMenuWidget)
	local f12_local0 = CoD.SplitscreenScaler.new(nil, 1.5)
	f12_local0:setLeftRight(true, false, 0, 0)
	f12_local0:setTopBottom(true, false, 0, 0)
	IngameMenuWidget:addElement(f12_local0)
	IngameMenuWidget.buttonList = CoD.ButtonList.new({
		leftAnchor = true,
		rightAnchor = false,
		left = 0,
		right = CoD.ButtonList.DefaultWidth,
		topAnchor = true,
		bottomAnchor = false,
		top = CoD.Menu.TitleHeight,
		bottom = CoD.Menu.TitleHeight + 720
	})
	f12_local0:addElement(IngameMenuWidget.buttonList)
	if CoD.isZombie == true then
		if Engine.CanPauseZombiesGame() and CoD.canLeaveGame(LocalClientIndex) then
			CoD.Class.AddButton(IngameMenuWidget, Engine.Localize("MENU_RESUMEGAME_CAPS"), "soloResumeGame")
		end
	else
		if UIExpression.Team(LocalClientIndex, "name") ~= "TEAM_SPECTATOR" and CoD.IsWagerMode() == false then
			CoD.Class.AddButton(IngameMenuWidget, Engine.Localize("MPUI_CHOOSE_CLASS_BUTTON_CAPS"), "open_chooseClass", CoD.Class.DisableChooseClass())
		end
	end
	if UIExpression.IsVisibilityBitSet(LocalClientIndex, CoD.BIT_ROUND_END_KILLCAM) == 0 and UIExpression.IsVisibilityBitSet(LocalClientIndex, CoD.BIT_FINAL_KILLCAM) == 0 and CoD.Class.IsChooseTeamAvailable() then
		CoD.Class.AddButton(IngameMenuWidget, Engine.Localize("MPUI_CHANGE_TEAM_BUTTON_CAPS"), "open_chooseTeam", CoD.Class.DisableChooseTeam())
	end
	CoD.Class.AddButton(IngameMenuWidget, Engine.Localize("MENU_OPTIONS_CAPS"), "open_options")
	if CoD.canLeaveGame(LocalClientIndex) then
		if CoD.isHost() then
			CoD.Class.AddButton(IngameMenuWidget, Engine.Localize("MENU_END_GAME_CAPS"), "open_endGamePopup")
		else
			CoD.Class.AddButton(IngameMenuWidget, Engine.Localize("MENU_LEAVE_GAME_CAPS"), "open_endGamePopup")
		end
		-- zm_qol ADDITION 2 of 2, part a - INSTANT EXIT, immediately under END
		-- GAME as asked, and inside the SAME canLeaveGame() gate: leaving is
		-- leaving, so if the game will not let you end it, it must not offer a
		-- faster way out either.
		if CoD.isZombie == true then
			CoD.Class.AddButton(IngameMenuWidget, Engine.Localize("INSTANT EXIT"), "zmqol_instant_exit")
		end
	end
	-- part b - QUIT TO DESKTOP. Outside the canLeaveGame() gate on purpose:
	-- closing the program is always available, and it is last so it cannot be
	-- hit by muscle memory aimed at the row above.
	-- 📝 No confirmation step, which is what the user asked for ("closes the
	-- game instantly"). It is one row below INSTANT EXIT on a menu people
	-- navigate blind, so if they ever want a confirm popup, EndGameButtonPressed
	-- above is the pattern to copy.
	if CoD.isZombie == true then
		CoD.Class.AddButton(IngameMenuWidget, Engine.Localize("QUIT TO DESKTOP"), "zmqol_quit_desktop")
	end
	if not IngameMenuWidget:restoreState() then
		IngameMenuWidget.buttonList:processEvent({
			name = "gain_focus_skip_disabled"
		})
	end
end

LUI.createMenu.class = function (LocalClientIndex)
	if CoD.Class.GametypeSettings == nil then
		CoD.Class.GametypeSettings = {
			teamCount = Engine.GetGametypeSetting("teamCount"),
			allowSpectating = Engine.GetGametypeSetting("allowSpectating"),
			allowInGameTeamChange = Engine.GetGametypeSetting("allowInGameTeamChange"),
			disableClassSelection = Engine.GetGametypeSetting("disableClassSelection")
		}
	end
	local ClassMenuHeader = "MPUI_PAUSE_MENU"
	if CoD.isZombie == true then
		ClassMenuHeader = "MENU_ZOMBIES_CAPS"
	end
	local IngameMenuWidget = CoD.InGameMenu.New("class", LocalClientIndex, UIExpression.ToUpper(nil, Engine.Localize(ClassMenuHeader)))
	Engine.PlaySound("uin_main_pause")
	IngameMenuWidget:addButtonPrompts()
	CoD.Class.PrepareClassButtonList(LocalClientIndex, IngameMenuWidget)
	IngameMenuWidget:registerEventHandler("open_chooseClass", CoD.Class.ChooseClassButtonPressed)
	IngameMenuWidget:registerEventHandler("open_chooseTeam", CoD.Class.ChooseTeamButtonPressed)
	IngameMenuWidget:addFriendsButton()
	IngameMenuWidget:registerEventHandler("button_prompt_friends", CoD.Class.ButtonPromptFriendsMenu)
	IngameMenuWidget:registerEventHandler("open_options", CoD.Class.OptionsButtonPressed)
	IngameMenuWidget:registerEventHandler("open_endGamePopup", CoD.Class.EndGameButtonPressed)
	-- zm_qol - the two additions' handlers. Registered unconditionally, the same
	-- way open_endGamePopup is: a handler with no button is inert, and this
	-- keeps the registration out of the isZombie branch below where the button
	-- code cannot see it.
	IngameMenuWidget:registerEventHandler("zmqol_instant_exit", CoD.Class.ZmQolInstantExitPressed)
	IngameMenuWidget:registerEventHandler("zmqol_quit_desktop", CoD.Class.ZmQolQuitToDesktopPressed)
	if CoD.isZombie == true then
		IngameMenuWidget:registerEventHandler("soloResumeGame", CoD.Class.ResumeGameButtonPressed)
	end
	local Mapname = UIExpression.TableLookup(LocalClientIndex, UIExpression.GetCurrentMapTableName(), 0, UIExpression.DvarString(nil, "mapname"), 3)
	local f13_local10 = CoD.SplitscreenScaler.new(nil, CoD.SplitscreenMultiplier)
	f13_local10:setLeftRight(false, true, 0, 0)
	f13_local10:setTopBottom(true, true, CoD.Menu.TitleHeight, -CoD.Menu.TitleHeight)
	IngameMenuWidget:addElement(f13_local10)
	if CoD.isZombie == false and not Engine.IsShoutcaster(LocalClientIndex) then
		local MapnameText = LUI.UIText.new()
		MapnameText:setLeftRight(false, true, -300, 0)
		MapnameText:setTopBottom(true, false, 0, CoD.textSize.Condensed)
		MapnameText:setFont(CoD.fonts.Condensed)
		MapnameText:setAlignment(LUI.Alignment.Left)
		MapnameText:setRGB(CoD.trueOrange.r, CoD.trueOrange.g, CoD.trueOrange.b)
		MapnameText:setText(Engine.Localize(Mapname .. "_CAPS"))
		f13_local10:addElement(MapnameText)
		local LocationText = LUI.UIText.new()
		LocationText:setLeftRight(false, true, -300, 0)
		LocationText:setTopBottom(true, false, CoD.textSize.Condensed, CoD.textSize.Condensed + CoD.textSize.Default)
		LocationText:setFont(CoD.fonts.Default)
		LocationText:setAlignment(LUI.Alignment.Left)
		LocationText:setText(Engine.Localize(Mapname .. "_LOC"))
		f13_local10:addElement(LocationText)
		CoD.Compass.AddInGameMap(f13_local10, LocalClientIndex, {
			leftAnchor = false,
			rightAnchor = true,
			left = -300,
			right = 0,
			topAnchor = true,
			bottomAnchor = false,
			top = CoD.textSize.Condensed + CoD.textSize.Default,
			bottom = CoD.textSize.Condensed + CoD.textSize.Default + 300
		})
		local f13_local15 = CoD.textSize.Condensed + CoD.textSize.Default + 300
		local GametypeText = LUI.UIText.new()
		GametypeText:setLeftRight(false, true, -300, 0)
		GametypeText:setTopBottom(true, false, f13_local15, f13_local15 + CoD.textSize.Condensed)
		GametypeText:setFont(CoD.fonts.Condensed)
		GametypeText:setAlignment(LUI.Alignment.Left)
		GametypeText:setText(UIExpression.GametypeName())
		GametypeText:setRGB(CoD.trueOrange.r, CoD.trueOrange.g, CoD.trueOrange.b)
		f13_local10:addElement(GametypeText)
		local f13_local17 = f13_local15 + CoD.textSize.Condensed
		local GametypeDescription = LUI.UIText.new()
		GametypeDescription:setLeftRight(false, true, -300, 0)
		GametypeDescription:setTopBottom(true, false, f13_local17, f13_local17 + CoD.textSize.Default)
		GametypeDescription:setFont(CoD.fonts.Default)
		GametypeDescription:setAlignment(LUI.Alignment.Left)
		GametypeDescription:setText(UIExpression.GametypeDescription())
		f13_local10:addElement(GametypeDescription)
	end
	if CoD.isZombie == false and not Engine.IsShoutcaster(LocalClientIndex) and UIExpression.IsGuest(LocalClientIndex) == 0 and Engine.GameModeIsMode(CoD.GAMEMODE_PUBLIC_MATCH) == true and CoD.CanRankUp(LocalClientIndex) == true then
		local f13_local14 = -10 - CoD.ButtonPrompt.Height
		local XPBarWidget = LUI.UIElement.new()
		XPBarWidget:setLeftRight(false, false, -(CoD.Menu.Width / 2), CoD.Menu.Width / 2)
		XPBarWidget:setTopBottom(false, true, f13_local14 - 40, f13_local14)
		IngameMenuWidget:addElement(XPBarWidget)
		local f13_local15 = LUI.UIImage.new()
		f13_local15:setLeftRight(true, true, 1, -1)
		f13_local15:setTopBottom(true, true, 1, -1)
		f13_local15:setRGB(0, 0, 0)
		f13_local15:setAlpha(0.6)
		XPBarWidget:addElement(f13_local15)
		XPBarWidget.border = CoD.Border.new(1, 1, 1, 1, 0.1)
		XPBarWidget:addElement(XPBarWidget.border)
		local XPBar = CoD.XPBar.New(nil, LocalClientIndex, CoD.Menu.Width - 20)
		XPBar:setLeftRight(true, true, 10, -10)
		XPBar:setTopBottom(true, true, 0, 0)
		XPBarWidget:addElement(XPBar)
		XPBar:processEvent({
			name = "animate_xp_bar",
			duration = 0
		})
	end
	return IngameMenuWidget
end

