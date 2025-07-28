const express = require('express');
const path = require('path');

const app = express();
const PORT = 4000;

// Serve static files from Client_UI
app.use(express.static(path.join(__dirname)));

// Route for the main HTML file
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'index.html'));
});

app.listen(PORT, () => {
  console.log(`✅ Frontend running at http://localhost:${PORT}`);
});
