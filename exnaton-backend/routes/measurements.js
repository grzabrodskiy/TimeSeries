'use strict';
const Router = require('express');

const getMeasurements = (app, db) => {
    const router = new Router();
    const measurmentsCollection = db.collection('measurements');

    router.get('/', async (req, res) => {
        const measurements = await measurmentsCollection.find().toArray();
        res.status(200).json({measurements: measurements}).end();
    });

    app.use('/measurements', router);
}

module.exports = getMeasurements;