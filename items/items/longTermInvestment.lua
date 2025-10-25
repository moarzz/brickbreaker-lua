local LongTermInvestment = ItemBase.new();
LongTermInvestment.__index = LongTermInvestment;
LongTermInvestment.name = "Long Term Investment";
LongTermInvestment.description = "Gain <color=money><font=big><longTermValue>$<color=white><font=default>\nIncrease the <color=money>$<color=white> gain of every future \n<font=big>Long Term Investment<font=default> by <color=money>1$<color=white> (max <color=money>20$<color=white>)";
LongTermInvestment.rarity = "common";

LongTermInvestment.consumable = true; -- does smthn ig
LongTermInvestment.descriptionOverwrite = true;

function LongTermInvestment.new()
    local instance = setmetatable({}, LongTermInvestment):init();

    return instance;
end

function LongTermInvestment:purchase()
    if not hasItem("Abandon Greed") then
        Player.money = Player.money + longTermInvestment.value;
        richGetRicherUpdate(Player.money - longTermInvestment.value, Player.money);
    end

    longTermInvestment.value = math.min(20, longTermInvestment.value + 1);
    print("Long Term Investment value increased to " .. longTermInvestment.value);
end

return LongTermInvestment;