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

end.

