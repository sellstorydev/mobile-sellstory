const fs = require('fs');

try {
  const data = JSON.parse(fs.readFileSync('./backup-workspaces-xKnLu20t7n6A0IJxl4NN-2025-09-07T10-12-24.json', 'utf8'));

  // Look for cards with customer data
  let foundCards = 0;
  const allCustomers = new Set();
  const allCustomerIds = new Set();

  function searchCards(obj, path = '') {
    if (obj && typeof obj === 'object') {
      if (obj.title && (obj.customer || obj.customerId)) {
        foundCards++;
        console.log(`Found card: ${obj.title}`);
        console.log(`  Customer: "${obj.customer || ''}"`);
        console.log(`  Customer ID: "${obj.customerId || ''}"`);
        
        if (obj.customer) {
          allCustomers.add(obj.customer);
        }
        if (obj.customerId) {
          allCustomerIds.add(obj.customerId);
        }
        console.log('');
      }
      
      for (const key in obj) {
        searchCards(obj[key], path + '.' + key);
      }
    }
  }

  searchCards(data);
  console.log(`Summary: ${foundCards} cards found with customer data`);
  console.log(`Unique customer names: ${Array.from(allCustomers).join(', ')}`);
  console.log(`Unique customer IDs: ${Array.from(allCustomerIds).join(', ')}`);
} catch (error) {
  console.error('Error:', error.message);
}
