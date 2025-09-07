-- modules
local pathway = require('@self/pathway')
export type pathway = pathway.pathway
export type node = pathway.node
export type traveller = pathway.traveller

-- local intersection = require('@self/intersection')

-- export
return {
    new = pathway,
    from_waypoints = pathway.build_from_waypoints,
    from_attachments = pathway.build_from_attachments,
    from_positions = pathway.build_from_positions

    -- intersections exports
}