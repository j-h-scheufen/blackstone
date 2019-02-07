const {
  addMeta,
  splitMeta,
  decrypt,
} = require(`${global.__common}/controller-dependencies`);
const boom = require('boom');
const Hoard = require('../hoard');
const hoard = new Hoard.Client(global.__settings.monax.hoard);

const createHoard = (req, res, next) => {
  const meta = {
    name: req.files[0].originalname,
    mime: req.files[0].mimetype,
  };

  const plaintextIn = {
    data: addMeta(meta, req.files[0].buffer),
    salt: req.body.salt ? Buffer.from(req.body.salt) : Buffer.from(process.env.HOARD_SALT),
  };

  hoard
    .put(plaintextIn)
    .then((_ref) => {
      const ref = Object.assign(_ref, {
        address: _ref.address.toString('hex'),
        secretKey: _ref.secretKey.toString('hex'),
      });
      res.status(200).json(ref);
      return next();
    })
    .catch(err => next(boom.badImplementation(err)));
};

const getHoard = (req, res, next) => {
  const ref = {
    address: Buffer.from(req.query.address, 'hex'),
    secretKey: Buffer.from(req.query.secretKey, 'hex'),
    salt: req.query.salt ? Buffer.from(req.query.salt) : Buffer.from(process.env.HOARD_SALT),
  };

  if (req.query.password != null) {
    ref.secretKey = decrypt(ref.secretKey, req.query.password);
  }

  hoard
    .get(ref)
    .then((_data) => {
      const data = splitMeta(_data);

      if (req.query.meta === 'true') {
        res.status(200).send(data);
      } else {
        res.attachment(data.meta.name);
        res.status(200).send(data.data);
      }

      return next();
    })
    .catch(err => next(boom.badImplementation(err)));
};

const getModelFromHoard = ({ address, secretKey }) => new Promise(async (resolve, reject) => {
  try {
    const hoardRef = {
      address: Buffer.from(address, 'hex'),
      secretKey: Buffer.from(secretKey, 'hex'),
      salt: Buffer.from(process.env.HOARD_SALT),
    };
    const data = await hoard.get(hoardRef);
    return resolve(data);
  } catch (err) {
    return reject(err);
  }
});

module.exports = {
  hoard,
  createHoard,
  getHoard,
  getModelFromHoard,
};
