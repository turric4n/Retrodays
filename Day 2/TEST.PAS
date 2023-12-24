{ Copyright Enrique Fuentes aka Turric4n :) http://www.turric4n.com
Moving a sprite in VGA 320x200 256 colors mode with FPC
Coments of this code are only in english, sorry, see the Practice video. }

{$asmmode intel}
{$MODE delphi}

program VGAInit;

uses
 CRT, SysUtils;

{ Important things!!! FPC is a 32 bit compiler and default Integer type
is 32 bits. We will use 16 bit registers to program VGA (AX -> AH,AL)
So, we need to pass 2 bytes Integer Types (smallint) to registers }

{ Things to know about VGA }
{ VGA memory is 64KB = 64000 Bytes }
{ IBM/AT VGA base memory address is $a000 }
{ VGA Mode 13h is 320x200 256 colors RGB "chunky graphics" can access video memory directly }
{ 320 * 200 is 64000 bytes. So EVERY Byte is a pixel on the screen }
{ Pixel is a Byte (0..254) }
{ VGA BIOS Mode 13h (16 bit) address is $0013 load in AX and call int $10 }
{ VGA BIOS Text mode 10h (16 bit) address s is $0010 load in AX and call int $10 }
{ INT 10h handles screen directly }

{
FIRST VGA COLORS
Value	Color
0	Black
1	Blue
2	Green
3	Cyan
4	Red
5	Magenta
6	Brown
7	Light Gray
8	Dark Gray
9	Light Blue
10	Light Green
11	Light Cyan
12	Light Red
13	Light Magenta
14	Yellow
15	White
}

const

VGAMODE13H = $0013; //VGA 320x200 256 colors
VGAMODE03H = $0003; //Text mode
VGABASEADDRESS = $a000; //VGA base memory address
VGABYTES = 64000; //320*200
VGARETRACE = $03DA; //VGA retrace port
VGARETRACEBIT = $08; //VGA retrace bit
SCREENWIDTH = 320; //Screen width
SCREENHEIGHT = 200; //Screen height

type

TColor = record // 6 bits per color
  Red, Green, Blue: Byte; // 0..63
end;

PColor = ^TColor; // Pointer to a color

TPalette = array[0..255] of TColor; // 256 colors

TBitmap = record // 320x200 256 colors
  Width, Height: Integer; // 320x200
  Palette: TPalette; // 256 colors
  Pixels: array[0..63, 0..63] of Byte; // 8x8 pixels
end;

PBitmap = ^TBitmap; // Pointer to a bitmap

TSprite = class
  private
    FWidth: Integer; 
    FHeight: Integer; 
    FBitmap: Pointer;
    FPalette: Pointer;
    FX : Integer;
    FY : Integer;
    FDX : Integer;
    FDY : Integer;
  public
    constructor Create(Width, Height: Integer);
    destructor Destroy; override;
    procedure SetPixel(X, Y: Integer; Color: Byte);
    function GetPixel(X, Y: Integer): Byte;
    procedure SetPaletteColor(ColorIndex: Byte; R,G,B: Byte);
    function GetPaletteColor(ColorIndex: Byte): TColor;  
    procedure Update;
    property X : Integer read FX write FX;
    property Y : Integer read FY write FY;
    property DX : Integer read FDX write FDX;
    property DY : Integer read FDY write FDY;
    property Width: Integer read FWidth;
    property Height: Integer read FHeight;
    property Bitmap: Pointer read FBitmap;
end;

TVGA = class
   //Init VGA 13h chunked array of 320*200 64kb memory
   class procedure SetMCGAMode; static;
   //Init VGA 03h dos text mode
   class procedure SetTextMode; static;
   //Fills VGA memory with a RGB byte color
   class procedure ClearingScreen(Color : Byte); static;
   //Set a color in VGA palette
   class procedure SetPaletteColor(ColorIndex: Byte; Color: TColor); static;
   //Slow routine to put color pixel in VGA with at coordinates
   class procedure PutPixel(X,Y : SmallInt; Color : Byte) static;
   //Fast routine to put color pixel in VGA to direct memory access
   class procedure PutPixelMemory(X,Y : SmallInt; Color : Byte; Where : Word) static;
   //Wait for VRetrace this will wait for the electron's V-Scan ends
   class procedure WaitForVRetrace; assembler; static;
end;

TAdlib = class
   //Init Adlib
   class procedure Init; static;
   //Play a note
   class procedure Play(Note : Byte); static;
   //Stop a note
   class procedure Stop(Note : Byte); static;
end;


constructor TSprite.Create(Width, Height: Integer);
begin
  FWidth := Width;
  FHeight := Height;
  FX := 0;
  FY := 0;  
  FDX := 1;
  FDY := 1;  
  GetMem(FBitmap, Width * Height);
  GetMem(FPalette, 256 * SizeOf(TColor));
end;

destructor TSprite.Destroy;
begin
  FreeMem(FBitmap);
  FreeMem(FPalette);
  inherited;
end;

procedure TSprite.Update;
begin
  FX := FX + FDX;
  FY := FY + FDY;
  if (FX < 0) or (FX > ScreenWidth - Self.Width) then FDX := -FDX;
  if (FY < 0) or (FY > ScreenHeight - Self.Height) then FDY := -FDY;
end;

procedure TSprite.SetPixel(X, Y: Integer; Color: Byte);
begin
  PByte(FBitmap + X + (Y * FWidth))^ := Color;
end;

function TSprite.GetPixel(X, Y: Integer): Byte;
begin
  Result := PByte(FBitmap + X + (Y * FWidth))^;
end;

procedure TSprite.SetPaletteColor(ColorIndex: Byte; R,G,B: Byte);
var 
  Color : TColor;
begin
  Color.Red := R;
  Color.Green := G;
  Color.Blue := B;
  PColor(FPalette + ColorIndex * SizeOf(TColor))^ := Color;
end;

function TSprite.GetPaletteColor(ColorIndex: Byte): TColor;
begin
  Result := PColor(FPalette + ColorIndex * SizeOf(TColor))^;
end;

class procedure TVGA.SetMCGAMode; static; //Mode 13h
begin
 asm
   mov ax, VGAMODE13H
   int 10h
 end;
end;

class procedure TVGA.SetTextMode; static; //Text mode 03h
begin
 asm
   mov ax, VGAMODE03H //Move 0003h to AX register
   int 10h //Call interrupt 10
 end;
end;

class procedure TVGA.ClearingScreen(Color : Byte); static; //Color is the color index in the palette
var
 x : Integer;
 VGAPointer : Pointer;
begin
 for x := 0 to VGABYTES do Mem[VGABASEADDRESS:0 + x] := color;  
 //FPC doen't support returns of far pointers with mem command.
 //FillChar(Mem[VGABASEADDRESS],VGABYTES,Color);
end;

class procedure TVGA.SetPaletteColor(ColorIndex: Byte; Color: TColor); static; //ColorIndex is the color index in the palette
begin
  asm
    mov dx, 3C8h //Port 3C8h is the VGA color index register
    mov al, [ColorIndex] //AL is the color index
    out dx, al //Write the color index to the port
    inc dx //Increment the port to 3C9h
    mov al, [Color.Red] //AL is the red color value
    out dx, al //Write the red color value to the port
    mov al, [Color.Green] //AL is the green color value
    out dx, al //Write the green color value to the port
    mov al, [Color.Blue] //AL is the blue color value
    out dx, al //Write the blue color value to the port
  end;
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

class procedure TVGA.PutPixelMemory(X,Y : SmallInt; Color : Byte; Where : Word); static;
begin
 Mem[Where:X+(Y*320)] := Color; //Memory access to Address + X(Byte Pos) + (Y*320)
end;

class procedure TVGA.WaitForVRetrace; assembler; // For pure asm routines
 label
  l1, l2;
 asm
  mov dx, 3DAh //Put 3DAh port of VGA retrace on dx register
  l1 :
   //Wait
   in al, dx //Retrieve input of 3DAh port on AL 8 bits
   and al, 08h //Is 08h ??
   jnz l1
  l2 :
   //Wait again
   in al, dx //Retrieve input of 3DAh port on AL 8 Bits
   and al, 08h //Is 08h ??
   jz l2
end;

class procedure TAdlib.Init;
begin
 asm
  mov dx, 0388h //Put 0388h port of Adlib on dx register
  mov al, 00111111b // AL (Low bits of a 16 bit register = 00111111b
  out dx, al //Write the 00111111b to the port
  mov dx, 038Ah //Put 038Ah port of Adlib on dx register
  mov al, 00000000b // AL (Low bits of a 16 bit register = 00000000b
  out dx, al //Write the 00000000b to the port
 end;
end;

class procedure TAdlib.Play(Note : Byte);
begin
 asm
  mov dx, 0388h //Put 0388h port of Adlib on dx register
  mov al, [Note] // AL (Low bits of a 16 bit register = Note
  out dx, al //Write the Note to the port
 end;
end;

class procedure TAdlib.Stop(Note : Byte);
begin
 asm
  mov dx, 0388h //Put 0388h port of Adlib on dx register
  mov al, [Note] // AL (Low bits of a 16 bit register = Note
  out dx, al //Write the Note to the port
 end;
end;

function CreatePlayer : TSprite;
var
  x, y: Integer;
begin        
  Result := TSprite.Create(64,64);
  // Set the palette of the Result object
  Result.SetPaletteColor(1,255,0,0);  
  Result.SetPaletteColor(2,0,255,0);
  Result.SetPaletteColor(3,0,0,255);
  Result.SetPaletteColor(4,255,255,255);
  Result.SetPaletteColor(5,0,0,0);
  Result.SetPaletteColor(6,255,255,0);
  Result.SetPaletteColor(7,255,0,255);
  Result.SetPaletteColor(8,0,255,255);
  Result.SetPaletteColor(9,128,128,128);
  Result.SetPaletteColor(10,128,0,0);
  Result.SetPaletteColor(11,0,128,0);
  Result.SetPaletteColor(12,0,0,128);
  Result.SetPaletteColor(13,128,128,0);
  Result.SetPaletteColor(14,128,0,128);
  Result.SetPaletteColor(15,0,128,128);
  Result.SetPaletteColor(16,192,192,192);
  Result.SetPaletteColor(17,128,128,128);
  Result.SetPaletteColor(18,153,153,255);
  Result.SetPaletteColor(19,153,51,102);
  Result.SetPaletteColor(20,255,255,204);
  Result.SetPaletteColor(21,204,255,255);
  Result.SetPaletteColor(22,102,0,102);
  Result.SetPaletteColor(23,255,128,128);
  Result.SetPaletteColor(24,0,102,204);
  Result.SetPaletteColor(25,204,204,255);
  Result.SetPaletteColor(26,0,0,128);
  Result.SetPaletteColor(27,255,0,255);
  Result.SetPaletteColor(28,255,255,0);
  Result.SetPaletteColor(29,0,255,255);
  Result.SetPaletteColor(30,128,0,128);
  Result.SetPaletteColor(31,128,0,0);
  Result.SetPaletteColor(32,0,128,128);
  Result.SetPaletteColor(33,0,0,255);
  Result.SetPaletteColor(34,0,204,255);
  Result.SetPaletteColor(35,204,255,255);
  Result.SetPaletteColor(36,204,255,204);
  Result.SetPaletteColor(37,255,255,153);
  Result.SetPaletteColor(38,153,204,255);
  Result.SetPaletteColor(39,255,153,204);
  Result.SetPaletteColor(40,204,153,255);
  Result.SetPaletteColor(41,255,204,153);
  Result.SetPaletteColor(42,51,102,255);
  Result.SetPaletteColor(43,51,204,204);
  Result.SetPaletteColor(44,153,204,0);
  Result.SetPaletteColor(45,255,204,0);
  Result.SetPaletteColor(46,255,153,0);
  Result.SetPaletteColor(47,255,102,0);
  Result.SetPaletteColor(48,102,102,153);
  Result.SetPaletteColor(49,150,150,150);
  Result.SetPaletteColor(50,0,51,102);
  Result.SetPaletteColor(51,51,153,102);
  Result.SetPaletteColor(52,0,51,0);
  Result.SetPaletteColor(53,51,51,0);
  Result.SetPaletteColor(54,153,51,0);
  Result.SetPaletteColor(55,153,51,102);
  Result.SetPaletteColor(56,51,51,153);
  Result.SetPaletteColor(57,51,51,51);
  Result.SetPaletteColor(58,128,0,0);
  Result.SetPaletteColor(59,0,128,0);
  Result.SetPaletteColor(60,128,128,0);
  Result.SetPaletteColor(61,0,0,128);
  Result.SetPaletteColor(62,128,0,128);
  Result.SetPaletteColor(63,0,128,128);
  // Set the pixels of the Result object
  for y := 0 to 63 do // For each row
    for x := 0 to 63 do // For each column
    begin 
      if (x = y) or (x = 63 - y) then
        Result.SetPixel(x, y, y)  // Set the pixel to white if it's part of the "X"
      else
        Result.SetPixel(x, y, 0);   // Otherwise, set the pixel to black
    end;
end;

procedure AdlibTimerInterrupt; interrupt;
var
  CurrentTime: LongInt;
begin
  CurrentTime := MemL[$0040:$006C];  // Get the current system time
  if CurrentTime - StartTime >= 9 then  // If half a second has passed
  begin
    Adlib.Stop(Note);  // Stop the current note
    Inc(Note);  // Move to the next note
    if Note <= 72 then  // If there are still notes left to play
    begin
      Adlib.Play(Note);  // Play the next note
      StartTime := CurrentTime;  // Reset the start time
    end;
  end;
end;

var
 paletteColor : TColor;
 vgaColor : Byte;
 x, y: Integer;
 cont : Boolean;
 persojugador : TSprite;
begin
  // Initialize the Adlib
  Adlib.Init;

  Note := 60;  // Start with the first note (C4)
  Adlib.Play(Note);  // Play the first note

  StartTime := MemL[$0040:$006C];  // Get the current system time

  SetIntVec($1C, @TimerInterrupt);  // Set the timer interrupt handler

  // Allocate memory for the logo
  persojugador := CreatePlayer;

  // Initialize the logo

  cont := true;
  TVGA.SetMCGAMode;
  TVGA.ClearingScreen(0);

  for y := 0 to persojugador.height do
    for x := 0 to persojugador.width do
    begin
      vgaColor := persojugador.GetPixel(x, y);
      paletteColor := persojugador.GetPaletteColor(vgaColor);
      TVGA.SetPaletteColor(vgaColor, paletteColor);
    end;
  while cont do
  begin
    TVGA.WaitForVRetrace;
    for y := 0 to persojugador.height - 1 do
      for x := 0 to persojugador.width - 1 do
      begin
        vgaColor := persojugador.GetPixel(x, y);
        TVGA.PutPixelMemory(persojugador.X + x, persojugador.Y + y, vgaColor, VGABASEADDRESS);
      end;     
    persojugador.Update;     
   if keypressed then
    begin
     case readkey of #27 : cont := false;     
    end;
   end;
  end;
  FadeOut(@Logo);
  SetIntVec($1C, nil);  // Restore the original timer interrupt handler
  TVGA.SetTextMode;  
end.