'use strict';
// create router out of Express.js
const Router = require('express');
// server side of back end / expressJS

// API to retrieve measurements from the server 
// the measurements are stored in MongoDB (collection 'measurements')
const getMeasurements = (app, db) => {
    const router = new Router();
    // import Router, router listens to HTTP and is a server, only has GET here but can support all other HTTP commands (post, delete, etc)
// can just delete the database instance, basically my cache, can implement a refresh or flush function on the client that deletes the database and makes you re-fetch info from external server

    // HTTP GET method - return all measurements
    router.get('/', async (req, res) => {// not used, wanted to do on the server side, then figured client is fast enough
    // if we called this, we'd need to call http://url.com/groupby
        const measurements = await db.collection('measurements').find({}, {_id: 0, "date": 0}).toArray();
        res.status(200).json({measurements: measurements}).end(); // send positive status, convert to JSON, send to client
    });
    // HTTP GET method to /group - return grouped measurements: supports grouppedBy={month|day|weekday}
    router.get('/grouped', async (req, res) => {
        const groupedBy = req.query.by;
        if (groupedBy == "month") { // https://www.google.com/groupby?by=month
            // group by query to MongoDB aggreging by month
            const measurementsGroupedByMonth = await db.collection('measurements').aggregate([//aggregate is "groupby" statement in database
                {
                    $group : {// saying which group to aggregate
                        _id : { weekday: "$date.month" },// aggregate by month
                        measurements: { $push: "$$ROOT" } // pushing all fields (root = shortcut for all fields)
                    }
                }
            ]).toArray();
            res.status(200).json({measurements: measurementsGroupedByMonth}).end(); // sends aggregated results back
        } else if (groupedBy == "day") {// aggregate by day
            const measurementsGroupedByDay = await db.collection('measurements').aggregate([
                {
                    $group : {
                        _id : { weekday: "$date.day" }, // aggregate by day
                        measurements: { $push: "$$ROOT" } // pushing all fields (root = shortcut for all fields)
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
        } // if dont understand the parameter Url, send error
    });

    app.use('/measurements', router);
    // when your client uses greg.com/measurements, you will invoke the router with this
}
// defaul method of the module to be exported
module.exports = getMeasurements;

// when you load this whole file (module), you will load the getMeasurement function (entire thing)
