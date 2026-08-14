-- ============================================================================
--  hudcraftablestombzombie.lua  -  ORIGINS TOP-RIGHT / TOP-LEFT HUD CONTAINERS
--
--  WHY THIS FILE EXISTS IN THE MOD:
--  The Origins generator-status dial (the six-wedge wheel with the skull) was
--  drawing on top of the mod's own BOCW round indicator, which sits at
--  horzalign "right" / vertalign "top" (quality_of_life.gsc::round_hud). The
--  user asked for the DIAL to move left, not the round counter.
--
--  🛑 THE DIAL IS NOT ENGINE-DRAWN. checkpoint_39 §6 said it was, and that was
--  wrong - it was concluded after searching patch_ui_zm.ff, which holds only
--  lobby/menu LUI. The dial's widget is
--        ui_mp/t6/zombie/capturezonewheeltombdisplay.lua
--  and it is POSITIONED here, both shipped inside zm_tomb_patch.ff.
--
--  WHAT IS CHANGED FROM STOCK: exactly one number.
--        local f1_local12 = 10     -> 240
--  f1_local12 is the capture-wheel container's inset from the right edge;
--  setLeftRight(false, true, -width - inset, -inset) anchors it to the right,
--  so raising the inset slides the whole wheel left and changes nothing else.
--
--  HOW THE REST OF THIS FILE WAS ESTABLISHED (not guessed):
--  Body adapted from BO2-Reimagined's decompile at commit 7a8dfbfd, then every
--  numeric constant checked against the constant tables of the SHIPPED bytecode
--  dumped out of zm_tomb_patch.ff with OpenAssetTools. Verified equal:
--    main chunk        10, 3000, 5000, 500, 0, 1, 2, 6, 50
--    CraftablesTombArea 0, 4, 90, 100, 10, 120
--  The file is straight-line widget construction with two identical
--  `if not LocalSplitscreenMultiplePlayers` branches, which is the safe end of
--  the decompile-trust scale (CLAUDE.md: trust a decompile in inverse
--  proportion to its control flow).
--
--  ⚠️ ONE DISCLOSED UNCERTAINTY - CoD.CraftablesTomb.TabletTopStart.
--  Reimagined's copy reads `CoD.RoundStatus.ChalkSize + 94`, but that commit is
--  titled "Origins: move tablet HUD up" and the float 94 does NOT occur anywhere
--  in the shipped bytecode (byte-scanned for 00 00 BC 42; zero hits), and no
--  numeric constant sits between the "ChalkSize" and "OneInchIconWidth" strings
--  in the constant table. So stock is the bare term and that is what is written
--  below. This value positions ONLY the bottom-left One Inch Punch tablet icon;
--  it does not touch the capture wheel. Flagged rather than silently assumed.
-- ============================================================================

-- ============================================================================
--  v1.95.7 - THE GENERATOR PROGRESS RING, FIXED AT THE MECHANISM.
--
--  User, 2026-08-14: *"progress overlay for the generators is missing again,
--  how have you not fixed this problem for good? fix that permanently and never
--  re-introduce it, generator progress icon always works no more hidden stuff."*
--
--  🛑 WHY EVERY PREVIOUS ATTEMPT FAILED, AND WHY THIS ONE CANNOT.
--
--  The ring lives in ui_mp/t6/zombie/tombcapturezonedisplay.lua. Its menu is
--  built by CoD.GametypeBase.new(), whose last act is setAlpha(0) - the menu is
--  born INVISIBLE. Nothing in the objective path ever raises that alpha:
--  GametypeBase.NewObjectiveEvent creates the waypoint child and calls update()
--  on it, and never touches the parent. The ONLY thing that raises it is
--  CoD.TCZWaypoint.UpdateVisibility, which runs solely on an incoming
--  hud_update_bit_<N> event - which is why opening the scoreboard "fixes" it.
--
--  From GSC exactly one of those eleven bits can be written: BIT_HUD_VISIBLE,
--  via setclientuivisibilityflag( "hud_visible", ... ). So every previous fix
--  was a 0 -> 1 flip of that flag, timed to land after the client had built its
--  menus. All of them are races, and all of them lost:
--      v1.90.10  flip at t+8s                      -> ring stayed hidden
--      v1.90.11  flip during an active capture     -> ring appeared, but the
--                                                     whole HUD blinked
--      v1.95.4   flip after spawn + black screen   -> logged
--                "ring hud: hud_visible cycled 0->1" and the ring STILL did not
--                appear, because the menu is created later than that
--  A flip that lands before the menu exists reaches nothing, and the server
--  cannot see when the client builds its LUI. There is no timing that is safe.
--
--  🌟 SO STOP FIGHTING THE ALPHA AND STOP IT BEING ZERO. This file is loaded by
--  the mod already, so it can wrap the ring's own constructor: run stock's, then
--  raise the menu it just built. No timer, no event, no flag, nothing hidden -
--  the menu is simply never in the broken state to begin with.
--
--  📝 THIS DOES NOT MAKE THE RING DRAW WHEN IT SHOULDN'T. The parent is only a
--  container; the visible wheel is a waypoint CHILD that createObjectiveIfNeeded
--  builds per objective, and stock keeps those objectives in the "invisible"
--  state until a capture starts. Alpha 1 on an empty container draws nothing -
--  it is exactly the state a normal game is in after the intro raises the flag.
--  Setting .visible = true as well keeps UpdateVisibility's own state machine
--  honest, so a later legitimate hide (pause menu, scoreboard) still works: its
--  hide branch tests `visible == true`.
--
--  📝 BOTH LOAD ORDERS ARE HANDLED. If tombcapturezonedisplay.lua has already
--  registered its constructor we wrap it now; if it has not, a __newindex hook
--  wraps it at the moment it registers. The hook passes every other key straight
--  through with rawset and chains any pre-existing __newindex, so it cannot
--  change what any other menu file does.
--
--  🛑 THE NAME IS VERIFIED, NOT COPIED FROM A DECOMPILE. "TombCaptureZoneDisplay"
--  appears in the string constant table of the SHIPPED bytecode dumped out of
--  zm_tomb_patch.ff with OpenAssetTools.
-- ============================================================================
local function zmqol_ring_force_visible(originalCreateMenu)
	return function(...)
		local menu = originalCreateMenu(...)

		--  Defensive on purpose: a nil method call is a HARD LUI error, which
		--  would take Origins' whole HUD down - strictly worse than the bug this
		--  fixes. LUI.createMenu itself is known to exist here, because this same
		--  file assigns LUI.createMenu.CraftablesTombArea further down.
		if menu and menu.setAlpha then
			menu:setAlpha(1)
			menu.visible = true
		end

		return menu
	end
end

if LUI.createMenu.TombCaptureZoneDisplay then
	LUI.createMenu.TombCaptureZoneDisplay = zmqol_ring_force_visible(LUI.createMenu.TombCaptureZoneDisplay)
else
	local zmqol_mt = getmetatable(LUI.createMenu) or {}
	local zmqol_prev_newindex = zmqol_mt.__newindex

	zmqol_mt.__newindex = function(t, k, v)
		if k == "TombCaptureZoneDisplay" and type(v) == "function" then
			v = zmqol_ring_force_visible(v)
		end

		if zmqol_prev_newindex then
			zmqol_prev_newindex(t, k, v)
		else
			rawset(t, k, v)
		end
	end

	setmetatable(LUI.createMenu, zmqol_mt)
end

require("T6.Zombie.CraftableItemTombDisplay")
require("T6.Zombie.QuestItemTombDisplay")
require("T6.Zombie.PersistentItemTombDisplay")
require("T6.Zombie.CaptureZoneWheelTombDisplay")
CoD.CraftablesTomb = {}
CoD.CraftablesTomb.ContainerHeight = CoD.QuestItemTombDisplay.IconSize + CoD.textSize[CoD.QuestItemTombDisplay.FontName] + 10
CoD.CraftablesTomb.ONSCREEN_DURATION = 3000
CoD.CraftablesTomb.WHEEL_ONSCREEN_DURATION = 5000
CoD.CraftablesTomb.FADE_IN_DURATION = 500
CoD.CraftablesTomb.FADE_OUT_DURATION = 500
CoD.CraftablesTomb.NEED_ALL_ZONES = 0
CoD.CraftablesTomb.ALL_ZONES_CAPTURED = 1
CoD.CraftablesTomb.ZONE_CAPTURED = 1
CoD.CraftablesTomb.ZONE_LOST = 2
CoD.CraftablesTomb.TotalZoneCount = 6
CoD.CraftablesTomb.ZoneWheelBlueColor = CoD.greenBlue
CoD.CraftablesTomb.ZoneWheelRedColor = CoD.red
CoD.CraftablesTomb.TabletTopStart = CoD.RoundStatus.ChalkSize
CoD.CraftablesTomb.OneInchIconWidth = 50
CoD.CraftablesTomb.OneInchIconHeight = CoD.CraftablesTomb.OneInchIconWidth
CoD.CraftablesTomb.NEED_TABLET = 0
CoD.CraftablesTomb.HAVE_TABLET_CLEAN = 1
CoD.CraftablesTomb.NEED_TABLET_DIRTY = 2

-- zm_qol: the capture wheel's inset from the right edge. Stock is 10, which put
-- the wheel hard into the top-right corner on top of the mod's round indicator.
CoD.CraftablesTomb.ZmQolWheelRightInset = 240

LUI.createMenu.CraftablesTombArea = function (f1_arg0)
	local f1_local0 = CoD.Menu.NewSafeAreaFromState("CraftablesTombArea", f1_arg0)
	f1_local0:setOwner(f1_arg0)
	f1_local0.topLeftScaleContainer = CoD.SplitscreenScaler.new(nil, CoD.Zombie.SplitscreenMultiplier)
	f1_local0.topLeftScaleContainer:setLeftRight(true, false, 0, 0)
	f1_local0.topLeftScaleContainer:setTopBottom(true, false, 0, 0)
	f1_local0:addElement(f1_local0.topLeftScaleContainer)
	local f1_local1 = CoD.QuestItemTombDisplay.IconSize
	local f1_local2 = CoD.QuestItemTombDisplay.ContainerSize / 4
	local f1_local3 = false
	local f1_local4 = LUI.UIHorizontalList.new()
	f1_local4:setLeftRight(true, true, 0, 0)
	f1_local4:setTopBottom(true, false, 0, CoD.CraftablesTomb.ContainerHeight)
	local f1_local5 = CoD.PersistentItemTombDisplay.new(f1_local4)
	f1_local0.topLeftScaleContainer:addElement(f1_local5)
	CoD.PersistentItemTombDisplay.AddPersistentStatusDisplay(f1_local5, f1_local2, f1_local3)
	local f1_local6 = 90
	local f1_local7 = LUI.UIHorizontalList.new()
	f1_local7:setLeftRight(true, true, 0, 0)
	f1_local7:setTopBottom(true, false, f1_local6, f1_local6 + CoD.CraftablesTomb.ContainerHeight)
	local f1_local8 = CoD.QuestItemTombDisplay.new(f1_local7)
	f1_local0.topLeftScaleContainer:addElement(f1_local8)
	if not CoD.Zombie.LocalSplitscreenMultiplePlayers then
		CoD.QuestItemTombDisplay.AddQuestStatusDisplay(f1_local8, f1_local2, f1_local3)
		f1_local8.shouldFadeOutQuestStatus = true
		f1_local8.highlightRecentItem = true
	end
	local f1_local9 = f1_local6 + 100
	local f1_local10 = LUI.UIVerticalList.new()
	f1_local10:setLeftRight(true, true, 0, 0)
	f1_local10:setTopBottom(true, false, f1_local9, f1_local9 + CoD.CraftablesTomb.ContainerHeight)
	local f1_local11 = CoD.CraftableItemTombDisplay.new(f1_local10)
	f1_local0.topLeftScaleContainer:addElement(f1_local11)
	if not CoD.Zombie.LocalSplitscreenMultiplePlayers then
		CoD.CraftableItemTombDisplay.AddDisplayContainer(f1_local11, CoD.CraftableItemTombDisplay.ContainerSize / 4, f1_local3)
		f1_local11.shouldFadeOutQuestStatus = true
		f1_local11.highlightRecentItem = true
	end
	f1_local0.topRightScaleContainer = CoD.SplitscreenScaler.new(nil, CoD.Zombie.SplitscreenMultiplier)
	f1_local0.topRightScaleContainer:setLeftRight(false, true, 0, 0)
	f1_local0.topRightScaleContainer:setTopBottom(true, false, 0, 0)
	f1_local0:addElement(f1_local0.topRightScaleContainer)
	local f1_local12 = CoD.CraftablesTomb.ZmQolWheelRightInset   -- stock: 10
	local f1_local13 = 10
	local f1_local14 = 120
	local Widget = LUI.UIElement.new()
	Widget:setLeftRight(false, true, -f1_local14 - f1_local12, -f1_local12)
	Widget:setTopBottom(true, false, f1_local13, f1_local14 + f1_local13)
	Widget:setAlpha(0)
	f1_local0.topRightScaleContainer:addElement(Widget)
	f1_local0.captureZoneWheelContainer = Widget
	local f1_local16 = CoD.CaptureZoneWheelTombDisplay.new(f1_local0.captureZoneWheelContainer)
	if not CoD.Zombie.LocalSplitscreenMultiplePlayers then
		CoD.CaptureZoneWheelTombDisplay.AddCaptureZoneWheel(f1_local16, f1_local14, f1_local3)
		f1_local16.shouldFadeOutQuestStatus = true
	end
	CoD.CraftablesTomb.OneInchPunchCleanMaterial = RegisterMaterial("zm_hud_icon_oneinch_clean")
	CoD.CraftablesTomb.OneInchPunchDirtyMaterial = RegisterMaterial("zm_hud_icon_oneinch_dirty")
	f1_local0.bottomLeftScaleContainer = CoD.SplitscreenScaler.new(nil, CoD.Zombie.SplitscreenMultiplier)
	f1_local0.bottomLeftScaleContainer:setLeftRight(true, false, 0, 0)
	f1_local0.bottomLeftScaleContainer:setTopBottom(false, true, 0, 0)
	f1_local0:addElement(f1_local0.bottomLeftScaleContainer)
	local f1_local17 = CoD.CraftablesTomb.TabletTopStart
	local Widget = LUI.UIElement.new()
	Widget:setLeftRight(true, false, 0, CoD.CraftablesTomb.OneInchIconWidth)
	Widget:setTopBottom(false, true, -CoD.CraftablesTomb.OneInchIconHeight - f1_local17, -f1_local17)
	Widget:setAlpha(0)
	f1_local0.bottomLeftScaleContainer:addElement(Widget)
	f1_local0.tabletContainer = Widget

	local tabletIcon = LUI.UIImage.new()
	tabletIcon:setLeftRight(true, true, 0, 0)
	tabletIcon:setTopBottom(true, true, 0, 0)
	tabletIcon:setImage(CoD.CraftablesTomb.OneInchPunchDirtyMaterial)
	Widget:addElement(tabletIcon)
	f1_local0.tabletIcon = tabletIcon

	f1_local0:registerEventHandler("player_tablet_state", CoD.CraftablesTomb.UpdateTabletState)
	f1_local0:registerEventHandler("hud_update_refresh", CoD.CraftablesTomb.UpdateVisibility)
	f1_local0:registerEventHandler("hud_update_bit_" .. CoD.BIT_HUD_VISIBLE, CoD.CraftablesTomb.UpdateVisibility)
	f1_local0:registerEventHandler("hud_update_bit_" .. CoD.BIT_EMP_ACTIVE, CoD.CraftablesTomb.UpdateVisibility)
	f1_local0:registerEventHandler("hud_update_bit_" .. CoD.BIT_DEMO_CAMERA_MODE_MOVIECAM, CoD.CraftablesTomb.UpdateVisibility)
	f1_local0:registerEventHandler("hud_update_bit_" .. CoD.BIT_DEMO_ALL_GAME_HUD_HIDDEN, CoD.CraftablesTomb.UpdateVisibility)
	f1_local0:registerEventHandler("hud_update_bit_" .. CoD.BIT_IN_VEHICLE, CoD.CraftablesTomb.UpdateVisibility)
	f1_local0:registerEventHandler("hud_update_bit_" .. CoD.BIT_IN_GUIDED_MISSILE, CoD.CraftablesTomb.UpdateVisibility)
	f1_local0:registerEventHandler("hud_update_bit_" .. CoD.BIT_IN_REMOTE_KILLSTREAK_STATIC, CoD.CraftablesTomb.UpdateVisibility)
	f1_local0:registerEventHandler("hud_update_bit_" .. CoD.BIT_AMMO_COUNTER_HIDE, CoD.CraftablesTomb.UpdateVisibility)
	f1_local0:registerEventHandler("hud_update_bit_" .. CoD.BIT_IS_FLASH_BANGED, CoD.CraftablesTomb.UpdateVisibility)
	f1_local0:registerEventHandler("hud_update_bit_" .. CoD.BIT_UI_ACTIVE, CoD.CraftablesTomb.UpdateVisibility)
	f1_local0:registerEventHandler("hud_update_bit_" .. CoD.BIT_SPECTATING_CLIENT, CoD.CraftablesTomb.UpdateVisibility)
	f1_local0:registerEventHandler("hud_update_bit_" .. CoD.BIT_SCOREBOARD_OPEN, CoD.CraftablesTomb.UpdateVisibility)
	f1_local0:registerEventHandler("hud_update_bit_" .. CoD.BIT_PLAYER_DEAD, CoD.CraftablesTomb.UpdateVisibility)
	f1_local0:registerEventHandler("hud_update_bit_" .. CoD.BIT_IS_SCOPED, CoD.CraftablesTomb.UpdateVisibility)
	f1_local0.visible = true
	return f1_local0
end

CoD.CraftablesTomb.UpdateVisibility = function (f2_arg0, f2_arg1)
	local f2_local0 = f2_arg1.controller
	if UIExpression.IsVisibilityBitSet(f2_local0, CoD.BIT_HUD_VISIBLE) == 1 and UIExpression.IsVisibilityBitSet(f2_local0, CoD.BIT_EMP_ACTIVE) == 0 and UIExpression.IsVisibilityBitSet(f2_local0, CoD.BIT_DEMO_CAMERA_MODE_MOVIECAM) == 0 and UIExpression.IsVisibilityBitSet(f2_local0, CoD.BIT_DEMO_ALL_GAME_HUD_HIDDEN) == 0 and UIExpression.IsVisibilityBitSet(f2_local0, CoD.BIT_IN_VEHICLE) == 0 and UIExpression.IsVisibilityBitSet(f2_local0, CoD.BIT_IN_GUIDED_MISSILE) == 0 and UIExpression.IsVisibilityBitSet(f2_local0, CoD.BIT_IN_REMOTE_KILLSTREAK_STATIC) == 0 and UIExpression.IsVisibilityBitSet(f2_local0, CoD.BIT_AMMO_COUNTER_HIDE) == 0 and UIExpression.IsVisibilityBitSet(f2_local0, CoD.BIT_IS_FLASH_BANGED) == 0 and UIExpression.IsVisibilityBitSet(f2_local0, CoD.BIT_UI_ACTIVE) == 0 and UIExpression.IsVisibilityBitSet(f2_local0, CoD.BIT_SCOREBOARD_OPEN) == 0 and UIExpression.IsVisibilityBitSet(f2_local0, CoD.BIT_IS_SCOPED) == 0 and (not CoD.IsShoutcaster(f2_local0) or CoD.ExeProfileVarBool(f2_local0, "shoutcaster_scorestreaks") and Engine.IsSpectatingActiveClient(f2_local0)) and CoD.FSM_VISIBILITY(f2_local0) == 0 then
		if f2_arg0.visible ~= true then
			f2_arg0:setAlpha(1)
			f2_arg0.m_inputDisabled = nil
			f2_arg0.visible = true
		end
	elseif f2_arg0.visible == true then
		f2_arg0:setAlpha(0)
		f2_arg0.m_inputDisabled = true
		f2_arg0.visible = nil
	end
	f2_arg0:dispatchEventToChildren(f2_arg1)
end

CoD.CraftablesTomb.UpdateTabletState = function (f3_arg0, f3_arg1)
	local f3_local0 = f3_arg1.newValue
	if f3_local0 == CoD.CraftablesTomb.NEED_TABLET then
		f3_arg0.tabletContainer:setAlpha(0)
	elseif f3_local0 == CoD.CraftablesTomb.HAVE_TABLET_CLEAN then
		f3_arg0.tabletIcon:setImage(CoD.CraftablesTomb.OneInchPunchCleanMaterial)
		f3_arg0.tabletContainer:setAlpha(1)
	elseif f3_local0 == CoD.CraftablesTomb.NEED_TABLET_DIRTY then
		f3_arg0.tabletIcon:setImage(CoD.CraftablesTomb.OneInchPunchDirtyMaterial)
		f3_arg0.tabletContainer:setAlpha(1)
	end
end
