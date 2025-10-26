local PhantomBullets = ItemBase.new();
PhantomBullets.__index = PhantomBullets;
PhantomBullets.name = "Phantom Bullets";
PhantomBullets.description = "Bullets only lose 1 dmg when they pass through bricks\nBullets start with half damage";
PhantomBullets.rarity = "rare";
PhantomBullets.imageReference = "assets/sprites/UI/itemIcons/Phantom-Bullets.png";

PhantomBullets.unique = true; -- does smthn ig

function PhantomBullets.new()
    local instance = setmetatable({}, PhantomBullets):init();

    return instance;
end

return PhantomBullets;