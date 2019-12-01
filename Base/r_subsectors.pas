//------------------------------------------------------------------------------
//
//  DelphiDoom: A modified and improved DOOM engine for Windows
//  based on original Linux Doom as published by "id Software"
//  Copyright (C) 1993-1996 by id Software, Inc.
//  Copyright (C) 2004-2019 by Jim Valavanis
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
//   Subsector precalc
//
//------------------------------------------------------------------------------
//  Site  : http://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit r_subsectors;

interface

uses
  r_defs,
  m_fixed;

procedure R_PrecalcPointInSubSector;

function R_PointInSubsectorPrecalc(const x: fixed_t; const y: fixed_t): Psubsector_t;

implementation

uses
  d_delphi,
  p_setup,
  r_main,
  z_zone;

//
// R_PrecalcPointInSubSector
//
type
  pointinsubsector_t = array[0..$FFFF] of Psubsector_t;
  pointinsubsector_p = ^pointinsubsector_t;

const
  POINTINSUBSECTORACCURACY = 32 * FRACUNIT;

var
  pointinsubsector: pointinsubsector_p;
  p_in_ss_width: integer;
  p_in_ss_height: integer;
  p_in_ss_minx, p_in_ss_miny, p_in_ss_maxx, p_in_ss_maxy: fixed_t;
  p_in_ss_size: integer = -1;

procedure R_PrecalcPointInSubSector;
var
  i, j: integer;
  pv: Pvertex_t;
  ss1, ss2: Psubsector_t;
  hitcnt: integer;
begin
  printf('R_PrecalcPointInSubSector: Generating matrix.'#13#10);
  pv := @vertexes[0];
  p_in_ss_minx := pv.x;
  p_in_ss_miny := pv.y;
  p_in_ss_maxx := pv.x;
  p_in_ss_maxy := pv.y;
  for i := 1 to numvertexes - 1 do
  begin
    inc(pv);
    if pv.x < p_in_ss_minx then
      p_in_ss_minx := pv.x
    else if pv.x > p_in_ss_maxx then
      p_in_ss_maxx := pv.x;
    if pv.y < p_in_ss_miny then
      p_in_ss_miny := pv.y
    else if pv.y > p_in_ss_maxy then
      p_in_ss_maxy := pv.y;
  end;

  p_in_ss_width := (p_in_ss_maxx - p_in_ss_minx) div POINTINSUBSECTORACCURACY + 1;
  p_in_ss_height := (p_in_ss_maxy - p_in_ss_miny) div POINTINSUBSECTORACCURACY + 1;

  p_in_ss_size := p_in_ss_width * p_in_ss_height;
  pointinsubsector := Z_Malloc(p_in_ss_size * SizeOf(Psubsector_t), PU_LEVEL, nil);
  ZeroMemory(pointinsubsector, p_in_ss_size * SizeOf(Psubsector_t));


  hitcnt := 0;
  for i := 0 to p_in_ss_width - 1 do
    for j := 0 to p_in_ss_height - 1 do
    begin
      ss1 := R_PointInSubSectorClassic(p_in_ss_minx + i * POINTINSUBSECTORACCURACY, p_in_ss_miny + j * POINTINSUBSECTORACCURACY);
      ss2 := R_PointInSubSectorClassic(p_in_ss_minx + i * POINTINSUBSECTORACCURACY + POINTINSUBSECTORACCURACY - 1, p_in_ss_miny + j * POINTINSUBSECTORACCURACY);
      if ss1 = ss2 then
      begin
        ss2 := R_PointInSubSectorClassic(p_in_ss_minx + i * POINTINSUBSECTORACCURACY + POINTINSUBSECTORACCURACY - 1, p_in_ss_miny + j * POINTINSUBSECTORACCURACY + POINTINSUBSECTORACCURACY - 1);
        if ss1 = ss2 then
        begin
          ss2 := R_PointInSubSectorClassic(p_in_ss_minx + i * POINTINSUBSECTORACCURACY, p_in_ss_miny + j * POINTINSUBSECTORACCURACY + POINTINSUBSECTORACCURACY - 1);
          if ss1 = ss2 then
          begin
            pointinsubsector[j * p_in_ss_width + i] := ss2;
            inc(hitcnt);
          end;
        end;
      end;
    end;

  printf('  Hit rate is %2.2f%s (%d/%d)'#13#10,
    [hitcnt / (p_in_ss_width * p_in_ss_height) * 100, '%', hitcnt, p_in_ss_width * p_in_ss_height]);
end;

function R_PointInSubsectorPrecalc(const x: fixed_t; const y: fixed_t): Psubsector_t;
var
  idx: integer;
begin
  idx := ((x - p_in_ss_minx) div POINTINSUBSECTORACCURACY) + p_in_ss_width * ((y - p_in_ss_miny) div POINTINSUBSECTORACCURACY);
  if (idx < 0) or (idx >= p_in_ss_size) then
  begin
    result := nil;
    exit;
  end;
  result := pointinsubsector[idx];
end;

end.