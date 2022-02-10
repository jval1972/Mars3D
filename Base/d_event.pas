//------------------------------------------------------------------------------
//
//  Mars3D: A source port of the game "Mars - The Ultimate Fighter"
//
//  Copyright (C) 1997 by Engine Technology CO. LTD
//  Copyright (C) 1993-1996 by id Software, Inc.
//  Copyright (C) 2018 by Retro Fans of Mars3D
//  Copyright (C) 2004-2022 by Jim Valavanis
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
//  Site  : https://sourceforge.net/projects/mars3d/
//------------------------------------------------------------------------------

{$I Mars3D.inc}

unit d_event;

interface

//
// Event handling.
//
// Input event types.

type
  evtype_t = (ev_keydown, ev_keyup, ev_mouse, ev_joystick);

// Event structure.
// keys / mouse/joystick buttons
// mouse/joystick x move
// mouse/joystick y move

  event_t = record
    _type : evtype_t;
    data1 : integer;
    data2 : integer;
    data3 : integer;
  end;
  Pevent_t = ^event_t;

  gameaction_t = (
    ga_nothing,
    ga_loadlevel,
{$IFDEF HEXEN}
    ga_initnew,
{$ENDIF}
    ga_newgame,
    ga_loadgame,
    ga_savegame,
    ga_playdemo,
    ga_completed,
{$IFDEF HEXEN}
    ga_leavemap,
    ga_singlereborn,
{$ENDIF}
    ga_victory,
    ga_worlddone,
    ga_screenshot
  );

//
// Button/action code definitions.
//
// Press "Fire".
// Use button, to open doors, activate switches.
// Flag: game events, not really buttons.
// Flag, weapon change pending.
// If true, the next 3 bits hold weapon num.
// The 3bit weapon mask and shift, convenience.
// Pause the game.
// Save the game at each console.
// Savegame slot numbers
//  occupy the second byte of buttons.

const
  // Press "Fire".
  BT_ATTACK = 1;
  // Use button, to open doors, activate switches.
  BT_USE = 2;

  // Flag: game events, not really buttons.
  BT_SPECIAL = 128;
  BT_SPECIALMASK = 3;

  // Flag, weapon change pending.
  // If true, the next 4 bits hold weapon num.
  BT_CHANGE = 4;
  // The 3bit weapon mask and shift, convenience.
  BT_WEAPONMASK = (8 + 16 + 32 + 64);
  BT_WEAPONSHIFT = 3;

  // Pause the game.
  BTS_PAUSE = 1;
  // Save the game at each console.
  BTS_SAVEGAME = 2;

  // Savegame slot numbers
  //  occupy the second byte of buttons.
  BTS_SAVEMASK = 4 + 8 + 16 + 32;
  BTS_SAVESHIFT = 2;

{$IFDEF STRIFE}
const
    BT2_INVUSE          = 8;
    // Drop inventory item
    BT2_INVDROP         = 16;
    // Jump up and down
    BT2_JUMP            = 32;
    // Use medkit
    BT2_HEALTH          = 128;
{$ENDIF}

// Commands Actions
const
  CM_SAVEGAME = 1;

//
// GLOBAL VARIABLES
//

{$IFDEF HEXEN}
const
// The top 3 bits of the artifact field in the ticcmd_t struct are used
//     as additional flags
  AFLAG_MASK = $3F;
  AFLAG_SUICIDE = $40;
  AFLAG_JUMP = $80;
{$ENDIF}

const
  MAXEVENTS = 256;

const
  NUMJOYBUTTONS = 12;

var
//
// EVENT HANDLING
//
// Events are asynchronous inputs generally generated by the game user.
// Events can be discarded if no responder claims them
//
  events: array[0..MAXEVENTS - 1] of event_t;
  eventhead: integer;
  eventtail: integer;

implementation

end.

