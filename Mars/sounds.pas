//------------------------------------------------------------------------------
//
//  DelphiDoom: A modified and improved DOOM engine for Windows
//  based on original Linux Doom as published by "id Software"
//  Copyright (C) 1993-1996 by id Software, Inc.
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
//   Created by the sound utility written by Dave Taylor.
//   Kept as a sample, DOOM2  sounds. Frozen.
//
//------------------------------------------------------------------------------
//  Site  : http://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

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
    mus_runnin,
    mus_stalks,
    mus_countd,
    mus_betwee,
    mus_doom,
    mus_the_da,
    mus_shawn,
    mus_ddtblu,
    mus_in_cit,
    mus_dead,
    mus_stlks2,
    mus_theda2,
    mus_doom2,
    mus_ddtbl2,
    mus_runni2,
    mus_dead2,
    mus_stlks3,
    mus_romero,
    mus_shawn2,
    mus_messag,
    mus_count2,
    mus_ddtbl3,
    mus_ampie,
    mus_theda3,
    mus_adrian,
    mus_messg2,
    mus_romer2,
    mus_tense,
    mus_shawn3,
    mus_openin,
    mus_evil,
    mus_ultima,
    mus_read_m,
    mus_dm2ttl,
    mus_dm2int,
    DO_NUMMUSIC
  );


//
// Identifiers for all sfx in game.
//

  sfxenum_t = (
    sfx_None,
    sfx_pistol,
    sfx_shotgn,
    sfx_sgcock,
    sfx_dshtgn,
    sfx_dbopn,
    sfx_dbcls,
    sfx_dbload,
    sfx_plasma,
    sfx_bfg,
    sfx_sawup,
    sfx_sawidl,
    sfx_sawful,
    sfx_sawhit,
    sfx_rlaunc,
    sfx_rxplod,
    sfx_firsht,
    sfx_firxpl,
    sfx_pstart,
    sfx_pstop,
    sfx_doropn,
    sfx_dorcls,
    sfx_stnmov,
    sfx_swtchn,
    sfx_swtchx,
    sfx_plpain,
    sfx_dmpain,
    sfx_popain,
    sfx_vipain,
    sfx_mnpain,
    sfx_pepain,
    sfx_slop,
    sfx_itemup,
    sfx_wpnup,
    sfx_oof,
    sfx_telept,
    sfx_posit1,
    sfx_posit2,
    sfx_posit3,
    sfx_bgsit1,
    sfx_bgsit2,
    sfx_sgtsit,
    sfx_cacsit,
    sfx_brssit,
    sfx_cybsit,
    sfx_spisit,
    sfx_bspsit,
    sfx_kntsit,
    sfx_vilsit,
    sfx_mansit,
    sfx_pesit,
    sfx_sklatk,
    sfx_sgtatk,
    sfx_skepch,
    sfx_vilatk,
    sfx_claw,
    sfx_skeswg,
    sfx_pldeth,
    sfx_pdiehi,
    sfx_podth1,
    sfx_podth2,
    sfx_podth3,
    sfx_bgdth1,
    sfx_bgdth2,
    sfx_sgtdth,
    sfx_cacdth,
    sfx_skldth,
    sfx_brsdth,
    sfx_cybdth,
    sfx_spidth,
    sfx_bspdth,
    sfx_vildth,
    sfx_kntdth,
    sfx_pedth,
    sfx_skedth,
    sfx_posact,
    sfx_bgact,
    sfx_dmact,
    sfx_bspact,
    sfx_bspwlk,
    sfx_vilact,
    sfx_noway,
    sfx_barexp,
    sfx_punch,
    sfx_hoof,
    sfx_metal,
    sfx_chgun,
    sfx_tink,
    sfx_bdopn,
    sfx_bdcls,
    sfx_itmbk,
    sfx_flame,
    sfx_flamst,
    sfx_getpow,
    sfx_bospit,
    sfx_boscub,
    sfx_bossit,
    sfx_bospn,
    sfx_bosdth,
    sfx_manatk,
    sfx_mandth,
    sfx_sssit,
    sfx_ssdth,
    sfx_keenpn,
    sfx_keendt,
    sfx_skeact,
    sfx_skesit,
    sfx_skeatk,
    sfx_radio,
    // JVAL: 20210108 - Additional
    sfx_dgsit,
    sfx_dgatk,
    sfx_dgact,
    sfx_dgdth,
    sfx_dgpain,
    // JVAL: 20210109 -e6y
    sfx_secret,
    sft_gibdth,
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
    (name: 'e1m8';   mapname: '';      alias: 'e3m4';  lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e1m9';   mapname: '';      alias: 'e3m9';  lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e2m1';   mapname: '';      alias: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e2m2';   mapname: '';      alias: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e2m3';   mapname: '';      alias: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e2m4';   mapname: '';      alias: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e2m5';   mapname: '';      alias: 'e1m7';  lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e2m6';   mapname: '';      alias: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e2m7';   mapname: '';      alias: 'e3m7';  lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e2m8';   mapname: '';      alias: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e2m9';   mapname: '';      alias: 'e3m1';  lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e3m1';   mapname: '';      alias: 'e2m9';  lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e3m2';   mapname: '';      alias: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e3m3';   mapname: '';      alias: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e3m4';   mapname: '';      alias: 'e1m8';  lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e3m5';   mapname: '';      alias: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e3m6';   mapname: '';      alias: 'e1m6';  lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e3m7';   mapname: '';      alias: 'e2m7';  lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e3m8';   mapname: '';      alias: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e3m9';   mapname: '';      alias: 'e1m9';  lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e3m4';   mapname: 'e4m1';  alias: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e3m2';   mapname: 'e4m2';  alias: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e3m3';   mapname: 'e4m3';  alias: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e1m5';   mapname: 'e4m4';  alias: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e2m7';   mapname: 'e4m5';  alias: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e2m4';   mapname: 'e4m6';  alias: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e2m6';   mapname: 'e4m7';  alias: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e2m5';   mapname: 'e4m8';  alias: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'e1m9';   mapname: 'e4m9';  alias: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'inter';  mapname: '';      alias: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'intro';  mapname: '';      alias: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'bunny';  mapname: '';      alias: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'victor'; mapname: '';      alias: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'introa'; mapname: '';      alias: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'runnin'; mapname: 'map01'; alias: 'map15'; lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'stalks'; mapname: 'map02'; alias: 'map11, map17'; lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'countd'; mapname: 'map03'; alias: 'map21'; lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'betwee'; mapname: 'map04'; alias: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'doom';   mapname: 'map05'; alias: 'map13'; lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'the_da'; mapname: 'map06'; alias: 'map12, map24'; lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'shawn';  mapname: 'map07'; alias: 'map19, map29'; lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'ddtblu'; mapname: 'map08'; alias: 'map14, map22'; lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'in_cit'; mapname: 'map09'; alias: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'dead';   mapname: 'map10'; alias: 'map16'; lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'stlks2'; mapname: 'map11'; alias: 'map02, map17'; lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'theda2'; mapname: 'map12'; alias: 'map06, map24'; lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'doom2';  mapname: 'map13'; alias: 'map05'; lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'ddtbl2'; mapname: 'map14'; alias: 'map08, map22'; lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'runni2'; mapname: 'map15'; alias: 'map01'; lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'dead2';  mapname: 'map16'; alias: 'map10'; lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'stlks3'; mapname: 'map17'; alias: 'map02, map11'; lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'romero'; mapname: 'map18'; alias: 'map27'; lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'shawn2'; mapname: 'map19'; alias: 'map07, map29'; lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'messag'; mapname: 'map20'; alias: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'count2'; mapname: 'map21'; alias: 'map03'; lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'ddtbl3'; mapname: 'map22'; alias: 'map08, map14'; lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'ampie';  mapname: 'map23'; alias: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'theda3'; mapname: 'map24'; alias: 'map06, map12'; lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'adrian'; mapname: 'map25'; alias: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'messg2'; mapname: 'map26'; alias: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'romer2'; mapname: 'map27'; alias: 'map18'; lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'tense';  mapname: 'map28'; alias: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'shawn3'; mapname: 'map29'; alias: 'map07, map19'; lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'openin'; mapname: 'map30'; alias: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'evil';   mapname: 'map31'; alias: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'ultima'; mapname: 'map32'; alias: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'read_m'; mapname: '';      alias: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'dm2ttl'; mapname: '';      alias: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),
    (name: 'dm2int'; mapname: '';      alias: '';      lumpnum: 0; data: nil; handle: 0; mp3stream: nil),

    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),

    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
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
    (name: 'none';   singularity: false; priority:   0; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),

    (name: 'pistol'; singularity: false; priority:  64; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'shotgn'; singularity: false; priority:  64; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'sgcock'; singularity: false; priority:  64; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'dshtgn'; singularity: false; priority:  64; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'dbopn';  singularity: false; priority:  64; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'dbcls';  singularity: false; priority:  64; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'dbload'; singularity: false; priority:  64; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'plasma'; singularity: false; priority:  64; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'bfg';    singularity: false; priority:  64; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'sawup';  singularity: false; priority:  64; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'sawidl'; singularity: false; priority: 118; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'sawful'; singularity: false; priority:  64; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'sawhit'; singularity: false; priority:  64; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'rlaunc'; singularity: false; priority:  64; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'rxplod'; singularity: false; priority:  70; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'firsht'; singularity: false; priority:  70; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'firxpl'; singularity: false; priority:  70; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'pstart'; singularity: false; priority: 100; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'pstop';  singularity: false; priority: 100; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'doropn'; singularity: false; priority: 100; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'dorcls'; singularity: false; priority: 100; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'stnmov'; singularity: false; priority: 119; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'swtchn'; singularity: false; priority:  78; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'swtchx'; singularity: false; priority:  78; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'plpain'; singularity: false; priority:  96; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'dmpain'; singularity: false; priority:  96; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'popain'; singularity: false; priority:  96; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'vipain'; singularity: false; priority:  96; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'mnpain'; singularity: false; priority:  96; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'pepain'; singularity: false; priority:  96; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'slop';   singularity: false; priority:  78; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'itemup'; singularity: true;  priority:  78; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'wpnup';  singularity: true;  priority:  78; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'oof';    singularity: false; priority:  96; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'telept'; singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'posit1'; singularity: true;  priority:  98; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'posit2'; singularity: true;  priority:  98; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'posit3'; singularity: true;  priority:  98; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'bgsit1'; singularity: true;  priority:  98; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'bgsit2'; singularity: true;  priority:  98; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'sgtsit'; singularity: true;  priority:  98; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'cacsit'; singularity: true;  priority:  98; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'brssit'; singularity: true;  priority:  94; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'cybsit'; singularity: true;  priority:  92; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'spisit'; singularity: true;  priority:  90; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'bspsit'; singularity: true;  priority:  90; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'kntsit'; singularity: true;  priority:  90; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'vilsit'; singularity: true;  priority:  90; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'mansit'; singularity: true;  priority:  90; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'pesit';  singularity: true;  priority:  90; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'sklatk'; singularity: false; priority:  70; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'sgtatk'; singularity: false; priority:  70; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'skepch'; singularity: false; priority:  70; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'vilatk'; singularity: false; priority:  70; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'claw';   singularity: false; priority:  70; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'skeswg'; singularity: false; priority:  70; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'pldeth'; singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'pdiehi'; singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'podth1'; singularity: false; priority:  70; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'podth2'; singularity: false; priority:  70; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'podth3'; singularity: false; priority:  70; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'bgdth1'; singularity: false; priority:  70; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'bgdth2'; singularity: false; priority:  70; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'sgtdth'; singularity: false; priority:  70; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'cacdth'; singularity: false; priority:  70; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'skldth'; singularity: false; priority:  70; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'brsdth'; singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'cybdth'; singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'spidth'; singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'bspdth'; singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'vildth'; singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'kntdth'; singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'pedth';  singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'skedth'; singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'posact'; singularity: true;  priority: 120; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'bgact';  singularity: true;  priority: 120; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'dmact';  singularity: true;  priority: 120; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'bspact'; singularity: true;  priority: 100; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'bspwlk'; singularity: true;  priority: 100; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'vilact'; singularity: true;  priority: 100; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'noway';  singularity: false; priority:  78; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'barexp'; singularity: false; priority:  60; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'punch';  singularity: false; priority:  64; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'hoof';   singularity: false; priority:  70; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'metal';  singularity: false; priority:  70; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'chgun';  singularity: false; priority:  64; link: @S_sfx[Ord(sfx_pistol)]; pitch: 150; volume: 0; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'tink';   singularity: false; priority:  60; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'bdopn';  singularity: false; priority: 100; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'bdcls';  singularity: false; priority: 100; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'itmbk';  singularity: false; priority: 100; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'flame';  singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'flamst'; singularity: false; priority:  32; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'getpow'; singularity: false; priority:  60; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'bospit'; singularity: false; priority:  70; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'boscub'; singularity: false; priority:  70; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'bossit'; singularity: false; priority:  70; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'bospn';  singularity: false; priority:  70; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'bosdth'; singularity: false; priority:  70; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'manatk'; singularity: false; priority:  70; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'mandth'; singularity: false; priority:  70; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'sssit';  singularity: false; priority:  70; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'ssdth';  singularity: false; priority:  70; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'keenpn'; singularity: false; priority:  70; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'keendt'; singularity: false; priority:  70; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'skeact'; singularity: false; priority:  70; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'skesit'; singularity: false; priority:  70; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'skeatk'; singularity: false; priority:  70; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'radio';  singularity: false; priority:  60; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),

    // killough 11/98: dog sounds
    (name: 'dgsit';  singularity: false; priority:  98; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'dgatk';  singularity: false; priority:  70; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'dgact';  singularity: false; priority: 120; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'dgdth';  singularity: false; priority:  70; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'dgpain'; singularity: false; priority:  96; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),

    //e6y
    (name: 'secret'; singularity: false; priority:  60; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'gibdth'; singularity: false; priority:  60; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),

    // JVAL - Splash sounds
    (name: 'gloop';  singularity: false; priority:  60; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'burn';   singularity: false; priority:  60; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'sgloop'; singularity: false; priority:  60; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),
    (name: 'sgloo2'; singularity: false; priority:  60; link: nil; pitch: -1; volume: -1; data: nil; usefulness: 0; lumpnum: 0; randomsoundlist: nil),

    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),

    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),

    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
    (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''), (name: ''),
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

function S_GetSoundNumForName(const sfx_name: string): integer;

function S_GetSoundNameForNum(const sfx_num: integer): string;

function S_GetRandomSoundList(const sfx_num: integer): TDNumberList;

procedure S_FreeRandomSoundLists;

procedure S_FreeMP3Streams;

function S_GetMusicNumForName(const mus_name: string): integer;

implementation

uses
  i_system,
  sc_actordef,
  w_wad;

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

  if Pos('DS', name) = 1 then
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
  if Pos('DS', sfxname) = 1 then
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

  if Pos('D_', name) = 1 then
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

