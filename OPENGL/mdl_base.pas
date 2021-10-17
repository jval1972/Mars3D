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
//  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
//  DESCRIPTION:
//    Base model class (Abstract)
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/mars3d/
//------------------------------------------------------------------------------

{$I Mars3D.inc}

unit mdl_base;

interface

uses
  d_delphi;

type
  TFrameIndexInfo = class
  private
    fStartFrame,
    fEndFrame: integer;
  public
    property StartFrame: integer read fStartFrame write fStartFrame;
    property EndFrame: integer read fEndFrame write fEndFrame;
  end;

type
  TBaseModel = class(TObject)
  protected
  public
    constructor Create(const name: string;
      const xoffset, yoffset, zoffset: float;
      const xscale, yscale, zscale: float;
      const additionalframes: TDStringList); virtual;
    destructor Destroy; override;
    procedure Draw(const frm1, frm2: integer; const offset: float); virtual; abstract;
    procedure DrawSimple(const frm: integer); virtual; abstract;
  end;


implementation

constructor TBaseModel.Create(const name: string;
  const xoffset, yoffset, zoffset: float;
  const xscale, yscale, zscale: float;
  const additionalframes: TDStringList); 
begin
  Inherited Create;
end;

destructor TBaseModel.Destroy;
begin
  Inherited;
end;

end.
