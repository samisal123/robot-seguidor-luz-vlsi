-- ============================================================
-- tb_robot_top.vhd
-- Prueba de sistema del robot completo con modelos del entorno:
--   - 4 HC-SR04: responden a su TRIG con un eco de 58 us por cm
--   - LDR y comparador de cerca: los maneja el testbench
--   - encoders quietos
-- Reloj de 2 MHz (minimo de tick_gen) para acortar la simulacion;
-- los tiempos del robot (ms) son reales.
-- Escenario: arranque con KEY0 -> BUSCAR (giro lento a la
-- izquierda) -> aparece luz al frente -> SEGUIR (ambas ruedas
-- adelante) -> obstaculo a 15 cm -> ESQUIVA -> se despeja ->
-- rodeo y vuelve a SEGUIR -> luz cerca junto a la lampara ->
-- META (motores parados, LEDs parpadeando).
-- El estado se lee de HEX5 y la bitacora UART se decodifica.
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_robot_top is
end entity tb_robot_top;

architecture sim of tb_robot_top is
    constant CLK_HZ : natural := 2_000_000;
    constant T_CLK  : time    := 500 ns;
    constant T_BIT  : time    := 17 * T_CLK;      -- CLK_HZ / 115200 = 17 ciclos

    signal clk   : std_logic := '0';
    signal key   : std_logic_vector(1 downto 0) := "11";
    signal sw    : std_logic_vector(9 downto 0) := (8 => '1', others => '0');
    signal ledr  : std_logic_vector(9 downto 0);
    signal hex0, hex1, hex2, hex3, hex4, hex5 : std_logic_vector(7 downto 0);
    signal trig, echo : std_logic_vector(3 downto 0) := (others => '0');
    signal ldr_ve : std_logic_vector(3 downto 0) := "0000";
    signal ldr_cerca : std_logic := '0';
    signal pwma, ain1, ain2, pwmb, bin1, bin2, stby : std_logic;
    signal uart  : std_logic;
    signal fin   : boolean := false;

    type t_int4 is array (0 to 3) of natural;
    signal dist_cm : t_int4 := (150, 150, 150, 150);

    signal linea    : string(1 to 64) := (others => ' ');
    signal n_lineas : natural := 0;

    -- Numero que muestra un display (patron gfedcba activo en bajo)
    function digito (h : std_logic_vector(7 downto 0)) return integer is
    begin
        case h(6 downto 0) is
            when "1000000" => return 0;
            when "1111001" => return 1;
            when "0100100" => return 2;
            when "0110000" => return 3;
            when "0011001" => return 4;
            when "0010010" => return 5;
            when "0000010" => return 6;
            when "1111000" => return 7;
            when others    => return -1;
        end case;
    end function;
begin

    clk <= not clk after T_CLK / 2 when not fin;

    dut : entity work.robot_top
        generic map (CLK_HZ => CLK_HZ)
        port map (
            MAX10_CLK1_50 => clk, KEY => key, SW => sw, LEDR => ledr,
            HEX0 => hex0, HEX1 => hex1, HEX2 => hex2, HEX3 => hex3, HEX4 => hex4, HEX5 => hex5,
            US_TRIG => trig, US_ECHO => echo, LDR_VE => ldr_ve, LDR_CERCA => ldr_cerca,
            MOT_PWMA => pwma, MOT_AIN1 => ain1, MOT_AIN2 => ain2,
            MOT_PWMB => pwmb, MOT_BIN1 => bin1, MOT_BIN2 => bin2, MOT_STBY => stby,
            ENC_L => "00", ENC_R => "00", UART_TX => uart,
            VGA_R => open, VGA_G => open, VGA_B => open, VGA_HS => open, VGA_VS => open);

    -- HC-SR04
    sensores : for i in 0 to 3 generate
        process
        begin
            wait until trig(i) = '1';
            wait until trig(i) = '0';
            wait for 150 us;
            echo(i) <= '1';
            wait for dist_cm(i) * 58 us;
            echo(i) <= '0';
        end process;
    end generate;

    -- Receptor UART (17 ciclos por bit)
    receptor : process
        variable r : std_logic_vector(7 downto 0);
        variable c : character;
        variable n : natural := 0;
    begin
        wait until falling_edge(uart);
        wait for T_BIT / 2;
        for i in 0 to 7 loop
            wait for T_BIT;
            r(i) := uart;
        end loop;
        wait for T_BIT;
        c := character'val(to_integer(unsigned(r)));
        if c = character'val(10) then
            n_lineas <= n_lineas + 1;
            n := 0;
        elsif n < 64 then
            n := n + 1;
            linea(n) <= c;
        end if;
    end process;

    estimulo : process
        variable alto : natural;

        -- Estado actual segun HEX5
        impure function estado return integer is
        begin
            return digito(hex5);
        end function;

        -- Espera hasta que el estado sea e (o falla al pasar el limite)
        procedure espera_estado (e : natural; limite : time; msg : string) is
            variable t0 : time;
        begin
            t0 := now;
            while estado /= e and now - t0 < limite loop
                wait for 1 ms;
            end loop;
            assert estado = e
                report msg & ": estado " & integer'image(estado) & ", se esperaba " &
                       integer'image(e) severity error;
        end procedure;

        -- Ciclos en alto de un PWM durante un periodo (256 * 10 ciclos)
        procedure mide_pwm (signal p : in std_logic; variable n : out natural) is
            variable c : natural := 0;
        begin
            for k in 1 to 2560 loop
                wait until rising_edge(clk);
                if p = '1' then
                    c := c + 1;
                end if;
            end loop;
            n := c;
        end procedure;
    begin
        -- Encendido y reset
        key(1) <= '0';
        wait for 1 ms;
        key(1) <= '1';
        wait for 40 ms;
        espera_estado(0, 1 ms, "Encendido");
        assert stby = '1' report "STBY deberia estar en 1 con SW8 arriba" severity error;

        -- KEY0: arranque
        key(0) <= '0';
        wait for 40 ms;
        key(0) <= '1';
        espera_estado(1, 50 ms, "Arranque");

        -- BUSCAR: izquierda atras y derecha adelante a V_BUSCA (110)
        wait for 150 ms;
        assert ain1 = '0' and ain2 = '1' report "BUSCAR: rueda izquierda deberia ir atras" severity error;
        assert bin1 = '1' and bin2 = '0' report "BUSCAR: rueda derecha deberia ir adelante" severity error;
        mide_pwm(pwma, alto);
        assert alto >= 1090 and alto <= 1110
            report "BUSCAR: duty izquierdo " & integer'image(alto) & "/2560" severity error;
        mide_pwm(pwmb, alto);
        assert alto >= 1090 and alto <= 1110
            report "BUSCAR: duty derecho " & integer'image(alto) & "/2560" severity error;

        -- Luz al frente
        ldr_ve <= "0001";
        espera_estado(2, 50 ms, "Luz al frente");
        wait for 200 ms;
        assert ain1 = '1' and ain2 = '0' and bin1 = '1' and bin2 = '0'
            report "SEGUIR: ambas ruedas deberian ir adelante" severity error;
        mide_pwm(pwma, alto);
        assert alto >= 1690 and alto <= 1710
            report "SEGUIR: duty izquierdo " & integer'image(alto) & "/2560" severity error;
        assert digito(hex4) = 1 report "HEX4 deberia mostrar el evento 1 (luz)" severity error;

        -- Obstaculo a 15 cm al frente
        dist_cm(0) <= 15;
        espera_estado(3, 250 ms, "Obstaculo al frente");
        assert digito(hex4) = 3 report "HEX4 deberia mostrar el evento 3 (obstaculo)" severity error;
        assert ledr(4) = '1' report "LEDR4 deberia marcar obstaculo al frente" severity error;
        wait for 100 ms;
        assert ain1 = '0' and ain2 = '1' and bin1 = '1'
            report "ESQUIVA: deberia girar a la izquierda (empate de diagonales)" severity error;

        -- Se despeja: rodeo y de vuelta a SEGUIR
        dist_cm(0) <= 150;
        espera_estado(2, 1500 ms, "Fin de la esquiva");

        -- Junto a la lampara: primero la luz cerca, luego la base como obstaculo
        ldr_cerca  <= '1';
        wait for 30 ms;
        dist_cm(0) <= 10;
        espera_estado(6, 800 ms, "Meta");
        assert digito(hex4) = 6 report "HEX4 deberia mostrar el evento 6 (meta)" severity error;
        wait for 100 ms;
        mide_pwm(pwma, alto);
        assert alto = 0 report "META: los motores deberian estar parados" severity error;
        mide_pwm(pwmb, alto);
        assert alto = 0 report "META: los motores deberian estar parados" severity error;

        -- LEDs parpadeando en META
        alto := 0;
        for k in 1 to 30 loop
            wait for 10 ms;
            if ledr(0) = '1' then
                alto := alto + 1;
            end if;
        end loop;
        assert alto > 5 and alto < 25 report "En META los LEDs deberian parpadear" severity error;

        -- Bitacora UART: la ultima linea es del estado META
        wait for 250 ms;
        assert n_lineas >= 5 report "Llegaron pocas lineas por UART" severity error;
        assert linea(1 to 5) = "E6 V6"
            report "Ultima linea UART: [" & linea(1 to 41) & "]" severity error;

        report "tb_robot_top: OK" severity note;
        fin <= true;
        wait;
    end process;

end architecture sim;
