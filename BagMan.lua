--[[--------------------------------------------------------------------
	BagMan
	Lets you move and scale the default bag frames.
	http://www.wowinterface.com/downloads/info23285-BagMan.html
	http://www.curse.com/addons/wow/bagman

	Copyright (c) 2014 Phanx <addons@phanx.net>. All rights reserved.
	Please DO NOT upload this addon to other websites, or post modified
	versions of it. However, you are welcome to include a copy of it
	WITHOUT CHANGES in compilations posted on Curse and/or WoWInterface.
	You are also welcome to use any/all of its code in your own addon, as
	long as you do not use my name or the name of this addon ANYWHERE in
	your addon, including its name, outside of an optional attribution.
----------------------------------------------------------------------]]

local L = {
	AltDrag = "<Alt-Drag to move this bag>",
	CtrlMouseWheel = "<Ctrl-MouseWheel to scale this bag>",
	Version = "Version %s loaded.",
	CmdResetHelp = "Use \"/bagman reset\" to reset the position and scale of all bags.",
}
if GetLocale() == "deDE" then
	L.AltDrag = "<ALT-Ziehen, um diese Tasche zu bewegen>"
	L.CtrlMouseWheel = "<STRG-Mausrad, um die Größe dieser Tasche zu ändern>"
	L.Version = "Version %s geladen."
	L.CmdResetHelp = "Gebt \"/bagman reset\" ein, um die Position und Größe aller Taschen zurückzusetzen."
elseif GetLocale():match("^es") then
	L.AltDrag = "<Alt + arrastre para mover esta bolsa>"
	L.CtrlMouseWheel = "<Ctrl + rueda del ratón para cambiar el tamaño de esta bolsa>"
	L.CmdResetHelp = "Introduce \"/bagman reset\" para restablecer la posición y tamaño de todas las bolsas."
	L.Version = "Versión %s cargada."
end

------------------------------------------------------------------------

local function SavePosition(f)
	local name = f:GetName()
	--print("|cffff9f3fBagMan|r", "SavePosition", name)

	local scale = f:GetScale()
	local cx, cy = f:GetCenter()
	cx, cy = cx * scale, cy * scale

	local x, y, hpoint, vpoint
	local width, height = UIParent:GetWidth(), UIParent:GetHeight()
	if cx > (width / 2) then
		hpoint = "RIGHT"
		x = (f:GetRight() * scale) - width
	else
		hpoint = "LEFT"
		x = f:GetLeft() * scale
	end
	if cy > (height / 2) then
		vpoint = "TOP"
		y = (f:GetTop() * scale) - height
	else
		vpoint = "BOTTOM"
		y = f:GetBottom() * scale
	end

	local db = BagManDB[name] or {}
	db.point = vpoint..hpoint
	db.x = x
	db.y = y
	BagManDB[name] = db

	f:ClearAllPoints()
	f:SetPoint(db.point, floor(x / scale + 0.5), floor(y / scale + 0.5))
	--print("|cffff9f3fBagMan|r", db.point, x, y)
end

local function RestorePosition(f)
	local name = f:GetName()
	--print("|cffff9f3fBagMan|r", "RestorePosition", name)
	local db = BagManDB[name]
	local s = db.scale or 1
	f:ClearAllPoints()
	f:SetPoint(db.point, db.x / s, db.y / s)
end

local function SetScale(f, scale)
	local name = f:GetName()
	--print("|cffff9f3fBagMan|r", "SetScale", name, scale)
	local db = BagManDB[name]
	db.scale = scale
	f:SetScale(scale)
	RestorePosition(f)
end

local function RestoreAllPositions()
	--print("|cffff9f3fBagMan|r", "RestoreAllPositions")
	for i = 1, NUM_CONTAINER_FRAMES do
		local name = "ContainerFrame"..i
		local f = _G[name]
		local db = BagManDB[name]
		if db and db.point then
			SetScale(f, db.scale or 1)
		elseif f:IsShown() then
			--print("|cffff9f3fBagMan|r", "NEW", name)
			SavePosition(f)
		end
	end
end

local function OnMouseDown(t)
	--print("|cffff9f3fBagMan|r", "OnMouseDown")
	if IsAltKeyDown() then
		local f = t:GetParent()
		f:StartMoving()
		f.__isMoving = true
	end
end

local function OnMouseUp(t)
	--print("|cffff9f3fBagMan|r", "OnMouseUp")
	local f = t:GetParent()
	if f.__isMoving then
		--print("|cffff9f3fBagMan|r", "isMoving")
		f:StopMovingOrSizing()
		f.__isMoving = nil
		SavePosition(f)
	end
end

local function OnHide(t)
	local f = t:GetParent()
	--local name = f:GetName()
	--print("|cffff9f3fBagMan|r", "OnHide", name)
	if f.__isMoving then
		--print("|cffff9f3fBagMan|r", "isMoving")
		f:StopMovingOrSizing()
		f.__isMoving = nil
	end
end

local function OnClick(t, b, ...)
	--print("|cffff9f3fBagMan|r", "OnClick")
	if not IsAltKeyDown() then
		t.__onClick(t, b, ...)
	end
end

local function OnMouseWheel(t, delta)
	if IsControlKeyDown() then
		--print("|cffff9f3fBagMan|r", "OnMouseWheel", delta)
		local f = t:GetParent()
		local scale = f:GetScale()
		if delta > 0 then
			scale = min(scale + 0.05, 3)
		elseif delta < 0 then
			scale = max(scale - 0.05, 0.1)
		end
		SetScale(f, floor(scale * 100 + 0.5) / 100)
	end
end

local function OnEnter(portrait)
	GameTooltip:AddLine(L.AltDrag, 0, 1, 0)
	GameTooltip:AddLine(L.CtrlMouseWheel, 0, 1, 0)
	GameTooltip:Show()
end

------------------------------------------------------------------------

BagManDB = {}

local BagMan = CreateFrame("Frame")
BagMan:RegisterEvent("PLAYER_LOGIN")
BagMan:SetScript("OnEvent", function(self, event)
	self:UnregisterEvent(event)
	--print("|cffff9f3fBagMan|r", event)

	for i = 1, NUM_CONTAINER_FRAMES do
		local name = "ContainerFrame"..i

		local f = _G[name]
		f:SetMovable(true)

		local t = f.ClickableTitleFrame
		t:SetScript("OnMouseDown", OnMouseDown)
		t:SetScript("OnMouseUp", OnMouseUp)
		t:SetScript("OnHide", OnHide)

		t:SetScript("OnShow", OnShow)

		t.__onClick = t:GetScript("OnClick")
		t:SetScript("OnClick", OnClick)

		t:EnableMouseWheel(true)
		t:SetScript("OnMouseWheel", OnMouseWheel)

		local p = f.PortraitButton
		p:HookScript("OnEnter", OnEnter)

		if BagManDB[name] then
			RestorePosition(f)
		end
	end

	hooksecurefunc("UpdateContainerFrameAnchors", RestoreAllPositions)
end)

------------------------------------------------------------------------

SLASH_BAGMAN1 = "/bagman"
SlashCmdList.BAGMAN = function(cmd)
	cmd = strlower(strtrim(cmd))
	--print("|cffff9f3fBagMan|r", cmd)
	if cmd == "reset" then
		wipe(BagManDB)
		for i = 1, NUM_CONTAINER_FRAMES do
			local f = _G["ContainerFrame"..i]
			f:SetScale(1)
			f:SetUserPlaced(false)
			f:ClearAllPoints()
		end
		return UpdateContainerFrameAnchors()
	end
	print("|cffffdd00BagMan:|r", format(L.Version, GetAddOnMetadata("BagMan", "Version")), L.CmdResetHelp)
end