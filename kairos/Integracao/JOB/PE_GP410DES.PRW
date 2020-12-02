#INCLUDE "PROTHEUS.CH"
#INCLUDE "rwmake.ch"            
#INCLUDE "TOPCONN.CH"
/*==================================================================================================
Ponto de entrada na rotina de geracao de CNABs para desprezar os funcionarios dos bancos
itau, santander, e BB qdo selecionado a opcao doc. O cliente utiliza apenas o banco bradesco para 
efetivar o doc/ted.
@author     A.Shibao
@since      22/02/2019
@param
@version    P12
@return
@project
@client    Ciee
//================================================================================================== */
User Function GP410DES()

Local aArea   := GetArea()  
Local cDesprSP:= "001*033*341" //BB*AMAZONIA/ITAU
Local cDesprRJ:= "001*104*341" 
Local lRet    := .t.

If  cEmpAnt == "40"
	If Left( SRA->RA_BCDEPSA,3 ) $ cDesprSP  .And. mv_par34 == 1
		lRet    := .f.
	Endif
elseif cEmpAnt == "50"
	// RJ - Via Bradesco faz doc para 001/104/341 - BB/CEF/ITAU
	If !(Left( SRA->RA_BCDEPSA,3 ) $ cDesprRJ) .And. mv_par34 == 1
		lRet    := .f.
	Endif
Endif
			
RestArea(aArea)   

Return(lRet)
