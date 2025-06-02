local upgradesUI = require("upgradesUI")

-- This file contains the player class, it manages his level, his abilities and his stats
local money = 0
damageThisFrame = 0
Player = {
    money = math.floor(money),
    score = 0,
    lives = 3,
    levelingUp = false,
    price = 1,
    newUpgradePrice = 100,
    upgradePriceMultScaling = 10,
    dead = false,
    bonuses = { -- These bonuses are percentages
    }
}

Player.bonusOrder = {}
Player.bonusPrice = {}
Player.bonusesList = {
    --income = {name = "income", description = "Money income", startingPrice = 50},
    speed = {name = "speed", description = "Ball speed", startingPrice = 100},
    paddleSize = {name = "paddleSize", description = "Paddle size", startingPrice = 100},
    damage = {name = "damage", description = "Damage boost", startingPrice = 100},
    ballDamage = {name = "ballDamage", description = "Ball damage boost", startingPrice = 100},
    bulletDamage = {name = "bulletDamage", description = "Bullet damage boost", startingPrice = 100},
    ammo = {name = "ammo", description = "Ammo boost", startingPrice = 100},
    range = {name = "range", description = "Range boost", startingPrice = 100},
    fireRate = {name = "fireRate", description = "Fire rate boost", startingPrice = 100},
    amount = {name = "amount", description = "Amount boost", startingPrice = 100},
}

Player.bonusUpgrades = {
    --income = function() Player.bonuses.income = Player.bonuses.income + 1 end,
    speed = function() Player.bonuses.speed = Player.bonuses.speed + 1 end,
    --paddleSpeed = function() Player.bonuses.paddleSpeed = Player.bonuses.paddleSpeed + 1
        --paddle.speed = paddle.speed + 200 end,
    paddleSize = function() Player.bonuses.paddleSize = Player.bonuses.paddleSize + 1 
        paddle.width = paddle.width+65 end,
    damage = function() Player.bonuses.damage = Player.bonuses.damage + 1 end,
    ballDamage = function() Player.bonuses.ballDamage = Player.bonuses.ballDamage + 2 end,
    bulletDamage = function() Player.bonuses.bulletDamage = Player.bonuses.bulletDamage + 2 end,
    ammo = function() Player.bonuses.ammo = Player.bonuses.ammo + 1 end,
    range = function() Player.bonuses.range = Player.bonuses.range + 1 end,
    fireRate = function() Player.bonuses.fireRate = Player.bonuses.fireRate + 1 end,
    amount = function() Player.bonuses.amount = Player.bonuses.amount + 1 
        local ballsToAdd = {}
        print("#unlocked ball types: " .. #Balls.getUnlockedBallTypes())
        for _, ballType in pairs(Balls.getUnlockedBallTypes()) do
            print("Ball type:", ballType.name)
            table.insert(ballsToAdd, ballType.name)
        end
        for _, ballName in ipairs(ballsToAdd) do
            print("Adding ball: " .. ballName)
            Balls.addBall(ballName)
        end
    end,
}

function Player.addBonus(name)
    Player.bonuses[name] = 0
    table.insert(Player.bonusOrder, name)
    Player.bonusPrice[name] = Player.bonusesList[name].startingPrice
    print("added bonus : ".. name ..  ", #Player.bonuses : " .. tableLength(Player.bonuses))
end

function Player.reset()
    Player.money = 0
    Player.lives = 3
    Player.levelingUp = false
    Player.price = 1
    Player.dead = false
    for name, bonus in pairs(Player.bonuses) do
        Player.bonuses[name] = 0
    end
end

function Player.die()
    toggleFreeze()
    Player.dead = true
end

local brickSpeedTween
function Player.hit()
    Player.lives = Player.lives - 1
    if Player.lives <= 0 then
        Player.die()
    end
    brickSpeed.value = -750
    brickSpeedTween = tween.new(2, brickSpeed, { value = 10 }, tween.outExpo)
    addTweenToUpdate(brickSpeedTween)

    print("Player hit! Lives left: " .. Player.lives)
end

local function checkForHit()
    for _, brick in ipairs(bricks) do
        if brick.y + brick.height > paddle.y then
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
    else
        error("Player tried to pay ".. amount.."but didn't habe enough money : "..Player.money)
    end
end

function Player.gain(amount)
    Player.money = Player.money + amount
    upgradesUI.tryQueue()
end

return Player