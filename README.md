# ConvertirCBR

**ConvertirCBR** es un script en PowerShell creado por Daniel Amores. Está diseñado para procesar archivos **CBR** y **CBZ**, normalizar nombres, extraer imágenes, convertirlas a formato **WEBP** y volver a empaquetar los archivos, mostrando además el **ahorro en espacio** de manera visual y organizada.

---

## 🧾 RESUMEN GENERAL

El script:

1. Solicita una ruta de **carpeta raíz** al usuario.
2. Busca **subcarpetas directas** dentro de esa ruta.
3. Procesa cada subcarpeta y la carpeta raíz:
   - Detecta la extensión real de los archivos (`.ZIP` o `.RAR`) según los **Magic Digits**.
   - Renombra los archivos `.CBR`/`.CBZ` a su **extensión correcta**.
   - Descomprime los archivos en **carpetas separadas**.
   - Elimina carpetas y archivos innecesarios (`__MACOSX`, `.TXT`, `Thumbs.db`, imágenes temporales).
   - Normaliza los nombres de los archivos eliminando **caracteres especiales**.
   - Extrae contenido de **subcarpetas internas** si es necesario.
   - Convierte todas las imágenes a **formato .WEBP** (altura 2000px, calidad 85).
   - Vuelve a empaquetar las imágenes convertidas en un archivo **.CBR**.
   - Compara el tamaño del archivo original con el convertido y muestra el **ahorro en MB**.
4. Muestra un resumen final del **ahorro total en espacio**.

---

## 🔁 Función Principal: `ProcesarArchivo`

**Parámetros:**

- `$archivo`: archivo `.CBR` o `.CBZ` a procesar.  
- `$carpetaDestino`: ruta donde se extraerán y procesarán las imágenes.  
- `[ref]$ahorroTotal`: variable por referencia para acumular el **ahorro total en MB**.

**Flujo interno de la función:**

### 🟦 1. Preparativos

- Detecta la **extensión real** del archivo.  
- Renombra el archivo si es necesario.  
- Define la **carpeta temporal de trabajo**.

### 🟦 2. Descompresión y limpieza

- Extrae los contenidos del archivo.  
- Elimina archivos y carpetas innecesarias.  
- Normaliza nombres de archivos e imágenes.

### 🟦 3. Conversión de imágenes

- Convierte todas las imágenes a **formato .WEBP**.  
- Mantiene **proporción y calidad** definida.

### 🟦 4. Reempaquetado y comparación

- Crea un archivo **.CBR** con las imágenes convertidas.  
- Compara tamaño con el archivo original.  
- Reemplaza el original si el nuevo es más pequeño y suma al **ahorro total**.

---

## 🟨 BLOQUE PRINCIPAL (Main)

1. Pide al usuario una **ruta absoluta**.  
2. Obtiene:
   - Carpeta raíz (`$carpetaRaiz`)  
   - Subcarpetas directas (`$subcarpetas`)  
3. Procesa cada subcarpeta.  
4. Luego procesa la **raíz** también.  
5. Al final, muestra el **ahorro total acumulado**.

---

## 🛠️ TECNOLOGÍAS USADAS

- PowerShell  
- 7-Zip para descomprimir archivos `.CBZ` y `.CBR`  
- FFMpeg para convertir imágenes a `.WEBP`  
- Funciones de PowerShell como `Get-ChildItem`, `Set-Location`, `Join-Path`, `Test-Path`  
- Uso de `[ref]` para **variables por referencia**  
- Interacción con el usuario (`Read-Host`)  

---

## 📌 EJEMPLO VISUAL

Imagina que tienes esta estructura:
C:\Comics
├── Comic1.cbr (120 MB)
├── Comic2.cbz (95 MB)

Si usas el script con:
Introduzca la ruta absoluta: C:\Comics

**Procedimiento:**

- El script procesa **solo la carpeta raíz**.  
- Detecta la **extensión real** de cada archivo (`.CBR` o `.CBZ`) según los **Magic Digits** y renombra a `.ZIP` o `.RAR`.  
- Descomprime cada archivo en **subcarpetas separadas** dentro de la carpeta raíz:  
  - `Comic1\`  
  - `Comic2\`  
- Ajusta la estructura de archivos para que cada **imagen quede organizada** correctamente en la carpeta raíz de cada cómic.  
- Convierte las imágenes al **formato .WEBP** con resolución **2000px** y **calidad 85%**.  
- Vuelve a empaquetar las imágenes en un nuevo **CBR/CBZ** según la extensión detectada inicialmente, reemplazando o creando un archivo optimizado.  
- Una vez realizado, elimina la carpeta **auxiliar** del archivo descomprimido.  

**Resultado visual de la estructura creada:**
C:\Comics
├── Comic1.cbr (45 MB) (Nuevo CBR generado)
├── Comic1.rar (120 MB) (CBR original renombrado a .RAR)
├── Comic2.cbz (95 MB) (Nuevo CBR generado)
├── Comic2.zip (95 MB) (CBZ original renombrado a .ZIP)

- Muestra un **resumen de los archivos procesados** y el resultado final.

---

## ✅ CONCLUSIÓN

Este script es una herramienta potente para **optimizar almacenamiento de cómics** en formato `.CBR`/`.CBZ`, manteniendo control sobre los archivos originales. Incluye:

- Validaciones  
- Limpieza de archivos innecesarios  
- Conversión segura de imágenes  
- Resumen visual del **ahorro de espacio**
