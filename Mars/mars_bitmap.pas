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

unit mars_bitmap;

interface

uses
  d_delphi;

procedure MARS_RotatebitmapBuffer90(const buf: PByteArray; const w, h: integer);

procedure MARS_FlipbitmapbufferHorz(const buf: PByteArray; const w, h: integer);

procedure MARS_BltImageBuffer(const inbuf: PByteArray; const inw, inh: integer;
  const outbuf: PByteArray; const x1, x2: integer; const y1, y2: integer);

procedure MARS_ColorReplace(const buf: PByteArray; const w, h: integer; const oldc, newc: byte);

type
  TMarsBitmap = class
  private
    fwidth, fheight: integer;
    fimg: PByteArray;
    function pos2idx(const x, y: integer): integer;
  protected
    procedure Resize(const awidth, aheight: integer); virtual;
    procedure SetWidth(const awidth: integer); virtual;
    procedure SetHeight(const aheight: integer); virtual;
    function GetPixel(x, y: integer): byte; virtual;
    procedure SetPixel(x, y: integer; const apixel: byte); virtual;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure ApplyTranslationTable(const trans: PByteArray);
    procedure AttachImage(const buf: PByteArray; const awidth, aheight: integer);
    procedure Clear(const color: byte);
    procedure RightCrop(const color: byte);
    property width: integer read fwidth write SetWidth;
    property height: integer read fheight write SetHeight;
    property Pixels[x, y: integer]: byte read GetPixel write SetPixel; default;
    property Image: PByteArray read fimg;
  end;

implementation

procedure MARS_RotatebitmapBuffer90(const buf: PByteArray; const w, h: integer);
var
  i, j: integer;
  img: PByteArray;
  b: byte;
begin
  img := mallocz(w * h);
  for i := 0 to w - 1 do
    for j := 0 to h - 1 do
    begin
      b := buf[j * w + i];
      img[i * h + j] := b;
    end;
  for i := 0 to w - 1 do
    for j := 0 to h - 1 do
    begin
      b := img[j * w + i];
      buf[j * w + i] := b;
    end;
  memfree(pointer(img), w * h);
end;

procedure MARS_FlipbitmapbufferHorz(const buf: PByteArray; const w, h: integer);
var
  i, j: integer;
  img: PByteArray;
  b: byte;
begin
  img := mallocz(w * h);
  for i := 0 to w - 1 do
    for j := 0 to h - 1 do
    begin
      b := buf[j * w + i];
      img[(h - j - 1) * w + i] := b;
    end;
  for i := 0 to w - 1 do
    for j := 0 to h - 1 do
    begin
      b := img[j * w + i];
      buf[j * w + i] := b;
    end;
  memfree(pointer(img), w * h);
end;

procedure MARS_BltImageBuffer(const inbuf: PByteArray; const inw, inh: integer;
  const outbuf: PByteArray; const x1, x2: integer; const y1, y2: integer);
var
  i, j: integer;
  b: byte;
  outh: integer;
begin
  outh := y2 - y1 + 1;
  for i := x1 to x2 do
    for j := y1 to y2 do
    begin
      b := inbuf[i * inh + j];
      outbuf[(i - x1) * outh + (j - y1)] := b;

//      b := inbuf[i + j * inw];
//      outbuf[(i - x1) + (j - y1) * (x2 - x1)] := b;
//      b := inbuf[i + j * inw];
//      outbuf[(i - x1) * (y2 - y1) + (j - y1)] := b;
    end;
end;

procedure MARS_ColorReplace(const buf: PByteArray; const w, h: integer; const oldc, newc: byte);
var
  i: integer;
begin
  for i := 0 to w * h - 1 do
    if buf[i] = oldc then
      buf[i] := newc;
end;

// TMarsBitmap

constructor TMarsBitmap.Create;
begin
  fwidth := 0;
  fheight := 0;
  fimg := nil;
  inherited;
end;

destructor TMarsBitmap.Destroy;
begin
  if fimg <> nil then
    memfree(pointer(fimg), fwidth * fheight);
  inherited;
end;

procedure TMarsBitmap.ApplyTranslationTable(const trans: PByteArray);
var
  i: integer;
begin
  for i := 0 to fwidth * fheight - 1 do
    fimg[i] := trans[fimg[i]];
end;

procedure TMarsBitmap.AttachImage(const buf: PByteArray; const awidth, aheight: integer);
var
  i: integer;
begin
  SetWidth(awidth);
  SetHeight(aheight);
  for i := 0 to fwidth * fheight - 1 do
    fimg[i] := buf[i];
end;

procedure TMarsBitmap.Clear(const color: byte);
var
  i: integer;
begin
  for i := 0 to fwidth * fheight - 1 do
    fimg[i] := color;
end;

procedure TMarsBitmap.RightCrop(const color: byte);

  function _do_crop_right: boolean;
  var
    i: integer;
    c: integer;
  begin
    if fwidth = 0 then
    begin
      result := false;
      exit;
    end;
    result := true;
    for i := 0 to fheight - 1 do
    begin
      c := fimg[pos2idx(i, fwidth - 1)];
      if c <> color then
      begin
        result := false;
        exit;
      end;
    end;
    SetWidth(fwidth - 1);
  end;

begin
  repeat until not _do_crop_right;
end;

function TMarsBitmap.pos2idx(const x, y: integer): integer;
begin
  result := x * fheight + y;
end;

procedure TMarsBitmap.Resize(const awidth, aheight: integer);
var
  oldsz, newsz: integer;
begin
  if (awidth = fwidth) and (aheight = fheight) then
    exit;
  oldsz := fwidth * fheight;
  fwidth := awidth;
  fheight := aheight;
  newsz := fwidth * fheight;
  if newsz <> oldsz then
    realloc(pointer(fimg), oldsz, newsz);
end;

procedure TMarsBitmap.SetWidth(const awidth: integer);
var
  oldsz, newsz: integer;
begin
  if awidth = fwidth then
    exit;
  oldsz := fwidth * fheight;
  fwidth := awidth;
  newsz := fwidth * fheight;
  if newsz <> oldsz then
    realloc(pointer(fimg), oldsz, newsz);
end;

procedure TMarsBitmap.SetHeight(const aheight: integer);
var
  oldsz, newsz: integer;
begin
  if aheight = fheight then
    exit;
  oldsz := fwidth * fheight;
  fheight := aheight;
  newsz := fwidth * fheight;
  if newsz <> oldsz then
    realloc(pointer(fimg), oldsz, newsz);
end;

function TMarsBitmap.GetPixel(x, y: integer): byte;
begin
  if not IsIntegerInRange(x, 0, fwidth - 1) then
  begin
    result := 0;
    exit;
  end;
  if not IsIntegerInRange(y, 0, fheight - 1) then
  begin
    result := 0;
    exit;
  end;
  result := fimg[pos2idx(x, y)];
end;

procedure TMarsBitmap.SetPixel(x, y: integer; const apixel: byte);
begin
  if not IsIntegerInRange(x, 0, fwidth - 1) then
    exit;
  if not IsIntegerInRange(y, 0, fheight - 1) then
    exit;
  fimg[pos2idx(x, y)] := apixel;
end;

end.
