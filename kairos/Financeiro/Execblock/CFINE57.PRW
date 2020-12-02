#Include "Protheus.ch"
#include "Fileio.ch"

/*/{Protheus.doc} CFINE57
JOB de processamento para gerar arquivo para retirada dos títulos do Serasa que foram baixados por boleto/crédito ou cancelamento.
@author danilo.grodzicki
@since 28/06/2020
@version P12.1.25
@type user function
/*/
User function CFINE57()

Local lJob := GetRemoteType() == -1  // Verifica se é job

Private lGerou  := .F.
Private nStart  :=  Seconds()
Private cDirArq := AllTrim(GetMV("CI_DIRARSE",.T.,"c:\spool\"))

if !lJob
	if !MsgYesNo("Confirma gerar arquivo para retirar os títulos baixados do Serasa?")
		Return
	endif
endif

if !LockByName("CFINE57",.T.,.T.)

	if !lJob
		MsgInfo("Já existe um processamento em execução, aguarde.","ATENÇÃO")
	endif

endif
	
	if !lJob
		FWMsgRun(,{|| CJBK57PR(lJob, @lGerou) },,"Realizando integração das negociações, aguarde...")
	else
		FwLogMsg("INFO", /*cTransactionId*/, "REST", "CFINE57", "", "01", "Processo iniciado" , 0, (nStart - Seconds()), {})
		CJBK57PR(lJob, @lGerou)
		FwLogMsg("INFO", /*cTransactionId*/, "REST", "CFINE57", "", "01", "Processo finalizado" , 0, (nStart - Seconds()), {})
	endif
	
	UnLockByName("CFINE57",.T.,.T.)

	if !lJob 
		if lGerou
			MsgInfo("Arquivo gerado no diretório: " + cDirArq + ".","ATENÇÃO")
		else
			MsgInfo("Não foram encontrados títulos para gerar o arquivo.","ATENÇÃO")
		endif
	endif	
Return

/*/{Protheus.doc} CJBK57PR
Rotina que gera o arquivo de retirada do Serasa
@author danilo.grodzicki
@since 28/06/2020
@version P12.1.25
@type static function
/*/
Static Function CJBK57PR(lJob, lGerou)

Local nLinha
Local nHandle

Local cTab    := GetNextAlias()
Local cSeqReg := "0000001"

DbSelectArea("SM0")
SM0->(DbSetOrder(01))
SM0->(DbSeek(cEmpAnt+cFilAnt))

DbSelectArea("SA1")
SA1->(DbSetOrder(01))

DbSelectArea("SE1")
SE1->(DbSetOrder(01))

// verifica se existe o diretório, se não existir cria o diretório
if !ExistDir(cDirArq)
	MakeDir(cDirArq)
endif 

BeginSql Alias cTab
	SELECT R_E_C_N_O_ AS RECSE1
	FROM %TABLE:SE1% SE1
	WHERE SE1.E1_FILIAL = %xfilial:SE1%
	  AND SE1.E1_XGERSER = 'S'
	  AND SE1.D_E_L_E_T_ = ''
EndSql

(cTab)->(dbSelectArea((cTab)))
(cTab)->(dbGoTop())
if (cTab)->(Eof())
	(cTab)->(DbCloseArea())
	Return
endif

nHandle := FCREATE(cDirArq + "retira_serasa_" + DtoS(Date()) + "_" + StrTran(Time(),":","") + ".txt")

if nHandle = -1
	if !lJob
		MsgInfo("Erro ao criar o arquivo: " + Str(Ferror()),"ATENÇÃO")
	else
		FwLogMsg("INFO", /*cTransactionId*/, "REST", "CFINE57", "", "01", "Erro ao criar arquivo: " + Str(Ferror()) , 0, (nStart - Seconds()), {})
		Return
	endif
else
	nLInha := "0" + StrZero(Val(SubStr(SM0->M0_CGC,1,8)),9) + DtoS(dDataBase) + space(04) + space(08) + space(04) + space(70) + "SERASA-CONVEM04" +;
	          CJBK57LT() + "E" + space(04) + space(403) + space(60) + cSeqReg
	FWrite(nHandle, nLInha + CRLF)
endif

(cTab)->(dbSelectArea((cTab)))
(cTab)->(dbGoTop())
while (cTab)->(!Eof())
	
	SE1->(DbGoTo((cTab)->RECSE1))

	SA1->(DbSeek(xFilial("SA1")+SE1->E1_CLIENTE+SE1->E1_LOJA))
	
	cSeqReg := Soma1(cSeqReg,7)

	nLInha := "1" + "E" + space(06) + DtoS(SE1->E1_VENCTO) + DtoS(SE1->E1_VENCTO) + SE1->E1_TIPO + space(04) + SA1->A1_PESSOA +;
			  iif(SA1->A1_PESSOA == "F", "2", "1") + StrZero(Val(SA1->A1_CGC),15) + space(02) + space(01) + space(15) + iif(SA1->A1_PESSOA == "F", SA1->A1_EST, space(02)) +;
			  space(01) + space(01) + space(15) + space(02) + space(01) + space(15) + space(02) + SA1->A1_NOME + space(10) + space(08) + space(70) + space(70) + SA1->A1_END +;
			  space(05) + Left(SA1->A1_BAIRRO,20) + Left(SA1->A1_MUN,25) + SA1->A1_EST + SA1->A1_CEP + StrZero(SE1->E1_VALOR*100,15) + SE1->E1_PREFIXO + SE1->E1_NUM + SE1->E1_PARCELA +;
			  space(01) + SE1->E1_FILORIG + space(34-Len(xFilial('FW9'))) + SA1->A1_DDD + space(01) + PadR(AllTrim(SA1->A1_TEL),9) + DtoS(SE1->E1_VENCTO) + StrZero(SE1->E1_VALOR*100,15) +;
			  space(09) + space(60) + cSeqReg
	
	FWrite(nHandle, nLInha + CRLF)
	
	RecLock("SE1", .F.)
		SE1->E1_XGERSER := " "
		SE1->E1_XDARQSE := Date()
	SE1->(MsUnlock())

	lGerou := .T.

	(cTab)->(DbSkip())

enddo

(cTab)->(DbCloseArea())

cSeqReg := Soma1(cSeqReg,7)

nLInha := "9" + space(02) + space(590) + cSeqReg

FWrite(nHandle, nLInha + CRLF)

FClose(nHandle)

Return

/*/{Protheus.doc} CJBK57LT
Controle de numeração do arquivo Serasa
@author danilo.grodzicki
@since 28/06/2020
@version P12.1.25
@type static function
/*/
Static Function CJBK57LT()

Local nCodSera	:= Val(GetMV("MV_ARQSERA"))
Local nTamArq	:= TamSX3("FW8_ARQSER")[1]
Local cNumSera	:= ""

//Verifica numero do ultimo Bordero Gerado
cNumSera := Soma1(StrZero(nCodSera,nTamArq,0),nTamArq)

While !MayIUseCode( "FW8->FW8_ARQSER" + xFilial("FW8") + cNumSera )	//verifica se esta na memoria, sendo usado
	cNumSera := Soma1(cNumSera) // busca o proximo numero disponivel 
EndDo                                           

//Atualiza o conteudo do parametro
PutMV("MV_ARQSERA",cNumSera)

Return cNumSera

/*/{Protheus.doc} CJOB57TE
Rotina de teste
@author Danilo José Grodzicki
@since 03/02/2020
@version undefined
@type function
/*/
User Function CJOB57TE()
	RpcSetType(3)
	RpcSetEnv("01","0001")
	U_CFINE57()
Return