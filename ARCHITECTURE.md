# Advanced Territories - Architecture Documentation

## Overview
Advanced Territory Control System is a comprehensive gang territory management resource for FiveM with automatic capture mechanics, police interactions, drug operations, and dynamic zone control.

## Directory Structure

```
advance-territories/
├── client/
│   └── init.lua          # Client initialization
├── server/
│   └── init.lua          # Server initialization
├── data/
│   ├── config.lua        # Main configuration
│   └── territories.lua   # Territory definitions
├── locales/
│   └── en.json          # Localization strings
└── modules/             # Feature modules
```

## Modules Description

### Core Modules

#### **zones** (client/server)
- Manages ox_lib zones and sphere zones
- Handles player entry/exit events
- Synchronizes zone states between clients

#### **territories** (client/server)
- Core territory management
- Territory ownership and gang assignments
- Territory state synchronization

#### **capture** (client/server)
- Automatic capture system with progress ticks
- Death penalty handling
- Capture notifications and state management

### Feature Modules

#### **economy** (client/server)
- Territory income generation
- Safe money management
- Economic rewards system

#### **drugs** (client/server)  
- Drug lab operations
- Production and storage
- Item manufacturing

#### **garage** (client/server)
- Gang vehicle spawning
- Vehicle management per territory
- Secure parking system

#### **stash** (client/server)
- Territory storage system
- Inventory management
- Secure item storage

#### **process** (client/server)
- Drug processing labs
- Item conversion mechanics
- Production management

### Special Systems

#### **spy** (client/server)
- NPC infiltration system
- Spy detection and rewards
- Alert notifications

#### **delivery** (client/server)
- Vehicle-based drug transport
- Police raid risk system
- Delivery rewards

#### **police** (client/server)
- Police neutralization mechanics
- Territory raids
- Law enforcement interactions

#### **arrest** (client/server)
- Arrest detection via statebags
- Capture interruption on arrest
- Player state monitoring

#### **buckets** (server)
- Instance management for interior labs
- Separate dimensions per gang
- Collision prevention

### Admin & UI

#### **admin** (client/server)
- Admin commands and controls
- Territory management tools
- System monitoring

#### **creator** (client/server)
- Interactive territory creation
- Point-based zone building
- Dynamic territory setup

#### **ui** (client)
- Territory information display
- HUD elements
- Visual feedback systems

#### **scenes** (client)
- 3D text displays
- Territory markers
- Visual indicators

#### **ipl** (client)
- Interior loading
- Map modifications
- Location management

### Utilities

#### **utils** (shared)
- Common functions
- Helper utilities
- Shared logic

## Key Features

1. **Automatic Capture System**
   - No manual commands needed
   - Progress-based capture with ticks
   - Death penalties and interruptions

2. **Police Integration**
   - Territories become neutral when raided
   - Arrest detection stops captures
   - Law enforcement balance

3. **Economic System**
   - Passive income from owned territories
   - Drug sales and processing
   - Risk/reward balance

4. **Instanced Interiors**
   - Separate lab instances per gang
   - No collision between gangs
   - Smooth transitions

5. **Dynamic Creation**
   - Admin tool for creating territories
   - Visual point placement
   - Real-time preview

## Dependencies

- ox_lib (zones, callbacks, UI)
- ox_inventory (storage, items)
- oxmysql (database)
- qb-core (framework)
- ox_target (interactions)

## Database Tables

- `territories` - Territory definitions and ownership
- `territory_income` - Economic tracking
- `territory_storage` - Stash contents
- `territory_vehicles` - Garage management

## Event Flow

1. Player enters territory → Zone detection
2. Automatic capture starts → Progress tracking
3. Police/Death interrupts → State management
4. Territory captured → Ownership update
5. Benefits activated → Income/Access granted
