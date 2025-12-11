return {
    Name = "Mount Sakahayang",
    VipOnly = false, 
    
    CheckPoints = {
        Spawn = {x = 778, y = 59, z = 650},
        ["Pos - 1"] = {x = 355, y = 74, z = 208},
        ["Pos - 2"] = {x = 430, y = 120, z = 272},
        ["Pos - 3"] = {x = 729, y = 162, z = 267},
        ["Pos - 4"] = {x = 564, y = 431, z = 372},
        ["Pos - 5"] = {x = 246, y = 418, z = 388},
        ["Pos - 6"] = {x = 32, y = 431, z = 589},
        ["Pos - 7"] = {x = 201, y = 497, z = 225},
        ["Pos - 8"] = {x = 159, y = 563, z = 137},
        ["Pos - 9"] = {x = 153, y = 814, z = 270},
        ["Pos - 10"] = {x = -238, y = 973, z = 651},
        ["Pos - 11"] = {x = -374, y = 1160, z = 874},
        ["Pos - 12"] = {x = -510, y = 1157, z = 874},
        ["Pos - 13"] = {x = -725, y = 1220, z = 775},
        ["Pos - 14"] = {x = -999, y = 1400, z = 1013},
        ["Pos - 15"] = {x = -1143, y = 1596, z = 679},
        Puncak = {x = -912, y = 3142, z = 561, ResetChar = true}
    },
    
    Sequence = {
        "Spawn", 
        "Pos - 1", "Pos - 2", "Pos - 3", "Pos - 4", "Pos - 5", 
        "Pos - 6", "Pos - 7", "Pos - 8", "Pos - 9", "Pos - 10", 
        "Pos - 11", "Pos - 12", "Pos - 13", "Pos - 14", "Pos - 15", 
        "Puncak"
    }
}
