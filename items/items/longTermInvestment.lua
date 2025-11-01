local LongTermInvestment = ItemBase.new();
LongTermInvestment.__index = LongTermInvestment;
LongTermInvestment.name = "Long Term Investment";
LongTermInvestment.description = "+<color=money>1$<color=white> interest per level";
LongTermInvestment.rarity = "common";
LongTermInvestment.imageReference = "assets/sprites/UI/ItemIcons/Long-Term-Investment.png";

LongTermInvestment.consumable = true; -- does smthn ig
LongTermInvestment.descriptionOverwrite = true;

function LongTermInvestment.new()
    local instance = setmetatable({}, LongTermInvestment):init();
    instance.descriptionPointers = { longTermValue = longTermInvestment.value } 

    return instance;
end

function LongTermInvestment:purchase()
    if not hasItem("Abandon Greed") then
        -- Player.changeMoney(longTermInvestment.value, self.id);
        -- Player.money = Player.money + longTermInvestment.value;
        -- richGetRicherUpdate(Player.money - longTermInvestment.value, Player.money);
    end

    longTermInvestment.value = math.min(10, longTermInvestment.value + 1);
    print("Long Term Investment value increased to " .. longTermInvestment.value);
end

return LongTermInvestment;