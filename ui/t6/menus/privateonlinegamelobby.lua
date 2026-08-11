-- ============================================================================
--  zm_qol: SOLO PLAY LOBBY TITLE
--
--  Stock titles this menu "CUSTOM GAMES" unconditionally, but Solo Play and
--  Custom Games are the SAME menu (PrivateOnlineGameLobby) - so entering
--  Zombies > Solo Play showed the Custom Games header.
--
--  This file is a faithful reconstruction of the stock one, verified against
--  the constant table of the shipped bytecode
--  (H:\Claude\BO2-Raw-files\ui\t6\menus\privateonlinegamelobby.lua): require /
--  T6.Menus.PrivateGameLobby / CoD / PrivateOnlineGameLobby / LUI / createMenu /
--  New / isMultiplayer / setPreviousMenu / MainLobby / Engine / Localize /
--  MPUI_CUSTOM_GAMES_CAPS / addTitle / panelManager / panels / buttonPane /
--  titleText - in exactly that order, with nothing left over. The ONLY addition
--  is the ZMUI_SOLO_PLAY_CAPS branch. Same approach BO2-Reimagined takes in its
--  copy of this file, minus its two unrelated gameplay changes.
--
--  WHY IT IS A SEPARATE FILE, and not a patch in privategamelobby_project.lua
--  (a file this mod already owns): stock privategamelobby.lua requires
--  T6.Menus.PrivateGameLobby_Project, and this file requires
--  T6.Menus.PrivateGameLobby. So our project file runs FIRST, and anything it
--  assigned to LUI.createMenu.PrivateOnlineGameLobby would be overwritten when
--  this file loaded afterwards. The title is also applied after New() returns,
--  so no _Project hook runs late enough to change it either.
--
--  ZMUI_SOLO_PLAY_CAPS is a STOCK localize key, not one this mod has to ship -
--  Plutonium's own ui/t6/mainlobby.lua:446 uses it for the "SOLO PLAY" button
--  the user clicks to get here.
--
--  party_solo is guaranteed correct by the time this runs: this mod's own
--  CoD.MainLobby.OpenSoloLobby_Zombie sets it to 1 immediately before
--  openMenu("PrivateOnlineGameLobby"), and OpenCustomGamesLobby sets it to 0 -
--  so the Custom Games lobby keeps its own title, and Multiplayer is untouched
--  because the branch also requires CoD.isZombie.
--
--  Shipped under BOTH ui/ and ui_mp/ (identical content). T6 resolves
--  "T6.Menus.X" against both roots - stock keeps this file under ui/ and
--  privategamelobby_project.lua under ui_mp/ - and the search ORDER between
--  them has never been measured in this project. Two identical copies means
--  whichever root wins, the result is the same. require() caches by module
--  name, so only one of them is ever executed.
-- ============================================================================

require("T6.Menus.PrivateGameLobby")

CoD.PrivateOnlineGameLobby = {}

LUI.createMenu.PrivateOnlineGameLobby = function (controller)
	local menu = CoD.PrivateGameLobby.New("PrivateOnlineGameLobby", controller)

	if CoD.isMultiplayer then
		menu:setPreviousMenu("MainLobby")
	end

	local title = Engine.Localize("MPUI_CUSTOM_GAMES_CAPS")

	if CoD.isZombie and UIExpression.DvarBool(nil, "party_solo") == 1 then
		title = Engine.Localize("ZMUI_SOLO_PLAY_CAPS")
	end

	menu:addTitle(title)
	menu.panelManager.panels.buttonPane.titleText = title

	return menu
end
