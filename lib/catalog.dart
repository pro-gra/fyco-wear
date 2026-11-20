import 'package:flutter/material.dart';
import 'product.dart';

class Catalog {
  static const List<Product> drops = [
    Product(
      id: 'MOD-01',
      title: "L'ENSEMBLE GAINANT SEAMLESS",
      subtitle: "High-Rise Ribbed Compression Set",
      description:
          "Tissu gainant haute compression respirant, maintien optimal pour cardio et pilates. Taille haute et maintien galbant sans coutures.",
      priceMad: 320.0,
      imageUrl: 'https://images.unsplash.com/photo-1518611012118-696072aa579a?auto=format&fit=crop&w=1000&q=80',
      sizes: ['S', 'M', 'L'],
      colors: [
        ProductColorOption(name: 'Noir Onyx', previewColor: Color(0xFF1B1B1B)),
        ProductColorOption(name: 'Brun Moka', previewColor: Color(0xFF4A3728)),
        ProductColorOption(name: 'Vert Sauge', previewColor: Color(0xFF8F9779)),
      ],
    ),
    Product(
      id: 'MOD-02',
      title: "L'ENSEMBLE SECOND SKIN FLARE",
      subtitle: "Butter-Soft Flared Active Legging & Bra",
      description:
          "Coupe flare évasée tendance, sensation seconde peau ultra-douce. Confort extrême pour le sport, le yoga ou un style streetwear minimaliste.",
      priceMad: 350.0,
      imageUrl: 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?auto=format&fit=crop&w=1000&q=80',
      sizes: ['S', 'M', 'L'],
      colors: [
        ProductColorOption(name: 'Gris Anthracite', previewColor: Color(0xFF2C2C2C)),
        ProductColorOption(name: 'Rose Poudré', previewColor: Color(0xFFD8A8A2)),
        ProductColorOption(name: 'Bleu Minuit', previewColor: Color(0xFF1E293B)),
      ],
    ),
  ];
}