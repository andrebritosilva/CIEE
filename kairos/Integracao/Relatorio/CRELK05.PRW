#Include 'Protheus.ch'
#Include 'Topconn.ch'
//---------------------------------------------------------------------------------------
/*/{Protheus.doc} CRELK05
Relatorio de Controle de Creditos Nao Identificados Sintetico Mes a Mes
@author  	Totvs
@since     	01/01/2015
@version  	P.11.8      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------
User Function CRELK05()
Private cDesc1 		:= "Este programa tem como objetivo imprimir relatorio "
Private cDesc2 		:= "sobre Controle de Creditos Nao Identificados"
Private cDesc3 		:= "de acordo com os parametros informados pelo usuario."
Private titulo 		:= "Controle de Creditos Nao Identificados"
Private nLin   		:= 80
Private Cabec1		:= ""
Private Cabec2		:= ""
Private imprime     := .T.
Private aOrd        := {}
Private lAbortPrint := .F.
Private limite      := 220
Private tamanho     := "G"
Private nomeprog    := StrTran(FunName(), "#", "")
Private nTipo       := 15
Private aReturn     := { "Zebrado", 1, "Administracao", 1, 2, 1, "", 1}
Private nLastKey    := 0
Private m_pag       := 01
Private wnrel       := "CFINR26"
Private cString     := "SZ5"
Private cPerg       := "CFINR26"
Private _cQuery		:= ""
Private _dDtINI		:= CTOD("")
Private _dDtFIM		:= CTOD("")


Pergunte(cPerg, .F.)

wnrel := SetPrint(cString,NomeProg,cPerg,@titulo,cDesc1,cDesc2,cDesc3,.F.,aOrd,.T.,Tamanho,,.F.)

If nLastKey == 27
	Return
Endif

SetDefault(aReturn,cString)

If nLastKey == 27
	Return
Endif

nTipo := If(aReturn[4]==1,15,18)

Do Case
	Case cEmpant $ '01/02'
		Titulo := Alltrim(Titulo) + " CIEE / SP Pendentes ate "+Dtoc(mv_par03)
	Case cEmpant == '03'
		Titulo := Alltrim(Titulo) + " CIEE / RJ Pendentes ate "+Dtoc(mv_par03)
	Case cEmpant == '05'
		Titulo := Alltrim(Titulo) + " CIEE / NACIONAL Pendentes ate "+Dtoc(mv_par03)
EndCase	

RptStatus({|| CRK05RUN(Cabec1,Cabec2,Titulo,nLin) },Titulo)

Return
//---------------------------------------------------------------------------------------
/*/{Protheus.doc} CRK05RUN
Rotina de processamento do relatorio
@author  	Totvs
@since     	01/01/2015
@version  	P.11.8      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------
Static Function CRK05RUN(Cabec1,Cabec2,Titulo,nLin)

Local _aRel		:= {}
Local _nItem	:= 1
Local _nI		:= 0
Local _nY		:= 0

_nCol_01	:= 000
_nCol_02	:= 002
_nCol_03	:= 003
_nCol_04	:= 024
_nCol_05	:= 025
_nCol_06	:= 035
_nCol_07	:= 037
_nCol_08	:= 049	//050
_nCol_09	:= 051	//052
_nCol_10	:= 063	//065
_nCol_11	:= 065	//067
_nCol_12	:= 077	//080
_nCol_13	:= 079	//082
_nCol_14	:= 091	//095
_nCol_15	:= 093	//097
_nCol_16	:= 105	//110
_nCol_17	:= 107	//112
_nCol_18	:= 119	//125
_nCol_19	:= 121	//127
_nCol_20	:= 133	//140
_nCol_21	:= 135	//142
_nCol_22	:= 147	//155
_nCol_23	:= 149	//157
_nCol_24	:= 161	//170
_nCol_25	:= 163	//172
_nCol_26	:= 175	//185
_nCol_27	:= 177	//187
_nCol_28	:= 189	//200
_nCol_29	:= 191	//202
_nCol_30	:= 204	//215
_nCol_31	:= 206	//217
_nCol_32	:= 219	//230

DbSelectArea("SA6")
DbSetOrder(1)
DbGotop()

While !EOF()
	If SA6->A6_BLOCKED == "1"
		DbSelectArea("SA6")
		SA6->(DbSkip())
		Loop
	EndIf

	aadd(_aRel	,{	strzero(_nItem,02)										,;	//[01] Numero do Item
					alltrim(SA6->A6_NREDUZ)+" - "+alltrim(SA6->A6_XCIDADE)	,;	//[02] Banco e Cidade
					SA6->A6_NUMCON											,;	//[03] Numero da Conta
					0														,;	//[04] 1 Mes
					0														,;	//[05] 2 Mes
					0														,;	//[06] 3 Mes
					0														,;	//[07] 4 Mes
					0														,;	//[08] 5 Mes
					0														,;	//[09] 6 Mes
					0														,;	//[10] 7 Mes
					0														,;	//[11] 8 Mes
					0														,;	//[12] 9 Mes
					0														,;	//[13]10 Mes
					0														,;	//[14]11 Mes
					0														,;	//[15]12 Mes - Mes do Parametro
					0														})	//[16]13 Total

	_nItem++	
	DbSelectArea("SA6")
	SA6->(DbSkip())
EndDo

_a7Meses	:= {	{"01","12","11","10","09","08","07","06","05","04","03","02","01"},;
					{"02","01","12","11","10","09","08","07","06","05","04","03","02"},;
					{"03","02","01","12","11","10","09","08","07","06","05","04","03"},;
					{"04","03","02","01","12","11","10","09","08","07","06","05","04"},;
					{"05","04","03","02","01","12","11","10","09","08","07","06","05"},;
					{"06","05","04","03","02","01","12","11","10","09","08","07","06"},;
					{"07","06","05","04","03","02","01","12","11","10","09","08","07"},;
					{"08","07","06","05","04","03","02","01","12","11","10","09","08"},;
					{"09","08","07","06","05","04","03","02","01","12","11","10","09"},;
					{"10","09","08","07","06","05","04","03","02","01","12","11","10"},;
					{"11","10","09","08","07","06","05","04","03","02","01","12","11"},;
					{"12","11","10","09","08","07","06","05","04","03","02","01","12"}}


cMes	:= strzero(month(mv_par03),2)
cAno	:= Strzero(Year(mv_par03),4)
_nPos 	:= ascan(_a7Meses,{|x| x[1] == cMes })

If _nPos > 0

	For _nI := 1 to 12

		If _nI > 1
			If cMes <= _a7Meses[_nPos, _nI]
				cAno	:= strzero(Year(mv_par03)-1	,4)
			EndIf
		EndIf
		
		_dDtINI	:= FirstDay(ctod("01/"+_a7Meses[_nPos, _nI]+"/"+cAno))
		_dDtFIM	:= iif(_nI==1,mv_par03,LastDay (ctod("01/"+_a7Meses[_nPos, _nI]+"/"+cAno)))
		
		CRK05QRY(_dDtINI,_dDtFIM)
		
		dbSelectArea("QUERY")
		dbGoTop()

		Do Case
			Case _nI == 1
				_xPos	:= 15
			Case _nI == 2
				_xPos	:= 14
			Case _nI == 3
				_xPos	:= 13
			Case _nI == 4
				_xPos	:= 12
			Case _nI == 5
				_xPos	:= 11
			Case _nI == 6
				_xPos	:= 10
			Case _nI == 7
				_xPos	:= 9
			Case _nI == 8
				_xPos	:= 8
			Case _nI == 9
				_xPos	:= 7
			Case _nI == 10
				_xPos	:= 6
			Case _nI == 11
				_xPos	:= 5
			Case _nI == 12
				_xPos	:= 4
		EndCase

		Do While !EOF()
			_nPos1 	:= ascan(_aRel,{|x| x[3] == QUERY->ZCG_CONTA })
			If _nPos1 > 0
				_aRel[_nPos1,_xPos]	:= QUERY->ZCG_VALOR
				_aRel[_nPos1,16] 	+= QUERY->ZCG_VALOR
			EndIf
			dbSelectArea("QUERY")
			QUERY->(DbSkip())
		EndDo
		dbSelectArea("QUERY")
		QUERY->(dbCloseArea())
    Next

EndIf

_aMeses	:= {	{"01","Janeiro"		},;
				{"02","Fevereiro"	},;
				{"03","Marco"		},;
				{"04","Abril"		},;
				{"05","Maio"		},;
				{"06","Junho"		},;
				{"07","Julho"		},;
				{"08","Agosto"		},;
				{"09","Setembro"	},;
				{"10","Outubro"		},;
				{"11","Novembro"	},;
				{"12","Dezembro"	}}

If _nPos > 0

	If nLin > 65 // Salto de Página. Neste caso o formulario tem 65 linhas...
		Cabec(Titulo,Cabec1,Cabec2,NomeProg,Tamanho,nTipo)
		nLin := 06
	EndIf

	@ nLin , _nCol_01 PSAY "It"
	@ nLin , _nCol_02 PSAY "|"
	@ nLin , _nCol_03 PSAY "Banco"
	@ nLin , _nCol_04 PSAY "|"
	@ nLin , _nCol_05 PSAY "C/C"

	_nPosMes := ascan(_aMeses,{|x| x[1] == _a7Meses[_nPos,12]})
	@ nLin , _nCol_06   PSAY "|"
	If cMes <= _a7Meses[_nPos, 12]
		cAno	:= strzero(Year(mv_par03)-1	,4)
	Else
		cAno	:= strzero(Year(mv_par03),4)
	EndIf
	@ nLin , _nCol_07 PSAY _aMeses[_nPosMes,02]+"/"+substr(cAno,3,2)

	_nPosMes := ascan(_aMeses,{|x| x[1] == _a7Meses[_nPos,11]})
	@ nLin , _nCol_08 PSAY "|"
	If cMes <= _a7Meses[_nPos, 11]
		cAno	:= strzero(Year(mv_par03)-1	,4)
	Else
		cAno	:= strzero(Year(mv_par03),4)
	EndIf
	@ nLin , _nCol_09 PSAY _aMeses[_nPosMes,02]+"/"+substr(cAno,3,2)

	_nPosMes := ascan(_aMeses,{|x| x[1] == _a7Meses[_nPos,10]})
	@ nLin , _nCol_10 PSAY "|"
	If cMes <= _a7Meses[_nPos, 10]
		cAno	:= strzero(Year(mv_par03)-1	,4)
	Else
		cAno	:= strzero(Year(mv_par03),4)
	EndIf
	@ nLin , _nCol_11 PSAY _aMeses[_nPosMes,02]+"/"+substr(cAno,3,2)

	_nPosMes := ascan(_aMeses,{|x| x[1] == _a7Meses[_nPos,09]})
	@ nLin , _nCol_12 PSAY "|"
	If cMes <= _a7Meses[_nPos, 09]
		cAno	:= strzero(Year(mv_par03)-1	,4)
	Else
		cAno	:= strzero(Year(mv_par03),4)
	EndIf
	@ nLin , _nCol_13 PSAY _aMeses[_nPosMes,02]+"/"+substr(cAno,3,2)

	_nPosMes := ascan(_aMeses,{|x| x[1] == _a7Meses[_nPos,08]})
	@ nLin , _nCol_14 PSAY "|"
	If cMes <= _a7Meses[_nPos, 08]
		cAno	:= strzero(Year(mv_par03)-1	,4)
	Else
		cAno	:= strzero(Year(mv_par03),4)
	EndIf
	@ nLin , _nCol_15 PSAY _aMeses[_nPosMes,02]+"/"+substr(cAno,3,2)

	_nPosMes := ascan(_aMeses,{|x| x[1] == _a7Meses[_nPos,07]})
	@ nLin , _nCol_16 PSAY "|"
	If cMes <= _a7Meses[_nPos, 07]
		cAno	:= strzero(Year(mv_par03)-1	,4)
	Else
		cAno	:= strzero(Year(mv_par03),4)
	EndIf
	@ nLin , _nCol_17 PSAY _aMeses[_nPosMes,02]+"/"+substr(cAno,3,2)

	_nPosMes := ascan(_aMeses,{|x| x[1] == _a7Meses[_nPos,06]})
	@ nLin , _nCol_18 PSAY "|"
	If cMes <= _a7Meses[_nPos, 06]
		cAno	:= strzero(Year(mv_par03)-1	,4)
	Else
		cAno	:= strzero(Year(mv_par03),4)
	EndIf
	@ nLin , _nCol_19 PSAY _aMeses[_nPosMes,02]+"/"+substr(cAno,3,2)

	_nPosMes := ascan(_aMeses,{|x| x[1] == _a7Meses[_nPos,05]})
	@ nLin , _nCol_20 PSAY "|"
	If cMes <= _a7Meses[_nPos, 05]
		cAno	:= strzero(Year(mv_par03)-1	,4)
	Else
		cAno	:= strzero(Year(mv_par03),4)
	EndIf
	@ nLin , _nCol_21 PSAY _aMeses[_nPosMes,02]+"/"+substr(cAno,3,2)

	_nPosMes := ascan(_aMeses,{|x| x[1] == _a7Meses[_nPos,04]})
	@ nLin , _nCol_22 PSAY "|"
	If cMes <= _a7Meses[_nPos, 04]
		cAno	:= strzero(Year(mv_par03)-1	,4)
	Else
		cAno	:= strzero(Year(mv_par03),4)
	EndIf
	@ nLin , _nCol_23 PSAY _aMeses[_nPosMes,02]+"/"+substr(cAno,3,2)

	_nPosMes := ascan(_aMeses,{|x| x[1] == _a7Meses[_nPos,03]})
	@ nLin , _nCol_24 PSAY "|"
	If cMes <= _a7Meses[_nPos, 03]
		cAno	:= strzero(Year(mv_par03)-1	,4)
	Else
		cAno	:= strzero(Year(mv_par03),4)
	EndIf
	@ nLin , _nCol_25 PSAY _aMeses[_nPosMes,02]+"/"+substr(cAno,3,2)

	_nPosMes := ascan(_aMeses,{|x| x[1] == _a7Meses[_nPos,02]})
	@ nLin , _nCol_26 PSAY "|"
	If cMes <= _a7Meses[_nPos, 02]
		cAno	:= strzero(Year(mv_par03)-1	,4)
	Else
		cAno	:= strzero(Year(mv_par03),4)
	EndIf
	@ nLin , _nCol_27 PSAY _aMeses[_nPosMes,02]+"/"+substr(cAno,3,2)

	_nPosMes := ascan(_aMeses,{|x| x[1] == _a7Meses[_nPos,01]})
	@ nLin , _nCol_28 PSAY "|"
	cAno	:= strzero(Year(mv_par03),4)
	@ nLin , _nCol_29 PSAY _aMeses[_nPosMes,02]+"/"+substr(cAno,3,2)
EndIf

@ nLin , _nCol_30 PSAY "|"
@ nLin , _nCol_31 PSAY "Total"
@ nLin , _nCol_32 PSAY "|"
nLin++

@ nLin , _nCol_01   PSAY "--"
@ nLin , _nCol_02   PSAY "+"
@ nLin , _nCol_03   PSAY Replicate("-",20)
@ nLin , _nCol_04   PSAY "+"
@ nLin , _nCol_05   PSAY Replicate("-",10)
@ nLin , _nCol_06   PSAY "+"
@ nLin , _nCol_07-1 PSAY Replicate("-",13)
@ nLin , _nCol_08   PSAY "+"
@ nLin , _nCol_09-1 PSAY Replicate("-",13)
@ nLin , _nCol_10   PSAY "+"
@ nLin , _nCol_11-1 PSAY Replicate("-",13)
@ nLin , _nCol_12   PSAY "+"
@ nLin , _nCol_13-1 PSAY Replicate("-",13)
@ nLin , _nCol_14   PSAY "+"
@ nLin , _nCol_15-1 PSAY Replicate("-",13)
@ nLin , _nCol_16   PSAY "+"
@ nLin , _nCol_17-1 PSAY Replicate("-",13)
@ nLin , _nCol_18   PSAY "+"
@ nLin , _nCol_19-1 PSAY Replicate("-",13)
@ nLin , _nCol_20   PSAY "+"
@ nLin , _nCol_21-1 PSAY Replicate("-",13)
@ nLin , _nCol_22   PSAY "+"
@ nLin , _nCol_23-1 PSAY Replicate("-",13)
@ nLin , _nCol_24   PSAY "+"
@ nLin , _nCol_25-1 PSAY Replicate("-",13)
@ nLin , _nCol_26   PSAY "+"
@ nLin , _nCol_27-1 PSAY Replicate("-",13)
@ nLin , _nCol_28   PSAY "+"
@ nLin , _nCol_29-1 PSAY Replicate("-",14)
@ nLin , _nCol_30   PSAY "+"
@ nLin , _nCol_31-1 PSAY Replicate("-",14)
@ nLin , _nCol_32   PSAY "+"
nLin++

_nTotMes1  := 0
_nTotMes2  := 0
_nTotMes3  := 0
_nTotMes4  := 0
_nTotMes5  := 0
_nTotMes6  := 0
_nTotMes7  := 0
_nTotMes8  := 0
_nTotMes9  := 0
_nTotMes10 := 0
_nTotMes11 := 0
_nTotMes12 := 0
_nTotMes13 := 0

For _nY := 1 to Len(_aRel)

	If nLin > 65 // Salto de Página. Neste caso o formulario tem 65 linhas...
		Cabec(Titulo,Cabec1,Cabec2,NomeProg,Tamanho,nTipo)
		nLin := 06
	EndIf

	@ nLin , _nCol_01 PSAY _aRel[_nY, 1] 								//Item
	@ nLin , _nCol_02 PSAY "|"
	@ nLin , _nCol_03 PSAY substr(_aRel[_nY, 2],1,20) 					//Banco
	@ nLin , _nCol_04 PSAY "|"
	@ nLin , _nCol_05 PSAY substr(_aRel[_nY, 3],1,10)					//Conta Corrente
	@ nLin , _nCol_06 PSAY "|"
	@ nLin , _nCol_07 PSAY _aRel[_nY, 4] picture "@E 9,999,999.99" 		//Mes 1
	@ nLin , _nCol_08 PSAY "|"
	@ nLin , _nCol_09 PSAY _aRel[_nY, 5] picture "@E 9,999,999.99" 		//Mes 2
	@ nLin , _nCol_10 PSAY "|"
	@ nLin , _nCol_11 PSAY _aRel[_nY, 6] picture "@E 9,999,999.99" 		//Mes 3
	@ nLin , _nCol_12 PSAY "|"
	@ nLin , _nCol_13 PSAY _aRel[_nY, 7] picture "@E 9,999,999.99" 		//Mes 4
	@ nLin , _nCol_14 PSAY "|"
	@ nLin , _nCol_15 PSAY _aRel[_nY, 8] picture "@E 9,999,999.99" 		//Mes 5
	@ nLin , _nCol_16 PSAY "|"
	@ nLin , _nCol_17 PSAY _aRel[_nY, 9] picture "@E 9,999,999.99" 		//Mes 6
	@ nLin , _nCol_18 PSAY "|"
	@ nLin , _nCol_19 PSAY _aRel[_nY,10] picture "@E 9,999,999.99"			//Mes 7
	@ nLin , _nCol_20 PSAY "|"
	@ nLin , _nCol_21 PSAY _aRel[_nY,11] picture "@E 9,999,999.99"			//Mes 8
	@ nLin , _nCol_22 PSAY "|"
	@ nLin , _nCol_23 PSAY _aRel[_nY,12] picture "@E 9,999,999.99"			//Mes 9
	@ nLin , _nCol_24 PSAY "|"
	@ nLin , _nCol_25 PSAY _aRel[_nY,13] picture "@E 9,999,999.99"			//Mes 10
	@ nLin , _nCol_26 PSAY "|"
	@ nLin , _nCol_27 PSAY _aRel[_nY,14] picture "@E 9,999,999.99"			//Mes 11
	@ nLin , _nCol_28 PSAY "|"
	@ nLin , _nCol_29 PSAY _aRel[_nY,15] picture "@E 99,999,999.99"			//Mes 12
	@ nLin , _nCol_30 PSAY "|"
	@ nLin , _nCol_31 PSAY _aRel[_nY,16] picture "@E 99,999,999.99"			//Total
	@ nLin , _nCol_32 PSAY "|"
	nLin++

	_nTotMes1  += _aRel[_nY, 4]
	_nTotMes2  += _aRel[_nY, 5]
	_nTotMes3  += _aRel[_nY, 6]
	_nTotMes4  += _aRel[_nY, 7]
	_nTotMes5  += _aRel[_nY, 8]
	_nTotMes6  += _aRel[_nY, 9]
	_nTotMes7  += _aRel[_nY,10]
	_nTotMes8  += _aRel[_nY,11]
	_nTotMes9  += _aRel[_nY,12]
	_nTotMes10 += _aRel[_nY,13]
	_nTotMes11 += _aRel[_nY,14]
	_nTotMes12 += _aRel[_nY,15]
	_nTotMes13 += _aRel[_nY,16]
Next _nY

@ nLin , _nCol_01   PSAY "--"
@ nLin , _nCol_02   PSAY "+"
@ nLin , _nCol_03   PSAY Replicate("-",20)
@ nLin , _nCol_04   PSAY "+"
@ nLin , _nCol_05   PSAY Replicate("-",10)
@ nLin , _nCol_06   PSAY "+"
@ nLin , _nCol_07-1 PSAY Replicate("-",13)
@ nLin , _nCol_08   PSAY "+"
@ nLin , _nCol_09-1 PSAY Replicate("-",13)
@ nLin , _nCol_10   PSAY "+"
@ nLin , _nCol_11-1 PSAY Replicate("-",13)
@ nLin , _nCol_12   PSAY "+"
@ nLin , _nCol_13-1 PSAY Replicate("-",13)
@ nLin , _nCol_14   PSAY "+"
@ nLin , _nCol_15-1 PSAY Replicate("-",13)
@ nLin , _nCol_16   PSAY "+"
@ nLin , _nCol_17-1 PSAY Replicate("-",13)
@ nLin , _nCol_18   PSAY "+"
@ nLin , _nCol_19-1 PSAY Replicate("-",13)
@ nLin , _nCol_20   PSAY "+"
@ nLin , _nCol_21-1 PSAY Replicate("-",13)
@ nLin , _nCol_22   PSAY "+"
@ nLin , _nCol_23-1 PSAY Replicate("-",13)
@ nLin , _nCol_24   PSAY "+"
@ nLin , _nCol_25-1 PSAY Replicate("-",13)
@ nLin , _nCol_26   PSAY "+"
@ nLin , _nCol_27-1 PSAY Replicate("-",13)
@ nLin , _nCol_28   PSAY "+"
@ nLin , _nCol_29-1 PSAY Replicate("-",14)
@ nLin , _nCol_30   PSAY "+"
@ nLin , _nCol_31-1 PSAY Replicate("-",14)
@ nLin , _nCol_32   PSAY "+"
nLin++

@ nLin , _nCol_01 PSAY ""			 								//Item
@ nLin , _nCol_02 PSAY "|"
@ nLin , _nCol_03 PSAY "Total"						 					//Banco
@ nLin , _nCol_04 PSAY "|"
@ nLin , _nCol_05 PSAY ""											//Conta Corrente
@ nLin , _nCol_06 PSAY "|"
@ nLin , _nCol_07 PSAY _nTotMes1 	picture "@E 9,999,999.99" 		//Mes 1
@ nLin , _nCol_08 PSAY "|"
@ nLin , _nCol_09 PSAY _nTotMes2 	picture "@E 9,999,999.99" 		//Mes 2
@ nLin , _nCol_10 PSAY "|"
@ nLin , _nCol_11 PSAY _nTotMes3 	picture "@E 9,999,999.99" 		//Mes 3
@ nLin , _nCol_12 PSAY "|"
@ nLin , _nCol_13 PSAY _nTotMes4 	picture "@E 9,999,999.99" 		//Mes 4
@ nLin , _nCol_14 PSAY "|"
@ nLin , _nCol_15 PSAY _nTotMes5 	picture "@E 9,999,999.99" 		//Mes 5
@ nLin , _nCol_16 PSAY "|"
@ nLin , _nCol_17 PSAY _nTotMes6 	picture "@E 9,999,999.99" 		//Mes 6
@ nLin , _nCol_18 PSAY "|"
@ nLin , _nCol_19 PSAY _nTotMes7 	picture "@E 9,999,999.99"			//Mes 7
@ nLin , _nCol_20 PSAY "|"
@ nLin , _nCol_21 PSAY _nTotMes8 	picture "@E 9,999,999.99"			//Mes 8
@ nLin , _nCol_22 PSAY "|"
@ nLin , _nCol_23 PSAY _nTotMes9 	picture "@E 9,999,999.99"			//Mes 9
@ nLin , _nCol_24 PSAY "|"
@ nLin , _nCol_25 PSAY _nTotMes10 	picture "@E 9,999,999.99"			//Mes 10
@ nLin , _nCol_26 PSAY "|"
@ nLin , _nCol_27 PSAY _nTotMes11 	picture "@E 9,999,999.99"			//Mes 11
@ nLin , _nCol_28 PSAY "|"
@ nLin , _nCol_29 PSAY _nTotMes12 	picture "@E 99,999,999.99"			//Mes 12
@ nLin , _nCol_30 PSAY "|"
@ nLin , _nCol_31 PSAY _nTotMes13 	picture "@E 99,999,999.99"			//Total
@ nLin , _nCol_32 PSAY "|"
nLin++
@ nLin , 000 PSAY Replicate("-",219)


If _nTotMes13 <> 0
	CRK05FLX(_nTotMes13)
EndIf


//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Finaliza a execucao do relatorio...                                 ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
SET DEVICE TO SCREEN

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Se impressao em disco, chama o gerenciador de impressao...          ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

If aReturn[5]==1
	dbCommitAll()
	SET PRINTER TO
	OurSpool(wnrel)
Endif

MS_FLUSH()

Return
//---------------------------------------------------------------------------------------
/*/{Protheus.doc} CRK05FLX
Rotina de gravação do Fluxo
@author  	Totvs
@since     	01/01/2015
@version  	P.11.8      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------
Static Function CRK05FLX(_nValor)                          

dbSelectArea("PAH")
dbSetOrder(1)  

_nTam:=40-Len("CRELK05")
_cChave:="CRELK05"+Space(_nTam)+DTOS(mv_par03)                                

If !(dbSeek(xFilial("PAH")+_cChave))
	RecLock("PAH", .T.)
		PAH->PAH_FILIAL := xFilial("PAH")            
		PAH->PAH_ORIGEM := "CRELK05"
     	PAH->PAH_DATA   := mv_par03
		PAH->PAH_VALOR  := _nValor
	msUnLock()
Else
	RecLock("PAH", .F.)
		PAH->PAH_VALOR  := _nValor
	msUnLock()
EndIf

Return				
//---------------------------------------------------------------------------------------
/*/{Protheus.doc} CRK05QRY
Monta query do relatorio
@author  	Totvs
@since     	01/01/2015
@version  	P.11.8      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------
Static Function CRK05QRY(_dDtINI,_dDtFIM)

_cQuery := " SELECT ZCG_CONTA, SUM(ZCG_VALOR) AS ZCG_VALOR"
_cQuery += " FROM "
_cQuery += RetSqlName("ZCG")+" ZCG"
_cQuery += " WHERE '"+ xFilial("ZCG") +"' = ZCG_FILIAL"
_cQuery += " AND D_E_L_E_T_ <> '*' "
_cQuery += " AND ZCG_CONTA   BETWEEN '"+mv_par01			+"' AND '"+mv_par02			+"' "		//conta
_cQuery += " AND ZCG_EMISSA BETWEEN '"+DTOS(_dDtINI)	+"' AND '"+DTOS(_dDtFIM)	+"' "		//emissao
If mv_PAR04 == 1 //SIM
	_cQuery += " AND (ZCG_RDR = '' OR ((ZCG_RDR <> '' AND ZCG_FECRAT = '') AND (SUBSTRING(ZCG_RDR,1,2) <> 'AP'))) " //status (Sempre em aberto)
	//OBS: SUBSTRING(ZCG_RDR,1,2) <> 'AP - este comando foi acrescentado para contemplar os registros que nao entram no fechamento de RDR (tipo transf.Bancaria) via cheque
	//alterado dia 25/05/10 pelo analista Emerson	
Else
	_cQuery += " AND ZCG_RDR = '' " //status (Sempre em aberto)
EndIf
_cQuery += " GROUP BY ZCG_CONTA"
_cQuery += " ORDER BY ZCG_CONTA"

TCQUERY _cQuery NEW ALIAS "QUERY"

Return
