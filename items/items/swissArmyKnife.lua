local SwissArmyKnife = ItemBase.new();
SwissArmyKnife.__index = SwissArmyKnife;
SwissArmyKnife.name = "Swiss Army Knife";
SwissArmyKnife.description = "Increases all stats of your weapons by 1 (except <color=damage>damage<color=white>) and reduce cooldown by 1";
SwissArmyKnife.rarity = "uncommon";

SwissArmyKnife.descriptionOverwrite = true; -- does smthn ig

function SwissArmyKnife.new()
    local instance = setmetatable({}, SwissArmyKnife):init();

    instance.stats.fireRate = 1;
    instance.stats.speed    = 1;
    instance.stats.cooldown =-1;
    instance.stats.size     = 1;
    instance.stats.amount   = 1;
    instance.stats.range    = 1;
    instance.stats.ammo     = 1;

    return instance;
end

return SwissArmyKnife;