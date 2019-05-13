----------------------------------------------------------------------------------
-- Company:         IIT, Madras
-- Engineer:        Urvish Markad
-- 
-- Create Date:    
-- Design Name:     Zone Valid Module for ISIP Core
-- Module Name:     Zone_Valid - Behavioral
-- Project Name:    
-- Target Devices:  ZC702 Xilinx Zynq Development Board
-- Tool Versions:   Vivado 2018.1
-- Description:     
-- 
-- Dependencies:    NA
-- 
-- Revision:        0.01
-- Revision         0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

Entity Zone_Valid is
 Port ( 
       gresetn                      :   In  Std_Logic;
       aclken                       :   In  Std_Logic;
       aclk                         :   In  Std_Logic;
       
       s_axis_video_tvalid          :   In  Std_Logic;
       s_axis_video_tuser_sof       :   In  Std_Logic;
       s_axis_video_tlast           :   In  Std_Logic;
       
       HMAX0                        :   In  Std_Logic_Vector(15 Downto 0);          --Double Buffered 1st Horizontal Delimiter 
       HMAX1                        :   In  Std_Logic_Vector(15 Downto 0);          --Double Buffered 2nd Horizontal Delimiter 
       HMAX2                        :   In  Std_Logic_Vector(15 Downto 0);          --Double Buffered 3rd Horizontal Delimiter 

       VMAX0                        :   In  Std_Logic_Vector(15 Downto 0);          --Double Buffered 1st Vertical Delimiter 
       VMAX1                        :   In  Std_Logic_Vector(15 Downto 0);          --Double Buffered 2nd Vertical Delimiter 
       VMAX2                        :   In  Std_Logic_Vector(15 Downto 0);          --Double Buffered 3rd Vertical Delimiter 
       
       ACTIVE_SIZE                  :   In  Std_Logic_Vector(31 Downto 0);          --Bits 0-15 : Active Pixels Per Line, Bits 16-31: Active Lines Per Frame
       
       ZONE_tvalid                  :   Out Std_Logic_Vector(15 Downto 0);          --Zone Valid Out
       ZONE_tsoz                    :   Out Std_Logic_Vector(15 Downto 0);          --Zone SOZ (Start of Zone) Out
       ZONE_tlast                   :   Out Std_Logic_Vector(15 Downto 0);          --Zone Last
       ZONE_teoz                    :   Out Std_Logic_Vector(15 Downto 0);           --Zone EOZ (End of Zone) Out 
       
       FPC_Out                      :   Out Std_Logic_Vector(15 Downto 0);
       FLC_Out                      :   Out Std_Logic_Vector(15 Downto 0)                       
       );
End Zone_Valid;

Architecture Behavioral of Zone_Valid is


Type        Vector_Array    is Array (0 to 15) of Std_Logic_Vector(15 Downto 0);


Signal      Clk                              :   Std_Logic;

Signal      FPC                              :   Std_Logic_Vector(15 Downto 0);     --Frame Pixel Counter
Signal      FLC                              :   Std_Logic_Vector(15 Downto 0);     --Frame Line Counter

Signal      ZoneValid                        :   Std_Logic_Vector(15 Downto 0);
Signal      Zone_SOZ                         :   Std_Logic_Vector(15 Downto 0);
Signal      Zone_Last                        :   Std_Logic_Vector(15 Downto 0);
Signal      Zone_EOZ                         :   Std_Logic_Vector(15 Downto 0);

Begin

Clk <= Aclken And Aclk;

Zone_Tsoz   <= Zone_SOZ;   
Zone_Tvalid <= ZoneValid;
Zone_Tlast  <= Zone_Last;
Zone_Teoz   <= Zone_EOZ;

FPC_Out <= FPC;
FLC_Out <= FLC;



FPC_Comp: Process(Clk, Gresetn)             --Frame Pixel Counter Process
Begin
If(Gresetn = '0') Then
    FPC <= (Others=>'0');                   
Elsif(Rising_Edge(Clk)) Then
    If((S_Axis_Video_Tvalid)='1' ) Then
        If(FPC = (ACTIVE_SIZE(15 Downto 0) - 1) ) Then       --Initialize to zero when reached maximum i.e. PixelsPerLine = ACTIVE_SIZE(15 Downto 0)           
            FPC <= (Others=>'0');
        Else                
            FPC <= FPC + 1;
        End If;
    Else
        FPC <= FPC;
    End If;
Else
    FPC <= FPC;
End If;                
End Process;



FLC_Comp: Process(Clk, Gresetn)                 --Frame Line Counter Process
Begin
If(Gresetn = '0') Then
    FLC <= (Others=>'0');
Elsif(Rising_Edge(Clk)) Then
    If(S_Axis_Video_Tvalid = '1') Then
        If(FLC = (ACTIVE_SIZE(31 Downto 16) - 1) And FPC = (ACTIVE_SIZE(15 Downto 0) - 1)) Then
            FLC <= (Others=>'0');
        Else
            If(S_Axis_Video_Tlast = '1') Then
                FLC <= FLC +1;
            Else
                FLC <= FLC;    
            End If;    
        End If;
    Else
        FLC <= FLC;
    End If;                
Else
    FLC <= FLC;
End If;                                      
End Process;



ZonalSOFGen: Process(Clk, Gresetn)              --Zonal SOF Generation Process or SOZ (Start of Zone) 
Begin
If(Gresetn = '0') Then
    Zone_SOZ  <= (Others=>'0');
Elsif(Rising_Edge(Clk)) Then
    If((S_Axis_Video_Tvalid) = '1') Then
        If(FPC = 0 And FLC = 0)  Then 
            Zone_SOZ(0) <= '1';                 --Zone_0 SOZ = '1' When at (0,0)
        Else
            Zone_SOZ(0) <= '0';                 --Zone_0 SOZ = '1' When others
        End If;
        
        If(FPC = HMAX0 -1 And FLC = 0) Then     
            Zone_SOZ(1) <= '1';                 --Zone_1 SOZ = '1' When at (HMAX0 - 1, 0)
        Else
            Zone_SOZ(1) <= '0';                 --Zone_1 SOZ = '0' When others  
        End If; 
        
        If(FPC = HMAX1 - 1 And FLC = 0) Then
            Zone_SOZ(2)  <= '1';                --Zone_2 SOZ = '1' When at (HMAX1 - 1, 0)
        Else
            Zone_SOZ(2)  <= '0';                --Zone_2 SOZ = '0' When others
        End If;           
        
        If(FPC = HMAX2 - 1 And FLC = 0) Then
            Zone_SOZ(3)  <= '1';                --Zone_3 SOZ = '1' When at (HMAX2 - 1, 0)
        Else
            Zone_SOZ(3)  <= '0';                --Zone_3 SOZ = '0' When others
        End If;        
        
        
        
        
        If(FPC = 0 And FLC = VMAX0 - 1) Then
            Zone_SOZ(4)  <= '1';                --Zone_4 SOZ = '1' When at (0, VMAX0 - 1)
        Else
            Zone_SOZ(4)  <= '0';                --Zone_4 SOZ = '0' When others
        End If;         
        
        If(FPC = HMAX0 - 1 And FLC = VMAX0 - 1) Then
            Zone_SOZ(5)  <= '1';                --Zone_5 SOZ = '1' When at (HMAX0 - 1, VMAX0 - 1)
        Else
            Zone_SOZ(5)  <= '0';                --Zone_5 SOZ = '0' When others
        End If; 
 
        If(FPC = HMAX1 - 1 And FLC = VMAX0 - 1) Then
            Zone_SOZ(6)  <= '1';                --Zone_6 SOZ = '1' When at (HMAX1 - 1, VMAX0 - 1)
        Else
            Zone_SOZ(6)  <= '0';                --Zone_6 SOZ = '0' When others
        End If;    
        
        If(FPC = HMAX2 - 1 And FLC = VMAX0 - 1) Then
            Zone_SOZ(7)  <= '1';                --Zone_7 SOZ = '1' When at (HMAX2 - 1, VMAX0 - 1)
        Else
            Zone_SOZ(7)  <= '0';                --Zone_7 SOZ = '0' When others
        End If;  
        
        
        
        
        If(FPC = 0 And FLC = VMAX1 - 1) Then
            Zone_SOZ(8)  <= '1';                --Zone_8 SOZ = '1' When at (0, VMAX1 - 1)
        Else
            Zone_SOZ(8)  <= '0';                --Zone_8 SOZ = '0' When others
        End If;                               
        
        If(FPC = HMAX0 - 1 And FLC = VMAX1 - 1) Then
            Zone_SOZ(9)  <= '1';                --Zone_9 SOZ = '1' When at (HMAX0 - 1, VMAX1 - 1)
        Else
            Zone_SOZ(9)  <= '0';                --Zone_9 SOZ = '0' When others
        End If;         
 
        If(FPC = HMAX1 - 1 And FLC = VMAX1 - 1) Then
            Zone_SOZ(10)  <= '1';                --Zone_10 SOZ = '1' When at (HMAX1 - 1, VMAX1 - 1)
        Else
            Zone_SOZ(10)  <= '0';                --Zone_10 SOZ = '0' When others
        End If;
        
        If(FPC = HMAX2 - 1 And FLC = VMAX1 - 1) Then
            Zone_SOZ(11)  <= '1';                --Zone_11 SOZ = '1' When at (HMAX2 - 1, VMAX1 - 1)
        Else
            Zone_SOZ(11)  <= '0';                --Zone_11 SOZ = '0' When others
        End If; 
        
        
        
        
        If(FPC = 0 And FLC = VMAX2 - 1) Then
            Zone_SOZ(12)  <= '1';                --Zone_12 SOZ = '1' When at (0, VMAX2 - 1)
        Else
            Zone_SOZ(12)  <= '0';                --Zone_12 SOZ = '0' When others
        End If;
        
        If(FPC = HMAX0 - 1 And FLC = VMAX2 - 1) Then
            Zone_SOZ(13)  <= '1';                --Zone_13 SOZ = '1' When at (HMAX0 - 1, VMAX2 - 1)
        Else
            Zone_SOZ(13)  <= '0';                --Zone_13 SOZ = '0' When others
        End If;
        
        If(FPC = HMAX1 - 1 And FLC = VMAX2 - 1) Then
            Zone_SOZ(14)  <= '1';                --Zone_14 SOZ = '1' When at (HMAX1 - 1, VMAX2 - 1)
        Else
            Zone_SOZ(14)  <= '0';                --Zone_14 SOZ = '0' When others
        End If;                                   
        
        If(FPC = HMAX2 - 1 And FLC = VMAX2 - 1) Then
            Zone_SOZ(15)  <= '1';                --Zone_15 SOZ = '1' When at (HMAX2 - 1, VMAX2 - 1)
        Else
            Zone_SOZ(15)  <= '0';                --Zone_15 SOZ = '0' When others
        End If;
   Else
        Zone_SOZ    <= Zone_SOZ;
   End If;     
Else
    Zone_SOZ    <= Zone_SOZ;
End If;                           
End Process;


ZonalValidGen: Process(Clk, Gresetn)
Begin
If(Gresetn = '0') Then
    ZoneValid  <= (Others=>'0');
Elsif(Rising_Edge(Clk)) Then
    If((S_Axis_Video_Tvalid) = '1') Then
        
        If((FPC < HMAX0 And FLC < VMAX0)) Then
            ZoneValid(0)   <= '1';
        Else
            ZoneValid(0)   <= '0';    
        End If;
        
        If(FPC >= HMAX0 And FPC < HMAX1 And FLC < VMAX0) Then
            ZoneValid(1)    <= '1';
        Else
            ZoneValid(1)    <= '0';
        End If;
        
        If(FPC >= HMAX1 And FPC < HMAX2 And FLC < VMAX0) Then
            ZoneValid(2)    <= '1';
        Else
            ZoneValid(2)    <= '0';
        End If;
        
        If(FPC >=HMAX2 And FLC  < VMAX0) Then
            ZoneValid(3)    <= '1';
        Else
            ZoneValid(3)    <= '0';
        End If;
        
        
        
        
        If(FPC < HMAX0 And FLC >= VMAX0 And FLC < VMAX1) Then
            ZoneValid(4)    <= '1';
        Else
            ZoneValid(4)    <= '0';
        End If;
        
        If(FPC >= HMAX0 And FPC < HMAX1 And FLC >= VMAX0 And FLC < VMAX1) Then
            ZoneValid(5)    <= '1';
        Else
            ZoneValid(5)    <= '0';
        End If;
        
        If(FPC >= HMAX1 And FPC < HMAX2 And FLC >= VMAX0 And FLC < VMAX1) Then
            ZoneValid(6)    <= '1';
        Else
            ZoneValid(6)    <= '0';
        End If;
        
        If(FPC >= HMAX2 And FLC >= VMAX0 And FLC < VMAX1) Then
            ZoneValid(7)    <= '1';
        Else
            ZoneValid(7)    <= '0';
        End If;
        
        
        
        
        If(FPC < HMAX0 And FLC >= VMAX1 And FLC < VMAX2) Then
            ZoneValid(8)    <= '1';
        Else
            ZoneValid(8)    <= '0';
        End If;
        
        If(FPC >= HMAX0 And FPC < HMAX1 And FLC >= VMAX1 And FLC < VMAX2) Then
            ZoneValid(9)    <= '1';
        Else
            ZoneValid(9)    <= '0';
        End If;
        
        If(FPC >= HMAX1 And FPC < HMAX2 And FLC >= VMAX1 And FLC < VMAX2) Then
            ZoneValid(10)   <= '1';
        Else
            ZoneValid(10)   <= '0';
        End If;
            
        If(FPC >= HMAX2 And FLC >= VMAX1 And FLC < VMAX2) Then
            ZoneValid(11)   <= '1';
        Else
            ZoneValid(11)   <= '0';
        End If;
        
        
        
        If(FPC < HMAX0 And FLC >= VMAX2) Then
            ZoneValid(12)   <= '1';
        Else
            ZoneValid(12)   <= '0';
        End If;
        
        If(FPC >= HMAX0 And FPC < HMAX1 And FLC >= VMAX2) Then
            ZoneValid(13)   <= '1';
        Else
            ZoneValid(13)   <= '0';
        End If;
        
        If(FPC >= HMAX1 And FPC < HMAX2 And FLC >= VMAX2) Then
            ZoneValid(14)   <= '1';
        Else
            ZoneValid(14)   <= '0';
        End If;
        
        If(FPC >= HMAX2 And FLC >= VMAX2) Then
            ZoneValid(15)   <= '1';
        Else
            ZoneValid(15)   <= '0';
        End If;
   Else
     ZoneValid   <= (Others=>'0');
   End If; 
Else
    ZoneValid   <= ZoneValid;
End If;                                                                                                                  
                                           
End Process;


ZoneLastGen: Process(Clk, Gresetn)
Begin
If(Gresetn = '0') Then
    Zone_Last   <= (Others=>'0');
Elsif(Rising_Edge(Clk)) Then
    If((S_Axis_Video_Tvalid) = '1') Then
        
        If(FPC = HMAX0 - 1 And FLC < VMAX0) Then
            Zone_Last(0)    <= '1';
        Else
            Zone_Last(0)    <= '0';
        End If;
        
        If(FPC = HMAX1 - 1 And FLC < VMAX0) Then
            Zone_Last(1)    <= '1';
        Else
            Zone_Last(1)    <= '0';
        End If;
        
        If(FPC = HMAX2 - 1 And FLC < VMAX0) Then
            Zone_Last(2)    <= '1';
        Else
            Zone_Last(2)    <= '0';
        End If;
        
        If(FPC = ACTIVE_SIZE(15 Downto 0) - 1 And FLC < VMAX0) Then
            Zone_Last(3)    <= '1';
        Else
            Zone_Last(3)    <= '0';
        End If;
        
        
        
        If(FPC = HMAX0 -1 And FLC >= VMAX0 And FLC < VMAX1) Then
            Zone_Last(4)    <= '1';
        Else
            Zone_Last(4)    <= '0';
        End If;
        
        If(FPC = HMAX1 - 1 And FLC >= VMAX0 And FLC < VMAX1) Then
            Zone_Last(5)    <= '1';
        Else
            Zone_Last(5)    <= '0';
        End If;
        
        If(FPC = HMAX2 - 1 And FLC >= VMAX0 And FLC < VMAX1) Then
            Zone_Last(6)    <= '1';
        Else
            Zone_Last(6)    <= '0';
        End If;
        
        If(FPC = ACTIVE_SIZE(15 Downto 0) - 1 And FLC >= VMAX0 And FLC < VMAX1) Then
            Zone_Last(7)    <= '1';
        Else
            Zone_Last(7)    <= '0';
        End If;
        
        

        If(FPC = HMAX0 -1 And FLC >= VMAX1 And FLC < VMAX2) Then
            Zone_Last(8)    <= '1';
        Else
            Zone_Last(8)    <= '0';
        End If;
        
        If(FPC = HMAX1 - 1 And FLC >= VMAX1 And FLC < VMAX2) Then
            Zone_Last(9)    <= '1';
        Else
            Zone_Last(9)    <= '0';
        End If;
        
        If(FPC = HMAX2 - 1 And FLC >= VMAX1 And FLC < VMAX2) Then
            Zone_Last(10)    <= '1';
        Else
            Zone_Last(10)    <= '0';
        End If;
        
        If(FPC = ACTIVE_SIZE(15 Downto 0) - 1 And FLC >= VMAX1 And FLC < VMAX2) Then
            Zone_Last(11)    <= '1';
        Else
            Zone_Last(11)    <= '0';
        End If;            
        
        
        
        If(FPC = HMAX0 -1 And FLC >= VMAX2) Then
            Zone_Last(12)    <= '1';
        Else
            Zone_Last(12)    <= '0';
        End If;
        
        If(FPC = HMAX1 - 1 And FLC >= VMAX2) Then
            Zone_Last(13)    <= '1';
        Else
            Zone_Last(13)    <= '0';
        End If;
        
        If(FPC = HMAX2 - 1 And FLC >= VMAX2) Then
            Zone_Last(14)    <= '1';
        Else
            Zone_Last(14)    <= '0';
        End If;
        
        If(FPC = ACTIVE_SIZE(15 Downto 0) - 1 And FLC >= VMAX2) Then
            Zone_Last(15)    <= '1';
        Else
            Zone_Last(15)    <= '0';
        End If;                                                                            
Else
    Zone_Last   <= Zone_Last;
End If;

Else
    Zone_Last   <= Zone_Last;
End If;            
End Process;


ZoneEOZ_Comp: Process(Clk, Gresetn)
Begin
If(Gresetn = '0') Then
    Zone_EOZ    <= (Others=>'0');
Elsif(Rising_Edge(Clk)) Then
    If((S_Axis_Video_Tvalid) = '1')  Then
    
        If(FPC = (HMAX0 -1) And FLC = (VMAX0 - 1)) Then
            Zone_EOZ(0)    <= '1';
        Else
            Zone_EOZ(0)    <= '0';
        End If;
        
        If(FPC = HMAX1 - 1 And FLC = VMAX0 - 1) Then
            Zone_EOZ(1)    <= '1';
        Else
            Zone_EOZ(1)    <= '0';
        End If;
        
        If(FPC = HMAX2 - 1 And FLC = VMAX0 - 1) Then
            Zone_EOZ(2)    <= '1';
        Else
            Zone_EOZ(2)    <= '0';
        End If;
        
        If(FPC = ACTIVE_SIZE(15 Downto 0) - 1 And FLC  = VMAX0 - 1) Then
            Zone_EOZ(3)    <= '1';
        Else
            Zone_EOZ(3)    <= '0';
        End If; 
        


        If(FPC = HMAX0 -1 And FLC = VMAX1 - 1) Then
            Zone_EOZ(4)    <= '1';
        Else
            Zone_EOZ(4)    <= '0';
        End If;
        
        If(FPC = HMAX1 - 1 And FLC = VMAX1 - 1) Then
            Zone_EOZ(5)    <= '1';
        Else
            Zone_EOZ(5)    <= '0';
        End If;
        
        If(FPC = HMAX2 - 1 And FLC = VMAX1 - 1) Then
            Zone_EOZ(6)    <= '1';
        Else
            Zone_EOZ(6)    <= '0';
        End If;
        
        If(FPC = ACTIVE_SIZE(15 Downto 0) - 1 And FLC  = VMAX1 - 1) Then
            Zone_EOZ(7)    <= '1';
        Else
            Zone_EOZ(7)    <= '0';
        End If;
        


        If(FPC = HMAX0 -1 And FLC = VMAX2 - 1) Then
            Zone_EOZ(8)    <= '1';
        Else
            Zone_EOZ(8)    <= '0';
        End If;
        
        If(FPC = HMAX1 - 1 And FLC = VMAX2 - 1) Then
            Zone_EOZ(9)    <= '1';
        Else
            Zone_EOZ(9)    <= '0';
        End If;
        
        If(FPC = HMAX2 - 1 And FLC = VMAX2 - 1) Then
            Zone_EOZ(10)    <= '1';
        Else
            Zone_EOZ(10)    <= '0';
        End If;
        
        If(FPC = ACTIVE_SIZE(15 Downto 0) - 1 And FLC  = VMAX2 - 1) Then
            Zone_EOZ(11)    <= '1';
        Else
            Zone_EOZ(11)    <= '0';
        End If;
        
        
        If(FPC = HMAX0 -1 And FLC = ACTIVE_SIZE(31 Downto 16) - 1) Then
            Zone_EOZ(12)    <= '1';
        Else
            Zone_EOZ(12)    <= '0';
        End If;
        
        If(FPC = HMAX1 - 1 And FLC = ACTIVE_SIZE(31 Downto 16) - 1) Then
            Zone_EOZ(13)    <= '1';
        Else
            Zone_EOZ(13)    <= '0';
        End If;
        
        If(FPC = HMAX2 - 1 And FLC = ACTIVE_SIZE(31 Downto 16) - 1) Then
            Zone_EOZ(14)    <= '1';
        Else
            Zone_EOZ(14)    <= '0';
        End If;
        
        If(FPC = ACTIVE_SIZE(15 Downto 0) - 1 And FLC  = ACTIVE_SIZE(31 Downto 16) - 1) Then
            Zone_EOZ(15)    <= '1';
        Else
            Zone_EOZ(15)    <= '0';
        End If;                                
    Else
        Zone_EOZ    <= Zone_EOZ;
    End If;    
Else
    Zone_EOZ    <= Zone_EOZ;
End If;                                             

End Process;



End Behavioral;
