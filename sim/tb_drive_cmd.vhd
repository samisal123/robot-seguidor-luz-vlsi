-- ============================================================
-- tb_drive_cmd.vhd
-- Valor final de cada accion, rampa de PASO_RAMPA por ms y que
-- una rueda nunca cambie de sentido con duty distinto de 0.
-- tick_1ms cada 2 ciclos.
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.robot_pkg.all;

entity tb_drive_cmd is
end entity tb_drive_cmd;

architecture sim of tb_drive_cmd is
    constant T_CLK : time := 10 ns;
    constant T_MS  : time := 2 * T_CLK;

    signal clk      : std_logic := '0';
    signal rst      : std_logic := '1';
    signal tick_1ms : std_logic := '0';
    signal accion   : std_logic_vector(2 downto 0) := A_PARO;
    signal habil    : std_logic := '1';
    signal dir_l, dir_r   : std_logic;
    signal duty_l, duty_r : std_logic_vector(7 downto 0);
    signal fin      : boolean := false;
begin

    clk <= not clk after T_CLK / 2 when not fin;

    process (clk)
    begin
        if rising_edge(clk) then
            tick_1ms <= not tick_1ms;
        end if;
    end process;

    dut : entity work.drive_cmd
        port map (clk => clk, rst => rst, tick_1ms => tick_1ms, accion => accion,
                  habilitado => habil, dir_l => dir_l, duty_l => duty_l,
                  dir_r => dir_r, duty_r => duty_r);

    -- El sentido solo cambia con la rueda en 0
    process (clk)
        variable dl, dr : std_logic := '1';
        variable vl, vr : natural := 0;
    begin
        if rising_edge(clk) then
            assert not (dir_l /= dl and vl /= 0)
                report "Rueda izquierda cambio de sentido en movimiento" severity error;
            assert not (dir_r /= dr and vr /= 0)
                report "Rueda derecha cambio de sentido en movimiento" severity error;
            assert abs (to_integer(unsigned(duty_l)) - vl) <= 8 and
                   abs (to_integer(unsigned(duty_r)) - vr) <= 8
                report "La rampa cambio mas de 8 en un paso" severity error;
            dl := dir_l;
            dr := dir_r;
            vl := to_integer(unsigned(duty_l));
            vr := to_integer(unsigned(duty_r));
        end if;
    end process;

    estimulo : process
        procedure revisa (a : std_logic_vector(2 downto 0); dl : std_logic; vl : natural;
                          dr : std_logic; vr : natural; msg : string) is
        begin
            accion <= a;
            wait for 80 * T_MS;    -- de sobra para cualquier rampa
            assert dir_l = dl and to_integer(unsigned(duty_l)) = vl
                report msg & ": rueda izquierda " & integer'image(to_integer(unsigned(duty_l)))
                severity error;
            assert dir_r = dr and to_integer(unsigned(duty_r)) = vr
                report msg & ": rueda derecha " & integer'image(to_integer(unsigned(duty_r)))
                severity error;
        end procedure;
    begin
        wait for 3 * T_CLK;
        rst <= '0';
        wait until rising_edge(clk);

        -- Rampa: 8 por ms desde 0, asi que a los 10 ms va en 80 (+- un paso)
        accion <= A_AVANZA;
        wait for 10 * T_MS;
        assert to_integer(unsigned(duty_l)) >= 72 and to_integer(unsigned(duty_l)) <= 88
            report "Rampa: tras 10 ms el duty deberia ser 80 y es " &
                   integer'image(to_integer(unsigned(duty_l))) severity error;

        revisa(A_AVANZA,    '1', 170, '1', 170, "AVANZA");
        revisa(A_CURVA_IZQ, '1', 80,  '1', 170, "CURVA_IZQ");
        revisa(A_CURVA_DER, '1', 170, '1', 80,  "CURVA_DER");
        revisa(A_GIRO_IZQ,  '0', 150, '1', 150, "GIRO_IZQ");
        revisa(A_GIRO_DER,  '1', 150, '0', 150, "GIRO_DER");
        revisa(A_REVERSA,   '0', 140, '0', 140, "REVERSA");
        revisa(A_BUSCA,     '0', 110, '1', 110, "BUSCA");
        revisa(A_PARO,      '1', 0,   '1', 0,   "PARO");

        -- Deshabilitado: todo en 0
        accion <= A_AVANZA;
        wait for 80 * T_MS;
        habil <= '0';
        wait for 80 * T_MS;
        assert to_integer(unsigned(duty_l)) = 0 and to_integer(unsigned(duty_r)) = 0
            report "Con habilitado = 0 el duty debe ser 0" severity error;

        report "tb_drive_cmd: OK" severity note;
        fin <= true;
        wait;
    end process;

end architecture sim;
