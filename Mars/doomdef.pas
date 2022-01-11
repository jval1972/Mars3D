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
//  Foundation, inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
// DESCRIPTION:
//  Internally used data structures for virtually everything,
//  key definitions, lots of other stuff.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/mars3d/
//------------------------------------------------------------------------------

{$I Mars3D.inc}

unit doomdef;

interface

uses
  d_delphi;

//
// Global parameters/defines.
//
// DOOM version
const
  VERSION099 = 99;
  VERSION110 = 110;
  VERSION111 = 111;
  VERSION112 = 112;
  VERSION113 = 113;
  VERSION114 = 114;
  VERSION115 = 115;
  VERSION116 = 116;
  VERSION117 = 117;
  VERSION118 = 118;
  VERSION119 = 119;
  VERSION120 = 120;
  VERSION121 = 121;
  VERSION122 = 122;
  VERSION203 = 203;
  VERSION204 = 204;
  VERSION205 = 205;
  VERSION206 = 206;
  VERSION = VERSION206;
{$IFDEF OPENGL}
  VERSIONSLOPES = VERSION122;
{$ENDIF}

type
// Game mode handling - identify IWAD version
//  to handle IWAD dependend animations etc.
  GameMode_t = (
    shareware,      // MARS shareware, E1M1-E1M2, E2M1-E2M3
    registered,     // MARS registered, E1M1-E1M7, E2M1-E2M9, E3M1-E3M4
    indetermined    // Well, no IWAD found.
  );

// Mission packs - might be useful for TC stuff?
  GameMission_t = (
    gm_mars,  // Mars
    gm_none
  );

  GameVersion_t = (
    gv_mars
  );

  // JVAL: Chex Support
  CustomGame_t = (
    cg_none
  );

// Identify language to use, software localization.
  Language_t = (
    english,
    chinese,
    unknown
  );

const
  // MAX RENDERING DIMENTIONS
  MAXWIDTH = 4096;
  MAXHEIGHT = 3072;

const
  // MIN RENDERING DIMENTIONS
  MINWIDTH = 320;
  MINHEIGHT = 200;

var
// Rendering Engine Screen Dimentions
  SCREENWIDTH: integer;
  SCREENHEIGHT: integer;
{$IFNDEF OPENGL}
// Window Screen Dimentions
  WINDOWWIDTH: integer;
  WINDOWHEIGHT: integer;
{$ENDIF}

  SCREENWIDTH32PITCH: integer;

  fullscreen: {$IFDEF OPENGL}boolean{$ELSE}integer = 0{$ENDIF};
  zaxisshift: boolean = true;

const
// The maximum number of players, multiplayer/networking.
  MAXPLAYERS = 4;

// State updates, number of tics / second.
  TICRATE = 35;

// The current state of the game: whether we are
// playing, gazing at the intermission screen,
// the game final animation, or a demo.
type
  gamestate_t = (
    GS_INDETERMINED,
    GS_LEVEL,
    GS_BRIEFING,
    GS_INTERMISSION,
    GS_FINALE,
    GS_DEMOSCREEN,
    GS_INTRO,
    GS_ENDOOM
  );

var
  gamestate: gamestate_t;
  oldgamestate: integer = -1;
  gamedirectories: TDStringList;

const
//
// Difficulty/skill settings/filters.
//

// Skill flags.
  MTF_EASY = 1;
  MTF_NORMAL = 2;
  MTF_HARD = 4;

// Deaf monsters/do not react to sound.
  MTF_AMBUSH = 8;

// killough 11/98
  MTF_NOTSINGLE = 16;
  MTF_NOTDM = 32;
  MTF_NOTCOOP = 64;
// DelphiDoom
  MTF_ONMIDSECTOR = 128;  // JVAL: 3d floors
  MTF_DONOTTRIGGERSCRIPTS = 256;  // JVAL: Script Events
  MTF_FRIEND = 512; // JVAL: version 205

type
  skill_t = (
    sk_baby,
    sk_easy,
    sk_medium,
    sk_hard,
    sk_nightmare
  );

//
// Key cards.
//
  card_t = (
    it_redcard,
    it_bluecard,
    it_yellowcard,
    it_redskull,
    it_blueskull,
    it_yellowskull,
    NUMCARDS
  );

// The defined weapons,
//  including a marker indicating
//  user has not changed weapon.
  weapontype_t = (
    wp_fist,            // Fist
    wp_pistol,          // Pistol
    wp_shockgun,        // Shock gun
    wp_nervegun,        // Nerve gun
    wp_freezegun,       // Freeze gun
    wp_flamegun,        // Flame gun
    wp_grenades,        // Grenade launcher
    wp_boomerang,       // Boomerang gun
    wp_missile,         // Missile launcher
    wp_trackingmissile, // Tracking Missile launcher
    wp_redcard,
    wp_bluecard,
    wp_yellowcard,
    NUMWEAPONS,
    // No pending weapon change.
    wp_nochange
  );

// Ammunition types defined.
  ammotype_t = (
    am_bullet,          // Pistol
    am_shockgunammo,    // For shock gun
    am_nervegunammo,    // For nerve gun
    am_freezegunammo,   // For freeze gun
    am_flamegunammo,    // For flame gun
    am_grenades,        // For granade launcher
    am_disk,            // For boomerang gun
    am_misl,            // Missile launcher
    am_trackingmisl,    // Tracking Missile launcher
    NUMAMMO,
    am_noammo // Unlimited for fist.
  );

// Power up artifacts.
  powertype_t = (
    pw_invulnerability,
    pw_strength,
    pw_invisibility,
    pw_ironfeet,
    pw_allmap,
    pw_infrared,
    pw_jetpack,
    NUMPOWERS
  );
  Ppowertype_t = ^powertype_t;

//
// Power up durations,
//  how many seconds till expiration,
//  assuming TICRATE is 35 ticks/second.
//
const
  INVULNTICS = 30 * TICRATE;
  INVISTICS = 60 * TICRATE;
  INFRATICS = 120 * TICRATE;
  IRONTICS = 60 * TICRATE;

//
// DOOM keyboard definition.
// This is the stuff configured by Setup.Exe.
// Most key data are simple ascii (uppercased).
//
const
  KEY_RIGHTARROW = $ae;
  KEY_LEFTARROW = $ac;
  KEY_UPARROW = $ad;
  KEY_DOWNARROW = $af;
  KEY_ESCAPE = 27;
  KEY_ENTER = 13;
  KEY_TAB = 9;

  KEY_F1 = $80 + $3b;
  KEY_F2 = $80 + $3c;
  KEY_F3 = $80 + $3d;
  KEY_F4 = $80 + $3e;
  KEY_F5 = $80 + $3f;
  KEY_F6 = $80 + $40;
  KEY_F7 = $80 + $41;
  KEY_F8 = $80 + $42;
  KEY_F9 = $80 + $43;
  KEY_F10 = $80 + $44;
  KEY_F11 = $80 + $57;
  KEY_F12 = $80 + $58;

  KEY_PRNT = $80 + $59;

  KEY_CON = 126;
  KEY_BACKSPACE = 127;
  KEY_PAUSE = $ff;

  KEY_EQUALS = $3d;
  KEY_MINUS = $2d;

  KEY_RSHIFT = $80 + $36;
  KEY_RCTRL = $80 + $1d;
  KEY_RALT = $80 + $38;

  KEY_PAGEDOWN = $80 + $45;
  KEY_PAGEUP = $80 + $46;
  KEY_INS = $80 + $47;


  KEY_HOME = $80 + $48;
  KEY_END = $80 + $49;
  KEY_DELETE = $80 + $4a;


  KEY_LALT = KEY_RALT;

const
  DEN_PLAYER5 = 4001;
  DEN_PLAYER6 = 4002;
  DEN_PLAYER7 = 4003;
  DEN_PLAYER8 = 4004;

implementation

end.

