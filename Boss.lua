-- Boss.lua - Special enemy that appears at difficulty transitions

Boss = {}
Boss.__index = Boss

-- Boss types with their properties
Boss.TYPES = {
    TRIANGLE = 1,
    HEXAGON = 2,
    OCTAGON = 3,
}

-- Boss properties
Boss.PROPERTIES = {
    [Boss.TYPES.TRIANGLE] = {
        name = "Triangle Guardian",
        color = {1, 0.3, 0},  -- Red-orange
        health = 30,
        pattern = "trianglePattern",
        vertices = 3,
    },
    [Boss.TYPES.HEXAGON] = {
        name = "Hexagon Overlord",
        color = {0.4, 0, 0.8},  -- Purple
        health = 45,
        pattern = "hexagonPattern",
        vertices = 6,
    },
    [Boss.TYPES.OCTAGON] = {
        name = "Octagon Destroyer",
        color = {0, 0.6, 0.8},  -- Cyan-blue
        health = 70,
        pattern = "octoPattern",
        vertices = 8,
    }
}

function Boss:new(bossType)
    local bossType = bossType or love.math.random(1, 3)
    local properties = Boss.PROPERTIES[bossType]
    
    local self = setmetatable({}, Boss)
    self.x = gameAreaWidth / 2 - 50
    self.y = 100
    self.width = 100
    self.height = 100
    self.radius = 50  -- For drawing and collision
    self.health = properties.health
    self.maxHealth = properties.health
    self.color = properties.color
    self.patternType = properties.pattern
    self.name = properties.name
    self.vertices = properties.vertices
    self.alive = true
    self.bossType = bossType
    
    -- Movement and attack patterns
    self.movementPhase = 0
    self.shootTimer = 0
    self.shootDelay = 0.8
    self.phaseTimer = 0
    self.phaseDelay = 3
    self.currentPhase = 1
    self.maxPhases = 3
    
    -- Special effects
    self.flashTimer = 0
    
    return self
end

function Boss:update(dt)
    -- Update movement based on type
    self:updateMovement(dt)
    
    -- Update shooting patterns
    self.shootTimer = self.shootTimer - dt
    self.phaseTimer = self.phaseTimer + dt
    
    -- Change phase periodically
    if self.phaseTimer >= self.phaseDelay then
        self.currentPhase = (self.currentPhase % self.maxPhases) + 1
        self.phaseTimer = 0
    end
    
    -- Shoot based on current phase
    if self.shootTimer <= 0 then
        self:firePattern()
        self.shootTimer = self.shootDelay
    end
    
    -- Update flash effect when hit
    if self.flashTimer > 0 then
        self.flashTimer = self.flashTimer - dt
    end
end

function Boss:updateMovement(dt)
    -- Different movement patterns based on boss type
    if self.bossType == Boss.TYPES.TRIANGLE then
        -- Move in a small figure-8 pattern
        self.movementPhase = self.movementPhase + dt
        self.x = gameAreaWidth / 2 - 50 + math.sin(self.movementPhase) * 100
        self.y = 100 + math.sin(self.movementPhase * 2) * 50
        
    elseif self.bossType == Boss.TYPES.HEXAGON then
        -- Bounce from side to side
        self.movementPhase = self.movementPhase + dt
        self.x = gameAreaWidth / 2 - 50 + math.sin(self.movementPhase * 0.8) * 150
        
    elseif self.bossType == Boss.TYPES.OCTAGON then
        -- Complex circular pattern
        self.movementPhase = self.movementPhase + dt
        self.x = gameAreaWidth / 2 - 50 + math.cos(self.movementPhase) * 100
        self.y = 100 + math.sin(self.movementPhase) * 70
    end
    
    -- Make sure boss stays on screen
    if self.x < 10 then self.x = 10 end
    if self.x > gameAreaWidth - self.width - 10 then self.x = gameAreaWidth - self.width - 10 end
    if self.y < 10 then self.y = 10 end
    if self.y > screenHeight / 2 then self.y = screenHeight / 2 end
end

function Boss:draw()
    -- Draw boss shape
    local centerX = self.x + self.width/2
    local centerY = self.y + self.height/2
    
    -- Flash white briefly when hit
    if self.flashTimer > 0 then
        love.graphics.setColor(1, 1, 1)
    else
        love.graphics.setColor(self.color)
    end
    
    -- Draw polygon based on vertices
    self:drawShape(centerX, centerY, self.radius, self.vertices)
    
    -- Draw boss health bar
    self:drawHealthBar()
    
    love.graphics.setColor(1, 1, 1)  -- Reset color
end

function Boss:drawShape(centerX, centerY, radius, vertices)
    -- Draw a regular polygon with the specified number of vertices
    local points = {}
    
    for i = 1, vertices do
        -- For triangle, start upside down
        local angle = (i / vertices) * math.pi * 2
        if vertices == 3 then
            angle = angle + math.pi  -- Rotate triangle to point down
        end
        
        table.insert(points, centerX + math.cos(angle) * radius)
        table.insert(points, centerY + math.sin(angle) * radius)
    end
    
    love.graphics.polygon("fill", points)
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.polygon("line", points)
end

function Boss:drawHealthBar()
    local barWidth = gameAreaWidth * 0.7
    local barHeight = 20
    local x = (gameAreaWidth - barWidth) / 2
    local y = 30
    
    -- Background
    love.graphics.setColor(0.3, 0.3, 0.3, 0.7)
    love.graphics.rectangle("fill", x, y, barWidth, barHeight)
    
    -- Health remaining
    local healthPercent = self.health / self.maxHealth
    love.graphics.setColor(self.color[1], self.color[2], self.color[3], 0.9)
    love.graphics.rectangle("fill", x, y, barWidth * healthPercent, barHeight)
    
    -- Border
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.rectangle("line", x, y, barWidth, barHeight)
    
    -- Name and health text
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(self.name, x, y - 25, barWidth, "center")
    love.graphics.printf(math.floor(self.health) .. "/" .. self.maxHealth, x, y + 2, barWidth, "center")
end

function Boss:firePattern()
    -- Choose pattern based on boss type and current phase
    if self.bossType == Boss.TYPES.TRIANGLE then
        if self.currentPhase == 1 then
            self:fireTrianglePatternPhase1()
        elseif self.currentPhase == 2 then
            self:fireTrianglePatternPhase2()
        else
            self:fireTrianglePatternPhase3()
        end
    elseif self.bossType == Boss.TYPES.HEXAGON then
        if self.currentPhase == 1 then
            self:fireHexagonPatternPhase1()
        elseif self.currentPhase == 2 then
            self:fireHexagonPatternPhase2()
        else
            self:fireHexagonPatternPhase3()
        end
    elseif self.bossType == Boss.TYPES.OCTAGON then
        if self.currentPhase == 1 then
            self:fireOctagonPatternPhase1()
        elseif self.currentPhase == 2 then
            self:fireOctagonPatternPhase2()
        else
            self:fireOctagonPatternPhase3()
        end
    end
end

-- Triangle boss patterns
function Boss:fireTrianglePatternPhase1()
    -- 3-way spread
    local centerX = self.x + self.width/2
    local centerY = self.y + self.height/2
    local bulletCount = 3
    
    for i = 1, bulletCount do
        local angle = ((i - 1) / bulletCount) * math.pi + math.pi/2 - math.pi/4
        local bullet = EnemyBullet:new(centerX - 5, centerY - 5)
        bullet.vx = math.cos(angle) * bullet.speed
        bullet.vy = math.sin(angle) * bullet.speed
        table.insert(enemyBullets, bullet)
    end
end

function Boss:fireTrianglePatternPhase2()
    -- Aimed shots
    local centerX = self.x + self.width/2
    local centerY = self.y + self.height/2
    local playerCenterX = player.x + player.width/2
    local playerCenterY = player.y + player.height/2
    
    local angle = math.atan2(playerCenterY - centerY, playerCenterX - centerX)
    local bulletCount = 5
    local spread = 0.1
    
    for i = 1, bulletCount do
        local spreadAngle = angle + (i - (bulletCount+1)/2) * spread
        local bullet = EnemyBullet:new(centerX - 5, centerY - 5)
        bullet.vx = math.cos(spreadAngle) * bullet.speed * 1.2
        bullet.vy = math.sin(spreadAngle) * bullet.speed * 1.2
        table.insert(enemyBullets, bullet)
    end
end

function Boss:fireTrianglePatternPhase3()
    -- Spiral
    local centerX = self.x + self.width/2
    local centerY = self.y + self.height/2
    local bulletCount = 12
    
    for i = 1, bulletCount do
        local angle = (i / bulletCount) * math.pi * 2 + self.phaseTimer * 3
        local bullet = EnemyBullet:new(centerX - 5, centerY - 5)
        bullet.vx = math.cos(angle) * bullet.speed * 0.8
        bullet.vy = math.sin(angle) * bullet.speed * 0.8
        table.insert(enemyBullets, bullet)
    end
end

-- Hexagon boss patterns
function Boss:fireHexagonPatternPhase1()
    -- Hexagonal pattern
    local centerX = self.x + self.width/2
    local centerY = self.y + self.height/2
    local bulletCount = 6
    
    for i = 1, bulletCount do
        local angle = (i / bulletCount) * math.pi * 2
        local bullet = EnemyBullet:new(centerX - 5, centerY - 5)
        bullet.vx = math.cos(angle) * bullet.speed
        bullet.vy = math.sin(angle) * bullet.speed
        bullet.color = {0.4, 0, 0.8}  -- Match boss color
        table.insert(enemyBullets, bullet)
    end
end

function Boss:fireHexagonPatternPhase2()
    -- Multiple ring pattern
    local centerX = self.x + self.width/2
    local centerY = self.y + self.height/2
    local bulletCount = 6
    
    for ring = 1, 2 do
        for i = 1, bulletCount do
            local angle = (i / bulletCount) * math.pi * 2 + ring * 0.5
            local distance = 10 + ring * 15
            local bullet = EnemyBullet:new(
                centerX + math.cos(angle) * distance - 5, 
                centerY + math.sin(angle) * distance - 5
            )
            bullet.vx = math.cos(angle) * bullet.speed
            bullet.vy = math.sin(angle) * bullet.speed
            bullet.color = {0.4, 0, 0.8}  -- Match boss color
            table.insert(enemyBullets, bullet)
        end
    end
end

function Boss:fireHexagonPatternPhase3()
    -- Dense wall pattern
    local centerX = self.x + self.width/2
    local centerY = self.y + self.height/2
    local bulletCount = 12
    
    for i = 1, bulletCount do
        local angle = (i / bulletCount) * math.pi + self.phaseTimer
        local bullet = EnemyBullet:new(centerX - 5, centerY - 5)
        bullet.vx = math.cos(angle) * bullet.speed * 0.9
        bullet.vy = math.sin(angle) * bullet.speed * 0.9
        bullet.color = {0.4, 0, 0.8}  -- Match boss color
        table.insert(enemyBullets, bullet)
    end
end

-- Octagon boss patterns
function Boss:fireOctagonPatternPhase1()
    -- 8-way pattern
    local centerX = self.x + self.width/2
    local centerY = self.y + self.height/2
    local bulletCount = 8
    
    for i = 1, bulletCount do
        local angle = (i / bulletCount) * math.pi * 2
        local bullet = EnemyBullet:new(centerX - 5, centerY - 5)
        bullet.vx = math.cos(angle) * bullet.speed
        bullet.vy = math.sin(angle) * bullet.speed
        bullet.color = {0, 0.6, 0.8}  -- Match boss color
        table.insert(enemyBullets, bullet)
    end
end

function Boss:fireOctagonPatternPhase2()
    -- Spinning cross pattern
    local centerX = self.x + self.width/2
    local centerY = self.y + self.height/2
    local bulletCount = 4
    local rotation = self.phaseTimer * 2
    
    for i = 1, bulletCount do
        local angle = (i / bulletCount) * math.pi * 2 + rotation
        
        -- Inner bullet
        local bullet1 = EnemyBullet:new(centerX - 5, centerY - 5)
        bullet1.vx = math.cos(angle) * bullet1.speed * 0.7  -- Fixed: use bullet1 not bullet
        bullet1.vy = math.sin(angle) * bullet1.speed * 0.7  -- Fixed: use bullet1 not bullet
        bullet1.color = {0, 0.6, 0.8}  -- Match boss color
        
        -- Outer bullet
        local bullet2 = EnemyBullet:new(centerX - 5, centerY - 5)
        bullet2.vx = math.cos(angle) * bullet2.speed * 1.3  -- Fixed: use bullet2 not bullet
        bullet2.vy = math.sin(angle) * bullet2.speed * 1.3  -- Fixed: use bullet2 not bullet
        bullet2.color = {0, 0.6, 0.8}  -- Match boss color
        
        table.insert(enemyBullets, bullet1)
        table.insert(enemyBullets, bullet2)
    end
end

function Boss:fireOctagonPatternPhase3()
    -- Spiral barrage
    local centerX = self.x + self.width/2
    local centerY = self.y + self.height/2
    local bulletCount = 8
    local baseAngle = self.phaseTimer * 4
    
    for i = 1, bulletCount do
        local angle = (i / bulletCount) * math.pi * 2 + baseAngle
        local bullet = EnemyBullet:new(centerX - 5, centerY - 5)
        bullet.vx = math.cos(angle) * bullet.speed * 1.1
        bullet.vy = math.sin(angle) * bullet.speed * 1.1
        bullet.color = {0, 0.6, 0.8}  -- Match boss color
        table.insert(enemyBullets, bullet)
    end
end

function Boss:takeDamage(amount)
    self.health = self.health - (amount or 1)
    self.flashTimer = 0.1  -- Flash effect
    
    if self.health <= 0 then
        self.alive = false
    end
end

return Boss