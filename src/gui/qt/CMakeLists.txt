# POKERTH.client ... Qt Widgets Client

set(CMAKE_AUTOUIC_SEARCH_PATHS . gui_800x480)

set(POKERTH_CLIENT_SRC ../../pokerth.cpp
    ../../session.cpp 
    ../../engine/local_engine/replay.cpp
    ../../core/loghelper_client.cpp
    ../../net/net_helper_client.cpp
    chattools/chattools.cpp
    guiwrapper.cpp
    qttools/qttoolswrapper.cpp
    qttools/qthelper/qthelper.cpp
    gametable/gametableimpl.cpp
    gametable/mycardspixmaplabel.cpp
    gametable/mysetlabel.cpp
    gametable/myactionbutton.cpp
    gametable/mystatuslabel.cpp
    gametable/myslider.cpp
    gametable/myavatarlabel.cpp
    gametable/myrighttabwidget.cpp
    gametable/mylefttabwidget.cpp
    gametable/startsplash/startsplash.cpp
    gametable/log/guilog.cpp
    aboutpokerth/aboutpokerthimpl.cpp
    connecttoserverdialog/connecttoserverdialogimpl.cpp
    createnetworkgamedialog/createnetworkgamedialogimpl.cpp
    createinternetgamedialog/createinternetgamedialogimpl.cpp
    joinnetworkgamedialog/joinnetworkgamedialogimpl.cpp
    newlocalgamedialog/newgamedialogimpl.cpp
    settingsdialog/settingsdialogimpl.cpp
    settingsdialog/myavatarbutton.cpp
    settingsdialog/myhpavatarbutton.cpp
    settingsdialog/selectavatardialog/selectavatardialogimpl.cpp
    settingsdialog/selectavatardialog/myavatarlistitem.cpp
    settingsdialog/manualblindsorderdialog/manualblindsorderdialogimpl.cpp
    startnetworkgamedialog/startnetworkgamedialogimpl.cpp
    startwindow/startwindowimpl.cpp
    styles/gametablestylereader.cpp
    styles/carddeckstylereader.cpp
    changecontentdialog/changecontentdialogimpl.cpp
    changecompleteblindsdialog/changecompleteblindsdialogimpl.cpp
    mymessagedialog/mymessagedialogimpl.cpp
    gamelobbydialog/gamelobbydialogimpl.cpp
    gamelobbydialog/mygamelisttreewidget.cpp
    timeoutmsgbox/timeoutmsgboximpl.cpp
    gametable/mychancelabel.cpp
    serverlistdialog/serverlistdialogimpl.cpp
    gametable/mytimeoutlabel.cpp
    gametable/mynamelabel.cpp
    settingsdialog/mystylelistitem.cpp
    gamelobbydialog/mygamelistsortfilterproxymodel.cpp
    internetgamelogindialog/internetgamelogindialogimpl.cpp
    gamelobbydialog/mynicklistsortfilterproxymodel.cpp
    gametable/mycashlabel.cpp
    sound/soundevents.cpp
    sound/qtaudioplayer.cpp
    mymessagebox/mymessagebox.cpp
    logfiledialog/logfiledialog.cpp)

if(ANDROID)
    list(APPEND POKERTH_CLIENT_SRC "resources/pokerth_android.qrc")
else()
    list(APPEND POKERTH_CLIENT_SRC "resources/pokerth.qrc")
endif()

file(GLOB QTSINGLEAPPLICATION_SRC ../../third_party/singleapplication/*.cpp)

add_executable(pokerth_client "${POKERTH_CLIENT_SRC}" "${QTSINGLEAPPLICATION_SRC}")

target_include_directories(pokerth_client PUBLIC ../../third_party/qtsingleapplication ../../third_party/qtlockedfile)
target_include_directories(pokerth_client PUBLIC ../../third_party/singleapplication)
target_include_directories(pokerth_client PRIVATE "${Boost_INCLUDE_DIRS}")
target_include_directories(pokerth_client PUBLIC ".uics/")
target_include_directories(pokerth_client PUBLIC
    ../../
    ../../config
    ../../core
    ../../engine
    ../../net
    ../../engine/local_engine
    ../../engine/network_engine
    connecttoserverdialog
    sound
    qttools
    chattools
    qttools/qthelper
    gametable
    gametable/startsplash
    gametable/log
    aboutpokerth
    createnetworkgamedialog
    createinternetgamedialog
    joinnetworkgamedialog
    newlocalgamedialog
    settingsdialog
    settingsdialog/selectavatardialog
    settingsdialog/manualblindsorderdialog
    startnetworkgamedialog
    startwindow
    serverlistdialog
    styles
    changecontentdialog
    changecompleteblindsdialog
    internetgamelogindialog
    mymessagedialog
    gamelobbydialog
    timeoutmsgbox
    logfiledialog
    mymessagebox/)

target_link_libraries(pokerth_client PUBLIC LibCurl)
target_link_libraries(pokerth_client PUBLIC "${SDL_LIBRARIES}" "${SDL_MIXER_LIBRARIES}")
target_link_libraries(pokerth_client PRIVATE Qt6::Core Qt6::Gui Qt6::Sql Qt6::Xml Qt6::Widgets Qt6::Network Qt6::Multimedia)
target_link_libraries(pokerth_client PUBLIC pokerth_lib)
target_link_libraries(pokerth_client PUBLIC pokerth_db)
target_link_libraries(pokerth_client PUBLIC pokerth_protocol)


set(QAPPLICATION_CLASS QApplication CACHE STRING "Inheritance class for SingleApplication")
add_subdirectory(../../third_party/singleapplication build_singleapplication)
target_link_libraries(pokerth_client PUBLIC SingleApplication::SingleApplication)

install(TARGETS pokerth_client DESTINATION bin OPTIONAL COMPONENT pokerth_client)
install(DIRECTORY ../../../data DESTINATION share/pokerth COMPONENT pokerth_client)
install(FILES ../../../pokerth.desktop DESTINATION share/applications COMPONENT pokerth_client)
install(FILES ../../../pokerth.desktop DESTINATION $ENV{HOME}/.local/share/applications COMPONENT pokerth_client)
install(FILES ../../../pokerth.png DESTINATION share/pixmaps COMPONENT pokerth_client)

