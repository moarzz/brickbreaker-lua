local AssassinsDagger = ItemBase.new();
AssassinsDagger.__index = AssassinsDagger;
AssassinsDagger.name = "Assassin's Dagger";
AssassinsDagger.description = "Damage has a <font=bold><critChance>%<font=default> chance to be doubled";
AssassinsDagger.rarity = "uncommon";
AssassinsDagger.imageReference = "assets/sprites/UI/itemIcons/Assassin's-Dagger.png";

AssassinsDagger.unique = true; -- does smthn ig


function AssassinsDagger.new()
    local instance = setmetatable({}, AssassinsDagger):init();

    instance.descriptionPointers = {
        critChance = hasItem("Four Leafed Clover") and 70 or 35;
    };

    instance.stats.damage = 2;

    return instance;
end

function AssassinsDagger.events:item_purchase_FourLeafedClover()
    self.descriptionPointers.critChance = 70;
end

function AssassinsDagger.events:item_sell_FourLeafedClover()
    self.descriptionPointers.critChance = 35;
end

return AssassinsDagger;