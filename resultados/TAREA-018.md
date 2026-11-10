# TAREA-018
Estado: FALLO (la descarga directa no existe; hay que bajar los archivos con cuenta de Altera)
Fecha: 2026-11-09 20:41
Equipo: pc-bd-scm.n.fi.unam

## Comandos y salida real

```
$ ls ~/Descargas/quartus13
ls: cannot access '/home/samuel/Descargas/quartus13': No such file or directory
$ mkdir -p ~/Descargas/quartus13          # creada, queda vacia
```

Antes de bajar 2.2 GB se reviso que responde la URL directa (solo cabeceras, `curl -sSIL`):

```
== QuartusSetupWeb-13.0.1.232.run
HTTP/2 301
location: https://corpredirect.intel.com/Redirector/404Redirector.aspx?404;https://downloads.intel.com/akdlm/software/acdsinst/13.0sp1/232/ib_installers/QuartusSetupWeb-13.0.1.232.run
HTTP/1.1 301 Moved Permanently
Location: https://www.intel.com/content/www/us/en/download-center/home.html
HTTP/2 200
content-type: text/html;charset=utf-8
== cyclone_web-13.0.1.232.qdz
HTTP/2 301
location: https://corpredirect.intel.com/Redirector/404Redirector.aspx?404;https://downloads.intel.com/akdlm/software/acdsinst/13.0sp1/232/ib_installers/cyclone_web-13.0.1.232.qdz
HTTP/1.1 301 Moved Permanently
Location: https://www.intel.com/content/www/us/en/download-center/home.html
HTTP/2 200
content-type: text/html;charset=utf-8
```

Las dos URLs terminan en una pagina HTML (el 404 de Intel redirige al Download Center), no en el archivo. Tambien se probo el espejo viejo de Altera, sin exito:

```
== https://download.altera.com/akdlm/software/acdsinst/13.0sp1/232/ib_installers/QuartusSetupWeb-13.0.1.232.run
HTTP/1.0 403 Forbidden
```

No se descargo nada, asi que no hubo SHA-1 que revisar ni instalacion (pasos 3 a 6 no se ejecutaron). No existe `~/altera/13.0sp1`.

```
$ lsusb | grep -iE "09fb|altera|blaster"
(nada: sin USB-Blaster conectado)
$ df -h ~
/dev/nvme0n1p6   59G   52G  4.6G  92% /
```

## Notas

- **Lo que tiene que hacer el equipo:** bajar con su cuenta, desde https://www.altera.com/downloads/fpga-development-tools/quartus-ii-web-edition-design-software-version-13-0sp1-linux, los dos archivos `QuartusSetupWeb-13.0.1.232.run` (1.6 GB, SHA-1 `1418b2971aa44686c5d11b6c8ef81eee137379e8`) y `cyclone_web-13.0.1.232.qdz` (568.9 MB, SHA-1 `882b19a8ffee1edd133693ff422a3f6c5a615589`) y dejarlos en `~/Descargas/quartus13`. Despues se vuelve a correr esta tarea desde el paso 3.
- **Espacio en disco:** quedan 4.6 GB libres en `/`. Los dos archivos ocupan ~2.2 GB y la instalacion de Quartus 13.0 SP1 con Cyclone ocupa varios GB mas, asi que probablemente no alcance. Los instaladores hacen falta durante la instalacion (solo se pueden borrar al final), asi que conviene liberar espacio antes (por ejemplo `~/.cache`, 2.0 GB) o descargar en otra unidad. No se borro nada.
- **USB-Blaster:** no hay cable conectado y `jtagconfig` de la 13.0 SP1 no existe todavia. Cuando se conecte, si no lo ve, la regla que el equipo debe agregar (con sudo) en `/etc/udev/rules.d/51-usbblaster.rules` es:

  ```
  SUBSYSTEM=="usb", ATTR{idVendor}=="09fb", ATTR{idProduct}=="6001", MODE="0666"
  SUBSYSTEM=="usb", ATTR{idVendor}=="09fb", ATTR{idProduct}=="6002", MODE="0666"
  SUBSYSTEM=="usb", ATTR{idVendor}=="09fb", ATTR{idProduct}=="6003", MODE="0666"
  SUBSYSTEM=="usb", ATTR{idVendor}=="09fb", ATTR{idProduct}=="6010", MODE="0666"
  SUBSYSTEM=="usb", ATTR{idVendor}=="09fb", ATTR{idProduct}=="6810", MODE="0666"
  ```

  y despues `sudo udevadm control --reload-rules && sudo udevadm trigger`, desconectar y volver a conectar el cable.
