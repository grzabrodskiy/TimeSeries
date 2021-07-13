'use strict';
// create router out of Express.js
const Router = require('express');

// API to retrieve measurements from the server 
// the measurements are stored in MongoDB (collection 'measurements')
const getMeasurements = (app, db) => {
    const router = new Router();

    // HTTP GET method - return all measurements
    router.get('/', async (req, res) => {
        const measurements = await db.collection('measurements').find({}, {_id: 0, "date": 0}).toArray();
        res.status(200).json({measurements: measurements}).end();
    });
    // HTTP GET method to /group - return grouped measurements: supports grouppedBy={month|day|weekday}
    router.get('/grouped', async (req, res) => {
        const groupedBy = req.query.by;
        if (groupedBy == "month") {
            // group by query to MongoDB aggreging by month
            const measurementsGroupedByMonth = await db.collection('measurements').aggregate([
                {
                    $group : {
                        _id : { weekday: "$date.month" },
                        measurements: { $push: "$$ROOT" }
                    }
                }
            ]).toArray();
            res.status(200).json({measurements: measurementsGroupedByMonth}).end();
        } else if (groupedBy == "day") {
            const measurementsGroupedByDay = await db.collection('measurements').aggregate([
                {
                    $group : {
                        _id : { weekday: "$date.day" },
                        measurements: { $push: "$$ROOT" }
                    },
                }
            ]).toArray();
            res.status(200).json({measurements: measurementsGroupedByDay}).end();
        } else if (groupedBy == "weekday") {
            const measurementsGroupedByWeekday = await db.collection('measurements').aggregate([
                {
                    $group : {
                       _id : { weekday: "$date.weekday" },
                       measurements: { $push: "$$ROOT" }
                    }
                }
            ]).toArray();
            res.status(200).json({measurements: measurementsGroupedByWeekday}).end();
        } else {
            res.status(400).json({error: "Invalid \"by\" parameter. Valid values: month, day, weekday"}).end();
        }
    });

    app.use('/measurements', router);
}
// defaul method of the module to be exported
module.exports = getMeasurements;
