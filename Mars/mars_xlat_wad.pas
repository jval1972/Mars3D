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
//  Gather resources from disk to a virtual WAD
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/mars3d/
//------------------------------------------------------------------------------

{$I Mars3D.inc}

unit mars_xlat_wad;

interface

uses
  d_delphi;

//==============================================================================
//
// Mars2Stream_Game
//
//==============================================================================
procedure Mars2Stream_Game(const handle: TDStream);

//==============================================================================
//
// Mars2WAD_Game
//
//==============================================================================
procedure Mars2WAD_Game(const fout: string);

implementation

uses
  Math,
  d_main,
  mars_files,
  mars_palette,
  mars_patch,
  mars_bitmap,
  mars_font,
  mars_sounds,
  mars_level,
  r_defs,
  v_video,
  w_wadreader,
  w_wadwriter,
  xmi_lib;

type
  TMarsToWADConverter = class(TObject)
  private
    wadwriter: TWadWriter;
    def_pal: packed array[0..767] of byte;
    def_palL: array[0..255] of LongWord;
    water_tr: array[0..255] of byte;
    water_ti: array[0..255] of byte;
  protected
    procedure Clear;
    function ReadFile(const aname: string; var p: pointer; var sz: integer): boolean;
    function GeneratePalette: boolean;
    function GenerateTranslationTables: boolean;
    function GenerateMenuTranslation: boolean;
    function GenerateFonts: boolean;
    function GenerateDosFonts: boolean;
    function GenerateMarsFonts: boolean;
    function GenerateMusic: boolean;
    function GenerateSounds: boolean;
    function GenerateLevels: boolean;
    function GenerateSprites: boolean;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure ConvertGame;
    procedure SavetoFile(const fname: string);
    procedure SavetoStream(const strm: TDStream);
  end;

//==============================================================================
//
// TMarsToWADConverter.Create
//
//==============================================================================
constructor TMarsToWADConverter.Create;
begin
  wadwriter := nil;
  Inherited;
end;

//==============================================================================
//
// TMarsToWADConverter.Destroy
//
//==============================================================================
destructor TMarsToWADConverter.Destroy;
begin
  Clear;
  Inherited;
end;

//==============================================================================
//
// TMarsToWADConverter.Clear
//
//==============================================================================
procedure TMarsToWADConverter.Clear;
begin
  if wadwriter <> nil then
    wadwriter.Free;
end;

//==============================================================================
//
// TMarsToWADConverter.ReadFile
//
//==============================================================================
function TMarsToWADConverter.ReadFile(const aname: string; var p: pointer; var sz: integer): boolean;
var
  fname: string;
  f: TFile;
begin
  result := false;

  fname := MARS_FindFile(aname);
  if not fexists(fname) then
  begin
    p := nil;
    sz := 0;
    exit;
  end;

  f := TFile.Create(fname, fOpenReadOnly);
  if f.Size = 0 then
  begin
    f.Free;
    result := false;
    p := nil;
    sz := 0;
    exit;
  end;

  sz := f.Size;
  p := malloc(sz);
  f.Read(p^, sz);
  f.Free;

  result := true;
end;

//==============================================================================
//
// TMarsToWADConverter.GeneratePalette
//
//==============================================================================
function TMarsToWADConverter.GeneratePalette: boolean;
var
  p: pointer;
  pal: PByteArray;
  size: integer;
  playpal1: packed array[0..768 * 22 - 1] of byte;
  playpal2: packed array[0..768 * 22 - 1] of byte;
  playpal: packed array[0..768 * 44 - 1] of byte;
  colormap: packed array[0..34 * 256 - 1] of byte;
  i: integer;
  r, g, b: LongWord;
begin
  result := ReadFile('GAME.PAL', p, size);
  if not result then
    exit;

  pal := p;

  MARS_CreateDoomPalette(pal, @playpal1, @colormap);
  wadwriter.AddData('PLAYPAL1', @playpal1, SizeOf(playpal1));
  wadwriter.AddData('COLORMAP', @colormap, SizeOf(colormap));

  // Keep def_pal AFTER SH_CreateDoomPalette call
  for i := 0 to 767 do
    def_pal[i] := pal[i];
  for i := 0 to 255 do
  begin
    r := def_pal[3 * i];
    if r > 255 then r := 255;
    g := def_pal[3 * i + 1];
    if g > 255 then g := 255;
    b := def_pal[3 * i + 2];
    if b > 255 then b := 255;
    def_palL[i] := (r shl 16) + (g shl 8) + (b);
  end;

  memfree(p, size);

  result := ReadFile('WATER.PAL', p, size);
  if not result then
    exit;

  pal := p;

  MARS_CreateDoomPalette(pal, @playpal2, @colormap);

  wadwriter.AddData('WATERPAL', @playpal2, SizeOf(playpal2));
  wadwriter.AddSeparator('C_START');  // JVAL: Needed to be detected by custom colormaps
  wadwriter.AddData('WATERMAP', @colormap, SizeOf(colormap));
  wadwriter.AddSeparator('C_END');
  memfree(p, size);

  if ReadFile('FOGTABLE.DAT', p, size) then
  begin
    memcpy(@colormap, p, size);
    wadwriter.AddData('FOGMAP', @colormap, SizeOf(colormap));
  end;
  memfree(p, size);

  memcpy(@playpal[0], @playpal1[0], 768 * 22);
  memcpy(@playpal[768 * 22], @playpal2[0], 768 * 22);
  wadwriter.AddData('PLAYPAL', @playpal, SizeOf(playpal));
end;

//==============================================================================
//
// TMarsToWADConverter.GenerateTranslationTables
//
//==============================================================================
function TMarsToWADConverter.GenerateTranslationTables: boolean;
var
  p: pointer;
  pal: PByteArray;
  size: integer;
begin
  result := ReadFile('WATER.PAL', p, size);
  if not result then
    exit;

  pal := p;

  MARS_CreateTranslation(@def_pal, pal, @water_tr);
  wadwriter.AddData('TR_WATER', @water_tr, 256);
  MARS_CreateTranslation(pal, @def_pal, @water_ti);
  wadwriter.AddData('TI_WATER', @water_ti, 256);

  memfree(p, size);
end;

//==============================================================================
//
// TMarsToWADConverter.GenerateMenuTranslation
//
//==============================================================================
function TMarsToWADConverter.GenerateMenuTranslation: boolean;
var
  trn: packed array[0..255] of byte;
  i: integer;
begin
  result := true;
  for i := 0 to 255 do
    trn[i] := i;
  for i := 0 to 15 do
    trn[208 + i] := 128 + i;
  wadwriter.AddData('TR_MENU', @trn, 256);
end;

//==============================================================================
//
// TMarsToWADConverter.GenerateFonts
//
//==============================================================================
function TMarsToWADConverter.GenerateFonts: boolean;
const
  NUM_SMALL_FONT_COLORS = 5;
  NUM_BIG_FONT_COLORS = 5;
var
  imgsize: integer;
  imginp: PByteArray;
  imgout: PByteArray;
  imgoutw: PByteArray;
  p: pointer;
  size: integer;
  i, j: integer;
  ch: char;
  BIG_FONT_COLORS: array[0..NUM_BIG_FONT_COLORS - 1] of LongWord;
  SMALL_FONT_COLORS: array[0..NUM_SMALL_FONT_COLORS - 1] of LongWord;
  cidx: integer;
  pnoise: double;
  c: LongWord;
  r1, g1, b1: LongWord;
  r, g, b: integer;
  x, y: integer;
  fnt: string;
  fpos: integer;
  fidx: integer;
  widx: integer;
  w: integer;

  function Interpolate(const a, b, frac: double): double;
  begin
    result := (1.0 - cos(pi * frac)) * 0.5;
    result:= a * (1 - result) + b * result;
  end;

  function Noise(const x,y: double): double;
  var
    n: integer;
  begin
    n := trunc(x + y * 57);
    n := (n shl 13) xor n;
    result := (1.0 - ( (n * (n * n * $EC4D + $131071F) + $5208DD0D) and $7FFFFFFF) / $40000000);
  end;

  function SmoothedNoise(const x, y: double): double;
  var
    corners: double;
    sides: double;
    center: double;
  begin
    corners := (Noise(x - 1, y - 1) + Noise(x + 1, y - 1) + Noise(x - 1, y + 1) + Noise(x + 1, y + 1) ) / 16;
    sides := (Noise(x - 1, y) + Noise(x + 1, y) + Noise(x, y - 1) + Noise(x, y + 1)) / 8;
    center := Noise(x, y) / 4;
    result := corners + sides + center
  end;

  function InterpolatedNoise(const x, y: double): double;
  var
    i1, i2: double;
    v1, v2, v3, v4: double;
    xInt: double;
    yInt: double;
    xFrac: double;
    yFrac: double;
  begin
    xInt := Int(x);
    xFrac := Frac(x);

    yInt := Int(y);
    yFrac := Frac(y);

    v1 := SmoothedNoise(xInt, yInt);
    v2 := SmoothedNoise(xInt + 1, yInt);
    v3 := SmoothedNoise(xInt, yInt + 1);
    v4 := SmoothedNoise(xInt + 1, yInt + 1);

    i1 := Interpolate(v1, v2, xFrac);
    i2 := Interpolate(v3, v4, xFrac);

    result := Interpolate(i1, i2, yFrac);
  end;

  function PerlinNoise(const x, y: integer): double;
  const
    PERSISTENCE = 0.50;
    LOOPCOUNT = 3;
    VARIATION = 16;
  var
    amp: double;
    ii: integer;
    freq: integer;
  begin
    freq := 1;
    result := 0.0;
    for ii := 0 to LOOPCOUNT - 1 do
    begin
      amp := Power(PERSISTENCE, ii);
      result := result + InterpolatedNoise(x * freq, y * freq) * amp;
      freq := freq shl 1;
    end;
    result := result * VARIATION;
  end;

begin
  result := true;

  SMALL_FONT_COLORS[0] := $E2CE4A;
  SMALL_FONT_COLORS[1] := $F0F0F0;
  SMALL_FONT_COLORS[2] := $0F0F0F;
  SMALL_FONT_COLORS[3] := $F00000;
  SMALL_FONT_COLORS[4] := $C0C0C0;

  imgout := malloc(8 * 8);
  for cidx := 0 to NUM_SMALL_FONT_COLORS - 1 do
  begin
    r1 := (SMALL_FONT_COLORS[cidx] shr 16) and $FF;
    g1 := (SMALL_FONT_COLORS[cidx] shr 8) and $FF;
    b1 := SMALL_FONT_COLORS[cidx] and $FF;
    wadwriter.AddSeparator('FN_START');
    for ch := Chr(33) to Chr(127) do
    begin
      x := ((Ord(ch) - 31) - 1) mod 16;
      y := ((Ord(ch) - 31) - 1) div 16;
      for j := 0 to 7 do
      begin
        fpos := x * 8 + (y * 8 + j) * 128;
        for i := 0 to 7 do
        begin
          imgout[i * 8 + j] := SMALL_FONT_DATA[fpos];
          inc(fpos);
        end;
      end;
      for i := 0 to 63 do
        if imgout[i] <> 0 then
        begin
          pnoise := PerlinNoise((i + x * 8) mod 128, (i * y + x * 8) div 128);
          r := GetIntegerInRange(round(r1 * imgout[i] / 256 + pnoise), 0, 255);
          g := GetIntegerInRange(round(g1 * imgout[i] / 256 + pnoise), 0, 255);
          b := GetIntegerInRange(round(b1 * imgout[i] / 256 + pnoise), 0, 255);
          c := r shl 16 + g shl 8 + b;
          imgout[i] := V_FindAproxColorIndex(@def_palL, c, 1, 255);
        end
        else
          imgout[i] := MARS_PATCH_BLANC;
      MARS_CreateDoomPatch(imgout, 8, 8, false, p, size, 0, 0);
      wadwriter.AddData('SFNT' + Chr(Ord('A') + cidx) + IntToStrzFill(3, Ord(ch)), p, size);
      memfree(p, size);
    end;
    wadwriter.AddSeparator('FN_END');
  end;
  MemFree(pointer(imgout), 8 * 8);

  imgsize := SizeOf(BIG_FONT_BUFFER);
  imginp := malloc(imgsize);

  BIG_FONT_COLORS[0] := $E2CE4A;
  BIG_FONT_COLORS[1] := $F0F0F0;
  BIG_FONT_COLORS[2] := $0F0F0F;
  BIG_FONT_COLORS[3] := $F00000;
  BIG_FONT_COLORS[4] := $C0C0C0;

  fnt := 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890`~!@#$%^&*()-_=+*/<>.,\[]|;:''"{}';
  imgout := malloc(18 * 21);
  for cidx := 0 to NUM_BIG_FONT_COLORS - 1 do
  begin
    r1 := (BIG_FONT_COLORS[cidx] shr 16) and $FF;
    g1 := (BIG_FONT_COLORS[cidx] shr 8) and $FF;
    b1 := BIG_FONT_COLORS[cidx] and $FF;
    for i := 0 to imgsize - 1 do
    begin
      if BIG_FONT_BUFFER[i] = 0 then
        imginp[i] := MARS_PATCH_BLANC
      else
      begin
        if BIG_FONT_BUFFER[i] = 255 then
          pnoise := PerlinNoise(i mod 1984, i div 1984)
        else
          pnoise := 0.0;
        r := round(r1 * BIG_FONT_BUFFER[i] / 256 + pnoise);
        if r > 255 then
          r := 255
        else if r < 0 then
          r := 0;
        g := round(g1 * BIG_FONT_BUFFER[i] / 256 + pnoise);
        if g > 255 then
          g := 255
        else if g < 0 then
          g := 0;
        b := round(b1 * BIG_FONT_BUFFER[i] / 256 + pnoise);
        if b > 255 then
          b := 255
        else if b < 0 then
          b := 0;
        c := r shl 16 + g shl 8 + b;
        imginp[i] := V_FindAproxColorIndex(@def_palL, c, 1, 255);
      end;
    end;

    wadwriter.AddSeparator('FN_START');
    for ch := Chr(33) to Chr(128) do
    begin
      fidx := CharPos(ch, fnt);
      if fidx > 0 then
      begin
        x := 0;
        y := 4 + (fidx - 1) * 21;
        MARS_BltImageBuffer(imginp, 18, 1984, imgout, x, x + 17, y, y + 20);
        // Right trim image
        widx := 18 * 21 - 1;
        while widx > 0 do
        begin
          if imgout[widx] <> MARS_PATCH_BLANC then
            break;
          dec(widx);
        end;
        if widx < 16 * 21 then
        begin
          w := (widx div 21) + 1;
          imgoutw := malloc(21 * w);
          memcpy(imgoutw, imgout, w * 21);
          MARS_CreateDoomPatch(imgoutw, w, 21, false, p, size, 1, 2);
          memfree(pointer(imgoutw), 21 * w);
        end
        else
          MARS_CreateDoomPatch(imgout, 18, 21, false, p, size, 1, 2);
      end
      else
      begin
        memset(imgout, MARS_PATCH_BLANC, 18 * 21);
        MARS_CreateDoomPatch(imgout, 5, 21, false, p, size, 1, 2);
      end;
      wadwriter.AddData('BFNT' + Chr(Ord('A') + cidx) + IntToStrzFill(3, Ord(ch)), p, size);
      memfree(p, size);
    end;
    wadwriter.AddSeparator('FN_END');
  end;

  memfree(pointer(imginp), imgsize);
  memfree(pointer(imgout), 18 * 21);
end;

//==============================================================================
// TMarsToWADConverter.GenerateDosFonts
//
// Generate DOS font in various colors
//
//==============================================================================
function TMarsToWADConverter.GenerateDosFonts: boolean;
const
  NUM_DOS_FONT_COLORS = 2;
var
  imgsize: integer;
  imginp: PByteArray;
  imgout: PByteArray;
  p: pointer;
  size: integer;
  i, j: integer;
  ch: char;
  COLORS: array[0..NUM_DOS_FONT_COLORS - 1] of LongWord;
  cidx: integer;
  c: LongWord;
  r1, g1, b1: LongWord;
  r, g, b: LongWord;
  x, y, fpos: integer;
begin
  result := true;

  COLORS[0] := 95 shl 16 + 207 shl 8 + 87;
  COLORS[1] := $FFFFFF;

  // Small dos font
  imgsize := 128 * 128;
  imginp := malloc(imgsize);

  imgout := malloc(8 * 8);
  for cidx := 0 to NUM_DOS_FONT_COLORS - 1 do
  begin
    r1 := (COLORS[cidx] shr 16) and $FF;
    g1 := (COLORS[cidx] shr 8) and $FF;
    b1 := COLORS[cidx] and $FF;
    for i := 0 to imgsize - 1 do
    begin
      if SMALL_DOS_FONT_BUFFER[i] = 0 then
        imginp[i] := MARS_PATCH_BLANC
      else
      begin
        r := round(r1 * SMALL_DOS_FONT_BUFFER[i] / 256);
        if r > 255 then
          r := 255;
        g := round(g1 * SMALL_DOS_FONT_BUFFER[i] / 256);
        if g > 255 then
          g := 255;
        b := round(b1 * SMALL_DOS_FONT_BUFFER[i] / 256);
        if b > 255 then
          b := 255;
        c := r shl 16 + g shl 8 + b;
        imginp[i] := V_FindAproxColorIndex(@def_palL, c, 1, 255);
      end;
    end;

    wadwriter.AddSeparator('FN_START');
    for ch := Chr(33) to Chr(128) do
    begin
      x := (Ord(ch) - 1) mod 16;
      y := (Ord(ch) - 1) div 16;
      for j := 0 to 7 do
      begin
        fpos := x * 8 + (y * 8 + j) * 128;
        for i := 0 to 7 do
        begin
          imgout[i * 8 + j] := imginp[fpos];
          inc(fpos);
        end;
      end;
      MARS_CreateDoomPatch(imgout, 8, 8, false, p, size, 0, 0);
      wadwriter.AddData('DFNT' + Chr(Ord('A') + cidx) + IntToStrzFill(3, Ord(ch)), p, size);
      memfree(p, size);
    end;
    wadwriter.AddSeparator('FN_END');
  end;

  memfree(pointer(imginp), imgsize);
  memfree(pointer(imgout), 8 * 8);
end;

//==============================================================================
//
// TMarsToWADConverter.GenerateMarsFonts
//
//==============================================================================
function TMarsToWADConverter.GenerateMarsFonts: boolean;
const
  NUM_MARS_FONT_COLORS = 2;
  MARS_FONT_FILESIZE = 2048;
var
  fntfilename: string;
  imgsize: integer;
  imginp: PByteArray;
  imgout: PByteArray;
  p: pointer;
  size: integer;
  i, j: integer;
  ch: char;
  COLORS: array[0..NUM_MARS_FONT_COLORS - 1] of LongWord;
  ASCII_FONT_BUFFER: PByteArray;
  ASCII_DATA: array[0..MARS_FONT_FILESIZE - 1] of byte;
  fs: TFile;
  bb: byte;
  cnt: integer;
  cidx: integer;
  c: LongWord;
  r1, g1, b1: LongWord;
  r, g, b: LongWord;
  fpos: integer;
begin
  fntfilename := MARS_FindFile('ASCII.FNT');
  if not fexists(fntfilename) then
  begin
    result := false;
    ZeroMemory(@ASCII_DATA, SizeOf(ASCII_DATA));
  end
  else
  begin
    fs := TFile.Create(fntfilename, fOpenReadOnly);
    if fs.Size <> MARS_FONT_FILESIZE then
    begin
      result := false;
      ZeroMemory(@ASCII_DATA, SizeOf(ASCII_DATA));
    end
    else
    begin
      result := true;
      fs.Read(ASCII_DATA, SizeOf(ASCII_DATA));
    end;
    fs.Free;
  end;

  COLORS[0] := 95 shl 16 + 207 shl 8 + 87;
  COLORS[1] := 55 shl 16 + 115 shl 8 + 43;

  // Small ascii font
  imgsize := 128 * 128;
  ASCII_FONT_BUFFER := malloc(imgsize);

  cnt := 0;
  for i := 0 to SizeOf(ASCII_DATA) - 1 do
  begin
    bb := ASCII_DATA[i];
    ASCII_FONT_BUFFER[cnt] := (bb shr 7) and 1;
    Inc(cnt);
    ASCII_FONT_BUFFER[cnt] := (bb shr 6) and 1;
    Inc(cnt);
    ASCII_FONT_BUFFER[cnt] := (bb shr 5) and 1;
    Inc(cnt);
    ASCII_FONT_BUFFER[cnt] := (bb shr 4) and 1;
    Inc(cnt);
    ASCII_FONT_BUFFER[cnt] := (bb shr 3) and 1;
    Inc(cnt);
    ASCII_FONT_BUFFER[cnt] := (bb shr 2) and 1;
    Inc(cnt);
    ASCII_FONT_BUFFER[cnt] := (bb shr 1) and 1;
    Inc(cnt);
    ASCII_FONT_BUFFER[cnt] := bb and 1;
    Inc(cnt);
  end;

  imginp := malloc(imgsize);

  imgout := malloc(8 * 16);
  for cidx := 0 to NUM_MARS_FONT_COLORS - 1 do
  begin
    r1 := (COLORS[cidx] shr 16) and $FF;
    g1 := (COLORS[cidx] shr 8) and $FF;
    b1 := COLORS[cidx] and $FF;
    for i := 0 to imgsize - 1 do
    begin
      if ASCII_FONT_BUFFER[i] = 0 then
        imginp[i] := MARS_PATCH_BLANC
      else
      begin
        r := r1 * ASCII_FONT_BUFFER[i];
        if r > 255 then
          r := 255;
        g := g1 * ASCII_FONT_BUFFER[i];
        if g > 255 then
          g := 255;
        b := b1 * ASCII_FONT_BUFFER[i];
        if b > 255 then
          b := 255;
        c := r shl 16 + g shl 8 + b;
        imginp[i] := V_FindAproxColorIndex(@def_palL, c, 1, 255);
      end;
    end;

    wadwriter.AddSeparator('FN_START');
    for ch := Chr(33) to Chr(127) do
    begin
      fpos := Ord(ch) * 128;
      for j := 0 to 15 do
      begin
        for i := 0 to 7 do
        begin
          imgout[i * 16 + j] := imginp[fpos];
          inc(fpos);
        end;
      end;
      MARS_CreateDoomPatch(imgout, 8, 16, false, p, size, 0, 0);
      wadwriter.AddData('MFNT' + Chr(Ord('A') + cidx) + IntToStrzFill(3, Ord(ch)), p, size);
      memfree(p, size);
    end;
    wadwriter.AddSeparator('FN_END');
  end;

  memfree(pointer(ASCII_FONT_BUFFER), imgsize);
  memfree(pointer(imginp), imgsize);
  memfree(pointer(imgout), 8 * 16);
end;

//==============================================================================
//
// TMarsToWADConverter.GenerateMusic
//
//==============================================================================
function TMarsToWADConverter.GenerateMusic: boolean;
var
  xmifilename: string;

  procedure _convert_music_track(const trNo: integer; const lumpname: string);
  var
    p: pointer;
    sz: integer;
  begin
    XMI_Init;

    if XMI_OpenMusicFile(xmifilename) then
      if XMI_ConvertTrackToMemory(trNo, 'mid', p, sz) then
      begin
        wadwriter.AddData(lumpname, p, sz);
        XMI_FreeMem(p, sz);
      end;

    XMI_ShutDown;
  end;

begin
  xmifilename := MARS_FindFile('MARS.XMI');
  if not fexists(xmifilename) then
  begin
    result := false;
    exit;
  end;

  wadwriter.AddSeparator('M_START');

  _convert_music_track(0, 'D_INTRO');
  _convert_music_track(1, 'D_E1M1');
  _convert_music_track(2, 'D_E1M2');
  _convert_music_track(3, 'D_E1M3');
  _convert_music_track(4, 'D_E1M4');
  _convert_music_track(5, 'D_E1M5');
  _convert_music_track(6, 'D_E1M6');
  _convert_music_track(7, 'D_E1M7');
  _convert_music_track(9, 'D_VICTOR');
  _convert_music_track(11, 'D_INTROA');
  _convert_music_track(14, 'D_INTER');

  wadwriter.AddSeparator('M_END');

  result := true;
end;

//==============================================================================
//
// TMarsToWADConverter.GenerateSounds
//
//==============================================================================
function TMarsToWADConverter.GenerateSounds: boolean;
var
  i: integer;
  sndfilename: string;
begin
  result := false;
  for i := 0 to Ord(NUM_MARS_SOUNDS) - 1 do
  begin
    sndfilename := MARS_FindFile(marssounds[i].name + '.WAV');
    if fexists(sndfilename) then
    begin
      marssounds[i].path := sndfilename;
      wadwriter.AddFile(marssounds[i].name, sndfilename);
      result := true;
    end;
  end;
end;

//==============================================================================
//
// TMarsToWADConverter.GenerateLevels
//
//==============================================================================
function TMarsToWADConverter.GenerateLevels: boolean;
var
  wadreader: TWadReader;
  i, j: integer;
  b: boolean;
begin
  result := false;

  if not fexists(mars_main_mad) then
    exit;

  if strtrim(mars_main_mad) = '' then
    exit;

  wadreader := TWadReader.Create;
  wadreader.OpenWadFile(mars_main_mad);

  for i := 1 to 4 do
    for j := 1 to 9 do
    begin
      b := MARS_PreprocessLevel('E' + itoa(i) + 'M' + itoa(j), wadreader, wadwriter);
      result := result or b;
    end;

  wadreader.Free;
end;

var
  TNT1A0: array[0..87] of Byte = (
    $10, $00, $10, $00, $08, $00, $08, $00, $48, $00, $00, $00, $49, $00, $00,
    $00, $4A, $00, $00, $00, $4B, $00, $00, $00, $4C, $00, $00, $00, $4D, $00,
    $00, $00, $4E, $00, $00, $00, $4F, $00, $00, $00, $50, $00, $00, $00, $51,
    $00, $00, $00, $52, $00, $00, $00, $53, $00, $00, $00, $54, $00, $00, $00,
    $55, $00, $00, $00, $56, $00, $00, $00, $57, $00, $00, $00, $FF, $FF, $FF,
    $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  );

//==============================================================================
//
// TMarsToWADConverter.GenerateSprites
//
//==============================================================================
function TMarsToWADConverter.GenerateSprites: boolean;
var
  wadreader: TWadReader;
  i, j, k: integer;
  buf: Pointer;
  sz: integer;
  p: Ppatch_t;
begin
  result := false;

  if not fexists(mars_main_mad) then
    exit;

  if strtrim(mars_main_mad) = '' then
    exit;

  wadreader := TWadReader.Create;
  wadreader.OpenWadFile(mars_main_mad);

  i := wadreader.EntryId('MOUSI0');
  if i < 0 then
    i := wadreader.EntryId('MOUSI1');

  j := wadreader.EntryId('MOUSJ0');
  if j < 0 then
    j := wadreader.EntryId('MOUSJ1');

  if (i < 0) or (j < 0) then
  begin
    // Check shareware
    k := wadreader.EntryId('E3M1');
    if k >= 0 then
    begin
      wadwriter.AddSeparator('SS_START');
      if i < 0 then
        wadwriter.AddData('MOUSI0', @TNT1A0, SizeOf(TNT1A0));
      if j < 0 then
        wadwriter.AddData('MOUSJ0', @TNT1A0, SizeOf(TNT1A0));
      wadwriter.AddSeparator('SS_END');

      result := true;
    end;
  end;

  i := wadreader.EntryId('BOMFA0');
  if i > 0 then // Can't be 0, must be in S_START/S_END namespace
  begin
    wadreader.ReadEntry(i, buf, sz);

    p := buf;
    if (p.leftoffset = -75) and (p.topoffset = -38) then
    begin
      wadwriter.AddSeparator('SS_START');

      p.leftoffset := -49;
      p.topoffset := -64;
      for k := 0 to 6 do
      begin
        wadwriter.AddData('BOMH' + Chr(Ord('A') + k) + '0', p, sz);
        Dec(p.leftoffset, 5);
        Inc(p.topoffset, 5);
      end;
      wadwriter.AddSeparator('SS_END');

      result := true;
    end;
    memfree(buf, sz);
  end;

  wadreader.Free;
end;

//==============================================================================
//
// TMarsToWADConverter.ConvertGame
//
//==============================================================================
procedure TMarsToWADConverter.ConvertGame;
begin
  Clear;

  wadwriter := TWadWriter.Create;

  GeneratePalette;
  GenerateTranslationTables;
  GenerateMenuTranslation;
  GenerateFonts;
  GenerateDosFonts;
  GenerateMarsFonts;
  GenerateMusic;
  GenerateSounds;
  GenerateLevels;
  GenerateSprites;
end;

//==============================================================================
//
// TMarsToWADConverter.SavetoFile
//
//==============================================================================
procedure TMarsToWADConverter.SavetoFile(const fname: string);
begin
  wadwriter.SaveToFile(fname);
end;

//==============================================================================
//
// TMarsToWADConverter.SavetoStream
//
//==============================================================================
procedure TMarsToWADConverter.SavetoStream(const strm: TDStream);
begin
  wadwriter.SaveToStream(strm);
end;

//==============================================================================
//
// Mars2Stream_Game
//
//==============================================================================
procedure Mars2Stream_Game(const handle: TDStream);
var
  cnv: TMarsToWADConverter;
begin
  cnv := TMarsToWADConverter.Create;
  try
    cnv.ConvertGame;
    cnv.SavetoStream(handle);
  finally
    cnv.Free;
  end;
end;

//==============================================================================
//
// Mars2WAD_Game
//
//==============================================================================
procedure Mars2WAD_Game(const fout: string);
var
  cnv: TMarsToWADConverter;
begin
  cnv := TMarsToWADConverter.Create;
  try
    cnv.ConvertGame;
    cnv.SavetoFile(fout);
  finally
    cnv.Free;
  end;
end;

end.

