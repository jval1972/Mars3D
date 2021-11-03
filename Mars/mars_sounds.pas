//------------------------------------------------------------------------------
//
//  Mars3D: A source port of the game "Mars3D" based on DelphiDoom
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
// DESCRIPTION:
//  Mars3D sounds
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/mars3d/
//------------------------------------------------------------------------------

{$I Mars3D.inc}

unit mars_sounds;

interface

type
  marssound_t = (
    snd_ARM1HURT,
    snd_BAL2ACT,
    snd_BAL2ATT,
    snd_BARLEXP,
    snd_BUBBLE,
    snd_CHEMHURT,
    snd_DEATH,
    snd_DEATH1,
    snd_DEATH2,
    snd_DEF2ACT,
    snd_DEF2ATT,
    snd_DEF2DTH,
    snd_DROPEN,
    snd_FIR1ACT,
    snd_FIR1ATT,
    snd_FIR1EXP,
    snd_FISHATT,
    snd_FISHDTH,
    snd_FISHHURT,
    snd_FISTEXP,
    snd_FISTSHT,
    snd_GLASEXP,
    snd_GUN1SHT,
    snd_GUN2ACT,
    snd_GUN2SHT,
    snd_GUN3EXP,
    snd_GUN5EXP,
    snd_GUN6SHT,
    snd_GUN7SHT,
    snd_GUN8SHT,
    snd_ITEMUP,
    snd_LAKEACT,
    snd_LAKEAPP,
    snd_LAKEATT,
    snd_LAKEDTH,
    snd_LAKEHURT,
    snd_MEC1ACT,
    snd_MEC2ACT,
    snd_MECHAPP,
    snd_MECHATT,
    snd_MECHDTH,
    snd_MECHHURT,
    snd_MECXDTH,
    snd_MIS1ACT,
    snd_MIS1EXP,
    snd_MIS1SHT,
    snd_MONSDTH,
    snd_MOS1DTH,
    snd_MOUSAPP,
    snd_MOUSATT,
    snd_MOUSDTH,
    snd_MOUSHURT,
    snd_ROLEDTH,
    snd_ROLEHURT,
    snd_SRAGATT,
    snd_SWON,
    snd_TELEPORT,
    snd_WATERIN,
    snd_WATERIN1,
    NUM_MARS_SOUNDS
  );

type
  marssoundinfo_t = record
    name: string[8];
    path: string[255];
    sound_id: integer;
  end;

const
  marssounds: array[0..Ord(NUM_MARS_SOUNDS) - 1] of marssoundinfo_t = (
    (name: 'ARM1HURT'; path: ''; sound_id: -1; ),
    (name: 'BAL2ACT';  path: ''; sound_id: -1; ),
    (name: 'BAL2ATT';  path: ''; sound_id: -1; ),
    (name: 'BARLEXP';  path: ''; sound_id: -1; ),
    (name: 'BUBBLE';   path: ''; sound_id: -1; ),
    (name: 'CHEMHURT'; path: ''; sound_id: -1; ),
    (name: 'DEATH';    path: ''; sound_id: -1; ),
    (name: 'DEATH1';   path: ''; sound_id: -1; ),
    (name: 'DEATH2';   path: ''; sound_id: -1; ),
    (name: 'DEF2ACT';  path: ''; sound_id: -1; ),
    (name: 'DEF2ATT';  path: ''; sound_id: -1; ),
    (name: 'DEF2DTH';  path: ''; sound_id: -1; ),
    (name: 'DROPEN';   path: ''; sound_id: -1; ),
    (name: 'FIR1ACT';  path: ''; sound_id: -1; ),
    (name: 'FIR1ATT';  path: ''; sound_id: -1; ),
    (name: 'FIR1EXP';  path: ''; sound_id: -1; ),
    (name: 'FISHATT';  path: ''; sound_id: -1; ),
    (name: 'FISHDTH';  path: ''; sound_id: -1; ),
    (name: 'FISHHURT'; path: ''; sound_id: -1; ),
    (name: 'FISTEXP';  path: ''; sound_id: -1; ),
    (name: 'FISTSHT';  path: ''; sound_id: -1; ),
    (name: 'GLASEXP';  path: ''; sound_id: -1; ),
    (name: 'GUN1SHT';  path: ''; sound_id: -1; ),
    (name: 'GUN2ACT';  path: ''; sound_id: -1; ),
    (name: 'GUN2SHT';  path: ''; sound_id: -1; ),
    (name: 'GUN3EXP';  path: ''; sound_id: -1; ),
    (name: 'GUN5EXP';  path: ''; sound_id: -1; ),
    (name: 'GUN6SHT';  path: ''; sound_id: -1; ),
    (name: 'GUN7SHT';  path: ''; sound_id: -1; ),
    (name: 'GUN8SHT';  path: ''; sound_id: -1; ),
    (name: 'ITEMUP';   path: ''; sound_id: -1; ),
    (name: 'LAKEACT';  path: ''; sound_id: -1; ),
    (name: 'LAKEAPP';  path: ''; sound_id: -1; ),
    (name: 'LAKEATT';  path: ''; sound_id: -1; ),
    (name: 'LAKEDTH';  path: ''; sound_id: -1; ),
    (name: 'LAKEHURT'; path: ''; sound_id: -1; ),
    (name: 'MEC1ACT';  path: ''; sound_id: -1; ),
    (name: 'MEC2ACT';  path: ''; sound_id: -1; ),
    (name: 'MECHAPP';  path: ''; sound_id: -1; ),
    (name: 'MECHATT';  path: ''; sound_id: -1; ),
    (name: 'MECHDTH';  path: ''; sound_id: -1; ),
    (name: 'MECHHURT'; path: ''; sound_id: -1; ),
    (name: 'MECXDTH';  path: ''; sound_id: -1; ),
    (name: 'MIS1ACT';  path: ''; sound_id: -1; ),
    (name: 'MIS1EXP';  path: ''; sound_id: -1; ),
    (name: 'MIS1SHT';  path: ''; sound_id: -1; ),
    (name: 'MONSDTH';  path: ''; sound_id: -1; ),
    (name: 'MOS1DTH';  path: ''; sound_id: -1; ),
    (name: 'MOUSAPP';  path: ''; sound_id: -1; ),
    (name: 'MOUSATT';  path: ''; sound_id: -1; ),
    (name: 'MOUSDTH';  path: ''; sound_id: -1; ),
    (name: 'MOUSHURT'; path: ''; sound_id: -1; ),
    (name: 'ROLEDTH';  path: ''; sound_id: -1; ),
    (name: 'ROLEHURT'; path: ''; sound_id: -1; ),
    (name: 'SRAGATT';  path: ''; sound_id: -1; ),
    (name: 'SWON';     path: ''; sound_id: -1; ),
    (name: 'TELEPORT'; path: ''; sound_id: -1; ),
    (name: 'WATERIN';  path: ''; sound_id: -1; ),
    (name: 'WATERIN1'; path: ''; sound_id: -1; )
  );

procedure MARS_InitSounds;

function MARS_StartSound(origin: pointer; const soundid: marssound_t): boolean;

function S_AmbientSound(const x, y: integer; const sndname: string): Pmobj_t;

function MARS_AmbientSound(const x, y: integer; const soundid: marssound_t): Pmobj_t;

implementation

uses
  d_delphi,
  mars_files,
  sounds,
  s_sound,
  w_wad;

procedure MARS_InitSounds;
var
  i: integer;
begin
  for i := 0 to Ord(NUM_MARS_SOUNDS) - 1 do
  begin
    marssounds[i].path := MARS_FindFile(marssounds[i].name + '.WAV');
    marssounds[i].sound_id := S_GetSoundNumForName(marssounds[i].name);
  end;
end;

function MARS_StartSound(origin: pointer; const soundid: marssound_t): boolean;
var
  id, wid: integer;
begin
  id := Ord(soundid);
  if not IsIntegerInRange(id, 0, Ord(NUM_MARS_SOUNDS) - 1) then
  begin
    Result := False;
    Exit;
  end;

  if marssounds[id].sound_id > 0 then
  begin
    S_StartSound(origin, marssounds[id].sound_id);
    Result := True;
    Exit;
  end;

  wid := S_GetSoundNumForName(marssounds[id].name);

  Result := wid > 0;

  if Result then
  begin
    marssounds[id].sound_id := wid; // JVAL: 20211103 - Remember sound
    S_StartSound(origin, wid);
  end;
end;

var
  MT_AMBIENTSOUND: integer = -2;

const
  STR_AMBIENTSOUND = 'MT_AMBIENTSOUND';

function S_AmbientSound(const x, y: integer; const sndname: string): Pmobj_t;
begin
  if MT_AMBIENTSOUND = -2 then
    MT_AMBIENTSOUND := Info_GetMobjNumForName(STR_AMBIENTSOUND);

  if MT_AMBIENTSOUND < 0  then
  begin
    result := nil;
    exit;
  end;

  result := P_SpawnMobj(x, y, ONFLOATZ, MT_AMBIENTSOUND);
  S_StartSound(result, sndname);
end;

function MARS_AmbientSound(const x, y: integer; const soundid: marssound_t): Pmobj_t;
begin
  if MT_AMBIENTSOUND = -2 then
    MT_AMBIENTSOUND := Info_GetMobjNumForName(STR_AMBIENTSOUND);

  if MT_AMBIENTSOUND < 0  then
  begin
    result := nil;
    exit;
  end;

  result := P_SpawnMobj(x, y, ONFLOATZ, MT_AMBIENTSOUND);
  MARS_StartSound(result, soundid);
end;

end.
