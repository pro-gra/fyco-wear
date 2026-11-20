const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { Resend } = require("resend");

initializeApp();

// Mettez ici votre clé API gratuite obtenue sur resend.com
const resend = new Resend("");

exports.sendOrderEmail = onDocumentCreated("orders/{orderId}", async (event) => {
  const snapshot = event.data;
  if (!snapshot) return;

  const order = snapshot.data();
  const customer = order.customer || {};
  const email = customer.email;

  if (!email) return;

  const orderRef = order.orderRef || event.params.orderId;
  const total = order.totalCodMad || 0;
  const items = order.items || [];

  const itemsHtml = items.map((item) => `
    <tr>
      <td style="padding: 8px; border-bottom: 1px solid #eee;">${item.productName} (${item.color}, Taille ${item.size})</td>
      <td style="padding: 8px; border-bottom: 1px solid #eee; text-align: center;">${item.quantity}</td>
      <td style="padding: 8px; border-bottom: 1px solid #eee; text-align: right;">${item.subtotalMad} MAD</td>
    </tr>
  `).join("");

  try {
    await resend.emails.send({
      from: "FYCO <onboarding@resend.dev>",
      to: email,
      subject: `Confirmation de votre commande FYCO [${orderRef}]`,
      html: `
        <div style="font-family: sans-serif; max-width: 600px; margin: auto; padding: 20px; background: #F9F6F0; color: #141211;">
          <h2 style="text-align: center; letter-spacing: 2px;">FYCO ATELIER</h2>
          <p>Bonjour <strong>${customer.fullName}</strong>,</p>
          <p>Merci pour votre commande ! Notre équipe va vous appeler très prochainement au <strong>${customer.phone}</strong> pour valider votre taille avant l'expédition.</p>
          
          <div style="background: white; padding: 15px; border-radius: 6px; border: 1px solid #E4DCD3; margin: 20px 0;">
            <p style="margin: 0; font-size: 12px; font-weight: bold; color: #6B6560;">CODE DE COMMANDE :</p>
            <h3 style="margin: 5px 0 0 0; letter-spacing: 1.5px;">${orderRef}</h3>
          </div>

          <table style="width: 100%; border-collapse: collapse; background: white; border-radius: 6px; overflow: hidden;">
            <thead>
              <tr style="background: #F1EBE1; text-align: left;">
                <th style="padding: 10px;">Article</th>
                <th style="padding: 10px; text-align: center;">Qté</th>
                <th style="padding: 10px; text-align: right;">Total</th>
              </tr>
            </thead>
            <tbody>
              ${itemsHtml}
            </tbody>
          </table>

          <h3 style="text-align: right; margin-top: 15px;">Total à régler au livreur : ${total} MAD</h3>
          <p style="font-size: 12px; color: #6B6560; text-align: center; margin-top: 30px;">Paiement en espèces à la livraison · FYCO Apparel Casablanca</p>
        </div>
      `,
    });
    console.log(`E-mail de confirmation envoyé avec succès à ${email}`);
  } catch (error) {
    console.error("Erreur lors de l'envoi de l'e-mail via Resend :", error);
  }
});