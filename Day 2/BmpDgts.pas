unit BmpDgts;

interface

type
  TBitmapDigit = array[0..6, 0..4] of Byte;
  TBitmapDigits = array of TBitmapDigit;

const
 BITMAPDGTS: TBitmapDigits = 
 (((0, 1, 1, 1, 0),  // 0
   (0, 1, 1, 1, 0),
   (1, 0, 0, 0, 1),
   (1, 0, 0, 0, 1),
   (1, 0, 0, 0, 1),
   (1, 0, 0, 0, 1),
   (0, 1, 1, 1, 0)),
  ((0, 0, 1, 0, 0),  // 1
   (0, 1, 1, 0, 0),
   (0, 0, 1, 0, 0),
   (0, 0, 1, 0, 0),
   (0, 0, 1, 0, 0),
   (0, 0, 1, 0, 0),
   (0, 1, 1, 1, 1)),
  ((0, 1, 1, 1, 0),  // 2
   (1, 0, 0, 0, 1),
   (0, 0, 0, 1, 0),
   (0, 0, 1, 0, 0),
   (0, 1, 0, 0, 0),
   (1, 0, 0, 0, 0),
   (1, 1, 1, 1, 1)),
  ((0, 1, 1, 1, 0),  // 3
   (1, 0, 0, 0, 1),
   (0, 0, 0, 1, 0),
   (0, 0, 1, 0, 0),
   (0, 0, 0, 1, 0),
   (1, 0, 0, 0, 1),
   (0, 1, 1, 1, 0)),
  ((1, 0, 0, 0, 1),  // 4
   (1, 0, 0, 0, 1),
   (1, 0, 0, 0, 1),
   (0, 1, 1, 1, 1),
   (0, 0, 0, 0, 1),
   (0, 0, 0, 0, 1),
   (0, 0, 0, 0, 1)),
  ((1, 1, 1, 1, 1),  // 5
   (1, 0, 0, 0, 0),
   (1, 0, 0, 0, 0),
   (0, 1, 1, 1, 0),
   (0, 0, 0, 0, 1),
   (1, 0, 0, 0, 1),
   (0, 1, 1, 1, 0)),
  ((0, 1, 1, 1, 0),  // 6
   (1, 0, 0, 0, 0),
   (1, 0, 0, 0, 0),
   (1, 1, 1, 1, 0),
   (1, 0, 0, 0, 1),
   (1, 0, 0, 0, 1),
   (0, 1, 1, 1, 0)),
  ((1, 1, 1, 1, 1),  // 7
   (0, 0, 0, 0, 1),
   (0, 0, 0, 1, 0),
   (0, 0, 1, 0, 0),
   (0, 1, 0, 0, 0),
   (0, 1, 0, 0, 0),
   (0, 1, 0, 0, 0)),
  ((0, 1, 1, 1, 0),  // 8
   (1, 0, 0, 0, 1),
   (1, 0, 0, 0, 1),
   (0, 1, 1, 1, 0),
   (1, 0, 0, 0, 1),
   (1, 0, 0, 0, 1),
   (0, 1, 1, 1, 0)),
  ((0, 1, 1, 1, 0),  // 9
   (1, 0, 0, 0, 1),
   (1, 0, 0, 0, 1),
   (0, 1, 1, 1, 1),
   (0, 0, 0, 0, 1),
   (0, 0, 0, 0, 1),
   (0, 1, 1, 1, 0)));   

implementation

end.
  