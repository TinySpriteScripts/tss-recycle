
# TSS Recycle

## install:

### core_inventory:

- inside your Config.Inventories insert 2 new inventory types from below (configure your own `slots` and `rows`)
```lua
["recycler_input"] = {
    slots = 100,
    rows = 10,
    x = "20%",
    y = "20%",
    label = "RECYCLER INPUT",
},

["recycler_output"] = {
    slots = 100,
    rows = 10,
    x = "20%",
    y = "20%",
    label = "RECYCLER OUTPUT",
},
```

### hrs_base_building

- in the Config.Models any model that has `type = "recycle"` change the event to the one below
```lua
TriggerEvent = {
    type = "client",
    event = "tss-recycle:pre_OpenRecycle",
    args = {"hrs_base_entity"},
    entityAsArg = "hrs_base_entity"
},
```

- where i made the function `SayercheckEntity()` in `client/main_unlocked.lua` it should look like this after jukebox, playerstores and recycle is installed
```lua
function SayerCheckEntity(id, cb)
    local can_delete = true
    local reason = ""

    for entity, values in pairs(propsalreadyspowned) do
        if values.id == id then
            local modelType = Config.Models[values.hash].type

            if modelType == "jukebox" then
                TriggerServerEvent('sayer-jukebox:DestroySound', values.id, true)
            elseif modelType == "recycle" then
                TriggerServerEvent('tss-recycle:StopBaseRecycler', values.id)
            elseif modelType == "player_store" then
                if values.clientmetadata and values.clientmetadata.citizenid then
                    print("running callback for stock items")
                    QBCore.Functions.TriggerCallback('sayer-stores:has_items_in_stock', function(has_items)
                        if has_items then
                            print("cannot Delete")
                            can_delete = false
                            reason = "You Have Items In Your Store"
                        end
                        cb(can_delete, reason)
                    end, values.clientmetadata.citizenid)
                    return -- early return because we're handling the callback
                end
            end
        end
    end

    cb(can_delete, reason)
end
```

- add this new event in the `client/main_unlocked.lua`
```lua
RegisterNetEvent('tss-recycle:pre_OpenRecycle',function(entity) 
    local propsID = propsalreadyspowned[entity].id
    TriggerEvent('tss-recycle:OpenRecycle', propsID)
end)
```

### other steps
- make sure to configure the Config