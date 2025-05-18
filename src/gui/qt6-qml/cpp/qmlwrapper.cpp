#include <QtCore>
#include <QtQml>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QSettings>
#include <QQmlContext>
#include <configfile.h>

#include "qmlconfig.h"
#include "qmlwrapper.h"
// #include "startviewimpl.h"
// #include "createlocalgameviewimpl.h"

QmlWrapper::QmlWrapper(boost::shared_ptr<ConfigFile> c)
    :QObject(), myConfig(c)
{
    myQmlEngine = new QQmlApplicationEngine;
    myQmlConfig = new QmlConfig(myConfig);

    QSettings settings;
    if (qEnvironmentVariableIsEmpty("QT_QUICK_CONTROLS_STYLE"))
        QQuickStyle::setStyle(settings.value("style").toString());

    // If this is the first time we're running the application,
    // we need to set a style in the settings so that the QML
    // can find it in the list of built-in styles.
    const QString styleInSettings = settings.value("style").toString();
    if (styleInSettings.isEmpty())
        settings.setValue(QLatin1String("style"), QQuickStyle::name());

    //TODO create Session and Log here

    // myStartViewImpl = new StartViewImpl(this);
    // myCreateLocalGameViewImpl = new CreateLocalGameViewImpl(this, myQmlEngine, myConfig, myStartViewImpl);

    // //Add c++ content to QML here
    myQmlEngine->rootContext()->setContextProperty("Config", myQmlConfig);
    // myQmlEngine->rootContext()->setContextProperty("StartViewImpl", myStartViewImpl);
    // myQmlEngine->rootContext()->setContextProperty("CreateLocalGameViewImpl", myCreateLocalGameViewImpl);

    myQmlEngine->load(QUrl(QStringLiteral("qrc:/pokerth.qml")));
}

QmlWrapper::~QmlWrapper()
{
    myQmlEngine->deleteLater();
}

QmlWrapper::QmlWrapper(const QmlWrapper&)
    :QObject()
{

}


