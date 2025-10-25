local LoadedDice = ItemBase.new();
LoadedDice.__index = LoadedDice;
LoadedDice.name = "Loaded Dice";
LoadedDice.description = "rerollPrice starts at <color=money>0$";
LoadedDice.rarity = "common";

LoadedDice.unique = true; -- does smthn ig

function LoadedDice.new()
    local instance = setmetatable({}, LoadedDice):init();

    return instance;
end

function LoadedDice:purchase()
    rerollPrice = 0; -- this is nit a global. fix it
end

return LoadedDice;