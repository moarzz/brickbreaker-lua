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
    newUpgradePrice = 5,
    upgradePriceMultScaling = 5,
    dead = false,
    bonuses = { -- These bonuses are percentages
    }
}

Player.bonusOrder = {}
Player.bonusPrice = {}
Player.bonusesList = {
    critChance = {name = "critChance", description = "Critical chance", startingPrice = 5},
    moneyIncome = {name = "moneyIncome", description = "Money income", startingPrice = 5},
    ballSpeed = {name = "ballSpeed", description = "Ball speed", startingPrice = 5},
    paddleSize = {name = "paddleSize", description = "Paddle size", startingPrice = 5},
    damage = {name = "damage", description = "Damage boost", startingPrice = 5},
    ballDamage = {name = "ballDamage", description = "Ball damage boost", startingPrice = 5},
    bulletDamage = {name = "bulletDamage", description = "Bullet damage boost", startingPrice = 5},
    ammo = {name = "ammo", description = "Ammo boost", startingPrice = 5},
    range = {name = "range", description = "Range boost", startingPrice = 5},
    fireRate = {name = "fireRate", description = "Fire rate boost", price = 5},
    pierce = {name = "pierce", description = "Pierce boost", price = 5},
    ammount = {name = "amount", description = "Amount boost", price = 10},
}

Player.bonusUpgrades = {
    critChance = function() Player.bonuses.critChance = Player.bonuses.critChance + 10 end,
    moneyIncome = function() Player.bonuses.moneyIncome = Player.bonuses.moneyIncome + 1 end,
    ballSpeed = function() Player.bonuses.ballSpeed = Player.bonuses.ballSpeed + 1 end,
    paddleSpeed = function() Player.bonuses.paddleSpeed = Player.bonuses.paddleSpeed + 1
        paddle.speed = paddle.speed + 200 end,
    paddleSize = function() Player.bonuses.paddleSize = Player.bonuses.paddleSize + 1 
        paddle.width = paddle.width+65 end,
    damage = function() Player.bonuses.damage = Player.bonuses.damage + 1 end,
    ballDamage = function() Player.bonuses.ballDamage = Player.bonuses.ballDamage + 2 end,
    bulletDamage = function() Player.bonuses.bulletDamage = Player.bonuses.bulletDamage + 2 end,
    ammo = function() Player.bonuses.ammo = Player.bonuses.ammo + 1 end,
    range = function() Player.bonuses.range = Player.bonuses.range + 1 end,
    fireRate = function() Player.bonuses.fireRate = Player.bonuses.fireRate + 1 end,
    pierce = function() Player.bonuses.pierce = Player.bonuses.pierce + 1 end,
    ammount = function() Player.bonuses.ammount = Player.bonuses.ammount + 1 
        for _, ballType in Balls.getUnlockedBallTypes() do
            Balls.addBall(ballType.name)
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
    Player.bonuses = { -- These bonuses are percentages
        critChance = 0,
        moneyIncome = 0,
        ballSpeed = 0,
        paddleSpeed = 0,
        paddleSize = 0
    }
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
end

return Player