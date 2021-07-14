'use strict' // every variable needs to be defined
// "main" Express.js module
require('dotenv').config() // require like import, dotenv package

// used to authenticate, query external API, connect their external server
const axios = require('axios').create({
  withCredentials: true, // parameter for auth
});
// used for simple HTTP server
const express = require('express') // imports express.js
const bodyParser = require('body-parser') // imports json parser
// used to get the data across external and own servers
var cors = require('cors') // imports cors

// our app
const app = new express();
app.use(bodyParser.json());
app.use(cors());
// creates/loads express.js (simple HTTP server) app, and app can use parser and cors to be used by the app
// our database
// MongoDB,  NoSQL database to store measurements in JSON format
const mongoUri = `mongodb://${process.env.MONGO_USER}:${process.env.MONGO_PASSWORD}@${process.env.MONGO_HOST}/${process.env.MONGO_DBNAME}?retryWrites=true&w=majority`;
const MongoClient = require('mongodb').MongoClient; // imports mongo DB
MongoClient.connect(mongoUri, (err, database) => { // connects spp to mongoDB
  if (err) return console.log(err); // error return statement

  const db = database.db('exnaton'); // create database object
  require('./routes/measurements')(app, db); // call main function (measurements), pass app and database as parameters
  
  checkMeasurmentsAndFillIfEmpty(db)
    .then(() => {
      
      app.listen(process.env.PORT, () => { // listens (waits for client to reach it) to port and tells app to use it
        console.log('We are live on ' + process.env.PORT); // waiting for client request, binds to port, sits on this port waiting for request to come
      });
    }).catch((e) => {
      console.log(e);
    });
});
// read measurements from external API
async function checkMeasurmentsAndFillIfEmpty(db) { // THIS IS CLIENT / DATABASE
  // read env variables (set by docker)
  const exnatonExternalApiBaseUrl = process.env.EXNATON_BASE_URL;
  const measurmentCollectionExists = await db.listCollections({name: 'measurements'}).hasNext();
  if (!measurmentCollectionExists) { // if not populated
    // authenticate with userID and password from env variables (set by docker)
    const authResponse = await axios.post(`${exnatonExternalApiBaseUrl}/authentication/auth`, {
      email: process.env.EXNATON_USER, // passing userid password given to us, env in docker
      password: process.env.EXNATON_PASSWORD,
    });
    // after the authentication, use sessionID for HTTP GET requests
    const cookies = authResponse.headers['set-cookie'][0];
    const sessionCookie = cookies.substring(0, cookies.indexOf(';'));
    // read the measurements with required parameters
    // parameters are hard-coded for visibility (can be moved to env variables)
    const measurementsResponse = await axios.get(`${exnatonExternalApiBaseUrl}/meterdata/measurement`, {
      params: {
        muid: '7eb6cb7a-bd74-4fb3-9503-0867b737c2f6',
        start: '2021-05-01T00:00:00Z',
        stop: '2021-06-30T23:59:59Z',
        limit: '1000000000' // wouldnt hard-code if production, either put in environment variables or put some UI, for display purposesr
      },
      headers:{
        Cookie: sessionCookie, // passing sessionCookie for authentication
      }
    });
    // reading measurements JSON array
    const measurements = measurementsResponse.data['data'].map((measurement) => { // reads JSON and uses map to convert to structure
      // use Axios to GET information from external HTTP server
      return { 
        "measurement": measurement['measurement'],// for example, here map takes measurement and converts it to new field "measurement"
        "positiveEnergy": measurement['0100010700FF'],// create list of structures to later be stored in local database from the list of JSON records
        "negativeEnergy": measurement['0100020700FF'],
        "balanceEnergy": measurement['0100100700FF'],
        "tags": measurement['tags'],
        "timestamp": measurement['timestamp'],
        "date": {
          "year": new Date(measurement['timestamp']).getFullYear(),
          "month": new Date(measurement['timestamp']).getMonth(),
          "day": new Date(measurement['timestamp']).getDate(),
          "weekday": new Date(measurement['timestamp']).getDay(),
        }
      };// map says that for every element of a collection, apply the function
    });
    // creating db indices for faster grouping
    await db.collection('measurements').createIndex({ "date.month": 1 });
    await db.collection('measurements').createIndex({ "date.day": 1 }); // client will use own group anyway
    await db.collection('measurements').createIndex({ "date.weekday": 1 });
    // inserting all the measurement records into measurement collection of our database
    await db.collection('measurements').insertMany(measurements);// store all in MANGO data-base
  }
}// map and filter are functions of stream
