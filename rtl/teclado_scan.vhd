-- ============================================================
-- teclado_scan.vhd
-- Barrido de dos teclados matriciales de 4x4 de membrana.
-- Cada ms activa una fila (la misma en los dos teclados): pone
-- esa fila en '0' y las demas quedan en alta impedancia (el top
-- convierte el '1' de filas en 'Z'). Las columnas tienen pull-up,
-- asi que una tecla presionada en la fila activa lee '0'.
-- Antes de cambiar de fila lee las 8 columnas; el barrido completo
-- tarda 4 ms.
-- Antirrebote: cada tecla cambia de estado solo despues de N_DEB
-- lecturas seguidas distintas a su estado (5 lecturas = 20 ms).
-- Salida teclas: '1' = presionada. Teclado k, fila r, columna c
-- en el bit 16k + 4r + c. Varias teclas a la vez se detectan
-- (polifonia); con tres teclas en esquinas de un rectangulo de la
-- misma matriz aparece una cuarta fantasma (el teclado no tiene
-- diodos).
-- col1 y col2 ya deben venir sincronizadas (sync_2ff).
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;

entity teclado_scan is
    generic (
        N_DEB : positive := 5
    );
    port (
        clk      : in  std_logic;
        rst      : in  std_logic;   -- sincrono, activo en alto
        tick_1ms : in  std_logic;
        filas    : out std_logic_vector(3 downto 0);   -- '0' = fila activa
        col1     : in  std_logic_vector(3 downto 0);   -- teclado 1, '0' = tecla
        col2     : in  std_logic_vector(3 downto 0);   -- teclado 2
        teclas   : out std_logic_vector(31 downto 0)
    );
end entity teclado_scan;

architecture rtl of teclado_scan is
    type t_cnt is array (0 to 31) of natural range 0 to N_DEB - 1;
    signal fila    : natural range 0 to 3 := 0;
    signal estable : std_logic_vector(31 downto 0) := (others => '0');
    signal cuenta  : t_cnt := (others => 0);
begin

    process (clk)
        variable crudo : std_logic;
        variable k     : natural range 0 to 31;
    begin
        if rising_edge(clk) then
            if rst = '1' then
                fila    <= 0;
                estable <= (others => '0');
                cuenta  <= (others => 0);
            elsif tick_1ms = '1' then
                -- lectura de la fila activa en los dos teclados
                for t in 0 to 1 loop
                    for c in 0 to 3 loop
                        k := 16 * t + 4 * fila + c;
                        if t = 0 then
                            crudo := not col1(c);
                        else
                            crudo := not col2(c);
                        end if;
                        if crudo = estable(k) then
                            cuenta(k) <= 0;
                        elsif cuenta(k) = N_DEB - 1 then
                            cuenta(k)  <= 0;
                            estable(k) <= crudo;
                        else
                            cuenta(k) <= cuenta(k) + 1;
                        end if;
                    end loop;
                end loop;
                -- siguiente fila
                if fila = 3 then
                    fila <= 0;
                else
                    fila <= fila + 1;
                end if;
            end if;
        end if;
    end process;

    salidas : for r in 0 to 3 generate
        filas(r) <= '0' when fila = r else '1';
    end generate;

    teclas <= estable;

end architecture rtl;
