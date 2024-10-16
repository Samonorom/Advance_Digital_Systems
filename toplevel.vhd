 
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

entity toplevel is
    generic (
        clock_freq  : integer := 50_000_000;  -- 50 MHz
        probe_delay : integer := 1_000_000;    -- 1 sec
        ro_length   : integer := 13;
        ro_count    : integer := 16 
    );
    port (
        reset : in  std_logic;
        clock : in  std_logic;
        done  : out std_logic;
        puf_response_out  : out std_logic
		  
    );
end toplevel;

architecture Behavioral of toplevel is
    component ro_puf is
		  generic (ro_length : integer; ro_count : integer ); 
        port ( 
				clock    : in  std_logic;
            reset    : in  std_logic;
            enable   : in  std_logic;
            challenge: in  std_logic_vector(2*(integer(ceil(log2(real(ro_count))))-1) - 1 downto 0);
            response : out std_logic
        );
    end component;
 
    constant challenge_width : integer := 2*(integer(ceil(log2(real(ro_count))))-1);
    constant delay_cycles    : integer := clock_freq / 1_000_000 * probe_delay;
    
    signal puf_reset    : std_logic;
    signal puf_enable   : std_logic;
    signal puf_challenge: std_logic_vector(challenge_width - 1 downto 0);
    signal puf_response : std_logic;
    
    type state_type is (IDLE, RESET_PUF, SET_CHALLENGE, WAIT_PROBE, STORE_RESPONSE, DONE_STATE);
    signal state : state_type;
    
    signal challenge_counter : unsigned( challenge_width - 1 downto 0);
    signal delay_counter     : integer range 0 to delay_cycles;
    
    type ram_type is array (0 to 2**challenge_width - 1) of std_logic;
    signal ram : ram_type := (others => '1');
begin
    -- Instantiate RO-PUF
    puf: ro_puf
        generic map (ro_length => ro_length, ro_count => ro_count  )  
        port map ( 
            clock     => clock,
            reset     => puf_reset,
            enable    => puf_enable,
            challenge => puf_challenge,
            response  => puf_response
        );

    -- Control process
	 -- FSM 
    process(reset, clock)
    begin
        if reset = '0' then
            state <= IDLE;
            done <= '0';
            challenge_counter <= (others => '0');
            delay_counter <= 0;
            puf_reset <= '0';
            puf_enable <= '0';
				puf_response_out <= '0';
        elsif rising_edge(clock) then
            case state is
                when IDLE =>
                    state <= RESET_PUF;
                    
                when RESET_PUF =>
                    puf_reset <= '0';
                    state <= SET_CHALLENGE;
                    
                when SET_CHALLENGE =>
                    puf_reset <= '1';
                    puf_challenge <= std_logic_vector(challenge_counter);
                    puf_enable <= '1';
                    state <= WAIT_PROBE;
                    
                when WAIT_PROBE =>
                    if delay_counter = delay_cycles then
                        puf_enable <= '0';
                        state <= STORE_RESPONSE;
                        delay_counter <= 0;
                    else
                        delay_counter <= delay_counter + 1;
                    end if;
                    
                when STORE_RESPONSE =>
                    ram(to_integer(challenge_counter)) <= puf_response;
                    puf_response_out <= puf_response; 
                    if challenge_counter = 2**challenge_width - 1 then
                        state <= DONE_STATE;
                    else
                        challenge_counter <= challenge_counter + 1;
                        state <= RESET_PUF;
                    end if;
                    
                when DONE_STATE =>
                    done <= '1';
            end case;
        end if;
    end process;
end Behavioral;


