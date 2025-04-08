import functions from "firebase-functions";
import admin from "firebase-admin";
import { GraphQLClient } from "graphql-request";

const client = new GraphQLClient("https://tight-monarch-58.hasura.app/v1/graphql", {
  headers: {
    "content-type": "application/json",
    "x-hasura-admin-secret": "p1dRqUzAlkfh71Q0j3HiR3IzkR8tYwtgIwn0VqKNvf9StNvFNSVuMCfp3t3FIK9c" // Substitua pela sua chave
  }
});

if (admin.apps.length === 0) {
  admin.initializeApp();
}

export const registerUser = functions.https.onCall(async (data, context) => {
  const { email, password, displayName } = data;
  
  if (!email || !password || !displayName) {
    throw new functions.https.HttpsError("invalid-argument", "Missing information");
  }

  try {
    const userRecord = await admin.auth().createUser({
      email,
      password,
      displayName
    });

    const customClaims = {
      "https://hasura.io/jwt/claims": {
        "x-hasura-default-role": "user",
        "x-hasura-allowed-roles": ["user"],
        "x-hasura-user-id": userRecord.uid
      }
    };

    await admin.auth().setCustomUserClaims(userRecord.uid, customClaims);
    return userRecord.toJSON();
  } catch (error) {
    throw new functions.https.HttpsError("internal", JSON.stringify(error));
  }
});

export const processSignUp = functions.auth.user().onCreate(async (user) => {
  const id = user.uid;
  const email = user.email;
  const name = user.displayName || "No Name";

  const mutation = `mutation($id: String!, $email: String, $name: String) {
    insert_user(objects: [{ id: $id, email: $email, name: $name }]) {
      affected_rows
    }
  }`;

  try {
    return await client.request(mutation, { id, email, name });
  } catch (error) {
    throw new functions.https.HttpsError("internal", "sync-failed");
  }
});

export const processDelete = functions.auth.user().onDelete(async (user) => {
  const mutation = `mutation($id: String!) {
    delete_user(where: { id: { _eq: $id } }) {
      affected_rows
    }
  }`;
  
  try {
    return await client.request(mutation, { id: user.uid });
  } catch (error) {
    throw new functions.https.HttpsError("internal", "sync-failed");
  }
});
