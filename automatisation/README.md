## Retour d'expérience
Lors de la première exécution, 2 tests (TC-18 et TC-19) échouaient sur WebKit
par dépassement de délai (30 s). L'analyse du rapport a montré que le test
agissait avant que la page ne soit prête. J'ai ajouté des vérifications
d'attente explicites (visibilité du lien de déconnexion, URL de l'étape de
paiement). Après correction : 36 tests sur 36 passés sur Chromium, Firefox et WebKit.
