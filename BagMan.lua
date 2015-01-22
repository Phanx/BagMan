--[[--------------------------------------------------------------------
	BagMan
	Lets you move and scale the default bag frames.
	Copyright (c) 2014, 2015 Phanx <addons@phanx.net>. All rights reserved.
	http://www.wowinterface.com/downloads/info23285-BagMan.html
	http://www.curse.com/addons/wow/bagman
----------------------------------------------------------------------]]

local L = {
	AltDrag = "<Alt-Drag to move this bag>",
	CtrlMouseWheel = "<Ctrl-MouseWheel to scale this bag>",
	Version = "Version %s loaded.",
	Cmd = "Available commands:",
	CmdCurrent = "(current: %s)",
	CmdGlobal = "global",
	CmdGlobalHelp = "Use the same settings on all characters",
	CmdGlobalSet = "Now using global settings.",
	CmdGlobalUnset = "Now using character specific settings",
	CmdReset = "reset",
	CmdResetHelp = "Reset the position and scale of all bags",
	CmdScale = "scale",
	CmdScaleHelp = "Change the scale of all bags (allowed: 0.5-2)",
	CmdScaleErr = "Scale must be between 0.5 and 2!",
}
if GetLocale() == "deDE" then
	L.AltDrag = "<ALT-Ziehen, um diese Tasche zu bewegen>"
	L.CtrlMouseWheel = "<STRG-Mausrad, um die Größe dieser Tasche zu ändern>"
	L.Version = "Version %s geladen."
	L.Cmd = "Verfügbare Befehle:"
	L.CmdCurrent = "(aktuell: %s)"
	L.CmdGlobal = "global"
	L.CmdGlobalHelp = "Die gleiche Einstellungen für alle Charaktere verwenden"
	L.CmdGlobalSet = "Einstellungen werden jetzt allgemein gespeichert."
	L.CmdGlobalUnset = "Einstellungen werden jetzt pro Charakter gespeichert."
	L.CmdReset = "zurücksetzen"
	L.CmdResetHelp = "Die Position und Größe aller Taschen zurücksetzen"
	L.CmdScale = "größe"
	L.CmdScaleHelp = "Die Größe aller Taschen ändern (erlaubt: 0.5-2)"
	L.CmdScaleErr = "Die Größe muss zwischen 0.5 und 2 sein!"
elseif GetLocale():match("^es") then
	L.AltDrag = "<Alt + arrastre para mover esta bolsa>"
	L.CtrlMouseWheel = "<Ctrl + rueda del ratón para cambiar el tamaño de esta bolsa>"
	L.Version = "Versión %s cargada."
	L.Cmd = "Comandos disponibles:"
	L.CmdCurrent = "(actual: %s)"
	L.CmdGlobal = "global"
	L.CmdGlobalHelp = "Usar la misma configuración para todos personajes"
	L.CmdGlobalSet = "La configuración se guarda ahora globalmente."
	L.CmdGlobalUnset = "La configuración se guarda ahora por personaje."
	L.CmdReset = "restablecer"
	L.CmdResetHelp = "Restablecer la posición y tamaño de todas las bolsas"
	L.CmdScale = "tamaño"
	L.CmdScaleHelp = "Cambiar el tamaño de todas bolsas (permitido: 0.5-2)"
	L.CmdScaleErr = "¡El tamaño debe estar entre 0.5 y 2!"
end

------------------------------------------------------------------------

local db

local function SavePosition(frame)
	local id = frame:GetID()
	--print("|cffff9f3fBagMan|r", "SavePosition", id)

	local scale = frame:GetScale()
	local cx, cy = frame:GetCenter()
	cx, cy = cx * scale, cy * scale

	local x, y, hpoint, vpoint
	local width, height = UIParent:GetWidth(), UIParent:GetHeight()
	if cx > (width / 2) then
		hpoint = "RIGHT"
		x = (frame:GetRight() * scale) - width
	else
		hpoint = "LEFT"
		x = frame:GetLeft() * scale
	end
	if cy > (height / 2) then
		vpoint = "TOP"
		y = (frame:GetTop() * scale) - height
	else
		vpoint = "BOTTOM"
		y = frame:GetBottom() * scale
	end

	local info = db[id] or {}
	db[id] = info

	info.point = vpoint..hpoint
	info.x = x
	info.y = y

	frame:ClearAllPoints()
	frame:SetPoint(info.point, floor(x / scale + 0.5), floor(y / scale + 0.5))
	--print("|cffff9f3fBagMan|r", info.point, x, y)
end

local function RestorePosition(frame)
	local id = frame:GetID()
	--print("|cffff9f3fBagMan|r", "RestorePosition", id)
	local info = db[id]
	if not info then
		return SavePosition(frame)
	end
	local s = info.scale or 1
	frame:ClearAllPoints()
	frame:SetPoint(info.point, info.x / s, info.y / s)
end

local function SetScale(frame, scale)
	local id = frame:GetID()
	--print("|cffff9f3fBagMan|r", "SetScale", id, scale)
	local info = db[id] or {}
	db[id] = info

	info.scale = scale
	frame:SetScale(scale)

	if info.point then
		RestorePosition(frame)
	end
end

local function RestoreAllPositions()
	--print("|cffff9f3fBagMan|r", "RestoreAllPositions")
	for i = 1, NUM_CONTAINER_FRAMES do
		local frame = _G["ContainerFrame"..i]
		if frame:IsShown() then
			local id = frame:GetID()
			if id < 100 then
				local info = db[id]
				if info and info.point then
					SetScale(frame, info.scale or 1)
				else
					SavePosition(frame)
				end
			end
		end
	end
end

local function OnMouseDown(title)
	--print("|cffff9f3fBagMan|r", "OnMouseDown")
	if IsAltKeyDown() then
		local frame = title:GetParent()
		frame:StartMoving()
		frame.__isMoving = true
		title:GetScript("OnLeave")(title)
	end
end

local function OnMouseUp(title)
	--print("|cffff9f3fBagMan|r", "OnMouseUp")
	local frame = title:GetParent()
	if frame.__isMoving then
		--print("|cffff9f3fBagMan|r", "isMoving")
		frame:StopMovingOrSizing()
		frame:SetUserPlaced(false)
		frame.__isMoving = nil
		SavePosition(frame)
		title:GetScript("OnEnter")(title)
	end
end

local function OnHide(title)
	local frame = title:GetParent()
	--local id = frame:GetID()
	--print("|cffff9f3fBagMan|r", "OnHide", id)
	if frame.__isMoving then
		--print("|cffff9f3fBagMan|r", "isMoving")
		frame:StopMovingOrSizing()
		frame.__isMoving = nil
	end
end

local function OnClick(title, b, ...)
	--print("|cffff9f3fBagMan|r", "OnClick")
	if not IsAltKeyDown() then
		title.__onClick(title, b, ...)
	end
end

local function OnMouseWheel(title, delta)
	if IsControlKeyDown() then
		--print("|cffff9f3fBagMan|r", "OnMouseWheel", delta)
		local frame = title:GetParent()
		local scale = frame:GetScale()
		if delta > 0 then
			scale = min(scale + 0.05, 2)
		elseif delta < 0 then
			scale = max(scale - 0.05, 0.5)
		end
		SetScale(frame, floor(scale * 100 + 0.5) / 100)
	end
end

local function OnEnter(portrait)
	GameTooltip:AddLine(L.AltDrag, 0, 1, 0)
	GameTooltip:AddLine(L.CtrlMouseWheel, 0, 1, 0)
	GameTooltip:Show()

	local frame = portrait:GetParent()
	if frame:GetLeft() < GameTooltip:GetWidth() then
		GameTooltip:ClearAllPoints()
		GameTooltip:SetPoint("BOTTOMLEFT", frame, "TOPRIGHT")
	end
end

------------------------------------------------------------------------

local BagMan = CreateFrame("Frame")
BagMan:RegisterEvent("BANKFRAME_OPENED")
BagMan:RegisterEvent("PLAYER_LOGIN")
BagMan:SetScript("OnEvent", function(self, event)
	--print("|cffff9f3fBagMan|r", event)

	if event == "BANKFRAME_OPENED" then
		return ToggleAllBags()
	end

	self:UnregisterEvent("PLAYER_LOGIN")

	if BagManDB and type(next(BagManDB)) == "string" then
		--print("|cffff9f3fBagMan|r", "Removing old name based settings")
		BagManDB = nil
	end

	if BagManDB then
		--print("|cffff9f3fBagMan|r", "Using global settings")
		BagManDBPC = nil -- clean up old character settings
		db = BagManDB
	else
		--print("|cffff9f3fBagMan|r", "Using character settings")
		if not BagManDBPC then
			--print("|cffff9f3fBagMan|r", "Initializing new character")
			BagManDBPC = {}
		end
		db = BagManDBPC
	end

	for i = 1, NUM_CONTAINER_FRAMES do
		local frame = _G["ContainerFrame"..i]
		frame:SetMovable(true)

		local title = frame.ClickableTitleFrame
		title:SetScript("OnMouseDown", OnMouseDown)
		title:SetScript("OnMouseUp", OnMouseUp)
		title:SetScript("OnHide", OnHide)

		title.__onClick = title:GetScript("OnClick")
		title:SetScript("OnClick", OnClick)

		title:EnableMouseWheel(true)
		title:SetScript("OnMouseWheel", OnMouseWheel)

		local portrait = frame.PortraitButton
		portrait:HookScript("OnEnter", OnEnter)
	end

	hooksecurefunc("UpdateContainerFrameAnchors", RestoreAllPositions)
end)

------------------------------------------------------------------------

hooksecurefunc("ContainerFrame_GenerateFrame", function(frame, size, id)
	if id and id > 0 and ENABLE_COLORBLIND_MODE == "0" then
		local link = GetInventoryItemLink("player", ContainerIDToInventoryID(id))
		local _, _, quality = GetItemInfo(link)
		local r, g, b = GetItemQualityColor(quality)
		_G[frame:GetName().."Name"]:SetTextColor(r, g, b)
	else
		_G[frame:GetName().."Name"]:SetTextColor(1, 1, 1)
	end
end)

------------------------------------------------------------------------

local YES = "|cff7fff7f"..YES.."|r"
local NO = "|cffff9f9f"..NO.."|r"

SLASH_BAGMAN1 = "/bagman"
SlashCmdList.BAGMAN = function(cmd)
	local cmd, arg = strsplit(" ", strlower(strtrim(cmd)))
	--print("|cffff9f3fBagMan|r", cmd)
	if cmd == "global" or cmd == L.CmdGlobal then
		if BagManDB then
			BagManDBPC = BagManDB
			BagManDB = nil
			db = BagManDBPC
			print("|cffffcc00BagMan:|r", L.CmdGlobalUnset)
		else
			BagManDB = BagManDBPC or {}
			BagManDBPC = nil
			db = BagManDB
			print("|cffffcc00BagMan:|r", L.CmdGlobalSet)
		end
		return
	elseif cmd == "reset" or cmd == L.CmdReset then
		wipe(db)
		for i = 1, NUM_CONTAINER_FRAMES do
			local frame = _G["ContainerFrame"..i]
			frame:SetScale(1)
			frame:SetUserPlaced(false)
			frame:ClearAllPoints()
		end
		return UpdateContainerFrameAnchors()
	elseif cmd == "scale" or cmd == L.CmdScale then
		local scale = tonumber(arg)
		if scale and scale >= 0.5 and scale <= 2 then
			for i = 1, NUM_CONTAINER_FRAMES do
				local frame = _G["ContainerFrame"..i]
				SetScale(frame, scale)
			end
		else
			print("|cffffcc00BagMan:|r", L.CmdScaleErr)
		end
		return
	end
	print("|cffffcc00BagMan:|r", format(L.Version, GetAddOnMetadata("BagMan", "Version")), L.Cmd)

	print(format("- |cff82c5ff%s|r - %s", L.CmdGlobal, L.CmdGlobalHelp) .. " " .. format(L.CmdCurrent, BagManDB and YES or NO))
	print(format("- |cff82c5ff%s|r - %s", L.CmdReset,  L.CmdResetHelp))
	print(format("- |cff82c5ff%s|r - %s", L.CmdScale,  L.CmdScaleHelp))
end