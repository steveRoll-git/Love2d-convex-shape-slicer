--[[
Anything that describes a position is a table with indexes [1] and [2] being the x and y of the point.
(other than `normal` on line 72)
This is so it'll be easier to draw the shapes with love.graphics.polygon later
]]

local love = love
local lg = love.graphics

lg.setBackgroundColor(0.4, 0.4, 0.4)

local table = table
local math = math

local function ccw(x1, y1,  x2, y2,  x3, y3) -- returns whether the points 1, 2 and 3 are in counter-clockwise order
  return (y3 - y1) * (x2 - x1) > (y2 - y1) * (x3 - x1)
end

local function lineIntersectsLine(x1, y1, x2, y2, x3, y3, x4, y4) -- returns the point of intersection between segments 1-2 and 3-4
  local x = ((x1 * y2 - y1 * x2) * (x3 - x4) - (x1 - x2) * (x3 * y4 - y3 * x4)) / ((x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4))
  local y = ((x1 * y2 - y1 * x2) * (y3 - y4) - (y1 - y2) * (x3 * y4 - y3 * x4)) / ((x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4))
  if ccw(x1, y1, x3, y3, x4, y4) ~= ccw(x2, y2, x3, y3, x4, y4) and ccw(x1, y1, x2, y2, x3, y3) ~= ccw(x1, y1, x2, y2, x4, y4) then
    return x, y
  end
end

local shapes = {}

do -- generate the first shape
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

local normalPush = 5 -- by how much the newly made shapes will move

function love.mousepressed(x, y, b)
  if b == 1 then
    if not clicked then
      clickStart[1], clickStart[2] = x, y
    elseif x ~= clickStart[1] or y ~= clickStart[2] then
      
      for i = #shapes, 1, -1 do
        local shape = shapes[i]
        
        local intersections = {}
        for i=1, #shape, 2 do -- check the intersection of the slice line with every line in the shape
          local x1, y1, x2, y2 = shape[i], shape[i + 1], (i == #shape - 1) and shape[1] or shape[i + 2], (i == #shape - 1) and shape[2] or shape[i + 3]
          local ix, iy = lineIntersectsLine(x1, y1, x2, y2, clickStart[1], clickStart[2], x, y)
          if ix then
            table.insert(intersections, {ix, iy, index = i}) -- stores the position of the intersection, and the index of the line it intersected with
          end
        end
        
        if #intersections == 2 then -- the shape is sliced only when there are 2 intersections
          table.remove(shapes, i)
          
          local normal = {x = intersections[2][1] - intersections[1][1], y = intersections[2][2] - intersections[1][2]} -- vector that is perpendicular to the slice line
          do
            -- normalize `normal` and make it perpendicular
            local len = (normal.x^2 + normal.y^2)^0.5
            normal.x = normal.x / len
            normal.y = normal.y / len
            normal.x, normal.y = normal.y, -normal.x
          end
          
          local newShape1 = {intersections[1][1], intersections[1][2]} -- will contain points from intersections[1] to intersections[2]
          local newShape2 = {intersections[2][1], intersections[2][2]} -- will contain points from intersections[2] to intersections[1]
          
          local ind1 = intersections[1].index
          local ind2 = intersections[2].index
          
          local lastEarly = 3
          
          for i=1, #shape, 2 do -- iterate through the original shape's points and decide whether we add it to newShape1 or newShape2
            local finalShape -- which shape will we add this point to?
            local index -- where will we add the point?
            
            if i > ind1 and i <= ind2 then
              -- this point belongs to `newShape1` if it's between `ind1` and `ind2`
              finalShape = newShape1
            else
              -- otherwise, it belongs to `newShape2`
              finalShape = newShape2
              if i > ind2 then
                -- add this point before the first ones, so the order will be correct
                index = lastEarly
                lastEarly = lastEarly + 2
              end
            end
            
            index = index or (#finalShape + 1) -- if we didn't set `index`, just add the point to the end of the shape
            
            --add the x and y of the point to the shape
            table.insert(finalShape, index, shape[i])
            index = index + 1
            table.insert(finalShape, index, shape[i + 1])
            
            if not finalShape.tx then
              -- which side of the slicing line is this shape on?
              if ccw(intersections[1][1], intersections[1][2], intersections[2][1], intersections[2][2], shape[i], shape[i + 1]) then
                finalShape.tx, finalShape.ty = -normal.x * normalPush, -normal.y * normalPush
              else
                finalShape.tx, finalShape.ty = normal.x * normalPush, normal.y * normalPush
              end
            end
          end
          
          --newShape1 ends with intersections[2]
          table.insert(newShape1, intersections[2][1])
          table.insert(newShape1, intersections[2][2])
          
          --newShape2 ends with intersections[1]
          table.insert(newShape2, intersections[1][1])
          table.insert(newShape2, intersections[1][2])
          
          --move newShape1's points by its tx and ty
          for i=1, #newShape1, 2 do
            newShape1[i] = newShape1[i] + newShape1.tx
            newShape1[i + 1] = newShape1[i + 1] + newShape1.ty
          end
          
          --move newShape2's points by its tx and ty
          for i=1, #newShape2, 2 do
            newShape2[i] = newShape2[i] + newShape2.tx
            newShape2[i + 1] = newShape2[i + 1] + newShape2.ty
          end
          
          --add the resulting shapes
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