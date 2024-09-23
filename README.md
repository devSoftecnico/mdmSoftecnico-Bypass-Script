# MDM-Softecnico Bypass Script

Este repositorio contiene un script para eludir la inscripción de MDM en dispositivos macOS. El script está diseñado para ejecutarse en **Modo de Recuperación** y también puede ser copiado a un SSD externo para facilitar su uso.

## Características:
- **Modo de Recuperación**: El script está optimizado para ejecutarse exclusivamente en Modo de Recuperación de macOS.
- **Soporte para Intel y Apple Silicon (M1/M2)**: Compatible con ambas arquitecturas.
- **Eliminación de MDM**: Bloquea los servidores de MDM y elimina los perfiles de inscripción de la máquina.
- **Creación de usuarios locales**: Permite crear un nuevo perfil de usuario con permisos administrativos.

## Instrucciones breves:

1. **Conectar el SSD externo** (si tienes uno) o **clonar este repositorio** a la máquina en Modo de Recuperación.

2. **Reiniciar en Modo de Recuperación**:
   - **Intel**: Reinicia tu Mac y mantén presionadas las teclas **Command (⌘) + R**.
   - **M1/M2**: Mantén presionado el botón de encendido hasta que veas las opciones de arranque, luego selecciona **Opciones**.

3. **Abrir la Terminal** desde el menú superior.

4. **Montar el SSD** si es necesario:

   ```bash
   diskutil mount /Volumes/mdmSoftecnico
Ejecutar el script:


Si el script está en el SSD:
    Copiar código
   ```bash
   sudo /Volumes/mdmSoftecnico/mdmSoftecnico.sh


Si estás usando el repositorio directamente:
   Copiar código
```bash

sudo ./mdmSoftecnico.sh

Introducir la contraseña de administrador cuando se te solicite.

Créditos:
Credits: eudy97 | MDM-bypass