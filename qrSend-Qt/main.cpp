#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include "../libQrSend.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    QString url;
    url.sprintf("http://%s/",GoServer());
    QQmlApplicationEngine engine;
    engine.load(QUrl(QStringLiteral("qrc:/main.qml")));
    engine.rootObjects().first()->setProperty("url",url);
    if (engine.rootObjects().isEmpty())
        return -1;
    return app.exec();
}
