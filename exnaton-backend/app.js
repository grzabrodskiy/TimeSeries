'use strict'

require('dotenv').config()

const axios = require('axios').create({
  withCredentials: true,
});
const express = require('express')
const bodyParser = require('body-parser')

const app = new express();
app.use(bodyParser.json());

const mongoUri = `mongodb://${process.env.MONGO_USER}:${process.env.MONGO_PASSWORD}@${process.env.MONGO_HOST}/${process.env.MONGO_DBNAME}?retryWrites=true&w=majority`;
const MongoClient = require('mongodb').MongoClient;
MongoClient.connect(mongoUri, (err, database) => {
  if (err) return console.log(err);

  const db = database.db('exnaton');
  require('./routes/measurements')(app, db);
  
  checkMeasurmentsAndFillIfEmpty(db)
    .then(() => {
      
      app.listen(process.env.PORT, () => {
        console.log('We are live on ' + process.env.PORT);
      });
    }).catch((e) => {
      console.log(e);
    });
});

async function checkMeasurmentsAndFillIfEmpty(db) {
  const exnatonExternalApiBaseUrl = process.env.EXNATON_BASE_URL;
  const measurmentCollectionExists = await db.listCollections({name: 'measurements'}).hasNext();
  if (!measurmentCollectionExists) {
    const authResponse = await axios.post(`${exnatonExternalApiBaseUrl}/authentication/auth`, {
      email: process.env.EXNATON_USER,
      password: process.env.EXNATON_PASSWORD,
    });
    const cookies = authResponse.headers['set-cookie'][0];
    const sessionCookie = cookies.substring(0, cookies.indexOf(';'));

    const measurementsResponse = await axios.get(`${exnatonExternalApiBaseUrl}/meterdata/measurement`, {
      params: {
        muid: '7eb6cb7a-bd74-4fb3-9503-0867b737c2f6',
        start: '2021-05-01T00:00:00Z',
        stop: '2021-07-01T23:59:59Z',
        limit: '1000000000'
      },
      headers:{
        Cookie: sessionCookie,
      }
    });
    const measurements = measurementsResponse.data['data'].map((measurement) => {
      return { 
        "measurement": measurement['measurement'],
        "positiveEnergy": measurement['0100010700FF'],
        "negativeEnergy": measurement['0100020700FF'],
        "balanceEnergy": measurement['0100100700FF'],
        "tags": measurement['tags'],
        "timestamp": measurement['timestamp'],
        "date": {
          "year": new Date(measurement['timestamp']).getFullYear(),
          "month": new Date(measurement['timestamp']).getMonth(),
          "day": new Date(measurement['timestamp']).getDate(),
          "dayOfWeek": new Date(measurement['timestamp']).getDay(),
        }
      };
    });
    await db.collection('measurements').createIndex({ "date.month": 1 });
    await db.collection('measurements').insertMany(measurements);
  }
}