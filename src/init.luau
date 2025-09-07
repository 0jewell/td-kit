-- modules
local pathway = require('@self/pathway')
export type pathway = pathway.pathway
export type node = pathway.node
export type traveller = pathway.traveller

-- helpers
local function build_from_waypoints(waypoints_folder: Instance): pathway
    return pathway().build_from_waypoints(waypoints_folder)
end

local function build_from_attachments(root_part: BasePart): pathway
    return pathway().build_from_attachments(root_part)
end

local function build_from_positions(positions: { Vector3 }): pathway
    return pathway().build_from_positions(positions)
end

-- export
return {
    new = pathway,
    from_waypoints = build_from_waypoints,
    from_attachments = build_from_attachments,
    from_positions = build_from_positions
}