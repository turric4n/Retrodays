//Copyright Enrique Fuentes aka Turric4n
//Coments are only in english, sorry, see the Practice video.

{$asmmode intel}

program VGAInit;

{ Important things!!! FPC is a 32 bit compiler and default Integer type
is 32 bits. We will use 16 bit registers to program VGA (AX -> AH,AL)
So, we need to pass 2 bytes Integer Types (smallint) to registers }

{ Things to know about VGA }
{ VGA memory is 64KB = 64000 Bytes }
{ IBM/AT VGA base memory address is $a000 }
{ VGA Mode 13h is 320x200 256 colors RGB "chunky graphics" can access video memory directly }
{ 320 * 200 is 64000 bytes. So EVERY Byte is a pixel on the screen }
{ Pixel is a Byte (0..254)
{ VGA BIOS Mode 13h (16 bit) address is $0013 load in AX and call int $10 }
{ VGA BIOS Text mode 10h (16 bit) address s is $0010 load in AX and call int $10 }
{ INT 10h handles screen directly }

const

VGAMODE13H = $0013;
VGAMODE03H = $0003;
VGABASEADDRESS = $a000;
VGABYTES = 64000;

type

TVGA = class
   //Init VGA 13h chunked array of 320*200 64kb memory
   class procedure SetMCGAMode; static;
   //Init VGA 03h dos text mode
   class procedure SetTextMode; static;
   //Fills VGA memory with a RGB byte color
   class procedure ClearingScreen(Color : Byte); static;
   //Slow routine to put color pixel in VGA with at coordinates
   class procedure PutPixel(X,Y : SmallInt; Color : Byte) static;
   //Fast routine to put color pixel in VGA to direct memory access
   class procedure PutPixelMemory(X,Y : SmallInt; Color : Byte) static;
end;

class procedure TVGA.SetMCGAMode; static;
begin
 asm
   mov ax, VGAMODE13H
   int 10h
 end;
end;

class procedure TVGA.SetTextMode; static;
begin
 asm
   mov ax, VGAMODE03H //Move 0003h to AX register
   int 10h //Call interrupt 10
 end;
end;

class procedure TVGA.ClearingScreen(Color : Byte); static;
var
 x : Integer;
begin
 for x := 0 to VGABYTES do Mem[VGABASEADDRESS:0 + x] := color;
 //FPC doen't support returns of far pointers with mem command.
 //FillChar(Mem[VGABASEADDRESS],VGABYTES,Color);
end;

class procedure TVGA.PutPixel(x,y : SmallInt; Color : Byte); static;
begin
 asm
  mov ah, 0Ch // AH (High bits of a 16 bit register = 0Ch Draws Pixel
  mov al, [Color] // AL (Low bits of a 16 bit register = Specified color
  mov cx, [x] // CX all bytes of 16 bit register = X coord
  mov dx, [y] // DX all bytes of 16 bit register = Y coord
  //mov bx, [1] // BX all bytes of 16 bit register = ? not supported on emulator
  int 10h // Call to INT10h
 end;
end;

class procedure TVGA.PutPixelMemory(X,Y : SmallInt; Color : Byte); static;
begin
  //todo
end;

var
 xc, yc, rancolor : SmallInt;
 x : Integer;

BEGIN
 try
  TVGA.SetMCGAMode;
  TVGA.ClearingScreen(128);
  for x := 0 to 512 do
  begin
   xc := random(320);
   yc := random(200);
   rancolor := random(255);
   TVGA.PutPixel(xc, yc, rancolor);
  end;
  ReadLN;
 finally
  TVGA.SetTextMode;
 end;
END.

