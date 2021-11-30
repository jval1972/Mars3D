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
//  Info searching
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/mars3d/
//------------------------------------------------------------------------------

{$I Mars3D.inc}

unit info_fnd;

interface

uses
  d_delphi;

function Info_FindStatesFromSprite(const sp: string): TDNumberList;

implementation

uses
  info,
  p_pspr;

function Info_FindStatesFromSprite(const sp: string): TDNumberList;
var
  spr: string;
  spr_idx: integer;
  frm: integer;
  i: integer;
  sp_idx: integer;
begin
  result := TDNumberList.Create;

  if length(sp) = 4 then
  begin
    spr := strupper(sp);
    spr_idx := Ord(spr[1]) +
               Ord(spr[2]) shl 8 +
               Ord(spr[3]) shl 16 +
               Ord(spr[4]) shl 24;

    sp_idx := -1;
    for i := 0 to numsprites - 1 do
      if sprnames[i] = spr_idx then
      begin
        sp_idx := i;
        break;
      end;
    if sp_idx = -1 then
      exit;

    for i := 0 to numstates - 1 do
    begin
      if states[i].sprite = sp_idx then
        result.Add(i)
    end;

    exit;
  end;

  if length(sp) = 5 then
  begin
    spr := strupper(sp[1] + sp[2] + sp[3] + sp[4]);
    spr_idx := Ord(spr[1]) +
               Ord(spr[2]) shl 8 +
               Ord(spr[3]) shl 16 +
               Ord(spr[4]) shl 24;

    sp_idx := -1;
    for i := 0 to numsprites - 1 do
      if sprnames[i] = spr_idx then
      begin
        sp_idx := i;
        break;
      end;
    if sp_idx = -1 then
      exit;

    frm := Ord(toupper(sp[5])) - Ord('A');

    for i := 0 to numstates - 1 do
    begin
      if states[i].sprite = sp_idx then
        if states[i].frame and FF_FRAMEMASK = frm then
          result.Add(i)
    end;

    exit;
  end;


end;


end.
