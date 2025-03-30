EnemyBullet = {}
EnemyBullet.__index = EnemyBullet

function EnemyBullet:new(x, y)
    local self = setmetatable({}, EnemyBullet)
    self.x = x
    self.y = y
    self.width = 10
    self.height = 10
    self.speed = 150
    self.vx = 0  -- Horizontal velocity
    self.vy = 0  -- Vertical velocity
    self.color = {1, 0.3, 0.3}  -- Pink-red
    return self 
end

function EnemyBullet:update(dt)
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt
end

function EnemyBullet:draw()
    love.graphics.setColor(self.color)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    love.graphics.setColor(1, 1, 1)  -- Reset color
end

function EnemyBullet:isOffScreen()
    return self.x < -self.width or 
           self.x > love.graphics.getWidth() or
           self.y < -self.height or
           self.y > love.graphics.getHeight()
end