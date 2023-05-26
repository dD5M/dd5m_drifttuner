# dds-drifttuner

# Showcase
[https://www.youtube.com/6b91vCKkX6Y](https://www.youtube.com/watch?v=6b91vCKkX6Y)

# Discord for more releases and support [dDStudio] https://discord.gg/P9ZzdzYaqm

# Instructions
Create the table in your datablase player_vehicles table as seen below with default value '0'.  Deploy 
the inventory item to your data/items.lua table in ox_inventory to apply a drift tuner to a vehicle.

# Config
Configure your notifications, and selected vehicles to receive drift tune.

# Test Drift
Admins can use the command /testdrift to apply drift tune to any vehicle with or without drift tuner value in DB.

# SQL
ALTER table player_vehicles
	ADD COLUMN `drifttuner` INT DEFAULT '0';

# ox_inventory
		["drifttuner"] = {
			label = "Drift Tuner",
			weight = 0,
			stack = true,
			close = true,
			description = "Install a drift tuner on a compatible vehicle.",
			client = {
				export = "dds-drifttuner.drifttuner",
				image = "tunerchip.png",
			}
		},

Ox_lib/QBox FiveM drift tuner with db sync.  Tuner status stored to vehicles table.
