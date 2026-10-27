-- ============================================================
-- graf_secuenciador.vhd
-- Datos para la grafica de grabacion y reproduccion: se graba
-- C4 (120 ms), silencio (60 ms), E4 (100 ms), acorde C4-E4-G4
-- (180 ms) y silencio (40 ms); luego se reproduce.
-- El "ms" dura 10 ciclos. Se registra cada ms.
-- Escribe salida/secuenciador.csv:
--   t_ms;estado;eventos;posicion;vivo1;vivo2;vivo3;sal1;sal2;sal3
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use work.synth_pkg.all;

entity graf_secuenciador is
end entity graf_secuenciador;

architecture sim of graf_secuenciador is
    signal clk            : std_logic := '0';
    signal rst            : std_logic := '1';
    signal tick_1ms       : std_logic := '0';
    signal cmd_grabar     : std_logic := '0';
    signal cmd_reproducir : std_logic := '0';
    signal cmd_parar      : std_logic := '0';
    signal conjunto       : std_logic_vector(20 downto 0) := (others => '0');
    signal salida         : std_logic_vector(20 downto 0);
    signal estado         : std_logic_vector(1 downto 0);
    signal eventos        : std_logic_vector(8 downto 0);
    signal posicion       : std_logic_vector(8 downto 0);
    signal fin            : boolean := false;

    function arma (a, b, c : natural) return std_logic_vector is
    begin
        return std_logic_vector(to_unsigned(c, 7)) & std_logic_vector(to_unsigned(b, 7))
               & std_logic_vector(to_unsigned(a, 7));
    end function;

    function n (v : std_logic_vector(20 downto 0); i : natural) return natural is
    begin
        return to_integer(unsigned(v(7 * i + 6 downto 7 * i)));
    end function;
begin

    clk <= not clk after 10 ns when not fin;

    process (clk)
        variable c : natural := 0;
    begin
        if rising_edge(clk) then
            tick_1ms <= '0';
            if c = 9 then
                c := 0;
                tick_1ms <= '1';
            else
                c := c + 1;
            end if;
        end if;
    end process;

    dut : entity work.secuenciador
        port map (clk => clk, rst => rst, tick_1ms => tick_1ms, cmd_grabar => cmd_grabar,
                  cmd_reproducir => cmd_reproducir, cmd_parar => cmd_parar, conjunto => conjunto,
                  salida => salida, estado => estado, eventos => eventos, posicion => posicion,
                  llena => open);

    estimulo : process
        procedure espera_ms (k : natural) is
        begin
            for i in 1 to k loop
                wait until rising_edge(clk) and tick_1ms = '1';
            end loop;
            wait for 1 ns;
        end procedure;

        procedure pulso (signal s : out std_logic) is
        begin
            s <= '1';
            wait until rising_edge(clk);
            wait for 1 ns;
            s <= '0';
        end procedure;
    begin
        wait for 100 ns;
        rst <= '0';
        espera_ms(20);
        pulso(cmd_grabar);
        espera_ms(30);
        conjunto <= arma(48, 0, 0);
        espera_ms(120);
        conjunto <= arma(0, 0, 0);
        espera_ms(60);
        conjunto <= arma(52, 0, 0);
        espera_ms(100);
        conjunto <= arma(48, 52, 55);
        espera_ms(180);
        conjunto <= arma(0, 0, 0);
        espera_ms(40);
        pulso(cmd_parar);
        espera_ms(50);
        pulso(cmd_reproducir);
        espera_ms(600);
        fin <= true;
        wait;
    end process;

    registro : process
        file f     : text open write_mode is "salida/secuenciador.csv";
        variable l : line;
        variable t : natural := 0;
    begin
        write(l, string'("t_ms;estado;eventos;posicion;vivo1;vivo2;vivo3;sal1;sal2;sal3"));
        writeline(f, l);
        while not fin loop
            wait until rising_edge(clk) and tick_1ms = '1';
            wait for 1 ns;
            t := t + 1;
            write(l, t);
            write(l, string'(";"));
            write(l, to_integer(unsigned(estado)));
            write(l, string'(";"));
            write(l, to_integer(unsigned(eventos)));
            write(l, string'(";"));
            write(l, to_integer(unsigned(posicion)));
            for i in 0 to 2 loop
                write(l, string'(";"));
                write(l, n(conjunto, i));
            end loop;
            for i in 0 to 2 loop
                write(l, string'(";"));
                write(l, n(salida, i));
            end loop;
            writeline(f, l);
        end loop;
        report "graf_secuenciador: OK";
        wait;
    end process;

end architecture sim;
