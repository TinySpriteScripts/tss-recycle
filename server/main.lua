local QBCore = exports['qb-core']:GetCoreObject()

local ActiveRecyclerUsers = {}

local ActiveRecyclerLoops = {} -- Stores threads per player+entity

AddEventHandler('onResourceStart', function(resource) 
    if GetCurrentResourceName() ~= resource then return end
end)

local function StartRecyclingLoop(src, identifier, citizenid)
    local key = identifier .. ":" .. citizenid
    if ActiveRecyclerLoops[key] then return end -- already running
    local itemsProcessed = 0

    ActiveRecyclerLoops[key] = true

    local inputStashName = 'recycler_input-' .. identifier .. citizenid
    local outputStashName = 'recycler_output-' .. identifier .. citizenid

    exports.core_inventory:openInventory(src, outputStashName, 'recycler_output', nil, nil, false, nil, false) --used to load output inventory or create it if not created already

    CreateThread(function()
        while ActiveRecyclerUsers[identifier] and ActiveRecyclerUsers[identifier][citizenid] do
            Wait(Config.RecycleTime * 1000)

            local items = exports.core_inventory:getInventory(inputStashName)

            if not items or #items == 0 then goto continue end

            for _, item in pairs(items) do
                local recycleData = Config.Recycle[item.name]
                if recycleData then
                    local removeCount = math.min(item.amount, 1)

                    -- First check if all recycled materials can fit
                    local can_carry = true
                    local matAmounts = {}

                    for _, mat in ipairs(recycleData) do
                        local amount = math.random(mat.Min, mat.Max)
                        matAmounts[#matAmounts + 1] = { item = mat.item, amount = amount }

                        if not exports.core_inventory:canCarry(outputStashName, mat.item, amount) then
                            can_carry = false
                            break
                        end
                    end

                    if not can_carry then
                        SendNotify(src, "Output Full", 'Your Recycler Cannot Output Any More Items', 'error')
                        goto continue
                    end

                    -- Now safe to remove and add
                    exports.core_inventory:removeItem(inputStashName, item.name, removeCount)
                    DebugCode("removed item: "..item.name)

                    for _, mat in ipairs(matAmounts) do
                        exports.core_inventory:addItem(outputStashName, mat.item, mat.amount)
                        DebugCode("gained item: "..mat.item)
                    end

                    itemsProcessed = itemsProcessed + 1
                    if itemsProcessed >= (Config.RecycleRate or 1) then break end
                end
            end

            ::continue::
        end

        ActiveRecyclerLoops[key] = nil
    end)
end

QBCore.Functions.CreateCallback("tss-recycle:GetRecyclerState", function(source, cb, identifier)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local citizenid = Player.PlayerData.citizenid

    local return_data = {
        turned_on = false,
    }

    if ActiveRecyclerUsers[identifier] ~= nil then 
        if ActiveRecyclerUsers[identifier][citizenid] ~= nil then
            return_data.turned_on = true
        end
    end
    cb(return_data)
end)

RegisterNetEvent('tss-recycle:OpenInputStash',function(data)
    local identifier = data.identifier
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local citizenid = Player.PlayerData.citizenid

    exports.core_inventory:openInventory(src, 'recycler_input-'..identifier..citizenid, 'recycler_input', nil, nil, true, nil, false)
end)

RegisterNetEvent('tss-recycle:OpenOutputStash',function(data)
    local identifier = data.identifier
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local citizenid = Player.PlayerData.citizenid

    exports.core_inventory:openInventory(src, 'recycler_output-'..identifier..citizenid, 'recycler_output', nil, nil, true, nil, false)
end)

RegisterNetEvent('tss-recycle:startRecycler', function(data)
    local identifier = data.identifier
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local citizenid = Player.PlayerData.citizenid
    identifier = tostring(identifier) -- ensure string key

    local input_stash = exports.core_inventory:getInventory('recycler_input-'..identifier..citizenid)

    if not ActiveRecyclerUsers[identifier] then ActiveRecyclerUsers[identifier] = {} end
    ActiveRecyclerUsers[identifier][citizenid] = true
    SendNotify(src, "Recycling Started", "Your Recycler is now turned on")
    
    StartRecyclingLoop(src, identifier, citizenid)
    -- Create a function or loop to handle when recyclers are turned on. it should take the items from input_stash and loop through them.
end)

RegisterNetEvent('tss-recycle:stopRecycler', function(data)
    local identifier = data.identifier
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local citizenid = Player.PlayerData.citizenid
    identifier = tostring(identifier)

    if ActiveRecyclerUsers[identifier] then
        ActiveRecyclerUsers[identifier][citizenid] = nil
        SendNotify(src, "Recycling Stopped", "Recycler Has Stopped")
        if next(ActiveRecyclerUsers[identifier]) == nil then
            ActiveRecyclerUsers[identifier] = nil
        end
    end
end)

RegisterNetEvent('tss-recycle:StopBaseRecycler', function(identifier)
    local identifier = "base_prop_"..identifier
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local citizenid = Player.PlayerData.citizenid
    identifier = tostring(identifier)

    if ActiveRecyclerUsers[identifier] then
        ActiveRecyclerUsers[identifier] = nil
        SendNotify(src, "Recycling Stopped", "Your Base Recycler Has Stopped")
    end

end)

AddEventHandler("playerDropped", function(reason)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    local cid = Player.PlayerData.citizenid
    for id, users in pairs(ActiveRecyclerUsers) do
        if users[cid] then
            users[cid] = nil
            if next(users) == nil then ActiveRecyclerUsers[id] = nil end
            ActiveRecyclerLoops[id..":"..cid] = nil
        end
    end
end)

function DebugCode(msg)
    if Config.DebugCode then
        print(msg)
    end
end

function SendNotify(src, Title, Msg, Type, Time)
    if not Title then Title = "Stores" end
    if not Time then Time = 5000 end
    if not Type then Type = 'success' end
    if not Msg then DebugCode("SendNotify Server Triggered With No Message") return end
    if Config.Notify == 'qb' then
        TriggerClientEvent('QBCore:Notify', src, Msg, Type, Time)
    elseif Config.Notify == 'okok' then
        TriggerClientEvent('okokNotify:Alert', src, Title, Msg, Time, Type, false)
    elseif Config.Notify == 'qs' then
        TriggerClientEvent('qs-notify:Alert', src, Msg, Time, Type)
    elseif Config.Notify == 'ox' then
        local data = {
            id = 'sayerstores_notify',
            title = Title,
            description = Msg,
            type = Type 
        }
        TriggerClientEvent('ox_lib:notify', src, data)
    elseif Config.Notify == 'other' then
        --add your notify event here
    end
end