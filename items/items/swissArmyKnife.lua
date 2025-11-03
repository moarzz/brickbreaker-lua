local SwissArmyKnife = ItemBase.new();
SwissArmyKnife.__index = SwissArmyKnife;
SwissArmyKnife.name = "Swiss Army Knife";
SwissArmyKnife.description = "Increases all stats of your weapons by 1 and reduce cooldown by 1";
SwissArmyKnife.rarity = "uncommon";
SwissArmyKnife.imageReference = "assets/sprites/UI/ItemIcons/Swiss-Army-Knife.png";

SwissArmyKnife.descriptionOverwrite = true; -- does smthn ig

function SwissArmyKnife.new()
    local instance = setmetatable({}, SwissArmyKnife):init();

    instance.stats.fireRate = 1;
    instance.stats.speed    = 1;
    instance.stats.cooldown =-1;
    instance.stats.damage     = 1;
    instance.stats.amount   = 1;
    instance.stats.range    = 1;
    instance.stats.ammo     = 1;

    return instance;
end

return SwissArmyKnife;