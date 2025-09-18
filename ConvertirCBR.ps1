# Funcion que renombra los archivos .CBR y .CBZ a .ZIP o .RAR
function RenombrarArchivosCBR {
	param (
		[System.IO.FileInfo]$archivo
	)
	
	# Detecta por los Magic Digits si el archivo es .RAR, .ZIP o Desconocido
	$extension = DetectarExtension -archivo $archivo
	
	# Si no deteca la extension lo omite
	if ($extension -ieq "Desconocido") {
		Write-Host "OMITIDO:" -NoNewline -ForegroundColor Yellow -BackgroundColor Black
		Write-Host " No se reconoce la extensión del archivo."
		return
	}

	# Renombra el archivo		
	$nuevoNombre = [System.IO.Path]::GetFileNameWithoutExtension($archivo.Name) + $extension
	try{
		Rename-Item -LiteralPath $archivo.FullName -NewName $nuevoNombre -ErrorAction Stop
		Write-Host "Renombrado:"
		Write-Host "    $($archivo.Name)" -ForegroundColor Green
		Write-Host " -> $nuevoNombre" -ForegroundColor Green
	} catch {
		Write-Host "ERROR:" -ForegroundColor DarkRed -BackgroundColor Black
		Write-Host " No se pudo renombrar el archivo: $($archivo.FullName)."
	}
}

# Funcion que detecta la extension real de un archivo a través de los Magic Digits
function DetectarExtension {
	param (
		[System.IO.FileInfo]$archivo
	)
	
	# Abre el archivo y lee sus primeros 4 digitas del codigo binario y los convierte a hexadecimal
	$stream = [System.IO.File]::OpenRead($archivo.FullName)
	$bytes = New-Object byte[] 4
	$stream.Read($bytes, 0, 4) | Out-Null
	$stream.Close()
	
	$hex = ($bytes | forEach-Object { "{0:X2}" -f $_ }) -join ''
	
	switch ($hex) {
		"504B0304" { return ".zip" }
		"52617221" { return ".rar" }
		default { return "Desconocido" }
	}
}

# Funcion que descomprime todos los archivos .ZIP en carpetas separadas
function DescomprimirArchivosZIP {
	param (
		[System.IO.FileInfo]$archivo
	)

	# Recoge el nombre del archivo para crear la carpeta correspondiente
	$carpetaDestino = [System.IO.Path]::GetFileNameWithoutExtension($archivo.Name)
	
	# Crea la carpeta de destino en caso de no existir
	if (-Not (Test-Path $carpetaDestino)) {
		New-Item -ItemType Directory -Path $carpetaDestino | Out-Null
	} else {
		Write-Host "OMITIDO:" -NoNewline -ForegroundColor Yellow -BackgroundColor Black
		Write-Host " Ya existe la carpeta $carpetaDestino."
		return
	}
	
	# Extrae el contenido del archivo comprimido
	Expand-Archive -LiteralPath $archivo -DestinationPath $carpetaDestino -Force
	
	Write-Host "Descomprimido: " -NoNewline
	Write-Host "$($archivo.Name)" -ForegroundColor Green
}

# Funcion que descomprime todos los archivos .RAR en carpetas separadas utilizando 7z
function DescomprimirArchivosRAR {
	param (
		[System.IO.FileInfo]$archivo,
		[string]$basePath
	)
	
	# Recoge el nombre del archivo para crear la carpeta correspondiente
	$carpetaDestino = [System.IO.Path]::GetFileNameWithoutExtension($archivo.Name)
	
	if (-Not (Test-Path $carpetaDestino)) {
		New-Item -ItemType Directory -Path $carpetaDestino | Out-Null
	} else {
		Write-Host "OMITIDO:" -NoNewline -ForegroundColor Yellow -BackgroundColor Black
		Write-Host " Ya existe la carpeta $carpetaDestino"
		return
	}
	
	# Extrae el contenido del archivo comprimido
	$sevenZip = Join-Path $basePath "7z.exe"
	if (-Not (Test-Path $sevenZip)) {
		Write-Host "ERROR:" -ForegroundColor DarkRed -BackgroundColor Black
		Write-Host "No existe 7z.exe"
		return
	} else {
		& $sevenZip x $archivo.FullName "-o$carpetaDestino" -y | Out-Null
		
		Write-Host "Descomprimido: " -NoNewline
		Write-Host "$($archivo.Name)" -ForegroundColor Green
	}
}

# Funcion que elimina las carpetas __MACOSX que se le pasa como parametro
function EliminarCarpetas {
	param (
		[System.IO.DirectoryInfo]$archivo
	)
	
	try {
		Remove-Item -LiteralPath $archivo.FullName -Recurse -Force -ErrorAction Stop
		Write-Host "Carpeta eliminada: " -NoNewline
		Write-Host "$($archivo.FullName)" -ForegroundColor Green
	} catch {
		Write-Host "ADVERTENCIA:" -NoNewline -ForegroundColor Yellow -BackgroundColor Black
		Write-Host " No se pudo eliminar la carpeta: $($archivo.FullName)."
	}
}

# Funcion que elimina los archivos .TXT que se le pasa como parametro
function EliminarArchivos {
	param (
		[System.IO.FileInfo]$archivo
	)
	
	try {
		Remove-Item -LiteralPath $archivo.FullName -Force -ErrorAction Stop
		Write-Host "Archivo eliminado: " -NoNewline
		Write-Host "$($archivo.FullName)" -ForegroundColor Green
	} catch {
		Write-Host "ADVERTENCIA:" -NoNewline -ForegroundColor Yellow -BackgroundColor Black
		Write-Host " No se pudo eliminar el archivo: $($archivo.FullName)."
	}
}

# Funcion que elimina los caracteres especiales [ ] { } %
function EliminarCaracteresEspeciales {
	param (
		[System.IO.FileSystemInfo]$archivo
	)
	
	$rutaAntigua = "\\?\$($archivo.FullName)"
	
	if ($archivo.PSIsContainer) {
		# En caso de ser un directorio
		$base = $archivo.Name
		$extension = ""
	} else {
		# En caso de ser un Archivo
		$base = $archivo.BaseName
		$extension = $archivo.Extension
	}
	
	# Renombra los caracteres especiales
	$baseNuevo = $base `
		-replace '[\[\]\{\}%&;!^~`"''<>:/\\\*\?]', '' `
		-replace '\s{2,}', ' ' `
		-replace 'Â', 'A' ` -replace 'â', 'a' `
		-replace 'Ê', 'E' ` -replace 'ê', 'e' `
		-replace 'Î', 'I' ` -replace 'î', 'i' `
		-replace 'Ô', 'O' ` -replace 'ô', 'o' `
		-replace 'Û', 'U' ` -replace 'û', 'u'
		
	$baseNuevo = $baseNuevo.TrimEnd()
	
	# Reconstruye
	$nombreNuevo = $baseNuevo + $extension
		
	if ($archivo.Name -ne $nombreNuevo) {
		try{
			Rename-Item -LiteralPath $rutaAntigua -NewName $nombreNuevo -ErrorAction Stop
			Write-Host "Recurso modificado: "
			Write-Host "    $($archivo.Name)" -ForegroundColor Green
			Write-Host " -> $nombreNuevo" -ForegroundColor Green
		} catch {
			Write-Host "ADVERTENCIA:" -NoNewline -ForegroundColor Yellow -BackgroundColor Black
			Write-Host " No se pudo modificar el recurso: $($archivo.Name)."
		}
	}
}

# Funcion que extrae el contenido de las subcarpetas a su carpeta padre
function ExtraerContenido {
	param (
		[System.IO.DirectoryInfo]$carpeta,
		[ref]$noProcesadas
	)
	
	Write-Host "Procesando: " -NoNewline
	Write-Host "$carpeta" -ForegroundColor Green
	
	# Obtener subcarpetas
	$subSubCarpetas = Get-ChildItem -Path $carpeta -Directory
	
	if ($subSubCarpetas.Count -eq 0) {
		Write-Host "   " -NoNewline
		Write-Host "OMITIDO:" -NoNewline -ForegroundColor Yellow -BackgroundColor Black
		Write-Host " No tiene subcarpetas`n"
		return
	}
	
	if ($subSubCarpetas.Count -gt 1) {
		Write-Host "   " -NoNewline
		Write-Host "OMITIDO:" -NoNewline -ForegroundColor Yellow -BackgroundColor Black
		Write-Host " Tiene mas de una subcarpeta`n"
		return
	}
	
	# Procesar si solo hay una carpeta
	$sub = $subSubCarpetas[0]
	Write-Host "   > Subcarpeta encontrada: " -NoNewline -ForegroundColor Cyan
	Write-Host "$($sub.Name)"
	
	# Mueve todo el contenido de la subcarpeta a su directorio padre
	$archivos = Get-ChildItem -Path $sub.FullName
	foreach ($archivo in $archivos) {
		$destino = Join-Path -Path $carpeta -ChildPath $archivo.Name
		
		if (Test-Path -Path $destino) {
			Write-Host "ADVERTENCIA:" -NoNewline -ForegroundColor Yellow -BackgroundColor Black
			Write-Host " El archivo ya existe en la ruta de destino."
		} else {
			Move-Item -Path $archivo.FullName -Destination $destino
		}
	}
	
	if (-not (Get-ChildItem -Path $sub.FullName -Force)) {
		Remove-Item -Path $sub.FullName -Force -Recurse
		Write-Host "   > Subcarpeta vacia: " -NoNewline -ForegroundColor Cyan
		Write-Host "Carpeta eliminada.`n"
	} else {
		Write-Host "   " -NoNewline
		Write-Host "ADVERTENCIA:" -NoNewline -ForegroundColor Yellow -BackgroundColor Black
		Write-Host " Aun quedan elementos en la subcarpeta. NO se eliminará por seguridad.`n"
	}
}

# Función para procesar una sola carpeta
function ProcesarImagenes {
    param (
        [System.IO.DirectoryInfo]$carpeta,
		[string]$ffmpeg,
		[ref]$errorCarpeta,
		$calidad
    )

	Write-Host "Procesando: " -NoNewline
    Write-Host "$carpeta" -ForegroundColor Yellow

    # Guardar ubicación actual y entrar en la carpeta destino
    Push-Location $carpeta.FullName

    # Obtener el nombre de la carpeta actual
    $carpetaActual = Split-Path -Leaf $PWD
    $searchPath = $PWD
	
    # Obtener archivos de imagen con extensiones específicas en carpeta actual
    $imagenes = Get-ChildItem -Path . -File | Where-Object {
        $_.Extension -match '\.(jpg|jpeg|tiff|tif|png|bmp|webp)$'
    }

    # Si no se encuentran imágenes, buscar la subcarpeta (debería haber 1)
    if ($imagenes.Count -eq 0) {
        $subfolders = Get-ChildItem -Directory

        if ($subfolders.Count -eq 1) {
            $subfolder = $subfolders[0].FullName
            $tempFolder = Join-Path $PWD "TEMP"

            # Renombrar la carpeta encontrada a TEMP
            Rename-Item -Path $subfolder -NewName "TEMP"
            $searchPath = $tempFolder

            # Buscar imágenes dentro de TEMP
            $imagenes = Get-ChildItem -Path $searchPath -File | Where-Object {
                $_.Extension -match '\.(jpg|jpeg|tiff|tif|png|bmp)$'
            }
        }
    }

    # Si sigue sin haber imágenes, abortar
    if ($imagenes.Count -gt 0) {
	    # Comprueba el numero de imágenes que hay en la carpeta y establece el contador a 0
		$total = $imagenes.Count
		$contador = 0
		
		# Crear carpeta WEBP con el mismo nombre que la carpeta actual en caso de no existir
		$carpetaWebP = Join-Path $PWD "$carpetaActual"
		if (!(Test-Path $carpetaWebP)) {
			New-Item -ItemType Directory -Path $carpetaWebP | Out-Null
		}
		
		# Convertir imagenes
		Write-Host "Convirtiendo páginas a .webp con 2000px y $calidad% de calidad" -ForegroundColor Green
		foreach ($imagen in $imagenes){
			$contador++
			$input = $imagen.FullName
			$output = Join-Path $carpetaWebP "$($imagen.BaseName).webp"
			
			& $ffmpeg -i "$input" -vf "scale=-1:2000" -c:v libwebp -quality $calidad "$output" *> $null

			Write-Host "($contador de $total) " -NoNewline -ForegroundColor Cyan
			Write-Host "Realizado: " -NoNewline
			Write-Host "$($imagen.Name)" -ForegroundColor Green
		}
		ProcesarCBR -carpetaWebP $carpetaWebP
		Pop-Location
    } else {
		$errorCarpeta.Value = 1
		Write-Host "OMITIDO:" -NoNewline -ForegroundColor Yellow -BackgroundColor Black
		Write-Host " No se han encontrado imágenes para procesar"
		Pop-Location
        return
	}
}

function ProcesarCBR {
	param (
		[string]$carpetaWebP
	)
	
    # Comprimir la carpeta a .ZIP
    Write-Host "`nComprimiendo a .ZIP ..." -ForegroundColor Cyan
	$carpetaZip = Split-Path $carpetaWebP -Leaf
    $archivoZip = Join-Path $PWD "$carpetaZip.zip"
    Compress-Archive -Path $carpetaWebP -DestinationPath $archivoZip -Force
    Write-Host ".ZIP creado" -ForegroundColor Green

    # Renombrar a .CBR
    $cbrFile = $archivoZip -replace '\.zip$', '.cbr'
    Rename-Item -Path $archivoZip -NewName $cbrFile -Force
    Write-Host "Renombrado a .CBR" -ForegroundColor Green

    # Mover a carpeta padre
    $parentFolder = Split-Path -Parent $PWD
    $destPath = Join-Path $parentFolder (Split-Path -Leaf $cbrFile)
    Move-Item -Path $cbrFile -Destination $destPath -Force
    Write-Host "Archivo .CBR movido`n" -ForegroundColor Green

    #Volver al directorio anterior
    Pop-Location
}

function VerificarTamaños {
	param (
		[System.IO.FileInfo]$archivoOriginal,
		[System.IO.FileInfo]$archivoModificado,
		[ref]$ahorroTotal
	)
	
	Write-Host "`nAhorro" -ForegroundColor Cyan
	Write-Host "Archivo Original: " -NoNewline
	Write-Host ("{0:N2} Mb" -f ($archivoOriginal.Length / 1MB)) -ForegroundColor Cyan
	Write-Host "Archivo Modificado: " -NoNewline
	Write-Host ("{0:N2} Mb <<<" -f ($archivoModificado.Length / 1MB)) -ForegroundColor Yellow
	$porcentaje = [math]::Round((($archivoOriginal.Length - $archivoModificado.Length) / $archivoOriginal.Length) * 100, 2)
	Write-Host "Reduccion: " -NoNewline
	Write-Host "$porcentaje %`n" -ForegroundColor Magenta
	
	$ahorroTotal.Value += $archivoOriginal.Length - $archivoModificado.Length
}

# ------------------------------------
#               MAIN
# ------------------------------------

# Recorre cada carpeta y convierte las imagenes en .webp reduciendo su resolucion a 1800px y a 80% de calidad. Vuelve a comprimir y .ZIP, renombra a .CBR y mueve el archivo a la carpeta principal.
Write-Host "=====================================================" -ForegroundColor DarkCyan
Write-Host " ConvertirCBR v0.86 by Daniel Amores" -ForegroundColor Yellow
Write-Host "-----------------------------------------------------" -ForegroundColor DarkCyan
Write-Host " Script en PowerShell para gestionar cómics:" -ForegroundColor Cyan
Write-Host " - Renombra .CBR/.CBZ según su formato real" -ForegroundColor Green
Write-Host " - Limpia archivos y carpetas innecesarias" -ForegroundColor Green
Write-Host " - Convierte imágenes a .webp optimizado" -ForegroundColor Green
Write-Host " - Recompone los archivos en .CBR ahorrando espacio" -ForegroundColor Green
Write-Host "=====================================================" -ForegroundColor DarkCyan
Write-Host ""

# Solicita al usuario la ruta
Write-Host "Introduzca la ruta absoluta: " -NoNewline -ForegroundColor Cyan
$ruta = Read-Host

if ([string]::IsNullOrWhiteSpace($ruta)) {
    Write-Host "No se ha introducido ninguna ruta. Operación cancelada.`n" -ForegroundColor Yellow
    exit
}

$ruta = $ruta.TrimEnd('\')
$ruta = $ruta.TrimEnd().ToLower()

$rutasNoPermitidas = @(
    "c:",
	"d:",
    "c:\windows",
    "c:\program files",
    "c:\program files (x86)",
    "c:\users"
)

if ($rutasNoPermitidas -contains $ruta) {
	Write-Host "Ruta no permitida. Operación cancelada.`n" -ForegroundColor Red
	exit
}

# Muestra el error en caso de escribir una ruta no valida
if (-Not (Test-Path -LiteralPath $ruta)) {
	Write-Host "ERROR:" -NoNewline -ForegroundColor DarkRed -BackgroundColor Black
	Write-Host " La carpeta '$ruta' no existe`n"
	return
}

# Solicita al usuario el porcentaje de calidad
Write-Host "Introduzca la calidad de imagen (1-100) (por defecto: 85): " -NoNewline -ForegroundColor Cyan
$calidad = Read-Host

if ([string]::IsNullOrWhiteSpace($calidad)) {
	$calidad = 85
}

if (-not [int]::TryParse($calidad, [ref]([int]0))) {
	Write-Host "ERROR:" -NoNewline -ForegroundColor DarkRed -BackgroundColor Black
	Write-Host " Debe introducir un número válido.`n"
	exit
}

# Resumen de operaciones
Write-Host "`n=== RESUMEN DE OPERACIONES ===" -ForegroundColor Yellow
Write-Host "Carpeta seleccionada: " -NoNewline
Write-Host "$ruta" -ForegroundColor Green
Write-Host "----------------------------------------" -ForegroundColor DarkGray
Write-Host "Se realizarán las siguientes operaciones:"
Write-Host "  - Normalización de los nombres de los archivos .CBR y .CBZ." -ForegroundColor Cyan
Write-Host "  - Renombrado de las extensiones .CBR y .CBZ a .RAR y .ZIP, detectando su extensión original." -ForegroundColor Cyan
Write-Host "  - Descompresión de los archivos .RAR y .ZIP en carpetas independientes." -ForegroundColor Cyan
Write-Host "  - Normalización y limpieza del contenido de cada carpeta:" -ForegroundColor Cyan
Write-Host "      - Eliminación de subcarpetas __MACOSX." -ForegroundColor DarkCyan
Write-Host "      - Eliminación de archivos .txt y Thumbs.db." -ForegroundColor DarkCyan
Write-Host "      - Eliminación de archivos .jpg con nombre _zz_ o _xx_ correspondientes a publicidad." -ForegroundColor DarkCyan
Write-Host "      - Eliminación de caracteres especiales como [], {}, %, etc." -ForegroundColor DarkCyan
Write-Host "      - Movimiento del contenido de subcarpetas internas a la carpeta principal." -ForegroundColor DarkCyan
Write-Host "      - Eliminación de subcarpetas vacías." -ForegroundColor DarkCyan
Write-Host "  - Conversión de imágenes .jpg a formato WebP (más óptimo), con resolución de 2000px y calidad al $($calidad)% respecto a la original." -ForegroundColor Cyan
Write-Host "  - Creación del nuevo archivo .CBR." -ForegroundColor Cyan
Write-Host "  - Cálculo de la diferencia de tamaño entre el archivo original y el nuevo." -ForegroundColor Cyan
Write-Host "  - Eliminación de la carpeta con el contenido descomprimido." -ForegroundColor Cyan
Write-Host "  - Informe al usuario del total de espacio ahorrado." -ForegroundColor Cyan

Write-Host "`nPara comenzar la operación, pulse cualquier tecla..."
[void][System.Console]::ReadKey($true)

# Carpeta base donde se ejecuta el script
$basePath = Get-Location

# Cambia de carpeta a la de la ruta
Set-Location -LiteralPath $ruta


# -------------------------------------------------------
# RENOMBRAR ARCHIVOS .CBR Y .CBZ
Write-Host "`nRENOMBRANDO ARCHIVOS .CBR y .CBZ" -ForegroundColor Yellow

# Obtener todos los archivos .CBR y .CBZ de la carpeta
$archivos = Get-ChildItem -LiteralPath $ruta -File | Where-Object { $_.Extension -match '\.cb[rz]$' }

# Normalizar
Write-Host "Normalizando" -ForegroundColor Cyan
if ($archivos.Count -gt 0) {
	foreach ($archivo in $archivos) {
		EliminarCaracteresEspeciales -archivo $archivo
	}
}
Write-Host "COMPLETADO" -ForegroundColor Green

# Obtener nuevamente todos los archivos .CBR y .CBZ de la carpeta ya normalizados
$archivos = Get-ChildItem -LiteralPath $ruta -File | Where-Object { $_.Extension -match '\.cb[rz]$' }

# Renombrar cada uno a .RAR
Write-Host "`nRenombrando" -ForegroundColor Cyan
if ($archivos.Count -gt 0) {
	$totalArchivos = 1
	foreach ($archivo in $archivos) {
		Write-Host "$($totalArchivos)/$($archivos.Count) " -NoNewline -ForegroundColor Cyan
		RenombrarArchivosCBR -archivo $archivo
		$totalArchivos++
	}
	Write-Host "COMPLETADO" -ForegroundColor Green
} else {
	Write-Host ">>> No se han encontrado archivos .CBR ni .CBZ" -ForegroundColor Red
}

# -------------------------------------------------------
# DESCOMPRIMIR ARCHIVOS .RAR y .ZIP
Write-Host "`nDESCOMPRIMIENDO archivos .RAR y .ZIP a carpetas separadas" -ForegroundColor  Yellow

# Obtener los archivos .ZIP de la carpeta
$archivos = Get-ChildItem -LiteralPath $ruta -File -Filter *.zip

# Descomprimir cada archivo .ZIP a su propia carpeta
Write-Host "Archivos .ZIP" -ForegroundColor Cyan
if ($archivos.Count -gt 0) {
	$totalArchivos = 1
	foreach ($archivo in $archivos) {
		Write-Host "$($totalArchivos)/$($archivos.Count) " -NoNewline -ForegroundColor Cyan
		DescomprimirArchivosZIP -archivo $archivo
		$totalArchivos++
	}
	Write-Host "COMPLETADO" -ForegroundColor Green
} else {
	Write-Host ">>> No se han encontrado archivos .ZIP" -ForegroundColor Red
}

# Obtener los archivos .RAR de la carpeta
$archivos = Get-ChildItem -LiteralPath $ruta -File -Filter *.rar

# Descomprimir cada archivo .RAR a su propia carpeta
Write-Host "`nArchivos .RAR" -ForegroundColor Cyan
if ($archivos.Count -gt 0){
	$totalArchivos = 1
	foreach ($archivo in $archivos) {
		Write-Host "$($totalArchivos)/$($archivos.Count) " -NoNewline -ForegroundColor Cyan
		DescomprimirArchivosRAR -archivo $archivo -basePath $basePath
		$totalArchivos++
	}
	Write-Host "COMPLETADO" -ForegroundColor Green
} else {
	Write-Host ">>> No se han encontrado archivos .RAR" -ForegroundColor Red
}


# -------------------------------------------------------
# REEMPLAZAR SIMBOLOS [ ] { } %, ELIMINACION DE ARCHIVOS DE PUBLICIDAD ..ZZ.., ELIMINACION DE CARPETAS __MACOSX, ELIMINACION DE ARCHIVOS .TXT
Write-Host "`nSANEAR Y NORMALIZAR CONTENIDOS" -ForegroundColor Yellow

# Eliminacion de __MACOSX
Write-Host "Eliminación de carpetas __MACOSX" -ForegroundColor Cyan

# Obtiene todos los archivos
$archivos = Get-ChildItem -Recurse -Directory -Force | Where-Object { $_.Name -ieq '__MACOSX' }

# Elimina las carpetas __MACOSX
if ($archivos.Count -gt 0) {
	$totalArchivos = 1
	foreach ($archivo in $archivos) {
		Write-Host "$($totalArchivos)/$($archivos.Count) " -NoNewline -ForegroundColor Cyan
		EliminarCarpetas -archivo $archivo
		$totalArchivos++
	}
	Write-Host "COMPLETADO" -ForegroundColor Green
} else {
	Write-Host ">>> No se han encontrado carpetas __MACOSX" -ForegroundColor Red
}


# -------------------------------------------------------
# Eliminacion de archivos .TXT
Write-Host "`nEliminación de archivos .TXT y Thumbs.db" -ForegroundColor Cyan

# Obtiene todos los archivos
$archivos = Get-ChildItem -Recurse -File -Force | Where-Object { $_.Extension -match '\.txt' -or $_.Name -match '^thumbs\.db$' }

#Elimina los archivos .TXT
if ($archivos.Count -gt 0) {
	$totalArchivos = 1
	foreach ($archivo in $archivos) {
		Write-Host "$($totalArchivos)/$($archivos.Count) " -NoNewline -ForegroundColor Cyan
		EliminarArchivos -archivo $archivo
		$totalArchivos++
	}
	Write-Host "COMPLETADO" -ForegroundColor Green
} else {
	Write-Host ">>> No se han encontrado archivos .TXT ni Thumbs.db" -ForegroundColor Red
}


# -------------------------------------------------------
# Eliminacion de archivos .JPG con nombres _zz_
Write-Host "`nEliminación de archivos .JPG con nombres _zz_ y _xx_ (Publicidad)" -ForegroundColor Cyan

# Obtiene todos los archivos
$archivos = Get-ChildItem -Recurse -File -Force | Where-Object { $_.Extension -match '\.jpg' -and ($_.BaseName -like 'zz*' -or $_.BaseName -like 'xx*') }

# Elimina los archivos .JPG que contengan ZZ en el nombre de archivo (son imagenes de publicidad)
if ($archivos.Count -gt 0) {
	$totalArchivos = 1
	foreach ($archivo in $archivos) {
		Write-Host "$($totalArchivos)/$($archivos.Count) " -NoNewline -ForegroundColor Cyan
		EliminarArchivos -archivo $archivo
		$totalArchivos++
	}
	Write-Host "COMPLETADO" -ForegroundColor Green
} else {
	Write-Host ">>> No se han encontrado archivos .JPG que contengan ZZ ni XX" -ForegroundColor Red
}


# -------------------------------------------------------
# Eliminacion de caracteres especiales [ ] { } % etc
Write-Host "`nEliminación de caracteres especiales [] {} % etc" -ForegroundColor Cyan

# Obtiene todos los archivos
$archivos = Get-ChildItem -Recurse -Force

# Elimina los caracteres especiales [ ] { } %
if ($archivos.Count -gt 0) {
	foreach ($archivo in $archivos){
		EliminarCaracteresEspeciales -archivo $archivo
	}
	Write-Host "COMPLETADO" -ForegroundColor Green
} else {
	Write-Host ">>> No se han encontrado archivos que contengan caracteres especiales [ ] { } %" -ForegroundColor Red
}


# -------------------------------------------------------
# Extraer contenido de subcarpetas a carpeta padre de cada comic
Write-Host "`nEXTRAER CONTENIDO DE CADA CARPETA" -ForegroundColor Yellow

# Obtiene todos los directorios
$carpetas = Get-ChildItem -Directory

# Comprueba cada directorio
if ($carpetas.Count -gt 0) {
	$totalCarpetas = 1
	$noProcesadas = @()
	foreach ($carpeta in $carpetas){
		Write-Host "$($totalCarpetas)/$($carpetas.Count) " -NoNewline -ForegroundColor Cyan
		ExtraerContenido -carpeta $carpeta -noProcesadas ([ref]$noProcesadas)
		$totalCarpetas++
	}
	
	if ($noProcesadas.Count -gt 0){
		Write-Host "Carpetas no procesadas: (Total: $($noProcesadas.Count))" -ForegroundColor Cyan
		foreach ($noProcesada in $noProcesadas){
			Write-Host "$noProcesada"
		}
	}
	Write-Host "COMPLETADO" -ForegroundColor Green
} else {
	Write-Host ">>> No se han encontrado directorios que contengan subdirectorios" -ForegroundColor Red
}


# -------------------------------------------------------
# Procesar imagenes a resolucion 1800 de altura con ancho automatico y calidad al 80%, convirtiendolas en webp
Write-Host "`nPROCESANDO IMÁGENES" -ForegroundColor Yellow

# Procesar cada subcarpeta
if ($carpetas.Count -gt 0) {
	$ahorroTotal = 0
	
	$totalCarpetas = 1
	foreach ($carpeta in $carpetas) {
		$errorCarpeta = 0
		Write-Host "$($totalCarpetas)/$($carpetas.Count) " -NoNewline -ForegroundColor Cyan
		$ffmpeg = Join-Path $basePath "ffmpeg.exe"
		ProcesarImagenes -carpeta $carpeta -ffmpeg $ffmpeg -errorCarpeta ([ref]$errorCarpeta) -calidad $calidad
		
		# Elimina la carpeta descomprimida
		if ((Test-Path -LiteralPath $carpeta.FullName) -and ($errorCarpeta -eq 0)){
			Remove-Item $carpeta.FullName -Recurse -Force
			Write-Host "Carpeta auxiliar eliminada." -ForegroundColor Cyan
		}
		
		# Comprobar diferencia de tamaño
		$archivoOriginal = Get-ChildItem | Where-Object { $_.BaseName -eq $carpeta.Name -and $_.Extension -in @(".zip", ".rar") }
		$archivoModificado = Get-ChildItem | Where-Object { $_.BaseName -eq $carpeta.Name -and $_.Extension -eq ".cbr" }
		if ($archivoOriginal -and $archivoModificado) {
			VerificarTamaños -archivoOriginal $archivoOriginal -archivoModificado $archivoModificado -ahorroTotal ([ref]$ahorroTotal)
		} else{
			Write-Host "No existen los archivos`n"
		}
		$totalCarpetas++
	}
} else {
    Write-Host ">>> No se encontraron carpetas para procesar en: $ruta" -ForegroundColor Red
}

# Muestra el resumen final
Write-Host ">>> TODOS LOS PROCESOS COMPLETADOS" -ForegroundColor Yellow
Write-Host "Ahorro Total: " -NoNewLine
Write-Host ("{0:N2} Mb`n" -f ($ahorroTotal / 1MB)) -ForegroundColor Cyan