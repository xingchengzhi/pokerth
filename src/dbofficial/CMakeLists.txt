# POKERTH.official_server

set(POKERTH_OFFICIAL_SERVER_SRC
    ../pokerth_server.cpp
    ../session.cpp
    asyncdbcreategame.cpp
    asyncdbgameplace.cpp
    asyncdbupdatescore.cpp
    asyncdbquery.cpp
    serverdbthread.cpp
    serverdbfactoryinternal.cpp
    singleasyncdbquery.cpp
    compositeasyncdbquery.cpp
    querycontext.cpp
    asyncdbendgame.cpp
    asyncdblogin.cpp
    asyncdbreportavatar.cpp
    asyncdbreportgame.cpp
    asyncdbavatarblacklist.cpp
    asyncdbadminplayers.cpp
    asyncdbblockplayer.cpp
    asyncdbplayerlastgames.cpp
    dbidmanager.cpp
    ../gui/qt/qttools/nonqttoolswrapper.cpp
    ../gui/qt/qttools/nonqthelper/nonqthelper.cpp
    ../core/common/loghelper_server.cpp
    ../net/common/net_helper_server.cpp
    ../net/common/servermanager.cpp
    ../net/common/servermanagerfactoryserver.cpp
    ../net/common/serverlobbythread.cpp
    ../net/common/serverexception.cpp 
    ../net/common/serveracceptinterface.cpp 
    ../net/common/serveracceptwebhelper.cpp 
    ../net/common/servergame.cpp 
    ../net/common/servergamestate.cpp 
    ../net/common/serverbanmanager.cpp 
    ../core/linux/convhelper.cpp)

# fix AUTOMOC issue: include used header files
set(POKERTH_OFFICIAL_SERVER_NET_HEADERS 
    ../net/net_helper.h
    ../net/servermanager.h
    ../net/servermanagerfactory.h
    ../net/serverlobbythread.h
    ../net/serverexception.h 
    ../net/serveracceptinterface.h 
    ../net/serveracceptwebhelper.h 
    ../net/servergame.h 
    ../net/servergamestate.h 
    ../net/serverbanmanager.h 
)

add_executable(pokerth_official_server ${POKERTH_OFFICIAL_SERVER_SRC} ${POKERTH_OFFICIAL_SERVER_NET_HEADERS} )

target_include_directories(pokerth_official_server PRIVATE "${Boost_INCLUDE_DIRS}")
target_include_directories(pokerth_official_server PUBLIC "${MYSQLPP_INCLUDE_DIR}")
target_include_directories(pokerth_official_server PUBLIC
    ../ 
    ../engine 
    ../gui
    ../gui/qt
    ../gui/qt/qttools
    ../gui/qt/qttools/nonqthelper
    ../net 
    ../engine/local_engine 
    ../engine/network_engine 
    ../config 
    ../core)

target_link_libraries(pokerth_official_server PUBLIC LibCurl)
target_link_libraries(pokerth_official_server PUBLIC "${MYSQLPP_LIBRARIES}")
target_link_libraries(pokerth_official_server PUBLIC pokerth_dbofficial)
target_link_libraries(pokerth_official_server PUBLIC pokerth_lib)
target_link_libraries(pokerth_official_server PUBLIC pokerth_db)
target_link_libraries(pokerth_official_server PUBLIC pokerth_protocol)
target_link_libraries(pokerth_official_server PRIVATE Qt6::Xml)

target_compile_definitions(pokerth_official_server PUBLIC POKERTH_OFFICIAL_SERVER POKERTH_DEDICATED_SERVER)

install(TARGETS pokerth_official_server DESTINATION bin OPTIONAL COMPONENT pokerth_official_server)
