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
//  DESCRIPTION:
//  Use wav sounds inside PK3 without a WAD corresponding alias
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/mars3d/
//------------------------------------------------------------------------------

{$I Mars3D.inc}

unit s_pk3sounds;

interface

procedure W_InitPK3Sounds;

implementation

uses
  d_delphi,
  i_tmp,
  m_argv,
  m_sha1,
  w_pak,
  w_wad,
  w_wadwriter;

var
  s_names: TDStringList;

const
  DSSTUBLUMP: array[0..149] of Byte = (
    $03, $00, $11, $2B, $8E, $00, $00, $00, $80, $80, $80, $80, $80, $80, $80,
    $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80,
    $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80,
    $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80,
    $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80,
    $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80,
    $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80,
    $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80,
    $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80,
    $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80
  );

procedure S_AddFileName(const filename: string);
var
  check: string;
  name: string;
  ext: string;
  doadd: Boolean;
begin
  check := strupper(filename);
  ext := fext(check);
  if (ext = '.WAV') or (ext = '.OGG') or (ext = '.FLAC') or (ext = '.OGA') or
    (ext = '.AU') or (ext = '.VOC') or (ext = '.SND') then
  begin
    check := fname(check);
    name := firstword(check, '.');
    if Length(name) > 2 then
      if Pos('DS', name) = 1 then
        Delete(name, 1, 2);
    if Length(name) <= 8 then
      if s_names.IndexOf(name) < 0 then
      begin
        doadd := true;
        if W_CheckNumForName(name) >= 0 then
          doadd := false
        else if Length(name) <= 6 then
        begin
          name := 'DS' + name;
          if W_CheckNumForName(name) >= 0 then
            doadd := false;
        end;
        if doadd then
          s_names.Add(name);
      end;
  end;
end;

procedure W_InitPK3Sounds;
var
  wad: TWADWriter;
  wadfilename: string;
  i: integer;
  mem: TDMemoryStream;
begin
  s_names := TDStringList.Create;

  PAK_FileNameIterator(@S_AddFileName);

  if s_names.Count > 0 then
  begin
    wad := TWadWriter.Create;

    for i := 0 to s_names.Count - 1 do
      wad.AddData(s_names.Strings[i], @DSSTUBLUMP, SizeOf(DSSTUBLUMP));

    mem := TDMemoryStream.Create;

    wad.SaveToStream(mem);

    wadfilename := M_SaveFileName('DATA\');
    MkDir(wadfilename);
    wadfilename := wadfilename + 'TMP\';
    MkDir(wadfilename);
    wadfilename := wadfilename + 'pk3sounds_' + readablestring(SHA1_CalcSHA1Buf(mem.memory^, mem.Size)) + '.wad';
    mem.Free;

    wad.SaveToFile(wadfilename);

    wad.Free;

    W_RuntimeLoad(wadfilename, F_ORIGIN_WAD);

    I_DeclareTempFile(wadfilename);
  end;

  s_names.Free;
end;

end.
