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

unit w_wadreader;

interface

uses
  d_delphi,
  w_wad;

type
  TWadReader = class
  private
    h: wadinfo_t;
    la: Pfilelump_tArray;
    fs: TFile;
    ffilename: string;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure Clear; virtual;
    procedure OpenWadFile(const aname: string);
    function EntryAsString(const id: integer): string; overload;
    function EntryAsString(const aname: string): string; overload;
    function ReadEntry(const id: integer; var buf: pointer; var bufsize: integer): boolean; overload;
    function ReadEntry(const aname: string; var buf: pointer; var bufsize: integer): boolean; overload;
    function EntryName(const id: integer): string;
    function EntryId(const aname: string): integer;
    function EntryInfo(const id: integer): Pfilelump_t; overload;
    function EntryInfo(const aname: string): Pfilelump_t; overload;
    function NumEntries: integer;
    function FileSize: integer;
    property FileName: string read ffilename;
    property Header: wadinfo_t read h;
  end;

function W_WadFastCrc32(const aname: string): string;

implementation

uses
  i_system,
  m_crc32;

constructor TWadReader.Create;
begin
  h.identification := 0;
  h.numlumps := 0;
  h.infotableofs := 0;
  la := nil;
  fs := nil;
  ffilename := '';
  Inherited;
end;

destructor TWadReader.Destroy;
begin
  Clear;
  Inherited;
end;

procedure TWadReader.Clear;
begin
  if h.numlumps > 0 then
  begin
    MemFree(pointer(la), h.numlumps * SizeOf(filelump_t));
    h.identification := 0;
    h.numlumps := 0;
    h.infotableofs := 0;
    la := nil;
    ffilename := '';
  end
  else
  begin
    h.identification := 0;
    h.infotableofs := 0;
  end;
  if fs <> nil then
  begin
    fs.Free;
    fs := nil;
  end;
end;

procedure TWadReader.OpenWadFile(const aname: string);
var
  madbuf: packed array[0..19] of byte;
  ismad: boolean;
  smad: string;
  pb: PByteArray;
  i: integer;
begin
  if aname = '' then
    Exit;
  {$IFDEF DEBUG}
  print('Opening WAD file ' + aname + #13#10);
  {$ENDIF}
  Clear;
  if not fexists(aname) then
  begin
    I_Warning('TWadReader.OpenWadFile(): Can not find WAD file ' + aname + #13#10);
    exit;
  end;

  fs := TFile.Create(aname, fOpenReadOnly);

  ismad := false;

  fs.Read(madbuf, SizeOf(madbuf));
  smad := '';
  for i := 0 to Length(MAD1) - 1 do
    smad := smad + Char(madbuf[i]);
  if smad = MAD1 then
  begin
    ismad := true;
    fs.Seek(8, sFromBeginning);
  end
  else
  begin
    smad := '';
    for i := 0 to Length(MAD2) - 1 do
      smad := smad + Char(madbuf[i]);
    if smad = MAD2 then
    begin
      ismad := true;
      fs.Seek(20, sFromBeginning);
    end;
  end;

  if not ismad then
  begin
    fs.Seek(0, sFromBeginning);
    fs.Read(h, SizeOf(wadinfo_t));
  end
  else
  begin
    h.identification := IMAD;
    fs.Read(h.numlumps, SizeOf(integer));
    fs.Read(h.infotableofs, SizeOf(integer));
  end;

  if (h.numlumps > 0) and (h.infotableofs < fs.Size) and ((h.identification = IWAD) or (h.identification = PWAD) or (h.identification = IMAD)) then
  begin
    fs.Seek(h.infotableofs, sFromBeginning);
    la := malloc(h.numlumps * SizeOf(filelump_t));
    fs.Read(la^, h.numlumps * SizeOf(filelump_t));
    if ismad then
    begin
      pb := PByteArray(la);
      for i := 0 to h.numlumps * SizeOf(filelump_t) - 1 do
        pb[i] := pb[i] - 48;
    end;
    ffilename := aname;
  end
  else
    I_Warning('TWadReader.OpenWadFile(): Invalid WAD file ' + aname + #13#10);
end;

function TWadReader.EntryAsString(const id: integer): string;
begin
  if (fs <> nil) and (id >= 0) and (id < h.numlumps) then
  begin
    SetLength(Result, la[id].size);
    fs.Seek(la[id].filepos, sFromBeginning);
    fs.Read((@Result[1])^, la[id].size);
  end
  else
    Result := '';
end;

function TWadReader.EntryAsString(const aname: string): string;
var
  id: integer;
begin
  id := EntryId(aname);
  if id >= 0 then
    Result := EntryAsString(id)
  else
    Result := '';
end;

function TWadReader.ReadEntry(const id: integer; var buf: pointer; var bufsize: integer): boolean;
begin
  if (fs <> nil) and (id >= 0) and (id < h.numlumps) then
  begin
    fs.Seek(la[id].filepos, sFromBeginning);
    bufsize := la[id].size;
    buf := malloc(bufsize);
    fs.Read(buf^, bufsize);
    Result := true;
  end
  else
    Result := false;
end;

function TWadReader.ReadEntry(const aname: string; var buf: pointer; var bufsize: integer): boolean;
var
  id: integer;
begin
  id := EntryId(aname);
  if id >= 0 then
    Result := ReadEntry(id, buf, bufsize)
  else
    Result := false;
end;

function TWadReader.EntryName(const id: integer): string;
begin
  if (id >= 0) and (id < h.numlumps) then
    Result := char8tostring(la[id].name)
  else
    Result := '';
end;

function TWadReader.EntryId(const aname: string): integer;
var
  i: integer;
  uname: string;
begin
  uname := strupper(aname);
  for i := h.numlumps - 1 downto 0 do
    if char8tostring(la[i].name) = uname then
    begin
      Result := i;
      Exit;
    end;
  Result := -1;
end;

function TWadReader.EntryInfo(const id: integer): Pfilelump_t;
begin
  if (id >= 0) and (id < h.numlumps) then
    Result := @la[id]
  else
    Result := nil;
end;

function TWadReader.EntryInfo(const aname: string): Pfilelump_t;
begin
  result := EntryInfo(EntryId(aname));
end;

function TWadReader.NumEntries: integer;
begin
  Result := h.numlumps;
end;

function TWadReader.FileSize: integer;
begin
  if fs <> nil then
    Result := fs.Size
  else
    Result := 0;
end;

function W_WadFastCrc32(const aname: string): string;
var
  w: TWadReader;
  m: TDMemoryStream;
  i: integer;
  h: wadinfo_t;
  fl: filelump_t;
begin
  w := TWadReader.Create;
  w.OpenWadFile(aname);

  m := TDMemoryStream.Create;
  h := w.Header;
  m.Write(h, SizeOf(wadinfo_t));

  for i := 0 to w.NumEntries - 1 do
  begin
    fl := w.EntryInfo(i)^;
    m.Write(fl, SizeOf(filelump_t));
  end;

  Result := GetCRC32(m.Memory, m.Size);

  w.Free;
  m.Free;
end;

end.
