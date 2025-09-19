# tdkit
tdkit is a lightweight module to help building Tower Defense mechanics on Roblox. Developed by me.

## Info
tdkit allows you to easily create pathways, move enemies along them, and detect intersections with towers' ranges.

## Installation

- Pesde:
```sh
pesde add 0jewell/tdkit
```

## Usage

Creating a pathway

```luau
local positions = {
    Vector3.new(0, 0, 0),
    Vector3.new(20, 0, 0),
    Vector3.new(30, 0, 10),
    Vector3.new(40, 0, 10),
}

local pathway = tdkit.from_positions(positions)
```

Creating a traveller (enemy)

```luau
local enemy = pathway.traveller()

while not enemy.is_at_end() do
    enemy.move(1) -- move 1 stud per tick
    task.wait(0.1)
end
```

Creating a tower and checking intersections

```luau
local tower_position = Vector3.new(10, 0, 0)
local tower_range = 8

local intersections = tdkit.intersections_on_circle(pathway, tower_position, tower_range)
```

Checking if enemy is in tower range

```luau
local function is_in_bounds(enemy, hitbox)
    return enemy.current_length >= hitbox.min_distance and enemy.current_length <= hitbox.max_distance
end

for _, seg in ipairs(intersections) do
    if is_in_bounds(enemy, seg) then
        print('enemy is inside tower hitbox')
    end
end
```