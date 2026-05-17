Stack_Size      EQU     0x00000400

                AREA    STACK, NOINIT, READWRITE, ALIGN=4
Stack_Mem       SPACE   Stack_Size
__initial_sp


Heap_Size       EQU     0x00000400 							
                AREA    HEAP, NOINIT, READWRITE, ALIGN=4
__heap_base
Heap_Mem        SPACE   Heap_Size
__heap_limit


; Vector Table Mapped to Address 0 at Reset

						PRESERVE8
                		THUMB

        				AREA	RESET, DATA, READONLY
        				EXPORT 	__Vectors
					
__Vectors		    	DCD		0x00003FFC
        				DCD		Reset_Handler
        				DCD		0  			
        				DCD		0
        				DCD		0
        				DCD		0
        				DCD		0
        				DCD		0
        				DCD		0
        				DCD		0
        				DCD		0
        				DCD 	0
        				DCD		0
        				DCD		0
        				DCD 	0
        				DCD		0
        				
        				; External Interrupts
						; IRQ0 -> Timer interrupt
						; IRQ1 -> UART interrupt
						; IRQ2 -> GPIO interrupt
						        				
        				DCD		Timer_Handler
        				DCD		UART_Handler
        				DCD		GPIO_Handler
        				DCD		0
        				DCD		0
        				DCD		0
        				DCD		0
        				DCD		0
        				DCD		0
        				DCD		0
        				DCD		0
        				DCD		0
        				DCD		0
        				DCD		0
        				DCD		0
        				DCD		0
              
                AREA |.text|, CODE, READONLY
;Reset Handler
Reset_Handler   PROC
                GLOBAL Reset_Handler
                ENTRY
				IMPORT  __main
                LDR     R0, =__main               
                BX      R0                        ;Branch to __main
                ENDP

Timer_Handler   PROC
                EXPORT Timer_Handler
				IMPORT Timer_ISR
                PUSH    {R0,R1,R2,LR}
				BL Timer_ISR
                POP     {R0,R1,R2,PC}                    ;return
                ENDP

UART_Handler    PROC
                EXPORT UART_Handler
				IMPORT UART_ISR
                PUSH    {R0,R1,R2,LR}
				BL UART_ISR
                POP     {R0,R1,R2,PC}
                ENDP

;--------------------------------------------------------
; When a GPIO interrupt occurs, the Cortex-M0
; jumps here first.
;
; The handler saves temporary registers onto the stack,
; calls the C function GPIO_ISR(), then restores the
; registers before returning from the interrupt.
;
; Actual Connect Four GPIO logic is implemented in C:
;   - SW0-SW6 : select Connect Four columns
;   - SW7     : request game reset
;--------------------------------------------------------					
GPIO_Handler    PROC
                EXPORT GPIO_Handler
				IMPORT GPIO_ISR
				
				; Save working registers and return address
                PUSH    {R0,R1,R2,LR}
				
				; Call C GPIO interrupt service routine
				BL GPIO_ISR
				
				; Restore registers and return from interrupt
                POP     {R0,R1,R2,PC}
                ENDP					

				ALIGN 		4					 ; Align to a word boundary

; User Initial Stack & Heap
                IF      :DEF:__MICROLIB
                EXPORT  __initial_sp
                EXPORT  __heap_base
                EXPORT  __heap_limit
                ELSE
                IMPORT  __use_two_region_memory
                EXPORT  __user_initial_stackheap
__user_initial_stackheap

                LDR     R0, =  Heap_Mem
                LDR     R1, =(Stack_Mem + Stack_Size)
                LDR     R2, = (Heap_Mem +  Heap_Size)
                LDR     R3, = Stack_Mem
                BX      LR

                ALIGN

                ENDIF

		END                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
   