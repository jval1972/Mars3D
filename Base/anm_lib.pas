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
//  Deluxe paint animation library (ANM files)
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/mars3d/
//------------------------------------------------------------------------------

{$I Mars3D.inc}

unit anm_lib;

interface

uses
  d_delphi;

type
  ULONG = LongWord;
  PULONG = ^ULONG;
  ULONGARRAY = packed array[0..$FFF] of ULONG;
  PULONGARRAY = ^ULONGARRAY;

  UWORD = Word;
  PUWORD = ^UWORD;
  UWORDARRAY = packed array[0..$FFF] of UWORD;
  PUWORDARRAY = ^UWORDARRAY;

  UBYTE = Byte;
  PUBYTE = ^UBYTE;
  UBYTEARRAY = packed array[0..$FFF] of UBYTE;
  PUBYTEARRAY = ^UBYTEARRAY;

  SBYTE = ShortInt;
  PSBYTE = ^SBYTE;
  SBYTEARRAY = packed array[0..$FFF] of SBYTE;
  PSBYTEARRAY = ^SBYTEARRAY;

  SWORD = SmallInt;
  PSWORD = ^SWORD;
  SWORDARRAY = packed array[0..$FFF] of SWORD;
  PSWORDARRAY = ^SWORDARRAY;

  LONG = Integer;
  PLONG = ^LONG;
  LONGARRAY = packed array[0..$FFF] of LONG;
  PLONGARRAY = ^LONGARRAY;

// structure declarations for deluxe animate large page files
type
  anmfileheader_t = packed record
    id: ULONG;              // 4 character ID == "LPF "
    maxLps: UWORD;          // max # largePages allowed. 256 FOR NOW.
    nLps: UWORD;            // # largePages in this file.
    nRecords: ULONG;        // # records in this file.  65534 is current limit plus
                            // one for last-to-first delta for looping the animation
    maxRecsPerLp: UWORD;    // # records permitted in an lp. 256 FOR NOW.
    lpfTableOffset: UWORD;  // Absolute Seek position of lpfTable.  1280 FOR NOW.
                            // The lpf Table is an array of 256 large page structures
                            // that is used to facilitate finding records in an anim
                            // file without having to seek through all of the Large
                            // Pages to find which one a specific record lives in.
    contentType: ULONG;     // 4 character ID == "ANIM"
    width: UWORD;           // Width of screen in pixels.
    height: UWORD;          // Height of screen in pixels.
    variant: UBYTE;         // 0==ANIM.
    version: UBYTE;         // 0==frame rate is multiple of 18 cycles/sec.
                            // 1==frame rate is multiple of 70 cycles/sec.
    hasLastDelta: UBYTE;    // 1==Last record is a delta from last-to-first frame.
    lastDeltaValid: UBYTE;  // 0==The last-to-first delta (if present) hasn't been
                            // updated to match the current first&last frames,  so it
                            // should be ignored.
    pixelType: UBYTE;       // 0==256 color.
    CompressionType: UBYTE; // 1==(RunSkipDump) Only one used FOR NOW.
    otherRecsPerFrm: UBYTE; // 0 FOR NOW.
    bitmaptype: UBYTE;      // 1==320x200, 256-color.  Only one implemented so far.
    recordTypes: array[0..31] of UBYTE; // Not yet implemented.
    nFrames: ULONG;         // In case future version adds other records at end of
                            // file, we still know how many actual frames.
                            // NOTE: DOES include last-to-first delta when present.
    framesPerSecond: UWORD; // Number of frames to play per second.
    pad2: array[0..28] of UWORD;  // 58 bytes of filler to round up to 128 bytes total.
  end;
  Panmfileheader_t = ^anmfileheader_t;

// this is the format of an large page structure
type
  anmdescriptor_t = packed record
    baseRecord: UWORD;  // Number of first record in this large page.
    nRecords: UWORD;    // Number of records in lp.
                        // bit 15 of "nRecords" == "has continuation from previous lp".
                        // bit 14 of "nRecords" == "final record continues on next lp".
    nBytes: UWORD;      // Total number of bytes of contents, excluding header. */
  end;
  Panmdescriptor_t = ^anmdescriptor_t;

type
  anmpalette_t = array[0..255] of LongWord;
  Panmpalette_t = ^anmpalette_t;

const
  ANM_WIDTH = 320;
  ANM_HEIGHT = 200;

type
  anmscreen8_t = packed array[0..ANM_WIDTH * ANM_HEIGHT - 1] of byte;
  Panmscreen8_t = ^anmscreen8_t;

  anmscreen32_t = packed array[0..ANM_WIDTH * ANM_HEIGHT - 1] of LongWord;
  Panmscreen32_t = ^anmscreen32_t;

type
  TANMFile = class(TObject)
  private
    fstream: TDStream;
    fpalette: anmpalette_t;
    oldstreampos: integer;
    lpheader: anmfileheader_t;    // file header will be loaded into this structure
    LpArray: packed array[0..255] of anmdescriptor_t; // arrays of large page structs used to find frames
    screen: Panmscreen8_t;  // pointer to the screen
    curlpnum: UWORD;  // initialize to an invalid Large page number
    curlp: anmdescriptor_t; // header of large page currently in memory
    thepage: PUWORD;  // pointer to the buffer where current large page is loaded
    fframecount: UWORD;
  protected
    function GetFrameCount: integer;
    function RGBSwap(buffer: LongWord): LongWord;
    function findpage(framenumber: UWORD): UWORD;
    procedure loadpage(pagenumber: UWORD; pagepointer: PUWORD);
    procedure CPlayRunSkipDump(srcP, dstP: PSBYTE);
    procedure renderframe(framenumber: UWORD; pagepointer: PUWORD);
    procedure drawframe(framenumber: UWORD);
    procedure initanm;
    procedure clearanm;
  public
    constructor Create(const astream: TDStream); virtual;
    destructor Destroy; override;
    procedure GetPalette(const pl: Panmpalette_t);
    function GetFrameImage8(const frm: integer; const scn8: Panmscreen8_t): boolean;
    function GetFrameImage32(const frm: integer; const scn32: Panmscreen32_t): boolean;
    property FrameCount: integer read GetFrameCount;
  end;

//==============================================================================
//
// ANM_QueryNumFrames
//
//==============================================================================
function ANM_QueryNumFrames(const anmfile: string): integer;

implementation

//==============================================================================
//
// TANMFile.Create
//
//==============================================================================
constructor TANMFile.Create(const astream: TDStream);
begin
  fstream := astream;
  oldstreampos := astream.position;
  initanm;
  inherited Create;
end;

//==============================================================================
//
// TANMFile.clearanm
//
//==============================================================================
procedure TANMFile.clearanm;
begin
  memfree(pointer(thepage), $10000); // deallocate page buffer
  memfree(pointer(screen), SizeOf(anmscreen8_t));
  fstream.Seek(oldstreampos, sFromBeginning);
end;

//==============================================================================
//
// TANMFile.Destroy
//
//==============================================================================
destructor TANMFile.Destroy;
begin
  clearanm;
  inherited Destroy;
end;

//==============================================================================
//
// TANMFile.GetFrameCount
//
//==============================================================================
function TANMFile.GetFrameCount: integer;
begin
  Result := fframecount;
end;

//==============================================================================
//
// TANMFile.RGBSwap
//
//==============================================================================
function TANMFile.RGBSwap(buffer: LongWord): LongWord;
type
  RGBA_t = packed array[0..3] of byte;
var
  x: byte;
  rgba: RGBA_t;
begin
  memcpy(@rgba, @buffer, 4);
  x := rgba[0];
  rgba[0] := rgba[2];
  rgba[2] := x;
  memcpy(@Result, @rgba, 4);
end;

//==============================================================================
//
// TANMFile.GetPalette
//
//==============================================================================
procedure TANMFile.GetPalette(const pl: Panmpalette_t);
var
  i: integer;
begin
  for i := 0 to 255 do
    pl[i] := fpalette[i];
end;

//==============================================================================
//
// TANMFile.GetFrameImage8
//
//==============================================================================
function TANMFile.GetFrameImage8(const frm: integer; const scn8: Panmscreen8_t): boolean;
var
  i: integer;
begin
  if frm >= fframecount then
  begin
    Result := False;
    Exit;
  end;

  for i := 0 to frm do
    drawframe(i);

  memcpy(scn8, screen, SizeOf(anmscreen8_t));

  Result := True;
end;

//==============================================================================
//
// TANMFile.GetFrameImage32
//
//==============================================================================
function TANMFile.GetFrameImage32(const frm: integer; const scn32: Panmscreen32_t): boolean;
var
  i: Integer;
begin
  if frm >= fframecount then
  begin
    Result := False;
    Exit;
  end;

  for i := 0 to frm do
    drawframe(i);

  for i := 0 to 320 * 200 - 1 do
    scn32[i] := fpalette[screen[i]];

  Result := True;
end;

//==============================================================================
// TANMFile.findpage
//
// given a frame number return the large page number it resides in
//
//==============================================================================
function TANMFile.findpage(framenumber: UWORD): UWORD;
begin
  result := 0;
  while result < lpheader.nLps do
  begin
    if(LpArray[result].baseRecord <= framenumber) and (LpArray[result].baseRecord + LpArray[result].nRecords > framenumber) then
      exit;
    Inc(result);
  end;
end;

//==============================================================================
// TANMFile.loadpage
//
// seek out and load in the large page specified
//
//==============================================================================
procedure TANMFile.loadpage(pagenumber: UWORD; pagepointer: PUWORD);
begin
  if curlpnum <> pagenumber then
  begin
    curlpnum := pagenumber;
    fstream.Seek($0B00 + pagenumber * $10000, sFromBeginning);
    fstream.Read(curlp, SizeOf(anmdescriptor_t));
    fstream.Seek(2, sFromCurrent); // skip empty word
    fstream.Read(pagepointer^, curlp.nBytes + (curlp.nRecords * 2));
  end;
end;

//==============================================================================
// TANMFile.CPlayRunSkipDump
//
// This version of the decompressor is here for portability to non PC's
//
//==============================================================================
procedure TANMFile.CPlayRunSkipDump(srcP, dstP: PSBYTE);
// srcP points at first sequence in Body
// dstP points at pixel #0 on screen.
var
  cnt: SBYTE;
  wordCnt: UWORD;
  byteCnt: UBYTE;
  pixel: UBYTE;
label
  nextOp,
  dump,
  run,
  longOp,
  notLongSkip,
  longRun;
begin
nextOp:
  cnt := srcP^;
  Inc(srcP);
  if cnt > 0 then
    goto dump;
  if cnt = 0 then
    goto run;
  cnt := cnt - $80;
  if cnt = 0 then
    goto longOp;

// shortSkip
    Inc(dstP, cnt);  // adding 7-bit count to 32-bit pointer
    goto nextOp;

dump:
    repeat
      dstP^ := srcP^;
      Inc(dstP);
      Inc(srcP);
      dec(cnt);
    until cnt = 0;

    goto nextOp;

run:
    byteCnt := PUBYTE(srcP)^; // 8-bit unsigned count
    wordCnt := byteCnt;
    Inc(srcP);
    pixel := srcP^;
    Inc(srcP);
    repeat
      dstP^ := pixel;
      Inc(dstP);
      Dec(wordCnt);
    until wordCnt = 0;

    goto nextOp;

longOp:
    wordCnt := PUWORD(srcP)^;
    Inc(srcP, SizeOf(wordCnt));
    if PSWORD(@wordCnt)^ <= 0 then
      goto notLongSkip; // Do SIGNED test.

// longSkip.
    Inc(dstP, wordCnt);
    goto nextOp;

notLongSkip:
    if wordCnt = 0 then
      exit;
    wordCnt := wordCnt - $8000; // Remove sign bit.
    if wordCnt >= $4000 then
      goto longRun;

// longDump.
    repeat
      dstP^ := srcP^;
      Inc(dstP);
      Inc(srcP);
      Dec(wordCnt);
    until wordCnt = 0;

    goto nextOp;

longRun:
    wordCnt := wordCnt - $4000; // Clear "longRun" bit.
    pixel := srcP^;
    Inc(srcP);
    repeat
      dstP^ := pixel;
      Inc(dstP);
      Dec(wordCnt);
    until wordCnt = 0;

    goto nextOp;
end;

//==============================================================================
// TANMFile.renderframe
//
// draw the frame sepcified from the large page in the buffer pointed to
//
//==============================================================================
procedure TANMFile.renderframe(framenumber: UWORD; pagepointer: PUWORD);
var
  ofs: UWORD;
  destframe: UWORD;
  pnt: PUBYTE;
  i: Integer;
begin
  destframe := framenumber - curlp.baseRecord;

  ofs := 0;
  for i := 0 to destframe - 1 do
    ofs := ofs + PUWORDARRAY(pagepointer)[i];

  pnt := PUBYTE(pagepointer);

  Inc(pnt, curlp.nRecords * 2 + ofs);

  if PUBYTEARRAY(pnt)[1] <> 0 then
    Inc(pnt, 4 + PUWORDARRAY(pnt)[1] + (PUWORDARRAY(pnt)[1] and 1))
  else
    Inc(pnt, 4);

  CPlayRunSkipDump(PSBYTE(pnt), PSBYTE(screen));
end;

//==============================================================================
// TANMFile.drawframe
//
// high level frame draw routine
//
//==============================================================================
procedure TANMFile.drawframe(framenumber: UWORD);
begin
  loadpage(findpage(framenumber), thepage);
  renderframe(framenumber, thepage);
end;

//==============================================================================
//
// TANMFile.initanm
//
//==============================================================================
procedure TANMFile.initanm;
var
  i: integer;
begin
  curlpnum := $FFFF;
  thepage := mallocz($10000); // allocate page buffer
  screen := mallocz(SizeOf(anmscreen8_t));

  // reset file position
  fstream.Seek(0, sFromBeginning);

  // read the anim file header
  fstream.Read(lpheader, SizeOf(anmfileheader_t));
  fframecount := UWORD(lpheader.nRecords);

  // read palette
  fstream.Seek(128, sFromCurrent);
  fstream.Read(fpalette, SizeOf(anmpalette_t));
  for i := 0 to 255 do
    fpalette[i] := RGBSwap(fpalette[i]);

  // read in large page descriptors
  fstream.Read(LpArray, 256 * SizeOf(anmdescriptor_t));
end;

//==============================================================================
//
// ANM_QueryNumFrames
//
//==============================================================================
function ANM_QueryNumFrames(const anmfile: string): integer;
var
  anm: TANMFile;
  anmstrm: TFile;
begin
  if anmfile = '' then
  begin
    Result := 0;
    Exit;
  end;

  if not fexists(anmfile) then
  begin
    Result := 0;
    Exit;
  end;

  anmstrm := TFile.Create(anmfile, fOpenReadOnly);
  anm := TANMFile.Create(anmstrm);
  Result := anm.FrameCount;
  anm.Free;
  anmstrm.Free;
end;

end.

