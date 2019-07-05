#
# Script generado por Javier Rodríguez para la subida de archivos a webpol de Becheckin
# 
# Para ejecutar el siguiente script es necesario tener la siguiente estructura:
# ./Carpeta/
#         /No subidos
#         /Subidos
#         /login.txt
#         /main.rb
#         /ejecutar.cmd
#
# Donde:
#   Carpeta: puede estar en cualquier ruta.
#   No subidos: contendrá los ficheros que van a ser subidos a webpol.
#   Subidos: Se crearán automáticamente las carpetas para cada cliente, 
#            y dentro de las mismas se encontrarán los ficheros que ya 
#            han sido escaneados y subidos a webpol
#   login.txt: Contiene todos los usuarios y contraseñas de los clientes 
#              para acceder a sus cuentas de webpol
#   main.rb: Script de ejecución en ruby.
#   ejecutar.cmd: Se encargará de ejecutar el script main.rb automáticamente.

require "watir"
require 'find'
require 'fileutils'

### DEFINICIÓN DE FUNCIONES

#Función para mover el archivo a la carpeta de archivos subidos
def mueveArchivo(archivo)
  dirname = './Subidos/'+File.basename(archivo, ".*")
  unless File.directory?(dirname)
    FileUtils.mkdir_p(dirname)
  end
  FileUtils.mv(archivo, dirname+'/'+File.basename(archivo))
end

def escaneaArchivos()
  puts "Escaneando archivos"
  # muestra la ruta ./
  # que es el directorio de Ruby
  Find.find('./No subidos') do |f|
      type = case
      # si la ruta es un fichero -> F
          when File.file?(f) then "F"
          # si la ruta es un directorio -> D
          when File.directory?(f) then "D"
          # si no sabemos lo que es -> ?
          else "?"
      end
    #Si se trata de un fichero, lo añadimos a la lista de ficheros a enviar
    if(type=="F")
      $archivos.push(f)
    end
  end
end

def leerArchivo(archivo)
  file = File.open(archivo, 'r+')
  file.each_line do |line|
    $usuario = line.split('|').at(1)
    $usuario = 'H'+$usuario
    break
  end
  file.close
end

def renombrarArchivo(archivo)
  nuevoNombre = File.dirname(archivo)+"/"+$nombreFichero
  if(archivo != nuevoNombre)
    FileUtils.mv(archivo, nuevoNombre)
  end
  return nuevoNombre
end

def incrementaAcierto()
  $progreso += 1
  $aciertos += 1
  puts "#{$progreso} de #{$archivos.length} archivos completados | #{$aciertos} con éxito | #{$fallos} con fallo "
end

def incrementaFallo()
  $progreso += 1
  $fallos += 1
  puts "#{$progreso} de #{$archivos.length} archivos completados | #{$aciertos} con éxito | #{$fallos} con fallo "
end

def obtenerLogin()
  file = File.open($login, 'r+')
  file.each_line do |line|
    if (line[$usuario])
      $password = line.split('=').last.chomp
      break
    end
  end
  file.close
end

def restaurarVariables()
  $usuario = ""
  $password = ""
  $nombreFichero = ""
end

def comprobarVersion()

  $b.goto "https://webpol.policia.es/e-hotel/#"
  sleep(1)
  $b.text_field(:id => "username").set $usuario
  $b.text_field(:id => "password").set $password
  $b.button(:id=> "loginButton").click
  $b.a(:id => "envioFicherosPrueba").click
  $nombreFichero = $b.span(:id => "msjNombreFichero").text.split(':').at(1)[1..-1]
end

def subirArchivo(archivo)
  $b.file_field(:id => "fichero").set File.absolute_path(archivo)
  sleep(1)
  $b.button(:id=> "btnEnvioFichero").click
  sleep(1)
end

def existeArchivo(archivo)
  dirname = './Subidos/'+File.basename(archivo, ".*")
  if File.directory?(dirname)
    if(File.file?(dirname+'/'+File.basename(archivo)))
      return true
    end
  end
  return false
end

def compruebaSubida()
  return $b.div(:id => "divMensajeGenerico").div( :class =>'alert-success').exist?
end

def init()

  # Definimos variables
  $login = "./login.txt"
  $archivos = Array.new
  $progreso = 0
  $fallos = 0
  $aciertos = 0
  $usuario = ""
  $password = ""
  $nombreFichero = ""
  $b = Watir::Browser.new :chrome

  # Escaneamos todos los archivos disponibles en "No subidos"
  escaneaArchivos()
  
  for archivo in $archivos;

    restaurarVariables()

    # Leemos el archivo para obtener el código de empresa
    leerArchivo(archivo)

    if(existeArchivo(archivo))
      incrementaFallo()
      next
    end

    obtenerLogin()

    if($usuario == "" || $password=="")
      incrementaFallo()
      next
    end
    
    # Accedemos a la web para ver cual debería ser el nombre del siguiente fichero
    comprobarVersion()

    # Renombramos el archivo con la versión obtenida en el paso anterior
    archivo = renombrarArchivo(archivo)

    # Subir archivo a webpol
    subirArchivo(archivo)

    # Comprobamos que se ha subido correctamente
    unless(compruebaSubida())
      incrementaFallo()
      next
    end

    # Una vez el proceso se haya completado, movemos el archivo a la carpeta "Subidos"
    mueveArchivo(archivo)
    incrementaAcierto()
  end
  
  puts "Script completado con éxito."
end

### FIN DEFINICIÓN DE FUNCIONES

init()