      SUBROUTINE TABLE5 (*,IN,OUT,TRL,IBUF,WRT,LFN,FN)
C
C     THIS ROUTINE IS CALLED ONLY BY OUTPT5 TO COPY A TABLE FILE IN 'IN'
C     TO AN OUPUT FILE 'OUT', BY FORTRAN WRITE, FORMATTED OR UNFORMATTED
C
C     IN,OUT = INPUT AND OUTPUT FILE, INTEGERS
C     TRL    = TRAILER OF INPUT FILE, INTEGERS
C     P4     = 0, OUTPUT FILE IS TO BE WRITTEN UNFORMATTED, BINARY, INT.
C            = 1, OUTPUT FILE IS TO BE WRITTEN FORMATTED, INTEGER
C     TI     = ARRAY TO OVERRIDE DATA TYPE OUTPUT. INTEGERS
C              SEE RULES BELOW.
C     Z,IBUF = OPEN CORE AND GINO BUFFER POINTER, INTEGER
C     WRT,LFN= ARE COMMUNICATION FLAGS BETWEEN TABLE5 AND OUTPT5
C     FN     = ARRAY FOR INPUT FILE NAME
C
C     THE FOLLOWING CONVENTIONS ARE USED FOR FORMATTED TAPE -
C
C       A   '/'+A4  FORMAT FOR BCD WORD               ( 5 BYTES)
C       AN  'I'+I9  FORMAT FOR INTEGER                (10 BYTES)
C       A 'R'+E14.7 FORMAT FOR S.P. REAL NUMBER.      (15 BYTES)
C       A 'D'+D14.7 FORMAT FOR D.P. REAL NUMBER.      (15 BYTES)
C       A 'X'+4 BLANKS IS A FILLER, AT END OF A LINE  ( 5 BYTES)
C
C       EACH RECORD IS PRECEEDED BY L5 (IN I10 FORMAT) WHERE L5 IS THE
C       TOTAL NO. OF CHARACTERS OF THIS CURRENT RECORD DIVIDED BY 5.
C
C       EACH RECORD IS WRITTEN IN MULTIPLE LINES OF 130 CHARACTERS EACH.
C       (131 CHARACTERS TO BE EXACTLY - 130 PLUS A BLANK)
C
C       ONE OR TWO FILLERS MAY ATTACH TO THE END OF A LINE TO MAKE UP
C       130 CHARACTERS. THAT IS, INTEGER AND S.P.REAL NUMBER AT THE END
C       OF A LINE WILL NOT BE SPLITTED BETWEEN TWO LINES
C
C       IF A ZERO IS PRECEEDED BY A F.P. REAL NUMBER, IT WILL BE WRITTEN
C       OUT AS A REAL ZERO (0.0), INTEGER ZERO (0) OTHERWISE.
C
C       DUE TO THE FACTS THAT FLOATING POINT ZEROS ARE ALWAYS TREATED AS
C       INTEGERS, DOUBLE PRECISION CAN NOT BE DETECTED, AND OCCATIONALLY
C       AUTOMATIC DATA TYPE CHECKING MAY ERR, THE USER CAN OVERRIDE THE
C       OUTPUT DATA FORMAT BY DEFINING TI ARRAYS WITH THE FOLLOWING
C       RULES -
C
C          EACH TI PARAMETER MUST HOLD 9 DIGITS, FROM LEFT TO RIGHT.
C               ZEROS-FILLED IF NECCESSARY.
C               TOTALLY THERE ARE 10 TI PARAMETERS. THEREFORE, THERE ARE
C               UP TO 90 CONTINUOUS DIGITS CAN BE USED.
C               (DEFAULT IS 90 ZEROS)
C          EACH DIGIT HOLDS VALUE FROM 0 THROUGH 9, VALUE
C               0 MEANS DATA TYPE WILL BE SET AUTOMATICALLY BY TABLE5
C               1 MEANS DATA TYPE IS INTEGER
C               2 MEANS DATA TYPE IS REAL, SINGLE PRECISION
C               3 MEANS DATA TYPE IS BCD WORD (4 BYTES PER WORD)
C               4 MEANS DATA TYPE IS REAL, DOUGLE PRECISION
C             5-9 HAS SPECIAL MEANING. IT MEANS THERE ARE (5-9) VALUES
C                 OF DATA TYPE DEFINED BY THE NEXT VALUE FOLLOWING.
C          EACH DIGIT IN TI, EXCEPT 5 THRU 9, DEFINES THE CORRESPODING
C               DATA TYPE IN THE TABLE BLOCK DATA, STARTING FROM THE
C               FIRST DATA WORD AND CONTINUE TO THE LAST.
C          IF TI(1) IS NEGATIVE, INTERMEDIATE STEPS IN FORMAT GENERATION
C               ARE PRINTED OUT.
C     E.G.
C     TABLE- 3  4  3.4  5.0E-3  TESTING  .6D+7  9  G  3.2  8  0.  0  4
C            12 13  14  15  28  61   88   14   44 .7D+7
C     TI   - TI(1) =-112233413, TI(2) = 212516140  OR
C            TI(1) = 604000025, TI(2) = 060400000 (7TH AND 24 WORDS ARE
C                                            D.P. AND 12TH WORD IS REAL)
C     NOTE - 2 BCD WORDS IN 'TESTING',
C            ALL OTHERS ARE 1 COMPUTER WORD PER DATA ENTRY
C            TI(2), THE LAST TI USED HERE, MUST FILL UP WITH ZEROS TO
C               MAKE UP A 9-DIGIT WORD.
C
C     TO READ THE OUTPUT FILE, USE TABLE-V SUBROUTINE AS REFERENCE
C
C     NOTE - THE FORMATTED OUTPUT FILE CAN BE VIEWED AND/OR EDITTED BY
C            THE SYSTEM EDITOR
C
C     WRITTEN BY G.CHAN/UNISYS,  1989
C
C  $MIXED_FORMATS
C
      IMPLICIT INTEGER (A-Z)
      LOGICAL          DEBUG,TION,DP
      INTEGER          TRL(7),NAME(2),SUB(2),FN(3,1)
      REAL             TEMP(2),RZ(1)
      DOUBLE PRECISION DTEMP
      CHARACTER*10     FMT(30),FMTI,FMTR,FMTD,FMTB,FMTX,LPREN,RPREN,
     1                 LPRI10
      CHARACTER        UFM*23,UWM*25,UIM*29
      COMMON /XMSSG /  UFM,UWM,UIM
      COMMON /SYSTEM/  SYSBUF,NOUT
      COMMON /BLANK /  DUMMY(4),P4,TI(1)
      COMMON /ZZZZZZ/  Z(1)
CWKBI 7/94
      COMMON /MACHIN/  MACH
      EQUIVALENCE      (Z(1),RZ(1)) ,  (DTEMP,TEMP(1))
      DATA    SUB   /  4HTABL,4HE5  /, DEBUG   /   .FALSE.      /
      DATA    FMTI,    FMTR         / '1HI,I9,' ,  '1HR,E14.7,' /
      DATA    FMTB,    FMTD         / '1H/,A4,' ,  '1HD,D14.7,' /
      DATA    FMTX,    LPRI10       / '1HX,4X,' ,  '(I10,'      /
      DATA    LPREN,   RPREN, DEL   / '(', '1X)',   4H),.)      /
      DATA    END,     TBLE         /  4H*END,      4HTBLE      /
C
      DEBUG = .FALSE.
      IF (TI(1) .LT. 0) DEBUG =.TRUE.
      TI(1) = IABS(TI(1))
      TION  = .FALSE.
      DO 10 L = 1,10
      IF (TI(L) .NE. 0) TION=.TRUE.
   10 CONTINUE
      IF (DEBUG) CALL PAGE1
      IF (DEBUG) WRITE (NOUT,20)
   20 FORMAT (///5X,'*** IN TABLE5/OUTPUT5 ***')
      KORE  = IBUF - 2
C
C     OPEN INPUT FILE, AND READ FILE NAME IN THE FILE HEADER RECORD
C     WRITE ONE HEADER RECORD, IN OUTPT5 MATRIX HEADER FORMAT, TO
C     OUTPUT TAPE
C
      CALL OPEN (*810,IN,Z(IBUF),0)
      CALL READ (*820,*830,IN,NAME,2,1,KK)
      IF (DEBUG) WRITE (NOUT,30) NAME
   30 FORMAT (/5X,'PROCESSING...',2A4,/)
      I = 0
      J = 1
      TRL(7) = 0
      IF (P4 .EQ. 0) WRITE (OUT   ) I,J,J,DTEMP,(TRL(K),K=2,7),NAME
      IF (P4 .EQ. 1) WRITE (OUT,40) I,J,J,DTEMP,(TRL(K),K=2,7),NAME
   40 FORMAT (3I8,/,D26.17,6I8,2A4)
C
   50 IF (P4 .EQ. 1) GO TO 100
C
C     UNFORMATED WRITE
C
      J = 2
   60 CALL READ  (*700,*70,IN,Z(J),KORE,1,KK)
      J = 0
      GO TO 840
   70 IF (J .EQ. 1) GO TO 80
      J = 1
      Z(1) = KK
   80 CALL WRITE (OUT,Z(1),KK,1)
      GO TO 60
C
C     FORMATTED WRITE
C
  100 J = 2
      CALL READ (*700,*110,IN,Z(J),KORE,1,KK)
      J = 0
      GO TO 840
C
C     SET UP USER DIRECTED TI TABLE IN Z(KK2) THRU Z(KK3)
C
  110 IF (DEBUG) WRITE (NOUT,120) (TI(J),J=1,10)
  120 FORMAT (//5X,'TI PARAMETERS =',/4X,10(1X,I9))
      KK1 = KK  + 2
      KK2 = KK1 + KK
      KK3 = KK2 + KK
      J   = KORE - KK3 - 9
      IF (J .LT. 0) GO TO 840
      DO 140 K = KK1,KK3
  140 Z(K) = 0
      IF (.NOT.TION) GO TO 260
      K  = KK1 - 9
      LL = 0
      L  = -1
  150 IF (L .GE. 0) GO TO 170
      L  = 8
      LL = LL + 1
      K  = K  + 9
      IF (K.GE.KK2 .OR. LL.GT.10) GO TO 200
      TIL= TI(LL)
      IF (TIL .GT. 0) GO TO 170
      L  = -1
      GO TO 150
  170 TIL10 = TIL/10
      Z(K+L)= TIL - TIL10*10
      TIL   = TIL10
      L  = L - 1
      GO TO 150
C
  200 K  = KK2 - 1
      IF (DEBUG) WRITE (NOUT,210) (Z(J),J=KK1,K)
  210 FORMAT (//5X,'DIGITIZED TI PARAMTERS =',/,(3X,25I3))
      I  = KK2
      DO 240 J = KK1,K
      JZ = Z(J)
      IF (JZ .LE. 4) GO TO 230
      JI = JZ + I - 1
      JJ = Z(J+1)
      IF (JJ .GT. 4) GO TO 860
      DO 220 L = I,JI
  220 Z(L) = JJ
      I  = JI + 1
      Z(J+1) = -1
      GO TO 240
  230 IF (JZ .EQ. -1) GO TO 240
      Z(I) = JZ
      I  = I + 1
  240 CONTINUE
      I  = KK3 - 1
      IF (DEBUG) WRITE (NOUT,250) (Z(J),J=KK2,I)
  250 FORMAT (//,5X,'DECODED TI PARAMETERS =',/,(3X,25I3))
C
C     COUNT HOW MANY 5-BYTE WORDS TO BE GENERATED, FILLERS INCLUDED
C
  260 KK2 = KK2 - 1
      K   = KK1
      PJJ = 1
      L5  = 10
C
      IF (DEBUG) CALL PAGE1
      DO 400 I = 1,KK
      K   = K + 1
      PJJ = JJ
      IF (TION) GO TO 290
  280 JJ  = NUMTYP(Z(I+1)) + 1
      GO TO 300
  290 JJ  = Z(KK2+I) + 1
      IF (JJ .EQ. 1) GO TO 280
  300 GO TO (310,320,340,380,340), JJ
C              0,  I,  R,  B,  D
C
C     ZERO
C
  310 JJ  = 3
      IF (PJJ.EQ.3 .OR. PJJ.EQ.5) GO TO 340
      JJ  = 2
C
C     INTEGER
C
  320 IF (MOD(L5,130) .LE. 120) GO TO 330
      Z(K)= 6
      K   = K  + 1
      L5  = L5 + 5
  330 Z(K)= JJ
      L5  = L5 + 10
      GO TO 400
C
C     REAL, S.P. OR D.P.
C
  340 J   = MOD(L5,130)
      IF (J-120) 370,350,360
  350 L5  = L5 + 5
      Z(K)= 6
      K   = K  + 1
  360 L5  = L5 + 5
      Z(K)= 6
      K   = K + 1
  370 Z(K)= JJ
      L5  = L5 + 15
      GO TO 400
C
C     BCD
C
  380 Z(K)= JJ
      L5  = L5 + 5
C
  400 CONTINUE
C
C     NOW WE FORM THE FORMAT
C
      DP  = .FALSE.
      KK  = K
      Z(1) = (L5-10)/5
      FMT(1) = LPRI10
C
      L5  = 10
      L   = 1
      I   = 1
      IB  = 1
      K   = KK1
  500 IF (L5 .LT. 130) GO TO 540
      L   = L + 1
      FMT(L) = RPREN
      IF (.NOT.DEBUG) GO TO 520
      CALL PAGE2 (-5)
      WRITE  (NOUT,510) (FMT(J),J=1,L)
  510 FORMAT (/,' DYNAMICALLY GENERATED FORMAT =',/,(1X,7A10))
CWKBD 7/94   520 WRITE  (OUT,FMT,ERR=530) (RZ(J),J=IB,I) 
CWKBNB 7/94
  520 IF ( MACH .NE. 5 .AND. MACH .NE. 2 ) GO TO 525
      WRITE  (OUT,FMT,ERR=530) (RZ(J),J=IB,I) 
      GO TO 530
  525 ISAVE = NOUT
      NOUT  = OUT
      CALL FORWRT ( FMT, RZ(IB), I-IB+1)
      NOUT  = ISAVE
CWKBNE 7/94
  530 IB  = I + 1
      L5  = 0
      L   = 1
      FMT(1) = LPREN
C
  540 K   = K + 1
      IF (K .GT. KK) GO TO 650
      I   = I + 1
      L   = L + 1
      J   = Z(K)
      GO TO (600,600,610,620,630,640), J
C              0,  I,  R,  B,  D, FL
  600 FMT(L) = FMTI
      L5  = L5 + 10
      GO TO 500
C
C     S.P. REAL NUMBERS
C
  610 FMT(L) = FMTR
      L5  = L5 + 15
      GO TO 500
C
  620 FMT(L) = FMTB
      L5  = L5 + 5
      GO TO 500
C
C     D.P. NUMBERS
C
  630 FMT(L) = FMTD
      L5     = L5 + 15
      TEMP(1)= RZ(L  )
      TEMP(2)= RZ(L+1)
      Z(L  ) = SNGL(DTEMP)
      Z(L+1) = DEL
      DP     =.TRUE.
      GO TO 500
C
C     FILLER
C
  640 FMT(L) = FMTX
      L5 = L5 + 5
      I  = I  - 1
      GO TO 500
C
  650 L  = L + 1
      FMT(L) = RPREN
      IF (.NOT.DEBUG) GO TO 660
      CALL PAGE2 (-5)
      WRITE (NOUT,510) (FMT(J),J=1,L)
C
C     REMOVED SECOND HALVES OF ALL D.P. NUMBERS IF THEY ARE PRESENT
C     THEN WRITE THE ARRAY OUT WITH THE GENERATED FORMAT
C
  660 IF (.NOT.DP) GO TO 680
      K   = IB - 1
      DO 670 J = IB,I
      IF (Z(J) .EQ. DEL) GO TO 670
      K   = K + 1
      Z(K)= Z(J)
  670 CONTINUE
      I   = K
CWKBD 7/94  680 WRITE (OUT,FMT,ERR=690) (RZ(J),J=IB,I) 
CWKBNB 7/94
  680 IF ( MACH .NE. 2 .AND. MACH .NE. 5 ) GO TO 685
      WRITE (OUT,FMT,ERR=690) (RZ(J),J=IB,I) 
      GO TO 690
  685 ISAVE = NOUT
      NOUT  = OUT
      CALL FORWRT ( FMT, RZ(IB), I-IB+1) 
      NOUT  = ISAVE
CWKBNE 7/94
C
C     RETURN TO PROCESS ANOTHER RECORD ON INPUT FILE
C
  690 DEBUG = .FALSE.
      GO TO 50
C
C     ALL DONE. SET WRT FLAG, UPDATE LFN AND FN, AND CLOSE INPUT FILE
C     AND ECHO USER MESSAGES
C
  700 WRT = 1
      IF (LFN .LT. 0) LFN = 0
      LFN = LFN + 1
      FN(1,LFN) = NAME(1)
      FN(2,LFN) = NAME(2)
      FN(3,LFN) = TBLE
      CALL CLOSE (IN,1)
      IF (P4 .EQ. 1) GO TO 730
      CALL PAGE2 (-7)
      WRITE  (OUT) I,END
      WRITE  (NOUT,710) UIM,NAME
  710 FORMAT (A29,' FROM OUTPUT5 MODULE, SUCCESSFUL TABLE-DATA ',
     1       'TRANSFERED FROM INPUT FILE ',2A4,' TO OUTPUT TAPE', //5X,
     2        'A HEADER RECORD WAS FIRST WRITTEN, THEN FOLLOWED BY')
      WRITE  (NOUT,720)
  720 FORMAT (5X,'FORTRAN UNFORMATTED (BINARY) WRITE')
      GO TO 950
  730 I  = 1
      WRITE  (OUT,740) I,END
  740 FORMAT (1X,I9,1X,A4)
      CALL PAGE2 (-13)
      WRITE  (NOUT,710) UIM,NAME
      WRITE  (NOUT,750)
  750 FORMAT (5X,'FORTRAN FORMATTED WRITE, 130 CHARACTERS PER LINE -',
     1      /10X,'(''/'',A4 FOR BCD WORD       ( 5 BYTES)',
     2      /11X,'''I'',I9 FOR INTEGER        (10 BYTES)',
     3      /11X,'''R'',E14.7 FOR S.P. REAL   (15 BYTES)',
     4      /11X,'''D'',D14.7 FOR D.P. NUMBER (15 BYTES)',
     5      /11X,'''X    '', FOR FILLER       ( 5 BYTES)')
      GO TO 950
C
C     ERROR
C
  810 J = 1
      GO TO 850
  820 J = 2
      GO TO 850
  830 J = 3
      GO TO 850
  840 IN= J
      J = 8
  850 CALL MESAGE (J,IN,SUB)
      GO TO 880
  860 WRITE  (NOUT,870) UWM,JI,JJ
  870 FORMAT (A25,', OUTPTT5 MODULE PARAMETER ERROR.  WRONG INDEX ',
     1       'VALUES',2I3)
  880 CALL FNAME (IN,NAME)
      WRITE  (NOUT,890) NAME
  890 FORMAT (/5X,'TABLE DATA BLOCK ',2A4,' WAS NOT COPIED TO OUTPUT',
     1        ' TAPE')
  900 CALL FWDREC (*950,IN)
      GO TO 900
C
  950 RETURN 1
      END