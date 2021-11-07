cmake_minimum_required(VERSION 3.10)
project(${CLIENT_NAME})


option(SDL_ON_Make "" ON)
option(CURL_ON_Make "" ON)
option(HEADERS_ON_Make "" ON)
option(VULKAN_ON_Make "" OFF)
option(APP_JPG_ON_Make "" OFF)

option(RENDERER_DLLS_ON_Make "" OFF)


set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake_modules)

aux_source_directory(code/libjpeg JPG_CODE)
add_library(jpeg ${JPG_CODE})


aux_source_directory(code/server SERVER_CODE)
list(REMOVE_ITEM SERVER_CODE code/server/sv_rankings.c)
add_library(server ${SERVER_CODE})
add_library(server_${SERVER_NAME} ${SERVER_CODE})
target_compile_definitions(server_${SERVER_NAME} PUBLIC -DDEDICATED)


aux_source_directory(code/qcommon COMMON_CODE)
list(FILTER COMMON_CODE EXCLUDE REGEX ".*vm_[alx].*.c")


add_library(qcommon ${COMMON_CODE} ${VM_SRC})
target_link_libraries(qcommon PRIVATE server)
add_library(qcommon_${SERVER_NAME} ${COMMON_CODE} ${VM_SRC})
target_link_libraries(qcommon_${SERVER_NAME} PUBLIC server_${SERVER_NAME})


aux_source_directory(code/botlib BOTLIB_CODE)
add_library(botlib ${BOTLIB_CODE})
target_compile_definitions(botlib PRIVATE -DBOTLIB)


aux_source_directory(code/client CLIENT_CODE)
if(NOT CURL_ON_Make)
    list(REMOVE_ITEM CLIENT_CODE code/client/cl_curl.c)
endif(NOT CURL_ON_Make)
add_library(client ${CLIENT_CODE})
target_link_libraries(client qcommon jpeg)
if(APP_JPG_ON_Make)
    target_compile_definitions(client PRIVATE -DAPP_JPG_ON_Make)
endif(APP_JPG_ON_Make)
if(VULKAN_ON_Make)
    target_compile_definitions(client PRIVATE -DVULKAN_API_ON_Make)
endif(VULKAN_ON_Make)



aux_source_directory(code/renderercommon RENDERER_COMMON_CODE)
add_library(renderer_common ${RENDERER_COMMON_CODE})


aux_source_directory(code/renderer RENDERER_CODE)
add_library(renderer ${RENDERER_CODE})
target_link_libraries(renderer renderer_common)


aux_source_directory(code/renderervk RENDERER_VK_CODE)
add_library(renderer_vk ${RENDERER_VK_CODE})
target_link_libraries(renderer_vk renderer_common)


if(SDL_ON_Make)
    aux_source_directory(code/sdl SDL_CODE)
    add_library(app_sdl ${SDL_CODE})
    find_package(SDL2 REQUIRED)
    target_link_libraries(app_sdl SDL2::Main)
    if(VULKAN_ON_Make)
        target_compile_definitions(app_sdl PRIVATE -DVULKAN_API_ON_Make)
    endif(VULKAN_ON_Make)

endif()

if(UNIX)
    set(APP_CODE
            code/unix/unix_main.c
            code/unix/unix_shared.c
            code/unix/linux_signals.c)

    if (NOT SDL_ON_Make)
        set(APP_UI_CODE
                code/unix/linux_glimp.c
                code/unix/linux_qgl.c
                code/unix/linux_snd.c
                code/unix/x11_dga.c
                code/unix/x11_randr.c
                code/unix/x11_vidmode.c)
        if(VULKAN_API_ON_Make)
            list(APPEND APP_UI_CODE code/unix/linux_qvk.c)
        endif(VULKAN_API_ON_Make)
    endif(NOT SDL_ON_Make)

    if(APPLE)
        set(EXE_TYPE MACOSX_BUNDLE)
        list(APPEND APP_CODE code/unix/quake3_flat.icns)
        set_source_files_properties(code/unix/quake3_flat.icns PROPERTIES
                MACOSX_PACKAGE_LOCATION Resources)
        set(MACOSX_BUNDLE_ICON_FILE quake3_flat.icns)
    endif()
elseif(WIN32)
    set(EXE_TYPE WIN32)
    set(APP_CODE
            code/win32/win_main.c
            code/win32/win_shared.c
            code/win32/win_syscon.c
            code/win32/win_resource.rc)
    if (NOT SDL_ON_Make)
        set(APP_UI_CODE
                code/win32/win_gamma.c
                code/win32/win_glimp.c
                code/win32/win_input.c
                code/win32/win_minimize.c
                code/win32/win_qgl.c
                code/win32/win_snd.c
                code/win32/win_wndproc.c)
        if(VULKAN_API_ON_Make)
            list(APPEND APP_UI_CODE code/win32/win_qvk.c)
        endif(VULKAN_API_ON_Make)
    endif(NOT SDL_ON_Make)
endif(UNIX)


if(CMAKE_SYSTEM_PROCESSOR MATCHES AMD|x86)
    set(VM_CODE code/qcommon/vm_x86.c)
elseif(CMAKE_SYSTEM_PROCESSOR MATCHES aarch)
    set(VM_CODE code/qcommon/vm_aarch64.c)
elseif(CMAKE_SYSTEM_PROCESSOR MATCHES arm)
    set(VM_CODE code/qcommon/vm_armv7l.c)
else()
    target_compile_definitions(qcommon PRIVATE -DVM_OFF_CFlags)
endif()


add_executable(${CLIENT_NAME} ${EXE_TYPE} ${VM_CODE} ${APP_CODE} ${APP_UI_CODE})
target_link_libraries(${CLIENT_NAME} client botlib)

if(SDL_ON_Make)
    target_link_libraries(${CLIENT_NAME} app_sdl)
endif(SDL_ON_Make)

if(VULKAN_ON_Make)
    target_link_libraries(${CLIENT_NAME} renderer_vk)
    target_compile_definitions(${CLIENT_NAME} PRIVATE -DVULKAN_API_ON_Make)
else()
    target_link_libraries(${CLIENT_NAME} renderer)
endif(VULKAN_ON_Make)

add_executable(${CLIENT_NAME}_${SERVER_NAME} ${EXE_TYPE} ${VM_CODE} ${APP_CODE})
target_link_libraries(${CLIENT_NAME}_${SERVER_NAME} qcommon_${SERVER_NAME} botlib)

if(WIN32)
    target_link_libraries(${CLIENT_NAME} winmm comctl32 ws2_32)
    target_link_libraries(${CLIENT_NAME}-server winmm comctl32 ws2_32)
endif(WIN32)
