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
//  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
// DESCRIPTION:
//  MATERIAL custom image format.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/mars3d/
//------------------------------------------------------------------------------

{$I Mars3D.inc}

unit t_material;

interface

uses
  d_delphi,
  t_main;

type
  TMaterialTextureManager = object(TTextureManager)
    tex1: PTexture;
  public
    constructor Create;
    function LoadHeader(stream: TDStream): boolean; virtual;
    function LoadImage(stream: TDStream): boolean; virtual;
    destructor Destroy; virtual;
  end;

implementation

constructor TMaterialTextureManager.Create;
begin
  inherited Create;
  SetFileExt('.MATERIAL');
end;

function TMaterialTextureManager.LoadHeader(stream: TDStream): boolean;
var
  s: TDStringList;
  texname, alphaname: string;
  alpha1: PTexture;
begin
  stream.seek(0, sFromBeginning);
  s := TDSTringList.Create;
  s.LoadFromStream(stream);
  texname := s.Values['texture'];
  alphaname := s.Values['alpha'];
  s.Free;
  result := texname <> '';
  if not result then
    exit;
  tex1 := T_LoadHiResTexture(texname);
  if tex1 = nil then
  begin
    result := false;
    exit;
  end;
  if alphaname <> '' then
  begin
    alpha1 := T_LoadHiResTexture(alphaname);
    if alpha1 = nil then
      exit;
    tex1.ConvertTo32bit;
    tex1.SetAlphaChannelFromImage(alpha1);
    dispose(alpha1, destroy);
  end;
  FBitmap^.SetBytesPerPixel(4);
  FBitmap^.SetWidth(tex1.GetWidth);
  FBitmap^.SetHeight(tex1.GetHeight);
end;

function TMaterialTextureManager.LoadImage(stream: TDStream): boolean;
begin
  memcpy(FBitmap.GetImage, tex1.GetImage, tex1.GetWidth * tex1.GetHeight * 4);
  FBitmap.SetExternalAlphaPresent(tex1.ExternalAlphaPresent);
  dispose(tex1, destroy);
  result := true;
end;

destructor TMaterialTextureManager.Destroy;
begin
  Inherited destroy;
end;

end.

