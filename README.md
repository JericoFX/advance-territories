Yes a lot of IA was involved because i dont want to code for fivem anymore so i just check what an IA can do

# Advanced Territories

A modular territory control system for FiveM using QBCore, ox_lib, and ox_inventory.

## Features

### Synchronization System
- **GlobalState Integration**: Real-time territory state synchronization using FiveM's GlobalState
- **ox_lib Callbacks**: Replaced network events with efficient callback system
- **StateBag Support**: Player and vehicle state tracking through entity statebags
- **Optimized Network Traffic**: Reduced network overhead with smart state updates

- **Dynamic Territory Creation**: Create territories in-game as polygon or box zones
- **Automatic Capture System**: Territories captured automatically based on gang presence
- **Zone Management**: Polygon and box zones with automatic player tracking
- **Drug Processing**: Different drug types with synchronized scenes and animations
- **NPC Drug Sales**: Sell drugs to NPCs using ox_target interaction system
- **Bucket System**: Gang members process drugs in separate instances (no collisions)
- **Economy System**: Territory income from businesses with tax collection
- **Stash System**: Gang-specific stashes with transfer on capture
- **Garage System**: Territory-based vehicle storage
- **Police Integration**: Police presence affects territory control and drug pricing
- **IPL Loading**: Automatic loading of drug lab interiors with bucket separation

## Dependencies

- ox_lib (v3.0.0+) - Required for callbacks, zones, and UI
- ox_inventory
- ox_target
- qb-core
- oxmysql

## Installation

1. Place the resource in your server's resources folder
2. Add `ensure advance-territories` to your server.cfg
3. Configure territories in `data/territories.lua`
4. Adjust settings in `data/config.lua`

## Usage

### Admin Commands
- `/createterritory` - Create a new territory zone (admin only)
- `/territories` - Open territory management menu (admin only)

### Automatic Features
- **Automatic Capture**: Enter capture zones with enough gang members to start capturing
- **Dynamic Territories**: Create territories on the fly without server restart
- **Bucket Separation**: Gang members process in separate instances

### Territory Features
- **Stash**: Access gang-specific storage
- **Garage**: Store and retrieve vehicles
- **Processing**: Process drugs with animated scenes
- **Drug Sales**: Interact with NPCs using ox_target or use `/selldrugs` command

### Drug Sales System
- **NPC Interaction**: Use ox_target to sell drugs to any NPC
- **Territory Control**: Better prices when selling in controlled territories
- **Police Heat**: Drug prices affected by police presence

## Documentation

- [Territory state request flow](docs/request-flow.md)
- **Automatic Mode**: `/selldrugs` command for continuous selling
- **Police Reports**: NPCs may report drug sales to police
- **Commands**:
  - `/selldrugs` - Start selling drugs to nearby NPCs
  - `/stopselling` - Stop the automatic selling mode

### Configuration

The resource is highly configurable through `data/config.lua`:
- Adjust capture times and requirements
- Configure police jobs and minimum counts
- Set economy values and tax rates
- Enable/disable features

## Module Structure

- `zones/` - Zone creation and player tracking
- `territories/` - Main territory logic
- `capture/` - Territory capture system
- `process/` - Drug processing with scenes
- `stash/` - Storage system
- `garage/` - Vehicle storage
- `economy/` - Income and tax system
- `ipl/` - Interior loading
- `scenes/` - Synchronized animations
- `admin/` - Administration commands

## Adding New Territories

Add territories in `data/territories.lua`:

```lua
Territories.example = {
    label = 'Example Territory',
    control = 'neutral',
    influence = 0,
    drugs = {'weed_skunk'},
    zone = {
        type = 'poly',
        points = {
            vec3(0.0, 0.0, 0.0),
            -- Add zone points
        },
        thickness = 30.0
    },
    capture = {
        point = vec3(0.0, 0.0, 0.0),
        radius = 15.0
    },
    features = {
        stash = {
            coords = vec3(0.0, 0.0, 0.0),
            heading = 0.0
        },
        -- Add other features
    }
}
```
