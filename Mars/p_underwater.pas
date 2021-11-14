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
//   Underwater logic
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/mars3d/
//------------------------------------------------------------------------------

{$I Mars3D.inc}

unit p_underwater;

interface

procedure P_SetupUnderwaterSectors;

const
  UNDERWATER_COLORMAP = 'WATERMAP';

var
  cm_underwater: integer = -1;

const
  U_INTERVAL_FACTOR = 3;
  U_DISP_STRENGTH_PCT = 2; // SOS: For value > 2 R_UnderwaterCalcX & R_UnderwaterCalcY will overflow in 4k unless we use floating point

implementation

uses
  p_setup,
  r_defs;

procedure P_RecursiveUnderwaterSector(const sec: Psector_t);
var
  i: integer;
  line: Pline_t;
begin
  if sec.renderflags and SRF_UNDERWATER <> 0 then
    Exit;
  sec.renderflags := sec.renderflags or SRF_UNDERWATER;
  sec.gravity := 0;
  for i := 0 to sec.linecount - 1 do
  begin
    line := sec.lines[i];
    if line.frontsector <> nil then
      if line.frontsector <> sec then
        P_RecursiveUnderwaterSector(line.frontsector);
    if line.backsector <> nil then
      if line.backsector <> sec then
        P_RecursiveUnderwaterSector(line.backsector);
  end;
end;

procedure P_SetupUnderwaterSectors;
var
  i: integer;
  sec: Psector_t;
begin
  sec := @sectors[0];
  for i := 0 to numsectors - 1 do
  begin
    if sec.special = 10 then
      P_RecursiveUnderwaterSector(sec);
    Inc(sec);
  end;
end;

end.
