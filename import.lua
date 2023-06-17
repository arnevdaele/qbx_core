--[[
    Usage:

    shared_script '@qbx-core/import.lua'

    modules { -- Can be `module 'module_name'` as well
        'module_name', -- This is the name of the file in the modules folder in qbx-core without the .lua
        'client:module_name', -- You can specify the side it should be loaded on like this
        'resourceName:module_name', -- You can also specify the resource it should be loaded from if you don't want to load it from qbx-core
        'resourceName:client:module_name' -- The resource loading also accepts a side to load on
    }
]]

local resources = {}
local isServer = IsDuplicityVersion()

local function getSide(value)
    return value == 'client' and 'client' or value == 'server' and 'server' or value == 'shared' and 'shared' or 'none'
end

local function checkSide(value)
    return value == 'client' and not isServer or value == 'server' and isServer or value == 'shared'
end

for i = 0, GetNumResources() - 1 do
    local resource = GetResourceByFindIndex(i)
    if GetResourceState(resource) == 'started' then
        resources[resource] = true
    end
end

for i = 0, GetNumResourceMetadata(resourceName, 'module') - 1 do
    local resourceName = 'qbx-core'
    local module = GetResourceMetadata(resourceName, 'module', i)
    if module then
        local file = module
        local split = {string.strsplit(':', module)}
        local doLoad = true
        if #split > 1 then
            local side = getSide(split[1])
            local isSide = side ~= 'none'
            local isResource = resources[split[1]]
            if isResource then
                resourceName = split[1]
                side = getSide(split[2])
                isSide = side ~= 'none'
            end

            side = not isSide and 'shared' or side

            doLoad = checkSide(side)
            file = isResource and isSide and split[3] or not isResource and isSide and split[2] or split[1]
        end

        if doLoad then
            local path = ('modules/%s.lua'):format(file)
            local import = LoadResourceFile(resourceName, path)
            local chunk = assert(load(import, ('@@%s/%s'):format(resourceName, path)))
            if chunk then
                chunk()
            end
        end
    end
end
