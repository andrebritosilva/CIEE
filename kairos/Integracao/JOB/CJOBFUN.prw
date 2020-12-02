#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} CJBKCLI
Rotina de geração de clientes de acordo com contrato e local de contrato
@author carlos.henrique
@since 31/05/2019
@version undefined
@type function
/*/
USER FUNCTION CJBKCLI(aCliFat, _cContrato, _cLocCtr, aLogCli)
Local cNatCLI:= SuperGetMV("CI_NATCLI",.T.,"99999999")
Local cCnpjBB:= ALLTRIM(SuperGetMV("CI_CNPJBB",.T.,"")) //Cnpj base da banco do brasil
Local cCnpjCX:= ALLTRIM(SuperGetMV("CI_CNPJCX",.T.,"")) //Cnpj base da caixa
Local cTSA1	 := ""
Local cTZC4	 := ""
Local aCli	 := {}
Local nAuto	 := 0
Local lRet	 := .T.
Local lGrava := .T.
Local cEmail := ""
Private lMsHelpAuto 	:= .T.
Private lMsErroAuto 	:= .F.
Private lAutoErrNoFile	:= .T. 

CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJBKCLI] Iniciando integração clientes.")

aCliFat:= {}
aLogCli:= {"","",""}

_cContrato := Padr(AllTrim(_cContrato),TamSX3("ZC1_CODIGO")[1]," ")
_cLocCtr   := Padr(AllTrim(_cLocCtr),TamSX3("ZC1_LOCCTR")[1]," ")

DBSELECTAREA("ZC1")
ZC1->(DBSETORDER(1))
IF ZC1->(DBSEEK(XFILIAL("ZC1") + _cContrato + _cLocCtr ))

	DBSELECTAREA("ZC0")
	ZC0->(DBSETORDER(1))
	ZC0->(DbSeek(xFilial("ZC0")+ZC1->ZC1_CODIGO))

	cTZC4:= GetNextAlias()

	BeginSql Alias cTZC4
		SELECT ZC4_MAIREP FROM %TABLE:ZC4% ZC4 
		WHERE ZC4_FILIAL=%xfilial:ZC4%
		AND ZC4_IDCONT=%EXP:_cContrato%
		AND ZC4_STATUS='1'
		AND ZC4.D_E_L_E_T_ =''	
	EndSql
	
	cEmail := (cTZC4)->ZC4_MAIREP

	(cTZC4)->(dbCloseArea())
	
	cTSA1:= GetNextAlias()
	
	IF !EMPTY(ZC1->ZC1_CMUNLO)
		BeginSql Alias cTSA1
			SELECT * FROM %TABLE:SA1% SA1 
			WHERE A1_FILIAL=%xfilial:SA1%
			AND A1_CGC=%EXP:ZC1->ZC1_DOCLOC%
			AND A1_COD_MUN=%EXP:ZC1->ZC1_CMUNLO%
			AND A1_MSBLQL<>'1'
			AND SA1.D_E_L_E_T_ =''	
		EndSql
	ELSE
		BeginSql Alias cTSA1
			SELECT * FROM %TABLE:SA1% SA1 
			WHERE A1_FILIAL=%xfilial:SA1%
			AND A1_CGC=%EXP:ZC1->ZC1_DOCLOC%
			AND A1_MSBLQL<>'1'
			AND SA1.D_E_L_E_T_ =''	
		EndSql
	ENDIF				
	
	//aRet:= GETLastQuery()
	                           	
	IF (cTSA1)->(!EOF())
		nAuto:= 4		
		AADD(aCliFat,(cTSA1)->A1_COD)
		AADD(aCliFat,(cTSA1)->A1_LOJA)	
		AADD(aCliFat,(cTSA1)->A1_EST)	
		AADD(aCliFat,(cTSA1)->A1_COD_MUN)			
		lGrava:= ZC1->ZC1_STATUS == "1" // Atualiza se o status for alterado para pendente
	ELSE
		nAuto:= 3
		AADD(aCliFat,"")
		AADD(aCliFat,"")
		AADD(aCliFat,"")
		AADD(aCliFat,"")			
	ENDIF
	
	(cTSA1)->(dbCloseArea())	
	
	IF lGrava
		
		IF nAuto == 4
			aAdd( aCli, {"A1_COD" , aCliFat[1] , NIL } )
			aAdd( aCli, {"A1_LOJA", aCliFat[2] , NIL } )	
		endif
		
		aAdd(aCli,{"A1_PESSOA" , IF(LEN(TRIM(ZC1->ZC1_DOCLOC))== 11 ,"F","J")              , NIL })
		aAdd(aCli,{"A1_NOME"   , IIF(EMPTY(ZC1->ZC1_RAZSOC),"ND KAIROS",ZC1->ZC1_RAZSOC)   , NIL })
		aAdd(aCli,{"A1_NREDUZ" , IIF(EMPTY(ZC1->ZC1_NOMFAN),"ND KAIROS",ZC1->ZC1_NOMFAN)   , NIL })
		aAdd(aCli,{"A1_TIPO"   , "F"			                                           , NIL })
		aAdd(aCli,{"A1_CGC"    , ZC1->ZC1_DOCLOC                                           , NIL })
		aAdd(aCli,{"A1_END"    , AllTrim(ZC1->ZC1_ENDLOC) + "," + AllTrim(ZC1->ZC1_NUMLOC) , NIL })
		aAdd(aCli,{"A1_EST"    , ZC1->ZC1_ESTLOC                                           , NIL })
		aAdd(aCli,{"A1_COD_MUN", ZC1->ZC1_CMUNLO                                           , NIL })	
		aAdd(aCli,{"A1_MUN"	   , ZC1->ZC1_CIDLOC                                           , NIL })
		aAdd(aCli,{"A1_COMPLEN", ZC1->ZC1_COMLOC                                           , NIL })	
		aAdd(aCli,{"A1_BAIRRO" , ZC1->ZC1_BAILOC                                           , NIL })
		aAdd(aCli,{"A1_CEP"    , ZC1->ZC1_CEPLOC                                           , NIL })
		aAdd(aCli,{"A1_NATUREZ", cNatCLI 		                                           , NIL })
		aAdd(aCli,{"A1_XCONTRA", ZC1->ZC1_CODIGO                                           , NIL })
		aAdd(aCli,{"A1_XLOCCTR", ZC1->ZC1_LOCCTR                                           , NIL })
		aAdd(aCli,{"A1_BLEMAIL", "1" 			                                           , NIL }) //Tratamento para envio do detalhe tipo 2 do cnab
		aAdd(aCli,{"A1_EMAIL"  , cEmail			                                           , NIL })
		aAdd(aCli,{"A1_XTPCLI" , "1"			                                           , NIL })
		
		IF !EMPTY(ZC1->ZC1_INSEST)
			aAdd(aCli,{"A1_INSCR"    , ZC1->ZC1_INSEST , NIL })
		ENDIF	
		
		IF !EMPTY(ZC1->ZC1_INSMUN)
			aAdd(aCli,{"A1_INSCRM"   , ZC1->ZC1_INSMUN , NIL })
		ENDIF
		
		if cCnpjBB$ZC1->ZC1_DOCLOC
			aAdd(aCli,{"A1_XTPEMPR", "4", NIL }) //Banco do Brasil
		elseif cCnpjCX$ZC1->ZC1_DOCLOC
			aAdd(aCli,{"A1_XTPEMPR", "5", NIL }) //Caixa		
		elseif ZC0->ZC0_TIPEMP=="2"
			aAdd(aCli,{"A1_XTPEMPR", "3", NIL }) //Publica
		elseif ZC0->ZC0_TIPEMP=="1" 
			aAdd(aCli,{"A1_XTPEMPR", "1", NIL }) //Privada
		elseif ZC0->ZC0_TIPEMP=="3"
			aAdd(aCli,{"A1_XTPEMPR", "2", NIL }) //Mista
		endif			
		
		MSExecAuto( { | x, y | Mata030( x, y ) }, aCli, nAuto)
		
		If lMsErroAuto
			
			lRet:= .F.
			
			If (__lSX8)
				RollBackSX8()
			EndIf     
			
			cMsgLog:= U_CAJERRO(GetAutoGRLog(),.T.)	
			
			RECLOCK("ZC1",.F.)
			ZC1->ZC1_STATUS	:= "3"
			ZC1->ZC1_MSGLOG	:= "Erro na integração do cliente"
			ZC1->ZC1_LOGCOM := cMsgLog
			ZC1->(MSUNLOCK())				

			aLogCli:= {"3","Erro na integração do cliente",cMsgLog}
										
		Else	
		
			aCliFat[1]:= SA1->A1_COD
			aCliFat[2]:= SA1->A1_LOJA
			aCliFat[3]:= SA1->A1_EST
			aCliFat[4]:= SA1->A1_COD_MUN
					
			If (__lSX8)
				ConfirmSX8()
			EndIf	

			RECLOCK("ZC1",.F.)
			ZC1->ZC1_STATUS	:= "2"
			ZC1->ZC1_MSGLOG	:= "Integração realizada com sucesso"
			ZC1->ZC1_LOGCOM := ""
			ZC1->(MSUNLOCK())				
				
		EndIf
	EndIf
ELSE
	lRet:= .F.
	aLogCli:= {"3","Erro na integração do cliente","Contrato/local: "+ TRIM(ZC5->ZC5_IDCONT) +" / "+ TRIM(ZC5->ZC5_LOCCON) + " não localizado!"}
ENDIF

CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJBKCLI] Fim integração clientes.")

RETURN lRet

/*/{Protheus.doc} CJBKFOR
Rotina de geração de fornecedores de acordo com contrato e local de contrato
@author carlos.henrique
@since 31/05/2019
@version undefined
@type function
/*/
USER FUNCTION CJBKFOR(aFornec, _cContrato, _cLocCtr, aLogFor)
Local cNatFOR:= SuperGetMV("CI_NATFOR",.T.,"99999999")
Local cCnpjBB:= ALLTRIM(SuperGetMV("CI_CNPJBB",.T.,"")) //Cnpj base da banco do brasil
Local cCnpjCX:= ALLTRIM(SuperGetMV("CI_CNPJCX",.T.,"")) //Cnpj base da caixa
Local cTSA2	 := ""
Local cTZC4	 := ""
Local aSA2	 := {}
Local nAuto	 := 0
Local lRet	 := .T.
Local lGrava := .T.
Local cEmail := ""
Private lMsHelpAuto 	:= .T.
Private lMsErroAuto 	:= .F.
Private lAutoErrNoFile	:= .T. 

CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJBKFOR] Iniciando integração fornecedores.")

aFornec:= {}
aLogFor:= {"","",""}

DBSELECTAREA("ZC1")
ZC1->(DBSETORDER(1))
IF ZC1->(DBSEEK(XFILIAL("ZC1") + _cContrato + _cLocCtr ))

	DBSELECTAREA("ZC0")
	ZC0->(DBSETORDER(1))
	ZC0->(DbSeek(xFilial("ZC0")+ZC1->ZC1_CODIGO))

	cTZC4:= GetNextAlias()

	BeginSql Alias cTZC4
		SELECT ZC4_MAIREP FROM %TABLE:ZC4% ZC4 
		WHERE ZC4_FILIAL=%xfilial:ZC4%
		AND ZC4_IDCONT=%EXP:_cContrato%
		AND ZC4_STATUS='1'
		AND ZC4.D_E_L_E_T_ =''	
	EndSql
	
	cEmail := (cTZC4)->ZC4_MAIREP

	(cTZC4)->(dbCloseArea())
	
	cTSA2:= GetNextAlias()
	
	IF !EMPTY(ZC1->ZC1_CMUNLO)
		BeginSql Alias cTSA2
			SELECT * FROM %TABLE:SA2% SA2 
			WHERE A2_FILIAL=%xfilial:SA2%
			AND A2_CGC=%EXP:ZC1->ZC1_DOCLOC%
			AND A2_COD_MUN=%EXP:ZC1->ZC1_CMUNLO%
			AND SA2.D_E_L_E_T_ =''	
		EndSql
	ELSE
		BeginSql Alias cTSA2
			SELECT * FROM %TABLE:SA2% SA2 
			WHERE A2_FILIAL=%xfilial:SA2%
			AND A2_CGC=%EXP:ZC1->ZC1_DOCLOC%
			AND SA2.D_E_L_E_T_ =''	
		EndSql
	ENDIF				
	
	//aRet:= GETLastQuery()
	                           	
	IF (cTSA2)->(!EOF())
		nAuto:= 4		
		AADD(aFornec,(cTSA2)->A2_COD)
		AADD(aFornec,(cTSA2)->A2_LOJA)	
		AADD(aFornec,(cTSA2)->A2_EST)	
		AADD(aFornec,(cTSA2)->A2_COD_MUN)			
		lGrava:= ZC1->ZC1_STATUS == "1" // Atualiza se o status for alterado para pendente
	ELSE
		nAuto:= 3
		AADD(aFornec,"")
		AADD(aFornec,"")
		AADD(aFornec,"")
		AADD(aFornec,"")			
	ENDIF
	
	(cTSA2)->(dbCloseArea())	
	
	IF lGrava
		
		IF nAuto == 4
			aAdd( aSA2, {"A2_COD" , aFornec[1] , NIL } )
			aAdd( aSA2, {"A2_LOJA", aFornec[2] , NIL } )	
		endif
		
		aAdd(aSA2,{"A2_PESSOA" , IF(LEN(TRIM(ZC1->ZC1_DOCLOC))== 11 ,"F","J") , NIL })
		aAdd(aSA2,{"A2_NOME"   , ZC1->ZC1_RAZSOC , NIL })
		aAdd(aSA2,{"A2_NREDUZ" , ZC1->ZC1_NOMFAN , NIL })
		aAdd(aSA2,{"A2_TIPO"   , "F"			 , NIL })
		aAdd(aSA2,{"A2_CGC"    , ZC1->ZC1_DOCLOC , NIL })
		aAdd(aSA2,{"A2_END"    , ZC1->ZC1_ENDLOC , NIL })
		aAdd(aSA2,{"A2_EST"    , ZC1->ZC1_ESTLOC , NIL })
		aAdd(aSA2,{"A2_COD_MUN", ZC1->ZC1_CMUNLO , NIL })	
		aAdd(aSA2,{"A2_MUN"	   , ZC1->ZC1_CIDLOC , NIL })
		aAdd(aSA2,{"A2_COMPLEN", ZC1->ZC1_COMLOC , NIL })	
		aAdd(aSA2,{"A2_BAIRRO" , ZC1->ZC1_BAILOC , NIL })
		aAdd(aSA2,{"A2_CEP"    , ZC1->ZC1_CEPLOC , NIL })
		aAdd(aSA2,{"A2_NATUREZ", cNatFOR 		 , NIL })
		aAdd(aSA2,{"A2_XCONTRA", ZC1->ZC1_CODIGO , NIL })
		aAdd(aSA2,{"A2_XLOCCTR", ZC1->ZC1_LOCCTR , NIL })
		aAdd(aSA2,{"A2_EMAIL"  , cEmail			 , NIL })	

		if cCnpjBB$ZC1->ZC1_DOCLOC
			aAdd(aSA2,{"A2_XTPEMPR", "4", NIL }) //Banco do Brasil
		elseif cCnpjCX$ZC1->ZC1_DOCLOC
			aAdd(aSA2,{"A2_XTPEMPR", "5", NIL }) //Caixa		
		elseif ZC0->ZC0_TIPEMP=="2"
			aAdd(aSA2,{"A2_XTPEMPR", "3", NIL }) //Publica
		elseif ZC0->ZC0_TIPEMP=="1" 
			aAdd(aSA2,{"A2_XTPEMPR", "1", NIL }) //Privada
		elseif ZC0->ZC0_TIPEMP=="3"
			aAdd(aSA2,{"A2_XTPEMPR", "2", NIL }) //Mista
		endif		
		
		IF !EMPTY(ZC1->ZC1_INSEST)
			aAdd(aSA2,{"A2_INSCR"    , ZC1->ZC1_INSEST , NIL })
		ENDIF	
		
		IF !EMPTY(ZC1->ZC1_INSMUN)
			aAdd(aSA2,{"A2_INSCRM"   , ZC1->ZC1_INSMUN , NIL })
		ENDIF
		
		aAdd(aSA2,{"A2_XTPCLI"    , "1" , NIL })			

		MSExecAuto({|x, y| MATA020(x, y)},aSA2, nAuto)
		
		If lMsErroAuto
			
			lRet:= .F.
			
			If (__lSX8)
				RollBackSX8()
			EndIf     
			
			cMsgLog:= U_CAJERRO(GetAutoGRLog(),.T.)	
			
			RECLOCK("ZC1",.F.)
			ZC1->ZC1_STATUS	:= "3"
			ZC1->ZC1_MSGLOG	:= "Erro na integração do fornecedor"
			ZC1->ZC1_LOGCOM := cMsgLog
			ZC1->(MSUNLOCK())				

			aLogFor:= {"3","Erro na integração do fornecedor",cMsgLog}
										
		Else	
		
			aFornec[1]:= SA2->A2_COD
			aFornec[2]:= SA2->A2_LOJA
			aFornec[3]:= SA2->A2_EST
			aFornec[4]:= SA2->A2_COD_MUN
					
			If (__lSX8)
				ConfirmSX8()
			EndIf	

			RECLOCK("ZC1",.F.)
			ZC1->ZC1_STATUS	:= "2"
			ZC1->ZC1_MSGLOG	:= "Integração realizada com sucesso"
			ZC1->ZC1_LOGCOM := ""
			ZC1->(MSUNLOCK())				
				
		EndIf
	EndIf
ELSE
	lRet:= .F.
	aLogFor:= {"3","Erro na integração do fornecedor","Contrato/local: "+ TRIM(ZC5->ZC5_IDCONT) +" / "+ TRIM(ZC5->ZC5_LOCCON) + " não localizado!"}
ENDIF

CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJBKFOR] Fim integração fornecedores.")

RETURN lRet

/*/{Protheus.doc} CAJERRO
Tratamento da mensagem de erro
@author carlos.henrique
@since 01/01/2015
@version undefined
@param aBlocoMsg, array, descricao
@type function
/*/
User Function CAJERRO(aBlocoMsg,lCompleto)
Local lHelp   := .F.
Local lTabela := .F.
Local lLinInv := .F.
Local lLinItem:= .F.
Local cLinha  := ""
Local aRet    := {}
Local cRet    := ""
Local nI      := 0
local nTotLin	:= LEN(aBlocoMsg)
default lCompleto:= .F.

IF lCompleto

	For nI:= 1 to nTotLin
		cRet+= aBlocoMsg[nI]+CRLF
	Next

ELSE

	IF nTotLin <= 10
		For nI := 1 to nTotLin
			cLinha  := UPPER( aBlocoMsg[nI] )
			
			If '<'$cLinha
				cLinha:= StrTran(cLinha,'<','(')
			EndIf
	
			If '>'$cLinha
				cLinha:= StrTran(cLinha,'>',')')
			EndIf
			
			If '&'$cLinha
				cLinha:= StrTran(cLinha,'&',' ')
			EndIf						
			
			aAdd(aRet,cLinha)
		Next
	ELSE
		For nI := 1 to nTotLin
			cLinha  := UPPER( aBlocoMsg[nI] )    
			cLinha  := STRTRAN( cLinha,CHR(13), " " )
			cLinha  := STRTRAN( cLinha,CHR(10), " " )  
			
			lHelp   	:= .F.
			lTabela 	:= .F.
			lLinInv	:= .F.
			lLinItem	:= .F.
				
			If SUBS(cLinha,1,4) == 'HELP' .OR. SUBS(cLinha,1,5) == "AJUDA"
				lHelp := .T.
			EndIf
			
			If SUBS( cLinha, 1, 6 ) == 'TABELA'
				lTabela := .T.
			EndIf
		
			If '< -- INVALIDO'$cLinha
				cLinha:= StrTran(cLinha,'< -- INVALIDO','( INVALIDO )')
				lLinInv	:= .T.
			EndIf          
			
			If 'ERRO NO ITEM'$cLinha
				lLinItem:= .T.
			EndIf
				
			If  lHelp .or. lTabela .or. lLinInv .or. lLinItem
				
				If '<'$cLinha
					cLinha:= StrTran(cLinha,'<','(')
				EndIf
		
				If '>'$cLinha
					cLinha:= StrTran(cLinha,'>',')')
				EndIf
				
				If '&'$cLinha
					cLinha:= StrTran(cLinha,'&',' ')
				EndIf						
					
				aAdd(aRet,cLinha)
			EndIf                   
		Next
	ENDIF
	
	For nI := 1 to Len(aRet)
		cRet += aRet[nI]+CRLF
	Next
	
ENDIF

Return cRet 

/*/{Protheus.doc} CICOBDW3
Gera fila de integração com DW3
@author carlos.henrique
@since 17/01/2020
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User Function CICOBDW3(cOcorre,cSituacao,lRetNF)
Local cJson:= ""
Local cZc6 := ""
Local cLink:= ""
Local cIdLog:= ""
Local aIdsCont:= {}
Local aIdsLoc:= {}
Local aIdsCfgC:= {}
Local aIdsCfgF:= {}
local cNossoNum := ""

DBSELECTAREA("ZC5")
ZC5->(DbOrderNickName("IDFATURAME"))
IF ZC5->(DBSEEK(SE1->E1_XIDFATU))

	cLink:= ""

	IF !EMPTY(ZC5->ZC5_NFELET) .AND. !EMPTY(ZC5->ZC5_CODNFE)

		cLink:= GetMv("CI_URLNFSE")

		if CEMPANT == "03"  // Empresa Rio de Janeiro

			if ZC5->ZC5_FILIAL $ "0001|0004|0005|0006|"
				cLink := StrTran(cLink, "<%=ZC5_NFELET%>", AllTrim(ZC5->ZC5_NFELET))
				cLink := StrTran(cLink, "<%=M0_INSCM%>", AllTrim(SM0->M0_INSCM))
				cLink := StrTran(StrTran(cLink, "<%=ZC5_CODNFE%>" , AllTrim(ZC5->ZC5_CODNFE)),"-","")
			elseif ZC5->ZC5_FILIAL == "0012"
				cLink := StrTran(cLink, "<%=ZC5_CODNFE%>" , Encode64(AllTrim(ZC5->ZC5_CODNFE)))
			endif
			
		else // Empresa Sao Paulo

			if ZC5->ZC5_FILIAL == "0001"
				cLink := StrTran(cLink, "<%=M0_INSCM%>", AllTrim(SM0->M0_INSCM))
				cLink := StrTran(cLink, "<%=ZC5_NFELET%>", AllTrim(ZC5->ZC5_NFELET))
				cLink := StrTran(cLink, "<%=ZC5_CODNFE%>", AllTrim(ZC5->ZC5_CODNFE))
			elseif ZC5->ZC5_FILIAL == "0003"
				SA1->(DbSeek(xFilial("SA1")+(cAliasZC5)->CLIENTE+(cAliasZC5)->LOJA))
				cLink := StrTran(cLink, "<%=ZC5_CODNFE%>", AllTrim(ZC5->ZC5_CODNFE))
				cLink := StrTran(cLink, "<%=A1_CGC%>", AllTrim(SA1->A1_CGC))
			elseif ZC5->ZC5_FILIAL == "0010"
				cLink := StrTran(cLink, "<%=ZC5_CODNFE%>", AllTrim(ZC5->ZC5_CODNFE))
				cLink := StrTran(cLink, "<%=ZC5_NFELET%>", AllTrim(ZC5->ZC5_NFELET))
			elseif ZC5->ZC5_FILIAL == "0013"
				cLink := StrTran(cLink, "<%=M0_CGC%>", AllTrim(SM0->M0_CGC))
				cLink := StrTran(cLink, "<%=ZC5_VALOR%>", AllTrim(Str((cAliasZC5)->VALOR,14,2)))
				cLink := StrTran(cLink, "<%=ZC5_NFELET%>", AllTrim(ZC5->ZC5_NFELET))
				cLink := StrTran(cLink, "<%=ZC5_CODNFE%>", AllTrim(ZC5->ZC5_CODNFE))
			elseif ZC5->ZC5_FILIAL $ "0012|0026|0060"
				cLink := StrTran(cLink, "<%=M0_CGC%>", AllTrim(SM0->M0_CGC))
				cLink := StrTran(cLink, "<%=ZC5_CODNFE%>", AllTrim(ZC5->ZC5_CODNFE))
				cLink := StrTran(cLink, "<%=ZC5_NFELET%>", AllTrim(ZC5->ZC5_NFELET))
			endif
		endif		
	
	ENDIF

	DBSELECTAREA("ZC6")

	cZc6 := GetNextAlias()
	
	BeginSql Alias cZc6
		SELECT ZC6.R_E_C_N_O_ AS RECZC6 
		FROM %TABLE:ZC6% ZC6
		WHERE ZC6_FILIAL=%Exp:ZC5->ZC5_FILIAL%
		AND ZC6_IDFATU=%Exp:ZC5->ZC5_IDFATU%
		AND ZC6.D_E_L_E_T_ =''
	EndSql
	
	//aRet:= GETLastQuery()[2]

	TCSETFIELD(cZc6,"E1_VENCREA","D")
	TCSETFIELD(cZc6,"E1_EMISSAO","D")
	
	(cZc6)->(dbSelectArea((cZc6)))
	(cZc6)->(dbGoTop())
	WHILE (cZc6)->(!EOF())

		ZC6->(dbGoto((cZc6)->RECZC6))
	
		IF ZC6->(!EOF())

			DBSELECTAREA("ZC0")
			ZC0->(DBSETORDER(1))
			ZC0->(DBSEEK(XFILIAL("ZC0")+ZC6->ZC6_IDCONT))

			DBSELECTAREA("ZC1")
			ZC1->(DBSETORDER(1))
			ZC1->(DBSEEK(XFILIAL("ZC1")+ZC6->ZC6_IDCONT+ZC6->ZC6_LOCCON))

			DBSELECTAREA("SB1")
			SB1->(DBSETORDER(1))
			SB1->(DBSEEK(XFILIAL("SB1")+ZC6->ZC6_PRODUT))			

			dbSelectArea("SEE")   // Tabela de Bancos 
			dbSetOrder(1)	
			SEE->(DbSeek(xfilial("SEE") + SE1->(E1_PORTADO+E1_AGEDEP+E1_CONTA))) 			
			
			IF lRetNF .AND.  SE1->E1_XINTDW3 != "S"
				
				cNossoNum:= ""

				IF !EMPTY(SE1->E1_NUMBCO)
					cNossoNum:= STRZERO(VAL(SE1->E1_NUMBCO),11) + "-" + U_MOD11("09"+STRZERO(VAL(SE1->E1_NUMBCO),11))
				ENDIF	
				
				cJson := '{'+CRLF
				cJson += '   "sintetico":{'+CRLF
				cJson += '      "idfatura": "' + EncodeUTF8(AllTrim(ZC5->ZC5_IDFATU), "cp1252") + '",'+CRLF
				cJson += '      "lote": "' + EncodeUTF8(AllTrim(ZC6->ZC6_LOTE), "cp1252") + '",'+CRLF
				cJson += '      "seqlote": ' + EncodeUTF8(AllTrim(ZC6->ZC6_SEQLOT), "cp1252") + ','+CRLF
				cJson += '      "processo": "' + EncodeUTF8(AllTrim(ZC6->ZC6_PROFAT), "cp1252") + '",'+CRLF
				cJson += '      "loterastreamento": "' + EncodeUTF8(AllTrim(ZC6->ZC6_LOTRAS), "cp1252") + '",'+CRLF
				cJson += '      "idcontrato": "' + EncodeUTF8(AllTrim(ZC6->ZC6_IDCONT), "cp1252") + '",'+CRLF
				cJson += '      "idlocalremessa": "' + EncodeUTF8(AllTrim(iif(empty(ZC6->ZC6_LOCREM),"",ZC6->ZC6_LOCREM)), "cp1252") + '",'+CRLF
				cJson += '      "documento": "' + EncodeUTF8(AllTrim(ZC1->ZC1_DOCLOC), "cp1252") + '",'+CRLF
				cJson += '      "razaosocial": "' + EncodeUTF8(AllTrim(ZC1->ZC1_RAZSOC), "cp1252") + '",'+CRLF
				cJson += '      "endereco":{'+CRLF
				cJson += '		   "cep": "' + EncodeUTF8(AllTrim(ZC1->ZC1_CEPLOC), "cp1252") + '",'+CRLF
				cJson += '		   "logradouro": "' + EncodeUTF8(AllTrim(ZC1->ZC1_LOGLOC), "cp1252") + '",'+CRLF
				cJson += '		   "endereco": "' + EncodeUTF8(AllTrim(ZC1->ZC1_ENDLOC), "cp1252") + '",'+CRLF
				cJson += '		   "numero": "' + EncodeUTF8(AllTrim(ZC1->ZC1_NUMLOC), "cp1252") + '",'+CRLF
				cJson += '		   "complemento": "' + EncodeUTF8(AllTrim(ZC1->ZC1_COMLOC), "cp1252") + '",'+CRLF
				cJson += '		   "bairro": "' + EncodeUTF8(AllTrim(ZC1->ZC1_BAILOC), "cp1252") + '",'+CRLF
				cJson += '		   "codigoibge": "' + EncodeUTF8(AllTrim(ZC1->ZC1_CMUNLO), "cp1252") + '",'+CRLF
				cJson += '		   "cidade": "' + EncodeUTF8(AllTrim(ZC1->ZC1_CIDLOC), "cp1252") + '",'+CRLF
				cJson += '		   "uf": "' + EncodeUTF8(AllTrim(ZC1->ZC1_ESTLOC), "cp1252") + '"'+CRLF
				cJson += '      },'+CRLF
				cJson += '      "idconfiguracaofaturamento": "' + EncodeUTF8(AllTrim(ZC6->ZC6_CONFAT), "cp1252") + '",'+CRLF
				cJson += '      "idfolha": ' + EncodeUTF8(AllTrim(iif(empty(ZC6->ZC6_IDFOLH),"null",ZC6->ZC6_IDFOLH)), "cp1252") + ','+CRLF
				cJson += '      "idconfiguracaocobranca": "' + EncodeUTF8(AllTrim(ZC6->ZC6_CONCOB), "cp1252") + '",'+CRLF
				cJson += '      "prefixotitulo": "' + EncodeUTF8(AllTrim(SE1->E1_PREFIXO), "cp1252") + '",'+CRLF
				cJson += '      "numerotitulo":"' + EncodeUTF8(AllTrim(SE1->E1_NUM), "cp1252") + '",'+CRLF
				cJson += '      "parcelatitulo":"' + EncodeUTF8(AllTrim(SE1->E1_PARCELA), "cp1252") + '",'+CRLF
				cJson += '      "tipotitulo":"' + EncodeUTF8(AllTrim(SE1->E1_TIPO), "cp1252") + '",'+CRLF
				cJson += '      "quantidade_tce_tca": "' + EncodeUTF8(AllTrim(Str(ZC6->ZC6_QTDE,14,2)), "cp1252") + '",'+CRLF
				cJson += '      "tpproduto": "' + EncodeUTF8(AllTrim(ZC6->ZC6_TIPPRO), "cp1252") + '",'+CRLF
				cJson += '      "datavencimento": "' + EncodeUTF8(AllTrim(DTOC(SE1->E1_VENCREA)), "cp1252") + '",'+CRLF
				cJson += '      "dataemissao":"' + EncodeUTF8(AllTrim(DTOC(SE1->E1_EMISSAO)), "cp1252") + '",'+CRLF
				cJson += '      "mensagemnota": "' + EncodeUTF8(AllTrim(ZC6->ZC6_MSGNOT), "cp1252") + '",'+CRLF
				cJson += '      "idrps":"' + EncodeUTF8(AllTrim(ZC5->ZC5_NOTA), "cp1252") + '",'  +CRLF
				cJson += '      "idnfe": ' + EncodeUTF8(AllTrim(iif(empty(ZC5->ZC5_CODNFE),"null",ZC5->ZC5_CODNFE)), "cp1252") + ','+CRLF

				if !empty(cLink)
					cJson += '      "urlnota":"' + EncodeUTF8(AllTrim(cLink), "cp1252") + '",'+CRLF
					cJson += '      "dataemissaonfe":"' + EncodeUTF8(AllTrim(DTOC(ZC5->ZC5_DATA)), "cp1252") + '",'+CRLF
					cJson += '      "horaemissaonfe":"' + EncodeUTF8(AllTrim(ZC5->ZC5_HORFIM), "cp1252") + '",'+CRLF
				else
					cJson += '      "urlnota":"",'+CRLF
					cJson += '      "dataemissaonfe":"",'+CRLF
					cJson += '      "horaemissaonfe":"",'+CRLF
				endif

				cJson += '      "codigoautorizacaonfe": ' + EncodeUTF8(AllTrim(iif(empty(ZC5->ZC5_NFELET),"null",ZC5->ZC5_NFELET)), "cp1252") + ','+CRLF
				cJson += '      "datacancelamentonfe":"' + EncodeUTF8(AllTrim(DTOC(ZC5->ZC5_DTCANC)), "cp1252") + '",'+CRLF
				cJson += '      "motivocancelamento":"' + EncodeUTF8(AllTrim(ZC5->ZC5_DESMOT), "cp1252") + '",'+CRLF
				cJson += '      "banco": "' + EncodeUTF8(AllTrim(SEE->EE_CODIGO ), "cp1252") + '",'+CRLF
				cJson += '      "codigocarteirabanco": "' + EncodeUTF8(AllTrim(SEE->EE_CODCART), "cp1252") + '",'+CRLF
				cJson += '      "nossonumero": "' + EncodeUTF8(AllTrim(cNossoNum), "cp1252") + '",'+CRLF
				cJson += '      "seunumero": "' + EncodeUTF8(AllTrim(SE1->E1_IDCNAB), "cp1252") + '",'+CRLF
				cJson += '      "codigoconveniobanco": "' + EncodeUTF8(AllTrim(SEE->EE_NUMCTR), "cp1252") + '",'+CRLF
				cJson += '      "valorcobranca": ' + EncodeUTF8(AllTrim(Str(SE1->E1_VALOR,14,2)), "cp1252") + ','+CRLF
	//			cJson += '      "valormulta": ' + EncodeUTF8(AllTrim(Str(SE1->E1_MULTA,14,2)), "cp1252") + ','+CRLF
	//			cJson += '      "valorjuros": ' + EncodeUTF8(AllTrim(Str(SE1->E1_JUROS,14,2)), "cp1252") + ','+CRLF
				cJson += '      "valormulta": ' + EncodeUTF8(AllTrim(Str(GetMV("CI_TXMULTA",.T.,2.0),6,2)), "cp1252") + ','+CRLF
				cJson += '      "valorjuros": ' + EncodeUTF8(AllTrim(Str((SE1->E1_VALOR*(GetMV("MV_TXPER",.T.,1.0)/100)/30)*100,14,2)), "cp1252" ) + ','+CRLF
				cJson += '      "tipodesconto":"1",'+CRLF
				cJson += '      "valordesconto":0,'+CRLF
				cJson += '      "datalimitedesconto":"",'+CRLF
				cJson += '      "valorabatimento": ' + EncodeUTF8(AllTrim(Str(SE1->E1_DECRESC,14,2)), "cp1252") + ','+CRLF
				cJson += '      "quantidadediasbaixa":0,'+CRLF
				cJson += '      "situacao": ' + iif(!Empty(cSituacao),'"'+ cSituacao + '"',"null") + ','+CRLF
				cJson += '      "ocorrencia": ' + iif(!Empty(cOcorre),'"'+ cOcorre + '"',"null") + ','+CRLF			
				cJson += '      "analitico":['+CRLF
				cJson += '         {'+CRLF
				cJson += '      	  "id": ' + EncodeUTF8(AllTrim(iif(empty(ZC6->ZC6_IDESTU),"null",ZC6->ZC6_IDESTU)), "cp1252") + ','+CRLF
				cJson += '            "cpf": "' + EncodeUTF8(AllTrim(ZC6->ZC6_CPFEST), "cp1252") + '",'+CRLF
				cJson += '            "nome": "' + EncodeUTF8(AllTrim(ZC6->ZC6_NOMEST), "cp1252") + '",'+CRLF
				cJson += '            "nomesocial": "' + EncodeUTF8(AllTrim(ZC6->ZC6_NOMSOC), "cp1252") + '",'+CRLF
				cJson += '            "competencia": "' + EncodeUTF8(AllTrim(ZC6->ZC6_COMPET), "cp1252") + '",'+CRLF
				cJson += '            "codigo_tce_tca": "' + EncodeUTF8(AllTrim(ZC6->ZC6_TCETCA), "cp1252") + '",'+CRLF
				cJson += '            "idlocalcontrato": "' + EncodeUTF8(AllTrim(ZC6->ZC6_LOCCON), "cp1252") + '",'+CRLF
				cJson += '            "tipo_faturamento": "' + EncodeUTF8(AllTrim(ZC6->ZC6_TIPFAT), "cp1252") + '",'+CRLF
				cJson += '            "valor": ' + EncodeUTF8(AllTrim(Str(ZC6->ZC6_VALOR,14,2)), "cp1252") + ','+CRLF
				cJson += '            "produto": "' + EncodeUTF8(AllTrim(ZC6->ZC6_PRODUT), "cp1252") + '",'+CRLF
				cJson += '            "descricao": "' + EncodeUTF8(AllTrim(SB1->B1_DESC), "cp1252") + '",'+CRLF
				cJson += '            "quantidade": ' + EncodeUTF8(AllTrim(Str(ZC6->ZC6_QTDE,14,2)), "cp1252") + ','+CRLF

				IF !EMPTY(SB1->B1_XTIPSER)
					aSubTip:= FWGetSX5("_T", AllTrim(SB1->B1_XTIPSER))
					IF !EMPTY(aSubTip)
						cJson += '            "subtipo": "' + EncodeUTF8(AllTrim( aSubTip[1][4] ), "cp1252") + '"'+CRLF
					ELSE
						cJson += '            "subtipo": ""'+CRLF
					ENDIF
				ELSE
					cJson += '            "subtipo": ""'+CRLF
				ENDIF	

				cJson += '         }'+CRLF
				cJson += '      ]'+CRLF
				cJson += '   }'+CRLF
				cJson += '}'+CRLF			

				RECLOCK("ZCS",.T.)
					cIdLog:= "FT" + CVALTOCHAR(ZCS->(RECNO()))
					ZCS->ZCS_FILIAL:= XFILIAL("ZCQ")
					ZCS->ZCS_TIPENV:= "COBRANCA_DW3" 
					ZCS->ZCS_OPEENV:= "1" //POST
					ZCS->ZCS_IDENTI:= ZC5->ZC5_IDFATU
					ZCS->ZCS_URL   := ""
					ZCS->ZCS_IDLOG := cIdLog
					ZCS->ZCS_DTINTE:= DATE()
					ZCS->ZCS_HRINTE:= TIME()
					ZCS->ZCS_STATUS:= "0"
					ZCS->ZCS_FILA  := ALLTRIM(GetMV("CI_FCOBDW3",.T.,"dev1-integracao-cobranca-dw3"))
					ZCS->ZCS_CODE  := "" 
					ZCS->ZCS_JSON  := cJson
				MSUNLOCK()  			
				
				Exit

			Else

				//Gera fila do contrato de serviços diversos
				IF LEFT(SE1->E1_XIDFATU,2) == "SD" .AND. LEFT(SE1->E1_XIDCNT,2) == "SD"
					IF ASCAN(aIdsCont,{|x| x==SE1->E1_XIDCNT }) == 0

						AADD(aIdsCont,SE1->E1_XIDCNT)

						cJson := '{'+CRLF
						cJson += '	"EMPRESA": {'+CRLF
						cJson += '		"idContrato": "' + EncodeUTF8(AllTrim(ZC0->ZC0_CODIGO), "cp1252") + '",'+CRLF
						cJson += '      "tipoContrato": "' + EncodeUTF8(AllTrim(ZC0->ZC0_TIPCON), "cp1252") + '",'+CRLF
						cJson += '		"tipoAprendiz": "' + EncodeUTF8(AllTrim(ZC0->ZC0_TIPAPR), "cp1252") + '",'+CRLF
						cJson += '		"programaAprendizagem": "' + EncodeUTF8(AllTrim(ZC0->ZC0_PRGAPE), "cp1252") + '",'+CRLF
						cJson += '		"tipoEmpresa": "' + EncodeUTF8(AllTrim(ZC0->ZC0_TIPEMP), "cp1252") + '",'+CRLF
						cJson += '		"razaoSocial": "' + EncodeUTF8(AllTrim(ZC0->ZC0_NOME), "cp1252") + '",'+CRLF
						cJson += '		"nomeFantasia": "' + EncodeUTF8(AllTrim(ZC0->ZC0_NREDUZ), "cp1252") + '",'+CRLF
						cJson += '		"documento": "' + EncodeUTF8(AllTrim(ZC0->ZC0_NUMDOC), "cp1252") + '",'+CRLF
						cJson += '		"sitcontrato": "' + EncodeUTF8(AllTrim(ZC0->ZC0_STCONV), "cp1252") + '",'+CRLF
						cJson += '		"sitempresa": "' + EncodeUTF8(AllTrim(ZC0->ZC0_STEMPR), "cp1252") + '",'+CRLF
						cJson += '		"formaPagamento": "' + EncodeUTF8(AllTrim(ZC0->ZC0_TIPCON), "cp1252") + '",'+CRLF
						cJson += '		"ENDERECO": {'+CRLF
						cJson += '			"cep": "' + EncodeUTF8(AllTrim(ZC0->ZC0_CEPEMP), "cp1252") + '",'+CRLF
						cJson += '			"logradouro": "' + EncodeUTF8(AllTrim(ZC0->ZC0_LOGEMP), "cp1252") + '",'+CRLF
						cJson += '			"endereco": "' + EncodeUTF8(AllTrim(ZC0->ZC0_ENDEMP), "cp1252") + '",'+CRLF
						cJson += '			"numero": "' + EncodeUTF8(AllTrim(ZC0->ZC0_NUMEMP), "cp1252") + '",'+CRLF
						cJson += '			"complemento": "' + EncodeUTF8(AllTrim(ZC0->ZC0_COMEMP), "cp1252") + '",'+CRLF
						cJson += '			"bairro": "' + EncodeUTF8(AllTrim(ZC0->ZC0_BAIEMP), "cp1252") + '",'+CRLF
						cJson += '			"codigoMunicipioIBGE": "' + EncodeUTF8(AllTrim(ZC0->ZC0_CMUNEM), "cp1252") + '",'+CRLF
						cJson += '			"cidade": "' + EncodeUTF8(AllTrim(ZC0->ZC0_CIDEMP), "cp1252") + '",'+CRLF
						cJson += '			"uf": "' + EncodeUTF8(AllTrim(ZC0->ZC0_ESTEMP), "cp1252") + '"'+CRLF
						cJson += '		},'+CRLF
						cJson += '		"CONSULTOR": {'+CRLF
						cJson += '			"id": "' + EncodeUTF8(AllTrim(ZC1->ZC1_IDCOEN), "cp1252") + '",'+CRLF
						cJson += '			"nome": "' + EncodeUTF8(AllTrim(ZC1->ZC1_NOCOEN), "cp1252") + '",'+CRLF
						cJson += '			"idCarteira": "' + EncodeUTF8(AllTrim(ZC1->ZC1_CACOEN), "cp1252") + '",'+CRLF
						cJson += '			"dsCarteira": "' + EncodeUTF8(AllTrim(ZC1->ZC1_DECOEN), "cp1252") + '"'+CRLF
						cJson += '		},'+CRLF

						IF !EMPTY(ZC0->ZC0_REPR)
							oRepres:= JsonObject():new()
							oRepres:fromJson(AllTrim(ZC0->ZC0_REPR))
							cRepres:= oRepres:TOJSON()
							cRepres:= RIGHT(cRepres,LEN(cRepres)-1)
							cRepres:= LEFT(cRepres,LEN(cRepres)-1)
							cJson += cRepres+","
						ELSE
							cRepres:= ' "representantes":['
							cRepres+= ' ]'
							cJson += cRepres+","					
						ENDIF

						IF !EMPTY(ZC0->ZC0_CONTAT)
							oContat:= JsonObject():new()
							oContat:fromJson(AllTrim(ZC0->ZC0_CONTAT))
							cContat:= oContat:TOJSON()
							cContat:= RIGHT(cContat,LEN(cContat)-1)
							cContat:= LEFT(cContat,LEN(cContat)-1)
							cJson += cContat
						ELSE
							cContato:= ' "contatos":['
							cContato+= ' ]'
							cJson += cContato
						ENDIF						

						cJson += '	}'
						cJson += '}'

						RECLOCK("ZCS",.T.)
							cIdLog:= "CT" + CVALTOCHAR(ZCS->(RECNO()))
							ZCS->ZCS_FILIAL:= XFILIAL("ZCQ")
							ZCS->ZCS_TIPENV:= "CONTRATO" 
							ZCS->ZCS_OPEENV:= "1" //POST
							ZCS->ZCS_IDENTI:= ZC0->ZC0_CODIGO
							ZCS->ZCS_URL   := ""
							ZCS->ZCS_IDLOG := cIdLog
							ZCS->ZCS_DTINTE:= DATE()
							ZCS->ZCS_HRINTE:= TIME()
							ZCS->ZCS_STATUS:= "0"
							ZCS->ZCS_FILA  := ALLTRIM(GetMV("CI_FCTDW3",.T.,"dev-integracao-contrato-dw3"))
							ZCS->ZCS_CODE  := "" 
							ZCS->ZCS_JSON  := cJson
						MSUNLOCK()   					
					
					ENDIF				
				ENDIF

				//Gera fila do local do contrato de serviços diversos
				IF LEFT(SE1->E1_XIDFATU,2) == "SD" .AND. LEFT(SE1->E1_XIDLOC,2) == "SD"
					IF ASCAN(aIdsLoc,{|x| x==SE1->E1_XIDLOC }) == 0

						AADD(aIdsLoc,SE1->E1_XIDLOC)

						cJson := '{'+CRLF
						cJson += '	"LOCALCONTRATO": {'+CRLF
						cJson += '		"id": "' + EncodeUTF8(AllTrim(ZC1->ZC1_LOCCTR), "cp1252") + '",'+CRLF
						cJson += '		"razaoSocial": "' + EncodeUTF8(AllTrim(ZC1->ZC1_RAZSOC), "cp1252") + '",'+CRLF
						cJson += '		"nomeFantasia": "' + EncodeUTF8(AllTrim(ZC1->ZC1_NOMFAN), "cp1252") + '",'+CRLF
						cJson += '		"documento": "' + EncodeUTF8(AllTrim(ZC1->ZC1_DOCLOC), "cp1252") + '",'+CRLF
						cJson += '		"inscricaoEstadual": "' + EncodeUTF8(AllTrim(ZC1->ZC1_INSEST), "cp1252") + '",'+CRLF
						cJson += '		"inscricaoMunicipal": "' + EncodeUTF8(AllTrim(ZC1->ZC1_INSMUN), "cp1252") + '",'+CRLF
						cJson += '		"ENDERECO": {'+CRLF
						cJson += '			"cep": "' + EncodeUTF8(AllTrim(ZC1->ZC1_CEPLOC), "cp1252") + '",'+CRLF
						cJson += '			"logradouro": "' + EncodeUTF8(AllTrim(ZC1->ZC1_LOGLOC), "cp1252") + '",'+CRLF
						cJson += '			"endereco": "' + EncodeUTF8(AllTrim(ZC1->ZC1_ENDLOC), "cp1252") + '",'+CRLF
						cJson += '			"numero": "' + EncodeUTF8(AllTrim(ZC1->ZC1_NUMLOC), "cp1252") + '",'+CRLF
						cJson += '			"complemento": "' + EncodeUTF8(AllTrim(ZC1->ZC1_COMLOC), "cp1252") + '",'+CRLF
						cJson += '			"bairro": "' + EncodeUTF8(AllTrim(ZC1->ZC1_BAILOC), "cp1252") + '",'+CRLF
						cJson += '			"codigoMunicipioIBGE": "' + EncodeUTF8(AllTrim(ZC1->ZC1_CMUNLO), "cp1252") + '",'+CRLF
						cJson += '			"cidade": "' + EncodeUTF8(AllTrim(ZC1->ZC1_CIDLOC), "cp1252") + '",'+CRLF
						cJson += '			"uf": "' + EncodeUTF8(AllTrim(ZC1->ZC1_ESTLOC), "cp1252") + '"'+CRLF
						cJson += '		},'+CRLF
						cJson += '		"CONSULTOR": {'+CRLF
						cJson += '			"id": "' + EncodeUTF8(AllTrim(ZC1->ZC1_IDCOLO), "cp1252") + '",'+CRLF
						cJson += '			"nome": "' + EncodeUTF8(AllTrim(ZC1->ZC1_NOCOLO), "cp1252") + '",'+CRLF
						cJson += '			"idCarteira": "' + EncodeUTF8(AllTrim(ZC1->ZC1_CACOLO), "cp1252") + '",'+CRLF
						cJson += '			"dsCarteira": "' + EncodeUTF8(AllTrim(ZC1->ZC1_DECOLO), "cp1252") + '"'+CRLF
						cJson += '		}'+CRLF
						cJson += '	}'+CRLF
						cJson += '}'+CRLF

						RECLOCK("ZCS",.T.)
							cIdLog:= "LC" + CVALTOCHAR(ZCS->(RECNO()))
							ZCS->ZCS_FILIAL:= XFILIAL("ZCQ")
							ZCS->ZCS_TIPENV:= "LOCAL_CONTRATO" 
							ZCS->ZCS_OPEENV:= "1" //POST
							ZCS->ZCS_IDENTI:= ZC1->ZC1_LOCCTR
							ZCS->ZCS_URL   := ""
							ZCS->ZCS_IDLOG := cIdLog
							ZCS->ZCS_DTINTE:= DATE()
							ZCS->ZCS_HRINTE:= TIME()
							ZCS->ZCS_STATUS:= "0"
							ZCS->ZCS_FILA  := ALLTRIM(GetMV("CI_FLCDW3",.T.,"dev-integracao-local-contrato-dw3"))
							ZCS->ZCS_CODE  := "" 
							ZCS->ZCS_JSON  := cJson
						MSUNLOCK()   					
					
					ENDIF				
				ENDIF

				//Gera fila da configuração de cobrança de serviços diversos
				IF LEFT(SE1->E1_XIDFATU,2) == "SD" .AND. LEFT(SE1->E1_XIDCNT,2) == "SD"
					IF ASCAN(aIdsCfgC,{|x| x==SE1->E1_XIDCNT }) == 0

						DbSelectArea("ZC3")
						ZC3->(DbSetOrder(2))
						IF ZC3->(DbSeek(xFilial("ZC3") + SE1->E1_XIDCNT))

							AADD(aIdsCfgC,SE1->E1_XIDCNT)

							cJson := '{'+CRLF
							cJson += '	"CONFIGURACAO": {'+CRLF
							cJson += '		"id": "' + EncodeUTF8(AllTrim(ZC3->ZC3_IDCOBR), "cp1252") + '",'+CRLF
							cJson += '		"nome": "' + EncodeUTF8(AllTrim(ZC3->ZC3_NOMCOB), "cp1252") + '",'+CRLF
							cJson += '		"padrao": "' + EncodeUTF8(AllTrim(ZC3->ZC3_CONFPA), "cp1252") + '",'+CRLF
							cJson += '		"idContrato": "' + EncodeUTF8(AllTrim(ZC3->ZC3_IDCONT), "cp1252") + '",'+CRLF
							cJson += '		"idConfiguracaofaturamento": "' + EncodeUTF8(AllTrim(ZC3->ZC3_IDPGTO), "cp1252") + '",'+CRLF
							cJson += '		"DADOSCONTATOCOBRANCA": {'+CRLF
							cJson += '			"nome": "' + EncodeUTF8(AllTrim(ZC3->ZC3_NOMCTR), "cp1252") + '",'+CRLF
							cJson += '			"documento": "' + EncodeUTF8(AllTrim(ZC3->ZC3_CPFCTR), "cp1252") + '",'+CRLF
							cJson += '			"ddd": "' + EncodeUTF8(AllTrim(ZC3->ZC3_DDDCTR), "cp1252") + '",'+CRLF
							cJson += '			"telefone": "' + EncodeUTF8(AllTrim(ZC3->ZC3_TELCTR), "cp1252") + '",'+CRLF
							cJson += '			"ramal": "' + EncodeUTF8(AllTrim(ZC3->ZC3_RAMCTR), "cp1252") + '",'+CRLF
							cJson += '			"email": "' + EncodeUTF8(AllTrim(ZC3->ZC3_MAILCT), "cp1252") + '",'+CRLF
							cJson += '			"cargo": "' + EncodeUTF8(AllTrim(ZC3->ZC3_CARCTR), "cp1252") + '"'+CRLF
							cJson += '		},'+CRLF
							cJson += '		"FICHACOBRANCABANCARIA": {'+CRLF
							cJson += '			"enviaBanco": "' + EncodeUTF8(AllTrim(ZC3->ZC3_ENVBCO), "cp1252") + '",'+CRLF
							cJson += '			"enviaBoletoEmail": "' + EncodeUTF8(AllTrim(ZC3->ZC3_ENVBOL), "cp1252") + '",'+CRLF
							cJson += '			"email": "' + EncodeUTF8(AllTrim(ZC3->ZC3_MAIBOL), "cp1252") + '",'+CRLF
							cJson += '			"CREDITOEMCONTA": {'+CRLF
							cJson += '				"banco": "' + EncodeUTF8(AllTrim(ZC3->ZC3_CODBCO), "cp1252") + '",'+CRLF
							cJson += '				"agencia": "' + EncodeUTF8(AllTrim(ZC3->ZC3_AGENCI), "cp1252") + '",'+CRLF
							cJson += '				"conta": "' + EncodeUTF8(AllTrim(ZC3->ZC3_CTACRE), "cp1252") + '"'+CRLF
							cJson += '			},'+CRLF
							cJson += '			"DATADEVENCIMENTO": {'+CRLF
							cJson += '				"tipo": "' + EncodeUTF8(AllTrim(ZC3->ZC3_TIPVEN), "cp1252") + '",'+CRLF
							cJson += '				"TPPADRAO": {'+CRLF
							cJson += '					"data": "' + EncodeUTF8(AllTrim(DtoC(ZC3->ZC3_DTPAVE)), "cp1252") + '"'+CRLF
							cJson += '				},'+CRLF
							cJson += '				"TPDIAVENCIMENTO": {'+CRLF
							cJson += '					"diaVencimento": "' + EncodeUTF8(AllTrim(ZC3->ZC3_DIAVEN), "cp1252") + '",'+CRLF
							cJson += '					"competencia": "' + EncodeUTF8(AllTrim(ZC3->ZC3_COMPET), "cp1252") + '",'+CRLF
							cJson += '					"diaSemana": "' + EncodeUTF8(AllTrim(ZC3->ZC3_REGVEN), "cp1252") + '",'+CRLF
							cJson += '					"regraFeriado": "' + EncodeUTF8(AllTrim(ZC3->ZC3_REGFER), "cp1252") + '"'+CRLF
							cJson += '				},'+CRLF
							cJson += '				"TPDIASUTEISCORRIDOS": {'+CRLF
							cJson += '					"regra": "' + EncodeUTF8(AllTrim(ZC3->ZC3_UTEIS), "cp1252") + '",'+CRLF
							cJson += '					"qtdDias": "' + EncodeUTF8(AllTrim(ZC3->ZC3_QTDIAS), "cp1252") + '",'+CRLF
							cJson += '					"dia": "' + EncodeUTF8(AllTrim(ZC3->ZC3_SEMUTE), "cp1252") + '",'+CRLF
							cJson += '					"regraFeriadoConsiderar": "' + EncodeUTF8(AllTrim(ZC3->ZC3_SEMCON), "cp1252") + '"'+CRLF
							cJson += '				}'+CRLF
							cJson += '			},'+CRLF
							cJson += '			"ENDERECO": {'+CRLF
							cJson += '				"cep": "' + EncodeUTF8(AllTrim(ZC3->ZC3_CEP), "cp1252") + '",'+CRLF
							cJson += '				"logradouro": "' + EncodeUTF8(AllTrim(ZC3->ZC3_LOGRAD), "cp1252") + '",'+CRLF
							cJson += '				"endereco": "' + EncodeUTF8(AllTrim(ZC3->ZC3_ENDERE), "cp1252") + '",'+CRLF
							cJson += '				"numero": "' + EncodeUTF8(AllTrim(ZC3->ZC3_NUMERO), "cp1252") + '",'+CRLF
							cJson += '				"complemento": "' + EncodeUTF8(AllTrim(ZC3->ZC3_COMPLE), "cp1252") + '",'+CRLF
							cJson += '				"bairro": "' + EncodeUTF8(AllTrim(ZC3->ZC3_BAIRRO), "cp1252") + '",'+CRLF
							cJson += '				"codigoIBGE": "' + EncodeUTF8(AllTrim(ZC3->ZC3_COIBGE), "cp1252") + '",'+CRLF
							cJson += '				"cidade": "' + EncodeUTF8(AllTrim(ZC3->ZC3_CIDADE), "cp1252") + '",'+CRLF
							cJson += '				"uf": "' + EncodeUTF8(AllTrim(ZC3->ZC3_ESTADO), "cp1252") + '",'+CRLF
							cJson += '				"menssagem": "' + EncodeUTF8(AllTrim(ZC3->ZC3_MSG), "cp1252") + '"'+CRLF
							cJson += '			}'+CRLF
							cJson += '		},'+CRLF
							cJson += '		"OUTRASCONFIGURACOES": {'+CRLF
							cJson += '			"RECIBO": {'+CRLF
							cJson += '				"emite": "' + EncodeUTF8(AllTrim(ZC3->ZC3_EMIREC), "cp1252") + '",'+CRLF
							cJson += '				"ValorTotal": "' + EncodeUTF8(AllTrim(ZC3->ZC3_VLRTOT), "cp1252") + '",'+CRLF
							cJson += '				"ReciboAutomatico": "' + EncodeUTF8(AllTrim(ZC3->ZC3_RECAUT), "cp1252") + '",'+CRLF
							cJson += '				"banco": "' + EncodeUTF8(AllTrim(ZC3->ZC3_BCOCON), "cp1252") + '",'+CRLF
							cJson += '				"agencia": "' + EncodeUTF8(AllTrim(ZC3->ZC3_AGEOUT), "cp1252") + '",'+CRLF
							cJson += '				"conta": "' + EncodeUTF8(AllTrim(ZC3->ZC3_CTACON), "cp1252") + '",'+CRLF
							cJson += '				"observacao": "' + EncodeUTF8(AllTrim(ZC3->ZC3_OBSREC), "cp1252") + '"'+CRLF
							cJson += '			},'+CRLF
							cJson += '			"CARTAFATURA": {'+CRLF
							cJson += '				"emite": "' + EncodeUTF8(AllTrim(ZC3->ZC3_CARFAT), "cp1252") + '",'+CRLF
							cJson += '				"observacao": "' + EncodeUTF8(AllTrim(ZC3->ZC3_OBSCAR), "cp1252") + '",'+CRLF
							cJson += '				"unificaLocal": "' + EncodeUTF8(AllTrim(ZC3->ZC3_UNILOC), "cp1252") + '"'+CRLF
							cJson += '			},'+CRLF
							cJson += '			"NOTAFISCAL": {'+CRLF
							cJson += '				"emite": "' + EncodeUTF8(AllTrim(ZC3->ZC3_EMINF), "cp1252") + '",'+CRLF
							cJson += '				"observacao": "' + EncodeUTF8(AllTrim(ZC3->ZC3_OBSNF), "cp1252") + '",'+CRLF
							cJson += '				"email": "' + EncodeUTF8(AllTrim(ZC3->ZC3_MAILNF), "cp1252") + '",'+CRLF
							cJson += '				"valorTotal": "' + EncodeUTF8(AllTrim(ZC3->ZC3_VTOTNF), "cp1252") + '"'+CRLF
							cJson += '			},'+CRLF
							cJson += '			"COBRANCASERASA": {'+CRLF
							cJson += '				"envia": "' + EncodeUTF8(AllTrim(ZC3->ZC3_SERASA), "cp1252") + '",'+CRLF
							cJson += '				"qtdDias": "' + EncodeUTF8(AllTrim(ZC3->ZC3_QTDDIA), "cp1252") + '"'+CRLF
							cJson += '			},'+CRLF
							cJson += '			"COBRANCATERCEIRO": {'+CRLF
							cJson += '				"envia": "' + EncodeUTF8(AllTrim(ZC3->ZC3_COBTER), "cp1252") + '",'+CRLF
							cJson += '				"qtdDias": "' + EncodeUTF8(AllTrim(ZC3->ZC3_DIATER), "cp1252") + '"'+CRLF
							cJson += '			},'+CRLF
							cJson += '			"RepasseEmpresa": "' + EncodeUTF8(AllTrim(ZC3->ZC3_REPEMP), "cp1252") + '",'+CRLF
							cJson += '			"CISeparada": "' + EncodeUTF8(AllTrim(ZC3->ZC3_CISEPA), "cp1252") + '"'+CRLF
							cJson += '		},'+CRLF
							cJson += '		"LOCAISCONTRATOSVINCULADOS": {'+CRLF
							cJson += '			"idLocalContratoResponsavel": "' + EncodeUTF8(AllTrim(ZC3->ZC3_LOCVIN), "cp1252") + '",'+CRLF
							cJson += '			"IdUnidade": "' + EncodeUTF8(AllTrim(ZC3->ZC3_UNRESP), "cp1252") + '",'+CRLF
							cJson += '			"documento": "' + EncodeUTF8(AllTrim(ZC3->ZC3_DOCRES), "cp1252") + '",'+CRLF

							DbSelectArea("ZCI")
							ZCI->(DbSetOrder(1))
							if ZCI->(DbSeek(xFilial("ZCI")+ZC3->ZC3_IDCOBR))
								cJson += '			"LOCAISCONTRATOS": ['+CRLF
								while AllTrim(ZCI->ZCI_FILIAL+ZCI->ZCI_IDCOBR) == AllTrim(xFilial("ZCI")+ZC3->ZC3_IDCOBR) .and. ZCI->(!Eof())
									cJson += '			{'+CRLF
									cJson += '				"IdContrato": "' + EncodeUTF8(AllTrim(ZCI->ZCI_IDCONT), "cp1252") + '",'+CRLF
									cJson += '				"IdLocalContrato": "' + EncodeUTF8(AllTrim(ZCI->ZCI_LOCCTR), "cp1252") + '"'+CRLF
									cJson += '			}'+CRLF
									ZCI->(DbSkip())
									if AllTrim(ZCI->ZCI_FILIAL+ZCI->ZCI_IDCOBR) == AllTrim(xFilial("ZCI")+ZC3->ZC3_IDCOBR) .and. ZCI->(!Eof())
										cJson += ','+CRLF
									endif
								enddo
								cJson += '			]'+CRLF
							else
								cJson += '			"LOCAISCONTRATOS": [ ]'+CRLF
							endif

							cJson += '	    },'+CRLF
							cJson += '		"validaFaturamento": "' + EncodeUTF8(AllTrim(ZC3->ZC3_VLDFAT), "cp1252") + '"'+CRLF
							cJson += '	}'+CRLF
							cJson += '}'+CRLF	

							RECLOCK("ZCS",.T.)
								cIdLog:= "CC" + CVALTOCHAR(ZCS->(RECNO()))
								ZCS->ZCS_FILIAL:= XFILIAL("ZCQ")
								ZCS->ZCS_TIPENV:= "CONFIGURACAO_COBRANCA" 
								ZCS->ZCS_OPEENV:= "1" //POST
								ZCS->ZCS_IDENTI:= SE1->E1_XIDCNT
								ZCS->ZCS_URL   := ""
								ZCS->ZCS_IDLOG := cIdLog
								ZCS->ZCS_DTINTE:= DATE()
								ZCS->ZCS_HRINTE:= TIME()
								ZCS->ZCS_STATUS:= "0"
								ZCS->ZCS_FILA  := ALLTRIM(GetMV("CI_FCCDW3",.T.,"dev-integracao-configuracao-cobranca-dw3"))
								ZCS->ZCS_CODE  := "" 
								ZCS->ZCS_JSON  := cJson
							MSUNLOCK()   					
						ENDIF
					ENDIF				
				ENDIF				

				//Gera fila da configuração de faturamento de serviços diversos
				IF LEFT(SE1->E1_XIDFATU,2) == "SD" .AND. LEFT(SE1->E1_XIDCNT,2) == "SD"
					IF ASCAN(aIdsCfgF,{|x| x==SE1->E1_XIDCNT }) == 0

						DbSelectArea("ZC4")
						ZC4->(DbSetOrder(2))
						IF ZC4->(DbSeek(xFilial("ZC4") + SE1->E1_XIDCNT))

							AADD(aIdsCfgF,SE1->E1_XIDCNT)

							cJson := '{'+CRLF
							cJson += '  "CONFIGURACAO": {'+CRLF
							cJson += '    "id": "' + EncodeUTF8(AllTrim(ZC4->ZC4_IDFATU), "cp1252") + '",'+CRLF
							cJson += '    "nome": "' + EncodeUTF8(AllTrim(ZC4->ZC4_NOME), "cp1252") + '",'+CRLF
							cJson += '    "sitConfiguracao": "' + EncodeUTF8(AllTrim(ZC4->ZC4_SITCON), "cp1252") + '",'+CRLF
							cJson += '    "idContrato": "' + EncodeUTF8(AllTrim(ZC4->ZC4_IDCONT), "cp1252") + '",'+CRLF
							cJson += '    "ContratoUnico": "' + EncodeUTF8(AllTrim(ZC4->ZC4_CONUNI), "cp1252") + '",'+CRLF
							cJson += '    "REPRESENTANTE": {'+CRLF
							cJson += '      "nome": "' + EncodeUTF8(AllTrim(ZC4->ZC4_NOMREP), "cp1252") + '",'+CRLF
							cJson += '      "documento": "' + EncodeUTF8(AllTrim(ZC4->ZC4_DOCREP), "cp1252") + '",'+CRLF
							cJson += '      "areaSetor": "' + EncodeUTF8(AllTrim(ZC4->ZC4_AREREP), "cp1252") + '",'+CRLF
							cJson += '      "cargo": "' + EncodeUTF8(AllTrim(ZC4->ZC4_CARREP), "cp1252") + '",'+CRLF
							cJson += '      "email": "' + EncodeUTF8(AllTrim(ZC4->ZC4_MAIREP), "cp1252") + '",'+CRLF
							cJson += '      "ddd": "' + EncodeUTF8(AllTrim(ZC4->ZC4_DDDREP), "cp1252") + '",'+CRLF
							cJson += '      "telefone": "' + EncodeUTF8(AllTrim(ZC4->ZC4_TELREP), "cp1252") + '",'+CRLF
							cJson += '      "ramal": "' + EncodeUTF8(AllTrim(ZC4->ZC4_RAMREP), "cp1252") + '"'+CRLF
							cJson += '    },'+CRLF
							cJson += '    "CONTRIBUICAO": {'+CRLF
							cJson += '      "tipo": "' + EncodeUTF8(AllTrim(ZC4->ZC4_TIPCON), "cp1252") + '",'+CRLF
							cJson += '      "percentual": "' + EncodeUTF8(AllTrim(ZC4->ZC4_PERCON), "cp1252") + '",'+CRLF
							cJson += '      "valorCiEstudante": "' + EncodeUTF8(AllTrim(Str(ZC4->ZC4_VLRCI,14,2)), "cp1252") + '",'+CRLF
							cJson += '      "valorContribuicao": "' + EncodeUTF8(AllTrim(Str(ZC4->ZC4_VLRCON,14,2)), "cp1252") + '",'+CRLF
							cJson += '      "mesbase": "' + EncodeUTF8(AllTrim(ZC4->ZC4_MESBAS), "cp1252") + '",'+CRLF
							cJson += '      "permutaFaturamento": "' + EncodeUTF8(AllTrim(ZC4->ZC4_PERFAT), "cp1252") + '",'+CRLF
							cJson += '      "bancoFaturamento": "' + EncodeUTF8(AllTrim(ZC4->ZC4_CODBCO), "cp1252") + '",'+CRLF
							cJson += '	    "bancoExcedente": "' + EncodeUTF8(AllTrim(ZC4->ZC4_BCOEXC), "cp1252") + '",'+CRLF
							cJson += '		"valorExcedente": "' + EncodeUTF8(AllTrim(Str(ZC4->ZC4_VLREXC,14,2)), "cp1252") + '",'+CRLF
							cJson += '      "reajusteanual": "' + EncodeUTF8(AllTrim(ZC4->ZC4_REAJCI), "cp1252") + '",'+CRLF
							cJson += '      "repasseEmpresa": "' + EncodeUTF8(AllTrim(ZC4->ZC4_REPEMP), "cp1252") + '",'+CRLF

							oFaixas:= JsonObject():new()
							oFaixas:fromJson(AllTrim(ZC4->ZC4_FAIXAS))
							cFaixas:= oFaixas:TOJSON()
							cFaixas:= RIGHT(cFaixas,LEN(cFaixas)-1)
							cFaixas:= LEFT(cFaixas,LEN(cFaixas)-1)

							cJson += cFaixas+","+CRLF
							
							
							cJson += '      "Indice": "' + EncodeUTF8(AllTrim(ZC4->ZC4_DESIND), "cp1252") + '",'+CRLF
							cJson += '      "ContribuicaoInicial": "' + EncodeUTF8(AllTrim(Str(ZC4->ZC4_CIAPRE,14,2)), "cp1252") + '",'+CRLF
							cJson += '      "EMISSAO": {'+CRLF
							cJson += '        "tipo": "' + EncodeUTF8(AllTrim(ZC4->ZC4_TIPEMI), "cp1252") + '",'+CRLF
							cJson += '        "dia": "' + EncodeUTF8(AllTrim(ZC4->ZC4_DIAEMI), "cp1252") + '"'+CRLF
							cJson += '      }'+CRLF
							cJson += '    }'+CRLF
							cJson += '  }'+CRLF
							cJson += '}'+CRLF

							RECLOCK("ZCS",.T.)
								cIdLog:= "CF" + CVALTOCHAR(ZCS->(RECNO()))
								ZCS->ZCS_FILIAL:= XFILIAL("ZCQ")
								ZCS->ZCS_TIPENV:= "CONFIGURACAO_FATURAMENTO" 
								ZCS->ZCS_OPEENV:= "1" //POST
								ZCS->ZCS_IDENTI:= SE1->E1_XIDCNT
								ZCS->ZCS_URL   := ""
								ZCS->ZCS_IDLOG := cIdLog
								ZCS->ZCS_DTINTE:= DATE()
								ZCS->ZCS_HRINTE:= TIME()
								ZCS->ZCS_STATUS:= "0"
								ZCS->ZCS_FILA  := ALLTRIM(GetMV("CI_FCFDW3",.T.,"dev-integracao-configuracao-faturamento-dw3"))
								ZCS->ZCS_CODE  := "" 
								ZCS->ZCS_JSON  := cJson
							MSUNLOCK()   					
						ENDIF
					ENDIF				
				ENDIF					

				cNossoNum:= ""

				IF !EMPTY(SE1->E1_NUMBCO)
					cNossoNum:= STRZERO(VAL(SE1->E1_NUMBCO),11) + "-" + U_MOD11("09"+STRZERO(VAL(SE1->E1_NUMBCO),11))
				ENDIF	
				
				cJson := '{'+CRLF
				cJson += '   "sintetico":{'+CRLF
				cJson += '      "idfatura": "' + EncodeUTF8(AllTrim(ZC5->ZC5_IDFATU), "cp1252") + '",'+CRLF
				cJson += '      "lote": "' + EncodeUTF8(AllTrim(ZC6->ZC6_LOTE), "cp1252") + '",'+CRLF
				cJson += '      "seqlote": ' + EncodeUTF8(AllTrim(ZC6->ZC6_SEQLOT), "cp1252") + ','+CRLF
				cJson += '      "processo": "' + EncodeUTF8(AllTrim(ZC6->ZC6_PROFAT), "cp1252") + '",'+CRLF
				cJson += '      "loterastreamento": "' + EncodeUTF8(AllTrim(ZC6->ZC6_LOTRAS), "cp1252") + '",'+CRLF
				cJson += '      "idcontrato": "' + EncodeUTF8(AllTrim(ZC6->ZC6_IDCONT), "cp1252") + '",'+CRLF
				cJson += '      "idlocalremessa": "' + EncodeUTF8(AllTrim(iif(empty(ZC6->ZC6_LOCREM),"",ZC6->ZC6_LOCREM)), "cp1252") + '",'+CRLF
				cJson += '      "documento": "' + EncodeUTF8(AllTrim(ZC1->ZC1_DOCLOC), "cp1252") + '",'+CRLF
				cJson += '      "razaosocial": "' + EncodeUTF8(AllTrim(ZC1->ZC1_RAZSOC), "cp1252") + '",'+CRLF
				cJson += '      "endereco":{'+CRLF
				cJson += '		   "cep": "' + EncodeUTF8(AllTrim(ZC1->ZC1_CEPLOC), "cp1252") + '",'+CRLF
				cJson += '		   "logradouro": "' + EncodeUTF8(AllTrim(ZC1->ZC1_LOGLOC), "cp1252") + '",'+CRLF
				cJson += '		   "endereco": "' + EncodeUTF8(AllTrim(ZC1->ZC1_ENDLOC), "cp1252") + '",'+CRLF
				cJson += '		   "numero": "' + EncodeUTF8(AllTrim(ZC1->ZC1_NUMLOC), "cp1252") + '",'+CRLF
				cJson += '		   "complemento": "' + EncodeUTF8(AllTrim(ZC1->ZC1_COMLOC), "cp1252") + '",'+CRLF
				cJson += '		   "bairro": "' + EncodeUTF8(AllTrim(ZC1->ZC1_BAILOC), "cp1252") + '",'+CRLF
				cJson += '		   "codigoibge": "' + EncodeUTF8(AllTrim(ZC1->ZC1_CMUNLO), "cp1252") + '",'+CRLF
				cJson += '		   "cidade": "' + EncodeUTF8(AllTrim(ZC1->ZC1_CIDLOC), "cp1252") + '",'+CRLF
				cJson += '		   "uf": "' + EncodeUTF8(AllTrim(ZC1->ZC1_ESTLOC), "cp1252") + '"'+CRLF
				cJson += '      },'+CRLF
				cJson += '      "idconfiguracaofaturamento": "' + EncodeUTF8(AllTrim(ZC6->ZC6_CONFAT), "cp1252") + '",'+CRLF
				cJson += '      "idfolha": ' + EncodeUTF8(AllTrim(iif(empty(ZC6->ZC6_IDFOLH),"null",ZC6->ZC6_IDFOLH)), "cp1252") + ','+CRLF
				cJson += '      "idconfiguracaocobranca": "' + EncodeUTF8(AllTrim(ZC6->ZC6_CONCOB), "cp1252") + '",'+CRLF
				cJson += '      "prefixotitulo": "' + EncodeUTF8(AllTrim(SE1->E1_PREFIXO), "cp1252") + '",'+CRLF
				cJson += '      "numerotitulo":"' + EncodeUTF8(AllTrim(SE1->E1_NUM), "cp1252") + '",'+CRLF
				cJson += '      "parcelatitulo":"' + EncodeUTF8(AllTrim(SE1->E1_PARCELA), "cp1252") + '",'+CRLF
				cJson += '      "tipotitulo":"' + EncodeUTF8(AllTrim(SE1->E1_TIPO), "cp1252") + '",'+CRLF
				cJson += '      "quantidade_tce_tca": "' + EncodeUTF8(AllTrim(Str(ZC6->ZC6_QTDE,14,2)), "cp1252") + '",'+CRLF
				cJson += '      "tpproduto": "' + EncodeUTF8(AllTrim(ZC6->ZC6_TIPPRO), "cp1252") + '",'+CRLF
				cJson += '      "datavencimento": "' + EncodeUTF8(AllTrim(DTOC(SE1->E1_VENCREA)), "cp1252") + '",'+CRLF
				cJson += '      "dataemissao":"' + EncodeUTF8(AllTrim(DTOC(SE1->E1_EMISSAO)), "cp1252") + '",'+CRLF
				cJson += '      "mensagemnota": "' + EncodeUTF8(AllTrim(ZC6->ZC6_MSGNOT), "cp1252") + '",'+CRLF
				cJson += '      "idrps":"' + EncodeUTF8(AllTrim(ZC5->ZC5_NOTA), "cp1252") + '",'  +CRLF
				cJson += '      "idnfe": ' + EncodeUTF8(AllTrim(iif(empty(ZC5->ZC5_CODNFE),"null",ZC5->ZC5_CODNFE)), "cp1252") + ','+CRLF

				if !empty(cLink)
					cJson += '      "urlnota":"' + EncodeUTF8(AllTrim(cLink), "cp1252") + '",'+CRLF
					cJson += '      "dataemissaonfe":"' + EncodeUTF8(AllTrim(DTOC(ZC5->ZC5_DATA)), "cp1252") + '",'+CRLF
					cJson += '      "horaemissaonfe":"' + EncodeUTF8(AllTrim(ZC5->ZC5_HORFIM), "cp1252") + '",'+CRLF
				else
					cJson += '      "urlnota":"",'+CRLF
					cJson += '      "dataemissaonfe":"",'+CRLF
					cJson += '      "horaemissaonfe":"",'+CRLF
				endif

				cJson += '      "codigoautorizacaonfe": ' + EncodeUTF8(AllTrim(iif(empty(ZC5->ZC5_NFELET),"null",ZC5->ZC5_NFELET)), "cp1252") + ','+CRLF
				cJson += '      "datacancelamentonfe":"' + EncodeUTF8(AllTrim(DTOC(ZC5->ZC5_DTCANC)), "cp1252") + '",'+CRLF
				cJson += '      "motivocancelamento":"' + EncodeUTF8(AllTrim(ZC5->ZC5_DESMOT), "cp1252") + '",'+CRLF
				cJson += '      "banco": "' + EncodeUTF8(AllTrim(SEE->EE_CODIGO ), "cp1252") + '",'+CRLF
				cJson += '      "codigocarteirabanco": "' + EncodeUTF8(AllTrim(SEE->EE_CODCART), "cp1252") + '",'+CRLF
				cJson += '      "nossonumero": "' + EncodeUTF8(AllTrim(cNossoNum), "cp1252") + '",'+CRLF
				cJson += '      "seunumero": "' + EncodeUTF8(AllTrim(SE1->E1_IDCNAB), "cp1252") + '",'+CRLF
				cJson += '      "codigoconveniobanco": "' + EncodeUTF8(AllTrim(SEE->EE_NUMCTR), "cp1252") + '",'+CRLF
				cJson += '      "valorcobranca": ' + EncodeUTF8(AllTrim(Str(SE1->E1_VALOR,14,2)), "cp1252") + ','+CRLF
	//			cJson += '      "valormulta": ' + EncodeUTF8(AllTrim(Str(SE1->E1_MULTA,14,2)), "cp1252") + ','+CRLF
	//			cJson += '      "valorjuros": ' + EncodeUTF8(AllTrim(Str(SE1->E1_JUROS,14,2)), "cp1252") + ','+CRLF
				cJson += '      "valormulta": ' + EncodeUTF8(AllTrim(Str(GetMV("CI_TXMULTA",.T.,2.0),6,2)), "cp1252") + ','+CRLF
				cJson += '      "valorjuros": ' + EncodeUTF8(AllTrim(Str((SE1->E1_VALOR*(GetMV("MV_TXPER",.T.,1.0)/100)/30),14,2)), "cp1252" ) + ','+CRLF
				cJson += '      "tipodesconto":"1",'+CRLF
				cJson += '      "valordesconto":0,'+CRLF
				cJson += '      "datalimitedesconto":"",'+CRLF
				cJson += '      "valorabatimento": ' + EncodeUTF8(AllTrim(Str(SE1->E1_DECRESC,14,2)), "cp1252") + ','+CRLF
				cJson += '      "quantidadediasbaixa":0,'+CRLF
				cJson += '      "situacao": ' + iif(!Empty(cSituacao),'"'+ cSituacao + '"',"null") + ','+CRLF
				cJson += '      "ocorrencia": ' + iif(!Empty(cOcorre),'"'+ cOcorre + '"',"null") + ','+CRLF		
				cJson += '      "analitico":['+CRLF
				cJson += '         {'+CRLF
				cJson += '      	  "id": ' + EncodeUTF8(AllTrim(iif(empty(ZC6->ZC6_IDESTU),"null",ZC6->ZC6_IDESTU)), "cp1252") + ','+CRLF
				cJson += '            "cpf": "' + EncodeUTF8(AllTrim(ZC6->ZC6_CPFEST), "cp1252") + '",'+CRLF
				cJson += '            "nome": "' + EncodeUTF8(AllTrim(ZC6->ZC6_NOMEST), "cp1252") + '",'+CRLF
				cJson += '            "nomesocial": "' + EncodeUTF8(AllTrim(ZC6->ZC6_NOMSOC), "cp1252") + '",'+CRLF
				cJson += '            "competencia": "' + EncodeUTF8(AllTrim(ZC6->ZC6_COMPET), "cp1252") + '",'+CRLF
				cJson += '            "codigo_tce_tca": "' + EncodeUTF8(AllTrim(ZC6->ZC6_TCETCA), "cp1252") + '",'+CRLF
				cJson += '            "idlocalcontrato": "' + EncodeUTF8(AllTrim(ZC6->ZC6_LOCCON), "cp1252") + '",'+CRLF
				cJson += '            "tipo_faturamento": "' + EncodeUTF8(AllTrim(ZC6->ZC6_TIPFAT), "cp1252") + '",'+CRLF
				cJson += '            "valor": ' + EncodeUTF8(AllTrim(Str(ZC6->ZC6_VALOR,14,2)), "cp1252") + ','+CRLF
				cJson += '            "produto": "' + EncodeUTF8(AllTrim(ZC6->ZC6_PRODUT), "cp1252") + '",'+CRLF
				cJson += '            "descricao": "' + EncodeUTF8(AllTrim(SB1->B1_DESC), "cp1252") + '",'+CRLF
				cJson += '            "quantidade": ' + EncodeUTF8(AllTrim(Str(ZC6->ZC6_QTDE,14,2)), "cp1252") + ','+CRLF

				IF !EMPTY(SB1->B1_XTIPSER)
					aSubTip:= FWGetSX5("_T", AllTrim(SB1->B1_XTIPSER))
					IF !EMPTY(aSubTip)
						cJson += '            "subtipo": "' + EncodeUTF8(AllTrim( aSubTip[1][4] ), "cp1252") + '"'+CRLF
					ELSE
						cJson += '            "subtipo": ""'+CRLF
					ENDIF
				ELSE
					cJson += '            "subtipo": ""'+CRLF
				ENDIF	

				cJson += '         }'+CRLF
				cJson += '      ]'+CRLF
				cJson += '   }'+CRLF
				cJson += '}'+CRLF			

				RECLOCK("ZCS",.T.)
					cIdLog:= "FT" + CVALTOCHAR(ZCS->(RECNO()))
					ZCS->ZCS_FILIAL:= XFILIAL("ZCQ")
					ZCS->ZCS_TIPENV:= "COBRANCA_DW3" 
					ZCS->ZCS_OPEENV:= "1" //POST
					ZCS->ZCS_IDENTI:= ZC5->ZC5_IDFATU
					ZCS->ZCS_URL   := ""
					ZCS->ZCS_IDLOG := cIdLog
					ZCS->ZCS_DTINTE:= DATE()
					ZCS->ZCS_HRINTE:= TIME()
					ZCS->ZCS_STATUS:= "0"
					ZCS->ZCS_FILA  := ALLTRIM(GetMV("CI_FCOBDW3",.T.,"dev1-integracao-cobranca-dw3"))
					ZCS->ZCS_CODE  := "" 
					ZCS->ZCS_JSON  := cJson
				MSUNLOCK()  

				RECLOCK("SE1",.F.)
					SE1->E1_XINTDW3:= "S"
				MSUNLOCK()  						 			

			endif

		endif
		
		(cZc6)->(dbSkip())
	END
	
	(cZc6)->(dbCloseArea())
	
ENDIF

return

/*/{Protheus.doc} CIKAIROS
Gera fila de integração com Kairos no retorno da cobrança
@author carlos.henrique
@since 17/01/2020
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User Function CIKAIROS(cOcorre,cSituacao)
Local cZc6 := ""
Local cJson:= ""
Default cSituacao := ""

DBSELECTAREA("ZC5")
ZC5->(DbOrderNickName("IDFATURAME"))
IF ZC5->(DBSEEK(SE1->E1_XIDFATU)) .and. !("SD"$ZC5->ZC5_LOTE)

	cZc6 := GetNextAlias()
	
	BeginSql Alias cZc6
		SELECT ZC6.R_E_C_N_O_ AS RECZC6 
		FROM %TABLE:ZC6% ZC6
		WHERE ZC6_FILIAL=%Exp:ZC5->ZC5_FILIAL%
		AND ZC6_IDFATU=%Exp:ZC5->ZC5_IDFATU%
		AND ZC6.D_E_L_E_T_ =''
	EndSql
	
	//aRet:= GETLastQuery()[2]
	
	(cZc6)->(dbSelectArea((cZc6)))
	(cZc6)->(dbGoTop())
	WHILE (cZc6)->(!EOF())

		ZC6->(dbGoto((cZc6)->RECZC6))	
	
		cJson := '{'
		cJson += '   "codigoFaturamento": ' + EncodeUTF8(AllTrim(ZC6->ZC6_IDKAIR), "cp1252") + ','
		cJson += '   "codigoContrato": ' + EncodeUTF8(AllTrim(ZC5->ZC5_IDCONT), "cp1252") + ','
		cJson += '   "codigoConfiguracaoFaturamento": ' + EncodeUTF8(AllTrim(ZC5->ZC5_CONFAT), "cp1252") + ','
		cJson += '   "codigoConfiguracaoCobranca": ' + EncodeUTF8(AllTrim(ZC5->ZC5_CONCOB), "cp1252") + ','
		cJson += '   "quantidadeTotalTCE": ' + EncodeUTF8(AllTrim(Str(ZC6->ZC6_QTDE,14,2)), "cp1252") + ','
		cJson += '   "valorTotalFaturamento": ' + EncodeUTF8(AllTrim(Str(ZC5->ZC5_VALOR,14,2)), "cp1252") + ','
		cJson += '   "codigoLocalContrato": ' + EncodeUTF8(AllTrim(ZC5->ZC5_LOCCON), "cp1252") + ','
		cJson += '   "codigoTCETCA": ' + EncodeUTF8(AllTrim(ZC6->ZC6_TCETCA), "cp1252") + ','
		cJson += '   "competencia": "' + EncodeUTF8(RIGHT(AllTrim(SE1->E1_XCOMPET),4) + "-" + LEFT(AllTrim(SE1->E1_XCOMPET),2), "cp1252") + '",'
		cJson += '   "tipoFaturamento": "' + EncodeUTF8(AllTrim(ZC6->ZC6_TIPPRO), "cp1252") + '",'
		cJson += '   "valorPago": ' + EncodeUTF8(AllTrim(Str(SE1->E1_VALOR,14,2)), "cp1252") + ','
		cJson += '   "dataOperacao": "' + EncodeUTF8(TRANSFORM(VAL(DTOS(ZC5->ZC5_DATA)),"9999-99-99"), "cp1252") + '",'

		//Situações
		//- NAO PAGA
		//- PAGA
		//- CANCELADA
		//- SERASA
		//- TERCEIRIZADA 
		IF cSituacao == "S"
			
			cJson += '   "situacao":"SERASA",'

		ELSEIF cSituacao == "T"
			
			cJson += '   "situacao":"TERCEIRIZADA",'

		ELSEIF cSituacao == "C"
			
			cJson += '   "situacao":"CANCELADA",'

		ELSEIF cSituacao == "P" 
			
			cJson += '   "situacao":"PAGA",'	

		ELSE
			
			cJson += '   "situacao":"NAO_PAGA",'	

		ENDIF

		cJson += '   "motivoCancelamento":"' + EncodeUTF8(AllTrim(ZC5->ZC5_DESMOT), "cp1252") + '"'+CRLF
		cJson += '}'

		RECLOCK("ZCQ",.T.)
			cIdLog:= "RF" + CVALTOCHAR(ZCQ->(RECNO()))
			ZCQ->ZCQ_FILIAL:= XFILIAL("ZCQ")
			ZCQ->ZCQ_TIPENV:= "RETORNO_FATURAMENTO" 
			ZCQ->ZCQ_OPEENV:= "1" //POST
			ZCQ->ZCQ_IDENTI:= ZC6->ZC6_IDKAIR
			ZCQ->ZCQ_URL   := ""
			ZCQ->ZCQ_IDLOG := cIdLog
			ZCQ->ZCQ_DTINTE:= DATE()
			ZCQ->ZCQ_HRINTE:= TIME()
			ZCQ->ZCQ_STATUS:= "0"
			ZCQ->ZCQ_FILA  := ALLTRIM(GetMV("CI_FRFDW3",.T.,"dev-integracao-contrato-dw3"))
			ZCQ->ZCQ_CODE  := "" 
			ZCQ->ZCQ_JSON  := cJson
		MSUNLOCK() 

		(cZc6)->(dbSkip())
	END
	
	(cZc6)->(dbCloseArea())	  
	
endif

return

