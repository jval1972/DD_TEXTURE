//------------------------------------------------------------------------------
//
//  DD_TEXTURE: A tool for creating textures from real world photos.
//  Copyright (C) 2017-2026 by Jim Valavanis
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
//    Image Rotation
//
//------------------------------------------------------------------------------
//  E-Mail: jvalavanis@gmail.com
//  Site  : https://sourceforge.net/projects/brickinventory/
//------------------------------------------------------------------------------

unit tx_imagerotate;

interface

uses
  Windows, Classes, Graphics, jpeg;

procedure RotateBitmap90DegreesCounterClockwise(var ABitmap: TBitmap);

procedure RotateBitmap90DegreesClockwise(var ABitmap: TBitmap);

procedure RotateBitmap180Degrees(var ABitmap: TBitmap);

procedure RotateJPEG90DegreesCounterClockwise(const jp: TJPEGImage);

procedure RotateJPEG90DegreesClockwise(const jp: TJPEGImage);

procedure RotateJPEG180Degrees(const jp: TJPEGImage);

function RotateBitmapFile90DegreesCounterClockwise(const fname: string): boolean;

function RotateBitmapFile90DegreesClockwise(const fname: string): boolean;

function RotateBitmapFile180Degrees(const fname: string): boolean;

function RotateJPEGFile90DegreesCounterClockwise(const fname: string): boolean;

function RotateJPEGFile90DegreesClockwise(const fname: string): boolean;

function RotateJPEGFile180Degrees(const fname: string): boolean;

procedure StretchBitmap(const srcBmp, dstBmp: TBitmap);

procedure RestoreBitmapDeformation(const bm: TBitmap);

implementation

uses
  SysUtils;

procedure RotateBitmap90DegreesCounterClockwise(var ABitmap: TBitmap);
const
  BitsPerByte = 8;
var
  PbmpInfoR: PBitmapInfoHeader;
  bmpBuffer, bmpBufferR: PByte;
  MemoryStream, MemoryStreamR: TMemoryStream;
  PbmpBuffer, PbmpBufferR: PByte;
  BytesPerPixel, PixelsPerByte: LongInt;
  BytesPerScanLine, BytesPerScanLineR: LongInt;
  PaddingBytes: LongInt;
  BitmapOffset: LongInt;
  BitCount: LongInt;
  WholeBytes, ExtraPixels: LongInt;
  SignificantBytes, SignificantBytesR: LongInt;
  ColumnBytes: LongInt;
  AtLeastEightBitColor: Boolean;
  T: LongInt;

  procedure NonIntegralByteRotate;
  var
    X, Y: LongInt;
    I: LongInt;
    MaskBits, CurrentBits: Byte;
    FirstMask, LastMask: Byte;
    PFirstScanLine: PByte;
    FirstIndex, CurrentBitIndex: LongInt;
    ShiftRightAmount, ShiftRightStart: LongInt;
  begin
    Inc(PbmpBuffer, BytesPerScanLine * (PbmpInfoR^.biHeight - 1) );
    PFirstScanLine := bmpBufferR;
    FirstIndex := BitsPerByte - BitCount;
    LastMask := 1 shl BitCount - 1;
    FirstMask := LastMask shl FirstIndex;
    CurrentBits := FirstMask;
    CurrentBitIndex := FirstIndex;
    ShiftRightStart := BitCount * (PixelsPerByte - 1);
    for Y := 1 to PbmpInfoR^.biHeight do
    begin
      PbmpBufferR := PFirstScanLine;
      for X := 1 to WholeBytes do
      begin
        MaskBits := FirstMask;
        ShiftRightAmount := ShiftRightStart;
        for I := 1 to PixelsPerByte do
        begin
          PbmpBufferR^ := ( PbmpBufferR^ and not CurrentBits ) or ((PbmpBuffer^ and MaskBits) shr ShiftRightAmount shl CurrentBitIndex);
          MaskBits := MaskBits shr BitCount;
          Inc(PbmpBufferR, BytesPerScanLineR);
          Dec(ShiftRightAmount, BitCount);
        end;
        Inc(PbmpBuffer);
      end;
      if ExtraPixels <> 0 then
      begin
        MaskBits := FirstMask;
        ShiftRightAmount := ShiftRightStart;
        for I := 1 to ExtraPixels do
        begin
          PbmpBufferR^ := ( PbmpBufferR^ and not CurrentBits ) or ((PbmpBuffer^ and MaskBits) shr ShiftRightAmount shl CurrentBitIndex);
          MaskBits := MaskBits shr BitCount;
          Inc(PbmpBufferR, BytesPerScanLineR);
          Dec(ShiftRightAmount, BitCount);
        end;
        Inc(PbmpBuffer);
      end;
      Inc(PbmpBuffer, PaddingBytes);
      Dec(PbmpBuffer, BytesPerScanLine shl 1);
      if CurrentBits = LastMask then
      begin
        CurrentBits := FirstMask;
        CurrentBitIndex := FirstIndex;
        Inc(PFirstScanLine);
      end
      else
      begin
        CurrentBits := CurrentBits shr BitCount;
        Dec(CurrentBitIndex, BitCount);
      end;
    end;
  end;

  procedure IntegralByteRotate;
  var
    X, Y: LongInt;
  begin
    Inc(PbmpBufferR, SignificantBytesR - BytesPerPixel);
    for Y := 1 to PbmpInfoR^.biHeight do
    begin
      for X := 1 to PbmpInfoR^.biWidth do
      begin
        Move(PbmpBuffer^, PbmpBufferR^, BytesPerPixel);

        Inc(PbmpBuffer, BytesPerPixel);

        Inc(PbmpBufferR, BytesPerScanLineR);
      end;
      Inc(PbmpBuffer, PaddingBytes);
      Dec(PbmpBufferR, ColumnBytes + BytesPerPixel);
    end;
  end;

begin
  MemoryStream := TMemoryStream.Create;
  ABitmap.SaveToStream(MemoryStream);
  ABitmap.Free;
  bmpBuffer := MemoryStream.Memory;
  BitmapOffset := PBitmapFileHeader(bmpBuffer)^.bfOffBits;
  Inc(bmpBuffer, SizeOf(TBitmapFileHeader));
  PbmpInfoR := PBitmapInfoHeader(bmpBuffer);
  bmpBuffer := MemoryStream.Memory;
  Inc(bmpBuffer, BitmapOffset);
  PbmpBuffer := bmpBuffer;
  with PbmpInfoR^ do
  begin
    BitCount := biBitCount;
    BytesPerScanLine := ((((biWidth * BitCount) + 31) div 32) * SizeOf(DWORD));
    BytesPerScanLineR := ((((biHeight * BitCount) + 31) div 32) * SizeOf(DWORD));
    AtLeastEightBitColor := BitCount >= BitsPerByte;
    if AtLeastEightBitColor then
    begin
      BytesPerPixel := biBitCount shr 3;
      SignificantBytes := biWidth * BitCount shr 3;
      SignificantBytesR := biHeight * BitCount shr 3;
      PaddingBytes := BytesPerScanLine - SignificantBytes;
      ColumnBytes := BytesPerScanLineR * biWidth;
    end
    else
    begin
      PixelsPerByte := SizeOf(Byte) * BitsPerByte div BitCount;
      WholeBytes := biWidth div PixelsPerByte;
      ExtraPixels := biWidth mod PixelsPerByte;
      PaddingBytes := BytesPerScanLine - WholeBytes;
      if ExtraPixels <> 0 then Dec(PaddingBytes);
    end;
    MemoryStreamR := TMemoryStream.Create;
    MemoryStreamR.SetSize(BitmapOffset + BytesPerScanLineR * biWidth);
  end;
  MemoryStream.Seek(0, soFromBeginning);
  MemoryStreamR.CopyFrom(MemoryStream, BitmapOffset);
  bmpBufferR := MemoryStreamR.Memory;
  Inc(bmpBufferR, BitmapOffset);
  PbmpBufferR := bmpBufferR;
  if AtLeastEightBitColor then
    IntegralByteRotate
  else
    NonIntegralByteRotate;
  MemoryStream.Free;
  PbmpBufferR := MemoryStreamR.Memory;
  Inc( PbmpBufferR, SizeOf(TBitmapFileHeader) );
  PbmpInfoR := PBitmapInfoHeader(PbmpBufferR);
  with PbmpInfoR^ do
  begin
    T := biHeight;
    biHeight := biWidth;
    biWidth := T;
    biSizeImage := 0;
  end;
  ABitmap := TBitmap.Create;
  MemoryStreamR.Seek(0, soFromBeginning);
  ABitmap.LoadFromStream(MemoryStreamR);
  MemoryStreamR.Free;
end;

procedure RotateBitmap90DegreesClockwise(var ABitmap: TBitmap);
const
  BitsPerByte = 8;
var
  PbmpInfoR: PBitmapInfoHeader;
  bmpBuffer, bmpBufferR: PByte;
  MemoryStream, MemoryStreamR: TMemoryStream;
  PbmpBuffer, PbmpBufferR: PByte;
  BytesPerPixel, PixelsPerByte: LongInt;
  BytesPerScanLine, BytesPerScanLineR: LongInt;
  PaddingBytes: LongInt;
  BitmapOffset: LongInt;
  BitCount: LongInt;
  WholeBytes, ExtraPixels: LongInt;
  SignificantBytes: LongInt;
  ColumnBytes: LongInt;
  AtLeastEightBitColor: Boolean;
  T: LongInt;

  procedure NonIntegralByteRotate;
  var
    X, Y: LongInt;
    I: LongInt;
    MaskBits, CurrentBits: Byte;
    FirstMask, LastMask: Byte;
    PLastScanLine: PByte;
    FirstIndex, CurrentBitIndex: LongInt;
    ShiftRightAmount, ShiftRightStart: LongInt;
  begin
    PLastScanLine := bmpBufferR;
    Inc(PLastScanLine, BytesPerScanLineR * (PbmpInfoR^.biWidth - 1) );
    FirstIndex := BitsPerByte - BitCount;
    LastMask := 1 shl BitCount - 1;
    FirstMask := LastMask shl FirstIndex;
    CurrentBits := FirstMask;
    CurrentBitIndex := FirstIndex;
    ShiftRightStart := BitCount * (PixelsPerByte - 1);
    for Y := 1 to PbmpInfoR^.biHeight do
    begin
      PbmpBufferR := PLastScanLine;
      for X := 1 to WholeBytes do
      begin
        MaskBits := FirstMask;
        ShiftRightAmount := ShiftRightStart;
        for I := 1 to PixelsPerByte do
        begin
          PbmpBufferR^ := ( PbmpBufferR^ and not CurrentBits ) or ((PbmpBuffer^ and MaskBits) shr ShiftRightAmount shl CurrentBitIndex);
          MaskBits := MaskBits shr BitCount;
          Dec(PbmpBufferR, BytesPerScanLineR);
          Dec(ShiftRightAmount, BitCount);
        end;
        Inc(PbmpBuffer);
      end;
      if ExtraPixels <> 0 then
      begin
        MaskBits := FirstMask;
        ShiftRightAmount := ShiftRightStart;
        for I := 1 to ExtraPixels do
        begin
          PbmpBufferR^ := (PbmpBufferR^ and not CurrentBits) or ((PbmpBuffer^ and MaskBits) shr ShiftRightAmount shl CurrentBitIndex);
          MaskBits := MaskBits shr BitCount;
          Dec(PbmpBufferR, BytesPerScanLineR);
          Dec(ShiftRightAmount, BitCount);
        end;
        Inc(PbmpBuffer);
      end;
      Inc(PbmpBuffer, PaddingBytes);
      if CurrentBits = LastMask then
      begin
        CurrentBits := FirstMask;
        CurrentBitIndex := FirstIndex;
        Inc(PLastScanLine);
      end
      else
      begin
        CurrentBits := CurrentBits shr BitCount;
        Dec(CurrentBitIndex, BitCount);
      end;
    end;
  end;

  procedure IntegralByteRotate;
  var
    X, Y: LongInt;
  begin
    Inc(PbmpBufferR, BytesPerScanLineR * (PbmpInfoR^.biWidth - 1));
    for Y := 1 to PbmpInfoR^.biHeight do
    begin
      for X := 1 to PbmpInfoR^.biWidth do
      begin
        Move(PbmpBuffer^, PbmpBufferR^, BytesPerPixel);
        Inc(PbmpBuffer, BytesPerPixel);
        Dec(PbmpBufferR, BytesPerScanLineR);
      end;
      Inc(PbmpBuffer, PaddingBytes);
      Inc(PbmpBufferR, ColumnBytes + BytesPerPixel);
    end;
  end;

begin
  MemoryStream := TMemoryStream.Create;
  ABitmap.SaveToStream(MemoryStream);
  ABitmap.Free;
  bmpBuffer := MemoryStream.Memory;
  BitmapOffset := PBitmapFileHeader(bmpBuffer)^.bfOffBits;
  Inc(bmpBuffer, SizeOf(TBitmapFileHeader));
  PbmpInfoR := PBitmapInfoHeader(bmpBuffer);
  bmpBuffer := MemoryStream.Memory;
  Inc(bmpBuffer, BitmapOffset);
  PbmpBuffer := bmpBuffer;
  with PbmpInfoR^ do
  begin
    BitCount := biBitCount;
    BytesPerScanLine := ((((biWidth * BitCount) + 31) div 32) * SizeOf(DWORD));
    BytesPerScanLineR := ((((biHeight * BitCount) + 31) div 32) * SizeOf(DWORD));
    AtLeastEightBitColor := BitCount >= BitsPerByte;
    if AtLeastEightBitColor then
    begin
      BytesPerPixel := biBitCount shr 3;
      SignificantBytes := biWidth * BitCount shr 3;
      PaddingBytes := BytesPerScanLine - SignificantBytes;
      ColumnBytes := BytesPerScanLineR * biWidth;
    end
    else
    begin
      PixelsPerByte := SizeOf(Byte) * BitsPerByte div BitCount;
      WholeBytes := biWidth div PixelsPerByte;
      ExtraPixels := biWidth mod PixelsPerByte;
      PaddingBytes := BytesPerScanLine - WholeBytes;
      if ExtraPixels <> 0 then Dec(PaddingBytes);
    end;
    MemoryStreamR := TMemoryStream.Create;
    MemoryStreamR.SetSize(BitmapOffset + BytesPerScanLineR * biWidth);
  end;
  MemoryStream.Seek(0, soFromBeginning);
  MemoryStreamR.CopyFrom(MemoryStream, BitmapOffset);
  bmpBufferR := MemoryStreamR.Memory;
  Inc(bmpBufferR, BitmapOffset);
  PbmpBufferR := bmpBufferR;
  if AtLeastEightBitColor then
    IntegralByteRotate
  else
    NonIntegralByteRotate;
  MemoryStream.Free;
  PbmpBufferR := MemoryStreamR.Memory;
  Inc(PbmpBufferR, SizeOf(TBitmapFileHeader));
  PbmpInfoR := PBitmapInfoHeader(PbmpBufferR);
  with PbmpInfoR^ do
  begin
    T := biHeight;
    biHeight := biWidth;
    biWidth := T;
    biSizeImage := 0;
  end;
  ABitmap := TBitmap.Create;
  MemoryStreamR.Seek(0, soFromBeginning);
  ABitmap.LoadFromStream(MemoryStreamR);
  MemoryStreamR.Free;
end;

procedure RotateBitmap180Degrees(var ABitmap: TBitmap);
var
  RotatedBitmap: TBitmap;
begin
  RotatedBitmap := TBitmap.Create;
  with RotatedBitmap do
  begin
    Width := ABitmap.Width;
    Height := ABitmap.Height;
    Canvas.StretchDraw(Rect(ABitmap.Width, ABitmap.Height, 0, 0), ABitmap);
  end;
  ABitmap.Free;
  ABitmap := RotatedBitmap;
end;

procedure RotateJPEG90DegreesCounterClockwise(const jp: TJPEGImage);
var
  b: TBitmap;
begin
  b := TBitmap.Create;
  b.Assign(jp);
  RotateBitmap90DegreesCounterClockwise(b);
  jp.Assign(b);
  b.Free;
end;

procedure RotateJPEG90DegreesClockwise(const jp: TJPEGImage);
var
  b: TBitmap;
begin
  b := TBitmap.Create;
  b.Assign(jp);
  RotateBitmap90DegreesClockwise(b);
  jp.Assign(b);
  b.Free;
end;

procedure RotateJPEG180Degrees(const jp: TJPEGImage);
var
  b: TBitmap;
begin
  b := TBitmap.Create;
  b.Assign(jp);
  RotateBitmap180Degrees(b);
  jp.Assign(b);
  b.Free;
end;

function RotateBitmapFile90DegreesCounterClockwise(const fname: string): boolean;
var
  b: TBitmap;
begin
  Result := False;
  if not FileExists(fname) then
    Exit;

  b := TBitmap.Create;
  try
    b.LoadFromFile(fname);
    RotateBitmap90DegreesCounterClockwise(b);
    b.SaveToFile(fname);
    Result := True;
  finally
    b.Free;
  end;
end;

function RotateBitmapFile90DegreesClockwise(const fname: string): boolean;
var
  b: TBitmap;
begin
  Result := False;
  if not FileExists(fname) then
    Exit;

  b := TBitmap.Create;
  try
    b.LoadFromFile(fname);
    RotateBitmap90DegreesClockwise(b);
    b.SaveToFile(fname);
    Result := True;
  finally
    b.Free;
  end;
end;

function RotateBitmapFile180Degrees(const fname: string): boolean;
var
  b: TBitmap;
begin
  Result := False;
  if not FileExists(fname) then
    Exit;

  b := TBitmap.Create;
  try
    b.LoadFromFile(fname);
    RotateBitmap180Degrees(b);
    b.SaveToFile(fname);
    Result := True;
  finally
    b.Free;
  end;
end;

function RotateJPEGFile90DegreesCounterClockwise(const fname: string): boolean;
var
  jp: TJPEGImage;
begin
  Result := False;
  if not FileExists(fname) then
    Exit;

  jp := TJPEGImage.Create;
  try
    jp.LoadFromFile(fname);
    RotateJPEG90DegreesCounterClockwise(jp);
    jp.CompressionQuality := 100;
    jp.SaveToFile(fname);
    Result := True;
  finally
    jp.Free;
  end;
end;

function RotateJPEGFile90DegreesClockwise(const fname: string): boolean;
var
  jp: TJPEGImage;
begin
  Result := False;
  if not FileExists(fname) then
    Exit;

  jp := TJPEGImage.Create;
  try
    jp.LoadFromFile(fname);
    RotateJPEG90DegreesClockwise(jp);
    jp.CompressionQuality := 100;
    jp.SaveToFile(fname);
    Result := True;
  finally
    jp.Free;
  end;
end;

function RotateJPEGFile180Degrees(const fname: string): boolean;
var
  jp: TJPEGImage;
begin
  Result := False;
  if not FileExists(fname) then
    Exit;

  jp := TJPEGImage.Create;
  try
    jp.LoadFromFile(fname);
    RotateJPEG180Degrees(jp);
    jp.CompressionQuality := 100;
    jp.SaveToFile(fname);
    Result := True;
  finally
    jp.Free;
  end;
end;

// From https://github.com/GabrielOnDelphi/ImageResamplerTest
procedure StretchBitmap(const srcBmp, dstBmp: TBitmap);
var
  ix, iy: integer;
  x, y, xdif, ydif: integer;
  xp1, xp2, yp: integer;
  wy, wyi, wx: integer;
  w11, w21, w12, w22: integer;
  sbBits, sbLine1, sbLine2: PByteArray;
  smLine1: PByteArray;
  dbLine: PByteArray;
  sbLineDif, dbLineDif: integer;
  w: integer;
begin
  srcBmp.PixelFormat := pf32bit;
  dstBmp.PixelFormat := pf32bit;

  xdif := (srcBmp.Width  shl 16) div dstBmp.Width;//CR: +1 avoids slight scaling distortion
  ydif := (srcBmp.Height shl 16) div dstBmp.Height;//CR: +1 avoids slight scaling distortion
  y := 0;
  sbBits := srcBmp.ScanLine[0];
  if srcBmp.Height > 1 then
    sbLineDif := integer(srcBmp.ScanLine[1]) - integer(sbBits)
  else
    sbLineDif := 0;
  dbLine := dstBmp.ScanLine[0];
  if dstBmp.Height > 1 then
    dbLineDif := integer(dstBmp.ScanLine[1]) - integer(dbLine) - 4 * dstBmp.Width
  else
    dbLineDif := 0;

  w := srcBmp.Width - 1;
  for iy := 0 to dstBmp.Height - 1 do
  begin
    yp := y shr 16;
    integer(sbLine1) := integer(sbBits) + sbLineDif * yp;
    integer(smLine1) := integer({smBits}nil) {+ smLineDif * yp};
    if yp < srcBmp.Height - 1 then
      integer(sbLine2) := integer(sbLine1) + sbLineDif
    else
      sbLine2 := sbLine1;
    x   := 0;
    wy  :=      y  and $FFFF;
    wyi := (not y) and $FFFF;
    for ix := 0 to dstBmp.Width - 1 do
    begin
      xp1 := x shr 16;
      if xp1 < w then
        xp2 := xp1 + 1
      else
        xp2 := xp1;
      wx  := x and $FFFF;
      w21 := (wyi * wx) shr 16; w11 := wyi - w21;
      w22 := (wy  * wx) shr 16; w12 := wy  - w22;
      {if smLine1 <> nil then begin
        w11 := (w11 * (256 - smLine1^[xp1])) shr 8;
        w21 := (w21 * (256 - smLine1^[xp2])) shr 8;
        w12 := (w12 * (256 - smLine2^[xp1])) shr 8;
        w22 := (w22 * (256 - smLine2^[xp2])) shr 8;
        dmLine^ := 255 - byte((w11 + w21 + w12 + w22) shr 8);
      end;}
      xp1 := xp1 * 4;
      xp2 := xp2 * 4;
      {blue} dbLine^[0] := (sbLine1[xp1    ] * w11 + sbLine1[xp2    ] * w21 + sbLine2[xp1    ] * w12 + sbLine2[xp2    ] * w22) shr 16;
      {green}dbLine^[1] := (sbLine1[xp1 + 1] * w11 + sbLine1[xp2 + 1] * w21 + sbLine2[xp1 + 1] * w12 + sbLine2[xp2 + 1] * w22) shr 16;
      {red}  dbLine^[2] := (sbLine1[xp1 + 2] * w11 + sbLine1[xp2 + 2] * w21 + sbLine2[xp1 + 2] * w12 + sbLine2[xp2 + 2] * w22) shr 16;
      inc(integer(dbLine), 4);
      //inc(dmLine);
      inc(x, xdif);
      //if ix = 0 then
      //  inc(x, Hlfxdif);
    end;
    inc(integer(dbLine), dbLineDif);
    inc(y, ydif);
  end;
end;

function pixelless(const test, x: LongWord): boolean;
var
  r1, r2, g1, g2, b1, b2: byte;
begin
  r1 := GetRValue(test);
  g1 := GetGValue(test);
  b1 := GetBValue(test);
  r2 := GetRValue(x);
  g2 := GetGValue(x);
  b2 := GetBValue(x);
  Result := (r2 <  r1) and (g2 < g1) and (b2 < b1);
end;

function ColorWeights(const c1, c2: LongWord; const w1, w2: Double): LongWord;
var
  r1, g1, b1: Integer;
  r2, g2, b2: Integer;
  r, g, b: Integer;
begin
  r1 := GetRValue(c1);
  g1 := GetGValue(c1);
  b1 := GetBValue(c1);
  r2 := GetRValue(c2);
  g2 := GetGValue(c2);
  b2 := GetBValue(c2);
  r := Round(w1 * r1 + w2 * r2);
  if r < 0 then
    r := 0
  else if r > 255 then
    r := 255;
  g := Round(w1 * g1 + w2 * g2);
  if g < 0 then
    g := 0
  else if g > 255 then
    g := 255;
  b := Round(w1 * b1 + w2 * b2);
  if b < 0 then
    b:= 0
  else if b > 255 then
    b := 255;
  Result := RGB(r, g, b);
end;

procedure RestoreBitmapDeformation(const bm: TBitmap);
const
  BUF_SIZE_7 = 10000;
var
  A, B: array[0..BUF_SIZE_7 - 1] of Integer;
  L: array[0..BUF_SIZE_7 - 1] of LongWord;
  i: integer;
  w, h: integer;
  x, y: integer;
  margin: integer;
  C: TCanvas;
  astart, bstop: Integer;
  px1, px2: Integer;
  w1, w2: double;
  dbl: double;
begin
  for i := 0 to BUF_SIZE_7 - 1 do
  begin
    A[i] := -1;
    B[i] := -1;
  end;

  bm.PixelFormat := pf32bit;
  C := bm.Canvas;

  w := bm.Width;
  h := bm.Height;

  margin := w div 6;

  for x := 0 to h - 1 do
  begin
    for i := 0 to margin - 1 do
      if pixelless(RGB(128, 128, 128), C.Pixels[i, x]) and pixelless(RGB(128, 128, 128), C.Pixels[i + 1, x]) then
      begin
        A[x] := i;
        Break;
      end;
    for i := w - 1 downto w - margin do
      if pixelless(RGB(128, 128, 128), C.Pixels[i, x]) and pixelless(RGB(128, 128, 128), C.Pixels[i - 1, x]) then
      begin
        B[x] := i;
        Break;
      end;

  end;

  astart := w;
  bstop := -1;
  for i := 0 to h - 1 do
    if (A[i] >= 0) and (B[i] >= 0) and (B[i] > A[i]) and (B[i] - A[i] > w div 2) then
    begin
      if A[i] < astart then
        astart := A[i];
      if B[i] > bstop then
        bstop := B[i];
    end;

  if (astart < bstop) and (bstop - astart > w div 2) then
  begin
    for i := 0 to w - 1 do
      L[i] := RGB(255, 255, 255);
    for x := 0 to h - 1 do
      if (A[x] >= 0) and (B[x] >= 0) and (B[x] > A[x]) and (B[x] - A[x] > w div 2) then
      begin
        for y := astart to bstop do
        begin
          // L[y] := C.Pixels[Round(A[x] + (B[x] - A[x]) * (y - astart) / (bstop - astart)), x]
          dbl := A[x] + (B[x] - A[x]) * (y - astart) / (bstop - astart);
          px1 := Trunc(dbl);
          px2 := px1 + 1;
          w2 := dbl - px1;
          w1 := 1.0 - w2;
          L[y] := ColorWeights(C.Pixels[px1, x], C.Pixels[px2, x], w1, w2);
        end;
        for y := 0 to w - 1 do
          C.Pixels[y, x] := L[y];
      end;

  end;
end;


end.

