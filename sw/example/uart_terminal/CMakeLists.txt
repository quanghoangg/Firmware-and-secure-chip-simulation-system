cmake_minimum_required(VERSION 3.24)
project(honhon_uart_terminal LANGUAGES CXX)

include("${CMAKE_CURRENT_LIST_DIR}/../../../cmake/honhon-example.cmake")
honhon_add_example(uart_terminal "${CMAKE_CURRENT_SOURCE_DIR}/main.c")
