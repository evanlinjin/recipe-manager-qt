#ifndef NETWORKMANAGER_H
#define NETWORKMANAGER_H

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QUrl>
#include <QJsonObject>
#include <QJsonDocument>
#include <QJsonArray>
#include <QDebug>

#include "dstypes.h"
#include "ongoingcommands.h"

class NetworkManager : public QObject
{
    Q_OBJECT
public:
    explicit NetworkManager(QString url, QString token, QObject *parent = 0);

private:
    QNetworkAccessManager* nm;
    OngoingCommands m_cmds;
    QUrl m_url;
    QString m_token;

signals:
    void recieved_error(QString cmd, QString msg);

    void recieved_measurements(QList<DSMeasurement>);
    void recieved_get_all_ingredients(QList<DSIngredient>);

public slots:
    void get_measurements();
    void get_all_ingredients();

private slots:
    void process_measurements(QJsonValue v);
    void process_get_all_ingredients(QJsonValue v);

    void handleRequest(QString cmd, QJsonValue v);
    void handleReply(QNetworkReply* reply);
};

#endif // NETWORKMANAGER_H
