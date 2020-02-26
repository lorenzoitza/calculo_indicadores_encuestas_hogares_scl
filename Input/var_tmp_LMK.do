
/*============================================================================
project:       Edades niveles de desagregación indicadores de mercado laboral
Author:        Angela Lopez 
Dependencies:  SCL/EDU/LMK - IDB 
------------------------------------------------------------------------------
Creation Date:    20 Febrero 2020 - 11:38:53
Modification Date:   
Do-file version:    01
References:          
Output:             Excel-DTA file
===============================================================================*/

/*=================================================================================
                        Program description: para incluir en el programa maestro  
===================================================================================*/

*1 Edades niveles de desagregación indicadores de mercado laboral

	*1.1 Poblacion en Edad de Trabajar - PET y economicamente activa PEA:
				cap gen pet=1 if condocup_ci==1 | condocup_ci==2 | condocup_ci==3
				cap gen pea=1 if condocup_ci==1 | condocup_ci==2 

	*1.2. Diferentes análisis de la PET:			
				gen age_15_64  = inrange(edad_ci,15,64) 
				gen age_25_64  = inrange(edad_ci,25,64) 
				gen age_65_mas = inrange(edad_ci,18,24) 
				
*2 ppp por país:
	
		*PPP 2011
				g 		ppp=1							// cambié la variable inicial que comenzaba con el valor de ARG
				replace	ppp=2.768382  if pais_c=="ARG"
				replace ppp=1.150889  if pais_c=="BHS"
				replace ppp=1.182611  if pais_c=="BLZ"
				replace ppp=2.906106  if pais_c=="BOL"
				replace ppp=1.658783  if pais_c=="BRA"
				replace ppp=2.412881  if pais_c=="BRB"
				replace ppp=370.1987  if pais_c=="CHL"
				replace ppp=1196.955  if pais_c=="COL"
				replace ppp=343.7857  if pais_c=="CRI"
				replace ppp=20.74103  if pais_c=="DOM"
				replace ppp=0.5472345 if pais_c=="ECU"
				replace ppp=3.873239  if pais_c=="GTM"
				replace ppp=10.08031  if pais_c=="HND"
				replace ppp=8.940212  if pais_c=="MEX"
				replace ppp=9.160075  if pais_c=="NIC"
				replace ppp=0.553408  if pais_c=="PAN"
				replace ppp=1.568639  if pais_c=="PER"
				replace ppp=2309.43   if pais_c=="PRY"
				replace ppp=0.5307735 if pais_c=="SLV"
				replace ppp=16.42385  if pais_c=="URY"
				replace ppp=2.915005  if pais_c=="VEN"
				replace ppp=63.35445  if pais_c=="JAM"
				replace ppp=4.619226  if pais_c=="TTO"

* 3 Variables de ingresos

	* 3.1 Población ocupada por encima del umbral del salario horario suficiente (1.95 US ppp)

				gen 	ylmpri_ppp = ylmpri_ci/ppp/ipc_c

				gen 	hsal_ci    = ylmpri_ppp/(horaspri_ci*4.3) if condocup_ci==1  
				gen 	liv_wage   = (hsal_ci>1.95) 
				replace liv_wage   =. if hsal==.			

	* 3.2 Ingreso laboral monetario
	
				gen       ylab_ci=ylm_ci if emp_ci==1
				label var ylab_ci "ingreso laboral monetario total"

				gen 	  ylab_ppp=ylab_ci/ppp/ipc_c
				label var ylab_ppp "Ingreso laboral monetario total a US$PPP(2011)"
				
	* 3.3 Ingreso horario en la actividad principal USD
	
				gen 	hwage_ci=ylmpri_ci/(horaspri_ci*4.3) if condocup_ci==1
				gen 	hwage_ppp=hwage_ci/ppp/ipc_c
				
	* 3.4 Ingreso por pensión contributiva 
	
				gen  	 ypen_ppp=ypen_ci/ppp/ipc_c
				
* 4 Formalidad laboral 
				gen 	formal_aux=1 if cotizando_ci==1
				replace formal_aux=1 if afiliado_ci==1 & (cotizando_ci!=1 | cotizando_ci!=0) & condocup_ci==1 & pais_c=="URY" & anio_c<=2000
				replace formal_aux=1 if afiliado_ci==1 & (cotizando_ci!=1 | cotizando_ci!=0) & condocup_ci==1 & pais_c=="BOL"   /* si se usa afiliado, se restringiendo a ocupados solamente*/
				replace formal_aux=1 if afiliado_ci==1 & (cotizando_ci!=1 | cotizando_ci!=0) & condocup_ci==1 & pais_c=="CRI" & anio_c<2000
				replace formal_aux=1 if afiliado_ci==1 & (cotizando_ci!=1 | cotizando_ci!=0) & condocup_ci==1 & pais_c=="GTM" & anio_c>1998
				replace formal_aux=1 if afiliado_ci==1 & (cotizando_ci!=1 | cotizando_ci!=0) & condocup_ci==1 & pais_c=="PAN"
				replace formal_aux=1 if afiliado_ci==1 & (cotizando_ci!=1 | cotizando_ci!=0) & condocup_ci==1 & pais_c=="PRY" & anio_c<=2006
				replace formal_aux=1 if afiliado_ci==1 & (cotizando_ci!=1 | cotizando_ci!=0) & condocup_ci==1 & pais_c=="DOM"
				replace formal_aux=1 if afiliado_ci==1 & (cotizando_ci!=1 | cotizando_ci!=0) & condocup_ci==1 & pais_c=="MEX" & anio_c>=2008
				replace formal_aux=1 if afiliado_ci==1 & (cotizando_ci!=1 | cotizando_ci!=0) & condocup_ci==1 & pais_c=="COL" & anio_c<=1999
				replace formal_aux=1 if afiliado_ci==1 & (cotizando_ci!=1 | cotizando_ci!=0) & condocup_ci==1 & pais_c=="ECU" 
				replace formal_aux=1 if afiliado_ci==1 & (cotizando_ci!=1 | cotizando_ci!=0) & condocup_ci==1 & pais_c=="BHS"

				drop formal_ci
				gen byte formal_ci=1 if formal_aux==1 & (condocup_ci==1 | condocup_ci==2)
				recode formal_ci .=0 if (condocup_ci==1 | condocup_ci==2)
				label var formal_ci "1=afiliado o cotizante / PEA"
				
* 5 Pensionistas 
				gen pensiont_ci=1 if pension_ci==1 | pensionsub_ci==1
				egen aux_pensiont_ci=mean(pensiont_ci)  /*indica q no hay dato ese año*/
				recode pensiont_ci .=0 if edad_ci>=65
				
				



				
				
				
				
				
				
				