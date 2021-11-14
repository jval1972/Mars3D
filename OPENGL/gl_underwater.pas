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
//  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
// DESCRIPTION:
//  OpenGL Underwater Rendering
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/mars3d/
//------------------------------------------------------------------------------

{$I Mars3D.inc}

unit gl_underwater;

interface

uses
  d_player;

procedure gld_InitUnderwater;

procedure gld_ShutDownUnderwater;

procedure gld_UnderwaterExecute(const p: Pplayer_t);

implementation

uses
  d_delphi,
  dglOpenGL,
  doomdef,
  gl_defs,
  gl_main,
  i_system,
  p_underwater,
  r_colormaps,
  r_draw;

var
  utex: GLUint;

function u_glsize(const value: integer): integer;
begin
  result := 1;
  while result < value do
    result := result * 2;
end;

procedure gld_InitUnderwater;
begin
  cm_underwater := R_CustomColorMapForName(UNDERWATER_COLORMAP);
  if cm_underwater < 0 then
    I_Error('R_InitUnderwater(): Underwater palette not found');
  glGenTextures(1, @utex);
end;

procedure gld_ShutDownUnderwater;
begin
  glDeleteTextures(1, @utex);
end;

const
  UMATRIX_SIZE = 16;

type
  uuv_t = record
    u, v: float;
  end;
  Puuv_t = ^uuv_t;

var
  umatrix: array[0..UMATRIX_SIZE, 0..UMATRIX_SIZE] of uuv_t;

procedure gld_UnderwaterExecute(const p: Pplayer_t);
var
  i, j: integer;
  tic64: int64;
  ftic: float;
  puuv: Puuv_t;
  ufactor: float;
  sines, cosines: array[0..UMATRIX_SIZE] of float;
  f: float;

  procedure _uvert(const x, y: float; const iuv, juv: integer);
  begin
//    glTexCoord2f((viewwindowx + x) / SCREENWIDTH, -(viewwindowy + y) / SCREENHEIGHT);
    glTexCoord2f(umatrix[iuv, juv].u, umatrix[iuv, juv].v);
    glVertex2f(viewwindowx + x, viewwindowy + y);
  end;

begin
  if p.underwatertics = 0 then
    Exit;

  tic64 := p.underwatertics;
  tic64 := tic64 * viewwidth div (LONGTICS_FACTOR * TICRATE * U_INTERVAL_FACTOR);
  tic64 := tic64 mod viewwidth;
  ftic := tic64 / viewwidth;
  ufactor := U_DISP_STRENGTH_PCT / 100;

  for i := 0 to UMATRIX_SIZE do
  begin
    f := (ftic + i / UMATRIX_SIZE) * 2 * Pi;
    sines[i] := ufactor * Sin(f);
    cosines[i] := ufactor * Cos(f);
  end;

  for i := 0 to UMATRIX_SIZE do
    for j := 0 to UMATRIX_SIZE do
    begin
      puuv := @umatrix[i, j];
      if i = 0 then
        puuv.u := 0.0
      else if i = UMATRIX_SIZE then
        puuv.u := 1.0
      else
      begin
        puuv.u := i / UMATRIX_SIZE + cosines[j];
        if puuv.u < 0.0 then
          puuv.u := 0.0
        else if puuv.u > 1.0 then
          puuv.u := 1.0;
      end;

      if j = 0 then
        puuv.v := 0.0
      else if j = UMATRIX_SIZE then
        puuv.v := 1.0
      else
      begin
        puuv.v := j / UMATRIX_SIZE + sines[i];
        if puuv.v < 0.0 then
          puuv.v := 0.0
        else if puuv.v > 1.0 then
          puuv.v := 1.0;
      end;
      puuv.u := (viewwindowx + puuv.u * viewwidth) / SCREENWIDTH;
      puuv.v := -(viewwindowy + puuv.v * viewheight) / SCREENHEIGHT;
    end;

  glBindTexture(GL_TEXTURE_2D, utex);

  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);

  glCopyTexImage2D(GL_TEXTURE_2D, 0, GL_BGRA, 0, 0, SCREENWIDTH, SCREENHEIGHT, 0);

  glColor4f(0.5, 0.5, 1.0, 1.0);
  glEnable(GL_ALPHA_TEST);
  glAlphaFunc(GL_NOTEQUAL, 0);

  glBegin(GL_QUADS);
  for i := 0 to UMATRIX_SIZE - 1 do
    for j := 0 to UMATRIX_SIZE - 1 do
    begin
      _uvert(i / UMATRIX_SIZE * viewwidth, j / UMATRIX_SIZE * viewheight, i, j);
      _uvert((i + 1) / UMATRIX_SIZE * viewwidth, j / UMATRIX_SIZE * viewheight, i + 1, j);
      _uvert((i + 1) / UMATRIX_SIZE * viewwidth, (j + 1) / UMATRIX_SIZE * viewheight, i + 1, j + 1);
      _uvert(i / UMATRIX_SIZE * viewwidth, (j + 1) / UMATRIX_SIZE * viewheight, i, j + 1);
    end;
  glEnd;
end;

end.
