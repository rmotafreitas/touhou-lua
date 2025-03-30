Player = {}
Player.__index = Player

function Player:new(x, y, width, height, speed)
    local self = setmetatable({}, Player)
    self.x = x or 400
    self.y = y or 300
    self.width = width or 50
    self.height = height or 50
    self.speed = speed or 200
    self.color = {1, 0, 0}  -- Red color (RGB values from 0 to 1)
    self.shootTimer = 0
    self.shootDelay = 0.15  -- Time between shots in seconds
    self.lives = 3  -- Starting with 3 lives
    self.invulnerable = false  -- Invulnerability flag after being hit
    self.invulnerableTimer = 0  -- Timer for invulnerability period
    self.powerUps = {}  -- Table to store active power-ups
    self.normalShootDelay = 0.15  -- Store original shoot delay
    self.skills = {}  -- Table to store collected skills (max 2)
    self.maxSkills = 2  -- Maximum number of skills that can be held
    return self
end

function Player:update(dt)
    -- Get the previous position to restore if needed
    local prevX, prevY = self.x, self.y
    
    -- Move with arrow keys
    if love.keyboard.isDown("left") or love.keyboard.isDown("a") then
        self.x = self.x - self.speed * dt
    end
    if love.keyboard.isDown("right") or love.keyboard.isDown("d") then
        self.x = self.x + self.speed * dt
    end
    if love.keyboard.isDown("up") or love.keyboard.isDown("w") then
        self.y = self.y - self.speed * dt
    end
    if love.keyboard.isDown("down") or love.keyboard.isDown("s") then
        self.y = self.y + self.speed * dt
    end
    
    -- Keep player within game area boundaries
    if self.x < 0 then
        self.x = 0
    end
    if self.x + self.width > gameAreaWidth then
        self.x = gameAreaWidth - self.width
    end
    if self.y < 0 then
        self.y = 0
    end
    if self.y + self.height > love.graphics.getHeight() then
        self.y = love.graphics.getHeight() - self.height
    end
    
    -- Update power-ups
    for name, powerUp in pairs(self.powerUps) do
        powerUp.timeLeft = powerUp.timeLeft - dt
        if powerUp.timeLeft <= 0 then
            -- Reset effects when power-up expires
            if name == "rapidFire" then
                self.shootDelay = self.normalShootDelay
            end
            self.powerUps[name] = nil
        end
    end
    
    -- Shooting logic
    self.shootTimer = self.shootTimer - dt
    if love.keyboard.isDown("space") and self.shootTimer <= 0 then
        self:shoot()
        self.shootTimer = self.shootDelay
    end
    
    -- Update invulnerability timer
    if self.invulnerable then
        self.invulnerableTimer = self.invulnerableTimer - dt
        if self.invulnerableTimer <= 0 then
            self.invulnerable = false
        end
    end
end

function Player:takeDamage()
    if self:hasShield() then
        -- Shield absorbs damage
        self.powerUps["shield"] = nil
        return
    end
    
    if not self.invulnerable then
        -- Only take damage if not invulnerable
        self:removeLife()
        self.invulnerable = true
        self.invulnerableTimer = 2  -- 2 seconds of invulnerability
    end
end

function Player:shoot()
    local bulletX = self.x + self.width/2 - 5  -- Center the bullet horizontally
    local bulletY = self.y - 10  -- Spawn bullet at top of player
    
    -- Normal forward shot
    table.insert(bullets, Bullet:new(bulletX, bulletY))
    
    -- Triple shot if power-up is active
    if self.powerUps["tripleShot"] then
        -- Left diagonal shot
        local leftBullet = Bullet:new(bulletX - 5, bulletY + 5)
        leftBullet.vx = -leftBullet.speed * 0.3
        leftBullet.vy = -leftBullet.speed * 0.7
        
        -- Right diagonal shot
        local rightBullet = Bullet:new(bulletX + 5, bulletY + 5)
        rightBullet.vx = rightBullet.speed * 0.3
        rightBullet.vy = -rightBullet.speed * 0.7
        
        table.insert(bullets, leftBullet)
        table.insert(bullets, rightBullet)
    end
end

function Player:draw()
    -- Make player flash when invulnerable
    if self.invulnerable then
        if math.floor(love.timer.getTime() * 10) % 2 == 0 then
            love.graphics.setColor(self.color[1], self.color[2], self.color[3], 0.5)
        else
            love.graphics.setColor(self.color)
        end
    else
        love.graphics.setColor(self.color)
    end
    
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    love.graphics.setColor(1, 1, 1)  -- Reset color to white
end

function Player:addPowerUp(name, duration, value)
    self.powerUps[name] = {
        timeLeft = duration,
        value = value or true
    }
    
    -- Apply immediate effects
    if name == "rapidFire" then
        self.shootDelay = self.normalShootDelay / 2
    end
end

function Player:addLife(amount)
    self.lives = self.lives + amount
end

function Player:removeLife()
    self.lives = self.lives - 1
end

function Player:hasShield()
    return self.powerUps["shield"] ~= nil
end

function Player:addSkill(skillType)
    if #self.skills < self.maxSkills then
        table.insert(self.skills, skillType)
        return true
    end
    return false  -- Cannot add more skills
end

function Player:useSkill()
    if #self.skills > 0 then
        local skillType = table.remove(self.skills, 1)  -- Remove and get first skill
        return skillType
    end
    return nil  -- No skills available
end
