#include <QtCore>
#include <QtQml>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QSettings>
#include <QQmlContext>
#include <configfile.h>
#include <QDomDocument>
#include <QDomElement>
#include <QDebug>

#include "qmlwrapper.h"
// #include "startviewimpl.h"
// #include "createlocalgameviewimpl.h"

QmlWrapper::QmlWrapper(boost::shared_ptr<ConfigFile> c)
    :QObject(), myConfig(c)
{
    
    myQmlEngine = new QQmlApplicationEngine;

    // make QSettings use the default PokerTH config.xml :
    const QSettings::Format XmlFormat = QSettings::registerFormat("xml", &readXmlFile, &writeXmlFile);
    QFileInfo fi(QString::fromStdString(myConfig->configFileName));
    QSettings::setPath(XmlFormat, QSettings::UserScope, fi.absolutePath().remove("/.pokerth"));
    QSettings settings(XmlFormat, QSettings::UserScope, ".pokerth", "config");

    if (qEnvironmentVariableIsEmpty("QT_QUICK_CONTROLS_STYLE"))
        QQuickStyle::setStyle(settings.value("style").toString());
    const QString styleInSettings = settings.value("style").toString();
    if (styleInSettings.isEmpty())
        settings.setValue(QLatin1String("style"), QQuickStyle::name());

    //TODO create Session and Log here

    // myStartViewImpl = new StartViewImpl(this);
    // myCreateLocalGameViewImpl = new CreateLocalGameViewImpl(this, myQmlEngine, myConfig, myStartViewImpl);

    // //Add c++ content to QML here
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

bool QmlWrapper::readXmlFile(QIODevice &device, QSettings::SettingsMap &map){

    QDomDocument xmlDoc;
    xmlDoc.setContent(device.readAll());
    QDomElement conf = xmlDoc.documentElement().firstChildElement( "Configuration" );
    for(QDomElement n = conf.firstChildElement(); !n.isNull(); n = n.nextSiblingElement())
	{
        map.insert(n.tagName(), QVariant(n.attribute("value")));
    }
    return true;
}

bool QmlWrapper::writeXmlFile(QIODevice &device, const QSettings::SettingsMap &map){
   
    QDomDocument xmlDoc;
    QDomProcessingInstruction xmlVers = xmlDoc.createProcessingInstruction("xml","version=\"1.0\" encoding='utf-8'");
    xmlDoc.appendChild(xmlVers);

    QDomElement root = xmlDoc.createElement( "PokerTH" );
    xmlDoc.appendChild( root );

    QDomElement config = xmlDoc.createElement( "Configuration" );
    root.appendChild( config );

    QMapIterator<QString, QVariant> i(map);
    while (i.hasNext()) {
        i.next();
        QDomElement tmpElement = xmlDoc.createElement(i.key());
        config.appendChild( tmpElement );
        tmpElement.setAttribute("value", i.value().toString());
    }
    device.write(xmlDoc.toString().toStdString().c_str());
    // @TODO: send a signal to configfile class?
    return true;
}
