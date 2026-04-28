local ChallengeRuns = {
    {
        name = "pincer offensive",
        description = "bricks come from the bottom of the screen as well. If any reach the middle, you lose.",
    },
    {
        name = "capitalism",
        description = "you cannot upgrade your weapons. start with +1 damage. items cost 2$ less",
    },
    {
        name = "fervor of battle", -- multiply the time until next heal by 0.9735 every time you heal with a minimum of like 0.5 or some shit
        description = "every 20 seconds, every brick gains 1hp and this number increases by 1."
    }
}

return ChallengeRuns