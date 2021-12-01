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
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/mars3d/
//------------------------------------------------------------------------------

{$I Mars3D.inc}

unit r_col_l;

interface

// Light column drawing functions
procedure R_DrawWhiteLightColumnHi;
procedure R_DrawRedLightColumnHi;
procedure R_DrawGreenLightColumnHi;
procedure R_DrawBlueLightColumnHi;
procedure R_DrawYellowLightColumnHi;

implementation

uses
  d_delphi,
  doomdef,
  m_fixed,
  r_draw,
  r_main,
  r_column;

procedure R_DrawWhiteLightColumnHi;
{$DEFINE WHITE}
{$I R_DrawLightColumnHi.inc}
{$UNDEF WHITE}

procedure R_DrawRedLightColumnHi;
{$DEFINE RED}
{$I R_DrawLightColumnHi.inc}
{$UNDEF RED}

procedure R_DrawGreenLightColumnHi;
{$DEFINE GREEN}
{$I R_DrawLightColumnHi.inc}
{$UNDEF GREEN}

procedure R_DrawBlueLightColumnHi;
{$DEFINE BLUE}
{$I R_DrawLightColumnHi.inc}
{$UNDEF BLUE}

procedure R_DrawYellowLightColumnHi;
{$DEFINE YELLOW}
{$I R_DrawLightColumnHi.inc}
{$UNDEF YELLOW}

end.
