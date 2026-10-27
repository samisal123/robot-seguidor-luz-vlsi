-- ============================================================
-- tb_display_hex.vhd
-- Prueba de los displays de 7 segmentos. Decodifica cada
-- display de regreso a un caracter (segmentos activos en bajo)
-- y compara contra el texto esperado.
-- Revisa:
--   1) nombre de cada modo en HEX5-HEX4
--   2) interpretacion: "o" + octava base y la ultima nota con
--      punto en los sostenidos (A4, C#5, B6) y "--" sin nota
--   3) grabacion y reproduccion: numero sin ceros a la izquierda
--      (0, 7, 40, 256)
--   4) configuracion: nombre de cada parametro y su valor
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.synth_pkg.all;

entity tb_display_hex is
end entity tb_display_hex;

architecture sim of tb_display_hex is
    constant T_CLK : time := 20 ns;

    signal clk       : std_logic := '0';
    signal modo      : std_logic_vector(1 downto 0) := M_INT;
    signal parametro : std_logic_vector(2 downto 0) := "000";
    signal forma     : std_logic_vector(1 downto 0) := "01";
    signal atk       : std_logic_vector(1 downto 0) := "10";
    signal dec       : std_logic_vector(1 downto 0) := "11";
    signal sus       : std_logic_vector(1 downto 0) := "00";
    signal rel       : std_logic_vector(1 downto 0) := "01";
    signal volumen   : std_logic_vector(2 downto 0) := "100";
    signal tempo     : std_logic_vector(1 downto 0) := "10";
    signal efecto    : std_logic_vector(1 downto 0) := "11";
    signal octava    : std_logic_vector(2 downto 0) := "100";
    signal ultima    : std_logic_vector(6 downto 0) := (others => '0');
    signal posicion  : std_logic_vector(8 downto 0) := (others => '0');
    signal hex0, hex1, hex2, hex3, hex4, hex5 : std_logic_vector(7 downto 0);
    signal fin       : boolean := false;

    -- segmentos (activo en bajo, sin punto) -> caracter
    function car (h : std_logic_vector(7 downto 0)) return character is
        variable s : std_logic_vector(6 downto 0);
    begin
        s := not h(6 downto 0);
        case s is
            when "0111111" => return '0';
            when "0000110" => return '1';
            when "1011011" => return '2';
            when "1001111" => return '3';
            when "1100110" => return '4';
            when "1101101" => return '5';   -- tambien S
            when "1111101" => return '6';
            when "0000111" => return '7';
            when "1111111" => return '8';
            when "1101111" => return '9';
            when "1110111" => return 'A';
            when "1111100" => return 'b';
            when "0111001" => return 'C';
            when "1011110" => return 'd';
            when "1111001" => return 'E';
            when "1110001" => return 'F';
            when "0111101" => return 'G';
            when "0110000" => return 'I';
            when "1010100" => return 'n';
            when "1011100" => return 'o';
            when "1110011" => return 'P';
            when "1010000" => return 'r';
            when "1111000" => return 't';
            when "0111110" => return 'U';
            when "0011100" => return 'u';
            when "1000000" => return '-';
            when "0000000" => return ' ';
            when others    => return '?';
        end case;
    end function;
begin

    clk <= not clk after T_CLK / 2 when not fin;

    dut : entity work.display_hex
        port map (
            clk       => clk,
            modo      => modo,
            parametro => parametro,
            forma     => forma,
            atk       => atk,
            dec       => dec,
            sus       => sus,
            rel       => rel,
            volumen   => volumen,
            tempo     => tempo,
            efecto    => efecto,
            octava    => octava,
            ultima    => ultima,
            posicion  => posicion,
            hex0      => hex0,
            hex1      => hex1,
            hex2      => hex2,
            hex3      => hex3,
            hex4      => hex4,
            hex5      => hex5
        );

    estimulo : process
        procedure ciclos (n : natural) is
        begin
            for i in 1 to n loop
                wait until rising_edge(clk);
            end loop;
            wait for 1 ns;
        end procedure;

        -- texto esperado de HEX5 a HEX0 (6 caracteres) y puntos
        procedure revisa (txt : string(1 to 6); puntos : std_logic_vector(5 downto 0); msg : string) is
            variable leido : string(1 to 6);
            variable dp    : std_logic_vector(5 downto 0);
        begin
            ciclos(2);
            leido := car(hex5) & car(hex4) & car(hex3) & car(hex2) & car(hex1) & car(hex0);
            dp := not (hex5(7) & hex4(7) & hex3(7) & hex2(7) & hex1(7) & hex0(7));
            assert leido = txt
                report "tb_display_hex: " & msg & ": se leyo '" & leido & "', se esperaba '" & txt & "'"
                severity error;
            assert dp = puntos
                report "tb_display_hex: " & msg & ": puntos incorrectos" severity error;
        end procedure;
    begin
        -- 1) y 2) interpretacion
        modo   <= M_INT;
        octava <= "100";
        ultima <= (others => '0');
        revisa("Ino4--", "000000", "interpretacion sin nota");
        ultima <= std_logic_vector(to_unsigned(57, 7));    -- A4
        revisa("Ino4A4", "000000", "A4");
        ultima <= std_logic_vector(to_unsigned(61, 7));    -- C#5
        octava <= "101";
        revisa("Ino5C5", "000010", "C#5");
        ultima <= std_logic_vector(to_unsigned(83, 7));    -- B6
        revisa("Ino5b6", "000000", "B6");
        ultima <= std_logic_vector(to_unsigned(54, 7));    -- F#4
        revisa("Ino5F4", "000010", "F#4");

        -- 3) grabacion y reproduccion
        modo <= M_GRA;
        posicion <= std_logic_vector(to_unsigned(0, 9));
        revisa("Gr   0", "000000", "grabacion 0");
        posicion <= std_logic_vector(to_unsigned(7, 9));
        revisa("Gr   7", "000000", "grabacion 7");
        modo <= M_REP;
        posicion <= std_logic_vector(to_unsigned(40, 9));
        revisa("rP  40", "000000", "reproduccion 40");
        posicion <= std_logic_vector(to_unsigned(256, 9));
        revisa("rP 256", "000000", "reproduccion 256");
        posicion <= std_logic_vector(to_unsigned(105, 9));
        revisa("rP 105", "000000", "reproduccion 105");

        -- 4) configuracion
        modo <= M_CONF;
        parametro <= std_logic_vector(to_unsigned(P_FORMA, 3));
        revisa("CFFo 1", "000000", "forma");
        parametro <= std_logic_vector(to_unsigned(P_ATTACK, 3));
        revisa("CFAt 2", "000000", "attack");
        parametro <= std_logic_vector(to_unsigned(P_DECAY, 3));
        revisa("CFdE 3", "000000", "decay");
        parametro <= std_logic_vector(to_unsigned(P_SUSTAIN, 3));
        revisa("CF5u 0", "000000", "sustain");
        parametro <= std_logic_vector(to_unsigned(P_RELEASE, 3));
        revisa("CFrE 1", "000000", "release");
        parametro <= std_logic_vector(to_unsigned(P_VOLUMEN, 3));
        revisa("CFUo 4", "000000", "volumen");
        parametro <= std_logic_vector(to_unsigned(P_TEMPO, 3));
        revisa("CFtE 2", "000000", "tempo");
        parametro <= std_logic_vector(to_unsigned(P_EFECTO, 3));
        revisa("CFEF 3", "000000", "efecto");

        report "tb_display_hex: OK";
        fin <= true;
        wait;
    end process;

end architecture sim;
