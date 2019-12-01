//------------------------------------------------------------------------------
//
//  DelphiDoom: A modified and improved DOOM engine for Windows
//  based on original Linux Doom as published by "id Software"
//  Copyright (C) 2004-2008 by Jim Valavanis
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
//  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
//------------------------------------------------------------------------------
//  E-Mail: jimmyvalavanis@yahoo.gr
//  Site  : http://delphidoom.sitesled.com/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit d_ticcmd;

interface

{
    d_ticcmd.h
}

// Emacs style mode select   -*- C++ -*-  
//----------------------------------------------------------------------------- 
// 
// $Id:$ 
//
// Copyright (C) 1993-1996 by id Software, Inc. 
// 
// This source is available for distribution and/or modification 
// only under the terms of the DOOM Source Code License as 
// published by id Software. All rights reserved. 
// 
// The source is distributed in the hope that it will be useful, 
// but WITHOUT ANY WARRANTY; without even the implied warranty of 
// FITNESS FOR A PARTICULAR PURPOSE. See the DOOM Source Code License 
// for more details. 
// 
// DESCRIPTION: 
//  System specific interface stuff. 
// 
//-----------------------------------------------------------------------------

// The data sampled per tick (single player)
// and transmitted to other peers (multiplayer).
// Mainly movements/button commands per game tick,
// plus a checksum for internal state consistency.
type
  ticcmd_t = packed record
    forwardmove: shortint; // *2048 for move 
    sidemove: shortint;    // *2048 for move
    angleturn: smallint;   // <<16 for angle delta
    consistancy: smallint; // checks for net game
    chatchar: byte;
    buttons: byte;
    commands: byte; // JVAL for special commands
    look: byte;   // JVAL look up/down/centering
    look2: byte;  // JVAL look left/right/forward
    jump: byte;   // JVAL Jump!
  end;
  Pticcmd_t = ^ticcmd_t;

implementation


end.

