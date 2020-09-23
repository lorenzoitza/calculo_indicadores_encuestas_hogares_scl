/*====================================================================
project:       Armonizacion actualización plataformas SCL
Author:        Angela Lopez 
Dependencies:  SCL/EDU/LMK - IDB 
----------------------------------------------------------------------
Creation Date:    01 feb 2020 - 11:47:53
Modification Date:   
Do-file version:    01
References:          
Output:             Excel-DTA file
====================================================================*/

/*====================================================================
                        0: Program set up
====================================================================*/
version 15.1
drop _all 
set more off 
*ssc install quantiles inequal7
cap ssc install estout
cap ssc install inequal7

global source  	 "\\Sdssrv03\surveys\harmonized"

global input	 "C:\Users\alop\Desktop\GitRepositories\calculo_indicadores_encuestas_hogares_scl\Input"
global output 	 "C:\Users\alop\Desktop\GitRepositories\calculo_indicadores_encuestas_hogares_scl\Onput"
global covidtmp  "C:\Users\ALOP\Inter-American Development Bank Group\Data Governance - SCL - General\Proyecto - Data management\Bases tmp"

**

/*====================================================================
                        1: Open dataset and Generate indicators
====================================================================*/

include "${input}\calculo_microdatos_scl.do"
						
tempfile tablas
tempname ptablas

** Este postfile da estructura a la base:

postfile `ptablas' str30(tiempo_id pais_id geografia_id clase clase2 nivel_id tema indicador valor muestra) using `tablas', replace

** Creo locales principales:
 

local temas educacion /*laboral pobreza  vivienda demografia diversidad migracion */							
local paises ARG BHS BOL BRB BLZ BRA CHL COL CRI ECU SLV GTM GUY HTI HND JAM MEX NIC PAN PRY PER DOM SUR TTO URY VEN
local anos 2006 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 

local geografia_id total_nacional


qui {
	foreach pais of local paises {
		foreach ano of local anos {
			
			* En este dofile de encuentra el diccionario de encuestas y rondas de la región
			include "${input}\Directorio HS LAC.do" 

			foreach encuesta of local encuestas {					
				foreach ronda of local rondas {					
							
					cap use "${source}\\`pais'\\`encuesta'\data_arm\\`pais'_`ano'`ronda'_BID.dta" , clear
					
					if _rc == 0 { //* Si esta base de datos existe, entonces haga: */
										
							* variables de clase
							
								cap gen Total  =  1
								cap gen Hombre = (sexo_ci==1)  
								cap gen Mujer  = (sexo_ci==2)
								cap gen Urbano = (zona_c==1)
								cap gen Rural  = (zona_c==0)
							
								if "`pais'" == "HND" | ("`pais'" == "NIC" & "`ano'" == "2009")  {
								drop quintil 
								}
										
								* Generando Quintiles de acuerdo a SUMMA y toda la división 
												
								cap egen    ytot_ci= rsum(ylm_ci ylnm_ci ynlm_ci ynlnm_ci) if miembros_ci==1
								replace ytot_ci= .   if ylm_ci==. & ylnm_ci==. & ynlm_ci==. & ynlnm_ci==.
								cap bys		idh_ch: egen ytot_ch= sum(ytot_ci) if miembros_ci==1
								replace ytot_ch=. if ytot_ch<=0
								cap gen 	pc_ytot_ch=ytot_ch/nmiembros_ch	
								sort 	pc_ytot_ch idh_ch idp_ci
								cap gen 	suma1=sum(factor_ci) if ytot_ch>0 & ytot_ch!=.
								cap qui su  suma1
								local 	ppquintil2 = r(max)/5 

								cap gen quintil_1=1 if suma1>=0 & suma1<=1*`ppquintil2'
								cap gen quintil_2=1 if suma1>1*`ppquintil2' & suma1<=2*`ppquintil2'
								cap gen quintil_3=1 if suma1>2*`ppquintil2' & suma1<=3*`ppquintil2'
								cap gen quintil_4=1 if suma1>3*`ppquintil2' & suma1<=4*`ppquintil2'
								cap gen quintil_5=1 if suma1>4*`ppquintil2' & suma1<=5*`ppquintil2'						
					
							* Variables intermedias 
					
								* Educación: niveles y edades teóricas cutomizadas  
									include "${input}\var_tmp_EDU.do"
								* Mercado laboral 
									include "${input}\var_tmp_LMK.do"
								* Pobreza, vivienda, demograficas
									include "${input}\var_tmp_SOC.do"
								* Inclusion
									include "${input}\var_tmp_GDI.do"	
									
							* base de datos de microdatos con variables intermedias
						include "${input}\append_calculo_microdatos_scl.do"											
						

*****************************************************************************************************************************************
					* 1.2: Indicators for each topic		
*****************************************************************************************************************************************
						foreach tema of local temas {
											
								if "`tema'" == "demografia" local indicadores jefa_ch jefaecon_ch pobfem_ci union_ci miembro6_ch miembro6y16_ch miembro65_ch unip_ch nucl_ch ampl_ch comp_ch corres_ch  pob18_ci pob65_ci urbano_ci pobedad_ci 
								
								if "`tema'" == "pobreza"    local indicadores pobreza31 pobreza vulnerable middle rich ginihh gini theilhh theil indexrem ylmfem_ch
								
								if "`tema'" == "educacion"  local indicadores tasa_bruta_asis tasa_neta_asis tasa_asis_edad tasa_no_asis_edad Años_Escolaridad_25_mas Ninis_2 leavers tasa_terminacion_c tasa_sobre_edad
								
								if "`tema'" == "vivienda"   local indicadores aguared_ch des2_ch luz_ch dirtf_ch refrig_ch auto_ch internet_ch cel_ch parednp_ch techonp_ch hacinamiento_ch estable_ch
								
								if "`tema'" == "laboral"    local indicadores tasa_ocupacion tasa_desocupacion tasa_participacion ocup_suf_salario ingreso_mens_prom ingreso_hor_prom formalidad_2 pensionista_65_mas y_pen_cont_ppp horas_trabajadas salminmes_ppp sal_menor_salmin dura_desempleo empleo_publico y_pen_cont y_pen_nocont y_pen_total salminhora_ppp salmin_hora salmin_mes tasa_asalariados tasa_independientes tasa_patrones tasa_sinremuneracion subempleo inglaboral_ppp_formales inglaboral_ppp_informales inglaboral_formales inglaboral_informales nivel_asalariados nivel_independientes nivel_patrones nivel_sinremuneracion nivel_subempleo tasa_agro nivel_agro tasa_minas nivel_minas tasa_industria nivel_industria tasa_sspublicos nivel_sspublicos tasa_construccion nivel_construccion tasa_comercio nivel_comercio tasa_transporte nivel_transporte tasa_financiero nivel_financiero tasa_servicios nivel_servicios tasa_profestecnico nivel_profestecnico tasa_director nivel_director tasa_administrativo nivel_administrativo tasa_comerciantes nivel_comerciantes tasa_trabss nivel_trabss tasa_trabagricola nivel_trabagricola tasa_obreros nivel_obreros tasa_ffaa nivel_ffaa tasa_otrostrab nivel_otrostrab 
								
								if "`tema'" == "diversidad" local indicadores pdis_ci
	
							
							
							foreach indicador of local indicadores {
							
							noi di in y "Calculating numbers for country: `pais' - year : `ano' - tema: `tema' - indicator: `indicador'"
								
								if "`tema'"	== "demografia" {
					
									local clases Total quintil_1 quintil_2 quintil_3 quintil_4 quintil_5 Rural Urbano
									local clases2 Total Rural Urbano
					
							foreach clase of local clases{
								foreach clase2 of local clases2 { 
								
										
										/* Porcentaje de hogares con jefatura femenina */
										if "`indicador'" == "jefa_ch" {
				
														capture sum Total [w=round(factor_ci)]	 if jefe_ci ==1 & sexo_ci!=. & `clase'==1 & `clase2'==1
														if _rc == 0 {
														local num_hog = `r(sum)'
														
														cap sum Total [w=round(factor_ci)]	 if jefa_ch==1 & `clase'==1 & `clase2'==1
														local numerador = `r(sum)'
														local valor = (`numerador' / `num_hog') * 100 
														
														cap sum Total  if jefa_ch==1 & `clase'==1 & `clase2'==1
														local muestra = `r(sum)'

														post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
														}
										} /* cierro indicador*/
										
										/* Porcentaje de hogares con jefatura económica femenina */
										if "`indicador'" == "jefaecon_ch" {
				
														capture sum Total [w=round(factor_ci)]	 if jefe_ci ==1 & sexo_ci!=. & `clase'==1 & `clase2'==1
														if _rc == 0 {
														local num_hog = `r(sum)'
														
														cap sum Total [w=round(factor_ci)]	 if hhfem_ch==1 & `clase'==1 & `clase2'==1
														local numerador = `r(sum)'
														local valor = (`numerador' / `num_hog') * 100 
														
														cap sum Total  if hhfem_ch==1 & `clase'==1 & `clase2'==1
														local muestra = `r(sum)'
														
														post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
														}
										} /* cierro indicador*/
										
										 if "`indicador'" == "pobfem_ci" {
				
														capture sum Total [w=round(factor_ci)]	 if jefe_ci ==1 & sexo_ci!=. & `clase'==1 & `clase2'==1 
														if _rc == 0 {
														local num_hog = `r(sum)'
														
														cap sum Total [w=round(factor_ci)]	 if  sexo_ci==2 & `clase'==1 & `clase2'==1
														local numerador = `r(sum)'
														local valor = (`numerador' / `num_hog') * 100 
														
														cap sum Total  if  sexo_ci==2 & `clase'==1 & `clase2'==1
														local muestra = `r(sum)'
														
														post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
														}
										} /* cierro indicador*/
										
										/* Porcentaje de hogares con al menos un miembro de 0-5 años*/
										if "`indicador'" == "miembro6_ch" {
				
														capture sum Total [w=round(factor_ci)]	if jefe_ci ==1 & `clase'==1 & `clase2'==1
														if _rc == 0 {
														local num_hog = `r(sum)'
														
														cap sum Total [w=round(factor_ci)]	 if miembro6_ch==1 & `clase'==1 & `clase2'==1
														local numerador = `r(sum)'
														local valor = (`numerador' / `num_hog') * 100 
														
														cap sum Total  if miembro6_ch==1 & `clase'==1 & `clase2'==1
														local muestra = `r(sum)'
														
														post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
														}
										} /* cierro indicador*/
										
										/* Porcentaje de hogares con al menos un miembro entre 6-16 años*/
										if "`indicador'" == "miembro6y16_ch" {
				
														capture sum Total [w=round(factor_ci)]	if jefe_ci ==1 & `clase'==1 & `clase2'==1
														if _rc == 0 {
														local num_hog = `r(sum)'
														
														cap sum Total [w=round(factor_ci)]	 if miembro6y16_ch==1 & `clase'==1 & `clase2'==1
														local numerador = `r(sum)'
														local valor = (`numerador' / `num_hog') * 100 
														
														cap sum Total  if miembro6y16_ch==1 & `clase'==1 & `clase2'==1
														local muestra = `r(sum)'
														
														post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
														}
										} /* cierro indicador*/
										
										/* Porcentaje de hogares con al menos un miembro de 65 años o más*/
										if "`indicador'" == "miembro65_ch" {
				
														capture sum Total [w=round(factor_ci)]	if jefe_ci ==1 & `clase'==1 & `clase2'==1
														if _rc == 0 {
														local num_hog = `r(sum)'
														
														cap sum Total [w=round(factor_ci)]	 if miembro65_ch==1 & `clase'==1 & `clase2'==1
														local numerador = `r(sum)'
														local valor = (`numerador' / `num_hog') * 100 
														
														sum Total  if miembro65_ch==1 & `clase'==1 & `clase2'==1
														local muestra = `r(sum)'
														
														post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
														}
										} /* cierro indicador*/
										
										/* Porcentaje de hogares unipersonales*/
										if "`indicador'" == "unip_ch" {
				
														capture sum Total [w=round(factor_ci)]	if jefe_ci ==1 & `clase'==1 & `clase2'==1
														if _rc == 0 {
														local num_hog = `r(sum)'
														
														sum Total [w=round(factor_ci)]	 if unip_ch==1 & `clase'==1 & `clase2'==1
														local numerador = `r(sum)'
														local valor = (`numerador' / `num_hog') * 100 
														
														sum Total  if unip_ch==1 & `clase'==1 & `clase2'==1
														local muestra = `r(sum)'
														
														post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
														}
										} /* cierro indicador*/
										
										/* Porcentaje de hogares nucleares*/
										if "`indicador'" == "nucl_ch" {
				
														capture sum Total [w=round(factor_ci)]	if jefe_ci ==1 & `clase'==1 & `clase2'==1
														if _rc == 0 {
														local num_hog = `r(sum)'
														
														sum Total [w=round(factor_ci)]	 if nucl_ch==1 & `clase'==1 & `clase2'==1
														local numerador = `r(sum)'
														local valor = (`numerador' / `num_hog') * 100 
														
														sum Total  if nucl_ch==1 & `clase'==1 & `clase2'==1
														local muestra = `r(sum)'
														
														post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
														}
										} /* cierro indicador*/
										
										/* Porcentaje de hogares ampliados*/
										if "`indicador'" == "ampl_ch" {
				
														capture sum Total [w=round(factor_ci)]	if jefe_ci ==1 & `clase'==1 & `clase2'==1
														if _rc == 0 {
														local num_hog = `r(sum)'
														
														sum Total [w=round(factor_ci)]	 if ampl_ch==1 & `clase'==1 & `clase2'==1
														local numerador = `r(sum)'
														local valor = (`numerador' / `num_hog') * 100 
														
														sum Total  if ampl_ch==1 & `clase'==1 & `clase2'==1
														local muestra = `r(sum)'
														
														post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
														}
										} /* cierro indicador*/
										
										/* Porcentaje de hogares compuestos*/
										if "`indicador'" == "comp_ch" {
				
														capture sum Total [w=round(factor_ci)]	if jefe_ci ==1 & `clase'==1 & `clase2'==1
														if _rc == 0 {
														local num_hog = `r(sum)'
														
														sum Total [w=round(factor_ci)]	 if comp_ch==1 & `clase'==1 & `clase2'==1
														local numerador = `r(sum)'
														local valor = (`numerador' / `num_hog') * 100 
														
														sum Total  if comp_ch==1 & `clase'==1 & `clase2'==1
														local muestra = `r(sum)'
														
														post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
														}
										} /* cierro indicador*/
										
										/* Porcentaje de hogares corresidentes*/
										if "`indicador'" == "corres_ch" {
				
														capture sum Total [w=round(factor_ci)]	if jefe_ci==1 & `clase'==1 & `clase2'==1
														if _rc == 0 {
														local num_hog = `r(sum)'
														
														sum Total [w=round(factor_ci)]	 if corres_ch==1 & `clase'==1 & `clase2'==1
														local numerador = `r(sum)'
														local valor = (`numerador' / `num_hog') * 100 
														
														sum Total  if corres_ch==1 & `clase'==1 & `clase2'==1
														local muestra = `r(sum)'
														
														post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
														}
										} /* cierro indicador*/
										
										 /*Razón de dependencia*/
										if "`indicador'" == "depen_ch" {
				
														capture sum depen_ch [w=round(factor_ci)] if jefe_ci==1 & `clase'==1 & `clase2'==1
														if _rc == 0 {
														local num_hog = `r(mean)'
														local valor = (`num_hog')* 100 
																					
														sum depen_ch if jefe_ci==1 & `clase'==1 & `clase2'==1
														local muestra = `r(sum)'
														
														post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
														}
										} /* cierro indicador*/
										
										/* Número promedio de miembros del hogar*/
										if "`indicador'" == "tamh_ch" {
				
														capture sum nmiembros_ch [w=round(factor_ci)] if jefe_ci==1 & `clase'==1 & `clase2'==1
														if _rc == 0 {
														local num_hog = `r(mean)'
														local valor = (`num_hog') * 100 
																					
														sum nmiembros_ch if jefe_ci==1 & `clase'==1 & `clase2'==1
														local muestra = `r(sum)'
														
														post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
														}
										} /* cierro indicador*/ 
										
										/* Porcentaje de población menor de 18 años*/
										if "`indicador'" == "pob18_ci" {
				
														capture sum Total [w=round(factor_ci)]	if `clase'==1 & `clase2'==1
														if _rc == 0 {
														local num_hog = `r(sum)'
														
														sum Total [w=round(factor_ci)]	 if pob18_ci==1 & `clase'==1 & `clase2'==1
														local numerador = `r(sum)'
														local valor = (`numerador' / `num_hog') * 100 
														
														sum Total  if pob18_ci==1 & `clase'==1 & `clase2'==1
														local muestra = `r(sum)'
														
														post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
														}
										} /* cierro indicador*/
										
										/* Porcentaje de población de 65+ años*/
										if "`indicador'" == "pob65_ci" {
				
														capture sum Total [w=round(factor_ci)]	if  `clase'==1 & `clase2'==1
														if _rc == 0 {
														local num_hog = `r(sum)'
														
														sum Total [w=round(factor_ci)]	 if pob65_ci==1 & `clase'==1 & `clase2'==1
														local numerador = `r(sum)'
														local valor = (`numerador' / `num_hog') * 100 
														
														sum Total  if pob65_ci==1 & `clase'==1 & `clase2'==1
														local muestra = `r(sum)'
														
														post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
														}
										} /* cierro indicador*/
																				
										/* Porcentaje de individuos en union formal o informal*/
										if "`indicador'" == "union_ci" {
				
														capture sum Total [w=round(factor_ci)]	if `clase'==1 & `clase2'==1
														if _rc == 0 {
														local num_hog = `r(sum)'
														
														sum Total [w=round(factor_ci)]	 if union_ci==1 & `clase'==1 & `clase2'==1
														local numerador = `r(sum)'
														local valor = (`numerador' / `num_hog') * 100 
														
														sum Total  if union_ci==1 & `clase'==1 & `clase2'==1
														local muestra = `r(sum)'
														
														post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
														}
										} /* cierro indicador*/
																				
										/* Edad mediana de la población en años */
										if "`indicador'" == "pobedad_ci_ch" {
				
														capture sum edad_ci [w=round(factor_ci)] if `clase'==1 & `clase2'==1
														if _rc == 0 {
														local num_hog = `r(mean)'
																					
														sum edad_ci if `clase'==1 & `clase2'==1
														local muestra = `r(sum)'
														
														post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
														}
										} /* cierro indicador*/	
								}/*cierro clase2*/		
							} /*cierro clase*/
							
								local clases Total quintil_1 quintil_2 quintil_3 quintil_4 quintil_5 
															
									foreach clase of local clases{
									
									/* Porcentaje de población que reside en zonas urbanas*/
										if "`indicador'" == "urbano_ci"  {
				
														capture sum Total [w=round(factor_ci)]	if  `clase'==1 
														if _rc == 0 {
														local num_hog = `r(sum)'
														
														sum Total [w=round(factor_ci)]	 if urbano_ci==1 & `clase'==1 
														local numerador = `r(sum)'
														local valor = (`numerador' / `num_hog') * 100 
														
														sum Total  if urbano_ci==1 & `clase'==1 
														local muestra = `r(sum)'
														
														post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("no_aplica") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
														}
										} /* cierro indicador*/
										
									} /*cierro clase*/			    
					} /*cierro demografia*/								
																	
								if "`tema'" == "educacion" 	{
									
									local clases  Total Hombre Mujer quintil_1 quintil_2 quintil_3 quintil_4 quintil_5 Rural Urbano
									local clases2 Total Hombre Mujer Rural Urbano
									
									foreach clase of local clases {	
										foreach clase2 of local clases2 {
								
										* Tasa Bruta de Asistencia
										if "`indicador'" == "tasa_bruta_asis" {
																									 
										* Prescolar   
														capture sum age_pres [w=round(factor_ci)]	 if `clase'==1 & asiste_ci!=. & `clase2' ==1
														if _rc == 0 {
														local pop_pres = `r(sum)'
														
														sum asis_pres [w=round(factor_ci)]	 if `clase'==1 & asiste_ci!=. & `clase2' ==1
														local numerador = `r(sum)'
														local valor = (`numerador' / `pop_pres') * 100 
														
														sum asis_pres 	 if `clase'==1 & asiste_ci!=. & `clase2' ==1
														local muestra = `r(sum)'
														
														post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("Prescolar") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
														}
										
										* Primaria   
														capture sum age_prim [w=round(factor_ci)] if asiste_ci!=. &  `clase'==1  & `clase2' ==1  
														if _rc == 0 {
														local pop_prim = `r(sum)'
														
														sum asis_prim [w=round(factor_ci)]	 if  edad_ci>=6 & asiste_ci!=. & `clase'==1 & `clase2' ==1
														local numerador = `r(sum)'
														local valor = (`numerador' / `pop_prim') * 100 
														
														sum asis_prim  if `clase'==1 & edad_ci>=6 & asiste_ci!=. & `clase2' ==1
														local muestra = `r(sum)'
														
														post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("Primaria") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
														}
										
										* Secundaria 
														capture sum age_seco [w=round(factor_ci)]	if `clase'==1 & asiste_ci!=. & `clase2' ==1
														if _rc == 0 {
														local pop_seco = `r(sum)'	
										
														sum asis_seco [w=round(factor_ci)]	 if `clase'==1 & edad_ci>=6 & asiste_ci!=. & `clase2' ==1
														local numerador = `r(sum)'
														local valor = (`numerador'/ `pop_seco') * 100 
														
														sum asis_seco  if `clase'==1 & edad_ci>=6 & asiste_ci!=. & `clase2' ==1
														local muestra = `r(sum)'
														
														post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("Secundaria") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
														}								
														
										*Terciaria
														capture sum age_tert [w=round(factor_ci)]	if `clase'==1 & asiste_ci!=. & `clase2' ==1
														if _rc == 0 {
														local pop_tert = `r(sum)'	
														
														sum asis_tert [w=round(factor_ci)]	 if `clase'==1 & edad_ci>=6 & asiste_ci!=. & `clase2' ==1
														local numerador = `r(sum)'
														local valor = (`numerador'/ `pop_tert') * 100 
														
														sum asis_tert  if `clase'==1 & edad_ci>=6 & asiste_ci!=. & `clase2' ==1
														local muestra = `r(sum)'
														
														post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("Superior") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
														
														} /*cierro if*/
														
										} /*cierro if de indicador*/
													
										* Tasa de Asistencia Neta
										if "`indicador'" == "tasa_neta_asis" {	

										* Prescolar   						
														cap estpost tab asis_pres [w=round(factor_ci)] 	if age_pres == 1 & asiste_ci !=. & `clase'==1 & `clase2' ==1, m
														if _rc == 0 {
															mat proporcion = e(pct)
															local valor = proporcion[1,2]
														
															estpost tab asis_pres				if age_pres == 1 & asiste_ci !=. & `clase'==1  & `clase2' ==1, m
															mat nivel = e(b)
															local muestra = nivel[1,2]
																									
														post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("Prescolar") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
														}
														
														else {
														
														post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("Primaria") ("`tema'") ("`indicador'") (".") (".")
														
														}
										* Primaria   
														cap estpost tab asis_prim [w=round(factor_ci)] 	if age_prim == 1 & asiste_ci !=. & `clase'==1 & `clase2' ==1, m
														if _rc == 0 {
															mat proporcion = e(pct)
															local valor = proporcion[1,1]
														
															estpost tab asis_prim				if age_prim == 1 & asiste_ci !=. & `clase'==1  & `clase2' ==1, m
															mat nivel = e(b)
															local muestra = nivel[1,1]
															
															post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("Primaria") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
														}
														
														else {
															
															post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("Primaria") ("`tema'") ("`indicador'") (".") (".")
														
														}
										* Secundaria 
														cap estpost tab asis_seco [w=round(factor_ci)] 	if age_seco == 1 & asiste_ci !=. & `clase'==1 & `clase2' ==1, m
														if _rc == 0 {
															mat proporcion = e(pct)
															local valor = proporcion[1,1]
															
															estpost tab asis_seco				if age_seco == 1 & asiste_ci !=. & `clase'==1  & `clase2' ==1, m
															mat nivel = e(b)
															local muestra = nivel[1,1]							
															
															post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("Secundaria") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
														}
														
														else {
															
															post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("Primaria") ("`tema'") ("`indicador'") (".") (".")
														
														}
														
										 *Superior						
														cap estpost tab asis_tert [w=round(factor_ci)] 	if age_tert == 1 & asiste_ci !=. & `clase'==1 & `clase2' ==1, m
														if _rc == 0 {
															mat proporcion = e(pct)
															local valor = proporcion[1,1]
									  
															estpost tab asis_tert				if age_tert == 1 & asiste_ci !=. & `clase'==1  & `clase2' ==1, m
															mat nivel = e(b)
															local muestra = nivel[1,1]																	
														
															post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("Superior") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
														}
														
														else {
															
															post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("Primaria") ("`tema'") ("`indicador'") (".") (".")
														
														}
														
										} /* cierro if indicador*/
																											
										* Tasa Asistencia grupo etario							
										if "`indicador'" == "tasa_asis_edad" {	
											
											local niveles age_4_5 age_6_11 age_12_14 age_15_17 age_18_23
											
												foreach nivel of local niveles {	
													
													cap estpost tab asiste_ci [w=round(factor_ci)] if `nivel' ==1 & `clase'==1
													if _rc == 0 {
														mat proporcion = e(pct)
														local valor = proporcion[1,2]
														
														estpost tab asiste_ci 				if `nivel' ==1 & `clase'==1
														mat nivel = e(b)
														local muestra = nivel[1,2]
																								
														post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
													}
													
													else {
															
															post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("Primaria") ("`tema'") ("`indicador'") (".") (".")
														
													}
														
												} /*cierro niveles*/
										} /* cierro if indicador*/

										* Tasa No Asistencia grupo etario
										if "`indicador'" == "tasa_no_asis_edad" {	
											
											local niveles age_4_5 age_6_11 age_12_14 age_15_17 age_18_23
											
												foreach nivel of local niveles {
									 
													cap estpost tab asiste_ci [w=round(factor_ci)] if `nivel' ==1 & `clase'==1
													if _rc == 0 {
													mat proporcion = e(pct)
													local valor = proporcion[1,1]
													
													estpost tab asiste_ci 				if `nivel' ==1 & `clase'==1
													mat nivel = e(b)
													local muestra = nivel[1,1]
														
													post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
													}
													
													else {
															
															post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("Primaria") ("`tema'") ("`indicador'") (".") (".")
														
													}
													
												} /*cierro niveles*/
										} /* cierro if indicador*/
												
										* Años_Escolaridad y Años_Escuela
										if "`indicador'" == "Años_Escolaridad_25_mas" {	
												
											local niveles anos_0 anos_1_5 anos_6 anos_7_11 anos_12 anos_13_o_mas
											
												foreach nivel of local niveles {
																								
													cap estpost tab `nivel' [w=round(factor_ci)] if  age_25_mas==1 & `clase'==1 & `clase2'==1 & (aedu_ci !=. | edad_ci !=.), m
													if _rc == 0 {
													mat proporcion = e(pct)
													local valor = proporcion[1,1]

													estpost tab `nivel' 				if age_25_mas==1 & `clase'==1 & `clase2'==1 & (aedu_ci !=. | edad_ci !=.), m
													mat nivel = e(b)
													local muestra = nivel[1,1]
																								
													post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
													} /* cierro if */
													
													else {
															
															post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("Primaria") ("`tema'") ("`indicador'") (".") (".")
														
													} /* cierro else */
													
												} /* cierro nivel */		
										} /* cierro if indicador*/		
													
										* Ninis Inactivos no asisten
										if "`indicador'" == "Ninis_2" {									
											
											local niveles age_15_24 age_15_29
												
												foreach nivel of local niveles {
																								
													cap estpost tab nini [w=round(factor_ci)] 	if `nivel' == 1 & `clase'==1  & edad_ci !=. & `clase2' ==1, m
													if _rc == 0 {
														mat proporcion = e(pct)
														local valor = proporcion[1,1]
														
														estpost tab nini 				if `nivel' == 1 & `clase'==1 & edad_ci !=. & `clase2' ==1, m
														mat nivel = e(b)
														local muestra = nivel[1,1]
														
													post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
													} /* cierro if */
													
													else {
															
													post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") (".") (".")
														
													} /* cierro else */
													
													
												} /* cierro nivel*/			
										} /* cierro if indicador*/		

										* Tasa de terminación
										if "`indicador'" == "tasa_terminacion_c" {	
													
											*Primaria
										
													cap estpost tab tprimaria [w=round(factor_ci)] if age_term_p_c == 1 & tprimaria !=. & `clase'==1  & edad_ci !=. & `clase2' ==1, m
													if _rc == 0 {
													mat proporcion = e(pct)
													local valor = proporcion[1,2]
													
													estpost tab tprimaria  if age_term_p_c == 1 & tprimaria !=. & `clase'==1  & edad_ci !=. & `clase2' ==1, m
													mat nivel = e(b)
													local muestra = nivel[1,2]
											
													post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("Primaria") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
													
													}/* cierro if */
													
													else {
															
													post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("Primaria") ("`tema'") ("`indicador'") (".") (".")
														
													} /* cierro else */
											
													
											*Secundaria		
										
													cap estpost tab tsecundaria [w=round(factor_ci)] 	if age_term_s_c == 1 & tprimaria !=. & `clase'==1  & edad_ci !=. & `clase2' ==1, m
													if _rc == 0 {
													mat proporcion = e(pct)
													local valor = proporcion[1,2]
													
													estpost tab tsecundaria  if age_term_s_c == 1 & tprimaria !=. & `clase'==1  & edad_ci !=. & `clase2' ==1, m
													mat nivel = e(b)
													local muestra = nivel[1,2]
														
													post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("Secundaria") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
													
													}/* cierro if */
													
													else {
															
													post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("Secundaria") ("`tema'") ("`indicador'") (".") (".")
														
													} /* cierro else */
													
										} /*cierro indicador 
																			
										* Tasa de abandono escolar temprano "Leavers"  */
										if "`indicador'" == "leavers" {
																									
													cap estpost tab leavers [w=round(factor_ci)] 	if age_18_24 == 1 & edad_ci !=. & `clase'==1 & `clase2' ==1, m
													if _rc == 0 {
													mat proporcion = e(pct)
													local valor = proporcion[1,1]
													
													estpost tab leavers 				if age_18_24 == 1 & edad_ci !=. & `clase'==1  & `clase2' ==1, m
													mat nivel = e(b)
													local muestra = nivel[1,1]
																							
													post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("Total") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
													} /* cierro if */
													
													else {
															
													post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("Total") ("`tema'") ("`indicador'") (".") (".")
														
													} /* cierro else */
													
										} /*cierro indicador 
												
										* Tasa de abandono sobreedad"  */
										if "`indicador'" == "tasa_sobre_edad" {								
											

											*Primaria
													
													cap estpost tab age_prim_sobre [w=round(factor_ci)] 	if asis_prim_c == 1 & asiste_ci !=. & `clase'==1 & `clase2' ==1, m
													if _rc == 0 {
													mat proporcion = e(pct)
													local valor = proporcion[1,1]
													
													estpost tab age_prim_sobre				if asis_prim_c == 1 & asiste_ci !=. & `clase'==1  & `clase2' ==1, m
													mat nivel = e(b)
													local muestra = nivel[1,1]

													post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("Primaria") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
													} /* cierro if */
													
													else {
															
													post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("Primaria") ("`tema'") ("`indicador'") (".") (".")
														
													} /* cierro else */
													
													
										} /* cierro if indicador*/ 
										} /* cierro clase2 */
									}	/* cierro clase */			
				
								} /*cierro educacion*/
				
								if "`tema'" == "laboral" 	{
									
									local clases  Total Hombre Mujer quintil_1 quintil_2 quintil_3 quintil_4 quintil_5 Rural Urbano
									local clases2 Total Hombre Mujer Rural Urbano
									local niveles Total age_15_24 age_15_29 age_15_64 age_25_64 age_65_mas 
							
								foreach clase of local clases {
									foreach clase2 of local clases2 {
										foreach nivel of local niveles {
								
										if "`indicador'" == "tasa_ocupacion" {																						 
							  
											cap estpost tabulate condocup_ci [w=round(factor_ci)] if `clase'==1 & `clase2' ==1
											if _rc == 0 {
											mat a = e(pct)
											mat b = e(b)
											local valor=a[1,1]
											local muestra=b[1,1]				

											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
											
										} /*cierro indicador*/
										
										if "`indicador'" == "tasa_desocupacion" {	
										
											capture sum `nivel' [w=round(factor_ci)] if `clase'==1 & pea==1 & `clase2' ==1
											if _rc == 0 {
											local denominador = `r(sum)'
															
											sum `nivel' [w=round(factor_ci)]	 if `clase'==1 & condocup_ci==2 & `clase2' ==1
											local numerador = `r(sum)'
											local valor = (`numerador' / `denominador') * 100 
											
											sum `nivel' if `clase'==1 & condocup_ci==2 & `clase2' ==1
											local muestra = `r(sum)'
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}				
											
										} /*cierro indicador*/
										
										if "`indicador'" == "tasa_participacion" {	
										
											capture sum `nivel' [w=round(factor_ci)] if `clase'==1 & pet==1 & `clase2' ==1
											if _rc == 0 {
											local denominador = `r(sum)'
															
											sum `nivel' [w=round(factor_ci)]	 if `clase'==1 & pea==1 & `clase2' ==1
											local numerador = `r(sum)'
											local valor = (`numerador' / `denominador') * 100 
											
											sum `nivel' if `clase'==1 & pea==1 & `clase2' ==1
											local muestra = `r(sum)'
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
											
										} /*cierro indicador*/
											
										if "`indicador'" == "ocup_suf_salario" {	
										
											capture sum `nivel' [w=round(factor_ci)] if `clase'==1 & liv_wage !=. & `clase2' ==1 & condocup_ci==1
											if _rc == 0 {
											local denominador = `r(sum)'
															
											sum `nivel' [w=round(factor_ci)]	 if `clase'==1 & liv_wage ==1 & `clase2' ==1 & condocup_ci==1
											local numerador = `r(sum)'
											local valor = (`numerador' / `denominador') * 100 
											
											sum `nivel' if `clase'==1 & liv_wage ==1 & `clase2' ==1 & condocup_ci==1
											local muestra = `r(sum)'
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
											
										} /*cierro indicador*/
										
										if "`indicador'" == "ingreso_mens_prom" {	
										
											capture sum `nivel' [w=round(factor_ci)] if `clase'==1 & ylab_ppp!=. & `clase2' ==1 & condocup_ci==1
											if _rc == 0 {
											local denominador = `r(sum)'
															
											sum ylab_ppp [w=round(factor_ci)]	 if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											local numerador = `r(sum)'
											local valor = (`numerador' / `denominador') 												
											

											sum ylab_ppp [w=round(factor_ci)]	 if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											local muestra = `r(sum)'
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
											
										} /*cierro indicador*/
										
										if "`indicador'" == "ingreso_hor_prom" {	
										
											capture sum `nivel' [w=round(factor_ci)] if `clase'==1 & hwage_ppp!=. & `clase2' ==1 & condocup_ci==1
											if _rc == 0 {
											local denominador = `r(sum)'
															
											sum hwage_ppp [w=round(factor_ci)]	 if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											local numerador = `r(sum)'
											local valor = (`numerador' / `denominador') 												
											

											sum hwage_ppp if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											local muestra = `r(sum)'
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
										} /*cierro indicador*/
										
										if "`indicador'" == "horas_trabajadas" {	
										
											capture sum horastot_ci [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1 & horastot_ci!=.
											if _rc == 0 {
											cap local valor = `r(mean)'												
											
											sum horastot_ci if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1 & horastot_ci!=.
											local muestra = `r(N)'
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
										} /*cierro indicador*/	

										if "`indicador'" == "dura_desempleo" {	
										
											capture sum durades_ci [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==2 & durades_ci!=.
											if _rc == 0 {
											cap local valor = `r(mean)'												
											
											sum durades_ci if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==2  & durades_ci!=.
											local muestra = `r(N)'
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
										} /*cierro indicador*/	

										if "`indicador'" == "salminmes_ppp" {	
										
											capture sum salmm_ppp [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1 & salmm_ppp!=.
											if _rc == 0 {
											cap local valor = `r(mean)'												
											
											sum salmm_ppp if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1 & salmm_ppp!=.
											local muestra = `r(N)'
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
										} /*cierro indicador*/
										
										if "`indicador'" == "sal_menor_salmin" {	
										
											capture estpost tab menorwmin [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											if _rc == 0 {
											mat a = e(pct)
											local valor=a[1,2]
											
											estpost tab menorwmin if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											mat b = e(b)
											local muestra=b[1,2]
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
										} /*cierro indicador*/							
																	
										if "`indicador'" == "salminhora_ppp" {	
										
											capture sum hsmin_ppp [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1 & hsmin_ppp!=.
											if _rc == 0 {
											cap local valor = `r(mean)'												
											
											sum hsmin_ppp if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1 & hsmin_ppp!=.
											local muestra = `r(N)'
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
										} /*cierro indicador*/	
										
										if "`indicador'" == "salmin_mes" {	
										
											capture sum salmm_ci [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1 & salmm_ci!=.
											if _rc == 0 {
											cap local valor = `r(mean)'												
											
											sum salmm_ci if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1 & salmm_ci!=.
											local muestra = `r(N)'
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
										} /*cierro indicador*/
										
										if "`indicador'" == "salmin_hora" {	
										
											capture sum hsmin_ci [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1 & hsmin_ci!=.
											if _rc == 0 {
											cap local valor = `r(mean)'												
											
											sum hsmin_ci if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1 & hsmin_ci!=.
											local muestra = `r(N)'
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
										} /*cierro indicador*/	

										if "`indicador'" == "tasa_asalariados" {	
										
											capture estpost tab asalariado [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											if _rc == 0 {
											mat a = e(pct)
											local valor=a[1,2]
											
											estpost tab asalariado if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											mat b = e(b)
											local muestra=b[1,2]
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
										} /*cierro indicador*/	
										
										if "`indicador'" == "tasa_independientes" {	
										
											capture estpost tab ctapropia [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											if _rc == 0 {
											mat a = e(pct)
											local valor=a[1,2]
											
											estpost tab ctapropia if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											mat b = e(b)
											local muestra=b[1,2]
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
										} /*cierro indicador*/	
										
										if "`indicador'" == "tasa_patrones" {	
										
											capture estpost tab patron [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											if _rc == 0 {
											mat a = e(pct)
											local valor=a[1,2]							
											estpost tab patron if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											mat b = e(b)					
											local muestra=b[1,2]
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
										} /*cierro indicador*/	
										
										if "`indicador'" == "tasa_sinremuneracion" {	
										
											cap estpost tab sinremuner [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											if _rc == 0 {
											mat a = e(pct)
											local valor=a[1,2]
											
											estpost tab sinremuner if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											mat b = e(b)
											local muestra=b[1,2]
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
										} /*cierro indicador*/							
										
										if "`indicador'" == "subempleo" {	
										
											capture estpost tab subemp_ci [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											if _rc == 0 {
											mat a = e(pct)
											local valor=a[1,2]
											
											estpost tab subemp_ci if `clase'==1 & `nivel'==1 & `clase2'==1 & condocup_ci==1
											mat b = e(b)
											local muestra=b[1,2]
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
											
										} /*cierro indicador*/		
										
										if "`indicador'" == "inglaboral_ppp_formales" {	
										
											cap sum ylab_ppp [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2'==1 & condocup_ci==1 & formal_ci==1
											if _rc == 0 {
											cap local valor = `r(mean)'												
											
											sum ylab_ppp if `clase'==1 & `nivel'==1 & `clase2'==1 & condocup_ci==1 & formal_ci==1
											local muestra = `r(N)'
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
											
						  } /*cierro indicador*/
										
										if "`indicador'" == "inglaboral_ppp_informales" {	
										
											capture sum ylab_ppp [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2'==1 & condocup_ci==1 & formal_ci==0
											if _rc == 0 {
											cap local valor = `r(mean)'												
											
											sum ylab_ppp if `clase'==1 & `nivel'==1 & `clase2'==1 & condocup_ci==1 & formal_ci==0
											local muestra = `r(N)'
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
										} /*cierro indicador*/
										
										if "`indicador'" == "inglaboral_formales" {	
										
											capture sum ylab_ci [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2'==1 & condocup_ci==1 & formal_ci==1
											if _rc == 0 {
											cap local valor = `r(mean)'												
											
											sum ylab_ci if `clase'==1 & `nivel'==1 & `clase2'==1 & condocup_ci==1 & formal_ci==1
											local muestra = `r(N)'
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
										} /*cierro indicador*/
										
										if "`indicador'" == "inglaboral_informales" {	
										
											capture sum ylab_ci [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2'==1 & condocup_ci==1 & formal_ci==0
											if _rc == 0 {
											cap local valor = `r(mean)'												
											
											sum ylab_ci if `clase'==1 & `nivel'==1 & `clase2'==1 & condocup_ci==1 & formal_ci==0
											local muestra = `r(N)'
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
										} /*cierro indicador*/
						
										if "`indicador'" == "nivel_asalariados" {	
										
											capture estpost tab asalariado [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											if _rc == 0 {
											mat a = e(b)
											local valor=a[1,2]
											
											estpost tab asalariado if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											mat b = e(b)
											local muestra=b[1,2]
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
										} /*cierro indicador*/	
										
										if "`indicador'" == "nivel_independientes" {	
										
											capture estpost tab ctapropia [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											if _rc == 0 {
											mat a = e(b)
											local valor=a[1,2]
											
											estpost tab ctapropia if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											mat b = e(b)
											local muestra=b[1,2]
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
											
										} /*cierro indicador*/	
										
										if "`indicador'" == "nivel_patrones" {	
										
											capture estpost tab patron [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											if _rc == 0 {
											mat a = e(b)
											local valor=a[1,2]
											
											estpost tab patron if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											mat b = e(b)
											local muestra=b[1,2]
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
											
										} /*cierro indicador*/	

										if "`indicador'" == "nivel_sinremuneracion" {	
											
											cap estpost tab sinremuner [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											if _rc == 0 {
											mat a = e(b)
											local valor=a[1,2]
											
											estpost tab sinremuner if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											mat b = e(b)
											local muestra=b[1,2]
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
										} /*cierro indicador*/		
										
										if "`indicador'" == "nivel_subempleo" {	
										
											capture estpost tab subemp_ci [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											if _rc == 0 {
											mat a = e(b)
											local valor=a[1,2]
											
											estpost tab subemp_ci if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											mat b = e(b)
											local muestra=b[1,2]
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
										} /*cierro indicador*/	

										if "`indicador'" == "tasa_agro" {	
										
											capture estpost tab agro [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											if _rc == 0 {
											mat a = e(pct)
											local valor=a[1,2]
											
											estpost tab agro if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											mat b = e(b)
											local muestra=b[1,2]
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
											
										} /*cierro indicador*/	
										
										if "`indicador'" == "nivel_agro" {	
										
											capture estpost tab agro [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											if _rc == 0 {
											mat a = e(b)
											local valor=a[1,2]
											
											estpost tab agro if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											mat b = e(b)
											local muestra=b[1,2]
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
											
										} /*cierro indicador*/	
										
										if "`indicador'" == "tasa_minas" {	
										
											capture estpost tab minas [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											if _rc == 0 {
											mat a = e(pct)
											local valor=a[1,2]
											
											estpost tab minas if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											mat b = e(b)
											local muestra=b[1,2]
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
											
										} /*cierro indicador*/	
										
										if "`indicador'" == "nivel_minas" {	
										
											cap estpost tab minas [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											if _rc == 0 {
											mat a = e(b)
											local valor=a[1,2]
											
											estpost tab minas if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											mat b = e(b)
											local muestra=b[1,2]
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
										} /*cierro indicador*/			

										if "`indicador'" == "tasa_industria" {	
										
											capture estpost tab industria [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											if _rc == 0 {
											mat a = e(pct)
											local valor=a[1,2]
											
											estpost tab industria if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											mat b = e(b)
											local muestra=b[1,2]
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
										} /*cierro indicador*/	
										
										if "`indicador'" == "nivel_industria" {	
										
											cap estpost tab industria [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											if _rc == 0 {
											mat a = e(b)
											local valor=a[1,2]
											
											estpost tab industria if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											mat b = e(b)
											local muestra=b[1,2]
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
										} /*cierro indicador*/								
										
										if "`indicador'" == "tasa_sspublicos" {	
										
											capture estpost tab sspublicos [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											if _rc == 0 {
											mat a = e(pct)
											local valor=a[1,2]
											
											estpost tab sspublicos if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											mat b = e(b)
											local muestra=b[1,2]
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
										} /*cierro indicador*/	
										
										if "`indicador'" == "nivel_sspublicos" {	
										
											capture estpost tab sspublicos [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											if _rc == 0 {
											mat a = e(b)
											local valor=a[1,2]
											
											estpost tab sspublicos if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											mat b = e(b)
											local muestra=b[1,2]
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
										} /*cierro indicador*/						
										
										if "`indicador'" == "tasa_construccion" {	
										
											cap estpost tab construccion [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											if _rc == 0 {
											mat a = e(pct)
											local valor=a[1,2]
											
											estpost tab construccion if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											mat b = e(b)
											local muestra=b[1,2]
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
										} /*cierro indicador*/	
										
										if "`indicador'" == "nivel_construccion" {	
										
											cap estpost tab construccion [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											if _rc == 0 {
											mat a = e(b)
											local valor=a[1,2]
											
											estpost tab construccion if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											mat b = e(b)
											local muestra=b[1,2]
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
											
										} /*cierro indicador*/		
										
										if "`indicador'" == "tasa_comercio" {	
										
											cap estpost tab comercio [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											if _rc == 0 {
											mat a = e(pct)
											local valor=a[1,2]
											
											estpost tab comercio if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											mat b = e(b)
											local muestra=b[1,2]
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
											
										} /*cierro indicador*/	
										
										if "`indicador'" == "nivel_comercio" {	
										
											cap estpost tab comercio [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											if _rc == 0 {
											mat a = e(b)
											local valor=a[1,2]
											
											estpost tab comercio if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											mat b = e(b)
											local muestra=b[1,2]
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
											
										} /*cierro indicador*/								
										
										if "`indicador'" == "tasa_transporte" {	
										
											capture estpost tab transporte [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											if _rc == 0 {
											mat a = e(pct)
											local valor=a[1,2]
											
											estpost tab transporte if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											mat b = e(b)
											local muestra=b[1,2]
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
											
										} /*cierro indicador*/	
										
										if "`indicador'" == "nivel_transporte" {	
										
											capture estpost tab transporte [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											if _rc == 0 {
											mat a = e(b)
											local valor=a[1,2]
											
											estpost tab transporte if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											mat b = e(b)
											local muestra=b[1,2]
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
											
										} /*cierro indicador*/								
										
										if "`indicador'" == "tasa_financiero" {	
										
											cap estpost tab financiero [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											if _rc == 0 {
											mat a = e(pct)
											local valor=a[1,2]
											
											estpost tab financiero if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											mat b = e(b)
											local muestra=b[1,2]
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
											
										} /*cierro indicador*/	
										
										if "`indicador'" == "nivel_financiero" {	
										
											cap estpost tab financiero [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											if _rc == 0 {
											mat a = e(b)
											local valor=a[1,2]
											
											estpost tab financiero if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											mat b = e(b)
											local muestra=b[1,2]
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
											
										} /*cierro indicador*/	
										
										if "`indicador'" == "tasa_servicios" {	
										
											cap estpost tab servicios [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											if _rc == 0 {
											mat a = e(pct)
											local valor=a[1,2]
											
											estpost tab servicios if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											mat b = e(b)
											local muestra=b[1,2]
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
											
										} /*cierro indicador*/	
										
										if "`indicador'" == "nivel_servicios" {	
										
											capture estpost tab servicios [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											if _rc == 0 {
											mat a = e(b)
											local valor=a[1,2]
											
											estpost tab servicios if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											mat b = e(b)
											local muestra=b[1,2]
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
											
										} /*cierro indicador*/
							
										if "`indicador'" == "tasa_profestecnico" {	
										
											cap estpost tab profestecnico [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											if _rc == 0 {
											mat a = e(pct)
											local valor=a[1,2]
											
											estpost tab profestecnico if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											mat b = e(b)
											local muestra=b[1,2]
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
											
										} /*cierro indicador*/	
										
										if "`indicador'" == "nivel_profestecnico" {	
										
											cap estpost tab profestecnico [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											if _rc == 0 {
											mat a = e(b)
											local valor=a[1,2]
											
											estpost tab profestecnico if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											mat b = e(b)
											local muestra=b[1,2]
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
											
										} /*cierro indicador*/	
										
										if "`indicador'" == "tasa_director" {	
										
											capture estpost tab director [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											if _rc == 0 {
											mat a = e(pct)
											local valor=a[1,2]
											
											estpost tab director if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											mat b = e(b)
											local muestra=b[1,2]
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
											
										} /*cierro indicador*/	
										
										if "`indicador'" == "nivel_director" {	
										
											cap estpost tab director [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											if _rc == 0 {
											mat a = e(b)
											local valor=a[1,2]
											
											estpost tab director if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											mat b = e(b)
											local muestra=b[1,2]
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}				

										} /*cierro indicador*/	
										
										if "`indicador'" == "tasa_administrativo" {	
										
											capture estpost tab administrativo [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											if _rc == 0 {
											mat a = e(pct)
											local valor=a[1,2]
											
											estpost tab administrativo if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											mat b = e(b)
											local muestra=b[1,2]
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											} 
											
										} /*cierro indicador*/	
										
										if "`indicador'" == "nivel_administrativo" {	
										
											capture estpost tab administrativo [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											if _rc == 0 {
											mat a = e(b)
											local valor=a[1,2]
											
											estpost tab administrativo if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											mat b = e(b)
											local muestra=b[1,2]
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
											
										} /*cierro indicador*/								
										
										if "`indicador'" == "tasa_comerciantes" {	
										
											capture estpost tab comerciantes [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											if _rc == 0 {
											mat a = e(pct)
											local valor=a[1,2]
											
											estpost tab comerciantes if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											mat b = e(b)
											local muestra=b[1,2]
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
											
										} /*cierro indicador*/	
										
										if "`indicador'" == "nivel_comerciantes" {	
										
											capture estpost tab comerciantes [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											if _rc == 0 {
											mat a = e(b)
											local valor=a[1,2]
											
											estpost tab comerciantes if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											mat b = e(b)
											local muestra=b[1,2]
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
										} /*cierro indicador*/							
										
										if "`indicador'" == "tasa_trabss" {	
										
											cap estpost tab trabss [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											if _rc == 0 {
											mat a = e(pct)
											local valor=a[1,2]
											
											estpost tab trabss if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											mat b = e(b)
											local muestra=b[1,2]
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
										} /*cierro indicador*/	
										
										if "`indicador'" == "nivel_trabss" {	
										
											capture estpost tab trabss [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											if _rc == 0 {
											mat a = e(b)
											local valor=a[1,2]
											
											estpost tab trabss if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											mat b = e(b)
											local muestra=b[1,2]
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
											
										} /*cierro indicador*/			
										
										if "`indicador'" == "tasa_trabagricola" {	
										
											capture estpost tab trabagricola [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											if _rc == 0 {
											mat a = e(pct)
											local valor=a[1,2]
											
											estpost tab trabagricola if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											mat b = e(b)
											local muestra=b[1,2]
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
											
										} /*cierro indicador*/	
										
										if "`indicador'" == "nivel_trabagricola" {	
										
											capture estpost tab trabagricola [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											if _rc == 0 {
											mat a = e(b)
											local valor=a[1,2]
											
											estpost tab trabagricola if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											mat b = e(b)
											local muestra=b[1,2]
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
											
										} /*cierro indicador*/								
										
										if "`indicador'" == "tasa_obreros" {	
										
											capture estpost tab obreros [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											if _rc == 0 {
											mat a = e(pct)
											local valor=a[1,2]
											
											estpost tab obreros if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											mat b = e(b)
											local muestra=b[1,2]
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
										} /*cierro indicador*/	
										
										if "`indicador'" == "nivel_obreros" {	
										
											cap estpost tab obreros [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											if _rc == 0 {
											mat a = e(b)
											local valor=a[1,2]
											
											estpost tab obreros if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											mat b = e(b)
											local muestra=b[1,2]
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
											
										} /*cierro indicador*/	

										if "`indicador'" == "tasa_ffaa" {	
										
											cap estpost tab ffaa [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											if _rc == 0 {
											mat a = e(pct)
											local valor=a[1,2]
											
											estpost tab ffaa if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											mat b = e(b)
											local muestra=b[1,2]
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
											
										} /*cierro indicador*/	
										
										if "`indicador'" == "nivel_ffaa" {	
										
											cap estpost tab ffaa [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											if _rc == 0 {
											mat a = e(b)
											local valor=a[1,2]
											
											estpost tab ffaa if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											mat b = e(b)
											local muestra=b[1,2]
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
											
										} /*cierro indicador*/	

										if "`indicador'" == "tasa_otrostrab" {	
										
											cap estpost tab otrostrab [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											if _rc == 0 {
											mat a = e(pct)
											local valor=a[1,2]
											
											estpost tab otrostrab if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											mat b = e(b)
											local muestra=b[1,2]
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
											
										} /*cierro indicador*/	
										
										if "`indicador'" == "nivel_otrostrab" {	
										
											capture estpost tab otrostrab [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											if _rc == 0 {
											mat a = e(b)
											local valor=a[1,2]
											
											estpost tab otrostrab if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											mat b = e(b)
											local muestra=b[1,2]
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
											
										} /*cierro indicador*/	
										
										if "`indicador'" == "empleo_publico" {	
										
											cap estpost tab spublico_ci [w=round(factor_ci)] if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											if _rc == 0 {
											mat a = e(pct)
											local valor=a[1,2]
											
											estpost tab spublico_ci if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											mat b = e(b)
											local muestra=b[1,2]
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
											
										} /*cierro indicador*/	
										
										if "`indicador'" == "formalidad_2" {	
										
											cap sum `nivel' [w=round(factor_ci)] if `clase'==1 & condocup_ci==1 & `clase2' ==1
											if _rc == 0 {
											local denominador = `r(sum)'
															
											sum `nivel' [w=round(factor_ci)]	 if `clase'==1 & formal_ci==1 & condocup_ci==1 & `clase2' ==1
											local numerador = `r(sum)'
											local valor = (`numerador' / `denominador') * 100												
											
											sum `nivel' if `clase'==1 & formal_ci==1 & condocup_ci==1 & `clase2' ==1
											local muestra = `r(sum)'
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
											
										} /*cierro indicador*/
										
										if "`indicador'" == "formalidad_3" {	
										
											capture sum `nivel' [w=round(factor_ci)] if `clase'==1 & condocup_ci==1 & categopri_ci==3 & `clase2' ==1
											if _rc == 0 {
											local denominador = `r(sum)'
															
											sum `nivel' [w=round(factor_ci)]	 if `clase'==1 & formal_ci==1 & categopri_ci==3 & condocup_ci==1 & `clase2' ==1
											local numerador = `r(sum)'
											local valor = (`numerador' / `denominador') * 100												
											
											sum `nivel' if `clase'==1 & formal_ci==1 & condocup_ci==1 & `clase2' ==1
											local muestra = `r(sum)'
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
											
										} /*cierro indicador*/
										
										if "`indicador'" == "formalidad_4" {	
										
											cap sum ylab_ppp [w=round(factor_ci)]	 if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											if _rc == 0 {
											local valor = `r(mean)' 												
											
											sum ylab_ppp [w=round(factor_ci)]	 if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											local muestra = `r(N)'
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
											
										} /*cierro indicador*/
										
										if "`indicador'" == "ingreso_hor_prom" {	
															
											cap sum hwage_ppp [w=round(factor_ci)]	 if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											if _rc == 0 {
											cap local valor = `r(mean)'												
											
											sum hwage_ppp if `clase'==1 & `nivel'==1 & `clase2' ==1 & condocup_ci==1
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
										} /*cierro indicador*/
									} /*cierro niveles*/
								
										if "`indicador'" == "pensionista_65_mas" {	
										
											capture sum age_65_mas [w=round(factor_ci)] if `clase'==1 & `clase2' ==1
											if _rc == 0 {
											local denominador = `r(sum)'
															
											sum age_65_mas [w=round(factor_ci)]	 if `clase'==1 & pensiont_ci==1 & `clase2' ==1
											local numerador = `r(sum)'
											local valor = (`numerador' / `denominador') * 100												
											
											sum age_65_mas if `clase'==1 & pensiont_ci==1 & `clase2' ==1
											local muestra = `r(sum)'
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("age_65_mas") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
											
										} /*cierro indicador*/	
										
										if "`indicador'" == "num_pensionista_65_mas" {	
										
											cap sum age_65_mas [w=round(factor_ci)] if `clase'==1 & pensiont_ci==1 & `clase2' ==1
											if _rc == 0 {
											local valor = `r(sum)'

											sum age_65_mas if `clase'==1 & pensiont_ci==1 & `clase2' ==1
											local muestra = `r(sum)'

											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("age_65_mas") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
											
										} /*cierro indicador*/								
										
										if "`indicador'" == "pensionista_cont_65_mas" {	
										
											capture sum age_65_mas [w=round(factor_ci)] if `clase'==1 & `clase2' ==1
											if _rc == 0 {
											local denominador = `r(sum)'
															
											sum age_65_mas [w=round(factor_ci)]	 if `clase'==1 & pension_ci==1 & `clase2' ==1
											local numerador = `r(sum)'
											local valor = (`numerador' / `denominador') * 100												
											
											sum age_65_mas if `clase'==1 & pension_ci==1 & `clase2' ==1
											local muestra = `r(sum)'

											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("age_65_mas") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
											
										} /*cierro indicador*/	
									
										if "`indicador'" == "pensionista_nocont_65_mas" {	
										
											capture sum age_65_mas [w=round(factor_ci)] if `clase'==1 & `clase2' ==1
											if _rc == 0 {
											local denominador = `r(sum)'
															
											sum age_65_mas [w=round(factor_ci)]	 if `clase'==1 & pensionsub_ci==1 & `clase2' ==1
											local numerador = `r(sum)'
											local valor = (`numerador' / `denominador') * 100												
											
											sum age_65_mas if `clase'==1 & pensionsub_ci==1 & `clase2' ==1
											local muestra = `r(sum)'

											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("age_65_mas") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
										} /*cierro indicador*/	
										
										if "`indicador'" == "pensionista_ocup_65_mas" {	
										
											capture sum age_65_mas [w=round(factor_ci)] if `clase'==1 & `clase2' ==1
											if _rc == 0 {
											local denominador = `r(sum)'
															
											sum age_65_mas [w=round(factor_ci)]	 if `clase'==1 & condocup_ci==1 & (pension_ci==1 | pensionsub_ci==1) & `clase2' ==1
											local numerador = `r(sum)'
											local valor = (`numerador' / `denominador') * 100												
											
											sum age_65_mas if `clase'==1 & condocup_ci==1 & (pension_ci==1 | pensionsub_ci==1) & `clase2' ==1
											local muestra = `r(sum)'
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("age_65_mas") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
											
										} /*cierro indicador*/	
																							
										if "`indicador'" == "y_pen_cont_ppp" {	
										
											capture sum age_65_mas [w=round(factor_ci)] if `clase'==1 & ypen_ppp!=. & `clase2' ==1
											if _rc == 0 {
											local denominador = `r(sum)'
															
											sum ypen_ppp [w=round(factor_ci)]	 if `clase'==1 & age_65_mas==1 & `clase2' ==1
											local numerador = `r(sum)'
											local valor = (`numerador' / `denominador') 											
											
											capture sum age_65_mas if `clase'==1 & ypen_ppp!=. & `clase2' ==1
											local denominador = `r(sum)'
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("age_65_mas") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
										} /*cierro indicador*/
										
										if "`indicador'" == "y_pen_cont" {	
										
											capture sum ypen_ci [w=round(factor_ci)] if `clase'==1 & ypen_ci!=. & `clase2' ==1 & age_65_mas==1
											if _rc == 0 {
											cap local valor = `r(mean)'											
											
											sum ypen_ci if `clase'==1 & ypen_ci!=. & `clase2' ==1 & age_65_mas==1
											cap local muestra = `r(N)'
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("age_65_mas") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
											
										} /*cierro indicador*/	
										
										if "`indicador'" == "y_pen_nocont" {	
										
											capture sum ypensub_ci [w=round(factor_ci)] if `clase'==1 & ypensub_ci!=. & `clase2' ==1 & age_65_mas==1
											if _rc == 0 {
											cap local valor = `r(mean)'											
											
											sum ypensub_ci if `clase'==1 & ypensub_ci!=. & `clase2' ==1 & age_65_mas==1
											local muestra = `r(N)'
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("age_65_mas") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
											
										} /*cierro indicador*/	
									
										if "`indicador'" == "y_pen_total" {	
										
											capture sum ypent_ci [w=round(factor_ci)] if `clase'==1 & ypent_ci!=. & `clase2' ==1 & age_65_mas==1
											if _rc == 0 {
											cap local valor = `r(mean)'											
											
											sum ypent_ci if `clase'==1 & ypent_ci!=. & `clase2' ==1 & age_65_mas==1
											local muestra = `r(N)'
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("age_65_mas") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
											
										} /*cierro indicador*/	

								}/*cierro clase2*/
							} /* cierro clase*/ 
					} /*cierro laboral*/
					
								if "`tema'" == "pobreza" 	{
					
									local niveles Total age_00_04 age_05_14 age_15_24 age_25_64 age_65_mas
									local clases  Total Hombre Mujer Rural Urbano
									local clases2 Total Hombre Mujer 
							
									foreach clase of local clases{
										foreach clase2 of local clases2 {
											foreach nivel of local niveles {
												
										/* Porcentaje poblacion que vive con menos de 3.1 USD diarios per capita*/
										if "`indicador'" == "pobreza31" {																						 
							  
											capture sum `nivel' [w=round(factor_ci)] if `clase'==1 & `clase2' ==1
											if _rc == 0 {
											local denominador = `r(sum)'
															
											sum `nivel' [w=round(factor_ci)]	 if `clase'==1 & poor31==1 & `clase2' ==1
											local numerador = `r(sum)'
											local valor = (`numerador' / `denominador') * 100 
											
											capture sum `nivel' if `clase'==1 & `clase2' ==1
											local muestra = `r(sum)'
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}				
										} /*cierro indicador*/		
										
										/* Porcentaje poblacion que vive con menos de 5 USD diarios per capita*/
										if "`indicador'" == "pobreza" {																						 
							  
											capture sum `nivel' [w=round(factor_ci)] if `clase'==1  & `clase2' ==1
											if _rc == 0 {
											local denominador = `r(sum)'
															
											sum `nivel' [w=round(factor_ci)]	 if `clase'==1 & poor==1 & `clase2' ==1
											local numerador = `r(sum)'
											local valor = (`numerador' / `denominador') * 100 
											
											capture sum `nivel' if `clase'==1  & `clase2' ==1
											local muestra = `r(sum)'
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}				
										} /*cierro indicador*/
										
										/* Porcentaje de la población con ingresos entre 5 y 12.4 USD diarios per capita*/
										if "`indicador'" == "vulnerable" {																						 
							  
											capture sum `nivel' [w=round(factor_ci)] if `clase'==1 & `clase2' ==1
											if _rc == 0 {
											local denominador = `r(sum)'
															
											sum `nivel' [w=round(factor_ci)]	 if `clase'==1 & vulnerable==1 & `clase2' ==1
											local numerador = `r(sum)'
											local valor = (`numerador' / `denominador') * 100 
											
											capture sum `nivel'  if `clase'==1 & `clase2' ==1
											local muestra = `r(sum)'
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}				
										} /*cierro indicador*/	
										
										/* Porcentaje de la población con ingresos entre 12.4 y 64 USD diarios per capita*/
										if "`indicador'" == "middle" {																						 
							  
											capture sum `nivel' [w=round(factor_ci)] if `clase'==1 & `clase2' ==1
											if _rc == 0 {
											local denominador = `r(sum)'
															
											sum `nivel' [w=round(factor_ci)]	 if `clase'==1 & middle==1 & `clase2' ==1
											local numerador = `r(sum)'
											local valor = (`numerador' / `denominador') * 100 
											
											capture sum `nivel' if `clase'==1 & `clase2' ==1
											local muestra = `r(sum)'
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}				
										} /*cierro indicador*/	
										
										/* Porcentaje de la población con ingresos mayores 64 USD diarios per capita*/
										
										if "`indicador'" == "rich" {																						 
							  
											capture sum `nivel' [w=round(factor_ci)] if `clase'==1 & `clase2' ==1
											if _rc == 0 {
											local denominador = `r(sum)'
															
											sum `nivel' [w=round(factor_ci)]	 if `clase'==1 & rich==1 & `clase2' ==1
											local numerador = `r(sum)'
											local valor = (`numerador' / `denominador') * 100 
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}				
										} /*cierro indicador*/	
											} /*cierro nivel*/	
										}/*cierro clases2*/
									} /*cierro clase*/
						
										local clases Total Urbano Rural
						
									foreach clase of local clases {
							
										/* Coeficiente de Gini para el ingreso per cápita del hogar*/			
										if "`indicador'" == "ginihh" {
										
											cap inequal7 pc_ytot_ch [w=round(factor_ci)] if `clase'==1 & pc_ytot_ch !=. & pc_ytot_ch>0 & (edad_ci>=15 & edad_ci<=64) & factor_ci!=. & jefe_ci==1
											if _rc == 0 {
											local valor =`r(gini)'
											
											cap inequal7 pc_ytot_ch if `clase'==1 & pc_ytot_ch !=. & pc_ytot_ch>0 & (edad_ci>=15 & edad_ci<=64) & factor_ci!=. & jefe_ci==1
											local muestra = `r(gini)'
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("no_aplica") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
											
										} /*cierro indicador*/
										
										/* Coeficiente de Gini para salarios por hora*/
										if "`indicador'" == "gini" {
										
											cap inequal7 ylmprixh [w=round(factor_ci)] if `clase'==1 & ylmprixh!=. & ylmprixh>0 & (edad_ci>=15 & edad_ci<=64) & factor_ci!=. 
											if _rc == 0 {
											local valor =`r(gini)'
											
											cap inequal7 ylmprixh if `clase'==1 & ylmprixh!=. & ylmprixh>0 & (edad_ci>=15 & edad_ci<=64) & factor_ci!=. 
											local muestra = `r(gini)'
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("no_aplica") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
											
										} /*cierro indicador*/
										
										  /* Coeficiente de theil para el ingreso per cápita del hogar*/
										if "`indicador'" == "theilhh" {
										
											cap inequal7 pc_ytot_ch [w=round(factor_ci)] if `clase'==1 & pc_ytot_ch !=. & pc_ytot_ch>0 & (edad_ci>=15 & edad_ci<=64) & factor_ci!=. & jefe_ci==1
											if _rc == 0 {
											local valor =`r(theil)'
											
											cap inequal7 pc_ytot_ch if `clase'==1 & pc_ytot_ch !=. & pc_ytot_ch>0 & (edad_ci>=15 & edad_ci<=64) & factor_ci!=. & jefe_ci==1				
											local muestra = `r(theil)'
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("no_aplica") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
										} /*cierro indicador*/
										
										/* Coeficiente de theil para salarios por hora*/
										if "`indicador'" == "theil" {
										
											cap inequal7 ylmprixh [w=round(factor_ci)] if `clase'==1 & ylmprixh!=. & ylmprixh>0 & (edad_ci>=15 & edad_ci<=64) & factor_ci!=. 
											if _rc == 0 {
											local valor =`r(theil)'
											
											cap inequal7 ylmprixh if `clase'==1 & ylmprixh!=. & ylmprixh>0 & (edad_ci>=15 & edad_ci<=64) & factor_ci!=. 
											local muestra = `r(theil)'
											
											post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("no_aplica") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
											}
										} /*cierro indicador*/
										
										/* Porcentaje del ingreso laboral del hogar contribuido por las mujeres */
										if "`indicador'" == "ylmfem_ch" {
				
														capture sum hhylmpri [w=round(factor_ci)]	if jefe_ci ==1 & sexo_ci!=. & `clase'==1
														if _rc == 0 {
														local num_hog = `r(sum)'
														
														sum  hhyLwomen [w=round(factor_ci)] if jefe_ci ==1 & `clase'==1 
														local numerador = `r(sum)'
														local valor = (`numerador' / `num_hog') * 100 
														
														sum hhyLwomen [w=round(factor_ci)] if jefe_ci ==1 & `clase'==1 
														local muestra = `r(sum)'
														
														post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("no_aplica") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
														}
										} /* cierro indicador*/
										} /*cierro clase*/	
											
										local clases Total quintil_1 quintil_2 quintil_3 quintil_4 quintil_5 Rural Urbano
						
									foreach clase of local clases {	
											
									  /* Porcentaje de hogares que reciben remesas del exterior */
										if "`indicador'" == "indexrem" {
				
														capture sum Total [w=round(factor_ci)]	if jefe_ci ==1 & sexo_ci!=. & `clase'==1
														if _rc == 0 {
														local num_hog = `r(sum)'
														
														sum  Total  [w=round(factor_ci)] if jefe_ci ==1 & indexrem==1 & `clase'==1 
														local numerador = `r(sum)'
														local valor = (`numerador' / `num_hog') * 100 
														
														sum Total [w=round(factor_ci)] if jefe_ci ==1 & indexrem==1 & `clase'==1 
														local muestra = `r(sum)'
														
														post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("no_aplica") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
														}
										} /* cierro indicador*/
										} /*cierro clase*/						
						
					} /*cierro pobreza*/
					
								if "`tema'" == "vivienda" 	{
								
									local clases Total quintil_1 quintil_2 quintil_3 quintil_4 quintil_5 Rural Urbano
									local clases2 Total Rural Urbano
								
									foreach clase of local clases{
										foreach clase2 of local clases2 {
						
										/* % de hogares con servicio de agua de acueducto*/
										if "`indicador'" == "aguared_ch" {
				
														capture sum Total [w=round(factor_ci)]	if jefe_ci ==1 & `clase'==1 & aguared_ch!=. & `clase2'==1
														if _rc == 0 {
														local num_hog = `r(sum)'
														
														sum Total [w=round(factor_ci)]	 if jefe_ci==1 & `clase'==1 & aguared_ch==1 & `clase2' ==1
														local numerador = `r(sum)'
														local valor = (`numerador' / `num_hog') * 100 
														
														sum Total if jefe_ci==1 & `clase'==1 & aguared_ch==1 & `clase2' ==1
														local muestra = `r(sum)'

														post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
														}
														
										} /* cierro indicador*/	
										
										/* % de hogares con acceso a servicios de saneamiento mejorados*/
										if "`indicador'" == "des2_ch" {
				
														capture sum Total [w=round(factor_ci)]	if jefe_ci ==1 & `clase'==1  & des2_ch!=. & `clase2' ==1
														if _rc == 0 {
														local num_hog = `r(sum)'
														
														sum Total [w=round(factor_ci)]	 if jefe_ci==1 & des2_ch==1 & `clase'==1 & `clase2' ==1
														local numerador = `r(sum)'
														local valor = (`numerador' / `num_hog') * 100 
														
														sum Total if jefe_ci==1 & des2_ch==1 & `clase'==1 & `clase2' ==1
														local muestra = `r(sum)'

														post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
														}
														
										} /* cierro indicador*/	
										
										/* % de hogares con electricidad */
										if "`indicador'" == "luz_ch" {
				
														capture sum Total [w=round(factor_ci)]	if jefe_ci ==1 & `clase'==1 & luz_ch!=. & `clase2' ==1
														if _rc == 0 {
														local num_hog = `r(sum)'
														
														sum Total [w=round(factor_ci)]	 if jefe_ci==1 & `clase'==1 & luz_ch==1 & `clase2' ==1
														local numerador = `r(sum)'
														local valor = (`numerador' / `num_hog') * 100 
														
														sum Total if jefe_ci==1 & `clase'==1 & luz_ch==1 & `clase2' ==1
														local muestra = `r(sum)'

														post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
														}
														
										} /* cierro indicador*/	
										
										/* % hogares con pisos de tierra */
										if "`indicador'" == "dirtf_ch" {
				
														capture sum Total [w=round(factor_ci)]	if jefe_ci ==1 & `clase'==1 & dirtf_ch!=. & `clase2' ==1
														if _rc == 0 {
														local num_hog = `r(sum)'
														
														sum Total [w=round(factor_ci)]	 if jefe_ci==1 & `clase'==1 & dirtf_ch==1 & `clase2' ==1
														local numerador = `r(sum)'
														local valor = (`numerador' / `num_hog') * 100 
														
														sum Total if jefe_ci==1 & `clase'==1 & dirtf_ch==1 & `clase2' ==1
														local muestra = `r(sum)'
														post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
														}
														
										} /* cierro indicador*/
										
										/* % de hogares con refrigerador */
										if "`indicador'" == "refrig_ch" {
				
														capture sum Total [w=round(factor_ci)]	if jefe_ci ==1 & `clase'==1 & refrig_ch!=. & `clase2' ==1
														if _rc == 0 {
														local num_hog = `r(sum)'
														
														sum Total [w=round(factor_ci)]	 if jefe_ci==1 & `clase'==1 & refrig_ch==1 & `clase2' ==1
														local numerador = `r(sum)'
														local valor = (`numerador' / `num_hog') * 100 
														
														sum Total if jefe_ci==1 & `clase'==1 & refrig_ch==1 & `clase2' ==1
														local muestra = `r(sum)'
														
														post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
														}
														
										} /* cierro indicador*/
										
										/* % de hogares con carro particular */
										if "`indicador'" == "auto_ch" {
				
														capture sum Total [w=round(factor_ci)]	if jefe_ci ==1 & `clase'==1 & auto_ch!=. & `clase2' ==1
														if _rc == 0 {
														local num_hog = `r(sum)'
														
														sum Total [w=round(factor_ci)]	 if jefe_ci==1 & `clase'==1 & auto_ch==1 & `clase2' ==1
														local numerador = `r(sum)'
														local valor = (`numerador' / `num_hog') * 100 
														
														sum Total if jefe_ci==1 & `clase'==1 & auto_ch==1 & `clase2' ==1
														local muestra = `r(sum)'
														
														post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
														}
														
										} /* cierro indicador*/
										
										/* % de hogares con acceso a internet */
										if "`indicador'" == "internet_ch" {
				
														capture sum Total [w=round(factor_ci)]	if jefe_ci ==1 & `clase'==1 & internet_ch!=. & `clase2' ==1
														if _rc == 0 {
														local num_hog = `r(sum)'
														
														sum Total [w=round(factor_ci)]	 if jefe_ci==1 & `clase'==1 & internet_ch==1 & `clase2' ==1
														local numerador = `r(sum)'
														local valor = (`numerador' / `num_hog') * 100 
														
														sum Total if jefe_ci==1 & `clase'==1 & internet_ch==1 & `clase2' ==1
														local muestra = `r(sum)'
														
														post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
														}
														
										} /* cierro indicador*/
										
										/* % de hogares con teléfono celular*/
										if "`indicador'" == "cel_ch" {
				
														capture sum Total [w=round(factor_ci)]	if jefe_ci ==1 & `clase'==1 & cel_ch!=. & `clase2' ==1
														if _rc == 0 {
														local num_hog = `r(sum)'
														
														sum Total [w=round(factor_ci)]	 if jefe_ci==1 & `clase'==1 & cel_ch==1 & `clase2' ==1
														local numerador = `r(sum)'
														local valor = (`numerador' / `num_hog') * 100 
														
														sum Total if jefe_ci==1 & `clase'==1 & cel_ch==1 & `clase2' ==1
														local muestra = `r(sum)'
														
														post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
														}
														
										} /* cierro indicador*/
										/* % de hogares con techos de materiales no permanentes*/
										if "`indicador'" == "techonp_ch" {
				
														capture sum Total [w=round(factor_ci)]	if jefe_ci ==1 & `clase'==1 & techonp_ch!=. & `clase2' ==1
														if _rc == 0 {
														local num_hog = `r(sum)'
														
														sum Total [w=round(factor_ci)]	 if jefe_ci==1 & `clase'==1 & techonp_ch==1 & `clase2' ==1
														local numerador = `r(sum)'
														local valor = (`numerador' / `num_hog') * 100 
														
														sum Total if jefe_ci==1 & `clase'==1 & techonp_ch==1 & `clase2' ==1
														local muestra = `r(sum)'
														
														post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
														}
														
										} /* cierro indicador*/
										
										/* % de hogares con paredes de materiales no permanentes*/
										if "`indicador'" == "parednp_ch" {
				
														capture sum Total [w=round(factor_ci)]	if jefe_ci ==1 & `clase'==1 & parednp_ch!=. & `clase2' ==1
														if _rc == 0 {
														local num_hog = `r(sum)'
														
														sum Total [w=round(factor_ci)]	 if jefe_ci==1 & `clase'==1 & parednp_ch==1 & `clase2' ==1
														local numerador = `r(sum)'
														local valor = (`numerador' / `num_hog') * 100 
														
														sum Total if jefe_ci==1 & `clase'==1 & parednp_ch==1 & `clase2' ==1
														local muestra = `r(sum)'
														
														post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
														}
														
										} /* cierro indicador*/
										
										/* Número de miembros por cuarto*/
										if "`indicador'" == "hacinamiento_ch" {
				
														capture sum Total [w=round(factor_ci)]	if jefe_ci ==1 & `clase'==1  & `clase2' ==1
														if _rc == 0 {
														local num_hog = `r(sum)'
														
														sum Total [w=round(factor_ci)]	 if jefe_ci==1 & `clase'==1  & `clase2' ==1
														local numerador = `r(sum)'
														local valor = (`numerador' / `num_hog') * 100 
														
														sum Total if jefe_ci==1 & `clase'==1  & `clase2' ==1
														local muestra = `r(sum)'
														
														post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
														}
														
										} /* cierro indicador*/
										
										/*% de hogares con estatus residencial estable */
										if "`indicador'" == "estable_ch" {
				
														capture sum Total [w=round(factor_ci)]	if jefe_ci ==1 & `clase'==1 & estable_ch!=. & `clase2' ==1
														if _rc == 0 {
														local num_hog = `r(sum)'
														
														sum Total [w=round(factor_ci)]	 if jefe_ci==1 & `clase'==1 & estable_ch==1 & `clase2' ==1
														local numerador = `r(sum)'
														local valor = (`numerador' / `num_hog') * 100 
														
														sum Total if jefe_ci==1 & `clase'==1 & estable_ch==1 & `clase2' ==1
														local muestra = `r(sum)'
														
														post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")

														}
														
										} /* cierro indicador*/
										}/*cierro clase2*/		
									} /*cierro clase*/
								} /*cierro vivienda*/
																									
								if "`tema'"	== "inclusion" {
										
										/* [inserte nombre extrendidpo del indicador] */
										if "`indicador'" == "[inserte nombre corto indicador]" {
				
														capture sum Total [w=round(factor_ci)]	 if `clase'==1 & `clase2' ==1
														if _rc == 0 {
														local denominador = `r(sum)'
														
														sum Total [w=round(factor_ci)]	 if raza==1 & `clase'==1 & `clase2' ==1
														local numerador = `r(sum)'
														local valor = (`numerador' / `denominador') * 100 
														
														sum Total if raza==1 & `clase'==1 & `clase2' ==1
														local muestra = `r(sum)'
														
														post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") ("`valor'") ("`muestra'")
														}
											} /* cierro indicador*/
								} /*cierro inclusion */
																					
								if "`tema'"	== "migracion" {
							
							/* [inserte nombre del indicador extendido] 
							
							if "`indicador'" == "[inserte nombre indicador corto]" {

							} /* cierro indicador*/
							
							*/ 
		} /*cierro migracion */
		
						}  /*cierro indicadores*/
					}/*Cierro temas*/
	
	

	
					}/*Cierro if _rc*/ 
							
					if _rc != 0  { /* Si esta base de datos no existe, entonces haga: */

						foreach tema of local temas {
											
							if "`tema'" == "demografia" local indicadores jefa_ch jefaecon_ch pobfem_ci union_ci miembro6_ch miembro6y16_ch miembro65_ch unip_ch nucl_ch ampl_ch comp_ch corres_ch  pob18_ci pob65_ci urbano_ci pobedad_ci 
							if "`tema'" == "pobreza"    local indicadores pobreza31 pobreza vulnerable middle rich ginihh gini theilhh theil indexrem ylmfem_ch
							if "`tema'" == "educacion"  local indicadores tasa_bruta_asis tasa_neta_asis tasa_asis_edad tasa_no_asis_edad Años_Escolaridad_25_mas Ninis_2 leavers tasa_terminacion_c tasa_sobre_edad
							if "`tema'" == "vivienda"   local indicadores aguared_ch des2_ch luz_ch dirtf_ch refrig_ch auto_ch internet_ch cel_ch parednp_ch techonp_ch hacinamiento_ch estable_ch
							if "`tema'" == "laboral"    local indicadores tasa_ocupacion tasa_desocupacion tasa_participacion ocup_suf_salario ingreso_mens_prom ingreso_hor_prom formalidad_2 pensionista_65_mas y_pen_cont_ppp 
							if "`tema'" == "inclusion"  local indicadores 
							if "`tema'" == "migracion"  local indicadores 
							
							foreach indicador of local indicadores {
									noi di in y "Calculating numbers for country: `pais' - year : `ano' - tema: `tema' - indicator: `indicador'"
									

									if "`tema'"	== "demografia"  {
									
										local clases Total quintil_1 quintil_2 quintil_3 quintil_4 quintil_5 Rural Urbano
			                              local clases2 Total Rural Urbano
										  
										  if "`indicador'" == "urbano_ci" 
					                   local clases Total quintil_1 quintil_2 quintil_3 quintil_4 quintil_5 
										  
									foreach clase of local clases{
					                foreach clase2 of local clases2 { 
										  
		
					
										post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") (".") (".")
										
									
											} /*cierro clases2*/
										} /*cierro clases*/

									} /*cierro demografia*/
										
									if "`tema'" == "educacion" {
										
										local clases  Total Hombre Mujer quintil_1 quintil_2 quintil_3 quintil_4 quintil_5 Rural Urbano
										local clases2 Total Hombre Mujer Rural Urbano
										
										foreach clase of local clases {
											foreach clase2 of local clases2 {
											
												if "`indicador'" == "tasa_neta_asis_c" | "`indicador'" == "tasa_bruta_asis_c"	local niveles Primaria Secundaria Superior
												if "`indicador'" == "tasa_neta_asis" | "`indicador'" == "tasa_bruta_asis"	 	local niveles Prescolar Primaria Secundaria Superior 
												if "`indicador'" == "tasa_asis_edad" | "`indicador'" == "tasa_no_asis_edad"		local niveles age_4_5 age_6_11 age_12_14 age_15_17 age_18_23  
												if "`indicador'" == "Años_Escolaridad_25_mas" 									local niveles anos_0 anos_1_5 anos_6 anos_7_11 anos_12 anos_13_o_mas 
												if "`indicador'" == "Ninis_1" | "`indicador'" == "Ninis_2"						local niveles age_15_24 age_15_29 
												if "`indicador'" == "tasa_terminacion" | "`indicador'" == "tasa_terminacion_c"	local niveles Primaria Secundaria 
												if "`indicador'" == "tasa_sobre_edad"											local niveles Primaria
												if "`indicador'" == "leavers" 													local niveles Total 
									  
												foreach nivel of local niveles {
													post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") (".") (".")
												} /* cierro niveles*/
											} /*cierro clases2*/
										} /*cierro clases*/
									} /*cierro educacion*/
									
									if "`tema'" == "laboral" {
									
										 local niveles Total age_15_24 age_15_29 age_15_64 age_25_64 age_65_mas 
										 local clases Total Hombre Mujer quintil_1 quintil_2 quintil_3 quintil_4 quintil_5 Rural Urbano
										 local clases2 Total Hombre Mujer Rural Urbano
										 
										foreach clase of local clases {
											foreach clase2 of local clases2 {
												
												if "`indicador'" == "pensionista_65_mas" | "`indicador'" == "y_pen_cont_ppp"	local niveles age_65_mas
									  
												foreach nivel of local niveles {
													post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") (".") (".")
												} /* cierro niveles*/
											} /*cierro clases2*/
										} /*cierro clases*/
									} /*cierro laboral*/
									
									if "`tema'" == "pobreza" {	
										
										local niveles Total age_00_04 age_05_14 age_15_24 age_25_64 age_65_mas
										local clases  Total Hombre Mujer Rural Urbano
										local clases2 Total Hombre Mujer
										
										if "`indicador'" == "ginihh" | "`indicador'" == "gini" | "`indicador'" == "theilhh" |"`indicador'" == "theil" |"`indicador'" == "ylmfem_ch" | "`indicador'" == "indexrem" local niveles no_aplica
										if "`indicador'" == "ginihh" | "`indicador'" == "gini" | "`indicador'" == "theilhh" |"`indicador'" == "theil" |"`indicador'" == "ylmfem_ch" | "`indicador'" == "indexrem"   local clases2 no_aplica
										if "`indicador'" == "ginihh" | "`indicador'" == "gini" | "`indicador'" == "theilhh" |"`indicador'" == "theil" |"`indicador'" == "ylmfem_ch" local clases Total Rural Urbano
										if "`indicador'" == "indexrem" local clases Total quintil_1 quintil_2 quintil_3 quintil_4 quintil_5 Rural Urbano
										
										foreach clase of local clases {	
											foreach clase2 of local clases2 {	
												foreach nivel of local niveles {
													post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("`nivel'") ("`tema'") ("`indicador'") (".") (".")
												} /* cierro niveles*/
											} /*cierro clases2*/
										} /*cierro clases*/
									} /*cierro pobreza*/
									
									if "`tema'" == "vivienda" 	{
		
										local clases Total quintil_1 quintil_2 quintil_3 quintil_4 quintil_5 Rural Urbano
										local clases2 Rural Urbano
										
										foreach clase of local clases {									  
											foreach clase2 of local clases2 {	
												
													post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") (".") (".")
													
											} /*cierro clases2*/
										} /*cierro clases*/
									} /*cierro vivienda*/
																		
									if "`tema'" == "inclusion" {
									
										local clases Total quintil_1 quintil_2 quintil_3 quintil_4 quintil_5 Rural Urbano
										local clases2 Total
									
										foreach clase of local clases {									  
											foreach clase2 of local clases2 {	
												
												post `ptablas' ("`ano'") ("`pais'") ("`geografia_id'") ("`clase'") ("`clase2'") ("no_aplica") ("`tema'") ("`indicador'") (".") (".")
											
									
											} /*cierro clases2*/
										} /*cierro clases*/
									} /*cierro inclusion*/
																			
							} /*cierro indicadores*/
						} /* cierro temas */
					
					}/*cierro if _rc*/

				
				
						
					} /* cierro rondas */		
				} /* cierro encuestas */
			} /* cierro anos */
		} /* cierro paises */
	} /* cierro quietly */
 

postclose `ptablas'
use `tablas', clear
destring valor muestra, replace
recode valor 0=.
recode muestra 0=.
save `tablas', replace 



/*====================================================================
                        2: Save and Export results
====================================================================*/



* guardo el archivo temporal
save "${input}\Indicadores_SCL.dta", replace

* Variables de formato 

include "${input}\var_formato.do"
order tiempo tiempo_id pais_id geografia_id clase clase_id clase2 clase2_id nivel nivel_id tema indicador tipo valor muestra


/*
export excel using "${output}\Indicadores_SCL.xlsx", first(var) sheet(Total_results) sheetreplace
export delimited using  "${output}\indicadores_encuestas_hogares_scl.csv", replace

unicode convertfile "${output}\indicadores_encuestas_hogares_scl.csv" "${output}\indicadores_encuestas_hogares_scl_converted.csv", dstencoding(latin1) replace */

*carpeta tmp

export delimited using  "${covidtmp}\indicadores_encuestas_hogares_scl.csv", replace
unicode convertfile "${covidtmp}\indicadores_encuestas_hogares_scl.csv" "${output}\indicadores_encuestas_hogares_scl_converted.csv", dstencoding(latin1) replace 
save "${covidtmp}\indicadores_encuestas_hogares_scl.dta", replace


/*


	g 		division = "soc" if tema == "demografia" | tema == "vivienda" | tema == "pobreza" 
	replace division = "lmk" if tema == "laboral" 													 
	replace division = "edu" if tema == "educacion" 
	replace division = "gdi" if tema == "inclusion"
	replace division = "mig" if tema == "migracion"

local divisiones soc lmk edu gdi mig											 

foreach div of local divisiones { 
	        
			preserve
			
			keep if (division == "`div'")
			drop division
		
			export delimited using "${output}\\indicadores_encuestas_hogares_`div'.csv", replace
			sleep 1000
			restore
						
} 
 */
 
 		
exit
/* End of do-file */



