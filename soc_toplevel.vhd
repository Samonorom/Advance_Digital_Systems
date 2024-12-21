library ieee;
use ieee.std_logic_1164.all;

entity soc_toplevel is
    port (
        clock                           : in    std_logic;                      -- Clock input
        hps_io_hps_io_emac1_inst_TX_CLK : out   std_logic;                      -- hps_io_emac1_inst_TX_CLK
        hps_io_hps_io_emac1_inst_TXD0   : out   std_logic;                      -- hps_io_emac1_inst_TXD0
        hps_io_hps_io_emac1_inst_TXD1   : out   std_logic;                      -- hps_io_emac1_inst_TXD1
        hps_io_hps_io_emac1_inst_TXD2   : out   std_logic;                      -- hps_io_emac1_inst_TXD2
        hps_io_hps_io_emac1_inst_TXD3   : out   std_logic;                      -- hps_io_emac1_inst_TXD3
        hps_io_hps_io_emac1_inst_RXD0   : in    std_logic;                      -- hps_io_emac1_inst_RXD0
        memory_mem_a                    : out   std_logic_vector(14 downto 0);  -- Memory interface
        memory_mem_ba                   : out   std_logic_vector(2 downto 0);
        memory_mem_ck                   : out   std_logic;
        memory_mem_ck_n                 : out   std_logic;
        memory_mem_cke                  : out   std_logic;
        memory_mem_cs_n                 : out   std_logic;
        memory_mem_ras_n                : out   std_logic;
        memory_mem_cas_n                : out   std_logic;
        memory_mem_we_n                 : out   std_logic;
        memory_mem_reset_n              : out   std_logic;
        memory_mem_dq                   : inout std_logic_vector(31 downto 0);
        memory_mem_dqs                  : inout std_logic_vector(3 downto 0);
        memory_mem_dqs_n                : inout std_logic_vector(3 downto 0);
        memory_mem_odt                  : out   std_logic;
        memory_mem_dm                   : out   std_logic_vector(3 downto 0);
        memory_oct_rzqin                : in    std_logic;                      -- OCT RZQ input
        digits_export                   : out   std_logic_vector(41 downto 0)   -- Digits output
    );
end entity soc_toplevel;

architecture rtl of soc_toplevel is

    -- Component Declaration
    component seven_segment_agent
        port (
            lamp_mode_common_anode  : in    boolean; -- Lamp mode (boolean)
            decimal_support         : in    boolean; -- Decimal support (boolean)
            signed_support          : in    boolean; -- Signed number support (boolean)
            blank_zeros_support     : in    boolean; -- Blank leading zeros (boolean)
            digits_export           : out   std_logic_vector(41 downto 0) -- Digits output
        );
    end component;

begin
    -- Instantiate seven_segment_agent
    u_seven_segment_agent: seven_segment_agent
        port map (
            lamp_mode_common_anode  => true,  -- Corrected to boolean type
            decimal_support         => true,  -- Corrected to boolean type
            signed_support          => true,  -- Corrected to boolean type
            blank_zeros_support     => false, -- Corrected to boolean type
            digits_export           => digits_export
        );

end architecture rtl;

