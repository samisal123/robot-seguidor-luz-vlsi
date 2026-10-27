-- ============================================================
-- graf_metronomo.vhd
-- Datos para la grafica del metronomo a 120 BPM durante 2.1 s:
-- tiempos, acento y el clic. Una muestra cada 4 ciclos y un ms
-- cada 195 ciclos (48.75 muestras por ms, casi la relacion real
-- de 48.83). Escribe salida/metronomo.csv: n;t_ms;beat;acento;clic
-- (beat y acento valen 1 en la muestra en que llego el pulso).
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity graf_metronomo is
end entity graf_metronomo;

architecture sim of graf_metronomo is
    signal clk      : std_logic := '0';
    signal rst      : std_logic := '1';
    signal tick_fs  : std_logic := '0';
    signal tick_1ms : std_logic := '0';
    signal beat     : std_logic;
    signal acento   : std_logic;
    signal clic     : std_logic_vector(7 downto 0);
    signal b_lat, a_lat : std_logic := '0';
    signal b_acc, a_acc : std_logic := '0';
    signal t_ms     : natural := 0;
    signal fin      : boolean := false;
begin

    clk <= not clk after 10 ns when not fin;

    process (clk)
        variable c4, cms : natural := 0;
    begin
        if rising_edge(clk) then
            tick_fs  <= '0';
            tick_1ms <= '0';
            if c4 = 3 then
                c4 := 0;
                tick_fs <= '1';
            else
                c4 := c4 + 1;
            end if;
            if cms = 194 then
                cms := 0;
                tick_1ms <= '1';
                t_ms <= t_ms + 1;
            else
                cms := cms + 1;
            end if;
        end if;
    end process;

    dut : entity work.metronomo
        port map (clk => clk, rst => rst, tick_fs => tick_fs, tick_1ms => tick_1ms,
                  metro_on => '1', tempo => "10", beat => beat, acento => acento, clic => clic);

    -- junta los pulsos de beat y acento de cada periodo de muestra
    process (clk)
    begin
        if rising_edge(clk) then
            if tick_fs = '1' then
                b_lat <= b_acc or beat;
                a_lat <= a_acc or acento;
                b_acc <= '0';
                a_acc <= '0';
            else
                if beat = '1' then
                    b_acc <= '1';
                end if;
                if acento = '1' then
                    a_acc <= '1';
                end if;
            end if;
        end if;
    end process;

    process
        file f     : text open write_mode is "salida/metronomo.csv";
        variable l : line;
        variable n : natural := 0;
    begin
        write(l, string'("n;t_ms;beat;acento;clic"));
        writeline(f, l);
        wait for 100 ns;
        rst <= '0';
        while t_ms < 2100 loop
            wait until rising_edge(clk) and tick_fs = '1';
            wait for 1 ns;
            n := n + 1;
            write(l, n);
            write(l, string'(";"));
            write(l, t_ms);
            write(l, string'(";"));
            write(l, std_logic'image(b_lat));
            write(l, string'(";"));
            write(l, std_logic'image(a_lat));
            write(l, string'(";"));
            write(l, to_integer(signed(clic)));
            writeline(f, l);
        end loop;
        report "graf_metronomo: OK";
        fin <= true;
        wait;
    end process;

end architecture sim;
