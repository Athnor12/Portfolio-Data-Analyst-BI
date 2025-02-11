-- requête 1 : Quel est le nombre de retour client sur la livraison ? --

SELECT 	count(libelle_categorie)
FROM 	retour_client
WHERE 	libelle_categorie = "livraison" ;

-- requête 2 : Quelle est la liste des notes des clients sur les réseaux sociaux sur les TV ? --

SELECT    libelle_source,
          cle_produit,
          titre_produit,
          note 
FROM      retour_client, produit
WHERE     retour_client.cle_produit = produit.cle_produit
AND       libelle_source = "réseaux sociaux"
AND       titre_produit = "TV"
GROUP BY  note ;

-- requête 3 : Quelle est la note moyenne pour chaque catégorie de produit ? (Classé de la meilleure à la moins bonne) -- 

SELECT    typologie_produit AS type_de_produit,
          round(avg(note), 2) as note_moyenne
FROM      retour_client, produit
WHERE     retour_client.cle_produit = produit.cle_produit
GROUP BY  typologie_produit
ORDER BY  note_moyenne DESC ;

-- requête 4 : Quels sont les 5 magasin avec les meilleures notes moyenne ? --

SELECT    round(avg(note), 2) as note_moyenne,
          ref_magasin as reference_magasin,
          libelle_de_commune as ville
FROM      retour_client, ref_magasin
WHERE     retour_client.ref_magasin = ref_magasin.ref_magasin
GROUP BY  retour_client.ref_magasin, libelle_de_commune
ORDER BY  note_moyenne desc
LIMIT     5 ;

-- requête 5 : Quels sont les magasins qui ont plus de 12 feedbacks sur le drive ? --

SELECT    ref_magasin as reference_magasin,
          libelle_de_commune as ville,
          libelle_categorie as categorie,
          count(libelle_categorie) as nombre_feedback
FROM      retour_client, ref_magasin
WHERE     retour_client.ref_magasin = ref_magasin.ref_magasin
AND       libelle_categorie = "drive"
GROUP BY  retour_client.ref_magasin, libelle_de_commune, libelle_categorie
HAVING    nombre_feedback > 12 ;

-- requête 6 : Quel est le classement des départements par note ? --

SELECT    departement,
          round(avg(note), 2) as note_moyenne
FROM      retour_client, ref_magasin
WHERE     retour_client.ref_magasin = ref_magasin.ref_magasin
GROUP BY  departement
ORDER BY  note_moyenne DESC ;

-- requête 7 : Quelle est la typologie de produit qui apporte le meilleur service après-vente ? --

SELECT    libelle_categorie as categorie,
          typologie_produit as type_de_produit,
          round(avg(note), 2) as note_moyenne
FROM      produit, retour_client
WHERE     retour_client.cle_produit = produit.cle_produit 
GROUP BY  libelle_categorie, typologie_produit
HAVING    libelle_categorie = "service après-vente"
ORDER BY  note_moyenne desc ;

-- requête 8 : Quelle est la note moyenne sur l’ensemble des boissons ? --

SELECT    titre_produit as produit,
          round(avg(note), 2) as note_moyenne
FROM      produit, retour_client
WHERE     retour_client.cle_produit = produit.cle_produit 
GROUP BY  titre_produit
HAVING    titre_produit = "Boissons" ;

-- requête 9 : Quel est le classement des jours de la semaine où l’expérience client est la meilleure expérience en magasin ? --

SELECT    strftime ("%w", date_achat) as jour_de_la_semaine,
          round(avg(note), 2) as note_moyenne
FROM      retour_client
WHERE     libelle_categorie = "expérience en magasin"
GROUP BY  jour_de_la_semaine ;

-- requête 10 : Sur quel mois a-t-on le plus de retour sur le service après-vente ? -- 

SELECT    strftime ("%m", date_achat) as mois,
          count(*) as nombre_retour 
FROM      retour_client
GROUP BY  mois, libelle_categorie
HAVING    libelle_categorie = "service après-vente"
ORDER BY  nombre_retour DESC ;

-- requête 11 : Quel est le pourcentage de recommandations clients ? (Comptabiliser le nombre de retour client qui ont répondu « oui » divisé par le nombre de retours total) --

SELECT    count(*) nombre_retour_client,
          round((SELECT count(*) FROM retour_client where recommandation = 1 ) / (SELECT count(*) * 1.0 FROM retour_client WHERE recommandation = 1 OR recommandation = 0), 2) as pourcentage
FROM      retour_client ;

-- requête 12 : Quels sont les magasin qui ont une note inférieure à la moyenne ? --

SELECT    retour_client.ref_magasin as reference_magasin,
          libelle_de_commune as ville,
          round(avg(note), 2) as note_moyenne_magasin
FROM      retour_client, ref_magasin
WHERE     retour_client.ref_magasin = ref_magasin.ref_magasin
GROUP BY  libelle_de_commune
HAVING    note_moyenne_magasin < (SELECT avg(note) from retour_client)
ORDER BY  note_moyenne_magasin DESC , reference_magasin DESC ;

-- requête 13 : Quelles sont les typologies produits qui ont amélioré leur moyenne entre le 1er et le 2e trimestre 2021 ? --

WITH note_Q1_2021 AS (
        SELECT 
        typologie_produit,
        round(avg(note), 2) as note_moyenne_Q1
        FROM retour_client, produit
        WHERE retour_client.cle_produit = produit.cle_produit 
        AND date_achat between "2021-01-01" and "2021-03-31"
        group by typologie_produit
 ), note_Q2_2021 AS (
        SELECT typologie_produit,
        round(avg(note), 2) as note_moyenne_Q2
        FROM retour_client, produit
        WHERE retour_client.cle_produit = produit.cle_produit 
        AND date_achat between "2021-04-01" and "2021-06-30"
        GROUP BY typologie_produit)
 
SELECT
  q1.typologie_produit,
  q1.note_moyenne_Q1,
  q2.typologie_produit,
  q2.note_moyenne_Q2,
  round((q2.note_moyenne_Q2 - q1.note_moyenne_Q1) / q1.note_moyenne_Q1 * 100, 2) as pourcentage_evolution
  
FROM note_Q1_2021 q1, note_Q2_2021 q2
WHERE q1.typologie_produit = q2.typologie_produit
AND pourcentage_evolution > 0 ;

-- requête 14 : NPS --

SELECT    round(SUM(CASE WHEN note IN ( '9', '10') THEN 1.0
          WHEN      note IN ('7', '8') THEN 0.0
          WHEN      note IS NULL THEN 0.0
          ELSE      -1.0 END)
          /
          SUM(CASE WHEN note <> " " THEN 1.0 ELSE 0.0 END)  *  100 ,  1)  as NPS
FROM      retour_client ;

-- requête 15 NPS par source --

SELECT    libelle_source,
          round(SUM(CASE WHEN note IN ('9', '10') THEN 1.0
          WHEN note IN ('7', '8') THEN 0.0
          WHEN note IS NULL THEN 0.0
          ELSE -1.0 END)
          /
          SUM(CASE WHEN note <> " " THEN 1.0 ELSE 0.0 END) *100, 0)
          As NPS
FROM      retour_client
GROUP BY  libelle_source ;

-- requête 16 : Quel est le nombre de retour client par source ? -- 

SELECT    libelle_source,
          count(*) as nombre_retour_client
FROM      retour_client
GROUP BY  libelle_source ;

-- requête 17 : Quels sont les 5 magasins avec le plus de feedback --

SELECT    libelle_de_commune,
          count(*) as nombre_retour_client
FROM      retour_client, ref_magasin
WHERE     retour_client.ref_magasin = ref_magasin.ref_magasin
GROUP BY  libelle_de_commune
ORDER BY  nombre_retour_client DESC
LIMIT     5 ;