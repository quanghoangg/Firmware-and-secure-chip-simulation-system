cmake_minimum_required(VERSION 3.24)
project(honhon LANGUAGES CXX)

include(cmake/honhon-example.cmake)
honhon_add_example(uart_echo "${CMAKE_CURRENT_SOURCE_DIR}/sw/example/uart_echo/main.c")
