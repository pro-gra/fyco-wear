# FYCO admin setup

## Grant the owner account admin access

Admin access is controlled by a Firebase Authentication custom claim. Do not put an email address or service-account key in Flutter code or in this repository.

1. Open Firebase Console → Authentication → Users and copy the UID of the account that should manage FYCO.
2. On a trusted machine with Google Cloud CLI installed, authenticate an administrator identity that has permission to set Firebase Authentication custom claims:
   `gcloud auth application-default login`
3. From the repository root, run:

   ```bash
   cd functions
   npm install
   cd ..
   # PowerShell:
   $env:FIREBASE_PROJECT_ID="YOUR_FIREBASE_PROJECT_ID"
   node functions/scripts/set-admin.js "FIREBASE_AUTH_UID"
   ```

4. Sign out of FYCO and sign back in. Then open `/admin` and choose **Produits & stock**.
5. Deploy the Firestore rules:

   ```bash
   firebase deploy --only firestore:rules
   ```

The script uses Application Default Credentials and the Firebase Admin SDK. Never commit a service-account JSON file.

## Product document

The admin panel manages `store_products/sculpt-jumpsuit`:

- `priceMad` and `originalPriceMad`
- `active` storefront visibility
- `inventory` quantities keyed as `milk-white__S`, `chocolate__M`, etc.

The storefront listens to this document in real time. When inventory is enabled, a variant with quantity 0 is shown as sold out and cannot be added to the cart. Cart line prices use the current price when the item is added.

## Important production security note

The existing guest checkout and tracking implementation currently relies on unrestricted access to `orders`. These rules have intentionally been left unchanged in this feature branch to avoid breaking checkout, but they expose customer order information and allow unauthorized writes. Before taking real customer orders, move order creation to a validated Cloud Function and restrict order reads to an authenticated owner/admin or a narrowly scoped tracking endpoint. Do not treat the existing order rules as production-safe.
