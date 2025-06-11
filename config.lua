Config = {}

-- for hrs_base_building prop
-- event to open recycle menu is
--  'tss-recycle:pre_OpenRecycle'

Config.DebugCode = false
Config.Notify = 'ox'

Config.SpawnRecycler = { --spawns a prop to be used as a recycler
    {
        Enable = true,
        Label = "Recycler",
        prop = `sayer_weaponbench`,
        Locations = {
            {ID = "recycler_1", Coords = vector4(2354.08, 3056.89, 48.15, 280.36)},
            {ID = "recycler_2", Coords = vector4(-1827.48, 2965.15, 32.81, 149.25)}, --military base
            {ID = "recycler_3", Coords = vector4(970.23, -216.57, 82.73, 62.23)},
            {ID = "recycler_4", Coords = vector4(-578.54, 5348.94, 70.22, 68.87)},
        },
    },
}

Config.RecycleRate = 1 --how many items to recyce at once (i think 1 is best)
Config.RecycleTime = 5 --how many seconds per item (dont put it too low or it could cause performance issues)


Config.Recycle = {

 -- Base Building
    ['model_door_wood'] = { --the item to recycle.  --JUST A EXAMPLE
        [1] = {item = 'plastic',Min = 1,Max = 4}, --the items you will get back and random amount
        [2] = {item = 'metalscrap',Min = 1,Max = 2},
        [3] = {item = 'copper',Min = 1,Max = 2},
        [4] = {item = 'aluminum',Min = 1,Max = 2},
        [5] = {item = 'ironoxide',Min = 1,Max = 2},
        [6] = {item = 'rubber',Min = 1,Max = 2},
    },
    ['beer'] = {
        [1] = {item = 'tosti',Min = 1,Max = 4},
        [2] = {item = 'twerks_candy',Min = 1,Max = 4},
        [3] = {item = 'sandwich',Min = 1,Max = 4},
    }

}