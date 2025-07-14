Territories = {}

Territories.grove_street = {
    label = 'Grove Street',
    control = 'neutral',
    influence = 0,
    drugs = {'weed_skunk'},
    blip = {
        coords = vec3(101.0, -1937.0, 20.0),
        sprite = 437,
        scale = 1.2
    },
    zone = {
        type = 'poly',
        points = {
            vec3(86.0, -1956.0, 21.0),
            vec3(114.0, -1961.0, 21.0),
            vec3(149.0, -1908.0, 21.0),
            vec3(118.0, -1881.0, 21.0),
            vec3(77.0, -1898.0, 21.0),
            vec3(56.0, -1922.0, 21.0)
        },
        thickness = 30.0
    },
    capture = {
        point = vec3(101.0, -1937.0, 20.8),
        radius = 15.0
    },
    features = {
        stash = {
            coords = vec3(101.0, -1937.0, 20.8),
            heading = 320.0
        },
        garage = {
            coords = vec3(94.0, -1942.0, 20.8),
            spawn = vec4(87.0, -1945.0, 20.8, 220.0),
            heading = 220.0
        },
        process = {
            coords = vec3(105.0, -1940.0, 20.8),
            heading = 50.0,
            type = 'weed',
            scene = {
                type = 'Weed',
                num = 2,
                offset = vec3(0.0, 0.896, 0.0),
                rotation = vec3(0.0, 0.0, 90.0)
            }
        }
    },
    businesses = {
        {
            type = 'store',
            coords = vec4(85.0, -1955.0, 21.0, 320.0),
            income = 500
        },
        {
            type = 'gas',
            coords = vec4(119.0, -1920.0, 21.0, 180.0),
            income = 750
        }
    }
}

Territories.forum_drive = {
    label = 'Forum Drive',
    control = 'neutral',
    influence = 0,
    drugs = {'coke_brick'},
    blip = {
        coords = vec3(-175.0, -1632.0, 33.0),
        sprite = 437,
        scale = 1.2
    },
    zone = {
        type = 'box',
        coords = vec3(-175.0, -1632.0, 33.0),
        size = vec3(200.0, 150.0, 50.0),
        rotation = 45.0
    },
    capture = {
        point = vec3(-175.0, -1632.0, 33.0),
        radius = 20.0
    },
    features = {
        stash = {
            coords = vec3(-167.0, -1634.0, 33.7),
            heading = 100.0
        },
        process = {
            coords = vec3(-163.0, -1638.0, 33.7),
            heading = 180.0,
            type = 'cocaine',
            scene = {
                type = 'Cocaine',
                num = 2,
                offset = vec3(7.663, -2.222, 0.395),
                rotation = vec3(0.0, 0.0, 0.0)
            }
        }
    },
    businesses = {
        {
            type = 'store',
            coords = vec4(-190.0, -1645.0, 33.0, 90.0),
            income = 600
        }
    }
}

Territories.rancho = {
    label = 'Rancho',
    control = 'neutral',
    influence = 0,
    drugs = {'meth'},
    blip = {
        coords = vec3(328.0, -2034.0, 20.0),
        sprite = 437,
        scale = 1.2
    },
    zone = {
        type = 'poly',
        points = {
            vec3(315.0, -2040.0, 20.0),
            vec3(370.0, -2058.0, 20.0),
            vec3(405.0, -2020.0, 20.0),
            vec3(380.0, -1995.0, 20.0),
            vec3(290.0, -2010.0, 20.0)
        },
        thickness = 40.0
    },
    capture = {
        point = vec3(328.0, -2034.0, 20.0),
        radius = 25.0
    },
    features = {
        stash = {
            coords = vec3(331.0, -2012.0, 22.3),
            heading = 180.0
        },
        garage = {
            coords = vec3(320.0, -2030.0, 20.8),
            spawn = vec4(310.0, -2025.0, 20.8, 320.0),
            heading = 320.0
        },
        process = {
            coords = vec3(335.0, -2016.0, 22.3),
            heading = 0.0,
            type = 'meth',
            scene = {
                type = 'Meth',
                num = 1,
                offset = vec3(-4.88, -1.95, 0.0),
                rotation = vec3(0.0, 0.0, 0.0)
            }
        }
    },
    businesses = {
        {
            type = 'mechanic',
            coords = vec4(340.0, -2040.0, 21.0, 180.0),
            income = 800
        }
    }
}

Territories.davis = {
    label = 'Davis',
    control = 'neutral',
    influence = 0,
    drugs = {'crack'},
    blip = {
        coords = vec3(85.0, -1670.0, 29.0),
        sprite = 437,
        scale = 1.2
    },
    zone = {
        type = 'poly',
        points = {
            vec3(50.0, -1700.0, 29.0),
            vec3(120.0, -1710.0, 29.0),
            vec3(130.0, -1640.0, 29.0),
            vec3(80.0, -1630.0, 29.0),
            vec3(40.0, -1650.0, 29.0)
        },
        thickness = 35.0
    },
    capture = {
        point = vec3(85.0, -1670.0, 29.0),
        radius = 20.0
    },
    features = {
        stash = {
            coords = vec3(88.0, -1668.0, 29.2),
            heading = 230.0
        },
        process = {
            coords = vec3(91.0, -1672.0, 29.2),
            heading = 140.0,
            type = 'crack',
            scene = {
                type = 'Meth',
                num = 1,
                offset = vec3(0.0, 0.0, 0.0),
                rotation = vec3(0.0, 0.0, 45.0)
            }
        }
    },
    businesses = {
        {
            type = 'liquor',
            coords = vec4(75.0, -1680.0, 29.0, 180.0),
            income = 400
        }
    }
}
