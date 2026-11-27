# honhon

honhon là SoC RV32 tối giản với Ibex, TL-UL, ROM, SRAM và nguyên IP UART từ OpenTitan. Firmware mẫu khởi động từ ROM, in lời chào và echo dữ liệu UART. VP là chương trình mô phỏng Verilator chạy trên Linux.

## Build và chạy

Từ thư mục `honhon/`, vào example và dùng workflow preset để cấu hình và build bằng một lệnh. Workflow cần CMake 3.25 trở lên.

```sh
cd sw/example/uart_echo
cmake --workflow --preset build
```

Thư mục `build/` nằm trong example. Firmware được tạo tại `build/sw/uart_echo.elf`, `build/sw/uart_echo.bin` và `build/sw/uart_echo.vmem`. VP nằm tại `build/vp/honhon-vp`.

Để chạy VP, dùng target `run_vp` từ cùng thư mục example. Target này cũng build lại khi mã nguồn thay đổi.

```sh
cmake --build build --target run_vp
```

VP in đường dẫn PTY khi khởi động. Mở terminal khác, thay `N` bằng số VP báo, rồi gõ ký tự để kiểm tra echo.

```sh
screen /dev/pts/N
```

Để theo dõi UART qua log, chạy lệnh sau từ thư mục example. Log nhận cả lời chào ngay cả khi chưa mở PTY.

```sh
tail -F build/uart0.log
```

Dừng VP bằng Ctrl+C ở terminal chạy mô phỏng. Dùng `honhon-vp --help` để xem tùy chọn đường dẫn ROM, log và giới hạn chu kỳ. VP mặc định nạp `build/sw/uart_echo.vmem`.

## Kiểm tra

Từ thư mục example, chạy:

```sh
ctest --test-dir build --output-on-failure
```

Bài kiểm tra chờ lời chào trong log, mở PTY, gửi dữ liệu nhị phân và kiểm tra byte trả về ở cả PTY lẫn log.

## Mã nguồn và môi trường

- `hw/` ghép các IP OpenTitan và định nghĩa bản đồ địa chỉ dùng chung.
- `sw/device/` chứa startup, linker script và cấu hình chip. `sw/drivers/hal/` cung cấp UART HAL trên `dif_uart`. `sw/example/uart_echo/` chứa firmware mẫu.
- `vp/` chạy clock/reset, nạp ROM và dùng mô hình nối tiếp `uartdpi.sv` của OpenTitan với PTY Linux và tệp log. Khi hàng đợi PTY đầy, log vẫn nhận toàn bộ đầu ra UART.
- `cmake/` chọn mã IP, Verilator và toolchain RV32. Cấu hình mặc định tìm checkout tại `../secure_chip/opentitan`, công cụ tại `../secure_chip/tools` và lowRISC LLVM trong cache của checkout.

Có thể đổi các đường dẫn bằng `-DOPENTITAN_ROOT=...`, `-DOPENTITAN_TOOLS=...`, `-Dverilator_DIR=...`, `-DSRECORD_ROOT=...` và `-DRISCV_TOOLCHAIN_ROOT=...`. Cần Python với các thư viện dành cho `regtool.py` và `autogen_dif.py`; trên workspace này CMake dùng được thư viện Python đã tải trong cache OpenTitan. CMake dùng trực tiếp thư mục runtime của Verilator và thêm đường dẫn thư viện SRecord khi chuyển ảnh ROM.
