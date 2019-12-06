local love = love
local lg = love.graphics

lg.setBackgroundColor(0.4, 0.4, 0.4)

local table = table

local math = math

local function ccw(x1,y1,x2,y2,x3,y3)
  return (y3 - y1) * (x2 - x1) > (y2 - y1) * (x3 - x1)
end

local function lineIntersectsLine(x1, y1, x2, y2, x3, y3, x4, y4)
  local x = ((x1 * y2 - y1 * x2) * (x3 - x4) - (x1 - x2) * (x3 * y4 - y3 * x4)) / ((x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4))
  local y = ((x1 * y2 - y1 * x2) * (y3 - y4) - (y1 - y2) * (x3 * y4 - y3 * x4)) / ((x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4))
  if ccw(x1, y1, x3, y3, x4, y4) ~= ccw(x2, y2, x3, y3, x4, y4) and ccw(x1, y1, x2, y2, x3, y3) ~= ccw(x1, y1, x2, y2, x4, y4) then
    return x, y
  end
end

local shapes = {}

do
  local circle = {}
  
  local radius = 100
  local segments = 4
  
  for i=0, segments - 1 do
    local angle = -i / segments * math.pi * 2
    table.insert(circle, lg.getWidth() / 2 + math.cos(angle) * radius)
    table.insert(circle, lg.getHeight() / 2 + math.sin(angle) * radius)
  end
  
  table.insert(shapes, circle)
end

local clickStart = {}
local clicked = false

local normalPush = 7

function love.mousepressed(x, y, b)
  if b == 1 then
    if not clicked then
      clickStart[1], clickStart[2] = x, y
    elseif x ~= clickStart[1] or y ~= clickStart[2] then
      
      for i = #shapes, 1, -1 do
        local shape = shapes[i]
        
        local intersections = {}
        for i=1, #shape, 2 do
          local x1, y1, x2, y2 = shape[i], shape[i + 1], (i == #shape - 1) and shape[1] or shape[i + 2], (i == #shape - 1) and shape[2] or shape[i + 3]
          local ix, iy = lineIntersectsLine(x1, y1, x2, y2, clickStart[1], clickStart[2], x, y)
          if ix then
            table.insert(intersections, {index = i, ix, iy})
          end
        end
        
        if #intersections == 2 then
          table.remove(shapes, i)
          
          local normal = {x = intersections[2][1] - intersections[1][1], y = intersections[2][2] - intersections[1][2]}
          do
            local len = (normal.x^2 + normal.y^2)^0.5
            normal.x = normal.x / len
            normal.y = normal.y / len
            normal.x, normal.y = normal.y, -normal.x
          end
          
          local newShape1 = {intersections[1][1], intersections[1][2]} -- from 1 to 2
          local newShape2 = {intersections[2][1], intersections[2][2]} -- from 2 to 1
          
          local ind1 = intersections[1].index
          local ind2 = intersections[2].index
          
          local lastEarly = 3
          
          for i=1, #shape, 2 do
            local finalShape
            local index
            
            if i > ind1 and i <= ind2 then
              finalShape = newShape1
            else
              finalShape = newShape2
              if i > ind2 then
                index = lastEarly
                lastEarly = lastEarly + 2
              end
            end
            
            index = index or (#finalShape + 1)
            
            table.insert(finalShape, index, shape[i])
            index = index + 1
            table.insert(finalShape, index, shape[i + 1])
            
            if not finalShape.tx then
              if ccw(intersections[1][1], intersections[1][2], intersections[2][1], intersections[2][2], shape[i], shape[i + 1]) then
                finalShape.tx, finalShape.ty = -normal.x * normalPush, -normal.y * normalPush
              else
                finalShape.tx, finalShape.ty = normal.x * normalPush, normal.y * normalPush
              end
            end
          end
          
          for i=1, #newShape1, 2 do
            newShape1[i] = newShape1[i] + newShape1.tx
            newShape1[i + 1] = newShape1[i + 1] + newShape1.ty
          end
          
          for i=1, #newShape2, 2 do
            newShape2[i] = newShape2[i] + newShape2.tx
            newShape2[i + 1] = newShape2[i + 1] + newShape2.ty
          end
          
          table.insert(newShape1, intersections[2][1])
          table.insert(newShape1, intersections[2][2])
          
          table.insert(newShape2, intersections[1][1])
          table.insert(newShape2, intersections[1][2])
          
          table.insert(shapes, newShape1)
          table.insert(shapes, newShape2)
        end
        
      end
      
    end
    clicked = not clicked
  end
end

function love.draw()
  for si, shape in ipairs(shapes) do
    lg.setColor(1,1,1)
    lg.polygon("fill", shape)
    lg.setColor(0.5, 0.5, 0.5)
    lg.setLineWidth(1)
    lg.setLineJoin("none")
    lg.polygon("line", shape)
  end
  if clicked then
    lg.setColor(1, 0, 0)
    lg.setLineWidth(2)
    lg.line(clickStart[1], clickStart[2], love.mouse.getPosition())
  end
end