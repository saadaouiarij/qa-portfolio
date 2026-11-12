-- =====================================================================
-- CONTRÔLES DE DONNÉES : FACTURATION vs COMPTABILITÉ
-- Base fictive de démonstration (aucune donnée réelle).
-- Auteure : Arij Saadaoui, Ingénieure QA
-- Compatible SQLite / PostgreSQL / MySQL (SQL standard).
-- =====================================================================


-- ---------------------------------------------------------------------
-- 1. CRÉATION DU SCHÉMA
-- ---------------------------------------------------------------------

CREATE TABLE clients (
    id   INTEGER PRIMARY KEY,
    nom  VARCHAR(100) NOT NULL
);

CREATE TABLE factures (
    id            INTEGER PRIMARY KEY,
    numero        VARCHAR(20)  NOT NULL,
    client_id     INTEGER      NOT NULL,
    date_facture  DATE         NOT NULL,
    montant_ht    DECIMAL(10,2) NOT NULL,
    tva_taux      DECIMAL(5,2)  NOT NULL,   -- ex. 20 pour 20 %
    montant_ttc   DECIMAL(10,2) NOT NULL,
    statut        VARCHAR(20)  NOT NULL     -- EMISE, PAYEE, ANNULEE
);

-- Volontairement SANS clé étrangère vers factures : on simule ici un
-- défaut d'intégrité (écriture rattachée à une facture inexistante).
CREATE TABLE ecritures_comptables (
    id            INTEGER PRIMARY KEY,
    facture_id    INTEGER      NOT NULL,
    montant       DECIMAL(10,2) NOT NULL,
    date_ecriture DATE         NOT NULL
);


-- ---------------------------------------------------------------------
-- 2. JEU DE DONNÉES (avec anomalies volontaires)
-- ---------------------------------------------------------------------

INSERT INTO clients (id, nom) VALUES
    (1, 'Société Alpha'),
    (2, 'Société Beta'),
    (3, 'Société Gamma');

INSERT INTO factures (id, numero, client_id, date_facture, montant_ht, tva_taux, montant_ttc, statut) VALUES
    (1,  'F-1001', 1, '2026-09-01', 1000.00, 20, 1200.00, 'PAYEE'),
    (2,  'F-1002', 2, '2026-09-03',  500.00, 20,  600.00, 'PAYEE'),
    (3,  'F-1003', 1, '2026-09-05',  250.00, 20,  300.00, 'EMISE'),   -- anomalie : aucune écriture
    (4,  'F-1004', 3, '2026-09-08',  800.00, 20,  960.00, 'PAYEE'),
    (5,  'F-1005', 2, '2026-09-10',  400.00, 20,  480.00, 'PAYEE'),   -- anomalie : écriture à 400 (HT) au lieu de 480
    (6,  'F-1006', 3, '2026-09-12', 1500.00, 20, 1800.00, 'PAYEE'),
    (7,  'F-1007', 1, '2026-09-15',  600.00, 20,  720.00, 'PAYEE'),   -- anomalie : écriture en double
    (8,  'F-1008', 2, '2026-09-18',  100.00, 20,  120.00, 'PAYEE'),
    (9,  'F-1009', 3, '2026-09-20',  900.00, 20, 1050.00, 'EMISE'),   -- anomalie : TTC faux (devrait être 1080)
    (10, 'F-1010', 1, '2026-09-22',  300.00, 20,  360.00, 'PAYEE'),   -- anomalie : écriture datée avant la facture
    (11, 'F-1011', 2, '2026-09-25',  700.00, 20,  840.00, 'ANNULEE'), -- anomalie : annulée mais écriture présente
    (12, 'F-1012', 3, '2026-09-28',  200.00, 20,  240.00, 'PAYEE');

INSERT INTO ecritures_comptables (id, facture_id, montant, date_ecriture) VALUES
    (1,   1, 1200.00, '2026-09-01'),
    (2,   2,  600.00, '2026-09-03'),
    (3,   4,  960.00, '2026-09-08'),
    (4,   5,  400.00, '2026-09-10'),
    (5,   6, 1800.00, '2026-09-12'),
    (6,   7,  720.00, '2026-09-15'),
    (7,   7,  720.00, '2026-09-15'),   -- doublon
    (8,   8,  120.00, '2026-09-18'),
    (9,   9, 1050.00, '2026-09-20'),
    (10, 10,  360.00, '2026-09-10'),   -- date antérieure à la facture
    (11, 11,  840.00, '2026-09-25'),
    (12, 12,  240.00, '2026-09-28'),
    (13, 99,  150.00, '2026-09-30');   -- facture 99 inexistante (écriture orpheline)


-- ---------------------------------------------------------------------
-- 3. REQUÊTES DE CONTRÔLE
-- ---------------------------------------------------------------------

-- CTRL-01 : Factures sans aucune écriture comptable
-- Une facture non comptabilisée fausse le chiffre d'affaires comptable.
SELECT f.numero, f.montant_ttc, f.statut
FROM factures f
LEFT JOIN ecritures_comptables e ON e.facture_id = f.id
WHERE e.id IS NULL;


-- CTRL-02 : Écarts de montant entre facture et comptabilité
-- On compare le TTC de la facture à la somme de ses écritures.
SELECT f.numero,
       f.montant_ttc                          AS montant_facture,
       SUM(e.montant)                         AS montant_comptabilise,
       SUM(e.montant) - f.montant_ttc         AS ecart
FROM factures f
JOIN ecritures_comptables e ON e.facture_id = f.id
GROUP BY f.id, f.numero, f.montant_ttc
HAVING SUM(e.montant) <> f.montant_ttc;


-- CTRL-03 : Factures comptabilisées plusieurs fois (doublons)
SELECT f.numero, COUNT(*) AS nb_ecritures
FROM factures f
JOIN ecritures_comptables e ON e.facture_id = f.id
GROUP BY f.id, f.numero
HAVING COUNT(*) > 1;


-- CTRL-04 : Écritures orphelines (aucune facture correspondante)
SELECT e.id AS ecriture_id, e.facture_id, e.montant
FROM ecritures_comptables e
LEFT JOIN factures f ON f.id = e.facture_id
WHERE f.id IS NULL;


-- CTRL-05 : Erreurs de calcul du TTC (HT x (1 + TVA) doit égaler le TTC)
SELECT numero, montant_ht, tva_taux, montant_ttc,
       ROUND(montant_ht * (1 + tva_taux / 100.0), 2) AS ttc_attendu
FROM factures
WHERE ABS(montant_ttc - ROUND(montant_ht * (1 + tva_taux / 100.0), 2)) > 0.01;


-- CTRL-06 : Factures annulées qui ont encore une écriture comptable
SELECT f.numero, f.statut, e.montant
FROM factures f
JOIN ecritures_comptables e ON e.facture_id = f.id
WHERE f.statut = 'ANNULEE';


-- CTRL-07 : Écritures datées avant la date de la facture (incohérence de dates)
SELECT f.numero, f.date_facture, e.date_ecriture
FROM factures f
JOIN ecritures_comptables e ON e.facture_id = f.id
WHERE e.date_ecriture < f.date_facture;
