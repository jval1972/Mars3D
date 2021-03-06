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
// DESCRIPTION
//  Detect known data files
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/mars3d/
//------------------------------------------------------------------------------

{$I Mars3D.inc}

unit mars_version;

interface

uses
  doomdef,
  doomstat;

var
  mars_crc32: string = '';

type
  marsversion_t = (
    mv10sha_mad_small,
    mv10reg_mad_small,
    mv10reg_mad_big,
    mv10sha_wad,
    mv10reg_wad,
    mv20reg_wad,
    mvunknown
  );

var
  marsversion: marsversion_t = mvunknown;

type
  marsversioninfo_t = record
    version: marsversion_t;
    fastcrc32: string[8];
    gamemode: GameMode_t;
    savepath: string[8];
    language: Language_t;
    versionstring: string[36];
  end;

const
  NUM_MARS_VERSION_INFO = 6;

const
  marsversioninfo: array[0..NUM_MARS_VERSION_INFO - 1] of marsversioninfo_t = (
    (version: mv10sha_mad_small; fastcrc32: 'c0314f5a'; gamemode: shareware;  savepath: 'MARS_SK';  language: chinese;  versionstring: 'Mars v1.0 Shareware (CHINESE)'),
    (version: mv10reg_mad_small; fastcrc32: 'ec408aef'; gamemode: registered; savepath: 'MARS_RK';  language: chinese;  versionstring: 'Mars v1.0 Registered (CHINESE)'),
    (version: mv10reg_mad_big;   fastcrc32: 'dc2ec8ad'; gamemode: registered; savepath: 'MARS_RKB'; language: chinese;  versionstring: 'Mars v1.0 Registered (CHINESE) (BIG)'),
    (version: mv10sha_wad;       fastcrc32: 'e1438da7'; gamemode: shareware;  savepath: 'MARS_SKW'; language: chinese;  versionstring: 'Mars v1.0 Shareware (CHINESE) (WAD)'),
    (version: mv10reg_wad;       fastcrc32: '486fa896'; gamemode: registered; savepath: 'MARS_RKW'; language: chinese;  versionstring: 'Mars v1.0 Registered (CHINESE) (WAD)'),
    (version: mv20reg_wad;       fastcrc32: '8075888a'; gamemode: registered; savepath: 'MARS_REW'; language: english; versionstring: 'Mars v1.0 Registered (ENGLISH) (WAD)')
  );

//==============================================================================
//
// MARS_GameModeFromCrc32
//
//==============================================================================
function MARS_GameModeFromCrc32(const crc: string): Gamemode_t;

//==============================================================================
//
// MARS_MADVersionFromCrc32
//
//==============================================================================
function MARS_MADVersionFromCrc32(const crc: string): marsversion_t;

//==============================================================================
//
// MARS_VersionStringFromCrc32
//
//==============================================================================
function MARS_VersionStringFromCrc32(const crc: string): string;

//==============================================================================
//
// MARS_CheckUnknownWad
//
//==============================================================================
function MARS_CheckUnknownWad(const filename: string): boolean;

//==============================================================================
//
// MARS_GetSavePath
//
//==============================================================================
function MARS_GetSavePath: string;

const
  MARS_MAX_EPISODES = 3;

var
  num_episode_maps: array[1..MARS_MAX_EPISODES] of integer;

//==============================================================================
//
// MARS_CheckEpisodeMaps
//
//==============================================================================
procedure MARS_CheckEpisodeMaps;

implementation

uses
  d_delphi,
  m_argv,
  w_wad,
  w_wadreader;

var
  savepath: string = 'MARS';

//==============================================================================
//
// MARS_GameModeFromCrc32
//
//==============================================================================
function MARS_GameModeFromCrc32(const crc: string): Gamemode_t;
var
  i: integer;
begin
  for i := 0 to NUM_MARS_VERSION_INFO - 1 do
  begin
    if strupper(crc) = strupper(marsversioninfo[i].fastcrc32) then
    begin
      result := marsversioninfo[i].gamemode;
      savepath := marsversioninfo[i].savepath;
      language := marsversioninfo[i].language;
      exit;
    end;
  end;
  result := indetermined;
end;

//==============================================================================
//
// MARS_MADVersionFromCrc32
//
//==============================================================================
function MARS_MADVersionFromCrc32(const crc: string): marsversion_t;
var
  i: integer;
begin
  for i := 0 to NUM_MARS_VERSION_INFO - 1 do
  begin
    if strupper(crc) = strupper(marsversioninfo[i].fastcrc32) then
    begin
      result := marsversioninfo[i].version;
      savepath := marsversioninfo[i].savepath;
      language := marsversioninfo[i].language;
      exit;
    end;
  end;
  savepath := 'MARS_' + crc;
  result := mvunknown;
end;

//==============================================================================
//
// MARS_VersionStringFromCrc32
//
//==============================================================================
function MARS_VersionStringFromCrc32(const crc: string): string;
var
  i: integer;
begin
  for i := 0 to NUM_MARS_VERSION_INFO - 1 do
  begin
    if strupper(crc) = strupper(marsversioninfo[i].fastcrc32) then
    begin
      result := marsversioninfo[i].versionstring;
      savepath := marsversioninfo[i].savepath;
      exit;
    end;
  end;
  savepath := 'MARS_' + crc;
  result := 'Game mode indeterminate';
end;

//==============================================================================
//
// MARS_CheckUnknownWad
//
//==============================================================================
function MARS_CheckUnknownWad(const filename: string): boolean;
const
  sNUMS = '0123456789';
var
  numlumps: integer;
  nummaps1, nummaps2: integer;
  name, s: string;
  crc: string;
  wad: TWadReader;
  i: integer;
begin
  crc := W_WadFastCrc32(filename);

  wad := TWadReader.Create;
  wad.OpenWadFile(filename);
  numlumps := wad.NumEntries;

  splitstring_ch(fname(filename), name, s, '.');
  nummaps1 := 0;
  nummaps2 := 0;

  for i := 0 to numlumps - 1 do
  begin
    s := strupper(wad.EntryName(i));
    if Length(s) = 4 then
    begin
      if s[1] = 'E' then
        if s[3] = 'M' then
          if Pos(s[2], sNUMS) > 0 then
            if Pos(s[4], sNUMS) > 0 then
              inc(nummaps1);
    end
    else if Length(s) = 5 then
    begin
      if s[1] = 'M' then
        if s[2] = 'A' then
          if s[3] = 'P' then
            if Pos(s[4], sNUMS) > 0 then
              if Pos(s[5], sNUMS) > 0 then
                inc(nummaps2);
    end
  end;
  wad.Free;

  result := nummaps1 + nummaps2 > 0;
  if result then
    savepath := name + '_' + crc;
end;

//==============================================================================
//
// MARS_GetSavePath
//
//==============================================================================
function MARS_GetSavePath: string;
var
  s: string;
begin
  s := 'DATA';
  MkDir(M_SaveFileName(s));
  s := s + '\SAVES';
  MkDir(M_SaveFileName(s));
  s := s + '\' + savepath;
  MkDir(M_SaveFileName(s));
  result := 'DATA\SAVES\' + savepath + '\';
end;

//==============================================================================
//
// MARS_CheckEpisodeMaps
//
//==============================================================================
procedure MARS_CheckEpisodeMaps;
var
  epi, mp: integer;
begin
  for epi := 1 to MARS_MAX_EPISODES do
    for mp := 1 to 9 do
    begin
      if W_CheckNumForName('E' + itoa(epi) + 'M' + itoa(mp)) >= 0 then
        num_episode_maps[epi] := mp
      else
        break;
    end;
end;

end.

