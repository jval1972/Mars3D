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
//  Items: key cards, artifacts, weapon, ammunition.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/mars3d/
//------------------------------------------------------------------------------

{$I Mars3D.inc}

unit d_items;

interface

uses
  doomdef,
  info_h;


type
  { Weapon info: sprite frames, ammunition use. }
  weaponinfo_t = record
    ammo: ammotype_t;
    upstate: integer;
    downstate: integer;
    readystate: integer;
    atkstate: integer;
    holdatkstate: integer;
    flashstate: integer;
  end;
  Pweaponinfo_t = ^weaponinfo_t;

//
// PSPRITE ACTIONS for weapons.
// This struct controls the weapon animations.
//
// Each entry is:
//   ammo/amunition type
//   upstate
//   downstate
//   readystate
//   atkstate, i.e. attack/fire/hit frame
//   flashstate, muzzle flash
//

var
  weaponinfo: array[0..Ord(NUMWEAPONS) - 1] of weaponinfo_t = (
  // fist
    (ammo: am_noammo;            upstate: Ord(S_PUNCHUP);   downstate: Ord(S_PUNCHDOWN);
     readystate: Ord(S_PUNCH);   atkstate: Ord(S_PUNCH1);   holdatkstate: Ord(S_NULL);
     flashstate: Ord(S_NULL)),
  // pistol
    (ammo: am_bullet;            upstate: Ord(S_PISTOLUP);  downstate: Ord(S_PISTOLDOWN);
     readystate: Ord(S_PISTOL);  atkstate: Ord(S_PISTOL1);  holdatkstate: Ord(S_NULL);
     flashstate: Ord(S_PISTOLFLASH)),
  // shock gun
    (ammo: am_shockgunammo;      upstate: Ord(S_SGUNUP);    downstate: Ord(S_SGUNDOWN);
     readystate: Ord(S_SGUN);    atkstate: Ord(S_SGUN1);    holdatkstate: Ord(S_NULL);
     flashstate: Ord(S_SGUNFLASH1)),
  // nerve gun
    (ammo: am_nervegunammo;      upstate: Ord(S_CHAINUP);   downstate: Ord(S_CHAINDOWN);
     readystate: Ord(S_CHAIN);   atkstate: Ord(S_CHAIN1);   holdatkstate: Ord(S_NULL);
     flashstate: Ord(S_CHAINFLASH1)),
  // freeze gun
    (ammo: am_freezegunammo;     upstate: Ord(S_MISSILEUP); downstate: Ord(S_MISSILEDOWN);
     readystate: Ord(S_MISSILE); atkstate: Ord(S_MISSILE1); holdatkstate: Ord(S_NULL);
     flashstate: Ord(S_MISSILEFLASH1)),
  // flame gun
     (ammo: am_flamegunammo;     upstate: Ord(S_PLASMAUP);  downstate: Ord(S_PLASMADOWN);
      readystate: Ord(S_PLASMA); atkstate: Ord(S_PLASMA1);  holdatkstate: Ord(S_NULL);
      flashstate: Ord(S_PLASMAFLASH1)),
  // granade launcher
     (ammo: am_grenades;         upstate: Ord(S_BFGUP);     downstate: Ord(S_BFGDOWN);
      readystate: Ord(S_BFG);    atkstate: Ord(S_BFG1);     holdatkstate: Ord(S_NULL);
      flashstate: Ord(S_BFGFLASH1)),
  // boomerang gun
     (ammo: am_disk;             upstate: Ord(S_SAWUP);     downstate: Ord(S_SAWDOWN);
      readystate: Ord(S_SAW);    atkstate: Ord(S_SAW1);     holdatkstate: Ord(S_NULL);
      flashstate: Ord(S_NULL)),
  // missile launcher
     (ammo: am_misl;             upstate: Ord(S_DSGUNUP);   downstate: Ord(S_DSGUNDOWN);
      readystate: Ord(S_DSGUN);  atkstate: Ord(S_DSGUN1);   holdatkstate: Ord(S_NULL);
      flashstate: Ord(S_DSGUNFLASH1)),
  // tracking missile launcher
     (ammo: am_trackingmisl;     upstate: Ord(S_DSGUNUP);   downstate: Ord(S_DSGUNDOWN);
      readystate: Ord(S_DSGUN);  atkstate: Ord(S_DSGUN1);   holdatkstate: Ord(S_NULL);
      flashstate: Ord(S_DSGUNFLASH1))
  );

implementation

end.

