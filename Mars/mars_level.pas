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
//   Mars Level Preprocess
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/mars3d/
//------------------------------------------------------------------------------

{$I Mars3D.inc}

unit mars_level;

interface

uses
  w_wadwriter,
  w_wadreader;

function MARS_PreprocessLevel(const levelname: string; const wadreader: TWadReader;
  const wadwriter: TWadWriter): boolean;

implementation

uses
  d_delphi,
  doomdata,
  m_fixed,
  p_local,
  w_wad;

function MARS_PreprocessLevel(const levelname: string; const wadreader: TWadReader;
  const wadwriter: TWadWriter): boolean;
var
  id, i: integer;
  p: pointer;
  doomthings: Pmapthing_tArray;
  numdoomthings: integer;
  doomlinedefs: Pmaplinedef_tArray;
  numdoomlinedefs: integer;
  doomsidedefs: Pmapsidedef_tArray;
  numdoomsidedefs: integer;
  doomvertexes: Pmapvertex_tArray;
  numdoomvertexes: integer;
  doomsectors: Pmapsector_tArray;
  numdoomsectors: integer;
  minx, maxx, miny, maxy: integer;
  stubx, stuby: integer;
  changed: boolean;
  sz: integer;

  function AddThingToWad(const x, y: integer; const angle: smallint; const mtype: word; const options: smallint): integer;
  var
    mthing: Pmapthing_t;
  begin
    realloc(pointer(doomthings), numdoomthings * SizeOf(mapthing_t), (numdoomthings + 1) * SizeOf(mapthing_t));
    mthing := @doomthings[numdoomthings];

    mthing.x := x;
    mthing.y := y;

    mthing.angle := angle;
    mthing._type := mtype;
    mthing.options := options;

    result := numdoomthings;
    inc(numdoomthings);
  end;

  function AddSectorToWAD(const floorheight, ceilingheight: integer;
    const floortexture, ceilingtexture: string): integer;
  var
    dsec: Pmapsector_t;
  begin
    realloc(pointer(doomsectors), numdoomsectors * SizeOf(mapsector_t), (numdoomsectors  + 1) * SizeOf(mapsector_t));
    dsec := @doomsectors[numdoomsectors];
    dsec.floorheight := floorheight;
    dsec.ceilingheight := ceilingheight;
    dsec.floorpic := stringtochar8(floortexture);
    dsec.ceilingpic := stringtochar8(ceilingtexture);
    dsec.lightlevel := 255;
    dsec.special := 0;
    dsec.tag := 0;

    result := numdoomsectors;
    inc(numdoomsectors);
  end;

  function AddVertexToWAD(const x, y: smallint): integer;
  var
    j: integer;
  begin
    for j := 0 to numdoomvertexes - 1 do
      if (doomvertexes[j].x = x) and (doomvertexes[j].y = y) then
      begin
        result := j;
        exit;
      end;
    realloc(pointer(doomvertexes), numdoomvertexes * SizeOf(mapvertex_t), (numdoomvertexes  + 1) * SizeOf(mapvertex_t));
    doomvertexes[numdoomvertexes].x := x;
    doomvertexes[numdoomvertexes].y := y;
    result := numdoomvertexes;
    inc(numdoomvertexes);
  end;

  function AddSidedefToWAD(const toptex, bottomtex, midtex: string;
    const sector: smallint): integer;
  var
    pside: Pmapsidedef_t;
  begin
    realloc(pointer(doomsidedefs), numdoomsidedefs * SizeOf(mapsidedef_t), (numdoomsidedefs  + 1) * SizeOf(mapsidedef_t));
    pside := @doomsidedefs[numdoomsidedefs];
    pside.textureoffset := 0;
    pside.rowoffset := 0;
    if toptex = '' then
      pside.toptexture := stringtochar8('-')
    else
      pside.toptexture := stringtochar8(toptex);
    if bottomtex = '' then
      pside.bottomtexture := stringtochar8('-')
    else
      pside.bottomtexture := stringtochar8(bottomtex);
    if midtex = '' then
      pside.midtexture := stringtochar8('-')
    else
      pside.midtexture := stringtochar8(midtex);
    pside.sector := sector;

    result := numdoomsidedefs;
    inc(numdoomsidedefs);
  end;

  function AddLineToWAD(const x1, y1, x2, y2: integer): integer;
  var
    ii: integer;
    v1, v2: integer;
  begin
    v1 := AddVertexToWAD(x1, y1);
    v2 := AddVertexToWAD(x2, y2);
    for ii := 0 to numdoomlinedefs - 1 do
    begin
      if (doomlinedefs[ii].v1 = v1) and (doomlinedefs[ii].v2 = v2) then
      begin
        result := ii;
        exit;
      end;
      if (doomlinedefs[ii].v1 = v2) and (doomlinedefs[ii].v2 = v1) then
      begin
        result := ii;
        exit;
      end;
    end;

    realloc(pointer(doomlinedefs), numdoomlinedefs * SizeOf(maplinedef_t), (numdoomlinedefs  + 1) * SizeOf(maplinedef_t));
    doomlinedefs[numdoomlinedefs].v1 := v1;
    doomlinedefs[numdoomlinedefs].v2 := v2;
    doomlinedefs[numdoomlinedefs].flags := ML_MAPPED;
    doomlinedefs[numdoomlinedefs].special := 0;
    doomlinedefs[numdoomlinedefs].tag := 0;
    doomlinedefs[numdoomlinedefs].sidenum[0] := -1;
    doomlinedefs[numdoomlinedefs].sidenum[1] := -1;
    result := numdoomlinedefs;
    inc(numdoomlinedefs);
  end;

  procedure _do_underwater_portal(const secid: integer);
  var
    newsecid: integer;
    sec, newsec: Pmapsector_t;
    l1, l2, l3: integer;
  begin
    sec := @doomsectors[secid];
    newsecid := AddSectorToWAD(sec.floorheight, sec.ceilingheight, sec.floorpic, sec.floorpic);
    newsec := @doomsectors[newsecid];
    newsec.lightlevel := 0; // Completely black

    l1 := AddLineToWAD(stubx, stuby, stubx + 16, stuby + 16);
    l2 := AddLineToWAD(stubx + 16, stuby + 16, stubx + 16, stuby);
    l3 := AddLineToWAD(stubx + 16, stuby, stubx, stuby);
    stubx := stubx + 32;

    doomlinedefs[l1].flags := doomlinedefs[l1].flags or ML_AUTOMAPIGNOGE;
    doomlinedefs[l2].flags := doomlinedefs[l1].flags or ML_AUTOMAPIGNOGE;
    doomlinedefs[l3].flags := doomlinedefs[l1].flags or ML_AUTOMAPIGNOGE;

    doomlinedefs[l1].sidenum[0] := AddSidedefToWAD('', '', 'WALL3-22', newsecid);
    doomlinedefs[l2].sidenum[0] := AddSidedefToWAD('', '', 'WALL3-22', newsecid);
    doomlinedefs[l3].sidenum[0] := AddSidedefToWAD('', '', 'WALL3-22', newsecid);

    doomlinedefs[l1].special := 293; // Fake flat for Water Portal
    doomlinedefs[l1].tag := sec.tag;

    sec.floorheight := sec.floorheight - PUNDERWATERPORTALHEIGHT div FRACUNIT;

    changed := true;
  end;

  procedure _do_underwater_sector(const secid: integer);
  var
    newsecid: integer;
    sec, newsec: Pmapsector_t;
    l1, l2, l3: integer;
  begin
    sec := @doomsectors[secid];
    newsecid := AddSectorToWAD(sec.floorheight, sec.ceilingheight, sec.floorpic, sec.ceilingpic);
    newsec := @doomsectors[newsecid];
    newsec.lightlevel := sec.lightlevel; // Completely black

    l1 := AddLineToWAD(stubx, stuby, stubx + 16, stuby + 16);
    l2 := AddLineToWAD(stubx + 16, stuby + 16, stubx + 16, stuby);
    l3 := AddLineToWAD(stubx + 16, stuby, stubx, stuby);
    stubx := stubx + 32;

    doomlinedefs[l1].flags := doomlinedefs[l1].flags or ML_AUTOMAPIGNOGE;
    doomlinedefs[l2].flags := doomlinedefs[l1].flags or ML_AUTOMAPIGNOGE;
    doomlinedefs[l3].flags := doomlinedefs[l1].flags or ML_AUTOMAPIGNOGE;

    doomlinedefs[l1].sidenum[0] := AddSidedefToWAD('', '', 'WALL3-22', newsecid);
    doomlinedefs[l2].sidenum[0] := AddSidedefToWAD('', '', 'WALL3-22', newsecid);
    doomlinedefs[l3].sidenum[0] := AddSidedefToWAD('', '', 'WALL3-22', newsecid);

    doomlinedefs[l1].special := 294; // Fake flat for underwaster sector
    doomlinedefs[l1].tag := sec.tag;

    sec.ceilingheight := sec.ceilingheight + PUNDERWATERSECTORCHEIGHT div FRACUNIT;

    changed := true;
  end;

begin
  id := wadreader.EntryId(levelname);
  if id < 0 then
  begin
    Result := False;
    Exit;
  end;

  changed := false;

  doomthings := nil;
  numdoomthings := 0;
  doomlinedefs := nil;
  numdoomlinedefs := 0;
  doomsidedefs := nil;
  numdoomsidedefs := 0;
  doomvertexes := nil;
  numdoomvertexes := 0;
  doomsectors := nil;
  numdoomsectors := 0;

  for i := id + 1 to id + 10 do
  begin
    if (wadreader.EntryName(i) = 'THINGS') and (numdoomthings = 0) then
    begin
      wadreader.ReadEntry(i, p, sz);
      doomthings := p;
      numdoomthings := sz div SizeOf(mapthing_t);
    end
    else if (wadreader.EntryName(i) = 'LINEDEFS') and (numdoomlinedefs = 0) then
    begin
      wadreader.ReadEntry(i, p, sz);
      doomlinedefs := p;
      numdoomlinedefs := sz div SizeOf(maplinedef_t);
    end
    else if (wadreader.EntryName(i) = 'SIDEDEFS') and (numdoomsidedefs = 0) then
    begin
      wadreader.ReadEntry(i, p, sz);
      doomsidedefs := p;
      numdoomsidedefs := sz div SizeOf(mapsidedef_t);
    end
    else if (wadreader.EntryName(i) = 'VERTEXES') and (numdoomvertexes = 0) then
    begin
      wadreader.ReadEntry(i, p, sz);
      doomvertexes := p;
      numdoomvertexes := sz div SizeOf(mapvertex_t);
    end
    else if (wadreader.EntryName(i) = 'SECTORS') and (numdoomsectors = 0) then
    begin
      wadreader.ReadEntry(i, p, sz);
      doomsectors := p;
      numdoomsectors := sz div SizeOf(mapsector_t);
    end;
  end;

  // Find Doom map bounding box;
  minx := 100000;
  maxx := -100000;
  miny := 100000;
  maxy := -100000;
  for i := 0 to numdoomvertexes - 1 do
  begin
    if doomvertexes[i].x > maxx then
      maxx := doomvertexes[i].x;
    if doomvertexes[i].x < minx then
      minx := doomvertexes[i].x;
    if doomvertexes[i].y > maxy then
      maxy := doomvertexes[i].y;
    if doomvertexes[i].y < miny then
      miny := doomvertexes[i].y;
  end;

  stubx := minx + 64;
  stuby := maxy + 256;

  for i := 0 to numdoomsectors - 1 do
  begin
    if doomsectors[i].special = 14 then
      _do_underwater_portal(i)
    else if doomsectors[i].special = 10 then
    _do_underwater_sector(i);
  end;

  if changed then
  begin
    wadwriter.AddSeparator(levelname);
    wadwriter.AddData('THINGS', doomthings, numdoomthings * SizeOf(mapthing_t));
    wadwriter.AddData('LINEDEFS', doomlinedefs, numdoomlinedefs * SizeOf(maplinedef_t));
    wadwriter.AddData('SIDEDEFS', doomsidedefs, numdoomsidedefs * SizeOf(mapsidedef_t));
    wadwriter.AddData('VERTEXES', doomvertexes, numdoomvertexes * SizeOf(mapvertex_t));
    wadwriter.AddSeparator('SEGS');
    wadwriter.AddSeparator('SSECTORS');
    wadwriter.AddSeparator('NODES');
    wadwriter.AddData('SECTORS', doomsectors, numdoomsectors * SizeOf(mapsector_t));
    wadwriter.AddSeparator('REJECT');
    wadwriter.AddSeparator('BLOCKMAP');
  end;

  // Free map data
  memfree(pointer(doomthings), numdoomthings * SizeOf(mapthing_t));
  memfree(pointer(doomlinedefs), numdoomlinedefs * SizeOf(maplinedef_t));
  memfree(pointer(doomsidedefs), numdoomsidedefs * SizeOf(mapsidedef_t));
  memfree(pointer(doomvertexes), numdoomvertexes * SizeOf(mapvertex_t));
  memfree(pointer(doomsectors), numdoomsectors * SizeOf(mapsector_t));

  result := true;
end;

end.
