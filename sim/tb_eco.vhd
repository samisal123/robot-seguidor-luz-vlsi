-- ============================================================
-- tb_eco.vhd
-- Prueba del eco con la linea de retardo real de 4096 muestras.
-- Revisa:
--   1) 3 x 4096 + 300 muestras al azar en todo el rango, con un
--      tramo apagado a la mitad, contra un modelo:
--        d = y[n - 4096] (0 si la RAM aun no da la vuelta)
--        y = saturar(x + piso(d / 2), +-2032) si activo, si no y = x
--      y y la bandera satura deben coincidir en cada muestra
--   2) despues de un reset (la RAM sigue llena de lo anterior):
--      impulsos de 1600 en n = 0 y -1000 en n = 100 regresan
--      exactamente en n + 4096 (800, -500), n + 8192 (400, -250)
--      y n + 12288 (200, -125); todo lo demas vale 0
--   3) latencia: sal_valida 3 ciclos despues de ent_valida
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_eco is
end entity tb_eco;

architecture sim of tb_eco is
    constant T_CLK   : time := 20 ns;
    constant RETARDO : natural := 4096;
    constant TOPE    : integer := 2032;

    signal clk        : std_logic := '0';
    signal rst        : std_logic := '1';
    signal activo     : std_logic := '1';
    signal ent_valida : std_logic := '0';
    signal x          : std_logic_vector(11 downto 0) := (others => '0');
    signal y          : std_logic_vector(11 downto 0);
    signal sal_valida : std_logic;
    signal satura     : std_logic;
    signal fin        : boolean := false;

    function piso_div (a, b : integer) return integer is
    begin
        if a >= 0 then
            return a / b;
        else
            return -((-a + b - 1) / b);
        end if;
    end function;
begin

    clk <= not clk after T_CLK / 2 when not fin;

    dut : entity work.eco
        generic map (RETARDO => RETARDO)
        port map (
            clk        => clk,
            rst        => rst,
            activo     => activo,
            ent_valida => ent_valida,
            x          => x,
            y          => y,
            sal_valida => sal_valida,
            satura     => satura
        );

    estimulo : process
        type t_mem is array (0 to RETARDO - 1) of integer;
        variable mem    : t_mem;
        variable ptr    : natural;
        variable lleno  : boolean;
        variable lfsr   : unsigned(15 downto 0) := x"BEEF";
        variable xv, d, s, e : integer;
        variable sat    : std_logic;
        variable yv     : integer;
        variable satv   : std_logic;
        variable n_sat  : natural := 0;
        variable act    : std_logic;

        procedure muestra (xin : integer; a : std_logic; yout : out integer;
                           sout : out std_logic) is
        begin
            x          <= std_logic_vector(to_signed(xin, 12));
            activo     <= a;
            ent_valida <= '1';
            wait until rising_edge(clk);
            ent_valida <= '0';
            wait for 1 ns;
            assert sal_valida = '0' report "sal_valida antes de tiempo (1)" severity error;
            wait until rising_edge(clk);
            wait for 1 ns;
            assert sal_valida = '0' report "sal_valida antes de tiempo (2)" severity error;
            wait until rising_edge(clk);
            wait for 1 ns;
            assert sal_valida = '1' report "sal_valida no llego a los 3 ciclos" severity error;
            yout := to_integer(signed(y));
            sout := satura;
            wait until rising_edge(clk);
            wait for 1 ns;
            assert sal_valida = '0' report "sal_valida dura mas de un ciclo" severity error;
        end procedure;

        procedure siguiente_azar is
        begin
            lfsr := lfsr(14 downto 0) & (lfsr(15) xor lfsr(13) xor lfsr(12) xor lfsr(10));
        end procedure;

        function esperado_impulso (n : integer) return integer is
        begin
            case n is
                when 0     => return 1600;
                when 100   => return -1000;
                when 4096  => return 800;
                when 4196  => return -500;
                when 8192  => return 400;
                when 8292  => return -250;
                when 12288 => return 200;
                when 12388 => return -125;
                when others => return 0;
            end case;
        end function;
    begin
        for i in 1 to 4 loop
            wait until rising_edge(clk);
        end loop;
        rst <= '0';
        wait until rising_edge(clk);
        wait for 1 ns;

        -- 1) azar contra el modelo
        ptr   := 0;
        lleno := false;
        for n in 0 to 3 * RETARDO + 299 loop
            siguiente_azar;
            xv := to_integer(signed(lfsr(11 downto 0)));
            if xv > TOPE then xv := TOPE; end if;
            if xv < -TOPE then xv := -TOPE; end if;
            if n >= 12000 and n < 13000 then
                act := '0';
            else
                act := '1';
            end if;
            -- modelo
            if lleno then
                d := mem(ptr);
            else
                d := 0;
            end if;
            if act = '1' then
                s := xv + piso_div(d, 2);
                if s > TOPE then
                    e := TOPE;  sat := '1';
                elsif s < -TOPE then
                    e := -TOPE; sat := '1';
                else
                    e := s;     sat := '0';
                end if;
            else
                e := xv; sat := '0';
            end if;
            mem(ptr) := e;
            if ptr = RETARDO - 1 then
                ptr := 0; lleno := true;
            else
                ptr := ptr + 1;
            end if;
            -- DUT
            muestra(xv, act, yv, satv);
            assert yv = e
                report "muestra " & integer'image(n) & ": y = " & integer'image(yv) &
                       ", se esperaba " & integer'image(e) severity error;
            assert satv = sat
                report "muestra " & integer'image(n) & ": satura incorrecta" severity error;
            if sat = '1' then
                n_sat := n_sat + 1;
            end if;
        end loop;
        report "azar: " & integer'image(3 * RETARDO + 300) & " muestras, " &
               integer'image(n_sat) & " saturadas";
        assert n_sat > 100 report "la prueba no ejercito la saturacion" severity error;

        -- 2) reset e impulsos: lo viejo de la RAM no debe oirse
        rst <= '1';
        wait until rising_edge(clk);
        rst <= '0';
        wait for 1 ns;
        for n in 0 to 3 * RETARDO + 199 loop
            if n = 0 then
                xv := 1600;
            elsif n = 100 then
                xv := -1000;
            else
                xv := 0;
            end if;
            muestra(xv, '1', yv, satv);
            assert yv = esperado_impulso(n)
                report "impulso: y(" & integer'image(n) & ") = " & integer'image(yv) &
                       ", se esperaba " & integer'image(esperado_impulso(n)) severity error;
            assert satv = '0' report "impulso: satura no debe activarse" severity error;
        end loop;

        report "tb_eco: OK";
        fin <= true;
        wait;
    end process;

end architecture sim;
