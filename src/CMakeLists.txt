# POKERTH.dedicated_server

set(POKERTH_SERVER_SRC pokerth_server.cpp
    session.cpp 
    gui/qt/qttools/nonqttoolswrapper.cpp
    gui/qt/qttools/nonqthelper/nonqthelper.cpp
    net/common/net_helper_server.cpp
    core/common/loghelper_server.cpp
    net/common/servermanager.cpp
    net/common/servermanagerfactoryserver.cpp
    # net/common/servermanagerfactoryclient.cpp
    net/common/serverlobbythread.cpp
    core/linux/convhelper.cpp)

add_executable(pokerth_dedicated_server "${POKERTH_SERVER_SRC}" )

target_include_directories(pokerth_dedicated_server PRIVATE "${Boost_INCLUDE_DIRS}")
target_include_directories(pokerth_dedicated_server PUBLIC
    engine 
    gui
    gui/qt
    gui/qt/qttools
    gui/qt/qttools/nonqthelper
    net 
    engine/local_engine 
    engine/network_engine 
    config 
    core)

target_link_libraries(pokerth_dedicated_server PUBLIC LibCurl)
# target_link_libraries(pokerth_dedicated_server PUBLIC -lircclient)
target_link_libraries(pokerth_dedicated_server PUBLIC pokerth_lib)
target_link_libraries(pokerth_dedicated_server PUBLIC pokerth_db)
target_link_libraries(pokerth_dedicated_server PUBLIC pokerth_protocol)
target_link_libraries(pokerth_dedicated_server PRIVATE Qt6::Xml)

target_compile_definitions(pokerth_dedicated_server PUBLIC POKERTH_DEDICATED_SERVER)

install(TARGETS pokerth_dedicated_server DESTINATION bin OPTIONAL COMPONENT pokerth_dedicated_server)
