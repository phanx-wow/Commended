--[[--------------------------------------------------------------------
	Commended
	A World of Warcraft user interface addon
	Copyright (c) 2013 A. Kinley (Phanx)

	This addon is freely available, and its source code freely viewable,
	but it is not "open source software" and you may not distribute it,
	with or without modifications, without permission from its author.

	See the included README and LICENSE files for more information!
----------------------------------------------------------------------]]

local ADDON = ...

local FACTION_FROM_ITEM = {
	[93225] = 1302, -- Anglers
	[93224] = 1341, -- August Celestials
	[93232] = 1375, -- Dominance Offensive
	[93215] = 1269, -- Golden Lotus
	[95545] = 1387, -- Kirin Tor Offensive
	[92522] = 1337, -- Klaxxi
	[93230] = 1345, -- Lorewalkers
	[93231] = 1376, -- Operation: Shieldwall
	[93220] = 1271, -- Order of the Cloud Serpent
	[93220] = 1270, -- Shado-Pan
	[95559] = 1435, -- Shado-Pan Assault
	[95548] = 1388, -- Sunreaver Onslaught
	[93226] = 1272, -- Tillers
}

------------------------------------------------------------------------
--	Utility functions


local HasCommendation
do
	local cache = {}
	local wasCollapsed = {}

	function HasCommendation(searchID)
		local result = cache[searchID]
		if result then
			return result
		end

		local i = 1
		while i <= GetNumFactions() do
			local name, _, _, _, _, _, _, _, isHeader, isCollapsed, _, _, _, factionID, hasBonusRepGain = GetFactionInfo(i)
			if isHeader and isCollapsed then
				wasCollapsed[name] = true
				ExpandFactionHeader(i)
			elseif factionID == searchID then
				result = hasBonusRepGain
				break
			end
			i = i + 1
		end

		i = 1
		while i <= GetNumFactions() do
			local name, _, _, _, _, _, _, _, isHeader, isCollapsed = GetFactionInfo(i)
			if isHeader and wasCollapsed[name] then
				wasCollapsed[name] = nil
				CollapseFactionHeader(i)
			end
			i = i + 1
		end

		cache[searchID] = result
		return result
	end

	local f = CreateFrame("Frame")
	f:RegisterEvent("UPDATE_FACTION")
	f:SetScript("OnEvent", function() wipe(cache) end)
end

------------------------------------------------------------------------
--	Add "Already known" to tooltips

local function AddTooltipInfo(self)
	local name, link = self:GetItem()
	local item = link and tonumber(strmatch(link, "item:(%d+)"))
	local faction = item and FACTION_FROM_ITEM[item]
	if faction and HasCommendation(faction) then
		self:AddLine(ITEM_SPELL_KNOWN, RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b)
		self:Show()
	end
end

GameTooltip:HookScript("OnTooltipSetItem", AddTooltipInfo)
ItemRefTooltip:HookScript("OnTooltipSetItem", AddTooltipInfo)

------------------------------------------------------------------------
--	Color item red in merchant windows

hooksecurefunc("MerchantFrame_UpdateMerchantInfo", function()
	local i = 1
	local itemButton = _G["MerchantItem"..i.."ItemButton"]
	while itemButton do
		local item = itemButton.link and tonumber(strmatch(itemButton.link, "item:(%d+)"))
		local faction = item and FACTION_FROM_ITEM[item]
		if faction and HasCommendation(faction) then
			local merchantButton = _G["MerchantItem"..i]
			SetItemButtonNameFrameVertexColor(merchantButton, 1, 0, 0)
			SetItemButtonSlotVertexColor(merchantButton, 1, 0, 0)
			SetItemButtonTextureVertexColor(itemButton, 0.9, 0, 0)
			SetItemButtonNormalTextureVertexColor(itemButton, 0.9, 0, 0)
		end
		i = i + 1
		itemButton = _G["MerchantItem"..i.."ItemButton"]
	end
end)

------------------------------------------------------------------------
--	Support for addon: GnomishVendorShrinker

if IsAddOnLoaded("GnomishVendorShrinker") then
	local GVS, GVS_ScrollFrame, GVS_EditBox
	local buttons = {}

	for _, f in ipairs({ MerchantFrame:GetChildren() }) do
		if not f:GetName() and f:IsObjectType("Frame") then
			local valid
			for _, ff in ipairs({ f:GetChildren() }) do
				if not ff:GetName() then
					if ff:IsObjectType("Button") and ff.BuyItem and ff.ItemName then
						tinsert(buttons, ff)
						valid = true
					elseif ff:IsObjectType("Slider") and valid then
						GVS_ScrollFrame = ff
					elseif ff:IsObjectType("EditBox") and valid then
						GVS_EditBox = ff
					end
				end
			end
			if GVS_ScrollFrame then
				GVS = f
				break
			end
		end
	end

	local function Update()
		for i = 1, #buttons do
			local row = buttons[i]
			local link = GetMerchantItemLink(row:GetID())
			local item = link and tonumber(strmatch(link, "item:(%d+)"))
			local faction = item and FACTION_FROM_ITEM[item]
			if faction and HasCommendation(faction) then
				row.backdrop:SetGradientAlpha("HORIZONTAL", 1,0,0,0.75, 1,0,0,0)
				row.backdrop:Show()
				row.icon:SetVertexColor(0.9, 0, 0)
			end
		end
	end

	GVS:HookScript("OnShow", Update)
	GVS_ScrollFrame:HookScript("OnValueChanged", Update)
	GVS_EditBox:HookScript("OnTextChanged", Update)
end

------------------------------------------------------------------------
--	Support for addon: xMerchant

if xMerchantScrollFrame then
	local buttons = setmetatable({}, { __index = function(t, i)
		local button = _G["xMerchantFrame"..i]
		t[i] = button
		return button
	end })

	local function Update(self)
		local numMerchantItems = GetMerchantNumItems()
		for i = 1, 10 do
			local merchantItem = i + FauxScrollFrame_GetOffset(self)
			if merchantItem <= numMerchantItems then
				local link = GetMerchantItemLink(merchantItem)
				local item = link and tonumber(strmatch(link, "item:(%d+)"))
				local faction = item and FACTION_FROM_ITEM[item]
				if faction and HasCommendation(faction) then
					local _, _, _, _, _, _, subType = GetItemInfo(link)
					local subText = gsub(subType, "%(OBSOLETE%)", "")
					buttons[i].iteminfo:SetFormattedText("|cffd00000%s - %s|r", subText, ITEM_SPELL_KNOWN)
				end
			end
		end
	end

	xMerchantScrollFrame:HookScript("OnShow", Update)
	xMerchantScrollFrame:HookScript("OnVerticalScroll", Update)
end