require("T6.menus.safeareamenu")

CoD.OptionsSettings = {}
CoD.OptionsSettings.CurrentTabIndex = 1
CoD.OptionsSettings.NeedVidRestart = false
CoD.OptionsSettings.NeedPicmip = false
CoD.OptionsSettings.NeedSndRestart = false
CoD.OptionsSettings.ResetRestartFlags = function ()
	CoD.OptionsSettings.NeedVidRestart = false
	CoD.OptionsSettings.NeedPicmip = false
	CoD.OptionsSettings.NeedSndRestart = false
end

CoD.OptionsSettings.LeaveApplyPopup_DeclineApply = function (f2_arg0, ClientInstance)
	f2_arg0:setPreviousMenu("OptionsMenu")
	CoD.OptionsSettings.ResetRestartFlags()
	f2_arg0:goBack(ClientInstance.controller)
end

CoD.OptionsSettings.ApplyPopup_DeclineApply = function (f3_arg0, ClientInstance)
	CoD.OptionsSettings.ResetRestartFlags()
	f3_arg0:goBack(ClientInstance.controller)
end

CoD.OptionsSettings.ApplyPopup_ApplyChanges = function (f4_arg0, ClientInstance)
	CoD.OptionsSettings.ApplyChanges()
	f4_arg0:goBack(ClientInstance.controller)
end

CoD.OptionsSettings.Back = function (f5_arg0, ClientInstance)
	if CoD.OptionsSettings.NeedVidRestart or CoD.OptionsSettings.NeedPicmip or CoD.OptionsSettings.NeedSndRestart then
		local f5_local0 = f5_arg0:openMenu("LeaveApplyConfirmPopup", ClientInstance.controller)
		f5_local0:registerEventHandler("confirm_action", CoD.OptionsSettings.ApplyPopup_ApplyChanges)
		f5_local0:registerEventHandler("decline_action", CoD.OptionsSettings.LeaveApplyPopup_DeclineApply)
		f5_arg0:close()
	else
		CoD.Options.UpdateWindowPosition()
		Engine.Exec(ClientInstance.controller, "updategamerprofile")
		Engine.SaveHardwareProfile()
		Engine.ApplyHardwareProfileSettings()
		f5_arg0:goBack(ClientInstance.controller)
	end
end

CoD.OptionsSettings.TabChanged = function (OptionsSettingsWidget, SettingsTab)
	OptionsSettingsWidget.buttonList = OptionsSettingsWidget.tabManager.buttonList
	local NextFocusableTab = OptionsSettingsWidget.buttonList:getFirstChild()
	while not NextFocusableTab.m_focusable do
		NextFocusableTab = NextFocusableTab:getNextSibling()
	end
	if NextFocusableTab ~= nil then
		NextFocusableTab:processEvent({
			name = "gain_focus"
		})
	end
	CoD.OptionsSettings.CurrentTabIndex = SettingsTab.tabIndex
end

CoD.OptionsSettings.SelectorChanged = function (OptionsMenuTab, SelectorChangedEventTable)
	if SelectorChangedEventTable.userRequested ~= true then
		return 
	end
	local SelectorChoices = OptionsMenuTab.buttonList.m_selectors
	local SelectorChanged = SelectorChangedEventTable.selector
	local OptionChanged = SelectorChanged.m_profileVarName
	if OptionChanged == "r_fullscreen" and SelectorChoices.r_monitor ~= nil and SelectorChoices.r_mode ~= nil then
		local FullscreenMode = SelectorChanged:getCurrentValue()
		local MonitorChoices = SelectorChoices.r_monitor
		local DisplayResolutionChoices = SelectorChoices.r_mode
		if FullscreenMode == "0" then
			MonitorChoices:setChoice(0)
			MonitorChoices:disableSelector()
			DisplayResolutionChoices:enableSelector()
		elseif FullscreenMode == "2" then
			MonitorChoices:enableSelector()
			DisplayResolutionChoices:disableSelector()
		else
			MonitorChoices:enableSelector()
			DisplayResolutionChoices:enableSelector()
		end
	end
	if OptionChanged == "r_vsync" and SelectorChoices.com_maxfps ~= nil then
		local MaxFPSSelector = SelectorChoices.com_maxfps
		if SelectorChanged:getCurrentValue() == "1" then
			MaxFPSSelector:setChoice(0)
			MaxFPSSelector:disableSelector()
		else
			MaxFPSSelector:enableSelector()
		end
	end
	if OptionChanged == "r_monitor" and SelectorChoices.r_mode ~= nil then
		CoD.OptionsSettings.Button_AddChoices_Resolution(SelectorChoices.r_mode)
	end
	if OptionChanged == "r_fullscreen" or OptionChanged == "r_mode" or OptionChanged == "r_aaSamples" or OptionChanged == "r_monitor" or OptionChanged == "r_texFilterQuality" then
		CoD.OptionsSettings.NeedVidRestart = true
		OptionsMenuTab:addApplyPrompt()
	end
	if OptionChanged == "r_picmip" then
		CoD.OptionsSettings.NeedPicmip = true
		OptionsMenuTab:addApplyPrompt()
	end
	if OptionChanged == "sd_xa2_device_name" then
		CoD.OptionsSettings.NeedSndRestart = true
		OptionsMenuTab:addApplyPrompt()
	end
end

CoD.OptionsSettings.ResolutionChanged = function (OptionsMenuTab, ClientInstance)
	CoD.OptionsSettings.RefreshMenu(OptionsMenuTab)
	CoD.Menu.ResolutionChanged(OptionsMenuTab, ClientInstance)
end

CoD.OptionsSettings.OpenBrightness = function (f9_arg0, ClientInstance)
	f9_arg0:saveState()
	f9_arg0:openMenu("Brightness", ClientInstance.controller)
	f9_arg0:close()
	CoD.OptionsSettings.DoNotSyncProfile = true
end

CoD.OptionsSettings.OpenMatureContent = function ( f10_arg0, f10_arg1 )
	f10_arg0:saveState()
	f10_arg0:openMenu( "MatureContentPopup", f10_arg1.controller )
	f10_arg0:close()
	CoD.OptionsSettings.DoNotSyncProfile = true
end

CoD.OptionsSettings.OpenApplyPopup = function (f11_arg0, ClientInstance)
	local f11_local0 = f11_arg0:openMenu("ApplyChangesPopup", ClientInstance.controller)
	f11_local0:registerEventHandler("confirm_action", CoD.OptionsSettings.ApplyPopup_ApplyChanges)
	f11_local0:registerEventHandler("decline_action", CoD.OptionsSettings.ApplyPopup_DeclineApply)
	f11_arg0:close()
end

CoD.OptionsSettings.OpenDefaultPopup = function (f12_arg0, ClientInstance)
	local f12_local0 = f12_arg0:openMenu("SetDefaultPopup", ClientInstance.controller)
	f12_local0:registerEventHandler("confirm_action", CoD.OptionsSettings.DefaultPopup_RestoreDefaultSettings)
	f12_local0:registerEventHandler("decline_action", CoD.OptionsSettings.DefaultPopup_Decline)
	f12_arg0:close()
end

CoD.OptionsSettings.ApplyChanges = function ()
	CoD.Options.UpdateWindowPosition()
	Engine.SaveHardwareProfile()
	Engine.ApplyHardwareProfileSettings()
	if CoD.OptionsSettings.NeedPicmip then
		Engine.Exec(nil, "r_applyPicmip")
	end
	if CoD.OptionsSettings.NeedVidRestart then
		Engine.Exec(nil, "vid_restart")
	end
	if CoD.OptionsSettings.NeedSndRestart then
		Engine.Exec(nil, "snd_restart")
	end
	CoD.OptionsSettings.ResetRestartFlags()
end

CoD.OptionsSettings.ResetSoundToDefault = function (LocalClientIndex)
	Engine.SetProfileVar(LocalClientIndex, "snd_menu_voice", 1)
	Engine.SetProfileVar(LocalClientIndex, "snd_menu_music", 1)
	Engine.SetProfileVar(LocalClientIndex, "snd_menu_sfx", 1)
	Engine.SetProfileVar(LocalClientIndex, "snd_menu_master", 1)
	Engine.SetProfileVar(LocalClientIndex, "snd_shoutcast_game", 0.25)
	Engine.SetProfileVar(LocalClientIndex, "snd_shoutcast_voip", 1)
	Engine.SetProfileVar(LocalClientIndex, "snd_menu_headphones", 0)
	Engine.SetProfileVar(LocalClientIndex, "snd_menu_hearing_impaired", 0)
	Engine.SetProfileVar(LocalClientIndex, "snd_menu_presets", CoD.AudioSettings.TREYARCH_MIX)
end

CoD.OptionsSettings.ResetGameToDefault = function (LocalClientIndex)
	Engine.SetProfileVar(LocalClientIndex, "team_indicator", 0)
	Engine.SetProfileVar(LocalClientIndex, "colorblind_assist", 0)
	Engine.SetHardwareProfileValue("cg_drawLagometer", 0)
	Engine.SetProfileVar(LocalClientIndex, "safeAreaTweakable_vertical", 1)
	Engine.SetProfileVar(LocalClientIndex, "safeAreaTweakable_horizontal", 1)
	Engine.SetProfileVar(LocalClientIndex, "r_gamma", 0.9)
end

CoD.OptionsSettings.ResetDvars = function (LocalClientIndex)
	Engine.Exec(LocalClientIndex, "reset r_fullscreen")
	Engine.Exec(LocalClientIndex, "reset r_vsync")
	Engine.Exec(LocalClientIndex, "reset r_picmip_manual")
	Engine.Exec(LocalClientIndex, "reset r_dofHDR")
	Engine.Exec(LocalClientIndex, "reset cg_chatHeight")
	Engine.Exec(LocalClientIndex, "reset cg_fov_default")
	Engine.Exec(LocalClientIndex, "reset cg_fovscale")
	Engine.Exec(LocalClientIndex, "reset com_maxfps")
	Engine.Exec(LocalClientIndex, "reset cg_drawFPS")
	Engine.SetDvar("sd_xa2_device_name", 0)
	Engine.SetDvar("sd_xa2_device_guid", 0)
end

CoD.OptionsSettings.DefaultPopup_RestoreDefaultSettings = function (f17_arg0, ClientInstance)
	CoD.OptionsSettings.ResetDvars(ClientInstance.controller)
	Engine.ResetHardwareProfileSettings(ClientInstance.controller)
	Engine.Exec(ClientInstance.controller, "r_applyPicmip")
	Engine.Exec(ClientInstance.controller, "vid_restart")
	Engine.Exec(ClientInstance.controller, "snd_restart")
	CoD.OptionsSettings.ResetSoundToDefault(ClientInstance.controller)
	CoD.OptionsSettings.ResetGameToDefault(ClientInstance.controller)
	Engine.SaveHardwareProfile()
	f17_arg0:goBack(ClientInstance.controller)
end

CoD.OptionsSettings.Button_ApplyDvarChanged = function (Button)
	Engine.SetDvar(Button.parentSelectorButton.m_dvarName, Button.value)
end

CoD.OptionsSettings.DefaultPopup_Decline = function (f18_arg0, ClientInstance)
	CoD.OptionsSettings.DoNotSyncProfile = true
	f18_arg0:goBack(ClientInstance.controller)
end

CoD.OptionsSettings.RefreshMenu = function (OptionsMenuTab)
	Engine.SyncHardwareProfileWithDvars()
	OptionsMenuTab:dispatchEventToChildren({
		name = "refresh_choice"
	})
	local SelectorChoices = OptionsMenuTab.buttonList.m_selectors
	local SelectorChoicesTextureQuality = SelectorChoices.r_picmip
	if Engine.GetHardwareProfileValueAsString("r_picmip_manual") == "0" and SelectorChoicesTextureQuality ~= nil then
		SelectorChoicesTextureQuality:setChoice(-1)
	end
	local SelectorChoicesShadows = SelectorChoices.sm_spotQuality
	if Engine.GetHardwareProfileValueAsString("sm_enable") == "0" and SelectorChoicesShadows ~= nil then
		SelectorChoicesShadows:setChoice(-1)
	end
	local SelectorChoicesAntiAliasing = SelectorChoices.r_aaSamples
	if SelectorChoicesAntiAliasing ~= nil then
		CoD.OptionsSettings.AdjustAntiAliasingSettings(SelectorChoicesAntiAliasing)
	end
	local SelectorChoicesResolution = SelectorChoices.r_mode
	if SelectorChoicesResolution then
		CoD.OptionsSettings.Button_AddChoices_Resolution(SelectorChoicesResolution)
	end
	local FullscreenMode = Engine.GetHardwareProfileValueAsString("r_fullscreen")
	local SelectorChoicesMonitors = SelectorChoices.r_monitor
	local SelectorChoicesResolution = SelectorChoices.r_mode
	if SelectorChoicesMonitors and SelectorChoicesResolution then
		if FullscreenMode == "0" then
			SelectorChoicesMonitors:setChoice(0)
			SelectorChoicesMonitors:disableSelector()
			SelectorChoicesResolution:enableSelector()
		elseif FullscreenMode == "2" then
			SelectorChoicesMonitors:enableSelector()
			SelectorChoicesResolution:disableSelector()
		else
			SelectorChoicesMonitors:enableSelector()
			SelectorChoicesResolution:enableSelector()
		end
	end
end

CoD.OptionsSettings.DisableOptionsInGame = function (Options)
	for Key, GraphicsSetting in ipairs({
		"r_mode",
		"r_fullscreen",
		"r_monitor",
		"r_aaSamples",
		"r_texFilterQuality",
		"r_picmip"
	}) do
		if Options[GraphicsSetting] then
			Options[GraphicsSetting]:disableSelector()
		end
	end
end

CoD.OptionsSettings.Button_AddChoices_Resolution = function (DisplayResolutionChoices)
	local ResolutionChoices = nil
	DisplayResolutionChoices:clearChoices()
	if Dvar.r_fullscreen:get() == 0 then
		for Key, DisplayResolutionChoice in ipairs(Dvar.r_mode:getDomainEnumStrings()) do
			DisplayResolutionChoices:addChoice(DisplayResolutionChoice, DisplayResolutionChoice)
		end
	else
		local MonitorIndex = Engine.GetHardwareProfileValueAsString("r_monitor")
		if tonumber(MonitorIndex) > Dvar.r_monitorCount:get() then
			MonitorIndex = "0"
		end
		if MonitorIndex == "0" then
			ResolutionChoices = Dvar.r_mode:getDomainEnumStrings()
		else
			ResolutionChoices = Dvar["r_mode" .. MonitorIndex]:getDomainEnumStrings()
		end
		for Key, DisplayResolutionChoice in ipairs(ResolutionChoices) do
			DisplayResolutionChoices:addChoice(DisplayResolutionChoice, DisplayResolutionChoice)
		end
	end
end

CoD.OptionsSettings.Button_AddChoices_DisplayMode = function (DisplayModeChoices)
	DisplayModeChoices:addChoice(Engine.Localize("PLATFORM_WINDOWED"), 0)
	DisplayModeChoices:addChoice(Engine.Localize("MENU_FULLSCREEN"), 1)
	DisplayModeChoices:addChoice(Engine.Localize("PLATFORM_WINDOWED_FULLSCREEN"), 2)
end

CoD.OptionsSettings.AdjustAntiAliasingSettings = function (AntiAliasingChoices)
	local AASamples = Engine.GetHardwareProfileValueAsString("r_aaSamples")
	if Dvar.r_txaaSupported:get() == true and Engine.GetHardwareProfileValueAsString("r_txaa") == "1" then
		if AASamples == "2" then
			AntiAliasingChoices:setChoice(17)
		elseif AASamples == "4" then
			AntiAliasingChoices:setChoice(18)
		end
	else
		Engine.SetHardwareProfile("r_txaa", 0)
	end
end

CoD.OptionsSettings.AntiAliasingChangeCallback = function (AntiAliasingChosen, f24_arg1)
	if f24_arg1 ~= true then
		return 
	elseif AntiAliasingChosen.value <= 16 then
		Engine.SetHardwareProfileValue("r_aaSamples", AntiAliasingChosen.value)
		Engine.SetHardwareProfileValue("r_txaa", 0)
	elseif AntiAliasingChosen.value == 17 then
		Engine.SetHardwareProfileValue("r_aaSamples", 2)
		Engine.SetHardwareProfileValue("r_txaa", 1)
		Engine.SetHardwareProfileValue("r_fxaa", 0)
	elseif AntiAliasingChosen.value == 18 then
		Engine.SetHardwareProfileValue("r_aaSamples", 4)
		Engine.SetHardwareProfileValue("r_txaa", 1)
		Engine.SetHardwareProfileValue("r_fxaa", 0)
	else
		Engine.SetHardwareProfileValue("r_aaSamples", 1)
		Engine.SetHardwareProfileValue("r_txaa", 0)
		Engine.SetHardwareProfileValue("r_fxaa", 0)
	end
end

CoD.OptionsSettings.Button_AddChoices_AntiAliasing = function (AntiAliasingChoices)
	AntiAliasingChoices:addChoice(Engine.Localize("MENU_OFF_CAPS"), 1, nil, CoD.OptionsSettings.AntiAliasingChangeCallback)
	AntiAliasingChoices:addChoice(Engine.Localize("PLATFORM_2X_MSAA_CAPS"), 2, nil, CoD.OptionsSettings.AntiAliasingChangeCallback)
	AntiAliasingChoices:addChoice(Engine.Localize("PLATFORM_4X_MSAA_CAPS"), 4, nil, CoD.OptionsSettings.AntiAliasingChangeCallback)
	AntiAliasingChoices:addChoice(Engine.Localize("PLATFORM_8X_MSAA_CAPS"), 8, nil, CoD.OptionsSettings.AntiAliasingChangeCallback)
	if Dvar.r_txaaSupported:get() == true then
		AntiAliasingChoices:addChoice(Engine.Localize("PLATFORM_2X_TXAA_CAPS"), 17, nil, CoD.OptionsSettings.AntiAliasingChangeCallback)
		AntiAliasingChoices:addChoice(Engine.Localize("PLATFORM_4X_TXAA_CAPS"), 18, nil, CoD.OptionsSettings.AntiAliasingChangeCallback)
	end
end

CoD.OptionsSettings.Button_AddChoices_TextureFiltering = function (TextureFilteringChoices)
	TextureFilteringChoices:addChoice(Engine.Localize("PLATFORM_LOW_CAPS"), 0)
	TextureFilteringChoices:addChoice(Engine.Localize("PLATFORM_MEDIUM_CAPS"), 1)
	TextureFilteringChoices:addChoice(Engine.Localize("PLATFORM_HIGH_CAPS"), 2)
end

CoD.OptionsSettings.TextureQualitySelectionChangeCallback = function (TextureQualityChosen, f27_arg1)
	if f27_arg1 ~= true then
		return 
	elseif TextureQualityChosen.value == -1 then
		Engine.SetHardwareProfileValue("r_picmip_manual", 0)
	else
		Engine.SetHardwareProfileValue("r_picmip_manual", 1)
		Engine.SetHardwareProfileValue("r_picmip", TextureQualityChosen.value)
		Engine.SetHardwareProfileValue("r_picmip_bump", TextureQualityChosen.value)
		Engine.SetHardwareProfileValue("r_picmip_spec", TextureQualityChosen.value)
	end
end

CoD.OptionsSettings.Button_AddChoices_TextureQuality = function (TextureQualityChoices)
	TextureQualityChoices:addChoice(Engine.Localize("MENU_AUTOMATIC_CAPS"), -1, nil, CoD.OptionsSettings.TextureQualitySelectionChangeCallback)
	TextureQualityChoices:addChoice(Engine.Localize("PLATFORM_LOW_CAPS"), 3, nil, CoD.OptionsSettings.TextureQualitySelectionChangeCallback)
	TextureQualityChoices:addChoice(Engine.Localize("MENU_NORMAL_CAPS"), 2, nil, CoD.OptionsSettings.TextureQualitySelectionChangeCallback)
	TextureQualityChoices:addChoice(Engine.Localize("PLATFORM_HIGH_CAPS"), 1, nil, CoD.OptionsSettings.TextureQualitySelectionChangeCallback)
	TextureQualityChoices:addChoice(Engine.Localize("MENU_EXTRA_CAPS"), 0, nil, CoD.OptionsSettings.TextureQualitySelectionChangeCallback)
end

CoD.OptionsSettings.ShadowsChangeCallback = function (ShadowSettingChosen, f29_arg1)
	if f29_arg1 ~= true then
		return 
	elseif ShadowSettingChosen.value == -1 then
		Engine.SetHardwareProfileValue("sm_enable", 0)
		Engine.SetHardwareProfileValue("sm_spotQuality", 0)
		Engine.SetHardwareProfileValue("sm_sunQuality", 0)
	else
		Engine.SetHardwareProfileValue("sm_enable", 1)
		Engine.SetHardwareProfileValue("sm_spotQuality", ShadowSettingChosen.value)
		Engine.SetHardwareProfileValue("sm_sunQuality", ShadowSettingChosen.value)
	end
end

CoD.OptionsSettings.Button_AddChoices_Shadows = function (ShadowChoices)
	ShadowChoices:addChoice(Engine.Localize("MENU_OFF_CAPS"), -1, nil, CoD.OptionsSettings.ShadowsChangeCallback)
	ShadowChoices:addChoice(Engine.Localize("PLATFORM_LOW_CAPS"), 0, nil, CoD.OptionsSettings.ShadowsChangeCallback)
	ShadowChoices:addChoice(Engine.Localize("PLATFORM_MEDIUM_CAPS"), 1, nil, CoD.OptionsSettings.ShadowsChangeCallback)
	ShadowChoices:addChoice(Engine.Localize("PLATFORM_HIGH_CAPS"), 2, nil, CoD.OptionsSettings.ShadowsChangeCallback)
end

CoD.OptionsSettings.Button_PlayerNameIndicator_SelectionChanged = function (PlayerNameIndicatorChoice)
	Engine.SetProfileVar(PlayerNameIndicatorChoice.parentSelectorButton.m_currentController, PlayerNameIndicatorChoice.parentSelectorButton.m_profileVarName, PlayerNameIndicatorChoice.value)
	PlayerNameIndicatorChoice.parentSelectorButton.hintText = PlayerNameIndicatorChoice.extraParams.associatedHintText
	local f31_local0 = PlayerNameIndicatorChoice.parentSelectorButton:getParent()
	if f31_local0 ~= nil and f31_local0.hintText ~= nil then
		f31_local0.hintText:updateText(PlayerNameIndicatorChoice.parentSelectorButton.hintText)
	end
end

CoD.OptionsSettings.Button_AddChoices_PlayerNameIndicator = function (PlayerNameIndicatorChoices)
	PlayerNameIndicatorChoices:addChoice(Engine.Localize("PLATFORM_INDICATOR_FULL_CAPS"), 0, {
		associatedHintText = Engine.Localize("PLATFORM_INDICATOR_FULL_DESC")
	}, CoD.OptionsSettings.Button_PlayerNameIndicator_SelectionChanged)
	PlayerNameIndicatorChoices:addChoice(Engine.Localize("MENU_INDICATOR_ABBREVIATED_CAPS"), 1, {
		associatedHintText = Engine.Localize("PLATFORM_INDICATOR_ABBREVIATED_DESC")
	}, CoD.OptionsSettings.Button_PlayerNameIndicator_SelectionChanged)
	PlayerNameIndicatorChoices:addChoice(Engine.Localize("MENU_INDICATOR_ICON_CAPS"), 2, {
		associatedHintText = Engine.Localize("MENU_INDICATOR_ICON_DESC")
	}, CoD.OptionsSettings.Button_PlayerNameIndicator_SelectionChanged)
end

CoD.OptionsSettings.Button_AddChoices_ChatHeight = function (ChatHeightChoices)
	ChatHeightChoices:addChoice(Engine.Localize("MENU_SHOW_CAPS"), 8)
	ChatHeightChoices:addChoice(Engine.Localize("MENU_HIDE_CAPS"), 0)
end

CoD.OptionsSettings.Button_AddChoices_SoundDevices = function (SoundDeviceChoices)
	for Key, SoundDeviceFullName in ipairs(Dvar.sd_xa2_device_name:getDomainEnumStrings()) do
		local SoundDeviceOption = SoundDeviceFullName
		if string.len(SoundDeviceFullName) > 32 then
			SoundDeviceOption = string.sub(SoundDeviceFullName, 1, 32) .. "..."
		end
		SoundDeviceChoices:addChoice(SoundDeviceOption, SoundDeviceFullName)
	end
end

CoD.OptionsSettings.Button_AddChoices_Monitor = function (MonitorChoices)
	local MonitorCount = Dvar.r_monitorCount:get()
	for MonitorOption = 1, MonitorCount, 1 do
		MonitorChoices:addChoice(MonitorOption, MonitorOption)
	end
end

CoD.OptionsSettings.Button_AddChoices_MaxCorpses = function (MaxCorpsesChoices)
	MaxCorpsesChoices:addChoice(Engine.Localize("MENU_TINY"), 3)
	MaxCorpsesChoices:addChoice(Engine.Localize("MENU_SMALL"), 5)
	MaxCorpsesChoices:addChoice(Engine.Localize("MENU_MEDIUM"), 10)
	MaxCorpsesChoices:addChoice(Engine.Localize("MENU_LARGE"), 16)
end

CoD.OptionsSettings.DrawFPSCallback = function (FPSDisplayed, f37_arg1)
	if f37_arg1 ~= true then
		return 
	else
		Engine.SetDvar("cg_drawFPS", FPSDisplayed.value)
		Engine.SetHardwareProfileValue("cg_drawFPS", FPSDisplayed.value)
	end
end

CoD.OptionsSettings.Button_AddChoices_DrawFPS = function (DrawFPSToggle)
	DrawFPSToggle:addChoice(Engine.Localize("MENU_NO_CAPS"), "Off", nil, CoD.OptionsSettings.DrawFPSCallback)
	DrawFPSToggle:addChoice(Engine.Localize("MENU_YES_CAPS"), "Simple", nil, CoD.OptionsSettings.DrawFPSCallback)
end

CoD.OptionsSettings.StreamerModeCallback = function (StreamerModeEnabled, client)
	if client then
		Engine.SetHardwareProfileValue(StreamerModeEnabled.parentSelectorButton.m_profileVarName, StreamerModeEnabled.value)
		if StreamerModeEnabled.value == 1 then
			Dvar.cl_enableStreamerMode:set(true)
		else
			Dvar.cl_enableStreamerMode:set(false)
		end
	end
end

CoD.OptionsSettings.Button_AddChoices_StreamerMode = function (StreamerModeToggle)
	if UIExpression.DvarBool(nil, "cl_enableStreamerMode") == 0 then
		StreamerModeToggle:addChoice(Engine.Localize("MENU_DISABLED_CAPS"), 0, nil, CoD.OptionsSettings.StreamerModeCallback)
		StreamerModeToggle:addChoice(Engine.Localize("MENU_ENABLED_CAPS"), 1, nil, CoD.OptionsSettings.StreamerModeCallback)
	else
		StreamerModeToggle:addChoice(Engine.Localize("MENU_ENABLED_CAPS"), 1, nil, CoD.OptionsSettings.StreamerModeCallback)
		StreamerModeToggle:addChoice(Engine.Localize("MENU_DISABLED_CAPS"), 0, nil, CoD.OptionsSettings.StreamerModeCallback)
	end
end

CoD.OptionsSettings.VoiceChatCallback = function (VoiceValue, f37_arg1)
	if f37_arg1 ~= true then
		return 
	else
		Engine.SetDvar("cl_voice", VoiceValue.value)
		Engine.SetHardwareProfileValue("cl_voice", VoiceValue.value)
	end
end

CoD.OptionsSettings.Button_AddChoices_VoiceChat = function (DrawFPSToggle)
	DrawFPSToggle:addChoice(Engine.Localize("MENU_NO_CAPS"), "0", nil, CoD.OptionsSettings.VoiceChatCallback)
	DrawFPSToggle:addChoice(Engine.Localize("MENU_YES_CAPS"), "1", nil, CoD.OptionsSettings.VoiceChatCallback)
end

CoD.OptionsSettings.Button_AddChoices_DepthOfField = function (DOFChoices)
	DOFChoices:addChoice(Engine.Localize("PLATFORM_LOW_CAPS"), 0)
	DOFChoices:addChoice(Engine.Localize("PLATFORM_MEDIUM_CAPS"), 1)
	DOFChoices:addChoice(Engine.Localize("PLATFORM_HIGH_CAPS"), 2)
end

CoD.OptionsSettings.Button_AddChoices_MaxFPS = function (MaxFPSChoices)
	MaxFPSChoices:addChoice(Engine.Localize("MENU_UNLIMITED"), 0)
	MaxFPSChoices:addChoice("30", 30)
	MaxFPSChoices:addChoice("45", 45)
	MaxFPSChoices:addChoice("60", 60)
	MaxFPSChoices:addChoice("90", 90)
	MaxFPSChoices:addChoice("120", 120)
	MaxFPSChoices:addChoice("200", 200)
end

local SaveSliderChanges = function (f1_arg0, f1_arg1)
	Engine.SetDvar(f1_arg0.m_dvarName, f1_arg1)
	Engine.SetHardwareProfileValue(f1_arg0.m_dvarName, f1_arg1)
end

CoD.OptionsSettings.DvarLeftRightSlidernew = function (LocalClientIndex, f2_arg1, DvarName, f2_arg3, f2_arg4, f2_arg5, f2_arg6)
	local f2_local0 = tonumber(UIExpression.DvarString(nil, DvarName))
	local LeftRightSlider = CoD.LeftRightSlider.new(f2_arg1, f2_arg5, nil, f2_local0, f2_arg3, f2_arg4, f2_arg6)
	LeftRightSlider.m_dvarName = DvarName
	LeftRightSlider.m_currentValue = f2_local0
	LeftRightSlider.m_currentController = LocalClientIndex
	LeftRightSlider:setSliderCallback(SaveSliderChanges)
	return LeftRightSlider
end

CoD.OptionsSettings.AddDvarLeftRightSlider = function (ParentElement, LocalClientIndex, f19_arg2, DvarName, f19_arg4, f19_arg5, HintText, f19_arg7, f19_arg8)
	local CustomDvarLeftRightSlider = CoD.OptionsSettings.DvarLeftRightSlidernew(LocalClientIndex, f19_arg2, DvarName, f19_arg4, f19_arg5, f19_arg7, {
		leftAnchor = true,
		rightAnchor = true,
		left = 0,
		right = 0,
		topAnchor = true,
		bottomAnchor = false,
		top = 0,
		bottom = CoD.CoD9Button.Height
	})
	CustomDvarLeftRightSlider.hintText = HintText
	CustomDvarLeftRightSlider:setPriority(f19_arg8)
	ParentElement:addElement(CustomDvarLeftRightSlider)
	CoD.ButtonList.AssociateHintTextListenerToButton(CustomDvarLeftRightSlider)
	if ParentElement.buttonBackingAnimationState then
		CustomDvarLeftRightSlider:addBackground(ParentElement.buttonBackingAnimationState)
	end
	return CustomDvarLeftRightSlider
end

CoD.OptionsSettings.CreateGraphicsTab = function (GraphicsTab, LocalClientIndex)
	local GraphicsTabContainer = LUI.UIContainer.new()
	local GraphicsTabButtonList = CoD.Options.CreateButtonList()
	GraphicsTab.buttonList = GraphicsTabButtonList
	GraphicsTabContainer:addElement(GraphicsTabButtonList)
	
	local DisplayResolutionChoices = GraphicsTabButtonList:addHardwareProfileLeftRightSelector(Engine.Localize("PLATFORM_VIDEO_MODE_CAPS"), "r_mode", Engine.Localize("PLATFORM_VIDEO_MODE_DESC"))
	CoD.OptionsSettings.Button_AddChoices_Resolution(DisplayResolutionChoices)
	
	local DisplayModeChoices = GraphicsTabButtonList:addHardwareProfileLeftRightSelector(Engine.Localize("PLATFORM_DISPLAY_MODE_CAPS"), "r_fullscreen", Engine.Localize("PLATFORM_DISPLAY_MODE_DESC"))
	CoD.OptionsSettings.Button_AddChoices_DisplayMode(DisplayModeChoices)
	if DisplayModeChoices:getCurrentValue() == "2" then
		DisplayResolutionChoices:disableSelector()
	end
	
	local MonitorUsedChoices = GraphicsTabButtonList:addHardwareProfileLeftRightSelector(Engine.Localize("PLATFORM_MONITOR_CAPS"), "r_monitor", Engine.Localize("PLATFORM_MONITOR_DESC"))
	CoD.OptionsSettings.Button_AddChoices_Monitor(MonitorUsedChoices)
	if DisplayModeChoices:getCurrentValue() == "0" then
		MonitorUsedChoices:setChoice(0)
		MonitorUsedChoices:disableSelector()
	end
	GraphicsTabButtonList:addSpacer(CoD.CoD9Button.Height / 2)
	
	local BrightnessChoices = GraphicsTabButtonList:addButton(Engine.Localize("MENU_BRIGHTNESS_CAPS"), Engine.Localize("PLATFORM_BRIGHTNESS_DESC"))
	BrightnessChoices:setActionEventName("open_brightness")
	
	local FOVSlider = CoD.OptionsSettings.AddDvarLeftRightSlider(GraphicsTabButtonList, LocalClientIndex, Engine.Localize("PLATFORM_FIELD_OF_VIEW_CAPS"), "cg_fov_default", 65, 120, Engine.Localize("PLATFORM_FOV_DESC"))
	FOVSlider:setNumericDisplayFormatString("%d")
	
	local FOVScaleSlider = GraphicsTabButtonList:addDvarLeftRightSlider(LocalClientIndex, Engine.Localize("FOV SCALE"), "cg_fovscale", 0.5, 2, Engine.Localize("Scale applied to the field of view."))
	FOVScaleSlider:setNumericDisplayFormatString("%.2f")
	FOVScaleSlider:setRoundToFraction(0.05)
	FOVScaleSlider:setBarSpeed(0.01)
	
	local FOVSensitivity = GraphicsTabButtonList:addDvarLeftRightSelector(LocalClientIndex, Engine.Localize("FOV SENSITIVITY"), "cg_usefovsensitivity", Engine.Localize("When enabled, your sensitivity is scaled based on your fovScale"))
	FOVSensitivity:addChoice(LocalClientIndex, Engine.Localize("MENU_DISABLED_CAPS"), 0, nil, CoD.OptionsSettings.Button_ApplyDvarChanged)
	FOVSensitivity:addChoice(LocalClientIndex, Engine.Localize("MENU_ENABLED_CAPS"), 1, nil, CoD.OptionsSettings.Button_ApplyDvarChanged)
	
	GraphicsTabButtonList:addSpacer(CoD.CoD9Button.Height / 2)
	local ShadowChoices = GraphicsTabButtonList:addHardwareProfileLeftRightSelector(Engine.Localize("MENU_SHADOWS_CAPS"), "sm_spotQuality", Engine.Localize("PLATFORM_SHADOWS_DESC"))
	CoD.OptionsSettings.Button_AddChoices_Shadows(ShadowChoices)
	if Engine.GetHardwareProfileValueAsString("sm_enable") == "0" then
		ShadowChoices:setChoice(-1)
	end

	local f41_local9 = GraphicsTabButtonList:addProfileLeftRightSelector( LocalClientIndex, Engine.Localize( "MENU_MATURE_CAPS" ), "cg_mature", Engine.Localize( "MENU_MATURE_CONTENT_DESC" ) )
	CoD.Options.Button_AddChoices_EnabledOrDisabled( f41_local9 )
	f41_local9:disableCycling()
	f41_local9:registerEventHandler( "button_action", function ( element, event )
		element:dispatchEventToParent( {
			name = "open_mature_content",
			controller = event.controller
		} )
	end )

	CoD.Options.Button_AddChoices_EnabledOrDisabled(GraphicsTabButtonList:addHardwareProfileLeftRightSelector(Engine.Localize("PLATFORM_RAGDOLL_CAPS"), "ragdoll_enable", Engine.Localize("PLATFORM_RAGDOLL_DESC")))
	GraphicsTabButtonList:addSpacer(CoD.CoD9Button.Height / 2)
	CoD.OptionsSettings.Button_AddChoices_PlayerNameIndicator(GraphicsTabButtonList:addProfileLeftRightSelector(LocalClientIndex, Engine.Localize("MENU_TEAM_INDICATOR_CAPS"), "team_indicator", ""))
	CoD.Options.Button_AddChoices_OnOrOff(GraphicsTabButtonList:addProfileLeftRightSelector(LocalClientIndex, Engine.Localize("MENU_COLOR_BLIND_ASSIST_CAPS"), "colorblind_assist", Engine.Localize("MENU_COLOR_BLIND_ASSIST_DESC")))
	CoD.OptionsSettings.Button_AddChoices_ChatHeight(GraphicsTabButtonList:addHardwareProfileLeftRightSelector(Engine.Localize("PLATFORM_CHATMESSAGES_CAPS"), "cg_chatHeight", Engine.Localize("PLATFORM_CHATMESSAGES_DESC")))
	return GraphicsTabContainer
end

CoD.OptionsSettings.CreateAdvancedTab = function (AdvancedTab, LocalClientIndex)
	local AdvancedTabContainer = LUI.UIContainer.new()
	local InGame = UIExpression.IsInGame() == 1
	local AdvancedTabButtonList = CoD.Options.CreateButtonList()
	AdvancedTab.buttonList = AdvancedTabButtonList
	AdvancedTabContainer.buttonList = AdvancedTabButtonList
	AdvancedTabContainer:addElement(AdvancedTabButtonList)
	local TextureQualityChoices = AdvancedTabButtonList:addHardwareProfileLeftRightSelector(Engine.Localize("MENU_TEXTURE_QUALITY_CAPS"), "r_picmip", Engine.Localize("PLATFORM_TEXTURE_QUALITY_DESC"))
	CoD.OptionsSettings.Button_AddChoices_TextureQuality(TextureQualityChoices)
	if Engine.GetHardwareProfileValueAsString("r_picmip_manual") == "0" then
		TextureQualityChoices:setChoice(-1)
	end
	if InGame and CoD.isMultiplayer then
		TextureQualityChoices:disableSelector()
	end
	CoD.OptionsSettings.Button_AddChoices_TextureFiltering(AdvancedTabButtonList:addHardwareProfileLeftRightSelector(Engine.Localize("MENU_TEXTURE_MIPMAPS_CAPS"), "r_texFilterQuality", Engine.Localize("PLATFORM_TEXTURE_FILTERING_DESC")))
	local AntiAliasingChoices = AdvancedTabButtonList:addHardwareProfileLeftRightSelector(Engine.Localize("MENU_ANTIALIASING_CAPS"), "r_aaSamples", Engine.Localize("PLATFORM_ANTIALIASING_DESC"))
	CoD.OptionsSettings.Button_AddChoices_AntiAliasing(AntiAliasingChoices)
	CoD.OptionsSettings.AdjustAntiAliasingSettings(AntiAliasingChoices)
	CoD.Options.Button_AddChoices_YesOrNo(AdvancedTabButtonList:addHardwareProfileLeftRightSelector(Engine.Localize("PLATFORM_FXAA_CAPS"), "r_fxaa", Engine.Localize("PLATFORM_FXAA_DESC")))
	CoD.Options.Button_AddChoices_OnOrOff(AdvancedTabButtonList:addHardwareProfileLeftRightSelector(Engine.Localize("PLATFORM_AMBIENT_OCCLUSION_CAPS"), "r_ssao", Engine.Localize("PLATFORM_AMBIENT_OCCLUSION_DESC")))
	CoD.OptionsSettings.Button_AddChoices_DepthOfField(AdvancedTabButtonList:addHardwareProfileLeftRightSelector(Engine.Localize("PLATFORM_DEPTH_OF_FIELD_CAPS"), "r_dofHDR", Engine.Localize("PLATFORM_DEPTH_OF_FIELD_DESC")))
	AdvancedTabButtonList:addSpacer(CoD.CoD9Button.Height / 2)
	AdvancedTabButtonList:addSpacer(CoD.CoD9Button.Height / 2)
	CoD.Options.Button_AddChoices_YesOrNo(AdvancedTabButtonList:addHardwareProfileLeftRightSelector(Engine.Localize("MENU_SYNC_EVERY_FRAME_CAPS"), "r_vsync", Engine.Localize("PLATFORM_VSYNC_DESC")))
	local MaxFpsChoices = AdvancedTabButtonList:addHardwareProfileLeftRightSelector(Engine.Localize("PLATFORM_MAX_FPS_CAPS"), "com_maxfps", Engine.Localize("PLATFORM_MAX_FPS_DESC"))
	CoD.OptionsSettings.Button_AddChoices_MaxFPS(MaxFpsChoices)
	if Engine.GetHardwareProfileValueAsString("r_vsync") == "1" then
		MaxFpsChoices:setChoice(0)
		MaxFpsChoices:disableSelector()
	end
	CoD.OptionsSettings.Button_AddChoices_DrawFPS(AdvancedTabButtonList:addHardwareProfileLeftRightSelector(Engine.Localize("PLATFORM_DRAW_FPS_CAPS"), "cg_drawFPS", Engine.Localize("PLATFORM_DRAW_FPS_DESC")))
	AdvancedTabButtonList:addSpacer(CoD.CoD9Button.Height / 2)
	
	CoD.OptionsSettings.Button_AddChoices_StreamerMode(AdvancedTabButtonList:addHardwareProfileLeftRightSelector("STREAMER MODE", "cl_enableStreamerMode", "Hides important networking and player information"))
	AdvancedTabButtonList:addSpacer(CoD.CoD9Button.Height / 2)
	
	local SafeAreaButton = AdvancedTabButtonList:addButton(Engine.Localize("MENU_SAFE_AREA_ADJUSTMENT_CAPS"), Engine.Localize("Edit the HUD safearea."))
	SafeAreaButton:setActionEventName("open_safe_area")
	
	return AdvancedTabContainer
end

CoD.OptionsSettings.CreateSoundTab = function (SoundTab, LocalClientIndex)
	local SoundTabContainer = LUI.UIContainer.new()
	local InGame = UIExpression.IsInGame() == 1
	local SoundTabButtonList = CoD.Options.CreateButtonList()
	SoundTab.buttonList = SoundTabButtonList
	SoundTabContainer:addElement(SoundTabButtonList)
	local VoiceVolumeSlider = SoundTabButtonList:addProfileLeftRightSlider(LocalClientIndex, Engine.Localize("MENU_VOICE_VOLUME_CAPS"), "snd_menu_voice", 0, 1, Engine.Localize("MENU_VOICE_VOLUME_DESC"), nil, nil, CoD.Options.AdjustSFX)
	local MusicVolumeSlider = SoundTabButtonList:addProfileLeftRightSlider(LocalClientIndex, Engine.Localize("MENU_MUSIC_VOLUME_CAPS"), "snd_menu_music", 0, 1, Engine.Localize("MENU_MUSIC_VOLUME_DESC"), nil, nil, CoD.Options.AdjustSFX)
	local SFXVolumeSlider = SoundTabButtonList:addProfileLeftRightSlider(LocalClientIndex, Engine.Localize("MENU_SFX_VOLUME_CAPS"), "snd_menu_sfx", 0, 1, Engine.Localize("MENU_SFX_VOLUME_DESC"), nil, nil, CoD.Options.AdjustSFX)
	local MasterVolumeSlider = SoundTabButtonList:addProfileLeftRightSlider(LocalClientIndex, Engine.Localize("MENU_MASTER_VOLUME_CAPS"), "snd_menu_master", 0, 1, Engine.Localize("MENU_MASTER_VOLUME_DESC"), nil, nil, CoD.Options.AdjustSFX)
	local CodCasterVolumeSlider = SoundTabButtonList:addProfileLeftRightSlider(LocalClientIndex, Engine.Localize("MENU_SHOUTCAST_GAME_VOLUME_CAPS"), "snd_shoutcast_game", 0, 2, Engine.Localize("MENU_SHOUTCAST_GAME_VOLUME_DESC"), nil, nil, CoD.Options.AdjustSFX)
	local CodCasterVOIPVolumeSlider = SoundTabButtonList:addProfileLeftRightSlider(LocalClientIndex, Engine.Localize("MENU_SHOUTCAST_VOIP_VOLUME_CAPS"), "snd_shoutcast_voip", 0, 2, Engine.Localize("MENU_SHOUTCAST_VOIP_VOLUME_DESC"), nil, nil, CoD.Options.AdjustSFX)
	SoundTabButtonList:addSpacer(CoD.CoD9Button.Height / 2)
	CoD.Options.Button_AddChoices_OnOrOff(SoundTabButtonList:addProfileLeftRightSelector(LocalClientIndex, Engine.Localize("MENU_HEARING_IMPAIRED_CAPS"), "snd_menu_hearing_impaired", Engine.Localize("MENU_HEARING_IMPAIRED_DESC")))
	if UIExpression.DvarBool(nil, "sd_can_switch_device") == 0 then
	else
		local SoundDeviceChoices = SoundTabButtonList:addHardwareProfileLeftRightSelector(Engine.Localize("PLATFORM_SOUND_DEVICE_CAPS"), "sd_xa2_device_name")
		CoD.OptionsSettings.Button_AddChoices_SoundDevices(SoundDeviceChoices)
		if Dvar.sd_xa2_num_devices:get() <= 1 or InGame then
			SoundDeviceChoices:disableSelector()
		end
	end
	SoundTabButtonList:addSpacer(CoD.CoD9Button.Height / 2)
	CoD.AudioSettings.Button_AudioPresets_AddChoices(SoundTabButtonList:addProfileLeftRightSelector(LocalClientIndex, Engine.Localize("MENU_AUDIO_PRESETS_CAPS"), "snd_menu_presets", "", nil, nil, CoD.AudioSettings.CycleSFX))
	if UIExpression.IsInGame() == 0 and not (UIExpression.IsDemoPlaying(LocalClientIndex) ~= 0) then
		local SoundSystemTest = SoundTabButtonList:addButton(Engine.Localize("MENU_SYSTEM_TEST_CAPS"), Engine.Localize("MENU_SYSTEM_TEST_DESC"))
		SoundSystemTest:registerEventHandler("button_action", CoD.AudioSettings.Button_SystemTestButton)
	end
	return SoundTabContainer
end

CoD.OptionsSettings.CreateVoiceChatTab = function (f44_arg0, f44_arg1)
	local f44_local0 = LUI.UIContainer.new()
	local f44_local1 = CoD.Options.CreateButtonList()
	f44_arg0.buttonList = f44_local1
	f44_local0:addElement(f44_local1)
	CoD.OptionsSettings.Button_AddChoices_VoiceChat(f44_local1:addHardwareProfileLeftRightSelector(Engine.Localize("MENU_VOICECHAT_CAPS"), "cl_voice", Engine.Localize("PLATFORM_VOICECHAT_DESC")))
	f44_local1:addSpacer(CoD.CoD9Button.Height / 2)
	local f44_local2 = f44_local1:addProfileLeftRightSlider(f44_arg1, Engine.Localize("PLATFORM_VOICECHAT_VOLUME"), "snd_voicechat_volume", 0, 1, Engine.Localize("PLATFORM_VOICECHAT_VOLUME_DESC"), nil, nil, CoD.Options.AdjustSFX)
	local f44_local3 = f44_local1:addProfileLeftRightSlider(f44_arg1, Engine.Localize("PLATFORM_VOICECHAT_RECORD_LEVEL"), "snd_voicechat_record_level", 0, 1, Engine.Localize("PLATFORM_VOICECHAT_RECORD_LEVEL_DESC"), nil, nil, CoD.Options.AdjustSFX)
	f44_local1:addSpacer(CoD.CoD9Button.Height / 2)
	local f44_local4 = f44_local1:addVoiceMeter(Engine.Localize("MENU_VOICECHAT_LEVEL_INDICATOR_CAPS"), Engine.Localize("PLATFORM_VOICEMETER_DESC"))
	return f44_local0
end

-- ============================================================================
--  zm_qol - THE "QUALITY OF LIFE" TAB.                            (v1.94.0)
--
--  User, 2026-08-14, on the v1.93.0 attempt: "the placement for the game menu
--  itself is wrong, it should be the furthest right, after voice chat... the
--  menu navigation arrows are bugged and colliding with text... rename the Game
--  tab to Quality Of Life and then add some toggable options in that menu
--  itself so when people now use my mod they don't need to rely on chat
--  commands which get annoying."
--
--  🛑 THE ARROW BUG WAS THE TAB POSITION, NOT THE ARROWS. Registering our tab
--  FIRST shifted every stock tab one place right, and the tab manager lays its
--  left/right arrows out from the ORIGINAL extents - so the left arrow landed
--  off the strip and the right one printed over "VOICE CHAT". Registered last,
--  the strip is stock's plus one on the end and both arrows sit correctly.
--
--  🌟 EVERY DVAR BELOW WAS READ OUT OF A LIVE DVAR DUMP OR THE MOD'S OWN
--  REGISTRATION LIST - none is guessed:
--     cl_allowDownload, cg_drawIdentifier, cg_flashScriptHashes, cg_holdToSprint
--         from console_zm.log's dvar dump
--     r_fog, r_dof_enable
--         the two the mod's own .fog command and night mode already write
--     night_mode, hud_master, hud_timer, hud_round_timer, hud_health_bar,
--     hud_remaining, hud_zone, rapid_fire, no_power, lod_fix
--         from qol_options.gsc's qol_opt_dvar() table
--     velocity, fly
--         from quality_of_life.gsc
--     god, ghost, infinite_ammo, infinite_sprint
--         added in v1.94.0 by zmqol_toggle_dvar_watch() for exactly this menu
--
--  📝 "REDUCE ENGINE SLEEPS" IS DELIBERATELY ABSENT. It is in the stock
--  Plutonium GAME tab the user screenshotted, but no dvar of that name exists
--  in this build's dump and inventing one would be a guess. The other three
--  standard entries are all here.
--
--  📝 PERMA-PERKS ARE NOT HERE EITHER - this mod has no perma-perk system at
--  all (zero matches in the whole tree), so there is nothing to toggle.
--
--  🛑 DESCRIPTIONS ARE SHORT ON PURPOSE. The v1.93.0 text ran off the right
--  edge of the screen; the hint line does not wrap.
--
--  🛑 NO CUSTOM APPLY CALLBACK. v1.93.0 passed
--  CoD.OptionsSettings.Button_ApplyDvarChanged as the 5th argument, which
--  REPLACES the widget's own DvarSelectorSetDvarFunc - and "hold to sprint"
--  then would not turn back off. Passing nil uses Plutonium's default handler,
--  the same one optionscontrols.lua uses for cl_freelook and m_pitch, which are
--  known to work both ways.
-- ============================================================================
CoD.OptionsSettings.QolToggle = function (ButtonList, LocalClientIndex, Label, DvarName, Description)
	local Selector = ButtonList:addDvarLeftRightSelector(LocalClientIndex, Engine.Localize(Label), DvarName, Engine.Localize(Description))
	Selector:addChoice(LocalClientIndex, Engine.Localize("MENU_DISABLED_CAPS"), 0)
	Selector:addChoice(LocalClientIndex, Engine.Localize("MENU_ENABLED_CAPS"), 1)
	return Selector
end

-- ============================================================================
--  🛑 v1.95.0 - THE LIST IS SPLIT ACROSS TWO TABS BECAUSE 22 ROWS DO NOT FIT.
--
--  User, 2026-08-14: "The Esc back at the bottom left doesn't account for all
--  the options in the list for this menu, and it collides with some of the
--  options in the list, and the header groups... also collide with the menu
--  options."
--
--  🌟 THE BUDGET IS MEASURED OFF A TAB THAT IS KNOWN TO RENDER CORRECTLY.
--  Stock's GRAPHICS tab in this same file is 13 rows + 3 half-height spacers =
--  14.5 row-pitches and it lays out cleanly, hint line and ESC prompt included.
--  The v1.94.0 QUALITY OF LIFE tab was 22 rows + 3 spacers = 23.5 pitches, 62%
--  over that, and CoD.ButtonList does not clip or scroll - it simply draws
--  past both ends of its container, over the tab strip above and the ESC
--  prompt below. That is the whole of the reported "scuffed-ness".
--
--  The three tabs below are 9.5, 11 and 7 pitches, all inside the proven 14.5.
--  🛑 IF YOU ADD A ROW, ADD IT TO THE SHORTEST TAB IT HONESTLY BELONGS IN, and
--  never take any tab past 14.5 pitches (a spacer counts as 0.5).
--
-- ============================================================================
--  🌟 v1.96.0 - THREE TABS: GAME / HUD / CHEATS, SORTED BY WHAT EACH ROW DOES.
--
--  User, 2026-08-16: *"add another tab in the pause menu options called CHEATS
--  after the HUD section, and move any cheat options like godmode, fly, ghost,
--  infinite sprint, infinite ammo, etc. to that tab to make room for other
--  future options in the GAME tab, and also make sure that any added toggable
--  options are in the correct relevant tab, so HUD would contain all hud element
--  toggles and so on."*
--
--  So the rule for this file is now: HUD holds things that draw on the HUD.
--  CHEATS holds things that change the rules in the player's favour. GAME holds
--  everything else - client/session options, world rendering, startup.
--
--  That moved the four RENDERING rows (night mode, fog, depth of field, model
--  detail fix) OUT of HUD, where they never belonged: none of them is a HUD
--  element, they are r_* / visionset settings applied to the world.
--
--  🛑 HOLD TO SPRINT IS REMOVED AND IT IS NOT MOVED TO CONTROLS. Same message:
--  *"in the game tab remove the hold to sprint option as this was never even in
--  the regular GAME tab without the mod to begin with, or just move it to
--  controls instead if that option didn't already exist."*
--
--  It cannot go to CONTROLS, and the reason is a bug this project already paid
--  for. Stock BO2's controls menu has no hold-to-sprint row at all - verified
--  directly against the retail decompile now sitting at
--  storage\t6\raw\ui\t6\menus\optionscontrols.lua.aside, whose five tabs (LOOK /
--  MOVE / COMBAT / INTERACT / GAMEPAD) contain only the "+sprint" key BIND. So
--  adding the row means this mod shipping its own optionscontrols.lua, and that
--  file would then SHADOW Plutonium's patched one exactly the way the .aside
--  copy did - which is what deleted RAW INPUT, MOUSE ACCELERATION and FIX HIGH
--  POLL RATE LAG from the user's CONTROLS menu in the first place
--  (.agents/checkpoint_48.md §4). Trading three working Plutonium rows for one
--  new row is a straight loss, so the row is simply gone.
--
--  The dvar itself is untouched and still works from the console:
--  `cg_holdToSprint 1`.
-- ============================================================================
CoD.OptionsSettings.CreateQolTab = function (QolTab, LocalClientIndex)
	local QolContainer = LUI.UIContainer.new()
	local QolButtons = CoD.Options.CreateButtonList()
	QolTab.buttonList = QolButtons
	QolContainer:addElement(QolButtons)

	local T = CoD.OptionsSettings.QolToggle

	-- The standard Plutonium game options.                            3 rows
	T(QolButtons, LocalClientIndex, "ALLOW DOWNLOADING",  "cl_allowDownload",     "Allow downloading mods from a server.")
	T(QolButtons, LocalClientIndex, "DRAW IDENTIFIER",    "cg_drawIdentifier",    "Session watermark at the top of the screen.")
	T(QolButtons, LocalClientIndex, "FLASH SCRIPT HASHES","cg_flashScriptHashes", "Flash script hashes on screen.")

	QolButtons:addSpacer(CoD.CoD9Button.Height / 2)

	-- World rendering. Not HUD - these change how the map is drawn.   4 rows
	T(QolButtons, LocalClientIndex, "NIGHT MODE",         "night_mode",           "Darker, moodier lighting.")
	T(QolButtons, LocalClientIndex, "FOG",                "r_fog",                "World fog. Off shows the map edge.")
	T(QolButtons, LocalClientIndex, "DEPTH OF FIELD",     "r_dof_enable",         "Blur at distance. Off is fully off.")
	T(QolButtons, LocalClientIndex, "MODEL DETAIL FIX",   "lod_fix",              "Stops distant models popping in.")

	QolButtons:addSpacer(CoD.CoD9Button.Height / 2)

	-- Startup.                                                        1 row
	T(QolButtons, LocalClientIndex, "INTRO CREDITS",      "intro_credits",        "Mod name and credits at match start.")

	return QolContainer                                             -- 9.5 total
end

CoD.OptionsSettings.CreateQolHudTab = function (QolHudTab, LocalClientIndex)
	local QolHudContainer = LUI.UIContainer.new()
	local QolHudButtons = CoD.Options.CreateButtonList()
	QolHudTab.buttonList = QolHudButtons
	QolHudContainer:addElement(QolHudButtons)

	local T = CoD.OptionsSettings.QolToggle

	-- HUD elements, and nothing else.                                12 rows
	T(QolHudButtons, LocalClientIndex, "HUD",               "hud_master",     "Master switch for the whole HUD.")
	T(QolHudButtons, LocalClientIndex, "HITMARKERS",        "hitmarkers",     "Hit and kill markers on your crosshair.")
	T(QolHudButtons, LocalClientIndex, "ROUND SUMMARY",     "round_summary",  "Stats pop-up after each round.")
	-- v1.98.0, user request 2026-08-16.
	T(QolHudButtons, LocalClientIndex, "PERK POP-UP",       "hud_perk_popup", "Icon and name shown when you buy a perk.")
	-- v1.99.0, user request 2026-08-16.
	T(QolHudButtons, LocalClientIndex, "POWER-UP TIMERS",   "hud_powerup_timers", "Seconds left under each power-up icon.")
	T(QolHudButtons, LocalClientIndex, "GAME TIMER",        "hud_timer",      "Time since the match started.")
	T(QolHudButtons, LocalClientIndex, "ROUND TIMER",       "hud_round_timer","Time since this round started.")
	T(QolHudButtons, LocalClientIndex, "HEALTH BAR",        "hud_health_bar", "Your health bar, bottom left.")
	-- v1.99.1, user request 2026-08-16. Belongs in HUD despite HUD being the
	-- longest tab: it draws a progress bar and a text line on the HUD, so the
	-- file's own sorting rule puts it here. 12 pitches, inside the proven 14.5.
	T(QolHudButtons, LocalClientIndex, "BLEEDOUT BAR",      "hud_bleedout_bar", "Countdown bar shown while you are downed.")
	T(QolHudButtons, LocalClientIndex, "ZOMBIES REMAINING", "hud_remaining",  "How many zombies are left.")
	T(QolHudButtons, LocalClientIndex, "ZONE NAME",         "hud_zone",       "Name of the area you are in.")
	T(QolHudButtons, LocalClientIndex, "VELOCITY METER",    "velocity",       "Your speed. Green, yellow, red.")

	return QolHudContainer                                          -- 11 total
end

CoD.OptionsSettings.CreateQolCheatsTab = function (QolCheatsTab, LocalClientIndex)
	local QolCheatsContainer = LUI.UIContainer.new()
	local QolCheatsButtons = CoD.Options.CreateButtonList()
	QolCheatsTab.buttonList = QolCheatsButtons
	QolCheatsContainer:addElement(QolCheatsButtons)

	local T = CoD.OptionsSettings.QolToggle

	-- 🛑 godmode / ghostmode, NOT god / ghost. Those two names belong to the
	-- mod's CHAT-COMMAND dvar channel, which blanks them the moment they are
	-- written - so the v1.94.0 rows switched themselves straight back off. See
	-- the long note in zmqol_toggle_dvar_watch() in quality_of_life.gsc.
	--                                                                 7 rows
	T(QolCheatsButtons, LocalClientIndex, "GOD MODE",        "godmode",        "You cannot be damaged.")
	T(QolCheatsButtons, LocalClientIndex, "GHOST",           "ghostmode",      "Zombies ignore you.")
	T(QolCheatsButtons, LocalClientIndex, "INFINITE AMMO",   "infinite_ammo",  "Never run out of ammo.")
	T(QolCheatsButtons, LocalClientIndex, "INFINITE SPRINT", "infinite_sprint","Sprint without tiring.")
	T(QolCheatsButtons, LocalClientIndex, "FLY MODE",        "fly",            "Noclip. Melee to stop.")
	T(QolCheatsButtons, LocalClientIndex, "RAPID FIRE",      "rapid_fire",     "Faster firing on every weapon.")
	T(QolCheatsButtons, LocalClientIndex, "NO POWER NEEDED", "no_power",       "Perks and doors work without power.")

	return QolCheatsContainer                                       -- 7 total
end

LUI.createMenu.OptionsSettingsMenu = function (LocalClientIndex)
	local OptionsSettingsWidget = nil
	local InGame = UIExpression.IsInGame() == 1
	-- ========================================================================
	--  zm_qol v1.95.1 - THE HEADING READS "QUALITY OF LIFE" AND IS CENTRED.
	--  User, 2026-08-14: "move where it says settings on the top left in the
	--  pause menu to where the arrow faces, which is centered, and rename it
	--  from SETTINGS to QUALITY OF LIFE."
	--
	--  🛑 THE IN-GAME PATH CANNOT PASS AN ALIGNMENT. CoD.InGameMenu.New(name,
	--  controller, title) calls addTitle(title) with ONE argument, and
	--  CoD.Menu.addTitle(text, alignment) defaults to LUI.Alignment.Left - which
	--  is why the heading sits top-left in game and centred out of game (the
	--  else-branch below has always passed Center).
	--
	--  🌟 READ OUT OF THE SHIPPED BYTECODE, NOT GUESSED. The constant table of
	--  BO2-Raw-files\ui\t6\codmenu.lua shows addTitle building
	--      self.titleElement = LUI.UIText.new() ... :setAlignment( <alignment> )
	--  and a sibling setTitle() that writes through the same handle. So
	--  titleElement is the real field name and setAlignment is the real method;
	--  re-aligning after construction is the supported route, not a second
	--  addTitle call that would stack two heading elements.
	--
	--  Guarded anyway: an unexpected nil here would hard-crash LUI, and a
	--  left-aligned heading is a cosmetic loss, not a broken menu.
	-- ========================================================================
	local ZmQolMenuTitle = Engine.Localize("QUALITY OF LIFE")
	if InGame then
		OptionsSettingsWidget = CoD.InGameMenu.New("OptionsSettingsMenu", LocalClientIndex, ZmQolMenuTitle)
		if OptionsSettingsWidget.titleElement then
			OptionsSettingsWidget.titleElement:setAlignment(LUI.Alignment.Center)
		end
	else
		OptionsSettingsWidget = CoD.Menu.New("OptionsSettingsMenu")
		OptionsSettingsWidget:addTitle(ZmQolMenuTitle, LUI.Alignment.Center)
		OptionsSettingsWidget:addLargePopupBackground()
	end
	OptionsSettingsWidget.addApplyPrompt = CoD.Options.AddApplyPrompt
	OptionsSettingsWidget.addResetPrompt = CoD.Options.AddResetPrompt
	OptionsSettingsWidget:setPreviousMenu("OptionsMenu")
	OptionsSettingsWidget:setOwner(LocalClientIndex)
	OptionsSettingsWidget:registerEventHandler("add_apply_prompt", CoD.Options.AddApplyPrompt)
	OptionsSettingsWidget:registerEventHandler("button_prompt_back", CoD.OptionsSettings.Back)
	OptionsSettingsWidget:registerEventHandler("tab_changed", CoD.OptionsSettings.TabChanged)
	OptionsSettingsWidget:registerEventHandler("selector_changed", CoD.OptionsSettings.SelectorChanged)
	OptionsSettingsWidget:registerEventHandler("resolution_changed", CoD.OptionsSettings.ResolutionChanged)
	OptionsSettingsWidget:registerEventHandler("apply_changes", CoD.OptionsSettings.ApplyChanges)
	OptionsSettingsWidget:registerEventHandler("restore_default_settings", CoD.OptionsSettings.RestoreDefaultSettings)
	OptionsSettingsWidget:registerEventHandler("open_brightness", CoD.OptionsSettings.OpenBrightness)
	OptionsSettingsWidget:registerEventHandler( "open_mature_content", CoD.OptionsSettings.OpenMatureContent )
	OptionsSettingsWidget:registerEventHandler("open_speaker_setup", CoD.AudioSettings.OpenSpeakerSetup)
	OptionsSettingsWidget:registerEventHandler("open_apply_popup", CoD.OptionsSettings.OpenApplyPopup)
	OptionsSettingsWidget:registerEventHandler("open_default_popup", CoD.OptionsSettings.OpenDefaultPopup)
	OptionsSettingsWidget:registerEventHandler("open_safe_area", CoD.OptionsSettings.OpenSafeArea)
	OptionsSettingsWidget:addSelectButton()
	OptionsSettingsWidget:addBackButton()
	if not InGame then
		OptionsSettingsWidget:addResetPrompt()
	end
	if CoD.OptionsSettings.NeedVidRestart or CoD.OptionsSettings.NeedPicmip or CoD.OptionsSettings.NeedSndRestart then
		OptionsSettingsWidget:addApplyPrompt()
	end
	if not CoD.OptionsSettings.DoNotSyncProfile then
		Engine.SyncHardwareProfileWithDvars()
	end
	CoD.OptionsSettings.DoNotSyncProfile = nil
	-- zm_qol v1.95.1 - 800 -> 700, because the tabs were renamed GAME and HUD.
	-- v1.95.0 raised stock's 500 to 800; THAT is what pulled the arrows off the
	-- text in the first place.
	--
	-- CoD.Options.SetupTabManager(widget, HorizontalOffset) does
	--     GenericTabManager:setLeftRight(false, false, -HorizontalOffset/2, HorizontalOffset/2)
	-- so the number is the TOTAL WIDTH of the tab strip container, centred, and
	-- the left/right arrows are drawn at its two edges. The tabs themselves are
	-- centre-aligned inside it and their width does not depend on it - so a
	-- container narrower than the labels puts both arrows on top of the text,
	-- which is exactly the screenshot: left arrow over "GRAPHICS", right arrow
	-- over "QUALITY OF LIFE". 500 was stock's value for FOUR tabs.
	--
	-- 🌟 MEASURED, NOT GUESSED. Scanned the user's 2000x1125 screenshot for the
	-- five label runs in the tab band (LUI is 1280x720, so exactly 1.5625 px per
	-- unit):
	--     GRAPHICS 536..645   ADVANCED 727..841   SOUND 924..997
	--     VOICE CHAT 1078..1207   QUALITY OF LIFE 1289..1465
	-- Five labels span 929 px = 595 units; stock's four span 675 px = 432 units
	-- inside the 500 container, i.e. stock leaves ~34 units of margin per side.
	-- The six labels are now GRAPHICS ADVANCED SOUND VOICE CHAT GAME HUD, and
	-- the two short names make the strip NARROWER than the five-tab version:
	-- 527 px of glyphs plus five 82 px gaps = 937 px = 600 units. 600 + 68 = 668
	-- is the minimum, so 700 leaves ~32 px of margin per side - stock's is 31.
	-- 800 would now leave 82 px per side and push the arrows visibly away from
	-- the text, which is the opposite of what was asked for.
	--
	-- 🌟 700 is also BO2-Reimagined's shipped value for a six-tab settings strip
	-- labelled GRAPHICS ADVANCED SOUND VOICE CHAT GAME MOD - the same label set
	-- to within one three-letter word (its ui/t6/options.lua, line 661).
	--
	-- 🌟 v1.96.0 - 700 -> 800, BECAUSE A SEVENTH TAB WAS ADDED (CHEATS), and the
	-- number is re-derived from the SAME pixel measurements rather than nudged.
	-- From the scan above: the inter-label gap is a constant 82 px, and the
	-- measured labels average ~14 px per capital glyph (GRAPHICS 109/8,
	-- ADVANCED 114/8, SOUND 73/5). CHEATS is 6 glyphs, so ~84 px, and it costs
	-- one extra gap as well:
	--     six tabs   937 px  = 600 units   (measured, v1.95.1)
	--     + 82 gap + 84 glyphs  ->  1103 px = 706 units
	-- Stock leaves ~34 units of margin per side, so the minimum here is
	-- 706 + 68 = 774. 800 leaves 47 units (73 px) per side.
	--
	-- 🛑 THE ERROR IS DELIBERATELY BIASED WIDE. Too narrow is the REPORTED bug -
	-- the arrows draw on top of the labels (v1.93.0/v1.95.0). Too wide only
	-- pushes the arrows a little further out, which nobody has ever reported.
	-- CHEATS's width is the one estimated quantity here, so the margin absorbs it.
	local SettingsTabs = CoD.Options.SetupTabManager(OptionsSettingsWidget, 800)
	SettingsTabs:addTab(LocalClientIndex, "MENU_GRAPHICS_CAPS", CoD.OptionsSettings.CreateGraphicsTab)
	SettingsTabs:addTab(LocalClientIndex, "MENU_ADVANCED_CAPS", CoD.OptionsSettings.CreateAdvancedTab)
	SettingsTabs:addTab(LocalClientIndex, "MENU_SOUND_CAPS", CoD.OptionsSettings.CreateSoundTab)
	SettingsTabs:addTab(LocalClientIndex, "MENU_VOICECHAT_CAPS", CoD.OptionsSettings.CreateVoiceChatTab)
	-- zm_qol: LAST, after VOICE CHAT. Registering it first is what broke the
	-- navigation arrows in v1.93.0 - see the note above CreateQolTab.
	-- Engine.Localize falls back to the literal when a key does not exist, which
	-- is how this renders as "QUALITY OF LIFE" with no new localize entry;
	-- Plutonium's own line for FOV SENSITIVITY relies on the same behaviour.
	SettingsTabs:addTab(LocalClientIndex, "GAME", CoD.OptionsSettings.CreateQolTab)
	-- v1.95.1 - the visuals and HUD half, named "HUD" at the user's request
	-- (2026-08-14), with the first tab renamed back to "GAME". Split so neither
	-- tab overflows - see the note above CreateQolTab.
	SettingsTabs:addTab(LocalClientIndex, "HUD", CoD.OptionsSettings.CreateQolHudTab)
	-- v1.96.0 - CHEATS, last, immediately after HUD as asked.
	SettingsTabs:addTab(LocalClientIndex, "CHEATS", CoD.OptionsSettings.CreateQolCheatsTab)
	if CoD.OptionsSettings.CurrentTabIndex then
		SettingsTabs:loadTab(LocalClientIndex, CoD.OptionsSettings.CurrentTabIndex)
	else
		SettingsTabs:refreshTab(LocalClientIndex)
	end
	return OptionsSettingsWidget
end

CoD.OptionsSettings.OpenSafeArea = function (OptionsSettingsWidget, ClientInstance)
	OptionsSettingsWidget:saveState()
	OptionsSettingsWidget:openMenu("SafeArea", ClientInstance.controller)
	OptionsSettingsWidget:close()
end
