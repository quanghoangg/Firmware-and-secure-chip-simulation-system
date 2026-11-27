# OpenTitan sources used by honhon

These files come from [lowRISC OpenTitan at revision `e852312`](https://github.com/lowRISC/opentitan/tree/e852312af4e29bda9b84c673545400e5fd00e23b). They include the RTL and UART DPI model used by the virtual platform and the UART DIF and headers used by the RV32 firmware. The Ibex RTL comes from the same OpenTitan revision, which imports Ibex at `7a4697f578c67c550fcad5e5e3078415e1f088d7`.

`hw/top/uart_regs.h` was generated with OpenTitan's `util/regtool.py -D`. `sw/device/lib/dif/autogen/dif_uart_autogen.{c,h}` were generated with `util/autogen_dif.py`. Both generators used `hw/ip/uart/data/uart.hjson` from the same revision. Paths in the generated comments are relative to the source trees.

See [LICENSE](LICENSE) and [NOTICE](NOTICE) for the upstream license and attribution.
