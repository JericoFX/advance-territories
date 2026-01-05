Config = {}

Config.Debug = true

Config.Interact = {
    distance = 2.0,
    drawDistance = 10.0
}

Config.Territory = {
    influenceTick = 10000,
    saveInterval = 5,
    control = {
        pointsPerKill = 5,
        pointsPerTick = 1,
        pointsPerPolice = 2,
        maxInfluence = 100,
        minInfluence = 0,
        captureTime = 15,
        minMembers = 2,
        maxMembers = 8
    }
}

Config.Police = {
    jobs = {
        'police',
        'sheriff',
        'bcso',
        'sasp',
        'fbi'
    },
    minOnDuty = 0,
    alertRadius = 150.0,
    alertChance = 25
}

Config.Gangs = {
    canCapture = true,
    canSellDrugs = true,
    territoryBonus = {
        drugPrice = 1.2,
        processSpeed = 0.8
    }
}

Config.Blips = {
    enabled = true,
    sprite = 437,
    scale = 1.2,
    colors = {
        neutral = 0,
        police = 3,
        ballas = 27,
        vagos = 46,
        families = 2,
        lostmc = 62,
        marabunta = 3
    }
}

Config.DrugSales = {
    enabled = true,
    distance = 10.0,
    chance = {
        buy = 50,
        report = 10,
        reject = 40
    },
    time = {
        min = 5000,
        max = 8000
    },
    amount = {
        min = 1,
        max = 10
    },
    prices = {
        ['weed_skunk'] = { min = 50, max = 100 },
        ['coke_brick'] = { min = 150, max = 300 },
        ['meth'] = { min = 100, max = 200 },
        ['crack'] = { min = 80, max = 150 }
    }
}

Config.Economy = {
    enabled = true,
    tax = {
        business = 0.10,
        drugSale = 0.15,
        processing = 0.05
    },
    collection = {
        cooldown = 3600,
        distribution = true
    },
    gradeShares = {
        [0] = 0.10,
        [1] = 0.15,
        [2] = 0.20,
        [3] = 0.25,
        [4] = 0.30
    }
}

Config.Garage = {
    enabled = true,
    requireControl = true,
    transferOnCapture = true,
    maxVehicles = 10,
    allowedTypes = {
        'automobile',
        'bike'
    }
}

Config.Stash = {
    enabled = true,
    requireControl = true,
    transferOnCapture = true,
    size = {
        weight = 500000,
        slots = 50
    }
}

Config.Processing = {
    enabled = true,
    requireControl = true,
    animations = true,
    scenes = true
}

Config.Rewards = {
    capture = {
        money = 5000,
        experience = 100
    },
    defend = {
        money = 2500,
        experience = 50
    },
    drugSale = {
        experience = 5
    }
}
