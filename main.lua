require "Player"
require "Bullet"
require "Enemy"
require "EnemyBullet"

-- Game initialization
function love.load()
    -- Screen layout
    screenWidth = love.graphics.getWidth()
    screenHeight = love.graphics.getHeight()
    gameAreaWidth = screenWidth * 0.8  -- 80% of screen width for game
    statsPanelWidth = screenWidth * 0.2  -- 20% of screen width for stats
    
    -- Stats tracking
    gameTime = 0
    enemiesDefeated = 0
    
    player = Player:new()
    bullets = {}  -- Table to store player bullets
    enemies = {}  -- Table to store enemies
    enemyBullets = {}  -- Table to store enemy bullets
    
    spawnTimer = 0
    spawnDelay = 3  -- Spawn enemy every 3 seconds
    
    -- Create initial enemies
    table.insert(enemies, Enemy:new(200, 50, 40, 40, 3, {0, 0.5, 1}, "circle"))
    table.insert(enemies, Enemy:new(400, 100, 40, 40, 3, {1, 0.3, 0.7}, "spiral"))
    table.insert(enemies, Enemy:new(600, 50, 40, 40, 3, {0.2, 0.8, 0.2}, "aimed"))
end

-- Game update
function love.update(dt)
    -- Update game time
    gameTime = gameTime + dt
    
    -- Update player
    player:update(dt)
    
    -- Constrain player to game area
    if player.x + player.width > gameAreaWidth then
        player.x = gameAreaWidth - player.width
    end
    
    -- Update player bullets
    for i = #bullets, 1, -1 do
        local bullet = bullets[i]
        bullet:update(dt)
        
        -- Check for collision with enemies
        for j = #enemies, 1, -1 do
            local enemy = enemies[j]
            if checkCollision(bullet, enemy) then
                enemy:takeDamage()
                table.remove(bullets, i)
                
                -- If enemy dies from this hit, increment counter
                if enemy.health <= 0 then
                    enemiesDefeated = enemiesDefeated + 1
                end
                
                break
            end
        end
        
        -- Remove bullets that go off screen or into stats panel
        if bullet:isOffScreen() or bullet.x + bullet.width > gameAreaWidth then
            table.remove(bullets, i)
        end
    end
    
    -- Update enemies
    for i = #enemies, 1, -1 do
        local enemy = enemies[i]
        enemy:update(dt)
        
        -- Remove enemies that are dead or move into stats panel
        if not enemy.alive or enemy.x > gameAreaWidth then
            table.remove(enemies, i)
        end
    end
    
    -- Update enemy bullets
    for i = #enemyBullets, 1, -1 do
        local bullet = enemyBullets[i]
        bullet:update(dt)
        
        -- Check for collision with player
        if checkCollision(bullet, player) then
            -- Implement player damage here
            table.remove(enemyBullets, i)
        -- Remove bullets that go off screen or into stats panel
        elseif bullet:isOffScreen() or bullet.x > gameAreaWidth then
            table.remove(enemyBullets, i)
        end
    end
    
    -- Spawn new enemies
    spawnTimer = spawnTimer + dt
    if spawnTimer >= spawnDelay then
        spawnEnemy()
        spawnTimer = 0
    end
end

-- Game drawing
function love.draw()
    -- Set scissor to limit drawing to game area only
    love.graphics.setScissor(0, 0, gameAreaWidth, screenHeight)
    
    -- Draw enemies
    for _, enemy in ipairs(enemies) do
        enemy:draw()
    end
    
    -- Draw enemy bullets
    for _, bullet in ipairs(enemyBullets) do
        bullet:draw()
    end
    
    -- Draw player
    player:draw()
    
    -- Draw player bullets
    for _, bullet in ipairs(bullets) do
        bullet:draw()
    end
    
    -- Reset scissor
    love.graphics.setScissor()
    
    -- Draw stats panel
    drawStatsPanel()
end

-- Draw the stats panel on the right side
function drawStatsPanel()
    -- Draw background for stats panel
    love.graphics.setColor(0.1, 0.1, 0.2)
    love.graphics.rectangle("fill", gameAreaWidth, 0, statsPanelWidth, screenHeight)
    
    -- Draw separator line
    love.graphics.setColor(0.5, 0.5, 0.8)
    love.graphics.setLineWidth(2)
    love.graphics.line(gameAreaWidth, 0, gameAreaWidth, screenHeight)
    
    -- Reset color for text
    love.graphics.setColor(1, 1, 1)
    
    -- Draw title
    love.graphics.printf("GAME STATS", gameAreaWidth, 20, statsPanelWidth, "center")
    
    -- Format game time (minutes:seconds)
    local minutes = math.floor(gameTime / 60)
    local seconds = math.floor(gameTime % 60)
    local timeString = string.format("%02d:%02d", minutes, seconds)
    
    -- Draw stats with consistent spacing for easy additions
    local yPos = 60
    local lineHeight = 30
    
    -- Time stat
    love.graphics.printf("Time:", gameAreaWidth + 10, yPos, statsPanelWidth - 20, "left")
    love.graphics.printf(timeString, gameAreaWidth + 10, yPos, statsPanelWidth - 20, "right")
    yPos = yPos + lineHeight
    
    -- Enemies defeated stat
    love.graphics.printf("Enemies:", gameAreaWidth + 10, yPos, statsPanelWidth - 20, "left")
    love.graphics.printf(tostring(enemiesDefeated), gameAreaWidth + 10, yPos, statsPanelWidth - 20, "right")
    yPos = yPos + lineHeight
    
    -- Add more stats here as needed, following the pattern:
    -- love.graphics.printf("Label:", gameAreaWidth + 10, yPos, statsPanelWidth - 20, "left")
    -- love.graphics.printf(value, gameAreaWidth + 10, yPos, statsPanelWidth - 20, "right")
    -- yPos = yPos + lineHeight
    
    -- Reset line width
    love.graphics.setLineWidth(1)
end

function spawnEnemy()
    local patterns = {"circle", "spiral", "aimed"}
    local pattern = patterns[love.math.random(1, #patterns)]
    local colors = {
        {0, 0.5, 1},    -- Blue
        {1, 0.3, 0.7},  -- Pink
        {0.2, 0.8, 0.2}, -- Green
        {1, 0.6, 0},    -- Orange
        {0.7, 0, 1}     -- Purple
    }
    -- Ensure enemies spawn within game area boundary
    local x = love.math.random(50, gameAreaWidth - 90)
    
    table.insert(enemies, Enemy:new(x, 0, 40, 40, 3, color, pattern))
end

function checkCollision(a, b)
    return a.x < b.x + b.width and
           a.x + a.width > b.x and
           a.y < b.y + b.height and
           a.y + a.height > b.y
end