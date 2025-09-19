-- modules
local pathway = require('./pathway')
type pathway = pathway.pathway
type node = pathway.node

-- types
export type t_list = {
    enter: number,
    exit: number
}

export type intersection = {
    min_distance: number,
    max_distance: number
}

-- this
local function get_segment_sphere_intersection(
    A: Vector3,
    B: Vector3,
    center: Vector3,
    radius: number
): t_list?
    local AB = B - A
    local AC = A - center

    local a = AB:Dot(AB)
    local b = 2 * AB:Dot(AC)
    local c = AC:Dot(AC) - radius^2

    local discriminant = b^2 - 4 * a * c

    if discriminant < 0 then
        return nil
    end

    local sqrt_discriminant = math.sqrt(discriminant)
    local t1 = (-b - sqrt_discriminant) / (2 * a)
    local t2 = (-b + sqrt_discriminant) / (2 * a)

    local results = {}
    if t1 >= 0 and t1 <= 1 then
        results.enter = t1
    end
    if t2 >= 0 and t2 <= 1 then
        results.exit = t2
    end

    return results
end

local function get_intersection_lengths_in_node(
    node: node,
    position: Vector3,
    range: number
): (number?, number?)

    local start_pos, final_pos = node.start_position, node.final_position
    local t_list = get_segment_sphere_intersection(start_pos, final_pos, position, range)

    if not t_list then
        return nil
    end

    if not t_list.exit and not t_list.enter then
        local middle_position = node.start_position:Lerp(node.final_position, 1/2)

        if (position - middle_position).Magnitude <= range then
            return node.start_length, node.final_length
        else
            return nil
        end
    end

    local start_length = t_list.enter
        and node.start_length + t_list.enter * node.length
        or node.start_length

    local end_length = t_list.exit
        and node.start_length + t_list.exit * node.length
        or node.final_length

    return start_length, end_length
end

local function get_path_intersections_on_circle(
    pathway: pathway,
    position: Vector3,
    range: number
): { intersection }
    local intersections = {}

    for _, node in ipairs(pathway.nodes) do
        local start_length, end_length = get_intersection_lengths_in_node(node, position, range)
        
        if start_length and end_length then
            table.insert(intersections, {
                min_distance = math.min(start_length, end_length),
                max_distance = math.max(start_length, end_length)
            })
        end
    end

    table.sort(intersections, function(a, b)
        return a.min_distance < b.min_distance
    end)

    return intersections
end

return {
    on_circle = get_path_intersections_on_circle,
    lengths_in_node = get_intersection_lengths_in_node
}