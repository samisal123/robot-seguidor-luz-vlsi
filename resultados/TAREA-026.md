# TAREA-026
Estado: OK
Fecha: 2026-11-10 08:39
Equipo: pc-bd-scm.n.fi.unam

## Comandos y salida real
```
$ git pull --rebase
Already up to date.
$ sh quartus/arreglar_interfaz.sh
Bajando http://security.ubuntu.com/ubuntu/pool/main/libp/libpng/libpng12-0_1.2.54-1ubuntu1.1_amd64.deb
SHA-256 correcto: libpng12-0_1.2.54-1ubuntu1.1_amd64.deb
Copiado a /home/samuel/altera/13.0sp1/quartus/linux64:
lrwxrwxrwx 1 samuel samuel     18 Jul 10  2018 /home/samuel/altera/13.0sp1/quartus/linux64/libpng12.so.0 -> libpng12.so.0.54.0
-rw-r--r-- 1 samuel samuel 149904 Jul 10  2018 /home/samuel/altera/13.0sp1/quartus/linux64/libpng12.so.0.54.0

Bibliotecas que le faltan a linux64/quartus (debe quedar vacio):

Probando la interfaz: se abre Quartus 40 s y se cierra sola
OK: la interfaz sigue abierta despues de 40 s
Lo que escribio Quartus en la terminal:
(codigo de salida 0)
```

## Notas
- Se uso el primer paquete (xenial-security, 1.2.54-1ubuntu1.1); su SHA-256 coincidio.
- `ldd` ya no reporta bibliotecas faltantes.
- La prueba corrio con `DISPLAY=:0` (la sesion de la PC), tal como lo hace el script; Quartus no escribio nada en la terminal (`logs/interfaz_salida.log` vacio).
- Bitacora completa en `logs/interfaz.log`.
