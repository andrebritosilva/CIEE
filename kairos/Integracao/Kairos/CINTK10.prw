#INCLUDE "TOTVS.CH"
#INCLUDE "RESTFUL.CH"
#INCLUDE "TBICONN.CH"

/*/{Protheus.doc} negociacao
Serviço de integração das negociações
@author carlos.henrique
@since 15/11/2019
@version undefined
@type class
/*/
WSRESTFUL negociacao DESCRIPTION "Serviço de integração das negociações" FORMAT APPLICATION_JSON
	WSMETHOD POST DESCRIPTION "Metodo de integração das negociações";
	WSSYNTAX "/negociacao/{id}";
	PATH "/negociacao/{id}"
END WSRESTFUL
/*/{Protheus.doc} POST
Realiza prorrogação da cobrança
@author carlos.henrique
@since 15/11/2019
@version undefined

@type function
/*/
WSMETHOD POST WSSERVICE negociacao

Local nTotParms	:= Len(::aURLParms)
Local cErro		:= ""

Private oJson
Private cJson     := ""
Private cTipInt	  := ""
Private dDtIniInt := Date()
Private cHrIniInt := Time()
Private cHrIniDw3 := ""
Private cHrFimDw3 := ""

If nTotParms >= 1 .And. Lower(::aURLParms[1]) == "prorrogacao"
	cTipInt:= "1"
ElseIf nTotParms >= 1 .And. Lower(::aURLParms[1]) == "abatimento"
	cTipInt:= "2"
ElseIf nTotParms >= 1 .And. Lower(::aURLParms[1]) == "parcelamento"
	cTipInt:= "3"
ElseIf nTotParms >= 1 .And. Lower(::aURLParms[1]) == "cancelamento"
	cTipInt:= "4"
ElseIf nTotParms >= 1 .And. Lower(::aURLParms[1]) == "agrupamento"
	cTipInt:= "5"
ElseIf nTotParms >= 1 .And. Lower(::aURLParms[1]) == "serasa"
	cTipInt:= "6"
ElseIf nTotParms >= 1 .And. Lower(::aURLParms[1]) == "global"
	cTipInt:= "7"
Else
	U_GrvLogKa("CINTK10", "POST", "2", "The server can't find the requested resource.","",Nil)
	Return U_RESTERRO(Self,"The server can't find the requested resource.")
Endif

DbSelectArea("ZC1")  // Locais de Contratos
ZC1->(DbSetOrder(01))

DbSelectArea("ZC3")  // Configuracoes de cobranca
ZC3->(DbSetOrder(01))

DbSelectArea("ZC4")  // Monitoramento de Notas
ZC4->(DbSetOrder(01))

DbSelectArea("ZC5")  // Monitoramento de Notas
ZC5->(DbOrderNickName("IDFATURAME"))

DbSelectArea("ZC7")  // Integracao do Pagamento de BA
ZC7->(DbSetOrder(01))

DbSelectArea("ZC9")  // Negociações
ZC9->(DbSetOrder(01))

DbSelectArea("SE1")  // Contas a Receber
SE1->(DbSetOrder(01))

::SetContentType('application/json')

oJson:= JsonObject():new()
oJson:fromJson(Self:GetContent(,.T.))

cJson := Self:GetContent(,.T.)

// Valida os dados do oJson
cErro := ValoJson(oJson,cTipInt)
if !Empty(cErro)
	U_GrvLogKa("CINTK10", "POST", "2", cErro, cJson, oJson)
	Return U_RESTERRO(Self,cErro)
endif

// Realiza a gravação na tabela ZC9
GravaZC9(oJson,cTipInt)

U_GrvLogKa("CINTK10", "POST", "1", "Integracao realizada com sucesso", cJson, oJson)

Return U_RESTOK(self,"Integracao realizada com sucesso")

/*/{Protheus.doc} ValoJson
Valida os dados do oJson
@author carlos.henrique
@since 15/11/2019
@version undefined

@type function
/*/
Static Function ValoJson(oJson,cTipNeg)

Local nI
Local cChave

Local cIdNeg     := ""
Local dDtaPro    := CtoD("")
Local nVlrAbt    := 0
//Local cRateio    := ""
Local cTipPar    := ""
Local dDatPar    := CtoD("")
Local dDtaVen    := CtoD("")
Local nVlrPar    := 0
Local cSerasa    := ""
Local cGlobal    := ""
Local cMotCanc   := ""
Local cRetorno   := ""
Local aTitCobr   := {}
Local cMotAgrup  := ""
Local nTotVlrPar := 0

Private cPrefix := ""
Private cNumTit := ""
Private cParTit := ""
Private cTipTit := ""

// Verifica se enviou o ID de negociação
cIdNeg := oJson[iif(cTipNeg == "5","agrupamento","sintetico")]:GetJsonText("idnegociacao")
if Empty(cIdNeg)
	Return("O ID de negociação é obrigatório.")
endif

// Verifica se já existe o ID da negociação
if ZC9->(DbSeek(xFilial("ZC9") + Padr(AllTrim(cIdNeg),FwTamSx3("ZC9_IDNEG")[1]," ") ))
	Return("O ID da negociação " + AllTrim(cIdNeg) + " já existe.")
endif

If cTipNeg == "5"  // Agrupamento
	
	// Verifica se enviou o motivo do agrupamento
	cMotAgrup := oJson["agrupamento"]:GetJsonText("motivoagrupamento")
	if Empty(cMotAgrup)
		Return("Motivo do agrupamento é obrigatório.")
	endif
	
	// Verifica se enviou ao menos uma parcela
	if Len(oJson["agrupamento"]["parcelas"]) <= 0
		Return("É obrigatório o envio de ao menos uma parcela.")
	endif
	
	// Valida a parcela enviada
	for nI = 1 to Len(oJson["agrupamento"]["parcelas"])
		
		// Verifica se enviou a data da parcela
		dDatPar := CtoD(oJson["agrupamento"]["parcelas"][nI]:GetJsonText("dataparcela"))
		if Empty(dDatPar)
			Return("Data da parcela é obrigatório.")
		endif
		
		// Verifica se enviou o valor da parcela
		nVlrPar := Val(oJson["agrupamento"]["parcelas"][nI]:GetJsonText("valor"))
		if nVlrPar <= 0
			Return("Valor da parcela é obrigatório.")
		endif
		
	next
	
	// Verifica se enviou ao menos um título de cobrança
	if Len(oJson["agrupamento"]["cobrancas"]) <= 0
		Return("É obrigatório o envio de ao menos um título de cobrança.")
	endif
	
	// Valida o título de cobrança enviado
	for nI = 1 to Len(oJson["agrupamento"]["cobrancas"])
		
		cChave := AllTrim(oJson["agrupamento"]["cobrancas"][nI]:GetJsonText("prefixotitulo"))+;
		          AllTrim(oJson["agrupamento"]["cobrancas"][nI]:GetJsonText("numerotitulo"))+;
		          AllTrim(oJson["agrupamento"]["cobrancas"][nI]:GetJsonText("parcelatitulo"))+;
		          AllTrim(oJson["agrupamento"]["cobrancas"][nI]:GetJsonText("tipotitulo"))
		
		if ascan(aTitCobr, {|x| x[1]==cChave}) <= 0
			aadd(aTitCobr,{cChave})
		else
			Return("Título de cobrança informado em duplicidade.")
		endif
		
		// Valida os tag's que são comuns
		cRetorno := ValInfCom(oJson,"A",nI)
		if !Empty(cRetorno)
			Return(cRetorno)
		endif
		
	next
	
Else
	
	// Valida os tag's que são comuns
	cRetorno := ValInfCom(oJson,"S")
	if !Empty(cRetorno)
		Return(cRetorno)
	endif
		
	// Verifica se o título já foi baixado
	If cTipNeg == "1" .or. cTipNeg == "2" .or. cTipNeg == "6" .or. cTipNeg == "7"  // Prorrogação ou Abatimento ou Serasa ou Global
		if SE1->E1_SALDO == 0 .and. !Empty(SE1->E1_BAIXA)
			Return("Titulo já baixado: " + CRLF + "Prefixo: " + cPrefix + CRLF + "Numero: " + cNumTit + CRLF + "Parcela: " + cParTit + CRLF + "Tipo: " + cTipTit + CRLF)
		endif
	endif
	
	If cTipNeg == "1"  // Prorrogação
		
		// Verifica se enviou a Data de Vencimento - Está data é utilizada na geração da instrução bancária (CFINA90.PRW)
		dDtaVen := CtoD(oJson["sintetico"]:GetJsonText("datavencimento"))
		if Empty(dDtaVen)
			Return("A data de vencimento é obrigatória.")
		endif
		
		if dDtaVen <> SE1->E1_VENCTO
			Return("A data de vencimento está diferente da data de vencimento do título: " + CRLF + "Data Vencimento: " + DtoC(dDtaVen) + CRLF + "Data Vencimento Título: " + DtoC(SE1->E1_VENCTO) + CRLF)
		endif

		// Verifica se enviou a Data de Prorrogação
		dDtaPro := CtoD(oJson["sintetico"]:GetJsonText("dataprorrogacao"))
		if Empty(dDtaPro)
			Return("A data de prorrogação é obrigatória.")
		endif
		
		// Verifica se a data de prorrogação é maior que a data de vencimento do título
		if dDtaPro <= SE1->E1_VENCTO
			Return("A data de prorrogação deve ser maior que a data de vencimento do título: " + CRLF + "Data Prorrogação: " + DtoC(dDtaPro) + CRLF + "Data Vencimento: " + DtoC(SE1->E1_VENCTO) + CRLF)
		endif
		
	elseIf cTipNeg == "2"  // Abatimento
		
		// Verifica se enviou o valor do abatimento
		nVlrAbt := Val(oJson["sintetico"]:GetJsonText("valorabatimento"))
		if nVlrAbt <= 0
			Return("O valor do abatimento é obrigatório.")
		endif
		
		// Verifica se o valor do abatimento não é maior ou igual ao valor do título
		if nVlrAbt >= SE1->E1_VALOR
			Return("O valor do abatimento não pode ser maior ou igual ao valor do título" + CRLF + " Valor abatimento: " + AllTrim( Str( nVlrAbt, FwTamSx3("E1_VALOR")[1], FwTamSx3("E1_VALOR")[2] ) ) + CRLF + "Valor do título: " + AllTrim( Str( SE1->E1_VALOR, FwTamSx3("E1_VALOR")[1], FwTamSx3("E1_VALOR")[2] ) ) + CRLF)
		endif
		
		// Se tem rateio, tem que enviar ao menos um analítico
//		cRateio := oJson["sintetico"]:GetJsonText("rateio")
//		if cRateio == "1"
//			if Len(oJson["sintetico"]["analitico"]) <= 0
//				Return("Se tem Rateio, é obrigatório o envio do analítico do Rateio.")
//			endif
//		endif
		
	elseIf cTipNeg == "3"  // Parcelamento
		
		// Verifica se enviou o tipo de valor parcelado
		cTipPar := oJson["sintetico"]:GetJsonText("tipovalorparcelado")
		if Empty(cTipPar)
			Return("Tipo de valor parcelado é obrigatório.")
		else
			if !(AllTrim(cTipPar) $ "12")
				Return("Tipo de valor parcelado: " + AllTrim(cTipPar) + " inválido.")
			endif
		endif
		
		if cTipPar == "1"  // Verifica se enviou o valor original
			if Val(oJson["sintetico"]:GetJsonText("valororiginal")) <= 0
				Return("Valor original do titulo é obrigatório.")
			endif
		else               // Verifica se enviou o valor atualizado
			if Val(oJson["sintetico"]:GetJsonText("valoratualizado")) <= 0
				Return("Valor atualizado do titulo é obrigatório.")
			endif
		endif
		
		// Verifica se envio as parcelas
		if Len(oJson["sintetico"]["parcelas"]) <= 0
			Return("O envio das parcelas é obrigatório.")
		else
			// Valida o conteúdo das parcelas
			nTotVlrPar := 0
			for nI = 1 to Len(oJson["sintetico"]["parcelas"])
				
				// Verifica se enviou a data da parcela
				dDatPar := CtoD(oJson["sintetico"]["parcelas"][nI]:GetJsonText("dataparcela"))
				if Empty(dDatPar)
					Return("Data da parcela é obrigatório.")
				endif
				
				// Verifica se enviou o valor da parcela
				nVlrPar := Val(oJson["sintetico"]["parcelas"][nI]:GetJsonText("valor"))
				if nVlrPar <= 0
					Return("Valor da parcela é obrigatório.")
				else
					nTotVlrPar += nVlrPar
				endif
				
			next
			
			if cTipPar == "1"  // Verifica se o total das parcelas não é maior que o valor original
				if nTotVlrPar > Val(oJson["sintetico"]:GetJsonText("valororiginal"))
					Return("O total das parcelas " + AllTrim( Str( nTotVlrPar, FwTamSx3("E1_VALOR")[1], FwTamSx3("E1_VALOR")[2] ) ) + CRLF + " nao pode ser maior que o valor original do titulo " + AllTrim( Str( Val(oJson["sintetico"]:GetJsonText("valororiginal")), FwTamSx3("E1_VALOR")[1], FwTamSx3("E1_VALOR")[2] ) ))
				endif
			else               // Verifica se o total das parcelas não é maior que o valor atualizado
				if nTotVlrPar > Val(oJson["sintetico"]:GetJsonText("valoratualizado"))
					Return("O total das parcelas " + AllTrim( Str( nTotVlrPar, FwTamSx3("E1_VALOR")[1], FwTamSx3("E1_VALOR")[2] ) ) + CRLF + " nao pode ser maior que o valor atualizado do titulo " + AllTrim( Str( Val(oJson["sintetico"]:GetJsonText("valoratualizado")), FwTamSx3("E1_VALOR")[1], FwTamSx3("E1_VALOR")[2] ) ))
				endif
			endif
			
		endif
		
	elseIf cTipNeg == "4"  // Cancelamento
		
		// Verifica se enviou o motivo do cancelamento
		cMotCanc := oJson["sintetico"]:GetJsonText("motivocancelamento")
		if Empty(cMotCanc)
			Return("Motivo do cancelamento é obrigatório.")
		endif
		
	elseIf cTipNeg == "6"  // Serasa
		
		// Verifica se enviou a tag serasa
		cSerasa := oJson["sintetico"]:GetJsonText("serasa")
		if Empty(cSerasa)
			Return("Serasa é obrigatório.")
		elseif !(cSerasa $ "12")
			Return("Serasa " + AllTrim(cSerasa) + " inválido.")
		endif
		
	elseIf cTipNeg == "7"  // Global
		
		// Verifica se enviou a tab global
		cGlobal := oJson["sintetico"]:GetJsonText("global")
		if Empty(cGlobal)
			Return("Global é obrigatório.")
		elseif !(cGlobal $ "12")
			Return("Global " + AllTrim(cGlobal) + " inválido.")
		endif
		
	endif
	
endif				

Return("")

/*/{Protheus.doc} ValInfCom
Realiza a validação das informações comuns do jSon
@author Danilo José Grodzicki
@since 06/02/2020
@version undefined
@type function
/*/
Static Function ValInfCom(oJson,cTag,nI)

Local cZC7       := GetNextAlias()
Local cIdFatu    := ""
Local cIdCont    := ""
Local cConFat    := ""
Local cIdFolha   := ""
Local cConCob    := ""
Local lValFolha  := .F.

// Verifica se enviou o ID do faturamento
if cTag == "S"
	cIdFatu := oJson["sintetico"]:GetJsonText("idfatura")
else
	cIdFatu := oJson["agrupamento"]["cobrancas"][nI]:GetJsonText("idfatura")
endif
if Empty(cIdFatu)
	Return("O ID do faturamento é obrigatório.")
endif

// Verifica se existe o ID do faturamento
if !ZC5->(DbSeek(Padr(AllTrim(cIdFatu),FwTamSx3("ZC5_IDFATU")[1]," ") ))
	Return("ID do faturamento " + AllTrim(cIdFatu) + " não existe.")
else
	if !Empty(ZC5->ZC5_IDFOLH)
		lValFolha  := .T.
	endif
endif

// Verifica se enviou o ID do contrato
if cTag == "S"
	cIdCont := oJson["sintetico"]:GetJsonText("idcontrato")
else
	cIdCont := oJson["agrupamento"]["cobrancas"][nI]:GetJsonText("idcontrato")
endif
if Empty(cIdCont)
	Return("O ID do contrato é obrigatório.")
endif

// Verifica se existe o ID contrato
if !ZC1->(DbSeek(xFilial("ZC1") + Padr(AllTrim(cIdCont),FwTamSx3("ZC1_CODIGO")[1]," ") ))
	Return("O ID do contrato " + AllTrim(cIdCont) + " não existe.")
endif

// Verifica se enviou o ID da configuração do faturamento
if cTag == "S"
	cConFat := oJson["sintetico"]:GetJsonText("idconfiguracaofaturamento")
else
	cConFat := oJson["agrupamento"]["cobrancas"][nI]:GetJsonText("idconfiguracaofaturamento")
endif
if Empty(cConFat)
	Return("O ID da configuração do faturamento é obrigatório.")
endif

// Verifica se existe o ID da configuração do faturamento
if !ZC4->(DbSeek(xFilial("ZC4") + Padr(AllTrim(cConFat),FwTamSx3("ZC4_IDFATU")[1]," ") ))
	Return("O ID da configuração do faturamento " + AllTrim(cConFat) + " não existe.")
endif

if lValFolha
	// Verifica se enviou o ID da folha
	if cTag == "S"
		cIdFolha := oJson["sintetico"]:GetJsonText("idfolha")
	else
		cIdFolha := oJson["agrupamento"]["cobrancas"][nI]:GetJsonText("idfolha")
	endif
	if Empty(cIdFolha)
		Return("O ID da folha é obrigatório.")
	endif

	// Verifica se existe o ID da folha
	BeginSql Alias cZC7
		SELECT R_E_C_N_O_ AS RECZC7
		FROM %TABLE:ZC7% ZC7
		WHERE ZC7_FILIAL = %xfilial:ZC7%
		AND ZC7_IDCNTT = %Exp:cIdCont%
		AND ZC7_IDFOL = %Exp:cIdFolha%
		AND ZC7.D_E_L_E_T_ = ''
	EndSql

	//	aRet := GETLastQuery()[2]

	(cZC7)->(dbSelectArea((cZC7)))
	(cZC7)->(dbGoTop())
	if (cZC7)->(Eof())
		Return("O ID da folha " + AllTrim(cIdFolha) + " para o contrato " + AllTrim(cIdCont) + " não existe.")
	endif
	(cZC7)->(dbCloseArea())
endif

// Verifica se enviou o ID da configuração de cobrança
if cTag == "S"
	cConCob := oJson["sintetico"]:GetJsonText("idconfiguracaocobranca")
else
	cConCob := oJson["agrupamento"]["cobrancas"][nI]:GetJsonText("idconfiguracaocobranca")
endif
if Empty(cConCob)
	Return("O ID da configuração de cobrança é obrigatório.")
endif

// Verifica se existe o ID da configuração de cobrança
if !ZC3->(DbSeek(xFilial("ZC3") + Padr(AllTrim(cConCob),FwTamSx3("ZC3_IDCOBR")[1]," ") ))
	Return("O ID da configuração de cobrança " + AllTrim(cConCob) + " não existe.")
endif

if cTag == "S"
	cPrefix := AVKEY(oJson["sintetico"]:GetJsonText("prefixotitulo") ,"E1_PREFIXO")
	cNumTit := AVKEY(oJson["sintetico"]:GetJsonText("numerotitulo")  ,"E1_NUM"    )
	cParTit := AVKEY(oJson["sintetico"]:GetJsonText("parcelatitulo") ,"E1_PARCELA")
	cTipTit := AVKEY(oJson["sintetico"]:GetJsonText("tipotitulo")    ,"E1_TIPO"   )
else
	cPrefix := AVKEY(oJson["agrupamento"]["cobrancas"][nI]:GetJsonText("prefixotitulo") ,"E1_PREFIXO")
	cNumTit := AVKEY(oJson["agrupamento"]["cobrancas"][nI]:GetJsonText("numerotitulo")  ,"E1_NUM"    )
	cParTit := AVKEY(oJson["agrupamento"]["cobrancas"][nI]:GetJsonText("parcelatitulo") ,"E1_PARCELA")
	cTipTit := AVKEY(oJson["agrupamento"]["cobrancas"][nI]:GetJsonText("tipotitulo")    ,"E1_TIPO"   )
endif

if Empty(cNumTit)
	Return("O numero do titulo é obrigatório.")
endif

// Verifica se o título existe
if !SE1->(DbSeek(xFilial("SE1") + cPrefix + cNumTit + cParTit + cTipTit ))
	Return("Não existe titulo para a chave: " + CRLF + "Prefixo:" + AllTrim(cPrefix) + CRLF + "Numero:" + AllTrim(cNumTit) + CRLF + "Parcela:" + AllTrim(cParTit) + CRLF + "Tipo:" + AllTrim(cTipTit) + CRLF)
endif

Return("")

/*/{Protheus.doc} GravaZC9
Realiza a gravação na tabela ZC9
@author carlos.henrique
@since 15/11/2019
@version undefined

@type function
/*/
Static Function GravaZC9(oJson,cTipNeg)

Local cIdNeg  := ""
Local cIdFatu := ""
Local cIdCont := ""
Local cIdFolha:= ""
Local cConFat := ""
Local cConCob := ""
Local cPrefix := ""
Local cNumTit := ""
Local cParTit := ""
Local cTipTit := ""
Local cVlrOri := ""
Local cVlrAtu := ""
Local cDatOri := ""
Local cDatAtu := ""
Local cBcoFat := ""
Local cMsgNot := ""
Local cDtaPro := ""
Local cVlrAbt := ""
Local cRateio := ""
Local cTipPar := ""
Local cMotivo := ""
Local cSerasa := ""
Local cGlobal := ""
Local nTotList:= 0
Local nCnta   := 0

if cTipNeg == "1"  // Prorrogação
	
	cIdNeg  := oJson["sintetico"]:GetJsonText("idnegociacao")
	cIdFatu := oJson["sintetico"]:GetJsonText("idfatura")
	cIdCont := oJson["sintetico"]:GetJsonText("idcontrato")
	cIdFolha:= oJson["sintetico"]:GetJsonText("idfolha")
	cConFat := oJson["sintetico"]:GetJsonText("idconfiguracaofaturamento")
	cConCob := oJson["sintetico"]:GetJsonText("idconfiguracaocobranca")
	cPrefix := oJson["sintetico"]:GetJsonText("prefixotitulo")
	cNumTit := oJson["sintetico"]:GetJsonText("numerotitulo")
	cParTit := oJson["sintetico"]:GetJsonText("parcelatitulo")
	cTipTit := oJson["sintetico"]:GetJsonText("tipotitulo")
	cVlrOri := oJson["sintetico"]:GetJsonText("valortotal")
	cDatOri := oJson["sintetico"]:GetJsonText("datavencimento")
	cBcoFat := oJson["sintetico"]:GetJsonText("bancofaturamento")
	cMsgNot := oJson["sintetico"]:GetJsonText("mensagemnota")
	cDtaPro := oJson["sintetico"]:GetJsonText("dataprorrogacao")
	cMotivo := DecodeUTF8(oJson["sintetico"]:GetJsonText("motivoprorrogacao"))
	
	Begin Transaction
		
		RecLock("ZC9",.T.)
			ZC9->ZC9_FILIAL := xFilial("ZC9")
			ZC9->ZC9_IDNEG	:= cIdNeg
			ZC9->ZC9_TIPNEG := cTipNeg
			ZC9->ZC9_IDFATU := cIdFatu
			ZC9->ZC9_IDCONT := cIdCont
			ZC9->ZC9_IDFOLH := cIdFolha
			ZC9->ZC9_CONFAT := cConFat
			ZC9->ZC9_CONCOB := cConCob
			ZC9->ZC9_PREFIX := cPrefix
			ZC9->ZC9_NUMTIT := cNumTit
			ZC9->ZC9_PARTIT := cParTit
			ZC9->ZC9_TIPTIT := cTipTit
			ZC9->ZC9_VLRORI := VAL(cVlrOri)
			ZC9->ZC9_DATORI := CTOD(cDatOri)
			ZC9->ZC9_BCOFAT := cBcoFat
			ZC9->ZC9_MSGNOT := cMsgNot
			ZC9->ZC9_DATPRO := CTOD(cDtaPro)
			ZC9->ZC9_MOTIVO	:= cMotivo
			ZC9->ZC9_KAIROS := "N" //Realiza integração Kairós
			ZC9->ZC9_INTDW3 := "S" //Realiza integração DW3
			ZC9->ZC9_STATUS := "1" // Pendente
			ZC9->ZC9_DTINTE := Date()
			ZC9->ZC9_HRINTE := Time()
			ZC9->ZC9_JSON   := cJson
		ZC9->(MsUnLock())

		// Grava a aprovção
		nTotList := Len(oJson["sintetico"]["aprovacao"])
		
		For nCnta:= 1 TO nTotList
			
			RecLock("ZCK",.T.)
				ZCK->ZCK_FILIAL := xFilial("ZCK")
				ZCK->ZCK_IDNEG  := cIdNeg
				ZCK->ZCK_NOME   := DecodeUTF8(oJson["sintetico"]["aprovacao"][nCnta]:GetJsonText("nome"))
				ZCK->ZCK_DATA   := CtoD(oJson["sintetico"]["aprovacao"][nCnta]:GetJsonText("data"))
				ZCK->ZCK_HORA   := oJson["sintetico"]["aprovacao"][nCnta]:GetJsonText("hora")
				ZCK->ZCK_CHAMAD := oJson["sintetico"]["aprovacao"][nCnta]:GetJsonText("chamado")
			ZCK->(MsUnLock())
			
		Next
		
	End Transaction
	
Elseif cTipNeg == "2"  // Abatimento 

	cIdNeg  := oJson["sintetico"]:GetJsonText("idnegociacao")
	cIdFatu := oJson["sintetico"]:GetJsonText("idfatura")
	cIdCont := oJson["sintetico"]:GetJsonText("idcontrato")
	cIdFolha:= oJson["sintetico"]:GetJsonText("idfolha")
	cConFat := oJson["sintetico"]:GetJsonText("idconfiguracaofaturamento")
	cConCob := oJson["sintetico"]:GetJsonText("idconfiguracaocobranca")
	cPrefix := oJson["sintetico"]:GetJsonText("prefixotitulo")
	cNumTit := oJson["sintetico"]:GetJsonText("numerotitulo")
	cParTit := oJson["sintetico"]:GetJsonText("parcelatitulo")
	cTipTit := oJson["sintetico"]:GetJsonText("tipotitulo")
	cVlrOri := oJson["sintetico"]:GetJsonText("valororiginal")
	cVlrAtu := oJson["sintetico"]:GetJsonText("valoratualizado")
	cDatOri := oJson["sintetico"]:GetJsonText("datavencimentooriginal")
	cDatAtu := oJson["sintetico"]:GetJsonText("datavencimentoatualizada")
	cBcoFat := oJson["sintetico"]:GetJsonText("bancofaturamento")
	cMsgNot := oJson["sintetico"]:GetJsonText("mensagemnota")
	cVlrAbt := oJson["sintetico"]:GetJsonText("valorabatimento")
	cRateio := oJson["sintetico"]:GetJsonText("rateio")
	cMotivo := DecodeUTF8(oJson["sintetico"]:GetJsonText("motivorateio"))
	
	Begin Transaction
			
		RecLock("ZC9",.T.)
			ZC9->ZC9_FILIAL := xFilial("ZC9")
			ZC9->ZC9_IDNEG	:= cIdNeg
			ZC9->ZC9_TIPNEG := cTipNeg
			ZC9->ZC9_IDFATU := cIdFatu
			ZC9->ZC9_IDCONT := cIdCont
			ZC9->ZC9_IDFOLH := cIdFolha
			ZC9->ZC9_CONFAT := cConFat
			ZC9->ZC9_CONCOB := cConCob
			ZC9->ZC9_PREFIX := cPrefix
			ZC9->ZC9_NUMTIT := cNumTit
			ZC9->ZC9_PARTIT := cParTit
			ZC9->ZC9_TIPTIT := cTipTit			
			ZC9->ZC9_VLRORI := VAL(cVlrOri)
			ZC9->ZC9_VLRATU := VAL(cVlrAtu)
			ZC9->ZC9_DATORI := CTOD(cDatOri)
			ZC9->ZC9_DATATU := CTOD(cDatAtu) 
			ZC9->ZC9_BCOFAT := cBcoFat
			ZC9->ZC9_MSGNOT := cMsgNot
			ZC9->ZC9_RATABT := cRateio //1=Sim;2=Não
			ZC9->ZC9_VLRABT := VAL(cVlrAbt)
			ZC9->ZC9_MOTIVO := cMotivo			
			ZC9->ZC9_KAIROS := "N" //Realiza integração Kairós 
			ZC9->ZC9_INTDW3 := "S" //Realiza integração DW3				
			ZC9->ZC9_STATUS := "1" // Pendente
			ZC9->ZC9_DTINTE := Date()
			ZC9->ZC9_HRINTE := Time()
			ZC9->ZC9_JSON   := cJson
		ZC9->(MsUnLock())

		// Grava a aprovção
		nTotList := Len(oJson["sintetico"]["aprovacao"])
		
		For nCnta:= 1 TO nTotList
			
			RecLock("ZCK",.T.)
				ZCK->ZCK_FILIAL := xFilial("ZCK")
				ZCK->ZCK_IDNEG  := cIdNeg
				ZCK->ZCK_NOME   := DecodeUTF8(oJson["sintetico"]["aprovacao"][nCnta]:GetJsonText("nome"))
				ZCK->ZCK_DATA   := CtoD(oJson["sintetico"]["aprovacao"][nCnta]:GetJsonText("data"))
				ZCK->ZCK_HORA   := oJson["sintetico"]["aprovacao"][nCnta]:GetJsonText("hora")
				ZCK->ZCK_CHAMAD := oJson["sintetico"]["aprovacao"][nCnta]:GetJsonText("chamado")
			ZCK->(MsUnLock())
			
		Next
		
		// Grava o analítico
		nTotList := Len(oJson["sintetico"]["analitico"])
		
		For nCnta:= 1 TO nTotList
		
			RecLock("ZCU",.T.)
				ZCU->ZCU_FILIAL := xFilial("ZCU")
				ZCU->ZCU_IDNEG  := cIdNeg
				ZCU->ZCU_ANALIT := oJson["sintetico"]["analitico"][nCnta]:GetJsonText("id")
				ZCU->ZCU_VALOR  := Val(oJson["sintetico"]["analitico"][nCnta]:GetJsonText("valorabatimento"))
				ZCU->ZCU_MOTIVO := DecodeUTF8(oJson["sintetico"]["analitico"][nCnta]:GetJsonText("motivoabatimento"))
			ZCU->(MsUnLock())
			
		Next
			
	End Transaction	
	
Elseif cTipNeg == "3"  // Parcelamento 

	cIdNeg  := oJson["sintetico"]:GetJsonText("idnegociacao")
	cIdFatu := oJson["sintetico"]:GetJsonText("idfatura")
	cIdCont := oJson["sintetico"]:GetJsonText("idcontrato")
	cIdFolha:= oJson["sintetico"]:GetJsonText("idfolha")
	cConFat := oJson["sintetico"]:GetJsonText("idconfiguracaofaturamento")
	cConCob := oJson["sintetico"]:GetJsonText("idconfiguracaocobranca")
	cPrefix := oJson["sintetico"]:GetJsonText("prefixotitulo")
	cNumTit := oJson["sintetico"]:GetJsonText("numerotitulo")
	cParTit := oJson["sintetico"]:GetJsonText("parcelatitulo")
	cTipTit := oJson["sintetico"]:GetJsonText("tipotitulo")
	cVlrOri := oJson["sintetico"]:GetJsonText("valororiginal")
	cVlrAtu := oJson["sintetico"]:GetJsonText("valoratualizado")
	cDatOri := oJson["sintetico"]:GetJsonText("datavencimento")
	cBcoFat := oJson["sintetico"]:GetJsonText("bancofaturamento")
	cMsgNot := oJson["sintetico"]:GetJsonText("mensagemnota")
	cTipPar := oJson["sintetico"]:GetJsonText("tipovalorparcelado")
	cMotivo := DecodeUTF8(oJson["sintetico"]:GetJsonText("motivoparcelamento"))

	Begin Transaction
			
		RecLock("ZC9",.T.)
			ZC9->ZC9_FILIAL := xFilial("ZC9")
			ZC9->ZC9_IDNEG	:= cIdNeg
			ZC9->ZC9_TIPNEG := cTipNeg
			ZC9->ZC9_IDFATU := cIdFatu
			ZC9->ZC9_IDCONT := cIdCont
			ZC9->ZC9_IDFOLH := cIdFolha
			ZC9->ZC9_CONFAT := cConFat
			ZC9->ZC9_CONCOB := cConCob
			ZC9->ZC9_PREFIX := cPrefix
			ZC9->ZC9_NUMTIT := cNumTit
			ZC9->ZC9_PARTIT := cParTit
			ZC9->ZC9_TIPTIT := cTipTit			
			ZC9->ZC9_VLRORI := VAL(cVlrOri)
			ZC9->ZC9_VLRATU := VAL(cVlrAtu)
			ZC9->ZC9_DATORI := CTOD(cDatOri)
			ZC9->ZC9_BCOFAT := cBcoFat
			ZC9->ZC9_MSGNOT := cMsgNot
			ZC9->ZC9_TIPPAR := cTipPar //1=Valor original;2=Valor atualizado
			ZC9->ZC9_MOTIVO := cMotivo
			ZC9->ZC9_KAIROS := "N" //Realiza integração Kairós 
			ZC9->ZC9_INTDW3 := "S" //Realiza integração DW3				
			ZC9->ZC9_STATUS := "1" // Pendente
			ZC9->ZC9_DTINTE := Date()
			ZC9->ZC9_HRINTE := Time()
			ZC9->ZC9_JSON   := cJson
		ZC9->(MsUnLock())

		// Grava a aprovção
		nTotList := Len(oJson["sintetico"]["aprovacao"])
		
		For nCnta:= 1 TO nTotList
			
			RecLock("ZCK",.T.)
				ZCK->ZCK_FILIAL := xFilial("ZCK")
				ZCK->ZCK_IDNEG  := cIdNeg
				ZCK->ZCK_NOME   := DecodeUTF8(oJson["sintetico"]["aprovacao"][nCnta]:GetJsonText("nome"))
				ZCK->ZCK_DATA   := CtoD(oJson["sintetico"]["aprovacao"][nCnta]:GetJsonText("data"))
				ZCK->ZCK_HORA   := oJson["sintetico"]["aprovacao"][nCnta]:GetJsonText("hora")
				ZCK->ZCK_CHAMAD := oJson["sintetico"]["aprovacao"][nCnta]:GetJsonText("chamado")
			ZCK->(MsUnLock())
			
		Next

		// Grava as parcelas
		nTotList := Len(oJson["sintetico"]["parcelas"])
		
		For nCnta:= 1 TO nTotList
		
			RecLock("ZCJ",.T.)
				ZCJ->ZCJ_FILIAL := xFilial("ZCJ")
				ZCJ->ZCJ_IDNEG  := cIdNeg
				ZCJ->ZCJ_PARCEL := CtoD(oJson["sintetico"]["parcelas"][nCnta]:GetJsonText("dataparcela"))
				ZCJ->ZCJ_VALOR  := Val(oJson["sintetico"]["parcelas"][nCnta]:GetJsonText("valor"))
			ZCJ->(MsUnLock())
			
		Next
			
	End Transaction		

Elseif cTipNeg == "4"  // Cancelamento

	cIdNeg  := oJson["sintetico"]:GetJsonText("idnegociacao")
	cIdFatu := oJson["sintetico"]:GetJsonText("idfatura")
	cIdCont := oJson["sintetico"]:GetJsonText("idcontrato")
	cIdFolha:= oJson["sintetico"]:GetJsonText("idfolha")
	cConFat := oJson["sintetico"]:GetJsonText("idconfiguracaofaturamento")
	cConCob := oJson["sintetico"]:GetJsonText("idconfiguracaocobranca")
	cPrefix := oJson["sintetico"]:GetJsonText("prefixotitulo")
	cNumTit := oJson["sintetico"]:GetJsonText("numerotitulo")
	cParTit := oJson["sintetico"]:GetJsonText("parcelatitulo")
	cTipTit := oJson["sintetico"]:GetJsonText("tipotitulo")
	cVlrOri := oJson["sintetico"]:GetJsonText("valortotal")
	cDatOri := oJson["sintetico"]:GetJsonText("datavencimento")
	cBcoFat := oJson["sintetico"]:GetJsonText("bancofaturamento")
	cMsgNot := oJson["sintetico"]:GetJsonText("mensagemnota")
	cMotivo := DecodeUTF8(oJson["sintetico"]:GetJsonText("motivocancelamento"))
	
	Begin Transaction
			
		RecLock("ZC9",.T.)
			ZC9->ZC9_FILIAL := xFilial("ZC9")
			ZC9->ZC9_IDNEG	:= cIdNeg
			ZC9->ZC9_TIPNEG := cTipNeg
			ZC9->ZC9_IDFATU := cIdFatu
			ZC9->ZC9_IDCONT := cIdCont
			ZC9->ZC9_IDFOLH := cIdFolha
			ZC9->ZC9_CONFAT := cConFat
			ZC9->ZC9_CONCOB := cConCob
			ZC9->ZC9_PREFIX := cPrefix
			ZC9->ZC9_NUMTIT := cNumTit
			ZC9->ZC9_PARTIT := cParTit
			ZC9->ZC9_TIPTIT := cTipTit			
			ZC9->ZC9_VLRORI := VAL(cVlrOri)
			ZC9->ZC9_DATORI := CTOD(cDatOri)
			ZC9->ZC9_BCOFAT := cBcoFat
			ZC9->ZC9_MSGNOT := cMsgNot
			ZC9->ZC9_MOTIVO	:= cMotivo
			ZC9->ZC9_KAIROS := "N" //Realiza integração Kairós 
			ZC9->ZC9_INTDW3 := "S" //Realiza integração DW3				
			ZC9->ZC9_STATUS := "1" // Pendente
			ZC9->ZC9_DTINTE := Date()
			ZC9->ZC9_HRINTE := Time()
			ZC9->ZC9_JSON   := cJson
		ZC9->(MsUnLock())

		// Grava a aprovção
		nTotList := Len(oJson["sintetico"]["aprovacao"])
		
		For nCnta:= 1 TO nTotList
			
			RecLock("ZCK",.T.)
				ZCK->ZCK_FILIAL := xFilial("ZCK")
				ZCK->ZCK_IDNEG  := cIdNeg
				ZCK->ZCK_NOME   := DecodeUTF8(oJson["sintetico"]["aprovacao"][nCnta]:GetJsonText("nome"))
				ZCK->ZCK_DATA   := CtoD(oJson["sintetico"]["aprovacao"][nCnta]:GetJsonText("data"))
				ZCK->ZCK_HORA   := oJson["sintetico"]["aprovacao"][nCnta]:GetJsonText("hora")
				ZCK->ZCK_CHAMAD := oJson["sintetico"]["aprovacao"][nCnta]:GetJsonText("chamado")
			ZCK->(MsUnLock())
			
		Next
			
	End Transaction
	
	
Elseif cTipNeg == "5"  // Agrupamento
	
	cIdNeg  := oJson["agrupamento"]:GetJsonText("idnegociacao")
	cMotivo := DecodeUTF8(oJson["agrupamento"]:GetJsonText("motivoagrupamento"))
	
	Begin Transaction
		
		nTotList := Len(oJson["agrupamento"]["cobrancas"])
		
		For nCnta:= 1 TO nTotList
		
			cIdFatu := oJson["agrupamento"]["cobrancas"][nCnta]:GetJsonText("idfatura")
			cIdCont := oJson["agrupamento"]["cobrancas"][nCnta]:GetJsonText("idcontrato")
			cConFat := oJson["agrupamento"]["cobrancas"][nCnta]:GetJsonText("idconfiguracaofaturamento")
			cIdFolha:= oJson["agrupamento"]["cobrancas"][nCnta]:GetJsonText("idfolha")
			cConCob := oJson["agrupamento"]["cobrancas"][nCnta]:GetJsonText("idconfiguracaocobranca")
			cPrefix := oJson["agrupamento"]["cobrancas"][nCnta]:GetJsonText("prefixotitulo")
			cNumTit := oJson["agrupamento"]["cobrancas"][nCnta]:GetJsonText("numerotitulo")
			cParTit := oJson["agrupamento"]["cobrancas"][nCnta]:GetJsonText("parcelatitulo")
			cTipTit := oJson["agrupamento"]["cobrancas"][nCnta]:GetJsonText("tipotitulo")
			cVlrOri := oJson["agrupamento"]["cobrancas"][nCnta]:GetJsonText("valortotal")
			cDatOri := oJson["agrupamento"]["cobrancas"][nCnta]:GetJsonText("datavencimento")
			cBcoFat := oJson["agrupamento"]["cobrancas"][nCnta]:GetJsonText("bancofaturamento")
			cMsgNot := oJson["agrupamento"]["cobrancas"][nCnta]:GetJsonText("mensagemnota")		
			
			RecLock("ZC9",.T.)
				ZC9->ZC9_FILIAL := xFilial("ZC9")
				ZC9->ZC9_IDNEG	:= cIdNeg
				ZC9->ZC9_TIPNEG := cTipNeg
				ZC9->ZC9_IDFATU := cIdFatu
				ZC9->ZC9_IDCONT := cIdCont
				ZC9->ZC9_IDFOLH := cIdFolha
				ZC9->ZC9_CONFAT := cConFat
				ZC9->ZC9_CONCOB := cConCob
				ZC9->ZC9_PREFIX := cPrefix
				ZC9->ZC9_NUMTIT := cNumTit
				ZC9->ZC9_PARTIT := cParTit
				ZC9->ZC9_TIPTIT := cTipTit			
				ZC9->ZC9_VLRORI := VAL(cVlrOri)
				ZC9->ZC9_DATORI := CTOD(cDatOri)
				ZC9->ZC9_BCOFAT := cBcoFat
				ZC9->ZC9_MSGNOT := cMsgNot
				ZC9->ZC9_MOTIVO	:= cMotivo
				ZC9->ZC9_KAIROS := "N" //Realiza integração Kairós 
				ZC9->ZC9_INTDW3 := "S" //Realiza integração DW3					
				ZC9->ZC9_STATUS := "1" // Pendente
				ZC9->ZC9_DTINTE := Date()
				ZC9->ZC9_HRINTE := Time()
				ZC9->ZC9_JSON   := cJson
			ZC9->(MsUnLock())
		
		Next

		// Grava a aprovção
		nTotList := Len(oJson["agrupamento"]["aprovacao"])
		
		For nCnta:= 1 TO nTotList
			
			RecLock("ZCK",.T.)
				ZCK->ZCK_FILIAL := xFilial("ZCK")
				ZCK->ZCK_IDNEG  := cIdNeg
				ZCK->ZCK_NOME   := DecodeUTF8(oJson["agrupamento"]["aprovacao"][nCnta]:GetJsonText("nome"))
				ZCK->ZCK_DATA   := CtoD(oJson["agrupamento"]["aprovacao"][nCnta]:GetJsonText("data"))
				ZCK->ZCK_HORA   := oJson["agrupamento"]["aprovacao"][nCnta]:GetJsonText("hora")
				ZCK->ZCK_CHAMAD := oJson["agrupamento"]["aprovacao"][nCnta]:GetJsonText("chamado")
			ZCK->(MsUnLock())
			
		Next

		// Grava as parcelas
		nTotList := Len(oJson["agrupamento"]["parcelas"])
		
		For nCnta:= 1 TO nTotList
		
			RecLock("ZCJ",.T.)
				ZCJ->ZCJ_FILIAL := xFilial("ZCJ")
				ZCJ->ZCJ_IDNEG  := cIdNeg
				ZCJ->ZCJ_PARCEL := CtoD(oJson["agrupamento"]["parcelas"][nCnta]:GetJsonText("dataparcela"))
				ZCJ->ZCJ_VALOR  := Val(oJson["agrupamento"]["parcelas"][nCnta]:GetJsonText("valor"))
			ZCJ->(MsUnLock())
			
		Next
			
	End Transaction	

Elseif cTipNeg == "6"  // Serasa 
	
	cIdNeg  := oJson["sintetico"]:GetJsonText("idnegociacao")
	cIdFatu := oJson["sintetico"]:GetJsonText("idfatura")
	cIdCont := oJson["sintetico"]:GetJsonText("idcontrato")
	cIdFolha:= oJson["sintetico"]:GetJsonText("idfolha")
	cConFat := oJson["sintetico"]:GetJsonText("idconfiguracaofaturamento")
	cConCob := oJson["sintetico"]:GetJsonText("idconfiguracaocobranca")
	cPrefix := oJson["sintetico"]:GetJsonText("prefixotitulo")
	cNumTit := oJson["sintetico"]:GetJsonText("numerotitulo")
	cParTit := oJson["sintetico"]:GetJsonText("parcelatitulo")
	cTipTit := oJson["sintetico"]:GetJsonText("tipotitulo")
	cVlrOri := oJson["sintetico"]:GetJsonText("valortotal")
	cDatOri := oJson["sintetico"]:GetJsonText("datavencimento")
	cBcoFat := oJson["sintetico"]:GetJsonText("bancofaturamento")
	cMsgNot := oJson["sintetico"]:GetJsonText("mensagemnota")
	cSerasa := oJson["sintetico"]:GetJsonText("serasa")
	cMotivo := DecodeUTF8(oJson["sintetico"]:GetJsonText("motivoserasa"))
	
	Begin Transaction
			
		RecLock("ZC9",.T.)
			ZC9->ZC9_FILIAL := xFilial("ZC9")
			ZC9->ZC9_IDNEG	:= cIdNeg
			ZC9->ZC9_TIPNEG := cTipNeg
			ZC9->ZC9_IDFATU := cIdFatu
			ZC9->ZC9_IDCONT := cIdCont
			ZC9->ZC9_IDFOLH := cIdFolha
			ZC9->ZC9_CONFAT := cConFat
			ZC9->ZC9_CONCOB := cConCob
			ZC9->ZC9_PREFIX := cPrefix
			ZC9->ZC9_NUMTIT := cNumTit
			ZC9->ZC9_PARTIT := cParTit
			ZC9->ZC9_TIPTIT := cTipTit			
			ZC9->ZC9_VLRORI := VAL(cVlrOri)
			ZC9->ZC9_DATORI := CTOD(cDatOri)
			ZC9->ZC9_BCOFAT := cBcoFat
			ZC9->ZC9_MSGNOT := cMsgNot
			ZC9->ZC9_SERASA	:= cSerasa
			ZC9->ZC9_MOTIVO	:= cMotivo
			ZC9->ZC9_KAIROS := "N" //Realiza integração Kairós 
			ZC9->ZC9_INTDW3 := "S" //Realiza integração DW3				
			ZC9->ZC9_STATUS := "1" // Pendente
			ZC9->ZC9_DTINTE := Date()
			ZC9->ZC9_HRINTE := Time()
			ZC9->ZC9_JSON   := cJson
		ZC9->(MsUnLock())

		// Grava a aprovção
		nTotList := Len(oJson["sintetico"]["aprovacao"])
		
		For nCnta:= 1 TO nTotList
			
			RecLock("ZCK",.T.)
				ZCK->ZCK_FILIAL := xFilial("ZCK")
				ZCK->ZCK_IDNEG  := cIdNeg
				ZCK->ZCK_NOME   := DecodeUTF8(oJson["sintetico"]["aprovacao"][nCnta]:GetJsonText("nome"))
				ZCK->ZCK_DATA   := CtoD(oJson["sintetico"]["aprovacao"][nCnta]:GetJsonText("data"))
				ZCK->ZCK_HORA   := oJson["sintetico"]["aprovacao"][nCnta]:GetJsonText("hora")
				ZCK->ZCK_CHAMAD := oJson["sintetico"]["aprovacao"][nCnta]:GetJsonText("chamado")
			ZCK->(MsUnLock())
			
		Next
			
	End Transaction	

Elseif cTipNeg == "7"  // Global 
	
	cIdNeg  := oJson["sintetico"]:GetJsonText("idnegociacao")
	cIdFatu := oJson["sintetico"]:GetJsonText("idfatura")
	cIdCont := oJson["sintetico"]:GetJsonText("idcontrato")
	cIdFolha:= oJson["sintetico"]:GetJsonText("idfolha")
	cConFat := oJson["sintetico"]:GetJsonText("idconfiguracaofaturamento")
	cConCob := oJson["sintetico"]:GetJsonText("idconfiguracaocobranca")
	cPrefix := oJson["sintetico"]:GetJsonText("prefixotitulo")
	cNumTit := oJson["sintetico"]:GetJsonText("numerotitulo")
	cParTit := oJson["sintetico"]:GetJsonText("parcelatitulo")
	cTipTit := oJson["sintetico"]:GetJsonText("tipotitulo")
	cVlrOri := oJson["sintetico"]:GetJsonText("valortotal")
	cDatOri := oJson["sintetico"]:GetJsonText("datavencimento")
	cBcoFat := oJson["sintetico"]:GetJsonText("bancofaturamento")
	cMsgNot := oJson["sintetico"]:GetJsonText("mensagemnota")
	cGlobal := oJson["sintetico"]:GetJsonText("global")
	cMotivo := DecodeUTF8(oJson["sintetico"]:GetJsonText("motivoglobal"))
	
	Begin Transaction
			
		RecLock("ZC9",.T.)
			ZC9->ZC9_FILIAL := xFilial("ZC9")
			ZC9->ZC9_IDNEG	:= cIdNeg
			ZC9->ZC9_TIPNEG := cTipNeg
			ZC9->ZC9_IDFATU := cIdFatu
			ZC9->ZC9_IDCONT := cIdCont
			ZC9->ZC9_IDFOLH := cIdFolha
			ZC9->ZC9_CONFAT := cConFat
			ZC9->ZC9_CONCOB := cConCob
			ZC9->ZC9_PREFIX := cPrefix
			ZC9->ZC9_NUMTIT := cNumTit
			ZC9->ZC9_PARTIT := cParTit
			ZC9->ZC9_TIPTIT := cTipTit			
			ZC9->ZC9_VLRORI := VAL(cVlrOri)
			ZC9->ZC9_DATORI := CTOD(cDatOri)
			ZC9->ZC9_BCOFAT := cBcoFat
			ZC9->ZC9_MSGNOT := cMsgNot
			ZC9->ZC9_GLOBAL	:= cGlobal
			ZC9->ZC9_MOTIVO	:= cMotivo
			ZC9->ZC9_KAIROS := "N" //Realiza integração Kairós 
			ZC9->ZC9_INTDW3 := "S" //Realiza integração DW3				
			ZC9->ZC9_STATUS := "1" // Pendente
			ZC9->ZC9_DTINTE := Date()
			ZC9->ZC9_HRINTE := Time()
			ZC9->ZC9_JSON   := cJson
		ZC9->(MsUnLock())

		// Grava a aprovção
		nTotList := Len(oJson["sintetico"]["aprovacao"])
		
		For nCnta:= 1 TO nTotList
			
			RecLock("ZCK",.T.)
				ZCK->ZCK_FILIAL := xFilial("ZCK")
				ZCK->ZCK_IDNEG  := cIdNeg
				ZCK->ZCK_NOME   := DecodeUTF8(oJson["sintetico"]["aprovacao"][nCnta]:GetJsonText("nome"))
				ZCK->ZCK_DATA   := CtoD(oJson["sintetico"]["aprovacao"][nCnta]:GetJsonText("data"))
				ZCK->ZCK_HORA   := oJson["sintetico"]["aprovacao"][nCnta]:GetJsonText("hora")
				ZCK->ZCK_CHAMAD := oJson["sintetico"]["aprovacao"][nCnta]:GetJsonText("chamado")
			ZCK->(MsUnLock())
			
		Next
			
	End Transaction	
				
endif

Return Nil