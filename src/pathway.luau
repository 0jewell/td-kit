-- types
export type ordered_node_details = {
    start: Vector3,
    ending: Vector3,
}
export type new_node_details = ordered_node_details & {
    start_length: number
}

export type partial_traveller = {
    current_index: number
}
export type traveller_settings = {
    speed: number?,
    length: number?
}

-- this
local function node_new(details: new_node_details)
    local start_length = details.start_length

    local start_position, final_position = details.start, details.ending
    local length = (final_position - start_position).Magnitude

    return {
        start_length = start_length,
        final_length = start_length + length,
        start_position = start_position,
        final_position = final_position,
        length = length,
    }
end

local function calculate_position_in_node(
    node: node,
    length: number
): Vector3
    local length_in_node = length - node.start_length
    local progress_in_node = node.length > 0 and (length_in_node / node.length) or 0
    
    return node.start_position + (node.final_position - node.start_position) * progress_in_node
end

local function pathway_new()
    local pathway = { nodes = {}, total_length = 0 }

    function pathway.new_node(details: ordered_node_details): node
        local node = node_new({
            start = details.start,
            ending = details.ending,
            start_length = pathway.total_length
        })
        pathway.total_length += node.length

        table.insert(pathway.nodes, node)
        return node
    end

    local function find_node_for_length(
        current_length: number,
        search_direction: number,
        last_index: number
    ): number
        local start_index = math.clamp(last_index, 1, #pathway.nodes)

        if search_direction == 1 then
            -- search forward
            for i = start_index, #pathway.nodes do
                if current_length <= pathway.nodes[i].final_length then
                    return i
                end
            end
            return #pathway.nodes
        else
            -- search backward
            for i = start_index, 1, -1 do
                if current_length >= pathway.nodes[i].start_length then
                    return i
                end
            end
            return 1
        end
    end

    local function get_traveller_position(
        traveller: partial_traveller,
        current_length: number,
        direction: number
    ): Vector3
        if #pathway.nodes == 0 then
            return Vector3.new()
        end

        local current_node = pathway.nodes[traveller.current_index]
        
        -- if the length is within the current node, calculate directly
        if current_node
            and current_length >= current_node.start_length
            and current_length <= current_node.final_length
        then
            return calculate_position_in_node(current_node, current_length)
        end

        -- if not, find the correct node
        local new_index = find_node_for_length(current_length, direction, traveller.current_index)
        traveller.current_index = new_index

        local target_node = pathway.nodes[new_index]
        if target_node then
            return calculate_position_in_node(target_node, current_length)
        end
        
        -- fallback
        return pathway.nodes[#pathway.nodes].final_position
    end

    local function calculate_distance(
        current_length: number,
        distance: number
    ): number

        local total_length = pathway.total_length
        local new_length = math.clamp(current_length + distance, 0, total_length)

        return new_length
    end

    function pathway.traveller_at(settings: traveller_settings): traveller
        local traveller = {
            current_length = settings.length or 0,
            last_length = settings.length or 0,
            current_index = 0,

            last_update = os.clock(),
            speed = settings.speed or 1,
            direction = 1,
            frozen = false
        }

        function traveller.get_length()
            local length = traveller.current_length
        
            if not traveller.frozen then
                local now = os.clock()
                local elapsed_time = now - traveller.last_update
                local distance = elapsed_time * traveller.speed * traveller.direction
                
                length = calculate_distance(length, distance)
            end

            return length
        end

        function traveller.update_and_get_length()
            local length = traveller.get_length()
            
            traveller.current_length = length
            traveller.last_update = os.clock()
            return length
        end

        function traveller.set_speed(new_speed: number)
            traveller.update_and_get_length()
            traveller.speed = new_speed
        end

        function traveller.set_direction(new_direction: number)
            traveller.update_and_get_length()
            traveller.direction = new_direction >= 0 and 1 or -1
        end

        function traveller.freeze()
            traveller.update_and_get_length()
            traveller.frozen = true
        end

        function traveller.unfreeze()
            traveller.update_and_get_length()
            traveller.frozen = false
        end

        function traveller.get_position(): Vector3
            local current_length = traveller.get_length() -- readonly
            return get_traveller_position(traveller, current_length, traveller.direction)
        end

        function traveller.is_at_end(): boolean
            return traveller.get_length() >= pathway.total_length
        end

        function traveller.move(deltaTime: number): number
            if traveller.frozen then
                return traveller.current_length
            end

            local distance = deltaTime * traveller.speed * traveller.direction
            local new_length = calculate_distance(traveller.current_length, distance)

            traveller.current_length = new_length
            traveller.last_update = os.clock()
            return new_length
        end

        function traveller.get_progress(): number
            if pathway.total_length == 0 then return 0 end
            return traveller.get_length() / pathway.total_length
        end

        return traveller
    end

    function pathway.traveller(settings: traveller_settings?): traveller
        return pathway.traveller_at(settings or {})
    end

    -- exports
    pathway.position_in_node = calculate_position_in_node
    pathway.find_node_for_length = find_node_for_length
    pathway.calculate_distance = calculate_distance
    pathway.get_traveller_position = get_traveller_position

    return pathway
end

local function build_from_waypoints(waypoints_folder: Instance)
    local pathway = pathway_new()

    local function build()
        pathway.nodes = {}
        pathway.total_length = 0

        local children = waypoints_folder:GetChildren()
        local valid_waypoints = {}

        for _, child in ipairs(children) do
            local index = tonumber(child.Name)
            if index ~= nil then
                local attachment = child:FindFirstChildWhichIsA("Attachment")

                if attachment then
                    table.insert(valid_waypoints, {
                        index = index,
                        attachment = attachment,
                    })
                end
            end
        end

        table.sort(valid_waypoints, function(a, b)
            return a.index < b.index
        end)

        for i = 1, #valid_waypoints - 1 do
            local current = valid_waypoints[i].attachment
            local next = valid_waypoints[i + 1].attachment

            pathway.new_node {
                start = current.WorldPosition,
                ending = next.WorldPosition,
            }
        end
    end
    build()

    -- connections
    waypoints_folder.ChildAdded:Connect(build)
    waypoints_folder.ChildRemoved:Connect(build)

    return pathway
end

local function build_from_attachments(root_part: BasePart): pathway
    local pathway = pathway_new()

    local attachment = root_part:FindFirstChild('0') :: Attachment
    if not attachment then
        error(`invalid rootpart at {root_part.Name}`)
    end

    repeat
        local next_ref = attachment:FindFirstAncestorWhichIsA('ObjectValue')
        if not next_ref or not next_ref.Value then
            break
        end

        local next_attachment = next_ref.Value :: Attachment

        pathway.new_node {
            start = attachment.WorldPosition,
            ending = next_attachment.WorldPosition,
        }

        attachment = next_attachment
    until false

    return pathway
end

local function build_from_positions(positions: { Vector3 }): pathway
    local pathway = pathway_new()

    for i = 1, #positions - 1 do
        pathway.new_node {
            start = positions[i],
            ending = positions[i + 1],
        }
    end

    return pathway
end

export type node = typeof(node_new(_G))
export type pathway = typeof(pathway_new())
export type traveller = typeof(pathway_new().traveller(_G))

return {
    new = pathway_new,
    from_waypoints = build_from_waypoints,
    from_attachments = build_from_attachments,
    from_positions = build_from_positions
}