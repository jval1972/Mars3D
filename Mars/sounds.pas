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
//  DESCRIPTION:
//   Created by the sound utility written by Dave Taylor.
//   Kept as a sample, DOOM2  sounds. Frozen.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/mars3d/
//------------------------------------------------------------------------------

{$I Mars3D.inc}

unit sounds;

interface

uses
  d_delphi;

//
// SoundFX struct.
//

type
  Psfxinfo_t = ^sfxinfo_t;

  sfxinfo_t = record
    // up to 6-character name
    name: string;

    // Sfx singularity (only one at a time)
    singularity: boolean;

    // Sfx priority
    priority: integer;

    // referenced sound if a link
    link: Psfxinfo_t;

    // pitch if a link
    pitch: integer;

    // volume if a link
    volume: integer;

    // sound data
    data: pointer;

    // this is checked every second to see if sound
    // can be thrown out (if 0, then decrement, if -1,
    // then throw out, if > 0, then it is in use)
    usefulness: integer;

    // lump number of sfx
    lumpnum: integer;

    // JVAL: Random list
    randomsoundlist: TDNumberList;
  end;

//
// MusicInfo struct.
//
  musicinfo_t = record
    // up to 6-character name
    name: string;
    mapname: string;
    alias: string;

    // lump number of music
    lumpnum: integer;

    // music data
    data: pointer;

    // music handle once registered
    handle: integer;
    // is an mp3?
    mp3stream: TDStream;
  end;
  Pmusicinfo_t = ^musicinfo_t;

//
// Identifiers for all music in game.
//

  musicenum_t = (
    mus_None,
    mus_e1m1,
    mus_e1m2,
    mus_e1m3,
    mus_e1m4,
    mus_e1m5,
    mus_e1m6,
    mus_e1m7,
    mus_e1m8,
    mus_e1m9,
    mus_e2m1,
    mus_e2m2,
    mus_e2m3,
    mus_e2m4,
    mus_e2m5,
    mus_e2m6,
    mus_e2m7,
    mus_e2m8,
    mus_e2m9,
    mus_e3m1,
    mus_e3m2,
    mus_e3m3,
    mus_e3m4,
    mus_e3m5,
    mus_e3m6,
    mus_e3m7,
    mus_e3m8,
    mus_e3m9,

    mus_e4m1,
    mus_e4m2,
    mus_e4m3,
    mus_e4m4,
    mus_e4m5,
    mus_e4m6,
    mus_e4m7,
    mus_e4m8,
    mus_e4m9,

    mus_inter,
    mus_intro,
    mus_bunny,
    mus_victor,
    mus_introa,
    DO_NUMMUSIC
  );

//
// Identifiers for all sfx in game.
//

  sfxenum_t = (
    sfx_None,
    sfx_pistol,
    sfx_stnmov,
    sfx_swtchn,
    sfx_swtchx,
    sfx_plpain,
    sfx_slop,
    sfx_itemup,
    sfx_oof,
    sfx_pldeth,
    sfx_noway,
    sfx_hoof,
    sfx_tink,
    sfx_itmbk,
    // JVAL: 20210108 - Additional
    sfx_dgsit,
    sfx_dgatk,
    sfx_dgact,
    sfx_dgdth,
    sfx_dgpain,
    // JVAL 9 December 2007, for water terrain
    sfx_gloop,
    // JVAL 9 December 2007, for lava terrain
    sfx_burn,
    // JVAL 20 October 2009, for nukage and sludge terrain
    sfx_sgloop,
    // JVAL 20210109 - NUKAGE SPLASH
    sfx_sgloo2,

    DO_NUMSFX
  );

const
  MAX_MUS = Ord(DO_NUMMUSIC) + 1024; // JVAL 1024 extra music
  MAX_NUMSFX = Ord(DO_NUMSFX) + 1536; // JVAL 1024 + 512 extra sounds

const
  S_music: array[0..MAX_MUS - 1] of musicinfo_t = (
    (name: '';       mapname: '';      alias: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e1m1';   mapname: '';      alias: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e1m2';   mapname: '';      alias: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e1m3';   mapname: '';      alias: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e1m4';   mapname: '';      alias: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e1m5';   mapname: '';      alias: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e1m6';   mapname: '';      alias: 'e3m6';  lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e1m7';   mapname: '';      alias: 'e2m5';  lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e1m5';   mapname: 'e1m8';  alias: 'e3m4';  lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e1m7';   mapname: 'e1m9';  alias: 'e3m9';  lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e1m1';   mapname: 'e2m1';  alias: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e1m2';   mapname: 'e2m2';  alias: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e1m3';   mapname: 'e2m3';  alias: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e1m4';   mapname: 'e2m4';  alias: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e1m5';   mapname: 'e2m5';  alias: 'e1m7';  lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e1m6';   mapname: 'e2m6';  alias: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e1m7';   mapname: 'e2m7';  alias: 'e3m7';  lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e1m5';   mapname: 'e2m8';  alias: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e1m7';   mapname: 'e2m9';  alias: 'e3m1';  lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e1m1';   mapname: 'e3m1';  alias: 'e2m9';  lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e1m2';   mapname: 'e3m2';  alias: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e1m3';   mapname: 'e3m3';  alias: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e1m4';   mapname: 'e3m4';  alias: 'e1m8';  lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e1m5';   mapname: 'e3m5';  alias: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e1m6';   mapname: 'e3m6';  alias: 'e1m6';  lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e1m7';   mapname: 'e3m7';  alias: 'e2m7';  lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e1m5';   mapname: 'e3m8';  alias: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e1m7';   mapname: 'e3m9';  alias: 'e1m9';  lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e1m1';   mapname: 'e4m1';  alias: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e1m2';   mapname: 'e4m2';  alias: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e1m3';   mapname: 'e4m3';  alias: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e1m4';   mapname: 'e4m4';  alias: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e1m5';   mapname: 'e4m5';  alias: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e1m6';   mapname: 'e4m6';  alias: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e1m7';   mapname: 'e4m7';  alias: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e1m5';   mapname: 'e4m8';  alias: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e1m7';   mapname: 'e4m9';  alias: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'inter';  mapname: '';      alias: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'intro';  mapname: '';      alias: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'bunny';  mapname: '';      alias: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'victor'; mapname: '';      alias: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'introa'; mapname: '';      alias: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),

    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),

    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: '')

  );

  S_sfx: array[0..MAX_NUMSFX - 1] of sfxinfo_t = (
  // S_sfx[0] needs to be a dummy for odd reasons.
    (name: 'none';      singularity: false; priority:   0; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),

    (name: 'GUN1SHT';   singularity: false; priority:  64; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'stnmov';    singularity: false; priority: 119; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'SWON';      singularity: false; priority:  78; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'SWON';      singularity: false; priority:  78; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'ROLEHURT';  singularity: false; priority:  96; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'ROLEDTH';   singularity: false; priority:  78; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'itemup';    singularity: true;  priority:  78; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'oof';       singularity: false; priority:  96; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'ROLEDTH';   singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'noway';     singularity: false; priority:  78; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'DEATH';     singularity: false; priority:  70; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'tink';      singularity: false; priority:  60; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'itmbk';     singularity: false; priority: 100; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),

    // killough 11/98: dog sounds
    (name: 'dgsit';     singularity: false; priority:  98; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'dgatk';     singularity: false; priority:  70; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'dgact';     singularity: false; priority: 120; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'dgdth';     singularity: false; priority:  70; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'dgpain';    singularity: false; priority:  96; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),

    // JVAL - Splash sounds
    (name: 'gloop';     singularity: false; priority:  60; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'burn';      singularity: false; priority:  60; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'sgloop';    singularity: false; priority:  60; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'sgloo2';    singularity: false; priority:  60; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),

    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),

    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),

    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: '')

  );

var
  numsfx: integer = Ord(DO_NUMSFX);
  nummusic: integer = Ord(DO_NUMMUSIC);

//==============================================================================
//
// S_GetSoundNumForName
//
//==============================================================================
function S_GetSoundNumForName(const sfx_name: string): integer;

//==============================================================================
//
// S_GetSoundNameForNum
//
//==============================================================================
function S_GetSoundNameForNum(const sfx_num: integer): string;

//==============================================================================
//
// S_GetRandomSoundList
//
//==============================================================================
function S_GetRandomSoundList(const sfx_num: integer): TDNumberList;

//==============================================================================
//
// S_FreeRandomSoundLists
//
//==============================================================================
procedure S_FreeRandomSoundLists;

//==============================================================================
//
// S_FreeMP3Streams
//
//==============================================================================
procedure S_FreeMP3Streams;

//==============================================================================
//
// S_GetMusicNumForName
//
//==============================================================================
function S_GetMusicNumForName(const mus_name: string): integer;

implementation

uses
  i_system,
  sc_actordef,
  w_wad;

//==============================================================================
//
// S_GetSoundNumForName
//
//==============================================================================
function S_GetSoundNumForName(const sfx_name: string): integer;
var
  i: integer;
  name: string;
  check: string;
  sfx: Psfxinfo_t;
begin
  result := atoi(sfx_name, -1);
  if (result >= 0) and (result < numsfx) and (itoa(result) = sfx_name) then
    exit;

  if sfx_name = '' then
  begin
    I_Warning('S_GetSoundNumForName(): No sound name specified, using default'#13#10);
    result := Ord(sfx_pistol);
    exit;
  end;

  name := strupper(SC_SoundAlias(sfx_name));
  for i := 1 to numsfx - 1 do
  begin
    check := strupper(S_sfx[i].name);
    if (check = name) or ('DS' + check = name) then
    begin
      result := i;
      exit;
    end;
  end;

  // JVAL: Not found, we will add a new sound

  if numsfx >= MAX_NUMSFX - 1 then // JVAL: Limit exceeded, we will use default pistol sound :(
  begin
    I_Warning('S_GetSoundNumForName(): Can not add %s sound, limit of %d sounds exceeded'#13#10, [sfx_name, numsfx]);
    result := Ord(sfx_pistol);
    exit;
  end;

  // JVAL: Register the new sound

  if Pos1('DS', name) then
    name := Copy(name, 3, Length(name) - 2);
  if name = '' then // JVAL: Normally this should not happen!
  begin
    I_Warning('S_GetSoundNumForName(): No sound name specified, using default'#13#10);
    result := Ord(sfx_pistol);
    exit;
  end;

  result := numsfx;
  sfx := @S_sfx[result];
  sfx.name := name;
  sfx.singularity := false;
  sfx.priority := 72;
  sfx.link := nil;
  sfx.pitch := -1;
  sfx.volume := -1;
  sfx.data := nil;
  sfx.usefulness := 0;
  sfx.lumpnum := -1; // JVAL: was = 0;
  sfx.randomsoundlist := nil;
  inc(numsfx);
end;

//==============================================================================
//
// S_GetSoundNameForNum
//
//==============================================================================
function S_GetSoundNameForNum(const sfx_num: integer): string;
begin
  if (sfx_num < 0) or (sfx_num >= numsfx) then
  begin
    result := '';
    exit;
  end;

  // JVAL: strupper -> for safety
  result := strupper(S_sfx[sfx_num].name);
end;

//==============================================================================
// S_GetRandomSoundList
//
// JVAL
// Retrieve the random sound list for a sfx number
// Note
//  Random list is in range of '0'..'9', of the last char of sound name eg
//    dsxxx0
//    dsxxx1
//    dsxxx2
//    dsxxx3
//    dsxxx7
//    dsxxx9
// It is not required to be all the numbers in last char
// Random sound list is saved not only to the sfx_num, but also to other sounds numbers
// of the same 'random' group
// Check WAD for presence of lumps
//
//==============================================================================
function S_GetRandomSoundList(const sfx_num: integer): TDNumberList;
var
  sfxname: string;
  sfxname1: string;
  sfxname2: string;
  sfxname3: string;
  sfxnum: integer;
  check: integer;
  c: char;
begin
  sfxname := S_GetSoundNameForNum(sfx_num);
  if sfxname = '' then
  begin
    result := nil;
    exit;
  end;

  if S_sfx[sfx_num].randomsoundlist = nil then
    S_sfx[sfx_num].randomsoundlist := TDNumberList.Create;

  result := S_sfx[sfx_num].randomsoundlist;

  if result.Count > 0 then
    exit;

  check := Ord(sfxname[Length(sfxname)]);
  if (check < Ord('0')) or (check > Ord('9')) then
  begin
    result.Add(sfx_num);  // This sound for sure!
    exit;
  end;

  // JVAL: look first for 'ds....' sound names
  if Pos1('DS', sfxname) then
  begin
    sfxname1 := sfxname;
    sfxname2 := Copy(sfxname, 3, Length(sfxname) - 2)
  end
  else
  begin
    sfxname1 := 'DS' + sfxname;
    sfxname2 := sfxname;
  end;
  sfxname3 := '';
  if Length(sfxname1) > 8 then
    SetLength(sfxname1, 8);
  if Length(sfxname2) > 8 then
    SetLength(sfxname2, 8);
  for c := '0' to '9' do
  begin
    sfxname1[Length(sfxname1)] := c;
    check := W_CheckNumForName(sfxname1);
    if check = -1 then
    begin
      sfxname2[Length(sfxname2)] := c;
      check := W_CheckNumForName(sfxname2);
      if check >= 0 then
        sfxname3 := sfxname2;
    end
    else
      sfxname3 := sfxname1;

    if check >= 0 then
    begin
      sfxnum := S_GetSoundNumForName(sfxname3);
      result.Add(sfxnum);
      S_sfx[sfxnum].lumpnum := check; // Save the lump number
      if S_sfx[sfxnum].randomsoundlist = nil then
        S_sfx[sfxnum].randomsoundlist := result;
    end;
  end;
end;

//==============================================================================
//
// S_FreeRandomSoundLists
//
//==============================================================================
procedure S_FreeRandomSoundLists;
var
  i, j: integer;
  l: TDNumberList;
begin
  for i := 1 to numsfx - 1 do
  begin
    if S_sfx[i].randomsoundlist <> nil then
    begin
      l := S_sfx[i].randomsoundlist;
      for j := i + 1 to numsfx - 1 do
        if S_sfx[j].randomsoundlist = l then
          S_sfx[i].randomsoundlist := nil;
      FreeAndNil(S_sfx[i].randomsoundlist);
    end;
  end;
end;

//==============================================================================
//
// S_FreeMP3Streams
//
//==============================================================================
procedure S_FreeMP3Streams;
var
  i, j: integer;
  s: TDStream;
begin
  for i := 0 to nummusic - 1 do
    if S_music[i].mp3stream <> nil then
    begin
      s := S_music[i].mp3stream;
      for j := i + 1 to nummusic - 1 do
        if S_music[j].mp3stream = s then
          S_music[j].mp3stream := nil;
      FreeAndNil(S_music[i].mp3stream);
    end;
end;

//==============================================================================
//
// S_GetMusicNumForName
//
//==============================================================================
function S_GetMusicNumForName(const mus_name: string): integer;
var
  i: integer;
  name: string;
  check: string;
  pmus: Pmusicinfo_t;
begin
  result := atoi(mus_name, -1);
  if (result >= 0) and (result < nummusic) and (itoa(result) = mus_name) then
    exit;

  if mus_name = '' then
  begin
    I_Warning('S_GetMusicNumForName(): No music name specified, using default'#13#10);
    result := 0;
    exit;
  end;

  name := strupper(mus_name);
  for i := 1 to nummusic - 1 do
  begin
    check := strupper(S_music[i].name);
    if (check = name) or ('D_' + check = name) then
    begin
      result := i;
      exit;
    end;
  end;

  // JVAL: Not found, we will add a new sound

  if nummusic >= MAX_MUS - 1 then // JVAL: Limit exceeded, we will use default music :(
  begin
    I_Warning('S_GetMusicNumForName(): Can not add "%s" music, limit of %d music lumps exceeded'#13#10, [mus_name, nummusic]);
    result := 0;
    exit;
  end;

  // JVAL: Register the new music

  if Pos1('D_', name) then
    name := Copy(name, 3, Length(name) - 2);
  if name = '' then // JVAL: Normally this should not happen!
  begin
    I_Warning('S_GetMusicNumForName(): No sound name specified, using default'#13#10);
    result := 0;
    exit;
  end;

  result := nummusic;
  pmus := @S_Music[result];
  pmus.name := name;
  pmus.lumpnum := W_CheckNumForName('D_' + name);
  if pmus.lumpnum < 0 then
    pmus.lumpnum := W_CheckNumForName(name);
  inc(nummusic);
end;

end.

