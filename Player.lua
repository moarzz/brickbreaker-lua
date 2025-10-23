local upgradesUI = require("upgradesUI")
local json = require("Libraries/dkjson")
local love = love

-- File path for storing game data
local saveFilePath = "gamedata.json"

-- Load game data from file
function loadGameData()
    
    local data = {
        highScore = 0,
        gold = 0,
        startingMoney = 0,
        permanentUpgrades = {},
        paddleCores = {["Collector's Core"] = true},  -- Initialize paddleCores
        permanentUpgradePrices = {
            amount = 100,
            speed = 100,
            damage = 100,
            -- ... other default prices
        },
        startingItems = {"Ball", "Nothing"},
    }
    if love.filesystem.getInfo(saveFilePath) then
        local contents = love.filesystem.read(saveFilePath)
        if contents then
            local fileData = json.decode(contents)
            if fileData then
                data.highScore = fileData.highScore or 0
                data.gold = fileData.gold or 0
                data.startingMoney = fileData.startingMoney or 0
                data.permanentUpgrades = fileData.permanentUpgrades or {}
                data.paddleCores = fileData.paddleCores or { ["Collector's Core"] = true }
                data.permanentUpgradePrices = fileData.permanentUpgradePrices or data.permanentUpgradePrices
                data.startingItems = fileData.startingItems or data.startingItems
                data.fastestTime = fileData.fastestTime or 100000000000
            end
        end
    else
        data.fastestTime = 100000000000
    end
    -- Update Player object directly
    Player.highScore = data.highScore
    Player.fastestTime = data.fastestTime
    Player.gold = data.gold
    Player.startingMoney = data.startingMoney
    Player.permanentUpgrades = data.permanentUpgrades
    Player.permanentUpgradePrices = data.permanentUpgradePrices
    Player.startingItems = data.startingItems
    Player.paddleCores = data.paddleCores

    -- Sync unlockedStartingBalls with startingItems for compatibility with UI
    Player.unlockedStartingBalls = {}
    if Player.startingItems then
        -- If startingItems is a list (array), convert to set
        if #Player.startingItems > 0 then
            for _, key in ipairs(Player.startingItems) do
                Player.unlockedStartingBalls[key] = true
            end
        else
            -- If startingItems is a table with keys (legacy), treat as set
            for key, unlocked in pairs(Player.startingItems) do
                if unlocked then
                    Player.unlockedStartingBalls[key] = true
                end
            end
        end
    end
    return data
end

local defaultPermanentUpgrades = {speed = 0, damage = 0, cooldown = 0, amount = 0, fireRate = 0, ammo = 0, range = 0}
Player = {
    money = 0,
    startingMoney = 0,
    gold = 0,
    rerolls = 0,
    score = 0,
    highScore = 0,
    fastestTime = 1000000, -- in seconds
    bricksDestroyed = 0,
    lives = 1,
    currentCore = "Collector's Core",
    levelingUp = false,
    choosingUpgrade = false,
    price = 1,
    newUpgradePrice = 100,
    selectedPaddleCore = "Collector's Core",
    upgradePriceMultScaling = 10,
    dead = false,
    lastHitTime = 0,
    items = {},
    queuedUpgrades = {},    
    permanentUpgrades = {}, -- Store permanent upgrades
    permanentUpgradePrices = {
        speed = 100,
        damage = 100,
        ballDamage = 100,
        bulletDamage = 100,
        cooldown = 100,
        fireRate = 100,
        ammo = 100,
        range = 100,
        amount = 100,
        --paddleSize = 100,
        paddleSpeed = 100,
        health = 500,
    },
    bonuses = { -- These bonuses are percentages
    },
    perks = {},
    level = 1,
    newWeaponLevelRequirement = 5,
    newStatLevelRequirement = 10,
    xpForNextLevel = 25,
    xp = 0,
    levelThreshold = 50, -- XP needed for each level
    paddleCores = {["Collector's Core"] = true},  -- Stores unlockedpaddle cores
}

function Player.initialize() 
    setmetatable(Player.permanentUpgrades, {
    __index = defaultPermanentUpgrades  -- if key not found in player, look in defaults
    })
end

-- Save game data to file        
function saveGameData()
    local hasBasicCore = false
    if Player.paddleCores then
        for core, _ in pairs(Player.paddleCores) do
            if core == "Collector's Core" then
                hasBasicCore = true
                break
            end
        end
    end
    if not hasBasicCore then
        Player.paddleCores["Collector's Core"] = true  -- Ensure Basic Core is always present
    end
    local data = {
        highScore = Player.highScore,
        fastestTime = Player.fastestTime,
        gold = Player.gold,
        startingMoney = Player.startingMoney,
        permanentUpgrades = {
            -- paddleSize = Player.permanentUpgrades.paddleSize or 0,
            -- paddleSpeed = Player.permanentUpgrades.paddleSpeed or 0,
            -- Keep other upgrades...
            speed = Player.permanentUpgrades.speed or 0,
            damage = Player.permanentUpgrades.damage or 0,
            cooldown = Player.permanentUpgrades.cooldown or 0,
            fireRate = Player.permanentUpgrades.fireRate or 0,
            ammo = Player.permanentUpgrades.ammo or 0,
            range = Player.permanentUpgrades.range or 0,
            amount = Player.permanentUpgrades.amount or 0,
            health = Player.permanentUpgrades.health or 0,
        },
        paddleCores = Player.paddleCores or {["Collector's Core"] = true},  -- Change this line
        permanentUpgradePrices = Player.permanentUpgradePrices,
        startingItems = Player.startingItems or {"Ball"},
    }
    local encoded = json.encode(data, { indent = true })
    love.filesystem.write(saveFilePath, encoded)
end

-- This file contains the player class, it manages his level, his abilities and his stats
local gameData = loadGameData()
function Player.loadJsonValues()
    Player.startingMoney = gameData.startingMoney or 0
    Player.money = gameData.startingMoney or 0
    Player.gold = gameData.gold or 0
    Player.highScore = gameData.highScore or 0
    Player.fastestTime = gameData.fastestTime or 10000
    Player.permanentUpgrades = gameData.permanentUpgrades or {}
    -- Apply paddle upgrades after loading
    if paddle then
        Player.bonusUpgrades.paddleSpeed()
        Player.bonusUpgrades.paddleSize()
    end
end

local money = 0
damageThisFrame = 0

Player.bonusOrder = {}
Player.bonusPrice = {}
Player.bonusesList = {
    speed = {name = "speed", description = "Ball speed", startingPrice = 100},
    damage = {name = "damage", description = "Damage boost", startingPrice = 100},
    ammo = {name = "ammo", description = "Ammo boost", startingPrice = 100},
    range = {name = "range", description = "Range boost", startingPrice = 100}, 
    fireRate = {name = "fireRate", description = "Fire rate boost", startingPrice = 100},
    amount = {name = "amount", description = "Amount boost", startingPrice = 100},
    cooldown = {name = "cooldown", description = "Cooldown reduction", startingPrice = 100},
}

Player.permanentUpgradePrices = {
    speed = 100,
    damage = 100,
    ballDamage = 100,
    bulletDamage = 100,
    cooldown = 100,
    fireRate = 100,
    ammo = 100,
    range = 100,
    amount = 100,
    --paddleSize = 100, -- This is now handled in permanentUpgrades.lua
}

Player.bonusUpgrades = {
    --income = function() Player.bonuses.income = Player.bonuses.income + 1 end,
    speed = function() Player.bonuses.speed = Player.bonuses.speed + 1 
    for _, ball in ipairs(Balls) do
        if ball.type == "ball" then
            Balls.adjustSpeed(ball.name)
        end
    end
    end,    
    paddleSize = function()
        -- This is handled in permanentUpgrades.lua now
        paddle.width = paddle.width + 100
        paddle.x = math.max(paddle.x - 50, statsWidth)  -- Adjust position to keep it centered
        Player.bonuses.paddleSize = (Player.bonuses.paddleSize or 0) + 1
    end,
    damage = function() Player.bonuses.damage = Player.bonuses.damage + 1 end,
    --ballDamage = function() Player.bonuses.ballDamage = Player.bonuses.ballDamage + 2 end,
    --bulletDamage = function() Player.bonuses.bulletDamage = Player.bonuses.bulletDamage + 2 end,
    ammo = function() Player.bonuses.ammo = Player.bonuses.ammo + 1 end,
    range = function() Player.bonuses.range = Player.bonuses.range + 1 end,
    fireRate = function() Player.bonuses.fireRate = Player.bonuses.fireRate + 1 end,
    amount = function() 
        Player.bonuses.amount = (Player.bonuses.amount or 0) + 1
        -- For each unlocked ball type
        local index = 0
        for _, ballType in pairs(Balls.getUnlockedBallTypes()) do
            if ballType.type == "ball" then  -- On  ly add actual balls
                Balls.addBall(ballType.name, true)  -- Pass true to indicate single ball add
            end
            index = index + 1
        end
        print("#unlocked ball types: " .. index)
    end,
    cooldown = function()
        Player.bonuses.cooldown = (Player.bonuses.cooldown or 0) - 1
    end,
}

Player.upgradePaddle = {
    paddleSize = function()
        -- This is handled in permanentUpgrades.lua now
        local value = 20
        paddle.width = paddle.width + value
        paddle.x = paddle.x - value / 2  -- Adjust position to keep it centered
        Player.permanentUpgrades.paddleSize = (Player.permanentUpgrades.paddleSize or 0) + 1
    end,
}

Player.availableCores = {
    { -- deprecated
        name = "Collector's Core",
        description = "You can have up to 5 items instead of 4.\n -1 to every stat",
        price = 0
    },
    --[[{
        name = "Size Core",
        description = "gain 10% paddle size per level",
        price = 0,
        startingItem = "ball",
    },
    {
        name = "Spray and Pray Core",
        description = "gain +1 fireRate for every 5 Player level",
        price = 250,
        startingItem = "Machine Gun"
    },
    {
        name = "Fast Study Core",
        description = "gain +2% experience gain per Player Level",
        price = 500,
        startingItem = "Shadow Ball"
    },
    {
        name = "Hacker Core",
        description = "Weapons start with an upgradePrice of 0",
        price = 750,
        startingItem = "Laser Beam"
    },
    {
        name = "Capitalist core",
        description = "instead of gaining normal interest, you gain $ equal to the Player's level when you level up (max 15)",
        price = 1000,
        startingItem = "Rocket Launcher"
    },]]
    {
        name = "Farm Core",
        description = "When you level up, all your weapons gain +1 to a random stat (-1 for cooldown).\nIt takes 100% more xp for you to level up",
        price = 1000,
    },
    {
        name = "Speed Core",
        description = "Start at lvl 4 with 50$, 1 random common weapon and 1 random uncommon weapon",
        price = 2000
    },
    {
        name = "Economy Core",
        description = "Always gain 15$ on level up, you cannot gain money from items",
        price = 1500,
    },
    --[[{
        name = "Madness Core",
        description = "Damage is divided by 2. Cooldown is halved. Every other stat is doubled.",
        price = 5000,
    },]]
}

Player.coreDescriptions = {
    -- ["Size Core"] = "gain 10% paddle size per level",
    ["Speed Core"] = "Start at lvl 5 with 20$, 1 random common weapon and 1 random uncommon weapon",
    ["Economy Core"] = "Always gain 12$ on level up, you cannot gain money from items",
    ["Collector's Core"] = "You can have up to 5 items instead of 4.\n There are only 2 items in the itemShop",
    ["Farm Core"] = "When you level up, all your weapons gain +1 to a random stat (-1 for cooldown)\nIt takes 100% more xp for you to level up and bricks grow in health 100% faster",
    --["Madness Core"] = "Damage and cooldown are reduced by 50%.\nevery other stat is doubled. bricks go twice as fast\n(can break the game)."
}

function Player.addBonus(name)
    Player.bonuses[name] = 0
    table.insert(Player.bonusOrder, name)
    if usingMoneySystem then
        Player.bonusPrice[name] = Player.currentCore == "Economy Core" and 50 or 100
    else
        Player.bonusPrice[name] = 5
    end
    print("added bonus : ".. name ..  ", #Player.bonuses : " .. tableLength(Player.bonuses))
end

function Player.reset()
    local oldScore = Player.score
    if oldScore > Player.highScore then
        Player.highScore = oldScore
        saveGameData()  -- Save the new high score
    end
    Player.startingMoney = gameData.startingMoney or 0
    Player.score = 0
    Player.money = gameData.startingMoney or 0
    Player.gold = gameData.gold or 0
    Player.goldEarned = 0
    Player.lives = 1
    Player.choosingUpgrade = false
    Player.price = 1
    Player.dead = false
    Player.bonuses = {} -- Clear the bonuses table first
    Player.perks = {} -- Clear the perks table
    Player.bonusOrder = {} -- Clear the bonus order
    Player.bonusPrice = {} -- Clear the bonus prices
    
    -- Initialize default bonuses from bonusesList
    Player.bonuses = {}

    Player.choosingUpgrade = false
    Player.dead = false
    Player.money = Player.startingMoney or 0
end

function Player.InterestGain()
    local moneyGain
    if Player.currentCore == "Economy Core" then
        moneyGain = 9
    else
        moneyGain = 6 --+ math.floor(math.min(Player.money, 25)/5)
    end
    gainMoneyWithAnimations(moneyGain)
end

function Player.levelUp()
    EventQueue:addEventToQueue(EVENT_POINTERS.gainMoney, 0.25, function() end)
    Player.InterestGain()
    setMusicEffect("paused")
    resetRerollPrice()
    Player.level = Player.level + 1
    if (Player.level) % 4 == 0 and tableLength(Balls.getUnlockedBallTypes()) < 6 then
        if usingMoneySystem then
            Player.xpForNextLevel = math.floor(Player.xpForNextLevel * 1.2)
        end
        Player.newWeaponLevelRequirement = Player.newWeaponLevelRequirement + 5
        setLevelUpShop(true) -- Set the level up shop with ball unlockedBallTypes
        Player.choosingUpgrade = true -- Set the flag to indicate leveling up
    end
    Player.xp = 0
    if usingMoneySystem then
        Player.xpForNextLevel = math.floor(Player.xpForNextLevel * 1.25)
    else
        if Player.level < 5 then
            Player.xpForNextLevel = math.floor(Player.xpForNextLevel * 2)
        elseif Player.level < 10 then
            Player.xpForNextLevel = math.floor(Player.xpForNextLevel * 1.6)
        elseif Player.level < 15 then
            Player.xpForNextLevel = math.floor(Player.xpForNextLevel * 1.55)
        elseif Player.level < 20 then
            Player.xpForNextLevel = math.floor(Player.xpForNextLevel * 1.45)
        elseif Player.level < 25 then
            Player.xpForNextLevel = math.floor(Player.xpForNextLevel * 1.35)
        elseif Player.level < 30 then
            Player.xpForNextLevel = math.floor(Player.xpForNextLevel * 1.25)
        elseif Player.level < 35 then
            Player.xpForNextLevel = math.floor(Player.xpForNextLevel * 1.2)
        elseif Player.level < 50 then
            Player.xpForNextLevel = math.floor(Player.xpForNextLevel * 1.15)
        else
            Player.xpForNextLevel = math.floor(Player.xpForNextLevel * 2)
        end
    end
    lvlUpPopup()
    if Player.currentCore == "Farm Core" then
        FarmCoreUpgrade()
        if hasItem("Birthday Hat") then
            FarmCoreUpgrade() -- Trigger a second time if the player has the Birthday Hat
        end
    elseif Player.currentCore == "Picky Core" then
        -- Every reroll costs 2$ instead of 1$
        Player.rerolls = 0
    end
    if (not usingMoneySystem) then
        Player.levelingUp = true
        if (Player.level - 1) % 3 ~= 0 then
            uiOffset.x = 0
        end
    end
    for _, item in pairs(Player.items) do
        if item.onLevelUp then
            item.onLevelUp(item)
            if hasItem("Birthday Hat") then
                item.onLevelUp(item) -- Trigger a second time if the player has the Birthday Hat
            end 
        end
    end
    if hasItem("Investment Guru") then
        if hasItem("Birthday Hat") then
            setItemShop({getItem("Long Term Investment"), getItem("Long Term Investment")})
        else
            setItemShop({getItem("Long Term Investment")})
        end
    elseif hasItem("Archeologist Hat") then
        local rarity = math.random(1,100) <= 75 and "rare" or "legendary"
        if hasItem("Birthday Hat") then
            setItemShop({getRandomItemOfRarity(rarity, math.random(1,100) <= 20), getRandomItemOfRarity(rarity, math.random(1,100) <= 20)})
        else
            setItemShop({getRandomItemOfRarity(rarity, math.random(1,100) <= 20)})
        end
    else
        setItemShop()
    end
end

local lastPopupTime = 0
local cumulatedXp = 0
function Player.gain(amount)
    
    Player.score = Player.score + amount
    Player.xp = Player.xp + amount -- XP follows score
    moneyBagValues.gainXp(amount, moneyBagValues)
    local farmCoreMult = (Player.currentCore == "Farm Core" and 1.5 or 1)
    if Player.xp >= (Player.xpForNextLevel * farmCoreMult) then
        Player.levelUp()
    end
    upgradesUI.tryQueue()
    -- xpPopup
    playSoundEffect(gainXpSFX, mapRange(amount, 1, 100, 0.3, 0.5), math.min(mapRange(amount, 1, 100, 0.55, 0.85), 1))
    if gameTime - lastPopupTime > 0.1 then
        xpPopup(amount + cumulatedXp)
        lastPopupTime = gameTime
        cumulatedXp = 0
    else
        cumulatedXp = (cumulatedXp or 0) + amount
    end
end

function Player.addGold(amount)
    Player.gold = Player.gold + amount
    saveGameData()
end

newHighScore = false
function Player.die()
    Player.levelingUp = false
    Player.choosingUpgrade = false
    setMusicEffect("dead")
    inGame = false
    -- Check and update high score
    print("player die")
   --  Balls.clear()
    if Player.score > Player.highScore then
        Player.highScore = Player.score
        newHighScore = true
    end
    deathTimerOver = false
    deathTweenValues.speed = getBrickSpeedMult()  -- Store the current speed for the death animation
    local deathTransitionTween = tween.new(1.15, deathTweenValues, {speed = 60, overlayOpacity = 1}, tween.inQuad)
    addTweenToUpdate(deathTransitionTween)
    Timer.after(1.15, function()
        toggleFreeze()
        deathTimerOver = true
    end)
    -- Calculate gold earned based on score
    local goldEarned = Player.level * math.ceil(Player.level / 5) * 5 
    Player.addGold(goldEarned)
    Player.dead = true
    saveGameData()  -- Save the new high score]]
end

local brickSpeedTween
local canTakeDamage = true
function Player.hit()
    if not Player.dead then
        Player.lives = Player.lives - 1
        if Player.lives <= 0 then
            Player.die()
        end
        --[[
        if canTakeDamage then
            canTakeDamage = false
            Timer.after(4, function() canTakeDamage = true end)
            Player.lives = Player.lives - 1
            Player.lastHitTime = love.timer.getTime()
                brickSpeed.value = -300 / getBrickSpeedByTime()
                brickSpeedTween = tween.new(2, brickSpeed, { value = 10 }, tween.outExpo)
                addTweenToUpdate(brickSpeedTween)
            end

            print("Player hit! Lives left: " .. Player.lives)
        end]]
    end
end

local function checkForHit()
    for _, brick in ipairs(bricks) do
        if paddle.y > screenHeight + 10 then
            Player.hit()
            damageScreenVisuals(0.25, 100)
        end
    end
end

function Player.update(dt)
    checkForHit()
end

function Player.pay(amount)
    if Player.money >= amount then
        local moneyBefore = Player.money
        Player.money = Player.money - amount
        richGetRicherUpdate(moneyBefore, Player.money)
    else
        local moneyBefore = Player.money
        Player.money = Player.money - amount
        richGetRicherUpdate(moneyBefore, Player.money)
        print("Player tried to pay ".. amount.."but didn't have enough money : "..Player.money)
    end
end

function Player:save()
    local saveData = {
        startingMoney = self.startingMoney,
        permanentUpgrades = {
            moneyBonus = self.moneyBonus or 0,
            damageBonus = self.damageBonus or 0,
            speedBonus = self.speedBonus or 0,
            healthBonus = self.healthBonus or 0,
            extraBallBonus = self.extraBallBonus or 0,
            criticalBonus = self.criticalBonus or 0,
            --paddleSize = self.permanentUpgrades.paddleSize or 0,
            paddleSpeed = self.permanentUpgrades.paddleSpeed or 0
        }
    }
    
    local jsonStr = json.encode(saveData, { indent = true })
    love.filesystem.write("savedata.json", jsonStr)
end

function Player:load()
    if love.filesystem.getInfo("savedata.json") then
        local contents = love.filesystem.read("savedata.json")
        local data = json.decode(contents)
        
        if data then
            self.startingMoney = data.startingMoney or 0
            self.money = self.startingMoney
            self.gold = data.gold or 0

              -- Load permanent upgrades
            if data.permanentUpgrades then
                self.moneyBonus = data.permanentUpgrades.moneyBonus or 0
                self.damageBonus = data.permanentUpgrades.damageBonus or 0
                self.speedBonus = data.permanentUpgrades.speedBonus or 0
                self.healthBonus = data.permanentUpgrades.healthBonus or 0
                self.extraBallBonus = data.permanentUpgrades.extraBallBonus or 0
                self.criticalBonus = data.permanentUpgrades.criticalBonus or 0
                -- self.permanentUpgrades.paddleSize = data.permanentUpgrades.paddleSize or 0
                -- self.permanentUpgrades.paddleSpeed = data.permanentUpgrades.paddleSpeed or 0
            end
        end
    end
end

return Player