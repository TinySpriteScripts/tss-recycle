local QBCore = exports['qb-core']:GetCoreObject()

SpawnedProp = {}
local SpawnTargetProp = {}

local my_citizenid = nil

AddEventHandler('onResourceStart', function(resource) 
    if GetCurrentResourceName() ~= resource then return end
    my_citizenid = QBCore.Functions.GetPlayerData().citizenid
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    my_citizenid = QBCore.Functions.GetPlayerData().citizenid
end)

CreateThread(function()
    for k,v in pairs(Config.SpawnRecycler) do
        if v.Enable then
            for d,j in pairs(v.Locations) do
                local model = ''
                model = v.prop
                RequestModel(model)
                while not HasModelLoaded(model) do
                  Wait(0)
                end
            
                SpawnedProp["Prop"..k..d] = CreateObject(model, j.Coords.x, j.Coords.y, j.Coords.z-1, false, true, false)
		        SetEntityHeading(SpawnedProp["Prop"..k..d],j.Coords.w)
                FreezeEntityPosition(SpawnedProp["Prop"..k..d],true)
                SetEntityAsMissionEntity(SpawnedProp["Prop"..k..d])  
                SpawnTargetProp["SpawnTargetProp"..k..d] = 
                exports['ox_target']:addLocalEntity(SpawnedProp["Prop"..k..d], {
                    {
                        onSelect = function()
                            OpenRecycleMenu(j.ID)
                        end,
                        icon = "fas fa-hammer",
                        label = v.Label,
                        distance = 3.0,
                    },
                })
            end
        end
    end
end)

--this event is triggerred from a base building prop and shouldnt be removed
RegisterNetEvent('tss-recycle:OpenRecycle',function(identifier) 
    identifier = "base_prop_"..identifier
    OpenRecycleMenu(identifier)
end)

function OpenRecycleMenu(identifier)
    local columns = {}
    QBCore.Functions.TriggerCallback('tss-recycle:GetRecyclerState',function(return_data)
        if return_data then
            if not return_data.turned_on then
                table.insert(columns, {
                    title = "Start Recycling",
                    icon = "power-off",
                    serverEvent = "tss-recycle:startRecycler",
                    args = {identifier = identifier},
                })
            else
                table.insert(columns, {
                    title = "Stop Recycling",
                    icon = "power-off",
                    serverEvent = "tss-recycle:stopRecycler",
                    args = {identifier = identifier},
                })
            end
            table.insert(columns, {
                title = "Open Input",
                icon = "download",
                serverEvent = "tss-recycle:OpenInputStash",
                args = {identifier = identifier},
            })
            table.insert(columns, {
                title = "Open Output",
                icon = "upload",
                serverEvent = "tss-recycle:OpenOutputStash",
                args = {identifier = identifier},
            })
            lib.registerContext({
                id = 'sayer_recycle_menu',
                title = 'Recycling',
                options = columns
            })
            lib.showContext('sayer_recycle_menu')
        end
    end, identifier)
end


AddEventHandler('onResourceStop', function(t) if t ~= GetCurrentResourceName() then return end
    for k in pairs(SpawnTargetProp) do exports.ox_target:removeLocalEntity(k) end
    for _,v in pairs(SpawnedProp) do
        if DoesEntityExist(v) then
            DeleteEntity(v)
        end
    end
end)
