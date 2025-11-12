# POKERTH.qml-client ... unfinisihed

set(POKERTH_QML_CLIENT_SRC ../../pokerth.cpp
    ../../session.cpp 
    ../../core/loghelper_client.cpp
    ../../net/net_helper_client.cpp
    ../../core/qttools/qthelper/qthelper.cpp
    ../../core/qttools/qttoolswrapper.cpp
    ../../core/qttoolsinterface.cpp
    cpp/retranslate.cpp
    cpp/settingsxmlhandler.cpp)

qt_add_resources(POKERTH_QML_CLIENT_SRC qml.qrc)

set(QML_FILES
    pokerth.qml
    components/CustomCheckBox.qml
    components/CustomComboBox.qml
    components/CustomTabBar.qml
    components/CustomToggle.qml
    components/GamePlayerBox.qml
    components/GamePlayerSelfBox.qml
    components/GuiSettings.qml
    components/InternetGameSettings.qml
    components/LocalGameSettings.qml
    components/LogsSettings.qml
    components/NetworkGameSettings.qml
    components/NicknameAvatarSettings.qml
    components/ResetSettings.qml
    components/SideMenu.qml
    components/SoundSettings.qml
    components/CustomButton.qml
    components/StyleSettings.qml
    pages/AboutPage.qml
    pages/GamePage.qml
    pages/InternetGamePage.qml
    pages/LocalGamePage.qml
    pages/LogsPage.qml
    pages/NetworkGameCreatePage.qml
    pages/NetworkGameEnterPage.qml
    pages/PreLoader.qml
    pages/SettingsPage.qml
    pages/StartPage.qml
    config/StaticData.qml
    config/Parameters.qml)

set(TS_FILES
    i18n/pokerth_de_DE.ts
    i18n/pokerth_fr_FR.ts
    i18n/pokerth_en_US.ts
)

qt_add_translations(pokerth_qml-client
    TS_FILES        ${TS_FILES}
    SOURCES         ${POKERTH_QML_CLIENT_SRC} ${QML_FILES}
    RESOURCE_PREFIX "/i18n"
)

add_executable(pokerth_qml-client "${POKERTH_QML_CLIENT_SRC}" "${QTSINGLEAPPLICATION_SRC}")

target_include_directories(pokerth_qml-client PUBLIC
    ../../config
    ../../core
    ../../core
    ../../core/qttools
    ../../core/qttools/qthelper
    ../
    cpp)

target_link_libraries(pokerth_qml-client PUBLIC pokerth_lib)
target_link_libraries(pokerth_qml-client PUBLIC pokerth_protocol)
target_link_libraries(pokerth_qml-client PUBLIC LibCurl)
target_link_libraries(pokerth_qml-client PRIVATE Qt6::Core Qt6::Gui Qt6::Quick Qt6::Qml Qt6::Sql Qt6::Xml Qt6::Svg Qt6::QuickControls2 Qt6::Widgets)

target_compile_definitions(pokerth_qml-client PUBLIC QML_CLIENT)

install(TARGETS pokerth_qml-client DESTINATION bin OPTIONAL)
install(DIRECTORY ../../../data DESTINATION share/pokerth)
install(FILES ../../../pokerth_qml.desktop DESTINATION share/applications)
install(FILES ../../../pokerth.png DESTINATION share/pixmaps)
