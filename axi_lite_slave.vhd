library IEEE;
use IEEE.std_logic_1164.ALL;
use iEEE.numeric_std.ALL;

entity axi_lite_slave is
    generic (
        C_S_AXI_DATA_WIDTH : natural := 32;
        C_S_AXI_ADDR_WIDTH : natural := 32
    );
    port (
        s_axi_aclk      : in std_logic;
        s_axi_areset_n  : in std_logic;

        s_axi_awaddr    : in std_logic_vector
            (C_S_AXI_ADDR_WIDTH-1 downto 0); 
        s_axi_awprot    : in std_logic_vector (2 downto 0);
        s_axi_awvalid   : in std_logic;
        s_axi_awready   : out std_logic;
        s_axi_wdata     : in std_logic_vector
            (C_S_AXI_DATA_WIDTH-1 downto 0);
        s_axi_wstrb     : in std_logic_vector
            ((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
        s_axi_wvalid    : in std_logic;
        s_axi_wready    : out std_logic;
        s_axi_bresp     : out std_logic_vector (1 downto 0);
        s_axi_bvalid    : out std_logic;
        s_axi_bready    : in std_logic;

        s_axi_araddr    : in std_logic_vector
            (C_S_AXI_ADDR_WIDTH-1 downto 0);
        s_axi_arprot    : in std_logic_vector (2 downto 0);
        s_axi_arvalid   : in std_logic;
        s_axi_arready   : out std_logic;
        s_axi_rdata     : out std_logic_vector
            (C_S_AXI_DATA_WIDTH-1 downto 0);
        s_axi_rresp     : out std_logic_vector (1 downto 0);
        s_axi_rvalid    : out std_logic;
        s_axi_rready    : in std_logic
    );
end entity axi_lite_slave;

architecture RTL of axi_lite_slave is
    signal axi_awready  : std_logic := '1';
    signal axi_wready   : std_logic := '1';
    signal axi_bvalid   : std_logic := '0';
    signal axi_arready  : std_logic := '0';
    signal axi_rvalid   : std_logic := '0';
    signal axi_rdata : std_logic_vector (C_S_AXI_DATA_WIDTH-1 downto 0);

    constant ADDR_LSB : natural := 2;
    constant AW : natural := C_S_AXI_ADDR_WIDTH-2;
    constant DW : natural := C_S_AXI_DATA_WIDTH;

    -- User registers
    type reg_file is array (0 to 63) of std_logic_vector (DW-1 downto 0);
    signal slv_mem : reg_file;

    -- Buffers for read process
    signal pre_raddr : std_logic_vector
        (C_S_AXI_ADDR_WIDTH-1 downto 0);
    signal rd_addr  : std_logic_vector
        (C_S_AXI_ADDR_WIDTH-1 downto 0);

    -- Buffers for write process
    signal pre_waddr : std_logic_vector
        (C_S_AXI_ADDR_WIDTH-1 downto 0);
    signal waddr : std_logic_vector
        (C_S_AXI_ADDR_WIDTH-1 downto 0);

    signal pre_wdata : std_logic_vector
        (C_S_AXI_DATA_WIDTH-1 downto 0);
    signal wdata : std_logic_vector
        (C_S_AXI_DATA_WIDTH-1 downto 0);

    signal pre_wstrb : std_logic_vector
        ((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
    signal wstrb : std_logic_vector
        ((C_S_AXI_DATA_WIDTH/8)-1 downto 0);

    -- Some useful indicators
    signal valid_read_request   : std_logic;
    signal read_response_stall  : std_logic;

    signal valid_write_address  : std_logic;
    signal valid_write_data     : std_logic;
    signal write_response_stall : std_logic;

begin
    s_axi_awready   <= axi_awready;
    s_axi_wready    <= axi_wready;
    s_axi_bresp <= "00";    -- OKAY response
    s_axi_bvalid    <= axi_bvalid;
    s_axi_arready   <= axi_arready;
    s_axi_rdata <= axi_rdata;
    s_axi_rresp <= "00";    -- OKAY response
    s_axi_rvalid    <= axi_rvalid;

    valid_read_request   <= s_axi_arvalid or not axi_arready;
    read_response_stall  <= axi_rvalid and not s_axi_rready;

    valid_write_address  <= s_axi_awvalid or not axi_awready;
    valid_write_data     <= s_axi_wvalid or not axi_wready;
    write_response_stall <= axi_bvalid and not s_axi_bready;

    ---- Read Processing ----

    process (s_axi_aclk) is
    begin
        if rising_edge(s_axi_aclk) then
            -- The read response channel valid signal
            if s_axi_areset_n = '0' then
                axi_rvalid <= '0';
            elsif read_response_stall = '1' then
                axi_rvalid <= '1';
            elsif valid_read_request = '1' then
                axi_rvalid <= '1';
            else
                axi_rvalid <= '0';
            end if;
        end if;
    end process;

    process (s_axi_aclk) is
    begin
        if rising_edge(s_axi_aclk) then
            -- Buffer the address
            if axi_arready = '1' then
                pre_raddr <= s_axi_araddr;
            end if;
        end if;
    end process;

    process (s_axi_aclk) is
    begin
        if rising_edge(s_axi_aclk) then
            -- Read the data
            if read_response_stall = '0'
            and valid_read_request = '1' then
                axi_rdata <= slv_mem(to_integer(unsigned(rd_addr(AW+ADDR_LSB-1 downto ADDR_LSB))));
            end if;
        end if;
    end process;

    process (s_axi_aclk) is
    begin
        if rising_edge(s_axi_aclk) then
            -- The read address channel ready signal
            if s_axi_areset_n = '0' then
                axi_arready <= '1';
            elsif read_response_stall = '1' then
                axi_arready <= not valid_read_request;
            else
                axi_arready <= '1';
            end if;
        end if;
    end process;
    
    rd_addr <= pre_raddr when axi_arready = '0' else s_axi_araddr;

    ---- Write Processing ----

    process (s_axi_aclk) is
    begin
        if rising_edge(s_axi_aclk) then
            -- The write address channel ready signal
            if s_axi_areset_n = '0' then
                axi_awready <= '1';
            elsif write_response_stall = '1' then
                axi_awready <= not valid_write_address;
            elsif valid_write_data = '1' then
                axi_awready <= '1';
            else
                axi_awready <= axi_awready and not s_axi_awvalid; 
            end if;
        end if;
    end process;

    process (s_axi_aclk) is
    begin
        if rising_edge(s_axi_aclk) then
            -- The write data channel ready signal
            if s_axi_areset_n = '0' then
                axi_wready <= '1';
            elsif write_response_stall = '1' then
                axi_wready <= not valid_write_data;
            elsif valid_write_address = '1' then
                axi_wready <= '1';
            else
                axi_wready <= axi_wready and not s_axi_wvalid;
            end if;
        end if;
    end process;

    process (s_axi_aclk) is
    begin
        if rising_edge(s_axi_aclk) then
            -- Buffer the address
            if axi_awready = '1' then
                pre_waddr <= s_axi_awaddr;
            end if;
        end if;
    end process;

    process (s_axi_aclk) is
    begin
        if rising_edge(s_axi_aclk) then
            -- Buffer the data
            if axi_wready = '1' then
                pre_wdata <= s_axi_wdata;
                pre_wstrb <= s_axi_wstrb;
            end if;
        end if;
    end process;

    process (s_axi_aclk) is
    begin
        if rising_edge(s_axi_aclk) then
            -- Actually write the data
            if write_response_stall = '0'
            and valid_write_address = '1'
            and valid_write_data = '1' then
                if wstrb(0) = '1' then
                    slv_mem(to_integer(unsigned(waddr(AW+ADDR_LSB-1 downto ADDR_LSB))))
                        (7 downto 0) <= wdata(7 downto 0);
                end if;
                if wstrb(1) = '1' then
                    slv_mem(to_integer(unsigned(waddr(AW+ADDR_LSB-1 downto ADDR_LSB))))
                        (15 downto 8) <= wdata(15 downto 8);
                end if;
                if wstrb(2) = '1' then
                    slv_mem(to_integer(unsigned(waddr(AW+ADDR_LSB-1 downto ADDR_LSB))))
                        (23 downto 16) <= wdata(23 downto 16);
                end if;
                if wstrb(3) = '1' then
                    slv_mem(to_integer(unsigned(waddr(AW+ADDR_LSB-1 downto ADDR_LSB))))
                        (31 downto 24) <= wdata(31 downto 24);
                end if;
            end if;
        end if;
    end process;

    process (s_axi_aclk) is
    begin
        if rising_edge(s_axi_aclk) then
            -- The write response channel valid signal
            if s_axi_areset_n = '0' then
                axi_bvalid <= '0';
            elsif valid_write_address = '1'
            and valid_write_data = '1' then
                axi_bvalid <= '1';
            elsif s_axi_bready = '1' then
                axi_bvalid <= '0';
            end if;
        end if; 
    end process;

    -- Read write address from buffer
    waddr <= pre_waddr when axi_awready = '0' else s_axi_awaddr;

    -- Read write data from buffer
    wstrb <= pre_wstrb when axi_wready = '0' else s_axi_wstrb;
    wdata <= pre_wdata when axi_wready = '0' else s_axi_wdata;

end architecture RTL;
