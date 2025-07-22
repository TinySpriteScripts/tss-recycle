local QBCore = exports['qb-core']:GetCoreObject()

local ActiveRecyclerUsers = {}

local ActiveRecyclerLoops = {} -- Stores threads per player+entity

AddEventHandler('onResourceStart', function(resource) 
    if GetCurrentResourceName() ~= resource then return end
end)

AddEventHandler('onResourceStop', function(resource)
    if GetCurrentResourceName() ~= resource then return end
    ActiveRecyclerUsers = {}
    ActiveRecyclerLoops = {}
end)

local function GetLoopKey(identifier, citizenid)
    if Config.UniqueStash then
        return identifier .. ":" .. citizenid
    else
        return identifier
    end
end


local function GetInputStashName(identifier, citizenid)
    if Config.UniqueStash then
        return 'recycler_input-' .. identifier .. citizenid
    else
        return 'recycler_input-' .. identifier
    end
end

local function GetOutputStashName(identifier, citizenid)
    if Config.UniqueStash then
        return 'recycler_output-' .. identifier .. citizenid
    else
        return 'recycler_output-' .. identifier
    end
end


local function StartRecyclingLoop(src, identifier, citizenid)
    local key = GetLoopKey(identifier, citizenid)
    if ActiveRecyclerLoops[key] then return end -- already running
    local itemsProcessed = 0

    ActiveRecyclerLoops[key] = true

    local inputStashName = GetInputStashName(identifier, citizenid)
    local outputStashName = GetOutputStashName(identifier, citizenid)

    exports.core_inventory:openInventory(src, outputStashName, 'recycler_output', nil, nil, false, nil, false)

    CreateThread(function()
        while ActiveRecyclerUsers[identifier] and ActiveRecyclerUsers[identifier][citizenid] do
            Wait(Config.RecycleTime * 1000)

            local items = exports.core_inventory:getInventory(inputStashName)

            if not items or #items == 0 then goto continue end

            for _, item in pairs(items) do
                local recycleData = Config.Recycle[item.name]
                if recycleData then
                    local removeCount = math.min(item.amount, 1)

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

                    if not can_carry then -- removed UniqueStash check so it's always enforced
                        SendNotify(src, "Output Full", 'Your Recycler Cannot Output Any More Items', 'error')
                        goto continue
                    end

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
        DebugCode("Stopped recycler loop: "..key)
    end)
end

QBCore.Functions.CreateCallback("sayer-recycle:GetRecyclerState", function(source, cb, identifier)
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

RegisterNetEvent('sayer-recycle:OpenInputStash',function(data)
    local identifier = data.identifier
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local citizenid = Player.PlayerData.citizenid

    local inventoryString = GetInputStashName(identifier, citizenid)

    exports.core_inventory:openInventory(src, inventoryString, 'recycler_input', nil, nil, true, nil, false)
end)

RegisterNetEvent('sayer-recycle:OpenOutputStash',function(data)
    local identifier = data.identifier
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local citizenid = Player.PlayerData.citizenid
    local inventoryString = GetOutputStashName(identifier, citizenid)

    exports.core_inventory:openInventory(src, inventoryString, 'recycler_output', nil, nil, true, nil, false)
end)

RegisterNetEvent('sayer-recycle:startRecycler', function(data)
    local identifier = data.identifier
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local citizenid = Player.PlayerData.citizenid
    identifier = tostring(identifier)
    local inventoryString = GetInputStashName(identifier, citizenid)

    if Config.UniqueStash then
        if not ActiveRecyclerUsers[identifier] then ActiveRecyclerUsers[identifier] = {} end
        ActiveRecyclerUsers[identifier][citizenid] = true
    else
        ActiveRecyclerUsers[identifier] = true
    end
    SendNotify(src, "Recycling Started", "Your Recycler is now turned on")

    StartRecyclingLoop(src, identifier, citizenid)
end)

RegisterNetEvent('sayer-recycle:stopRecycler', function(data)
    local identifier = data.identifier
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local citizenid = Player.PlayerData.citizenid
    identifier = tostring(identifier)

    if Config.UniqueStash then
        if ActiveRecyclerUsers[identifier] then
            ActiveRecyclerUsers[identifier][citizenid] = nil
            if next(ActiveRecyclerUsers[identifier]) == nil then
                ActiveRecyclerUsers[identifier] = nil
            end
        end
    else
        ActiveRecyclerUsers[identifier] = nil
    end

    ActiveRecyclerLoops[GetLoopKey(identifier, citizenid)] = nil -- added cleanup
    SendNotify(src, "Recycling Stopped", "Your Recycler has been turned off") -- added consistency
end)

RegisterNetEvent('sayer-recycle:StopBaseRecycler', function(identifier)
    local identifier = "base_prop_"..identifier
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local citizenid = Player.PlayerData.citizenid
    identifier = tostring(identifier)

    if ActiveRecyclerUsers[identifier] then
        ActiveRecyclerUsers[identifier] = nil
        ActiveRecyclerLoops[GetLoopKey(identifier, citizenid)] = nil -- cleanup added
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
            ActiveRecyclerLoops[GetLoopKey(id, cid)] = nil
        end
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