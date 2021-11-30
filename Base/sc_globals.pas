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

unit sc_globals;

interface

procedure SC_InitGlobals;

procedure SC_ShutDownGlobals;

procedure SC_AddGlobalPrecalc(const name: string);

implementation

uses
  d_delphi;

const
  NUM_SCGLOBALLISTS = 64;
var
  scgloballists: array[0..NUM_SCGLOBALLISTS - 1] of TDStringList;

procedure SC_InitGlobals;
var
  i: integer;
begin
  for i := 0 to NUM_SCGLOBALLISTS - 1 do
    scgloballists[i] := TDStringList.Create;
end;
procedure SC_ShutDownGlobals;
var
  i: integer;
begin
  for i := 0 to NUM_SCGLOBALLISTS - 1 do
    scgloballists[i].Free;
end;

procedure SC_AddGlobalPrecalc(const name: string);
begin
end;

end.
 
