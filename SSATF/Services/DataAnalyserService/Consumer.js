const { Kafka } = require('kafkajs');
require('dotenv').config();

const KAFKA_BROKER = process.env.KAFKA_BROKER;
const CLIENTID = process.env.CLIENTID;
const TOPIC = process.env.TOPIC;
const GROUPID = process.env.GROUPID;

const kafka = new Kafka({
  clientId: CLIENTID,
  brokers: [KAFKA_BROKER],
});

const consumer = kafka.consumer({ groupId: GROUPID });

// The startConsumer function takes a message handler callback
const startConsumer = async (messageHandler) => {
  await consumer.connect();
  console.log('Connected to Kafka broker (Consumer)');

  await consumer.subscribe({ topic: TOPIC, fromBeginning: true });
  console.log(`Subscribed to topic: ${TOPIC}`);

  await consumer.run({
    eachMessage: async ({ topic, partition, message }) => {
      try {
        await messageHandler({ topic, partition, message });
      } catch (err) {
        console.error('Error in message handler:', err);
      }
    },
  });
};

// Export startConsumer for usage in index.js
module.exports = {
  startConsumer,
  disconnectConsumer: async () => {
    await consumer.disconnect();
  }
};
