Bullet = {}
Bullet.__index = Bullet

function Bullet:new(x, y)
    local self = setmetatable({}, Bullet)
    self.x = x
    self.y = y
    self.width = 10
    self.height = 10
    self.speed = 400
    self.vx = 0  -- Horizontal velocity (default 0)
    self.vy = -self.speed  -- Vertical velocity (default up)
    self.color = {1, 1, 0}  -- Yellow color
    return self
end

function Bullet:update(dt)
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt
end

function Bullet:draw()
    love.graphics.setColor(self.color)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    love.graphics.setColor(1, 1, 1)  -- Reset color to white
end

function Bullet:isOffScreen()
    return self.y < -self.height
end