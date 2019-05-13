----------------------------------------------------------------------------------
-- Company:             IIT, Madras
-- Engineer:            Urvish Markad
-- 
-- Create Date:         
-- Design Name:         Min_Max Module for Image Statistics IP Core
-- Module Name:         Min_Max - Behavioral
-- Project Name:        
-- Target Devices:      ZC702 Evaluation Board
-- Tool Versions:       Vivado 2018.1
-- Description:         
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision              0.01 - File Created
-- Additional Comments:     
-- 
----------------------------------------------------------------------------------
Library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
Package Nested_Data_Type is 
TYPE SLV24_Vector16   IS ARRAY (0 TO 15) OF Std_Logic_Vector(23 Downto 0);
TYPE SLV8_Vector16    IS ARRAY (0 TO 15) OF Std_Logic_Vector(7 Downto 0); 
TYPE SLV0_Vector48    IS ARRAY (0 TO 47) OF Std_Logic;
TYPE SLV0_Vector16    IS ARRAY (0 TO 15) OF Std_Logic;
End Package Nested_Data_Type;


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

Library Work;
use Work.Nested_Data_Type.ALL;


Entity Min_Max is
  Port ( 
        aclk                                     :   In  Std_Logic;
        aclken                                   :   In  Std_Logic;
        gresetn                                  :   In  Std_Logic;
        
        zone_tvalid                              :   In  SLV0_Vector16;
        zone_tsoz                                :   In  SLV0_Vector16;
        zone_teoz                                :   In  SLV0_Vector16;
        
        s_axis_video_tdata                       :   In  Std_Logic_Vector(23 Downto 0);
        s_axis_video_tvalid                      :   In  Std_Logic;
        
        zone_min_tdata                           :   Out SLV24_Vector16;
        zone_min_tvalid                          :   Out SLV0_Vector16;
        
        zone_max_tdata                           :   Out SLV24_Vector16;
        zone_max_tvalid                          :   Out SLV0_Vector16                     
);
End Min_Max;

Architecture Behavioral of Min_Max is

Signal              Clk                                         :   Std_Logic;                                             
                           

Signal              Red                                         :   Std_Logic_Vector(7 Downto 0);
Signal              Green                                       :   Std_Logic_Vector(7 Downto 0);
Signal              Blue                                        :   Std_Logic_Vector(7 Downto 0);



Signal              Zone_ON                                     :   SLV0_Vector16;

Signal              Mux_Out_Red                                 :   SLV8_Vector16;
Signal              Min_Out_Red                                 :   SLV8_Vector16; 

Signal              Mux_Out_Green                               :   SLV8_Vector16;
Signal              Min_Out_Green                               :   SLV8_Vector16;

Signal              Mux_Out_Blue                                :   SLV8_Vector16;
Signal              Min_Out_Blue                                :   SLV8_Vector16;  

Signal              Zone_Red                                    :   SLV8_Vector16;
Signal              Zone_Green                                  :   SLV8_Vector16;
Signal              Zone_Blue                                   :   SLV8_Vector16;    

Signal              Mux2_Out_Red                                :   SLV8_Vector16;
Signal              Mux2_Out_Green                              :   SLV8_Vector16;
Signal              Mux2_Out_Blue                               :   SLV8_Vector16;

Signal              Max_Out_Red                                 :   SLV8_Vector16;
Signal              Max_Out_Green                               :   SLV8_Vector16;
Signal              Max_Out_Blue                                :   SLV8_Vector16; 

Signal              Zone_Min_Mdata                              :   SLV24_Vector16;             --Modular Zonal Min Ouputs
Signal              Zone_Min_Mvalid                             :   SLV0_Vector16;              --Modular Zonal Min Output Valid 

Signal              Zone_Max_Mdata                              :   SLV24_Vector16;             --Modular Zonal Max Output
Signal              Zone_Max_Mvalid                             :   SLV0_Vector16;              --Modular Zonal Max Output Valid

Begin

Clk     <= Aclk And Aclken;

Red     <= S_Axis_Video_Tdata(23 Downto 16);
Blue    <= S_Axis_Video_Tdata(15 Downto 08);
Green   <= S_Axis_Video_Tdata(07 Downto 00);


MinMaxAssign: For I in 0 to 15 Generate
Zone_Min_Tdata(I)  <= (Others=>'0') When Gresetn = '0' Else Zone_Min_Mdata(I);
Zone_Min_Tvalid(I) <= '0'           When Gresetn = '0' Else Zone_Min_Mvalid(I);

Zone_Max_Tdata(I)  <= (Others=>'0') When Gresetn = '0' Else Zone_Max_Mdata(I);
Zone_Max_Tvalid(I) <= '0'           When Gresetn = '0' Else Zone_Max_Mvalid(I);
End Generate;

ZonalRGB: Process(Clk, Gresetn)
Begin
If(Gresetn = '0') Then
    For I IN 0 TO 15 Loop
        Zone_Red(I)   <= (Others=>'0');
        Zone_Green(I) <= (Others=>'0');
        Zone_Blue(I)  <= (Others=>'0');
    End Loop;
Elsif(Rising_Edge(Clk)) Then
    For I In 0 TO 15 Loop
        If(Zone_Tvalid(I) = '1') Then
            Zone_Red(I)     <= Red;
            Zone_Green(I)   <= Green;
            Zone_Blue(I)    <= Blue;
        Else
            Zone_Red(I)     <= Zone_Red(I);
            Zone_Green(I)   <= Zone_Green(I);
            Zone_Blue(I)    <= Zone_Blue(I);
        End If;        
    End Loop;                  
End If;
End Process;

ZoneOnLatchGen: Process(Clk, Gresetn)
Begin
If(Gresetn = '0') Then
    For I in 0 to 15 Loop
    Zone_ON(I)  <= '0';
    End Loop;
Elsif(Rising_Edge(Clk)) Then
    For I in 0 to 15 Loop
        If(Zone_Tsoz(I) = '1') Then
            Zone_ON(I)  <= '1';                         --Switch ON when SOZ = '1' is received
        Elsif(Zone_Teoz(I) = '1') Then
            Zone_ON(I)  <= '0';                         --Switch OFF when EOZ = '1' is received
        Else
            Zone_ON     <= Zone_ON;
        End If;                        
    End Loop;                 
Else
    Zone_ON <= Zone_ON;
End If;    
End Process;


         
RedMinComp: For I in 0 to 15 Generate
    Mux_Out_Red(I) <= X"FF"          When Zone_Tsoz(I) = '1'                Else Min_Out_Red(I);
    
    Min_Out_Red(I) <= X"FF"          When Gresetn = '0'                     Else
                      Mux_Out_Red(I) When (Zone_Red(I) > Mux_Out_Red(I))    Else
                      Zone_Red(I);                   
End Generate; 

GreenMinComp: For I in 0 to 15 Generate
    Mux_Out_Green(I) <= X"FF"          When Zone_Tsoz(I) = '1'                    Else Min_Out_Green(I);
    
    Min_Out_Green(I) <= X"FF"          When Gresetn = '0'                         Else
                      Mux_Out_Green(I) When (Zone_Green(I) > Mux_Out_Green(I))    Else
                      Zone_Green(I);                   
End Generate; 


BlueMinComp: For I in 0 to 15 Generate
    Mux_Out_Blue(I) <= X"FF"          When Zone_Tsoz(I) = '1'                      Else Min_Out_Blue(I);
    
    Min_Out_Blue(I) <= X"FF"          When Gresetn = '0'                           Else
                      Mux_Out_Blue(I)  When (Zone_Blue(I) > Mux_Out_Blue(I))       Else
                      Zone_Blue(I);                   
End Generate; 






RedMaxComp: For I in 0 to 15 Generate
    Mux2_Out_Red(I)    <= X"00"                    When Zone_Tsoz(I) = '1'               Else Max_Out_Red(I);
    
    Max_Out_Red(I)     <= X"00"                    When Gresetn = '0'                    Else
                          Mux2_Out_Red(I)          When (Zone_Red(I) < Mux2_Out_Red(I))  Else
                          Zone_Red(I);

End Generate;


GreenMaxComp: For I in 0 to 15 Generate
    Mux2_Out_Green(I)    <= X"00"                    When Zone_Tsoz(I) = '1'                   Else Max_Out_Green(I);
    
    Max_Out_Green(I)     <= X"00"                    When Gresetn = '0'                        Else
                            Mux2_Out_Green(I)        When (Zone_Green(I) < Mux2_Out_Green(I))  Else
                            Zone_Green(I);

End Generate;


BlueMaxComp: For I in 0 to 15 Generate
    Mux2_Out_Blue(I)    <= X"00"                     When Zone_Tsoz(I) = '1'                   Else Max_Out_Blue(I);
    
    Max_Out_Blue(I)     <= X"00"                     When Gresetn = '0'                        Else
                           Mux2_Out_Blue(I)          When (Zone_Blue(I) < Mux2_Out_Blue(I))    Else
                           Zone_Blue(I);

End Generate;




RGBMinAssign: Process(Clk, Gresetn)
Begin
If(Gresetn = '0') Then
   For I in 0 TO 15 Loop
    Zone_Min_Mdata(I)  <= (Others=>'0');
    Zone_Min_Mvalid(I) <= '0';
   End Loop; 
Elsif(Rising_Edge(Clk)) Then
    For I in 0 to 15 Loop
        If((S_Axis_Video_Tvalid And Zone_ON(I)) = '1') Then
            If(Zone_Teoz(I) = '1') Then
                Zone_Min_Mdata(I)  <= Min_Out_Red(I) & Min_Out_Blue(I) & Min_Out_Green(I);              --Latch the Results on EOZ = '1'
                Zone_Min_Mvalid(I) <= '1';    
            Else
                Zone_Min_Mdata(I)   <= Zone_Min_Mdata(I);
                Zone_Min_Mvalid(I)  <= Zone_Min_Mvalid(I);
            End If;
        Elsif(Zone_Teoz(15) = '1') Then                                                                 --Show Valid = '0' Flag On EOF i.e. Zone_Teoz(15) = '1'
            Zone_Min_Mdata(I)       <= Zone_Min_Mdata(I);
            Zone_Min_Mvalid(I)      <= '0'; 
                   
            
        Else
            Zone_Min_Mdata(I)       <= Zone_Min_Mdata(I);
            Zone_Min_Mvalid(I)      <= Zone_Min_Mvalid(I);
        End If;
                               
    End Loop; 
End If;
End Process;


RGBMaxAssign: Process(Clk, Gresetn)
Begin
If(Gresetn = '0') Then
    For I in 0 TO 15 Loop
        Zone_Max_Mdata(I)   <= (Others=>'0');
        Zone_Max_Mvalid(I)  <= '0';    
    End Loop;
Elsif(Rising_Edge(Clk)) Then
    For I in 0 TO 15 Loop
        If((S_Axis_Video_Tvalid And Zone_ON(I)) = '1') Then
            If(Zone_Teoz(I) = '1') Then
                Zone_Max_Mdata(I)  <= Max_Out_Red(I) & Max_Out_Blue(I) & Max_Out_Green(I);          --Latch the Results on EOZ = '1'
                Zone_Max_Mvalid(I) <= '1';
            Else
                Zone_Max_Mdata(I)   <= Zone_Max_Mdata(I);
                Zone_Max_Mvalid(I)  <= Zone_Max_Mvalid(I);
            End If;
         Else
            Zone_Max_Mdata(I)    <= Zone_Max_Mdata(I);
            Zone_Max_Mvalid(I)   <= Zone_Max_Mvalid(I);
         End If;                       
    End Loop;   
End If;     
End Process;



End Behavioral;
