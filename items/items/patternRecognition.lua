local PatternRecognition = ItemBase.new();
PatternRecognition.__index = PatternRecognition;
PatternRecognition.name = "Pattern Recognition";
PatternRecognition.description = "<font=bold>On Damage Dealt<font=default>\ndeal damage to another brick with the same health (if there is one)";
PatternRecognition.rarity = "rare";
PatternRecognition.imageReference = "assets/sprites/UI/ItemIcons/Pattern-Recognition.png";

PatternRecognition.unique = true; -- does smthn ig

function PatternRecognition.new()
    local instance = setmetatable({}, PatternRecognition):init();

    return instance;
end

function PatternRecognition:onDamageDealt(originalHealth, damageDealt)
    -- Find another brick with the same health as originalHealth
    for _, brick in ipairs(bricks) do
        if brick.health == originalHealth and brick.health > 0 and brick.y > -brick.height then
            -- Deal damage to that brick
            dealDamage({stats = {damage = damageDealt}}, brick, nil, true);
            -- Optionally, you can add some visual or sound effect here to indicate the damage
            break -- Only affect one brick
        end
    end
end

return PatternRecognition;