const functions = require("firebase-functions");
const admin = require("firebase-admin");
const request = require("graphql-request");

admin.initializeApp();

// Cliente GraphQL com variáveis de ambiente do Firebase
const client = new request.GraphQLClient(functions.config().hasura.endpoint, {
  headers: {
    "content-type": "application/json",
    "x-hasura-admin-secret": functions.config().hasura.admin_secret,
  },
});

// Função chamada pelo app Flutter para registrar usuário
exports.registerUser = functions.https.onCall(async (data) => {
  const { email, password, displayName } = data;

  if (!email || !password || !displayName) {
    throw new functions.https.HttpsError('register-failed', 'missing information');
  }

  try {
    const userRecord = await admin.auth().createUser({
      email,
      password,
      displayName,
    });

    const customClaims = {
      "https://hasura.io/jwt/claims": {
        "x-hasura-default-role": "user",
        "x-hasura-allowed-roles": ["user"],
        "x-hasura-user-id": userRecord.uid,
      },
    };

    await admin.auth().setCustomUserClaims(userRecord.uid, customClaims);

    console.log("✅ Usuário registrado e claims adicionadas:", userRecord.uid);

    return userRecord.toJSON();
  } catch (error) {
    console.error('❌ Error processing register:', error);
    throw new functions.https.HttpsError('internal', 'Error processing register.');
  }
});

// Ao criar usuário no Auth, insere no Hasura
exports.processSignUp = functions.auth.user().onCreate(async (user) => {
  const id = user.uid;
  const email = user.email;
  const name = user.displayName || "No Name";

  console.log("✅ processSignUp chamado:", { id, email, name });

  if (!id || !email || !name) {
    throw new functions.https.HttpsError('sync-failed', 'missing information');
  }

  const mutation = `
    mutation($id: String!, $email: String, $name: String) {
      insert_user(objects: [{
        id: $id,
        email: $email,
        name: $name,
      }]) {
        affected_rows
      }
    }`;

  try {
    const data = await client.request(mutation, { id, email, name });
    console.log("✅ Usuário inserido no Hasura:", data);
    return data;
  } catch (error) {
    console.error('❌ Error processing sign up:', error);
    throw new functions.https.HttpsError('internal', 'Error processing sign up.');
  }
});

// Ao deletar usuário no Auth, deleta do Hasura
exports.processDelete = functions.auth.user().onDelete(async (user) => {
  const id = user.uid;

  const mutation = `
    mutation($id: String!) {
      delete_user(where: {id: {_eq: $id}}) {
        affected_rows
      }
    }`;

  try {
    const data = await client.request(mutation, { id });
    console.log("🗑️ Usuário deletado do Hasura:", data);
    return data;
  } catch (error) {
    console.error('❌ Error processing delete:', error);
    throw new functions.https.HttpsError('internal', 'Error processing delete.');
  }
});

// Atualiza nome do usuário no Hasura
exports.updateUserName = functions.https.onCall(async (data) => {
  const { id, name } = data;

  if (!id || !name) {
    throw new functions.https.HttpsError('update-failed', 'missing information');
  }

  const mutation = `
    mutation($id: String!, $name: String!) {
      update_user(where: {id: {_eq: $id}}, _set: {name: $name}) {
        affected_rows
      }
    }`;

  try {
    const result = await client.request(mutation, { id, name });
    console.log("✏️ Nome do usuário atualizado:", result);
    return result;
  } catch (error) {
    console.error('❌ Error processing user name:', error);
    throw new functions.https.HttpsError('internal', 'Error processing user name.');
  }
});
