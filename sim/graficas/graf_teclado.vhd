-- ============================================================
-- graf_teclado.vhd
-- Datos para la grafica del barrido y el antirrebote: la tecla
-- "6" del teclado 1 (fila 2, columna 3) rebota 6 ms al
-- presionarla, se mantiene y rebota 5 ms al soltarla.
-- El "ms" dura 20 ciclos. Se registra cada ciclo.
-- Escribe salida/teclado.csv: t_ms;fila;col3_crudo;tecla_filtrada
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity graf_teclado is
end entity graf_teclado;

architecture sim of graf_teclado is
    constant CIC_MS : natural := 20;   -- ciclos por ms

    signal clk      : std_logic := '0';
    signal rst      : std_logic := '1';
    signal tick_1ms : std_logic := '0';
    signal filas    : std_logic_vector(3 downto 0);
    signal col1     : std_logic_vector(3 downto 0);
    signal teclas   : std_logic_vector(31 downto 0);
    signal pres     : std_logic_vector(15 downto 0) := (others => '0');
    signal ciclo    : natural := 0;
    signal fin      : boolean := false;
begin

    clk <= not clk after 10 ns when not fin;

    process (clk)
    begin
        if rising_edge(clk) then
            ciclo <= ciclo + 1;
            if (ciclo + 1) mod CIC_MS = 0 then
                tick_1ms <= '1';
            else
                tick_1ms <= '0';
            end if;
        end if;
    end process;

    teclado : entity work.modelo_teclado
        port map (filas => filas, cols => col1, presion => pres);

    dut : entity work.teclado_scan
        port map (clk => clk, rst => rst, tick_1ms => tick_1ms, filas => filas,
                  col1 => col1, col2 => "1111", teclas => teclas);

    -- tecla con rebotes (tiempos en ms)
    process
        procedure espera (n : real) is
        begin
            wait for n * real(CIC_MS) * 20 ns;
        end procedure;
    begin
        rst <= '0';
        espera(10.0);
        for i in 1 to 4 loop
            pres(6) <= '1';
            espera(0.7);
            pres(6) <= '0';
            espera(0.8);
        end loop;
        pres(6) <= '1';
        espera(50.0);
        for i in 1 to 3 loop
            pres(6) <= '0';
            espera(0.9);
            pres(6) <= '1';
            espera(0.8);
        end loop;
        pres(6) <= '0';
        wait;
    end process;

    process
        file f     : text open write_mode is "salida/teclado.csv";
        variable l : line;
        variable fila : integer;
    begin
        write(l, string'("t_ms;fila;col3_crudo;tecla_filtrada"));
        writeline(f, l);
        for c in 0 to 100 * CIC_MS loop
            wait until rising_edge(clk);
            wait for 1 ns;
            fila := -1;
            for r in 0 to 3 loop
                if filas(r) = '0' then
                    fila := r + 1;
                end if;
            end loop;
            write(l, real(c) / real(CIC_MS), right, 0, 3);
            write(l, string'(";"));
            write(l, fila);
            write(l, string'(";"));
            if col1(2) = '0' then
                write(l, string'("0"));
            else
                write(l, string'("1"));
            end if;
            write(l, string'(";"));
            write(l, std_logic'image(teclas(6)));
            writeline(f, l);
        end loop;
        report "graf_teclado: OK";
        fin <= true;
        wait;
    end process;

end architecture sim;
