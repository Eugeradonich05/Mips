.data
# Variables y estructuras de datos
slist: .word 0
cclist: .word 0
wclist: .word 0
categoryCount: .word 0
idCount: .word 1
schedv: .space 32
almacenamiento: .space 50
# Mensajes
menu: .ascii "Colecciones de objetos categorizados\n"
      .ascii "====================================\n"
      .ascii "1-Nueva categoria\n"
      .ascii "2-Siguiente categoria\n"
      .ascii "3-Categoria anterior\n"
      .ascii "4-Listar categorias\n"
      .ascii "5-Borrar categoria actual\n"
      .ascii "6-Anexar objeto a la categoria actual\n"
      .ascii "7-Listar objetos de la categoria\n"
      .ascii "8-Borrar objeto de la categoria\n"
      .asciiz "0-Salir\n"
enterOp: .asciiz "Ingrese la opcion: "
selectCategory: .asciiz ">"
error: .asciiz "Error:"
opcionInvalida: .asciiz "Opcion incorrecta.\n"
return: .asciiz "\n"
catName: .asciiz "Ingrese el nombre de la categoria: "
selCat: .asciiz "Se ha seleccionado la categoria: "
idObj: .asciiz "Ingrese el ID del objeto a eliminar: "
objName: .asciiz "Ingrese el nombre de un objeto: "
success: .asciiz "La operación se realizó con éxito.\n"
msgFaltaAlmacenamiento: .asciiz "No hay memoria!!\n"
errorCategorySelec: .asciiz "No hay categoria selecionada\n"
successDeleteCategory: .asciiz "Se elimino correctamente la categoria!!\n"
catAcatual: .asciiz "--Lista de objetos de la categoria--> "
.text
.globl main

# Programa principal
main:
    # Inicializacion de las listas
    la $t0, slist
    li $t1, 0
    sw $t1, 0($t0)
    la $t0, cclist
    li $t1, 0
    sw $t1, 0($t0)
    la $t0, wclist
    li $t1, 0
    sw $t1, 0($t0)

    # Inicializar vector de funciones
    la $t0, schedv
    la $t1, newcategory
    sw $t1, 0($t0)
    la $t1, nextcategory
    sw $t1, 4($t0)
    la $t1, prevcategory
    sw $t1, 8($t0)
    la $t1, listcategory
    sw $t1, 12($t0)
    la $t1, delcategory
    sw $t1, 16($t0)
    la $t1, addobject
    sw $t1, 20($t0)
    la $t1, listobject
    sw $t1, 24($t0)
    la $t1, delobject
    sw $t1, 28($t0)

    # Menú inicial
    li $v0, 4
    la $a0, menu
    syscall

loop:
    # Ingresa opcion
    li $v0, 4
    la $a0, enterOp
    syscall
    li $v0, 5
    syscall
    move $t2, $v0  # Guardar opción ingresada

    # Validacion de la op
    beqz $t2, exitmenu  #  ? si la opción es 0
    bltz $t2, invalid_option	# ? si es menor q 0
    li $t3, 9
    bge $t2, $t3, invalid_option 
    sub $t2, $t2, 1	
    
    # Ejecutar función correspondiente
    li $t3, 4
    mul $t4, $t2, $t3
    la $t0, schedv
    add $t0, $t0, $t4
    lw $t1, 0($t0)
    jalr $t1
    j loop

#Msj error por ingresar una opcion no valida
invalid_option:
    li $v0, 4
    la $a0, error
    syscall
    
    li $v0, 4
    la $a0, opcionInvalida
    syscall
    
    j loop
   #salida del programa
exitmenu:
    li $v0, 10
    syscall
    #funcion q reserva espacio
smalloc:
    lw $t0, slist          # Cargar la lista libre
    beqz $t0, sbrk    # Si está vacía, llamar a sbrk
    move $v0, $t0          # Retornar dirección del nodo disponible
    lw $t0, 12($t0)        # Actualizar slist al siguiente nodo libre
    sw $t0, slist
    jr $ra                 # Retornar
# Implementación de sbrk para reservar espacio en el heap
sbrk:
    li $a0, 16             # Tamaño del nodo (4 palabras)
    li $v0, 9              # Syscall para asignar memoria
    syscall
    jr $ra     
   #libera memoria
sfree: 
	lw  $t0, slist
	sw $t0, 12($a0)
	sw $a0, slist
	jr $ra

# Crear nueva categoría
newcategory:
    addiu $sp, $sp, -8    # Reservar espacio en el stack
    sw $ra, 0($sp)        # Guardar el valor de retorno

    # Asignar nodo con smalloc
    jal smalloc
    move $t1, $v0         # Dirección del nuevo nodo en t1 con memoria en el heap

    # Solicitar el nombre de la categoría
    li $v0, 4
    la $a0, catName
    syscall
    li $v0, 8
    la $a0, almacenamiento	
    li $a1, 49		#catidad maxima de caracteres
    syscall

    # Asignar memoria para el nombre de la categoría
    li $v0, 9
    li $a0, 50
    syscall
    move $t2, $v0         # Dirección del nombre de categoria en $t2

    # Copiar el nombre desde el almacenamiento
    la $t3, almacenamiento #carga la direccion de la palabra
    move $t4, $t2	#t4 tiene la direccion del nombre de la categoria

copyname:
    lb $t0, 0($t3)	#carga la palabra caracter por caracter
    sb $t0, 0($t4) 	#almacena la palabra caracter por caracter en $t4
    beqz $t0, endcopy
    addiu $t3, $t3, 1
    addiu $t4, $t4, 1
    j copyname

endcopy:                                            
    # Guardar el nombre en el nodo
    sw $0, 4($t1)      # Guardar la direccion de la lista de objetos (0 por defecto)
    sw $t2, 8($t1)        # Guardar la dirección del nombre en el nodo

    # Configurar la lista circular
    lw $t3, cclist        # Cargar la lista actual
    beqz $t3, emptylist   # Si la lista está vacía, inicializarla

    # Conectar el nuevo nodo en la lista para crear una lista doblemente enlazada
    lw $t4, 0($t3)        # apunta al ultimo nodo, el anterior al primer	
    sw $t4, 0($t1)        #el anterior del nuevo nodo aputn al ultimo nodo
    sw $t1, 12($t4)       # siguiente del último nodo apunta al nuevo nodo
    sw $t3, 12($t1)       # siguiente del nuevo nodo apunta al primero
    sw $t1, 0($t3)        # el anterior del primero apunta al nuevo nodo
    j setcurrent

emptylist:
    # Si la lista está vacía, el nuevo nodo apunta a sí mismo
    sw $t1, cclist        # Actualizar cclist con el nuevo nodo
    sw $t1, 0($t1)        # el anteriori apunta a sí mismo
    sw $t1, 12($t1)       # el siguiente  apunta a sí mismo
    sw $t1, wclist
setcurrent:
    # Incrementar el contador de nodos
    lw $t5, categoryCount
    addi $t5, $t5, 1      
    sw $t5, categoryCount    
   
    # Mensaje de éxito
    la $a0, success
    li $v0, 4
    syscall

    lw $ra, 0($sp)        # Restaurar $ra
    lw $a0, 4($sp)        # Restaurar $a0
    addiu $sp, $sp, 8     # Restaurar el stack
    jr $ra                # Retornar

errorspacefull:
    # Mostrar mensaje de error por falta de almacenamiento
    li $v0, 4
    la $a0, error
    syscall

    li $v0, 4
    la $a0, msgFaltaAlmacenamiento         
    syscall

    li $v0, 4
    la $a0, return
    syscall

    lw $ra, 0($sp)        # Restaurar $ra
    addiu $sp, $sp, 8     # Restaurar el stack
    jr $ra                # Retornar
listcategory:
    addiu $sp, $sp -8
    sw $ra, 0($sp)
    
    lw $t0, cclist  	#carga el valor de la lsita
    beqz $t0, error301 	#? si eta vacia va al error
    lw $t3, wclist	#carga el valor de la lista actual
    move $t1, $t0	#t1 y t5 tiene la dirccion de la lista
    move $t5, $t0	
        
listloop:
    beq $t1, $t3, printselectCategory	 
    li $v0, 4	
    lw $a0, 8($t1)
    syscall  # imprime la categoria seleccionada
    
    li $v0, 4
    la $a0, return
    syscall
travelloop:        
    lw $t1, 12($t1)  # actualiza a la siguiente lista
    bne $t1, $t5, listloop # si la siguiente categoria es igual a la que se imprimio, termina el recorrido
    j endlist
printselectCategory:
    #Imprime la categoria que esta en curso
    li $v0, 4
    la $a0, selectCategory
    syscall
    
    li $v0, 4
    lw $a0, 8($t3)
    syscall
    
    li $v0, 4
    la $a0, return
    syscall
    
    j travelloop	     	     	     	     	     	     	     	     
error301:
   # Mostrar mensaje de error	 
    li $v0, 4
    la $a0, error
    syscall 
    
    li $v0, 1
    li $t1, 301
    move $a0, $t1
    syscall
    
    li $v0, 4
    la $a0, return
    syscall
   
   #restaura todo para vovler al menu
endlist:
   lw $ra, 0($sp)
   addiu $sp, $sp, 8
   jr $ra 
   
nextcategory:
    addiu $sp, $sp, -4
    sw $ra, 0($sp)

    # Cargar la dirección de la categoría actual de la lista de categorías actuales
    lw $t0, wclist
    beqz $t0, error201  # Si no hay categoría actual, mostrar error

    # Obtener la dirección del siguiente nodo
    lw $t1, 12($t0)  # $t1 = siguiente nodo de la categoría actual
    beq $t1, $t0, error202  # si el siguiente es el mismo, dara error

    # Actualizar la categoría actual a la siguiente
    sw $t1, wclist

    # Mostrar mensaje de éxito
    la $a0, selCat
    li $v0, 4
    syscall
    
   # Cargar el nombre de la nueva categoría seleccionada 
   lw $t6, 8($t1) # $t6 es el nombre de la categoría en el nuevo nodo seleccionado
    # Imprimir el nombre de la nueva categoría
   li $v0, 4 
   move $a0, $t6 
   syscall 
   
   li $v0, 4 
   la $a0, return 
   syscall
   
   j endselectcat

error201:
    # Mostrar mensaje de error
    li $v0, 4
    la $a0, error
    syscall 
    
    li $v0, 1
    li $t1, 201
    move $a0, $t1
    syscall
    
    li $v0, 4
    la $a0, return
    syscall
	
    j endselectcat
error202:
    # Mostrar mensaje de error
    li $v0, 4
    la $a0, error
    syscall 
    
    li $v0, 1
    li $t1, 202
    move $a0, $t1
    syscall
    
    li $v0, 4
    la $a0, return
    syscall      
    #restaura todo para vovler al menu    
endselectcat:
    lw $ra, 0($sp)
    addiu $sp, $sp, 4
    jr $ra	      
prevcategory:
    addiu $sp, $sp, -4
    sw $ra, 0($sp)

    # Cargar la dirección de la categoría actual de la lista de categorías actuales
    lw $t0, wclist
    beqz $t0, error201  # Si no hay categoría actual, mostrar error

    # Obtener la dirección del siguiente nodo
    lw $t1, 0($t0)  # $t1 = anterior nodo de la categoría actual
    beq $t1, $t0, error202  # si el siguiente es el mismo, dara error

    # Actualizar la categoría actual a la siguiente
    sw $t1, wclist
    # Mostrar mensaje de éxito
    la $a0, selCat
    li $v0, 4
    syscall
    
   # Cargar el nombre de la nueva categoría seleccionada 
   lw $t6, 8($t1) # $t6 = nombre de la categoría en el nuevo nodo seleccionado
    # Imprimir el nombre de la nueva categoría seleccionada 
   li $v0, 4 
   move $a0, $t6 
   syscall 
   
   li $v0, 4 
   la $a0, return 
   syscall
   
   j endselectcat
delcategory:
    # Verificar si hay una categoría seleccionada
    lw $t0, wclist      # Cargar la categoría seleccionada
    beqz $t0, error401

    # Obtener la lista de objetos asociada a la categoría
    lw $t1, 4($t0)      # Cargar el puntero a la lista de objetos
    beqz $t1, skipObjectDeletion  # Si no hay objetos, saltar al siguiente paso

deleteObjectsLoop:
    lw $t2, 4($t1)      # Obtener el siguiente objeto en la lista
    move $a0, $t1       # Pasar el puntero del objeto actual a sfree
    jal sfree           # Llamar a la función sfree para liberar el objeto
    move $t1, $t2       # Avanzar al siguiente objeto
    bnez $t1, deleteObjectsLoop  # Repetir si aún hay objetos

skipObjectDeletion:
    # Ajustar los punteros de las categorías
    lw $t3, 0($t0)      # Cargar el puntero anterior de la categoría
    lw $t4, 4($t0)      # Cargar el puntero siguiente de la categoría

    # Actualizar al siguiente del nodo anterior
    beqz $t3, updateNextPointer  # ? no hay nodo anterior, saltar
    sw $t4, 4($t3)

updateNextPointer:
    # Actualizar el `prev` del nodo siguiente
    beqz $t4, finalizeCategoryDeletion  # ? no hay nodo siguiente, saltar
    sw $t3, 0($t4)

finalizeCategoryDeletion:
    move $a0, $t0       # Pasar el puntero de la categoría seleccionada a sfree
    jal sfree           # Llamar a la función sfree para liberar la categoría

    # Restablecer el puntero de categoría seleccionada
    li $t0, 0           # wclist = NULL
    sw $t0, wclist

    # Mostrar mensaje de éxito solo una vez
    la $a0, successDeleteCategory
    li $v0, 4
    syscall
# Regresar al punto de llamada
    jr $ra              

 error401:
 	li $v0, 4
 	la $a0, error
 	syscall
	li $a0,401
	li $v0, 1
	syscall
	li $v0, 4
	la $a0, return
	syscall
delobject:    
    # Implementar lógica para borrar objeto
    jr $ra
addobject:
    addiu $sp, $sp, -8
    sw $ra, 0($sp)

    # Verificar si hay una categoría seleccionada
    lw $t0, wclist
    beqz $t0, errorIndexObj

    # Solicitar el nombre del objeto
    li $v0, 4
    la $a0, objName
    syscall

    li $v0, 8
    la $a0, almacenamiento
    li $a1, 49
    syscall

    # Asignar memoria para el nombre del objeto
    
    li $v0, 9
    li $a0, 12
    syscall
    move $t1, $v0         # Dirección del nombre del objeto en $t1
	
	sw $zero, 0($t1) # prev = NULL
	sw $zero, 4($t1) # next = NULL
    
    
li $a0, 50
li $v0, 9
syscall
move $t2, $v0    # Dirección del string

# Copiar el contenido del almacenamiento al espacio reservado
la $t3, almacenamiento   # Dirección del almacenamiento de entrada


copyobjname:
    lb $t4, 0($t3)    # Leer byte del almacenamiento
    sb $t4, 0($t2)    # Escribir byte en la memoria reservada
    beqz $t4, endcopyobj
    addiu $t3, $t3, 1
    addiu $t2, $t2, 1
    j copyobjname

endcopyobj:
    # Almacenar el puntero del nombre en el nodo (offset 8)
    sw $v0, 8($t1)    # Guardar la dirección del string en el nodo
    
    
    

copynodoname:
   # Conectar el objeto en la lista
lw $t4, 4($t0)       # Dirección del inicio de la lista de objetos
beqz $t4, createobjectlist

lw $t5, 0($t4)       # Último objeto de la lista
sw $t5, 0($t1)       # "prev" del nuevo objeto apunta al último
sw $t1, 4($t5)       # "next" del último apunta al nuevo
sw $t4, 4($t1)       # "next" del nuevo apunta al primero
sw $t1, 0($t4)       # "prev" del primero apunta al nuevo

j endaddobject



createobjectlist:
    # Crear una nueva lista si no existe
    sw $t1, 4($t0)        # Guardar el inicio de la lista de objetos en la categoría
    sw $t1, 0($t1)        # "prev" del objeto apunta a sí mismo
    sw $t1, 4($t1)        # "next" del objeto apunta a sí mismo

endaddobject:
    # Mostrar mensaje que se cargo correcatamente
    la $a0, success
    li $v0, 4
    syscall

   #lw $t2, 8($t1)
   #li $v0,4
   #move $a0, $t2
   #syscall
   
   #restaura todo para vovler al menu
     lw $ra, 0($sp)
    addiu $sp, $sp, 8
   
    
      jr $ra
   
errorIndexObj:
# Mostrar mensaje de error
    la $a0, error
    li $v0, 4
    syscall
    li $a0, 501
    li $v0,1
    syscall
    li $v0, 4
    la $a0,return
    syscall
    jr $ra
   

listobject:
   addiu $sp, $sp, -8
    sw $ra, 0($sp)

    # Verificar si hay una categoría seleccionada
    lw $t0, wclist
    beqz $t0, errorCategorySelecs
	
	#msj para ver la categoria q esta
	li $v0, 4
	la $a0,catAcatual
	syscall
	
	#Nombre de categoria
	lw $t5, 8($t0)
	move $a0, $t5
	li $v0, 4
	syscall


    # Cargar la lista de objetos de la categoría
    lw $t1, 4($t0)
    beqz $t1, errorobjeto  # Si no hay objetos, mostrar error

    # Guardar la dirección del inicio de la lista
    move $t2, $t1

#loop para imprimri los objetis
listloopobjects:
    # Imprimir el nombre del objeto actual
    li $v0, 4
    lw $a0, 8($t1)
    syscall

    # Avanzar al siguiente objeto
    lw $t1, 4($t1)  # "next"
    beq $t1, $t2, endlistobjects  # Si volvemos al inicio, terminamos

    j listloopobjects


errorCategorySelecs:
    # Mostrar mensaje de error
    la $a0, error
    li $v0, 4
    syscall
    li $a0, 601
    li $v0,1
    syscall
    li $v0, 4
    la $a0,return
    syscall
    j endlistobjects


errorobjeto:
    # Mostrar mensaje de error
    la $a0, error
    li $v0, 4
    syscall
    li $a0, 602
    li $v0,1
    syscall
    li $v0, 4
    la $a0,return
    syscall
    j endlistobjects

endlistobjects:
    lw $ra, 0($sp)
    addiu $sp, $sp, 8
    jr $ra
