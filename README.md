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

### 1. Serveur Cloudflare (version gratuite)
1. Dans **Workers & Pages**, crée un Worker nommé `odyssee-mots`.
2. Clique sur **Edit code**, colle le contenu de `worker/worker.js`, puis clique sur **Deploy**.
3. Va dans **Settings → Bindings → Add binding → Workers AI**. Nom de variable : `AI`.
4. Va dans **Settings → Variables and Secrets**. Ajoute le secret `ACCESS_CODE` : un code inventé.

Les textes sont écrits par Gemma 4 et les illustrations dessinées par FLUX.1 schnell, tous deux via Workers AI. L'offre gratuite donne 10 000 « neurones » par jour, soit environ 6 à 8 histoires illustrées. La réserve se recharge chaque nuit.

### 2. Options payantes (facultatives)
- Illustrations Gemini, où le héros reste plus constant grâce à l'image modèle : secrets `GEMINI_API_KEY` et `IMAGE_PROVIDER` = `gemini`.
- Textes par Claude : secret `ANTHROPIC_API_KEY`.

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
