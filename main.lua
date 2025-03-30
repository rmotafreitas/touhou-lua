require "Player"
require "Bullet"
require "Enemy"
require "EnemyBullet"
require "ScoreManager"  -- Add this line

-- Game state management
local gameState = "game"  -- Initial state: "game", "gameover"
local newHighScore = false  -- Track if player achieved a new high score

-- Game initialization
function love.load()
    -- Screen layout
    screenWidth = love.graphics.getWidth()
    screenHeight = love.graphics.getHeight()
    gameAreaWidth = screenWidth * 0.8  -- 80% of screen width for game
    statsPanelWidth = screenWidth * 0.2  -- 20% of screen width for stats
    
    -- Initialize score manager
    ScoreManager.init()
    
    -- Initialize game
    resetGame()
end

-- Reset all game variables to start a new game
function resetGame()
    -- Stats tracking
    gameTime = 0
    enemiesDefeated = 0
    score = 0
    newHighScore = false
    
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
    if gameState == "game" then
        updateGame(dt)
    elseif gameState == "gameover" then
        -- Simple update for game over screen (could add animations later)
        if love.keyboard.isDown("return") or love.keyboard.isDown("space") then
            resetGame()
            gameState = "game"
        end
    end
end

-- Update function for the active game
function updateGame(dt)
    -- Check for game over
    if player.lives <= 0 then
        -- Check for high score before transitioning to game over
        newHighScore = ScoreManager.updateHighScore(score)
        gameState = "gameover"
        return
    end

    -- Update game time
    gameTime = gameTime + dt
    
    -- Add small amount of score for surviving (10 points per second)
    score = score + (10 * dt)
    
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
                
                -- If enemy dies from this hit, increment counter and add score
                if enemy.health <= 0 then
                    enemiesDefeated = enemiesDefeated + 1
                    
                    -- Award points based on enemy type
                    if enemy.patternType == "circle" then
                        score = score + 100
                    elseif enemy.patternType == "spiral" then
                        score = score + 150
                    elseif enemy.patternType == "aimed" then
                        score = score + 200
                    else
                        score = score + 50
                    end
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
            -- Player takes damage when hit
            player:takeDamage()
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
    if gameState == "game" then
        drawGame()
    elseif gameState == "gameover" then
        drawGameOver()
    end
end

-- Draw function for the active game
function drawGame()
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

-- Draw game over screen
function drawGameOver()
    -- Set background color
    love.graphics.setColor(0.1, 0.1, 0.2)
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
    
    -- Game Over title
    love.graphics.setColor(1, 0.3, 0.3)
    love.graphics.printf("GAME OVER", 0, screenHeight * 0.25, screenWidth, "center")
    
    -- Format game time (minutes:seconds)
    local minutes = math.floor(gameTime / 60)
    local seconds = math.floor(gameTime % 60)
    local timeString = string.format("%02d:%02d", minutes, seconds)
    
    -- Display stats centered
    local yPos = screenHeight * 0.4
    local lineHeight = 30
    
    -- Display final score with larger font and gold color
    love.graphics.setColor(1, 0.8, 0)  -- Gold color
    love.graphics.printf("FINAL SCORE: " .. math.floor(score), 0, yPos, screenWidth, "center")
    yPos = yPos + lineHeight
    
    -- Display high score
    if newHighScore then
        love.graphics.setColor(1, 1, 0.3)  -- Brighter yellow for new high score
        love.graphics.printf("NEW HIGH SCORE!", 0, yPos, screenWidth, "center")
    else
        love.graphics.printf("HIGH SCORE: " .. ScoreManager.highScore, 0, yPos, screenWidth, "center")
    end
    yPos = yPos + lineHeight * 1.5
    
    -- Other stats
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Time Survived: " .. timeString, 0, yPos, screenWidth, "center")
    yPos = yPos + lineHeight
    
    love.graphics.printf("Enemies Defeated: " .. enemiesDefeated, 0, yPos, screenWidth, "center")
    yPos = yPos + lineHeight * 2
    
    -- Restart instructions
    love.graphics.setColor(0.8, 0.8, 1)
    love.graphics.printf("Press ENTER or SPACE to restart", 0, yPos, screenWidth, "center")
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
    
    -- Current Score stat
    love.graphics.setColor(1, 0.8, 0)  -- Gold color for score
    love.graphics.printf("Score:", gameAreaWidth + 10, yPos, statsPanelWidth - 20, "left")
    love.graphics.printf(math.floor(score), gameAreaWidth + 10, yPos, statsPanelWidth - 20, "right")
    yPos = yPos + lineHeight
    
    -- High Score stat
    love.graphics.printf("High Score:", gameAreaWidth + 10, yPos, statsPanelWidth - 20, "left")
    love.graphics.printf(ScoreManager.highScore, gameAreaWidth + 10, yPos, statsPanelWidth - 20, "right")
    yPos = yPos + lineHeight
    
    -- Reset to white for other stats
    love.graphics.setColor(1, 1, 1)
    
    -- Time stat
    love.graphics.printf("Time:", gameAreaWidth + 10, yPos, statsPanelWidth - 20, "left")
    love.graphics.printf(timeString, gameAreaWidth + 10, yPos, statsPanelWidth - 20, "right")
    yPos = yPos + lineHeight
    
    -- Enemies defeated stat
    love.graphics.printf("Enemies:", gameAreaWidth + 10, yPos, statsPanelWidth - 20, "left")
    love.graphics.printf(tostring(enemiesDefeated), gameAreaWidth + 10, yPos, statsPanelWidth - 20, "right")
    yPos = yPos + lineHeight
    
    -- Lives stat
    love.graphics.printf("Lives:", gameAreaWidth + 10, yPos, statsPanelWidth - 20, "left")
    love.graphics.printf(tostring(player.lives), gameAreaWidth + 10, yPos, statsPanelWidth - 20, "right")
    yPos = yPos + lineHeight
    
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
    local color = colors[love.math.random(1, #colors)]
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