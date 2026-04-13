import 'package:flutter/material.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Politique de Confidentialité')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Introduction',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Votre vie privée est importante pour nous. Cette politique de confidentialité explique comment nous collectons, utilisons, divulguons et protégeons vos informations personnelles.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Text(
              'Informations collectées',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Nous collectons des informations que vous nous fournissez directement, telles que votre nom, adresse e-mail, date de naissance, sexe, numéro de téléphone, et des données de santé (rythme cardiaque, SpO2, mouvements, température) provenant de vos capteurs.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Text(
              'Utilisation des informations',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Nous utilisons les informations collectées pour fournir, maintenir et améliorer nos services, personnaliser votre expérience, communiquer avec vous, et à des fins de recherche et d\'analyse pour améliorer la détection de l\'apnée du sommeil.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Text(
              'Partage des informations',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Nous ne partageons pas vos informations personnelles avec des tiers, sauf si cela est nécessaire pour fournir nos services (par exemple, avec votre médecin traitant si vous y consentez), pour se conformer à la loi, ou pour protéger nos droits.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Text(
              'Sécurité des données',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Nous mettons en œuvre des mesures de sécurité techniques et organisationnelles appropriées pour protéger vos informations personnelles contre l\'accès non autorisé, la divulgation, l\'altération ou la destruction.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Text(
              'Vos droits',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Vous avez le droit d\'accéder à vos informations personnelles, de les corriger, de les supprimer ou de vous opposer à leur traitement. Veuillez nous contacter pour exercer ces droits.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Text(
              'Modifications de cette politique',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Nous pouvons mettre à jour cette politique de confidentialité de temps à autre. Nous vous informerons de tout changement en publiant la nouvelle politique sur cette page.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Text(
              'Contactez-nous',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Si vous avez des questions concernant cette politique de confidentialité, veuillez nous contacter à support@sleepapneadetect.com.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

