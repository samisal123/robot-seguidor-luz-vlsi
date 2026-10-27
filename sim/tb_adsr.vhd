-- ============================================================
-- tb_adsr.vhd
-- Prueba de la envolvente ADSR con las 4 configuraciones de
-- cada parametro. Los tiempos se miden en muestras (tick_fs) y
-- se comparan con T * Fs / 1000 (Fs = 48 828.125 Hz), con 2 %
-- de tolerancia mas 2 muestras. Para simular rapido hay una
-- muestra cada 2 ciclos de reloj.
-- Revisa:
--   1) attack de 2, 50, 200 y 800 ms (de 0 al maximo), subiendo
--   2) decay de 50, 200, 600 y 1500 ms (escala completa) hasta
--      cada uno de los 4 niveles de sustain (64, 128, 192, 255),
--      y que el nivel se quede en el sustain
--   3) release de 20, 150, 500 y 1500 ms (escala completa),
--      bajando, hasta reposo con activa = '0'
--   4) soltar a mitad del attack: pasa directo a liberacion
--   5) volver a presionar durante la liberacion: ataca desde el
--      nivel en que iba, sin caer a 0
--   6) cambiar el sustain mientras se sostiene la nota: el nivel
--      va al nuevo valor sin saltos
--   7) reset
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_adsr is
end entity tb_adsr;

architecture sim of tb_adsr is
    constant T_CLK : time := 20 ns;
    constant FS    : real := 48828.125;

    constant E_REPOSO  : std_logic_vector(2 downto 0) := "000";
    constant E_ATAQUE  : std_logic_vector(2 downto 0) := "001";
    constant E_DECAE   : std_logic_vector(2 downto 0) := "010";
    constant E_SOSTIE  : std_logic_vector(2 downto 0) := "011";
    constant E_LIBERA  : std_logic_vector(2 downto 0) := "100";

    signal clk     : std_logic := '0';
    signal rst     : std_logic := '1';
    signal tick_fs : std_logic := '0';
    signal gate    : std_logic := '0';
    signal atk     : std_logic_vector(1 downto 0) := "00";
    signal dec     : std_logic_vector(1 downto 0) := "00";
    signal sus     : std_logic_vector(1 downto 0) := "11";
    signal rel     : std_logic_vector(1 downto 0) := "00";
    signal nivel   : std_logic_vector(7 downto 0);
    signal etapa   : std_logic_vector(2 downto 0);
    signal activa  : std_logic;
    signal fin     : boolean := false;

    type t_ms is array (0 to 3) of real;
    constant T_ATK : t_ms := (2.0, 50.0, 200.0, 800.0);
    constant T_DEC : t_ms := (50.0, 200.0, 600.0, 1500.0);
    constant T_REL : t_ms := (20.0, 150.0, 500.0, 1500.0);
    type t_niv is array (0 to 3) of natural;
    constant NIV_SUS : t_niv := (64, 128, 192, 255);
begin

    clk <= not clk after T_CLK / 2 when not fin;

    process (clk)
    begin
        if rising_edge(clk) then
            tick_fs <= not tick_fs;     -- una muestra cada 2 ciclos
        end if;
    end process;

    dut : entity work.adsr
        port map (
            clk     => clk,
            rst     => rst,
            tick_fs => tick_fs,
            gate    => gate,
            atk     => atk,
            dec     => dec,
            sus     => sus,
            rel     => rel,
            nivel   => nivel,
            etapa   => etapa,
            activa  => activa
        );

    estimulo : process
        variable n   : natural;
        variable niv : integer;
        variable ant : integer;

        -- espera una muestra (el ciclo siguiente a un tick)
        procedure muestra is
        begin
            wait until rising_edge(clk) and tick_fs = '1';
            wait for 1 ns;
        end procedure;

        -- cuenta muestras hasta que la etapa sea e; revisa que el
        -- nivel solo suba (dir = 1), solo baje (dir = -1) o nada (0)
        procedure cuenta_hasta (e : std_logic_vector(2 downto 0); dir : integer;
                                tope : natural; cuenta : out natural) is
            variable c : natural := 0;
            variable a : integer := to_integer(unsigned(nivel));
            variable v : integer;
        begin
            while etapa /= e and c < tope loop
                muestra;
                c := c + 1;
                v := to_integer(unsigned(nivel));
                if dir = 1 then
                    assert v >= a report "tb_adsr: el nivel debia subir" severity error;
                elsif dir = -1 then
                    assert v <= a report "tb_adsr: el nivel debia bajar" severity error;
                end if;
                a := v;
            end loop;
            assert etapa = e report "tb_adsr: no se llego a la etapa esperada" severity error;
            cuenta := c;
        end procedure;

        procedure revisa_tiempo (medido : natural; ms : real; msg : string) is
            variable esperado : real;
        begin
            esperado := ms * FS / 1000.0;
            assert abs (real(medido) - esperado) <= 0.02 * esperado + 2.0
                report "tb_adsr: " & msg & ": " & integer'image(medido) & " muestras, se esperaban "
                       & integer'image(integer(esperado)) severity error;
        end procedure;

        procedure a_reposo is
            variable c : natural;
        begin
            gate <= '0';
            cuenta_hasta(E_REPOSO, -1, 200000, c);
            muestra;
        end procedure;
    begin
        rst <= '1';
        wait for 10 * T_CLK;
        wait until rising_edge(clk);
        rst <= '0';
        muestra;
        assert etapa = E_REPOSO and activa = '0' and unsigned(nivel) = 0
            report "tb_adsr: debe iniciar en reposo" severity error;

        -- 1) attack (sustain al maximo para que no haya decay)
        sus <= "11";
        dec <= "00";
        rel <= "00";
        for a in 0 to 3 loop
            atk  <= std_logic_vector(to_unsigned(a, 2));
            muestra;
            gate <= '1';
            cuenta_hasta(E_DECAE, 1, 100000, n);
            revisa_tiempo(n, T_ATK(a), "attack " & integer'image(a));
            assert to_integer(unsigned(nivel)) = 255
                report "tb_adsr: el attack debe llegar a 255" severity error;
            a_reposo;
        end loop;

        -- 2) decay hasta cada sustain
        atk <= "00";
        for d in 0 to 3 loop
            for s in 0 to 3 loop
                dec <= std_logic_vector(to_unsigned(d, 2));
                sus <= std_logic_vector(to_unsigned(s, 2));
                muestra;
                gate <= '1';
                cuenta_hasta(E_DECAE, 1, 100000, n);
                cuenta_hasta(E_SOSTIE, -1, 100000, n);
                revisa_tiempo(n, T_DEC(d) * real(255 - NIV_SUS(s)) / 255.0,
                              "decay " & integer'image(d) & " a sustain " & integer'image(s));
                for i in 1 to 200 loop
                    muestra;
                    niv := to_integer(unsigned(nivel));
                    assert abs (niv - NIV_SUS(s)) <= 1 and etapa = E_SOSTIE
                        report "tb_adsr: el sustain no se mantiene en " & integer'image(NIV_SUS(s))
                        severity error;
                end loop;
                a_reposo;
            end loop;
        end loop;

        -- 3) release desde 255
        sus <= "11";
        for r in 0 to 3 loop
            rel <= std_logic_vector(to_unsigned(r, 2));
            muestra;
            gate <= '1';
            cuenta_hasta(E_SOSTIE, 0, 100000, n);
            for i in 1 to 10 loop
                muestra;
            end loop;
            gate <= '0';
            cuenta_hasta(E_REPOSO, -1, 200000, n);
            revisa_tiempo(n, T_REL(r), "release " & integer'image(r));
            muestra;
            assert unsigned(nivel) = 0 and activa = '0'
                report "tb_adsr: tras el release el nivel debe ser 0 y activa 0" severity error;
        end loop;

        -- 4) soltar a mitad del attack de 800 ms
        atk <= "11";
        rel <= "01";
        muestra;
        gate <= '1';
        for i in 1 to 5000 loop
            muestra;
        end loop;
        assert etapa = E_ATAQUE report "tb_adsr: debe seguir en attack" severity error;
        niv := to_integer(unsigned(nivel));
        assert niv > 20 and niv < 50 report "tb_adsr: nivel a mitad del attack fuera de lo esperado" severity error;
        gate <= '0';
        muestra;
        muestra;
        assert etapa = E_LIBERA report "tb_adsr: al soltar en attack debe liberar" severity error;
        assert to_integer(unsigned(nivel)) <= niv and to_integer(unsigned(nivel)) >= niv - 1
            report "tb_adsr: la liberacion debe empezar desde el nivel actual" severity error;
        a_reposo;

        -- 5) volver a presionar durante la liberacion (release de 1500 ms)
        atk <= "01";
        rel <= "11";
        sus <= "11";
        muestra;
        gate <= '1';
        cuenta_hasta(E_SOSTIE, 0, 100000, n);
        gate <= '0';
        for i in 1 to 20000 loop
            muestra;
        end loop;
        assert etapa = E_LIBERA report "tb_adsr: debe estar liberando" severity error;
        niv := to_integer(unsigned(nivel));
        gate <= '1';
        ant := niv;
        for i in 1 to 100 loop
            muestra;
            assert to_integer(unsigned(nivel)) >= ant - 1
                report "tb_adsr: al reatacar el nivel no debe caer" severity error;
            ant := to_integer(unsigned(nivel));
        end loop;
        assert etapa = E_ATAQUE and ant > niv
            report "tb_adsr: debe atacar desde el nivel de la liberacion" severity error;
        cuenta_hasta(E_SOSTIE, 1, 100000, n);

        -- 6) cambiar el sustain en operacion: 255 -> 64 -> 192
        dec <= "01";
        sus <= "00";
        for i in 1 to 3 loop
            muestra;
        end loop;
        ant := 255;
        for i in 1 to 20000 loop
            muestra;
            assert to_integer(unsigned(nivel)) <= ant and ant - to_integer(unsigned(nivel)) <= 1
                report "tb_adsr: el sustain debe bajar sin saltos" severity error;
            ant := to_integer(unsigned(nivel));
            assert etapa = E_SOSTIE report "tb_adsr: debe seguir sostenido" severity error;
        end loop;
        assert abs (to_integer(unsigned(nivel)) - 64) <= 1
            report "tb_adsr: el nuevo sustain debe ser 64" severity error;
        sus <= "10";
        for i in 1 to 3 loop
            muestra;
        end loop;
        for i in 1 to 20000 loop
            muestra;
            assert to_integer(unsigned(nivel)) >= ant and to_integer(unsigned(nivel)) - ant <= 1
                report "tb_adsr: el sustain debe subir sin saltos" severity error;
            ant := to_integer(unsigned(nivel));
        end loop;
        assert abs (to_integer(unsigned(nivel)) - 192) <= 1
            report "tb_adsr: el nuevo sustain debe ser 192" severity error;

        -- 7) reset con la nota sostenida
        rst <= '1';
        wait until rising_edge(clk);
        wait for 1 ns;
        rst <= '0';
        assert etapa = E_REPOSO and unsigned(nivel) = 0
            report "tb_adsr: el reset debe llevar a reposo" severity error;

        report "tb_adsr: OK";
        fin <= true;
        wait;
    end process;

end architecture sim;
