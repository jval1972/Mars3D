//------------------------------------------------------------------------------
//
//  DelphiHexen: A modified and improved Hexen port for Windows
//  based on original Linux Doom as published by "id Software", on
//  Hexen source as published by "Raven" software and DelphiDoom
//  as published by Jim Valavanis.
//  Copyright (C) 2004-2008 by Jim Valavanis
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
//  E-Mail: jimmyvalavanis@yahoo.gr
//  Site  : http://delphidoom.sitesled.com/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit r_span32_fog;

interface

procedure R_DrawSpanNormal_Fog;

implementation
{$DEFINE FOG}

uses
  d_delphi,
  m_fixed,
  r_span, r_span32, r_draw, r_hires, r_grow,
  v_video;

//
// Draws the actual span (Normal resolution).
//
procedure R_DrawSpanNormal_Fog;
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
  c, c1, r, g, b: LongWord;
  lfactor: integer;
  fog_color: fixed_t;
begin
  destl := @((ylookupl[ds_y]^)[columnofs[ds_x1]]);

  // We do not check for zero spans here?
  count := ds_x2 - ds_x1;

  lfactor := ds_lightlevel;
  if lfactor >= 0 then // Use hi detail lightlevel
  begin
//    fog_color := (FRACUNIT - lfactor) * 255;
    fog_color := (50000 - lfactor) * 255;
    if fog_color < 0 then
      fog_color := 0;
    {$UNDEF INVERSECOLORMAPS}
    {$UNDEF TRANSPARENTFLAT}
    {$I R_DrawSpanNormal.inc}
  end
  else // Use inversecolormap
  begin
    {$DEFINE INVERSECOLORMAPS}
    {$UNDEF TRANSPARENTFLAT}
    {$I R_DrawSpanNormal.inc}
  end;
end;

end.

