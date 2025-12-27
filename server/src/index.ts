import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import mongoose from 'mongoose';

import { config } from './config.js';
import { router } from './routes/index.js';
import { errorHandler } from './middleware/errorHandler.js';

async function bootstrap() {
  await mongoose.connect(config.mongoUri);

  const app = express();
  app.use(helmet());
  app.use(cors({ origin: '*', methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'] }));
  app.use(express.json());

  app.use('/api', router);

  app.use(errorHandler);

  app.listen(config.port, () => {
    // Using console.log here is acceptable to indicate server start
    console.log(`API running on http://localhost:${config.port}`);
  });
}

bootstrap().catch((err) => {
  console.error('Failed to start server', err);
  process.exit(1);
});
