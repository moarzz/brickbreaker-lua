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
        paddleCores = {["Size Core"] = true},  -- Initialize paddleCores
        permanentUpgradePrices = {
            amount = 100,
            speed = 100,
            damage = 100,
            -- ... other default prices
        },
        startingItems = {"Ball", "Nothing"},
        settings = {
            musicVolume = 1,
            sfxVolume = 1,
            fullscreen = true,
            damageNumbersOn = true
        }
    }
    if love.filesystem.getInfo(saveFilePath) then
        local contents = love.filesystem.read(saveFilePath)
        if contents then
            local fileData = json.decode(contents)
            if fileData then
                data.highScore = fileData.highScore or 0
                data.gold = fileData.gold or 0
                data.startingMoney = fileData.startingMoney or 0
                -- data.permanentUpgrades = fileData.permanentUpgrades or {}
                data.paddleCores = fileData.paddleCores or { ["Size Core"] = true }
                -- data.permanentUpgradePrices = fileData.permanentUpgradePrices or data.permanentUpgradePrices
                data.startingItems = fileData.startingItems or data.startingItems
                data.fastestTime = fileData.fastestTime or 100000000000
                data.settings = fileData.settings or data.settings
                data.firstRunCompleted = fileData.firstRunCompleted or false
            end
        end
    else
        data.fastestTime = 100000000000; --! this is a thing that is in the code of this game; yes
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
    musicVolume = data.settings.musicVolume
    sfxVolume = data.settings.sfxVolume
    fullScreenCheckbox = data.settings.fullscreen
    damageNumbersOn = data.settings.damageNumbersOn
    firstRunCompleted = data.firstRunCompleted or false

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
    hiddenMoney = 0;
    realMoney = 0;
    startingMoney = 0,
    gold = 0,
    rerolls = 0,
    score = 0,
    highScore = 0,
    fastestTime = 1000000, -- in seconds
    bricksDestroyed = 0,
    lives = 1,
    currentCore = "Size Core",
    levelingUp = false,
    choosingUpgrade = false,
    price = 1,
    newUpgradePrice = 100,
    selectedPaddleCore = "Size Core",
    upgradePriceMultScaling = 10,
    dead = false,
    lastHitTime = 0,
    items = {},
    queuedUpgrades = {},    
    permanentUpgrades = {}, -- Store permanent upgrades
    permanentUpgradePrices = {
    },
    bonuses = { -- These bonuses are percentages
    },
    perks = {},
    level = 1,
    newWeaponLevelRequirement = 5,
    newStatLevelRequirement = 10,
    xpForNextLevel = 25,
    xp = 0,
    xpGainMult = 1,
    levelThreshold = 50, -- XP needed for each level
    paddleCores = {["Size Core"] = true},  -- Stores unlockedpaddle cores
}

function Player.initialize() 
    setmetatable(Player.permanentUpgrades, {
    __index = defaultPermanentUpgrades  -- if key not found in player, look in defaults
    })
end

-- Save game data to file        
function saveGameData()

    -- code to check if the player has the basic core, game would break otherwise (just for first time open and safety)
    local hasBasicCore = false
    if Player.paddleCores then
        for core, _ in pairs(Player.paddleCores) do
            if core == "Size Core" then
                hasBasicCore = true
                break
            end
        end
    end
    if not hasBasicCore then
        Player.paddleCores["Size Core"] = true  -- Ensure Basic Core is always present
    end


    local data = {
        highScore = Player.highScore,
        firstRunCompleted = firstRunCompleted or false,
        fastestTime = Player.fastestTime,
        gold = Player.gold,
        startingMoney = Player.startingMoney,
        --[[permanentUpgrades = {
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
        },]]
        paddleCores = Player.paddleCores or {["Size Core"] = true},  -- Change this line
        -- permanentUpgradePrices = Player.permanentUpgradePrices,
        startingItems = Player.startingItems or {"Ball"},
        settings = {
            musicVolume = musicVolume,
            sfxVolume = sfxVolume,
            fullscreen = fullScreenCheckbox,
            damageNumbersOn = damageNumbersOn
        }
    }
    local encoded = json.encode(data, { indent = true })
    love.filesystem.write(saveFilePath, encoded)
end

-- This file contains the player class, it manages his level, his abilities and his stats

local gameData = loadGameData()
function Player.loadJsonValues() -- wtf is this bootleg function?
    firstRunCompleted = gameData.firstRunCompleted or false
    Player.startingMoney = gameData.startingMoney or 0
    Player.hiddenMoney = gameData.startingMoney or 0
    Player.gold = gameData.gold or 0
    Player.highScore = gameData.highScore or 0
    Player.fastestTime = gameData.fastestTime or 10000
    -- Player.permanentUpgrades = gameData.permanentUpgrades or {}
    -- Apply paddle upgrades after loading
    if paddle then
        Player.bonusUpgrades.paddleSpeed()
        Player.bonusUpgrades.paddleSize()
    end
end

-- local money = 0
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
    {
        name = "Size Core",
        description = "gain 8% paddle size per level",
        price = 0,
        startingItem = "ball",
    },
    {
        name = "Spray and Pray Core",
        description = "gain +1 fireRate for every 5 Player level.",
        price = 250,
        startingItem = "Machine Gun"
    },
    {
        name = "Fast Study Core",
        description = "gain +5% experience gain per Player Level",
        price = 500,
        startingItem = "Shadow Ball"
    },
    {
        name = "Hacker Core",
        description = "All Weapons start with an upgradePrice of 0",
        price = 750,
        startingItem = "Laser Beam"
    },
    {
        name = "Loan Core",
        description = "gain 10$ instead of 6$ on level up. There are no items that give money in the shop",
        price = 1000,
    },
    --[[{
        name = "Farm Core",
        description = "When you level up, all your weapons gain +1 to a random stat (-1 for cooldown).\nIt takes 100% more xp for you to level up",
        price = 1000,
    },
    
    {
        name = "Madness Core",
        description = "Damage is divided by 2. Cooldown is halved. Every other stat is doubled.",
        price = 5000,
    },]]
}

Player.coreDescriptions = {
    ["Size Core"] = "gain 8% paddle size per level",
    ["Spray and Pray Core"] = "gain +1 fireRate for every 5 Player level",
    ["Fast Study Core"] = "gain +5% experience gain per Player Level",
    ["Hacker Core"] = "All Weapons start with an upgradePrice of 0",
    ["Loan Core"] = "start with 25$. gain 3$ instead of 5$ on level up.",
    ["Farm Core"] = "When you level up, all your weapons gain +1 to a random stat (-1 for cooldown)\nIt takes 100% more xp for you to level up and bricks grow in health 100% faster",
    --["Madness Core"] = "Damage and cooldown are reduced by 50%.\nevery other stat is doubled. bricks go twice as fast\n(can break the game)."
}

Player.coreRestrictions = {
    -- ["Economy Core"] = {"Financial Plan", "Coupon Collector", "Degenerate Gambling", }
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
    Player.hiddenMoney = gameData.startingMoney or 0;
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
end

function Player.InterestGain()
    local moneyGain
    if Player.currentCore == "Loan Core" then
        moneyGain = 3 + longTermInvestment.value --+ math.floor(math.min(Player.money, 25)/5)
    else
        moneyGain = 5 + longTermInvestment.value --+ math.floor(math.min(Player.money, 25)/5)
    end

    Player.changeMoney(moneyGain);
end

function Player.onLevelUp()
    EventQueue:addEventToQueue(EVENT_POINTERS.levelUp, 0);
    Player.InterestGain()
end

function Player.levelUp()
    setMusicEffect("paused")
    love.mouse.setVisible(true)
    resetRerollPrice()
    Player.level = Player.level + 1

    -- should player unlock new weapon?
    if (Player.level) % 4 == 0 and tableLength(Balls.getUnlockedBallTypes()) < 6 then
        if usingMoneySystem then
            Player.xpForNextLevel = math.floor(Player.xpForNextLevel * 1.2)
        end
        Player.newWeaponLevelRequirement = Player.newWeaponLevelRequirement + 5
        setLevelUpShop(true) -- Set the level up shop with ball unlockedBallTypes
        Player.choosingUpgrade = true -- Set the flag to indicate leveling up
    else
        Player.onLevelUp()
    end

    -- crooky
    if (not firstRunCompleted) and Player.level == 2 then
        Crooky:giveInfo("run", "firstLevelUp")
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
            Player.xpForNextLevel = math.floor(Player.xpForNextLevel * 1.5)
        elseif Player.level < 20 then
            Player.xpForNextLevel = math.floor(Player.xpForNextLevel * 1.4)
        elseif Player.level < 25 then
            Player.xpForNextLevel = math.floor(Player.xpForNextLevel * 1.3)
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
    elseif Player.currentCore == "Size Core" then
        paddle.width = paddle.width + 24
    elseif Player.currentCore == "Fast Study Core" then
        Player.xpGainMult = Player.xpGainMult + 0.05
    elseif Player.level % 5 == 0 and Player.currentCore == "Spray and Pray Core" then -- THIS IS NOT AN ERROR
        Player.permanentUpgrades.fireRate = (Player.permanentUpgrades.fireRate or 0) + 1
    end
    if (not usingMoneySystem) then
        Player.levelingUp = true
        if (Player.level - 1) % 3 ~= 0 then
            uiOffset.x = 0
        end
    end

    if hasItem("Investment Guru") then
        if hasItem("Birthday Hat") then
            setItemShop({getItem("Long Term Investment"), getItem("Long Term Investment")})
        else
            setItemShop({getItem("Long Term Investment")})
        end
    -- elseif hasItem("Archeologist Hat") then
        -- local rarity = math.random(1,100) <= 75 and "rare" or "legendary"
        -- if hasItem("Birthday Hat") then
            -- setItemShop({getRandomItemOfRarity(rarity, math.random(1,100) <= 20), getRandomItemOfRarity(rarity, math.random(1,100) <= 20)})
        -- else
            -- setItemShop({getRandomItemOfRarity(rarity, math.random(1,100) <= 20)})
        -- end
    else
        setItemShop()
    end
end

local lastPopupTime = 0
local cumulatedXp = 0
function resetXpStuff()
    lastPopupTime = 0
    cumulatedXp = 0
end
function Player.gain(amount)
    amount = amount * Player.xpGainMult
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
    firstRunCompleted = true
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
        love.mouse.setVisible(true)
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
        if paddle.y > screenHeight + 25 then
            Player.hit()
            damageScreenVisuals(0.25, 100)
        end
    end
end

function Player.update(dt)
    checkForHit()
end

function Player.changeMoney(amnt, itemID)
    Player.realMoney = Player.realMoney + amnt;
    if amnt > 0 then
        gainMoneyWithAnimations(amnt, itemID)
    else
        gainMoneyWithAnimations(amnt, itemID)
    end
end

function Player.shiftMoneyValue(amnt)
    Player.hiddenMoney = Player.hiddenMoney + amnt;

    if Player.hiddenMoney < 0 then
        print("player spent more money then they had");
    end
end

function Player.setMoney(amnt)
    Player.hiddenMoney = amnt;
    Player.realMoney = amnt;
end

function Player.getMoney()
    return Player.hiddenMoney;
end

function Player.pay(amount)
    Player.changeMoney(-amount);
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
            self.hiddenMoney = self.startingMoney;
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