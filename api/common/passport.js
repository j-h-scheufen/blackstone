const boom = require('boom');
const jwt = require('jsonwebtoken');
const passportJwt = require('passport-jwt');
const bcrypt = require('bcryptjs');
const { app_db_pool } = require(`${global.__common}/postgres-db`);
const JwtStrategy = passportJwt.Strategy;
const LocalStrategy = require('passport-local').Strategy;
const contracts = require(`${global.__controllers}/contracts-controller`);
const sqlCache = require(`${global.__controllers}/postgres-query-helper`);
const { getSHA256Hash } = require(`${global.__common}/controller-dependencies`);

module.exports = (passport) => {
  const isValidUser = async (id) => {
    try {
      await contracts.getUserById(getSHA256Hash(id));
      return true;
    } catch (err) {
      if (err.output.statusCode === 404) {
        return false;
      }
      throw err;
    }
  };

  const cookieExtractor = (req) => {
    let token = null;
    if (req && req.cookies) {
      token = req.cookies['access_token'];
    }
    return token;
  };

  const jwtOpts = {
    jwtFromRequest: cookieExtractor,
    secretOrKey: global.__settings.monax.jwt.secret,
    issuer: global.__settings.monax.jwt.issuer,
    passReqToCallback: true,
    jsonWebTokenOptions: {
      expiresIn: global.__settings.monax.jwt.expiresIn,
    },
  };

  const usernameOpts = {
    usernameField: 'username',
    passwordField: 'password',
    passReqToCallback: true,
  };

  const emailOpts = {
    usernameField: 'email',
    passwordField: 'password',
    passReqToCallback: true,
  };

  passport.serializeUser((user, done) => {
    done(null, user);
  });

  passport.deserializeUser((user, done) => {
    done(null, user);
  });

  /*
  Local Strategy Flow:
  Get address hashed userId from chain
  Get address from vent using hashed userId
  Compare chain address to vent address and return unauthorized on mismatch
  Get address and password digest from pg
  Compare chain address to pg address and return unauthorized on mismatch
  Compare given password with password digest and return unauthorized on mismatch
  Return success
  */
  const authenticate = async (usernameOrEmail, idType, password, done) => {
    const text = `SELECT username, email, address, password_digest, created_at, activated FROM users WHERE LOWER(${idType}) = LOWER($1)`;
    try {
      const { rows } = await app_db_pool.query({
        text,
        values: [usernameOrEmail],
      });
      if (!rows[0]) {
        return done(null, false, { message: 'Invalid login credentials' });
      }
      if (!rows[0].activated) {
        return done(null, false, { message: 'User account not yet activated' });
      }
      const {
        username, password_digest: pwDigest, address: addressFromPg, created_at: createdAt,
      } = rows[0];

      // The following section is an additional security measure.
      // The UserAccount address for the user logging in is retrieved from the the Ecosystem smart contract
      // and compared to the addresses found in the USER_ACCOUNTS Vent table as well as the
      // USERS table in the customers DB. This makes sure that we're using the correct UserAccount
      // for this user!
      const hashedId = getSHA256Hash(username);
      const { address: addressFromChain } = await contracts.getUserById(hashedId);
      const data = (await sqlCache.getUsers({ user_account_address: addressFromChain }))[0];
      if (!data) return done(null, false, { message: 'Invalid login credentials' });
      const isPassword = await bcrypt.compare(password, pwDigest);
      if (isPassword) {
        if (addressFromChain === addressFromPg && data.address === addressFromChain) {
          const token = jwt.sign(
            {
              address: addressFromChain,
              id: username,
            },
            global.__settings.monax.jwt.secret,
            {
              expiresIn: global.__settings.monax.jwt.expiresIn,
              subject: username,
              issuer: global.__settings.monax.jwt.issuer,
            },
          );
          return done(null, {
            token, address: addressFromChain, createdAt, username,
          }, { message: 'Login successful' });
        }
        return done(null, false, { message: 'Failed to login - User account address mismatch' });
      }
      return done(null, false, { message: 'Invalid login credentials' });
    } catch (err) {
      if (err.output && (err.output.statusCode === 401 || err.output.statusCode === 404)) {
        return done(null, false, { message: 'Invalid login credentials' });
      }
      return done(boom.badImplementation(err));
    }
  };
  const usernameStrategy = new LocalStrategy(usernameOpts, async (req, username, password, done) => {
    await authenticate(username, 'username', password, done);
  });

  const emailStrategy = new LocalStrategy(emailOpts, async (req, email, password, done) => {
    await authenticate(email, 'email', password, done);
  });

  const jwtStrategy = new JwtStrategy(jwtOpts, async (req, jwtPayload, done) => {
    try {
      const userIsValid = await isValidUser(jwtPayload.id);
      if (userIsValid) {
        const user = {
          address: jwtPayload.address,
          id: jwtPayload.id,
        };
        return done(null, user, { message: 'User authentication successful' });
      }
      return done(null, null, { message: 'No user found' });
    } catch (err) {
      return done(err, null, { message: 'Failed to authenticate user' });
    }
  });

  passport.use('username-login', usernameStrategy);
  passport.use('email-login', emailStrategy);
  passport.use('jwt', jwtStrategy);
};
