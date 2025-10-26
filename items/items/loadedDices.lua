local LoadedDice = ItemBase.new();
LoadedDice.__index = LoadedDice;
LoadedDice.name = "Loaded Dice";
LoadedDice.description = "rerollPrice starts at <color=money>0$";
LoadedDice.rarity = "common";
LoadedDice.imageReference = "assets/sprites/UI/itemIcons/Loaded-Dices.png";

LoadedDice.unique = true; -- does smthn ig

function LoadedDice.new()
    local instance = setmetatable({}, LoadedDice):init();

    return instance;
end

function LoadedDice:purchase()
    setRerollPrice(0);
end

return LoadedDice;