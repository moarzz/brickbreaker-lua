local PowerDrill = ItemBase.new();
PowerDrill.__index = PowerDrill;
PowerDrill.name = "Power Drill";
PowerDrill.description = "Choose a random weapon\n randomly upgrade two of its stats";
PowerDrill.rarity = "common";

PowerDrill.consumable = true; -- does smthn ig

function PowerDrill.new()
    local instance = setmetatable({}, PowerDrill):init();

    return instance;
end

function PowerDrill:purchase()
    local unlockedWeapons = Balls.getUnlockedBallTypes();

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

    for i = 1, 2 do
        local statList = {};
        for statName, _ in pairs(selectedWeapon.stats) do
            table.insert(statList, statName);
        end
        local statToUpgrade = statList[math.random(1, #statList)];

        gainStatWithAnimation(statToUpgrade, selectedWeapon.name);
    end
end

return PowerDrill;