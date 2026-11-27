#include "honhon.h"

uint32_t SystemCoreClock;

void SystemInit(void) {
  SystemCoreClock = HONHON_CLOCK_HZ;
}
