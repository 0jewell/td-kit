-- modules
local pathway = require('@self/pathway')
export type pathway = pathway.pathway
export type node = pathway.node
export type traveller = pathway.traveller

local intersection = require('@self/intersection')

-- export
return {
    new = pathway,
    from_waypoints = pathway.from_waypoints,
    from_attachments = pathway.from_attachments,
    from_positions = pathway.from_positions,

    -- intersections exports
    intersections_on_circle = intersection.on_circle,
    intersection_lengths_in_node = intersection.lengths_in_node
}