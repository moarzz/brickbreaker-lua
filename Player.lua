local upgradesUI = require("upgradesUI")

-- This file contains the player class, it manages his level, his abilities and his stats
local money = 0
Player = {
    money = math.floor(money),
    lives = 3,
    levelingUp = false,
    price = 1,
    dead = false,
    bonuses = { -- These bonuses are percentages
        critChance = 0,
        moneyIncome = 0,
        ballSpeed = 0,
        paddleSpeed = 0,
        paddleSize = 0
    }
}

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

local brickSpeedAfterHit = 500
local brickSpeedTween
function Player.hit()
    Player.lives = Player.lives - 1
    if Player.lives <= 0 then
        Player.die()
    end
    brickSpeed.value = -brickSpeedAfterHit
    brickSpeedTween = tween.new(2, brickSpeed, { value = 10 }, tween.outQuad)
    addTweenToUpdate(brickSpeedTween)
    print("Player hit! Lives left: " .. Player.lives)
end

local function checkForHit()
    for _, brick in ipairs(bricks) do
        if brick.y + brick.height > paddle.y + paddle.height/2 then
            Player.hit()
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

Player.bonusUpgrades = {
    critChance = function() Player.bonuses.critChance = Player.bonuses.critChance + 5 end,
    moneyIncome = function() Player.bonuses.moneyIncome = Player.moneyIncome + 5 end,
    ballSpeed = function() Player.bonuses.ballSpeed = Player.bonuses.ballSpeed + 5 end,
    paddleSpeed = function() Player.bonuses.paddleSpeed = Player.bonuses.paddleSpeed + 50
        paddle.speed = paddle.speed + 200 end,
    paddleSize = function() Player.bonuses.paddleSize = Player.bonuses.paddleSize + 25 
        paddle.width = paddle.width+32.5 end
}

return Player