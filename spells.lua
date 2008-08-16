-- We only list spells that are usable in a single stance, like Intercept or Charge
StanceTrackerSpells = {
	-- Defensive Stance
	[71] = "defensive",
	[676] = "defensive",
	[3411] = "defensive",
	
	-- Battle Stance
	[2457] = "battle",
	[100] = "battle",
	[6178] = "battle",
	[11578] = "battle",
	
	-- Berserker Stance
	[2458] = "berserker",
	[20252] = "berserker",
	[20616] = "berserker",
	[20617] = "berserker",
	[25272] = "berserker",
	[47996] = "berserker",
	[25275] = "berserker",
	[18499] = "berserker",
}

StanceTrackerStances = {
	["defensive"] = "Interface\\Icons\\Ability_Warrior_DefensiveStance",
	["battle"] = "Interface\\Icons\\Ability_Warrior_OffensiveStance",
	["berserker"] = "Interface\\Icons\\Ability_Racial_Avatar",
}