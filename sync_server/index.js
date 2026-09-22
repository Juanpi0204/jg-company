const express = require('express');
const cors = require('cors');
const { MongoClient } = require('mongodb');

const app = express();
const port = process.env.PORT || 10000;

const uri = process.env.MONGO_URI || 'mongodb+srv://juangarces028_db_user:Juan.123@cluster0.b4inhbz.mongodb.net/jg_company?retryWrites=true&w=majority';
let client;
let db;

async function getDb() {
  if (!client) {
    client = new MongoClient(uri);
    await client.connect();
    db = client.db('jg_company');
    console.log('✅ Conectado a MongoDB Atlas (jg_company)');
  }
  return db;
}

app.use(cors());
app.use(express.json({ limit: '10mb' }));

// ── GET /status ─────────────────────────────────────────────────────────────
app.get('/status', async (req, res) => {
  try {
    const database = await getDb();
    const cols = await database.listCollections().toArray();
    res.json({
      status: 'connected',
      database: 'jg_company',
      collections: cols.map(c => c.name),
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    res.status(500).json({ status: 'error', message: err.message });
  }
});

// ── POST /sync ──────────────────────────────────────────────────────────────
app.post('/sync', async (req, res) => {
  try {
    const database = await getDb();
    const {
      accounts = [],
      clients = [],
      providers = [],
      creditCards = [],
      // forceEmpty: true solo si el usuario borró todos los datos intencionalmente
      forceEmpty = false
    } = req.body;

    console.log(`📥 [SYNC] Recibido: ${accounts.length} pantallas, ${clients.length} clientes, ${providers.length} proveedores, ${creditCards.length} tarjetas`);

    // ── REGLA DE SEGURIDAD ANTI-BORRADO ─────────────────────────────────────
    // Si todos los arrays están vacíos y forceEmpty no es true,
    // es probable que sea un sync accidental desde dispositivo sin datos locales.
    // En ese caso NO tocamos MongoDB.
    const todosVacios = accounts.length === 0 && clients.length === 0 &&
                        providers.length === 0 && creditCards.length === 0;
    if (todosVacios && !forceEmpty) {
      console.log('⚠️ [SYNC] Todos los arrays vacíos sin forceEmpty=true. Sync ignorado para proteger datos.');
      return res.json({
        ok: true,
        message: 'Sync ignorado: arrays vacíos sin forceEmpty. Datos en MongoDB protegidos.',
        protected: true,
        timestamp: new Date().toISOString()
      });
    }

    // 1. Sincronizar Pantallas
    const colPantallas = database.collection('pantallas');
    const accountIds = accounts.map(a => String(a.id)).filter(Boolean);

    if (accountIds.length > 0) {
      await colPantallas.deleteMany({ id: { $nin: accountIds } });
      for (const acc of accounts) {
        if (acc.id) {
          const doc = { ...acc };
          delete doc._id;
          await colPantallas.replaceOne({ id: String(acc.id) }, doc, { upsert: true });
        }
      }
    } else if (forceEmpty) {
      // Solo borrar si el usuario explícitamente quiere borrar todo
      await colPantallas.deleteMany({});
    }
    // Si accountIds.length === 0 y !forceEmpty, no tocamos la colección

    // 2. Sincronizar Clientes
    const colClientes = database.collection('clientes');
    const clientIds = clients.map(c => String(c.id)).filter(Boolean);

    if (clientIds.length > 0) {
      await colClientes.deleteMany({ id: { $nin: clientIds } });
      for (const cl of clients) {
        if (cl.id) {
          const doc = { ...cl };
          delete doc._id;
          await colClientes.replaceOne({ id: String(cl.id) }, doc, { upsert: true });
        }
      }
    } else if (forceEmpty) {
      await colClientes.deleteMany({});
    }

    // 3. Sincronizar Proveedores
    const colProveedores = database.collection('proveedores');
    const providerIds = providers.map(p => String(p.id)).filter(Boolean);

    if (providerIds.length > 0) {
      await colProveedores.deleteMany({ id: { $nin: providerIds } });
      for (const pr of providers) {
        if (pr.id) {
          const doc = { ...pr };
          delete doc._id;
          await colProveedores.replaceOne({ id: String(pr.id) }, doc, { upsert: true });
        }
      }
    } else if (forceEmpty) {
      await colProveedores.deleteMany({});
    }

    // 4. Sincronizar Tarjetas de Crédito
    const colTarjetas = database.collection('tarjetas_credito');
    const cardIds = creditCards.map(c => String(c.id)).filter(Boolean);

    if (cardIds.length > 0) {
      await colTarjetas.deleteMany({ id: { $nin: cardIds } });
      for (const card of creditCards) {
        if (card.id) {
          const doc = { ...card };
          delete doc._id;
          await colTarjetas.replaceOne({ id: String(card.id) }, doc, { upsert: true });
        }
      }
    } else if (forceEmpty) {
      await colTarjetas.deleteMany({});
    }

    console.log(`✅ [SYNC EXITOSO] MongoDB Atlas actualizado.`);

    res.json({
      ok: true,
      message: 'Sincronización exitosa con MongoDB Atlas',
      syncedAccounts: accounts.length,
      syncedClients: clients.length,
      syncedProviders: providers.length,
      syncedCreditCards: creditCards.length,
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    console.error('❌ [SYNC ERROR]:', err);
    res.status(500).json({ ok: false, error: err.message });
  }
});

// ── GET /pull ───────────────────────────────────────────────────────────────
app.get('/pull', async (req, res) => {
  try {
    const database = await getDb();
    const colPantallas = database.collection('pantallas');
    const colClientes = database.collection('clientes');
    const colProveedores = database.collection('proveedores');
    const colTarjetas = database.collection('tarjetas_credito');

    const accounts = await colPantallas.find().toArray();
    const clients = await colClientes.find().toArray();
    const providers = await colProveedores.find().toArray();
    const creditCards = await colTarjetas.find().toArray();

    accounts.forEach(a => delete a._id);
    clients.forEach(c => delete c._id);
    providers.forEach(p => delete p._id);
    creditCards.forEach(c => delete c._id);

    res.json({
      ok: true,
      accounts,
      clients,
      providers,
      creditCards
    });
  } catch (err) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

app.listen(port, '0.0.0.0', () => {
  console.log(`🚀 JG COMPANY Sync Server corriendo en puerto ${port}`);
});
