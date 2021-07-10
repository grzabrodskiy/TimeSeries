'use strict';
const Router = require('express');

const getMeasurements = (app, db) => {
    const router = new Router();

    router.get('/', async (req, res) => {
        const measurements = await db.collection('measurements').find({}, {"date": false}).toArray();
        res.status(200).json({measurements: measurements}).end();
    });

    router.get('/grouped', async (req, res) => {
        const groupedBy = req.query.by;
        if (groupedBy == "month") {
            res.status(500).end(); //TODO
        } else if (groupedBy == "day") {
            res.status(500).end(); //TODO
        } else if (groupedBy == "weekday") {
            res.status(500).end(); //TODO
        } else {
            res.status(400).json({error: "Invalid \"by\" parameter. Valid values: month, day, weekday"}).end();
        }
    });

    app.use('/measurements', router);
}

module.exports = getMeasurements;