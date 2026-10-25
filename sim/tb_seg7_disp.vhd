-- ============================================================
-- tb_seg7_disp.vhd
-- Verifica seg7_disp leyendo los displays como texto con una
-- tabla propia (patron de 7 segmentos -> caracter):
--   estado y evento 0..7 en HEX5 y HEX4,
--   los 256 valores de duty dan duty*100/256 en 2 digitos,
--   puntos decimales apagados en modo normal,
--   modo distancia: sensor con punto en HEX3, distancias
--   0..510 sin ceros a la izquierda y 511 como "---".
-- GHDL: sim/correr.sh seg7_disp
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_seg7_disp is
end entity tb_seg7_disp;

architecture sim of tb_seg7_disp is
    constant T_CLK : time := 20 ns;
    signal clk       : std_logic := '0';
    signal estado    : std_logic_vector(2 downto 0) := "000";
    signal evento    : std_logic_vector(2 downto 0) := "000";
    signal duty_l    : std_logic_vector(7 downto 0) := (others => '0');
    signal duty_r    : std_logic_vector(7 downto 0) := (others => '0');
    signal modo_dist : std_logic := '0';
    signal sensor    : std_logic_vector(1 downto 0) := "00";
    signal dist_cm   : std_logic_vector(8 downto 0) := (others => '0');
    signal hex0, hex1, hex2, hex3, hex4, hex5 : std_logic_vector(7 downto 0);
    signal fin       : boolean := false;

    -- Segmentos gfedcba activos en bajo -> caracter ('?' si no se reconoce)
    function leer (h : std_logic_vector(7 downto 0)) return character is
    begin
        case h(6 downto 0) is
            when "1000000" => return '0';
            when "1111001" => return '1';
            when "0100100" => return '2';
            when "0110000" => return '3';
            when "0011001" => return '4';
            when "0010010" => return '5';
            when "0000010" => return '6';
            when "1111000" => return '7';
            when "0000000" => return '8';
            when "0010000" => return '9';
            when "0111111" => return '-';
            when "1111111" => return ' ';
            when others    => return '?';
        end case;
    end function;

    function car (n : natural) return character is
    begin
        return character'val(character'pos('0') + n);
    end function;

    -- n en 3 caracteres sin ceros a la izquierda
    function texto3 (n : natural) return string is
    begin
        if n >= 100 then
            return car(n / 100) & car((n / 10) mod 10) & car(n mod 10);
        elsif n >= 10 then
            return ' ' & car(n / 10) & car(n mod 10);
        else
            return "  " & car(n);
        end if;
    end function;
begin

    clk <= not clk after T_CLK / 2 when not fin;

    dut : entity work.seg7_disp
        port map (clk => clk, estado => estado, evento => evento,
                  duty_l => duty_l, duty_r => duty_r, modo_dist => modo_dist,
                  sensor => sensor, dist_cm => dist_cm,
                  hex0 => hex0, hex1 => hex1, hex2 => hex2,
                  hex3 => hex3, hex4 => hex4, hex5 => hex5);

    estimulo : process
        variable pl, pr : natural;
        variable txt    : string(1 to 3);

        -- Las conversiones van en etapas: el % de duty tarda 3 ciclos
        -- y el display uno mas; se esperan 4 flancos
        procedure esperar is
        begin
            for k in 1 to 4 loop
                wait until rising_edge(clk);
            end loop;
            wait for 1 ns;
        end procedure;
    begin
        -- Estado y evento
        for i in 0 to 7 loop
            estado <= std_logic_vector(to_unsigned(i, 3));
            evento <= std_logic_vector(to_unsigned(7 - i, 3));
            esperar;
            assert leer(hex5) = car(i) report "HEX5 no muestra el estado " & integer'image(i) severity error;
            assert leer(hex4) = car(7 - i) report "HEX4 no muestra el evento " & integer'image(7 - i) severity error;
            assert hex5(7) = '1' and hex4(7) = '1' report "punto encendido en HEX5/HEX4" severity error;
        end loop;

        -- Casos puntuales de duty
        duty_l <= std_logic_vector(to_unsigned(128, 8));
        duty_r <= std_logic_vector(to_unsigned(255, 8));
        esperar;
        assert leer(hex3) & leer(hex2) = "50" report "duty 128 no muestra 50" severity error;
        assert leer(hex1) & leer(hex0) = "99" report "duty 255 no muestra 99" severity error;

        -- Los 256 valores de duty, en ambas ruedas
        for i in 0 to 255 loop
            duty_l <= std_logic_vector(to_unsigned(i, 8));
            duty_r <= std_logic_vector(to_unsigned(255 - i, 8));
            esperar;
            pl := i * 100 / 256;
            pr := (255 - i) * 100 / 256;
            assert leer(hex3) = car(pl / 10) and leer(hex2) = car(pl mod 10)
                report "duty_l " & integer'image(i) & ": se esperaba " & integer'image(pl) &
                       ", se lee " & leer(hex3) & leer(hex2)
                severity error;
            assert leer(hex1) = car(pr / 10) and leer(hex0) = car(pr mod 10)
                report "duty_r " & integer'image(255 - i) & ": se esperaba " & integer'image(pr) &
                       ", se lee " & leer(hex1) & leer(hex0)
                severity error;
            assert hex3(7) = '1' and hex2(7) = '1' and hex1(7) = '1' and hex0(7) = '1'
                report "punto encendido en modo normal" severity error;
        end loop;

        -- Modo distancia
        modo_dist <= '1';
        for s in 0 to 3 loop
            sensor <= std_logic_vector(to_unsigned(s, 2));
            esperar;
            assert leer(hex3) = car(s) and hex3(7) = '0'
                report "HEX3 no muestra el sensor con punto" severity error;
        end loop;

        dist_cm <= std_logic_vector(to_unsigned(123, 9));
        esperar;
        assert leer(hex2) & leer(hex1) & leer(hex0) = "123" report "123 cm mal mostrado" severity error;

        for n in 0 to 510 loop
            dist_cm <= std_logic_vector(to_unsigned(n, 9));
            esperar;
            txt := leer(hex2) & leer(hex1) & leer(hex0);
            assert txt = texto3(n)
                report "dist " & integer'image(n) & ": se lee '" & txt & "'" severity error;
            assert hex2(7) = '1' and hex1(7) = '1' and hex0(7) = '1'
                report "punto encendido en la distancia" severity error;
        end loop;

        dist_cm <= (others => '1');
        esperar;
        assert leer(hex2) & leer(hex1) & leer(hex0) = "---" report "511 no muestra ---" severity error;

        -- El estado sigue visible en modo distancia
        estado <= "110";
        esperar;
        assert leer(hex5) = '6' report "estado no visible en modo distancia" severity error;

        -- De regreso al modo normal
        modo_dist <= '0';
        duty_l <= std_logic_vector(to_unsigned(26, 8));   -- 10.15 %
        esperar;
        assert leer(hex3) & leer(hex2) = "10" and hex3(7) = '1'
            report "no regreso al modo normal" severity error;

        report "tb_seg7_disp: OK" severity note;
        fin <= true;
        wait;
    end process;

end architecture sim;
