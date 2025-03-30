require "Player"
require "Bullet"
require "Enemy"
require "EnemyBullet"
require "PowerUp"
require "ScoreManager"
require "DifficultyManager"
require "Boss"  -- Add this line
require "SpecialSkill"

-- Game state management
local gameState = "game"  -- States: "game", "boss", "gameover"
local newHighScore = false
local bossTransitionTimer = 0
local bossRewardTimer = 0
local currentBoss = nil
local bossDefeated = false
local bossMessage = nil
local bossMessageTimer = 0
local timeStopActive = false
local timeStopTransitionTimer = 0

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
    
    -- Initialize difficulty manager
    DifficultyManager.init()
    
    -- Reset spawn delay based on initial difficulty
    spawnDelay = DifficultyManager.getParameter("enemySpawnDelay")
    
    powerUps = {}  -- Table to store active power-ups
    nextPowerUpThreshold = PowerUp.SCORE_THRESHOLDS[1]  -- Set first threshold
    currentThresholdIndex = 1
    powerUpMessage = nil  -- For displaying power-up notifications
    powerUpMessageTimer = 0
    
    -- Boss-related variables
    currentBoss = nil
    bossTransitionTimer = 0
    bossRewardTimer = 0
    bossDefeated = false
    bossMessage = nil
    bossMessageTimer = 0
    
    skillCards = {}  -- Table to store skill cards
    skillParticles = {}  -- Table to store skill particle effects
    activeSkill = nil  -- Currently active skill
    activeSkillTimer = 0  -- Timer for active skill duration
    skillDropThreshold = 600  -- Score needed for first skill card (lowered from 1000)
    lastSkillDropScore = 0  -- Track when last skill dropped
    
    timeStopActive = false
    timeStopTransitionTimer = 0
    
    -- Create initial enemies
    table.insert(enemies, Enemy:new(200, 50, 40, 40, 3, {0, 0.5, 1}, "circle"))
    table.insert(enemies, Enemy:new(400, 100, 40, 40, 3, {1, 0.3, 0.7}, "spiral"))
    table.insert(enemies, Enemy:new(600, 50, 40, 40, 3, {0.2, 0.8, 0.2}, "aimed"))
end

-- Game update
function love.update(dt)
    if gameState == "game" then
        updateGame(dt)
    elseif gameState == "boss" then
        updateBossFight(dt)
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
    
    -- Check if we've hit a score threshold for spawning a power-up
    if score >= nextPowerUpThreshold then
        spawnPowerUp()
        
        -- Set next threshold
        currentThresholdIndex = currentThresholdIndex + 1
        if currentThresholdIndex <= #PowerUp.SCORE_THRESHOLDS then
            nextPowerUpThreshold = PowerUp.SCORE_THRESHOLDS[currentThresholdIndex]
        else
            -- If we've reached the end of predefined thresholds, add a large increment
            nextPowerUpThreshold = nextPowerUpThreshold + 2000
        end
    end
    
    -- Update power-up message
    if powerUpMessage then
        powerUpMessageTimer = powerUpMessageTimer - dt
        if powerUpMessageTimer <= 0 then
            powerUpMessage = nil
        end
    end
    
    -- Update power-ups
    for i = #powerUps, 1, -1 do
        local powerUp = powerUps[i]
        powerUp:update(dt)
        
        -- Check for collision with player
        if checkCollision(powerUp, player) then
            -- Apply power-up effect
            local name, description = powerUp:apply(player)
            
            -- Show message
            powerUpMessage = {
                name = name,
                description = description,
                color = powerUp.color
            }
            powerUpMessageTimer = 5  -- Show for 5 seconds
            
            -- Remove power-up from game
            table.remove(powerUps, i)
        elseif not powerUp.active then
            table.remove(powerUps, i)
        end
    end
    
    -- Apply score multiplier if active
    if player.powerUps["scoreMultiplier"] then
        local multiplier = player.powerUps["scoreMultiplier"].value
        score = score + (10 * dt * (multiplier - 1))  -- Add the extra score
    end
    
    -- Check if difficulty level should increase
    local difficultyIncreased = DifficultyManager.updateDifficulty(score)
    
    -- If difficulty increased, start boss fight
    if difficultyIncreased then
        -- Start boss transition
        gameState = "boss"
        bossTransitionTimer = 3  -- 3 seconds transition
        
        -- Clear all enemy bullets immediately
        enemyBullets = {}
        
        -- Create a boss based on difficulty level
        local bossType = (DifficultyManager.getLevel() - 1) % 3 + 1
        
        -- Debug output to see what's happening
        print("Spawning boss: " .. bossType .. " at difficulty level " .. DifficultyManager.getLevel())
        
        -- For the first boss, force it to be the Triangle Guardian
        if DifficultyManager.getLevel() == 2 then  -- First boss at level 2
            bossType = Boss.TYPES.TRIANGLE
            print("Forcing first boss to be Triangle Guardian")
        end
        
        currentBoss = Boss:new(bossType)
        
        -- Show boss arrival message
        bossMessage = {
            name = "Boss Approaching!",
            description = currentBoss.name,
            color = currentBoss.color
        }
        bossMessageTimer = 5  -- Show for 5 seconds
    end
    
    -- Check if we should spawn a skill card
    if score - lastSkillDropScore >= skillDropThreshold and #player.skills < player.maxSkills then
        spawnSkillCard()
        lastSkillDropScore = score
        skillDropThreshold = skillDropThreshold * 1.5  -- 1.5x multiplier instead of 2x
        
        -- Add a small random variance to make the timing less predictable
        skillDropThreshold = skillDropThreshold + love.math.random(-100, 100)
        
        -- Ensure the threshold doesn't go below a minimum value
        skillDropThreshold = math.max(skillDropThreshold, 400)
    end
    
    -- Update skill cards
    for i = #skillCards, 1, -1 do
        local card = skillCards[i]
        card:update(dt)
        
        -- Check for collision with player
        if checkCollision(card, player) then
            -- Add skill to player's collection
            if player:addSkill(card.type) then
                -- Show message
                local properties = SpecialSkill.PROPERTIES[card.type]
                powerUpMessage = {
                    name = "Skill Card: " .. properties.name,
                    description = properties.description,
                    color = properties.color
                }
                powerUpMessageTimer = 5  -- Show for 5 seconds
            end
            
            -- Remove card from game
            table.remove(skillCards, i)
        elseif not card.active then
            table.remove(skillCards, i)
        end
    end
    
    -- Update active skill
    if activeSkill then
        activeSkillTimer = activeSkillTimer - dt
        
        -- Update skill particles
        local particlesActive = SpecialSkill.updateParticles(skillParticles, dt)
        
        -- Handle skill ending
        if activeSkillTimer <= 0 or not particlesActive then
            -- If Time Stop is ending, start transition period
            if timeStopActive and activeSkill == SpecialSkill.TYPES.TIME_STOP then
                timeStopActive = false
                timeStopTransitionTimer = 1.0  -- 1 second transition period
            end
            activeSkill = nil
        end
    end
    
    -- Gradually return to normal speed after Time Stop
    local enemyTimeScale = 1.0
    if activeSkill == SpecialSkill.TYPES.TIME_STOP then
        -- Full Time Stop effect (20% speed)
        enemyTimeScale = 0.2
    elseif timeStopTransitionTimer > 0 then
        -- Gradual transition back to normal speed
        timeStopTransitionTimer = timeStopTransitionTimer - dt
        -- Gradually increase from 0.2 to 1.0
        enemyTimeScale = 0.2 + (1.0 - 0.2) * (1.0 - timeStopTransitionTimer)
    end
    
    -- Update enemies with the calculated time scale
    for i = #enemies, 1, -1 do
        local enemy = enemies[i]
        enemy:update(dt * enemyTimeScale)
        
        -- Remove enemies that are dead or move into stats panel
        if not enemy.alive or enemy.x > gameAreaWidth then
            table.remove(enemies, i)
        end
    end
    
    -- Same for enemy bullets - only update if not in Time Stop
    if not (activeSkill == SpecialSkill.TYPES.TIME_STOP) then
        -- Apply transition for bullets too
        local bulletTimeScale = timeStopTransitionTimer > 0 and enemyTimeScale or 1.0
        
        for i = #enemyBullets, 1, -1 do
            local bullet = enemyBullets[i]
            bullet:update(dt * bulletTimeScale)
            
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
    end
end

-- New function to update boss fights
function updateBossFight(dt)
    -- Check for game over
    if player.lives <= 0 then
        newHighScore = ScoreManager.updateHighScore(score)
        gameState = "gameover"
        return
    end
    
    -- Handle boss arrival transition
    if bossTransitionTimer > 0 then
        bossTransitionTimer = bossTransitionTimer - dt
        
        -- Clear normal enemies and bullets during transition
        if #enemies > 0 then
            for i = #enemies, 1, -1 do
                table.remove(enemies, i)
            end
        end
        
        -- Also ensure no bullets remain
        if #enemyBullets > 0 then
            enemyBullets = {}
        end
        
        -- When transition completes, start the actual fight
        if bossTransitionTimer <= 0 then
            -- Boss has fully arrived, play is normal now
        end
        
        -- Update player during transition
        player:update(dt)
        return
    end
    
    -- Handle boss defeated sequence
    if bossDefeated then
        bossRewardTimer = bossRewardTimer - dt
        
        -- When reward sequence completes, return to normal gameplay
        if bossRewardTimer <= 0 then
            gameState = "game"
            bossDefeated = false
            return
        end
        
        -- Update player during victory sequence
        player:update(dt)
        return
    end
    
    -- Update boss
    if currentBoss and currentBoss.alive then
        local bossTimeScale = (activeSkill == SpecialSkill.TYPES.TIME_STOP) and 0.2 or 1
        currentBoss:update(dt * bossTimeScale)
    end
    
    -- Update player
    player:update(dt)
    
    -- Update player bullets
    for i = #bullets, 1, -1 do
        local bullet = bullets[i]
        bullet:update(dt)
        
        -- Check for collision with boss
        if currentBoss and currentBoss.alive and checkCollisionWithBoss(bullet, currentBoss) then
            currentBoss:takeDamage()
            table.remove(bullets, i)
            
            -- Check if boss is defeated
            if not currentBoss.alive then
                -- Boss defeated - start reward sequence
                bossDefeated = true
                bossRewardTimer = 3  -- 3 seconds for reward animation
                
                -- Reward player with an extra life
                player:addLife(1)
                
                -- Show victory message
                bossMessage = {
                    name = "Boss Defeated!",
                    description = "+1 Life",
                    color = {0, 1, 0}  -- Green
                }
                bossMessageTimer = 5  -- Show for 5 seconds
            end
        else
            -- Only check for bullets going off screen if they didn't hit the boss
            if bullet:isOffScreen() or bullet.x + bullet.width > gameAreaWidth then
                table.remove(bullets, i)
            end
        end
    end
    
    -- Update enemy bullets (skip if Time Stop is active)
    if not (activeSkill == SpecialSkill.TYPES.TIME_STOP) then
        for i = #enemyBullets, 1, -1 do
            local bullet = enemyBullets[i]
            bullet:update(dt)
            
            -- Check for collision with player
            if checkCollision(bullet, player) then
                player:takeDamage()
                table.remove(enemyBullets, i)
            -- Remove bullets that go off screen
            elseif bullet:isOffScreen() or bullet.x > gameAreaWidth then
                table.remove(enemyBullets, i)
            end
        end
    end
    
    -- Update active skill
    if activeSkill then
        activeSkillTimer = activeSkillTimer - dt
        
        -- Update skill particles
        local particlesActive = SpecialSkill.updateParticles(skillParticles, dt)
        
        if activeSkillTimer <= 0 or not particlesActive then
            activeSkill = nil
        end
    end
    
    -- Update boss message
    if bossMessage then
        bossMessageTimer = bossMessageTimer - dt
        if bossMessageTimer <= 0 then
            bossMessage = nil
        end
    end
end

-- Game drawing
function love.draw()
    if gameState == "game" then
        drawGame()
    elseif gameState == "boss" then
        drawBossFight()
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
    
    -- Draw power-ups
    for _, powerUp in ipairs(powerUps) do
        powerUp:draw()
    end
    
    -- Draw skill cards
    for _, card in ipairs(skillCards) do
        card:draw()
    end
    
    -- Draw active skill particles
    if activeSkill then
        SpecialSkill.drawParticles(skillParticles)
    end
    
    -- Draw player
    player:draw()
    
    -- Draw player bullets
    for _, bullet in ipairs(bullets) do
        bullet:draw()
    end
    
    -- Draw power-up message if one is active
    if powerUpMessage then
        drawPowerUpMessage()
    end
    
    -- Draw active power-ups indicators
    drawActivePowerUps()
    
    -- Draw skill cards in the bottom right
    drawSkillCards()
    
    -- Reset scissor
    love.graphics.setScissor()
    
    -- Draw stats panel
    drawStatsPanel()
end

-- New function to draw boss fights
function drawBossFight()
    -- Set scissor to limit drawing to game area
    love.graphics.setScissor(0, 0, gameAreaWidth, screenHeight)
    
    -- Draw boss if transition is complete
    if bossTransitionTimer <= 0 and currentBoss and not bossDefeated then
        currentBoss:draw()
    end
    
    -- Draw enemy bullets
    for _, bullet in ipairs(enemyBullets) do
        bullet:draw()
    end
    
    -- Draw skill cards
    for _, card in ipairs(skillCards) do
        card:draw()
    end
    
    -- Draw active skill particles
    if activeSkill then
        SpecialSkill.drawParticles(skillParticles)
    end
    
    -- Draw player
    player:draw()
    
    -- Draw player bullets
    for _, bullet in ipairs(bullets) do
        bullet:draw()
    end
    
    -- Draw boss arrival/victory message
    if bossMessage then
        drawBossMessage()
    end
    
    -- Draw active power-ups indicators
    drawActivePowerUps()
    
    -- Draw skill cards in the bottom right
    drawSkillCards()
    
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
    
    -- Add next power-up threshold info
    love.graphics.printf("Next Power-up:", gameAreaWidth + 10, yPos, statsPanelWidth - 20, "left")
    love.graphics.printf(nextPowerUpThreshold, gameAreaWidth + 10, yPos, statsPanelWidth - 20, "right")
    yPos = yPos + lineHeight
    
    -- Add difficulty level to stats panel
    love.graphics.printf("Difficulty:", gameAreaWidth + 10, yPos, statsPanelWidth - 20, "left")
    love.graphics.printf(DifficultyManager.getLevelName(), gameAreaWidth + 10, yPos, statsPanelWidth - 20, "right")
    yPos = yPos + lineHeight
    
    -- Show boss info when in boss fight
    if gameState == "boss" and currentBoss then
        love.graphics.setColor(currentBoss.color)
        love.graphics.printf("BOSS FIGHT", gameAreaWidth + 10, yPos, statsPanelWidth - 20, "center")
        yPos = yPos + lineHeight
        
        -- Show boss health percentage
        local healthPercent = math.floor((currentBoss.health / currentBoss.maxHealth) * 100)
        love.graphics.printf("Boss Health:", gameAreaWidth + 10, yPos, statsPanelWidth - 20, "left")
        love.graphics.printf(healthPercent .. "%", gameAreaWidth + 10, yPos, statsPanelWidth - 20, "right")
        yPos = yPos + lineHeight
    end
    
    -- Reset color and line width
    love.graphics.setColor(1, 1, 1)
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
    local x = love.math.random(50, gameAreaWidth - 90)
    
    -- Get health and speed based on current difficulty
    local health = DifficultyManager.getParameter("enemyHealth")
    local speed = DifficultyManager.getParameter("enemySpeed")
    
    table.insert(enemies, Enemy:new(x, 0, 40, 40, health, color, pattern, speed))
end

function spawnPowerUp()
    local x = love.math.random(50, gameAreaWidth - 80)
    local y = 0
    table.insert(powerUps, PowerUp:new(x, y))
end

function spawnSkillCard()
    local x = love.math.random(50, gameAreaWidth - 80)
    local y = 0
    table.insert(skillCards, SpecialSkill:new(x, y))
end

function checkCollision(a, b)
    return a.x < b.x + b.width and
           a.x + a.width > b.x and
           a.y < b.y + b.height and
           a.y + a.height > b.y
end

-- Function to check collision with boss (circular/polygon)
function checkCollisionWithBoss(bullet, boss)
    local bulletCenterX = bullet.x + bullet.width/2
    local bulletCenterY = bullet.y + bullet.height/2
    local bossCenterX = boss.x + boss.width/2
    local bossCenterY = boss.y + boss.height/2
    
    -- Simple circular collision for boss
    local dx = bulletCenterX - bossCenterX
    local dy = bulletCenterY - bossCenterY
    local distance = math.sqrt(dx * dx + dy * dy)
    
    return distance < boss.radius
end

-- Function to draw the power-up message
function drawPowerUpMessage()
    -- Create a semi-transparent background
    love.graphics.setColor(0, 0, 0, 0.7)
    local msgWidth = gameAreaWidth * 0.6
    local msgHeight = 80
    local x = (gameAreaWidth - msgWidth) / 2
    local y = screenHeight * 0.3
    
    love.graphics.rectangle("fill", x, y, msgWidth, msgHeight)
    love.graphics.setColor(powerUpMessage.color)
    love.graphics.rectangle("line", x, y, msgWidth, msgHeight)
    
    -- Draw the power-up name and description
    love.graphics.printf(powerUpMessage.name, x, y + 15, msgWidth, "center")
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(powerUpMessage.description, x, y + 45, msgWidth, "center")
end

-- Function to draw boss messages
function drawBossMessage()
    -- Create a semi-transparent background
    love.graphics.setColor(0, 0, 0, 0.8)
    local msgWidth = gameAreaWidth * 0.7
    local msgHeight = 100
    local x = (gameAreaWidth - msgWidth) / 2
    local y = screenHeight * 0.4
    
    love.graphics.rectangle("fill", x, y, msgWidth, msgHeight)
    love.graphics.setColor(bossMessage.color)
    love.graphics.rectangle("line", x, y, msgWidth, msgHeight)
    
    -- Draw the message name and description
    love.graphics.setColor(bossMessage.color)
    love.graphics.printf(bossMessage.name, x, y + 20, msgWidth, "center")
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(bossMessage.description, x, y + 55, msgWidth, "center")
end

-- Function to draw indicators for active power-ups
function drawActivePowerUps()
    local x = 10
    local y = screenHeight - 40
    
    for name, powerUp in pairs(player.powerUps) do
        local properties
        if name == "tripleShot" then
            properties = PowerUp.PROPERTIES[PowerUp.TYPES.TRIPLE_SHOT]
        elseif name == "scoreMultiplier" then
            properties = PowerUp.PROPERTIES[PowerUp.TYPES.SCORE_MULTIPLIER]
        elseif name == "rapidFire" then
            properties = PowerUp.PROPERTIES[PowerUp.TYPES.RAPID_FIRE]
        elseif name == "shield" then
            properties = PowerUp.PROPERTIES[PowerUp.TYPES.SHIELD]
        end
        
        if properties then
            -- Draw power-up indicator
            love.graphics.setColor(properties.color)
            love.graphics.rectangle("fill", x, y, 25, 25)
            
            -- Draw timer
            local timeLeft = math.floor(powerUp.timeLeft)
            love.graphics.setColor(1, 1, 1)
            love.graphics.printf(timeLeft, x, y + 5, 25, "center")
            
            x = x + 35
        end
    end
    
    -- Reset color
    love.graphics.setColor(1, 1, 1)
end

-- Add function to draw skill cards in the bottom right
function drawSkillCards()
    local cardWidth = 30
    local cardHeight = 40
    local padding = 5
    local startX = gameAreaWidth - (cardWidth + padding) * player.maxSkills
    local y = screenHeight - cardHeight - padding
    
    -- Draw skill card slots (empty slots)
    for i = 1, player.maxSkills do
        -- Draw empty slot
        love.graphics.setColor(0.2, 0.2, 0.3, 0.5)
        love.graphics.rectangle("fill", startX + (i-1) * (cardWidth + padding), y, cardWidth, cardHeight)
        love.graphics.setColor(0.5, 0.5, 0.6, 0.8)
        love.graphics.rectangle("line", startX + (i-1) * (cardWidth + padding), y, cardWidth, cardHeight)
    end
    
    -- Draw actual skill cards
    for i, skillType in ipairs(player.skills) do
        local properties = SpecialSkill.PROPERTIES[skillType]
        
        -- Draw card background
        love.graphics.setColor(0.2, 0.2, 0.3)
        love.graphics.rectangle("fill", startX + (i-1) * (cardWidth + padding), y, cardWidth, cardHeight)
        
        -- Draw colored border
        love.graphics.setColor(properties.color)
        love.graphics.rectangle("line", startX + (i-1) * (cardWidth + padding), y, cardWidth, cardHeight)
        
        -- Draw inner pattern
        local centerX = startX + (i-1) * (cardWidth + padding) + cardWidth/2
        local centerY = y + cardHeight/2
        local radius = cardWidth * 0.3
        
        love.graphics.setColor(properties.color[1], properties.color[2], properties.color[3], 0.8)
        
        -- Draw a symbol based on skill type
        if skillType == SpecialSkill.TYPES.STAR_SHOWER then
            drawStar(centerX, centerY, radius)
        elseif skillType == SpecialSkill.TYPES.TIME_STOP then
            drawClock(centerX, centerY, radius)
        elseif skillType == SpecialSkill.TYPES.SPIRIT_BOMB then
            drawSpiral(centerX, centerY, radius)
        end
    end
    
    -- Reset color
    love.graphics.setColor(1, 1, 1)
    
    -- Draw instruction hint if player has skills
    if #player.skills > 0 then
        love.graphics.setColor(1, 1, 1, 0.7)
        love.graphics.printf("Press ENTER to use", startX, y - 20, player.maxSkills * (cardWidth + padding), "center")
    end
end

-- Helper functions for drawing the symbols
function drawStar(x, y, radius)
    local points = {}
    for i = 1, 5 do
        local angle = (i * 2 * math.pi / 5) - math.pi/2
        table.insert(points, x + radius * math.cos(angle))
        table.insert(points, y + radius * math.sin(angle))
        
        local innerAngle = ((i + 0.5) * 2 * math.pi / 5) - math.pi/2
        table.insert(points, x + radius * 0.4 * math.cos(innerAngle))
        table.insert(points, y + radius * 0.4 * math.sin(innerAngle))
    end
    love.graphics.polygon("fill", points)
end

function drawClock(x, y, radius)
    love.graphics.circle("line", x, y, radius)
    -- Draw hour hand
    love.graphics.line(x, y, x + radius * 0.5 * math.cos(-math.pi/3), y + radius * 0.5 * math.sin(-math.pi/3))
    -- Draw minute hand
    love.graphics.line(x, y, x + radius * 0.7 * math.cos(math.pi/6), y + radius * 0.7 * math.sin(math.pi/6))
end

function drawSpiral(x, y, radius)
    local points = {}
    local spirals = 2
    local steps = 20
    
    for i = 0, steps do
        local t = i / steps
        local angle = t * math.pi * 2 * spirals
        local r = t * radius
        table.insert(points, x + r * math.cos(angle))
        table.insert(points, y + r * math.sin(angle))
    end
    
    love.graphics.line(points)
    love.graphics.circle("fill", x, y, radius * 0.2)
end

-- Add to love.keypressed function (create if missing)
function love.keypressed(key)
    if key == "return" or key == "kpenter" then
        -- Activate special skill when Enter is pressed
        if gameState == "game" or gameState == "boss" then
            activateSkill()
        end
    end
end

-- Function to activate a skill
function activateSkill()
    -- Only activate if no skill is currently active
    if not activeSkill and #player.skills > 0 then
        local skillType = player:useSkill()
        if skillType then
            activeSkill = skillType
            local properties = SpecialSkill.PROPERTIES[skillType]
            activeSkillTimer = properties.duration
            
            -- Create particles
            skillParticles = SpecialSkill.createParticles(
                skillType, 
                0, 0, 
                gameAreaWidth, 
                screenHeight
            )
            
            -- Apply immediate effects based on skill type
            if skillType == SpecialSkill.TYPES.STAR_SHOWER then
                applyStarShowerEffect()
            elseif skillType == SpecialSkill.TYPES.SPIRIT_BOMB then
                applySpiritBombEffect()
            end
            
            -- Show skill activation message
            powerUpMessage = {
                name = "SPECIAL SKILL: " .. properties.name,
                description = properties.description,
                color = properties.color
            }
            powerUpMessageTimer = 5  -- Show for 5 seconds
            
            -- Track if we're using Time Stop for smooth transition later
            if skillType == SpecialSkill.TYPES.TIME_STOP then
                timeStopActive = true
            end
        end
    end
end

-- Apply Star Shower effect
function applyStarShowerEffect()
    -- Damage all enemies
    for _, enemy in ipairs(enemies) do
        enemy:takeDamage(SpecialSkill.PROPERTIES[SpecialSkill.TYPES.STAR_SHOWER].damage)
    end
    
    -- Also damage boss if fighting one
    if gameState == "boss" and currentBoss and currentBoss.alive then
        currentBoss:takeDamage(SpecialSkill.PROPERTIES[SpecialSkill.TYPES.STAR_SHOWER].damage * 2)
    end
end

-- Apply Spirit Bomb effect
function applySpiritBombEffect()
    -- Clear all enemy bullets
    enemyBullets = {}
    
    -- Heavy damage to all enemies
    for _, enemy in ipairs(enemies) do
        enemy:takeDamage(SpecialSkill.PROPERTIES[SpecialSkill.TYPES.SPIRIT_BOMB].damage)
    end
    
    -- Also damage boss if fighting one
    if gameState == "boss" and currentBoss and currentBoss.alive then
        currentBoss:takeDamage(SpecialSkill.PROPERTIES[SpecialSkill.TYPES.SPIRIT_BOMB].damage * 3)
    end
end