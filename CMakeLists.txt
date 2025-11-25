cmake_minimum_required(VERSION 3.15)

set(QT_MIN_VERSION "6.7.0")

project(POKERTH)

option(CMAKE_AUTORCC "" ON)
option(CMAKE_AUTOUIC "" ON)
option(CMAKE_AUTOMOC "" ON)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/cmake")

list(APPEND CMAKE_AUTOUIC_SEARCH_PATHS "uics/")
list(APPEND CMAKE_AUTOUIC_SEARCH_PATHS "src/gui/qt")
list(APPEND CMAKE_AUTOUIC_SEARCH_PATHS "src/gui/qt/gui_800x480")

if(GUI_800_480)
    add_definitions(-DGUI_800x480)
endif()

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

include(FindBoost)
include(FindProtobuf)

find_package(Boost REQUIRED COMPONENTS iostreams random thread filesystem program_options)
find_package(OpenSSL REQUIRED)
find_package(CURL REQUIRED)

if(ANDROID)
    set(Protobuf_USE_STATIC_LIBS ON)
    set(protobuf_MODULE_COMPATIBLE ON)
    # Force Protobuf to use emulated TLS instead of native TLS
    add_definitions(-DPROTOBUF_USE_DLLS)
    add_compile_options(-femulated-tls)  # WICHTIG: Emuliere TLS für Android
endif()

find_package(Protobuf REQUIRED)
find_package(Protobuf CONFIG)

# Find abseil (required for protobuf >= 5.27)
if(ANDROID)
    add_definitions(-DPROTOBUF_USE_DLLS)  # Kann TLS-Probleme umgehen
    find_package(absl CONFIG REQUIRED)
endif()

protobuf_generate_cpp(PROTOBUF_GEN_SRC PROTOBUF_GEN_HDRS
    chatcleaner.proto pokerth.proto
    PROTOC_OUT_DIR  ${CMAKE_SOURCE_DIR}/src/third_party/protobuf)
find_package(Qt6 ${QT_MIN_VERSION} REQUIRED COMPONENTS Core Sql Xml WebSockets Qml Quick QuickControls2 Widgets Svg Network LinguistTools Multimedia REQUIRED)


# POKERTH.lib

set(POKERTH_LIB_SRC 
    src/engine/game.cpp 
    src/playerdata.cpp 
    src/config/configfile.cpp 
    src/engine/boardinterface.cpp 
    src/engine/enginefactory.cpp 
    src/engine/handinterface.cpp 
    src/engine/playerinterface.cpp 
    src/engine/berointerface.cpp 
    src/gui/guiinterface.cpp 
    src/core/thread.cpp 
    src/core/crypthelper.cpp 
    src/core/avatarmanager.cpp 
    src/core/pokerthexception.cpp 
    src/engine/local_engine/cardsvalue.cpp 
    src/engine/local_engine/localboard.cpp 
    src/engine/local_engine/localenginefactory.cpp 
    src/engine/local_engine/localhand.cpp 
    src/engine/local_engine/localplayer.cpp 
    src/engine/local_engine/localberopreflop.cpp 
    src/engine/local_engine/localberoflop.cpp 
    src/engine/local_engine/localberoturn.cpp 
    src/engine/local_engine/localberoriver.cpp 
    src/engine/local_engine/localberopostriver.cpp 
    src/engine/local_engine/localbero.cpp 
    src/engine/local_engine/localexception.cpp 
    src/engine/local_engine/arraydata.cpp 
    src/engine/log.cpp 
    src/engine/network_engine/clientboard.cpp 
    src/engine/network_engine/clientenginefactory.cpp 
    src/engine/network_engine/clienthand.cpp 
    src/engine/network_engine/clientplayer.cpp 
    src/engine/network_engine/clientbero.cpp 
    src/net/chatcleanermanager.cpp 
    src/net/chatcleanercallback.cpp 
    src/net/clientcallback.cpp 
    src/net/clientcontext.cpp 
    src/net/clientstate.cpp 
    src/net/clientthread.cpp 
    src/net/downloadhelper.cpp 
    src/net/downloaderthread.cpp 
    src/net/netpacket.cpp 
    src/net/netpacketvalidator.cpp 
    src/net/senderhelper.cpp 
    src/net/sendercallback.cpp 
    src/net/servercallback.cpp 
    src/net/sessiondata.cpp 
    src/net/sessiondatacallback.cpp 
    src/net/sessionmanager.cpp 
    src/net/socket_startup.cpp 
    src/net/clientexception.cpp 
    src/net/netcontext.cpp 
    src/net/netexception.cpp 
    src/net/transferhelper.cpp 
    src/net/uploaderthread.cpp 
    src/net/uploadhelper.cpp 
    src/net/sendbuffer.cpp 
    src/net/asiosendbuffer.cpp 
    src/net/websendbuffer.cpp 
    src/net/receivebuffer.cpp 
    src/net/asioreceivebuffer.cpp 
    src/net/webreceivebuffer.cpp 
    src/net/uploadcallback.cpp
    src/gui/generic/serverguiwrapper.cpp 
    src/gui/qttoolsinterface.cpp)

if(ANDROID)
    list(APPEND POKERTH_LIB_SRC "src/engine/local_engine/tools_android.cpp")
else()
    list(APPEND POKERTH_LIB_SRC "src/engine/local_engine/tools.cpp")
endif()

add_library(pokerth_lib STATIC ${POKERTH_LIB_SRC})

target_include_directories(pokerth_lib PRIVATE "${Boost_INCLUDE_DIRS}")
target_include_directories(pokerth_lib PUBLIC
    src
    src/engine src/engine/local_engine 
    src/engine/network_engine
    src/gui 
    src/gui/qt 
    src/gui/qt/qttools 
    src/gui/qt/gametable
    src/net
    src/config
    src/core
    src/third_party/websocketpp)

target_link_libraries(pokerth_lib PUBLIC "${Boost_LIBRARIES}")
target_link_libraries(pokerth_lib PUBLIC "${OPENSSL_LIBRARIES}")
target_link_libraries(pokerth_lib PUBLIC CURL::libcurl)
target_link_libraries(pokerth_lib PRIVATE Qt6::Xml Qt6::Sql)
target_compile_options(pokerth_lib PUBLIC -fexceptions -frtti -Wno-stringop-overflow)
target_compile_definitions(pokerth_lib PUBLIC ENABLE_IPV6 HAVE_OPENSSL BOOST_FILESYSTEM_DEPRECATED)


# POKERTH.dbofficial

file(GLOB POKERTH_DBOFFICIAL_SRC src/dbofficial/*.cpp)

add_library(pokerth_dbofficial "${POKERTH_DBOFFICIAL_SRC}")

# Use Qt6::Sql instead of mysql++ (compat header in src/dbofficial)
target_include_directories(pokerth_dbofficial PRIVATE "${Boost_INCLUDE_DIRS}")
target_include_directories(pokerth_dbofficial PUBLIC src/)
target_link_libraries(pokerth_dbofficial PRIVATE Qt6::Sql)

# POKERTH.db

file(GLOB POKERTH_DB_SRC src/db/common/*.cpp)

add_library(pokerth_db "${POKERTH_DB_SRC}")

target_include_directories(pokerth_db PRIVATE "${Boost_INCLUDE_DIRS}")
target_include_directories(pokerth_db PUBLIC src/)


# POKERTH.protocol

add_library(pokerth_protocol "${PROTOBUF_GEN_SRC}")

message(STATUS "Protobuf include dir: ${Protobuf_INCLUDE_DIR}")

target_include_directories(pokerth_protocol PRIVATE "${Protobuf_INCLUDE_DIR}")
target_include_directories(pokerth_protocol PUBLIC "src/third_party/protobuf")

target_link_libraries(pokerth_protocol PUBLIC "${Protobuf_LIBRARIES}")

# Link abseil libraries for Android (required by protobuf >= 5.27)
if(ANDROID)
    # WICHTIG: Die Reihenfolge ist entscheidend!
    target_link_libraries(pokerth_protocol PUBLIC 
        # CRITICAL: Protobuf muss VOR Abseil gelinkt werden
        # Dann Base-Bibliotheken (enthalten TLS-Symbole)
        absl::base
        absl::raw_logging_internal
        absl::spinlock_wait
        absl::malloc_internal
        absl::log_severity
        
        # NEUE: Status & StatusOr (für FailedPreconditionError)
        absl::status
        absl::statusor
        
        # NEUE: Log Every Pow2 State
        absl::log_internal_conditions
        
        # Debugging & Demangle
        absl::debugging_internal
        absl::demangle_internal
        absl::demangle_rust
        absl::decode_rust_punycode
        absl::utf8_for_code_point
        absl::tracing_internal
        
        # Strings
        absl::strings
        absl::strings_internal
        absl::string_view
        absl::int128
        absl::throw_delegate
        
        # Time & Sync
        absl::time
        absl::civil_time
        absl::time_zone
        absl::synchronization
        absl::graphcycles_internal
        absl::kernel_timeout_internal
        
        # Hash (WICHTIG: Nach Base, vor Cord)
        absl::city
        absl::hash
        absl::raw_hash_set
        absl::hashtablez_sampler
        absl::exponential_biased
        
        # Cord
        absl::cord
        absl::cordz_info
        absl::cord_internal
        absl::cordz_functions
        absl::cordz_handle
        absl::crc_cord_state
        absl::crc32c
        absl::crc_internal
        absl::crc_cpu_detect
        absl::str_format_internal
        
        # Logging
        absl::log_internal_check_op
        absl::log_internal_message
        absl::log_internal_log_sink_set
        absl::log_internal_globals
        absl::log_globals
        absl::vlog_config_internal
        absl::log_internal_fnmatch
        absl::log_sink
        absl::log_entry
        absl::log_internal_proto
        absl::log_internal_nullguard
        absl::examine_stack
        absl::log_internal_format
        absl::log_internal_structured_proto
        absl::strerror
        absl::leak_check
        absl::stacktrace
        absl::symbolize
        
        # UTF8
        utf8_range::utf8_range
        utf8_range::utf8_validity
    )
endif()

set_property(SOURCE src/third_party/protobuf/chatcleaner.pb.cc PROPERTY SKIP_AUTOGEN ON)
set_property(SOURCE src/third_party/protobuf/chatcleaner.pb.h PROPERTY SKIP_AUTOGEN ON)
set_property(SOURCE src/third_party/protobuf/pokerth.pb.cc PROPERTY SKIP_AUTOGEN ON)
set_property(SOURCE src/third_party/protobuf/pokerth.pb.h PROPERTY SKIP_AUTOGEN ON)

add_subdirectory(src)
add_subdirectory(src/chatcleaner)
add_subdirectory(src/dbofficial)
add_subdirectory(src/gui/qt)
add_subdirectory(src/gui/qt6-qml)

