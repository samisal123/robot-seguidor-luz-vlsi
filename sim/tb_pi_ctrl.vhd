-- ============================================================
-- tb_pi_ctrl.vhd
-- 1. Lazo abierto (habilitado = '0'): duty = objetivo.
-- 2. Lazo cerrado con una planta mas debil que la nominal:
--    la rueda real da 45 transiciones por ventana a duty 255 y el
--    PI se configuro con VMAX = 64. Con objetivo 128 la consigna
--    es 32 transiciones; el PI debe subir el duty hasta que la
--    medida llegue a 32 +- 1.
-- 3. Planta mas fuerte (90 a duty 255): el duty baja.
-- 4. Objetivo 0: duty 0.
-- 5. Rueda frenada (medida 0): el duty se satura en 255, no da
--    la vuelta.
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_pi_ctrl is
end entity tb_pi_ctrl;

architecture sim of tb_pi_ctrl is
    constant T_CLK : time := 10 ns;

    signal clk      : std_logic := '0';
    signal rst      : std_logic := '1';
    signal habil    : std_logic := '0';
    signal actualiza: std_logic := '0';
    signal objetivo : std_logic_vector(7 downto 0) := (others => '0');
    signal medida   : std_logic_vector(9 downto 0) := (others => '0');
    signal duty     : std_logic_vector(7 downto 0);
    signal fin      : boolean := false;
begin

    clk <= not clk after T_CLK / 2 when not fin;

    dut : entity work.pi_ctrl
        generic map (VMAX => 64)
        port map (clk => clk, rst => rst, habilitado => habil, actualizar => actualiza,
                  objetivo => objetivo, medida => medida, duty => duty);

    estimulo : process
        variable v : natural;

        -- n actualizaciones con una planta: medida = duty * vmax_real / 256
        procedure lazo (n : natural; vmax_real : natural) is
        begin
            for k in 1 to n loop
                medida <= std_logic_vector(to_unsigned(
                              (to_integer(unsigned(duty)) * vmax_real) / 256, 10));
                wait until rising_edge(clk);
                actualiza <= '1';
                wait until rising_edge(clk);
                actualiza <= '0';
                wait for 4 * T_CLK;
            end loop;
        end procedure;
    begin
        wait for 3 * T_CLK;
        rst <= '0';

        -- 1. lazo abierto
        objetivo <= std_logic_vector(to_unsigned(128, 8));
        wait for 3 * T_CLK;
        assert to_integer(unsigned(duty)) = 128 report "Lazo abierto: duty /= objetivo" severity error;

        -- 2. planta debil
        habil <= '1';
        wait for 3 * T_CLK;
        lazo(120, 45);
        v := (to_integer(unsigned(duty)) * 45) / 256;
        assert v >= 31 and v <= 33
            report "Planta debil: la medida quedo en " & integer'image(v) &
                   " con duty " & integer'image(to_integer(unsigned(duty))) severity error;
        assert to_integer(unsigned(duty)) > 128
            report "Planta debil: el duty deberia subir" severity error;

        -- 3. planta fuerte
        lazo(120, 90);
        v := (to_integer(unsigned(duty)) * 90) / 256;
        assert v >= 31 and v <= 33
            report "Planta fuerte: la medida quedo en " & integer'image(v) severity error;
        assert to_integer(unsigned(duty)) < 128
            report "Planta fuerte: el duty deberia bajar" severity error;

        -- 4. objetivo 0
        objetivo <= (others => '0');
        wait for 3 * T_CLK;
        assert to_integer(unsigned(duty)) = 0 report "Objetivo 0: duty /= 0" severity error;

        -- 5. rueda frenada
        objetivo <= std_logic_vector(to_unsigned(200, 8));
        lazo(60, 0);
        assert to_integer(unsigned(duty)) = 255
            report "Rueda frenada: duty deberia saturar en 255 y es " &
                   integer'image(to_integer(unsigned(duty))) severity error;

        report "tb_pi_ctrl: OK" severity note;
        fin <= true;
        wait;
    end process;

end architecture sim;
