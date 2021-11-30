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
//  DESCRIPTION:
//    Thing frame/state LUT,
//    generated by multigen utilitiy.
//    This one is the original DOOM version, preserved.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/mars3d/
//------------------------------------------------------------------------------

{$I Mars3D.inc}

{$Z4}

unit info_h;

interface

uses
  d_delphi,
  d_think,
  r_renderstyle,
  p_gender,
  sc_params;

type
  spritenum_t = (
    SPR_TNT1, SPR_BLUD, SPR_PUFF, SPR_TFOG, SPR_IFOG, SPR_ROLE, SPR_POL5, SPR_DOGS,

    // [BH] 100 extra sprite names to use in dehacked patches
    SPR_SP00, SPR_SP01, SPR_SP02, SPR_SP03, SPR_SP04, SPR_SP05, SPR_SP06, SPR_SP07, SPR_SP08, SPR_SP09,
    SPR_SP10, SPR_SP11, SPR_SP12, SPR_SP13, SPR_SP14, SPR_SP15, SPR_SP16, SPR_SP17, SPR_SP18, SPR_SP19,
    SPR_SP20, SPR_SP21, SPR_SP22, SPR_SP23, SPR_SP24, SPR_SP25, SPR_SP26, SPR_SP27, SPR_SP28, SPR_SP29,
    SPR_SP30, SPR_SP31, SPR_SP32, SPR_SP33, SPR_SP34, SPR_SP35, SPR_SP36, SPR_SP37, SPR_SP38, SPR_SP39,
    SPR_SP40, SPR_SP41, SPR_SP42, SPR_SP43, SPR_SP44, SPR_SP45, SPR_SP46, SPR_SP47, SPR_SP48, SPR_SP49,
    SPR_SP50, SPR_SP51, SPR_SP52, SPR_SP53, SPR_SP54, SPR_SP55, SPR_SP56, SPR_SP57, SPR_SP58, SPR_SP59,
    SPR_SP60, SPR_SP61, SPR_SP62, SPR_SP63, SPR_SP64, SPR_SP65, SPR_SP66, SPR_SP67, SPR_SP68, SPR_SP69,
    SPR_SP70, SPR_SP71, SPR_SP72, SPR_SP73, SPR_SP74, SPR_SP75, SPR_SP76, SPR_SP77, SPR_SP78, SPR_SP79,
    SPR_SP80, SPR_SP81, SPR_SP82, SPR_SP83, SPR_SP84, SPR_SP85, SPR_SP86, SPR_SP87, SPR_SP88, SPR_SP89,
    SPR_SP90, SPR_SP91, SPR_SP92, SPR_SP93, SPR_SP94, SPR_SP95, SPR_SP96, SPR_SP97, SPR_SP98, SPR_SP99,

    SPR_NULL,
    
    DO_NUMSPRITES
  );

  statenum_t = (
    S_NULL,
    S_BLOOD1,         S_BLOOD2,         S_BLOOD3,
    S_PUFF1,          S_PUFF2,          S_PUFF3,          S_PUFF4,
    S_TFOG,           S_TFOG01,         S_TFOG02,         S_TFOG2,
    S_TFOG3,          S_TFOG4,          S_TFOG5,          S_TFOG6,
    S_TFOG7,          S_TFOG8,          S_TFOG9,          S_TFOG10,
    S_IFOG,           S_IFOG01,         S_IFOG02,         S_IFOG2,
    S_IFOG3,          S_IFOG4,          S_IFOG5,
    S_PLAY,           S_PLAY_RUN1,      S_PLAY_RUN2,      S_PLAY_RUN3,
    S_PLAY_RUN4,      S_PLAY_ATK1,      S_PLAY_ATK2,      S_PLAY_PAIN,
    S_PLAY_PAIN2,     S_PLAY_DIE1,      S_PLAY_DIE2,      S_PLAY_DIE3,
    S_PLAY_DIE4,      S_PLAY_DIE5,      S_PLAY_DIE6,      S_PLAY_DIE7,
    S_PLAY_XDIE1,     S_PLAY_XDIE2,     S_PLAY_XDIE3,     S_PLAY_XDIE4,
    S_PLAY_XDIE5,     S_PLAY_XDIE6,     S_PLAY_XDIE7,     S_PLAY_XDIE8,
    S_PLAY_XDIE9,
    S_CPLAY,          S_CPLAY_RUN1,     S_CPLAY_RUN2,     S_CPLAY_RUN3,
    S_CPLAY_RUN4,     S_CPLAY_ATK1,     S_CPLAY_ATK2,     S_CPLAY_PAIN,
    S_CPLAY_PAIN2,    S_CPLAY_DIE1,     S_CPLAY_DIE2,     S_CPLAY_DIE3,
    S_CPLAY_DIE4,     S_CPLAY_DIE5,     S_CPLAY_DIE6,     S_CPLAY_DIE7,
    S_CPLAY_XDIE1,    S_CPLAY_XDIE2,    S_CPLAY_XDIE3,    S_CPLAY_XDIE4,
    S_CPLAY_XDIE5,    S_CPLAY_XDIE6,    S_CPLAY_XDIE7,    S_CPLAY_XDIE8,
    S_CPLAY_XDIE9,
    S_FPLAY,          S_FPLAY_RUN1,     S_FPLAY_RUN2,     S_FPLAY_RUN3,
    S_FPLAY_RUN4,     S_FPLAY_ATK1,     S_FPLAY_ATK2,     S_FPLAY_PAIN,
    S_FPLAY_PAIN2,    S_FPLAY_DIE1,     S_FPLAY_DIE2,     S_FPLAY_DIE3,
    S_FPLAY_DIE4,     S_FPLAY_DIE5,     S_FPLAY_DIE6,     S_FPLAY_DIE7,
    S_FPLAY_XDIE1,    S_FPLAY_XDIE2,    S_FPLAY_XDIE3,    S_FPLAY_XDIE4,
    S_FPLAY_XDIE5,    S_FPLAY_XDIE6,    S_FPLAY_XDIE7,    S_FPLAY_XDIE8,
    S_FPLAY_XDIE9,
    S_SMOKE1,         S_SMOKE2,         S_SMOKE3,         S_SMOKE4,
    S_SMOKE5,
    S_GIBS,

    // [crispy] additional BOOM and MBF states, sprites and code pointers
    S_TNT1,
    S_DOGS_STND,
    S_DOGS_STND2,
    S_DOGS_RUN1,
    S_DOGS_RUN2,
    S_DOGS_RUN3,
    S_DOGS_RUN4,
    S_DOGS_RUN5,
    S_DOGS_RUN6,
    S_DOGS_RUN7,
    S_DOGS_RUN8,
    S_DOGS_ATK1,
    S_DOGS_ATK2,
    S_DOGS_ATK3,
    S_DOGS_PAIN,
    S_DOGS_PAIN2,
    S_DOGS_DIE1,
    S_DOGS_DIE2,
    S_DOGS_DIE3,
    S_DOGS_DIE4,
    S_DOGS_DIE5,
    S_DOGS_DIE6,
    S_DOGS_RAISE1,
    S_DOGS_RAISE2,
    S_DOGS_RAISE3,
    S_DOGS_RAISE4,
    S_DOGS_RAISE5,
    S_DOGS_RAISE6,
    S_NONE,

    DO_NUMSTATES
  );


type
  state_t = record
    sprite: integer;
    frame: integer;
    tics: integer;
    tics2: integer;
    action: actionf_t;
    nextstate: integer;
    misc1: integer;
    misc2: integer;
    params: TCustomParamList;
    owners: TDNumberList;
    dlights: T2DNumberList;
{$IFDEF OPENGL}
    models: TDNumberList;
{$ENDIF}
    voxels: TDNumberList;
{$IFNDEF OPENGL}
    voxelradius: integer;
{$ENDIF}
    flags_ex: integer;
  end;
  Pstate_t = ^state_t;

type
  mobjtype_t = (
    MT_PLAYER,        MT_SMOKE,         MT_PUFF,          MT_BLOOD,
    MT_TFOG,          MT_IFOG,          MT_TELEPORTMAN,   MT_MISC71,

    // BOOM/MBF
    MT_PUSH,
    MT_PULL,
    MT_DOGS,
    MT_NONE,

    DO_NUMMOBJTYPES
  );

const
  MOBJINFONAMESIZE = 30;

type
  mobjinfo_t = record
    name: array[0..MOBJINFONAMESIZE - 1] of char;
    inheritsfrom: integer;
    doomednum: integer;
    spawnstate: integer;
    spawnhealth: integer;
    seestate: integer;
    seesound: integer;
    reactiontime: integer;
    attacksound: integer;
    painstate: integer;
    painchance: integer;
    painsound: integer;
    meleestate: integer;
    missilestate: integer;
    deathstate: integer;
    xdeathstate: integer;
    deathsound: integer;
    speed: integer;
    radius: integer;
    height: integer;
    mass: integer;
    damage: integer;
    activesound: integer;
    flags: integer;
    flags_ex: integer;
    flags2_ex: integer;
    raisestate: integer;
    customsound1: integer;
    customsound2: integer;
    customsound3: integer;
    meleesound: integer;
    dropitem: integer;
    missiletype: integer;
    explosiondamage: integer;
    explosionradius: integer;
    meleedamage: integer;
    renderstyle: mobjrenderstyle_t;
    alpha: integer;
    healstate: integer;
    crashstate: integer;
    interactstate: integer;
    missileheight: integer;
    vspeed: integer;  // Initial vertical speed
    pushfactor: integer; // How much can be pushed? 1..FRACUNIT
    friction: Integer; // Default is ORIG_FRICTION
    scale: integer;
    gravity: integer;
    flags3_ex: integer;
    flags4_ex: integer;
    minmissilechance: integer;
    floatspeed: integer;
    normalspeed: integer;
    fastspeed: integer;
    obituary: string[64];
    hitobituary: string[64];
    gender: gender_t;
    meleerange: integer;
    maxstepheight: integer;
    maxdropoffheight: integer;
    gibhealth: integer;
    maxtargetrange: integer;
    WeaveIndexXY: integer;
    WeaveIndexZ: integer;
    spriteDX: integer;
    spriteDY: integer;
  end;
  Pmobjinfo_t = ^mobjinfo_t;

// JVAL: 20200108 - Old extra DelphiDoom mobjs made dynamic  
var
  MT_SPLASHBASE: integer = -2;
  MT_SPLASH: integer = -2;
  MT_LAVASPLASH: integer = -2;
  MT_LAVASMOKE: integer = -2;
  MT_SLUDGESPLASH: integer = -2;
  MT_SLUDGECHUNK: integer = -2;
  MT_NUKAGECHUNK: integer = -2;
  MT_NUKAGESPLASH: integer = -2;
  MT_GREENBLOOD: integer = -2;
  MT_BLUEBLOOD: integer = -2;
  MT_BARREL: integer = -2;
  MT_GREENGIBS: integer = -2;
  MT_BLUEGIBS: integer = -2;

implementation

end.

