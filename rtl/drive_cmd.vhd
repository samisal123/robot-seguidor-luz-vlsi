-- ============================================================
-- drive_cmd.vhd
-- Traduce la accion de la FSM a direccion y duty de cada rueda:
--   accion      izquierda          derecha
--   PARO        0                  0
--   AVANZA      adelante V_AVANCE  adelante V_AVANCE
--   CURVA_IZQ   adelante V_CURVA   adelante V_AVANCE
--   CURVA_DER   adelante V_AVANCE  adelante V_CURVA
--   GIRO_IZQ    atras V_GIRO       adelante V_GIRO
--   GIRO_DER    adelante V_GIRO    atras V_GIRO
--   REVERSA     atras V_REVERSA    atras V_REVERSA
--   BUSCA       atras V_BUSCA      adelante V_BUSCA (giro lento)
-- El duty de salida sigue al objetivo con una rampa de
-- PASO_RAMPA por ms. Si la rueda debe cambiar de sentido, la
-- rampa baja a 0, cambia la direccion y vuelve a subir.
-- Con habilitado = '0' el objetivo es 0.
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.robot_pkg.all;

entity drive_cmd is
    generic (
        V_AVANCE   : natural  := 170;
        V_CURVA    : natural  := 80;
        V_GIRO     : natural  := 150;
        V_BUSCA    : natural  := 110;
        V_REVERSA  : natural  := 140;
        PASO_RAMPA : positive := 8
    );
    port (
        clk        : in  std_logic;
        rst        : in  std_logic;   -- sincrono, activo en alto
        tick_1ms   : in  std_logic;
        accion     : in  std_logic_vector(2 downto 0);
        habilitado : in  std_logic;
        dir_l      : out std_logic;   -- '1' adelante
        duty_l     : out std_logic_vector(7 downto 0);
        dir_r      : out std_logic;
        duty_r     : out std_logic_vector(7 downto 0)
    );
end entity drive_cmd;

architecture rtl of drive_cmd is
    subtype t_duty is natural range 0 to 255;

    signal obj_dl, obj_dr : std_logic := '1';
    signal obj_vl, obj_vr : t_duty := 0;
    signal act_dl, act_dr : std_logic := '1';
    signal act_vl, act_vr : t_duty := 0;

    -- Un paso de rampa de una rueda hacia (dir_obj, v_obj)
    procedure rampa (signal d_act : inout std_logic; signal v_act : inout t_duty;
                     d_obj : std_logic; v_obj : t_duty) is
    begin
        if d_act /= d_obj and v_act /= 0 then
            -- primero frenar hasta 0 en el sentido actual
            if v_act > PASO_RAMPA then
                v_act <= v_act - PASO_RAMPA;
            else
                v_act <= 0;
            end if;
        else
            d_act <= d_obj;
            if v_act + PASO_RAMPA <= v_obj then
                v_act <= v_act + PASO_RAMPA;
            elsif v_act > v_obj + PASO_RAMPA then
                v_act <= v_act - PASO_RAMPA;
            else
                v_act <= v_obj;
            end if;
        end if;
    end procedure;
begin

    -- Objetivo de cada rueda
    process (accion, habilitado)
    begin
        obj_dl <= '1';
        obj_dr <= '1';
        obj_vl <= 0;
        obj_vr <= 0;
        if habilitado = '1' then
            case accion is
                when A_AVANZA =>
                    obj_vl <= V_AVANCE;
                    obj_vr <= V_AVANCE;
                when A_CURVA_IZQ =>
                    obj_vl <= V_CURVA;
                    obj_vr <= V_AVANCE;
                when A_CURVA_DER =>
                    obj_vl <= V_AVANCE;
                    obj_vr <= V_CURVA;
                when A_GIRO_IZQ =>
                    obj_dl <= '0';
                    obj_vl <= V_GIRO;
                    obj_vr <= V_GIRO;
                when A_GIRO_DER =>
                    obj_dr <= '0';
                    obj_vl <= V_GIRO;
                    obj_vr <= V_GIRO;
                when A_REVERSA =>
                    obj_dl <= '0';
                    obj_dr <= '0';
                    obj_vl <= V_REVERSA;
                    obj_vr <= V_REVERSA;
                when A_BUSCA =>
                    obj_dl <= '0';
                    obj_vl <= V_BUSCA;
                    obj_vr <= V_BUSCA;
                when others =>
                    null;   -- PARO
            end case;
        end if;
    end process;

    process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                act_dl <= '1';
                act_dr <= '1';
                act_vl <= 0;
                act_vr <= 0;
            elsif tick_1ms = '1' then
                rampa(act_dl, act_vl, obj_dl, obj_vl);
                rampa(act_dr, act_vr, obj_dr, obj_vr);
            end if;
        end if;
    end process;

    dir_l  <= act_dl;
    dir_r  <= act_dr;
    duty_l <= std_logic_vector(to_unsigned(act_vl, 8));
    duty_r <= std_logic_vector(to_unsigned(act_vr, 8));

end architecture rtl;
