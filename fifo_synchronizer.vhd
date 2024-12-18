library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity fifo_synchronizer is
    generic (
        DATA_WIDTH : positive := 12;  -- Width of data (ADC is 12-bit)
        FIFO_DEPTH : positive := 4    -- Depth of FIFO (power of 2)
    );
    port (
        -- Write domain (ADC Controller - 1 MHz) producer
        wr_clk      : in  std_logic;
        wr_rst_n    : in  std_logic;
        wr_data     : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        wr_en       : in  std_logic;
        full        : out std_logic;
        
        -- Read domain (Display Controller - 50 MHz) consumer
        rd_clk      : in  std_logic;
        rd_rst_n    : in  std_logic;
        rd_data     : out std_logic_vector(DATA_WIDTH-1 downto 0);
        rd_en       : in  std_logic;
        empty       : out std_logic
    );
end entity fifo_synchronizer;

architecture rtl of fifo_synchronizer is
    -- Calculate required address width based on FIFO depth
    constant ADDR_WIDTH : positive := positive(ceil(log2(real(FIFO_DEPTH))));
    
    -- Component declarations
    component two_stage_synchronizer is
        generic (
            WIDTH : positive
        );
        port (
            clk     : in  std_logic;
            rst_n   : in  std_logic;
            din     : in  std_logic_vector(WIDTH-1 downto 0);
            dout    : out std_logic_vector(WIDTH-1 downto 0)
        );
    end component;

    component bin_to_gray is
        generic (
            input_width : positive
        );
        port (
            bin_in  : in  std_logic_vector(input_width-1 downto 0);
            gray_out: out std_logic_vector(input_width-1 downto 0)
        );
    end component;

    component gray_to_bin is
        generic (
            input_width : positive
        );
        port (
            gray_in : in  std_logic_vector(input_width-1 downto 0);
            bin_out : out std_logic_vector(input_width-1 downto 0)
        );
    end component;

    -- Memory array for FIFO storage
    type mem_array is array (0 to FIFO_DEPTH-1) of 
        std_logic_vector(DATA_WIDTH-1 downto 0);
    signal memory : mem_array;
    
    -- Write domain signals
    signal wr_ptr_bin : unsigned(ADDR_WIDTH downto 0);
    signal wr_ptr_gray : std_logic_vector(ADDR_WIDTH downto 0);
    signal rd_ptr_gray_sync : std_logic_vector(ADDR_WIDTH downto 0);
    
    -- Read domain signals
    signal rd_ptr_bin : unsigned(ADDR_WIDTH downto 0);
    signal rd_ptr_gray : std_logic_vector(ADDR_WIDTH downto 0);
    signal wr_ptr_gray_sync : std_logic_vector(ADDR_WIDTH downto 0);
    
    -- Additional signals for converted values
    signal wr_ptr_bin_slv : std_logic_vector(ADDR_WIDTH downto 0);  -- Binary write pointer as std_logic_vector
    signal rd_ptr_bin_slv : std_logic_vector(ADDR_WIDTH downto 0);  -- Binary read pointer as std_logic_vector
    signal rd_ptr_sync_bin_slv : std_logic_vector(ADDR_WIDTH downto 0);  -- Synchronized read pointer as std_logic_vector
    signal wr_ptr_sync_bin_slv : std_logic_vector(ADDR_WIDTH downto 0);  -- Synchronized write pointer as std_logic_vector
    signal rd_ptr_sync_bin : unsigned(ADDR_WIDTH downto 0);  -- Synchronized read pointer as unsigned
    signal wr_ptr_sync_bin : unsigned(ADDR_WIDTH downto 0);  -- Synchronized write pointer as unsigned
    
    -- Internal status signals
    signal full_i  : std_logic;
    signal empty_i : std_logic;

begin
    -- Type conversion for pointers
    wr_ptr_bin_slv <= std_logic_vector(wr_ptr_bin);
    rd_ptr_bin_slv <= std_logic_vector(rd_ptr_bin);
    rd_ptr_sync_bin <= unsigned(rd_ptr_sync_bin_slv);
    wr_ptr_sync_bin <= unsigned(wr_ptr_sync_bin_slv);

    -- Connect internal status to output ports
    full <= full_i;
    empty <= empty_i;

    -- Binary to Gray converter for write pointer
    wr_bin_to_gray: bin_to_gray
        generic map (
            input_width => ADDR_WIDTH + 1
        )
        port map (
            bin_in  => wr_ptr_bin_slv,
            gray_out => wr_ptr_gray
        );
    
    -- Binary to Gray converter for read pointer
    rd_bin_to_gray: bin_to_gray
        generic map (
            input_width => ADDR_WIDTH + 1
        )
        port map (
            bin_in  => rd_ptr_bin_slv,
            gray_out => rd_ptr_gray
        );

    -- Synchronizer for write pointer (crossing to read domain)
    wr_ptr_sync: two_stage_synchronizer
        generic map (
            WIDTH => ADDR_WIDTH + 1
        )
        port map (
            clk     => rd_clk,
            rst_n   => rd_rst_n,
            din     => wr_ptr_gray,
            dout    => wr_ptr_gray_sync
        );

    -- Synchronizer for read pointer (crossing to write domain)
    rd_ptr_sync: two_stage_synchronizer
        generic map (
            WIDTH => ADDR_WIDTH + 1
        )
        port map (
            clk     => wr_clk,
            rst_n   => wr_rst_n,
            din     => rd_ptr_gray,
            dout    => rd_ptr_gray_sync
        );

    -- Gray to Binary converter for synchronized write pointer
    wr_sync_to_bin: gray_to_bin
        generic map (
            input_width => ADDR_WIDTH + 1
        )
        port map (
            gray_in => wr_ptr_gray_sync,
            bin_out => wr_ptr_sync_bin_slv
        );

    -- Gray to Binary converter for synchronized read pointer
    rd_sync_to_bin: gray_to_bin
        generic map (
            input_width => ADDR_WIDTH + 1
        )
        port map (
            gray_in => rd_ptr_gray_sync,
            bin_out => rd_ptr_sync_bin_slv
        );

    -- Write pointer update process
    write_pointer: process(wr_clk, wr_rst_n)
    begin
        if wr_rst_n = '0' then
            wr_ptr_bin <= (others => '0');
        elsif rising_edge(wr_clk) then
            if wr_en = '1' and full_i = '0' then
                wr_ptr_bin <= wr_ptr_bin + 1;
            end if;
        end if;
    end process;

    -- Read pointer update process
    read_pointer: process(rd_clk, rd_rst_n)
    begin
        if rd_rst_n = '0' then
            rd_ptr_bin <= (others => '0');
        elsif rising_edge(rd_clk) then
            if rd_en = '1' and empty_i = '0' then
                rd_ptr_bin <= rd_ptr_bin + 1;
            end if;
        end if;
    end process;

    -- Memory write process
    write_data: process(wr_clk)
    begin
        if rising_edge(wr_clk) then
            if wr_en = '1' and full_i = '0' then
                memory(to_integer(wr_ptr_bin(ADDR_WIDTH-1 downto 0))) <= wr_data;
            end if;
        end if;
    end process;

    -- Continuous read from memory
    rd_data <= memory(to_integer(rd_ptr_bin(ADDR_WIDTH-1 downto 0)));

    -- Flag generation process
    flag_generation: process(wr_ptr_bin,rd_ptr_sync_bin,rd_ptr_bin,wr_ptr_sync_bin)
    begin
        -- Full condition: write pointer + 1 = read pointer (accounting for wraparound)
        if (wr_ptr_bin(ADDR_WIDTH-1 downto 0) = rd_ptr_sync_bin(ADDR_WIDTH-1 downto 0)) and
           (wr_ptr_bin(ADDR_WIDTH) /= rd_ptr_sync_bin(ADDR_WIDTH)) then
            full_i <= '1';
        else
            full_i <= '0';
        end if;

        -- Empty condition: read pointer = write pointer
        if (rd_ptr_bin = wr_ptr_sync_bin) then
            empty_i <= '1';
        else
            empty_i <= '0';
        end if;
    end process;

end architecture rtl;