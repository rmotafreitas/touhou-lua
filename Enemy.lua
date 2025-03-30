Enemy = {}
Enemy.__index = Enemy

function Enemy:new(x, y, width, height, health, color, patternType)
    local self = setmetatable({}, Enemy)
    self.x = x or love.math.random(50, love.graphics.getWidth() - 50)
    self.y = y or 50
    self.width = width or 40
    self.height = height or 40
    self.health = health or 3
    self.color = color or {0, 0.5, 1}  -- Default cyan-blue
    self.speed = 50
    self.patternType = patternType or "circle"
    self.shootTimer = 0
    self.shootDelay = 1.5  -- Time between firing patterns
    self.patternTimer = 0  -- Used for pattern animations
    self.alive = true
    return self
end

function Enemy:update(dt)
    -- Simple movement - can be expanded
    self.y = self.y + self.speed * dt * 0.2
    
    -- Shooting logic
    self.shootTimer = self.shootTimer - dt
    self.patternTimer = self.patternTimer + dt
    
    if self.shootTimer <= 0 then
        self:firePattern()
        self.shootTimer = self.shootDelay
    end
    
    -- Remove if off screen
    if self.y > love.graphics.getHeight() + 50 then
        self.alive = false
    end
end

function Enemy:draw()
    love.graphics.setColor(self.color)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    love.graphics.setColor(1, 1, 1)  -- Reset color
end

function Enemy:firePattern()
    -- Choose pattern based on patternType
    if self.patternType == "circle" then
        self:fireCirclePattern()
    elseif self.patternType == "spiral" then
        self:fireSpiralPattern()
    elseif self.patternType == "aimed" then
        self:fireAimedPattern()
    end
end

function Enemy:fireCirclePattern()
    local bulletCount = 8
    local centerX = self.x + self.width/2
    local centerY = self.y + self.height
    
    for i = 1, bulletCount do
        local angle = (i / bulletCount) * math.pi * 2
        local bulletX = centerX - 5
        local bulletY = centerY - 5
        local bullet = EnemyBullet:new(bulletX, bulletY)
        
        -- Set velocity based on angle
        bullet.vx = math.cos(angle) * bullet.speed
        bullet.vy = math.sin(angle) * bullet.speed
        
        table.insert(enemyBullets, bullet)
    end
end

function Enemy:fireSpiralPattern()
    local angle = self.patternTimer * 5
    local centerX = self.x + self.width/2
    local centerY = self.y + self.height
    
    for i = 0, 2 do
        local currentAngle = angle + (i * math.pi * 2 / 3)
        local bulletX = centerX - 5
        local bulletY = centerY - 5
        local bullet = EnemyBullet:new(bulletX, bulletY)
        
        bullet.vx = math.cos(currentAngle) * bullet.speed
        bullet.vy = math.sin(currentAngle) * bullet.speed
        
        table.insert(enemyBullets, bullet)
    end
end

function Enemy:fireAimedPattern()
    -- Aim at player
    local centerX = self.x + self.width/2
    local centerY = self.y + self.height
    local playerCenterX = player.x + player.width/2
    local playerCenterY = player.y + player.height/2
    
    local angle = math.atan2(playerCenterY - centerY, playerCenterX - centerX)
    
    -- Create 3 bullets in a spread
    for i = -1, 1 do
        local spreadAngle = angle + (i * 0.2)
        local bullet = EnemyBullet:new(centerX - 5, centerY - 5)
        bullet.vx = math.cos(spreadAngle) * bullet.speed
        bullet.vy = math.sin(spreadAngle) * bullet.speed
        table.insert(enemyBullets, bullet)
    end
end

function Enemy:takeDamage(amount)
    self.health = self.health - (amount or 1)
    if self.health <= 0 then
        self.alive = false
    end
end