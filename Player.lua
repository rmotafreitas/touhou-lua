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
    if not self.invulnerable then
        self.lives = self.lives - 1
        self.invulnerable = true
        self.invulnerableTimer = 2  -- 2 seconds of invulnerability
    end
end

function Player:shoot()
    local bulletX = self.x + self.width/2 - 5  -- Center the bullet horizontally
    local bulletY = self.y - 10  -- Spawn bullet at top of player
    table.insert(bullets, Bullet:new(bulletX, bulletY))
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
