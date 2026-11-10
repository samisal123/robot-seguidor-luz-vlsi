-- ============================================================
-- tb_reset_encendido.vhd
-- Prueba del reset del sistema.
-- Revisa:
--   1) rst arranca en '1' y se queda arriba mientras el PLL no
--      esta enganchado (listo = '0')
--   2) despues de listo = '1' sigue en '1' 17 flancos y baja en
--      el 18 (2 del sincronizador y 16 de cuenta); no vuelve a subir
--   3) el boton RESET (boton_n = '0') sube rst a los 2 flancos,
--      lo mantiene mientras esta presionado y lo baja en el flanco
--      18 despues de soltarlo
--   4) si el PLL se desengancha, rst vuelve a subir
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;

entity tb_reset_encendido is
end entity tb_reset_encendido;

architecture sim of tb_reset_encendido is
    constant T_CLK : time := 40 ns;

    signal clk     : std_logic := '0';
    signal listo   : std_logic := '0';
    signal boton_n : std_logic := '1';
    signal rst     : std_logic;
    signal fin     : boolean := false;
begin

    clk <= not clk after T_CLK / 2 when not fin;

    dut : entity work.reset_encendido
        port map (clk => clk, listo => listo, boton_n => boton_n, rst => rst);

    estimulo : process
        -- cuenta los flancos que rst sigue en '1' despues de un cambio
        procedure mide_bajada (esperado : natural; msg : string) is
            variable altos : natural := 0;
        begin
            for i in 1 to 100 loop
                wait until rising_edge(clk);
                wait for 1 ns;
                if rst = '1' then
                    altos := altos + 1;
                    assert altos = i report "tb_reset_encendido: " & msg & ": rst volvio a subir"
                        severity error;
                end if;
            end loop;
            assert altos = esperado
                report "tb_reset_encendido: " & msg & ": rst duro " & integer'image(altos)
                       & " ciclos, se esperaban " & integer'image(esperado) severity error;
        end procedure;
    begin
        -- 1)
        wait for 1 ns;
        assert rst = '1' report "tb_reset_encendido: rst debe arrancar en 1" severity error;
        for i in 1 to 50 loop
            wait until rising_edge(clk);
            wait for 1 ns;
            assert rst = '1' report "tb_reset_encendido: rst bajo sin PLL" severity error;
        end loop;

        -- 2)
        listo <= '1';
        mide_bajada(17, "arranque");

        -- 3) boton de reset
        boton_n <= '0';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait for 1 ns;
        assert rst = '1' report "tb_reset_encendido: el boton no subio rst" severity error;
        for i in 1 to 30 loop
            wait until rising_edge(clk);
            wait for 1 ns;
            assert rst = '1' report "tb_reset_encendido: rst bajo con el boton presionado" severity error;
        end loop;
        boton_n <= '1';
        mide_bajada(17, "boton");

        -- 4) el PLL se desengancha
        listo <= '0';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait for 1 ns;
        assert rst = '1' report "tb_reset_encendido: sin PLL rst debe subir" severity error;
        listo <= '1';
        mide_bajada(17, "reenganche");

        report "tb_reset_encendido: OK";
        fin <= true;
        wait;
    end process;

end architecture sim;
