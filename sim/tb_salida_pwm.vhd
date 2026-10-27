-- ============================================================
-- tb_salida_pwm.vhd
-- Prueba del PWM de 8 bits.
-- Mide ventanas de 256 ciclos alineadas con el primer flanco de
-- subida despues del reset y revisa bit por bit que cada periodo
-- sea un solo pulso al inicio con el ancho esperado; si el periodo
-- no fuera de 256 ciclos las ventanas se desfasarian y fallaria.
-- Revisa:
--   1) despues del reset el duty es 128
--   2) las 256 muestras (-128..127): ancho = muestra + 128 ciclos
--      (-128 queda siempre en 0, 127 da 255 de 256)
--   3) el duty solo cambia al inicio de un periodo: un cambio a la
--      mitad no afecta al periodo en curso, un cambio en la posicion
--      254 entra en el siguiente y uno en la posicion 255 ya no
--   4) reset a media marcha: salida en 0 y vuelve con duty 128
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_salida_pwm is
end entity tb_salida_pwm;

architecture sim of tb_salida_pwm is
    constant T_CLK : time := 20 ns;

    signal clk     : std_logic := '0';
    signal rst     : std_logic := '1';
    signal muestra : std_logic_vector(7 downto 0) := (others => '0');
    signal pwm     : std_logic;
    signal fin     : boolean := false;
begin

    clk <= not clk after T_CLK / 2 when not fin;

    dut : entity work.salida_pwm
        port map (
            clk     => clk,
            rst     => rst,
            muestra => muestra,
            pwm     => pwm
        );

    estimulo : process
        variable periodos : natural := 0;
        variable cur      : integer;

        -- Revisa una ventana de 256 ciclos (muestreando en flancos de
        -- bajada); en la posicion pos_cambio pone la muestra nueva
        procedure ventana (ancho : integer; pos_cambio : integer; nueva : integer) is
            variable esp : std_logic;
        begin
            for pos in 0 to 255 loop
                wait until falling_edge(clk);
                if pos < ancho then
                    esp := '1';
                else
                    esp := '0';
                end if;
                assert pwm = esp
                    report "periodo " & integer'image(periodos) & " (ancho " &
                           integer'image(ancho) & "): pwm incorrecto en la posicion " &
                           integer'image(pos) severity error;
                if pos = pos_cambio then
                    muestra <= std_logic_vector(to_signed(nueva, 8));
                end if;
            end loop;
            periodos := periodos + 1;
        end procedure;
    begin
        for i in 1 to 4 loop
            wait until rising_edge(clk);
        end loop;
        rst <= '0';
        wait until rising_edge(pwm) for 1 us;
        assert pwm = '1' report "el PWM no arranco despues del reset" severity error;

        -- 1) y 2): duty 128 del reset, luego las 256 muestras en orden
        cur := 128;
        for d in 0 to 255 loop
            ventana(cur, 100, d - 128);   -- el cambio a la mitad no afecta este periodo
            cur := d;
        end loop;
        -- unos valores al azar en medio
        ventana(cur, 17, 37);     cur := 37 + 128;
        ventana(cur, 200, -77);   cur := -77 + 128;
        ventana(cur, 0, 5);       cur := 5 + 128;

        -- 3) limites del cambio de duty
        ventana(cur, 254, 60);    -- en 254 todavia entra
        cur := 60 + 128;
        ventana(cur, 255, -60);   -- en 255 ya no entra en el siguiente
        ventana(cur, -1, 0);      -- sigue el anterior
        cur := -60 + 128;
        ventana(cur, -1, 0);      -- ahora si el nuevo
        report "periodos revisados: " & integer'image(periodos);

        -- 4) reset a media marcha
        for i in 1 to 30 loop
            wait until rising_edge(clk);
        end loop;
        muestra <= std_logic_vector(to_signed(100, 8));
        rst     <= '1';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait for 1 ns;
        assert pwm = '0' report "en reset la salida debe quedar en 0" severity error;
        rst <= '0';
        wait until rising_edge(pwm) for 100 ns;
        assert pwm = '1' report "el PWM no arranco despues del segundo reset" severity error;
        ventana(128, -1, 0);      -- primer periodo con el duty del reset
        ventana(228, -1, 0);      -- y luego el de la muestra (100 + 128)

        report "tb_salida_pwm: OK";
        fin <= true;
        wait;
    end process;

end architecture sim;
