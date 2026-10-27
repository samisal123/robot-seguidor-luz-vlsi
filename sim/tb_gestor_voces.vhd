-- ============================================================
-- tb_gestor_voces.vhd
-- Prueba del reparto de notas entre las 3 voces.
-- Un modelo simple de las envolventes da activas: una voz sigue
-- activa LIB ciclos despues de bajar su gate (su liberacion).
-- Revisa, en casos dirigidos:
--   1) notas que llegan una por una ocupan voces distintas
--   2) soltar una nota baja solo su gate y conserva la nota
--   3) volver a presionar una nota en liberacion usa la misma voz,
--      aunque haya otra voz en reposo
--   4) una nota nueva prefiere una voz en reposo a una que libera
--   5) un acorde que cambia completo se reasigna en 3 ciclos
-- Y en 20 000 conjuntos aleatorios, en cada ciclo:
--   a) ninguna voz con gate tiene una nota que no se pide
--   b) dos voces con gate nunca tienen la misma nota
--   c) 3 ciclos despues de un cambio, toda nota pedida tiene voz
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity tb_gestor_voces is
end entity tb_gestor_voces;

architecture sim of tb_gestor_voces is
    constant T_CLK : time := 20 ns;
    constant LIB   : natural := 6;      -- ciclos de liberacion del modelo

    signal clk      : std_logic := '0';
    signal rst      : std_logic := '1';
    signal conjunto : std_logic_vector(20 downto 0) := (others => '0');
    signal activas  : std_logic_vector(2 downto 0) := (others => '0');
    signal notas_v  : std_logic_vector(20 downto 0);
    signal gates    : std_logic_vector(2 downto 0);
    signal estable  : natural := 0;     -- ciclos desde el ultimo cambio
    signal fin      : boolean := false;

    function n_de (v : std_logic_vector(20 downto 0); i : natural) return natural is
    begin
        return to_integer(unsigned(v(7 * i + 6 downto 7 * i)));
    end function;

    function arma (a, b, c : natural) return std_logic_vector is
    begin
        return std_logic_vector(to_unsigned(c, 7)) & std_logic_vector(to_unsigned(b, 7))
               & std_logic_vector(to_unsigned(a, 7));
    end function;
begin

    clk <= not clk after T_CLK / 2 when not fin;

    dut : entity work.gestor_voces
        port map (
            clk      => clk,
            rst      => rst,
            conjunto => conjunto,
            activas  => activas,
            notas_v  => notas_v,
            gates    => gates
        );

    -- modelo de las envolventes: activa mientras hay gate y LIB
    -- ciclos despues de bajarlo
    modelo : process (clk)
        type t_cnt is array (0 to 2) of natural;
        variable resto : t_cnt := (others => 0);
    begin
        if rising_edge(clk) then
            for v in 0 to 2 loop
                if gates(v) = '1' then
                    resto(v) := LIB;
                    activas(v) <= '1';
                elsif resto(v) > 0 then
                    resto(v) := resto(v) - 1;
                    activas(v) <= '1';
                else
                    activas(v) <= '0';
                end if;
            end loop;
        end if;
    end process;

    -- invariantes en cada ciclo
    invariantes : process (clk)
        variable pedida : boolean;
        variable tiene  : boolean;
        variable cuenta : natural := 0;
        variable ant    : std_logic_vector(20 downto 0) := (others => '0');
    begin
        if rising_edge(clk) then
            if conjunto /= ant then
                cuenta := 0;
            elsif cuenta < 1000 then
                cuenta := cuenta + 1;
            end if;
            ant := conjunto;
            estable <= cuenta;
            if rst = '0' then
                for v in 0 to 2 loop
                    if gates(v) = '1' then
                        -- a) la nota de una voz con gate se pide
                        -- (con un ciclo de retraso del registro)
                        if cuenta >= 1 then
                            pedida := false;
                            for i in 0 to 2 loop
                                if n_de(conjunto, i) /= 0 and n_de(conjunto, i) = n_de(notas_v, v) then
                                    pedida := true;
                                end if;
                            end loop;
                            assert pedida
                                report "tb_gestor_voces: voz con gate y nota que no se pide" severity error;
                        end if;
                        -- b) sin notas repetidas
                        for w in v + 1 to 2 loop
                            if gates(w) = '1' then
                                assert n_de(notas_v, v) /= n_de(notas_v, w)
                                    report "tb_gestor_voces: dos voces con la misma nota" severity error;
                            end if;
                        end loop;
                    end if;
                end loop;
                -- c) toda nota pedida tiene voz 3 ciclos despues
                if cuenta >= 3 then
                    for i in 0 to 2 loop
                        if n_de(conjunto, i) /= 0 then
                            tiene := false;
                            for v in 0 to 2 loop
                                if gates(v) = '1' and n_de(notas_v, v) = n_de(conjunto, i) then
                                    tiene := true;
                                end if;
                            end loop;
                            assert tiene
                                report "tb_gestor_voces: nota pedida sin voz" severity error;
                        end if;
                    end loop;
                end if;
            end if;
        end if;
    end process;

    estimulo : process
        procedure ciclos (n : natural) is
        begin
            for i in 1 to n loop
                wait until rising_edge(clk);
            end loop;
            wait for 1 ns;
        end procedure;

        variable s1, s2   : positive := 7;
        variable r        : real;
        variable k, na    : natural;
        variable notas    : std_logic_vector(20 downto 0);
        type t_lista is array (0 to 2) of natural;
        variable l        : t_lista;
        variable tmp      : natural;
        variable dup      : boolean;
    begin
        rst <= '1';
        ciclos(3);
        rst <= '0';
        ciclos(2);
        assert gates = "000" report "tb_gestor_voces: al inicio no debe haber gates" severity error;

        -- 1) llegan 60, 64, 67
        conjunto <= arma(60, 0, 0);
        ciclos(3);
        assert gates = "001" and n_de(notas_v, 0) = 60
            report "tb_gestor_voces: 60 debe ir a la voz 0" severity error;
        conjunto <= arma(60, 64, 0);
        ciclos(3);
        assert gates = "011" and n_de(notas_v, 1) = 64
            report "tb_gestor_voces: 64 debe ir a la voz 1" severity error;
        conjunto <= arma(60, 64, 67);
        ciclos(3);
        assert gates = "111" and n_de(notas_v, 2) = 67
            report "tb_gestor_voces: 67 debe ir a la voz 2" severity error;

        -- 2) soltar 64: solo baja la voz 1 y conserva su nota
        conjunto <= arma(60, 67, 0);
        ciclos(2);
        assert gates = "101" and n_de(notas_v, 1) = 64
            report "tb_gestor_voces: soltar 64 debe bajar solo la voz 1" severity error;

        -- 3) volver a presionar 64 durante su liberacion: misma voz
        conjunto <= arma(60, 64, 67);
        ciclos(3);
        assert gates = "111" and n_de(notas_v, 1) = 64 and n_de(notas_v, 0) = 60
               and n_de(notas_v, 2) = 67
            report "tb_gestor_voces: 64 debe volver a la voz 1" severity error;

        -- 4) soltar todo, esperar a que la voz 0 termine, y que las
        -- voces 1 y 2 sigan liberando: una nota nueva va a la 0
        conjunto <= arma(0, 0, 0);
        ciclos(LIB + 4);
        assert gates = "000" and activas = "000"
            report "tb_gestor_voces: todas deben estar en reposo" severity error;
        conjunto <= arma(50, 0, 0);
        ciclos(3);
        conjunto <= arma(51, 0, 0);       -- 50 a liberar, 51 entra
        ciclos(3);
        assert gates = "010" and n_de(notas_v, 1) = 51
            report "tb_gestor_voces: 51 debe ir a una voz en reposo (1)" severity error;
        conjunto <= arma(51, 53, 0);      -- voz 0 liberando, voz 2 en reposo
        ciclos(2);
        assert gates = "110" and n_de(notas_v, 2) = 53
            report "tb_gestor_voces: 53 debe preferir la voz en reposo (2)" severity error;

        -- 3b) misma nota durante su liberacion con otra voz en reposo:
        -- debe preferir la voz que ya tenia la nota
        conjunto <= arma(0, 0, 0);
        ciclos(LIB + 4);
        conjunto <= arma(60, 64, 0);
        ciclos(3);
        assert gates = "011" and n_de(notas_v, 1) = 64
            report "tb_gestor_voces: 60 y 64 deben ir a las voces 0 y 1" severity error;
        conjunto <= arma(60, 0, 0);
        ciclos(2);
        assert gates = "001" and activas(1) = '1'
            report "tb_gestor_voces: la voz 1 debe estar liberando" severity error;
        conjunto <= arma(60, 64, 0);
        ciclos(2);
        assert gates = "011" and n_de(notas_v, 1) = 64
            report "tb_gestor_voces: 64 debe volver a su voz (1) aunque la 2 este en reposo"
            severity error;

        -- 5) acorde que cambia completo
        conjunto <= arma(60, 64, 67);
        ciclos(LIB + 5);
        conjunto <= arma(62, 65, 69);
        ciclos(1);
        assert gates = "000" or gates = "001" or gates = "010" or gates = "100"
            report "tb_gestor_voces: el primer ciclo debe soltar las tres" severity error;
        ciclos(3);
        assert gates = "111" report "tb_gestor_voces: el nuevo acorde debe tener 3 voces" severity error;

        -- conjuntos aleatorios (notas distintas, ordenadas, de 0 a 3)
        for prueba in 1 to 20000 loop
            uniform(s1, s2, r);
            na := integer(trunc(r * 4.0));
            for i in 0 to 2 loop
                loop
                    uniform(s1, s2, r);
                    l(i) := 40 + integer(trunc(r * 12.0));   -- pocas notas: muchas repeticiones
                    dup := false;
                    for j in 0 to i - 1 loop
                        if l(j) = l(i) then
                            dup := true;
                        end if;
                    end loop;
                    exit when not dup;
                end loop;
            end loop;
            -- ordenar
            for i in 0 to 1 loop
                for j in 0 to 1 - i loop
                    if l(j) > l(j + 1) then
                        tmp := l(j);
                        l(j) := l(j + 1);
                        l(j + 1) := tmp;
                    end if;
                end loop;
            end loop;
            notas := (others => '0');
            for i in 0 to 2 loop
                if i < na then
                    notas(7 * i + 6 downto 7 * i) := std_logic_vector(to_unsigned(l(i), 7));
                end if;
            end loop;
            conjunto <= notas;
            uniform(s1, s2, r);
            ciclos(1 + integer(trunc(r * 10.0)));
        end loop;

        report "tb_gestor_voces: OK";
        fin <= true;
        wait;
    end process;

end architecture sim;
