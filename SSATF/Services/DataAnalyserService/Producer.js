require('dotenv').config();
const { Kafka } = require('kafkajs');
const { Partitioners } = require('kafkajs');
const BROKER = process.env.KAFKA_BROKER;
const CLIENT_ID = process.env.PRODUCER_CLIENT_ID || 'data-processor-producer';
const ENRICHED_TOPIC = process.env.ENRICHED_TOPIC || 'data-enriched-transactions';

const kafka = new Kafka({
  clientId: CLIENT_ID,
  brokers: [BROKER]
});

const producer = kafka.producer({
  createPartitioner: Partitioners.LegacyPartitioner
});
const connectProducer = async () => {
  try {
    await producer.connect();
    console.log(' Kafka Producer connected (Data Processor)');
  } catch (error) {
    console.error(' Failed to connect Kafka producer:', error.message);
    process.exit(1);
  }
};

const sendEnrichedTransaction = async (enrichedTx) => {
  try {
    return await producer.send({
      topic: ENRICHED_TOPIC,
      messages: [
        {
          key: enrichedTx.transactionId?.toString() || null,
          value: JSON.stringify(enrichedTx)
        }
      ]
    });
  } catch (error) {
    console.error(' Error sending enriched transaction:', error.message);
  }
};

const disconnectProducer = async () => {
  try {
    await producer.disconnect();
    console.log(' Kafka Producer disconnected');
  } catch (error) {
    console.error(' Error during producer disconnect:', error.message);
  }
};

module.exports = {
  connectProducer,
  sendEnrichedTransaction,
  disconnectProducer
};
