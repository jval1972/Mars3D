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
//  Temporary files managment.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/mars3d/
//------------------------------------------------------------------------------

{$I Mars3D.inc}

unit i_tmp;

interface

procedure I_InitTempFiles;

procedure I_ShutDownTempFiles;

function I_NewTempFile(const name: string): string;

procedure I_DeclareTempFile(const name: string);

implementation

uses
  Windows,
  m_argv,
  d_delphi;

var
  tempfiles: TDStringList;

procedure I_InitTempFiles;
begin
  tempfiles := TDStringList.Create;
end;

procedure I_ShutDownTempFiles;
var
  i: integer;
begin
{$I-}
  for i := 0 to tempfiles.Count - 1 do
    fdelete(tempfiles.Strings[i]);
{$I+}    
  tempfiles.Free;
end;

function I_NewTempFile(const name: string): string;
var
  buf: array[0..1024] of char;
begin
  ZeroMemory(@buf, SizeOf(buf));
  GetTempPath(SizeOf(buf), buf);

  result := M_SaveFileName('DATA\');
  MkDir(result);
  result := result + 'TMP\';
  MkDir(result);

  result :=  result + fname(name);
  tempfiles.Add(result);
end;

procedure I_DeclareTempFile(const name: string);
begin
  tempfiles.Add(name);
end;

end.
