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
        permanentUpgradePrices = {
            amount = 100,
            speed = 100,
            damage = 100,
            -- ... other default prices
        },
        startingItems = {"Ball", "Pistol", "Nothing"},
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
                data.permanentUpgradePrices = fileData.permanentUpgradePrices or data.permanentUpgradePrices
                data.startingItems = fileData.startingItems or data.startingItems
            end
        end
    end
    -- Update Player object directly
    Player.highScore = data.highScore
    Player.gold = data.gold
    Player.startingMoney = data.startingMoney
    Player.permanentUpgrades = data.permanentUpgrades
    Player.permanentUpgradePrices = data.permanentUpgradePrices
    Player.startingItems = data.startingItems

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

Player = {
    money = 0,
    startingMoney = 0,
    gold = 0,
    score = 0,
    highScore = 0,
    lives = 2,
    levelingUp = false,
    price = 1,
    newUpgradePrice = 100,
    upgradePriceMultScaling = 10,
    dead = false,
    lastHitTime = 0,    permanentUpgrades = {}, -- Store permanent upgrades
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
    },
    bonuses = { -- These bonuses are percentages
    },
    perks = {},
    level = 1,
    xp = 0,
    levelThresholds = {5000, 50000}, -- XP needed for each level
}
-- Save game data to file        l
function saveGameData()
    local data = {
        highScore = Player.highScore,
        gold = Player.gold,
        startingMoney = Player.startingMoney,
        permanentUpgrades = {
            paddleSize = Player.permanentUpgrades.paddleSize or 0,
            paddleSpeed = Player.permanentUpgrades.paddleSpeed or 0,
            -- Keep other upgrades...
            speed = Player.permanentUpgrades.speed or 0,
            damage = Player.permanentUpgrades.damage or 0,
            --ballDamage = Player.permanentUpgrades.ballDamage or 0,
            --bulletDamage = Player.permanentUpgrades.bulletDamage or 0,
            cooldown = Player.permanentUpgrades.cooldown or 0,
            fireRate = Player.permanentUpgrades.fireRate or 0,
            ammo = Player.permanentUpgrades.ammo or 0,
            range = Player.permanentUpgrades.range or 0,
            amount = Player.permanentUpgrades.amount or 0
        },
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
    Player.highScore = gameData.highScore
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
    paddleSize = {name = "paddleSize", description = "Paddle size", startingPrice = 100},
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
    paddleSize = 100, -- This is now handled in permanentUpgrades.lua
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
        paddle.width = paddle.width + 75
        paddle.x = math.max(paddle.x - 37.5, statsWidth)  -- Adjust position to keep it centered
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
        paddle.width = paddle.width + 25
        paddle.x = math.max(paddle.x - 25, statsWidth)  -- Adjust position to keep it centered
        Player.permanentUpgrades.paddleSize = (Player.permanentUpgrades.paddleSize or 0) + 1
    end,
    
    paddleSpeed = function()
        Player.permanentUpgrades.paddleSpeed = (Player.permanentUpgrades.paddleSpeed or 0) + 1
        paddle.speed = paddle.speed + 75
    end,
}

Player.perksList = {
    --[[superSpeed = {name = "superSpeed", description = "doubles ball speed. if amount <= 3"},
    cellularDivision = {name = "cellularDivision", description = "doubles amount. damage is halved."},
    warriorSpirit = {name = "warriorSpirit", description = "doubles damage. speed is halved."},]]
    bulletStorm = {name = "bulletStorm", description = "doubles fire rate."},
    explosiveBullets = {name = "explosiveBullets", description = "bullets explode on impact, dealing damage to nearby bricks.", 
        onUnlock = function()
            print("Explosive bullets perk unlocked!")
            Player.perks.explosiveBullets = true
        end
    },
    multishot = {
        name = "multishot",
        description = "Bullets split into three projectiles after traveling a short distance. Bullet damage is reduced by 50% rounded up."
    },
    speedBounce = {name = "speedBounce", description = "Temporarily increases ball speed on bounce."},
    techSupremacy = {name = "techSupremacy", description = "doubles damage of all tech items"},
    brickBreaker = {
        name = "brickBreaker",
        description = "5% chance to instantly destroy any small brick regardless of health when they take damage"
    },
    paddleSquared = {
        name = "paddleSquared",
        description = "paddleBounce effects trigger twice"
    },
    --[[timeKeeper = {
        name = "timeKeeper",
        description = "all cooldown are reduced by 50% (rounded up).",
    },
    phantomBullets = {
        name = "phantomBullets",
        description = "Bullets pass through bricks without losing damage, but deal 50% damage to them (rounded up)."
    },
    particle accelerator = {
        name = "particleAccelerator",
        description = "Increases the speed of everything aside from the bricks by 50%"
    },
    popBounce = {name = "popBounce", description = "on paddleBounce, deal DAMAGE to a random brick."},
    chainReaction = {
        name = "Chain Reaction",
        description = "When a brick is destroyed, adjacent bricks take DAMAGE damage"
    },]]
}

Player.perkUpgrades = {
    superSpeed = function()
        Player.bonuses.speed = (Player.bonuses.speed or 0) * 2
    end,
    
    cellularDivision = function()
        Player.bonuses.amount = (Player.bonuses.amount or 0) * 2
        Player.bonuses.damage = (Player.bonuses.damage or 0) / 2
        Balls.amountIncrease()
    end,
    
    warriorSpirit = function()
        Player.bonuses.damage = (Player.bonuses.damage or 0) * 2
        Player.bonuses.speed = (Player.bonuses.speed or 0) / 2
    end,
    
    bulletStorm = function()
        Player.perks.bulletStorm = true
        print("bullet storm perk unlocked!")
    end,
    
    explosiveBullets = function()
        print("got explosive bullet.")
        Player.perks.explosiveBullets = true
    end,

    timeKeeper = function()
        Player.perks.timeKeeper = true
    end,
    
    speedBounce = function()
        Player.perks.speedBounce = true
    end,

    techSupremacy = function() 
        Player.perks.techSupremacy = true
    end,
    
    popBounce = function()
        Player.perks.popBounce = true
    end,
    
    brickBreaker = function()
        Player.perks.brickBreaker = true
    end,
    
    paddleSquared = function()
        Player.perks.paddleSquared = true
    end,
    
    multishot = function()
        Player.perks.multishot = true
        print("multishot perk unlocked!")
    end,
    
    magneticField = function()
        Player.perks.magneticField = true
    end,
    
    chainReaction = function()
        Player.perks.chainReaction = true
    end
}

function Player.addBonus(name)
    Player.bonuses[name] = 0
    table.insert(Player.bonusOrder, name)
    Player.bonusPrice[name] = Player.bonusesList[name].startingPrice
    print("added bonus : ".. name ..  ", #Player.bonuses : " .. tableLength(Player.bonuses))
end

function Player.addPerk(name)
    -- Add the perk to the player's perks table if it doesn't exist
    if not Player.perks[name] then
        Player.perks[name] = true
        -- Call the perk's upgrade function if it exists
        if Player.perkUpgrades[name] then
            Player.perkUpgrades[name]()
        end
        print("Added perk: " .. name)
    else
        print("Player already has perk: " .. name)
    end
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
    Player.lives = 3
    Player.levelingUp = false
    Player.price = 1
    Player.dead = false
    Player.bonuses = {} -- Clear the bonuses table first
    Player.perks = {} -- Clear the perks table
    Player.bonusOrder = {} -- Clear the bonus order
    Player.bonusPrice = {} -- Clear the bonus prices
    
    -- Initialize default bonuses from bonusesList
    Player.bonuses = {}

    Player.levelingUp = false
    Player.dead = false
    Player.money = Player.startingMoney or 0
end

function Player.gain(amount)
    Player.money = Player.money + amount
    Player.score = Player.score + amount
    Player.xp = Player.score -- XP follows score
    saveGameData()
    upgradesUI.tryQueue()
end

function Player.addGold(amount)
    Player.gold = Player.gold + amount
    saveGameData()
end
newHighScore = false
function Player.die()
    -- Check and update high score
    if Player.score > Player.highScore then
        Player.highScore = Player.score
        newHighScore = true
    end

    -- Calculate gold earned based on score
    local goldEarned = math.floor(2 * math.sqrt(Player.score))
    Player.addGold(goldEarned)
    toggleFreeze()
    Player.dead = true
    saveGameData()  -- Save the new high score
end

local brickSpeedTween
local canTakeDamage = true
function Player.hit()
    if canTakeDamage then
        canTakeDamage = false
        Timer.after(4, function() canTakeDamage = true end)
        Player.lives = Player.lives - 1
        Player.lastHitTime = love.timer.getTime()
        if Player.lives <= 0 then
            Player.die()
        end
        brickSpeed.value = -300 / getBrickSpeedByTime()
        brickSpeedTween = tween.new(2, brickSpeed, { value = 10 }, tween.outExpo)
        addTweenToUpdate(brickSpeedTween)

        print("Player hit! Lives left: " .. Player.lives)
    end
end

local function checkForHit()
    for _, brick in ipairs(bricks) do
        if brick.y + brick.height > screenHeight - brickHeight * 6 + paddle.height then
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
        Player.money = Player.money - amount
        saveGameData()
    else
        error("Player tried to pay ".. amount.."but didn't have enough money : "..Player.money)
    end
end

function Player:save()    local saveData = {
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
                self.permanentUpgrades.paddleSize = data.permanentUpgrades.paddleSize or 0
                self.permanentUpgrades.paddleSpeed = data.permanentUpgrades.paddleSpeed or 0
            end
        end
    end
end

-- This existing code in Balls.lua already handles explosive bullets
if Player.perks.explosiveBullets then
    -- Create explosion effect
    local scale = (bullet.stats.damage * 0.5)
    createSpriteAnimation(bullet.x, bullet.y, scale/3, explosionVFX, 512, 512, 0.02, 5)
    playSoundEffect(explosionSFX, 0.3 + scale * 0.2, math.max(1 - scale * 0.1, 0.1), false, true)
    
    -- Damage nearby bricks
    local radius = bullet.stats.damage * 24 -- Explosion radius based on bullet damage
    local bricksTouchingCircle = getBricksTouchingCircle(bullet.x, bullet.y, radius)
    for _, touchingBrick in ipairs(bricksTouchingCircle) do
        if touchingBrick ~= brick then -- Don't hit the same brick twice
            dealDamage(bullet, touchingBrick)
        end
    end
end

return Player