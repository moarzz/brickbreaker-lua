local PaddleDefenseSystem = ItemBase.new();
PaddleDefenseSystem.__index = PaddleDefenseSystem;
PaddleDefenseSystem.name = "Paddle Defense System";
PaddleDefenseSystem.description = "<font=bold>On ball bounce with paddle<font=default>\nshoot a bullet that deals <color=damage>damage<color=white> equal to that ball's <color=damage>damage";
PaddleDefenseSystem.rarity = "uncommon";

PaddleDefenseSystem.unique = true; -- does smthn ig

function PaddleDefenseSystem.new()
    local instance = setmetatable({}, PaddleDefenseSystem):init();

    instance.stats.speed = 2;

    return instance;
end

return PaddleDefenseSystem;