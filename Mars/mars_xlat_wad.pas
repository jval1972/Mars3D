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

procedure Mars2Stream_Game(const handle: TDStream);

procedure Mars2WAD_Game(const fout: string);

implementation

uses
  Math,
  m_fixed,
  mars_files,
  mars_palette,
  mars_patch,
  mars_bitmap,
  mars_font,
  mars_sounds,
  sc_engine,
  v_video,
  w_wadwriter,
  w_wad,
  xmi_lib;

type
  TMarsToWADConverter = class(TObject)
  private
    wadwriter: TWadWriter;
    def_pal: packed array[0..767] of byte;
    def_palL: array[0..255] of LongWord;
    water_tr: array[0..255] of byte;
  protected
    procedure Clear;
    function ReadFile(const aname: string; var p: pointer; var sz: integer): boolean;
    function GeneratePalette: boolean;
    function GenerateTranslationTables: boolean;
    function GenerateBigFonts: boolean;
    function GenerateDosFonts: boolean;
    function GenerateMenuTranslation: boolean;
    function GenerateMusic: boolean;
    function GenerateSounds: boolean;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure ConvertGame;
    procedure SavetoFile(const fname: string);
    procedure SavetoStream(const strm: TDStream);
  end;

constructor TMarsToWADConverter.Create;
begin
  wadwriter := nil;
  Inherited;
end;

destructor TMarsToWADConverter.Destroy;
begin
  Clear;
  Inherited;
end;

procedure TMarsToWADConverter.Clear;
begin
  if wadwriter <> nil then
    wadwriter.Free;
end;

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

function TMarsToWADConverter.GeneratePalette: boolean;
var
  p: pointer;
  pal: PByteArray;
  size: integer;
  playpal: packed array[0..768 * 14 - 1] of byte;
  colormap: packed array[0..34 * 256 - 1] of byte;
  i: integer;
  r, g, b: LongWord;
begin
  result := ReadFile('GAME.PAL', p, size);
  if not result then
    exit;

  pal := p;
  MARS_CreateDoomPalette(pal, @playpal, @colormap);

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

  wadwriter.AddData('PLAYPAL', @playpal, SizeOf(playpal));
  wadwriter.AddData('COLORMAP', @colormap, SizeOf(colormap));
  memfree(p, size);
end;

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

  memfree(p, size);
end;

function TMarsToWADConverter.GenerateBigFonts: boolean;
const
  NUM_BIG_FONT_COLORS = 3;
var
  imgsize: integer;
  imginp: PByteArray;
  imgout: PByteArray;
  imgoutw: PByteArray;
  p: pointer;
  size: integer;
  i: integer;
  ch: char;
  COLORS: array[0..NUM_BIG_FONT_COLORS - 1] of LongWord;
  cidx: integer;
  pnoise: double;
  c: LongWord;
  r1, g1, b1: LongWord;
  r, g, b: integer;
  x, y: integer;
  fnt: string;
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

  imgsize := SizeOf(BIG_FONT_BUFFER);
  imginp := malloc(imgsize);

  COLORS[0] := $800000;
  COLORS[1] := $808080;
  COLORS[2] := $C47C0C;

  fnt := 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890`~!@#$%^&*()-_=+*/<>.,\[]|;:''"{}';
  imgout := malloc(18 * 21);
  for cidx := 0 to NUM_BIG_FONT_COLORS - 1 do
  begin
    r1 := (COLORS[cidx] shr 16) and $FF;
    g1 := (COLORS[cidx] shr 8) and $FF;
    b1 := COLORS[cidx] and $FF;
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

    for ch := Chr(33) to Chr(128) do
    begin
      fidx := Pos(ch, fnt);
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
          MARS_CreateDoomPatch(imgoutw, w, 21, false, p, size, 4, 1);
          memfree(pointer(imgoutw), 21 * w);
        end
        else
          MARS_CreateDoomPatch(imgout, 18, 21, false, p, size, 4, 1);
      end
      else
      begin
        memset(imgout, MARS_PATCH_BLANC, 18 * 21);
        MARS_CreateDoomPatch(imgout, 5, 21, false, p, size, 4, 1);
      end;
      wadwriter.AddData('BIGF' + Chr(Ord('A') + cidx) + IntToStrzFill(3, Ord(ch)), p, size);
      memfree(p, size);
    end;
  end;

  memfree(pointer(imginp), imgsize);
  memfree(pointer(imgout), 18 * 21);
end;

// Generate DOS font in various colors
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

  COLORS[0] := 192 shl 16 + 14 shl 8 + 14 shl 8;
  COLORS[1] := $FFFFFF;

  // Big dos font
  imgsize := $10000;
  imginp := malloc(imgsize);

  imgout := malloc(14 * 14);
  for cidx := 0 to NUM_DOS_FONT_COLORS - 1 do
  begin
    r1 := (COLORS[cidx] shr 16) and $FF;
    g1 := (COLORS[cidx] shr 8) and $FF;
    b1 := COLORS[cidx] and $FF;
    for i := 0 to imgsize - 1 do
    begin
      if DOS_FONT_BUFFER[i] = 0 then
        imginp[i] := MARS_PATCH_BLANC
      else
      begin
        r := round(r1 * DOS_FONT_BUFFER[i] / 256);
        if r > 255 then
          r := 255;
        g := round(g1 * DOS_FONT_BUFFER[i] / 256);
        if g > 255 then
          g := 255;
        b := round(b1 * DOS_FONT_BUFFER[i] / 256);
        if b > 255 then
          b := 255;
        c := r shl 16 + g shl 8 + b;
        imginp[i] := V_FindAproxColorIndex(@def_palL, c, 1, 255);
      end;
    end;

    for ch := Chr(33) to Chr(128) do
    begin
      x := Ord(ch) mod 16;
      y := Ord(ch) div 16;
      MARS_BltImageBuffer(imginp, 256, 256, imgout, x * 16 + 1, x * 16 + 14, y * 16 + 2, y * 16 + 15);
      MARS_CreateDoomPatch(imgout, 14, 14, false, p, size, 3, 1);
      wadwriter.AddData('DOSF' + Chr(Ord('A') + cidx) + IntToStrzFill(3, Ord(ch)), p, size);
      memfree(p, size);
    end;
  end;

  memfree(pointer(imginp), imgsize);
  memfree(pointer(imgout), 14 * 14);

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
      wadwriter.AddData('DOSS' + Chr(Ord('A') + cidx) + IntToStrzFill(3, Ord(ch)), p, size);
      memfree(p, size);
    end;
  end;

  memfree(pointer(imginp), imgsize);
  memfree(pointer(imgout), 8 * 8);
end;

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
  _convert_music_track(14, 'D_INTER');

  wadwriter.AddSeparator('M_END');

  result := true; 
end;

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

procedure TMarsToWADConverter.ConvertGame;
begin
  Clear;

  wadwriter := TWadWriter.Create;

  GeneratePalette;
  GenerateTranslationTables;
  GenerateBigFonts;
  GenerateDosFonts;
  GenerateDosFonts;
  GenerateMenuTranslation;
  GenerateMusic;
  GenerateSounds;
end;

procedure TMarsToWADConverter.SavetoFile(const fname: string);
begin
  wadwriter.SaveToFile(fname);
end;

procedure TMarsToWADConverter.SavetoStream(const strm: TDStream);
begin
  wadwriter.SaveToStream(strm);
end;

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

