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
// DESCRIPTION:
//  ANMINFO lump
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/mars3d/
//------------------------------------------------------------------------------

{$I Mars3D.inc}

unit anm_info;

interface

type
  anminfo_t = record
    name: string[64];
    maxframe: integer;
    repeatframe: integer;
    tic: integer;
  end;
  Panminfo_t = ^anminfo_t;
  anminfo_tArray = array[0..$FF] of anminfo_t;
  Panminfo_tArray = ^anminfo_tArray;

procedure ANM_InfoInit;

procedure ANM_InfoShutDown;

function ANM_GetInfo(const anmfile: string): anminfo_t;

implementation

uses
  d_delphi,
  sc_engine,
  sc_utils,
  w_pak,
  w_wad;

const
  ANMINFOLUMPNAME = 'ANMINFO';

var
  anminfo: Panminfo_tArray;
  numanminfo: integer;

procedure ANM_ClearItemInfo(const inf: Panminfo_t);
begin
  inf.name := '';
  inf.maxframe := -1;
  inf.repeatframe := -1;
  inf.tic := 1;
end;

procedure ANM_AddInfo(const inf: Panminfo_t);
var
  i: integer;
  check: string;
begin
  check := strupper(inf.name);
  if check = '' then
    Exit;

  i := 0;
  while i < numanminfo do
  begin
    if check = anminfo[i].name then
      Break;
    Inc(i);
  end;

  if i = numanminfo then
  begin
    realloc(pointer(anminfo), numanminfo * SizeOf(anminfo_t), (numanminfo + 1) * SizeOf(anminfo_t));
    Inc(numanminfo);
  end;

  anminfo[i] := inf^;
end;

procedure ANM_DoParseText(const in_text: string);
var
  sc: TScriptEngine;
  inf: anminfo_t;
begin
  sc := TScriptEngine.Create(in_text);

  ANM_ClearItemInfo(@inf);
  while sc.GetString do
  begin
    if sc.MatchString('ANIMFILE') then
    begin
      ANM_AddInfo(@inf);
      ANM_ClearItemInfo(@inf);
      sc.MustGetString;
      inf.name := sc._String;
      while sc.GetString do
      begin
        if sc.MatchString('MAXFRAME') then
        begin
          sc.MustGetInteger;
          inf.maxframe := sc._Integer;
        end
        else if sc.MatchString('REPEATFRAME') then
        begin
          sc.MustGetInteger;
          inf.repeatframe := sc._Integer;
        end
        else if sc.MatchString('TIC') then
        begin
          sc.MustGetInteger;
          inf.tic := sc._Integer;
        end
        else if sc.MatchString('ANIMFILE') then
        begin
          sc.UnGet;
          Break;
        end;
      end;
    end;
  end;
  ANM_AddInfo(@inf); // Add any pending item
  sc.Free;
end;

procedure ANM_ParseText(const in_text: string);
begin
  ANM_DoParseText(SC_Preprocess(in_text, false));
end;

procedure ANM_InfoInit;
var
  i: integer;
begin
  anminfo := nil;
  numanminfo := 0;

  for i := 0 to W_NumLumps - 1 do
    if char8tostring(W_GetNameForNum(i)) = ANMINFOLUMPNAME then
      ANM_ParseText(W_TextLumpNum(i));


  PAK_StringIterator(ANMINFOLUMPNAME, ANM_ParseText);
  PAK_StringIterator(ANMINFOLUMPNAME + '.txt', ANM_ParseText);
end;

procedure ANM_InfoShutDown;
begin
  if numanminfo > 0 then
  begin
    memfree(pointer(anminfo), numanminfo * SizeOf(anminfo_t));
    numanminfo := 0;
  end;
end;

function ANM_GetInfo(const anmfile: string): anminfo_t;
var
  i: integer;
  check: string;
begin
  check := strupper(fname(anmfile));
  for i := 0 to numanminfo - 1 do
    if check = anminfo[i].name then
    begin
      Result := anminfo[i];
      Exit;
    end;

  // Not found
  ANM_ClearItemInfo(@Result);
end;

end.
