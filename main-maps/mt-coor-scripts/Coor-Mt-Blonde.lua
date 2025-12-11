-- Coor-Mt-Blonde.lua
return {
    Name = "Mount Blonde",
    VipOnly = false, -- Set true jika khusus VIP
    
    -- Koordinat Point
    CheckPoints = {
        Spawn = {x = -24, y = 10, z = -104},
        ["Pos - 1"] = {x = 623, y = 89, z = -356},
        ["Pos - 2"] = {x = 932, y = 141, z = -249},
        ["Pos - 3"] = {x = 1512, y = 189, z = -249.72},
        ["Pos - 4"] = {x = 2638, y = 341, z = -234},
        ["Pos - 5"] = {x = 2911, y = 341, z = -234},
        ["Pos - 6"] = {x = 3235, y = 341, z = -215},
        ["Pos - 7"] = {x = 3387, y = 538, z = -238},
        ["Pos - 8"] = {x = 3432, y = 717, z = -222},
        Puncak = {x = 3599, y = 780, z = -241}
    },
    
    -- Urutan Teleportasi Otomatis
    Sequence = {
        "Spawn", 
        "Pos - 1", 
        "Pos - 2", 
        "Pos - 3", 
        "Pos - 4", 
        "Pos - 5", 
        "Pos - 6", 
        "Pos - 7", 
        "Pos - 8", 
        "Puncak"
    }
}