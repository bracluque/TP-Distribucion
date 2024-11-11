/*
**********----------------- > EDUCACIÓN PRINCIPAL SOSTENEDOR DEL HOGAR (PSG)
P1. v238a: ¿Cuándo usted tenía 15 años quién era el principal sostén de su hogar (PSH) 
(la persona que realizaba el mayor aporte económico al hogar)?: = 1 su padre, =2 su madre, = 3 otro.
P2. v240a: ¿Podría indicarme cuál fue el nivel educativo más alto que cursó el/la PSH?
Ninguno     =0 | Terciario               = 5
Primario    =1 | Universitario           = 6 
EGB         =2 | Posgrado Universitario  = 7 
Secundario  =3 | Educación especial      = 8 
Polimodal   =4 | NS/NR                   = 99
P3. v241a: ¿El PSH terminó el nivel? = 1 si, = 2 no */
gen educ_psh = .
replace educ_psh = 0 if (v240a == 0) & parent == 1 // Sin instrucción
replace educ_psh = 1 if ((v240a == 1 & v241a == 2) | (v240a == 2 & v241a == 2) | v240a == 8) & parent == 1 // primaria (EGB) incompleta (incluye especial)
replace educ_psh = 2 if ((v240a == 1 & v241a == 1) | (v240a == 2 & v241a == 1)) & parent == 1 // Primaria (EGB) completa
replace educ_psh = 3 if ((v240a == 3 & v241a == 2) | (v240a == 4 & v241a == 2)) & parent == 1 // Secundario incompleto
replace educ_psh = 4 if ((v240a == 3 & v241a == 1) | (v240a == 4 & v241a == 1)) & parent == 1 // Secundario Completo
replace educ_psh = 5 if ((v240a == 5 & v241a == 2) | (v240a == 6 & v241a == 2)) & parent == 1 // Terciario incompleto
replace educ_psh = 6 if ((v240a == 5 & v241a == 1) | (v240a == 6 & v241a == 1) | (v240a == 7)) & parent == 1  // Terciario Completo

* Como hay personas que reportan el nivel educativo pero no si lo completo, lo incorporamos:
replace educ_psh = 1 if ((v240a == 1 & v241a == .) | (v240a == 2 & v241a == .)) & parent == 1 // Sin instrucción o primaria (EGB) incompleta (incluye especial)
replace educ_psh = 3 if ((v240a == 3 & v241a == .) | (v240a == 4 & v241a == .)) & parent == 1 // Secundario incompleto
replace educ_psh = 5 if ((v240a == 5 & v241a == .) | (v240a == 6 & v241a == .)) & parent == 1 // Terciario incompleto

/*
EDUCACIÓN CÓNYUGE
Idem anterior pero con v244a: ¿Podría indicarme cuál fue el nivel más alto que cursó el/la CÓNYUGE del PSH?
y v245a: ¿El/la cónyuge terminó el nivel? = 1 si, = 2 no */
gen educ_cony = .
replace educ_cony = 0 if v244a == 0  & parent == 1 // Sin instrucción
replace educ_cony = 1 if ((v244a == 1 & v245a == 2) | (v244a == 2 & v245a == 2) | v244a == 8) & parent == 1 // primaria (EGB) incompleta (incluye especial)
replace educ_cony = 2 if ((v244a == 1 & v245a == 1) | (v244a == 2 & v245a == 1)) & parent == 1 // Primaria (EGB) completa
replace educ_cony = 3 if ((v244a == 3 & v245a == 2) | (v244a == 4 & v245a == 2)) & parent == 1 // Secundario incompleto
replace educ_cony = 4 if ((v244a == 3 & v245a == 1) | (v244a == 4 & v245a == 1)) & parent == 1 // Secundario incompleto
replace educ_cony = 5 if ((v244a == 5 & v245a == 2) | (v244a == 6 & v245a == 2)) & parent == 1 // Terciario incompleto
replace educ_cony = 6 if ((v244a == 5 & v245a == 1) | (v244a == 6 & v245a == 1) | (v244a == 7)) & parent == 1 // Terciario incompleto

* Como hay personas que reportan el nivel educativo pero no si lo completo, lo incorporamos:
replace educ_cony = 1 if ((v244a == 1 & v245a == .) | (v244a == 2 & v245a == .)) & parent == 1 // Sin instrucción o primaria (EGB) incompleta (incluye especial)
replace educ_cony = 3 if ((v244a == 3 & v245a == .) | (v244a == 4 & v245a == .)) & parent == 1 // Secundario incompleto
replace educ_cony = 5 if ((v244a == 5 & v245a == .) | (v244a == 6 & v245a == .)) & parent == 1 // Terciario incompleto

/*
**********----------------- > EDUCACIÓN CONYUGE (PSG) v240b y v241b */

replace educ_psh = 0 if v240b == 0 & parent == 2 // Sin instrucción
replace educ_psh = 1 if ((v240b == 1 & v241b == 2) | (v240b == 2 & v241b == 2) | v240b == 8) & parent == 2 // Sin instrucción o primaria (EGB) incompleta (incluye especial)
replace educ_psh = 2 if ((v240b == 1 & v241b == 1) | (v240b == 2 & v241b == 1)) & parent == 2 // Primaria (EGB) completa
replace educ_psh = 3 if ((v240b == 3 & v241b == 2) | (v240b == 4 & v241b == 2)) & parent == 2 // Secundario incompleto
replace educ_psh = 4 if ((v240b == 3 & v241b == 1) | (v240b == 4 & v241b == 1)) & parent == 2 // Secundario incompleto
replace educ_psh = 5 if ((v240b == 5 & v241b == 2) | (v240b == 6 & v241b == 2)) & parent == 2 // Terciario incompleto
replace educ_psh = 6 if ((v240b == 5 & v241b == 1) | (v240b == 6 & v241b == 1) | (v240b == 7)) & parent == 2 // Terciario incompleto

* Como hay personas que reportan el nivel educativo pero no si lo completo, lo incorporamos:
replace educ_psh = 1 if ((v240b == 1 & v241b == .) | (v240b == 2 & v241b == .)) & parent == 2 // Sin instrucción o primaria (EGB) incompleta (incluye especial)
replace educ_psh = 3 if ((v240b == 3 & v241b == .) | (v240b == 4 & v241b == .)) & parent == 2 // Secundario incompleto
replace educ_psh = 5 if ((v240b == 5 & v241b == .) | (v240b == 6 & v241b == .)) & parent == 2 // Terciario incompleto

* EDUCACIÓN CÓNYUGE --- > v244b y v245b
replace educ_cony = 0 if v244b == 0 & parent == 2 // Sin instrucción
replace educ_cony = 1 if ((v244b == 1 & v245b == 2) | (v244b == 2 & v245b == 2) | v244b == 8) & parent == 2 // Sin instrucción o primaria (EGB) incompleta (incluye especial)
replace educ_cony = 2 if ((v244b == 1 & v245b == 1) | (v244b == 2 & v245b == 1)) & parent == 2 // Primaria (EGB) completa
replace educ_cony = 3 if ((v244b == 3 & v245b == 2) | (v244b == 4 & v245b == 2)) & parent == 2 // Secundario incompleto
replace educ_cony = 4 if ((v244b == 3 & v245b == 1) | (v244b == 4 & v245b == 1)) & parent == 2 // Secundario incompleto
replace educ_cony = 5 if ((v244b == 5 & v245b == 2) | (v244b == 6 & v245b == 2)) & parent == 2 // Terciario incompleto
replace educ_cony = 6 if ((v244b == 5 & v245b == 1) | (v244b == 6 & v245b == 1) | (v244b == 7)) & parent == 2 // Terciario incompleto

* Como hay personas que reportan el nivel educativo pero no si lo completo, lo incorporamos:
replace educ_cony = 1 if ((v244b == 1 & v245b == .) | (v244b == 2 & v245b == .)) & parent == 2 // Sin instrucción o primaria (EGB) incompleta (incluye especial)
replace educ_cony = 3 if ((v244b == 3 & v245b == .) | (v244b == 4 & v245b == .)) & parent == 2 // Secundario incompleto
replace educ_cony = 5 if ((v244b == 5 & v245b == .) | (v244b == 6 & v245b == .)) & parent == 2 // Terciario incompleto

egen educ_max = rowmax(educ_cony educ_psh)
label var educ_max "Educación Máxima (padre/madre)"
label define educ_max 1 "Prii" 2 "Pric" 3 "Seci" 4 "Secc" 5 "Supi" 6 "Supc"
label values educ_max educ_max
