--[[
-------------------------------------------------------------------------------
-- FlowersSheLikes, by Ayantir
-------------------------------------------------------------------------------
This software is under : CreativeCommons CC BY-NC-SA 4.0
Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)

You are free to:

    Share — copy and redistribute the material in any medium or format
    Adapt — remix, transform, and build upon the material
    The licensor cannot revoke these freedoms as long as you follow the license terms.


Under the following terms:

    Attribution — You must give appropriate credit, provide a link to the license, and indicate if changes were made. You may do so in any reasonable manner, but not in any way that suggests the licensor endorses you or your use.
    NonCommercial — You may not use the material for commercial purposes.
    ShareAlike — If you remix, transform, or build upon the material, you must distribute your contributions under the same license as the original.
    No additional restrictions — You may not apply legal terms or technological measures that legally restrict others from doing anything the license permits.


Please read full licence at : 
http://creativecommons.org/licenses/by-nc-sa/4.0/legalcode
]]

-- Init
local ADDON_NAME = "FlowersSheLikes"
local ADDON_AUTHOR = "Ayantir"
local ADDON_VERSION = "11"
local ADDON_WEBSITE = "http://www.esoui.com/downloads/info933-FlowersSheLikes.html"

local db
local defaults = {
	likedColor = {["r"] = 0, ["g"] = 1, ["b"] = 0, ["a"] = 1},
	whyNotColor = {["r"] = 0.192, ["g"] = 0.549, ["b"] = 0.905, ["a"] = 1},
}

-- Rewrite of a core function \esoui\ingame\reticle\reticle.lua
function ZO_Reticle:TryHandlingInteraction(interactionPossible, currentFrameTimeSeconds)
	if interactionPossible then
		local action, interactableName, interactionBlocked, isOwned, additionalInteractInfo, context, contextLink, isCriminalInteract = GetGameCameraInteractableActionInfo()
		local interactKeybindButtonColor = ZO_NORMAL_TEXT
		local additionalInfoLabelColor = ZO_CONTRAST_TEXT
		self.interactKeybindButton:ShowKeyIcon()

		if action and interactableName then
			if isOwned or isCriminalInteract then
				interactKeybindButtonColor = ZO_ERROR_COLOR
			end

			if additionalInteractInfo == ADDITIONAL_INTERACT_INFO_NONE or additionalInteractInfo == ADDITIONAL_INTERACT_INFO_INSTANCE_TYPE then
				self.interactKeybindButton:SetText(zo_strformat(SI_GAME_CAMERA_TARGET, action))
			elseif additionalInteractInfo == ADDITIONAL_INTERACT_INFO_EMPTY then
				self.interactKeybindButton:SetText(zo_strformat(SI_FORMAT_BULLET_TEXT, GetString(SI_GAME_CAMERA_ACTION_EMPTY)))
				self.interactKeybindButton:HideKeyIcon()
			elseif additionalInteractInfo == ADDITIONAL_INTERACT_INFO_LOCKED then
				self.interactKeybindButton:SetText(zo_strformat(SI_GAME_CAMERA_TARGET_ADDITIONAL_INFO, action, GetString("SI_LOCKQUALITY", context)))
			elseif additionalInteractInfo == ADDITIONAL_INTERACT_INFO_FISHING_NODE then
				self.additionalInfo:SetHidden(false)
				self.additionalInfo:SetText(GetString(SI_HOLD_TO_SELECT_BAIT))
				local lure = GetFishingLure()
				if lure then
					local name = GetFishingLureInfo(lure)
					self.interactKeybindButton:SetText(zo_strformat(SI_GAME_CAMERA_TARGET_ADDITIONAL_INFO_BAIT, action, name))
				else
					self.interactKeybindButton:SetText(zo_strformat(SI_GAME_CAMERA_TARGET_ADDITIONAL_INFO, action, GetString(SI_NO_BAIT_OR_LURE_SELECTED)))
				end
			elseif additionalInteractInfo == ADDITIONAL_INTERACT_INFO_REQUIRES_KEY then
				local itemName = GetItemLinkName(contextLink)
				if interactionBlocked == true then
					self.interactKeybindButton:SetText(zo_strformat(SI_GAME_CAMERA_TARGET_ADDITIONAL_INFO_REQUIRES_KEY, action, itemName))
				else
					self.interactKeybindButton:SetText(zo_strformat(SI_GAME_CAMERA_TARGET_ADDITIONAL_INFO_WILL_CONSUME_KEY, action, itemName))
				end
			elseif additionalInteractInfo == ADDITIONAL_INTERACT_INFO_PICKPOCKET_CHANCE then
				local isHostile, difficulty, isEmpty, prospectiveResult, monsterSocialClassString, monsterSocialClass
				self.isInBonus, isHostile, self.percentChance, difficulty, isEmpty, prospectiveResult, monsterSocialClassString, monsterSocialClass = GetGameCameraPickpocketingBonusInfo()

				-- Prevent your success chance from going over 100%
				self.percentChance = zo_min(self.percentChance, 100)

				local additionalInfoText
				if(isEmpty and prospectiveResult == PROSPECTIVE_PICKPOCKET_RESULT_INVENTORY_FULL) then
					additionalInfoText = GetString(SI_JUSTICE_PICKPOCKET_TARGET_EMPTY)
				elseif prospectiveResult ~= PROSPECTIVE_PICKPOCKET_RESULT_CAN_ATTEMPT then
					additionalInfoText = GetString("SI_PROSPECTIVEPICKPOCKETRESULT", prospectiveResult)
				else
					additionalInfoText = isEmpty and GetString(SI_JUSTICE_PICKPOCKET_TARGET_EMPTY) or monsterSocialClassString
				end
				
				self.interactKeybindButton:SetText(zo_strformat(SI_GAME_CAMERA_TARGET_ADDITIONAL_INFO, action, additionalInfoText))
				
				interactKeybindButtonColor = ((not isHostile) and ZO_ERROR_COLOR or ZO_NORMAL_TEXT)
				
				if not interactionBlocked then
					TriggerTutorial(TUTORIAL_TRIGGER_PICKPOCKET_PROMPT_VIEWED)
					self.additionalInfo:SetHidden(false)
					additionalInfoLabelColor = (self.isInBonus and ZO_SUCCEEDED_TEXT or ZO_CONTRAST_TEXT)

					if(self.isInBonus and not self.wasInBonus) then
						self.bonusScrollTimeline:PlayForward()
						PlaySound(SOUNDS.JUSTICE_PICKPOCKET_BONUS)
						self.wasInBonus = true
					elseif(not self.isInBonus and self.wasInBonus) then
						self.bonusScrollTimeline:PlayBackward()
						self.wasInBonus = false
					elseif(not self.bonusScrollTimeline:IsPlaying()) then
						self.additionalInfo:SetText(zo_strformat(SI_PICKPOCKET_SUCCESS_CHANCE, self.percentChance))
						self.oldPercentChance = self.percentChance
					end
				else
					self.additionalInfo:SetHidden(true)
				end
			elseif additionalInteractInfo == ADDITIONAL_INTERACT_INFO_WEREWOLF_ACTIVE_WHILE_ATTEMPTING_TO_CRAFT then
				self.interactKeybindButton:SetText(zo_strformat(SI_CANNOT_CRAFT_WHILE_WEREWOLF))
			elseif additionalInteractInfo == ADDITIONAL_INTERACT_INFO_IN_HIDEYHOLE then
				self.interactKeybindButton:SetText(zo_strformat(SI_EXIT_HIDEYHOLE))
			end
			
			local interactContextString = interactableName;
			if(additionalInteractInfo == ADDITIONAL_INTERACT_INFO_INSTANCE_TYPE) then
				local instanceType = context
				if instanceType ~= INSTANCE_DISPLAY_TYPE_NONE then 
					local instanceTypeString = zo_iconTextFormat(GetInstanceDisplayTypeIcon(instanceType), 34, 34, GetString("SI_INSTANCEDISPLAYTYPE", instanceType))
					interactContextString = zo_strformat(SI_ZONE_DOOR_RETICLE_INSTANCE_TYPE_FORMAT, interactableName, instanceTypeString)
				end
			end
			
			self.interactContext:SetText(interactContextString)
			self.interactionBlocked = interactionBlocked
			
			ZO_ReticleContainerInteractContext:SetColor(1, 1, 1, 1)
			for key, val in ipairs(FlowersSheLikes.flowerListLocalized) do
				if interactableName == val then
					if db[key] then
						if db[key] == 1 then
							ZO_ReticleContainerInteractContext:SetColor(db.likedColor.r, db.likedColor.g, db.likedColor.b, db.likedColor.a)
						elseif db[key] == 2 then
							ZO_ReticleContainerInteractContext:SetColor(db.whyNotColor.r, db.whyNotColor.g, db.whyNotColor.b, db.whyNotColor.a)
						end
					end
				end
			end
			
			self.interactKeybindButton:SetNormalTextColor(interactKeybindButtonColor)
			self.additionalInfo:SetColor(additionalInfoLabelColor:UnpackRGBA())  
			return true
			
		end
	end
end

local function BuildMenu()
	
	local LAM = LibStub('LibAddonMenu-2.0')
	
	-- Create control panel
	local panelData = {
		type = "panel",
		name = ADDON_NAME,
		displayName = ZO_HIGHLIGHT_TEXT:Colorize(ADDON_NAME),
		author = ADDON_AUTHOR,
		version = ADDON_VERSION,
		registerForRefresh = true,
		registerForDefaults = true,
		website = ADDON_WEBSITE,
	}
	
	LAM:RegisterAddonPanel("FlowersSheLikesOptions", panelData)
	
	local optionsTable = {}
	local optionsIndex = 0
	
	optionsIndex = optionsIndex + 1
	optionsTable[optionsIndex] = {
		type = "header",
		name = FlowersSheLikes.lang.optionsH,
		width = "full",
	}
	
	optionsIndex = optionsIndex + 1
	optionsTable[optionsIndex] = {
		type = "colorpicker",
		name = FlowersSheLikes.lang.likedColor,
		tooltip = FlowersSheLikes.lang.likedColorTT,
		getFunc = function() return db.likedColor.r, db.likedColor.g, db.likedColor.b,db.likedColor.a end,
		setFunc = function(r, g, b, a)
			db.likedColor.r = r
			db.likedColor.g = g
			db.likedColor.b = b
			db.likedColor.a = a
		end,
		default = defaults.likedColor,
	}
	
	optionsIndex = optionsIndex + 1
	optionsTable[optionsIndex] = {
		type = "colorpicker",
		name = FlowersSheLikes.lang.whyNotColor,
		tooltip = FlowersSheLikes.lang.whyNotColorTT,
		getFunc = function() return db.whyNotColor.r, db.whyNotColor.g, db.whyNotColor.b, db.whyNotColor.a end,
		setFunc = function(r, g, b, a)
			db.whyNotColor.r = r
			db.whyNotColor.g = g
			db.whyNotColor.b = b
			db.whyNotColor.a = a
		end,
		default = defaults.whyNotColor,
	}
	
	for key, val in ipairs(FlowersSheLikes.flowerListLocalized) do
	
		optionsIndex = optionsIndex + 1
		optionsTable[optionsIndex] = {
			type = "dropdown",
			name = val,
			choices = {FlowersSheLikes.lang.likeList1, FlowersSheLikes.lang.likeList2, FlowersSheLikes.lang.likeList3},
			getFunc = function()
				if db[key] == 1 then
					return FlowersSheLikes.lang.likeList1
				elseif db[key] == 2 then
					return FlowersSheLikes.lang.likeList2
				else
					return FlowersSheLikes.lang.likeList3
				end
			end,
			setFunc = function(choice)
				if choice == FlowersSheLikes.lang.likeList1 then
					db[key] = 1
				elseif choice == FlowersSheLikes.lang.likeList2 then
					db[key] = 2
				else
					db[key] = 3
				end			
			end,
			width = "full",
			default = 3,
		}
	
	end
	
	LAM:RegisterOptionControls("FlowersSheLikesOptions", optionsTable)
	
end

-- Initialises the settings and settings menu
local function OnAddonLoaded(_, addonName)

	if addonName == ADDON_NAME then
		db = ZO_SavedVars:NewAccountWide('FLOWERS', 1, nil, defaults)
		BuildMenu()
	end
	
end

-- Addon activation
EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED, OnAddonLoaded)