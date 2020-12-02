#Include 'Protheus.ch'
#INCLUDE "FWMVCDEF.CH"

//---------------------------------------------------------------------------------------
/*/{Protheus.doc} CCADK18
Monitor integração ICN
@author  	danilo.grodzicki
@since     	30/09/2020
@version  	P.12.1.25
@return   	Nenhum
/*/
//---------------------------------------------------------------------------------------
User Function CCADK18()

Local oBrowse := FwMBrowse():New()

oBrowse:SetAlias("ZCC")
oBrowse:SetDescription("Monitor de Integração ICN")
oBrowse:AddLegend("ZCC_STATUS=='4'", "BR_AMARELO"  , "Pendente"  )
oBrowse:AddLegend("ZCC_STATUS=='5'", "BR_VERMELHO" , "Erro"      )
oBrowse:AddLegend("ZCC_STATUS=='6'", "BR_VERDE"    , "Integrado" )

oBrowse:SetFilterDefault("ZCC_STATUS=='4'.OR.ZCC_STATUS=='5'.OR.ZCC_STATUS=='6'")

oBrowse:DisableDetails() 

// Ativação da Classe
oBrowse:Activate()

RETURN

//---------------------------------------------------------------------------------------
/*/{Protheus.doc} MenuDef
Rotina de definição do menu
@author  	danilo.grodzicki
@since     	30/09/2020
@version  	P.12.1.25
@return   	Nenhum
/*/
//---------------------------------------------------------------------------------------
Static Function MenuDef()

Local aRotina := {}

ADD OPTION aRotina TITLE "Visualizar"   ACTION "U_CCK05VIS"   OPERATION 2 ACCESS 0
ADD OPTION aRotina TITLE "Integrar ICN" ACTION "U_CJOBK18"    OPERATION 4 ACCESS 0
ADD OPTION aRotina TITLE "Legenda"      ACTION "U_CCK18LEG()" OPERATION 6 ACCESS 0

Return(aRotina)

//---------------------------------------------------------------------------------------
/*/{Protheus.doc} ModelDef
Rotina de definição do MODEL
@author  	danilo.grodzicki
@since     	30/09/2020
@version  	P.12.1.25
@return   	Nenhum
/*/
//---------------------------------------------------------------------------------------
Static Function ModelDef()

Local oStruZCC 	:= FWFormStruct(1, "ZCC")
Local oModel   	:= MPFormModel():New( 'CCK18MD', /*bPreValidacao*/, /*bPosVld*/, /*bCommit*/ , /*bCancel*/ )

oModel:AddFields("ZCCMASTER", /*cOwner*/, oStruZCC)
oModel:SetPrimaryKey({"ZCC_FILIAL","ZCC_IDREP"})
oModel:SetDescription("Monitor integração ICN")

Return oModel

//---------------------------------------------------------------------------------------
/*/{Protheus.doc} ViewDef
Rotina de definição do VIEW
@author  	danilo.grodzicki
@since     	30/09/2020
@version  	P.12.1.25
@return   	Nenhum
/*/
//---------------------------------------------------------------------------------------
Static Function ViewDef()

Local oView    := FWFormView():New()
Local oStruZCC := FWFormStruct( 2, "ZCC")
Local oModel   := FWLoadModel("CCADK18")

oView:SetModel(oModel)
oView:AddField("VIEW", oStruZCC, "ZCCMASTER")
oView:CreateHorizontalBox("TELA", 100)
oView:SetOwnerView("VIEW", "TELA")

Return oView

/*/{Protheus.doc} CCK18LEG
Legenda monitor integração ICN
@author danilo.grodzicki
@since 30/09/2020
@version 12.1.25
@type user function
/*/
User Function CCK18LEG()

BrwLegenda("Monitor integração ICN","Legenda", { {"BR_VERMELHO", OemToAnsi("Erro"      )},;
									  		     {"BR_VERDE"   , OemToAnsi("Integrado" )},;
									  		     {"BR_AMARELO" , OemToAnsi("Pendente"  )}})

Return Nil

/*/{Protheus.doc} CJOBK18
Integração ICN
@author danilo.grodzicki
@since 30/09/2020
@version 12.1.25
@type user function
/*/
User Function CJOBK18()

Local lJob		:= GetRemoteType() == -1 // Verifica se é job
Local cEmpInt	:= CEMPANT
Local cFilInt	:= CFILANT
Local nOpca		:= 0

IF !lJob	
	IF MSGYESNO("Confirma o processamento da Integração ICN ?")
		nOpca:= 1
	ENDIF
ELSE
	CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK18] Iniciando processamento via schedule.")
	nOpca:= 1		                                                                                                          
ENDIF

IF !LockByName("CJOBK18",.T.,.T.)
	nOpca:= 0
	IF !lJob
		MSGINFO("Já existe um processamento em execução, aguarde!")
	ELSE
		CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK18] Já existe um processamento em execução, aguarde!")
	ENDIF
ENDIF

IF nOpca > 0

	IF !lJob
		FWMsgRun(,{|| CJBK18PR() },,"Realizando processamento da Integração ICN, aguarde...")
	ELSE
		CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK18] Processo Iniciado para "+cEmpInt+"-"+cFilInt)
		CJBK18PR() 
		CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK18] Processo Finalizado para "+cEmpInt+"-"+cFilInt)	
	ENDIF
	
	UnLockByName("CJOBK18",.T.,.T.)	
	
ENDIF

RETURN

/*/{Protheus.doc} CJBK18PR
Integração ICN
@author danilo.grodzicki
@since 30/09/2020
@version 12.1.25
@type user function
/*/
Static Function CJBK18PR()

Local nI
Local cCod
Local cMsg
Local cTab
Local lRet
Local oWsdl
Local nValBa
Local cErros
Local cResposta
Local cUserName
Local cUfOrigem

Local cError   := ""
Local cWarning := ""

Local aOps    := {}
Local aSimple := {}

DbSelectArea("ZCN")
ZCN->(DbSetOrder(01))

DbSelectArea("ZCD")
ZCD->(DbSetOrder(01))

DbSelectArea("ZC5")
ZC5->(DbSetOrder(08))

DbSelectArea("ZC6")
ZC6->(DbSetOrder(04))

// Pega os registros que ainda não foram integrados
cTab := GetNextAlias()
BeginSql alias cTab
	SELECT ZCC.R_E_C_N_O_ AS RECNO
	FROM %table:ZCC% ZCC
	WHERE ZCC.ZCC_FILIAL = %xFilial:ZCC%
	  AND ZCC.ZCC_STATUS = '4'
	  AND ZCC.ZCC_CODINT IN ('  ','00','03','04')
	  AND ZCC.D_E_L_E_T_ = ' '
EndSql

//aRet := GETLastQuery()[2]
(cTab)->(DbGoTop())
if (cTab)->(Eof())
	(cTab)->(DbCloseArea())
	Return Nil
endif

CONOUT("[" + LEFT(DTOC(Date()),5) + "][" + LEFT(Time(),5) + "][CJOBK18] INICIO INTEGRACAO ICN")

while (cTab)->(!Eof())
	
	ZCC->(DbGoTo((cTab)->RECNO))
	
	CONOUT("[" + LEFT(DTOC(Date()),5) + "][" + LEFT(Time(),5) + "][CJOBK18] INTEGRACAO ICN RECNO:" + AllTrim(Str((cTab)->RECNO)))

	// Cria o objeto da classe TWsdlManager
	oWsdl := TWsdlManager():New()
	oWsdl:lSSLInsecure := .T.

	// Faz o parse da URL
	lRet := oWsdl:ParseURL( "https://convenios.ciee-rs.org.br/ICNRepasseRealizado_HLG/ICNRepasseRealizado.svc/basic" )
	if !lRet
		CONOUT("[" + LEFT(DTOC(Date()),5) + "][" + LEFT(Time(),5)+"][CJOBK18] " + oWsdl:cError)
		(cTab)->(DbSkip())
		FreeObj(oWsdl)
		loop
	endif

	// Mostra as operações disponiveis que vamos utilizar na função SetOperation
	aOps := oWsdl:ListOperations() 

	If Len( aOps ) == 0
		CONOUT("[" + LEFT(DTOC(Date()),5) + "][" + LEFT(Time(),5)+"][CJOBK18] " + oWsdl:cError)
		(cTab)->(DbSkip())
		FreeObj(oWsdl)
		loop
	EndIf

	// Define a operação que será utizada 
	lRet := oWsdl:SetOperation( aOps[1][1] )

	If !lRet
		CONOUT("[" + LEFT(DTOC(Date()),5) + "][" + LEFT(Time(),5)+"][CJOBK18] " + oWsdl:cError)
		(cTab)->(DbSkip())
		FreeObj(oWsdl)
		loop
	EndIf

	// Lista os tipos simples da mensagem de input envolvida na operação
	// Retorna um array contendo os tipos simples da mensagem do tipo input da operação ATUAL.
	aSimple := oWsdl:SimpleInput()

	ZCD->(DbSeek(xFilial("ZCD")+ZCC->ZCC_IDREP))
	while ZCD->ZCD_FILIAL+ZCD->ZCD_IDREP == xFilial("ZCD")+ZCC->ZCC_IDREP .and. ZCD->(!Eof())
		
		ZC5->(DbSeek(ZCD->ZCD_IDFATU))
		ZC6->(DbSeek(xFilial("ZC6")+ZCD->ZCD_IDFATU))
		
		// cUserName - Usuário do sistema
		if cEmpAnt == "03"
			cUserName := "CIEERJ"
		else
			cUserName := "CIEESP"
		endif

		// UF Origem
		if cEmpAnt == "03"
			cUfOrigem := "RJ"
		else
			cUfOrigem := "SP"
		endif

		// UF Destino
		if ZCC->ZCC_REPAPR == "P"  // Repasse pagar
			ZCN->(DbSeek(xFilial("ZCN")+ZCC->ZCC_AUTUPG))
		elseif ZCC->ZCC_REPAPR == "R"  // Repasse receber
			ZCN->(DbSeek(xFilial("ZCN")+ZCC->ZCC_AUTURC))
		endif

		// Valor da Bolsa
		cTab := GetNextAlias()
		BeginSql alias cTab
			SELECT ZC8.ZC8_VLPAG
			FROM %table:ZC8% ZC8
			WHERE ZC8.ZC8_FILIAL = %exp:ZC6->ZC6_FILIAL%
			AND ZC8.ZC8_IDFOL = %exp:ZC6->ZC6_IDFOLH%
			AND ZC8.ZC8_NUMTCE = %exp:ZC6->ZC6_TCETCA%
			AND ZC8.ZC8_TIPO = '1'
			AND ZC8.D_E_L_E_T_ = ' '
		EndSql
//		aRet   := GETLastQuery()[2]
		nValBa := 0
		(cTab)->(DbGoTop())
		if (cTab)->(!Eof())
			nValBA := (cTab)->ZC8_VLPAG
			(cTab)->(DbCloseArea())
		endif

		lRet := oWsdl:SetValue(aSimple[01][1],cUserName                                                                                                   )  // username - Usuário do sistema
		lRet := oWsdl:SetValue(aSimple[02][1],"ciee"                                                                                                      )  // password - Senha do usuário
		lRet := oWsdl:SetValue(aSimple[03][1],cUfOrigem                                                                                                   )  // reporigrep - UF Origem
		lRet := oWsdl:SetValue(aSimple[04][1],ZCN->ZCN_UF                                                                                                 )  // repdestrep - UF Destino
		lRet := oWsdl:SetValue(aSimple[05][1],Left(ZC6->ZC6_COMPET,2) + "/" + Right(ZC6->ZC6_COMPET,4)                                                    )  // repmesano - Mês/Ano de Repasse - COMPETENCIA A QUE SE REFERE O PAGAMENTO (COMPETENCIA DA COBRANCA)
		lRet := oWsdl:SetValue(aSimple[06][1],Left(DtoS(ZC6->ZC6_DATVEN),4) + "-" + Subs(DtoS(ZC6->ZC6_DATVEN),5,2) + "-" + Right(DtoS(ZC6->ZC6_DATVEN),2))  // repdatcob - Data Cobrança - DATA DO FATURAMENTO DA COBRANCA
		lRet := oWsdl:SetValue(aSimple[07][1],Left(DtoS(ZC6->ZC6_DATVEN),4) + "-" + Subs(DtoS(ZC6->ZC6_DATVEN),5,2) + "-" + Right(DtoS(ZC6->ZC6_DATVEN),2))  // repdatvct - Data Vencimento - DATA DO VENCIMENTO
		lRet := oWsdl:SetValue(aSimple[08][1],Left(DtoS(ZC6->ZC6_DATVEN),4) + "-" + Subs(DtoS(ZC6->ZC6_DATVEN),5,2) + "-" + Right(DtoS(ZC6->ZC6_DATVEN),2))  // repdatliq - Data Liquidação - DATA DE LIQUIDACAO
		lRet := oWsdl:SetValue(aSimple[09][1],Left(DtoS(ZCC->ZCC_EMISSA),4) + "-" + Subs(DtoS(ZCC->ZCC_EMISSA),5,2) + "-" + Right(DtoS(ZCC->ZCC_EMISSA),2))  // repdatrep - Data do Repasse - DATA DE AGENDAMENTO DO PAGAMENTO DO REPASSE
		lRet := oWsdl:SetValue(aSimple[10][1],AllTrim(Trans(nValBA,"@E 9999999999999.99"))                                                                )  // repvlrbol - Valor da Bolsa - VALOR DE BOLSA BASE
		lRet := oWsdl:SetValue(aSimple[11][1],AllTrim(Trans(ZC6->ZC6_VLRTOT,"@E 9999999999999.99"))                                                       )  // repvlrci - Valor do CI - VALOR DA CI FATURADA
		lRet := oWsdl:SetValue(aSimple[12][1],AllTrim(Trans(ZC6->ZC6_VLRTOT*0.9,"@E 9999999999999.99"))                                                   )  // repvlrrep - Valor do Repasse - 90% DA CI LIQUIDA PAGA (CI – DESCONTO)
		lRet := oWsdl:SetValue(aSimple[13][1],AllTrim(ZCC->ZCC_IDREP)                                                                                     )  // repsitorig - Situação Origem - CHAVE DE CONTROLE DO REPASSE (ID)
		lRet := oWsdl:SetValue(aSimple[14][1]," "                                                                                                         )  // repsitdest - Situação Destino - BRANCO
		lRet := oWsdl:SetValue(aSimple[15][1],"0.00"                                                                                                      )  // repvlrdesc - Valor do Desconto - VALOR DE DESCONTO NA COBRANCA(REF. AO REPASEE)
		lRet := oWsdl:SetValue(aSimple[16][1]," "                                                                                                         )  // repmotdesc - Motivo Desconto - MOTIVO DO DESCONTO
		lRet := oWsdl:SetValue(aSimple[17][1],AllTrim(ZC6->ZC6_TCETCA)                                                                                    )  // repcpf - CPF do Repasse - CONTRATO DE ESTAGIO (TCE)
		lRet := oWsdl:SetValue(aSimple[18][1],AllTrim(ZC6->ZC6_IDLCOT)                                                                                    )  // repcnpj - CNPJ do Repasse - LOCAL DO CONTRATO
		lRet := oWsdl:SetValue(aSimple[19][1],AllTrim(ZCC->ZCC_IDREP)                                                                                     )  // repcodloc - Código Local - CONTROLE DE REPASSE
		lRet := oWsdl:SetValue(aSimple[20][1]," "                                                                                                         )  // estcodloc - CONTROLES ICN (inicial em branco)
		lRet := oWsdl:SetValue(aSimple[21][1],ZCN->ZCN_UF                                                                                                 )  // estuf - UF do Estagiário - UF DE DESTINO DO REPASSE CONFORME A UNID. CIEE DO FATURAMENTO / PAGAMENTO RECEBIDO
		lRet := oWsdl:SetValue(aSimple[22][1]," "                                                                                                         )  // empcodloc - Código Local da Empresa - CONTROLES ICN (inicial em branco)
		lRet := oWsdl:SetValue(aSimple[23][1],ZCN->ZCN_UF                                                                                                 )  // empuf - UF da Empresa - UF DE DESTINO DO REPASSE CONFORME A UNID. CIEE DO FATURAMENTO / PAGAMENTO RECEBIDO
		lRet := oWsdl:SetValue(aSimple[24][1]," "                                                                                                         )  // etgcodloc - Código Local do Estágio - CONTROLES ICN (inicial em branco)
		lRet := oWsdl:SetValue(aSimple[25][1],ZCN->ZCN_UF                                                                                                 )  // etguf - UF do Estágio - UF DE DESTINO DO REPASSE CONFORME A UNID. CIEE DO FATURAMENTO / PAGAMENTO RECEBIDO

		If !lRet
			CONOUT("[" + LEFT(DTOC(Date()),5) + "][" + LEFT(Time(),5)+"][CJOBK18] " + oWsdl:cError)
			exit
		EndIf

		ZCD->(DbSkip())
	enddo

	If !lRet
		CONOUT("[" + LEFT(DTOC(Date()),5) + "][" + LEFT(Time(),5)+"][CJOBK18] " + oWsdl:cError)
		(cTab)->(DbSkip())
		FreeObj(oWsdl)
		loop
	EndIf
	
	// Exibe a mensagem que será enviada
	//conout( oWsdl:GetSoapMsg() )

	// Envia a mensagem SOAP ao servidor
	lRet := oWsdl:SendSoapMsg()
	If !lRet
		CONOUT("[" + LEFT(DTOC(Date()),5) + "][" + LEFT(Time(),5)+"][CJOBK18] " + oWsdl:cError)
		(cTab)->(DbSkip())
		FreeObj(oWsdl)
		loop
	EndIf

	// Pega a mensagem de resposta
	cResposta := oWsdl:GetSoapResponse()

	// Executa a leitura do XML de resposta
	oRet := XmlParser(cResposta,"_",@cError,@cWarning)
	IF !EMPTY(cError)
		CONOUT("[" + LEFT(DTOC(Date()),5) + "][" + LEFT(Time(),5)+"][CJOBK18] " + cError)
		(cTab)->(DbSkip())
		FreeObj(oRet)
		FreeObj(oWsdl)
		loop
	ELSE
		cResposta := oRet:_S_ENVELOPE:_S_BODY:_SAVERESPONSE:_SAVERESULT:TEXT
		FreeObj(oRet)
		oRet := XmlParser(cResposta,"_",@cError,@cWarning)
		IF !EMPTY(cError)
			CONOUT("[" + LEFT(DTOC(Date()),5) + "][" + LEFT(Time(),5)+"][CJOBK18] " + cError)
			(cTab)->(DbSkip())
			FreeObj(oRet)
			FreeObj(oWsdl)
			loop
		ELSE
			cCod   := oRet:_RETCIEE:_COD:TEXT
			cMsg   := oRet:_RETCIEE:_MSG:TEXT
			cErros := ""
			if cCod == "00"  // Erro
				for nI = 1 to LEN(oRet:_RETCIEE:_ERROS:_ERRO)
					if Empty(cErros)
						cErros := AllTrim(oRet:_RETCIEE:_ERROS:_ERRO[nI]:TEXT) + CRLF
					else
						cErros += AllTrim(oRet:_RETCIEE:_ERROS:_ERRO[nI]:TEXT) + CRLF
					endif
				next
				cStatus := "5"
			elseif cCod == "01" .or. cCod == "02"  // 01 = Inserido / 02 = Atualizado com sucesso
				cErros := ""
				cStatus := "6"
			elseif cCod == "03" .or. cCod == "04"  // Aviso
				for nI = 1 to LEN(oRet:_RETCIEE:_AVISOS:_AVISO)
					if Empty(cErros)
						cErros := AllTrim(oRet:_RETCIEE:_AVISOS:_AVISO[nI]:TEXT) + CRLF
					else
						cErros += AllTrim(oRet:_RETCIEE:_AVISOS:_AVISO[nI]:TEXT) + CRLF
					endif
				next
				cStatus := "5"
			endif
			ZCC->(RecLock("ZCC", .F.))
				ZCC->ZCC_STATUS := cStatus
				ZCC->ZCC_CODINT := cCod
				ZCC->ZCC_MSGINT := cMsg
				ZCC->ZCC_ERRAVI := cErros
			ZCC->(MsUnLock())
		ENDIF
	ENDIF

	FreeObj(oRet)
	FreeObj(oWsdl)

	(cTab)->(DbSkip())
enddo

CONOUT("[" + LEFT(DTOC(Date()),5) + "][" + LEFT(Time(),5) + "][CJOBK18] FIM INTEGRACAO ICN")

(cTab)->(DbCloseArea())

Return

/*/{Protheus.doc} Scheddef
Define parametros do processamento via schedule
@author carlos.henrique
@since 06/06/2019
@version undefined

@type function
/*/
Static Function Scheddef()
Local aParam := {"P","CJOBK18","",{},""}    
Return aParam