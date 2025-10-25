local Mechanic = ItemBase.new();
Mechanic.__index = Mechanic;
Mechanic.name = "Mechanic";
Mechanic.description = "<font=bold>on level up<font=default>\nupgrade a random stat from a random weapon";
Mechanic.rarity = "common";

function Mechanic.new()
    local instance = setmetatable({}, Mechanic):init();

    return instance;
end

function Mechanic.events:levelUp()
    local unlockedWeapons = Balls.getUnlockedBallTypes()
    if tableLength(unlockedWeapons) == 0 then
        return;
    end

    -- Select a random weapon
    local randomWeaponIndex = math.random(1, tableLength(unlockedWeapons));
    local selectedWeapon;
    local i = 1;

    for _, weapon in pairs(unlockedWeapons) do
        if i == randomWeaponIndex then
            selectedWeapon = weapon;
            break;
        end

        i = i + 1;
    end

    if not selectedWeapon then
        return;
    end

    local statList = {}
    for statName, _ in pairs(selectedWeapon.stats) do
        table.insert(statList, statName)
    end
    local statToUpgrade = statList[math.random(1, #statList)]

    gainStatWithAnimation(statToUpgrade, selectedWeapon.name)

    print("Upgraded " .. selectedWeapon.name .. "'s " .. statToUpgrade .. " by 1!");
end

return Mechanic;