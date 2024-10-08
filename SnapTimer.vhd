-- SnapTimer.vhd
-- Created 2023
--
-- This SCOMP peripheral takes in configuration in form of a 16 bit value
-- When all bits are 0, the peripheral resets internal counts and starts listening
-- When first bit is 1, the rest 15 bits are used as unsigned positive number to configure minimum time between snaps
-- (time is measured in number of cycles, driven by CLK signal)
-- When first bit is 0, the rest 15 bits are used as unsigned positive number to configure minimum volume of snaps
-- (refer to ADC interface for volume)


library IEEE;
library lpm;

use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;
use lpm.lpm_components.all;

entity SnapTimer is
port(
    CS          : in  std_logic;
    IO_WRITE    : in  std_logic;
    SYS_CLK     : in  std_logic;  -- SCOMP's clock
    RESETN      : in  std_logic;
    AUD_DATA    : in  std_logic_vector(15 downto 0);
    AUD_NEW     : in  std_logic;
    IO_DATA     : inout  std_logic_vector(15 downto 0);
	 CLK			 : in  std_logic
);
end SnapTimer;

architecture a of SnapTimer is

    signal out_en      : std_logic;
    signal parsed_data : std_logic_vector(15 downto 0);
    signal output_data : std_logic_vector(15 downto 0);
	 
	 -- config
	 signal v_min		  : std_logic_vector(15 downto 0);
	 signal t_min       : std_logic_vector(15 downto 0);
	 
	 -- controls
	 signal combined_reset: boolean;
	 signal key         : std_logic_vector(15 downto 0);
	 signal skey        : std_logic_vector(15 downto 0);
	 
	 -- running related
	 signal v_net       : std_logic_vector(15 downto 0);
	 signal t_net       : std_logic_vector(15 downto 0);
	 -- number of signals processed by the fast clocked "state machine" (the READ portion)
	 signal sig_count   : std_logic_vector(15 downto 0);
	 -- number of signals processed by SCOMP through an 'IN Sound' operation
	 signal sig_rcount  : std_logic_vector(15 downto 0);
	 -- number of signals processed by the slow state machine (the MAIN portion)
	 signal sig_scount  : std_logic_vector(15 downto 0);
	 signal timer       : std_logic_vector(15 downto 0);
	 

begin

    -- OUTPUT
    process (RESETN, CS) begin
	     if resetn = '0' then
				sig_rcount <= x"0000";
        elsif rising_edge(CS) then
				if sig_rcount = sig_scount then
				    output_data <= '0' & timer(14 downto 0);
			   else
				    output_data <= '1' & timer(14 downto 0);
					 sig_rcount <= sig_scount;
			   end if;
        end if;
    end process;
	 
    -- Drive IO_DATA when needed.
    out_en <= CS AND ( NOT IO_WRITE );
    with out_en select IO_DATA <=
        output_data        when '1',
        "ZZZZZZZZZZZZZZZZ" when others;
		  
    combined_reset <= (RESETN = '0') or (key /= skey);
		  
	 -- CONFIG & CONTROLS
	 PROCESS (RESETN, CS)
	 BEGIN
        IF (RESETN = '0') THEN
            key <= x"0000";
            t_min <= "0111111111111111";
            v_min <= "0111111111111111";
		  ELSIF (RISING_EDGE(CS)) THEN
            IF io_write = '1' THEN
				if IO_DATA = x"0000" then
				    key <= key + 1;
				elsif IO_DATA(15) = '1' THEN
					 t_min <= '0' & IO_DATA(14 downto 0);
				else
                v_min <= '0' & IO_DATA(14 downto 0);
				end if;
			END IF;
		END IF;
	 END PROCESS;

    -- READ
    process (combined_reset, SYS_CLK)
    begin
        if combined_reset then
				sig_count <= x"0000";
            parsed_data <= x"0000";
        elsif rising_edge(AUD_NEW) then
            parsed_data <= AUD_DATA;
				if (v_net(15) = '0') and (t_net(15) = '0') then
				    sig_count <= sig_scount + 1;
				end if;
        end if;
    end process;
	 
	 -- DETECTION
	 v_net <= AUD_DATA - v_min;
	 t_net <= timer - t_min;
	 
	 -- MAIN state machine
	 PROCESS (combined_reset, CLK)
	 BEGIN
        if combined_reset then
		      skey <= key;
				sig_scount <= x"0000";
				timer <= x"0000";
        elsif RISING_EDGE(CLK) then
		      -- state machine is up to date with the fast clock
		      if sig_count = sig_scount then
				    if timer /= "0111111111111111" then
					     timer <= timer + 1;
					 end if;
			   else
				    -- one or few snaps came from the fast clock, and are not processed yet by the slow clock
				    sig_scount <= sig_count;
					 timer <= x"0000";
				end if;
		  end if;
	 END PROCESS;

end a;