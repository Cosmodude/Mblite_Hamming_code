#include "printf.c"

#define UART_REG_ADDR 0xF0000004
#define UART_TX_ADDR  0xF0000000
#define RTC_ADDR      0xE0000000

#define UART_TX_BUSY  0x00000004
#define UART_RX_READY 0x00000002
#define NULL ((void*)0)

volatile int* time_us = (int*)RTC_ADDR;

unsigned int bubble_time;
unsigned int hanoi_time;
unsigned int matmul_time;
unsigned int perm_time;
unsigned int quick_time;
unsigned int queen_time;
unsigned int sieve_time;

/*--------------- Bubble ----------------*/
#define MAX 100
#define BUBBLE_RUN_TIMES 10

int bubble_a[MAX];

int rnum() {
  return( ((*time_us >> 2) ^ 777) % 1111 );
}


void initran() {
  int i;

  for(i=0; i<MAX; i++)
    bubble_a[i] = rnum();
}

void bubble() {
  int i,j,t;

  for(i=MAX-1; i>=0; i--)
    for(j=1; j<MAX; j++ )
      if ( bubble_a[j-1] > bubble_a[j] ) {
	t = bubble_a[j-1];
	bubble_a[j-1] = bubble_a[j];
	bubble_a[j] = t;
      }
}

/*void show(n)
int n;
{
  int i;

  for(i=0; i<n; i++ ) printf("%d ",bubble_a[i]);
  printf("\n");
}*/

void bubble_main() {
    int i;
    bubble_time = *time_us;
    for (i=0; i < BUBBLE_RUN_TIMES; i++)
    {
        initran();  
        bubble();
    }
    bubble_time = *time_us - bubble_time;
}

/*------------------  Tower of hanoi ----------------*/

#define HANOI_RUN_TIMES 100

int num[4];

void mov( int n, int from, int to)
{
  int other;
  if( n == 1) {
    num[from] = num[from] - 1;
    num[to] = num[to] + 1;
    /*printf("%d -> %d\n",from,to);*/
  } else {
    other = 6 - from - to;
    mov(n-1, from, other);
    mov(1, from, to );
    mov(n-1, other, to);
  }
}

void hanoi_main() {
    int i;
    int disk;
    disk = 3;
    num[0] = 0;
    num[1] = disk;
    num[2] = 0;
    num[3] = 0;
    hanoi_time = *time_us;
    for (i=0; i < HANOI_RUN_TIMES; i++)
    {  
        mov(disk,1,3);
    }
    hanoi_time = *time_us - hanoi_time;
}

/*------------------  Matrix multiplication ----------------*/

#define  N  10
#define MATMUL_RUN_TIMES 100

int a[N][N], b[N][N], c[N][N];

void inita() {
  int i,j;

  for(i=0; i<N; i++)
    for(j=0; j<N; j++)
      a[i][j] = rnum();
}

void initb() {
  int i,j;

  for(i=0; i<N; i++)
    for(j=0; j<N; j++)
      b[i][j] = rnum();
}

void matmul() {
  int i,j,k;

  for(i=0; i<N; i++)
    for(j=0; j<N; j++) {
      c[i][j] = 0;
      for(k=0; k<N; k++)
	c[i][j] += a[i][k] * b[k][j];
    }
}

void matmul_main() {
    int i;
    matmul_time = *time_us;
    for (i=0; i < MATMUL_RUN_TIMES; i++)
    {   
        inita();
        initb();
        matmul();
    }
    matmul_time = *time_us - matmul_time;
    /*show();*/
}

/*show() {
  int i,j;

  for(i=0; i<N; i++)  {
    for(j=0; j<N; j++)
      printf("%d ",c[i][j]);
    printf("\n");
  }
}*/

/*------------------  Permutation generation ----------------*/

#define PERM_N 4
#define PERM_RUN_TIMES 5

int val[PERM_N], id;

void visit(k)
int k;
{
  int t;

  id++;
  val[k] = id;
  /*if (id == PERM_N-1) writeperm();*/
  for(t=0; t<PERM_N; t++)
    if( val[t] == 0) visit(t);
  id--;
  val[k] = 0;
}

void perm_main() {
    int i,j;

    perm_time = *time_us;
    for (j=0; j < PERM_RUN_TIMES; j++)
    { 
        for(i=0; i<PERM_N; i++) val[i] = 0;
        id = -1;
        visit(0);
    }
    perm_time = *time_us - perm_time;
}

/*------------------  Queen puzzle ----------------*/

#define QUEEN_RUN_TIMES 5
#define Q 8		/* size of Q x Q board */
#define Z Q+1 		/* empty */
#define D (Q+Q-1)       /* size of diagonal */

int col[Q], d45[D], d135[D], queen[Q];
int soln;

void find(level)
int level;
{
  int i;

  if ( level == Q ) {
    /*printboard();*/
  } else {
    for(i=0; i<Q; i++ ) {
      if( col[i] >= level &&
	  d45[level+i] >= level &&
	  d135[level + Q -1 - i] >= level ) {
	queen[level] = i;
	col[i] = d45[level+i] = d135[level + Q -1 - i] = level;
	find(level+1);
	col[i] = d45[level+i] = d135[level + Q -1 - i] = Z;
      }
    }
  }
}

void queen_main() {
    int i,j;

    queen_time = *time_us;
    for (j=0; j < QUEEN_RUN_TIMES; j++)
    {
        for(i=0; i<Q; i++) col[i] = Z;
        for(i=0; i<D; i++) { d45[i] = d135[i] = Z; }
        soln = 0;
        find(0);
    }
    queen_time = *time_us - queen_time;

}

/*------------------  Quick sort ----------------*/

/*#define N 100*/
#define QUICK_RUN_TIMES 100

int quick_a[N];


void quick_initran() {
  int i;
  for(i=0; i<N; i++)
    quick_a[i] = rnum();
}

void qsort2(l,r)
int l,r;
{
  int v,t,i,j;

  if ( r>l ) {
    v = quick_a[r];
    i = l-1;
    j = r;
    do {
      do i++; while (quick_a[i] < v);
      do j--; while (quick_a[j] > v);
      t = quick_a[i];
      quick_a[i] = quick_a[j];
      quick_a[j] = t;
    } while( j > i);
    quick_a[j] = quick_a[i];
    quick_a[i] = quick_a[r];
    quick_a[r] = t;
    qsort2(l,i-1);
    qsort2(i+1,r);
  }
}

void quick_main() {    
    int j;
    quick_time = *time_us;
    for (j=0; j < QUICK_RUN_TIMES; j++)
    {  
        quick_initran();
        qsort2(0,N);
    }
    quick_time = *time_us - quick_time;

}

/*------------------  Sieve prime search ----------------*/

#define SIEVE_RUN_TIMES 5
#define SIEVE_N 10000

int p[SIEVE_N];

void sieve() {
  int i, k, prime;

  for(i=0; i<SIEVE_N; i++)
    if( p[i] ) {
      prime = i + i + 3;
      for(k=i+ prime; k<SIEVE_N; k+= prime)
	p[k] = 0;
    }
}

void sieve_main() { 
    int i,j;

    sieve_time = *time_us;
    for (j=0; j < SIEVE_RUN_TIMES; j++)
    {
        for(i=0; i<SIEVE_N; i++ ) p[i] = 1;
        sieve();
    }
    sieve_time = *time_us - sieve_time;
}

/*---------------------------------------------*/

void put_char(void* p, char c)			/*Char output*/
{
    volatile int* uart_reg = (int*)UART_REG_ADDR;
    volatile int* txrx_reg = (int*)UART_TX_ADDR;
    while (*uart_reg & UART_TX_BUSY);   // wait for transmitter to become free
	*txrx_reg = c;			            /*write byte to transmitter*/
}

int main(void)
{
    init_printf(NULL, put_char);
    printf("Stanford integer test\n");
    printf("Running Bubble test\n");
    bubble_main();
    printf("Running Hanoi test\n");
    hanoi_main();
    printf("Running MatMul test\n");
    matmul_main();
    printf("Running Perm test\n");
    perm_main();
    printf("Running QSort test\n");
    quick_main();
    printf("Running Queen test\n");
    queen_main();
    printf("Running Sieve test\n");
    sieve_main();
    printf("Bubble time: %uus\n", (bubble_time / BUBBLE_RUN_TIMES));
    printf("Hanoi time: %uus\n", (hanoi_time / HANOI_RUN_TIMES));
    printf("Matmul time: %uus\n", (matmul_time / MATMUL_RUN_TIMES));
    printf("Perm time: %uus\n", (perm_time / PERM_RUN_TIMES));
    printf("QSort time: %uus\n", (quick_time / QUICK_RUN_TIMES));
    printf("Queen time: %uus\n", (queen_time / QUEEN_RUN_TIMES));
    printf("Sieve time: %uus\n", (sieve_time / SIEVE_RUN_TIMES));
    return 0;
}
