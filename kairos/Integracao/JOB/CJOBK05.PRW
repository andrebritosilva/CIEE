#INCLUDE "TOTVS.CH"
#INCLUDE "TOPCONN.CH"
#include "protheus.ch"
#include "tbiconn.ch"
#include 'parmtype.ch'


/*/{Protheus.doc} CJOBK05
//TODO Descrição - JOB Integração entre as tabelas ZC0/ZC1 (Contrato e Local de Contrato) do BackOffice com as tabelas integradoras ZZ0/ZZ1 do RH
@author marcelo.moraes
@since 02/04/2020
@version 1.0
@return ${return}, ${return_description}
@param aParam, array, descricao
@type function
/*/
User Function CJOBK05(aParam)

Local cFilaJob  := ""

DEFAULT aParam := {"40","40000101"}

//=====================================================================================
// Validação de Parâmetros Empresa / Filial. Necessário para preparação de ambientes
//=====================================================================================
If ValType( aParam ) <> "A"
	ConOut("## CJOBK05 Parametro Empresa/Filial Incorreto [aParam] Kill... ##")
	Return
ElseIf ValType( aParam[1] ) <> "C" .Or. ValType( aParam[2] ) <> "C"
	ConOut("## CJOBK05 Parametro Empresa e/ou Filial Incorreto(s) [aParam] Kill... ##")
	Return
EndIf

//=====================================================================================
// Preparação do Ambiente. 
//=====================================================================================

RpcSetEnv( aParam[1] , aParam[1] , Nil, Nil, "GPE", Nil )//, aTables )

//=====================================================================================
// Controle de semaforo - Nao permitir execução de mais de uma instância:
//=====================================================================================
cFilaJob	:=	"CJOBK05-"+aParam[1]+aParam[2]

If !LockByName(cFilaJob)
	ConOut("## JOB ["+cFilaJob+"] já esta ativo, execução abortada... "+DTOC(Date())+"-"+Time()+" ##")
	Return
Else
	ConOut("## Inicio ["+cFilaJob+"] "+DTOC(Date())+"-"+Time()+" ##")
EndIf

ProcMovimentos()

UnlockByName(cFilaJob)
	
ConOut("## Fim ["+cFilaJob+"] "+DTOC(Date())+"-"+Time()+" ##")

return

/*/{Protheus.doc} ProcMovimentos
//TODO Descrição auto-gerada.
@author marcelo.moraes
@since 31/03/2020
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
Static Function ProcMovimentos()

Local nHndERP   := AdvConnection()
Local cBcoBk    := TRIM(SuperGetMv("CI_BANCOBK",.F.,"MSSQL/CDPRXC_HOM"))
Local cSrvBk    := TRIM(SuperGetMv("CI_SERVIBK",.F.,"172.28.13.135"))
Local nPtaBk    := SuperGetMv("CI_PORTABK",.F.,9335)
Local nConBk    := 0 
Local _cAliasBK := GetNextAlias()
Local cQuery    := ""
Local cUpdate   := ""
Local cTabZC0   := "ZC0"+IIF(CEMPANT=="40","010","030")
Local cTabZC1   := "ZC1"+IIF(CEMPANT=="40","010","030")
//Local aRecnoZC0 := {}
Local cFilZZ0   := ""
Local cCodZZ0   := ""
Local cFilZZ1   := ""
Local cCodZZ1   := ""
Local cLCRZZ1   := ""
LocaL _cHora    := ""

nConBk := TCLink(cBcoBk,cSrvBk,nPtaBk)

If nConBk >= 0

	//Seta top do backoffice
	tcSetConn(nConBk)
	
	//==============================
	// Busca contratos do BackOficce
	//==============================
	
	cQuery += " SELECT "
	cQuery += " ZC0_FILIAL, "
	cQuery += " ZC0_CODIGO, "
	cQuery += " ZC0_TIPCON, "
	cQuery += " ZC0_TIPAPR, "
	cQuery += " ZC0_PRGAPE, "
	cQuery += " ZC0_TIPEMP, "
	cQuery += " ZC0_NOME, "
	cQuery += " ZC0_NREDUZ, "
	cQuery += " ZC0_NUMDOC, "
	cQuery += " ZC0_STCONV, "
	cQuery += " ZC0_STEMPR, "
	cQuery += " ZC0_FORPGT, "
	cQuery += " ZC0_CEPEMP, "
	cQuery += " ZC0_LOGEMP, "
	cQuery += " ZC0_ENDEMP, "
	cQuery += " ZC0_NUMEMP, "
	cQuery += " ZC0_COMEMP, "
	cQuery += " ZC0_BAIEMP, "
	cQuery += " ZC0_CMUNEM, "
	cQuery += " ZC0_CIDEMP, "
	cQuery += " ZC0_ESTEMP, "
	cQuery += " ZC0.R_E_C_N_O_ AS RECNOZC0 "
	cQuery += " FROM "+cTabZC0+" ZC0 "
	cQuery += " WHERE " 
	cQuery += " ZC0.D_E_L_E_T_='' AND "
	cQuery += " ZC0_STZZ0='' "
	cQuery += " ORDER BY ZC0_CODIGO "
	
	cQuery := ChangeQuery(cQuery)

	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),_cAliasBK,.T.,.T.)
	MemoWrite("CJOBK05-ZC0.SQL",cQuery)

else
	ConOut(" ## Falha ao executar TCLINK do BackOffice... "+DTOC(Date())+"-"+Time()+" ##")
	return
endif

//===============================================
// Grava os contratos na tabela integradora do RH
//===============================================

(_cAliasBK)->(dbGoTop())  

While !(_cAliasBK)->(eof())

	//Seta top de RH
	tcSetConn(nHndERP)

	Begin Transaction
	
		//======================
		// Grava ZZ0 - Contratos
		//======================
	
		cFilZZ0 := PadR((_cAliasBK)->ZC0_FILIAL,TamSx3('ZZ0_FILIAL')[1])
		cCodZZ0 := PadR((_cAliasBK)->ZC0_CODIGO,TamSx3('ZZ0_CODIGO')[1])
		
		ZZ0->(DbSetOrder(1))
		If ZZ0->(DbSeek(cFilZZ0+cCodZZ0))
			ZZ0->(RecLock("ZZ0",.F.))
		else
			ZZ0->(RecLock("ZZ0",.T.))
			ZZ0->ZZ0_FILIAL := (_cAliasBK)->ZC0_FILIAL
			ZZ0->ZZ0_CODIGO := (_cAliasBK)->ZC0_CODIGO
		endif
	
		ZZ0->ZZ0_TIPCON := IIF(!EMPTY((_cAliasBK)->ZC0_TIPCON),(_cAliasBK)->ZC0_TIPCON,ZZ0->ZZ0_TIPCON)
		ZZ0->ZZ0_TIPAPR := IIF(!EMPTY((_cAliasBK)->ZC0_TIPAPR),(_cAliasBK)->ZC0_TIPAPR,ZZ0->ZZ0_TIPAPR)
		ZZ0->ZZ0_PRGAPE := IIF(!EMPTY((_cAliasBK)->ZC0_PRGAPE),(_cAliasBK)->ZC0_PRGAPE,ZZ0->ZZ0_PRGAPE)
		ZZ0->ZZ0_TIPEMP := IIF(!EMPTY((_cAliasBK)->ZC0_TIPEMP),(_cAliasBK)->ZC0_TIPEMP,ZZ0->ZZ0_TIPEMP)
		ZZ0->ZZ0_NOME   := IIF(!EMPTY((_cAliasBK)->ZC0_NOME)  ,(_cAliasBK)->ZC0_NOME  ,ZZ0->ZZ0_NOME)
		ZZ0->ZZ0_NREDUZ := IIF(!EMPTY((_cAliasBK)->ZC0_NREDUZ),(_cAliasBK)->ZC0_NREDUZ,ZZ0->ZZ0_NREDUZ)
		ZZ0->ZZ0_NUMDOC := IIF(!EMPTY((_cAliasBK)->ZC0_NUMDOC),(_cAliasBK)->ZC0_NUMDOC,ZZ0->ZZ0_NUMDOC)
		ZZ0->ZZ0_STCONV := IIF(!EMPTY((_cAliasBK)->ZC0_STCONV),(_cAliasBK)->ZC0_STCONV,ZZ0->ZZ0_STCONV)
		ZZ0->ZZ0_STEMPR := IIF(!EMPTY((_cAliasBK)->ZC0_STEMPR),(_cAliasBK)->ZC0_STEMPR,ZZ0->ZZ0_STEMPR)
		ZZ0->ZZ0_FORPGT := IIF(!EMPTY((_cAliasBK)->ZC0_FORPGT),(_cAliasBK)->ZC0_FORPGT,ZZ0->ZZ0_FORPGT)
		ZZ0->ZZ0_CEPEMP := IIF(!EMPTY((_cAliasBK)->ZC0_CEPEMP),(_cAliasBK)->ZC0_CEPEMP,ZZ0->ZZ0_CEPEMP)
		ZZ0->ZZ0_LOGEMP := IIF(!EMPTY((_cAliasBK)->ZC0_LOGEMP),(_cAliasBK)->ZC0_LOGEMP,ZZ0->ZZ0_LOGEMP)
		ZZ0->ZZ0_ENDEMP := IIF(!EMPTY((_cAliasBK)->ZC0_ENDEMP),(_cAliasBK)->ZC0_ENDEMP,ZZ0->ZZ0_ENDEMP)
		ZZ0->ZZ0_NUMEMP := IIF(!EMPTY((_cAliasBK)->ZC0_NUMEMP),(_cAliasBK)->ZC0_NUMEMP,ZZ0->ZZ0_NUMEMP)
		ZZ0->ZZ0_COMEMP := IIF(!EMPTY((_cAliasBK)->ZC0_COMEMP),(_cAliasBK)->ZC0_COMEMP,ZZ0->ZZ0_COMEMP)
		ZZ0->ZZ0_BAIEMP := IIF(!EMPTY((_cAliasBK)->ZC0_BAIEMP),(_cAliasBK)->ZC0_BAIEMP,ZZ0->ZZ0_BAIEMP)
		ZZ0->ZZ0_CMUNEM := IIF(!EMPTY((_cAliasBK)->ZC0_CMUNEM),(_cAliasBK)->ZC0_CMUNEM,ZZ0->ZZ0_CMUNEM)
		ZZ0->ZZ0_CIDEMP := IIF(!EMPTY((_cAliasBK)->ZC0_CIDEMP),(_cAliasBK)->ZC0_CIDEMP,ZZ0->ZZ0_CIDEMP)
		ZZ0->ZZ0_ESTEMP := IIF(!EMPTY((_cAliasBK)->ZC0_ESTEMP),(_cAliasBK)->ZC0_ESTEMP,ZZ0->ZZ0_ESTEMP)
		ZZ0->(MsUnlock())	
	
		//=============================================
		// Atualiza os status da tabela ZC0 - Contratos
		//==============================================
		
		_cHora    := Substr(Time(),1,2) + Substr(Time(),4,2) +SUBSTR(Time(),7,2)
	
		//Seta top do backoffice
		tcSetConn(nConBk)
	
		cUpdate := " UPDATE " + cTabZC0	  
		cUpdate += " SET ZC0_STZZ0='A', "
		cUpdate += "     ZC0_MSGZZ0=' INTEGRADO - ZZ0 ', "
		cUpdate += "     ZC0_DTIZZ0='"+DTOS(Date())+"', "
		cUpdate += "     ZC0_HRZZ0='"+_cHora+"' "				
		cUpdate += " WHERE R_E_C_N_O_ =	" +  alltrim(str((_cAliasBK)->RECNOZC0))  	
		
		TcSqlExec(cUpdate)

	End Transaction

	(_cAliasBK)->(DbSKIP())
	
End

(_cAliasBK)->(dbCloseArea())

//Seta top do backoffice
tcSetConn(nConBk)

//=========================================
// Busca locais de contratos do BackOficce
//=========================================

_cAliasBK := GetNextAlias()

cQuery := " SELECT "
cQuery += " ZC1_FILIAL, "
cQuery += " ZC1_CODIGO, "
cQuery += " ZC1_LOCCTR, "
cQuery += " ZC1_RAZSOC, "
cQuery += " ZC1_NOMFAN, "
cQuery += " ZC1_DOCLOC, "
cQuery += " ZC1_INSEST, "
cQuery += " ZC1_INSMUN, "
cQuery += " ZC1_CEPLOC, "
cQuery += " ZC1_LOGLOC, "
cQuery += " ZC1_ENDLOC, "
cQuery += " ZC1_NUMLOC, "
cQuery += " ZC1_COMLOC, "
cQuery += " ZC1_BAILOC, "
cQuery += " ZC1_CMUNLO, "
cQuery += " ZC1_CIDLOC, "
cQuery += " ZC1_ESTLOC, "
cQuery += " ZC1_IDCOLO, "
cQuery += " ZC1_NOCOLO, "
cQuery += " ZC1_CACOLO, "
cQuery += " ZC1_DECOLO, "
//cQuery += " ZC1_IDCOEN, "
//cQuery += " ZC1_NOCOEN, "
//cQuery += " ZC1_CACOEN, "
//cQuery += " ZC1_DECOEN, "
cQuery += " ZC1_CODTIT, "
cQuery += " ZC1_CODCTR, "
cQuery += " ZC1.R_E_C_N_O_ AS RECNOZC1 "
cQuery += " FROM "+cTabZC1+" ZC1 "
cQuery += " WHERE " 
cQuery += " ZC1.D_E_L_E_T_='' AND "
cQuery += " ZC1_STZZ1='' "
cQuery += " ORDER BY ZC1_CODIGO "

cQuery := ChangeQuery(cQuery)

dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),_cAliasBK,.T.,.T.)
MemoWrite("CJOBK05-ZC1.SQL",cQuery)

//==========================================================
// Grava os locais de contratos na tabela integradora do RH
//===========================================================

(_cAliasBK)->(dbGoTop())  

While !(_cAliasBK)->(eof())

	//Seta top de RH
	tcSetConn(nHndERP)

	Begin Transaction
		
		//================================
		// Grava ZZ1 - Locais de Contrato
		//================================
	
	    cFilZZ1 := PadR((_cAliasBK)->ZC1_FILIAL,TamSx3('ZZ1_FILIAL')[1])
		cCodZZ1 := PadR((_cAliasBK)->ZC1_CODIGO,TamSx3('ZZ1_CODIGO')[1])
		cLCRZZ1 := PadR((_cAliasBK)->ZC1_LOCCTR,TamSx3('ZZ1_LOCCTR')[1])
		
		ZZ1->(DbSetOrder(1))
		If ZZ1->(DbSeek(cFilZZ1+cCodZZ1+cLCRZZ1))
			ZZ1->(RecLock("ZZ1",.F.))
		else
			ZZ1->(RecLock("ZZ1",.T.))
			ZZ1->ZZ1_FILIAL := (_cAliasBK)->ZC1_FILIAL
			ZZ1->ZZ1_CODIGO := (_cAliasBK)->ZC1_CODIGO
			ZZ1->ZZ1_LOCCTR := (_cAliasBK)->ZC1_LOCCTR
		endif
	
		ZZ1->ZZ1_RAZSOC := IIF(!EMPTY((_cAliasBK)->ZC1_RAZSOC),(_cAliasBK)->ZC1_RAZSOC,ZZ1->ZZ1_RAZSOC)
		ZZ1->ZZ1_NOMFAN := IIF(!EMPTY((_cAliasBK)->ZC1_NOMFAN),(_cAliasBK)->ZC1_NOMFAN,ZZ1->ZZ1_NOMFAN)
		ZZ1->ZZ1_DOCLOC := IIF(!EMPTY((_cAliasBK)->ZC1_DOCLOC),(_cAliasBK)->ZC1_DOCLOC,ZZ1->ZZ1_DOCLOC)
		ZZ1->ZZ1_INSEST := IIF(!EMPTY((_cAliasBK)->ZC1_INSEST),(_cAliasBK)->ZC1_INSEST,ZZ1->ZZ1_INSEST)
		ZZ1->ZZ1_INSMUN := IIF(!EMPTY((_cAliasBK)->ZC1_INSMUN),(_cAliasBK)->ZC1_INSMUN,ZZ1->ZZ1_INSMUN)
		ZZ1->ZZ1_CEPLOC := IIF(!EMPTY((_cAliasBK)->ZC1_CEPLOC),(_cAliasBK)->ZC1_CEPLOC,ZZ1->ZZ1_CEPLOC)
		ZZ1->ZZ1_LOGLOC := IIF(!EMPTY((_cAliasBK)->ZC1_LOGLOC),(_cAliasBK)->ZC1_LOGLOC,ZZ1->ZZ1_LOGLOC)
		ZZ1->ZZ1_ENDLOC := IIF(!EMPTY((_cAliasBK)->ZC1_ENDLOC),(_cAliasBK)->ZC1_ENDLOC,ZZ1->ZZ1_ENDLOC)
		ZZ1->ZZ1_NUMLOC := IIF(!EMPTY((_cAliasBK)->ZC1_NUMLOC),(_cAliasBK)->ZC1_NUMLOC,ZZ1->ZZ1_NUMLOC)
		ZZ1->ZZ1_COMLOC := IIF(!EMPTY((_cAliasBK)->ZC1_COMLOC),(_cAliasBK)->ZC1_COMLOC,ZZ1->ZZ1_COMLOC)
		ZZ1->ZZ1_BAILOC := IIF(!EMPTY((_cAliasBK)->ZC1_BAILOC),(_cAliasBK)->ZC1_BAILOC,ZZ1->ZZ1_BAILOC)
		ZZ1->ZZ1_CMUNLO := IIF(!EMPTY((_cAliasBK)->ZC1_CMUNLO),(_cAliasBK)->ZC1_CMUNLO,ZZ1->ZZ1_CMUNLO)
		ZZ1->ZZ1_CIDLOC := IIF(!EMPTY((_cAliasBK)->ZC1_CIDLOC),(_cAliasBK)->ZC1_CIDLOC,ZZ1->ZZ1_CIDLOC)
		ZZ1->ZZ1_ESTLOC := IIF(!EMPTY((_cAliasBK)->ZC1_ESTLOC),(_cAliasBK)->ZC1_ESTLOC,ZZ1->ZZ1_ESTLOC)
		ZZ1->ZZ1_IDCOLO := IIF(!EMPTY((_cAliasBK)->ZC1_IDCOLO),(_cAliasBK)->ZC1_IDCOLO,ZZ1->ZZ1_IDCOLO)
		ZZ1->ZZ1_NOCOLO := IIF(!EMPTY((_cAliasBK)->ZC1_NOCOLO),(_cAliasBK)->ZC1_NOCOLO,ZZ1->ZZ1_NOCOLO)
		ZZ1->ZZ1_CACOLO := IIF(!EMPTY((_cAliasBK)->ZC1_CACOLO),(_cAliasBK)->ZC1_CACOLO,ZZ1->ZZ1_CACOLO)
		ZZ1->ZZ1_DECOLO := IIF(!EMPTY((_cAliasBK)->ZC1_DECOLO),(_cAliasBK)->ZC1_DECOLO,ZZ1->ZZ1_DECOLO)
//		ZZ1->ZZ1_IDCOEN := IIF(!EMPTY((_cAliasBK)->ZC1_IDCOEN),(_cAliasBK)->ZC1_IDCOEN,ZZ1->ZZ1_IDCOEN)
//		ZZ1->ZZ1_NOCOEN := IIF(!EMPTY((_cAliasBK)->ZC1_NOCOEN),(_cAliasBK)->ZC1_NOCOEN,ZZ1->ZZ1_NOCOEN)
//		ZZ1->ZZ1_CACOEN := IIF(!EMPTY((_cAliasBK)->ZC1_CACOEN),(_cAliasBK)->ZC1_CACOEN,ZZ1->ZZ1_CACOEN)
//		ZZ1->ZZ1_DECOEN := IIF(!EMPTY((_cAliasBK)->ZC1_DECOEN),(_cAliasBK)->ZC1_DECOEN,ZZ1->ZZ1_DECOEN)
		ZZ1->ZZ1_CODTIT := IIF(!EMPTY((_cAliasBK)->ZC1_CODTIT),(_cAliasBK)->ZC1_CODTIT,ZZ1->ZZ1_CODTIT)
		ZZ1->ZZ1_CODCTR := IIF(!EMPTY((_cAliasBK)->ZC1_CODCTR),(_cAliasBK)->ZC1_CODCTR,ZZ1->ZZ1_CODCTR)
	
		ZZ1->(MsUnlock())	
	
		//========================================================
		// Atualiza os status da tabela ZC1 - Locais de Contratos
		//=========================================================
		
		_cHora    := Substr(Time(),1,2) + Substr(Time(),4,2) +SUBSTR(Time(),7,2)
	
		//Seta top do backoffice
		tcSetConn(nConBk)
	
		cUpdate := " UPDATE " + cTabZC1 
		cUpdate += " SET ZC1_STZZ1='A', "
		cUpdate += "     ZC1_MSGZZ1=' INTEGRADO - ZZ1 ', "
		cUpdate += "     ZC1_DTIZZ1='"+DTOS(Date())+"', "
		cUpdate += "     ZC1_HRZZ1='"+_cHora+"' "				
		cUpdate += " WHERE R_E_C_N_O_ =	" +  alltrim(str((_cAliasBK)->RECNOZC1))  	
		
		TcSqlExec(cUpdate)

	End Transaction

	(_cAliasBK)->(DbSKIP())
	
End

(_cAliasBK)->(dbCloseArea())

TCUnLink(nConBk)

TCUnLink(nHndERP)

return