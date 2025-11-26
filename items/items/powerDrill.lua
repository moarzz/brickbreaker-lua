local PowerDrill = ItemBase.new();
PowerDrill.__index = PowerDrill;
PowerDrill.name = "Power Drill";
PowerDrill.description = "Choose a random weapon\n randomly upgrade two of its stats";
PowerDrill.rarity = "common";
PowerDrill.imageReference = "assets/sprites/UI/ItemIcons/Power-Drill.png";

PowerDrill.consumable = true; -- does smthn ig

function PowerDrill.new()
    local instance = setmetatable({}, PowerDrill):init();

    return instance;
end

function PowerDrill:purchase()
    local unlockedWeapons = WeaponHandler.getActiveWeapons();

    if #unlockedWeapons == 0 then
        return;
    end

    -- Select a random weapon
    local randomWeaponIndex = math.random(1, #unlockedWeapons);
    local selectedWeapon = unlockedWeapons[randomWeaponIndex];

    if not selectedWeapon then
        return;
    end

    for i = 1, 2 do
        local statList = {};
        for statName, _ in pairs(selectedWeapon.stats) do
            table.insert(statList, statName);
        end
        if selectedWeapon.type == "ball" then
            table.insert(statList, "amount")
        end
        local statNotAmmo = true;
        local statToUpgrade = "damage"
        while statNotAmmo do
            statToUpgrade = statList[math.random(1, #statList)];
            if statToUpgrade ~= "ammo" then
                statNotAmmo = false;
            end
        end

        gainStatWithAnimation(statToUpgrade, selectedWeapon.name);
    end
end

return PowerDrill;