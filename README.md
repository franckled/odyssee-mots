# Odyssée Mots

*Invente, lis et vis tes propres contes.*

Un livre illustré interactif pour les enfants de 5 à 13 ans et plus. L'enfant choisit son héros ou son héroïne et l'univers de l'aventure. Un parent peut aussi écrire le début. L'IA écrit ensuite l'histoire page après page, l'illustre, et pose des questions qui en changent le cours.

## Ce que fait le prototype

- **Questions à l'enfant** avant l'histoire : âge, héros (fille, garçon, animal, robot, créature magique), nom imaginaire, couleur préférée, univers.
- **Histoire de 10 pages** pour les 5-9 ans et **de 12 pages** à partir de 9 ans, avec 3 moments de choix.
- **Illustrations** à chaque page, dans un style gai et frais. La première image sert de modèle aux suivantes pour garder le même héros.
- **Promotion de la lecture** :
  - il faut lire la page avant de continuer ;
  - une petite question de compréhension précède chaque choix ;
  - les étoiles de lecture récompensent l'enfant ;
  - un carnet de mots nouveaux ;
  - la police Andika, conçue pour les jeunes lecteurs.
- **Espace parents** derrière une barrière (une multiplication) : réglages, début d'histoire, signalements, effacement des données.
- **Protection de l'enfance** :
  - des règles strictes à chaque appel à l'IA ;
  - une relecture indépendante de chaque page ;
  - un contrôle du texte écrit par le parent ;
  - les filtres de Google réglés au plus strict ;
  - aucune donnée personnelle demandée ;
  - rien n'est conservé sur le serveur.

## Organisation

```
lib/            application Flutter
worker/         serveur Cloudflare (garde les clés d'API secrètes)
.github/        publication automatique sur GitHub Pages
```

## Mise en route

### 1. Clé Google Gemini
1. Va sur **aistudio.google.com**, puis « Get API key » et « Create API key ».
2. Active la facturation : la génération d'images est payante.
3. Fixe un **plafond de dépenses** dans Google Cloud (Billing, puis Budgets).

### 2. Serveur Cloudflare
1. Dans le tableau de bord Cloudflare, ouvre **Workers & Pages**, puis **Create**, puis **Create Worker**. Nomme-le `odyssee-mots` et clique sur **Deploy**.
2. Clique sur **Edit code**. Efface tout, colle le contenu de `worker/worker.js`, puis clique sur **Deploy**.
3. Va dans **Settings**, puis **Variables and Secrets**. Ajoute deux secrets (type *Secret*) :
   - `GEMINI_API_KEY` : ta clé Google ;
   - `ACCESS_CODE` : un code d'accès inventé, assez long.
4. Note l'adresse du Worker (`https://odyssee-mots.<ton-nom>.workers.dev`).

Option : ajoute `ANTHROPIC_API_KEY` pour que Claude écrive les textes, Gemini gardant les illustrations.

### 3. Application
1. Sur GitHub, va dans **Settings**, puis **Pages**. Dans Source, choisis **GitHub Actions**.
2. Ouvre l'app sur `https://franckled.github.io/odyssee-mots/`.
3. Va dans l'espace parents, colle l'adresse du Worker et le code d'accès, puis clique sur **Enregistrer et tester**.

## Avant une publication sur les stores

- Avis juridique : RGPD (consentement parental en dessous de 15 ans), AI Act (mention de l'IA, déjà présente), règles « Enfants » d'Apple et « Familles » de Google.
- Comptes, abonnement ou crédits pour couvrir le coût de génération.
- Signalements envoyés à un vrai service de modération (aujourd'hui, ils restent sur l'appareil).
- Stockage des illustrations sur l'appareil (aujourd'hui, seule la couverture est gardée).
- Lecture à voix haute avec surlignage pour les 5-7 ans.
- Compilation Android et iOS (Codemagic, sans terminal).
