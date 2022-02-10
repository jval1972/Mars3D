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
// DESCRIPTION:
//  Clipper utilities for 3d floors & slopes
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/mars3d/
//------------------------------------------------------------------------------

{$I Mars3D.inc}

unit r_cliputils;

interface

uses
  m_fixed,
  r_clipper,
  r_defs;

const
  POINTBITS = 13;
  POINTUNIT = 1 shl POINTBITS;

const
  MAXZ = FRACUNIT * 16384;

//==============================================================================
//
// R_MakeClipperPoint
//
//==============================================================================
function R_MakeClipperPoint(v: Pvertex_t): TIntPoint; overload;

//==============================================================================
//
// R_MakeClipperPoint
//
//==============================================================================
function R_MakeClipperPoint(const x1, y1: fixed_t): TIntPoint; overload;

const
  MAXSUBSECTORPOINTS = 16384;

implementation

uses
  r_main;

//==============================================================================
//
// R_MakeClipperPoint
//
//==============================================================================
function R_MakeClipperPoint(v: Pvertex_t): TIntPoint; overload;
begin
  result.X := (v.x - viewx) div POINTUNIT;
  result.Y := (v.y - viewy) div POINTUNIT;
end;

//==============================================================================
//
// R_MakeClipperPoint
//
//==============================================================================
function R_MakeClipperPoint(const x1, y1: fixed_t): TIntPoint; overload;
begin
  result.X := (x1  - viewx) div POINTUNIT;
  result.Y := (y1  - viewy) div POINTUNIT;
end;

end.
