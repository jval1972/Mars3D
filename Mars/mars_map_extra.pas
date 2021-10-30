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
//  Special Map handling for Mars3D.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/mars3d/
//------------------------------------------------------------------------------

{$I Mars3D.inc}

unit mars_map_extra;

interface

uses
  p_mobj_h,
  r_defs;

procedure P_WallBounceMobj(const mo: Pmobj_t; const line: Pline_t);

procedure P_MobjBounceMobj(const mo: Pmobj_t; const othermo: Pmobj_t);

implementation

uses
  m_fixed,
  m_vectors,
  r_main;

procedure P_WallBounceMobj(const mo: Pmobj_t; const line: Pline_t);
var
  d, wall, reflect: vec2_t;
begin
  d[0] := mo.momx / FRACUNIT;
  d[1] := mo.momy / FRACUNIT;
  wall[0] := line.dx / FRACUNIT;
  wall[1] := line.dy / FRACUNIT;
  CalculateReflect2(d, wall, reflect);
  mo.momx := Round(reflect[0] * FRACUNIT);
  mo.momy := Round(reflect[1] * FRACUNIT);
  mo.angle := R_PointToAngle(mo.momx, mo.momy);
end;

procedure P_MobjBounceMobj(const mo: Pmobj_t; const othermo: Pmobj_t);
var
  d, wall, reflect: vec2_t;
begin
  d[0] := mo.momx / FRACUNIT;
  d[1] := mo.momy / FRACUNIT;
  wall[0] := -othermo.y / FRACUNIT;
  wall[1] := othermo.x / FRACUNIT;
  CalculateReflect2(d, wall, reflect);
  mo.momx := Round(reflect[0] * FRACUNIT);
  mo.momy := Round(reflect[1] * FRACUNIT);
  mo.angle := R_PointToAngle(mo.momx, mo.momy);
end;


end.
