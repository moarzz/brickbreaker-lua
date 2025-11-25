local Mechanic = ItemBase.new();
Mechanic.__index = Mechanic;
Mechanic.name = "Mechanic";
Mechanic.description = "<font=bold>on level up<font=default>\npay <color=money>2$<color=white> and then upgrade a random stat from a random weapon twice";
Mechanic.rarity = "common";
Mechanic.imageReference = "assets/sprites/UI/ItemIcons/Mechanic.png";

function Mechanic.new()
    local instance = setmetatable({}, Mechanic):init();

    return instance;
end

function Mechanic.events:levelUp()
    Player.changeMoney(-2, self.id)
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
    for i=1, 2 do
        local statNotAmmo = true;
        local statToUpgrade = "damage"
        while statNotAmmo do
            statToUpgrade = statList[math.random(1, #statList)];
            if statToUpgrade ~= "ammo" then
                statNotAmmo = false;
            end
        end

        gainStatWithAnimation(statToUpgrade, selectedWeapon.name, self.id)

        print("Upgraded " .. selectedWeapon.name .. "'s " .. statToUpgrade .. " by 1!");
    end
end

return Mechanic;