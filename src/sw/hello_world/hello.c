#define UART_REG_ADDR 0xF0000004
#define UART_TX_ADDR  0xF0000000
#define RTC_ADDR      0xE0000000

#define UART_TX_BUSY  0x00000004
#define UART_RX_READY 0x00000002

#define NULL ((void*)0)

#include "printf.c"


volatile unsigned int* time_us = (unsigned int*)RTC_ADDR;
volatile int* uart_reg = (int*)UART_REG_ADDR;
volatile int* txrx_reg = (int*)UART_TX_ADDR;

void put_char(void* p, char c)			/*Char output*/
{
    while (*uart_reg & UART_TX_BUSY);   // wait for transmitter to become free
	*txrx_reg = c;			            /*write byte to transmitter*/
}

#define SLEEP_TIME 3000

int main(void)
{
	int prevtime = 0;
	volatile unsigned int *time_us = (unsigned int*)RTC_ADDR;
	
	init_printf(NULL, put_char);
	
	printf("Hello World!!!\n");
	
	while (1)
	{
		while ((prevtime + SLEEP_TIME) > *time_us);
		prevtime = *time_us;
		
		if (*uart_reg & UART_RX_READY)
		{
		    put_char(NULL, *txrx_reg);
		}
	} 

	return 0;
	
}


