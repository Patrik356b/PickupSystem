# PickupSystem
Load pickups for sa-mp - vehicle nos/repair &amp; teleporting

Warning: Pickups can npt currently be created using this script, it only loads them.


Requirements:

´´´
<FileManager>		// By JaTochNietDan:		http://forum.sa-mp.com/showthread.php?t=92246
<streamer>			// By Incognito:			http://forum.sa-mp.com/showthread.php?t=102865
<sscanf2>	  		// By Y_Less:				http://forum.sa-mp.com/showthread.php?t=120356
´´´


On line 40 the debug level can be set:
´´´
new DEBUG_PICKUP_LEVEL = 4; // set the debug level
´´´
These debug levels are available:
´´´
	DEBUG_PICKUP_NONE = -1,		// (-1) No prints
	DEBUG_PICKUP_INFO,			  // (0) Print information messages
	DEBUG_PICKUP_FOLDERS,	  	// (1) Print each directory
	DEBUG_PICKUP_FILES,		  	// (2) Print each file loaded
	DEBUG_PICKUP_LINES,		  	// (3) Print each line loaded
	DEBUG_PICKUP_BUFFER		  	// (4) Print line buffering
´´´
