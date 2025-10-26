local Omnipotence = ItemBase.new();
Omnipotence.__index = Omnipotence;
Omnipotence.name = "Omnipotence";
Omnipotence.description = "Increases all stats of your weapons by 3";
Omnipotence.rarity = "legendary";

function Omnipotence.new()
    local instance = setmetatable({}, Omnipotence):init();

    instance.stats.speed    = 3;
    instance.stats.damage   = 3;
    instance.stats.cooldown =-3;
    instance.stats.size     = 3;
    instance.stats.amount   = 3;
    instance.stats.range    = 3;
    instance.stats.fireRate = 3;
    instance.stats.ammo     = 3;

    return instance;
end

return Omnipotence;