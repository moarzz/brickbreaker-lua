function love.conf(t)
    t.identity = 'brickbreaker-lua'
    t.version = "11.4"
    
    t.console = true

    -- Window settings
    t.window.title = "Brick Breaker"
    t.window.width = 960
    t.window.height = 540
    t.window.fullscreen = false
    t.window.vsync = 0
    t.window.resizable = true
    
    -- Web-specific settings
    t.window.highdpi = false  -- Important for web scaling
end