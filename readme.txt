//------------------------------------------------------------------------------
//
//  Mars3D: A source port of the game "Mars - The Ultimate Fighter"
//
//  Copyright (C) 1997 by Engine Technology CO. LTD
//  Copyright (C) 1993-1996 by id Software, Inc.
//  Copyright (C) 2018 by Retro Fans of Mars3D
//  Copyright (C) 2004-2021 by Jim Valavanis
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/mars3d/
//------------------------------------------------------------------------------

This is a source port of the DOS game 終極戰士 [Mars - The Ultimate Fighter]

       In order to run the game you must have the game data.
     The english translation of the game can be downloaded at:
             https://mars3d-game.wixsite.com/index


Features:
--------
-High screen resolutions.
-True color software rendering.
-OpenGL rendering.
-Uncapped framerate.
-Textured automap.
-Dynamic lights.
-Flac & ogg sound effects.
-MOD, S3M, IT & XM track music support.
-Screenshots.
-In game menu to configure gameplay, key bindings & screen resolution.
-Use Doom game editing utilities to create custom content.
-Advanced scripting (PascalScript).
-New enemies and pickups, using the original game resources.

History
-------
Fix gravity field inheritance in ACTORDEF declarations.
TWadReader() error cheching.
String evaluation in parameters of ACTORDEF functions.
Speed optimizations to script library.
Infinite state cycle error message will display the actor's name.
Software rendering lights affect masked, sprites and voxels.
Evaluate string parameters.
Added ACTORDEF functions:
 -A_SetMasterCustomParam(param: string, value: integer)
 -A_AddMasterCustomParam(param: string, value: integer)
 -A_SubtractMasterCustomParam(param: string, value: integer)
 -A_JumpIfMasterCustomParam(param: string, value: integer, offset: integer)
 -A_JumpIfMasterCustomParamLess(param: string, value: integer, offset: integer)
 -A_JumpIfMasterCustomParamGreater(param: string, value: integer, offset: integer)
 -A_GoToIfMasterCustomParam(param: string, value: integer, state: state_t)
 -A_GoToIfMasterCustomParamLess(param: string, value: integer, state: state_t)
 -A_GoToIfMasterCustomParamGreater(param: string, value: integer, state: state_t)
 -A_SetTracerCustomParam(param: string, value: integer)
 -A_AddTracerCustomParam(param: string, value: integer)
 -A_SubtractTracerCustomParam(param: string, value: integer)
 -A_JumpIfTracerCustomParam(param: string, value: integer, offset: integer)
 -A_JumpIfTracerCustomParamLess(param: string, value: integer, offset: integer)
 -A_JumpIfTracerCustomParamGreater(param: string, value: integer, offset: integer)
 -A_GoToIfTracerCustomParam(param: string, value: integer, state: state_t)
 -A_GoToIfTracerCustomParamLess(param: string, value: integer, state: state_t)
 -A_GoToIfTracerCustomParamGreater(param: string, value: integer, state: state_t)
Evalueate actor flags in ACTORDEF functions parameters with the FLAG() function.
A_JumpXXXX() ACTORDEF functions will recognize the RANDOM & RANDOMPICK keywords for setting offset.

Version 1.0.9.746 (20211226)
-----------------
Fixed intermission screens.
Fixed finale wipe after flc playback in 8 bit color mode.

Version 1.0.8.745 (20211226)
-----------------
Fixed intermission screen showing a previously closed menu as the background in OpenGL mode.
Barrels can not be destroyed by shock gun, flame gun and disks.
Some work to support the script library (ddc_mars.dll) by the next version of DelphiDoom IDE & PascalScript command line compiler.

Version 1.0.7.744 (20211225)
-----------------
Boss fires green (freeze) missiles.
Display boss health bar.
Boss health and difficulty raised.
Corrected the position that the boss spawns missiles.
Fixed objects bouncing on wall when hitting lower or higher texture.

Version 1.0.6.743 (20211224)
-----------------
Fixed use keycard sequence repeat bug..
Change line special 136 to 137 in MARS.MAD.
Fixed problem with the "-" prefix in MF4_EX_xxx flags.

Version 1.0.5.742 (20211221)
-----------------
Fixed the crosshair on/off in the menu.
r_fakecontrast console variable will add contrast to ALL perpendicular lines.
Don't show briefing while preparing demo playback.

Version 1.0.4.741 (20211208)
-----------------
The player can jump higher.
The player can step-up higher (32 pt instead of 24).
Fixed problem with the "use_white_fog" console variable in OpenGL mode.
Default value for "use_fog" console variable set to true.

Version 1.0.3.740 (20211205)
-----------------
Fixed OpenGL underwater rendering in NVidia cards.
Added the "gl_underwater_pp" console variable, takes values 0, 1 & 2 (for default, safe and disabled underwater distortion effect in OpenGL)
Fog strength can be configured individually for normal rendering, underwater rendering and white fog sectors. (Menu/Options/OpenGL/Fog)
Fixed grenade launcher weapon sprite, also the sequence has been smoothed.
Fixed problem with the boomerang disk projective, now it does not disappear after hit ceilings.
Fixed problem with the flying drone, now it falls to ground when destroyed.
The extra Episode 2 & 3 maps will reuse music from the first episode, since no more music tracks are available in game data.
Fixed raise state sprite sequence for floor turret drone (MT_DEFENDER).
Hint messages now work. Unreachable hint without proper translation in E1M4 set to invisible and disabled.

Version 1.0.2.739 (20211201)
-----------------
Fixed spelling mistakes.
Fixed crash when starting at the same directory as MARS.MAD file.

Version 1.0.1.738 (20211201)
-----------------
Initial release.
