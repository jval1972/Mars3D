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
