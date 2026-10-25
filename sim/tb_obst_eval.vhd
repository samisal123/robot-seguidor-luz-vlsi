-- ============================================================
-- tb_obst_eval.vhd
-- Umbrales e histeresis de cada sensor (frente 25, diagonales 18,
-- atras 12, histeresis 5), sin eco = libre, 0 cm = obstaculo, y
-- la eleccion de lado libre.
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_obst_eval is
end entity tb_obst_eval;

architecture sim of tb_obst_eval is
    constant T_CLK : time := 10 ns;
    signal clk  : std_logic := '0';
    signal rst  : std_logic := '1';
    signal dist : std_logic_vector(35 downto 0) := (others => '1');
    signal obs  : std_logic_vector(3 downto 0);
    signal lado : std_logic;
    signal fin  : boolean := false;
begin

    clk <= not clk after T_CLK / 2 when not fin;

    dut : entity work.obst_eval
        port map (clk => clk, rst => rst, dist => dist, obs => obs, lado_libre => lado);

    estimulo : process
        procedure pon (i : natural; cm : natural) is
        begin
            dist(9 * i + 8 downto 9 * i) <= std_logic_vector(to_unsigned(cm, 9));
            wait for 3 * T_CLK;
        end procedure;

        procedure revisa (i : natural; v : std_logic; msg : string) is
        begin
            assert obs(i) = v report "Sensor " & integer'image(i) & ": " & msg severity error;
        end procedure;

        type t_u is array (0 to 3) of natural;
        constant U : t_u := (25, 18, 18, 12);
    begin
        wait for 3 * T_CLK;
        rst <= '0';
        wait for 3 * T_CLK;
        assert obs = "0000" report "Sin eco deberia ser libre" severity error;

        for i in 0 to 3 loop
            pon(i, U(i));          revisa(i, '0', "en el umbral no es obstaculo");
            pon(i, U(i) - 1);      revisa(i, '1', "abajo del umbral es obstaculo");
            pon(i, U(i) + 4);      revisa(i, '1', "dentro de la histeresis se mantiene");
            pon(i, U(i) + 5);      revisa(i, '0', "umbral + histeresis libera");
            pon(i, U(i) + 1);      revisa(i, '0', "arriba del umbral sigue libre");
            pon(i, 0);             revisa(i, '1', "0 cm es obstaculo");
            pon(i, 511);           revisa(i, '0', "sin eco libera");
        end loop;

        -- Lado libre: compara diagonal derecha contra izquierda
        pon(1, 40);  pon(2, 80);
        assert lado = '1' report "Derecha mas libre: lado deberia ser 1" severity error;
        pon(1, 80);  pon(2, 40);
        assert lado = '0' report "Izquierda mas libre: lado deberia ser 0" severity error;
        pon(1, 60);  pon(2, 60);
        assert lado = '0' report "Empate: lado deberia ser 0" severity error;

        report "tb_obst_eval: OK" severity note;
        fin <= true;
        wait;
    end process;

end architecture sim;
