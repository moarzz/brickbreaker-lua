local BirthdayHat = ItemBase.new();
BirthdayHat.__index = BirthdayHat;
BirthdayHat.name = "Birthday Hat";
BirthdayHat.description = "<font=bold>on Level up<font=default> effects are doubled";
BirthdayHat.rarity = "legendary";

BirthdayHat.unique = true; -- does smthn ig

function BirthdayHat.new()
    local instance = setmetatable({}, BirthdayHat):init();

    return instance;
end

return BirthdayHat;