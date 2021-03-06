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
//    Mars files
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/mars3d/
//------------------------------------------------------------------------------

{$I Mars3D.inc}

unit mars_files;

interface

var
  marsdirectory: string = '';
  marsdatafile: string = '';

//==============================================================================
//
// MARS_FindFile
//
//==============================================================================
function MARS_FindFile(const fn: string): string;

implementation

uses
  d_delphi,
  d_main;

//==============================================================================
//
// MARS_FindFile
//
//==============================================================================
function MARS_FindFile(const fn: string): string;
var
  fn1: string;
  dir: string;
  i: integer;
begin
  Result := fn;
  if fexists(Result) then
    Exit;

  fn1 := fname(fn);
  Result := fn1;
  if fexists(Result) then
    Exit;

  if Length(marsdirectory) > 0 then
  begin
    dir := marsdirectory;
    if not (dir[Length(dir)] in ['\', '/']) then
      dir := dir + '\';

    dir := fixslashpath(dir);

    Result := dir + fn1;
    if fexists(Result) then
      Exit;

    Result := dir + 'INSTALL\' + fn1;
    if fexists(Result) then
      Exit;

    // Parent directory
    for i := Length(dir) downto 3 do
      if dir[i] in ['\', '/'] then
      begin
        SetLength(dir, i);
        Result := dir + fn1;
        if fexists(Result) then
          Exit;
      end;
  end;

  Result := D_FileInDoomPath(fn);
end;

end.
