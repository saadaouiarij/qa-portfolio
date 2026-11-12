# Plan de tests – Application e-commerce SauceDemo

**Auteure :** Arij Saadaoui, Ingénieure QA
**Application testée :** https://www.saucedemo.com (boutique en ligne fictive d'entraînement)
**Version du document :** 1.0

---

## 1. Objectif

Valider les fonctionnalités principales de l'application : authentification, catalogue produits, panier, tunnel de commande et déconnexion. Ce plan sert aussi de base pour identifier les scénarios de non-régression à automatiser (Playwright / Selenium).

## 2. Périmètre

**Inclus :**
- Connexion et déconnexion
- Liste des produits (affichage et tri)
- Ajout et suppression de produits dans le panier
- Tunnel de commande (saisie des informations, récapitulatif, confirmation)
- Contrôle d'accès aux pages sans connexion

**Exclu :**
- Tests de performance et de charge
- Tests de sécurité approfondis
- Compatibilité multi-navigateurs complète (un navigateur de référence : Chrome)

## 3. Types de tests

| Type | Description |
|---|---|
| Fonctionnel | Vérification de chaque fonctionnalité par rapport au comportement attendu |
| Négatif | Saisies invalides, champs obligatoires, accès non autorisé |
| Non-régression | Sous-ensemble de cas critiques à rejouer à chaque livraison |
| Exploratoire | Comportements anormaux observés avec les comptes de test à anomalies |

## 4. Environnement et jeux de données

- **Navigateur :** Chrome (dernière version)
- **URL :** https://www.saucedemo.com
- **Mot de passe commun à tous les comptes :** `secret_sauce`

| Compte | Usage |
|---|---|
| `standard_user` | Parcours nominal |
| `locked_out_user` | Test du compte bloqué |
| `problem_user` | Comportements anormaux (anomalies volontaires) |
| `performance_glitch_user` | Lenteurs à la connexion |
| `error_user` | Erreurs lors de certaines actions |

**Données de commande utilisées :** Prénom `Arij`, Nom `Saadaoui`, Code postal `1002`.

## 5. Critères d'entrée et de sortie

- **Entrée :** application accessible, comptes de test disponibles, plan de tests validé.
- **Sortie :** 100 % des cas exécutés, aucune anomalie bloquante ou majeure ouverte, anomalies restantes documentées avec leur criticité.

## 6. Cas de tests

**Priorité :** P1 = critique (à inclure dans la non-régression), P2 = important, P3 = secondaire.
Les colonnes « Résultat obtenu » et « Statut » sont à remplir après exécution réelle des tests.

| ID | Module | Scénario | Étapes | Résultat attendu | Priorité | Résultat obtenu | Statut |
|---|---|---|---|---|---|---|---|
| TC-01 | Connexion | Connexion valide | 1. Ouvrir le site. 2. Saisir `standard_user` / `secret_sauce`. 3. Cliquer sur Login. | L'utilisateur arrive sur la page des produits (/inventory.html). | P1 | Conforme au résultat attendu | Passé |
| TC-02 | Connexion | Mot de passe incorrect | 1. Saisir `standard_user` et un mauvais mot de passe. 2. Cliquer sur Login. | Message d'erreur : « Username and password do not match any user in this service ». Pas de connexion. | P1 | Conforme au résultat attendu | Passé |
| TC-03 | Connexion | Nom d'utilisateur vide | 1. Laisser le nom vide, saisir le mot de passe. 2. Cliquer sur Login. | Message d'erreur : « Username is required ». | P2 | Conforme au résultat attendu | Passé |
| TC-04 | Connexion | Mot de passe vide | 1. Saisir `standard_user`, laisser le mot de passe vide. 2. Cliquer sur Login. | Message d'erreur : « Password is required ». | P2 | Conforme au résultat attendu | Passé |
| TC-05 | Connexion | Compte bloqué | 1. Saisir `locked_out_user` / `secret_sauce`. 2. Cliquer sur Login. | Message d'erreur indiquant que l'utilisateur est bloqué. Pas de connexion. | P1 | Conforme au résultat attendu | Passé |
| TC-06 | Accès | Accès direct sans connexion | 1. Sans être connecté, ouvrir directement `/inventory.html`. | Redirection vers la page de connexion avec un message indiquant qu'une connexion est nécessaire. | P1 | Conforme au résultat attendu | Passé |
| TC-07 | Catalogue | Affichage de la liste des produits | 1. Se connecter avec `standard_user`. | 6 produits affichés, chacun avec image, nom, description, prix et bouton « Add to cart ». | P1 | Conforme au résultat attendu | Passé |
| TC-08 | Catalogue | Tri par nom A à Z | 1. Se connecter. 2. Choisir « Name (A to Z) ». | Produits triés par ordre alphabétique croissant. | P2 | Conforme au résultat attendu | Passé |
| TC-09 | Catalogue | Tri par nom Z à A | 1. Choisir « Name (Z to A) ». | Produits triés par ordre alphabétique décroissant. | P3 | Conforme au résultat attendu | Passé |
| TC-10 | Catalogue | Tri par prix croissant | 1. Choisir « Price (low to high) ». | Produits triés du moins cher au plus cher. | P2 | Conforme au résultat attendu | Passé |
| TC-11 | Catalogue | Tri par prix décroissant | 1. Choisir « Price (high to low) ». | Produits triés du plus cher au moins cher. | P3 | Conforme au résultat attendu | Passé |
| TC-12 | Panier | Ajout d'un produit | 1. Cliquer sur « Add to cart » pour « Sauce Labs Backpack ». | Le bouton devient « Remove », le badge du panier affiche 1. | P1 | Conforme au résultat attendu | Passé |
| TC-13 | Panier | Ajout de plusieurs produits | 1. Ajouter 3 produits différents. 2. Ouvrir le panier. | Le badge affiche 3. Les 3 produits sont listés dans le panier avec le bon prix. | P1 | Conforme au résultat attendu | Passé |
| TC-14 | Panier | Suppression d'un produit | 1. Ajouter un produit. 2. Ouvrir le panier. 3. Cliquer sur « Remove ». | Le produit disparaît du panier et le badge est mis à jour. | P1 | Conforme au résultat attendu | Passé |
| TC-15 | Commande | Commande complète (parcours nominal) | 1. Ajouter un produit. 2. Panier puis Checkout. 3. Saisir Arij / Saadaoui / 1002. 4. Continue puis Finish. | Page de confirmation affichant « Thank you for your order! ». Le panier est vidé. | P1 | Conforme au résultat attendu | Passé |
| TC-16 | Commande | Prénom manquant | 1. Aller au Checkout avec un produit. 2. Laisser le prénom vide, remplir le reste. 3. Continue. | Message d'erreur indiquant que le prénom est obligatoire. | P2 | Conforme au résultat attendu | Passé |
| TC-17 | Commande | Code postal manquant | 1. Au Checkout, laisser le code postal vide. 2. Continue. | Message d'erreur indiquant que le code postal est obligatoire. | P2 | Conforme au résultat attendu | Passé |
| TC-18 | Commande | Calcul du total | 1. Ajouter 2 produits. 2. Aller jusqu'au récapitulatif (étape Overview). | Total articles = somme des prix. Taxe et total général cohérents. Vérifier le calcul à la main. | P1 | Conforme au résultat attendu | Passé |
| TC-19 | Déconnexion | Déconnexion | 1. Se connecter. 2. Ouvrir le menu (icône en haut à gauche). 3. Cliquer sur « Logout ». | Retour à la page de connexion. | P1 | Conforme au résultat attendu | Passé |
| TC-20 | Exploratoire | Comportement du compte `problem_user` | 1. Se connecter avec `problem_user`. 2. Observer les images, ajouter des produits, tester le tri, tenter une commande. | Comportement identique à `standard_user`. Tout écart est documenté comme anomalie. | P2 | *(à compléter avec vos observations)* | À compléter |

## 7. Scénarios candidats à l'automatisation

Les cas de priorité P1 sont les meilleurs candidats : TC-01, TC-02, TC-05, TC-06, TC-07, TC-12, TC-13, TC-14, TC-15, TC-18, TC-19. Ils sont stables, répétitifs et couvrent le parcours critique. Ils seront automatisés avec Playwright (voir le dossier `automatisation`).

## 8. Suivi des anomalies

Les anomalies détectées sont documentées dans Jira (voir captures dans le dossier `anomalies`) avec : titre, étapes pour reproduire, résultat attendu et obtenu, gravité, capture d'écran.
