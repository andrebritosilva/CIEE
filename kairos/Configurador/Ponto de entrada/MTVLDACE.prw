#Include 'Protheus.ch'
//---------------------------------------------------------------------------------------
/*/{Protheus.doc} MTVLDACE
Ponto de entrada validar o acesso a rotina quando chamada pelo menu
@author  	Carlos Henrique
@since     	01/01/2015
@version  	P.11.8
@return   	Nenhum
/*/
//---------------------------------------------------------------------------------------
User Function MTVLDACE()

	Local aArea		:= u_GETALLAREA()
	Local lNovoBC	:= SuperGetMv("CI_NOVOBC",.F.,.T.)
	Local aFunExc	:= StrTokArr(GetNewPar("CI_FEXECBC","MADELNFS"),",")
	Local lRet		:= .T.
	Local oObjBrow	:= NIL
	Local cAlias	:= ""
	Local nRecno	:= 0
	Local lExeExp	:= .T.
	Local nCnt		:= 0
	Local lEx103	:= TYPE("l103Exclui") == "L"

	If lNovoBC

		lRet:= .F. // Manter como falso para n�o executar a chamada padr�o do banco de conhecimento

		//Tratamento para excutar a fun��o padr�o para alguns casos que est�o no parametro CI_FEXECBC
		//Exemplo: Exclus�o da nota fiscal de saida MADELNFS
		For nCnt:= 1 to len(aFunExc)
			If ISINCALLSTACK(aFunExc[nCnt])
				If TRIM(aFunExc[nCnt])=="MADELNFS"
					lRet		:= .F.	//N�o executar o padr�o na exclus�o da nota
					lExeExp	:= .F.	//N�o executar o especifico na exclus�o da nota
				ElseIf u_C99E03STB(.F., .T.) .AND. TRIM(aFunExc[nCnt])$"MA140GRAVA"
					lRet		:= .F.  //Executar padr�o
				ElseIf lEx103 .AND. TRIM(aFunExc[nCnt])=="A103NFISCAL"
					lRet        := l103Exclui
				//Else
					//lRet		:= .T.  	//Executar padr�o
				ElseIf isInCallStack("A140EstCla")
					lExeExp		:= .F.
				EndIf
				Exit
			EndIf
		Next nCnt

		//Tratamento para n�o gerar erro na exclus�o da nota de saida
		If !lRet .and. lExeExp

			oObjBrow:= GetObjBrow()

			If oObjBrow != NIL .or. ISINCALLSTACK("CNTA300") .or. ISINCALLSTACK("U_CFINA86");
				.or. ISINCALLSTACK("U_CCFGA06") .or. ISINCALLSTACK("U_CCADK05")

				If ISINCALLSTACK("CN170CONH") //Documento dentro da rotina de Visualiza��o do Contrato. O Alias padr�o vem CN9, porem o Documento fica atrelado a CNK-documentos
					cAlias	:= "CNK"
				ElseIf ISINCALLSTACK("CNTA300")
					cAlias	:= "CN9"
				ElseIf ISINCALLSTACK("U_CFINA86")
					cAlias	:= "ZFQ"
				ElseIf ISINCALLSTACK("U_CCOMA15")
					cAlias	:= "SF1"
				ElseIf ISINCALLSTACK("U_CCFGA06")
					If !Empty(ZPN->ZPN_NUMDOC)
						cAlias	:= "SF1"
					Else
						cAlias	:= "SE2"
					EndIf
				ElseIf ISINCALLSTACK("U_CCADK05")
					cAlias	:= "ZCC"
				Else
					cAlias	:= IIF(oObjBrow!= NIL,oObjBrow:CREALALIAS,ALIAS())
				EndIf
				nRecno	:= (cAlias)->(RECNO())

				//DBSELECTAREA("SX2")
				//SX2->(DBSEEK(cAlias))
				If EMPTY(FwSX2Util():GetSX2data(cAlias, {"X2_DISPLAY"})[1][2])
					MSGALERT("Campo X2_DISPLAY n�o informado para tabela "+ cAlias)
				Else
					//Rotina especifica para visualiza��o do banco de conhecimento no fluig utilizando apenas um usu�rio
					If u_C99E03STB(.F., .T.)
						U_CCFGE03(cAlias,nRecno,,,.T.)
					Else
						U_CCFGE03(cAlias,nRecno)
					EndIf
				EndIf

			Else

				MSGALERT("N�o foi possivel identificar o Browse, contate o administrador!!")

			EndIf

		EndIf

	EndIf

	U_GETALLAREA(aArea)

Return lRet
