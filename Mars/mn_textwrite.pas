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
//  Ceiling aninmation (lowering, crushing, raising)
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/mars3d/
//------------------------------------------------------------------------------

{$I Mars3D.inc}

unit mn_textwrite;

interface

uses
  r_defs;

type
  menupos_t = record
    x, y: integer;
  end;

function M_SmallStringWidth(const str: string): integer;

function M_SmallStringHeight(const str: string): integer;

function M_WriteSmallText(x, y: integer; const str: string; const scn: integer): menupos_t;

function M_WriteSmallTextCenter(y: integer; const str: string; const scn: integer): menupos_t;

function M_WriteSmallWhiteText(x, y: integer; const str: string; const scn: integer): menupos_t;

function M_WriteSmallWhiteTextCenter(y: integer; const str: string; const scn: integer): menupos_t;

function M_WriteSmallWhiteTextCenterNarrow(y: integer; const str: string; const scn: integer): menupos_t;

function M_BigStringWidth(const str: string; const font_array: Ppatch_tPArray): integer;

function M_WriteBigText(x, y: integer; const font_array: Ppatch_tPArray; const str: string; const scn: integer): menupos_t;

function M_WriteBigTextCenter(y: integer; const font_array: Ppatch_tPArray; const str: string; const scn: integer): menupos_t;

function M_WriteBigTextRed(x, y: integer; const str: string; const scn: integer): menupos_t;

function M_WriteBigTextRedCenter(y: integer; const str: string; const scn: integer): menupos_t;

function M_WriteBigTextGray(x, y: integer; const str: string; const scn: integer): menupos_t;

function M_WriteBigTextGrayCenter(y: integer; const str: string; const scn: integer): menupos_t;

function M_WriteBigTextOrange(x, y: integer; const str: string; const scn: integer): menupos_t;

function M_WriteBigTextOrangeCenter(y: integer; const str: string; const scn: integer): menupos_t;

implementation

uses
  d_delphi,
  hu_stuff,
  v_data,
  v_video,
  w_wad,
  z_zone;

//
// Find string width from small_font chars
//
function M_SmallStringWidth(const str: string): integer;
var
  i: integer;
  c: integer;
begin
  result := 0;
  for i := 1 to Length(str) do
  begin
    c := Ord(toupper(str[i])) - Ord(DOS_FONTSTART);
    if (c < 0) or (c >= DOS_FONTSIZE) then
      result := result + 4
    else
      result := result + small_fontA[c].width;
  end;
end;

function M_SmallStringWidthNarrow(const str: string): integer;
var
  i: integer;
  c: integer;
begin
  result := 0;
  for i := 1 to Length(str) do
  begin
    c := Ord(toupper(str[i])) - Ord(DOS_FONTSTART);
    if (c < 0) or (c >= DOS_FONTSIZE) then
      result := result + 3
    else
      result := result + small_fontA[c].width;
  end;
end;

//
// Find string height from small_font chars
//
function M_SmallStringHeight(const str: string): integer;
var
  i: integer;
  height: integer;
begin
  height := small_fontA[0].height;

  result := height;
  for i := 1 to Length(str) do
    if str[i] = #10 then
      result := result + height;
end;

//
// Write a string using the small_font
//
function M_WriteSmallText(x, y: integer; const str: string; const scn: integer): menupos_t;
var
  w: integer;
  ch: integer;
  c: integer;
  cx: integer;
  cy: integer;
  len: integer;
begin
  len := Length(str);
  if len = 0 then
  begin
    result.x := x;
    result.y := y;
    exit;
  end;

  ch := 1;
  cx := x;
  cy := y;

  while true do
  begin
    if ch > len then
      break;

    c := Ord(str[ch]);
    inc(ch);

    if c = 0 then
      break;

    if c = 10 then
    begin
      cx := x;
      continue;
    end;

    if c = 13 then
    begin
      cy := cy + 12;
      continue;
    end;

    c := Ord(toupper(Chr(c))) - Ord(DOS_FONTSTART);
    if (c < 0) or (c >= DOS_FONTSIZE) then
    begin
      cx := cx + 4;
      continue;
    end;

    w := small_fontA[c].width;
    if (cx + w) > 320 then
      break;
    V_DrawPatch(cx, cy, scn, small_fontA[c], false);
    cx := cx + w;
  end;

  result.x := cx;
  result.y := cy;
end;

function M_WriteSmallTextCenter(y: integer; const str: string; const scn: integer): menupos_t;
var
  i, x, w: integer;
  lst: TDStringList;
begin
  lst := TDStringList.Create;
  lst.Text := str;
  for i := 0 to lst.Count - 1 do
  begin
    w := M_SmallStringWidth(lst.Strings[i]);
    x := (320 - w) div 2;
    M_WriteSmallText(x, y, lst.Strings[i], scn);
    y := y + 14;
  end;
  lst.Free;
end;

function M_WriteSmallWhiteText(x, y: integer; const str: string; const scn: integer): menupos_t;
var
  w: integer;
  ch: integer;
  c: integer;
  cx: integer;
  cy: integer;
  len: integer;
begin
  len := Length(str);
  if len = 0 then
  begin
    result.x := x;
    result.y := y;
    exit;
  end;

  ch := 1;
  cx := x;
  cy := y;

  while true do
  begin
    if ch > len then
      break;

    c := Ord(str[ch]);
    inc(ch);

    if c = 0 then
      break;

    if c = 10 then
    begin
      cx := x;
      continue;
    end;

    if c = 13 then
    begin
      cy := cy + 12;
      continue;
    end;

    c := Ord(toupper(Chr(c))) - Ord(DOS_FONTSTART);
    if (c < 0) or (c >= DOS_FONTSIZE) then
    begin
      cx := cx + 4;
      continue;
    end;

    w := small_fontB[c].width;
    if (cx + w) > 320 then
      break;
    V_DrawPatch(cx, cy, scn, small_fontB[c], false);
    cx := cx + w;
  end;

  result.x := cx;
  result.y := cy;
end;

function M_WriteSmallWhiteTextNarrow(x, y: integer; const str: string; const scn: integer): menupos_t;
var
  w: integer;
  ch: integer;
  c: integer;
  cx: integer;
  cy: integer;
  len: integer;
begin
  len := Length(str);
  if len = 0 then
  begin
    result.x := x;
    result.y := y;
    exit;
  end;

  ch := 1;
  cx := x;
  cy := y;

  while true do
  begin
    if ch > len then
      break;

    c := Ord(str[ch]);
    inc(ch);

    if c = 0 then
      break;

    if c = 10 then
    begin
      cx := x;
      continue;
    end;

    if c = 13 then
    begin
      cy := cy + 12;
      continue;
    end;

    c := Ord(toupper(Chr(c))) - Ord(DOS_FONTSTART);
    if (c < 0) or (c >= DOS_FONTSIZE) then
    begin
      cx := cx + 3;
      continue;
    end;

    w := small_fontB[c].width;
    if (cx + w) > 320 then
      break;
    V_DrawPatch(cx, cy, scn, small_fontB[c], false);
    cx := cx + w;
  end;

  result.x := cx;
  result.y := cy;
end;

function M_WriteSmallWhiteTextCenter(y: integer; const str: string; const scn: integer): menupos_t;
var
  i, x, w: integer;
  lst: TDStringList;
begin
  lst := TDStringList.Create;
  lst.Text := str;
  for i := 0 to lst.Count - 1 do
  begin
    w := M_SmallStringWidth(lst.Strings[i]);
    x := (320 - w) div 2;
    M_WriteSmallWhiteText(x, y, lst.Strings[i], scn);
    y := y + 14;
  end;
  lst.Free;
end;

function M_WriteSmallWhiteTextCenterNarrow(y: integer; const str: string; const scn: integer): menupos_t;
var
  i, x, w: integer;
  lst: TDStringList;
begin
  lst := TDStringList.Create;
  lst.Text := str;
  for i := 0 to lst.Count - 1 do
  begin
    w := M_SmallStringWidthNarrow(lst.Strings[i]);
    x := (320 - w) div 2;
    M_WriteSmallWhiteTextNarrow(x, y, lst.Strings[i], scn);
    y := y + 14;
  end;
  lst.Free;
end;

//
// Write a string using the big_fontX
//
function M_BigStringWidth(const str: string; const font_array: Ppatch_tPArray): integer;
var
  i: integer;
  c: integer;
begin
  result := 0;
  for i := 1 to Length(str) do
  begin
    c := Ord(toupper(str[i])) - Ord(BIG_FONTSTART);
    if (c < 0) or (c >= BIG_FONTSIZE) then
      result := result + 4
    else
      result := result + font_array[c].width;
  end;
end;

function M_WriteBigText(x, y: integer; const font_array: Ppatch_tPArray; const str: string; const scn: integer): menupos_t;
var
  w: integer;
  ch: integer;
  c: integer;
  cx: integer;
  cy: integer;
  len: integer;
begin
  len := Length(str);
  if len = 0 then
  begin
    result.x := x;
    result.y := y;
    exit;
  end;

  ch := 1;
  cx := x;
  cy := y;

  while true do
  begin
    if ch > len then
      break;

    c := Ord(str[ch]);
    inc(ch);

    if c = 0 then
      break;

    if c = 10 then
    begin
      cx := x;
      continue;
    end;

    if c = 13 then
    begin
      cy := cy + 14;
      continue;
    end;

    c := Ord(toupper(Chr(c))) - Ord(BIG_FONTSTART);
    if (c < 0) or (c >= BIG_FONTSIZE) then
    begin
      cx := cx + 4;
      continue;
    end;

    w := font_array[c].width;
    if (cx + w) > 320 then
      break;
    V_DrawPatch(cx, cy, scn, font_array[c], false);
    cx := cx + w;
  end;

  result.x := cx;
  result.y := cy;
end;

function M_WriteBigTextCenter(y: integer; const font_array: Ppatch_tPArray; const str: string; const scn: integer): menupos_t;
var
  i, x, w: integer;
  lst: TDStringList;
begin
  lst := TDStringList.Create;
  lst.Text := str;
  for i := 0 to lst.Count - 1 do
  begin
    w := M_BigStringWidth(lst.Strings[i], font_array);
    x := (320 - w) div 2;
    M_WriteBigText(x, y, font_array, lst.Strings[i], scn);
    y := y + 14;
  end;
  lst.Free;
end;

function M_WriteBigTextRed(x, y: integer; const str: string; const scn: integer): menupos_t;
begin
  result := M_WriteBigText(x, y, @big_fontA, str, scn);
end;

function M_WriteBigTextRedCenter(y: integer; const str: string; const scn: integer): menupos_t;
begin
  result := M_WriteBigTextCenter(y, @big_fontA, str, scn);
end;

function M_WriteBigTextGray(x, y: integer; const str: string; const scn: integer): menupos_t;
begin
  result := M_WriteBigText(x, y, @big_fontB, str, scn);
end;

function M_WriteBigTextGrayCenter(y: integer; const str: string; const scn: integer): menupos_t;
begin
  result := M_WriteBigTextCenter(y, @big_fontB, str, scn);
end;

function M_WriteBigTextOrange(x, y: integer; const str: string; const scn: integer): menupos_t;
begin
  result := M_WriteBigText(x, y, @big_fontC, str, scn);
end;

function M_WriteBigTextOrangeCenter(y: integer; const str: string; const scn: integer): menupos_t;
begin
  result := M_WriteBigTextCenter(y, @big_fontC, str, scn);
end;


end.
 
