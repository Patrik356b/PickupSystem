/*======================================================================================================//
	Custom Pickups Praser

	Credits:
		Patrik356b
			https://github.com/Patrik356b
	
	Some code borrowed from:
		Southclaw
			https://github.com/Southclaw
//======================================================================================================*/
#define FILTERSCRIPT

#include <a_samp>

  //======================================================================================================//
 // Predefinitions and External Dependencies                                                             //
//======================================================================================================//

#undef MAX_PLAYERS
#define MAX_PLAYERS 	(32)

#define MAX_STREAMED_PICKUPS	(128)

#define DIRECTORY_SCRIPTFILES		"./scriptfiles/"
#define DIRECTORY_PICKUPS			"Pickups/"

  //======================================================================================================//
 // Resources                                                                                            //
//======================================================================================================//

#tryinclude <FileManager>		// By JaTochNietDan:		http://forum.sa-mp.com/showthread.php?t=92246
#tryinclude <streamer>			// By Incognito:			http://forum.sa-mp.com/showthread.php?t=102865
#tryinclude <sscanf2>			// By Y_Less:				http://forum.sa-mp.com/showthread.php?t=120356

  //======================================================================================================//
 // Data Structures                                                                                      //
//======================================================================================================//

new DEBUG_PICKUP_LEVEL = 4; // set the debug level

enum
{
	DEBUG_PICKUP_NONE = -1,		// (-1) No prints
	DEBUG_PICKUP_INFO,			// (0) Print information messages
	DEBUG_PICKUP_FOLDERS,		// (1) Print each directory
	DEBUG_PICKUP_FILES,			// (2) Print each file loaded
	DEBUG_PICKUP_LINES,			// (3) Print each line loaded
	DEBUG_PICKUP_BUFFER			// (4) Print line buffering
}

  //======================================================================================================//
 // Required bits                                                                                        //
//======================================================================================================//

#if !defined file_move
	#error Missing plugin: FileManager By JaTochNietDan: forum.sa-mp.com/showthread.php?t=92246
#endif

#if !defined Streamer_IncludeFileVersion
	#error Missing plugin: Streamer By Incognito: forum.sa-mp.com/showthread.php?t=102865
#endif

#if !defined unformat
	#error Missing plugin: sscanf2 By Y_Less: forum.sa-mp.com/showthread.php?t=120356
#endif

  //======================================================================================================//
 // Core                                                                                                 //
//======================================================================================================//

// Usage for all macros: BitFlag_X(variable, flag) - http://forum.sa-mp.com/showthread.php?t=216730
#define BitFlag_Get(%0,%1)            ((%0) & (%1))   // Returns zero (false) if the flag isn't set.
#define BitFlag_On(%0,%1)             ((%0) |= (%1))  // Turn on a flag.
#define BitFlag_Off(%0,%1)            ((%0) &= ~(%1)) // Turn off a flag.
#define BitFlag_Toggle(%0,%1)         ((%0) ^= (%1))  // Toggle a flag (swap true/false).

enum PickupFlags:(<<= 1) {
	Enable_Nitro = 1,
	Enable_Repair,

	Enable_SpeedBoost_X,
	Enable_SpeedBoost_Y,
	Enable_SpeedBoost_Z,

	Enable_Rotation,

	Enable_Teleport_X,
	Enable_Teleport_Y,
	Enable_Teleport_Z,
	Enable_Teleport_I,
	Enable_Teleport_W
};

new PickupFlags:PickupData[MAX_STREAMED_PICKUPS];

new DEBUG_PICKUP_INTERNAL=true;

new TotalPickups = -1;

enum PickupEnum
{
	StreamPickupID,			// Dynamic pickup id
	StreamType = 14,		// SA-MP Pickup Type

	StreamNitro,					// Is this a nitrous pickup?
	Float:StreamRepair,				// Is this a repair pickup?
	
	Float:SpeedBoost_X = 0.0,		// Speedboost Velocity X
	Float:SpeedBoost_Y = 0.0,		// Speedboost Velocity Y
	Float:SpeedBoost_Z = 0.0,		// Speedboost Velocity Z

	Float:Teleport_X = 0.0,			// Teleport Position X
	Float:Teleport_Y = 0.0,			// Teleport Position Y
	Float:Teleport_Z = 0.0,			// Teleport Position Z
	Teleport_I,						// Teleport Interior
	Teleport_W,						// Teleport Virtual World

	RotationType,				// Static or incremental rotation?
	Float:Rotation = 17			// Change vehicle  rotation
};

new PickupInfo[MAX_STREAMED_PICKUPS][PickupEnum];
new Text3D:PickupLabels[MAX_STREAMED_PICKUPS];

public OnFilterScriptInit()
{
	for(new idt=0; idt < MAX_3DTEXT_GLOBAL; idt++){
		Delete3DTextLabel(Text3D:idt);
	}


	if(!dir_exists(DIRECTORY_SCRIPTFILES))
	{
		print("ERROR: Directory '"DIRECTORY_SCRIPTFILES"' not found. Creating directory.");
		dir_create(DIRECTORY_SCRIPTFILES);
	}

	if(!dir_exists(DIRECTORY_SCRIPTFILES DIRECTORY_PICKUPS))
	{
		print("ERROR: Directory '"DIRECTORY_SCRIPTFILES DIRECTORY_PICKUPS"' not found. Creating directory.");
		dir_create(DIRECTORY_SCRIPTFILES DIRECTORY_PICKUPS);
	}

	DEBUG_PICKUP_INTERNAL = (DEBUG_PICKUP_LEVEL >= DEBUG_PICKUP_INFO) ? printf(">> Pickups Are Loading...\n\tDebug Level:") : DEBUG_PICKUP_INTERNAL ;

	/*
	// This will print 0 if debug is enabled and 1 if it's not
	printf("DEBUG_PICKUP_INTERNAL=%i (Do not print debug?)", DEBUG_PICKUP_INTERNAL);
	*/

	switch(DEBUG_PICKUP_LEVEL)
	{
		case DEBUG_PICKUP_INFO:		printf("Print information messages");
		case DEBUG_PICKUP_FOLDERS:	printf("Print each directory");
		case DEBUG_PICKUP_FILES:	printf("Print each file loaded");
		case DEBUG_PICKUP_LINES:	printf("Print each line loaded");
		case DEBUG_PICKUP_BUFFER:	printf("Print line buffering");
	}

	LoadPickupsFromFolder(DIRECTORY_PICKUPS);

	DEBUG_PICKUP_INTERNAL = (DEBUG_PICKUP_LEVEL >= DEBUG_PICKUP_INFO) ? printf(">> Loaded %i pickups", TotalPickups) : DEBUG_PICKUP_INTERNAL ;
	
	printf("\tPickups Are Loaded!");

	return 1;
}

/*
	DEBUG_PICKUP_INTERNAL = (DEBUG_PICKUP_LEVEL >= DEBUG_PICKUP_INFO) ? printf(">> Pickups Are Loading...") : DEBUG_PICKUP_INTERNAL ;
	DEBUG_PICKUP_INTERNAL = (DEBUG_PICKUP_LEVEL >= DEBUG_PICKUP_FOLDERS) ? printf(">> Pickups Are Loading...") : DEBUG_PICKUP_FOLDERS ;
	DEBUG_PICKUP_INTERNAL = (DEBUG_PICKUP_LEVEL >= DEBUG_PICKUP_FILES) ? printf(">> Pickups Are Loading...") : DEBUG_PICKUP_FILES ;
	DEBUG_PICKUP_INTERNAL = (DEBUG_PICKUP_LEVEL >= DEBUG_PICKUP_LINES) ? printf(">> Pickups Are Loading...") : DEBUG_PICKUP_LINES ;
	DEBUG_PICKUP_INTERNAL = (DEBUG_PICKUP_LEVEL >= DEBUG_PICKUP_BUFFER) ? printf(">> Pickups Are Loading...") : DEBUG_PICKUP_BUFFER ;
*/

LoadPickupsFromFolder(folder[])
{
	new
		foldername[256],
		dir:dirhandle,
		item[64],
		type,
		filename[256]

		;

	format(foldername, sizeof(foldername), DIRECTORY_SCRIPTFILES"%s", folder);
	dirhandle = dir_open(foldername);

	if(DEBUG_PICKUP_LEVEL >= DEBUG_PICKUP_INFO)
	{
		new
			totalfiles,
			totalpickup,
			totalfolders;

		while(dir_list(dirhandle, item, type))
		{
			if(type == FM_FILE)
			{
				totalfiles++;

				if(!strcmp(item[strlen(item) - 4], ".txt"))
					totalpickup++;
			}

			if(type == FM_DIR && strcmp(item, "..") && strcmp(item, ".") && strcmp(item, "_"))
				totalfolders++;
		}

		// Reopen the directory so the next code can run properly.
		dir_close(dirhandle);
		dirhandle = dir_open(foldername);

		printf("DEBUG: [LoadPickupsFromFolder] Reading directory '%s': %d files, %d .txt files, %d folders", foldername, totalfiles, totalpickup, totalfolders);
	}

	while(dir_list(dirhandle, item, type))
	{
		if(type == FM_FILE)
		{
			if(!strcmp(item[strlen(item) - 4], ".txt"))
			{
				filename[0] = EOS;
				format(filename, sizeof(filename), "%s%s", folder, item);
				LoadPickups(filename);
			}
		}

		if(type == FM_DIR && strcmp(item, "..") && strcmp(item, ".") && strcmp(item, "_"))
		{
			filename[0] = EOS;
			format(filename, sizeof(filename), "%s%s/", folder, item);
			LoadPickupsFromFolder(filename);
		}
	}

	dir_close(dirhandle);

	if(DEBUG_PICKUP_LEVEL >= DEBUG_PICKUP_FOLDERS)
		print("DEBUG: [LoadPickupsFromFolder] Finished reading directory.");
}

LoadPickups(filename[])
{
	new
		File:file,
		line[256],

		linenumber = 1,
		operations,
		
		funcname[32],
		funcargs[128],
		
		globalworld = -1,
		globalinterior = -1,
		Float:globalrange = 350.0,

		Float:posx,
		Float:posy,
		Float:posz,
		
		tmpPickup
		;

	if(!fexist(filename))
	{
		printf("ERROR: file: \"%s\" NOT FOUND", filename);
		return 0;
	}

	file = fopen(filename, io_read);

	if(!file)
	{
		printf("ERROR: file: \"%s\" NOT LOADED", filename);
		return 0;
	}

	if(DEBUG_PICKUP_LEVEL >= DEBUG_PICKUP_FILES)
	{
		new totallines;

		while(fread(file, line))
			totallines++;

		// Reopen the file so the actual read code runs properly.
		fclose(file);
		file = fopen(filename, io_read);

		printf("\nDEBUG: [LoadPickups] Reading file '%s': %d lines.", filename, totallines);
	}

	while(fread(file, line))
	{
		if(DEBUG_PICKUP_LEVEL >= DEBUG_PICKUP_BUFFER)
			print(line);

		if(line[0] < 65)
		{
			linenumber++;
			continue;
		}

		if(sscanf(line, "p<(>s[32]p<)>s[128]{s[96]}", funcname, funcargs))
		{
			linenumber++;
			continue;
		}

		if(strfind(funcname, "options", true) != -1)
		{
			new Int_Arg, Float:Floating_Arg;

			if(strfind(funcargs, "type", true) != -1)
			{
				if(!sscanf(funcargs, "p<,>{s[32]}i", Int_Arg))
				{
					PickupInfo[TotalPickups][StreamType]=Int_Arg;
					Streamer_SetIntData(STREAMER_TYPE_PICKUP, TotalPickups, E_STREAMER_TYPE, Int_Arg);

					if(DEBUG_PICKUP_LEVEL >= DEBUG_PICKUP_LINES)
						printf(" DEBUG: [LoadPickups] Updated options to: \"%s\" = Type %i []=%i", funcargs, Int_Arg, PickupInfo[TotalPickups][StreamType]);
				}

				new debuglabel[128];
				format(debuglabel, sizeof(debuglabel), "[DEBUG]: PickupID: %i Int:%i World: %i Type:%i\nX:%f Y:%f Z:%f", TotalPickups, Streamer_GetIntData(STREAMER_TYPE_PICKUP, PickupInfo[TotalPickups][StreamPickupID], E_STREAMER_INTERIOR_ID), Streamer_GetIntData(STREAMER_TYPE_PICKUP, PickupInfo[TotalPickups][StreamPickupID], E_STREAMER_WORLD_ID), PickupInfo[TotalPickups][StreamType], posx, posy, posz);
				Update3DTextLabelText(PickupLabels[TotalPickups], 0x00FF00FF, debuglabel);
			}
			
			if(strfind(funcargs, "nitro", true) != -1)
			{
				if(!sscanf(funcargs, "p<,>{s[32]}d", Int_Arg))
				{
					PickupInfo[TotalPickups][StreamNitro]=Int_Arg;
					BitFlag_On(PickupData[TotalPickups], Enable_Nitro);

					if(DEBUG_PICKUP_LEVEL >= DEBUG_PICKUP_LINES)
						printf(" DEBUG: [LoadPickups] Updated options to: \"%s\" = Nitros %ix", funcargs, Int_Arg);
				}
			}
			else if(strfind(funcargs, "repair", true) != -1)
			{
				if(!sscanf(funcargs, "p<,>{s[32]}f", Floating_Arg))
				{
					// Is repair level in percent?
					if(Floating_Arg <= 201)
					{
						new Float:tmph = Floating_Arg;
						Floating_Arg = floatmul(Floating_Arg, 75.0);
						Floating_Arg = floatdiv(Floating_Arg, 10.0);
						Floating_Arg = floatadd(Floating_Arg, 249.0 + floatdiv(tmph, 100));

					    if(DEBUG_PICKUP_LEVEL >= DEBUG_PICKUP_LINES)
							printf(" DEBUG: [LoadPickups] Updated options to: \"%s\" = Repair level: %f%%", funcargs, Floating_Arg);
					}
					else
					{
						if(DEBUG_PICKUP_LEVEL >= DEBUG_PICKUP_LINES)
							printf(" DEBUG: [LoadPickups] Updated options to: \"%s\" = Repair level: %f", funcargs, Floating_Arg);
					}

					PickupInfo[TotalPickups][StreamRepair]=Floating_Arg;
					BitFlag_On(PickupData[TotalPickups], Enable_Repair);
				}
			}
			else if(strfind(funcargs, "velocity", true) != -1)
			{
				if(!sscanf(funcargs, "p<,>{s[32]}cf", Int_Arg, Floating_Arg))
				{
					switch(Int_Arg)
					{
						case 'x', 'X':
						{
							if(DEBUG_PICKUP_LEVEL >= DEBUG_PICKUP_LINES)
								printf(" DEBUG: [LoadPickups] Updated options to: \"%s\" = SpeedBoost_X: %f", funcargs, Floating_Arg);
							
							PickupInfo[TotalPickups][SpeedBoost_X]=Floating_Arg;
							BitFlag_On(PickupData[TotalPickups], Enable_SpeedBoost_X);
						}
						case 'y', 'Y':
						{
							if(DEBUG_PICKUP_LEVEL >= DEBUG_PICKUP_LINES)
								printf(" DEBUG: [LoadPickups] Updated options to: \"%s\" = SpeedBoost_Y: %f", funcargs, Floating_Arg);
							
							PickupInfo[TotalPickups][SpeedBoost_Y]=Floating_Arg;
							BitFlag_On(PickupData[TotalPickups], Enable_SpeedBoost_Y);
						}
						case 'z', 'Z':
						{
							if(DEBUG_PICKUP_LEVEL >= DEBUG_PICKUP_LINES)
								printf(" DEBUG: [LoadPickups] Updated options to: \"%s\" = SpeedBoost_Z: %f", funcargs, Floating_Arg);
							
							PickupInfo[TotalPickups][SpeedBoost_Z]=Floating_Arg;
							BitFlag_On(PickupData[TotalPickups], Enable_SpeedBoost_Z);
						}
					}
				}
			}
			else if(strfind(funcargs, "teleport", true) != -1)
			{
				if(!sscanf(funcargs, "p<,>{s[32]}cf", Int_Arg, Floating_Arg))
				{
					switch(Int_Arg)
					{
						case 'x', 'X':
						{
							PickupInfo[TotalPickups][Teleport_X]=Floating_Arg;
							BitFlag_On(PickupData[TotalPickups], Enable_Teleport_X);

							if(DEBUG_PICKUP_LEVEL >= DEBUG_PICKUP_LINES)
								printf(" DEBUG: [LoadPickups] Updated options to: \"%s\" = Teleport_X: %f []=%f", funcargs, Floating_Arg, PickupInfo[TotalPickups][Teleport_X]);

							new debuglabel[128];
							format(debuglabel, sizeof(debuglabel), "[DEBUG]: PickupID: %i Int:%i World: %i Type:%i\nX:%f Y:%f Z:%f\n\tTELEPORT!", TotalPickups+1, Streamer_GetIntData(STREAMER_TYPE_PICKUP, PickupInfo[TotalPickups][StreamPickupID], E_STREAMER_INTERIOR_ID), Streamer_GetIntData(STREAMER_TYPE_PICKUP, PickupInfo[TotalPickups][StreamPickupID], E_STREAMER_WORLD_ID), PickupInfo[TotalPickups][StreamType], posx, posy, posz);
							Update3DTextLabelText(PickupLabels[TotalPickups+1], 0xFF5500FF, debuglabel);
						}
						case 'y', 'Y':
						{
							if(DEBUG_PICKUP_LEVEL >= DEBUG_PICKUP_LINES)
								printf(" DEBUG: [LoadPickups] Updated options to: \"%s\" = Teleport_Y: %f", funcargs, Floating_Arg);
							
							PickupInfo[TotalPickups][Teleport_Y]=Floating_Arg;
							BitFlag_On(PickupData[TotalPickups], Enable_Teleport_Y);
						}
						case 'z', 'Z':
						{
							if(DEBUG_PICKUP_LEVEL >= DEBUG_PICKUP_LINES)
								printf(" DEBUG: [LoadPickups] Updated options to: \"%s\" = Teleport_Z: %f", funcargs, Floating_Arg);
							
							PickupInfo[TotalPickups][Teleport_Z]=Floating_Arg;
							BitFlag_On(PickupData[TotalPickups], Enable_Teleport_Z);
						}
						case 'i', 'I':
						{
							if(!sscanf(funcargs, "p<,>{s[32]c}i", Int_Arg))
							{
								if(DEBUG_PICKUP_LEVEL >= DEBUG_PICKUP_LINES)
									printf(" DEBUG: [LoadPickups] Updated options to: \"%s\" = Teleport_I: %i", funcargs, Int_Arg);
								
								PickupInfo[TotalPickups][Teleport_I]=Int_Arg;
								BitFlag_On(PickupData[TotalPickups], Enable_Teleport_I);
							}
						}
						case 'w', 'W':
						{
							if(!sscanf(funcargs, "p<,>{s[32]c}i", Int_Arg))
							{
								if(DEBUG_PICKUP_LEVEL >= DEBUG_PICKUP_LINES)
									printf(" DEBUG: [LoadPickups] Updated options to: \"%s\" = Teleport_W: %i", funcargs, Int_Arg);
								
								PickupInfo[TotalPickups][Teleport_W]=Int_Arg;
								BitFlag_On(PickupData[TotalPickups], Enable_Teleport_W);
							}
						}
					}
				}
			}
			else
			{
				// Prase file-dependant settings: Worldid, Interior, StreamDistance
				if(!sscanf(funcargs, "p<,>ddf", globalworld, globalinterior, globalrange))
				{
					if(DEBUG_PICKUP_LEVEL >= DEBUG_PICKUP_LINES)
						printf(" DEBUG: [LoadPickups] Updated options to: %d, %d, %f", globalworld, globalinterior, globalrange);

					operations++;
				}
			}
		}
		if(strfind(funcname, "create", true) != -1) // Scan for any function starting with 'Create', this covers CreateObject, CreateDynamicObject, CreateStreamedObject, etc.
		{
			new
				modelid,
				world,
				interior,
				Float:range;

			if(!sscanf(funcargs, "p<,>dfff{fff}D(-1)D(-1){D(-1)}F(-1.0)", modelid, posx, posy, posz, world, interior, range))
			{
				TotalPickups++;

				if(world == -1)
					world = globalworld;

				if(interior == -1)
					interior = globalinterior;

				if(range == -1.0)
					range = globalrange;

				if(DEBUG_PICKUP_LEVEL >= DEBUG_PICKUP_LINES)
				{
					printf(" DEBUG: [LoadPickups] Pickup: %d, %d, %.2f, %.2f, %.2f, %i, %i, %.2f",
						modelid, PickupInfo[TotalPickups][StreamType], posx, posy, posz, world, interior, range);
				}				

				PickupInfo[TotalPickups][StreamType]=14; // fix for wrong type
				PickupInfo[TotalPickups][StreamPickupID] = CreateDynamicPickup(modelid, PickupInfo[TotalPickups][StreamType], posx, posy, posz, world, interior, -1, range);

				new debuglabel[128];
				format(debuglabel, sizeof(debuglabel), "[DEBUG]: PickupID: %i Int:%i World: %i Type:%i\nX:%f Y:%f Z:%f", PickupInfo[TotalPickups][StreamPickupID], interior, world, PickupInfo[TotalPickups][StreamType], posx, posy, posz);
				PickupLabels[TotalPickups] = Create3DTextLabel(debuglabel, 0xFFFF00FF, posx, posy, posz, globalrange, 0);

				printf("PickupInfo[PickupID][StreamPickupID] = %i\ttmpPickup = %i\n", PickupInfo[TotalPickups][StreamPickupID], TotalPickups);

				operations++;
				tmpPickup++;
			}
		}

		linenumber++;
	}

	fclose(file);

	if(DEBUG_PICKUP_LEVEL >= DEBUG_PICKUP_FILES)
		printf("DEBUG: [LoadPickups] Finished reading file. %d pickups loaded from %d lines, %d total operations.", tmpPickup, linenumber, operations);

	return linenumber;
}

public OnPlayerPickUpDynamicPickup(playerid, pickupid)
{
	new pickup_debug_msg[128];
	format(pickup_debug_msg, sizeof(pickup_debug_msg), " [DEBUG: OnPlayerPickUpDynamicPickup] PickupID:%i", pickupid);
	SendClientMessage(playerid, 0xFFFF00AA, pickup_debug_msg);

	for(new current_pickup=0; current_pickup < sizeof(PickupInfo); current_pickup++)
	{
		if(pickupid == PickupInfo[current_pickup][StreamPickupID])
		{
			new Float:oldx,Float:oldy,Float:oldz;
			new vehicle=GetPlayerVehicleID(playerid);
			new seat=GetPlayerVehicleSeat(playerid);

			if(bool:BitFlag_Get(PickupData[current_pickup], Enable_Teleport_X) != false)
			{
				if(GetPlayerState(playerid) == PLAYER_STATE_DRIVER)
				{
					GetVehiclePos(vehicle, oldx, oldy, oldz);
					SetVehiclePos(vehicle, PickupInfo[current_pickup][Teleport_X], oldy, oldz);
				}
				else if(GetPlayerState(playerid) == PLAYER_STATE_ONFOOT)
				{
					GetPlayerPos(playerid, oldx, oldy, oldz);
					SetPlayerPos(playerid, PickupInfo[current_pickup][Teleport_X], oldy, oldz);
				}

				format(pickup_debug_msg, sizeof(pickup_debug_msg), " [DEBUG: Pickups] PickupID:%i Teleported to X:%f", pickupid, PickupInfo[current_pickup][Teleport_X]);
				SendClientMessage(playerid, 0xFFFF00AA, pickup_debug_msg);
			}
			if(bool:BitFlag_Get(PickupData[current_pickup], Enable_Teleport_Y) != false)
			{
				if(GetPlayerState(playerid) == PLAYER_STATE_DRIVER)
				{
					GetVehiclePos(vehicle, oldx, oldy, oldz);
					SetVehiclePos(vehicle, oldx, PickupInfo[current_pickup][Teleport_Y], oldz);
				}
				else if(GetPlayerState(playerid) == PLAYER_STATE_ONFOOT)
				{
					GetPlayerPos(playerid, oldx, oldy, oldz);
					SetPlayerPos(playerid, oldx, PickupInfo[current_pickup][Teleport_Y], oldz);
				}

				format(pickup_debug_msg, sizeof(pickup_debug_msg), " [DEBUG: Pickups] PickupID:%i Teleported to Y:%f", pickupid, PickupInfo[current_pickup+1][Teleport_Y]);
				SendClientMessage(playerid, 0xFFFF00AA, pickup_debug_msg);
			}
			if(bool:BitFlag_Get(PickupData[current_pickup], Enable_Teleport_Z) != false)
			{
				if(GetPlayerState(playerid) == PLAYER_STATE_DRIVER)
				{
					GetVehiclePos(vehicle, oldx, oldy, oldz);
					SetVehiclePos(vehicle, oldx, oldy, PickupInfo[current_pickup][Teleport_Z]);
				}
				else if(GetPlayerState(playerid) == PLAYER_STATE_ONFOOT)
				{
					GetPlayerPos(playerid, oldx, oldy, oldz);
					SetPlayerPos(playerid, oldx, oldy, PickupInfo[current_pickup][Teleport_Z]);
				}

				format(pickup_debug_msg, sizeof(pickup_debug_msg), " [DEBUG: Pickups] PickupID:%i Teleported to Z:%f", pickupid, PickupInfo[current_pickup-1][Teleport_Z]);
				SendClientMessage(playerid, 0xFFFF00AA, pickup_debug_msg);
			}
			if(bool:BitFlag_Get(PickupData[current_pickup], Enable_Teleport_I) != false)
			{
				SetPlayerInterior(playerid, PickupInfo[current_pickup][Teleport_I]);

				if(GetPlayerState(playerid) == PLAYER_STATE_DRIVER)
				{
					if(seat == 128)
					{
						printf("An error has prevented us from returning the seat ID.\nOnPlayerPickUpDynamicPickup(playerid:%i, pickupid:%i)", playerid, pickupid);
						SendClientMessage(playerid, 0x55FF00FF, "<DEBUG: PICKUP> {FF8800}An error has occured: Could not retreive the seat ID!");
					}
					else
					{
						LinkVehicleToInterior(vehicle, PickupInfo[current_pickup][Teleport_I]);
					}
				}
				if(vehicle) PutPlayerInVehicle(playerid, vehicle, seat);

				format(pickup_debug_msg, sizeof(pickup_debug_msg), " [DEBUG: Pickups] PickupID:%i Teleported to I:%i", pickupid, PickupInfo[current_pickup][Teleport_I]);
				SendClientMessage(playerid, 0xFFFF00AA, pickup_debug_msg);
			}
			if(bool:BitFlag_Get(PickupData[current_pickup], Enable_Teleport_W) != false)
			{
				SetPlayerVirtualWorld(playerid, PickupInfo[current_pickup][Teleport_W]);

				if(GetPlayerState(playerid) == PLAYER_STATE_DRIVER)
				{
					if(seat == 128)
					{
						printf("An error has prevented us from returning the seat ID.\nOnPlayerPickUpDynamicPickup(playerid:%i, pickupid:%i)", playerid, pickupid);
						SendClientMessage(playerid, 0x55FF00FF, "<DEBUG: PICKUP> {FF8800}An error has occured: Could not retreive the seat ID!");
					}
					else
					{
						SetVehicleVirtualWorld(vehicle, PickupInfo[current_pickup][Teleport_W]);
					}
				}
				if(vehicle) PutPlayerInVehicle(playerid, vehicle, seat);

				format(pickup_debug_msg, sizeof(pickup_debug_msg), " [DEBUG: Pickups] PickupID:%i Teleported to VW:%i", pickupid, PickupInfo[current_pickup][Teleport_W]);
				SendClientMessage(playerid, 0xFF5500FF, pickup_debug_msg);
			}

			// Relevent code has been executed...
			break;
		}
	}

	return 1;
}
