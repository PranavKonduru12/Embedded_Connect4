# Embedded_Connect4
Connect 4 game runs on an ARM Cortex-M0 soft-core processor on the Nexys A7 FPGA

This project aims at building a two-player real-time application by making use of the features available on the FPGA, such as VGA display, GPIO interface, timer, UART, interrupt handling, etc. The motivation behind such an effort is to learn about embedded systems design and see how various peripherals could be used to create a useful application.

The current system is built over an existing embedded framework: a snake game equivalent to the ones on the Nokia phones (modified to be multiplayer from the physical controls to the interface). The framework offers some APIs related to display control, input handling, and periphery management that are re-used within the current implementation to build the application. Namely, this implementation offers an ability for two players to interact with a 7×6 board presented to the player in a VGA format. Using GPIO pins, the players could control the cursor and place pieces into corresponding columns. Various aspects of the game, such as turns switching, gravity-based dropping, and winning conditions, were implemented in software, whereas hardware managed display and peripheral handling.

The results anticipated from this particular project include an effective game application that will be capable of controlling moves through the switches, writing the player names on the interface, and displaying moves as well as determining the winner of the game.
