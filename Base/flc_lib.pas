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
//    FLI/FLC file library
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/mars3d/
//------------------------------------------------------------------------------

{$I Mars3D.inc}

unit flc_lib;

interface

uses
  d_delphi;

type
  // FLI Header
  fliheader_t = packed record
    filler1: integer;
    ID: word;
    Frames: word;
    filler2: integer;
    filler3: integer;
    Speed: LongWord;
    filler4: packed array[0..59] of byte;
    oframe1: LongWord;
    filler5: packed array[0..3] of byte;
  end;
  Pfliheader_t = ^fliheader_t;

  // Frames Header
  frameheader_t = packed record
    Size: integer;
    filler1: word;
    Chunks: word;
    filler2: packed array[0..7] of byte; // Pad to 16 Bytes
  end;
  Pframeheader_t = ^frameheader_t;

  // Chunk
  flichunk_t = packed record
    Size: word;
    Zero: word;
    Kind: word;
    Data: byte;
  end;
  Pflichunk_t = ^flichunk_t;

  // Color entry
  rgb_t = packed record
    red, green, blue: byte;
  end;

  // Palette entries
  palettepacket_t = packed record
    FirstColor: byte;
    ColorCount: byte;
    Colors: packed array[0..255] of rgb_t;
  end;
  Ppalettepacket_t = ^palettepacket_t;

  // Fli Palette entries
  flipalentries_t = packed record
    PacketCount: word;
    FirstPacket: palettepacket_t;
  end;
  Pflipalentries_t = ^flipalentries_t;

  flidatapacket_t = packed array[0..256] of byte;
  Pflidatapacket_t = ^flidatapacket_t;

  // Draw Packet
  flidrawpacket_t = packed record
    IncX: byte;
    Size: byte;
    Data: flidatapacket_t;
  end;
  Pflidrawpacket_t = ^flidrawpacket_t;

  // flidrawlines_t
  flidrawlines_t = packed record
    PacketCount: byte;
    FirstPacket: flidrawpacket_t;
  end;
  Pflidrawlines_t = ^flidrawlines_t;

  // Fli Draw
  flidraw_t = packed record
    DrawLine: word;
    DrawHeight: word;
    FirstLine: flidrawlines_t;
  end;
  Pflidraw_t = ^flidraw_t;

  // Brun Packet
  brunpacket_t = packed record
    Size: byte;
    Data: flidatapacket_t;
  end;
  Pbrunpacket_t = ^brunpacket_t;

  // Fli Brun
  flibrun_t = packed record
    PacketCount: byte;
    FirstPacket: flidrawpacket_t;
  end;
  Pflibrun_t = ^flibrun_t;

  bitmapdata_t = packed array[0..199, 0..319] of byte;  // Virtual screen buffer
  Pbitmapdata_t = ^bitmapdata_t;

type
  flipalette_t = array[0..255] of LongWord;
  Pflipalette_t = ^flipalette_t;

const
  FLI_WIDTH = 320;
  FLI_HEIGHT = 200;

const
  FLI_COLOR256 = 4;
  FLI_SS2 = 7;
  FLI_COLOR = 11;
  FLI_LC = 12;
  FLI_BLACK = 13;
  FLI_BRUN = 15;
  FLI_COPY = 16;
  FLI_PSTAMP = 18;

type
  fliscreen8_t = packed array[0..FLI_WIDTH * FLI_HEIGHT - 1] of byte;
  Pfliscreen8_t = ^fliscreen8_t;

  fliscreen32_t = packed array[0..FLI_WIDTH * FLI_HEIGHT - 1] of LongWord;
  Pfliscreen32_t = ^fliscreen32_t;

  TFLIFile = class(TObject)
  private
    fActive: boolean;           // FLI Running
    fFliFile: string;           // FLI File Name
    fOpen: boolean;             // File open
    fLoading: boolean;          // Switch on while loading a frame
    fInterval: word;            // Timer duration
    fLoop: boolean;             // loop at last frame
    PalCount: word;             // Number of Palette Chunck : skip PaletteEntries if possible
    FirstPal: boolean;          // Flag for Palette Chunck count
    Fli: file;                  // File handle
    fFrame: word;               // current frame
    fFrameCount: word;          // total frames
    fSpeed: word;               // speed of FLI
    FirstFrame: integer;        // File position of the first frame
    BitmapData: Pbitmapdata_t;  // Drawing buffer
    fPalette: flipalette_t;     // 256 colors palette
  protected
    procedure SetActive(Value: boolean);
    procedure SetFliFile(Value: string);
    procedure SetInterval(Value: word);
    procedure DrawFrame(const FrameData: Pointer; Chunks: word);
    procedure FliPalette(const PaletteData: Pflipalentries_t);
    procedure FliPalette256(const PaletteData: Pflipalentries_t);
    procedure FliDrawPartial(const DrawData: Pflidraw_t);
    procedure FliDrawPartialW(var DrawData);
    procedure FliBrun(const BrunData: Pflibrun_t);
    procedure FliCopy(const CopyData: Pbitmapdata_t);
    function UnPackData(var x: smallint; y: smallint; const Data: Pflidatapacket_t;
      Size: word): word;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure NextFrame;
    procedure GetPalette(const pl: Pflipalette_t);
    function GetFrameImage8(const frm: integer; const scn8: Pfliscreen8_t): boolean;
    function GetFrameImage32(const frm: integer; const scn32: Pfliscreen32_t): boolean;
  published
    property Frame: word read fFrame;
    property FrameCount: word read fFrameCount;
    property Active: boolean read fActive write SetActive;
    property FileName: string read fFliFile write SetFliFile;
    property Interval: word read fInterval write SetInterval stored False;
    property Loop: boolean read fLoop write fLoop;
  end;

implementation

uses
  i_system;

//==============================================================================
//
// TFLIFile.Create
//
//==============================================================================
constructor TFLIFile.Create;
begin
  inherited Create;

  New(BitmapData);

  fSpeed := 0;
  fOpen := False;
  fLoading := False;
  fLoop := True;
end;

//==============================================================================
//
// TFLIFile.Destroy
//
//==============================================================================
destructor TFLIFile.Destroy;
begin
  Active := False;
  if fOpen then
    {$I-}
    CloseFile(Fli);
    {$I+}
  Dispose(BitmapData);
  inherited Destroy;
end;

//==============================================================================
//
// TFLIFile.SetActive
//
//==============================================================================
procedure TFLIFile.SetActive(Value: boolean);
begin
  if fActive = Value then
    Exit;
  fActive := Value;
  if Value and (FileName <> '') then
    Interval := fSpeed
  else
    Interval := 0;
end;

//==============================================================================
//
// TFLIFile.SetFliFile
//
//==============================================================================
procedure TFLIFile.SetFliFile(Value: string);
var
  Header: fliheader_t;
begin
  Active := False;
  if fOpen then
  begin
    {$I-}
    CloseFile(Fli);
    {$I+}
    fOpen := False;
  end;
  fFliFile := Value;
  if Value = '' then
  begin
    fSpeed := 0;
    fFrameCount := 0;
    fFrame := 0;
    PalCount := 0;
    exit;
  end;

  FileMode := 0;
  AssignFile(Fli, Value);
  {$I-}
  Reset(Fli, 1);
  {$I+}
  if IOResult <> 0 then
  begin
    I_Warning('TFLIFile.SetFliFile(): Can not open file "%s"', [Value]);
    fFliFile := '';
    fSpeed := 0;
    fFrameCount := 0;
    fFrame := 0;
    PalCount := 0;
    exit;
  end;
  fopen := True;
  BlockRead(Fli, Header, SizeOf(Header));
  if (Header.ID = $AF11) or (Header.ID = $AF12) then
  begin
    fSpeed := Header.Speed;
    fFrameCount := Header.Frames;
    fFrame := 0;
    PalCount := 0;
    FirstPal := True;
    if Header.ID = $AF11 then
      FirstFrame := FilePos(Fli)
    else
    begin
      FirstFrame := Header.oframe1;
      Seek(Fli, FirstFrame);
    end;
    NextFrame;
    FirstPal := False;
  end;
end;

//==============================================================================
//
// TFLIFile.SetInterval
//
//==============================================================================
procedure TFLIFile.SetInterval(Value: word);
begin
  fInterval := Value;
end;

//==============================================================================
//
// TFLIFile.NextFrame
//
//==============================================================================
procedure TFLIFile.NextFrame;
var
  FrameHeader: frameheader_t;
  FrameSize: word;
  FrameData: pointer;
begin
  if fFliFile = '' then
    Exit;

  BlockRead(Fli, FrameHeader, SizeOf(FrameHeader));
  FrameSize := FrameHeader.Size - SizeOf(FrameHeader);
  GetMem(FrameData, FrameSize);
  BlockRead(Fli, FrameData^, FrameSize);
  DrawFrame(FrameData, FrameHeader.Chunks);
  FreeMem(FrameData, FrameSize);

  Inc(fFrame);
  if fFrame = fFrameCount then
  begin
    Seek(Fli, FirstFrame);
    fFrame := 1;
    Active := Loop;
  end;
end;

//==============================================================================
//
// TFLIFile.DrawFrame
//
//==============================================================================
procedure TFLIFile.DrawFrame(const FrameData: Pointer; Chunks: word);
var
  Chunk: Pflichunk_t;
begin
  Chunk := FrameData;
  while Chunks > 0 do
  begin
    case Chunk.Kind of
      FLI_COLOR:
        FliPalette(@Chunk.Data);
      FLI_COLOR256:
        FliPalette256(@Chunk.Data);
      FLI_LC:
        FliDrawPartial(@Chunk.Data);
      FLI_SS2:
        FliDrawPartialW(Chunk.Data);
      FLI_PSTAMP:
        ;
      FLI_BRUN:
        FliBrun(@Chunk.Data);
      FLI_BLACK:
        FillChar(BitmapData^, SizeOf(bitmapdata_t), 0);
      FLI_COPY:
        FliCopy(@Chunk.Data);
      else
      begin
        I_Warning('TFLIFile.DrawFrame(): Invalide Chunk type "' + itoa(Chunk.Kind) +
            '" (Size=' + itoa(Chunk.Size) + ')');
        active := False;
      end;
    end;
    if Chunk.Zero <> 0 then
    begin
      I_Warning('TFLIFile.DrawFrame(): Chunk Size trop grand: ' + itoa(Chunk.Zero));
      active := False;
    end;
    Chunk := Pflichunk_t(integer(Chunk) + Chunk.Size);
    Dec(Chunks);
  end;
end;

//==============================================================================
//
// TFLIFile.FliPalette
//
//==============================================================================
procedure TFLIFile.FliPalette(const PaletteData: Pflipalentries_t);
var
  Color: word;
  Packets: smallint;
  Packet: Ppalettepacket_t;
  Count: smallint;
  i: smallint;
  r, g, b: byte;
begin
  if FirstPal then
    Inc(PalCount);

  Color := 0;
  Packets := PaletteData.PacketCount;
  Packet := @PaletteData.FirstPacket;
  while Packets > 0 do
  begin
    Dec(Packets);
    Inc(Color, Packet.FirstColor);
    Count := Packet.ColorCount;
    if Count = 0 then
      Count := 256;
    i := 0;
    while i < Count do
    begin
      r := Packet.Colors[i].red shl 2;
      g := Packet.Colors[i].Green shl 2;
      b := Packet.Colors[i].Blue shl 2;
      fpalette[Color + i] := b + g shl 8 + r shl 16;
      Inc(i);
    end;
  end;
end;

//==============================================================================
//
// TFLIFile.FliPalette256
//
//==============================================================================
procedure TFLIFile.FliPalette256(const PaletteData: Pflipalentries_t);
var
  Color: word;
  Packets: smallint;
  Packet: Ppalettepacket_t;
  Count: smallint;
  i: smallint;
  r, g, b: byte;
begin
  if FirstPal then
    Inc(PalCount);

  Color := 0;
  Packets := PaletteData.PacketCount;
  Packet := @PaletteData.FirstPacket;
  while Packets > 0 do
  begin
    Dec(Packets);
    Inc(Color, Packet.FirstColor);
    Count := Packet.ColorCount;
    if Count = 0 then
      Count := 256;
    i := 0;
    while i < Count do
    begin
      r := Packet.Colors[i].red;
      g := Packet.Colors[i].Green;
      b := Packet.Colors[i].Blue;
      fpalette[Color + i] := b + g shl 8 + r shl 16;
      Inc(i);
    end;
  end;
end;

//==============================================================================
//
// TFLIFile.UnPackData
//
//==============================================================================
function TFLIFile.UnPackData(var x: smallint; y: smallint; const Data: Pflidatapacket_t;
  Size: word): word;
begin
  if Size > 127 then
  begin // repeat
    FillChar(BitmapData[y, x], 256 - Size, Data[0]);
    Inc(x, 256 - Size);
    Result := 1;
  end
  else
  begin // copy
    Move(Data^, BitmapData[y, x], Size);
    Inc(x, Size);
    Result := Size;
  end;
end;

//==============================================================================
//
// TFLIFile.FliDrawPartial
//
//==============================================================================
procedure TFLIFile.FliDrawPartial(const DrawData: Pflidraw_t);
var
  Packet: Pflidrawpacket_t;
  x, y: smallint;
  h, packets: word;
  DrawLines: Pflidrawlines_t;
begin
  y := 199 - DrawData.DrawLine;
  h := DrawData.DrawHeight;
  DrawLines := @DrawData.FirstLine;

  while h > 0 do
  begin
    packets := DrawLines.PacketCount;
    Packet := @DrawLines.FirstPacket;
    x := 0;
    while packets > 0 do
    begin
      Inc(x, Packet.IncX);
      Packet := @Packet.Data[UnPackData(x, y, @Packet.Data, Packet.Size)];
      Dec(packets);
    end;
    Dec(y);
    DrawLines := @Packet^;
    Dec(h);
  end;
end;

//==============================================================================
//
// TFLIFile.FliDrawPartialW
//
//==============================================================================
procedure TFLIFile.FliDrawPartialW(var DrawData);
var
  fpos: integer;
  i, x, y: smallint;
  lines: word;
  cmd, cmd2: SmallInt;
  v1, v2: byte;

  function _getc: byte;
  var
    p: PByteArray;
  begin
    p := @DrawData;
    result := p[fpos];
    inc(fpos);
  end;

  function _getw: word;
  var
    p: PByteArray;
    w: PWordArray;
  begin
    p := @DrawData;
    p := @p[fpos];
    w := PWordArray(p);
    result := w[0];
    inc(fpos, 2);
  end;

begin
  fpos := 0;
  lines := _getw;
  y := 0;
  cmd := 0;
  while lines > 0 do
  begin
    // process the prefix commands
    while true do
    begin
      cmd := _getw;
      if cmd and $8000 <> 0 then
      begin
        if cmd and $4000 <> 0 then
        begin
          // skip down some lines
          y := y - cmd;
        end
        else
        begin
          // set last pixel value
          BitmapData[199 - y, 319] := cmd and $FF;
        end;
      end
      else
        break;
    end;

    // start decoding the line
    x := 0;
    while cmd > 0 do
    begin
      x := x + _getc;
      cmd2 := ShortInt(_getc);
      if cmd2 > 0 then
      begin
        // copy straight
        for i := 0 to 2 * cmd2 - 1 do
          BitmapData[199 - y, x + i] := _getc;
        x := x + 2 * cmd2;
      end
      else
      begin
        // repeat
        cmd2 := -cmd2;
        v1 := _getc;
        v2 := _getc;
        repeat
          BitmapData[199 - y, x] := v1;
          inc(x);
          BitmapData[199 - y, x] := v2;
          inc(x);
          dec(cmd2);
        until cmd2 = 0;
      end;
      dec(cmd);
    end;
    Inc(y);
    dec(lines);
   end;
 end;

//==============================================================================
//
// TFLIFile.FliBrun
//
//==============================================================================
procedure TFLIFile.FliBrun(const BrunData: Pflibrun_t);
var
  x, y: smallint;
  Packets: smallint;
  Packet: Pbrunpacket_t;
  FliBrun: Pflibrun_t;
begin
  FliBrun := BrunData;
  y := 199;
  while y >= 0 do
  begin
    Packets := FliBrun.PacketCount;
    Packet := @FliBrun.FirstPacket;
    x := 0;
    while Packets > 0 do
    begin
      Packet := @Packet.Data[UnPackData(x, y, @Packet.Data, 256 - Packet.Size)];
      Dec(Packets);
    end;
    Dec(y);
    FliBrun := @Packet^;
  end;
end;

//==============================================================================
//
// TFLIFile.FliCopy
//
//==============================================================================
procedure TFLIFile.FliCopy(const CopyData: Pbitmapdata_t);
var
  i: integer;
begin
  i := 199;
  while i >= 0 do
  begin
    Move(CopyData[i, 0], BitmapData[199 - i, 0], 320);
    Dec(i);
  end;
end;

//==============================================================================
//
// TFLIFile.GetPalette
//
//==============================================================================
procedure TFLIFile.GetPalette(const pl: Pflipalette_t);
var
  i: integer;
begin
  for i := 0 to 255 do
    pl[i] := fpalette[i];
end;

//==============================================================================
//
// TFLIFile.GetFrameImage8
//
//==============================================================================
function TFLIFile.GetFrameImage8(const frm: integer; const scn8: Pfliscreen8_t): boolean;
var
  i: integer;
begin
  if not IsIntegerInRange(frm, 0, fframecount - 1) then
  begin
    Result := False;
    Exit;
  end;

  while fFrame < frm do
    NextFrame;
  if fFrame <> frm then
  begin
    SetFliFile(fFliFile);
    while fFrame < frm do
      NextFrame;
  end;

  if fFrame <> frm then
    Result := False
  else
  begin
    for i := 0 to 199 do
      memcpy(@scn8[i * 320], @BitmapData[199 - i][0], 320);
    Result := True;
  end;
end;

//==============================================================================
//
// TFLIFile.GetFrameImage32
//
//==============================================================================
function TFLIFile.GetFrameImage32(const frm: integer; const scn32: Pfliscreen32_t): boolean;
var
  i: Integer;
begin
  if not IsIntegerInRange(frm, 0, fframecount - 1) then
  begin
    Result := False;
    Exit;
  end;

  while fFrame < frm do
    NextFrame;
  if fFrame <> frm then
  begin
    SetFliFile(fFliFile);
    while fFrame < frm do
      NextFrame;
  end;

  if fFrame <> frm then
    Result := False
  else
  begin
    for i := 0 to 320 * 200 - 1 do
      scn32[i] := fpalette[BitmapData[199 - i div 320][i mod 320]];
    Result := True;
  end;
end;

end.

