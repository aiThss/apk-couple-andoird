import express from 'express';
import cors from 'cors';
import mongoose from 'mongoose';
import morgan from 'morgan';
import { config } from './config.js';
import { errorHandler, notFound } from './errors.js';
import { router } from './routes.js';

const app = express();

app.set('trust proxy', true);
app.use(cors({ origin: config.corsOrigin === '*' ? true : config.corsOrigin }));
app.use(express.json({ limit: '1mb' }));
app.use(morgan(config.nodeEnv === 'production' ? 'combined' : 'dev'));
app.use('/uploads', express.static(config.uploadDir));
app.use('/api', router);
app.use(notFound);
app.use(errorHandler);

await mongoose.connect(config.mongoUri);

app.listen(config.port, () => {
  console.log(`Couple Snap API listening on :${config.port}`);
});
