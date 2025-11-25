local PaddleDefenseSystem = ItemBase.new();
PaddleDefenseSystem.__index = PaddleDefenseSystem;
PaddleDefenseSystem.name = "Paddle Defense System";
PaddleDefenseSystem.description = "<font=bold>On ball bounce with paddle<font=default>\nshoot a bullet of that ball's <color=damage>damage";
PaddleDefenseSystem.rarity = "common";
PaddleDefenseSystem.imageReference = "assets/sprites/UI/ItemIcons/Paddle-Defense-System.png";

PaddleDefenseSystem.unique = true; -- does smthn ig

function PaddleDefenseSystem.new()
    local instance = setmetatable({}, PaddleDefenseSystem):init();

    -- instance.stats.speed = 1;

    return instance;
end

return PaddleDefenseSystem;