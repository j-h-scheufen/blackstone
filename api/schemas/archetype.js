const Joi = require('joi');

/*

sample archetype:
{
  name: 'archetype name',
  author: '36ADA22D3A4B841EFB73414CD97C35C0A660C1C2',
  description: 'things about this archetype',
  isPrivate: 1,
  active: 1,
  parameters: [
    { type: 0, name: 'bool' },
    { type: 1, name: 'string' },
    { type: 2, name: 'num' },
    { type: 3, name: 'date' },
    { type: 4, name: 'datetime' },
    { type: 5, name: 'money' },
    { type: 6, name: 'user' },
    { type: 7, name: 'addr' },
    { type: 8, name: 'signatory' },
  ],
  executionProcessDefinition: '8010494870E1A8B2BA3F05CCCCDBFA337BF5F064',
  formationProcessDefinition: '0506903B34830785168D840BB70D7D48D31A5C1F',
  jurisdictions: [
    {
      country: 'CA',
      regions: [
        '9CD6EEC0C135A0DEC4176812CE66259A61CB5075E1494A123383E2A12A45691C',
        '26F96B983F45DA344CE851B10C57D7E35063D70F08D07E6B9DE9EDC171292FFB',
        '6B76BFAF03C7F62FBAB330430E56863F149153120FC38638930BEEC724089C06',
      ],
    },
    { country: 'US', regions: ['0000000000000000000000000000000000000000000000000000000000000000'] },
  ],
  documents: [
    {
      name: 'pdf-test.pdf',
      address: 'ffb95e8c8d8346c9a63f83078f2a6577b5c3c50896e8b3e5aab4ee4ae3ea9880',
      secretKey: '8265c79f5e52c59b141f2113e10c7c3b08278cebf8f958be69d882329bff31fc',
    },
    {
      name: 'test.md',
      address: '53920144769c88f6359a8f7e0eddae979a4363482fddbdc6f89ae4026a055de8',
      secretKey: '93b4101e36ddeb7989f38b9657104a76fc6af144912d376d294d40a4a50e0360',
    },
  ],
  packageId: '9BBC0DA311D1C72DF9287B49E0DF1D2AF3BA26375BB3B546C679DD8B4FC21252',
  governingArchetypes: [
    '686b6aefa7467db432903d4fed9cd23c2ee6bd57'
    '3a2629aa5ad584877212e16dc4b2b0e778acf4b9'
    'c969b9e29fb9f65299b474c18e4bbd5340124db2'
    'd2534600f8bdf6eadfe360bf2ff3f2c8e5514e71'
  ]
};
*/

const archetypeSchema = Joi.object().keys({
  name: Joi.string()
    .required(),
  password: Joi.string().optional(),
  author: Joi.string()
    .hex()
    .required(),
  description: Joi.string().required(),
  price: Joi.number().optional().default(0),
  isPrivate: [
    Joi.boolean(),
    Joi.number()
      .integer()
      .min(0)
      .max(1),
  ],
  active: [
    Joi.boolean(),
    Joi.number()
      .integer()
      .min(0)
      .max(1),
  ],
  formationProcessDefinition: Joi.string()
    .hex()
    .required(),
  executionProcessDefinition: Joi.string()
    .hex()
    .required(),
  jurisdictions: Joi.array().items(
    Joi.object().keys({
      country: Joi.string()
        .alphanum()
        .required(),
      regions: Joi.array()
        .items(Joi.string().hex())
        .required(),
    }),
  ),
  documents: Joi.array().items(
    Joi.object().keys({
      name: Joi.string(),
      address: Joi.string().hex(),
      secretKey: Joi.string().hex(),
    }),
  ),
  parameters: Joi.array().items(
    Joi.object().keys({
      type: Joi.number()
        .min(0)
        .max(12),
      name: Joi.string().max(32, 'utf8'),
      signatory: Joi.boolean(),
    }),
  ),
  packageId: Joi.string().optional().default(''),
  governingArchetypes: Joi.array().items(Joi.string().hex()).optional(),
});

module.exports = archetypeSchema;
