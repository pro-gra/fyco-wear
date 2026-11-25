const admin = require('firebase-admin');

async function main() {
  const uid = process.argv[2];
  const projectId = process.env.FIREBASE_PROJECT_ID;
  if (!uid || !projectId) {
    console.error('Usage: FIREBASE_PROJECT_ID=your-project-id node scripts/set-admin.js FIREBASE_AUTH_UID');
    process.exit(1);
  }

  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
    projectId,
  });

  const auth = admin.auth();
  const user = await auth.getUser(uid);
  await auth.setCustomUserClaims(uid, { ...(user.customClaims || {}), admin: true });
  console.log(`Granted FYCO admin access to ${user.email || uid}.`);
  console.log('The user must sign out and sign in again to refresh their ID token.');
  await admin.app().delete();
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
