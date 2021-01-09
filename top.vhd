----------------------------------------------------------------------------
--  top.vhd
--	MicroZed I2C Passthrough
--	Version 1.0
--
--  Copyright (C) 2019 H.Poetzl
--
--	This program is free software: you can redistribute it and/or
--	modify it under the terms of the GNU General Public License
--	as published by the Free Software Foundation, either version
--	2 of the License, or (at your option) any later version.
--
--  Vivado 2017.4:
--    mkdir -p build.vivado
--    (cd build.vivado && vivado -mode tcl -source ../vivado.tcl)
----------------------------------------------------------------------------



library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.ALL;

library unisim;
use unisim.VCOMPONENTS.ALL;

use work.vivado_pkg.ALL;	-- Vivado Attributes

use work.axi3m_pkg.ALL;
use work.axi3ml_pkg.ALL;
use work.axi3s_pkg.ALL;

entity top is
    port (
  	i2c_scl : inout std_logic;	-- icsp clock
  	i2c_sda : inout std_logic;	-- icsp data
	--
	rfe_pclk : out std_logic;
	rfw_pclk : out std_logic
    );

end entity top;


architecture RTL of top is

    signal ps_fclk : std_logic_vector (3 downto 0);
    signal ps_reset_n : std_logic_vector (3 downto 0);

    signal rfe_clk : std_logic;
    signal rfw_clk : std_logic;

    --------------------------------------------------------------------
    -- I2C Signals
    --------------------------------------------------------------------

    signal i2c_sda_i : std_logic;
    signal i2c_sda_o : std_logic;
    signal i2c_sda_t : std_logic;

    signal i2c_scl_i : std_logic;
    signal i2c_scl_o : std_logic;
    signal i2c_scl_t : std_logic;

    signal i2c1_sda_i : std_logic;
    signal i2c1_sda_o : std_logic;
    signal i2c1_sda_t : std_logic;
    signal i2c1_sda_t_n : std_logic;

    signal i2c1_scl_i : std_logic;
    signal i2c1_scl_o : std_logic;
    signal i2c1_scl_t : std_logic;
    signal i2c1_scl_t_n : std_logic;

    --------------------------------------------------------------------
    -- PS7 AXI Master Signals
    --------------------------------------------------------------------

	signal m_axi0_aclk : std_logic;
	signal m_axi0_areset_n : std_logic;

    signal m_axi0_ri : axi3m_read_in_r;
    signal m_axi0_ro : axi3m_read_out_r;
    signal m_axi0_wi : axi3m_write_in_r;
    signal m_axi0_wo : axi3m_write_out_r;

    signal m_axi0l_ri : axi3ml_read_in_r;
    signal m_axi0l_ro : axi3ml_read_out_r;
    signal m_axi0l_wi : axi3ml_write_in_r;
    signal m_axi0l_wo : axi3ml_write_out_r;

begin

    --------------------------------------------------------------------
    -- PS7 Interface
    --------------------------------------------------------------------

    ps7_stub_inst : entity work.ps7_stub
	port map (
	    ps_fclk => ps_fclk,
	    ps_reset_n => ps_reset_n,
	    --
	    i2c1_sda_i => i2c1_sda_i,
	    i2c1_sda_o => i2c1_sda_o,
	    i2c1_sda_t_n => i2c1_sda_t_n,
	    --
	    i2c1_scl_i => i2c1_scl_i,
	    i2c1_scl_o => i2c1_scl_o,
	    i2c1_scl_t_n => i2c1_scl_t_n,
		--
		--
	    m_axi0_aclk => m_axi0_aclk,
	    m_axi0_areset_n => m_axi0_areset_n,
	    --
	    m_axi0_arid => m_axi0_ro.arid,
	    m_axi0_araddr => m_axi0_ro.araddr,
	    m_axi0_arburst => m_axi0_ro.arburst,
	    m_axi0_arlen => m_axi0_ro.arlen,
	    m_axi0_arsize => m_axi0_ro.arsize,
	    m_axi0_arprot => m_axi0_ro.arprot,
	    m_axi0_arvalid => m_axi0_ro.arvalid,
	    m_axi0_arready => m_axi0_ri.arready,
	    --
	    m_axi0_rid => m_axi0_ri.rid,
	    m_axi0_rdata => m_axi0_ri.rdata,
	    m_axi0_rlast => m_axi0_ri.rlast,
	    m_axi0_rresp => m_axi0_ri.rresp,
	    m_axi0_rvalid => m_axi0_ri.rvalid,
	    m_axi0_rready => m_axi0_ro.rready,
	    --
	    m_axi0_awid => m_axi0_wo.awid,
	    m_axi0_awaddr => m_axi0_wo.awaddr,
	    m_axi0_awburst => m_axi0_wo.awburst,
	    m_axi0_awlen => m_axi0_wo.awlen,
	    m_axi0_awsize => m_axi0_wo.awsize,
	    m_axi0_awprot => m_axi0_wo.awprot,
	    m_axi0_awvalid => m_axi0_wo.awvalid,
	    m_axi0_awready => m_axi0_wi.awready,
	    --
	    m_axi0_wid => m_axi0_wo.wid,
	    m_axi0_wdata => m_axi0_wo.wdata,
	    m_axi0_wstrb => m_axi0_wo.wstrb,
	    m_axi0_wlast => m_axi0_wo.wlast,
	    m_axi0_wvalid => m_axi0_wo.wvalid,
	    m_axi0_wready => m_axi0_wi.wready,
	    --
	    m_axi0_bid => m_axi0_wi.bid,
	    m_axi0_bresp => m_axi0_wi.bresp,
	    m_axi0_bvalid => m_axi0_wi.bvalid,
		m_axi0_bready => m_axi0_wo.bready );

	axi_lite_inst : entity work.axi_lite
		port map (
			s_axi_aclk => m_axi0_aclk,
			s_axi_areset_n => m_axi0_areset_n,
			
			s_axi_ro => m_axi0_ri,
			s_axi_ri => m_axi0_ro,
			s_axi_wo => m_axi0_wi,
			s_axi_wi => m_axi0_wo,

			m_axi_ro => m_axi0l_ro,
			m_axi_ri => m_axi0l_ri,
			m_axi_wo => m_axi0l_wo,
			m_axi_wi => m_axi0l_wi );

	axi_lite_slave_inst : entity work.axi_lite_slave
		port map (
			s_axi_aclk => m_axi0_aclk,	
			s_axi_areset_n => m_axi0_areset_n,
			--
			s_axi_araddr => m_axi0_ro.araddr,
			s_axi_arprot => m_axi0_ro.arprot,
			s_axi_arvalid => m_axi0_ro.arvalid,
			s_axi_arready => m_axi0_ri.arready,
			--
			s_axi_rdata => m_axi0_ri.rdata,
			s_axi_rresp => m_axi0_ri.rresp,
			s_axi_rvalid => m_axi0_ri.rvalid,
			s_axi_rready => m_axi0_ro.rready,
			--
			s_axi_awaddr => m_axi0_wo.awaddr,
			s_axi_awprot => m_axi0_wo.awprot,
			s_axi_awvalid => m_axi0_wo.awvalid,
			s_axi_awready => m_axi0_wi.awready,
			--
			s_axi_wdata => m_axi0_wo.wdata,
			s_axi_wstrb => m_axi0_wo.wstrb,
			s_axi_wvalid => m_axi0_wo.wvalid,
			s_axi_wready => m_axi0_wi.wready,
			--
			s_axi_bresp => m_axi0_wi.bresp,
			s_axi_bvalid => m_axi0_wi.bvalid,
			s_axi_bready => m_axi0_wo.bready );

    BUFG_ce_inst : BUFG
        port map (
            I => ps_fclk(1),
            O => rfe_clk );

    ODDR_ce_inst : ODDR
	port map (
	    C => rfe_clk, Q => rfe_pclk,
	    CE => '1', R => '0', S => '0',
	    D1 => '1', D2 => '0');

    BUFG_cw_inst : BUFG
        port map (
            I => ps_fclk(2),
            O => rfw_clk );

    ODDR_cw_inst : ODDR
	port map (
	    C => rfw_clk, Q => rfw_pclk,
	    CE => '1', R => '0', S => '0',
	    D1 => '1', D2 => '0');

    --------------------------------------------------------------------
    -- I2C Interface
    --------------------------------------------------------------------

    i2c_sda_o <= i2c1_sda_o;
    i2c_sda_t <= i2c1_sda_t;

    i2c1_sda_i <= i2c_sda_i;
    i2c1_sda_t <= not i2c1_sda_t_n;

    IOBUF_sda_inst : IOBUF
	port map (
	    I => i2c_sda_o, O => i2c_sda_i,
	    T => i2c_sda_t, IO => i2c_sda );

    PULLUP_sda_inst : PULLUP
        port map ( O => i2c_sda );

    i2c_scl_o <= i2c1_scl_o;
    i2c_scl_t <= i2c1_scl_t;

    i2c1_scl_i <= i2c_scl_i;
    i2c1_scl_t <= not i2c1_scl_t_n;

    IOBUF_scl_inst : IOBUF
	port map (
	    I => i2c_scl_o, O => i2c_scl_i,
	    T => i2c_scl_t, IO => i2c_scl );

    PULLUP_scl_inst : PULLUP
        port map ( O => i2c_scl );


end RTL;
