Bullet = {}
Bullet.__index = Bullet

function Bullet:new(x, y)
    local self = setmetatable({}, Bullet)
    self.x = x
    self.y = y
    self.width = 10
    self.height = 10
    self.speed = 400
    self.color = {1, 1, 0}  -- Yellow color
    return self
end

function Bullet:update(dt)
    self.y = self.y - self.speed * dt  -- Move upward
end

function Bullet:draw()
    love.graphics.setColor(self.color)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    love.graphics.setColor(1, 1, 1)  -- Reset color to white
end

function Bullet:isOffScreen()
    return self.y < -self.height
end