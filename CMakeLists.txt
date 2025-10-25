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

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

include(FindBoost)
include(FindGSasl)
include(FindMySQL)

find_package(Boost REQUIRED COMPONENTS iostreams random thread filesystem program_options)
find_package(GSasl REQUIRED)
find_package(SQLite3 REQUIRED)
find_package(OpenSSL REQUIRED)
find_package(SDL REQUIRED)
find_package(SDL_mixer REQUIRED)
find_package(CURL REQUIRED)
find_package(MySQL REQUIRED)
find_package(Protobuf REQUIRED)
    protobuf_generate_cpp(PROTOBUF_GEN_SRC PROTOBUF_GEN_HDRS
    chatcleaner.proto pokerth.proto
    PROTOC_OUT_DIR  ${CMAKE_SOURCE_DIR}/src/third_party/protobuf)
find_package(Qt6 ${QT_MIN_VERSION} REQUIRED COMPONENTS Core Sql Xml WebSockets Qml Quick QuickControls2 Widgets Svg Network LinguistTools REQUIRED)

# @TODO: better use a FindCurl.cmake file?
add_library(LibCurl INTERFACE IMPORTED)
set_target_properties(LibCurl PROPERTIES
INTERFACE_INCLUDE_DIRECTORIES "${CURL_INCLUDE_DIRS}")
if(WIN32)
    target_link_libraries(LibCurl INTERFACE "${CURL_LIBRARY}")
else()
    set_target_properties(LibCurl PROPERTIES
        INTERFACE_LINK_LIBRARIES "${CURL_LIBRARY}")
endif()


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
    src/core/common/thread.cpp 
    src/core/common/crypthelper.cpp 
    src/core/common/avatarmanager.cpp 
    src/core/common/pokerthexception.cpp 
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
    src/net/common/chatcleanermanager.cpp 
    src/net/common/chatcleanercallback.cpp 
    src/net/common/clientcallback.cpp 
    src/net/common/clientcontext.cpp 
    src/net/common/clientstate.cpp 
    src/net/common/clientthread.cpp 
    src/net/common/downloadhelper.cpp 
    src/net/common/downloaderthread.cpp 
    src/net/common/netpacket.cpp 
    src/net/common/netpacketvalidator.cpp 
    src/net/common/senderhelper.cpp 
    src/net/common/sendercallback.cpp 
    src/net/common/servercallback.cpp 
    src/net/common/sessiondata.cpp 
    src/net/common/sessiondatacallback.cpp 
    src/net/common/sessionmanager.cpp 
    src/net/common/socket_startup.cpp 
    src/net/common/clientexception.cpp 
    src/net/common/netcontext.cpp 
    src/net/common/netexception.cpp 
    src/net/common/transferhelper.cpp 
    src/net/common/uploaderthread.cpp 
    src/net/common/uploadhelper.cpp 
    src/net/common/sendbuffer.cpp 
    src/net/common/asiosendbuffer.cpp 
    src/net/common/websendbuffer.cpp 
    src/net/common/receivebuffer.cpp 
    src/net/common/asioreceivebuffer.cpp 
    src/net/common/webreceivebuffer.cpp 
    src/net/common/uploadcallback.cpp
    src/gui/generic/serverguiwrapper.cpp 
    src/gui/qttoolsinterface.cpp)

if(ANDROID)
    list(APPEND POKERTH_LIB_SRC "src/engine/local_engine/tools_android.cpp")
else()
    list(APPEND POKERTH_LIB_SRC "src/engine/local_engine/tools.cpp")
endif()

# fix AUTOMOC issue: include used header files
set(POKERTH_LIB_NET_HEADERS 
    src/net/chatcleanermanager.h 
    src/net/chatcleanercallback.h 
    src/net/clientcallback.h 
    src/net/clientcontext.h 
    src/net/clientstate.h 
    src/net/clientthread.h 
    src/net/downloadhelper.h 
    src/net/downloaderthread.h 
    src/net/netpacket.h 
    src/net/netpacketvalidator.h 
    src/net/senderhelper.h 
    src/net/sendercallback.h
    src/net/servercallback.h  
    src/net/sessiondata.h 
    src/net/sessiondatacallback.h 
    src/net/sessionmanager.h 
    src/net/socket_startup.h 
    src/net/clientexception.h 
    src/net/netcontext.h 
    src/net/netexception.h 
    src/net/transferhelper.h 
    src/net/uploaderthread.h 
    src/net/uploadhelper.h
    src/net/sendbuffer.h 
    src/net/asiosendbuffer.h 
    src/net/websendbuffer.h 
    src/net/receivebuffer.h 
    src/net/asioreceivebuffer.h 
    src/net/webreceivebuffer.h 
    src/net/uploadcallback.h
)

add_library(pokerth_lib STATIC ${POKERTH_LIB_SRC} ${POKERTH_LIB_NET_HEADERS})

target_include_directories(pokerth_lib PRIVATE "${Boost_INCLUDE_DIRS}")
target_include_directories(pokerth_lib PUBLIC
    src
    src/engine src/engine/local_engine src/engine/network_engine
    src/gui src/gui/qt src/gui/qt/qttools src/gui/qt/gametable
    src/net
    src/config
    src/core
    src/third_party/websocketpp)

target_link_libraries(pokerth_lib PUBLIC "${SQLite3_LIBRARIES}")
target_link_libraries(pokerth_lib PUBLIC "${GSASL_LIBRARIES}")
target_link_libraries(pokerth_lib PUBLIC "${Boost_LIBRARIES}")
target_link_libraries(pokerth_lib PUBLIC "${OPENSSL_LIBRARIES}")
target_link_libraries(pokerth_lib PRIVATE Qt6::Xml)

target_compile_options(pokerth_lib PUBLIC -fexceptions -frtti)
target_compile_definitions(pokerth_lib PUBLIC ENABLE_IPV6 HAVE_OPENSSL BOOST_FILESYSTEM_DEPRECATED MYSQLPP_MYSQL_HEADERS_BURIED)


# POKERTH.dbofficial

file(GLOB POKERTH_DBOFFICIAL_SRC src/dbofficial/*.cpp)

add_library(pokerth_dbofficial "${POKERTH_DBOFFICIAL_SRC}")

target_include_directories(pokerth_dbofficial PRIVATE "${MYSQLPP_INCLUDE_DIR}")
target_include_directories(pokerth_dbofficial PRIVATE "${Boost_INCLUDE_DIRS}")
target_include_directories(pokerth_dbofficial PUBLIC src/)


# POKERTH.db

file(GLOB POKERTH_DB_SRC src/db/common/*.cpp)

add_library(pokerth_db "${POKERTH_DB_SRC}")

target_include_directories(pokerth_db PRIVATE "${Boost_INCLUDE_DIRS}")
target_include_directories(pokerth_db PUBLIC src/)


# POKERTH.protocol

add_library(pokerth_protocol "${PROTOBUF_GEN_SRC}")

target_include_directories(pokerth_protocol PRIVATE "${Protobuf_INCLUDE_DIR}")
target_include_directories(pokerth_protocol PUBLIC "src/third_party/protobuf")

target_link_libraries(pokerth_protocol PUBLIC "${Protobuf_LIBRARIES}")

set_property(SOURCE src/third_party/protobuf/chatcleaner.pb.cc PROPERTY SKIP_AUTOGEN ON)
set_property(SOURCE src/third_party/protobuf/chatcleaner.pb.h PROPERTY SKIP_AUTOGEN ON)
set_property(SOURCE src/third_party/protobuf/pokerth.pb.cc PROPERTY SKIP_AUTOGEN ON)
set_property(SOURCE src/third_party/protobuf/pokerth.pb.h PROPERTY SKIP_AUTOGEN ON)

add_subdirectory(src)
add_subdirectory(src/chatcleaner)
add_subdirectory(src/dbofficial)
add_subdirectory(src/gui/qt)
add_subdirectory(src/gui/qt6-qml)

