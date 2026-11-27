# honhon

honhon là SoC RV32 tối giản với Ibex, TL-UL, ROM, SRAM và nguyên IP UART từ OpenTitan. Firmware mẫu khởi động từ ROM, in lời chào và echo dữ liệu UART. VP là chương trình mô phỏng Verilator chạy trên Linux.

## Build và chạy

Repo chứa các nguồn OpenTitan cần để build firmware và VP trong `third_party/opentitan/`. Trên Linux, chuẩn bị CMake 3.25 trở lên, Ninja, Python 3, trình biên dịch C++17, Verilator, LLVM hỗ trợ RISC-V (`clang`, `ld.lld`) và `llvm-objcopy` hoặc GNU `objcopy` từ binutils. VP đã được kiểm tra với Verilator 5.048.

Khi các công cụ có trên `PATH`, vào example từ thư mục repo và build bằng một lệnh.

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

## Terminal UART

Từ thư mục gốc của repo, build và chạy example `uart_terminal`:

```sh
cd sw/example/uart_terminal
cmake --workflow --preset build
cmake --build build --target run_vp
```

Mở terminal thứ hai, thay `N` bằng số PTY VP in ra và kết nối bằng pySerial:

```sh
python3 -m serial.tools.miniterm /dev/pts/N 115200 --raw
```

Tại dấu nhắc `honhon>`, gõ `help`, `echo Xin chao`, `clear` hoặc `info` rồi nhấn Enter. Dùng Backspace để sửa dòng và `Ctrl+]` để thoát `miniterm`. Firmware và log UART nằm trong `sw/example/uart_terminal/build/`.

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
- `third_party/opentitan/` chứa RTL, UART DPI, UART DIF và định nghĩa thanh ghi đã sinh. Xem phiên bản nguồn và giấy phép trong [README của phần OpenTitan](third_party/opentitan/README.md).
- `cmake/` cấu hình VP và LLVM cho firmware RV32. `sw/bin_to_vmem.py` chuyển firmware nhị phân thành ảnh ROM.

Khi công cụ nằm ở thư mục riêng, thêm các thư mục `bin/` vào `PATH` trước khi chạy workflow. Bạn cũng có thể lưu đường dẫn công cụ vào cấu hình CMake của example.

```sh
cmake --preset ninja \
  -Dverilator_DIR=/path/to/verilator/share/verilator \
  -DRISCV_TOOLCHAIN_ROOT=/path/to/llvm
```
