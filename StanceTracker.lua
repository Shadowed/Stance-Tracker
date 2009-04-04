local StanceTracker = {}
local enemyStances = {}

function StanceTracker:OnInitialize()
	StanceTrackDB = StanceTrackDB or {locked = true, size = 24, scale = 1.0}
	
	self.db = { profile = StanceTrackDB }
	self.spells = {
		-- Defensive Stance
		[71] = "defensive",
		-- Battle Stance
		[2457] = "battle",
		-- Berserker Stance
		[2458] = "berserker",
	}
	self.stances = {
		["defensive"] = "Interface\\Icons\\Ability_Warrior_DefensiveStance",
		["battle"] = "Interface\\Icons\\Ability_Warrior_OffensiveStance",
		["berserker"] = "Interface\\Icons\\Ability_Racial_Avatar",
	}
end

-- Display for the targets stance
local backdrop = {bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeSize = 0.80,
		insets = {left = 1, right = 1, top = 1, bottom = 1}}

function StanceTracker:CreateDisplay()
	self.frame = CreateFrame("Frame", nil, UIParent)
	self.frame:SetScale(self.db.profile.scale)
	self.frame:SetBackdrop(backdrop)
	self.frame:SetBackdropColor(0, 0, 0, 1.0)
	self.frame:SetBackdropBorderColor(0.30, 0.30, 0.30, 1.0)
	self.frame:SetClampedToScreen(true)
	self.frame:SetMovable(true)
	self.frame:EnableMouse(true)
	self.frame:RegisterForDrag("LeftButton")
	self.frame:Hide()

	-- Positioning
	self.frame:SetScript("OnDragStart", function(self)
		if( not StanceTracker.db.profile.locked ) then
			self.isMoving = true
			self:StartMoving()
		end
	end)
	
	self.frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		
		local scale = self:GetEffectiveScale()
		
		StanceTracker.db.profile.x = self:GetLeft() * scale
		StanceTracker.db.profile.y = self:GetTop() * scale
	end)
	
	if( self.db.profile.x and self.db.profile.y ) then
		local scale = self.frame:GetEffectiveScale()
		self.frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", self.db.profile.x / scale, self.db.profile.y / scale)
	else
		self.frame:SetPoint("CENTER", UIParent, "CENTER")
	end
	
	-- Stance icon
	self.frame.icon = self.frame:CreateTexture(nil, "ARTWORK")
	self.frame.icon:SetAllPoints(self.frame)
	
	
	-- Size
	self.frame:SetWidth(self.db.profile.size + 2)
	self.frame:SetHeight(self.db.profile.size + 2)

	self.frame.icon:SetWidth(self.db.profile.size)
	self.frame.icon:SetHeight(self.db.profile.size)
end

function StanceTracker:UpdateDisplay()
	if( not self.frame ) then
		self:CreateDisplay()
	end
	
	local guid = UnitGUID("target")
	if( not UnitExists("target") or not enemyStances[guid] ) then
		self.frame:Hide()
		return
	end
	
	-- Update the icon
	self.frame.icon:SetTexture(self.stances[enemyStances[guid]])
	self.frame:Show()
end

-- Combat log monitoring
local COMBATLOG_OBJECT_TYPE_PLAYER = COMBATLOG_OBJECT_TYPE_PLAYER
local COMBATLOG_OBJECT_REACTION_HOSTILE	= COMBATLOG_OBJECT_REACTION_HOSTILE
local ENEMY_AFFILIATION = bit.bor(COMBATLOG_OBJECT_REACTION_HOSTILE, COMBATLOG_OBJECT_TYPE_PLAYER)

local eventsRegistered = {["SPELL_CAST_SUCCESS"] = true}
function StanceTracker:COMBAT_LOG_EVENT_UNFILTERED(timestamp, eventType, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellID)
	-- Enemy switched stances
	if( eventsRegistered[eventType] and self.spells[spellID] and bit.band(sourceFlags, ENEMY_AFFILIATION) == ENEMY_AFFILIATION ) then
		enemyStances[sourceGUID] = self.spells[spellID]
		self:UpdateDisplay()
	end
end

function StanceTracker:PLAYER_TARGET_CHANGED()
	self:UpdateDisplay()
end

-- Reset list
function StanceTracker:PLAYER_LEAVING_WORLD()
	if( self.frame ) then
		self.frame:Hide()
	end
	
	for k in pairs(enemyStances) do
		enemyStances[k] = nil
	end
end

function StanceTracker:Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff33ff99Stance Tracker|r: %s", msg))
end

function StanceTracker:Echo(msg)
	DEFAULT_CHAT_FRAME:AddMessage(msg)
end

-- Event thing
local frame = CreateFrame("Frame")
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
frame:RegisterEvent("PLAYER_TARGET_CHANGED")
frame:RegisterEvent("PLAYER_LEAVING_WORLD")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, ...)
	if( event == "ADDON_LOADED" and select(1, ...) == "StanceTracker" ) then
		StanceTracker:OnInitialize()
		self:UnregisterEvent("ADDON_LOADED")
	elseif( event ~= "ADDON_LOADED" ) then
		StanceTracker[event](StanceTracker, ...)
	end
end)


-- Slash command
local L = {
	["Stance Tracker commands"] = "Stance Tracker commands",
	["/stancetracker size <number> - Sets how large the stance indicator should be."] = "/stancetracker size <number> - Sets how large the stance indicator should be.",
	["/stancetracker locked - Toggles locking the stance indicator so you can move it."] = "/stancetracker locked - Toggles locking the stance indicator so you can move it.",
	["/stancetracker scale <number> - Indicator scale as a decimal, 1.0 for 100%, 0.95 for 95% and so on."] = "/stancetracker scale <number> - Indicator scale as a decimal, 1.0 for 100%, 0.95 for 95% and so on.",
	
	["Stance icon size set to %dx%d."] = "Stance icon size set to %dx%d.",
	["Stance indicator locked."] = "Stance indicator locked.",
	["Stance indicator unlocked."] = "Stance indicator unlocked.",
	["Stance indicator scale set to %.2f."] = "Stance indicator scale set to %.2f.",
}

SLASH_STANCETRACK1 = "/stancetracker"
SLASH_STANCETRACK2 = "/st"
SlashCmdList["STANCETRACK"] = function(msg)
	msg = string.lower(msg or "")
	
	local self = StanceTracker
	local cmd, arg = string.split(" ", msg)
	if( cmd == "size" and tonumber(arg) ) then
		self.db.profile.size = tonumber(arg) or 0
		self:Print(string.format(L["Stance icon size set to %dx%d."], self.db.profile.size, self.db.profile.size))
		
		if( self.frame ) then
			self.frame:SetWidth(self.db.profile.size + 2)
			self.frame:SetHeight(self.db.profile.size + 2)

			self.frame.icon:SetWidth(self.db.profile.size)
			self.frame.icon:SetHeight(self.db.profile.size)
		end
	
	elseif( cmd == "scale" and tonumber(arg) ) then
		self.db.profile.scale = tonumber(arg) or 0
		self:Print(string.format(L["Stance indicator scale set to %.2f."], self.db.profile.scale))
	
		if( self.frame ) then
			self.frame:SetScale(self.db.profile.scale)
		end

	elseif( cmd == "locked" ) then
		self.db.profile.locked = not self.db.profile.locked
	
		if( self.db.profile.locked ) then
			self:Print(L["Stance indicator locked."])
		else
			self:Print(L["Stance indicator unlocked."])
		end
	else
		self:Echo(L["Stance Tracker commands"])
		self:Echo(L["/stancetracker size <number> - Sets how large the stance indicator should be."])
		self:Echo(L["/stancetracker scale <number> - Indicator scale as a decimal, 1.0 for 100%, 0.95 for 95% and so on."])
		self:Echo(L["/stancetracker locked - Toggles locking the stance indicator so you can move it."])
	end
end
