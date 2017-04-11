extern int lab7(void);	
extern int pin_connect_block_setup(void);
extern int uart_init(void);
extern int timer_init(void);

int main()
{ 	
   pin_connect_block_setup();
   uart_init();
   timer_init();
   lab7();
}
