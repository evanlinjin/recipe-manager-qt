#include "ingredienteditwindowmodel.h"

IngredientEditWindowModel::IngredientEditWindowModel(QObject *parent) :
    Ingredient(parent), m_editMode(true), m_ready(false) {
}

QObject* IngredientEditWindowModel::getVolumesObj(int i) {
    return m_volumes.value<QList<QObject*> >().at(i);
}

QObject* IngredientEditWindowModel::getWeightsObj(int i) {
    return m_weights.value<QList<QObject*> >().at(i);
}

QString IngredientEditWindowModel::get_nid() {
    return QString("ingredient_edit_window_model ") + name();
}

void IngredientEditWindowModel::linkUp(QString key, NetworkManager* nm, MeasurementsModel *mm, IngredientsModel *im) {
    this->nManager = nm; this->mModel = mm; this->iModel = im;

    if (nm == nullptr || mm == nullptr || im == nullptr) {
        qDebug() << "[IngredientEditWindowModel::linkUp] recieved nullptr!?";
        return;
    }

    this->reloadMeasurements();

    this->m_editMode = (key != QString("")); emit editModeChanged();
    if (!m_editMode) {
        setReady();
        return;
    }

    connect(nm, SIGNAL(recieved_get_ingredient_of_key(DSIngredient,QString)),
            this, SLOT(process_get_ingredient_of_key_reply(DSIngredient,QString)));

    nm->get_ingredient_of_key(key, get_nid());
}

void IngredientEditWindowModel::addTag(QString v) {
    v = v.trimmed().toLower();
    auto newTags = this->tags();
    for (int i = 0; i < newTags.size(); i++) {
        if (newTags.at(i) == v) return;
    }
    newTags.append(v);
    newTags.sort();
    this->setTags(newTags);
}

void IngredientEditWindowModel::removeTag(QString v) {
    v = v.trimmed().toLower();
    auto newTags = this->tags();
    for (int i = 0; i < newTags.size(); i++) {
        if (newTags.at(i) == v) newTags.removeAt(i);
    }
    newTags.sort();
    this->setTags(newTags);
}

void IngredientEditWindowModel::changeConversion(QString wv, int wu, QString vv, int vu) {
    double weightValue = wv.toDouble();
    double weightMultiply = getWeightsObj(wu)->property("multiply").toDouble();
    double volumeValue = vv.toDouble();
    double volumeMultiply = getVolumesObj(vu)->property("multiply").toDouble();

    if (weightValue <= 0 || weightMultiply <= 0 || volumeValue <= 0 || volumeMultiply <= 0) {
        qDebug() << "Invalid input...";
        return;
    }

    double kgs = (weightValue * weightMultiply) / 1000;
    double cps = (volumeValue * volumeMultiply) / 0.24;
    setKgPCup(kgs/cps);
}

void IngredientEditWindowModel::process_get_ingredient_of_key_reply(DSIngredient v, QString id) {
    if (id != get_nid()) return;
    this->setM(v);
    emit qmlUpdateNeeded();
    this->setReady();
}

void IngredientEditWindowModel::reloadMeasurements() {
    this->m_volumes = mModel->getVolumeMeasurements(); emit volumesChanged();
    this->m_weights = mModel->getWeightMeasurements(); emit weightsChanged();
}

void IngredientEditWindowModel::revertChanges() {
    setNotReady();
    nManager->get_ingredient_of_key(this->name(), get_nid());
}

void IngredientEditWindowModel::submitChanges() {
    if (editMode()) {
        nManager->modify_ingredient(this->getM(), get_nid());
    } else {
        nManager->add_ingredient(this->getM(), get_nid());
    }
}
