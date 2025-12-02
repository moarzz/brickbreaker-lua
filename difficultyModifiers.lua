local difficultyModifiers = {}

local currentModifierLevel = 0
function setDifficultyModifiers(newLevel)
    currentModifierLevel = newLevel
end
function getDifficultyModifiers()
    return currentModifierLevel
end
local modifierDescriptions = {
    "No Difficulty Modifier",
    "Bricks have 30% more health",
    "Boss spawns 1 minute 30 seconds earlier",
    "Bricks move 40% faster",
    "Items cost 1$ more",
    "Bricks have 60% more health", -- 60% total, this gives 30% on top of the first one
    "Boss spawns 3 minutes earlier", -- 3 minutes total, this gives 1m30s on top of the first one
}

local unlockedModifiersPerCore = {
    ["Amount Core"] = 0,
    ["Spray and Pray Core"] = 0,
    ["Fast Study Core"] = 0,
    ["Hacker Core"] = 0,
    ["Loan Core"] = 0,
    ["Size Core"] = 0,
}

return difficultyModifiers