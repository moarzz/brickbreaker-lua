-- Price for unlocking a new spell
Player = Player or {currentCore = "Bouncy Core"} -- Ensure Player table exists
local newSpellPrice = 10000

-- Helper: get unlocked spells (assuming Balls.getUnlockedBallTypes returns all, filter for type=="spell")
local function getUnlockedSpells()
    local spells = {}
    for _, ballType in pairs(Balls.getUnlockedBallTypes()) do
        if ballType.type == "spell" then
            table.insert(spells, ballType)
        end
    end
    return spells
end

local suit = require("Libraries.Suit") -- UI library
local upgradesUI = {}

local rerollPrice = 5

-- items list
longTermInvestmentSellValueBuff = 0
local items = {
    ["+3 buff"] = {
        name = "+3 buff",
        rarity = "common",
        stats = {},
        description = "+3 speed",
        onInShop = function(self)
            self.stats = {} 
            local statNames = {"damage", "speed", "amount", "ammo", "fireRate", "cooldown", "range"}
            local itemNames = {"Kitchen Knife", "Running Shoes", "2 for 1 Meal Ticket", "Extended Magazine", "Fast Hands", "Duct Tape", "Fake Pregnancy Belly"}
            local randomIndex = math.random(1,7)
            local randomStatName = statNames[randomIndex]
            self.name = itemNames[randomIndex]
            self.stats[randomStatName] = 3
            self.description = (randomStatName == "cooldown" and "-" or "+") .. "3 " .. randomStatName
        end
    },
    ["Triple Trouble"] = {
        name = "Triple Trouble",
        rarity = "common",
        stats = {},
        description = "+3 speed",
        onInShop = function(self)
            local iterations = 0
            local statNames = {"damage", "speed", "amount", "ammo", "fireRate", "cooldown", "range"}
            local randomIndex = math.random(1,7)
            local secondRandomIndex = randomIndex
            while secondRandomIndex == randomIndex do
                iterations = iterations + 1
                secondRandomIndex = math.random(1,7)
                if iterations > 100 then break end
            end
            iterations = 0
            local thirdRandomIndex = secondRandomIndex
            while thirdRandomIndex == randomIndex or thirdRandomIndex == secondRandomIndex do
                iterations = iterations + 1
                thirdRandomIndex = math.random(1,7)
                if iterations > 100 then break end
            end
            local randomStatName = statNames[randomIndex]
            local secondRandomStatName = statNames[secondRandomIndex]
            local thirdRandomStatName = statNames[thirdRandomIndex]
            self.stats[randomStatName] = 1
            self.stats[secondRandomStatName] = 1
            self.stats[thirdRandomStatName] = 1
            self.description = (randomStatName == "cooldown" and "-" or "+") .. "1 " .. randomStatName .. "\n" .. (secondRandomStatName == "cooldown" and "-" or "+") .. "1 " .. secondRandomStatName .. "\n" .. (thirdRandomStatName == "cooldown" and "-" or "+") .. "1 " .. thirdRandomStatName
        end
    },
    ["Financial Plan"] = {
        name = "Financial Plan",
        incomeBonus = 3,
        stats = {},
        description = "+3$ per level",
        rarity = "common"
    },
    --[[["Balls To The Wall"] = {
        name = "Balls To The Wall",
        stats = {speed = 1, amount = 1, damage = 1, range = 1, fireRate = 1, ammo = 1, cooldown = -1},
        description = "ball weapons gain +1 to all stats. (-1 for cooldown)",
        statsCondition = function(weapon) return weapon.type == "ball" end,
        rarity = "common"
    },
    ["TechTok"] = {
        name = "TechTok",
        stats = {speed = 1, amount = 1, damage = 1, range = 1, fireRate = 1, ammo = 1, cooldown = -1},
        description = "tech weapons gain +1 to all stats. (-1 for cooldown)",
        statsCondition = function(weapon) return weapon.type == "tech" end,
        rarity = "common"
    },
    ["Sharpshooter"] = {
        name = "Sharpshooter",
        stats = {speed = 1, amount = 1, damage = 1, range = 1, fireRate = 1, ammo = 1, cooldown = -1},
        description = "gun weapons gain +1 to all stats. (-1 for cooldown)",
        statsCondition = function(weapon) return weapon.type == "gun" end,
        rarity = "common"
    },]]
    ["Homing Bullets"] = {
        name = "Homing Bullets",
        stats = {ammo = 1, cooldown = -1},
        description = "+1 ammo, -1 cooldown, Bullets will home in on the nearest brick",
        rarity = "common"
    },
    ["Long Term Investment"] = {
        name = "Long Term Investment",
        stats = {},
        description = "",
        rarity = "common",
        onInShop = function(self) 
            self.description = "Gain " .. math.min((longTermInvestmentSellValueBuff) + 1, 15) .. "$\nIncrease the $ gain of every future 'Long Term Investment' by 1 (max 15)."
        end,
        onBuy = function()
            Player.money = Player.money + math.min((longTermInvestmentSellValueBuff) + 1, 15)
            longTermInvestmentSellValueBuff = math.min(20, longTermInvestmentSellValueBuff + 1)
        end,
        consumable = true
    },
    ["Loaded Dices"] = {
        name = "Loaded Dices",
        stats = {},
        description = "rerollPrice starts at 0$.",
        rarity = "common",
        onBuy = function(self)
            rerollPrice = 0
        end
    },
    ["Handy Wrench"] = {
        name = "Handy Wrench",
        stats = {},
        description = "When you buy this, reduce the upgrade price of a random weapon by 2 (min 0)",
        priceDiff = -1,
        rarity = "common",
        onBuy = function() 
            local randomWeaponId = math.random(1, tableLength(Balls.getUnlockedBallTypes()))
            local i = 1
            for _, weapon in pairs(Balls.getUnlockedBallTypes()) do
                if i == randomWeaponId then
                    weapon.price = math.max(weapon.price - 2, 0)
                    break
                end
                i = i + 1
            end
        end,
        consumable = true
    },
    ["+4 buff"] = {
        name = "+4 buff",
        rarity = "uncommon",
        stats = {},
        description = "+4 speed",
        onInShop = function(self) 
            local statNames = {"damage", "speed", "amount", "ammo", "fireRate", "cooldown", "range"}
            local itemNames = {"Kitchen Knife +", "Running Shoes +", "2 for 1 Meal Ticket +", "Extended Magazine +", "Fast Hands +", "Duct Tape +", "Fake Pregnancy Belly +"}
            local randomIndex = math.random(1,7)
            local randomStatName = statNames[randomIndex]
            self.name = itemNames[randomIndex]
            self.stats[randomStatName] = 4
            self.description = (randomStatName == "cooldown" and "-" or "+") .. "4 " .. randomStatName
        end
    },
    ["Triple Trouble +"] = {
        name = "Triple Trouble +",
        rarity = "uncommon",
        stats = {},
        description = "+3 speed",
        onInShop = function(self) 
            local iterations = 0
            local statNames = {"damage", "speed", "amount", "ammo", "fireRate", "cooldown", "range"}
            local randomIndex = math.random(1,7)
            local secondRandomIndex = randomIndex
            while secondRandomIndex == randomIndex do
                iterations = iterations + 1
                secondRandomIndex = math.random(1,7)
                if iterations > 100 then break end
            end
            iterations = 0
            local thirdRandomIndex = secondRandomIndex
            while thirdRandomIndex == randomIndex or thirdRandomIndex == secondRandomIndex do
                iterations = iterations + 1
                thirdRandomIndex = math.random(1,7)
                if iterations > 100 then break end
            end
            local randomStatName = statNames[randomIndex]
            local secondRandomStatName = statNames[secondRandomIndex]
            local thirdRandomStatName = statNames[thirdRandomIndex]
            self.stats[randomStatName] = 2
            self.stats[secondRandomStatName] = 2
            self.stats[thirdRandomStatName] = 2
            self.description = (randomStatName == "cooldown" and "-" or "+") .. "2 " .. randomStatName .. "\n" .. (secondRandomStatName == "cooldown" and "-" or "+") .. "2 " .. secondRandomStatName .. "\n" .. (thirdRandomStatName == "cooldown" and "-" or "+") .. "2 " .. thirdRandomStatName
        end
    },
    ["Satanic Necklace"] = {
        name = "Satanic Necklace",
        stats = {damage = 6, amount = -1, fireRate = -1, ammo = -1, cooldown = 1, speed = -1, range = -1},
        description = "+6 damage, -1 to every other stat",
        rarity = "uncommon"
    },
    --[[["Ballbuster"] = {
        name = "Ballbuster",
        stats = {speed = 2, amount = 2, damage = 2, range = 2, fireRate = 2, ammo = 2, cooldown = -2},
        description = "ball weapons gain +2 to all stats. (-2 for cooldown)",
        statsCondition = function(weapon) return weapon.type == "ball" end,
        rarity = "uncommon"
    },
    ["Quickdraw"] = {
        name = "Quickdraw",
        stats = {speed = 2, amount = 2, damage = 2, range = 2, fireRate = 2, ammo = 2, cooldown = -2},
        description = "gun weapons gain +2 to all stats. (-2 for cooldown)",
        statsCondition = function(weapon) return weapon.type == "gun" end,
        rarity = "uncommon"
    },
    ["Engineer"] = {
        name = "Engineer",
        stats = {speed = 2, amount = 2, damage = 2, range = 2, fireRate = 2, ammo = 2, cooldown = -2},
        description = "tech weapons gain +2 to all stats. (-2 for cooldown)",
        statsCondition = function(weapon) return weapon.type == "tech" end,
        rarity = "uncommon"
    },]]
    ["Degenerate Gambling"] = {
        name = "Degenerate Gambling",
        stats = {},
        incomeBonus = -1,
        description = "-1$ per level, 25% chance to gain 20$ on level up end",
        rarity = "uncommon",
        onLevelUpEnd = function() 
            if math.random(1,100) <= (hasItem("Four Leafed Clover") and 30 or 60) then
                local moneyBefore = Player.money
                Player.money = Player.money + 20
                richGetRicherUpdate(moneyBefore, Player.money)
            end
        end
    },
    ["Nerdy Glasses"] = {
        name = "Nerdy Glasses",
        stats = {damage = -1, speed = -1, cooldown = 1, size = -1, amount = -1, range = -1, fireRate = -1, ammo = -1},
        incomeBonus = 8,
        description = "+8$ per Level, -1 to every stat (+1 to cooldown)",
        rarity = "uncommon",
    },
    ["Bouncy Walls"] = {
        name = "Bouncy Walls",
        stats = {amount = 1, speed = 1},
        description = "+1 amount, +1 speed\nBalls gain a temporary boost of speed after bouncing off walls",
        rarity = "uncommon"
    },
    ["Swiss Army Knife"] = {
        name = "Swiss Army Knife",
        stats = {damage = 1, fireRate = 1, speed = 1, cooldown = -1, size = 1, amount = 1, range = 1, ammo = 1},
        description = "Increases all stats of your weapons by 1",
        rarity = "uncommon"
    },
    ["Paddle Defense System"] = {
        name = "Paddle Defense System",
        stats = {speed = 2},
        description = "+2 speed\nWhen balls bounce on the paddle, shoot a bullet that deals damage equal to that ball's damage",
        rarity = "uncommon"
    },
    ["Spray and Pray"] = {
        name = "Spray and Pray",
        stats = {fireRate = 2},
        description = "+2 fireRate\nfireRate items shoot 50% faster but are a lot less accurate",
        rarity = "uncommon"
    },
    ["Superhero t-shirt"] = {
        name = "Superhero t-shirt",
        stats = {},
        description = "While you own this item, 'Incrediball' is added to the pool of weapons you can unlcock.",
        rarity = "uncommon"
    },
    ["Huge Paddle"] = {
        name = "Huge Paddle",
        stats = {amount = 2},
        description = "+2 amount \npaddle width is increased by 75%",
        rarity = "uncommon"
    },
    ["+9 buff"] = {
        name = "+9 buff",
        rarity = "rare",
        stats = {},
        description = "+9 speed",
        onInShop = function(self) 
            local statNames = {"damage", "speed", "amount", "ammo", "fireRate", "cooldown", "range"}
            local itemNames = {"Kitchen Knife ++", "Running Shoes ++", "2 for 1 Meal Ticket ++", "Extended Magazine ++", "Fast Hands ++", "Duct Tape ++", "Fake Pregnancy Belly ++"}
            local randomIndex = math.random(1,7)
            local randomStatName = statNames[randomIndex]
            self.name = itemNames[randomIndex]
            self.stats[randomStatName] = 9
            self.description = (randomStatName == "cooldown" and "-" or "+") .. "9 " .. randomStatName
        end
    },
    ["Triple Trouble ++"] = {
        name = "Triple Trouble ++",
        rarity = "rare",
        stats = {},
        description = "+3 speed",
        onInShop = function(self) 
            local iterations = 0
            local statNames = {"damage", "speed", "amount", "ammo", "fireRate", "cooldown", "range"}
            local randomIndex = math.random(1,7)
            local secondRandomIndex = randomIndex
            while secondRandomIndex == randomIndex do
                iterations = iterations + 1
                secondRandomIndex = math.random(1,7)
                if iterations > 100 then break end
            end
            iterations = 0
            local thirdRandomIndex = secondRandomIndex
            while thirdRandomIndex == randomIndex or thirdRandomIndex == secondRandomIndex do
                iterations = iterations + 1
                thirdRandomIndex = math.random(1,7)
                if iterations > 100 then break end
            end
            local randomStatName = statNames[randomIndex]
            local secondRandomStatName = statNames[secondRandomIndex]
            local thirdRandomStatName = statNames[thirdRandomIndex]
            self.stats[randomStatName] = 3
            self.stats[secondRandomStatName] = 3
            self.stats[thirdRandomStatName] = 3
            self.description = (randomStatName == "cooldown" and "-" or "+") .. "3 " .. randomStatName .. "\n" .. (secondRandomStatName == "cooldown" and "-" or "+") .. "3 " .. secondRandomStatName .. "\n" .. (thirdRandomStatName == "cooldown" and "-" or "+") .. "3 " .. thirdRandomStatName
        end
    },
    ["Rich Get Richer"] = {
        name = "Rich Get Richer",
        stats = {amount = 0, fireRate = 0},
        description = "+1 amount and +1 fireRate for every 25$ you have",
        rarity = "rare",
        onBuy = function(self)
            local bonus = math.floor(Player.money / 25)
            self.stats.amount = bonus
            self.stats.fireRate = bonus
        end
    },
    ["Overclock"] = {
        name = "Overclock",
        stats = {},
        description = "When you buy this, all your weapons get a permanent upgrade to a random one of their stats",
        rarity = "rare",
        onBuy = function() FarmCoreUpgrade() end,
        consumable = true
    },
    ["Recession"] = {
        name = "Recession",
        stats = {},
        description = "On Level Up, reduce the upgrade price of all your items by 1 (min 0)",
        rarity = "rare",
        onLevelUp = function() 
            for _, weaponType in pairs(Balls.getUnlockedBallTypes()) do
                weaponType.price = math.max(weaponType.price - 1, 0)
            end
        end
    },
    ["Phantom Bullets"] = {
        name = "Phantom Bullets",
        stats = {damage = -5},
        description = "-5 damage, Bullets only lose 1 dmg when they pass through bricks",
        rarity = "rare"
    },
    --[[["Total Aballilation"] = {
        name = "Total Aballilation",
        stats = {speed = 3, amount = 3, damage = 3, range = 3, fireRate = 3, ammo = 3, cooldown = -3},
        description = "ball weapons gain +3 to all stats. (-3 for cooldown)",
        statsCondition = function(weapon) return weapon.type == "ball" end,
        rarity = "rare"
    },  
    ["Gunslinger"] = {
        name = "Gunslinger",
        stats = {speed = 3, amount = 3, damage = 3, range = 3, fireRate = 3, ammo = 3, cooldown = -3},
        description = "gun weapons gain +3 to all stats. (-3 for cooldown)",
        statsCondition = function(weapon) return weapon.type == "gun" end,
        rarity = "rare"
    },
    ["Glorious Evolution"] = {
        name = "Glorious Evolution",
        stats = {speed = 3, amount = 3, damage = 3, range = 3, fireRate = 3, ammo = 3, cooldown = -3},
        description = "tech weapons gain +3 to all stats. (-3 for cooldown)",
        statsCondition = function(weapon) return weapon.type == "tech" end,
        rarity = "rare"
    },]]
    ["Four Leafed Clover"] = {
        name = "Four Leafed Clover",
        stats = {},
        description = "every % value on items is doubled",
        rarity = "uncommon"
    }, 
    ["Flash Sale"] = {
        name = "Flash Sale",
        stats = {},
        description = "Reduce the upgrade price of all of your items by 2 (min 0)",
        onBuy = function() 
            for _, weaponType in pairs(Balls.getUnlockedBallTypes()) do
                weaponType.price = math.max(weaponType.price - 2, 0)
            end
        end,
        rarity = "uncommon",
        consumable = true
    },
    ["Electromagnetic alignment"] = {
        name = "Electromagnetic alignment",
        stats = {speed = 2},
        description = "+2 speed. Balls gain a small magnetic attraction towards bricks. (doesn't affect Magnetic Ball)",
        rarity = "rare"
    },
    ["Sudden Mitosis"] = {
        name = "Sudden Mitosis",
        stats = {},
        description = "when a brick is destroyed, 35% chance to spawn a small ball that lasts 8 seconds",
        rarity = "rare"
    },
    ["Jack Of All Trades"] = {
        name = "Jack Of All Trades",
        stats = {speed = 2, cooldown = -2, size = 2, amount = 2, range = 2, fireRate = 2, ammo = 2},
        description = "Increases all stats of your weapons by 2 (except damage), but decreases cooldown by 2",
        rarity = "rare"
    },
    ["Split Shooter"] = {
        name = "Split Shooter",
        stats = {},
        description = "Bullets have a 50% chance to split into 2 after being shot",
        rarity = "rare"
    },
    ["Blind Violence"] = {
        name = "Blind Violence",
        stats = {damage = 10, speed = -2, amount = -2, cooldown = 2, range = -2, fireRate = -2, ammo = -2},
        description = "Damage + 10, but all other stats -2 (cooldown + 2)",
        rarity = "rare"
    },
    ["Investment Guru"] = {
        name = "Investment Guru",
        stats = {},
        description = "Start every level with a 'Long Term Investment' in the shop",
        rarity = "rare"
    },
    ["Insider Trading"] = {
        name = "Insider Trading",
        stats = {},
        description = "Fill the shop with 'Long Term Investment' items",
        consumable = true,
        onBuy = function()
            setItemShop({getItem("Long Term Investment"), getItem("Long Term Investment"), getItem("Long Term Investment")})
            print("caca")
        end,
        rarity = "rare"
    },
    ["Buy the Dip"] = {
        name = "Buy the Dip",
        stats = {},
        description = "When you buy this, set the upgrade price of the weapon with the highest price to 0",
        rarity = "rare",
        consumable = true,
        onBuy = function() 
            local highestPrice = 0
            local highestWeapon = nil
            for _, weapon in pairs(Balls.getUnlockedBallTypes()) do
                if weapon.price > highestPrice then
                    highestPrice = weapon.price
                    highestWeapon = weapon
                end
            end
            if highestWeapon then
                highestWeapon.price = 0
            end
        end
    },
    ["Total Anihilation"] = {
        name = "Total Anihilaiton",
        stats = {damage = 2, range = 2},
        description = "+2 damage and range. Explosions cause 4 smaller explosions to happen nearby",
        rarity = "rare NOT READY"
    },
    ["Omnipotence"] = {
        name = "Omnipotence",
        stats = {speed = 3, damage = 3, cooldown = -3, size = 3, amount = 3, range = 3, fireRate = 3, ammo = 3},
        description = "Increases all stats of your weapons by 3",
        rarity = "legendary"
    },
    ["Brickbreaker"] = {
        name = "Brickbreaker",
        stats = {},
        description = "Every damage you deal has an 8% chance of instantly killing the brick (4% for big bricks, 0% for boss)",
        rarity = "legendary",
    },
    ["Sacred Gift"] = {
        name = "Sacred Gift",
        stats = {},
        description = "When you buy this, increase all your weapon's stats by 1",
        rarity = "legendary",
        consumable = true,
        onBuy = function()
            for _, weapon in pairs(Balls.getUnlockedBallTypes()) do
                if not weapon.noAmount and weapon.type == "ball" then
                    weapon.ballAmount = weapon.ballAmount + 1
                    Balls.addBall(weapon.name, true)
                end
                for statName, statValue in pairs(weapon.stats) do
                    if statName == "cooldown" then
                        weapon.stats[statName] = statValue - 1
                    elseif statName == "speed" then
                        weapon.stats[statName] = statValue + 50
                    else
                        weapon.stats[statName] = statValue + 1
                    end
                end
            end
        end
    },
    ["Total Economic Collapse"] = {
        name = "Total Economic Collapse",
        stats = {},
        description = "When you buy this, set the upgrade price of all weapons to 0",
        onBuy = function() 
            for _, weaponType in pairs(Balls.getUnlockedBallTypes()) do
                weaponType.price = 0
            end
        end,
        rarity = "legendary",
        consumable = true
    }
}



function richGetRicherUpdate(moneyBefore, moneyAfter)
    if hasItem("Rich Get Richer") then
        local diff = math.floor(moneyAfter/25) - math.floor(moneyBefore/25)
        if diff ~= 0 then
            getItem("Rich Get Richer").stats.amount = getItem("Rich Get Richer").stats.amount + diff
            getItem("Rich Get Richer").stats.fireRate = getItem("Rich Get Richer").stats.fireRate + diff
            if diff > 0 then
                Balls.amountIncrease(diff)
            else
                Balls.amountDecrease(math.abs(diff))
            end
        end
    end
end

local commonItems = {}
local commonItemsConsumable = {}
local uncommonItems = {}
local uncommonItemsConsumable = {}
local rareItems = {}
local rareItemsConsumable = {}
local legendaryItems = {}
local legendaryItemsConsumable = {}
local testItems = {}

function initializeRarityItemLists()
    commonItems = {}
    commonItemsConsumable = {}
    uncommonItems = {}
    uncommonItemsConsumable = {}
    rareItems = {}
    rareItemsConsumable = {}
    legendaryItems = {}
    legendaryItemsConsumable = {}
    testItems = {}
    for itemName, itemData in pairs(items) do
        local consumable = itemData.consumable or false
        if itemData.rarity == "common" then
            if consumable then
                table.insert(commonItemsConsumable, itemName)
            else
                table.insert(commonItems, itemName)
            end
        elseif itemData.rarity == "uncommon" then
            if consumable then
                table.insert(uncommonItemsConsumable, itemName)
            else
                table.insert(uncommonItems, itemName)
            end
        elseif itemData.rarity == "rare" then
            if consumable then
                table.insert(rareItemsConsumable, itemName)
            else
                table.insert(rareItems, itemName)
            end
        elseif itemData.rarity == "legendary" then
            if consumable then
                table.insert(legendaryItemsConsumable, itemName)
            else
                table.insert(legendaryItems, itemName)
            end
        elseif itemData.rarity == "test" then
            table.insert(testItems, itemName)
        else
            print("Warning: Item '" .. tostring(itemName) .. "' has unknown rarity '" .. tostring(itemData.rarity) .. "'")
        end
    end
end

function getItem(itemName) 
    return items[itemName]
end

function hasItem(itemName)
    for _, item in ipairs(Player.items) do
        if item.name == itemName then
            return true
        end
    end
    return false
end

function getItemsIncomeBonus()
    local incomeBonus = 0
    for itemName, item in pairs(Player.items) do
        if item.incomeBonus then
            incomeBonus = incomeBonus + item.incomeBonus
        end
    end
    return incomeBonus
end

function getStatItemsBonus(statName, weapon)
    local totalBonus = 0
    if #Player.items < 1 then return 0 end
    
    -- Calculate the actual item bonus
    for itemName, item in pairs(Player.items) do
        if item.stats[statName] then
            if item.statsCondition then
                if item.statsCondition(weapon) then
                    totalBonus = totalBonus + item.stats[statName]
                end
            else
                totalBonus = totalBonus + item.stats[statName]
            end
        end
    end
    
    -- Apply minimum value logic only if weapon is provided
    if weapon then
        local weaponStatValue = 0
        if statName == "amount" and not weapon.noAmount then
            weaponStatValue = weapon.ballAmount
        elseif weapon.stats[statName] then
            weaponStatValue = weapon.stats[statName]
        end
        
        -- Calculate what the total would be with current bonus
        local permanentBonus = Player.permanentUpgrades[statName] or 0
        local currentStatValue = weaponStatValue + permanentBonus + totalBonus
        
        -- If the total would be less than 1, adjust the bonus to make it exactly 1
        local targetValue = statName == "speed" and 50 or 1
        targetValue = statName == "cooldown" and 0 or 1
        if currentStatValue < targetValue then
            totalBonus = targetValue - weaponStatValue - permanentBonus
        end
    end
    
    return totalBonus
end

function itemsOnLevelUpEnd()
    for _, item in pairs(Player.items) do
        if item.onLevelUpEnd then
            item.onLevelUpEnd()
        end
    end
end
-----------------------------------

currentlyHoveredButton = nil
local shortStatNames = {
    speed = "Speed",
    damage = "Dmg",
    cooldown = "Cd",
    size = "Size",
    amount = "Amnt",
    range = "Range",
    fireRate = "F.Rate",
    ammo = "Ammo",
}

local invisButtonColor = {
                    normal  = {bg = {0,0,0,0}, fg = {1,1,1}},           -- invisible bg, black fg
                    hovered = {bg = {0.19,0.6,0.73,0.2}, fg = {1,1,1}}, -- glowing bg, white fg
                    active  = {bg = {1,0.6,0}, fg = {1,1,1}}          -- faint bg, white fg
                }

local buttonWidth, buttonHeight = 25, 25 -- Dimensions for each button

local upgradesQueue = {}
function upgradesUI.queueUpgrade(upgradePrice)
    table.insert(upgradesQueue, currentlyHoveredButton)
end


function upgradesUI.tryQueue()
    for x = #upgradesQueue, 1, -1 do
        if upgradesQueue[x]() then
            table.remove(upgradesQueue, x)
        end
    end
end

uiOffset = {x = 0, y = 0}
local drawPlayerStatsHeight = 200 -- Height of the player stats section
local function drawPlayerStats()
    local xOffset = -uiOffset.x

    -- Initialize the layout for the stats section
    local x, y = screenWidth/2 - uiWindowImg:getWidth()/2, screenHeight - uiWindowImg:getHeight() + 60
    --love.graphics.draw(uiWindowImg, x, y) -- Draw the background window image
    local padding = 10
    x = x + 20 + xOffset
    y = y + 40

    -- Draw the "Stats" title header
    suit.layout:reset(x, y, padding, padding) -- Reset layout with padding
    local xx = x
    local statsLayout = {
        min_width = 430, -- Minimum width for the layout
        pos = {x, y}, -- Starting position (x, y)
        padding = {padding, padding}, -- Padding between cells
        {"fill", 30},
        {"fill"}
    }

    local definition = suit.layout:cols(statsLayout) -- Create a column layout for the stats

    -- render money
    local x, y, w, h = definition.cell(2)
    local fontSize = 80 * (moneyScale.scale or 1)
    setFont(fontSize)
    love.graphics.setColor(1,1,1,1)
    x,y = statsWidth/2 - getTextSize(formatNumber(Player.money))/2 - 100 + xOffset, 175 - love.graphics.getFont():getHeight()/2 -- Adjust position for better alignment
    local moneyOffsetX = 0---math.cos(math.rad(5))*getTextSize(formatNumber(Player.money))/2
    love.graphics.setColor(0,0,0,1)
    love.graphics.print(formatNumber(Player.money) .. "$",x + 104 +moneyOffsetX, y +5, math.rad(1.5))
    local moneyColor = {14/255, 202/255, 92/255,1}
    love.graphics.setColor(moneyColor)
    love.graphics.print(formatNumber(Player.money) .. "$",x + 100 + moneyOffsetX, y + 1, math.rad(1.5))

    -- render interest if player has not finished leveling up
    local interestValue = math.floor(math.min(Player.money, Player.currentCore == "Economy Core" and 50 or 25)/5) + 5 + getItemsIncomeBonus()
    if Player.levelingUp and interestValue > 0 then
        setFont(45)
        love.graphics.setColor(moneyColor)
        x, y = x + 90, y - 45
        love.graphics.print("+" .. formatNumber(interestValue) .. "$",x + 100 + moneyOffsetX, y + 1, math.rad(1.5))
    end



    --[[if Player.bricksDestroyed then
        setFont(28)
        local text = "Bricks Destroyed : " .. formatNumber(Player.bricksDestroyed)
        love.graphics.setColor(0, 0, 0, 0.7)
        local tw = love.graphics.getFont():getWidth(text)
        local th = love.graphics.getFont():getHeight()
        love.graphics.setColor(1, 0.5, 0.25, 1)
        love.graphics.print(text, statsWidth/2 - tw/2, - th/2 + 320)
        love.graphics.setColor(1, 1, 1, 1) -- Reset color to white
    end]]

    if Player.currentCore then
        setFont(38)
        local coreText = tostring(Player.currentCore)
        love.graphics.setColor(0, 0, 0, 0.7)
        local tw = love.graphics.getFont():getWidth(coreText)
        local th = love.graphics.getFont():getHeight()
        -- Centered under Bricks Destroyed (which is at x=40, y=40)
        love.graphics.setColor(0.9, 0.9, 0.9, 1)
        love.graphics.print(coreText, statsWidth/2 - tw/2 + xOffset, 40 - th/2)
        love.graphics.setColor(1, 1, 1, 1)
    end

    if Player.score then
        setFont(38)
        local text = formatNumber(Player.score) .. " pts"
        love.graphics.setColor(0, 0, 0, 0.7)
        local tw = love.graphics.getFont():getWidth(text)
        local th = love.graphics.getFont():getHeight()
        love.graphics.setColor(0.25, 0.5, 1, 1)
        love.graphics.print(text, statsWidth/2 - th/2 - 25 + xOffset, 315 - th/2)
        love.graphics.setColor(1, 1, 1, 1) -- Reset color to white
    end
    -- Add a separator line for better visual clarity
    suit.layout:row(statsWidth, 65) -- Add spacing for the separator
    local x,y = suit.layout:nextRow(),y
end

local function drawInterestUpgrade()
    --[[local xOffset = -uiOffset.x
    love.graphics.draw(uiWindowImg, xOffset + uiWindowImg:getWidth(), 100, 0, 0.5, 0.65)
    love.graphics.draw(uiLabelImg, xOffset + uiWindowImg:getWidth() * 1.25 - uiLabelImg:getWidth()*0.65/2, 80, 0, 0.65, 1)]]
end

local levelUpShopType = "weapon"
local displayedUpgrades = {} -- This should be an array, not a table with string keys
local tweenSpeed = 2 -- Adjust this to control fade in speed

function setLevelUpShop()
    levelUpShopAlpha = 0
    shouldTweenAlpha = true
    displayedUpgrades = {} -- Clear the displayed upgrades
    levelUpShopType = "weapon"
    -- Ball unlocks
    local unlockedBallNames = {}
    for _, ball in pairs(Balls.getUnlockedBallTypes()) do
        unlockedBallNames[ball.name] = true
    end
    -- Only include non-spell balls
    local availableBalls = {}
    local weightedBalls = {}  -- Store balls with their weights
    local unlockedCount = #Balls.getUnlockedBallTypes()
    print("Unlocked Count: " .. unlockedCount)
    
    for name, ballType in pairs(Balls.getBallList()) do
        if (not unlockedBallNames[name]) then
            local weight = 0
            local ballList = Balls.getBallList()
            
            -- Calculate weight based on rarity and unlock count
            if ballList[ballType.name].rarity == "common" then
                if unlockedCount <= 2 then
                    weight = 7  -- High weight for commons early
                else
                    weight = 5
                end
            elseif ballList[ballType.name].rarity == "uncommon" then
                if unlockedCount == 1 then
                    weight = 2
                else
                    weight = 4
                end
            elseif ballList[ballType.name].rarity == "rare" then
                if unlockedCount == 1 then
                    weight = 0   -- No rare balls with just 1 unlock
                elseif unlockedCount == 2 then
                    weight = 1
                else
                    weight = 3
                end
            elseif ballList[ballType.name].rarity == "legendary" then
                weight = 10
            else
                weight = 7  -- Default weight for unspecified rarity
            end

            if ballType.canBuy then
                if not ballType.canBuy() then
                    weight = 0 -- Exclude spells from ball unlocks
                end
            end
            -- Only add balls with weight > 0
            if weight > 0 then
                for i=1, weight do
                    table.insert(weightedBalls, {
                        ball = ballType,
                        weight = weight
                    })
                end
            end
        end
    end

    for i=1, 3 do
        local thisBallType
        local doAgain = true
        while doAgain do
            local maxIterations = 100
            local iter = 0
            repeat
                iter = iter + 1
                local randomIndex = math.random(1, #weightedBalls)
                thisBallType = weightedBalls[randomIndex].ball
                doAgain = false

                if (thisBallType.rarity == "rare" or thisBallType.rarity == "legendary") and tableLength(Balls.getUnlockedBallTypes()) < 2 then
                    doAgain = true
                end

                if thisBallType.canBuy then
                    if not thisBallType.canBuy() then
                        doAgain = true
                    end
                end

                for _, displayedUpgrade in ipairs(displayedUpgrades) do
                    if displayedUpgrade.name == thisBallType.name then
                        doAgain = true
                        break
                    end
                end
            until not doAgain or iter >= maxIterations
            if iter >= maxIterations then
                print("Warning: Ball upgrade selection exceeded maxIterations, allowing duplicate or skipping.")
            end
        end
        table.insert(displayedUpgrades, {
            name = thisBallType.name,
            description = thisBallType.description,
            type = thisBallType.type,
            rarity = thisBallType.rarity or "common",
            effect = function()
                print("will add ball: " .. thisBallType.name)
                Balls.addBall(thisBallType.name)
            end
        })
        ::continue::
    end
end

addStatQueued = false -- Flag to indicate if the "add stat" button was queued
local function drawPlayerUpgrades()
    local xOffset = -uiOffset.x
    local padding = 10 -- Padding between elements
    local cellWidth, cellHeight = 200, 50 -- Dimensions for each cell
    local rowCount = 3 -- Number of rows

    --drawTitle
    setFont(28) -- Set font for the title
    suit.layout:reset(0, -80, padding, padding) -- Reset layout with padding
    local x,y,w,h = suit.layout:row(statsWidth - 20, 60)
    x = x + xOffset
    y = screenHeight/2 - 190
    love.graphics.draw(uiBigWindowImg, 0 + xOffset, y + 25, 0, 1, 1) -- Draw the background window image
    love.graphics.draw(uiLabelImg, x+15, y,0,1.5,1) -- Draw the title background image
    suit.layout:reset(x, y, padding, padding) -- Reset layout with padding
    suit.Label("Player Upgrades", {align = "center", valign = "center"}, suit.layout:row(statsWidth - 20, 60)) -- Title row
    
    -- Define the order of keys for Player.bonuses
    local rowCount = math.ceil((#Player.bonusOrder)/2)

    local intIndex = 1
    local currentRow = 0
    local currentCol = 0

    for i=1, math.max(rowCount,1), 1 do -- for each row
        currentRow = currentRow + 1
        local x, y = suit.layout:nextRow()

        local bonusLayout = {
            min_width = statsWidth - 20, -- Minimum width for the layout
            pos = {x + xOffset, y}, -- Starting position (x, y) with xOffset
            padding = {padding, padding}, -- Padding between cells
        }

        local colsOnThisRow = math.min(2, #Player.bonusOrder-intIndex+2)

        for i=1, colsOnThisRow, 1 do
            table.insert(bonusLayout, {"fill", 30})
        end
        local definition = suit.layout:cols(bonusLayout) -- Create a column layout for the bonuses

        currentCol = 0
        for i=1, math.min(colsOnThisRow, #Player.bonusOrder-intIndex+1), 1 do -- for each col on this row
            currentCol = currentCol + 1
            local bonusName = Player.bonusOrder[intIndex] -- Get the bonus name
            local x,y,w,h = definition.cell(i)
            x = x + xOffset -- Apply xOffset to the cell position
            suit.layout:reset(x, y, padding, padding) -- Reset layout with padding

            local statName = Player.bonusOrder[intIndex]

            -- render price
            setFont(45)
            local moneyOffsetX = -math.cos(math.rad(5))*getTextSize(formatNumber(math.ceil(Player.bonusPrice[bonusName]))) / 2
            love.graphics.setColor(0,0,0,1)
            love.graphics.print(formatNumber(math.ceil(Player.bonusPrice[bonusName])) .. "$", x + 104 + moneyOffsetX, y+4, math.rad(5))
            local moneyColor = Player.money >= Player.bonusPrice[bonusName] and {14/255, 202/255, 92/255,1} or {164/255, 14/255, 14/255,1}
            love.graphics.setColor(moneyColor)
            love.graphics.print(formatNumber(math.ceil(Player.bonusPrice[bonusName])) .. "$", x + 100 + moneyOffsetX, y, math.rad(5))
            love.graphics.setColor(1,1,1,1)

            -- draw value
            setFont(35)
            suit.layout:padding(0, 0)
            suit.Label(tostring((bonusName ~= "cooldown" and "+ " or "") .. tostring(Player.bonuses[bonusName] or 0)), {align = "center"}, x-5, y+50, cellWidth, 100) -- Display the stat value

            -- draw stat icon
            local iconX = x + cellWidth/2 - iconsImg[statName]:getWidth()*1.75/2
            love.graphics.draw(iconsImg[statName], iconX, y + 125, 0, 1.75, 1.75)
            y = y + 25

            -- draw separator
            if i == 1 then
                love.graphics.setColor(0.5,0.5,0.5,1)
                love.graphics.rectangle("fill", x + cellWidth, y + 10, 1, 125)
                love.graphics.setColor(1,1,1,1)
            end

            -- horizontal seperator
            if currentRow > 1 then
                love.graphics.setColor(0.5,0.5,0.5,1)
                love.graphics.rectangle("fill", x + 45, y-35, 125, 1)
                love.graphics.setColor(1,1,1,1)
            end

            local buttonID
            buttonID = generateNextButtonID() -- Generate a unique ID for the button
            local upgradeStatButton = dress:Button("", {color = invisButtonColor, id = buttonID}, x+5, y-20, cellWidth, cellHeight*4)
            -- Check if the player has enough money to upgrade
            local upgradeQueued = false
            if Player.queuedUpgrades then
                if Player.queuedUpgrades[1] == bonusName then
                    upgradeQueued = true
                end
            end
            if upgradeStatButton.hit or (upgradeQueued and Player.money >= math.ceil(Player.bonusPrice[bonusName])) and (usingMoneySystem or Player.levelingUp) then
                if Player.money < math.ceil(Player.bonusPrice[bonusName]) then
                    if usingMoneySystem then
                        print("Not enough money to upgrade " .. bonusName)
                        table.insert(Player.queuedUpgrades, bonusName)
                    end
                else
                    playSoundEffect(upgradeSFX, 0.5, 0.95, false)
                    if upgradeQueued then
                        -- Remove the queued upgrade if the player has enough money now
                        for i = #Player.queuedUpgrades, 1, -1 do
                            if Player.queuedUpgrades[i] == bonusName then
                                table.remove(Player.queuedUpgrades, i)
                                break
                            end
                        end
                    end
                    -- Always pay first, then increase the price
                    Player.pay(math.ceil(Player.bonusPrice[bonusName])) -- Deduct the cost from the player's money
                    Player.bonusUpgrades[bonusName]() -- Call the upgrade function
                    Player.bonusPrice[bonusName] = Player.bonusPrice[bonusName] * (usingMoneySystem and 10 or 2) -- Increase the price for the next upgrade
                    print(bonusName .. " upgraded to " .. Player.bonuses[bonusName])
                    if bonusName == "cooldown" then
                        Balls.reduceAllCooldowns()
                    end
                    if bonusName == "ammo" then
                        for _, ball in pairs(Balls.getUnlockedBallTypes()) do
                            if ball.type == "gun" then
                                ball.currentAmmo = (ball.currentAmmo or 0) + (ball.ammoMult or 1) -- Reset ammo for all gun balls
                            end
                        end
                    end
                end
            end
            if upgradeStatButton.entered then
                hoveredStatName = statName
            elseif upgradeStatButton.left then
                hoveredStatName = nil
            end
            local upgradeCount = 0
            for _, queuedUpgrade in ipairs(Player.queuedUpgrades) do
                if queuedUpgrade == statName then
                    upgradeCount = upgradeCount + 1
                end
            end 
            setFont(30)
            if upgradeCount > 0 then
                love.graphics.setColor(161/255, 231/255, 1, 1)
                love.graphics.print((statName == "cooldown" and "-" or "+") .. upgradeCount, x + cellWidth/3*2 - 5, y + 35) -- Display queued upgrade count
            end
            love.graphics.setColor(1,1,1,1)

            if love.mouse.getX() < x+5 + cellWidth and love.mouse.getX() > x+5 and love.mouse.getY() < y-20 + cellHeight*4 and love.mouse.getY() > y-20 then
                hoveredStatName = statName
            end
            intIndex = intIndex + 1
        end
        if intIndex < 5 then
            if currentCol < 2 then
                local x,y,w,h = definition.cell(currentCol+1)
                -- Calculate center position
                local labelWidth = w*3/4
                local centerX = x + (w - labelWidth)/2 + xOffset
                suit.layout:reset(centerX, y - 65, padding, padding)
                setFont(30)
                suit.Label("Unlock New Stat at lvl " .. Player.newStatLevelRequirement, {color = {normal = {fg = {1,1,1}}, hovered = {fg = {1,1,1}}, active = {fg = {1,1,1}}}, align = "center"}, suit.layout:row(labelWidth, cellHeight*4))
                if unlockNewStatQueued then
                    Player.newUpgradePrice = Player.newUpgradePrice * Player.upgradePriceMultScaling
                    setLevelUpShop(false) -- Set the level up shop with ball unlockedBallTypes
                    Player.choosingUpgrade = true -- Set the flag to indicate leveling up
                    unlockNewStatQueued = false
                end
                setFont(16)
            elseif i == math.max(rowCount,1) then
                y = y + 210 -- Add padding to the y position for the next row
                x = x + xOffset
                -- Calculate center position for full width label
                suit.layout:reset(10 + xOffset, y - 10, padding, padding)
                setFont(30)
                suit.Label("Unlock New Stat at lvl " .. Player.newStatLevelRequirement, {color = {normal = {fg = {1,1,1}}, hovered = {fg = {1,1,1}}, active = {fg = {1,1,1}}}, align = "center"}, suit.layout:row(w, cellHeight*4))
                if unlockNewStatQueued then
                    Player.newUpgradePrice = Player.newUpgradePrice * Player.upgradePriceMultScaling
                    setLevelUpShop(false) -- Set the level up shop with ball unlockedBallTypes
                    Player.choosingUpgrade = true -- Set the flag to indicate leveling up
                    unlockNewStatQueued = false
                end
            end
        end
        y = y + 210
        suit.layout:reset(10, y, 0, 0)
        suit.layout:row(statsWidth, 5) -- Add spacing for the separator
    end
end

unlockNewWeaponQueued = false
local currentBallShowHeight = 0
local function drawBallStats()
    if not (Player.levelingUp and not Player.choosingUpgrade) then
        return
    end 
    -----------------------------------
    -- Initialize position and layout --
    -----------------------------------
    local x, y = suit.layout:nextRow() -- Get the next row position
    local x, y = 10, 10 -- Starting position for the ball stats (horizontal from left)
    local w, h
    local padding = 100
    -- Initialize the layout with the starting position and padding
    suit.layout:reset(x, y, 10, 10) -- Set padding (10px horizontal and vertical)

    ----------------
    -- Draw Title --
    ----------------
    setFont(28)
    suit.layout:row(screenWidth - 20, 60)
    local x,y = suit.layout:nextRow()

    ----------------------------
    -- Prepare Ball List Data --
    ----------------------------
    local i = 0
    local ballsToShow = {}
    for ballName, ballType in pairs(Balls.getUnlockedBallTypes()) do
        ballsToShow[ballName] = ballType
    end

    -----------------------
    -- Draw Ball Entries --
    -----------------------
    local startX = 460 -- Starting X position
    local currentX = startX -- Current X position for drawing
    
    for ballName, ballType in pairs(ballsToShow) do
        i = i + 1
        if tableLength(ballsToShow) > 6 then
            if (i < (1 + currentBallShowHeight * 3)) or i > (6 + 3 * currentBallShowHeight) then goto continue
            else
                i = i - 3 * currentBallShowHeight
            end
        end
        -- Reset X position at the start of each row (every 3 balls)
        if (i-1) % 3 == 0 then
            currentX = startX
        end
        y = 475 + math.floor((i-1)/3) * 300 -- Move to next row every 3 balls
        suit.layout:reset(currentX, y, padding, padding)

        -- draw window
        love.graphics.draw(uiWindowImg, currentX-25,y)    

        -- draw title label and title
        setFont(26)
        love.graphics.draw(uiLabelImg, currentX + statsWidth/2-uiLabelImg:getWidth()/2-10, y-25)
        setFont(getMaxFittingFontSize(ballType.name or "Unk", 30, uiLabelImg:getWidth()-30))
        suit.Label(ballType.name or "Unk", {align = "center"}, currentX + statsWidth/2-uiLabelImg:getWidth()/2-7, y-25, uiLabelImg:getWidth(), uiLabelImg:getHeight())

        -- type label
        setFont(20)
        local typeColor = {normal = {fg = {0.6,0.6,0.6,1}}}
        local labelY = y + uiLabelImg:getHeight()/2
        suit.Label(ballType.type or "Unk type", {color = typeColor, align = "center"}, currentX + statsWidth/2-50-7, labelY, 100, 50)

        -- price label
        setFont(50)
        local moneyOffsetX = -math.cos(math.rad(5))*getTextSize(formatNumber(math.ceil(ballType.price)))/2
        love.graphics.setColor(0,0,0,1)
        love.graphics.print(formatNumber(math.ceil(ballType.price)) .. "$",currentX + statsWidth/2 + 104 +moneyOffsetX, labelY+4, math.rad(5))
        local moneyColor = Player.money >= math.ceil(ballType.price) and {14/255, 202/255, 92/255,1} or {164/255, 14/255, 14/255,1}
        love.graphics.setColor(moneyColor)
        love.graphics.print(formatNumber(math.ceil(ballType.price)) .. "$",currentX + statsWidth/2 + 100 +moneyOffsetX, labelY, math.rad(5))
        love.graphics.setColor(1,1,1,1)

        -- damageDealt label (top right, mirroring price)
        local damageDealt = ballType.damageDealt or 0
        local dmgText = tostring(formatNumber(damageDealt)) .. " dmg"
        setFont(25)
        local dmgOffsetX = -math.cos(math.rad(-2.5))*getTextSize(dmgText)/2
        local dmgTextWidth = love.graphics.getFont():getWidth(dmgText)

        -- Place at top right of the window, mirroring price
        local dmgX = currentX + statsWidth*1/4
        local dmgY = labelY + 13
        love.graphics.setColor(0,0,0,1)
        love.graphics.print(dmgText, dmgX + 4 + dmgOffsetX, dmgY + 4,math.rad(-2.5))
        love.graphics.setColor(1,0.25,0.25,1)
        love.graphics.print(dmgText, dmgX + dmgOffsetX, dmgY, math.rad(-2.5))
        love.graphics.setColor(1,1,1,1)
        

        labelY = labelY + 20
        local statsX = currentX + 10
        if #Balls.getUnlockedBallTypes() > 1 then
        end
        local myLayout = {
            min_width = 410, -- Minimum width for the layout
            pos = {statsX, labelY + 40}, -- Starting position (x, y)
            padding = {5, 5}, -- Padding between cells
        }
        -- Calculate the number of rows needed for the stats
        local rowCount = (ballType.noAmount or false) and countStringKeys(ballType.stats) or countStringKeys(ballType.stats) + 1
        if ballType.noAmount and ballType.stats.amount then
            rowCount = rowCount-- - 1 -- If no amount, don't count it
        end
        for x = 1,  rowCount do -- adds a {"fill"} for each stat in the ballType.stats table
            table.insert(myLayout, {"fill", 30}) -- for stats
        end
        local definition = suit.layout:cols(myLayout)
        statsX, labelY, w, h = definition.cell(1)
        suit.layout:reset(10, labelY, padding, padding) -- Set padding (10px horizontal and vertical)
        suit.layout:row(w, h)

        -- Draw upgrade buttons for each stat
        local intIndex = 1 -- keeps track of the current cell int id being checked
        -- Define the order of keys
        local statOrder = { "amount", "damage", "speed", "cooldown", "range", "fireRate", "ammo"} -- Order of stats to display

        -- makes sure amount is only called on things that use it
        local typeStats = {} -- Initialize the typeStats table
        if ballType.noAmount == false then
           typeStats = { amount = ballType.ballAmount } -- Start with amount
        end
        for statName, statValue in pairs(ballType.stats) do
            typeStats[statName] = statValue -- Add stats to the table
        end

        -- loops over each stats
        for _, statName in ipairs(statOrder) do
            local statValue = nil
            -- makes speed display as low value
            if typeStats[statName] then
                if statName == "speed" then
                    statValue = typeStats[statName]/50 -- Add speed to the stats table
                else
                    statValue = typeStats[statName]
                end
            end
            if statValue then -- Only process if the stat exists
                local buttonResult = nil
                statsX, labelY, w, h = definition.cell(intIndex)
                suit.layout:reset(statsX, labelY, padding, padding) -- Set padding (10px horizontal and vertical)
                setFont(20)

                local cellWidth = (430-10*rowCount)/rowCount
                
                -- draw value
                setFont(35)
                suit.layout:padding(0, 0)
                -- Add permanent upgrades to the display value
                local permanentUpgradeValue = Player.permanentUpgrades[statName] or 0
                local bonusValue = getStatItemsBonus(statName, ballType) or 0
                local value = (Player.currentCore == "Cooldown Core" and statName == "cooldown") and 2 or statValue + bonusValue + permanentUpgradeValue
                if statName == "ammo" then
                    value = value - permanentUpgradeValue - bonusValue + bonusValue * ballType.ammoMult -- Adjust ammo value based on ammoMult
                end
                if (statName == "fireRate" or statName == "amount") and Player.currentCore == "Damage Core" then
                    value = 1
                end
                if statName == "damage" then
                    if Player.currentCore == "Damage Core" then
                        value = value * 5 -- Double damage for Damage Core
                    elseif Player.currentCore == "Phantom Core" and (ballType.type == "gun" or ballType.name == "Gun Turrets" or ballType.name == "Gun Ball")then
                        value = value / 2
                    end
                    if ballName == "Sniper" then
                        value = value * 10
                    end
                end
                --[[if statName == "amount" and ballType.noAmount == false and getStatItemsBonus("amount", ballType) > 0 then
                    value = value
                end]]
                if statName == "cooldown" then
                    value = math.max(0, value)
                end
                if Player.currentCore == "Madness Core" then
                    if statName == "damage" or statName == "cooldown" then
                        value = value * 0.5 -- Half damage and cooldown for Madness Core
                    else
                        value = value * 2 -- Double speed for Madness Core
                    end
                end
                if (Player.currentCore == "Phantom Core" and ballType.type == "gun" and statName == "damage") or (Player.currentCore == "Madness Core" and (statName == "damage" or statName == "cooldown")) then
                    suit.Label(tostring(string.format("%.1f", value)), {align = "center"}, statsX, labelY-25, cellWidth, 100)
                else
                    suit.Label(tostring(value), {align = "center"}, statsX, labelY-25, cellWidth, 100)
                end

                -- draw stat icon
                local iconX = statsX + cellWidth/2 - iconsImg[statName]:getWidth()*1.75/2
                love.graphics.draw(iconsImg[statName], iconX, labelY + 75,0,1.75,1.75)

                -- draw seperator
                if intIndex < rowCount then
                    love.graphics.setColor(0.4,0.4,0.4,1)
                    love.graphics.rectangle("fill", statsX + cellWidth, labelY, 1, 125)
                    love.graphics.setColor(1,1,1,1)
                end

                -- draw invis button
                local invisButtonColor = {
                    normal  = {bg = {0,0,0,0}, fg = {0,0,0}},           -- invisible bg, black fg
                    hovered = {bg = {0.19,0.6,0.73,0.2}, fg = {1,1,1}}, -- glowing bg, white fg
                    active  = {bg = {1,0.6,0}, fg = {1,1,1}}          -- faint bg, white fg
                }
                local buttonID
                buttonID = generateNextButtonID() -- Generate a unique ID for the button
                local upgradeStatButton = dress:Button("", {color = invisButtonColor, id = buttonID}, statsX, labelY-10, cellWidth, 150)
                -- Right-click to remove all queued upgrades of this stat
                local canUpgrade = true
                -- Core-specific restrictions
                if statName == "cooldown" and Player.currentCore == "Cooldown Core" then
                    canUpgrade = false -- Cannot upgrade cooldown if using Cooldown Core
                end
                if ((statName == "fireRate" or statName == "amount") and Player.currentCore == "Damage Core") then
                    canUpgrade = false -- Cannot upgrade fireRate or amount if using Damage Core
                end
                -- Ammo restrictions
                if statName == "ammo" and (((ballType.stats.cooldown or 1000) + getStatItemsBonus("cooldown", ballType) + (Player.permanentUpgrades["cooldown"] or 0)) <= 0 and ballType.name ~= "Gun Turrets") then
                    canUpgrade = false -- Cannot upgrade ammo if cooldown is already at 0
                end
                local upgradeQueued = false
                if ballType.queuedUpgrades then
                    if ballType.queuedUpgrades[1] == statName then
                        upgradeQueued = true
                    end
                end
                if ((upgradeStatButton.hit or (upgradeQueued and Player.money >= math.ceil(ballType.price))) and canUpgrade) and (usingMoneySystem or Player.levelingUp) then
                    if Player.money < math.ceil(ballType.price) then
                        -- does nothing
                    elseif statName == "cooldown" and getStat(ballName, "cooldown") <= 0 then
                        print("cannot upgrade cooldown any further")
                        playSoundEffect(upgradeSFX, 0.5, 0.95, false)
                    else
                        playSoundEffect(upgradeSFX, 0.5, 0.95, false)
                        if upgradeQueued then
                            for i, queuedUpgrade in ipairs(ballType.queuedUpgrades) do
                                if queuedUpgrade == statName then
                                    table.remove(ballType.queuedUpgrades, i)
                                    break
                                end
                            end
                        end
                        setFont(16)
                        print("Upgrading " .. ballType.name .. "'s " .. statName)
                        local stat = ballType.stats[statName] or 0-- Get the current stat value
                        if statName == "speed" then
                            ballType.stats.speed = ballType.stats.speed + 50 -- Example action
                            Balls.adjustSpeed(ballType.name) -- Adjust the speed of the ball
                        elseif statName == "amount" and not ballType.noAmount then
                            Balls.addBall(ballType.name, true) -- Add a new ball of the same type
                            ballType.ballAmount = ballType.ballAmount + 1
                        elseif statName == "cooldown" then
                            ballType.stats.cooldown = ballType.stats.cooldown - 1
                        elseif statName == "ammo" then
                            print(ballType.name .. " ammo increased by " .. ballType.ammoMult)
                            ballType.currentAmmo = ballType.currentAmmo + ballType.ammoMult -- Increase ammo by ammoMult
                            ballType.stats.ammo = ballType.stats.ammo + ballType.ammoMult -- Example action
                        else
                            ballType.stats[statName] = ballType.stats[statName] + 1 -- Example action
                            print( "stat ".. statName .. " increased to " .. ballType.stats[statName])
                        end
                        Player.pay(math.ceil(ballType.price)) -- Deduct the cost from the player's money
                        if usingMoneySystem then
                            ballType.price = ballType.price * 2 -- Increase the price of the ball
                        else
                            ballType.price = ballType.price + 1
                        end
                    end
                elseif upgradeStatButton.entered then
                    hoveredStatName = statName
                elseif upgradeStatButton.left then
                    hoveredStatName = nil
                end
                
                local upgradeCount = 0
                for _, queuedUpgrade in ipairs(ballType.queuedUpgrades) do
                    if queuedUpgrade == statName then
                        upgradeCount = upgradeCount + 1
                    end
                end
                setFont(30)
                if upgradeCount > 0 then
                    love.graphics.setColor(161/255, 231/255, 1, 1)
                    love.graphics.print((statName == "cooldown" and "-" or "+") .. upgradeCount, statsX + cellWidth/3*2 - 5, labelY - 5) -- Display queued upgrade count\
                end
                intIndex = intIndex + 1
                love.graphics.setColor(1,1,1,1)
            end
        end
        suit.layout:row(statsWidth, 20) -- Add spacing for the separator
        
        -- Move to next horizontal position
        currentX = currentX + statsWidth + 50 -- Move right for next ball (20px spacing)
        if tableLength(ballsToShow) > 6 then
            i = i + 3 * currentBallShowHeight
        end
        ::continue::
    end
    
    if true then
        local numBalls = tableLength(Balls.getUnlockedBallTypes())
        local column = numBalls % 3 -- Get the current column (0, 1, or 2)
        
        -- If we're at the start of a new row, reset X position
        if column == 0 then
            currentX = startX
            y = y + 300 -- Move to next row
        end
        
        suit.layout:reset(currentX, y, padding, padding)
        love.graphics.draw(uiSmallWindowImg, currentX-25, y) -- Draw the background window image
        -- Button to unlock a new ball type
        setFont(30)
        local angle = angle or math.rad(1.5) -- Default angle if not provided
        love.graphics.setColor(1, 1, 1, 1)
        setFont(35)
        local levelRequirement = Player.newWeaponLevelRequirement or 5
        suit.Button("unlock new weapon at lvl " .. levelRequirement, {align = "center", color = invisButtonColor}, suit.layout:row(uiSmallWindowImg:getWidth() - 25, uiSmallWindowImg:getHeight() - 27))
        if unlockNewWeaponQueued then
            Balls.NextBallPriceIncrease()
            setLevelUpShop(true) -- Set the level up shop with ball unlockedBallTypes
            Player.choosingUpgrade = true -- Set the flag to indicate leveling up
            unlockNewWeaponQueued = false
        end
    end
    -- Add DOWN and UP buttons to the bottom of the area, side by side (no logic inside)
    if tableLength(ballsToShow) > 6 then
        local btnW, btnH = 120, 40
        -- Place buttons below the last row of balls
        local numRows = math.ceil(tableLength(ballsToShow) / 3)
        local btnY = screenHeight - btnH
        local btnX = startX + (screenWidth - startX - btnW)/2
        setFont(25)
        if currentBallShowHeight < math.ceil(tableLength(ballsToShow)/3) then
            if suit.Button("DOWN", {id="ballStatsDown"}, btnX, btnY, btnW, btnH).hit then
                currentBallShowHeight = math.min(currentBallShowHeight + 1, math.ceil(tableLength(ballsToShow)/3))
            end
        end
        btnX = btnX + btnW + 20
        if currentBallShowHeight > 0 then
            if suit.Button("UP", {id="ballStatsUp"}, btnX, btnY, btnW, btnH).hit then
                currentBallShowHeight = math.max(0, currentBallShowHeight - 1)
            end
        end
    end
end

local function drawPerks()
    local padding = 10 -- Padding between elements
    local cellWidth, cellHeight = 200, 50 -- Dimensions for each cell
    local rowCount = 3 -- Number of rows

    --drawTitle
    setFont(28) -- Set font for the title
    local x,y,w,h = suit.layout:nextRow(statsWidth - 20, 60)
    y = y + 200 -- Adjust y position for the title
    suit.layout:reset(x, y, padding, padding) -- Reset layout with padding
    love.graphics.draw(uiBigWindowImg, 0, y +25) -- Draw the background window image
    love.graphics.draw(uiLabelImg, x+15, y,0,1.5,1) -- Draw the title background image
    suit.Label("Player Upgrades", {align = "center", valign = "center"}, suit.layout:row(statsWidth - 20, 60)) -- Title row
end

local function getRarityWindow(rarity)
    if rarity == "common" then
        return uiBigWindowImg
    elseif rarity == "uncommon" then
        return uiBigWindowImgUncommon
    elseif rarity == "rare" then
        return uiBigWindowImgRare
    elseif rarity == "legendary" then
        return uiBigWindowImglegendary
    else
        return uiBigWindowImg -- default to common if unknown rarity
    end
end

function drawLevelUpShop()
    -- Initialize layout for the buttons
    local buttonWidth = (love.graphics.getWidth() - 300) / 3 - 60
    local buttonHeight = love.graphics.getHeight() - 500
    local buttonY = screenHeight/2 - buttonHeight/2 + 25
    -- print("level up shop opacity: " .. levelUpShopAlpha)
    local opacity = levelUpShopAlpha or 1
    --print("level up shop opacity: " .. opacity)
    local topText = levelUpShopType == "playerUpgrade" and "Choose a new Player Upgrade" or "Choose a new Weapon"
    setFont(60)
    love.graphics.print(topText, screenWidth/2 - getTextSize(topText)/2, buttonY - 175)

    -- Create a custom theme table that includes opacity
    local customTheme = {
        color = {
            normal = {bg = {0,0,0,0}, fg = {1,1,1,opacity}},
            hovered = {bg = {0.19,0.6,0.73,opacity*0.2}, fg = {1,1,1,opacity}},
            active = {bg = {1,0.6,0,opacity*0.2}, fg = {1,1,1,opacity}}
        }
    }

    for index, currentUpgrade in ipairs(displayedUpgrades) do
        -- Calculate button position
        local buttonX = 175 + (index - 1) * ((love.graphics.getWidth() - 300) / 3)

        -- Use suit to create a button with opacity
        suit.layout:reset(buttonX, buttonY, 10, 10)

        -- Check if mouse is over the button and brighten color if so
        local mx, my = love.mouse.getPosition()
        local isMouseOver = mx >= buttonX and mx <= buttonX + buttonWidth and my >= buttonY and my <= buttonY + buttonHeight

        love.graphics.setColor(0.5, 0.5, 0.5, opacity) -- Brighter background
        love.graphics.draw(getRarityWindow(currentUpgrade.rarity), buttonX - 10 * buttonWidth/getRarityWindow(currentUpgrade.rarity):getWidth(), buttonY, 0, buttonWidth/ getRarityWindow(currentUpgrade.rarity):getWidth(), buttonHeight/ getRarityWindow(currentUpgrade.rarity):getHeight()) -- Draw the background window image
        
        -- Draw labels with opacity
        love.graphics.setColor(1,1,1,opacity)
        

        suit.layout:row(buttonWidth-20,15)
        -- type specific logic
        setFont(35)
        dress:Label(currentUpgrade.name, {align = "center", color = {normal = {fg = {1,1,1,opacity}}}}, suit.layout:row(buttonWidth - 30, 55))
        setFont(30)
        dress:Label(currentUpgrade.type, {align = "center", color = {normal = {fg = {0.7,0.7,0.7,opacity}}}}, suit.layout:row(buttonWidth - 30, 45))
        setFont(24)
        dress:Label(currentUpgrade.description, {align = "center", color = {normal = {fg = {1,1,1,opacity}}}}, suit.layout:row(buttonWidth - 30, 150))
        suit.layout:row(buttonWidth - 20, 15)
        for statName, statValue in pairs(Balls.getBallList()[currentUpgrade.name].stats) do
            love.graphics.setColor(1,1,1,opacity)
            setFont(24)
            dress:Label(statName .. ": " .. statValue, {align = "center", color = {normal = {fg = {1,1,1,opacity}}}}, suit.layout:row(buttonWidth - 30, 30))
        end

        -- Register the invisible button with the custom theme
        local buttonID = "upgrade_" .. index
        suit.layout:reset(buttonX, buttonY, 10, 10)
        local buttonHit = suit.Button("", {id = buttonID, align = "center", color = customTheme.color}, suit.layout:col(buttonWidth, buttonHeight)).hit
        
        if buttonHit and opacity >= 0.995 then
            playSoundEffect(upgradeSFX, 0.5, 0.95, false)
            -- Button clicked: apply the effect and close the shop
            print("Clicked on upgrade: " .. currentUpgrade.name)
            currentUpgrade.effect() -- Apply the effect of the upgrade
            Timer.after(15, function() 
                if Player.choosingUpgrade then Player.choosingUpgrade = false end
            end)
            Player.choosingUpgrade = false
            if not usingMoneySystem then
                uiOffset.x = 0
                -- local uiRevealTween = tween.new(0.01, uiOffset, {x = 0}, tween.outExpo)
                -- addTweenToUpdate(uiRevealTween)
            end
        end
    end
    local x, y = suit.layout:nextRow()
    local x = screenWidth/2 - 150
    local w, h = 250, 75 -- Dimensions for the reroll button
    local buttonID = "reroll_button" -- Unique ID for the reroll button
    suit.layout:reset(x, y, 10, 10) -- Reset layout for the reroll button
    setFont(30)
    if Player.rerolls > 0 then
        if suit.Button("Reroll", {id = buttonID, align = "center"}, suit.layout:row(w,h)).hit then
            Player.rerolls = Player.rerolls - 1
            local isBallShop = levelUpShopType == "ball"
            setLevelUpShop(isBallShop) -- Reroll the upgrades
        end
    end

end

local function getRarityDistributionByLevel()
    local level = Player.level
    if level < 5 then
        return {common = 1, uncommon = 0, rare = 0.0, legendary = 0.0}
    elseif level < 10 then
        return {common = 0.9, uncommon = 0.1, rare = 0, legendary = 0.0}
    elseif level < 15 then
        return {common = 0.725, uncommon = 0.25, rare  = 0.025, legendary = 0}
    elseif level < 20 then
        return {common = 0.64, uncommon = 0.3, rare = 0.05, legendary = 0}
    elseif level < 25 then
        return {common = 0.5, uncommon = 0.35, rare = 0.125, legendary = 0.025}
    else
        return {common = 0.4, uncommon = 0.35, rare = 0.2, legendary = 0.05}
    end
end

local function getRandomItemOfRarity(rarity, consumable)
    consumable = consumable or false
    local rarityList = {}   
    if rarity == "common" then
        if consumable then
            rarityList = commonItemsConsumable
        else
            rarityList = commonItems
        end
    elseif rarity == "uncommon" then
        if consumable then
            rarityList = uncommonItemsConsumable
        else
            rarityList = uncommonItems
        end
    elseif rarity == "rare" then
        if consumable then
            rarityList = rareItemsConsumable
        else
            rarityList = rareItems
        end
    elseif rarity == "legendary" then
        if consumable then
            rarityList = legendaryItemsConsumable
        else
            rarityList = legendaryItems
        end
    end
    if #rarityList == 0 then
        print("Error: No items available for rarity " .. rarity .. " with consumable = " .. tostring(consumable))
        local item = getRandomItemOfRarity(rarity, false)
        return item
    else
        print("Choosing from " .. #rarityList .. " items of rarity " .. rarity .. " with consumable = " .. tostring(consumable))
    end
    return items[rarityList[math.random(1, #rarityList)]]
end

local displayedItems = {}
function setItemShop(forcedItems)
    forcedItems = forcedItems or {}
    displayedItems = {}
    for i=1, Player.currentCore == "Collector's Core" and 2 or 3 do
        local itemToDisplay = nil
        if forcedItems[i] then
            itemToDisplay = forcedItems[i]
            if itemToDisplay then
                if itemToDisplay.onInShop then
                    itemToDisplay.onInShop(itemToDisplay)
                end
                displayedItems[i] = itemToDisplay
            else
                print("Error: No item found in setItemShop()")
            end
            goto continue
        end
        -- calculate wanted rarity and choose an available item of that rarity
        local rarityDistribution = getRarityDistributionByLevel()
        local commonChance, uncommonChance, rareChance, legendaryChance = rarityDistribution.common, rarityDistribution.uncommon, rarityDistribution.rare, rarityDistribution.legendary
        local randomChance = math.random(1,100)/100
        local isConsumable = math.random(1,100) <= 20 -- 20% chance to be a consumable

        local doAgain = true
        local iterations = 0
        local maxIterations = 100
        local iterations = 0
        while doAgain and iterations < maxIterations do
            iterations = iterations + 1
            doAgain = false
            if randomChance <= commonChance then
                itemToDisplay = getRandomItemOfRarity("common", isConsumable)
            elseif randomChance <= commonChance + uncommonChance then
                itemToDisplay = getRandomItemOfRarity("uncommon", isConsumable)
            elseif randomChance <= commonChance + uncommonChance + rareChance then
                itemToDisplay = getRandomItemOfRarity("rare", isConsumable)
            elseif randomChance <= commonChance + uncommonChance + rareChance + legendaryChance then
                itemToDisplay = getRandomItemOfRarity("legendary", isConsumable)
            else
                itemToDisplay = getRandomItemOfRarity("common", isConsumable)
            end
            if iterations > 20 then
                itemToDisplay = getRandomItemOfRarity("common", false)
            end
            for _, displayedItem in pairs(displayedItems) do
                if displayedItem.name == itemToDisplay.name then
                    doAgain = true
                    break
                end
            end
            for _, playerItem in ipairs(Player.items) do
                if playerItem.name == itemToDisplay.name then
                    doAgain = true
                    break
                end
            end
        end
        if iterations >= maxIterations then
            print("Warning: setItemShop exceeded maxIterations, skipping slot or allowing duplicate.")
        end
        if testItems[i] and not forcedItems[i] then
            displayedItems[i] = items[testItems[i]]
        else
            if itemToDisplay then
                if itemToDisplay.onInShop then
                    itemToDisplay.onInShop(itemToDisplay)
                end
                displayedItems[i] = itemToDisplay
            else
                print("Error: No item found in setItemShop()")
            end
        end
        ::continue::
    end
end

local maxItems = 3

function setMaxItems(value)
    maxItems = value
end

function resetRerollPrice()
    if Player.currentCore == "Picky Core" then
        rerollPrice = 2
    elseif hasItem("Loaded Dices") then
        rerollPrice = 0
    else
        rerollPrice = 3
    end
end

local function drawItemShop()
    if Player.levelingUp and not Player.choosingUpgrade then
        setFont(60)
        local i = 0
        for index, item in ipairs(displayedItems) do
            local scale = item.consumable and 0.75 or 1
            local windowW = uiBigWindowImg:getWidth() * 0.75 * scale
            local windowH = uiBigWindowImg:getHeight() * 0.65 * scale
            local itemX = 450 + (i) * (uiBigWindowImg:getWidth()*0.75 + 50)
            local itemY = 50
            -- Center the window at the same position as a normal item
            local centerX = itemX + uiBigWindowImg:getWidth()*0.75/2
            local centerY = itemY + uiBigWindowImg:getHeight()*0.65/2
            itemX = centerX - windowW/2
            itemY = centerY - windowH/2

            local upgradePrice = item.rarity == "common" and 10 or item.rarity == "uncommon" and 20 or item.rarity == "rare" and 30 or item.rarity == "legendary" and 40 or 10
            if item.consumable then
                upgradePrice = upgradePrice * 0.5
                if Player.currentCore == "Picky Core" then
                    upgradePrice = math.ceil(upgradePrice * 0.5)
                end
            end

            local color = (tableLength(Player.items) >= maxItems and not item.consumable) and {0.6, 0.6, 0.6, 1} or {1, 1, 1, 1}
            love.graphics.setColor(color)
            love.graphics.draw(getRarityWindow(item.rarity or "common"), itemX, itemY, 0, 0.75 * scale, 0.65 * scale)
            setFont(math.floor(28 * scale))
            drawTextCenteredWithScale(item.name or "Unknown", itemX + 10 * scale, itemY + 35 * scale, scale, windowW - 20 * scale, color)

            setFont(math.floor(20 * scale))
            suit.Label(item.description or "No description", {align = "center"}, itemX + 25 * scale, itemY + 100 * scale, windowW - 50 * scale, 100 * scale)
            if dress:Button("", {id = "bruhdmsavklsam" .. i, color = invisButtonColor}, itemX, itemY, windowW, windowH).hit then
                print("button working")
                if (#Player.items < maxItems or item.consumable) and Player.money >= upgradePrice then
                    Player.pay(upgradePrice)
                    playSoundEffect(upgradeSFX, 0.5, 0.95)
                    table.remove(displayedItems, index)
                    if item.onBuy then
                        item.onBuy(item)
                    end
                    if not item.consumable then
                        table.insert(Player.items, item)
                    end
                    if item.stats.amount then
                        Balls.amountIncrease(item.stats.amount)
                    end
                    for _, weaponType in pairs(Balls.getUnlockedBallTypes()) do
                        if weaponType.type == "ball" then
                            Balls.adjustSpeed(weaponType.name) -- Adjust the speed of the ball
                        end
                    end
                    
                end
            end
            local moneyXoffset = item.consumable and -65 or 0
            local moneyYoffset = item.consumable and -25 or 0
            printMoney(upgradePrice, itemX + uiBigWindowImg:getWidth() * 0.75 - 40 - getTextSize(upgradePrice .. "$")/2 + moneyXoffset, itemY + uiBigWindowImg:getHeight() * 0.65/2 - 80 + moneyYoffset, math.rad(4), Player.money >= upgradePrice, 50)

            i = i + 1
        end
        love.graphics.draw(uiLabelImg, screenWidth - 275, 50 + uiBigWindowImg:getHeight() * 0.65/2 - 60) -- Draw the title background image
        setFont(30)
        local actualRerollPrice = Player.currentCore == "Picky Core" and 2 or rerollPrice
        if suit.Button("Reroll", {id = "reroll_items", color = invisButtonColor}, screenWidth - 260, 50 + uiBigWindowImg:getHeight() * 0.65/2 - 57, uiLabelImg:getWidth() - 30, uiLabelImg:getHeight() - 6).hit then
            if Player.money >= actualRerollPrice then
                Player.pay(actualRerollPrice)
                playSoundEffect(upgradeSFX, 0.5, 0.95)
                setItemShop()
                if Player.currentCore ~= "Picky Core" then
                    rerollPrice = rerollPrice + 1
                end
                
            end
        end
        printMoney(actualRerollPrice, screenWidth - 40 - getTextSize(actualRerollPrice .. "$")/2, 30 + uiBigWindowImg:getHeight() * 0.65/2 - 60, math.rad(4), Player.money >= actualRerollPrice, 40)

        love.graphics.setColor(0.6, 0.6, 0.6, 0.6) -- Light gray
        love.graphics.rectangle("fill", 403, 50 + uiBigWindowImg:getHeight() * 0.65 + 50, screenWidth, 3) -- Separator line
    end
end

-- Helper function to draw the item tooltip
local function drawItemTooltip(item)
    local mouseX, mouseY = love.mouse.getPosition()
    local tooltipPadding = 10
    local tooltipWidth = 200
    
    -- Set font for measuring text
    setFont(14)
    local wrappedText, lines = love.graphics.getFont():getWrap(item.description, tooltipWidth - tooltipPadding * 2)
    local tooltipHeight = #lines * love.graphics.getFont():getHeight() + tooltipPadding * 2
    
    -- Adjust tooltip position to keep it on screen
    local tooltipX = mouseX + 15 -- Offset from mouse
    local tooltipY = mouseY + 15
    
    -- Keep tooltip within screen bounds
    if tooltipX + tooltipWidth > love.graphics.getWidth() then
        tooltipX = mouseX - tooltipWidth - 15
    end
    if tooltipY + tooltipHeight > love.graphics.getHeight() then
        tooltipY = mouseY - tooltipHeight - 15
    end
    
    -- Draw tooltip background
    love.graphics.setColor(0.1, 0.1, 0.1, 0.9) -- Dark semi-transparent background
    love.graphics.rectangle("fill", tooltipX, tooltipY, tooltipWidth, tooltipHeight)
    
    -- Draw tooltip border
    love.graphics.setColor(0.8, 0.8, 0.8, 1) -- Light border
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", tooltipX, tooltipY, tooltipWidth, tooltipHeight)
    
    -- Draw tooltip text
    love.graphics.setColor(1, 1, 1, 1) -- White text
    setFont(14)
    love.graphics.printf(item.description, tooltipX + tooltipPadding, tooltipY + tooltipPadding, tooltipWidth - tooltipPadding * 2, "left")
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

local function drawPlayerItems()
    if Player.levelingUp and not Player.choosingUpgrade then
        love.graphics.setColor(0.6, 0.6, 0.6, 0.6) -- Light gray
        love.graphics.rectangle("fill", 400, 0, 3, screenHeight)
        love.graphics.setColor(1,1,1,1)
        
        -- Determine scale factor based on item count
        local itemCount = #Player.items
        local scaleFactor = maxItems <= 4  and 0.75 or 0.6 -- Scale down when more than 3 items
        
        -- Scale fonts and sizes
        local titleFontSize = math.floor(40 * scaleFactor)
        local itemNameFontSize = math.floor(16 * scaleFactor)
        local sellButtonFontSize = math.floor(20 * scaleFactor)
        local moneyFontSize = math.floor(30 * scaleFactor)
        
        -- Scale image dimensions
        local imgScaleX = 0.4 * scaleFactor
        local imgScaleY = 0.35 * scaleFactor
        
        -- Scale spacing and positioning
        local baseSpacing = 25 * scaleFactor
        local itemSpacing = (uiBigWindowImg:getHeight() * imgScaleY + baseSpacing)
        
        setFont(titleFontSize)
        love.graphics.print("Items", 200 - getTextSize("Items")/2, 400)
        
        local hoveredItem = nil -- Track which item is being hovered
        
        for index, item in ipairs(Player.items) do
            local sellPrice = item.rarity == "common" and 5 or item.rarity == "uncommon" and 10 or item.rarity == "rare" and 15 or item.rarity == "legendary" and 20 or 5
            
            -- Keep original row-based positioning, just scaled
            local itemX = 50 * scaleFactor
            local startingY = 30 + uiBigWindowImg:getHeight() * 0.65 + 50 + 53 -- Don't scale the starting Y
            local itemY = startingY + (index - 1) * itemSpacing
            
            -- Check if mouse is hovering over this item
            local mouseX, mouseY = love.mouse.getPosition()
            local itemWidth = uiBigWindowImg:getWidth() * imgScaleX
            local itemHeight = uiBigWindowImg:getHeight() * imgScaleY
            
            if mouseX >= itemX and mouseX <= itemX + itemWidth and
               mouseY >= itemY and mouseY <= itemY + itemHeight then
                hoveredItem = item
            end
            
            love.graphics.draw(getRarityWindow(item.rarity or "common"), itemX, itemY, 0, imgScaleX, imgScaleY)
            setFont(itemNameFontSize)
            drawTextCenteredWithScale(item.name, itemX + 10 * scaleFactor, itemY + uiBigWindowImg:getHeight() * imgScaleY/2 - 40 * scaleFactor, 1, uiBigWindowImg:getWidth() * imgScaleX - 20 * scaleFactor)
            
            local sellButtonID = "sell_item_" .. index
            setFont(sellButtonFontSize)
            if item.name == "Long Term Investment" then
                sellPrice = sellPrice + longTermInvestmentSellValueBuff
            end
            
            -- Scale button dimensions and positioning
            local buttonWidth = 120 * scaleFactor
            local buttonHeight = 100 * scaleFactor
            local buttonX = itemX + uiBigWindowImg:getWidth() * imgScaleX + 30 * scaleFactor
            local buttonY = itemY + uiBigWindowImg:getHeight() * imgScaleY/2 - 50 * scaleFactor
            
            if suit.Button("Sell", {id = sellButtonID, color = invisButtonColor}, buttonX, buttonY, buttonWidth, buttonHeight).hit then
                local moneyBefore = Player.money
                Player.money = Player.money + sellPrice
                richGetRicherUpdate(moneyBefore, Player.money)
                playSoundEffect(upgradeSFX, 0.5, 0.95)
                if item.stats.amount then
                    if item.stats.amount > 0 then
                        Balls.amountDecrease(item.stats.amount)
                    elseif item.stats.amount < 0 then
                        Balls.amountIncrease(math.abs(item.stats.amount))
                    end
                end
                if item.onSell then
                    item.onSell()
                end
                table.remove(Player.items, index)
            end
            
            -- Scale money display positioning
            local moneyX = itemX + uiBigWindowImg:getWidth() * imgScaleX + 125 * scaleFactor
            local moneyY = itemY + 40 * scaleFactor
            printMoney(sellPrice, moneyX, moneyY, math.rad(4), true, moneyFontSize)
        end
        
        -- Draw tooltip if hovering over an item
        if hoveredItem and hoveredItem.description then
            drawItemTooltip(hoveredItem)
        end
    end
end

function upgradesUI.draw()

    
    drawPlayerStats() -- Draw the player stats table
    --[[
    drawPlayerUpgrades() -- Draw the player upgrades table
    ]]
    drawBallStats() -- Draw the ball stats table
    if Player.currentCore ~= "Farm Core" then
        drawItemShop()
        drawPlayerItems()
    end

    -- Draw separator lines
    if usingMoneySystem then
        love.graphics.setColor(0.6, 0.6, 0.6, 0.6*math.max(math.min(math.max(0, 1-math.abs(Balls.getMinX()-statsWidth)/100), 1),math.min(math.max(0, 1-math.max(paddle.x-statsWidth,0)/100), 1))) -- Light gray
        love.graphics.rectangle("fill", statsWidth, 0, 1, screenHeight) -- Separator line
        love.graphics.setColor(0.6, 0.6, 0.6, 0.6*math.max(math.min(math.max(0, 1-math.abs(Balls.getMaxX()-(screenWidth - statsWidth))/100), 1), math.min(math.max(0, 1-math.max((screenWidth - statsWidth) - (paddle.x + paddle.width),0)/100))))
        love.graphics.rectangle("fill", screenWidth - statsWidth, 0, 1, screenHeight)
        love.graphics.setColor(0.6, 0.6, 0.6, 0.6* mapRangeClamped(math.abs(getHighestBrickY() + brickHeight - paddle.y), 0, 150, 1, 0)) -- Reset color to white
        love.graphics.rectangle("fill", statsWidth, paddle.y, screenWidth - statsWidth * 2, 1) -- Draw the paddle area
        love.graphics.setColor(1, 1, 1, 1) -- Reset color to white   
    end
    
    -- Draw Player.bricksDestroyed at the bottom left of the screen

    -- Draw stat hover label if hovering a stat
    if hoveredStatName and Player.levelingUp then
        local mx, my = love.mouse.getPosition()
        setFont(22)
        local tw = love.graphics.getFont():getWidth(hoveredStatName)
        local th = love.graphics.getFont():getHeight()
        love.graphics.setColor(0,0,0,0.7)
        love.graphics.rectangle("fill", mx-80 - tw, my-8, tw+86, th+65, 6, 6)
        love.graphics.setColor(1,1,1,1)
        love.graphics.print(hoveredStatName, mx - tw - 40, my-4)
    end
    love.graphics.setColor(1,1,1,1)
end

function upgradesUI.update(dt)
    
end

return upgradesUI