local ShadownBall = BallBase.new();
ShadownBall.__index = ShadownBall;
ShadownBall.name = "Shadow Ball";
ShadownBall.type = "spell";
ShadownBall.description = "shoots shadowBalls that pass through bricks. Very slow fire rate.";
ShadownBall.rarity = "uncommon";
ShadownBall.startingPrice = 25;
ShadownBall.size = 1;
ShadownBall.stats = {
    damage = 1;
    range = 2;
    fireRate = 3;
};

ShadownBall.trail = Trail.new(10, 50);

function ShadownBall.new()
    local instance = setmetatable({}, ShadownBall):init();

    return instance;
end

function ShadownBall:onBuy()
    --[[
    Timer.after(0.15, function()
        cast("Shadow Ball")
    end)
    ]]
end

return ShadownBall;