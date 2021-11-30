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
// DESCRIPTION
//  Steam stuff
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/mars3d/
//------------------------------------------------------------------------------

{$I Mars3D.inc}

unit i_steam;

interface

function QuerySteamDirectory(const appid: integer): string;

implementation

uses
  d_delphi,
  windows,
  registry;

const
  KEY_WOW64_64KEY = $100;
  KEY_WOW64_32KEY = $200;

function QuerySteamDirectory1(const flags, appid: integer): string;
var
  reg: TRegistry;
begin
  reg := TRegistry.Create(flags);
  reg.RootKey := HKEY_LOCAL_MACHINE;
  if reg.OpenKey('\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Steam App ' + itoa(appid), false) then
    result := reg.ReadString('InstallLocation')
  else if reg.OpenKey('\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Steam App ' + itoa(appid), false) then
    result := reg.ReadString('InstallLocation')
  else
    result := '';
  reg.free;
end;

function QuerySteamDirectory(const appid: integer): string;
begin
  result := QuerySteamDirectory1(KEY_READ, appid);
  if result = '' then
  begin
    result := QuerySteamDirectory1(KEY_READ or KEY_WOW64_64KEY, appid);
    if result = '' then
      result := QuerySteamDirectory1(KEY_READ or KEY_WOW64_32KEY, appid);
  end;
  if result <> '' then
  begin
    result := fixslashpath(result);
    if result[length(result)] <> '\' then
      result := result + '\';
  end;
end;

end.

