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
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/mars3d/
//------------------------------------------------------------------------------

{$I Mars3D.inc}

unit r_span32_ripple;

interface

//==============================================================================
//
// R_DrawSpanNormal_Ripple
//
//==============================================================================
procedure R_DrawSpanNormal_Ripple;

implementation

uses
  d_delphi,
  m_fixed,
  r_precalc,
  r_ripple,
  r_flatinfo,
  r_span,
  r_span32,
  r_draw;

//==============================================================================
//
// R_DrawSpanNormal_Ripple
//
//==============================================================================
procedure R_DrawSpanNormal_Ripple;
var
  xfrac: fixed_t;
  yfrac: fixed_t;
  xstep: fixed_t;
  ystep: fixed_t;
  destl: PLongWord;
  count: integer;
  i: integer;
  spot: integer;

  r1, g1, b1: byte;
  c: LongWord;
  lfactor: integer;
  bf_r: PIntegerArray;
  bf_g: PIntegerArray;
  bf_b: PIntegerArray;
  rpl: PIntegerArray;
begin
  destl := @((ylookupl[ds_y]^)[columnofs[ds_x1]]);

  // We do not check for zero spans here?
  count := ds_x2 - ds_x1;
  if count < 0 then
    exit;

  rpl := ds_ripple;
  lfactor := ds_lightlevel;
  if lfactor >= 0 then // Use hi detail lightlevel
  begin
    R_GetPrecalc32Tables(lfactor, bf_r, bf_g, bf_b, ds_fog);  // JVAL: Mars fog sectors
    {$DEFINE RIPPLE}
    {$UNDEF INVERSECOLORMAPS}
    {$UNDEF TRANSPARENTFLAT}
    {$I R_DrawSpanNormal.inc}
  end
  else // Use inversecolormap
  begin
    {$DEFINE RIPPLE}
    {$DEFINE INVERSECOLORMAPS}
    {$UNDEF TRANSPARENTFLAT}
    {$I R_DrawSpanNormal.inc}
  end;
end;

end.

