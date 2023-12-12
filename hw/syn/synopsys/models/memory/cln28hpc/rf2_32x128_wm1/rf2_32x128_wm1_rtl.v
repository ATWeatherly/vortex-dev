/* verilog_rtl_memcomp Version: c0.1.0-EAC */
/* common_memcomp Version: c0.1.2-EAC */
/* lang compiler Version: 4.5.1-EAC Nov  6 2014 16:10:45 */
//
//       CONFIDENTIAL AND PROPRIETARY SOFTWARE OF ARM PHYSICAL IP, INC.
//      
//       Copyright (c) 1993 - 2019 ARM Physical IP, Inc.  All Rights Reserved.
//      
//       Use of this Software is subject to the terms and conditions of the
//       applicable license agreement with ARM Physical IP, Inc.
//       In addition, this Software is protected by patents, copyright law 
//       and international treaties.
//      
//       The copyright notice(s) in this Software does not indicate actual or
//       intended publication of this Software.
//
//       Repair Verilog RTL for High Capacity Two Port Register File SVT MVT Compiler
//
//       Instance Name:              rf2_32x128_wm1_rtl_top
//       Words:                      32
//       User Bits:                  128
//       Mux:                        2
//       Drive:                      6
//       Write Mask:                 On
//       Extra Margin Adjustment:    On
//       Redundancy:                 off
//       Redundant Rows:             0
//       Redundant Columns:          2
//       Test Muxes                  On
//       Ser:                        none
//       Retention:                  on
//       Power Gating:               off
//
//       Creation Date:  Mon Oct 14 17:01:45 2019
//       Version:      r0p0
//
//       Verified
//
//       Known Bugs: None.
//
//       Known Work Arounds: N/A
//
`timescale 1ns/1ps

module rf2_32x128_wm1_rtl_top (
          CENYA, 
          AYA, 
          CENYB, 
          WENYB, 
          AYB, 
          QA, 
          SOA, 
          SOB, 
          CLKA, 
          CENA, 
          AA, 
          CLKB, 
          CENB, 
          WENB, 
          AB, 
          DB, 
          EMAA, 
          EMASA, 
          EMAB, 
          TENA, 
          TCENA, 
          TAA, 
          TENB, 
          TCENB, 
          TWENB, 
          TAB, 
          TDB, 
          RET1N, 
          SIA, 
          SEA, 
          DFTRAMBYP, 
          SIB, 
          SEB, 
          COLLDISN
   );

   output                   CENYA;
   output [4:0]             AYA;
   output                   CENYB;
   output [127:0]           WENYB;
   output [4:0]             AYB;
   output [127:0]           QA;
   output [1:0]             SOA;
   output [1:0]             SOB;
   input                    CLKA;
   input                    CENA;
   input [4:0]              AA;
   input                    CLKB;
   input                    CENB;
   input [127:0]            WENB;
   input [4:0]              AB;
   input [127:0]            DB;
   input [2:0]              EMAA;
   input                    EMASA;
   input [2:0]              EMAB;
   input                    TENA;
   input                    TCENA;
   input [4:0]              TAA;
   input                    TENB;
   input                    TCENB;
   input [127:0]            TWENB;
   input [4:0]              TAB;
   input [127:0]            TDB;
   input                    RET1N;
   input [1:0]              SIA;
   input                    SEA;
   input                    DFTRAMBYP;
   input [1:0]              SIB;
   input                    SEB;
   input                    COLLDISN;
   wire [127:0]             QOA;
   wire [127:0]             DIB;

   assign QA = QOA;
   assign DIB = DB;
   rf2_32x128_wm1_fr_top u0 (
         .CENYA(CENYA),
         .AYA(AYA),
         .CENYB(CENYB),
         .WENYB(WENYB),
         .AYB(AYB),
         .QOA(QOA),
         .SOA(SOA),
         .SOB(SOB),
         .CLKA(CLKA),
         .CENA(CENA),
         .AA(AA),
         .CLKB(CLKB),
         .CENB(CENB),
         .WENB(WENB),
         .AB(AB),
         .DIB(DIB),
         .EMAA(EMAA),
         .EMASA(EMASA),
         .EMAB(EMAB),
         .TENA(TENA),
         .TCENA(TCENA),
         .TAA(TAA),
         .TENB(TENB),
         .TCENB(TCENB),
         .TWENB(TWENB),
         .TAB(TAB),
         .TDB(TDB),
         .RET1N(RET1N),
         .SIA(SIA),
         .SEA(SEA),
         .DFTRAMBYP(DFTRAMBYP),
         .SIB(SIB),
         .SEB(SEB),
         .COLLDISN(COLLDISN)
);

endmodule

module rf2_32x128_wm1_fr_top (
          CENYA, 
          AYA, 
          CENYB, 
          WENYB, 
          AYB, 
          QOA, 
          SOA, 
          SOB, 
          CLKA, 
          CENA, 
          AA, 
          CLKB, 
          CENB, 
          WENB, 
          AB, 
          DIB, 
          EMAA, 
          EMASA, 
          EMAB, 
          TENA, 
          TCENA, 
          TAA, 
          TENB, 
          TCENB, 
          TWENB, 
          TAB, 
          TDB, 
          RET1N, 
          SIA, 
          SEA, 
          DFTRAMBYP, 
          SIB, 
          SEB, 
          COLLDISN
   );

   output                   CENYA;
   output [4:0]             AYA;
   output                   CENYB;
   output [127:0]           WENYB;
   output [4:0]             AYB;
   output [127:0]           QOA;
   output [1:0]             SOA;
   output [1:0]             SOB;
   input                    CLKA;
   input                    CENA;
   input [4:0]              AA;
   input                    CLKB;
   input                    CENB;
   input [127:0]            WENB;
   input [4:0]              AB;
   input [127:0]            DIB;
   input [2:0]              EMAA;
   input                    EMASA;
   input [2:0]              EMAB;
   input                    TENA;
   input                    TCENA;
   input [4:0]              TAA;
   input                    TENB;
   input                    TCENB;
   input [127:0]            TWENB;
   input [4:0]              TAB;
   input [127:0]            TDB;
   input                    RET1N;
   input [1:0]              SIA;
   input                    SEA;
   input                    DFTRAMBYP;
   input [1:0]              SIB;
   input                    SEB;
   input                    COLLDISN;

   wire [127:0]    DB;
   wire [127:0]    QA;

   assign DB=DIB;
   assign QOA=QA;
   rf2_32x128_wm1 u0 (
         .CENYA(CENYA),
         .AYA(AYA),
         .CENYB(CENYB),
         .WENYB(WENYB),
         .AYB(AYB),
         .QA(QA),
         .SOA(SOA),
         .SOB(SOB),
         .CLKA(CLKA),
         .CENA(CENA),
         .AA(AA),
         .CLKB(CLKB),
         .CENB(CENB),
         .WENB(WENB),
         .AB(AB),
         .DB(DB),
         .EMAA(EMAA),
         .EMASA(EMASA),
         .EMAB(EMAB),
         .TENA(TENA),
         .TCENA(TCENA),
         .TAA(TAA),
         .TENB(TENB),
         .TCENB(TCENB),
         .TWENB(TWENB),
         .TAB(TAB),
         .TDB(TDB),
         .RET1N(RET1N),
         .SIA(SIA),
         .SEA(SEA),
         .DFTRAMBYP(DFTRAMBYP),
         .SIB(SIB),
         .SEB(SEB),
         .COLLDISN(COLLDISN)
   );

endmodule // rf2_32x128_wm1_fr_top

